extends "res://tests/test_case.gd"

## P2-094 (22 Oct): an ordinary build piece (floor, wall) could be laid
## straight through a world boulder; only placed buildings and slope were
## checked. The live preview now refuses world scatter (trees and boulders) in
## the footprint, and nothing else: people, houses and story gates keep their
## own rules (review 22 Oct: Grandpa's body and DoorGate must never block).

const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const VEGETATION := preload("res://scripts/world/vegetation.gd")
const RUNS_IN_INITIALIZED_TREE := true

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
	# The physics server only learns the new transform on the next step; the
	# synchronous query below needs it now.
	body.force_update_transform()
	return body


func _scatter_body(scatter: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Rock_Medium_1_Collision"
	scatter.add_child(body)
	return body


func test_only_world_scatter_blocks() -> void:
	var scatter: Node3D = VEGETATION.new()
	var rock := _scatter_body(scatter)
	assert_true(BUILD_PLACER.blocking_world_hit({"collider": rock}), "a tree or boulder's scatter collision blocks")
	assert_true(BUILD_PLACER.blocking_world_hit({"collider": null}), "a hit with no node behind it blocks")
	var gate := StaticBody3D.new()
	gate.name = "DoorGate"
	var house := Node3D.new()
	house.add_child(gate)
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": gate}), "a house's invisible story gate never blocks")
	var person: Node3D = CHARACTER_MODEL.new()
	var person_body := StaticBody3D.new()
	person_body.name = "Body"
	person.add_child(person_body)
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": person_body}), "an NPC or trainer's static body never blocks")
	var walker := CharacterBody3D.new()
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": walker}), "the player or a creature never blocks")
	var placed := Node3D.new()
	placed.add_to_group(BUILD_PLACER.PLACED_GROUP)
	var wall_body := StaticBody3D.new()
	placed.add_child(wall_body)
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": wall_body}), "a placed building is left to occupancy rules")
	assert_false(BUILD_PLACER.blocking_world_hit({"collider": rock}, rock), "the ghost never blocks itself")
	for node: Node in [scatter, house, person, walker, placed]:
		node.free()


func test_a_boulder_in_the_footprint_refuses_the_spot() -> void:
	_world = Node3D.new()
	Engine.get_main_loop().root.add_child(_world)
	var scatter: Node3D = VEGETATION.new()
	_world.add_child(scatter)
	var rock := _static_box(scatter, Vector3(0.0, 1.5, 0.0), Vector3(2.0, 3.0, 2.0))
	rock.name = "Rock_Medium_1_Collision"
	# Synchronous: the runner does not await test methods, and the space query
	# sees a body as soon as it is in the tree.
	var space := _world.get_world_3d().direct_space_state
	assert_true(BUILD_PLACER.world_occupied_in(space, Vector3.ZERO), "a floor centred on a boulder is refused")
	assert_false(BUILD_PLACER.world_occupied_in(space, Vector3(6.0, 0.0, 6.0)), "clear ground stays legal")
	assert_false(BUILD_PLACER.world_occupied_in(space, Vector3(0.0, 4.0, 0.0)), "standing on top of it is not an overlap")


func test_a_person_in_the_footprint_does_not_refuse_the_spot() -> void:
	_world = Node3D.new()
	Engine.get_main_loop().root.add_child(_world)
	var person: Node3D = CHARACTER_MODEL.new()
	_world.add_child(person)
	var body := _static_box(person, Vector3(0.0, 0.9, 0.0), Vector3(0.7, 1.8, 0.7))
	body.name = "Body"
	var space := _world.get_world_3d().direct_space_state
	assert_false(BUILD_PLACER.world_occupied_in(space, Vector3.ZERO), "an NPC standing on the spot does not block the build")
