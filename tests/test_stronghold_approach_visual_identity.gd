extends "res://tests/test_case.gd"

## Focused contract for the authored Stronghold Approach composition. The
## occupation beats must remain tall enough to read across the open meadow and
## outside the real road, whose centreline is the player's traversal contract.

const PROPS_PATH := "res://data/config/bands/band5_stronghold_approach/props.json"
const VEGETATION_PATH := "res://data/config/bands/band5_stronghold_approach/vegetation.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
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
		assert_eq(str(prop.get("model", "")), "Banner", "%s uses the shared Hall standard" % wanted)
		assert_true(float(prop.get("scale", 0.0)) >= 3.0, "%s remains landscape-readable" % wanted)
		assert_eq(str((prop.get("retint", {}) as Dictionary).get("Banner", "")), "#7a2430",
			"%s keeps Team Tether's oxblood reservation" % wanted)


func test_authored_approach_props_are_installed_and_leave_the_road_open() -> void:
	var spine := _stronghold_spine()
	assert_true(spine.size() >= 6, "the production Band 5 spine still exists")
	for wanted in REQUIRED_TALL_READS + ["OuterWatchWagon", "RoadDropSignalRing", "RoadDropSignalFire",
			"GatewardFenceWest", "GatewardFenceEast", "GatewardCrateWest", "GatewardBarrelEast",
			"HallwardTorchWest", "HallwardTorchEast", "HallwardFenceWest", "HallwardFenceEast",
			"HallwardWeaponStand", "HallwardSupplyCrate"]:
		var prop := _prop_named(wanted)
		assert_false(prop.is_empty(), "%s remains authored" % wanted)
		assert_true(_asset_exists(prop), "%s resolves to an installed production asset" % wanted)
		var raw_at := prop.get("at", []) as Array
		var at := Vector2(float(raw_at[0]), float(raw_at[1]))
		assert_true(_distance_to_polyline(at, spine) >= 5.0,
			"%s stays outside the five-metre walking corridor" % wanted)


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
