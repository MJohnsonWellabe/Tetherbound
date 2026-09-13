extends "res://tests/test_case.gd"

## Focused contract for the authored Stronghold Approach composition. The
## occupation beats must remain tall enough to read across the open meadow and
## outside the real road, whose centreline is the player's traversal contract.

const PROPS_PATH := "res://data/config/bands/band5_stronghold_approach/props.json"
const SPAWNS_PATH := "res://data/config/bands/band5_stronghold_approach/spawns.json"
const VEGETATION_PATH := "res://data/config/bands/band5_stronghold_approach/vegetation.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const STRONGHOLD_PATH := "res://data/config/stronghold.json"
const CAPTURE_PATH := "res://tools/capture_stronghold_approach_identity.gd"
const REQUIRED_TALL_READS := [
	"OuterWatchStandard",
	"RoadDropStandard",
	"GatewardStandardWest",
	"GatewardStandardEast",
	"HallwardStandardWest",
	"HallwardStandardEast",
]


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _clusters() -> Array:
	return _read_json(PROPS_PATH).get("clusters", []) as Array


func _cluster_named(wanted: String) -> Dictionary:
	for raw: Variant in _clusters():
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == wanted:
			return cluster
	return {}


func _prop_named(wanted: String) -> Dictionary:
	for raw_cluster: Variant in _clusters():
		for raw_prop: Variant in (raw_cluster as Dictionary).get("props", []):
			var prop := raw_prop as Dictionary
			if str(prop.get("name", "")) == wanted:
				return prop
	return {}


func _retint_colour(prop: Dictionary, surface: String) -> String:
	var value: Variant = (prop.get("retint", {}) as Dictionary).get(surface, "")
	if value is Dictionary:
		return str((value as Dictionary).get("color", ""))
	return str(value)


func _stronghold_spine() -> PackedVector2Array:
	var result := PackedVector2Array()
	var trail := _read_json(TERRAIN_PATH).get("trail", {}) as Dictionary
	for raw: Variant in trail.get("bands", []):
		var route := raw as Dictionary
		if str(route.get("id", "")) != "band5_stronghold_approach":
			continue
		for point: Variant in route.get("points", []):
			result.append(Vector2(float(point[0]), float(point[1])))
	return result


func _distance_to_polyline(point: Vector2, line: PackedVector2Array) -> float:
	var nearest := INF
	for index in line.size() - 1:
		var a := line[index]
		var b := line[index + 1]
		var ab := b - a
		var t := clampf((point - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + ab * t))
	return nearest


func _asset_exists(prop: Dictionary) -> bool:
	var dir := str(prop.get("dir", "res://assets/props/quaternius_fantasy"))
	var model := str(prop.get("model", ""))
	for extension in ["gltf", "glb", "obj"]:
		if ResourceLoader.exists("%s/%s.%s" % [dir, model, extension]):
			return true
	return false


func _spawn_order(wanted: int) -> Dictionary:
	for raw: Variant in _read_json(SPAWNS_PATH).get("spawns", []):
		var spawn := raw as Dictionary
		if int(spawn.get("order", -1)) == wanted:
			return spawn
	return {}


func _file_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func test_three_occupation_beats_lead_toward_the_hall() -> void:
	var outer := _cluster_named("outer_watch_cache")
	var middle := _cluster_named("road_watch_drop")
	var final := _cluster_named("gateward_processional_threshold")
	var overlook := _cluster_named("hallward_overlook")
	assert_false(outer.is_empty(), "the approach keeps its foreground watch")
	assert_false(middle.is_empty(), "the approach keeps its mid-ground road drop")
	assert_false(final.is_empty(), "the approach keeps its final paired threshold")
	assert_false(overlook.is_empty(), "the final bend keeps its Hall-framing overlook")
	assert_eq(int(final.get("order", -1)), 5003, "the new beat uses the band-reserved order range")
	assert_eq(int(overlook.get("order", -1)), 5004,
		"the Hall overlook uses the next band-reserved order")
	for wanted in REQUIRED_TALL_READS:
		var prop := _prop_named(wanted)
		assert_false(prop.is_empty(), "%s remains authored" % wanted)
		assert_eq(str(prop.get("model", "")), "Banner_1",
			"%s uses the full installed vertical standard, not the retired cutout" % wanted)
		assert_between(float(prop.get("scale", 0.0)), 1.5, 1.6,
			"%s keeps the accepted full-standard landscape scale" % wanted)
		assert_eq(_retint_colour(prop, "MI_Banner"), "#7a2430",
			"%s keeps Team Tether's oxblood reservation" % wanted)


