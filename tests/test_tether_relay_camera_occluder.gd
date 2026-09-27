extends "res://tests/test_case.gd"

## F04 (Captain Vance's relay fight): the platform retrofit's service frames
## are visual-only, and the fight camera parked behind their timbers. Each
## retrofit dressing gets one box over its render bounds on the camera rig's
## occlusion-only layer -- stops the lens, adds no traversal collision.

const RELAY := preload("res://scripts/world/tether_relay.gd")
const CAMERA_RIG := preload("res://scripts/player/camera_rig.gd")


func test_occluder_covers_the_render_bounds_on_the_camera_only_layer() -> void:
	var relay: Node3D = RELAY.new()
	var scene := Node3D.new()
	var bounds := AABB(Vector3(-1.0, 0.0, -0.5), Vector3(2.0, 3.0, 1.0))
	relay.call("_add_camera_occluder", scene, bounds)
	var body := scene.get_node_or_null(^"CameraOccluder") as StaticBody3D
	assert_true(body != null, "the dressing carries a CameraOccluder body")
	if body != null:
		assert_eq(body.collision_layer, CAMERA_RIG.OCCLUSION_ONLY_LAYER,
			"on the rig's occlusion-only layer, which the arm and clear-orbit sweep mask")
		assert_eq(body.collision_mask, 0, "it collides with nothing itself")
		assert_eq(body.collision_layer & 1, 0, "not on layer 1, so the player walks as before")
		var shape := body.get_child(0) as CollisionShape3D
		var box := shape.shape as BoxShape3D if shape != null else null
		assert_true(box != null, "one box shape")
		if box != null:
			assert_eq(box.size, bounds.size, "sized to the render bounds")
			assert_eq(shape.position, bounds.get_center(), "centred on them")
	scene.free()
	relay.free()


func test_the_occluder_rides_every_retrofit_dressing() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/tether_relay.gd")
	var build := source.substr(source.find("func _build_platform_retrofit"))
	build = build.substr(0, build.find("\nfunc ", 10))
	assert_true(build.contains("_add_camera_occluder(scene, bounds)"),
		"_build_platform_retrofit adds the occluder to each placed dressing")
