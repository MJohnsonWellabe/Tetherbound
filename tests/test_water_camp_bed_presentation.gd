extends "res://tests/test_case.gd"

## Geometry/ownership bounds only; native captures must judge padded identity,
## terrain contact and overlap with the actual resting creature silhouettes.
const PRESENTATION := preload("res://scripts/world/water_camp_bed_presentation.gd")
const BED := preload("res://scripts/build/creature_bed.gd")


func _config() -> Dictionary:
	var config := PRESENTATION.settings()
	config.enabled = true
	return config


func test_default_off_and_nonwater_beds_add_nothing() -> void:
	assert_false(bool(PRESENTATION.settings().get("enabled", true)))
	var bed := Node3D.new()
	bed.name = "water_camp_first_shore_creature_bed"
	assert_eq(PRESENTATION.attach(bed), null)
	assert_eq(bed.get_child_count(), 0)
	bed.name = "PlayerBuiltCreatureBed"
	assert_eq(PRESENTATION.attach(bed, _config()), null)
	assert_eq(bed.get_child_count(), 0)
	bed.free()


func test_decoration_preserves_bed_transform_collider_and_prompt() -> void:
	var bed := Node3D.new()
	bed.name = "water_camp_first_shore_creature_bed"
	bed.transform = Transform3D(Basis(Vector3.UP, 0.4), Vector3(7, 6, 142))
	var collider := StaticBody3D.new()
	collider.collision_layer = 2
	bed.add_child(collider)
	var prompt := Node3D.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0, 0.6, 0.7)
	bed.add_child(prompt)
	var before := bed.transform
	var prompt_before := prompt.transform
	var decoration := PRESENTATION.attach(bed, _config())
	assert_true(decoration != null)
	assert_eq(PRESENTATION.attach(bed, _config()), decoration)
	assert_eq(bed.get_child_count(), 3)
	assert_true(bed.transform.is_equal_approx(before))
	assert_true(prompt.transform.is_equal_approx(prompt_before))
	assert_eq(collider.collision_layer, 2)
	assert_eq(decoration.find_children("*", "CollisionObject3D", true, false).size(), 0)
	assert_eq(decoration.find_children("*", "CollisionShape3D", true, false).size(), 0)
	bed.free()
	assert_false(is_instance_valid(decoration))


func test_padding_leaves_entry_and_central_rest_ellipse_clear() -> void:
	var bed := Node3D.new()
	bed.name = "water_camp_salt_crown_creature_bed"
	var decoration := PRESENTATION.attach(bed, _config())
	assert_eq(decoration.get_child_count(), 9)
	var highest := 0.0
	var minimum_central_ellipse := INF
	var entry_blocked := false
	for pad: MeshInstance3D in decoration.get_children():
		var arrays := pad.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for vertex: Vector3 in vertices:
			var at := pad.transform * vertex
			highest = maxf(highest, at.y)
			# A 3.2 x 2.6m central ellipse remains unoccupied at every height.
			minimum_central_ellipse = minf(minimum_central_ellipse,
				pow(at.x / 1.6, 2.0) + pow(at.z / 1.3, 2.0))
			# Front entry corridor (+Z) remains open beyond the rest centre.
			entry_blocked = entry_blocked or (absf(at.x) < 1.0 and at.z > 0.0)
		var material := pad.material_override as StandardMaterial3D
		assert_eq(material.albedo_texture.resource_path, BED.PAD_CANVAS_ALBEDO)
		assert_eq(material.normal_texture.resource_path, BED.PAD_CANVAS_NORMAL)
		assert_true(material.uv1_triplanar)
	assert_true(minimum_central_ellipse >= 1.0)
	assert_false(entry_blocked)
	assert_between(highest, 0.60, 0.70)
	assert_eq(BED.REST_ANCHOR, Vector3(0, 0.29, 0))
	bed.free()
