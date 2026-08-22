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
	_test_gated_invisible_left_alone()
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


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("wild streaming: OK — distant clusters sleep, near ones tick, engaged/fainting/respawning are never touched, and a round trip changes nothing about a creature's identity.")
		quit(0)
		return
	for line in _failures:
		print("wild streaming FAIL: %s" % line)
	quit(1)
