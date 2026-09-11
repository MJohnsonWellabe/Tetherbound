extends "res://tests/test_case.gd"

const RELAY_PATH := "res://data/config/tether_relay.json"
const SITE_PATH := "res://data/config/relay_site.json"
const RETROFIT_MODEL := "res://assets/environment/team_tether/hall/team_tether_scaffold_tower.glb"


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
	var massing := config.get("deck_massing", {}) as Dictionary
	assert_true((massing.get("fascia", []) as Array).size() >= 3,
		"relay deck still has a single thin slab edge")
	assert_true((massing.get("support_caps", []) as Array).size() >= 4,
		"relay support legs have no stepped capital-and-foot articulation")
	assert_true((massing.get("arches", []) as Array).size() >= 2,
		"relay undercroft has no installed-kit support silhouette")
	assert_true(ResourceLoader.exists(str(massing.get("arch_model", ""))),
		"relay undercroft arch uses a missing presentation asset")
	var knees: Array = massing.get("knee_braces", [])
	assert_eq(knees.size(), 4,
		"relay roof edge still lacks a bounded cantilever support silhouette")
	for raw: Variant in knees:
		var knee := raw as Dictionary
		assert_true((knee.get("from", []) as Array).size() == 3)
		assert_true((knee.get("to", []) as Array).size() == 3)
		assert_between(float(knee.get("width", 0.0)), 0.18, 0.26,
			"maintenance brace is too fine to read or too thick for presentation-only trim")
	var retrofit := config.get("platform_retrofit", {}) as Dictionary
	var retrofit_list: Array = retrofit.get("list", [])
	assert_true(ResourceLoader.exists(RETROFIT_MODEL),
		"relay platform retrofit uses a missing installed Team Tether scene")
	assert_eq(retrofit_list.size(), 2,
		"relay pad should have two authored scaffold faces, not exposed box supports")
	var retrofit_ids: Dictionary = {}
	for raw: Variant in retrofit_list:
		var frame := raw as Dictionary
		retrofit_ids[str(frame.get("id", ""))] = true
		assert_eq(str(frame.get("model", "")), "team_tether_scaffold_tower")
		assert_between(float(frame.get("top_y", 0.0)), 9.0, 9.25,
			"scaffold must fit the existing lower fascia rather than alter deck height")
		assert_between(float(frame.get("scale_min", 0.0)), 0.7, 0.8)
		assert_between(float(frame.get("scale_max", 0.0)), 1.3, 1.5)
		assert_true((frame.get("face_local", []) as Array).size() == 2,
			"scaffold working face is not authored against its support")
	assert_true(retrofit_ids.has("yard_service_frame"))
	assert_true(retrofit_ids.has("apparatus_service_frame"))
	var yard_frame := retrofit_list[0] as Dictionary
	var side_frame := retrofit_list[1] as Dictionary
	assert_true(float((yard_frame.get("at", []) as Array)[0]) < 3.0,
		"yard scaffold has drifted into the undercroft arch aperture")
	assert_true(float((side_frame.get("at", []) as Array)[0]) > 11.0,
		"apparatus scaffold has drifted off the outer support face")
	var ground_pad := config.get("ground_pad", {}) as Dictionary
	assert_between(float(ground_pad.get("edge_feather_m", 0.0)), 3.0, 5.0,
		"worked relay ground still has a hard rectangular biome transition")

	var live_lights := 0
	var warm_approach := false
	var undercroft_work := false
	for raw: Variant in config.get("scene_lights", []):
		var light := raw as Dictionary
		live_lights += 1 if bool(light.get("live_only", false)) else 0
		warm_approach = warm_approach or str(light.get("id", "")) == "approach_warm"
		undercroft_work = undercroft_work or str(light.get("id", "")) == "undercroft_work"
		assert_true(float(light.get("range", 0.0)) <= 10.0,
			"relay practical light leaked into biome-wide exposure")
	assert_true(live_lights >= 2, "live machinery has no local teal read at night")
	assert_true(warm_approach, "relay approach camp has no bounded warm night landmark")
	assert_true(undercroft_work,
		"dark platform undercroft has no bounded authored maintenance light")
	var mast := config.get("approach_mast", {}) as Dictionary
	assert_true((mast.get("at", []) as Array).size() == 2,
		"checkpoint cloth has no authored support mast")
	assert_true(float(mast.get("height", 0.0)) >= 3.0,
		"checkpoint mast is too small to explain the large faction cloth")
	var gate_presentation := (config.get("gate", {}) as Dictionary).get(
		"presentation", {}) as Dictionary
	assert_between(float(gate_presentation.get("stone_value_lift", 0.0)), 0.12, 0.2,
		"gate face must retain readable courses without returning to bleached stone")


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
