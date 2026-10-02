extends "res://tests/test_case.gd"

## Actual built box placement tests; these do not prove physical shop traversal.
const SHOP := preload("res://scripts/world/shop_interior.gd")
const PLACER := preload("res://scripts/world/village_npcs.gd")

func test_actual_enabled_floor_top_tracks_transform_and_refuses_absent_support() -> void:
	var shop := SHOP.new()
	get_tree().root.add_child(shop)
	assert_true(is_nan(shop.floor_top_world_at(0.0, 0.0)))
	shop._build_floor()
	shop.transform = Transform3D(Basis(Vector3.UP, 0.4).scaled(Vector3.ONE * 2.0), Vector3(6.0, 3.0, 8.0))
	assert_almost_eq(shop.floor_top_world_at(6.0, 8.0), 3.14, 0.000001)
	var inside: Vector3 = shop.to_global(Vector3(1.0, 0.0, 1.0))
	assert_almost_eq(shop.floor_top_world_at(inside.x, inside.z), 3.14, 0.000001)
	assert_true(is_nan(shop.floor_top_world_at(26.0, 8.0)))
	assert_true(is_nan(shop.floor_top_world_at(INF, 8.0)))
	shop._floor_shape.disabled = true
	assert_true(is_nan(shop.floor_top_world_at(6.0, 8.0)))
	shop._floor_shape.disabled = false
	(shop._floor_shape.get_parent() as StaticBody3D).collision_layer = 0
	assert_true(is_nan(shop.floor_top_world_at(6.0, 8.0)))
	shop.free()

func test_npc_support_uses_its_current_village_floor_without_lowering_terrain() -> void:
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var village := Node3D.new()
	village.name = "Village"
	world.add_child(village)
	var building := Node3D.new()
	village.add_child(building)
	building.position = Vector3(26.0, 0.85, 2.0)
	var shop := SHOP.new()
	shop.name = "Interior"
	building.add_child(shop)
	shop._build_floor()
	var placer := PLACER.new()
	world.add_child(placer)
	assert_almost_eq(placer._interior_support_height(26.0, 0.6, 0.9), 0.92, 0.000001,
		"Mira's feet stand on the actual separated floor")
	assert_almost_eq(placer._interior_support_height(26.0, 0.6, 1.2), 1.2, 0.000001)
	assert_almost_eq(placer._interior_support_height(62.0, 20.0, 1.968), 1.968, 0.000001)
	world.free()
