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
const PLACE_AHEAD := 3.0
const POSITION_EPSILON := 0.08
const MOVE_EPSILON := 0.16
const MOVE_FRAME_LIMIT := 360
const ROOF_ROUTE_MARGIN := 1.25

## The broad grassy shoulder southeast of the opening pad, centred at (14,20).
## It is deliberately off the village trail and pond vegetation: a player can
## walk here from the opening area without using a debug warp, and the 2x2
## shell leaves a complete exterior circuit. The smoke wrapper may stage a
## player here for mechanical placement regression only; canonical evidence
## must enter this helper from ordinary traversal with naturally earned stock.
const BUILD_PATCH_XZ := Vector2(14.0, 20.0)
const BUILD_PATCH_APPROACH_EPSILON := 0.55

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
var _look_x_axis: JoyAxis = JOY_AXIS_RIGHT_X
var _look_x_sign := 1.0
var _house_record_start := 0


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

	var door_target := floor_a + Vector3(0, 0, -1)
	if not await _select_piece("door"):
		return _result()
	if not await _move_ghost_to(door_target, Vector3(-1.3, 0, -1.0)):
		return _result()
	if await _place_current("door") == null:
		return _result()

	var wall_targets: Array[Dictionary] = [
		{"position": floor_a + Vector3(2, 0, -1), "aim_offset": Vector3(1.3, 0, -1.0)},
		{"position": floor_a + Vector3(0, 0, 3), "aim_offset": Vector3(-1.3, 0, 1.0)},
		{"position": floor_a + Vector3(2, 0, 3), "aim_offset": Vector3(1.3, 0, 1.0)},
	]
	if not await _select_piece("wall"):
		return _result()
	for wall in wall_targets:
		var wall_target: Vector3 = wall["position"]
		var wall_aim_offset: Vector3 = wall["aim_offset"]
		if not await _move_ghost_to(wall_target, wall_aim_offset):
			return _result()
		if await _place_current("wall") == null:
			return _result()
	transcript.append("placed one doorway and three wall pieces through the catalogue and snap contract")

	var roof_supports: Array[Dictionary] = [
		{"floor": floor_a, "aim_offset": Vector3(-1.7, 0, 0)},
		{"floor": floor_a + Vector3(2, 0, 0), "aim_offset": Vector3(1.7, 0, 0)},
		{"floor": floor_a + Vector3(0, 0, 2), "aim_offset": Vector3(-1.7, 0, 0)},
		{"floor": floor_a + Vector3(2, 0, 2), "aim_offset": Vector3(1.7, 0, 0)},
	]
	for support in roof_supports:
		var target: Vector3 = support["floor"]
		var aim_offset: Vector3 = support["aim_offset"]
		var roof_target := Vector3(target.x, target.y + 3.05, target.z)
		# Armed structural ghosts own enough of the construction interaction that
		# long controller travel can stall even on a clear exterior lane. Stow the
		# previous wall/roof with the visible Cancel control, walk normally, then
		# reopen the catalogue and select Roof at the reachable stance.
		if not await _stow_piece_for_travel():
			return _result()
		if not await _move_to_roof_stance(roof_target, aim_offset):
			return _result()
		if not await _select_piece("roof"):
			return _result()
		var placed_roof: Variant = await _place_current("roof")
		if placed_roof == null:
			return _result()
		var placed_roof_position: Vector3 = placed_roof
		if _flat_distance(placed_roof_position, roof_target) > POSITION_EPSILON:
			_fail("controller Roof selection placed at %s instead of supported anchor %s" % [placed_roof, roof_target])
			return _result()
	transcript.append("stowed for travel and placed four supported roofs through four real Roof selections")

	var built_records := (_game.get("placed_buildings") as Array).size() - before_records
	if built_records != 12:
		_fail("house sequence should add 12 records before dismantle, added %d" % built_records)
		return _result()
	if _item_count("wood") != before_wood - 39 or _item_count("stone") != before_stone - 34:
		_fail("paid house did not spend exact natural-material cost (wood %d->%d, stone %d->%d)" % [
			before_wood, _item_count("wood"), before_stone, _item_count("stone")])
		return _result()

	var wall_positions: Array[Vector3] = []
	for wall in wall_targets:
		wall_positions.append(wall["position"])
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

	# This is ordinary locomotion, not fixture positioning. The build patch is
	# only a short walk from the opening pad, but the controller still has to
	# reach it through the live collision world before a single material is spent.
	if not await _walk_to(Vector3(BUILD_PATCH_XZ.x, _player.global_position.y, BUILD_PATCH_XZ.y)):
		_fail("controller could not reach the documented off-trail Meadows build patch")
		return false
	if _flat_distance(_player.global_position, Vector3(BUILD_PATCH_XZ.x, 0.0, BUILD_PATCH_XZ.y)) > BUILD_PATCH_APPROACH_EPSILON:
		_fail("controller stopped outside the documented build patch")
		return false
	if not _player.is_on_floor():
		_fail("controller arrival did not leave the player grounded on the documented Meadows patch")
		return false

	# The green, live Floor ghost is the placement-clearance proof. It is armed
	# through the public catalogue, moved by parsed stick input and read only as
	# the placer's rendered legality state; no test-side build transaction occurs.
	if not await _select_piece("floor"):
		return false
	await _settle(8)
	var placer := _tree.get_first_node_in_group(&"build_placer")
	if placer == null or not bool(placer.get("_ghost_ok")):
		_fail("the documented patch has no legal first Floor ghost; do not spend materials there")
		return false
	transcript.append("walked by controller to the documented off-trail patch; grounded green Floor ghost verified before spending")
	return true


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


