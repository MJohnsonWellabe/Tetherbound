extends "res://tests/test_case.gd"

## P2-013 (vis-meadows, OFF until GPU-judged): relay yard dressing and tiling.

const RELAY := preload("res://scripts/world/tether_relay.gd")
const RELAY_CONFIG := "res://data/config/tether_relay.json"
const PROPS := "res://data/config/bands/band3_the_river_lock/props.json"


func _relay_station() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROPS))
	for cluster: Variant in parsed.clusters:
		if cluster is Dictionary and str(cluster.get("name", "")) == "relay_station":
			return cluster
	return {}


func test_yard_props_ship_off_installed_and_clear_of_the_road() -> void:
	var cluster := _relay_station()
	var extra: Dictionary = cluster.get("candidate_props", {})
	assert_false(bool(extra.get("enabled", true)), "P2-013 props ship OFF")
	var relay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RELAY_CONFIG))
	var centre := Vector2(float(relay.site.centre[0]), float(relay.site.centre[1]))
	var across := Vector2(0.826, 0.565)
	for prop: Dictionary in extra.props:
		var dir := str(prop.get("dir", "res://assets/props/quaternius_fantasy"))
		var found := false
		for ext: String in ["gltf", "glb", "obj"]:
			found = found or ResourceLoader.exists("%s/%s.%s" % [dir, prop.model, ext])
		assert_true(found, "model installed: " + str(prop.model))
		var at := Vector2(float(prop.at[0]), float(prop.at[1]))
		assert_true(absf((at - centre).dot(across)) >= 9.0, "prop stands off the road axis: " + str(prop.model))


func test_ground_pad_candidate_off_is_the_shipped_pad() -> void:
	var relay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RELAY_CONFIG))
	assert_false(bool(relay.ground_pad.p2_013_candidate.get("enabled", true)))
	assert_eq(JSON.stringify(RELAY.ground_pad_config(relay)), JSON.stringify(relay.ground_pad))
	relay.ground_pad.p2_013_candidate.enabled = true
	var on := RELAY.ground_pad_config(relay)
	assert_almost_eq(float(on.surface_candidate.uv_scale), 0.14)
	assert_true(bool(on.surface_candidate.enabled), "surface keeps its own keys")
