extends "res://tests/test_case.gd"

## close-1024 MESHY 10: a landmark with `trimesh_collider` gets collision that
## follows its drawn mesh, so a flyer meets the Veilfall crown it can see rather
## than passing through it (the capped terrain below already matches its draw).
const LANDMARKS := preload("res://scripts/world/water_landmark_models.gd")


func test_trimesh_collision_follows_every_drawn_mesh() -> void:
	var root := Node3D.new()
	var a := MeshInstance3D.new()
	a.mesh = BoxMesh.new()
	var b := MeshInstance3D.new()
	b.mesh = SphereMesh.new()
	b.position = Vector3(3.0, 1.0, 0.0)
	root.add_child(a)
	a.add_child(b)
	var bodies: Array = LANDMARKS.add_trimesh_collision(root)
	assert_eq(bodies.size(), 2, "one body per drawn mesh")
	for body: StaticBody3D in bodies:
		var shape := body.get_child(0) as CollisionShape3D
		assert_true(shape.shape is ConcavePolygonShape3D, "the shape is the drawn triangle mesh")
		assert_true((shape.shape as ConcavePolygonShape3D).get_faces().size() > 0, "the shape has faces")
	assert_eq(bodies[0].get_parent(), a, "collision rides the mesh's own transform")
	root.free()


func test_the_veilfall_crown_candidate_asks_for_drawn_collision() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/tidewake_look.json"))
	var crown: Array = raw.get("veilfall_mountain_candidate", [])
	assert_false(crown.is_empty(), "precondition: the crown candidate exists")
	assert_true(bool(crown[0].get("trimesh_collider", false)), "the crown collides where it is drawn")
