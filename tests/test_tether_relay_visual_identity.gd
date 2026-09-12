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
	assert_between(float(weathering.get("macro_strength", 0.0)), 0.3, 0.42,
		"relay masonry has no broad weather/value break-up")
	assert_between(float(weathering.get("stone_strength", 0.0)), 0.16, 0.28,
		"relay masonry has lost its installed stone texture response")
	assert_true(float(weathering.get("roughness_floor", 0.0)) >= 0.9,
		"field masonry has returned to a clean toy sheen")

	var trim := config.get("deck_trim", {}) as Dictionary
	assert_eq(str(trim.get("rail_material", "")), "textured_timber",
		"service rail is still a flat faction-colour primitive")
	assert_between(float(trim.get("accent_band_height", 0.0)), 0.02, 0.06,
		"rail should carry a thin oxblood accent, not become another solid bar")
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
		var finish := frame.get("finish", {}) as Dictionary
		assert_true(finish.has("albedo_tint"),
			"scaffold has no authored value separation from the undercroft")
		assert_true(float(finish.get("roughness", 0.0)) >= 0.88,
			"scaffold has returned to a pristine toy finish")
	assert_true(retrofit_ids.has("yard_service_frame"))
	assert_true(retrofit_ids.has("apparatus_service_frame"))
	var yard_frame := retrofit_list[0] as Dictionary
	var side_frame := retrofit_list[1] as Dictionary
	assert_true(float((yard_frame.get("at", []) as Array)[0]) < 3.0,
		"yard scaffold has drifted into the undercroft arch aperture")
	assert_true(float((side_frame.get("at", []) as Array)[0]) > 11.0,
		"apparatus scaffold has drifted off the outer support face")
	assert_ne(str((yard_frame.get("finish", {}) as Dictionary).get("albedo_tint", "")),
		str((side_frame.get("finish", {}) as Dictionary).get("albedo_tint", "")),
		"both scaffold faces still collapse into one repeated material value")
	var ground_pad := config.get("ground_pad", {}) as Dictionary
	assert_between(float(ground_pad.get("edge_feather_m", 0.0)), 3.0, 5.0,
		"worked relay ground still has a hard rectangular biome transition")

	var live_lights := 0
	var warm_approach := false
	var undercroft_work := false
	var gate_warm_count := 0
	for raw: Variant in config.get("scene_lights", []):
		var light := raw as Dictionary
		live_lights += 1 if bool(light.get("live_only", false)) else 0
		warm_approach = warm_approach or str(light.get("id", "")) == "approach_warm"
		undercroft_work = undercroft_work or str(light.get("id", "")) == "undercroft_work"
		gate_warm_count += 1 if str(light.get("id", "")).begins_with("gate_warm_") else 0
		assert_true(float(light.get("range", 0.0)) <= 10.0,
			"relay practical light leaked into biome-wide exposure")
	assert_true(live_lights >= 2, "live machinery has no local teal read at night")
	assert_true(warm_approach, "relay approach camp has no bounded warm night landmark")
	assert_true(undercroft_work,
		"dark platform undercroft has no bounded authored maintenance light")
	var undercroft_fill := false
	var gantry_route_fill := false
	for raw: Variant in config.get("scene_lights", []):
		var light := raw as Dictionary
		if str(light.get("id", "")) == "undercroft_fill":
			undercroft_fill = true
			assert_true(float(light.get("energy", 99.0)) <= 1.4,
				"undercroft fill is competing with the work practical")
			assert_true(float(light.get("range", 99.0)) <= 6.0,
				"undercroft fill is leaking beyond the platform")
			assert_true(ResourceLoader.exists("%s/%s.gltf" % [
				str(light.get("fixture_dir", "")), str(light.get("fixture_model", ""))]),
				"undercroft fill has no installed physical source")
		if str(light.get("id", "")) == "gantry_route_fill":
			gantry_route_fill = true
			var at: Array = light.get("at", [])
			assert_eq(at.size(), 2, "gantry fill has no authored mount point")
			if at.size() == 2:
				assert_true(Vector2(float(at[0]), float(at[1])).distance_to(
					Vector2(-2.0, -11.0)) <= 1.0,
					"gantry fill no longer serves the black circulation bay")
			assert_true(float(light.get("energy", 99.0)) <= 0.9,
				"gantry fill is washing out the bounded undercroft lighting")
			assert_true(float(light.get("range", 99.0)) <= 5.0,
				"gantry fill is leaking beyond the circulation floor")
			assert_true(ResourceLoader.exists("%s/%s.gltf" % [
				str(light.get("fixture_dir", "")), str(light.get("fixture_model", ""))]),
				"gantry fill has no installed physical source")
	assert_true(undercroft_fill,
		"black undercroft has no modest secondary fill behind its arch")
	assert_true(gantry_route_fill,
		"black gantry circulation floor has no restrained local fill")
	assert_eq(gate_warm_count, 2,
		"front arch needs one physical warm practical on each pier")
	for raw: Variant in config.get("scene_lights", []):
		var light := raw as Dictionary
		if str(light.get("id", "")) in ["undercroft_work", "gate_warm_west", "gate_warm_east"]:
			assert_true(bool(light.get("emitter", false)),
				"warm architectural light has no visible physical source")
			assert_between(float(light.get("energy", 0.0)), 2.5, 3.2,
				"warm architectural pool is absent or no longer bounded")
			assert_between(float(light.get("emitter_radius", 0.0)), 0.05, 0.08,
				"warm source is invisible or has returned to a glaring white orb")
			assert_between(float(light.get("emitter_energy", 0.0)), 0.5, 0.8,
				"warm source emission no longer preserves its amber colour")
	var mast := config.get("approach_mast", {}) as Dictionary
	assert_true(mast.is_empty(),
		"complete approach standard must not retain the rejected hand-built mast")
	var approach_standard := config.get("banner", {}) as Dictionary
	assert_eq(str(approach_standard.get("model", "")), "Banner_1",
		"relay barrier restored the flat castle cloth cutout")
	assert_eq(str(approach_standard.get("dir", "")),
		"res://assets/props/quaternius_fantasy")
	assert_almost_eq(float(approach_standard.get("scale", 0.0)), 1.55, 0.001)
	assert_almost_eq(float(approach_standard.get("sink_m", 0.0)), -2.4, 0.001)
	assert_eq(str((approach_standard.get("retint", {}) as Dictionary).get(
		"MI_Banner", "")), "#7a2430")
	var gate_presentation := (config.get("gate", {}) as Dictionary).get(
		"presentation", {}) as Dictionary
	assert_between(float(gate_presentation.get("stone_value_lift", 0.0)), 0.12, 0.2,
		"gate face must retain readable courses without returning to bleached stone")
	var gate := config.get("gate", {}) as Dictionary
	var heraldry := gate.get("heraldry", {}) as Dictionary
	var standards: Array = heraldry.get("list", [])
	assert_eq(standards.size(), 2,
		"broad gate face needs a paired faction standard hierarchy")
	assert_eq(str(heraldry.get("model", "")), "Banner_1",
		"relay heraldry must not restore the flat castle cloth cutout")
	assert_true(ResourceLoader.exists("%s/%s.gltf" % [
		str(heraldry.get("dir", "")), str(heraldry.get("model", ""))]),
		"gate heraldry does not use the installed vertical standard")
	assert_almost_eq(float(heraldry.get("scale", 0.0)), 1.55, 0.001,
		"gate standards keep the accepted Hallward scale")
	assert_eq(str(heraldry.get("material", "")), "MI_Banner",
		"relay heraldry retints the real cloth material")
	assert_false(bool(heraldry.get("add_bracket", true)),
		"the complete standard must not receive a redundant primitive bracket")
	var opening_half := float(gate.get("opening", 0.0)) * 0.5
	for raw: Variant in standards:
		var standard := raw as Dictionary
		var at: Array = standard.get("at", [])
		assert_eq(at.size(), 2)
		if at.size() == 2:
			assert_true(absf(float(at[1])) > opening_half,
				"gate standard intrudes into the traversable arch opening")
		assert_true(absf(float(standard.get("yaw_offset_deg", 0.0))) >= 8.0,
			"gate standard presents a flat planar face instead of its full silhouette")


