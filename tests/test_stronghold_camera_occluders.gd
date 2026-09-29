extends "res://tests/test_case.gd"

## F04#7 C3 / M3 (judge r4 7121d40c; capture_named_fight --lens-probe): the
## Warden's fight was drawn from inside the Hall's decoration, which is never
## solid. Each decoration box and interior-structure member carries a
## camera-only body: it stops the lens and nothing else.

const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const INTERIOR := preload("res://scripts/world/interior_structure.gd")
const CAMERA_RIG := preload("res://scripts/player/camera_rig.gd")


func _assert_camera_only(body: StaticBody3D, size: Vector3, what: String) -> void:
	assert_true(body != null, "%s carries a camera occluder" % what)
	if body == null:
		return
	assert_eq(body.collision_layer, CAMERA_RIG.OCCLUSION_ONLY_LAYER, "%s: on the rig's occlusion-only layer" % what)
	assert_eq(body.collision_mask, 0, "%s: collides with nothing itself" % what)
	assert_eq(body.collision_layer & 1, 0, "%s: not on layer 1, so nobody stands on it" % what)
	var box := (body.get_child(0) as CollisionShape3D).shape as BoxShape3D
	assert_eq(box.size, size, "%s: the decoration's own box" % what)


func test_a_decoration_box_stops_the_lens_but_a_solid_box_keeps_its_wall() -> void:
	var hall: Node3D = STRONGHOLD.new()
	hall.call("_box", Vector3(0.6, 0.5, 26.0), Vector3(1.0, 4.0, 2.0), StandardMaterial3D.new(), false)
	var bodies := hall.find_children("*", "StaticBody3D", false, false)
	assert_eq(bodies.size(), 1, "one body for one decoration box")
	_assert_camera_only(bodies[0] as StaticBody3D, Vector3(0.6, 0.5, 26.0), "a trim band")
	assert_eq((bodies[0] as Node3D).position, Vector3(1.0, 4.0, 2.0), "placed on the band")
	hall.call("_box", Vector3(1.0, 6.0, 1.0), Vector3.ZERO, StandardMaterial3D.new(), true)
	var solid := 0
	for node: Node in hall.find_children("*", "StaticBody3D", false, false):
		if (node as StaticBody3D).collision_layer & 1:
			solid += 1
	assert_eq(solid, 1, "a solid wall is still a wall")
	hall.free()


func test_interior_structure_members_stop_the_lens() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/interior_structure.gd")
	var member := source.substr(source.find("func _member("))
	member = member.substr(0, member.find("\nfunc ", 10))
	assert_true(member.contains("collision_layer = CAMERA_OCCLUSION_ONLY_LAYER"),
		"every member adds a camera-only occluder")
	assert_eq(INTERIOR.CAMERA_OCCLUSION_ONLY_LAYER, CAMERA_RIG.OCCLUSION_ONLY_LAYER, "the rig's own layer")
