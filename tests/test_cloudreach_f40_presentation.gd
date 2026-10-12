extends "res://tests/test_case.gd"

const MERGE := preload("res://scripts/world/cloudreach_visual_candidate.gd")
const AVIARY := preload("res://scripts/world/cloudreach_aviary.gd")
const CROWN := preload("res://scripts/world/cloudreach_aviary_crown.gd")
const SANCTUARY := preload("res://scripts/world/cloudreach_aviary_sanctuary.gd")


func test_candidate_keeps_collision_contract_and_baseline_immutable() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MERGE.PATH))
	var combined := MERGE._merge(base, candidate.aviary)
	assert_true(candidate.enabled)
	assert_true(base.crown_arcade.enabled)
	assert_true(combined.towers.enabled)
	for field: String in ["throat", "drum", "arches", "footprint", "dome", "pylon_anchor"]:
		assert_eq(combined[field], base[field], "candidate preserves " + field)
	assert_true(AVIARY.throat_clear(combined))


func test_crown_and_garden_are_repeatable_without_new_collision() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MERGE.PATH))
	var spec := MERGE._merge(base, candidate.aviary)
	var root := Node3D.new()
	var material := StandardMaterial3D.new()
	var materials := {"stone": material, "masonry": material}
	var built := AVIARY.build(root, materials, spec)
	var original_collision := root.find_children("*", "CollisionObject3D", true, false).size()
	var crown := CROWN.build(root, spec.crown_arcade, spec.drum, material, material)
	SANCTUARY.build(root, spec.sanctuary, built.arches, materials)
	var child_count := root.get_child_count()
	assert_eq(crown.get_child_count(), 22)
	assert_eq(crown.find_children("CrownBay*", "Node3D", false, false).size(), 20)
	for name_key: String in ["CrownEntablature", "CrownWeatheringCourse"]:
		var cornice := crown.get_node_or_null(NodePath(name_key)) as MeshInstance3D
		assert_true(cornice != null and cornice.mesh != null, "the named cornice course exists: " + name_key)
	assert_eq(root.find_children("SanctuaryPlanter*", "Node3D", true, false).size(), 4)
	assert_eq(root.find_children("*", "CollisionObject3D", true, false).size(), original_collision)
	assert_eq(CROWN.build(root, spec.crown_arcade, spec.drum, material, material), crown)
	SANCTUARY.build(root, spec.sanctuary, built.arches, materials)
	assert_eq(root.get_child_count(), child_count, "repeated presentation build does not duplicate props/lights")
	root.free()


func test_parked_gallery_gate_owns_core_meshes_and_light_overrides() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MERGE.PATH))
	var spec := MERGE._merge(base, candidate.aviary)
	assert_false(spec.crown_arcade.upper_gallery.enabled, "rejected P2-022 candidate ships OFF")
	for enabled: bool in [false, true]:
		var crown_spec: Dictionary = spec.crown_arcade.duplicate(true)
		crown_spec.upper_gallery.enabled = enabled
		var root := Node3D.new()
		var material := StandardMaterial3D.new()
		var crown := CROWN.build(root, crown_spec, spec.drum, material, material)
		assert_eq(root.has_node("AviaryUpperGallery"), enabled)
		assert_eq(crown.has_node("UpperGalleryLedge"), enabled)
		assert_eq(crown.find_children("CrownLanternFlame*", "Node3D", true, false).size(), 5 if enabled else 0)
		var lights := crown.find_children("CrownLanternLight*", "OmniLight3D", true, false)
		assert_eq(lights.size(), 5, "OFF preserves every original crown light")
		for light: OmniLight3D in lights:
			assert_almost_eq(light.light_energy, 2.0 if enabled else 1.5)
			assert_almost_eq(light.omni_range, 16.0 if enabled else 10.0)
			assert_eq(light.position, Vector3(-(8.15 - 0.8) * 0.5, 1.4, 1.3 * 0.5 + 0.8))
			assert_eq(light.light_color, Color("#ffbe7b"))
			assert_false(light.shadow_enabled)
		assert_eq(root.find_children("*", "CollisionObject3D", true, false).size(), 0)
		root.free()
	assert_false(spec.crown_arcade.upper_gallery.enabled, "preview builds do not mutate the shipping config")


func test_parked_gallery_restores_baseline_membrane_and_retains_opt_in() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MERGE.PATH))
	var spec := MERGE._merge(base, candidate.aviary)
	assert_almost_eq(float(base.membrane.to_rib_fraction), 0.35)
	assert_almost_eq(float(spec.crown_arcade.upper_gallery.membrane_to_rib_fraction), 0.78)
	var radius := float(spec.dome.radius_m)
	var centre_y := float(spec.drum.height_m)
	var alpha_top := asin(float(spec.dome.oculus_radius_m) / radius)
	var dome := {"sphere_radius": radius, "sphere_centre_y": centre_y, "apex_alpha": alpha_top}
	for mode: int in [0, 1, 2]:
		var configured := spec.duplicate(true)
		configured.crown_arcade.upper_gallery.enabled = mode != 0
		configured.crown_arcade.enabled = mode != 2
		var root := Node3D.new()
		var panels := AVIARY._build_membrane(root, configured, dome, {})
		assert_eq(panels.size(), 20, "the gate retains the existing panel/gap count")
		var minimum_y := INF
		var maximum_y := -INF
		for panel: MeshInstance3D in panels:
			var vertices: PackedVector3Array = panel.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				minimum_y = minf(minimum_y, vertex.y)
				maximum_y = maxf(maximum_y, vertex.y)
		var fraction := 0.78 if mode == 1 else 0.35
		assert_almost_eq(maximum_y, centre_y + radius * sin(fraction * (PI * 0.5 - alpha_top)), 0.001)
		if mode == 1:
			assert_true(minimum_y > centre_y + 10.0, "ON retains the gallery glazing clearance")
		else:
			assert_almost_eq(minimum_y, centre_y, 0.001, "OFF restores the original membrane rim")
		root.free()
	assert_almost_eq(float(spec.membrane.to_rib_fraction), 0.35, 0.0001, "building never rewrites baseline data")
