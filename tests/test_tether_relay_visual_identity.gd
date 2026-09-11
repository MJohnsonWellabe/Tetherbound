extends "res://tests/test_case.gd"

const RELAY_PATH := "res://data/config/tether_relay.json"
const SITE_PATH := "res://data/config/relay_site.json"


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s did not parse" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func test_relay_platform_has_readable_material_edges_and_practical_lights() -> void:
	var config := _read(RELAY_PATH)
	var weathering := (config.get("site", {}) as Dictionary).get("weathering", {}) as Dictionary
	assert_between(float(weathering.get("darken", 0.0)), 0.26, 0.36,
		"working relay masonry should retain visible brick contrast without returning to white")

	var trim := config.get("deck_trim", {}) as Dictionary
	var segments: Array = trim.get("segments", [])
	assert_true(segments.size() >= 4, "apparatus pad has no authored edge silhouette")
	for raw: Variant in segments:
		var segment := raw as Dictionary
		assert_true((segment.get("from", []) as Array).size() == 2)
		assert_true((segment.get("to", []) as Array).size() == 2)

	var live_lights := 0
	var warm_approach := false
	for raw: Variant in config.get("scene_lights", []):
		var light := raw as Dictionary
		live_lights += 1 if bool(light.get("live_only", false)) else 0
		warm_approach = warm_approach or str(light.get("id", "")) == "approach_warm"
		assert_true(float(light.get("range", 0.0)) <= 10.0,
			"relay practical light leaked into biome-wide exposure")
	assert_true(live_lights >= 2, "live machinery has no local teal read at night")
	assert_true(warm_approach, "relay approach camp has no bounded warm night landmark")
	var mast := config.get("approach_mast", {}) as Dictionary
	assert_true((mast.get("at", []) as Array).size() == 2,
		"checkpoint cloth has no authored support mast")
	assert_true(float(mast.get("height", 0.0)) >= 3.0,
		"checkpoint mast is too small to explain the large faction cloth")


func test_relay_staffing_is_authored_presence_not_a_capture_crowd() -> void:
	var relay := _read(RELAY_PATH)
	var site := _read(SITE_PATH)
	var decorative_ground := 0
	for raw: Variant in site.get("people", []):
		var person := raw as Dictionary
		if str(person.get("rank", "")) == "grunt":
			decorative_ground += 1
	assert_between(decorative_ground, 2, 2,
		"relay yard should read as guarded without duplicating its real trainer roster")
	var deck_people: Array = (relay.get("deck_people", {}) as Dictionary).get("list", [])
	assert_eq(deck_people.size(), 1,
		"the compact apparatus pad should have one clear console guard silhouette")
