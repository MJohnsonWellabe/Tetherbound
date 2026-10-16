extends SceneTree

## STREAM-D: distance-based activation for wild creatures.
##
##   godot --headless --path . --script tests/smoke_wild_streaming.gd
##
## `encounter_director.gd::_tick_streaming()` is the fix for the density the
## owner has directed (~70 -> 700-1100 creatures across the chapter): a
## cluster far from the player must not tick, one near the player must tick
## exactly as it always has, and a creature engaged/fainting/respawning must
## never be switched off regardless of distance — deactivating one mid-catch
## would be the exact bug this file exists to keep out.
##
## Named `smoke_`, not `test_`, on purpose: `_tick_streaming()` reads
## `Node3D.global_position`, whose getter hard-requires the node be inside a
## live SceneTree (`is_inside_tree()` — confirmed empirically: a freestanding
## Node3D's `global_position` silently reads back `Vector3.ZERO` with a
## engine-level error rather than the position actually set on it). Per
## docs/decisions/D02 that scope belongs to the smoke tests, not
## `tests/test_case.gd`'s pure-logic RefCounted suite, which
## `tests/run_tests.gd` auto-discovers by the `test_*.gd` filename alone — a
## SceneTree-shaped file caught by that glob would crash the whole suite the
## first time the runner called `.before_each()` on an instance that has no
## such method. `encounter_director.gd` itself is instantiated directly here
## (never added to the tree, so its own `_ready()` — which wants a real
## player/manager NodePath — never runs) and its private streaming fields are
## populated by hand to the shape `_spawn_creatures()` would have built; its
## private functions are called directly. No scene load, no Terrain3D, no
## multi-minute boot — this is closer to `tests/test_party_seam.gd`'s
## stand-in pattern than to `smoke_traversal.gd`'s.

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")


## Exercise the real body's release/restore/contact code with a small fitted
## model. Asset loading/colourway appearance still require real game proof.
class ResidencyWild extends "res://scripts/creatures/wild_creature.gd":
	var dressing: Array = []
	func _ready() -> void:
		visibility_changed.connect(_on_visibility_changed)
	func _build_model(_look: Dictionary) -> bool:
		for child: Node in _model.get_children():
			_release_art(child)
		var art := Node3D.new()
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		(mesh.mesh as BoxMesh).size = Vector3(1.0, 2.0, 3.0)
		art.add_child(mesh)
		_model.add_child(art)
		_fit(art, 1.0)
		_model.rotation.y = 0.4
		_render_yaw = 0.4
		_combat_flinch_art = art
		_has_model = true
		_body.visible = false
		_head.visible = false
		return true
	func _refresh_shiny_tint() -> void:
		if not _visual_suspended:
			dressing = [shiny, alpha, tier, aspect_variant, _height, _radius]
	func _apply_ground_contact_shadow() -> void:
		pass
	func _apply_night_floor() -> void:
		pass


class GroundWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 4.0


class GroundableWild extends Node3D:
	func place_on_ground(pos: Vector3) -> bool:
		global_position = Vector3(pos.x, 4.0, pos.z)
		return true

## Night-gate cases (PERF c5e139d6): night controlled directly, base _ready
## skipped so the director can sit in the tree and see `remote_trainer`
## (guest) bodies the way a host does.
class NightDirector extends "res://scripts/combat/encounter_director.gd":
	var night := false
	func _ready() -> void:
		pass
	func _is_night() -> bool:
		return night

