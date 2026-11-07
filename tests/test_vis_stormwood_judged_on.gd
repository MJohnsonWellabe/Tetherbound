extends "res://tests/test_case.gd"

## VIS-STORMWOOD judged gains (owner 4 Nov 2026: every judged CPU improvement
## ships ON with its score). Each flag below is ON and records its mapped
## CPU score from the lane's verdict (ralph/reports/LANES/VIS-STORMWOOD/).


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _assert_on(block: Dictionary, score: String, label: String) -> void:
	assert_true(bool(block.get("enabled", false)), "%s ships ON (judged gain)" % label)
	assert_true(str(block.get("_why_on", "")).contains(score), "%s records %s" % [label, score])


## j1: F41#1 Stormheart 3.22 -> 3.94.
func test_stormheart_j1_arms_ship_on() -> void:
	var cfg := _json("res://data/config/stormheart_presentation.json")
	_assert_on(cfg.deck_light_1101, "3.94", "deck_light_1101")
	_assert_on(cfg.hollow_floor, "3.94", "hollow_floor")
	_assert_on(cfg.hero_interior.round2, "3.94", "hero_interior.round2")
	assert_true(bool(cfg.hero_interior.get("enabled", false)), "round2 needs hero_interior ON")


## j1: F41#4 named destinations 4.00 -> 4.59.
func test_lantern_pools_j1_arms_ship_on() -> void:
	var cfg := _json("res://data/config/stormwood_lantern_pools.json")
	for key: String in ["arrival_pools", "basin", "lantern_model", "glow_fungi", "grove"]:
		_assert_on(cfg[key], "4.59", key)


## j3: F41#8 named silhouettes 4.72 -> 4.96 (offset-map caveat recorded).
func test_role_accessories_j3_ship_on() -> void:
	_assert_on(_json("res://data/config/npc_role_accessories.json"), "4.96", "npc_role_accessories")


## j4: F41#10 Glass Sink 4.03 -> 5.07.
func test_glass_sink_j4_arms_ship_on() -> void:
	_assert_on(_json("res://data/config/hero_landmarks_1101.json").glass_sink, "5.07", "hero_landmarks_1101.glass_sink")
	var sink := _json("res://data/config/stormwood_glass_sink.json")
	_assert_on(sink.dark_pool_candidate, "5.07", "dark_pool_candidate")
	_assert_on(sink.obsidian_1104, "5.07", "obsidian_1104")



## qj_obs3: F41#10 Glass Sink obsidian r3 3.96 -> 4.38.
func test_glass_sink_obsidian_r3_ships_on() -> void:
	_assert_on(_json("res://data/config/stormwood_glass_sink.json").obsidian_1104.r3, "4.38", "obsidian_1104.r3")


## F41#19 qj_seam2: seam clear r2 (dark fissures kept) judged 4.77 -> 5.59.
func test_glass_field_seam_clear_r2_ships_on() -> void:
	_assert_on(_json("res://data/config/stormwood_glass_field.json").seam_clear_1104, "5.59", "seam_clear_1104")


## F41#4 qj_path: darker damp-earth path judged 5.56 -> 5.92.
func test_path_loam_ships_on() -> void:
	_assert_on(_json("res://data/config/stormwood_ground_finish.json").path_loam_1104, "5.92", "path_loam_1104")


## F41#19 qj_footing: fuller installed-rock collar judged 5.09 -> 5.22.
func test_glass_field_footing_ships_on() -> void:
	_assert_on(_json("res://data/config/stormwood_glass_field.json").rock_collar_candidate.footing_1104, "5.22", "footing_1104")
