extends "res://tests/test_case.gd"

## P2-094 (22 Oct): an ordinary build piece (floor, wall) could be laid
## straight through a world boulder; only placed buildings and slope were
## checked. The live preview now refuses world geometry in the footprint.

const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")

var _world: Node3D = null


func after_each() -> void:
	if is_instance_valid(_world):
		_world.free()
	_world = null


func _static_box(parent: Node, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	body.global_position = at
	return body


func test_world_geometry_blocks_but_bodies_and_placed_pieces_do_not() -> void:
	var rock := StaticBody3D.new()
	assert_true(BUILD_PLACER.blocking_world_hit({"collider": rock}), "a world static body blocks")
	assert_true(BUILD_PLACER.blocking_world_hit({"collider": null}), "streamed vegetation collision (no node) blocks")
	var walker := CharacterBody3D.new()
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": walker}), "the player or a creature never blocks")
	var placed := Node3D.new()
	placed.add_to_group(BUILD_PLACER.PLACED_GROUP)
	var wall_body := StaticBody3D.new()
	placed.add_child(wall_body)
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": wall_body}), "a placed building's own collider is left to occupancy rules")
	var ghost := Node3D.new()
	var ghost_body := StaticBody3D.new()
	ghost.add_child(ghost_body)
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": ghost_body}, ghost), "the ghost never blocks itself")
	for node: Node in [rock, walker, placed, ghost]:
		node.free()


func test_a_boulder_in_the_footprint_refuses_the_spot() -> void:
	_world = Node3D.new()
	Engine.get_main_loop().root.add_child(_world)
	_static_box(_world, Vector3(0.0, 1.5, 0.0), Vector3(2.0, 3.0, 2.0))
	for _i in 3:
		await Engine.get_main_loop().physics_frame
	var space := _world.get_world_3d().direct_space_state
	assert_true(BUILD_PLACER.world_occupied_in(space, Vector3.ZERO), "a floor centred on a boulder is refused")
	assert_false(BUILD_PLACER.world_occupied_in(space, Vector3(6.0, 0.0, 6.0)), "clear ground stays legal")
	assert_false(BUILD_PLACER.world_occupied_in(space, Vector3(0.0, 4.0, 0.0)), "standing on top of it is not an overlap")