## A body whose physics follows its visibility, as creature_body.gd's own
## `_on_visibility_changed()` does.
class GatedWild extends Node3D:
	func _ready() -> void:
		visibility_changed.connect(func() -> void: set_physics_process(visible))

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	# Only code that runs after at least one `await` sees a genuinely live
	# tree: `_init()` itself runs before the engine sets `main_loop`, so a
	# freshly created Node3D's `global_position` getter fails its own
	# `is_inside_tree()` check even after `root.add_child()` if nothing here
	# has yielded yet. One `await process_frame` is enough to be past that —
	# the same reason `encounter_director.gd::_ready()` itself awaits one
	# frame before spawning anything.
	await process_frame
	_test_tick_streaming_exists()
	_test_distant_deactivates_near_stays_active()
	_test_engaged_fainting_respawning_never_deactivated()
	_test_deactivate_reactivate_round_trip_identical()
	_test_active_cluster_recovers_a_delayed_fall()
	_test_gated_invisible_left_alone()
	_test_night_reveal_keeps_a_far_cluster_asleep()
	_test_a_guest_wakes_a_night_cluster_the_host_is_far_from()
	_test_visual_residency_preserves_exact_geometry_and_current_dressing()
	_test_visual_horizon_and_protected_transitions()
	_test_visual_pose_and_tween_guards()
	_report()


func _new_director() -> Node:
	return DIRECTOR.new()


func _fake_player(pos: Vector3) -> CharacterBody3D:
	# `_player` is typed `CharacterBody3D` on the real node, and `.set()` on a
	# typed script var enforces that type at runtime same as a direct
	# assignment would — a plain Node3D is refused here.
	var player := CharacterBody3D.new()
	root.add_child(player)
	player.global_position = pos
	return player


func _member(pos: Vector3) -> Node3D:
	var wild := Node3D.new()
	root.add_child(wild)
	wild.global_position = pos
	wild.set_physics_process(true)  # matches a freshly instantiated body's real default
	return wild


func _cluster(centre: Vector3, radius: float, members: Array[Node3D]) -> Dictionary:
	return {"centre": centre, "radius": radius, "members": members, "active": true}


func _cleanup(director: Node, player: Node3D, members: Array[Node3D]) -> void:
	director.free()
	if is_instance_valid(player):
		player.free()
	for m in members:
		if is_instance_valid(m):
			m.free()


func _fail(message: String) -> void:
	_failures.append(message)


# --- the thing exists --------------------------------------------------------

func _test_tick_streaming_exists() -> void:
	var director := _new_director()
	if not director.has_method("_tick_streaming"):
		_fail("encounter_director.gd has no _tick_streaming()")
	if not director.has_method("_set_wild_active"):
		_fail("encounter_director.gd has no _set_wild_active()")
	if not director.has_method("_activation_radius_margin"):
		_fail("encounter_director.gd has no _activation_radius_margin()")
	var margin: float = director.call("_activation_radius_margin")
	if margin <= 0.0:
		_fail("activation margin must clear a real detection range, not be zero/negative (got %.2f)" % margin)
	director.free()


# --- it behaves: a distant cluster sleeps, a near one does not ---------------

func _test_distant_deactivates_near_stays_active() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var near_members: Array[Node3D] = [_member(Vector3(5, 0, 0)), _member(Vector3(-4, 0, 3))]
	var far_members: Array[Node3D] = [_member(Vector3(2000, 0, 0))]
	director.set("_player", player)
	director.set("_clusters", [
		_cluster(Vector3(0, 0, 0), 10.0, near_members),
		_cluster(Vector3(2000, 0, 0), 10.0, far_members),
	] as Array[Dictionary])

	director.call("_tick_streaming")

	for m in near_members:
		if not m.is_physics_processing():
			_fail("a cluster the player is standing inside must keep ticking")
	for m in far_members:
		if m.is_physics_processing():
			_fail("a cluster 2km away must stop ticking")

	# The reverse transition, in one run: walk the player to the far cluster
	# and nowhere near the first — this is the "per-cluster check, re-evaluated
	# on player movement" the task asked for, not "computed once at boot".
	player.global_position = Vector3(2000, 0, 0)
	director.call("_tick_streaming")
	for m in far_members:
		if not m.is_physics_processing():
			_fail("the cluster the player just walked into must wake up")
	for m in near_members:
		if m.is_physics_processing():
			_fail("the cluster the player just left must go back to sleep")

	_cleanup(director, player, near_members + far_members)


# --- it behaves: engaged / fainting / respawning are never touched -----------

