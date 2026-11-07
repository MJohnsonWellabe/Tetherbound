extends "res://tests/test_case.gd"

## NEAR6-CR judged gains (owner 4 Nov 2026: every judged CPU improvement ships
## ON with its score). Each flag below is ON and records its mapped CPU score
## from the lane's verdict (ralph/reports/LANES/NEAR6-CR/qj/).


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _assert_on(block: Dictionary, score: String, label: String) -> void:
	assert_true(bool(block.get("enabled", false)), "%s ships ON (judged gain)" % label)
	assert_true(str(block.get("_why_on", "")).contains(score), "%s records %s" % [label, score])


## F40-8-2a6eb2207108-11040854: F40#8 P2-053 route markers 5.87 -> 6.32.
func test_anchor_vessel_quiet_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_npc_runtime.json")
	_assert_on(cfg.world_payoffs.anchor_vessel_quiet, "6.32", "world_payoffs.anchor_vessel_quiet")


## F40-17-f201152b7ca0-11041023: F40#17 P2-102 High Perches rim mushroom 5.09 -> 5.72.
func test_rim_pickup_in_view_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_physical_runtime.json")
	_assert_on(cfg.rim_pickup_in_view, "5.72", "rim_pickup_in_view")
	assert_false(bool(cfg.rim_pickup_inset.get("enabled", false)), "round-1 inset (flat 4.57) stays OFF")


## F40-9-68037b4643f8-11041154: F40#9 P2-068 named NPC posts 5.05 -> 5.25.
func test_post_role_props_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_npc_runtime.json")
	_assert_on(cfg.post_role_props, "5.25", "post_role_props")


## F40-2-edb6d881b763-11041450: F40#2 P2-022 summit aviary 5.64 -> 6.16.
func test_summit_silhouette_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_f40_items.json")
	_assert_on(cfg.summit_silhouette, "6.16", "summit_silhouette")


## F40-19-63afb3c3967f-11041555: F40#19 Cloudreach night (matrix piece 7) 5.10 -> 5.84.
func test_night_foreground_fill_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_visual.json")
	_assert_on(cfg.time_override_arms.night_foreground_fill, "5.84", "time_override_arms.night_foreground_fill")


## F40-4-f99566cca348-11041557: F40#4 P2-023 landform edges 5.96 -> 6.27.
func test_shelf_edge_fringe_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_f40_items.json")
	_assert_on(cfg.shelf_edge_fringe, "6.27", "shelf_edge_fringe")
	assert_false(bool(cfg.shelf_edge_soften.get("enabled", false)), "shelf_edge_soften (judged worse) stays OFF")


## F40-19-rain-810b52e4b41d-11041812: F40#19 Cloudreach day rain (matrix piece 4) 5.69 -> 5.80.
func test_rain_storm_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_visual.json")
	_assert_on(cfg.weather_arms.rain_storm, "5.80", "weather_arms.rain_storm")
	assert_false(bool(cfg.weather_arms.rain_mood.get("enabled", false)), "rain_mood (judged flat) stays OFF")


## F40-17-53b0b6dc0941-11041858: F40#17 P2-102 rim mushroom cluster 5.85 -> 6.19.
func test_rim_pickup_cluster_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_physical_runtime.json")
	_assert_on(cfg.rim_pickup_cluster, "6.19", "rim_pickup_cluster")


## F40-9-bf0f5543f8e6-11042046: F40#9 P2-068 NPC post dais 5.44 -> 5.62.
func test_post_dais_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_npc_runtime.json")
	_assert_on(cfg.post_dais, "5.62", "post_dais")


## F40-19-458a13de2967-11042202: F40#19 night gate-path braziers 5.00 -> 5.51.
func test_gate_path_braziers_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_visual.json")
	_assert_on(cfg.gate_path_braziers, "5.51", "gate_path_braziers")
	assert_true(bool(cfg.time_override_arms.night_foreground_fill.get("enabled", false)), "night fill stays ON under the braziers")


## F40-19-9025b78edb4e-11050024: F40#19 night gate-path verge 5.54 -> 5.81.
func test_gate_path_verge_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_visual.json")
	_assert_on(cfg.gate_path_verge, "5.81", "gate_path_verge")
	for item: Array in cfg.gate_path_verge.items:
		assert_ne(str(item[0]), "bush", "Bush_Common reads red at night; verge keeps flowers and rocks only")


## F40-19-rain-7dbc7c42c9d7-11050224: F40#19 rain streaks 5.48 -> 5.61.
func test_rain_streaks_ships_on() -> void:
	var cfg := _json("res://data/config/cloudreach_visual.json")
	_assert_on(cfg.rain_streaks, "5.61", "rain_streaks")
