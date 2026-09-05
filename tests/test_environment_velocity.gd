extends "res://tests/test_case.gd"

const MODIFIERS := preload("res://scripts/world/environment_velocity_modifiers.gd")

class Owner extends Node:
	func add_wind(body: CharacterBody3D, _delta: float) -> void:
		body.velocity.x += 7.0


func test_order_replacement_and_no_modifier_identity() -> void:
	var modifiers := MODIFIERS.new()
	var body := CharacterBody3D.new()
	var owner := Owner.new()
	body.velocity = Vector3(1, 2, 3)
	modifiers.begin_step(body)
	modifiers.apply(body, 0.1)
	assert_eq(body.velocity, Vector3(1, 2, 3))
	assert_true(modifiers.register_modifier(&"wind", owner, owner.add_wind, 20))
	assert_true(modifiers.register_modifier(&"first", owner, func(actor: CharacterBody3D, _dt: float): actor.velocity.x *= 2, 10))
	modifiers.apply(body, 0.1)
	assert_eq(body.velocity.x, 9.0, "ordered modifier receives chosen locomotion velocity")
	assert_true(modifiers.register_modifier(&"wind", owner, owner.add_wind, 20))
	body.velocity.x = 1
	modifiers.apply(body, 0.1)
	assert_eq(body.velocity.x, 9.0, "same id replaces rather than duplicates")
	modifiers.clear_all()
	body.free()
	owner.free()


func test_external_drift_is_not_reintegrated_and_velocity_reset_invalidates_debt() -> void:
	var modifiers := MODIFIERS.new()
	var body := CharacterBody3D.new()
	var owner := Owner.new()
	modifiers.register_modifier(&"wind", owner, owner.add_wind)
	for tick in 120:
		modifiers.begin_step(body)
		body.velocity = body.velocity.move_toward(Vector3.ZERO, 0.1)
		modifiers.apply(body, 1.0 / 60.0)
		modifiers.after_slide(body)
	assert_eq(body.velocity.x, 7.0)
	modifiers.clear_modifier(&"wind")
	modifiers.begin_step(body)
	assert_eq(body.velocity, Vector3.ZERO, "clear removes last transient drift next tick")
	modifiers.register_modifier(&"wind", owner, owner.add_wind)
	modifiers.apply(body, 0.1)
	modifiers.after_slide(body)
	body.velocity = Vector3(0, -3, 0)
	modifiers.begin_step(body)
	assert_eq(body.velocity, Vector3(0, -3, 0), "external recovery/teleport reset is not reversed")
	modifiers.clear_all()
	body.free()
	owner.free()


func test_freed_owner_invalid_callable_and_clear_during_dispatch_are_safe() -> void:
	var modifiers := MODIFIERS.new()
	var body := CharacterBody3D.new()
	var owner := Owner.new()
	assert_false(modifiers.register_modifier(&"invalid", owner, Callable()))
	modifiers.register_modifier(&"dead", owner, owner.add_wind)
	owner.free()
	modifiers.apply(body, 0.1)
	assert_eq(body.velocity, Vector3.ZERO)
	assert_eq(modifiers._entries.size(), 0)
	owner = Owner.new()
	modifiers.register_modifier(&"later", owner, owner.add_wind, 10)
	modifiers.register_modifier(&"clear", owner, func(_actor: CharacterBody3D, _dt: float): modifiers.clear_modifier(&"later"), 0)
	modifiers.apply(body, 0.1)
	assert_eq(body.velocity, Vector3.ZERO)
	modifiers.clear_all()
	body.free()
	owner.free()


func test_fly_restriction_discard_does_not_create_reverse_wind() -> void:
	var modifiers := MODIFIERS.new()
	var body := CharacterBody3D.new()
	var owner := Owner.new()
	modifiers.register_modifier(&"wind", owner, owner.add_wind)
	modifiers.apply(body, 0.1)
	body.velocity = Vector3.ZERO
	modifiers.after_slide(body, true)
	modifiers.begin_step(body)
	assert_eq(body.velocity, Vector3.ZERO)
	modifiers.clear_all()
	body.free()
	owner.free()


func test_each_production_path_has_one_slide_and_an_environment_hook() -> void:
	for path: String in ["res://scripts/player/player_controller.gd", "res://scripts/player/fly_controller.gd", "res://scripts/creatures/creature_body.gd"]:
		var slides := 0
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var clean := line.strip_edges()
			if not clean.begins_with("#") and clean.ends_with("move_and_slide()"):
				slides += 1
		assert_eq(slides, 1, path)
		assert_true(FileAccess.get_file_as_string(path).contains("environment_velocity"), path)