func _test_engaged_fainting_respawning_never_deactivated() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var engaged := _member(Vector3(5000, 0, 0))
	var fainting := _member(Vector3(5000, 0, 0))
	var respawning := _member(Vector3(5000, 0, 0))
	var ordinary := _member(Vector3(5000, 0, 0))
	var members: Array[Node3D] = [engaged, fainting, respawning, ordinary]

	director.set("_player", player)
	director.set("_engaged_with", engaged)
	director.set("_faint_timers", {fainting: 2.0})
	director.set("_respawn_timers", {respawning: 10.0})
	director.set("_clusters", [_cluster(Vector3(5000, 0, 0), 10.0, members)] as Array[Dictionary])

	director.call("_tick_streaming")

	if not engaged.is_physics_processing():
		_fail("a creature mid-fight (and mid-catch, which happens inside a fight) must never be deactivated")
	if not fainting.is_physics_processing():
		_fail("a fainting creature's physics_process is notify_fainted()'s own business, not streaming's")
	if not respawning.is_physics_processing():
		_fail("a respawning creature's physics_process is _tick_respawn()'s own business, not streaming's")
	if ordinary.is_physics_processing():
		_fail("an ordinary same-cluster member with none of the three guards must still deactivate")

	_cleanup(director, player, members)


# --- it behaves: deactivate/reactivate is a no-op on identity ----------------

func _test_deactivate_reactivate_round_trip_identical() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var wild := _member(Vector3(9000, 0, 0))
	# A marker that would NOT survive a real despawn/respawn (queue_free + a
	# fresh instantiate()) — this is the thing a naive "streaming despawns the
	# cluster" implementation would break and this check would catch.
	var identity_marker := RefCounted.new()
	wild.set_meta(&"identity", identity_marker)
	var original_position := wild.global_position

	director.set("_player", player)
	director.set("_clusters", [_cluster(Vector3(9000, 0, 0), 10.0, [wild])] as Array[Dictionary])

	director.call("_tick_streaming")  # far: deactivates
	if wild.is_physics_processing():
		_fail("the cluster should have deactivated on the first tick")
	if not is_instance_valid(wild):
		_fail("deactivation must not free the node")
	if not wild.global_position.is_equal_approx(original_position):
		_fail("deactivation must not move the creature")
	if wild.get_meta(&"identity") != identity_marker:
		_fail("deactivation must not rebuild the creature")

	player.global_position = Vector3(9000, 0, 0)
	director.call("_tick_streaming")  # near: reactivates
	if not wild.is_physics_processing():
		_fail("the cluster should have reactivated once the player walked into it")
	if not wild.global_position.is_equal_approx(original_position):
		_fail("reactivation must not move the creature")
	if wild.get_meta(&"identity") != identity_marker:
		_fail("reactivation must hand back the SAME node, not a re-rolled one")

	_cleanup(director, player, [wild])


# --- it behaves: collision arriving after activation cannot lose wildlife ----

func _test_active_cluster_recovers_a_delayed_fall() -> void:
	var world := GroundWorld.new()
	var director := _new_director()
	# Keep the director's fake world off-tree, as the rest of this smoke keeps
	# the director itself: entering the tree would run production `_ready()` and
	# demand real player/manager NodePaths. The wild still belongs to the live
	# root so its global transform behaves exactly like a production Node3D.
	world.add_child(director)
	var player := _fake_player(Vector3.ZERO)
	var wild := GroundableWild.new()
	root.add_child(wild)
	wild.global_position = Vector3(2, -40, 1)
	wild.set_physics_process(true)
	director.set("_player", player)
	director.set("_clusters", [
		_cluster(Vector3.ZERO, 10.0, [wild] as Array[Node3D]),
	] as Array[Dictionary])
	director.set("_active_reground_left", 0.0)

	# The cluster was already active, which is the exact state where the old
	# transition-only check skipped this body forever after a delayed fall.
	director.call("_tick_streaming", 0.1)
	if not is_equal_approx(wild.global_position.y, 4.0):
		_fail("an already-active nearby creature that fell after activation must be regrounded")
	if not wild.is_physics_processing():
		_fail("recovering an active fallen creature must leave its physics running")

	player.free()
	world.free()


