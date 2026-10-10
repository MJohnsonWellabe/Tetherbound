extends "res://tests/test_case.gd"

## Footprint ownership only. Native approaches still judge whether costumes
## read and the clearing edge looks natural under the shipping dune treatment.
const CLEARANCE := preload("res://scripts/world/water_named_grass_clearance.gd")

class WaterWorld:
	extends Node3D
	var simulation_only := false
	var realm := "water"
	func world_realm() -> String:
		return realm

var _world: WaterWorld


func before_each() -> void:
	_world = WaterWorld.new()


func after_each() -> void:
	_world.free()


func test_explicitly_disabled_is_an_exact_spawn_noop() -> void:
	var body := CharacterBody3D.new()
	body.name = "water_adair"
	body.position = Vector3(17.0, 3.0, 8.0)
	body.set_meta("water_npc_id", "water_adair")
	var before := body.transform
	var metadata := body.get_meta_list()
	assert_false(CLEARANCE.apply(body, _world, {"enabled": false}))
	assert_eq(body.get_meta_list(), metadata)
	assert_false(body.is_in_group(CLEARANCE.GROUP))
	assert_true(body.transform.is_equal_approx(before))
	assert_eq(body.get_child_count(), 0)
	body.free()


func test_production_default_footprint_preserves_actor_prompt_and_collision() -> void:
	assert_true(bool(CLEARANCE.settings().get("enabled", false)))
	var body := CharacterBody3D.new()
	body.name = "water_trainer_bex"
	body.transform = Transform3D(Basis(Vector3.UP, 0.75), Vector3(4, 8, 12))
	body.velocity = Vector3(0.2, 0.0, 0.3)
	body.collision_layer = 4
	body.collision_mask = 9
	var prompt := Node3D.new()
	prompt.name = "WaterChallenge"
	prompt.position = Vector3(1.5, 1.05, 0.0)
	body.add_child(prompt)
	var before := body.transform
	var velocity_before := body.velocity
	var prompt_before := prompt.transform
	assert_true(CLEARANCE.apply(body, _world))
	assert_true(body.is_in_group(CLEARANCE.GROUP))
	assert_almost_eq(float(body.get_meta(CLEARANCE.RADIUS_META)), 2.5)
	assert_eq(body.get_child_count(), 1)
	assert_true(body.transform.is_equal_approx(before))
	assert_eq(body.velocity, velocity_before)
	assert_eq(body.collision_layer, 4)
	assert_eq(body.collision_mask, 9)
	assert_true(prompt.transform.is_equal_approx(prompt_before))
	# The footprint belongs to this live body, not an extra node frozen at its
	# spawn coordinate. GrassField reads body.global_position when gathering it.
	body.position += Vector3(2, 0, 1)
	assert_true(body.is_in_group(CLEARANCE.GROUP))
	assert_eq(body.get_child_count(), 1)
	body.free()
	assert_false(is_instance_valid(body))
	assert_false(is_instance_valid(prompt))


func test_reused_npc_and_existing_clearance_are_not_overwritten() -> void:
	var body := Node3D.new()
	assert_true(CLEARANCE.apply(body, _world, {"enabled": true, "radius_m": 2.5}))
	assert_false(CLEARANCE.apply(body, _world, {"enabled": true, "radius_m": 3.0}))
	assert_almost_eq(float(body.get_meta(CLEARANCE.RADIUS_META)), 2.5)
	assert_eq(body.get_groups().count(CLEARANCE.GROUP), 1)
	body.free()
	var existing := Node3D.new()
	existing.add_to_group(CLEARANCE.GROUP)
	existing.set_meta(CLEARANCE.RADIUS_META, 4.25)
	assert_false(CLEARANCE.apply(existing, _world, {"enabled": true, "radius_m": 2.5}))
	assert_almost_eq(float(existing.get_meta(CLEARANCE.RADIUS_META)), 4.25)
	assert_true(existing.is_in_group(CLEARANCE.GROUP))
	existing.free()


func test_radius_is_local_bounded_and_invalid_input_has_no_effect() -> void:
	for value: float in [0.0, 2.5, 100.0]:
		var body := Node3D.new()
		assert_true(CLEARANCE.apply(body, _world, {"enabled": true, "radius_m": value}))
		assert_almost_eq(float(body.get_meta(CLEARANCE.RADIUS_META)), clampf(value, 2.0, 3.0))
		body.free()
	var invalid := Node3D.new()
	assert_false(CLEARANCE.apply(invalid, _world, {"enabled": true, "radius_m": NAN}))
	assert_false(invalid.is_in_group(CLEARANCE.GROUP))
	assert_false(invalid.has_meta(CLEARANCE.RADIUS_META))
	assert_false(CLEARANCE.apply(null, _world, {"enabled": true, "radius_m": 2.5}))
	invalid.free()


func test_offscreen_simulation_and_other_realms_do_not_register() -> void:
	var body := Node3D.new()
	var config := {"enabled": true, "radius_m": 2.5}
	_world.simulation_only = true
	assert_false(CLEARANCE.apply(body, _world, config))
	assert_false(body.is_in_group(CLEARANCE.GROUP))
	assert_false(body.has_meta(CLEARANCE.RADIUS_META))
	_world.simulation_only = false
	_world.realm = "meadows"
	assert_false(CLEARANCE.apply(body, _world, config))
	assert_false(CLEARANCE.apply(body, null, config))
	assert_false(body.is_in_group(CLEARANCE.GROUP))
	assert_false(body.has_meta(CLEARANCE.RADIUS_META))
	body.free()
