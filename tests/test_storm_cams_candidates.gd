extends "res://tests/test_case.gd"

## Flag-off candidates from the STORMCAMS lane (1 Nov): each is inert while its
## `enabled` is false and replaces only its own keys when on.

const GLASS_SINK := preload("res://scripts/world/stormwood_glass_sink.gd")
const GROUNDING := preload("res://scripts/world/pickup_grounding.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func test_glass_sink_dark_pool_is_off_and_inert_by_default() -> void:
	var config := _json("res://data/config/stormwood_glass_sink.json")
	assert_true(config.has("dark_pool_candidate"), "the P2-070 candidate must be declared")
	assert_false(bool((config["dark_pool_candidate"] as Dictionary).get("enabled", true)),
		"the candidate ships OFF")
	var same := GLASS_SINK.with_dark_pool(config)
	assert_eq(same["glass_colour"], config["glass_colour"], "OFF must not change the glass")


func test_glass_sink_dark_pool_on_darkens_the_glass_and_fades_far_specular() -> void:
	var config := _json("res://data/config/stormwood_glass_sink.json")
	var cand: Dictionary = (config["dark_pool_candidate"] as Dictionary).duplicate(true)
	cand["enabled"] = true
	config["dark_pool_candidate"] = cand
	var on := GLASS_SINK.with_dark_pool(config)
	assert_true(Color(str(on["glass_colour"])).get_luminance()
			< Color(str(config["glass_colour"])).get_luminance(), "the pool must read darker")
	var far: Array = on["far_fade_m"]
	assert_true(float(far[1]) > float(far[0]), "the far fade must be switched on")
	assert_false(on.has("enabled"), "the switch must not leak into the material keys")


func test_candy_tiers_are_off_by_default() -> void:
	var config := _json("res://data/config/pickup_grounding.json")
	assert_false(bool((config.get("tier_candidate", {}) as Dictionary).get("enabled", true)),
		"the P2-045 candidate ships OFF")
	if not bool((GROUNDING.config().get("tier_candidate", {}) as Dictionary).get("enabled", false)):
		assert_true(GROUNDING.tier_spec("rare_candy").is_empty(), "OFF must give no tier change")


func test_candy_tiers_differ_in_count_and_size_when_declared() -> void:
	var items: Dictionary = (_json("res://data/config/pickup_grounding.json")["tier_candidate"] as Dictionary)["items"]
	var good: Dictionary = items["good_candy"]
	var great: Dictionary = items["great_candy"]
	var rare: Dictionary = items["rare_candy"]
	assert_true(int(good.get("count", 1)) < int(great.get("count", 1))
		and int(great.get("count", 1)) < int(rare.get("count", 1)), "each tier needs its own count")
	assert_true(float(good["scale_mult"]) < float(great["scale_mult"])
		and float(great["scale_mult"]) < float(rare["scale_mult"]), "each tier needs its own size step")


func test_harvest_hero2_is_off_and_gives_crown_its_own_silhouette() -> void:
	var cfg := _json("res://data/config/stormwood_harvest_hero2.json")
	assert_false(bool(cfg.get("enabled", true)), "the P2-046 round-2 candidate ships OFF")
	assert_true(preload("res://scripts/world/stormwood_harvest_runtime.gd").hero2_for("stormglass").is_empty(),
		"OFF must leave the landed hero in charge")
	var items: Dictionary = cfg["items"]
	var plain: Dictionary = (items["stormglass"]["models"] as Array)[0]
	var crown: Dictionary = (items["stormglass_crown"]["models"] as Array)[0]
	assert_ne(str(plain["model"]), str(crown["model"]), "stormglass and its crown need different silhouettes")
	assert_true(float((crown["height_m"] as Array)[0]) > float((plain["height_m"] as Array)[0]),
		"the crown grade must stand taller")


func test_glass_field_rock_collar_ships_off() -> void:
	var cfg := _json("res://data/config/stormwood_glass_field.json")
	var collar: Dictionary = cfg.get("rock_collar_candidate", {})
	assert_true(collar.has("stones"), "the P2-043 candidate must be declared")
	assert_false(bool(collar.get("enabled", true)), "the candidate ships OFF")


func test_crown_arch_round2_ships_off_and_raises_the_arch_when_on() -> void:
	var hero := preload("res://scripts/world/stormwood_crown_arch_hero.gd")
	var cfg := _json("res://data/config/crown_arch_hero.json")
	assert_false(bool((cfg["round2_candidate"] as Dictionary).get("enabled", true)), "ships OFF")
	assert_eq(hero.with_round2(cfg)["height_m"], cfg["height_m"], "OFF leaves the landed arch")
	var cand: Dictionary = (cfg["round2_candidate"] as Dictionary).duplicate(true)
	cand["enabled"] = true
	cfg["round2_candidate"] = cand
	var on := hero.with_round2(cfg)
	assert_true(float(on["height_m"]) > 5.5, "round 2 stands the arch taller")
	assert_true(on.has("edge_dressing"), "round 2 dresses the slab edge")


func test_water_npc_placement_ships_off_and_moves_only_named_npcs() -> void:
	var placement := preload("res://scripts/world/water_npc_placement.gd")
	var cfg := _json("res://data/config/water_npc_placement_candidate.json")
	assert_false(bool(cfg.get("enabled", true)), "the P2-074 candidate ships OFF")
	var nalia := {"id": "water_nalia", "island_local_offset": [0.0, 0.0, 23.0]}
	var bren := {"id": "water_bren", "island_local_offset": [9.0, 0.0, 12.0]}
	assert_eq(placement.offset(nalia, cfg), [0.0, 0.0, 23.0], "OFF keeps the authored offset")
	var on := cfg.duplicate(true)
	on["enabled"] = true
	assert_eq(placement.offset(nalia, on), on["offsets"]["water_nalia"], "ON moves Nalia")
	assert_eq(placement.offset(bren, on), [9.0, 0.0, 12.0], "ON leaves everyone else alone")


func test_stormwood_character_rim_ships_off_and_dresses_only_shadowed_meshes() -> void:
	var rim := preload("res://scripts/world/stormwood_character_rim.gd")
	assert_false(bool(_json("res://data/config/stormwood_character_rim.json").get("enabled", true)),
		"the P2-056 candidate ships OFF")
	var body := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	body.add_child(mesh)
	var card := MeshInstance3D.new()
	card.mesh = QuadMesh.new()
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(card)
	var material := rim.overlay({"colour": "#b8c8ff", "energy": 0.45, "power": 3.0})
	assert_eq(rim.dress(body, material), 1, "only the shadow-casting body mesh takes the rim")
	assert_eq(mesh.material_overlay, material, "the body mesh carries the rim overlay")
	assert_eq(card.material_overlay, null, "effect cards are left alone")
	assert_eq(rim.dress(body, material), 0, "dressing twice changes nothing")
	body.free()


func test_road_puddles_ship_off() -> void:
	var cfg := _json("res://data/config/stormwood_road_current.json")
	var puddles: Dictionary = cfg.get("puddle_candidate", {})
	assert_true(puddles.has("spacing_m"), "the P2-040 candidate must be declared")
	assert_false(bool(puddles.get("enabled", true)), "the candidate ships OFF")


func test_camera_occlusion_fade_ships_off_and_is_inert_off_tree() -> void:
	var cfg := _json("res://data/config/camera.json")
	var fade: Dictionary = cfg.get("occlusion_fade", {})
	assert_true(fade.has("fade_transparency"), "the occlusion candidate must be declared")
	assert_false(bool(fade.get("enabled", true)), "the candidate ships OFF")
	var occ := preload("res://scripts/player/camera_occlusion.gd")
	assert_true(occ.occluders(null, Vector3.ZERO, Vector3.ONE, []).is_empty(), "no world, no occluders")


func test_stormwood_light_pass_ships_off_and_merges_when_on() -> void:
	var look := preload("res://scripts/world/stormwood_look.gd")
	var cfg := _json("res://data/config/stormwood_look.json")
	var pass_cfg: Dictionary = cfg["light_pass_1101"]
	assert_false(bool(pass_cfg.get("enabled", true)), "the light pass ships OFF")
	assert_eq(look.with_light_pass(cfg)["rig"], cfg["rig"], "OFF leaves the rig alone")
	pass_cfg = pass_cfg.duplicate(true)
	pass_cfg["enabled"] = true
	cfg["light_pass_1101"] = pass_cfg
	var on := look.with_light_pass(cfg)
	assert_true(float(on["rig"]["environment"]["fog_density"]) > float(cfg["rig"]["environment"]["fog_density"]),
		"the pass adds depth fog")
	assert_true(bool(on["storm_light"]["enabled"]), "the pass turns the rim light on")
	assert_true(on.has("storm_fill"), "the pass adds the fill light")
	assert_eq(on["rig"]["sun"]["pitch_deg"], cfg["rig"]["sun"]["pitch_deg"], "unlisted rig keys keep their values")


func test_catch_framed_r2_and_hud_prompt_clear_ship_off() -> void:
	var catching := _json("res://data/config/catching.json")
	var r2: Dictionary = (catching["framed_camera"] as Dictionary)["r2"]
	assert_false(bool(r2.get("enabled", true)), "the P2-059 round-2 framing ships OFF")
	assert_true(float((r2["resolve_camera"] as Dictionary)["pitch_start_deg"])
			> float((catching["framed_camera"]["resolve_camera"] as Dictionary)["pitch_start_deg"]),
		"round 2 is a shallower resolve shot")
	var hud := _json("res://data/config/hud.json")
	assert_false(bool((hud["message_clears_prompt"] as Dictionary).get("enabled", true)), "the prompt clear ships OFF")