# --- it behaves: a gated-invisible member is left to the gate system ---------

func _test_gated_invisible_left_alone() -> void:
	var director := _new_director()
	var player := _fake_player(Vector3.ZERO)
	var gated := _member(Vector3.ZERO)
	gated.visible = false
	gated.set_physics_process(false)  # what R5.3's gate sync already did to it

	# Cluster starts marked inactive so the player standing right on top of it
	# is a real activate TRANSITION, and `_set_wild_active()`'s gate-skip
	# branch actually runs rather than the call being skipped entirely because
	# nothing changed.
	var cluster := _cluster(Vector3.ZERO, 10.0, [gated])
	cluster["active"] = false

	director.set("_player", player)
	director.set("_wild_gates", {gated: {"time": "night"}})
	director.set("_clusters", [cluster] as Array[Dictionary])

	director.call("_tick_streaming")
	if gated.is_physics_processing():
		_fail("streaming must not turn on a creature the gate has hidden")

	_cleanup(director, player, [gated])


# --- night gates: a reveal never wakes a cluster nobody is near (co-op) -----

func _night_setup(host_at: Vector3) -> Dictionary:
	var director := NightDirector.new()
	root.add_child(director)
	var player := _fake_player(host_at)
	var gated := GatedWild.new()
	gated.name = "Wild_duskhush_1053_1"
	root.add_child(gated)
	gated.global_position = Vector3(200, 0, 0)
	gated.visible = false
	gated.set_physics_process(false)
	var cluster := _cluster(Vector3(200, 0, 0), 10.0, [gated] as Array[Node3D])
	cluster["active"] = false
	director.set("_player", player)
	director.set("_wild_gates", {gated: {"time": "night"}})
	director.set("_clusters", [cluster] as Array[Dictionary])
	director.set("_wild_cluster", {gated: cluster})
	return {"director": director, "player": player, "gated": gated, "cluster": cluster}


func _test_night_reveal_keeps_a_far_cluster_asleep() -> void:
	var setup := _night_setup(Vector3.ZERO)
	var director: NightDirector = setup.director
	var gated: Node3D = setup.gated
	director.night = true
	director.call("_sync_spawn_gates")
	if not gated.visible:
		_fail("a night gate must still reveal its creature at night")
	if gated.is_physics_processing():
		_fail("a night creature revealed in a cluster nobody is near must stay asleep")
	director.night = false
	director.call("_sync_spawn_gates")
	if gated.visible:
		_fail("the night gate must hide its creature again by day")
	_cleanup(director, setup.player, [gated])


func _test_a_guest_wakes_a_night_cluster_the_host_is_far_from() -> void:
	var setup := _night_setup(Vector3.ZERO)
	var director: NightDirector = setup.director
	var gated: Node3D = setup.gated
	var identity := [gated.get_instance_id(), str(gated.name), gated.global_position]
	director.night = true
	director.call("_sync_spawn_gates")
	# A guest's replicated trainer body stands beside the cluster; the host
	# stays 200 m away. Streaming wakes clusters for ANY occupant of the realm.
	var guest := Node3D.new()
	guest.add_to_group(&"remote_trainer")
	root.add_child(guest)
	guest.global_position = Vector3(203, 0, 0)
	director.call("_tick_streaming")
	if not bool((setup.cluster as Dictionary).get("active")):
		_fail("a guest beside a night cluster must activate it on the host")
	if not gated.is_physics_processing():
		_fail("a revealed night creature must wake when a guest brings its cluster into range")
	if [gated.get_instance_id(), str(gated.name), gated.global_position] != identity:
		_fail("waking a night cluster must not change the creature's identity or place")
	guest.free()
	_cleanup(director, setup.player, [gated])


