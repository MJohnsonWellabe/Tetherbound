extends RefCounted

## Left-stick travel that can get around what is in the way.
##
## GATEB-PATH. Every continuous harness in this repo walked by pointing the
## stick at a coordinate and holding it, and that is the single reason
## `tests/smoke_gate_b_continuous.gd` had never finished a run. The Meadows has
## no navmesh -- nothing under `scripts/`, `scenes/` or `autoload/` so much as
## mentions `NavigationServer3D` -- so "walk toward the point" has always meant
## "walk into whatever stands between here and the point, and keep pushing".
##
## The evidence is exact rather than inferred. The run before this reported
##
##   could not reach or activate door 'Door' in 1200 frames (player 3.6m away at
##   (18, 1, -6), door at (15, 1, -3), prompt enabled=true,
##   arbiter winner=EncounterDirector)
##
## and the geometry says why: Oskar stands at [22,-6], Mira's door is the hole
## in cottage_a's front wall, and cottage_a (`data/config/village.json`,
## `at: [18,-2]`, `yaw_deg: -135`) puts that wall's solid left-hand piece
## (`data/config/building_prefabs.json`, local x -2.2..0.2 at local z 3)
## directly across the straight line between them. Twenty seconds of walking
## into plaster, with the door offerable the whole time and simply not visible
## from where the player stood -- `interactable.gd::_has_line_of_sight` refuses
## an offer through a wall, so the EncounterDirector was not stealing the
## interact line, it was the only thing still bidding for it.
##
## What this does instead is the walk a person does in the dark: when a leg
## stops closing on its target, put a hand on the wall and slide. A free-space
## probe picks which hand; repeated failures on that side switch hands.
##
## Deliberately NOT an authored per-villager waypoint table. The same straight
## line breaks at Bram's inn, on the material route's long treks, and at every
## later beat these harnesses have not reached yet, and a table would need an
## entry for each of them. This is the general answer, and it lives entirely in
## the test harness -- no gameplay code changes, because nothing about the game
## is wrong here.
##
## Shared rather than copied: `gate_a_npc_gather_segment.gd` and
## `gate_a_material_route.gd` each had their own straight-line walker with its
## own way of pushing the stick, and two copies of a navigator is how one of
## them silently stops being fixed.

## Physics frames of no measurable progress before the walk decides it is
## pressed against something rather than merely slow.
const STALL_FRAMES := 26
## Metres of closing that count as progress. Loose enough that a diagonal
## scrape along a wall does not read as travel.
const PROGRESS := 0.08
## Physics frames spent walking sideways once a detour starts. Each further
## detour on the same side runs `DETOUR_GROWTH` frames longer, because a long
## wall needs a longer slide than a fence post does.
const DETOUR_FRAMES := 45
const DETOUR_GROWTH := 25
## Detours on one side that fail to unstick before the other side is tried.
const DETOURS_PER_SIDE := 3
## The sideways free-space probe: cast at roughly hip height so the ray clears
## the ground, and only as far as a detour would actually walk.
const PROBE_HEIGHT := 1.0
const PROBE_REACH := 3.0
## How far ahead the GROUND is checked before sliding that way, and the drop
## that counts as a cliff rather than a step down.
##
## GATEB-COORD. The free-space probe above is a horizontal ray: it can see a
## wall and is completely blind to a hole. So a detour would cheerfully slide
## off the edge of the Practice Meadow plateau, and the walker would spend the
## rest of its budget four metres below the target trying to climb terrain it
## cannot climb -- the Gate B build segment failed that way over and over,
## reporting its trainer at y=-2.0 while the stance it wanted sat at y=3.0.
## A side whose ground falls away by more than `SAFE_DROP` is treated as
## blocked, exactly like a wall, because for a walker it is worse than one.
const GROUND_LOOK_AHEAD := 2.0
const SAFE_DROP := 1.2
const GROUND_PROBE_DEPTH := 8.0
## Metres from the target at which the stick eases off, and the smallest
## deflection it eases to. Full stick into a target measured in centimetres
## overshoots and oscillates around it; `gate_a_build_segment.gd` stops within
## `MOVE_EPSILON` 0.16m and had these exact numbers of its own before this file
## existed, so they are kept rather than re-invented.
const EASE_METRES := 0.9
const EASE_FLOOR := 0.32

var _tree: SceneTree = null
var _player: Node3D = null
var _rig: Node3D = null
## `drive.call(local_x: float, local_y: float)` pushes the caller's own left
## stick. Each harness parses its own bindings and signs out of the live
## InputMap, so the navigator hands over stick-space numbers and lets the
## caller stay the one that speaks to `Input`.
var _drive: Callable = Callable()

var _gap := INF
var _stall := 0
var _detour := Vector3.ZERO
var _detour_left := 0
var _side := 0.0
var _side_detours := 0


func _init(tree: SceneTree, player: Node3D, rig: Node3D, drive: Callable) -> void:
	_tree = tree
	_player = player
	_rig = rig
	_drive = drive


## Physics frames this will wait, in total, for locomotion to come back before
## giving up on a leg. Ten minutes: a wild fight is the usual reason and it
## ends on its own; anything longer is a stuck world, not a busy one.
const HELD_FRAMES := 36000


