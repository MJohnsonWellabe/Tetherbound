extends Node3D

## OP-0905-15 / D110 — the storm road's own collapsed bridge rebuilds itself
## the moment the Warden falls, and its far rim is the walk into Cloudreach.
##
## The owner's reaction to the keyed realm arch `playground_world.gd` used to
## stand at the Storm Road (`docs/owner/OWNER_PLAYTEST_2026-09-05.md`
## OP-0905-15): "The portal to the next biome is horrible. It didn't need to
## be there. When you beat the legendary the rift collapses and the second
## biome is revealed and pulled into the map to connect."
## `docs/decisions/D110-the-rift-collapse-is-the-crossing-to-cloudreach.md`
## records the change and what it supersedes. Short version: no arch, no key
## prompt — the SAME `legendary_freed` flag `rift_collapse.gd` already watches
## for SG44's sky event now also rebuilds the ACTUAL COLLAPSED BRIDGE
## `severed_spokes.gd` left standing with nothing between its two abutments,
## on the SAME carve `data/config/terrain_playground.json`'s `storm_road`
## spoke authors — never a number copied out of it, so moving that road moves
## this with it.
##
## Two things this file owns that `rift_collapse.gd` still does not:
##
##   * a walkable deck across the carve, between the two abutments
##     `severed_spokes.gd::_build_collapsed_bridge` already stood, timed to
##     appear once `rift_collapse.gd`'s own sky event has finished
##     (`collapse.hold_seconds + dissipate_seconds`, read from the SAME
##     `rift_collapse.json` so the two stay in step) — unless the flag is
##     already set at build (a loaded save), in which case the span stands
##     immediately with no animation, the same as every other post-flag world
##     change in this chapter (`rift_collapse.gd::_apply_now`, `meadow_
##     healing.gd`, ...);
##   * one Area3D past the far rim that is the actual realm boundary: crossing
##     it calls `Game.enter_realm("cloudreach", "cloudreach_arrival_from_
##     meadows")` exactly once. Before the flag there is neither span nor
##     trigger — the carve failsafe `severed_spokes.gd` already hangs on this
##     same carve (`blocker.carve.failsafe`) is untouched and still catches a
##     fall into the gap.
##
## Everything upstream of the flag is exactly as `rift_collapse.gd`'s own
## header still describes it: sky only, nothing to reach. This file is what
## the sky event becomes reachable INTO once the world says it is time.
##
## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb every other builder in this directory uses, and never a raycast
## (D09).

const CONFIG_PATH := "res://data/config/rift_collapse.json"
const TERRAIN_CONFIG_PATH := "res://data/config/terrain_playground.json"
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")

## The trigger's own node name. OP-0905-15's implementation brief names the
## Area3D itself "RiftCrossing"; this file's own root (built as a sibling of
## `RiftCollapse` in `playground_world.gd`) already carries that name, so the
## child gets the same word with the role appended rather than an exact
## duplicate a `find_child` would have to disambiguate by type alone.
const TRIGGER_NAME := "RiftCrossingTrigger"
const DECK_BODY_NAME := "CrossingDeckBody"

const REALM_UNLOCK_FLAG := "realm_gate_cloudreach_unlocked"

var _config: Dictionary = {}
var _crossing_config: Dictionary = {}
var _spoke: Dictionary = {}
var _world: Node3D = null
var _progression: RefCounted = null
var _flag := "legendary_freed"
var _revision := -1

## The crossing's own frame, resolved once from the spoke's carve — never
## authored in this file. Move the storm road and this moves with it.
var _near := Vector2.ZERO
var _far := Vector2.ZERO
var _near_ground := 0.0
var _far_ground := 0.0

var _waiting_for_collapse := false
var _wait_elapsed := 0.0

var _spawned := false
var _appearing := false
var _appear_elapsed := 0.0
var _appear_seconds := 3.0

var _deck_anchor: Node3D = null
var _deck_body: StaticBody3D = null
var _trigger: Area3D = null
var _entered := false


func build(world: Node3D) -> void:
	_world = world
	_config = _load_json(CONFIG_PATH)
	if _config.is_empty():
		push_warning("rift_collapse.json missing; the storm road never rebuilds")
		return
	_crossing_config = _config.get("crossing", {})
	if not _resolve_frame():
		return
	_watch_the_flag()
	if not _spawned:
		set_process(true)