func test_approach_replaces_arrow_pennants_with_seated_vertical_standards() -> void:
	var spine := _stronghold_spine()
	for wanted in REQUIRED_TALL_READS:
		var prop := _prop_named(wanted)
		assert_eq(str(prop.get("dir", "")), "res://assets/props/quaternius_fantasy",
			"%s stays in the installed shared prop family" % wanted)
		assert_between(float(prop.get("scale", 0.0)), 1.5, 1.6,
			"%s keeps the measured 3.6-3.8m vertical read" % wanted)
		assert_between(float(prop.get("sink_m", 0.0)), -2.5, -2.3,
			"%s lifts the source mesh's below-origin extent onto the verge" % wanted)
		var raw_at := prop.get("at", []) as Array
		var at := Vector2(float(raw_at[0]), float(raw_at[1]))
		var required_clearance := 9.5 if str(wanted).begins_with("Hallward") else 5.0
		assert_true(_distance_to_polyline(at, spine) >= required_clearance,
			"%s keeps centre clearance for its wider vertical rig" % wanted)


func test_authored_approach_props_are_installed_and_leave_the_road_open() -> void:
	var spine := _stronghold_spine()
	assert_true(spine.size() >= 6, "the production Band 5 spine still exists")
	for wanted in REQUIRED_TALL_READS + ["OuterWatchWagon", "RoadDropSignalRing", "RoadDropSignalFire",
			"GatewardFenceWest", "GatewardFenceEast", "GatewardCrateWest", "GatewardBarrelEast",
			"HallwardTorchWest", "HallwardTorchEast", "HallwardFenceWest", "HallwardFenceEast",
			"HallwardWeaponStand", "HallwardSupplyCrate", "HallwardSupplyWagon",
			"HallGateBeaconWest", "HallGateBeaconEast"]:
		var prop := _prop_named(wanted)
		assert_false(prop.is_empty(), "%s remains authored" % wanted)
		assert_true(_asset_exists(prop), "%s resolves to an installed production asset" % wanted)
		var raw_at := prop.get("at", []) as Array
		var at := Vector2(float(raw_at[0]), float(raw_at[1]))
		assert_true(_distance_to_polyline(at, spine) >= 5.0,
			"%s stays outside the five-metre walking corridor" % wanted)
	var wagon := _prop_named("HallwardSupplyWagon")
	assert_eq(str(wagon.get("model", "")), "Prop_Wagon", "overlook activity uses the installed freight cue")
	assert_true(_distance_to_polyline(Vector2(float(wagon.at[0]), float(wagon.at[1])), spine) >= 8.0,
		"the larger wagon keeps extra route margin")


func test_aggressor_pack_is_reachable_without_sitting_on_the_road_or_capture_stand() -> void:
	var pack := _spawn_order(5001)
	assert_eq(str(pack.get("species", "")), "galecrest", "the authored aggressor species is preserved")
	assert_eq(int(pack.get("count", 0)), 3, "the authored three-creature challenge is preserved")
	assert_eq(float((pack.get("alpha", {}) as Dictionary).get("scale", 0.0)), 1.5,
		"the boss-sized alpha is preserved")
	var at := pack.get("centre", []) as Array
	var centre := Vector2(float(at[0]), float(at[2]))
	var radius := float(pack.get("radius", 0.0))
	var road_gap := _distance_to_polyline(centre, _stronghold_spine()) - radius
	assert_between(road_gap, 5.0, 28.0,
		"the pack must clear the travelled spine while remaining an immediate reachable detour")