## Walk to `point`, detouring around whatever is in the way. True if it arrived.
##
## GATEB-COORD: a leg PAUSES while the player cannot move.
## `encounter_director.gd::_set_exploration_active()` turns
## `locomotion_enabled` off for the whole of a fight, and a wild creature
## picking one is the single most common thing to happen to a harness walking
## across open meadow. Without this the walk kept pushing the stick at a body
## that could not move, read every frame of it as a stall, escalated into
## longer and longer sideways detours, and then -- the moment the fight
## ended -- set off in whichever direction the last detour had chosen. That is
## how the Gate B build segment kept finding its trainer nine metres east and
## five metres below the stance it had already reached.
##
## Frames spent held do not count against the leg's budget: the budget is a
## measure of walking, and none is being done.
func walk_to(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:
	reset()
	var held := 0
	var walked := 0
	while walked < budget:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= close_enough:
			return true
		if not can_walk():
			held += 1
			if held > HELD_FRAMES:
				return false
			# Hands off the stick, and forget the stall this was building up:
			# nothing that happened while the body was frozen says anything
			# about what is in the way.
			_drive.call(0.0, 0.0)
			reset()
			await _tree.physics_frame
			continue
		walked += 1
		await step(point)
	return false


## Is the body this is driving actually able to move right now? Public, because
## a caller that drives `step()` itself -- `gate_a_npc_gather_segment.gd` walks
## up to a villager one frame at a time so it can watch the interact line --
## needs the same answer and must not have its own copy of it.
##
## Read off the player rather than passed in, because every harness in this
## repo finds its player by exactly this method and none of them should have to
## remember to wire up a fight check.
func can_walk() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if not _player.has_method("locomotion_enabled"):
		return true
	return bool(_player.call("locomotion_enabled"))


## One physics frame of travel toward `point`. Split out so a caller can
## interleave walking with watching what the world is offering.
func step(point: Vector3) -> void:
	var to := point - _player.global_position
	to.y = 0.0
	if _detour_left > 0:
		# Stop sliding the moment the ground ahead stops being ground. The side
		# was checked when the detour began, but a slide is several metres long
		# and an edge can arrive part-way along it.
		if _drops_away(_detour):
			_detour_left = 0
			_side = -_side
			_side_detours = 0
		else:
			_detour_left -= 1
			_push(_detour)
			await _tree.physics_frame
			return
	var gap := to.length()
	if gap < _gap - PROGRESS:
		_gap = gap
		_stall = 0
	else:
		_stall += 1
		if _stall >= STALL_FRAMES:
			_begin_detour(to)
			_push(_detour)
			await _tree.physics_frame
			return
	_push(to.normalized() * clampf(gap / EASE_METRES, EASE_FLOOR, 1.0))
	await _tree.physics_frame


## One physics frame of stick in a world direction, with no detour logic. For a
## deliberate shuffle -- a sidestep to change the interact arbiter's mind --
## which is not a leg of travel and must not be read as a stall.
func push_once(direction: Vector3) -> void:
	_push(direction)


func reset() -> void:
	_gap = INF
	_stall = 0
	_detour = Vector3.ZERO
	_detour_left = 0
	_side = 0.0
	_side_detours = 0


## Turn the walk sideways. Which way is decided once per side and then KEPT:
## following a wall means committing to a direction, and a walk that re-chose
## every stall would oscillate in the corner it is trying to leave.
func _begin_detour(to: Vector3) -> void:
	_stall = 0
	_gap = to.length()
	if _side == 0.0:
		_side = _freer_side(to)
		_side_detours = 0
	elif _side_detours >= DETOURS_PER_SIDE:
		_side = -_side
		_side_detours = 0
	_side_detours += 1
	_detour = to.normalized().cross(Vector3.UP).normalized() * _side
	_detour_left = DETOUR_FRAMES + (_side_detours - 1) * DETOUR_GROWTH


## +1 or -1: which perpendicular is the better way to slide. A tie goes to +1
## rather than to a coin flip, so a failing run reproduces frame for frame.
##
## A drop beats free space. GATEB-COORD: open air reads as the freest possible
## direction to a horizontal ray, so without checking the ground first the
## probe actively PREFERS walking off a ledge.
func _freer_side(to: Vector3) -> float:
	var side := to.normalized().cross(Vector3.UP).normalized()
	var right_drops := _drops_away(side)
	var left_drops := _drops_away(-side)
	if right_drops != left_drops:
		return -1.0 if right_drops else 1.0
	if _free_space(-side) > _free_space(side) + 0.2:
		return -1.0
	return 1.0


## Does the ground fall away by more than `SAFE_DROP` a step in `direction`?
## True also when there is no ground within `GROUND_PROBE_DEPTH` at all, which
## is the same answer for a walker and a cheaper one to be wrong about.
func _drops_away(direction: Vector3) -> bool:
	var world := _player.get_world_3d()
	var space := world.direct_space_state if world != null else null
	if space == null:
		return false
	var foot := _player.global_position
	var ahead := foot + direction.normalized() * GROUND_LOOK_AHEAD + Vector3.UP * PROBE_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(ahead,
		ahead + Vector3.DOWN * GROUND_PROBE_DEPTH)
	query.collide_with_areas = false
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	return foot.y - (hit.get("position") as Vector3).y > SAFE_DROP


## Metres of clear space in `direction`, capped at `PROBE_REACH`.
func _free_space(direction: Vector3) -> float:
	var world := _player.get_world_3d()
	var space := world.direct_space_state if world != null else null
	if space == null:
		return PROBE_REACH
	var from := _player.global_position + Vector3.UP * PROBE_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * PROBE_REACH)
	# Areas are triggers -- interior camera volumes, encounter zones -- not
	# things a body can walk into.
	query.collide_with_areas = false
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return PROBE_REACH
	return from.distance_to(hit.get("position", from) as Vector3)


func _push(direction: Vector3) -> void:
	var basis: Basis = _rig.call("planar_basis")
	var local := basis.inverse() * direction
	_drive.call(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
