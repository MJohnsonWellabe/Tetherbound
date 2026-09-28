extends "res://tests/test_case.gd"

## F04#6: each captain's fight leaves a visible change -- the standard beside
## them falls and they step out of the road -- derived only from the defeat
## flag, so a reload or a late joiner sees the same thing.

const AFTERMATH := preload("res://scripts/world/trainer_aftermath.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")


func test_every_captain_has_a_standard_and_a_stand_down_and_the_warden_a_show() -> void:
	for id: String in ["relay_captain", "captain_riverwatch", "captain_field", "captain_ridge"]:
		var entry := AFTERMATH.for_trainer(id)
		assert_false(TRAINERS.trainer(id).is_empty(), "%s is a real trainer" % id)
		assert_true(entry.has("standard"), "%s plants a standard" % id)
		assert_true(entry.has("stand_down"), "%s stands down" % id)
	assert_true(AFTERMATH.for_trainer("warden_aldis").has("victory_show"), "the Warden shows the key and heart")
	assert_true(AFTERMATH.for_trainer("quarry_picket_dorn").is_empty(), "an ordinary trainer changes nothing")


func test_offsets_are_in_the_body_frame_facing_plus_z() -> void:
	var at := AFTERMATH.local_offset(Vector3.ZERO, 0.0, [0.0, 2.0])
	assert_almost_eq(at.z, 2.0, 0.001, "forward is +Z at yaw 0")
	var turned := AFTERMATH.local_offset(Vector3.ZERO, PI * 0.5, [0.0, 2.0])
	assert_almost_eq(turned.x, 2.0, 0.001, "forward follows the yaw")
	var right := AFTERMATH.local_offset(Vector3.ZERO, 0.0, [1.0, 0.0])
	assert_almost_eq(right.x, -1.0, 0.001, "right is -X at yaw 0")


func test_settle_puts_a_beaten_captain_in_the_after_state() -> void:
	var holder := Node3D.new()
	var body := Node3D.new()
	holder.add_child(body)
	body.rotation.y = 0.3
	body.set_meta(AFTERMATH.HOME_META, Transform3D(Basis(Vector3.UP, 0.3), Vector3(10.0, 0.0, 20.0)))
	var standard := Node3D.new()
	holder.add_child(standard)
	var cloth := MeshInstance3D.new()
	var box := BoxMesh.new()
	var source := StandardMaterial3D.new()
	source.resource_name = "MI_Banner"
	box.material = source
	cloth.mesh = box
	standard.add_child(cloth)
	body.set_meta(AFTERMATH.STANDARD_META, standard)
	AFTERMATH.settle(body, "captain_field")
	var struck := cloth.get_surface_override_material(0) as StandardMaterial3D
	assert_ne(struck, null, "the cloth has its own material")
	assert_almost_eq(struck.albedo_color.a, 0.0, 0.001, "the standard's colours are struck")
	assert_almost_eq(source.albedo_color.a, 1.0, 0.001, "the shared Banner_1 material is untouched")
	var down: Dictionary = AFTERMATH.for_trainer("captain_field")["stand_down"]
	assert_almost_eq(body.rotation.y, 0.3 + deg_to_rad(float(down["turn_deg"])), 0.001,
		"the captain has turned from the fight")
	holder.free()