func _resident_wild(pos: Vector3) -> ResidencyWild:
	var wild := CREATURE_SCENE.instantiate() as CharacterBody3D
	wild.set_script(ResidencyWild)
	root.add_child(wild)
	var body := wild as ResidencyWild
	body.species_id = "bramblebun"
	body.instance = preload("res://scripts/creatures/creature_instance.gd").new()
	body._height = 3.0
	body._radius = 0.9
	body._collision.shape = CapsuleShape3D.new()
	(body._collision.shape as CapsuleShape3D).height = 3.0
	(body._collision.shape as CapsuleShape3D).radius = 0.9
	body._build_model({})
	body.global_position = pos
	body.set_physics_process(false)
	return body


func _test_visual_residency_preserves_exact_geometry_and_current_dressing() -> void:
	var director := _new_director()
	var wild := _resident_wild(Vector3(1000, 5, 300))
	wild.instance.hp = 0.65
	var shape := wild._collision.shape
	var identity := [wild.get_instance_id(), wild.species_id, wild.instance, wild.instance.hp, wild.global_transform]
	var pivot := wild.model_pivot()
	var art := pivot.get_child(0)
	var bounds := BOUNDS.measure(pivot)
	var radius: float = director.call("_ambient_render_radius", wild)
	var towards := wild.global_position + Vector3(3, 0, 4)
	var contact := [wild.contact_extent_towards(towards), wild.contact_half_length(), wild._render_half_extents]
	var box_contact := [wild.contact_box_extent_towards(towards), wild.contact_box_half_diagonal()]
	if not wild.suspend_visuals(bounds):
		_fail("ordinary fully fitted visual must suspend")
	if is_instance_valid(art) or pivot.get_child_count() != 0 or wild._animator != null or wild._combat_flinch_art != null:
		_fail("suspension must free actual art and release animator/flinch references")
	if not wild.suspended_render_bounds().is_equal_approx(bounds) \
			or not is_equal_approx(float(director.call("_ambient_render_radius", wild)), radius):
		_fail("empty Model must retain the exact admitted render bounds/radius")
	if contact != [wild.contact_extent_towards(towards), wild.contact_half_length(), wild._render_half_extents]:
		_fail("suspension must not replace measured contact geometry with capsule bounds")
	if box_contact != [wild.contact_box_extent_towards(towards), wild.contact_box_half_diagonal()]:
		_fail("suspension must preserve the conservative contact box too")
	if identity != [wild.get_instance_id(), wild.species_id, wild.instance, wild.instance.hp, wild.global_transform] \
			or wild._collision.shape != shape or not wild.visible or wild.is_physics_processing():
		_fail("suspension must leave identity, instance, transform, collider, visibility and AI state unchanged")
	wild.set_shiny(true)
	wild.set_tier("rare")
	if not wild.ensure_visual_resident() or wild.visual_is_suspended() or pivot.get_child_count() != 1:
		_fail("restore must rebuild a real model on the retained pivot")
	if wild.dressing != [true, false, "rare", "", 3.0, 0.9]:
		_fail("restore must dress the CURRENT individual before showing its model")
	if contact != [wild.contact_extent_towards(towards), wild.contact_half_length(), wild._render_half_extents] \
			or not BOUNDS.measure(pivot).is_equal_approx(bounds):
		_fail("restore must preserve measured scale/contact geometry")
	if identity != [wild.get_instance_id(), wild.species_id, wild.instance, wild.instance.hp, wild.global_transform] \
			or wild._collision.shape != shape \
			or box_contact != [wild.contact_box_extent_towards(towards), wild.contact_box_half_diagonal()]:
		_fail("restore must preserve identity, HP, collider and conservative contact box")
	wild.suspend_visuals(bounds)
	wild.apply_size_multiplier(1.5)
	if wild.visual_is_suspended() or not is_equal_approx(wild._height, 4.5) \
			or not wild._render_half_extents.is_equal_approx((contact[2] as Vector2) * 1.5):
		_fail("size mutation must restore first and scale exact fitted geometry once")
	director.free()
	wild.free()