func test_hall_has_one_approach_crown_and_local_night_separation() -> void:
	var config := _read_json(STRONGHOLD_PATH)
	var occupation := config.get("hall_occupation", {}) as Dictionary
	var crown := {}
	for raw: Variant in occupation.get("retrofit_skyline", []):
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == "approach_crown_west":
			crown = entry
	assert_false(crown.is_empty(), "the long approach keeps a supported Hall crown cue")
	assert_eq(str(crown.get("model", "")), "team_tether_banner_rig",
		"the crown reuses the existing faction prop")
	assert_between(float(crown.get("scale", 0.0)), 1.5, 1.6,
		"the crown remains readable without becoming a tower-sized sign")
	assert_eq(float(crown.get("lift", 0.0)), 15.54, "the crown remains seated on the proven roof deck")
	var fill := {}
	for raw: Variant in config.get("lights", []):
		var light := raw as Dictionary
		if str(light.get("id", "")) == "approach_facade_fill":
			fill = light
	assert_false(fill.is_empty(), "the existing local facade-fill slot remains identifiable")
	assert_eq(str(fill.get("type", "")), "spot",
		"the existing fill slot must rake the approach and facade instead of losing an omni at the per-object cap")
	assert_eq(str(fill.get("colour", "")), "#8fa6c8", "night separation stays cool beneath warm fires")
	assert_eq(fill.get("at", []), [0.0, -40.0], "the rake light left the production ramp")
	assert_eq(fill.get("aim", []), [0.0, -10.0], "the rake light no longer faces the Hall")
	assert_between(float(fill.get("angle", 0.0)), 80.0, 84.0, "facade rake became a pin spot or a hemisphere")
	assert_between(float(fill.get("energy", 0.0)), 5.6, 6.0, "local fill became ineffective or a floodlight")
	assert_between(float(fill.get("range", 0.0)), 56.0, 60.0, "local fill no longer spans ramp and gate mass")
	assert_between(float(fill.get("attenuation", 0.0)), 0.8, 0.9,
		"facade rake no longer carries a bounded falloff across the Hall base")


func test_capture_faces_the_hall_and_fails_closed_on_near_wildlife() -> void:
	var source := _file_text(CAPTURE_PATH)
	assert_true(source.contains("final-stronghold-approach-04"), "capture output was not advanced")
	assert_true(source.contains("\"target\": HALL"), "long approach views do not face the Hall")
	assert_true(source.count("\"target\": HALL") == 4, "every evidence view should preserve the Hall bearing")
	assert_true(source.contains("Vector2(-49.0, 7187.0)"),
		"arrival regressed to the pre-reveal band boundary instead of the first honest road bend")
	assert_true(source.contains("\"side\": 5.0"),
		"road-drop camera lost its bounded shoulder clearance from the foreground pylon")
	assert_true(source.contains("func _near_wildlife_blocker"), "capture does not reject giant wildlife obstruction")
	assert_true(source.contains("wildlife_clear"), "manifest omits the live obstruction receipt")


func test_midground_signal_uses_warm_fire_not_reserved_teal() -> void:
	var fire := _prop_named("RoadDropSignalFire")
	assert_eq(str(fire.get("glow", "")), "campfire", "the road drop remains readable at night")
	assert_true(float(fire.get("glow_scale", 0.0)) <= 1.0, "the signal stays punctuation, not a floodlight")
	assert_false(fire.has("retint"), "ordinary road fire does not carry a faction-colour override")
	for wanted in ["HallwardTorchWest", "HallwardTorchEast"]:
		var torch := _prop_named(wanted)
		assert_eq(str(torch.get("model", "")), "Torch_Metal",
			"final wayfinding has an installed physical source")
		assert_eq(str(torch.get("glow", "")), "campfire",
			"final wayfinding remains locally warm rather than reserved tether teal")
		assert_between(float(torch.get("glow_scale", 0.0)), 0.6, 0.8,
			"final torch is invisible or competes with the Hall")