func test_hero_apparatus_dominates_an_integrated_service_boiler() -> void:
	var config := _read(RELAY_PATH)
	var apparatus := config.get("apparatus", {}) as Dictionary
	assert_true(float(apparatus.get("height", 0.0)) >= 5.8,
		"approved relay hero scale regressed")
	assert_true(float((apparatus.get("finish", {}) as Dictionary).get("roughness", 0.0)) >= 0.75,
		"hero apparatus lost its field-machinery finish")
	var props: Array = (config.get("deck_props", {}) as Dictionary).get("list", [])
	var boiler: Dictionary = {}
	var service_count := 0
	for raw: Variant in props:
		var prop := raw as Dictionary
		var model := str(prop.get("model", ""))
		if model == "team_tether_boiler_chimney":
			boiler = prop
		if model in ["tt_pipe_straight", "tt_pipe_valve"]:
			service_count += 1
			assert_false(bool(prop.get("collision", true)),
				"service connection changed the accepted console route")
			assert_true(ResourceLoader.exists("%s/%s.glb" % [
				str(prop.get("dir", "")), model]),
				"service connection is not an installed Hall-kit asset")
	assert_false(boiler.is_empty(), "relay lost its service boiler")
	assert_true(float(boiler.get("scale", 99.0)) <= 0.6,
		"service boiler returned to co-dominant hero scale")
	assert_true(float((boiler.get("finish", {}) as Dictionary).get("roughness", 0.0)) >= 0.88,
		"service boiler returned to a pristine toy finish")
	assert_eq(service_count, 2,
		"boiler is no longer visibly integrated into the relay apparatus")