func _test_visual_horizon_and_protected_transitions() -> void:
	var director := NightDirector.new()
	root.add_child(director)
	var player := _fake_player(Vector3.ZERO)
	var wild := _resident_wild(Vector3(2000, 0, 0))
	director.set("_player", player)
	director.set("_wild_visual_config", {"restore_m": 520.0, "release_m": 650.0})
	var cluster := _cluster(wild.global_position, 10.0, [wild] as Array[Node3D])
	cluster["active"] = false
	director.set("_clusters", [cluster] as Array[Dictionary])
	director.call("_tick_streaming")
	if not wild.visual_is_suspended(): _fail("far inactive ordinary visual must release")
	player.global_position.x = 1400.0
	director.call("_tick_streaming")
	if not wild.visual_is_suspended(): _fail("600m hysteresis band must retain suspended state")
	player.global_position.x = 1500.0
	director.call("_tick_streaming")
	if wild.visual_is_suspended() or wild.is_physics_processing():
		_fail("visual must return at 500m while the short AI reach remains inactive")
	player.global_position = Vector3.ZERO
	director.call("_tick_streaming")
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = wild.global_position + Vector3(0, 5, 20)
	camera.make_current()
	director.call("_tick_streaming")
	if wild.visual_is_suspended(): _fail("current camera must protect a remote visible body")
	camera.free()
	director.call("_tick_streaming")
	var guest := Node3D.new()
	root.add_child(guest)
	guest.add_to_group(&"remote_trainer")
	guest.global_position = wild.global_position + Vector3(400, 0, 0)
	director.call("_tick_streaming")
	if wild.visual_is_suspended(): _fail("remote realm occupant must restore visuals outside AI range")
	guest.free()
	for protected_map: String in ["_faint_timers", "_respawn_timers", "_once_only"]:
		director.call("_tick_streaming")
		director.set(protected_map, {wild: 10.0})
		director.call("_tick_streaming")
		if wild.visual_is_suspended(): _fail(protected_map + " must restore/protect its body")
		director.set(protected_map, {})
	director.call("_tick_streaming")
	director.set("_engaged_with", wild)
	director.call("_tick_streaming")
	if wild.visual_is_suspended(): _fail("engagement must restore before use")
	director.set("_engaged_with", null)
	director.call("_tick_streaming")
	director.set("_wild_visual_config", {})
	director.call("_update_wild_visual_residency", wild, false, [Vector3.ZERO] as Array[Vector3])
	if wild.visual_is_suspended(): _fail("disabled residency must restore the old resident behavior")
	_cleanup(director, player, [wild])


func _test_visual_pose_and_tween_guards() -> void:
	var wild := _resident_wild(Vector3.ZERO)
	var bounds := BOUNDS.measure(wild.model_pivot())
	wild._rest_pose_pending = true
	if wild.suspend_visuals(bounds): _fail("pending skeletal rest must veto release")
	wild._rest_pose_pending = false
	wild._combat_hitstop_active = true
	if wild.suspend_visuals(bounds): _fail("combat hitstop must veto release")
	wild._combat_hitstop_active = false
	wild._catch_tween = wild.create_tween()
	wild._catch_tween.tween_interval(1.0)
	if wild.suspend_visuals(bounds): _fail("catch tween must veto release")
	wild._kill_catch_tween()
	if wild.suspend_visuals(AABB()): _fail("missing measured geometry must never authorize release")
	wild.suspend_visuals(bounds)
	wild.play_faint()
	if wild.visual_is_suspended(): _fail("faint presentation must synchronously restore")
	wild.free()


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("wild streaming: OK — distant clusters sleep, near ones tick and recover delayed falls, engaged/fainting/respawning are never touched, a round trip changes nothing about a creature's identity, and a night reveal wakes a cluster only when the host or a guest is near.")
		quit(0)
		return
	for line in _failures:
		print("wild streaming FAIL: %s" % line)
	quit(1)
