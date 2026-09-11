extends "res://tests/test_case.gd"

## Focused contract for the production Old Mill approach. This pins the
## relationship the visual pass creates instead of asserting subjective image
## quality: a player approaches a real mill clearing, meets a physical sign
## with the canonical name, and does not receive the neighbouring river-region
## name at the same stand.

const MILL_CROSSING := preload("res://scripts/world/mill_crossing.gd")
const MAP_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const VEGETATION_PATH := "res://data/config/bands/band3_the_river_lock/vegetation.json"
const TELEPORT_PATH := "res://data/config/debug_teleport_spots.json"


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _entry(rows: Array, id: String) -> Dictionary:
	for raw: Variant in rows:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func test_canonical_name_is_shared_by_crossing_landmark_and_player_destination() -> void:
	var terrain := _read_json(TERRAIN_PATH)
	var crossing := _entry(terrain.get("crossings", []) as Array, "old_mill_crossing")
	var map := _read_json(MAP_PATH)
	var landmark := _entry(map.get("landmarks", []) as Array, "old_mill_crossing")
	var arrival := _entry(map.get("regions", []) as Array, "old_mill_crossing_region")
	assert_eq(str(crossing.get("label", "")), "Old Mill Crossing")
	assert_eq(str(landmark.get("display_name", "")), "Old Mill Crossing")
	assert_eq(str(arrival.get("display_name", "")), "Old Mill Crossing")
	assert_true(float(arrival.get("radius", 0.0)) >= 34.0,
		"the canonical south-bank stand is outside the Old Mill arrival region")

	var destination_name := ""
	for biome_raw: Variant in _read_json(TELEPORT_PATH).get("biomes", []):
		for band_raw: Variant in (biome_raw as Dictionary).get("bands", []):
			for spot_raw: Variant in (band_raw as Dictionary).get("spots", []):
				var spot := spot_raw as Dictionary
				if str(spot.get("display_name", "")) == "Old Mill Crossing":
					destination_name = str(spot.get("display_name", ""))
	assert_eq(destination_name, "Old Mill Crossing",
		"the Settings destination drifted from the map and physical crossing name")


func test_mill_and_sign_sightlines_are_scoped_clearings_not_bald_footprints() -> void:
	var vegetation := _read_json(VEGETATION_PATH)
	var mill_clear := false
	var sign_clear := false
	var approach_lens_clear := false
	for raw: Variant in vegetation.get("clearings", []):
		var row := raw as Dictionary
		var id := str(row.get("id", ""))
		var at := Vector2(float(row.get("x", INF)), float(row.get("z", INF)))
		if id == "old_mill_building" and at.distance_to(Vector2(-162.1, 4210.6)) < 0.2:
			mill_clear = float(row.get("radius", 0.0)) >= 15.0
		if id == "old_mill_sign" and at.distance_to(Vector2(-158.8, 4189.5)) < 0.2:
			sign_clear = float(row.get("radius", 0.0)) <= 5.0
		if id == "old_mill_approach_lens" and at.distance_to(Vector2(-157.0, 4199.0)) < 0.2:
			approach_lens_clear = float(row.get("radius", 0.0)) >= 9.5
	assert_true(mill_clear, "the installed-kit mill has no tree/sapling sightline clearing")
	assert_true(sign_clear, "the approach sign has no tightly scoped sightline clearing")
	assert_true(approach_lens_clear,
		"the ordinary south-bank camera-to-wheel lens still permits a full tree obstruction")

	for raw: Variant in vegetation.get("footprints", []):
		var row := raw as Dictionary
		var at := Vector2(float(row.get("x", INF)), float(row.get("z", INF)))
		assert_true(at.distance_to(Vector2(-162.1, 4210.6)) > 5.0,
			"the mill identity pass used a footprint and would strip its meadow ground cover")


func test_old_mill_builds_one_physical_canonical_sign_off_the_route() -> void:
	var world := FakeGroundWorld.new()
	var crossing: Node3D = MILL_CROSSING.new()
	crossing.name = "MillCrossing"
	world.add_child(crossing)
	# Exercise only the visual identity addition. Full crossing construction also
	# wires the global story ledger and therefore belongs to traversal tests.
	crossing.set("_centre", Vector2(-152.0, 4203.0))
	crossing.set("_across", Vector2(0.0, 1.0))
	crossing.set("_crossing", {"label": "Old Mill Crossing"})
	crossing.call("_build_approach_sign", world)
	var sign := world.get_node_or_null("OldMillCrossingSign") as Node3D
	assert_true(sign != null, "the ordinary approach has no physical Old Mill Crossing sign")
	if sign == null:
		world.free()
		return
	assert_eq(int(sign.call("placed")), 1,
		"the crossing sign should carry one canonical destination arm")
	var road_x := float((crossing.call("near_point", 13.5) as Vector2).x)
	assert_true(absf(sign.position.x - road_x) >= 6.0,
		"the identity sign was placed in the bridge walking line")
	world.free()


func test_old_mill_builds_a_front_facing_channel_wheel() -> void:
	var world := FakeGroundWorld.new()
	var crossing: Node3D = MILL_CROSSING.new()
	world.add_child(crossing)
	crossing.set("_centre", Vector2(-152.0, 4203.0))
	crossing.call("_build_visible_mill_wheel", world, 0.0)
	var wheel := world.get_node_or_null("OldMillWaterWheel") as Node3D
	assert_true(wheel != null, "the crossing has no readable water-wheel hero shape")
	if wheel != null:
		assert_true(wheel.get_node_or_null("Rim") != null, "the hero wheel has no circular rim")
		var paddles := 0
		for child: Node in wheel.get_children():
			if child.name.begins_with("Paddle"):
				paddles += 1
		assert_eq(paddles, 10, "the hero wheel does not carry a readable paddle rhythm")
		assert_true(wheel.position.distance_to(Vector3(-144.8, 3.0, 4201.5)) < 0.1,
			"the hero wheel drifted away from the bridge channel sightline")
	world.free()


class FakeGroundWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0
