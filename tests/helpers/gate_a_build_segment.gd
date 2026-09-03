extends RefCounted

## Reusable controller-only construction segment for Gate A's continuous run.
##
## The caller owns progression and naturally earned materials. This helper
## walks the actual player from their current Meadows position to the documented
## opening-meadow build patch before it opens Build. It does not grant inventory,
## teleport, arm pending_build, call a menu/placer private method, or edit
## placed_buildings. Every change to play state comes from a physical joypad
## event fed through the live InputMap.

const BUILD_MENU_GROUP := &"build_menu"
const PLACED_GROUP := &"placed_building"
const BUILD_SNAP := preload("res://scripts/build/build_snap_contract.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const PLACE_AHEAD := 3.0
## Where the hammer goes if the caller has not already put it somewhere, and
## the quick-bar buttons in slot order.
const HAMMER_SLOT := 3
const HOTBAR_ACTIONS: Array[StringName] = [&"hotbar_1", &"hotbar_2", &"hotbar_3", &"hotbar_4"]
const POSITION_EPSILON := 0.08
const MOVE_EPSILON := 0.16
const MOVE_FRAME_LIMIT := 360
## The floor under a walk's frame budget once there is a building in the way.
## Sixty seconds: the navigator spends most of a leg round a house sliding
## along its walls rather than closing on the target.
const WALK_FRAME_FLOOR := 3600

## The Practice Meadow's authored clearing, centred at (30,-40). It has a
## 16m vegetation exclusion and the ordinary village route ends here via
## (10,-10)->(18,-24)->(30,-40). This segment still walks to it; the smoke
## wrapper may stage a player only for mechanical placement regression.
## Canonical evidence must arrive through ordinary traversal with naturally
## earned stock.
const BUILD_PATCH_XZ := Vector2(30.0, -40.0)
const BUILD_PATCH_APPROACH_EPSILON := 0.55
## The reusable paid segment begins only after ordinary exploration has reached
## the Village Square. From there it follows the authored Practice Meadow road,
## never a fixture-only diagonal across settlement collision.
const BUILD_ROUTE_XZ: Array[Vector2] = [
	# BESIDE the well, not on top of it.
	#
	# GATEB-COORD: this was (10, -10) with a 0.75m tolerance, and
	# `data/config/village.json` puts the WELL at exactly (10, -10) -- a solid
	# stone curb, two posts and a canopy. So the entry this segment demands the
	# caller reach "through ordinary exploration" was a point no body can
	# occupy, and the Gate B continuous run proved it: three approaches from
	# three directions, stopping 7.8m, 4.3m and 7.5m away, circling a target
	# they could see and could never stand on.
	#
	# The square is the paved apron where the four paths meet, not the well
	# head. Three metres south of it is on that apron, clear of every
	# structure, and on the way to the Practice Meadow road bend.
	Vector2(10.0, -13.0), # Village Square, on the apron south of the well
	Vector2(18.0, -24.0), # Practice Meadow road bend
	BUILD_PATCH_XZ, # Practice Meadow clearing
]
const BUILD_ROUTE_ENTRY_EPSILON := 0.75
const HOUSE_AIM_DIRECTION := Vector3(0, 0, -1)

var failures: Array[String] = []
var transcript: Array[String] = []
var _tree: SceneTree
var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _camera_rig: Node3D
var _move_x_axis: JoyAxis = JOY_AXIS_LEFT_X
var _move_y_axis: JoyAxis = JOY_AXIS_LEFT_Y
var _move_x_sign := 1.0
var _move_y_sign := 1.0
## Travel, built lazily because the bindings above are resolved after `run()`
## starts. See `stick_navigator.gd`.
var _nav = null  # stick_navigator.gd; untyped so its methods read as methods
var _look_x_axis: JoyAxis = JOY_AXIS_RIGHT_X
var _look_x_sign := 1.0
var _house_record_start := 0
var _preflight_first_floor := Vector3.INF


func run(tree: SceneTree, world: Node3D, player: CharacterBody3D, camera_rig: Node3D) -> Dictionary:
	_tree = tree
	_world = world
	_player = player
	_camera_rig = camera_rig
	_game = tree.root.get_node_or_null(^"Game")
	if not await _preflight():
		return _result()

	var before_records := (_game.get("placed_buildings") as Array).size()
	_house_record_start = before_records
	var before_wood := _item_count("wood")
	var before_stone := _item_count("stone")

	var first: Variant = await _place_current("floor")
	if first == null:
		return _result()
	var floor_a: Vector3 = first
	if floor_a.distance_to(_preflight_first_floor) > POSITION_EPSILON:
		_fail("first paid Floor drifted from the no-spend preflight anchor %s to %s" % [_preflight_first_floor, floor_a])
		return _result()
	var floor_targets: Array[Vector3] = [
		floor_a + Vector3(2, 0, 0),
		floor_a + Vector3(0, 0, 2),
		floor_a + Vector3(2, 0, 2),
	]
	for target in floor_targets:
		if not await _move_ghost_to(target):
			return _result()
		if await _place_current("floor") == null:
			return _result()
	transcript.append("repeat-placed four paid floors from one Floor selection")

	# Keep both side edges open. The roof stance route stays on this open exterior
	# ring and was walked during no-spend preflight before the first Floor.
	if not await _turn_camera_toward(HOUSE_AIM_DIRECTION):
		return _result()
	var door_target := floor_a + Vector3(0, 0, -1)
	if not await _select_piece("door"):
		return _result()
	if not await _move_ghost_to(door_target):
		return _result()
	if await _place_current("door") == null:
		return _result()

	var wall_targets: Array[Vector3] = [
		floor_a + Vector3(2, 0, -1),
		floor_a + Vector3(0, 0, 3),
		floor_a + Vector3(2, 0, 3),
	]
	if not await _select_piece("wall"):
		return _result()
	for wall_target in wall_targets:
		if not await _move_ghost_to(wall_target):
			return _result()
		if await _place_current("wall") == null:
			return _result()

	# Work the exterior ring in the exact order proved by no-spend preflight:
	# rear pair while already outside its edge, then the front pair. No transfer
	# crosses the floor footprint or a wall/door line.
	var rear_roofs: Array[Vector3] = [floor_a + Vector3(2, 0, 2), floor_a + Vector3(0, 0, 2)]
	for floor_target in rear_roofs:
		if not await _place_roof_from_exterior(floor_target, HOUSE_AIM_DIRECTION, "rear-exterior"):
			return _result()
	transcript.append("placed two supported rear roofs from short rear-exterior stances")

	# The front row is aimed at from the OTHER side, facing back at the house.
	#
	# GATEB-COORD. Both pairs used to be placed facing `HOUSE_AIM_DIRECTION`,
	# and for the rear row that is right -- the stance lands outside the north
	# edge. For the FRONT row the same facing puts the stance three metres the
	# wrong way, which is on top of the floor the shell now encloses: the
	# trainer circled the finished house for three full attempts trying to
	# reach a spot inside it. The front row's exterior is the south side, so
	# that is where this stands, facing back.
	#
	# The roof ANCHOR does not move with the facing --
	# `build_snap_contract.gd::_add_supported_roofs()` corrects by the
	# SUPPORT's yaw, not the player's -- so `roof_target` is unchanged and the
	# ghost still snaps to the same supported candidate.
	#
	# The crossing goes round the WEST flank, which is level ground, rather
	# than whichever way the navigator's wall-following picks: left to itself
	# it went round the east side, off the Practice Meadow plateau, and down
	# onto ground four metres lower that it could not climb back up. Only the
	# first of the pair needs it; the second is already there.
	var front_roofs: Array[Vector3] = [floor_a + Vector3(2, 0, 0), floor_a]
	var west_of_the_house: Array[Vector3] = [
		floor_a + Vector3(-4, 0, 2),
		floor_a + Vector3(-4, 0, -4),
	]
	for floor_target in front_roofs:
		if not await _place_roof_from_exterior(floor_target, -HOUSE_AIM_DIRECTION,
				"front-exterior", west_of_the_house):
			return _result()
		west_of_the_house = []
	transcript.append("placed two supported front roofs from the same open exterior ring")

	var wall_positions: Array[Vector3] = wall_targets.duplicate()
	transcript.append("placed one doorway and three wall pieces through the catalogue and snap contract")

	var built_records := (_game.get("placed_buildings") as Array).size() - before_records
	if built_records != 12:
		_fail("house sequence should add 12 records before dismantle, added %d" % built_records)
		return _result()
	if _item_count("wood") != before_wood - 39 or _item_count("stone") != before_stone - 34:
		_fail("paid house did not spend exact natural-material cost (wood %d->%d, stone %d->%d)" % [
			before_wood, _item_count("wood"), before_stone, _item_count("stone")])
		return _result()

	# The AIM points and the PLACED positions are not the same point.
	# `wall_targets` above are the grid cells the ghost is aimed at;
	# `build_snap_contract.gd` then seats the piece half its own thickness off
	# that, exactly as `_planned_house_steps()` accounts for with `wall_c`. The
	# dismantle check compares against where the wall actually STANDS, so it
	# needs the same correction -- without it the highlight was right and the
	# comparison was 0.11m out, which is `POSITION_EPSILON` plus a hair.
	var wall_seat := BUILD_SNAP._thickness_correction(BUILD_SNAP.WALL_Z_CENTER, 0.0)
	var aimed_wall := _outside_wall_for_camera(wall_positions, floor_a + Vector3(1, 0, 1))
	if not await _dismantle_aimed_wall(aimed_wall + wall_seat):
		return _result()
	if not await _cancel_and_resume():
		return _result()
	transcript.append("cancelled Build and resumed parsed-controller movement")
	return _result()


func _preflight() -> bool:
	if _game == null or _world == null or _player == null or _camera_rig == null:
		_fail("segment wiring is incomplete")
		return false
	if bool(_game.get("free_build")):
		_fail("Gate A build evidence must run in paid mode")
	if str(_game.get("pending_build")) != "":
		_fail("segment must start in exploration with no armed build piece")
	if _item_count("wood") < 39 or _item_count("stone") < 34:
		_fail("caller has insufficient natural materials: need 39 wood and 34 stone")
	_resolve_move_bindings()
	if not failures.is_empty():
		return false

	# The caller must bring the real player to the Village Square through ordinary
	# exploration first. Once there, this follows the authored road one leg at a
	# time, rather than cutting a synthetic diagonal through settlement collision.
	var route_entry: Vector2 = BUILD_ROUTE_XZ.front()
	if _flat_distance(_player.global_position, Vector3(route_entry.x, 0.0, route_entry.y)) > BUILD_ROUTE_ENTRY_EPSILON:
		_fail("build segment must begin at the Village Square route entry through ordinary exploration")
		return false
	for i in range(1, BUILD_ROUTE_XZ.size()):
		var waypoint := BUILD_ROUTE_XZ[i]
		if not await _walk_to(Vector3(waypoint.x, _player.global_position.y, waypoint.y),
				"Practice Meadow road waypoint %d" % i):
			_fail("controller could not follow the documented Village Square-to-Practice Meadow road")
			return false
		if not _player.is_on_floor():
			_fail("controller left the ground on Practice Meadow road waypoint %d" % i)
			return false
	if _flat_distance(_player.global_position, Vector3(BUILD_PATCH_XZ.x, 0.0, BUILD_PATCH_XZ.y)) > BUILD_PATCH_APPROACH_EPSILON:
		_fail("controller stopped outside the documented build patch")
		return false
	if not _player.is_on_floor():
		_fail("controller arrival did not leave the player grounded on the documented Meadows patch")
		return false

	# FACE THE AUTHORED DIRECTION BEFORE THE GHOST IS READ.
	#
	# GATEB-COORD. The ghost forms `PLACE_AHEAD` metres along the CAMERA's
	# forward, and until now the camera was left wherever the walk to the patch
	# happened to end -- so the whole house landed somewhere different on every
	# run, five or six metres from the documented clearing as often as not. That
	# is what made this segment fail differently every time it was driven: one
	# run could not reach a front-roof stance because the house had drifted onto
	# ground that falls away five metres (the player stood at y=-2.0 trying to
	# reach a stance at y=3.0), the next could not highlight a wall.
	#
	# `HOUSE_AIM_DIRECTION` is the direction `_planned_house_steps()` is already
	# written for -- its own comment says "this exact house sequence's roofs all
	# resolve at yaw 0". Facing it here is what makes that true rather than
	# hoped for, and puts the house on the authored, vetted patch every run.
	if not await _turn_camera_toward(HOUSE_AIM_DIRECTION):
		return false

	# The green, live Floor ghost seeds the whole no-spend plan. It is armed
	# through the public catalogue and read only as the placer's rendered legality
	# state; no test-side build transaction occurs.
	if not await _select_piece("floor"):
		return false
	await _settle(8)
	# STAND ON THE PATCH AGAIN, facing the authored direction, before the ghost
	# is read.
	#
	# GATEB-COORD. Opening the catalogue is not instantaneous: it waits for the
	# world to stop swallowing hotkeys, and what swallows them out here is a
	# wild creature picking a fight. A fight moves the player. So the arrival
	# checks above could pass, a Bramblebun could engage, and the ghost that
	# seeds the ENTIRE house plan would then form from wherever the fight left
	# the trainer standing -- which is why consecutive runs put the house at
	# (28,-48), (30,-44), (34,-36) and (36,-38) from the same authored patch,
	# and why one of them ended up trying to reach a roof stance across a
	# five-metre drop.
	if not await _stand_on_the_patch_facing_the_house():
		return false
	var placer := _tree.get_first_node_in_group(&"build_placer")
	var ghost := placer.get("_ghost") as Node3D if placer != null else null
	if placer == null or ghost == null or not bool(placer.get("_ghost_ok")):
		_fail("the documented patch has no legal first Floor ghost; do not spend materials there")
		return false
	_preflight_first_floor = ghost.global_position
	if not await _preflight_all_planned_anchors(placer):
		return false
	transcript.append("walked by controller to the Practice Meadow patch; all twelve planned anchors were green/reachable before spending")
	return true


## The stance the first paid Floor is placed from, re-established and held.
func _hold_the_first_floor_stance() -> bool:
	for attempt in 3:
		if not await _turn_camera_toward(HOUSE_AIM_DIRECTION):
			return false
		var forward := -(_camera_rig.call("planar_basis") as Basis).z
		var stance := _preflight_first_floor - forward * PLACE_AHEAD
		if not await _walk_to(stance, "preflight Floor stance (attempt %d)" % (attempt + 1)):
			return false
		await _settle(12)
		if _flat_distance(_player.global_position, stance) <= MOVE_EPSILON * 2.0:
			return true
		transcript.append("something moved the trainer off the first Floor stance (%s); "
			% str(_player.global_position.round()) + "walking back")
	_fail("could not hold the first Floor stance long enough to read its ghost")
	return false


## Back to the documented patch centre, facing `HOUSE_AIM_DIRECTION`. Both
## halves are re-established rather than assumed: whatever moved the player
## also turned the camera with them.
func _stand_on_the_patch_facing_the_house() -> bool:
	var patch := Vector3(BUILD_PATCH_XZ.x, _player.global_position.y, BUILD_PATCH_XZ.y)
	for attempt in 3:
		# The requirement is the patch, not a pinpoint: `_preflight()` accepts
		# `BUILD_PATCH_APPROACH_EPSILON`, so asking the navigator for 16cm here
		# would fail on ground that is perfectly good to build from.
		if not await _walk_to(patch, "documented build patch centre",
				BUILD_PATCH_APPROACH_EPSILON * 0.8):
			return false
		if not await _turn_camera_toward(HOUSE_AIM_DIRECTION):
			return false
		await _settle(12)
		if _flat_distance(_player.global_position, patch) <= BUILD_PATCH_APPROACH_EPSILON:
			return true
		transcript.append("something moved the trainer off the build patch (%s); walking back"
			% str(_player.global_position.round()))
	_fail("could not stand on the documented build patch to read the first ghost; "
		+ "the trainer keeps being moved off it (now at %s)" % str(_player.global_position.round()))
	return false


func _preflight_all_planned_anchors(placer: Node) -> bool:
	# Future structural targets have no real supports until the paid sequence
	# exists, so this asks BuildPlacer's public, side-effect-free preview against
	# test-local planned records. The live ghost uses this same method every
	# frame; records here never reach GameState or the scene tree.
	if not placer.has_method("preview_placement"):
		_fail("BuildPlacer exposes no public planned-placement preview")
		return false
	if not await _stow_piece_for_travel():
		return false
	var planned: Array[Dictionary] = []
	# The plan is REBASED on the first floor this preflight itself resolves.
	#
	# GATEB-COORD. `_preflight_first_floor` is read off the LIVE ghost, from
	# wherever the player happened to be standing when the patch was reached,
	# and `build_grid.gd::snap_to_grid(raw, ground_y)` takes a ground-clamped
	# piece's height from the raw point being aimed at rather than from the
	# resolved cell centre. So the same cell resolves a little differently from
	# a different stance, and every expectation derived from that first reading
	# was out by that difference -- most visibly on the door, which correctly
	# snapped to a floor edge and inherited the floor's real height:
	#
	#   planned door ghost resolves to (36.0, -1.261, -38.889) instead of
	#   (36.0, -1.126, -38.889) (off by 0.135: xz 0.000, snapped_to_neighbour=true)
	#
	# The four floors agreed with each other to the millimetre; only the basis
	# was stale. Rebasing on step 0's own resolved position makes the whole plan
	# internally consistent, and every anchor after it snaps to a neighbour and
	# inherits its height exactly -- so the check below stays exact rather than
	# being loosened around the discrepancy.
	var steps := _planned_house_steps(_preflight_first_floor)
	var index := -1
	while index + 1 < steps.size():
		index += 1
		var step: Dictionary = steps[index]
		if not await _turn_camera_toward(HOUSE_AIM_DIRECTION):
			return false
		var id := str(step.get("id", ""))
		var target: Vector3 = step.get("position", Vector3.INF)
		var require_structural := bool(step.get("require_structural", false))
		var forward := -(_camera_rig.call("planar_basis") as Basis).z
		var stance := target - forward * PLACE_AHEAD
		if not await _walk_to(stance, "public %s preflight stance" % id):
			_fail("controller could not reach the public %s preflight stance at %s" % [id, stance])
			return false
		await _settle(4)
		var raw := _player.global_position + forward * PLACE_AHEAD
		var preview: Dictionary = placer.call("preview_placement", _game, id, raw, planned)
		if not bool(preview.get("has_ground", false)) or not bool(preview.get("ok", false)):
			_fail("planned %s anchor at %s is not green before spending: %s" % [id, target, str(preview.get("reason", "no ground"))])
			return false
		var resolved: Vector3 = preview.position
		if index == 0:
			# Step 0 IS the basis. Adopt what it actually resolved to and
			# rebuild every expectation from it, including the one the paid
			# sequence will use.
			if resolved.distance_to(target) > POSITION_EPSILON:
				transcript.append(("rebased the house plan on the preflight's own first "
					+ "floor: %s rather than the live ghost's %s") % [str(resolved), str(target)])
				_preflight_first_floor = resolved
				steps = _planned_house_steps(resolved)
				target = (steps[0] as Dictionary).get("position", resolved)
		if resolved.distance_to(target) > POSITION_EPSILON:
			_fail(("planned %s ghost resolves to %s instead of %s (off by %.3f: "
				+ "xz %.3f, y %.3f). snapped_to_neighbour=%s, stance wanted %s and the "
				+ "player stands at %s (%.3f off), so the raw preview point was %s")
				% [id, resolved, target, resolved.distance_to(target),
					Vector2(resolved.x - target.x, resolved.z - target.z).length(),
					absf(resolved.y - target.y),
					str(preview.get("snapped_to_neighbour", false)),
					str(stance.round()), str(_player.global_position.round()),
					Vector2(stance.x - _player.global_position.x,
						stance.z - _player.global_position.z).length(),
					str(raw)])
			return false
		if require_structural != bool(preview.get("structural", false)):
			_fail("planned %s anchor structural=%s, expected %s" % [id, str(preview.get("structural", false)), str(require_structural)])
			return false
		planned.append({
			"id": id,
			"position": [resolved.x, resolved.y, resolved.z],
			"yaw_deg": float(preview.get("yaw_deg", 0.0)),
		})
		transcript.append("preflight green/reachable %s at %s" % [id, resolved])
	# Return to the original, legal Floor stance and rearm through the public
	# catalogue. This is still before the first place press.
	if not await _turn_camera_toward(HOUSE_AIM_DIRECTION):
		return false
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	if not await _walk_to(_preflight_first_floor - forward * PLACE_AHEAD, "return to the preflight Floor stance"):
		_fail("controller could not return to the preflight Floor stance")
		return false
	if not await _select_piece("floor"):
		return false
	# And stand there AGAIN. GATEB-COORD: arming through the catalogue waits
	# out whatever is swallowing hotkeys, and out here that is a wild creature
	# picking a fight -- which moves the player, and with them the ghost. Every
	# ghost read in this file re-establishes its stance after arming for the
	# same reason; this was the last one that did not.
	if not await _hold_the_first_floor_stance():
		return false
	var live_ghost := placer.get("_ghost") as Node3D
	if live_ghost != null and bool(placer.get("_ghost_ok")) \
			and _flat_distance(live_ghost.global_position, _preflight_first_floor) <= POSITION_EPSILON \
			and live_ghost.global_position.distance_to(_preflight_first_floor) > POSITION_EPSILON:
		# Same grid cell, different height. GATEB-COORD: a ground-clamped floor
		# takes its Y from the raw point being aimed at rather than the
		# resolved cell centre (`build_grid.gd::snap_to_grid`), and standing
		# back on a stance is only ever good to `MOVE_EPSILON`, so the live
		# ghost can sit a few centimetres off the one the preflight read. This
		# ghost is where the first paid Floor is about to go, so it becomes the
		# basis -- nothing has been spent yet, and everything downstream is
		# derived from the floor that actually lands.
		transcript.append("live Floor ghost re-formed %.3fm below/above the preflight anchor; "
			% absf(live_ghost.global_position.y - _preflight_first_floor.y)
			+ "adopting %s as the house basis" % str(live_ghost.global_position))
		_preflight_first_floor = live_ghost.global_position
	if live_ghost == null or not bool(placer.get("_ghost_ok")) \
			or live_ghost.global_position.distance_to(_preflight_first_floor) > POSITION_EPSILON:
		_fail("returning to the preflight Floor stance did not restore the green live ghost "
			+ "(ghost %s, wanted %s, player at %s)" % [
				str(live_ghost.global_position) if live_ghost != null else "<none>",
				str(_preflight_first_floor), str(_player.global_position.round())])
		return false
	return true


## BUILD-KIT-3: door/wall/roof anchors get `BUILD_SNAP._thickness_correction`
## added, same as a real placement now does (see that function's own header
## on `build_snap_contract.gd`) -- every structural piece in this exact house
## sequence places at yaw 0 (the front/back walls are always found before the
## side walls in `_add_supported_roofs`'s own wall scan, confirmed by hand
## against its iteration order), so one correction per family covers all of
## them. Floor steps are untouched: `_add_floor_edges` never corrects the
## floor anchor itself, only what snaps to its edges.
func _planned_house_steps(floor_a: Vector3) -> Array[Dictionary]:
	var wall_c := BUILD_SNAP._thickness_correction(BUILD_SNAP.WALL_Z_CENTER, 0.0)
	var roof_c := BUILD_SNAP._thickness_correction(BUILD_SNAP.ROOF_Z_CENTER, 0.0)
	return [
		{"id": "floor", "position": floor_a, "require_structural": false},
		{"id": "floor", "position": floor_a + Vector3(2, 0, 0), "require_structural": false},
		{"id": "floor", "position": floor_a + Vector3(0, 0, 2), "require_structural": false},
		{"id": "floor", "position": floor_a + Vector3(2, 0, 2), "require_structural": false},
		{"id": "door", "position": floor_a + Vector3(0, 0, -1) + wall_c, "require_structural": true},
		{"id": "wall", "position": floor_a + Vector3(2, 0, -1) + wall_c, "require_structural": true},
		{"id": "wall", "position": floor_a + Vector3(0, 0, 3) + wall_c, "require_structural": true},
		{"id": "wall", "position": floor_a + Vector3(2, 0, 3) + wall_c, "require_structural": true},
		{"id": "roof", "position": floor_a + Vector3(2, BUILD_SNAP.ROOF_Y, 2) + roof_c, "require_structural": true},
		{"id": "roof", "position": floor_a + Vector3(0, BUILD_SNAP.ROOF_Y, 2) + roof_c, "require_structural": true},
		{"id": "roof", "position": floor_a + Vector3(2, BUILD_SNAP.ROOF_Y, 0) + roof_c, "require_structural": true},
		{"id": "roof", "position": floor_a + Vector3(0, BUILD_SNAP.ROOF_Y, 0) + roof_c, "require_structural": true},
	]


func _select_piece(id: String) -> bool:
	var menu := await _open_the_catalogue()
	if menu == null:
		return false

	for category_try in 5:
		var cells := _visible_build_cells(menu)
		var wanted := -1
		var focused := -1
		var focus_owner := _tree.root.gui_get_focus_owner()
		for i in cells.size():
			if _cell_id(cells[i]) == id:
				wanted = i
			if cells[i] == focus_owner:
				focused = i
		if wanted >= 0:
			if focused < 0:
				_fail("Build catalogue has no controller-focused cell")
				return false
			var action := &"ui_right" if wanted >= focused else &"ui_left"
			for step in absi(wanted - focused):
				await _tap_action(action)
			await _tap_action(&"ui_accept")
			await _settle(8)
			if str(_game.get("pending_build")) != id:
				_fail("controller selected %s but live pending selection is '%s'" % [id, str(_game.get("pending_build"))])
				return false
			if _open_build_menu() != null:
				_fail("Build catalogue stayed open after selecting %s" % id)
				return false
			return true
		# CONTROLLER-MAP moved the catalogue's category cycle off the rotate
		# triggers and onto LB/RB. `build_menu.gd` reads `menu_tab_left`/
		# `menu_tab_right` and says so in its own comment: "the rotate actions
		# used to double as category ... a trigger that also changed category
		# would be the wrong thing". This helper was still pressing
		# `build_rotate_right`, so nothing outside the first category could be
		# selected at all -- measured: "could not reach 'creature_bed' through
		# controller catalogue navigation".
		await _tap_action(&"menu_tab_right")
		await _settle(8)
	_fail("could not reach %s through controller category/cell navigation" % id)
	return false


## Everything `playground_hud.gd::_world_input_allowed()` reads, in one line.
func _world_input_state() -> String:
	var arbiter := _tree.get_first_node_in_group(&"interaction_arbiter")
	var manager := _world.get_node_or_null(^"CombatManager")
	var director := _world.get_node_or_null(^"EncounterDirector")
	return "fighting=%s, trainer_battle=%s, arbiter enabled=%s, input owner=%s, paused=%s" % [
		str(manager != null and bool(manager.call("is_fighting"))),
		str(director != null and bool(director.call("trainer_battle_active"))),
		str(arbiter == null or bool(arbiter.call("enabled"))),
		str(INPUT_OWNER.current(_tree) != null),
		str(_tree.paused)]


## True once nothing is swallowing world hotkeys. False means it never cleared.
func _wait_until_the_world_will_hear_a_press() -> bool:
	var arbiter := _tree.get_first_node_in_group(&"interaction_arbiter")
	var manager := _world.get_node_or_null(^"CombatManager")
	var director := _world.get_node_or_null(^"EncounterDirector")
	for _i in 5400:
		var busy := (manager != null and bool(manager.call("is_fighting"))) \
			or (director != null and bool(director.call("trainer_battle_active"))) \
			or (arbiter != null and not bool(arbiter.call("enabled"))) \
			or INPUT_OWNER.current(_tree) != null
		if not busy:
			return true
		await _tree.physics_frame
	_fail("the world never stopped swallowing hotkeys (%s)" % _world_input_state())
	return false


## Open the build catalogue the way a CONTROLLER actually can.
##
## `build_open` lost its pad button to the owner's fourteen-button map
## (CONTROLLER-MAP; `playground_hud.gd::_hammer_opens_the_catalogue` says so in
## its own words: "hammer + interact is the ONLY pad route into build mode").
## This helper still tapped `build_open`, which has nothing but a keyboard B
## bound to it -- so `_tap_action` failed the InputMap lookup and every
## controller build segment reported "Build did not open from the parsed
## controller build_open press". The menu was fine; the harness was pressing a
## button the pad no longer has.
##
## The keyboard action is still preferred when it HAS a pad binding, so this
## goes back to one press the day the map changes again.
## GATEB-COORD: retried, and only after the world will actually hear the press.
##
## `playground_hud.gd::_read_world_hotkeys()` is gated by
## `_world_input_allowed()`, which refuses while a fight is running, while the
## interaction arbiter is asleep (a conversation, a naming prompt, a fade) or
## while a panel owns input. The Practice Meadow patch is open meadow with wild
## creatures in it, so a creature engaging the player as the segment reaches
## the patch swallowed the only pad route into build mode -- intermittently,
## and reported as the bare line "Build did not open", with the arbiter winner
## reading <none> because a fight silences it too.
##
## A player waits for the fight to end and presses again. So does this.
func _open_the_catalogue() -> Node:
	if _open_build_menu() != null:
		return _open_build_menu()
	for attempt in 4:
		# The armed ghost has to be stowed FIRST. On the pad `build_place` and
		# `interact` are the same physical X (project.godot: joypad button 2),
		# so with a piece armed the press that would reopen the catalogue puts
		# another floor down instead -- and `build_placer.gd` disables the
		# interaction arbiter for the duration, which makes
		# `_world_input_allowed()` refuse the hammer route outright. The
		# keyboard's `build_open` has its own carve-out for this (BUILD-FLOW:
		# "Start reopens the dedicated catalogue while a ghost remains armed");
		# the pad's answer is the one a player has, which is to cancel with B
		# and press X again.
		if not await _stow_piece_for_travel():
			return null
		if not await _wait_until_the_world_will_hear_a_press():
			break
		if _joy_binding_for(&"build_open") != null:
			await _tap_action(&"build_open")
		else:
			if not await _hammer_in_hand():
				return null
			await _tap_action(&"interact")
		await _settle(30)
		if _open_build_menu() != null:
			return _open_build_menu()
		transcript.append("Build did not open on press %d (%s); waiting and pressing again"
			% [attempt + 1, _world_input_state()])
		await _settle(90)
	var menu := _open_build_menu()
	if menu == null:
		# GATEB-COORD: say WHO took the button. `_hammer_opens_the_catalogue()`
		# forfeits the interact press to any ACTIONABLE arbiter winner, so a
		# wandering creature's "Engage" or a nearby harvest node's "Chop" is
		# enough to swallow the only pad route into build mode -- and it is
		# nondeterministic, which is exactly the shape of failure a bare
		# "Build did not open" cannot be diagnosed from.
		var arbiter := _tree.get_first_node_in_group(&"interaction_arbiter")
		var who: Variant = arbiter.call("winning_provider") if arbiter != null else null
		_fail(("Build did not open from the controller's own route into the catalogue "
			+ "(equipped=%s, arbiter winner=%s offering %s, %s)")
			% [str(_game.get("equipped_tool")),
				str((who as Node).name) if who is Node and is_instance_valid(who as Object)
					else "<none>",
				str(arbiter.call("winner")) if arbiter != null else "<no arbiter>",
				_world_input_state()])
	return menu


## The hammer, drawn from the quick bar. It is the build TOOL under
## CONTROLLER-MAP, and the village hands it over (`camp_hammer_given`) before
## any of this segment's work is reachable in an ordinary run.
##
## GATEB-COORD: this used to GRANT one when the caller had none, and
## `tests/test_gate_a_build_segment_contract.gd` bans exactly that -- "reusable
## segment must not use bypass 'inventory.call(\"add\"'". The ban is right:
## this segment's whole claim is that every change to play state came through
## a physical joypad event, and a satchel it filled itself is not that. Every
## real caller already has the hammer (the village hands it over; the tail
## smoke stages it with the other tools), so the absence of one is a caller
## defect and is now reported as one.
func _hammer_in_hand() -> bool:
	if str(_game.get("equipped_tool")) == "hammer":
		return true
	var inventory: RefCounted = _game.get("inventory")
	if int(inventory.call("count", "hammer")) <= 0:
		_fail("there is no hammer in the satchel; the village's gift (camp_hammer_given) "
			+ "comes before any of this segment's work and is not this segment's to grant")
		return false
	var slot := int(_game.call("hotbar_slot_of", "hammer")) if _game.has_method("hotbar_slot_of") else -1
	if slot < 0:
		slot = HAMMER_SLOT
		if not bool(_game.call("assign_hotbar", slot, "hammer")):
			_fail("the hammer could not be put on the quick bar, which is how build mode is entered")
			return false
	await _tap_action(HOTBAR_ACTIONS[slot])
	await _settle(8)
	if str(_game.get("equipped_tool")) != "hammer":
		_fail("the quick-bar press did not put the hammer in hand; build mode cannot be opened")
		return false
	return true


func _joy_binding_for(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event
	return null


func _place_current(expected_id: String) -> Variant:
	var before := (_game.get("placed_buildings") as Array).size()
	await _tap_action(&"build_place")
	await _settle(5)
	var records: Array = _game.get("placed_buildings") as Array
	if records.size() != before + 1:
		_fail("fresh controller Place edge for %s added %d records" % [expected_id, records.size() - before])
		return null
	var record := records.back() as Dictionary
	if str(record.get("id", "")) != expected_id:
		_fail("expected newly placed %s, got %s" % [expected_id, str(record.get("id", ""))])
		return null
	if str(_game.get("pending_build")) != expected_id:
		_fail("repeat placement lost %s selection" % expected_id)
		return null
	return _record_position(record)


## GATEB-COORD: through `stick_navigator.gd`, like `_walk_to()` beside it.
##
## This was the segment's second straight-line walker, and it is the one that
## runs while the house is going UP -- so by the time it walks to the first
## wall's stance there are four placed floors standing between it and the
## target. It stopped dead against them:
##
##   controller movement could not line the ghost up with (32.0, 0.264, -41.0)
##
## The precision is unchanged: the navigator is asked for the same
## `MOVE_EPSILON`, because where the player stands is what decides where the
## ghost lands.
func _move_ghost_to(target: Vector3, aim_offset: Vector3 = Vector3.ZERO) -> bool:
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	var wanted_player := target + aim_offset - forward * PLACE_AHEAD
	if _nav == null:
		_nav = NAVIGATOR.new(_tree, _player, _camera_rig, _parse_move_stick)
	var budget := maxi(WALK_FRAME_FLOOR,
		240 + int(_player.global_position.distance_to(wanted_player) * 60.0))
	var arrived: bool = await _nav.walk_to(wanted_player, budget, MOVE_EPSILON)
	_release_move_stick()
	await _settle(3)
	if arrived:
		return true
	_fail("controller movement could not line the ghost up with %s (wanted to stand at %s, "
		% [target, str(wanted_player.round())] + "stopped %.2fm short at %s)" % [
			Vector2(wanted_player.x - _player.global_position.x,
				wanted_player.z - _player.global_position.z).length(),
			str(_player.global_position.round())])
	return false


## `via` is walked before the stance, in order.
##
## GATEB-COORD: the front pair's exterior is on the far side of a house that is
## by then closed with a door and three walls, so getting there means going
## round it -- and `stick_navigator.gd` finds its way by sliding along whatever
## it is pressed against, which took the trainer round the EAST side, off the
## Practice Meadow plateau, and down onto ground four metres lower that it then
## could not climb back up:
##
##   controller could not walk to the front-exterior exterior Roof stance
##   (stopped 3.10m short at (35.0, -1.0, -40.0), wanted (32.0, 3.0, -40.0))
##
## The west flank is level, so the caller routes the crossing that way rather
## than leaving the choice to a wall-follower that cannot see a cliff.
func _place_roof_from_exterior(floor_target: Vector3, inward: Vector3, side: String,
		via: Array[Vector3] = []) -> bool:
	# A roof's production snap candidate needs a floor plus any adjacent wall or
	# doorway. Build one open row at a time: this lets the player aim from that
	# row's exterior without walking around, through, or across a closed shell.
	if not await _stow_piece_for_travel():
		return false
	if not await _turn_camera_toward(inward):
		return false
	# BUILD-KIT-3: this exact house sequence's roofs all resolve at yaw 0 (see
	# `_planned_house_steps`'s own comment on why) so the same correction
	# applies to every call site.
	var roof_c := BUILD_SNAP._thickness_correction(BUILD_SNAP.ROOF_Z_CENTER, 0.0)
	var roof_target := Vector3(floor_target.x, floor_target.y + BUILD_SNAP.ROOF_Y, floor_target.z) + roof_c
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	var wanted_player := roof_target - forward * PLACE_AHEAD
	for waypoint: Vector3 in via:
		if not await _walk_to(waypoint, "%s Roof approach waypoint %s"
				% [side, str(waypoint.round())], 1.0):
			return false
	transcript.append(("%s Roof: floor target %s -> roof anchor %s; camera forward %s; "
		+ "stance %s; trainer starts at %s") % [side, str(floor_target.round()),
		str(roof_target.round()), str(forward.snapped(Vector3(0.01, 0.01, 0.01))),
		str(wanted_player.round()), str(_player.global_position.round())])
	if not await _walk_to(wanted_player, "%s exterior Roof stance" % side):
		_fail("controller could not reach the %s exterior Roof stance" % side)
		return false
	if not await _select_piece("roof"):
		return false
	# STAND THERE AGAIN. GATEB-COORD: opening the catalogue waits for the world
	# to stop swallowing hotkeys, and out here that means waiting out a wild
	# creature's fight -- which moves the player. The stance was reached and
	# then abandoned, and the ghost, which forms `PLACE_AHEAD` along the camera
	# from wherever the trainer now is, resolved six metres and five vertical
	# metres away from the anchor it was supposed to snap to:
	#
	#   rear-exterior exterior Roof ghost resolved to (38.0, -1.606, -40.0)
	#   instead of supported anchor (32.0, 3.590, -42.558)
	if not await _walk_to(wanted_player, "%s exterior Roof stance (after arming)" % side):
		_fail("controller could not hold the %s exterior Roof stance" % side)
		return false
	if not await _turn_camera_toward(inward):
		return false
	if not await _assert_live_roof_ghost(roof_target, side):
		return false
	var placed_roof: Variant = await _place_current("roof")
	if placed_roof == null:
		return false
	var placed_roof_position: Vector3 = placed_roof
	if placed_roof_position.distance_to(roof_target) > POSITION_EPSILON:
		_fail("controller %s Roof selection placed at %s instead of supported anchor %s" % [side, placed_roof, roof_target])
		return false
	return true


func _assert_live_roof_ghost(roof_target: Vector3, side: String) -> bool:
	await _settle(8)
	var placer := _tree.get_first_node_in_group(&"build_placer")
	var ghost := placer.get("_ghost") as Node3D if placer != null else null
	if placer == null or ghost == null or not bool(placer.get("_ghost_ok")):
		_fail("%s exterior Roof stance has no green live ghost" % side)
		return false
	if ghost.global_position.distance_to(roof_target) > POSITION_EPSILON:
		_fail("%s exterior Roof ghost resolved to %s instead of supported anchor %s" % [side, ghost.global_position, roof_target])
		return false
	transcript.append("%s exterior Roof stance reached a green live ghost at %s" % [side, roof_target])
	return true


func _turn_camera_toward(world_direction: Vector3) -> bool:
	var wanted := Vector2(world_direction.x, world_direction.z).normalized()
	if wanted.length_squared() < 0.01:
		_fail("roof camera orientation received no planar direction")
		return false
	for frame in MOVE_FRAME_LIMIT:
		var forward := -(_camera_rig.call("planar_basis") as Basis).z
		var flat := Vector2(forward.x, forward.z).normalized()
		if flat.dot(wanted) >= 0.995:
			_release_look()
			return true
		# The camera applies a positive look-right axis as a rightward yaw. The
		# signed planar cross product tells the parsed controller which physical
		# direction closes the remaining angle; no transform is written here.
		var turn_right := -Vector3(forward.x, 0.0, forward.z).cross(world_direction).y > 0.0
		_release_look()
		Input.action_press(&"look_right" if turn_right else &"look_left", 1.0)
		await _tree.physics_frame
	_release_look()
	_fail("controller right stick could not orient the roof camera toward the exterior ring")
	return false


func _stow_piece_for_travel() -> bool:
	if str(_game.get("pending_build")) == "":
		return true
	await _tap_action(&"build_cancel")
	await _settle(6)
	if str(_game.get("pending_build")) != "":
		_fail("visible Build Cancel did not stow the armed piece before controller travel")
		return false
	if _open_build_menu() != null:
		_fail("stowing placement unexpectedly opened the Build catalogue")
		return false
	return true


func _dismantle_aimed_wall(target_position: Vector3) -> bool:
	var records_before: Array = (_game.get("placed_buildings") as Array).duplicate(true)
	var neighbours_before := _record_fingerprints_except(records_before, "wall", target_position)
	var wood_before := _item_count("wood")
	var stone_before := _item_count("stone")
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	var wanted_player := target_position - forward * 2.0
	if not await _stow_piece_for_travel():
		return false
	if not await _walk_to(wanted_player, "aimed dismantle stance"):
		return false
	# Dismantle highlighting belongs to the live placer and therefore requires
	# Build to be armed. Re-enter through the public catalogue only after the
	# travel is complete; selecting Wall spends nothing until Place is pressed.
	if not await _select_piece("wall"):
		return false
	if not await _aim_until_the_wall_lights_up(target_position, forward):
		return false
	await _tap_action(&"build_dismantle")
	await _settle(6)
	var records_after: Array = _game.get("placed_buildings") as Array
	if records_after.size() != records_before.size() - 1:
		_fail("Dismantle removed %d records instead of exactly one" % (records_before.size() - records_after.size()))
		return false
	if _record_fingerprints(records_after) != neighbours_before:
		_fail("Dismantle changed a neighbour instead of only the aimed wall")
		return false
	if _item_count("wood") != wood_before + 6 or _item_count("stone") != stone_before + 2:
		_fail("aimed paid Wall did not refund exactly 6 wood and 2 stone")
		return false
	transcript.append("highlighted and dismantled one aimed wall; exact refund and every neighbour verified")
	return true


## Shuffle until the intended wall is the one the placer is highlighting.
##
## GATEB-COORD. `build_placer.gd` decides what to dismantle by what the player
## is AIMED at, and the stance this walks to is only good to `MOVE_EPSILON` --
## 16cm, which over a two-metre aim is about four and a half degrees and is
## easily the difference between this wall, its neighbour, and nothing at all.
## One press from one spot reported the whole house a failure:
##
##   construction aim did not visibly highlight the intended wall before Y
##
## A player edges over until the piece lights up. Four stand-off distances are
## tried along the same approach line, so the aim changes without the segment
## walking round to a different face and dismantling a different wall.
func _aim_until_the_wall_lights_up(target_position: Vector3, forward: Vector3) -> bool:
	var last := "nothing highlighted"
	for stand_off: float in [2.0, 1.6, 2.4, 1.3]:
		if not await _walk_to(target_position - forward * stand_off,
				"aimed dismantle stance %.1fm out" % stand_off):
			return false
		# LOOK at it, from where the player actually ended up.
		# `build_placer.gd::_update_dismantle_target()` casts from the camera
		# through the centre of the screen, so the highlight follows the
		# CAMERA, not the stance -- and after walking the roof ring the rig is
		# not necessarily still facing the wall the stance was computed from.
		var to_wall := target_position - _player.global_position
		to_wall.y = 0.0
		if to_wall.length() > 0.2 and not await _turn_camera_toward(to_wall):
			return false
		await _settle(12)
		var highlighted := _highlighted_placed_piece()
		if highlighted != null and str(highlighted.get_meta("building_id", "")) == "wall" \
				and _flat_distance(highlighted.global_position, target_position) <= POSITION_EPSILON:
			return true
		last = ("nothing highlighted (%s)" % _what_the_dismantle_ray_hits()) \
			if highlighted == null else \
			"highlighted the %s at %s, %.2fm from the intended wall" % [
				str(highlighted.get_meta("building_id", "?")),
				str(highlighted.global_position.round()),
				_flat_distance(highlighted.global_position, target_position)]
		transcript.append("dismantle aim from %.1fm out: %s" % [stand_off, last])
	var eye := -(_camera_rig.call("planar_basis") as Basis).z
	_fail(("construction aim did not visibly highlight the intended wall at %s before Y, "
		+ "from any of four stand-off distances; last attempt %s. Player at %s, camera "
		+ "planar forward %s, %d pieces standing")
		% [str(target_position.round()), last, str(_player.global_position.round()),
			str(eye.snapped(Vector3(0.01, 0.01, 0.01))),
			_tree.get_nodes_in_group(PLACED_GROUP).size()])
	return false


## The ray `build_placer.gd::_update_dismantle_target()` casts, and what it
## runs into first.
##
## GATEB-COORD: that function decides what is highlighted by casting from the
## CAMERA through the centre of the screen, with no exclusions -- so in a
## third-person world the player's own body is a candidate for stopping it, and
## so is any creature standing between the camera and the wall. "Nothing
## highlighted" cannot distinguish those from a ray that reached nothing at
## all, and they want different answers.
func _what_the_dismantle_ray_hits() -> String:
	var viewport := _tree.root.get_viewport()
	var camera := viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return "no current Camera3D; the placer cannot cast at all"
	var centre := viewport.get_visible_rect().size * 0.5
	var from := camera.project_ray_origin(centre)
	var to := from + camera.project_ray_normal(centre) * 40.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return "the screen-centre ray from %s hits nothing in 40m" % str(from.round())
	var collider: Variant = hit.get("collider")
	var chain: Array[String] = []
	var node := collider as Node
	while node != null and chain.size() < 4:
		chain.append("%s%s" % [str(node.name),
			"[placed]" if node.is_in_group(PLACED_GROUP) else ""])
		node = node.get_parent()
	return "the screen-centre ray from %s hits %s at %s" % [
		str(from.round()), " < ".join(chain), str((hit.get("position") as Vector3).round())]


func _cancel_and_resume() -> bool:
	await _tap_action(&"build_cancel")
	await _settle(6)
	if str(_game.get("pending_build")) != "":
		_fail("Build Cancel left a piece armed")
		return false
	if _tree.paused or _open_build_menu() != null:
		_fail("Build Cancel did not restore the live Meadows world")
		return false
	var before := _player.global_position
	_parse_move_stick(0.0, -1.0)
	for i in 24:
		await _tree.physics_frame
	_release_move_stick()
	await _settle(4)
	if _flat_distance(before, _player.global_position) < 0.35:
		_fail("parsed controller movement did not resume after exiting Build")
		return false
	return true


## Travel one leg, around whatever is in the way -- see `stick_navigator.gd`.
##
## The straight-line version this replaces is still visible in the navigator's
## own easing constants: `EASE_METRES` 0.9 and `EASE_FLOOR` 0.32 came from here,
## because a leg that ends within `MOVE_EPSILON` (0.16m) needs the stick to ease
## off near the target and full deflection everywhere else.
##
## What is added is the detour. The documented Village Square-to-Practice-Meadow
## road runs past two fence runs (`data/config/village.json`, at [14,-20] and
## [19.5,-25.5], both "along the practice-meadow path"), and a straight stick
## vector between waypoints has no way past a fence post it happens to meet.
## GATEB-COORD: the budget comes from the leg, and the floor under it is
## generous on purpose. `MOVE_FRAME_LIMIT` on its own is six seconds, which is
## fine walking to an empty patch and nowhere near enough once the house is
## standing: the front-roof stances are on the far side of a building this
## segment has just put up, so getting there means walking AROUND four walls
## with a navigator that finds its way by sliding along them.
## `close_enough` defaults to the tight `MOVE_EPSILON` because most call sites
## here are placing a ghost, and where the player stands is what decides where
## the ghost lands. Walks that only need to BE somewhere pass their own, looser
## value -- asking for 16cm when 50 will do is how a walk fails on a pebble.
##
## Retried from a clean navigator state, up to three times. `stick_navigator.gd`
## picks which way to slide once per side and then commits, so an attempt that
## has orbited itself into a corner will keep orbiting; starting over re-runs
## the free-space probe from wherever it ended up, which is usually somewhere
## the first attempt could not see from.
func _walk_to(target: Vector3, purpose: String,
		close_enough: float = MOVE_EPSILON) -> bool:
	if _nav == null:
		_nav = NAVIGATOR.new(_tree, _player, _camera_rig, _parse_move_stick)
	for attempt in 3:
		var budget := maxi(WALK_FRAME_FLOOR,
			240 + int(_player.global_position.distance_to(target) * 60.0))
		_nav.reset()
		var arrived: bool = await _nav.walk_to(target, budget, close_enough)
		_release_move_stick()
		if arrived:
			return true
		transcript.append("attempt %d at the %s stopped %.2fm short at %s; starting over" % [
			attempt + 1, purpose,
			Vector2(target.x - _player.global_position.x,
				target.z - _player.global_position.z).length(),
			str(_player.global_position.round())])
		await _settle(30)
	_fail("controller could not walk to the %s (stopped %.2fm short at %s, wanted %s)" % [
		purpose,
		Vector2(target.x - _player.global_position.x,
			target.z - _player.global_position.z).length(),
		str(_player.global_position.round()), str(target.round())])
	return false


func _tap_action(action: StringName) -> void:
	var binding: InputEvent = null
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			binding = event
			break
	if binding == null:
		_fail("%s has no physical joypad binding" % action)
		return
	if binding is InputEventJoypadButton:
		var press := InputEventJoypadButton.new()
		press.button_index = (binding as InputEventJoypadButton).button_index
		press.pressed = true
		Input.parse_input_event(press)
		await _settle(2)
		var release := press.duplicate() as InputEventJoypadButton
		release.pressed = false
		Input.parse_input_event(release)
	else:
		var press := InputEventJoypadMotion.new()
		press.axis = (binding as InputEventJoypadMotion).axis
		press.axis_value = (binding as InputEventJoypadMotion).axis_value
		Input.parse_input_event(press)
		await _settle(2)
		var release := press.duplicate() as InputEventJoypadMotion
		release.axis_value = 0.0
		Input.parse_input_event(release)
	await _settle(3)


func _visible_build_cells(menu: Node) -> Array[Button]:
	var cells: Array[Button] = []
	for node in menu.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree() and _cell_id(button) != "":
			cells.append(button)
	cells.sort_custom(func(a: Button, b: Button) -> bool:
		return a.global_position.y < b.global_position.y - 1.0 \
			or (absf(a.global_position.y - b.global_position.y) <= 1.0 and a.global_position.x < b.global_position.x))
	return cells


func _cell_id(button: Button) -> String:
	for node in button.find_children("*", "TextureRect", true, false):
		var texture := (node as TextureRect).texture
		if texture != null and texture.resource_path.contains("/buildables/"):
			return texture.resource_path.get_file().get_basename()
	return ""


func _open_build_menu() -> Node:
	for node in _tree.get_nodes_in_group(BUILD_MENU_GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return node
	return null


func _highlighted_placed_piece() -> Node3D:
	for node in _tree.get_nodes_in_group(PLACED_GROUP):
		var placed := node as Node3D
		if placed != null and _has_overlay(placed):
			return placed
	return null


func _has_overlay(node: Node) -> bool:
	if node is MeshInstance3D and (node as MeshInstance3D).material_overlay != null:
		return true
	for child in node.get_children():
		if _has_overlay(child):
			return true
	return false


func _record_fingerprints_except(records: Array, id: String, position: Vector3) -> Array[String]:
	var out: Array[String] = []
	var skipped := false
	for record_value in records:
		var record := record_value as Dictionary
		if not skipped and str(record.get("id", "")) == id \
				and _flat_distance(_record_position(record), position) <= POSITION_EPSILON:
			skipped = true
			continue
		out.append(_record_fingerprint(record))
	out.sort()
	return out


func _record_fingerprints(records: Array) -> Array[String]:
	var out: Array[String] = []
	for record_value in records:
		out.append(_record_fingerprint(record_value as Dictionary))
	out.sort()
	return out


func _record_fingerprint(record: Dictionary) -> String:
	return "%s|%s|%.3f" % [str(record.get("id", "")), str(record.get("position", [])), float(record.get("yaw_deg", 0.0))]


func _record_position(record: Dictionary) -> Vector3:
	var position: Array = record.get("position", [])
	return Vector3(float(position[0]), float(position[1]), float(position[2])) if position.size() == 3 else Vector3.INF


func _outside_wall_for_camera(walls: Array[Vector3], house_centre: Vector3) -> Vector3:
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	var best := walls[0]
	var best_projection := INF
	for wall in walls:
		# Stand two metres farther opposite the view direction. Picking the wall
		# already farthest that way keeps the stance outside the footprint.
		var projection := (wall - house_centre).dot(forward)
		if projection < best_projection:
			best_projection = projection
			best = wall
	return best


func _item_count(id: String) -> int:
	return int(_game.get("inventory").call("count", id))


func _release_look() -> void:
	Input.action_release(&"look_right")
	Input.action_release(&"look_left")


func _resolve_move_bindings() -> void:
	var right := _joy_motion_for(&"move_right")
	var back := _joy_motion_for(&"move_back")
	var look_right := _joy_motion_for(&"look_right")
	if right == null or back == null or look_right == null:
		_fail("movement and camera actions need physical joypad axes for the exterior-ring proof")
		return
	_move_x_axis = right.axis
	_move_x_sign = signf(right.axis_value)
	_move_y_axis = back.axis
	_move_y_sign = signf(back.axis_value)
	_look_x_axis = look_right.axis
	_look_x_sign = signf(look_right.axis_value)


func _joy_motion_for(action: StringName) -> InputEventJoypadMotion:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return event as InputEventJoypadMotion
	return null


## LOCOMOTION is polled, so it is driven by polling.
##
## `player_controller.gd::_apply_movement()` and `camera_rig.gd` both read
## `Input.get_vector(...)`, and a synthesized `InputEventJoypadMotion` fed
## through `Input.parse_input_event()` does not reach that poll in a headless
## run: measured on `main` at the Village Square route entry, with the stick
## "held" in all eight compass directions, the player moved 0.00m every time
## while `locomotion_enabled` was true, nothing owned input and the tree was
## not paused. Every walk in this segment failed as "controller could not walk
## to ...", which reads as a blocked route and was a press that never arrived.
##
## `gate_a_npc_gather_segment.gd` -- the one segment that does reach its
## targets -- has always used `Input.action_press()` with a strength for
## exactly this. archive/docs/HANDOFF.md §10's rule is unchanged and still applies to
## everything else in this file: a poll cannot move Control focus or activate a
## Button, so BUTTONS stay parsed events (`_tap_action`) and only the two
## polled analogue sticks change.
func _parse_move_stick(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))


func _release_move_stick() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		Input.action_release(action)


func _settle(frames: int) -> void:
	for i in frames:
		await _tree.physics_frame


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _fail(message: String) -> void:
	failures.append(message)


func _result() -> Dictionary:
	_release_move_stick()
	return {"passed": failures.is_empty(), "failures": failures.duplicate(), "transcript": transcript.duplicate()}
