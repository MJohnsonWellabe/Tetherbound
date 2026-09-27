extends "res://tests/test_case.gd"

## F04 (Warden Aldis's fight): exterior banner cloth had no collider and the
## fight camera parked behind it. Each hung banner now carries a thin box over
## its cloth on the camera rig's occlusion-only layer, colliding with nothing.

const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const CAMERA_RIG := preload("res://scripts/player/camera_rig.gd")


func test_a_hung_banner_carries_a_camera_only_occluder_over_its_cloth() -> void:
	var hold: Node3D = STRONGHOLD.new()
	hold.call("_hang_banner", Vector3(1.0, 5.0, 2.0), 0.0)
	var banner := hold.get_node_or_null(^"ExteriorBanner") as Node3D
	assert_true(banner != null, "the banner is hung")
	if banner == null:
		hold.free()
		return
	var cloth := banner.get_node_or_null(^"BannerCloth") as Node3D
	var occluder := banner.get_node_or_null(^"CameraOccluder") as StaticBody3D
	assert_true(occluder != null, "the banner carries a CameraOccluder")
	if occluder != null and cloth != null:
		assert_eq(occluder.collision_layer, CAMERA_RIG.OCCLUSION_ONLY_LAYER,
			"on the rig's occlusion-only layer")
		assert_eq(occluder.collision_mask, 0, "it collides with nothing itself")
		assert_eq(occluder.position, cloth.position, "centred on the cloth")
		var box := (occluder.get_child(0) as CollisionShape3D).shape as BoxShape3D
		var width := float(STRONGHOLD.BANNER_CLOTH_W) * float(STRONGHOLD.BANNER_SCALE)
		var height := float(STRONGHOLD.BANNER_CLOTH_H) * float(STRONGHOLD.BANNER_SCALE)
		assert_almost_eq(box.size.y, height, 0.001, "as tall as the cloth")
		assert_almost_eq(box.size.z, width, 0.001, "as wide as the cloth")
	hold.free()
