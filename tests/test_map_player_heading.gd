extends "res://tests/test_case.gd"

const MINIMAP := preload("res://scripts/ui/minimap.gd")
const TAB_MAP := preload("res://scripts/ui/tab_map.gd")

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		node.free()
	_nodes.clear()


func _player_with_model(player_yaw: float, model_yaw: float) -> Node3D:
	var player := Node3D.new()
	player.rotation.y = player_yaw
	var model := Node3D.new()
	model.name = "Model"
	model.rotation.y = model_yaw
	player.add_child(model)
	_nodes.append(player)
	return player


func test_heading_comes_from_visible_trainer_not_backward_camera_axis() -> void:
	var player := _player_with_model(0.0, 0.0)
	var backward_camera_yaw := PI

	assert_almost_eq(MINIMAP.player_facing_yaw(player, backward_camera_yaw), 0.0, 0.0001,
		"camera basis.z is backward; the map must use the trainer model's +Z facing")

	var tab := TAB_MAP.new()
	_nodes.append(tab)
	assert_almost_eq(float(tab.call("_facing_yaw", null, player)), 0.0, 0.0001,
		"the full map must share the minimap's trainer-facing convention")


func test_parent_and_model_yaw_both_contribute_to_world_facing() -> void:
	var player := _player_with_model(PI * 0.25, PI * 0.25)
	assert_almost_eq(MINIMAP.player_facing_yaw(player), PI * 0.5, 0.0001,
		"heading must use the model's world-space forward axis")


func test_triangle_tips_distinguish_forward_from_backward_on_both_maps() -> void:
	var minimap_forward := MINIMAP.player_up_marker_forward(0.0, 0.0)
	var minimap_backward := MINIMAP.player_up_marker_forward(0.0, PI)
	assert_true(minimap_forward.dot(Vector2.UP) > 0.999,
		"when travel and trainer facing agree, the minimap tip must point up")
	assert_true(minimap_backward.dot(Vector2.DOWN) > 0.999,
		"a backward-facing trainer must point down, not reuse the forward tip")

	var full_map_forward := MINIMAP.north_up_marker_forward(0.0)
	var full_map_backward := MINIMAP.north_up_marker_forward(PI)
	assert_true(full_map_forward.dot(Vector2.DOWN) > 0.999,
		"trainer +Z faces south/down on the north-up full map")
	assert_true(full_map_backward.dot(Vector2.UP) > 0.999,
		"the opposite trainer facing must reverse the full-map tip")
