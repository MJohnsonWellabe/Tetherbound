extends "res://tests/test_case.gd"

## Actual built box placement tests; these do not prove physical shop traversal.
const SHOP := preload("res://scripts/world/shop_interior.gd")
const PLACER := preload("res://scripts/world/village_npcs.gd")
const PLAYER := preload("res://scripts/player/player_controller.gd")

class DiagnosticRig extends Node3D:
	func planar_basis() -> Basis:
		return Basis.IDENTITY

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


func _case_real_flat_idle_controller_recovers_resumes_and_loses_support() -> void:
	# Disclosed synthetic registration/starting pose, actual built shop floor,
	# production controller and unmodified capsule. Full Mira travel is separate.
	var tree := Engine.get_main_loop() as SceneTree
	var world := Node3D.new()
	tree.root.add_child(world)
	var shop := SHOP.new()
	shop.position = Vector3(26.0, 0.85, 2.0)
	world.add_child(shop)
	shop._build_floor()
	var rig := DiagnosticRig.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var player: CharacterBody3D = PLAYER.new()
	player.camera_rig_path = ^"../CameraRig"
	player.position = Vector3(27.0260849, 0.922, 3.00220108)
	player.floor_max_angle = 0.7854
	player.floor_snap_length = 0.4
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.position.y = 0.9
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	collision.shape = capsule
	player.add_child(collision)
	world.add_child(player)
	for _frame in 120:
		await tree.physics_frame
	assert_true(player.is_on_floor())
	assert_true(_actual_zero_recovery(player) <= player.safe_margin + 0.00001,
		"flat idle must meet the original recovery skin after ordinary native motion")
	assert_true(player.global_position.y >= shop.floor_top_world_at(player.global_position.x, player.global_position.z))
	var locked_at := player.global_position
	player.call("set_locomotion_enabled", false)
	Input.action_press("move_forward")
	for _frame in 60:
		await tree.physics_frame
	assert_true(player.global_position.distance_to(locked_at) <= 0.001,
		"held raw input cannot move the production locomotion-locked body")
	assert_true(_actual_zero_recovery(player) <= player.safe_margin + 0.00001,
		"effective idle must retain recovery while raw input remains held")
	Input.action_release("move_forward")
	player.call("set_locomotion_enabled", true)
	var before := player.global_position
	Input.action_press("move_forward")
	for _frame in 22:
		await tree.physics_frame
	Input.action_release("move_forward")
	var walked := Vector2(player.global_position.x - before.x, player.global_position.z - before.z).length()
	assert_true(walked >= 0.3, "real production input must resume movement")
	assert_true(walked <= 5.0 * 22.0 / 60.0 + player.safe_margin,
		"one ordinary move pass must retain the configured walk speed")
	assert_true(player.is_on_floor())
	assert_true(_actual_zero_recovery(player) <= player.safe_margin + 0.00001,
		"active movement must retain the unchanged actual skin guard")
	for _frame in 30:
		await tree.physics_frame
	assert_true(_actual_zero_recovery(player) <= player.safe_margin + 0.00001,
		"post-movement flat idle must remain clear")
	var supported_y := player.global_position.y
	shop.queue_free()
	for _frame in 45:
		await tree.physics_frame
	assert_false(player.is_on_floor(), "removed support must never retain grounded idle")
	assert_true(player.global_position.y < supported_y - 0.1)
	assert_true(player.velocity.y < 0.0, "off-floor gravity must remain downward")
	world.queue_free()
	await tree.process_frame


func _actual_zero_recovery(player: CharacterBody3D) -> float:
	var parameters := PhysicsTestMotionParameters3D.new()
	parameters.from = player.global_transform
	parameters.motion = Vector3.ZERO
	parameters.margin = player.safe_margin
	parameters.recovery_as_collision = true
	parameters.max_collisions = 8
	var result := PhysicsTestMotionResult3D.new()
	PhysicsServer3D.body_test_motion(player.get_rid(), parameters, result)
	return result.get_travel().length()


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
	assert_eq(result.get("assertions", 0), 23, "all support, placement and actual idle/resume/fall assertions must finish")
	assert_true(result.get("completed", false), combined)
	var native_log := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	assert_false(native_log.is_empty(), "the actual child must retain its full native log")
	combined += "\n" + native_log
	assert_false(combined.contains("ERROR:") or combined.contains("SCRIPT ERROR"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
