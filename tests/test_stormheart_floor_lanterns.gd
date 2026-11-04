extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#1: stormheart_presentation.floor_lanterns_1104
## rings the Stormheart hollow floor with installed lantern posts and warm
## lights. Ships OFF; ON it stays outside the 37 m fight ring, adds no
## collider, and its light is warm (lanterns), never red.

const LANTERNS := preload("res://scripts/world/stormheart_floor_lanterns.gd")


func _raw() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(LANTERNS.CONFIG_PATH)).floor_lanterns_1104


func test_floor_lanterns_ship_off() -> void:
	assert_false(bool(_raw().get("enabled", true)), "ships OFF until judged")
	assert_eq(LANTERNS.config(), {}, "OFF installs nothing")


func test_floor_lanterns_ring_sits_at_the_wall_foot() -> void:
	var cfg := _raw()
	var centre := Vector2(float(cfg.centre[0]), float(cfg.centre[1]))
	var points := LANTERNS.ring_points(cfg)
	assert_eq(points.size(), int(cfg.count), "one post per count")
	for p: Vector2 in points:
		assert_true(p.distance_to(centre) > 37.0, "outside the fight ring")
	var light := Color(str(cfg.light_colour))
	assert_true(light.r >= light.g and light.g > light.b, "warm lantern light")
	assert_true(light.g > light.r * 0.55, "amber, not red or oxblood")


func test_floor_lanterns_add_no_collider() -> void:
	var cfg := _raw()
	cfg["enabled"] = true
	var world := Node3D.new()
	var root := LANTERNS.install(world, cfg)
	assert_true(root != null, "installs when ON")
	assert_eq(root.find_children("*", "CollisionObject3D", true, false).size(), 0, "visual only")
	assert_eq(root.find_children("*", "OmniLight3D", true, false).size(), int(cfg.count), "one warm light per post")
	world.free()
