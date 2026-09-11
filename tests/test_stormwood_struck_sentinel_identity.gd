extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/stormwood_struck_sentinel.gd")
const WORLD := preload("res://scripts/world/stormwood_world.gd")
const WORLD_SOURCE := "res://scripts/world/stormwood_world.gd"
const WORLD_CONFIG := "res://data/config/stormwood_world.json"
const TRAINERS_CONFIG := "res://data/config/stormwood_trainers.json"


func test_struck_sentinel_is_a_readable_visual_only_landmark_off_the_road_seat() -> void:
	var presentation := PRESENTATION.new()
	presentation.call("build")
	var elder := presentation.get_node_or_null(^"LightningSplitElder") as Node3D
	assert_true(elder != null, "The Struck Sentinel lost its installed elder silhouette")
	if elder != null:
		assert_true(elder.scale.x >= 4.2 and elder.scale.x <= 4.6,
			"the 9.5m native elder no longer lands near a 40-44m landmark height")
	assert_true(presentation.get_node_or_null(^"FallenCrownLimb") != null,
		"the sentinel no longer reads as lightning-broken")
	assert_true(presentation.get_node_or_null(^"CharredRootPlate") != null,
		"the lightning story has no grounded blast footprint")
	var scar := presentation.get_node_or_null(^"LightningSplitScar") as Node3D
	assert_true(scar != null and scar.get_child_count() >= 9,
		"the dead tree lost its readable split-scar energy path")
	if scar != null:
		for child: Node in scar.get_children():
			var mesh := child as MeshInstance3D
			assert_true(mesh != null and mesh.material_override is StandardMaterial3D
				and (mesh.material_override as StandardMaterial3D).emission_enabled,
				"a lightning-scar segment is no longer emissive")
	var light := presentation.get_node_or_null(^"StrikeAfterglow") as OmniLight3D
	assert_true(light != null and light.omni_range <= 24.0 and light.light_energy <= 2.25,
		"the sentinel lost its restrained local night focus")
	assert_true(presentation.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"visual landmark dressing changed route or encounter collision")
	presentation.free()


func test_landmark_seat_and_ranger_pax_stay_authoritative_while_visual_moves_clear() -> void:
	assert_true(WORLD != null, "production Stormwood no longer parses with the sentinel presentation")
	var offset := PRESENTATION.visual_offset_xz()
	assert_true(offset.length() >= 30.0 and offset.length() <= 32.0,
		"the visual elder can collapse the spring camera at the canonical landmark seat")
	var route_a := Vector2(-300.0, 180.0)
	var route_b := Vector2(-350.0, 450.0)
	var visual_at := Vector2(-320.0, 240.0) + offset
	assert_true(visual_at.distance_to(Geometry2D.get_closest_point_to_segment(
		visual_at, route_a, route_b)) >= 18.0,
		"the giant visual trunk moved back onto critical Ash Road")
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_CONFIG))
	var landmark := _entry(world.get("landmarks", []), "struck_sentinel")
	assert_eq(landmark.get("position", []), [-320.0, 28.0, 240.0],
		"the canonical map/discovery seat moved instead of only its presentation")
	var trainers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TRAINERS_CONFIG))
	var pax := _entry(trainers.get("trainers", []), "ranger_pax_sentinel")
	assert_eq(pax.get("position", []), [-320.0, 29.92, 240.0],
		"the bounded visual recovery moved Ranger Pax's encounter")
	var source := FileAccess.get_file_as_string(WORLD_SOURCE)
	assert_true(source.contains('sentinel.name = "StruckSentinelPresentation"'),
		"the production Stormwood world does not install the location presentation")
	assert_false(source.contains('DeadTree_1.gltf",sentinel,5.0'),
		"the camera-blocking tree still occupies the canonical landmark seat")


func _entry(entries: Array, wanted: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == wanted:
			return raw as Dictionary
	return {}