func test_hall_gate_beacons_light_the_destination_without_blocking_the_spine() -> void:
	var spine := _stronghold_spine()
	var west := _prop_named("HallGateBeaconWest")
	var east := _prop_named("HallGateBeaconEast")
	for beacon: Dictionary in [west, east]:
		assert_false(beacon.is_empty(), "the Hall gate lost a physical night beacon")
		assert_eq(str(beacon.get("model", "")), "Torch_Metal",
			"Hall destination light has no installed physical source")
		assert_eq(str(beacon.get("glow", "")), "campfire",
			"Hall destination light stopped using the production local-light path")
		assert_between(float(beacon.get("glow_scale", 0.0)), 0.9, 1.0,
			"Hall destination light is too weak to reach stone or became a floodlight")
		var raw_at := beacon.get("at", []) as Array
		assert_eq(raw_at.size(), 2, "Hall gate beacon has no world placement")
		if raw_at.size() != 2:
			continue
		var at := Vector2(float(raw_at[0]), float(raw_at[1]))
		assert_true(_distance_to_polyline(at, spine) >= 8.0,
			"Hall gate beacon intrudes on the final walking corridor")
		assert_true(at.distance_to(Vector2(8.0, 7548.0)) <= 17.0,
			"Hall gate beacon is too far from the Outer Works face to light it")
	assert_true(Vector2(float((west.at as Array)[0]), float((west.at as Array)[1])).y
		< Vector2(float((east.at as Array)[0]), float((east.at as Array)[1])).y,
		"Hall gate beacons collapsed into a kit-symmetric placement")


func test_occupation_clearings_are_local_and_keep_ground_cover() -> void:
	var expected := {20: 9.0, 21: 8.0, 22: 14.0, 23: 13.0}
	var seen := {}
	for raw: Variant in _read_json(VEGETATION_PATH).get("clearings", []):
		var clearing := raw as Dictionary
		var order := int(clearing.get("order", -1))
		if not expected.has(order):
			continue
		seen[order] = true
		assert_true(float(clearing.get("radius", INF)) <= float(expected[order]),
			"approach clearing %d stays tightly scoped" % order)
	assert_eq(seen.size(), expected.size(), "all three occupation beats are protected from canopy overlap")


func test_outer_arrival_has_a_bounded_canopy_sightline_to_the_hall() -> void:
	var clearings := _read_json(VEGETATION_PATH).get("clearings", []) as Array
	var arrival := Vector2(-49.0, 7187.0)
	var hall := Vector2(8.0, 7560.0)
	var reveal: Array[Dictionary] = []
	var hallward := {}
	for raw: Variant in clearings:
		var clearing := raw as Dictionary
		var order := int(clearing.get("order", -1))
		if order == 23:
			hallward = clearing
		if order < 24 or order > 34:
			continue
		reveal.append(clearing)
		assert_true(float(clearing.get("radius", INF)) <= 18.0,
			"outer reveal clearing %d exceeds the bounded canopy aperture" % order)
		var point := Vector2(float(clearing.get("x", INF)), float(clearing.get("z", INF)))
		assert_true(_distance_to_polyline(point, PackedVector2Array([arrival, hall])) <= 1.0,
			"outer reveal clearing %d drifted off the actual R4 arrival-to-Hall bearing" % order)
	assert_eq(reveal.size(), 11,
		"the honest outer bend needs all eleven bounded apertures")
	if reveal.size() != 11:
		return
	for index in reveal.size():
		assert_eq(int(reveal[index].order), 24 + index,
			"outer reveal apertures must remain ordered from arrival to Hall")
	var first := reveal.front() as Dictionary
	var first_point := Vector2(float(first.x), float(first.z))
	assert_true(first_point.distance_to(arrival) <= float(first.radius) - 4.0,
		"the canopy aperture no longer securely contains the ordinary arrival stand")
	for index in reveal.size() - 1:
		var left := reveal[index] as Dictionary
		var right := reveal[index + 1] as Dictionary
		var left_point := Vector2(float(left.x), float(left.z))
		var right_point := Vector2(float(right.x), float(right.z))
		var overlap := float(left.radius) + float(right.radius) - left_point.distance_to(right_point)
		assert_true(overlap >= 4.0,
			"outer reveal clearings %d and %d leave no canopy-overhang margin" % [int(left.order), int(right.order)])
	assert_false(hallward.is_empty(), "the corrected reveal lost its Hallward handoff")
	if not hallward.is_empty():
		var last := reveal.back() as Dictionary
		var last_point := Vector2(float(last.x), float(last.z))
		var hallward_point := Vector2(float(hallward.x), float(hallward.z))
		var handoff_overlap := float(last.radius) + float(hallward.radius) \
			- last_point.distance_to(hallward_point)
		assert_true(handoff_overlap >= 4.0,
			"the long reveal leaves a canopy gap before the existing Hallward aperture")