func _move_to_roof_stance(target: Vector3, aim_offset: Vector3) -> bool:
	# Each roof is aimed from the open X side of the shell. A right-stick turn
	# makes the camera look inward before the left stick walks there, so the
	# three-metre placement reach never asks the trainer to stand inside a wall.
	# The left/right support order below therefore traces a complete exterior
	# ring instead of relying on the camera's incidental original heading.
	var outward := Vector3(signf(aim_offset.x), 0.0, 0.0)
	if is_zero_approx(outward.x):
		_fail("roof support lacks an exterior-side orientation")
		return false
	if not await _turn_camera_toward(-outward):
		return false
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	var wanted_player := target + aim_offset - forward * PLACE_AHEAD
	var shell := _lower_shell_bounds()
	if shell.size == Vector2.ZERO:
		_fail("could not derive the completed lower-shell footprint for the roof route")
		return false
	var left_x := shell.position.x - ROOF_ROUTE_MARGIN
	var right_x := shell.end.x + ROOF_ROUTE_MARGIN
	var front_z := shell.position.y - ROOF_ROUTE_MARGIN
	var back_z := shell.end.y + ROOF_ROUTE_MARGIN
	var centre := shell.get_center()
	var current_lane_x := left_x if _player.global_position.x < centre.x else right_x
	var wanted_lane_x := left_x if wanted_player.x < centre.x else right_x
	# Step outside the actual placed floor/wall/door footprint, not a guessed
	# world-space rectangle. The deliberately conservative half-module bounds
	# also cover the wall collider's timber end caps.
	if not await _walk_axis_to(current_lane_x, true, "geometry-derived roof side clearance"):
		return false
	# If the trainer already stands beyond the front/back bounds, cross at that
	# exact Z instead of steering back toward a fixed lane. This is the live
	# failure the first route exposed: its guessed +Z waypoint could put solid
	# scenery between a perfectly safe current stance and the requested point.
	var crossing_z := _player.global_position.z
	if crossing_z >= front_z and crossing_z <= back_z:
		crossing_z = front_z if absf(crossing_z - front_z) < absf(crossing_z - back_z) else back_z
	if not await _walk_axis_to(crossing_z, false, "geometry-derived roof crossing clearance"):
		return false
	if not await _walk_axis_to(wanted_lane_x, true, "geometry-derived roof crossing lane"):
		return false
	if not await _walk_axis_to(wanted_player.z, false, "geometry-derived roof approach lane"):
		return false
	return await _move_ghost_to(target, aim_offset)


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


func _lower_shell_bounds() -> Rect2:
	var bounds := Rect2()
	var has_piece := false
	var records: Array = _game.get("placed_buildings") as Array
	for i in range(_house_record_start, records.size()):
		var record := records[i] as Dictionary
		if not ["floor", "wall", "door"].has(str(record.get("id", ""))):
			continue
		var position := _record_position(record)
		if position == Vector3.INF:
			continue
		# A full half-module in both axes is conservative for walls/doors but
		# exact for floors. Conservatism is intentional: controller routing must
		# clear visible/collidable end caps, not skim their nominal thin axis.
		var low := Vector2(position.x - BUILD_SNAP.HALF, position.z - BUILD_SNAP.HALF)
		var high := Vector2(position.x + BUILD_SNAP.HALF, position.z + BUILD_SNAP.HALF)
		if not has_piece:
			bounds = Rect2(low, high - low)
			has_piece = true
		else:
			bounds = bounds.expand(low).expand(high)
	return bounds if has_piece else Rect2()


func _walk_axis_to(coordinate: float, x_axis: bool, purpose: String) -> bool:
	var current := _player.global_position.x if x_axis else _player.global_position.z
	var direction := signf(coordinate - current)
	if direction == 0.0:
		return true
	for frame in MOVE_FRAME_LIMIT:
		current = _player.global_position.x if x_axis else _player.global_position.z
		var remaining := coordinate - current
		if remaining * direction <= 0.0:
			_release_move_stick()
			return true
		var strength := clampf(absf(remaining) / 0.9, 0.32, 1.0)
		var world_direction := Vector3(direction, 0.0, 0.0) if x_axis else Vector3(0.0, 0.0, direction)
		var local := (_camera_rig.call("planar_basis") as Basis).inverse() * world_direction * strength
		_parse_move_stick(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
		await _tree.physics_frame
	_release_move_stick()
	_fail("controller could not cross the %s" % purpose)
	return false


func _dismantle_aimed_wall(target_position: Vector3) -> bool:
	var records_before: Array = (_game.get("placed_buildings") as Array).duplicate(true)
	var neighbours_before := _record_fingerprints_except(records_before, "wall", target_position)
	var wood_before := _item_count("wood")
	var stone_before := _item_count("stone")
	var forward := -(_camera_rig.call("planar_basis") as Basis).z
	var wanted_player := target_position - forward * 2.0
	if not await _stow_piece_for_travel():
		return false
	if not await _walk_to(wanted_player):
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


func _walk_to(target: Vector3) -> bool:
	for frame in MOVE_FRAME_LIMIT:
		var delta := Vector3(target.x - _player.global_position.x, 0, target.z - _player.global_position.z)
		if delta.length() <= MOVE_EPSILON:
			_release_move_stick()
			return true
		var strength := clampf(delta.length() / 0.9, 0.32, 1.0)
		var local := (_camera_rig.call("planar_basis") as Basis).inverse() * delta.normalized() * strength
		_parse_move_stick(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
		await _tree.physics_frame
	_release_move_stick()
	_fail("controller could not walk to the aimed dismantle stance")
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
