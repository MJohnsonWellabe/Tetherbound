extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/cloudreach_realm_gate_crag.gd")


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION.CONFIG_PATH))
	return parsed as Dictionary if parsed is Dictionary else {}


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["path", "masonry", "masonry_trim", "bronze", "key_glow"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#78909a")
		result[key] = material
	return result


func test_realm_gate_crag_presentation_has_complete_arrival_hierarchy() -> void:
	var cfg := _config()
	assert_eq(str(cfg.get("landmark_id", "")), "realm_gate_crag")
	assert_eq((cfg.get("approach_pavers", []) as Array).size(), 3)
	assert_eq((cfg.get("outer_buttresses", []) as Array).size(), 2)
	assert_eq((cfg.get("arrival_beacons", []) as Array).size(), 2)
	assert_true(float((cfg.get("banner", {}) as Dictionary).get("forward_z_m", 0.0)) <= -3.0,
		"banner cloth must sit in front of the imported masonry facade")
	assert_true(float((cfg.get("beacon_light", {}) as Dictionary).get("range_m", 0.0)) >= 32.0,
		"arrival beacons must carry local night fill to the gate crown")
	assert_true(PRESENTATION.route_clear_half_width(cfg) >= 4.5,
		"the ceremonial layer must preserve a broad player route")
	var presentation := PRESENTATION.new()
	presentation.build(_materials())
	var roles := {}
	var collision_count := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("gate_role", ""))
		if not role.is_empty():
			roles[role] = int(roles.get(role, 0)) + 1
		if child is CollisionObject3D:
			collision_count += 1
	assert_eq(int(roles.get("approach_paver", 0)), 3)
	assert_eq(int(roles.get("outer_buttress", 0)), 2)
	assert_eq(int(roles.get("realm_banner", 0)), 2)
	assert_eq(int(roles.get("banner_sigil", 0)), 4)
	assert_eq(int(roles.get("realm_emblem", 0)), 1)
	assert_eq(int(roles.get("realm_emblem_core", 0)), 1)
	assert_eq(int(roles.get("arrival_flame", 0)), 2)
	assert_eq(int(roles.get("arrival_light", 0)), 2)
	assert_eq(collision_count, 0,
		"presentation dressing must not change the production gate collision")
	# Every low, bulky decoration stays outside the open route. Pavers are the
	# intentional flush ground treatment and are excluded from this clearance test.
	var route_half := PRESENTATION.route_clear_half_width(cfg)
	for child: Node in presentation.get_children():
		if child is not MeshInstance3D or str(child.get_meta("gate_role", "")) == "approach_paver":
			continue
		var mesh := child as MeshInstance3D
		var world_bounds := _transformed_bounds(mesh)
		if world_bounds.position.y >= 5.0:
			continue
		assert_true(world_bounds.end.x <= -route_half or world_bounds.position.x >= route_half,
			"low decoration %s intrudes into the open route" % child.name)
	presentation.free()


func test_cloudreach_world_mounts_the_dedicated_gate_presentation() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("const REALM_GATE_CRAG_PRESENTATION := preload("))
	assert_true(source.contains("ledge_size = Vector3(58.0, 36.0, 54.0)"),
		"the arrival gate must not inherit the generic 72 m occluding cliff drum")
	assert_true(source.contains("var facade_origin := Vector3(-24.0, -34.0, -29.0)"),
		"the gatehouse must meet the real arrival road on the crag face")
	assert_true(source.contains("presentation.name = \"RealmGateCragPresentation\""))
	assert_true(source.contains("presentation.call(\"build\", _materials)"))
	assert_false(source.contains("\"GateFoundationCrag\""),
		"a second nested crag would hide the arrival gate again")


func test_named_location_catalogue_stands_on_the_approach_not_inside_the_gate() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/debug_teleport_spots.json"))
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var found := {}
	for biome_raw: Variant in (parsed as Dictionary).get("biomes", []):
		var biome := biome_raw as Dictionary
		if str(biome.get("id", "")) != "cloudreach":
			continue
		for band_raw: Variant in biome.get("bands", []):
			for spot_raw: Variant in (band_raw as Dictionary).get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Realm Gate Crag":
					found = spot
	assert_false(found.is_empty())
	assert_eq(found.get("position", []), [-15.5, -202.0])
	assert_almost_eq(float(found.get("view_heading_deg", 0.0)), -11.0, 0.001)
	var stand := Vector2(-15.5, -202.0)
	var landmark := Vector2(0.0, -130.0)
	assert_true(stand.distance_to(landmark) >= 70.0,
		"the catalogue must frame the full landmark instead of spawning inside it")


func _transformed_bounds(mesh: MeshInstance3D) -> AABB:
	var local := mesh.get_aabb()
	var result := AABB()
	var found := false
	for x: float in [local.position.x, local.end.x]:
		for y: float in [local.position.y, local.end.y]:
			for z: float in [local.position.z, local.end.z]:
				var point := mesh.transform * Vector3(x, y, z)
				if not found:
					result = AABB(point, Vector3.ZERO)
					found = true
				else:
					result = result.expand(point)
	return result
