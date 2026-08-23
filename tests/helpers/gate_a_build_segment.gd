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
const PLACE_AHEAD := 3.0
const POSITION_EPSILON := 0.08
const MOVE_EPSILON := 0.16
const MOVE_FRAME_LIMIT := 360

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
	Vector2(10.0, -10.0), # Village Square
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

	var front_roofs: Array[Vector3] = [floor_a + Vector3(2, 0, 0), floor_a]
	for floor_target in front_roofs:
		if not await _place_roof_from_exterior(floor_target, HOUSE_AIM_DIRECTION, "front-exterior"):
			return _result()
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

	if not await _dismantle_aimed_wall(_outside_wall_for_camera(wall_positions, floor_a + Vector3(1, 0, 1))):
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

	# The green, live Floor ghost seeds the whole no-spend plan. It is armed
	# through the public catalogue and read only as the placer's rendered legality
	# state; no test-side build transaction occurs.
	if not await _select_piece("floor"):
		return false
	await _settle(8)
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
	for step: Dictionary in _planned_house_steps(_preflight_first_floor):
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
		if resolved.distance_to(target) > POSITION_EPSILON:
			_fail("planned %s ghost resolves to %s instead of %s" % [id, resolved, target])
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
	await _settle(8)
	var live_ghost := placer.get("_ghost") as Node3D
	if live_ghost == null or not bool(placer.get("_ghost_ok")) \
			or live_ghost.global_position.distance_to(_preflight_first_floor) > POSITION_EPSILON:
		_fail("returning to the preflight Floor stance did not restore the green live ghost")
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
	await _tap_action(&"build_open")
	await _settle(10)
	var menu := _open_build_menu()
	if menu == null:
		_fail("Build did not open from the parsed controller build_open press")
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
		await _tap_action(&"build_rotate_right")
		await _settle(8)
	_fail("could not reach %s through controller category/cell navigation" % id)
	return false


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


func _move_ghost_to(target: Vector3, aim_offset: Vector3 = Vector3.ZERO) -> bool:
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	var wanted_player := target + aim_offset - forward * PLACE_AHEAD
	for frame in MOVE_FRAME_LIMIT:
		var delta := Vector3(wanted_player.x - _player.global_position.x, 0, wanted_player.z - _player.global_position.z)
		if delta.length() <= MOVE_EPSILON:
			_release_move_stick()
			await _settle(3)
			return true
		var strength := clampf(delta.length() / 0.9, 0.32, 1.0)
		var local := (_camera_rig.call("planar_basis") as Basis).inverse() * delta.normalized() * strength
		_parse_move_stick(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
		await _tree.physics_frame
	_release_move_stick()
	_fail("controller movement could not line the ghost up with %s" % target)
	return false


func _place_roof_from_exterior(floor_target: Vector3, inward: Vector3, side: String) -> bool:
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
	if not await _walk_to(wanted_player, "%s exterior Roof stance" % side):
		_fail("controller could not reach the %s exterior Roof stance" % side)
		return false
	if not await _select_piece("roof"):
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
			_parse_axis(_look_x_axis, 0.0)
			return true
		# The camera applies a positive look-right axis as a rightward yaw. The
		# signed planar cross product tells the parsed controller which physical
		# direction closes the remaining angle; no transform is written here.
		var turn_right := -Vector3(forward.x, 0.0, forward.z).cross(world_direction).y > 0.0
		_parse_axis(_look_x_axis, (1.0 if turn_right else -1.0) * _look_x_sign)
		await _tree.physics_frame
	_parse_axis(_look_x_axis, 0.0)
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
	await _settle(8)
	var highlighted := _highlighted_placed_piece()
	if highlighted == null or str(highlighted.get_meta("building_id", "")) != "wall" \
			or _flat_distance(highlighted.global_position, target_position) > POSITION_EPSILON:
		_fail("construction aim did not visibly highlight the intended wall before Y")
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
func _walk_to(target: Vector3, purpose: String) -> bool:
	if _nav == null:
		_nav = NAVIGATOR.new(_tree, _player, _camera_rig, _parse_move_stick)
	var arrived: bool = await _nav.walk_to(target, MOVE_FRAME_LIMIT, MOVE_EPSILON)
	_release_move_stick()
	if not arrived:
		_fail("controller could not walk to the %s" % purpose)
	return arrived


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


func _parse_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


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


func _parse_move_stick(x: float, y: float) -> void:
	_parse_axis(_move_x_axis, x * _move_x_sign)
	_parse_axis(_move_y_axis, y * _move_y_sign)


func _release_move_stick() -> void:
	_parse_move_stick(0.0, 0.0)


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