func test_support_finish_and_gantry_console_sequence_are_authored() -> void:
	var config := _read(RELAY_PATH)
	var site := config.get("site", {}) as Dictionary
	var variants := ((site.get("support_finish", {}) as Dictionary).get(
		"variants", {}) as Dictionary)
	for role: String in ["deck", "fascia", "support", "arch", "console"]:
		assert_true(variants.has(role), "support finish omits %s" % role)
		var spec := variants.get(role, {}) as Dictionary
		assert_true(spec.has("tint") and float(spec.get("tile", 0.0)) > 0.0,
			"support finish %s has no material/course treatment" % role)
		assert_true(float(spec.get("macro_strength", 0.0)) >= 0.16 and
			float(spec.get("stone_strength", 0.0)) >= 0.1,
			"support finish %s has no weather/value variation" % role)
	var deck_luma := Color(str((variants.get("deck", {}) as Dictionary).get(
		"tint", "#000000"))).get_luminance()
	var fascia_luma := Color(str((variants.get("fascia", {}) as Dictionary).get(
		"tint", "#000000"))).get_luminance()
	assert_true(deck_luma - fascia_luma >= 0.12,
		"deck and fascia still collapse into one slab value")
	var gantry_guides := 0
	for raw: Variant in ((config.get("deck_trim", {}) as Dictionary).get("segments", []) as Array):
		if str((raw as Dictionary).get("role", "")).begins_with("gantry_"):
			gantry_guides += 1
	assert_eq(gantry_guides, 2,
		"raised route no longer has paired gantry-edge guidance")
	var route := config.get("route_guidance", {}) as Dictionary
	var ramp := (config.get("ramps", []) as Array)[0] as Dictionary
	assert_eq(route.get("from", []), ramp.get("from", []),
		"route cue has drifted away from the real ramp foot")
	assert_eq(route.get("to", []), ramp.get("to", []),
		"route cue has drifted away from the real ramp head")
	assert_almost_eq(float(route.get("width", 0.0)), float(ramp.get("width", -1.0)), 0.001,
		"route cue no longer preserves the ramp's traversable width")
	assert_between(float(route.get("signal_size", 0.0)), 0.12, 0.2,
		"route foot signal is invisible or has become a competing beacon")
	assert_between(int(route.get("traction_bar_count", 0)), 6, 9,
		"relay ramp has no repeated material cue or has become a visual ladder")
	assert_between(float(route.get("traction_bar_width", 0.0)), 0.08, 0.14,
		"ramp traction bars are invisible or obstructive-looking")
	assert_between(float(route.get("traction_bar_inset", 0.0)), 0.18, 0.32,
		"ramp traction bars no longer span the walked surface")
	var console := (config.get("apparatus", {}) as Dictionary).get("console", {}) as Dictionary
	assert_true(float(console.get("face_width_frac", 0.0)) >= 0.8 and
		float(console.get("face_height_frac", 0.0)) >= 0.45,
		"console face is no longer legible from the gantry")
	assert_between(float(console.get("face_forward_gap", 0.0)), 0.04, 0.1,
		"console face is buried in the cabinet or floating off it")
	assert_between(float(console.get("face_frame_width", 0.0)), 0.07, 0.14,
		"console face has no readable faction frame")
	assert_between(float(console.get("hood_depth", 0.0)), 0.28, 0.46,
		"console has no readable hood silhouette or overwhelms the cabinet")
	assert_true(ResourceLoader.exists("%s/%s.glb" % [
		str(console.get("marker_dir", "")), str(console.get("marker_model", ""))]),
		"console marker is not an installed valve asset")
	for raw: Variant in config.get("scene_lights", []):
		var light := raw as Dictionary
		if bool(light.get("live_only", false)):
			assert_true(ResourceLoader.exists("%s/%s.gltf" % [
				str(light.get("fixture_dir", "")), str(light.get("fixture_model", ""))]),
				"route-critical teal light still uses a floating sphere")
	var source := FileAccess.get_file_as_string("res://scripts/world/tether_relay.gd")
	for required: String in ["_support_stone_material", "RELAY_TIMBER_ALBEDO",
			"ServiceRailAccent", "_build_route_guidance", "RouteFootSignal",
			"RouteHeadSignal", "RouteTractionBar",
			"ConsoleFaceFrame", "ConsoleFaceHood", "ConsoleValveMarker",
			"_build_scene_light_fixture", 'spec.get("collision", true)']:
		assert_true(source.contains(required), "production relay omits %s" % required)


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


