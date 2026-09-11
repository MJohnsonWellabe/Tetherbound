extends "res://tests/test_case.gd"

const IDENTITY := preload("res://scripts/world/mill_pond_identity.gd")
const VILLAGE := preload("res://scripts/world/village.gd")


func test_pond_mill_builds_a_large_bank_facing_water_wheel() -> void:
	var identity: Node3D = IDENTITY.new()
	identity.call("build")
	assert_eq(identity.name, "PondMillIdentity")
	assert_true(identity.position.distance_to(Vector3(-4.3, 2.15, 0.0)) < 0.01,
		"the readable wheel drifted off the mill's west wall and stream race")
	assert_true(identity.get_node_or_null("Rim") != null,
		"the Pond mill has no readable circular rim")
	assert_true(identity.get_node_or_null("Axle") != null,
		"the Pond mill wheel has no axle connection to the building")
	assert_true(identity.get_node_or_null("WheelWash") != null,
		"the wheel no longer makes visible contact with the stream")
	assert_true(identity.get_node_or_null("IronTyre") != null,
		"the Pond wheel has no material break between timber rim and iron tyre")
	assert_true(identity.get_node_or_null("IronHubOuter") != null and
		identity.get_node_or_null("IronHubInner") != null,
		"the Pond wheel axle has no believable hub connection")

	var spokes := 0
	var paddles := 0
	var straps := 0
	for child: Node in identity.get_children():
		if child.name.begins_with("Spoke"):
			spokes += 1
		elif child.name.begins_with("Paddle"):
			paddles += 1
		elif child.name.begins_with("RimStrap"):
			straps += 1
	assert_eq(spokes, 10, "the water wheel lost its radial spoke rhythm")
	assert_eq(paddles, 10, "the water wheel lost its working paddle rhythm")
	assert_eq(straps, 10, "the wheel lost its iron fastening rhythm")
	var rim := identity.get_node(^"Rim") as MeshInstance3D
	var rim_material := rim.material_override as StandardMaterial3D
	assert_true(rim_material != null and rim_material.albedo_texture != null and
		rim_material.normal_texture != null and rim_material.uv1_triplanar,
		"the hero wheel timber regressed to flat brown primitive material")
	identity.free()


func test_pond_route_head_has_a_bounded_reveal_clearing() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/bands/band1_lower_meadows/vegetation.json"))
	assert_true(parsed is Dictionary, "Band 1 vegetation config did not parse")
	if not parsed is Dictionary:
		return
	var found := false
	var lens_found := false
	for raw: Variant in (parsed as Dictionary).get("clearings", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 1912:
			var clearing := raw as Dictionary
			found = true
			var radius := float(clearing.get("radius", 0.0))
			assert_between(radius, 12.0, 15.0,
				"Pond reveal clearing is missing or strips the wider pocket")
			var centre := Vector2(float(clearing.x), float(clearing.z))
			assert_true(centre.distance_to(Vector2(-320.0, 484.0)) <= radius and
				centre.distance_to(Vector2(-330.0, 492.0)) <= radius,
				"Pond reveal clearing no longer covers both route head and pulled-back eye")
		elif raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 1913:
			var lens := raw as Dictionary
			lens_found = true
			assert_between(float(lens.get("radius", 0.0)), 7.0, 9.0,
				"Pond mill sightline lens is missing or too broad")
			assert_true(Vector2(float(lens.x), float(lens.z)).distance_to(
				Vector2(-366.5, 506.5)) <= 3.0,
				"Pond mill sightline lens drifted off the exact camera-to-mill segment")
	assert_true(found, "the obstructed Pond route head has no bounded reveal opening")
	assert_true(lens_found, "the ranger-to-mill canopy seam still blocks the Pond reveal")


func test_village_routes_only_the_mill_to_the_pond_identity() -> void:
	var village: Node3D = VILLAGE.new()
	var mill := Node3D.new()
	village.call("_exterior_identity", mill, "mill")
	assert_true(mill.get_node_or_null("PondMillIdentity") != null,
		"the production village mill did not receive its working silhouette")

	var unrelated := Node3D.new()
	village.call("_exterior_identity", unrelated, "cottage_a")
	assert_eq(unrelated.get_child_count(), 0,
		"the Pond-specific identity leaked onto another village prefab")
	mill.free()
	unrelated.free()
	village.free()
