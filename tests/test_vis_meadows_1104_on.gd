extends "res://tests/test_case.gd"

## VIS-MEADOWS (4 Nov 2026): Meadows arms that a CPU code-blind A/B judged as a
## gain ship ON (owner 4 Nov: "If it's an improvement move it to main").
## Each ON flag carries its CPU score in `_why_on`.
## Verdict: ralph/reports/LANES/VIS-MEADOWS/r1a/VERDICT.md.


func _load(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, path + " parses")
	return parsed if parsed is Dictionary else {}


func _cluster(path: String, name: String) -> Dictionary:
	for cluster: Variant in _load(path).get("clusters", []):
		if cluster is Dictionary and str((cluster as Dictionary).get("name", "")) == name:
			return cluster
	return {}


func test_f38_20_stronghold_arms_ship_on_with_their_cpu_score() -> void:
	var stronghold := _load("res://data/config/stronghold.json")
	var keep: Dictionary = stronghold.get("p2_003_candidate", {})
	assert_true(bool(keep.get("enabled", false)), "P2-003 keep candidate ON")
	assert_true(str(keep.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "keep carries its CPU score")
	assert_true(bool((stronghold.get("approach_pylons", {}) as Dictionary).get("p2_003_unlit_candidate_enabled", false)),
		"P2-003 unlit approach pylons ON")
	var courtyard := _cluster("res://data/config/bands/band5_stronghold_approach/props.json", "wd_stronghold_courtyard")
	var candidate: Dictionary = courtyard.get("candidate", {})
	assert_true(bool(candidate.get("enabled", false)), "courtyard dressing ON")
	assert_true(str(candidate.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "courtyard carries its CPU score")


func test_f38_22_mill_and_settlement_arms_ship_on_with_their_cpu_score() -> void:
	var clearings: Dictionary = _load("res://data/config/meadows_hero_pieces.json").get("clearings_wd", {})
	assert_true(bool(clearings.get("enabled", false)), "trail-camp clearings ON")
	assert_true(str(clearings.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "clearings carries its CPU score")
	var seat := _load("res://data/config/meadows_doorstep_seat.json")
	assert_true(bool(seat.get("doorstep_seat_enabled", false)), "doorstep seat ON")
	assert_true(str(seat.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "doorstep seat carries its CPU score")
	var market := _cluster("res://data/config/bands/band1_lower_meadows/props.json", "wd_village_market")
	var candidate: Dictionary = market.get("candidate", {})
	assert_true(bool(candidate.get("enabled", false)), "village market ON")
	assert_true(str(candidate.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "market carries its CPU score")


func test_f38_13_catch_arms_ship_on_with_their_cpu_score() -> void:
	var framed: Dictionary = _load("res://data/config/catching.json").get("framed_camera", {})
	assert_true(bool(framed.get("enabled", false)), "framed catch camera ON")
	var r2: Dictionary = framed.get("r2", {})
	assert_true(bool(r2.get("enabled", false)), "framed_camera r2 (oblique behind-trainer resolve) ON")
	assert_true(str(r2.get("_why_on", "")).contains("CPU 6.22 -> 7.19"), "r2 carries its CPU score")
	var orb: Dictionary = _load("res://data/config/camfx.json").get("catch_orb", {})
	assert_true(bool(orb.get("enabled", false)), "physical catch orb ON")
	var card: Dictionary = _load("res://data/config/hud.json").get("catch_card", {})
	assert_true(bool(card.get("enabled", false)), "catch result card ON")


func test_f38_20_yard_fill_reaches_the_whole_courtyard_with_its_score() -> void:
	var day: Dictionary = _load("res://data/config/stronghold.json").get("courtyard_daylight_candidate", {})
	assert_true(bool(day.get("enabled", false)), "courtyard daylight ON")
	var light: Dictionary = day.get("light", {})
	assert_true(float(light.get("range", 0.0)) >= 52.0, "the fill reaches the courtyard entrance")
	assert_true(float(light.get("attenuation", 1.0)) <= 0.22, "an even pool, not a steep peak")
	assert_true(str(day.get("_why_r3_yard_fill", "")).contains("CPU 4.71 -> 5.73"), "r3 records its CPU score")


func test_f38_20_keep_keeps_its_value_through_the_fog_with_its_score() -> void:
	var keep: Dictionary = (_load("res://data/config/stronghold.json").get("p2_003_candidate", {}) as Dictionary).get("keep", {})
	assert_true(bool(keep.get("fog_disable", false)), "the keep resists the depth fog")
	assert_eq(str(keep.get("albedo_tint", "")), "#b3ab9c", "lifted stone so it reads as shaded stone, not a black cut-out")
	assert_true(str(keep.get("_why_r4_fog", "")).contains("CPU 5.22 -> 5.70"), "r4 records its CPU score")
	var gate: Dictionary = preload("res://scripts/world/stronghold.gd").p2_003_gatehouse(_load("res://data/config/stronghold.json"))
	assert_true(bool(gate.get("fog_disable", false)), "the shipped gatehouse carries fog_disable")


func test_f38_20_courtyard_centre_dressing_ships_on_with_its_score() -> void:
	var centre := _cluster("res://data/config/bands/band5_stronghold_approach/props.json", "vm_stronghold_courtyard_centre")
	var candidate: Dictionary = centre.get("candidate", {})
	assert_true(bool(candidate.get("enabled", false)), "courtyard centre dressing ON")
	assert_true(str(candidate.get("_why_on", "")).contains("CPU 5.51 -> 5.75"), "records its CPU score")
	for prop: Variant in centre.get("props", []):
		assert_true(bool((prop as Dictionary).get("visual_only", false)), "visual only, so routes and NPC paths are unchanged")
		var x := float(((prop as Dictionary).get("at", [0, 0]) as Array)[0])
		assert_true(x < 6.5 or x > 9.5 or str((prop as Dictionary).get("model", "")) == "Torch_Metal", "the walking lane (x 6.5-9.5) stays clear")


## Hard rule: dark red/oxblood is Team Tether's only. The market stall cloth
## (MI_Banner) is painted red through vertex colours, so a tan multiply alone
## left it maroon (two judges, quick_judge f38_22-market-folk). The retint must
## drop the vertex colour.
func test_village_market_cloth_is_not_oxblood() -> void:
	var market := _cluster("res://data/config/bands/band1_lower_meadows/props.json", "wd_village_market")
	var checked := 0
	for prop: Variant in market.get("props", []):
		var retint: Dictionary = (prop as Dictionary).get("retint", {})
		if retint.has("MI_Banner"):
			var cloth: Dictionary = retint["MI_Banner"]
			assert_false(bool(cloth.get("vertex_colour", true)), "the stall cloth drops its red vertex paint")
			checked += 1
	assert_true(checked >= 2, "both market stalls are covered")


func test_f38_22_market_folk_ship_on_silent_with_their_score() -> void:
	var folk: Dictionary = _load("res://data/config/village_npcs.json").get("market_folk", {})
	assert_true(bool(folk.get("enabled", false)), "market folk ON")
	assert_true(str(folk.get("_why_on", "")).contains("CPU 6.44 -> 6.62"), "records its CPU score")
	var people: Array = folk.get("villagers", [])
	assert_eq(people.size(), 4, "four market villagers")
	for person: Variant in people:
		var spec: Dictionary = person
		assert_false(spec.has("greeting") or spec.has("greeting_when"), "silent set dressing: no prompt, no dialogue")
		assert_false(preload("res://scripts/world/village_npcs.gd").has_anything_to_say(spec), "nothing to say, so no Greet prompt")


## F38#20 r5: the keep rises from a rock crag instead of floating on the
## skyline (CPU 5.87 -> 6.05, quick_judge f38_20-crag2).
func test_f38_20_keep_crag_ships_on_with_its_score() -> void:
	var config := _load("res://data/config/stronghold.json")
	var gatehouse: Dictionary = preload("res://scripts/world/stronghold.gd").p2_003_gatehouse(config)
	var crag: Dictionary = {}
	for companion: Variant in gatehouse.get("companions", []):
		if companion is Dictionary and str((companion as Dictionary).get("id", "")) == "crag":
			crag = companion
	assert_false(crag.is_empty(), "the crag is placed beside the keep")
	assert_true(str(crag.get("_why_on", "")).contains("CPU 5.87 -> 6.05"), "records its CPU score")
	assert_true(ResourceLoader.exists(str(crag.get("path", ""))), "the crag model is installed")
	var offset: Array = crag.get("offset", [])
	assert_true(float(offset[2]) - 40.0 > 103.0, "the crag's front face stays behind the hall's last chamber")
	var spire_kept := false
	for companion: Variant in gatehouse.get("companions", []):
		if companion is Dictionary and str((companion as Dictionary).get("id", "")) == "spire":
			spire_kept = true
	assert_true(spire_kept, "the spire is still placed")


## F38#20 r6: the two courtyard bonfires pool real light on the floor by day
## (CPU 5.87 -> 6.42, quick_judge f38_20-fire-glow).
func test_f38_20_courtyard_fires_light_the_yard_with_their_score() -> void:
	var yard := _cluster("res://data/config/bands/band5_stronghold_approach/props.json", "wd_stronghold_courtyard")
	assert_true(str((yard.get("candidate", {}) as Dictionary).get("_why_on", "")).contains("CPU 5.87 -> 6.42"), "records its CPU score")
	var fires := 0
	for prop: Variant in yard.get("props", []):
		var spec: Dictionary = prop
		if str(spec.get("model", "")) == "Bonfire_Fire":
			assert_eq(str(spec.get("glow", "")), "campfire", "the fire keeps its campfire overlay")
			assert_almost_eq(float(spec.get("glow_scale", 1.0)), 4.0, 0.001, "the fire's light reaches the yard")
			fires += 1
	assert_eq(fires, 2, "both courtyard fires")


## F38#20 r7: the gate camera's foreground cobbles are dressed in two working
## groups that keep the walking lane clear (CPU 5.36 -> 6.08,
## quick_judge f38_20-yard-fore).
func test_f38_20_courtyard_foreground_ships_on_clear_of_the_lane() -> void:
	var fore := _cluster("res://data/config/bands/band5_stronghold_approach/props.json", "vm_stronghold_courtyard_fore")
	var cand: Dictionary = fore.get("candidate", {})
	assert_true(bool(cand.get("enabled", false)), "foreground dressing ON")
	assert_true(str(cand.get("_why_on", "")).contains("CPU 5.36 -> 6.08"), "records its CPU score")
	var props: Array = fore.get("props", [])
	assert_true(props.size() >= 10, "both groups placed")
	for prop: Variant in props:
		var spec: Dictionary = prop
		assert_true(bool(spec.get("visual_only", false)), "visual only, no collider: routes unchanged")
		var x := float((spec.get("at", [0.0, 0.0]) as Array)[0])
		assert_false(x > 6.5 and x < 9.5, "%s stays out of the walking lane" % spec.get("model", ""))
		assert_almost_eq(float(spec.get("y_world", 0.0)), 6.17, 0.001, "seated on the courtyard floor")


## F38#20 r8: two lit torches flank the outer-works yard's back door, so the
## doorway is no longer a black slab (CPU 6.50 -> 6.80,
## quick_judge f38_20-door-torches2).
func test_f38_20_door_torches_ship_on_with_their_score() -> void:
	var torches := _cluster("res://data/config/bands/band5_stronghold_approach/props.json", "vm_stronghold_door_torches")
	var cand: Dictionary = torches.get("candidate", {})
	assert_true(bool(cand.get("enabled", false)), "door torches ON")
	assert_true(str(cand.get("_why_on", "")).contains("CPU 6.50 -> 6.80"), "records its CPU score")
	var props: Array = torches.get("props", [])
	assert_eq(props.size(), 2, "one torch each side of the door")
	for prop: Variant in props:
		var spec: Dictionary = prop
		assert_eq(str(spec.get("glow", "")), "campfire", "the torch carries the campfire light")
		assert_true(bool(spec.get("glow_light_only", false)), "Torch_Metal has no Fire surface; the light is the effect")
		assert_true(bool(spec.get("visual_only", false)), "visual only, no collider")
		var x := float((spec.get("at", [0.0, 0.0]) as Array)[0])
		assert_false(x > 6.5 and x < 9.5, "clear of the walking lane to the door")


## F38#20 r9: the approach pylons stand 7 m, so the line leads to the keep
## without out-topping it in frame (CPU 5.31 -> 5.83,
## quick_judge f38_20-pylons-low).
func test_f38_20_approach_pylons_ship_low_with_their_score() -> void:
	var pylons: Dictionary = _load("res://data/config/stronghold.json").get("approach_pylons", {})
	assert_almost_eq(float(pylons.get("height", 0.0)), 7.0, 0.001, "pylons lowered to 7 m")
	assert_true(float(pylons.get("height", 0.0)) > 1.8 * 3.0, "still several times the 1.80 m trainer")
	assert_almost_eq(float(pylons.get("sag_scale", 0.0)), 1.3, 0.001, "cable sag kept in proportion")
	assert_true(str(pylons.get("_why_r9_height", "")).contains("CPU 5.31 -> 5.83"), "records its CPU score")
	assert_eq((pylons.get("list", []) as Array).size(), 15, "every pylon station kept")


## F38#20 r10: the keep grows 170 -> 210 m with its front face held, and the
## crag grows with it (CPU 6.08 -> 6.20, quick_judge f38_20-keep-big).
func test_f38_20_bigger_keep_keeps_its_front_face_with_its_score() -> void:
	var keep: Dictionary = (_load("res://data/config/stronghold.json").get("p2_003_candidate", {}) as Dictionary).get("keep", {})
	assert_true(str(keep.get("_why_r10_size", "")).contains("CPU 6.08 -> 6.20"), "records its CPU score")
	var width := float(keep.get("width_m", 0.0))
	var centre := float((keep.get("offset", [0.0, 0.0, 0.0]) as Array)[2])
	assert_almost_eq(width, 210.0, 0.001, "keep 210 m wide")
	assert_almost_eq(centre - width * 0.43 * 0.5, 140.6 - 170.0 * 0.43 * 0.5, 0.2, "front face unchanged, so nothing new reaches the chambers")


## F38#15 mount scale (coordinator-approved, presentation only): the carrier
## art grows so the bird stands clearly taller than the 1.80 m trainer, while
## flight collision, the seat (feet offset) and the grip bones are unchanged
## (CPU 6.21 -> 7.08, quick_judge f38_15-mount-scale).
func test_f38_15_mount_grows_without_moving_collision_or_seat() -> void:
	var fly := _load("res://data/config/fly_traversal.json")
	assert_almost_eq(float(fly.get("collision_height_m", 0.0)), 4.5, 0.001, "flight collision height unchanged")
	var expected := {"galecrest": [3.2, 2.45, ["foot_l", "foot_r"]], "galewisp": [3.4, 2.3, ["foot_l", "foot_r"]]}
	# Galewisp art height 3.0 -> 3.4 on 12 Nov with the landing side step (G-galeland2.md).
	# Galewisp's grip moved to its feet on 12 Nov with the remake carrier
	# (G-faint2-medium-galecarrier.md); height and seat are as F38#15 left them.
	for id: String in expected:
		var cap: Dictionary = (fly.get("capabilities", {}) as Dictionary).get(id, {})
		var want: Array = expected[id]
		assert_true(bool(cap.get("presentation_scale_enabled", false)), id + " presentation scale ON")
		assert_almost_eq(float(cap.get("presentation_height_m", 0.0)), float(want[0]), 0.001, id + " art height")
		assert_true(float(cap.get("presentation_height_m", 0.0)) > 1.8, id + " taller than the trainer")
		assert_true(str(cap.get("_why_presentation_height", "")).contains("CPU 6.21 -> 7.08"), id + " records its CPU score")
		assert_almost_eq(float((cap.get("feet_offset", [0, 0, 0]) as Array)[1]), float(want[1]), 0.001, id + " seat (feet offset) unchanged")
		assert_eq(cap.get("grip_bones", []), want[2], id + " grip bones unchanged")
		var art: Node3D = preload("res://scripts/player/fly_controller.gd").make_carrier_art(cap)
		assert_ne(art, null, id + " carrier art builds")
		if art != null:
			assert_almost_eq(art.position.y, float(want[1]), 0.001, id + " art hangs from the same offset")
			art.free()


## F38#41 old quarry: natural rock worked faces, grey stone and sunk floor
## tiles (raw Bar A 5.80 -> 6.43, three code-blind judges,
## qj/f38_41-natural-faces). The worked faces still build and keep their names.
func test_f38_41_quarry_natural_faces_ship_on_with_their_score() -> void:
	var quarry := _load("res://data/config/old_quarry.json")
	var cut: Dictionary = quarry.get("worked_cut", {})
	assert_true(bool(cut.get("natural_faces", false)), "natural worked faces ON")
	assert_true(str(cut.get("_why_natural_faces", "")).contains("5.80 -> 6.43"), "records its CPU score")
	for piece: Variant in cut.get("pieces", []):
		var p := piece as Dictionary
		if str(p.get("role", "")) in ["extraction_face", "tool_course", "working_bench"]:
			var c := Color(str(p.get("colour", "#000000")))
			assert_true(c.s < 0.15, "%s is grey stone, not tan" % str(p.get("name", "")))
	var prefabs := _load("res://data/config/building_prefabs.json")
	var floors := 0
	for module: Variant in ((((prefabs.get("prefabs", {}) as Dictionary).get("quarry_foundation", {})) as Dictionary).get("modules", []) as Array):
		if str((module as Dictionary).get("module", "")) == "Floor_UnevenBrick":
			floors += 1
			assert_almost_eq(float(((module as Dictionary).get("at", []) as Array)[1]), -0.4, 0.001, "floor tile sunk")
	assert_eq(floors, 6, "six quarry floor tiles")
	var builder: Object = preload("res://scripts/world/old_quarry.gd").new()
	builder.set("_natural_worked_faces", true)
	var face := builder.call("_textured_wedge", "WorkedFaceWest", Vector3(6.8, 5.2, 4.0),
		Color("#8f8b82"), "", "", 0.52, 0.78, 0.96) as MeshInstance3D
	assert_true(face != null and face.mesh != null, "natural worked face builds")
	if face != null:
		assert_eq(face.name, "WorkedFaceWest", "keeps its production node name")
		face.free()
	builder.free()


## F38#37 quarry foreman dialogue: the east worked face moved 3 m back so the
## dialogue camera no longer sits inside it (mapped 5.31 -> 6.09,
## qj/f38_37-east-face). The face stays inside the quarry worksite.
func test_f38_37_east_face_clears_the_foreman_camera_with_its_score() -> void:
	var cut: Dictionary = _load("res://data/config/old_quarry.json").get("worked_cut", {})
	assert_true(str(cut.get("_why_east_face_moved", "")).contains("5.31 -> 6.09"), "records its CPU score")
	var found := false
	for piece: Variant in cut.get("pieces", []):
		if str((piece as Dictionary).get("name", "")) == "WorkedFaceEast":
			found = true
			var at := (piece as Dictionary).get("at", []) as Array
			assert_almost_eq(float(at[0]), 391.64, 0.01, "east face x")
			assert_almost_eq(float(at[1]), 1788.23, 0.01, "east face z")
			assert_true(Vector2(float(at[0]), float(at[1])).distance_to(Vector2(392.0, 1792.0)) > 3.5,
				"east face clear of the foreman's stand")
	assert_true(found, "WorkedFaceEast still built")


## F38#23 relay yard: the undercroft yard-face arch (the frame's black mass,
## named by tests/probe_camera_pixel.gd) gets a lighter arch finish
## (mapped 5.90 -> 6.04, qj/f38_23-arch-lift).
func test_f38_23_relay_arch_lift_ships_on_with_its_score() -> void:
	var site: Dictionary = _load("res://data/config/tether_relay.json").get("site", {})
	var arch: Dictionary = ((site.get("support_finish", {}) as Dictionary).get("variants", {}) as Dictionary).get("arch", {})
	assert_eq(str(arch.get("tint", "")), "#e4d8c2", "lifted arch tint")
	assert_true(Color(str(arch.get("tint", "#000000"))).get_luminance() > Color("#a0927b").get_luminance() + 0.2, "arch reads lighter than before")
	assert_true(str(arch.get("_why_tint", "")).contains("5.90 -> 6.04"), "records its CPU score")


## F38#23 relay yard: the smaller cobble flags (`ground_pad.surface_candidate.r2`)
## ship ON (mapped 6.73 -> 6.93, qj/f38_23-cobble-r2).
func test_f38_23_relay_cobble_r2_ships_on_with_its_score() -> void:
	var pad: Dictionary = _load("res://data/config/tether_relay.json").get("ground_pad", {})
	var r2: Dictionary = ((pad.get("surface_candidate", {}) as Dictionary).get("r2", {}) as Dictionary)
	assert_true(bool(r2.get("enabled", false)), "smaller flags ON")
	assert_true(float(r2.get("uv_scale", 0.0)) > 0.4, "flags at the denser scale")
	assert_true(str(r2.get("_why_on", "")).contains("6.73 / 6.93"), "records its CPU score")


## F38#33 catch result: the reticle's fading capture-chance readout clears as
## the result card lands (caught or broke free), mapped 6.32 -> 7.11
## (qj/f38_33-clear-reticle2).
func test_f38_33_result_clears_reticle_ships_on_with_its_score() -> void:
	var card: Dictionary = _load("res://data/config/hud.json").get("catch_card", {})
	assert_true(bool(card.get("enabled", false)), "catch card ON")
	assert_true(bool(card.get("result_clears_reticle", false)), "result clears the reticle ON")
	assert_true(str(card.get("_why_on_result_clears_reticle", "")).contains("6.32 -> 7.11"), "records its CPU score")
	assert_true(preload("res://scripts/ui/capture_reticle.gd").result_clears_reticle(), "the reticle reads the flag")