## The seam's frame, off the spoke's OWN carve — the same carve
## `severed_spokes.gd::_build_collapsed_bridge` already stood two abutments
## on. `across` here is the direction the ROAD crosses the gap (the carve's
## own `axis_deg` runs roughly perpendicular to the road, along the gorge's
## length); `side > 0` is the abutment that function already names "near",
## repeated here unchanged so this file's near/far agree with the masonry
## that is already standing.
func _resolve_frame() -> bool:
	var wanted := str(_config.get("spoke", "storm_road"))
	var terrain := _load_json(TERRAIN_CONFIG_PATH)
	for entry: Variant in (terrain.get("spokes", {}).get("routes", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == wanted:
			_spoke = entry
			break
	if _spoke.is_empty():
		push_warning("rift_crossing: no spoke '%s' in terrain_playground.json" % wanted)
		return false
	var blocker: Dictionary = _spoke.get("blocker", {})
	var carve: Dictionary = blocker.get("carve", {})
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		push_warning("rift_crossing: spoke '%s' has no carve to bridge" % wanted)
		return false
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var margin := float(_crossing_config.get("abutment_margin_m", 1.5))
	var reach: float = float(carve.get("half_width", 6.0)) + float(carve.get("rim", 5.0)) + margin
	_near = centre + across * reach
	_far = centre - across * reach
	_near_ground = float(_world.call("ground_height_at", _near.x, _near.y))
	_far_ground = float(_world.call("ground_height_at", _far.x, _far.y))
	if is_nan(_near_ground) or is_nan(_far_ground):
		push_warning("rift_crossing: no ground at the storm road's abutments; the span has nothing to stand on")
		return false
	return true


## `legendary_freed`, read never written — see `rift_collapse.gd`'s own
## header on why this is polling `revision` rather than a signal.
func _watch_the_flag() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	_progression = game.get("progression") as RefCounted
	if _progression == null:
		return
	_flag = str(_config.get("flag", "legendary_freed"))
	if bool(_progression.call("has", _flag)):
		_spawn_span(true)


func _process(delta: float) -> void:
	if _spawned:
		if _appearing:
			_advance_appear(delta)
		return
	if _waiting_for_collapse:
		_wait_elapsed += delta
		var collapse: Dictionary = _config.get("collapse", {})
		var hold := float(collapse.get("hold_seconds", 1.2))
		var dissipate := maxf(float(collapse.get("dissipate_seconds", 9.0)), 0.01)
		if _wait_elapsed >= hold + dissipate:
			_spawn_span(false)
		return
	_poll_the_flag()


func _poll_the_flag() -> void:
	if _progression == null:
		return
	var revision := int(_progression.get("revision"))
	if revision == _revision:
		return
	_revision = revision
	if bool(_progression.call("has", _flag)):
		_waiting_for_collapse = true
		_wait_elapsed = 0.0


func _spawn_span(instant: bool) -> void:
	if _spawned:
		return
	_spawned = true
	_waiting_for_collapse = false
	_appear_seconds = maxf(float(_crossing_config.get("appear_seconds", 3.0)), 0.05)
	_build_deck()
	_build_trigger()
	_build_sign()
	if instant:
		_deck_anchor.scale = Vector3.ONE
		_finish_appear()
	else:
		_deck_anchor.scale = Vector3(0.02, 1.0, 1.0)
		_appearing = true
		_appear_elapsed = 0.0
		_set_deck_collision(false)


func _advance_appear(delta: float) -> void:
	_appear_elapsed += delta
	var t := clampf(_appear_elapsed / _appear_seconds, 0.0, 1.0)
	_deck_anchor.scale = Vector3(maxf(t, 0.02), 1.0, 1.0)
	if t >= 1.0:
		_finish_appear()


func _finish_appear() -> void:
	_appearing = false
	if _deck_anchor != null:
		_deck_anchor.scale = Vector3.ONE
	_set_deck_collision(true)
	set_process(false)


func _set_deck_collision(enabled: bool) -> void:
	if _deck_body == null:
		return
	for child in _deck_body.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = not enabled


## The deck itself: one masonry slab on the same T_UnevenBrick sheet the
## carve's own abutments wear (`severed_spokes.gd::_stone_material`, reused
## through a throwaway instance the same way `tether_relay.gd`/`stronghold.gd`
## already borrow that file's helpers), plus two low rails so the edge reads.
## Built as a child of `DeckAnchor`, seated at the near abutment with its own
## local +X run toward the far one, so animating `DeckAnchor.scale.x` from
## near-zero to one grows the whole span (deck, rails, collider together) from
## the near side without a second code path for the animated and the
## instant-from-save cases.
func _build_deck() -> void:
	var width := float(_crossing_config.get("deck_width", 4.4))
	var thickness := float(_crossing_config.get("deck_thickness", 0.34))
	var rail_height := float(_crossing_config.get("rail_height", 0.55))
	var rail_thickness := float(_crossing_config.get("rail_thickness", 0.16))
	var rail_inset := float(_crossing_config.get("rail_inset", 0.3))
	var length := _near.distance_to(_far)
	var direction := (_far - _near).normalized()
	# NOT `severed_spokes.gd::_ground_wall`'s own `atan2(axis.x,axis.y)+PI*0.5`
	# convention: that formula only has to put a run's LENGTH along a bearing
	# for a box built symmetric about its own centre, where a sign-flipped
	# local +X reads identically. This deck is built one-sided from the near
	# anchor (local x=0) out to the far one (local x=length), so the sign
	# matters -- local +X must map to `direction` itself, not its reverse.
	# A Node3D's local +X maps to global (cos(rotation.y), 0, -sin(rotation.y)),
	# so this solves cos(yaw)=direction.x, -sin(yaw)=direction.y for yaw.
	var yaw := atan2(-direction.y, direction.x)
	# GATE-CROSSING-SLOPE. `gated_crossing.gd`'s own `deck_ground := maxf(near,
	# far)` is right for the South Bridge/Old Mill Crossing because both their
	# landings sit on the SAME authored `flats` pad and agree to within
	# centimetres (that file's own comment says so). The storm road's carve
	# has no such pad -- measured on the real bake (`tools/_probe_rift_
	# crossing_slope.gd`, this task): near abutment ground -1.22, far abutment
	# ground +3.99, a real 5.2 m difference over the ~25 m span. A flat deck at
	# the higher of the two would stand the near landing off a sheer ~5.2 m
	# unclimbable step -- measured with a live probe: it never even reaches
	# the deck, plateauing at the same ~28 m the UNCROSSABLE carve already
	# produced before this file existed. So the deck is a ramp: `DeckAnchor`
	# sits at the near ground exactly, and one `rotate_object_local` around
	# its own (post-yaw) local Z tilts local +X up to the far ground -- an
	# 11.8-degree grade on the measured numbers, comfortably under every
	# floor_max_angle in this game.
	var slope := atan2(_far_ground - _near_ground, length)

	var stone: Node3D = SEVERED_SPOKES.new()
	var material: StandardMaterial3D = stone.call("_stone_material")
	stone.free()

	_deck_anchor = Node3D.new()
	_deck_anchor.name = "DeckAnchor"
	_deck_anchor.position = Vector3(_near.x, _near_ground, _near.y)
	_deck_anchor.rotation.y = yaw
	_deck_anchor.rotate_object_local(Vector3(0.0, 0.0, 1.0), slope)
	add_child(_deck_anchor)

	var deck_mesh := MeshInstance3D.new()
	deck_mesh.name = "CrossingDeckMesh"
	var deck_box := BoxMesh.new()
	deck_box.size = Vector3(length, thickness, width)
	deck_box.material = material
	deck_mesh.mesh = deck_box
	# The deck's TOP face sits at the anchor's own height; the slab hangs down
	# from it, same as a real span would sit on its abutments.
	deck_mesh.position = Vector3(length * 0.5, -thickness * 0.5, 0.0)
	_deck_anchor.add_child(deck_mesh)

	_deck_body = StaticBody3D.new()
	_deck_body.name = DECK_BODY_NAME
	_deck_body.position = deck_mesh.position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = deck_box.size
	shape.shape = box
	_deck_body.add_child(shape)
	_deck_anchor.add_child(_deck_body)

	for side: float in [1.0, -1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "CrossingRail_%s" % ("A" if side > 0.0 else "B")
		var rail_box := BoxMesh.new()
		rail_box.size = Vector3(length, rail_height, rail_thickness)
		rail_box.material = material
		rail.mesh = rail_box
		rail.position = Vector3(length * 0.5, rail_height * 0.5, side * (width * 0.5 - rail_inset))
		_deck_anchor.add_child(rail)


## Past the far abutment, continuing the same direction the deck runs in.
## This is the realm boundary itself: nothing before it (the pre-flag carve,
## the animating span) is ever enterable, and this does not exist until the
## span is standing.
func _build_trigger() -> void:
	var depth := float(_crossing_config.get("trigger_depth_m", 10.0))
	var width := float(_crossing_config.get("trigger_width_m", 10.0))
	var span := float(_crossing_config.get("trigger_length_m", 6.0))
	var direction := (_far - _near).normalized()
	var centre := _far + direction * depth
	var ground := float(_world.call("ground_height_at", centre.x, centre.y))
	if is_nan(ground):
		ground = _far_ground
	# See `_build_deck`'s own comment on this formula -- kept the same here
	# (even though this box is centred, so the sign would not matter for
	# catching a body) so `span`/`width` land along the axes their names say.
	var yaw := atan2(-direction.y, direction.x)

	_trigger = Area3D.new()
	_trigger.name = TRIGGER_NAME
	_trigger.position = Vector3(centre.x, ground + 1.5, centre.y)
	_trigger.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(span, 3.0, width)
	shape.shape = box
	_trigger.add_child(shape)
	_trigger.body_entered.connect(_on_trigger_entered)
	add_child(_trigger)


## Old signage, `severed_spokes.gd::_build_sign`'s own word for it — reused
## through the same throwaway-instance convention as the material above,
## rather than re-implementing the plank/arm/label geometry here. Best
## effort: a malformed or missing signpost mesh only warns (see that
## function's own guard), never blocks the crossing.
func _build_sign() -> void:
	var label := str(_crossing_config.get("sign_label", "Cloudreach Cliffs"))
	if label.is_empty():
		return
	var direction := (_far - _near).normalized()
	if direction == Vector2.ZERO:
		return
	var side := Vector2(-direction.y, direction.x)
	var offset := float(_crossing_config.get("sign_offset_m", 3.0))
	var ahead := float(_crossing_config.get("sign_ahead_m", 30.0))
	var at := _far + side * offset
	var aimed := _far + direction * ahead
	var post: Node3D = SEVERED_SPOKES.new()
	post.name = "CrossingSign"
	add_child(post)
	post.call("_build_sign", _world, {
		"sign": {"at": [at.x, at.y], "label": label, "points": [[at.x, at.y], [aimed.x, aimed.y]]},
	}, "rift_crossing")


## The far trigger fires `Game.enter_realm` exactly once. Guarded three ways:
## re-entry (`_entered`), a fade/dialogue in progress (the same
## `interaction_arbiter.gd::enabled()` every interactable prompt already
## checks), and the router's own entitlement check — the Warden grants
## `realm_key_cloudreach` at the same moment as `legendary_freed`, so this
## should never actually see the key missing, but a walk-through trigger has
## no retry prompt if it did, so the flag is left unlatched until `Game`
## itself agrees the crossing may proceed.
##
## `realm_gate_cloudreach_unlocked` is also set here, once. That flag used to
## be written by the arch's own "unlock" interaction and is still what
## Cloudreach's own return gate (`cloudreach_world.gd::MeadowsReturnRealmGate`)
## checks before it will hand the player back — D110 preserves that contract
## rather than editing a file this task does not own.
func _on_trigger_entered(body: Node3D) -> void:
	if _entered:
		return
	if not body is CharacterBody3D or body.name != "Player":
		return
	var arbiter := get_tree().get_first_node_in_group("interaction_arbiter")
	if arbiter != null and arbiter.has_method("enabled") and not bool(arbiter.call("enabled")):
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null or not game.has_method("enter_realm"):
		return
	if game.has_method("can_enter_realm") and not bool(game.call("can_enter_realm", "cloudreach")):
		return
	_entered = true
	if _progression != null and not bool(_progression.call("has", REALM_UNLOCK_FLAG)):
		_progression.call("set_flag", REALM_UNLOCK_FLAG)
	print("[rift_crossing] the player crossed the rebuilt storm road span into Cloudreach")
	game.call("enter_realm", "cloudreach", "cloudreach_arrival_from_meadows")


## --- what the test reads ------------------------------------------------------

func near_anchor() -> Vector3:
	return Vector3(_near.x, _near_ground, _near.y)


func far_anchor() -> Vector3:
	return Vector3(_far.x, _far_ground, _far.y)


## True once the span is fully standing (instantly from a save, or after its
## own appear animation) with a live collider.
func span_ready() -> bool:
	return _spawned and not _appearing


## Returns `Vector2.INF` on malformed input — `severed_spokes.gd`'s own
## convention, matched here because `_resolve_frame` tests against it.
func _vec2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		var list: Array = raw
		return Vector2(float(list[0]), float(list[1]))
	return Vector2.INF


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