func test_relay_recapture_exposes_the_hero_and_real_console_route() -> void:
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_tether_relay_identity.gd")
	for required: String in ["03-relay-apparatus", "05-relay-route-console",
			"Vector2(-10.0, 0.0)", "Vector2(2.9, -9.0)",
			"final-relay-04", "VIEWS.size() * 2",
			"SEAT_ATTEMPTS := 3", "_seat_player_on_live_surface",
			"reset_physics_interpolation()"]:
		assert_true(source.contains(required), "Relay recapture omits %s" % required)
	var config := _read(RELAY_PATH)
	var capture_seat := Vector2(-10.0, 0.0)
	var route := config.get("route_guidance", {}) as Dictionary
	var route_from: Array = route.get("from", [])
	assert_eq(route_from.size(), 2)
	if route_from.size() == 2:
		assert_between(capture_seat.distance_to(Vector2(
			float(route_from[0]), float(route_from[1]))), 4.0, 7.0,
			"console proof is no longer an ordinary yard view of the ramp foot")
	var standards: Array = ((config.get("gate", {}) as Dictionary).get(
		"heraldry", {}) as Dictionary).get("list", [])
	for raw: Variant in standards:
		var at: Array = (raw as Dictionary).get("at", [])
		if at.size() == 2:
			assert_true(capture_seat.distance_to(Vector2(float(at[0]), float(at[1]))) > 5.0,
				"console proof camera has returned to a gate-standard occlusion seat")
