extends "res://tests/test_case.gd"

## Actual built box placement tests; these do not prove physical shop traversal.
const SHOP := preload("res://scripts/world/shop_interior.gd")
const PLACER := preload("res://scripts/world/village_npcs.gd")

func _case_actual_enabled_floor_top_tracks_transform_and_refuses_absent_support() -> void:
	var shop := SHOP.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(shop)
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

func _case_npc_support_uses_its_current_village_floor_without_lowering_terrain() -> void:
	var world := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(world)
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


func test_native_actual_floor_and_npc_placement_support() -> void:
	# The parent unit runner executes in SceneTree._init, before the main loop
	# exists. A deferred initialized child supplies actual registered geometry.
	var output: Array = []
	var log_path := ProjectSettings.globalize_path("user://shop-floor-support-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script",
		"res://tests/helpers/shop_floor_support_native.gd", "--log-file", log_path], output, true)
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("SHOP_FLOOR_SUPPORT_RESULT="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("SHOP_FLOOR_SUPPORT_RESULT="))
			if parsed is Dictionary: result = parsed
	assert_eq(code, 0, combined)
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_eq(result.get("assertions", 0), 10, "all transformed support and NPC placement assertions must finish")
	assert_true(result.get("completed", false), combined)
	var native_log := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	assert_false(native_log.is_empty(), "the actual child must retain its full native log")
	combined += "\n" + native_log
	assert_false(combined.contains("ERROR:") or combined.contains("SCRIPT ERROR"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
