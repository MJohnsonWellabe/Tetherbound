extends "res://tests/test_case.gd"

## NEAR6-TW judged gains (owner 4 Nov 2026: every judged CPU improvement ships
## ON with its score). Each flag below is ON and records its mapped CPU score
## from the lane's verdict (ralph/reports/LANES/NEAR6-TW/qj/).


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _assert_on(block: Dictionary, score: String, label: String) -> void:
	assert_true(bool(block.get("enabled", false)), "%s ships ON (judged gain)" % label)
	assert_true(str(block.get("_why_on", "")).contains(score), "%s records %s" % [label, score])


## r27: F39#27 grass around named characters 6.03 -> 6.23.
func test_water_character_rim_ships_on() -> void:
	_assert_on(_json("res://data/config/water_character_rim.json"), "6.23", "water_character_rim")


## r14: F39#14 swimmer water contact 6.10 -> 6.80.
func test_swim_wake_trail_ships_on() -> void:
	var cfg := _json("res://data/config/human_water_contact_visual.json")
	_assert_on(cfg.wake_trail, "6.80", "human_water_contact_visual.wake_trail")
	var loaded: Dictionary = preload("res://scripts/player/human_water_contact_view.gd").load_settings()
	assert_eq(int(loaded.get("max_trail_rings", 0)), int(cfg.wake_trail.max_trail_rings), "the wake's ring count applies")
	assert_true(float(loaded.get("trail_grow_to", 1.0)) > 1.0, "trail rings spread as they fade")


## r20b: F39#20 fight background ground contact 5.87 -> 6.42.
func test_fight_ring_hide_ships_on() -> void:
	var cfg := _json("res://data/config/water_resource_models.json")
	_assert_on(cfg.fight_ring_hide, "6.42", "water_resource_models.fight_ring_hide")
	assert_true((cfg.fight_ring_hide.items as Array).has("reef_stone"), "the reef stone stands aside")
	assert_true(bool(cfg.fight_ring_hide.get("pickups", false)), "world pickups stand aside too")
	var pickup: Node = preload("res://scripts/world/item_cache_pickup.gd").new()
	assert_true(pickup.has_method("set_fight_hidden"), "pickups answer combat_arena's hide call")
	pickup.free()


## r24: F39#24 creature rest poses 5.02 -> 6.69.
func test_prone_rest_ships_on() -> void:
	var cfg := _json("res://data/config/water_creature_rest_visual.json")
	_assert_on(cfg.prone_rest, "6.69", "water_creature_rest_visual.prone_rest")
	for id: String in ["riptusk", "water_riptusk", "torrentoad", "water_torrentoad"]:
		assert_true((cfg.prone_rest.species as Array).has(id), "%s rests prone" % id)
	assert_true(float(cfg.prone_rest.sink_height_frac) > 0.0 and float(cfg.prone_rest.sink_height_frac) <= 0.5,
		"the settle stays a partial sink")


## r16b: F39#16 live current streaks 5.96 -> 6.54.
func test_live_current_seams_ship_softened() -> void:
	var flow: Dictionary = _json("res://data/config/tidewake_look.json").current_flow
	assert_true(str(flow.get("_why_near6_live_seams", "")).contains("6.54"), "records 6.54")
	assert_almost_eq(float(flow.state_shader.live.seam_opacity), 0.1, 0.0001, "live seams faded")
	assert_almost_eq(float(flow.shader.seam_wander_m), 9.0, 0.0001, "seams wander")


## r10: F41#10 Glass Sink 4.84 -> 5.36 (Crown massif hidden from inside its footprint).
func test_crown_massif_near_hide_ships_on() -> void:
	var massif: Dictionary = _json("res://data/config/stormwood_crown_overlook.json").massif
	_assert_on(massif.near_hide_1104, "5.36", "stormwood_crown_overlook.massif.near_hide_1104")
	var begin := float(massif.near_hide_1104.visible_from_m)
	assert_true(begin >= float(massif.width_m) * 0.8, "begins beyond the silhouette's own footprint")
	var overlook: Array = _json("res://data/config/stormwood_crown_overlook.json").deck.at
	var at: Array = massif.at
	assert_true(Vector2(float(overlook[0]) - float(at[0]), float(overlook[1]) - float(at[1])).length() > begin + float(massif.fade_m),
		"the Crown Overlook still sees the massif")


## The fill uniform defaults to 0, so the Stormwood rim keeps its rim-only look.
func test_rim_overlay_fill_defaults_off() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/character_rim_overlay.gdshader")
	assert_true(code.contains("uniform float fill_energy = 0.0;"), "fill_energy defaults to 0")
	var stormwood := _json("res://data/config/stormwood_character_rim.json")
	assert_false(stormwood.has("fill_energy"), "Stormwood rim sets no fill")


## r29p: F39#29 Tidewake dialogue speaker visibility 5.54 -> 6.34 (Nalia posted on the passage floor).
func test_nalia_dialogue_post_ships_on() -> void:
	var cfg := _json("res://data/config/water_npc_posts_candidate.json")
	_assert_on(cfg, "6.34", "water_npc_posts_candidate")
	assert_true((cfg.offsets as Dictionary).has("water_nalia"), "Nalia is posted")
	assert_false((cfg.offsets as Dictionary).has("water_trainer_rune"), "Rune's unjudged post stays off")
