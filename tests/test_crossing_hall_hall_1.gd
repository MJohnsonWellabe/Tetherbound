extends "res://tests/test_case.gd"

## HALL-1 (F17#6 GPU swing): one `hall_1` flag layers a candidate over the
## shipped Hall config before anything is built. ON since the GPU judged it; OFF ships the earlier Hall.

const HALL := preload("res://scripts/world/crossing_hall.gd")
const CONFIG := "res://data/config/crossing_hall.json"


func _shipping() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary


func test_shipping_config_ships_hall_1_on_and_layers_the_candidate() -> void:
	var cfg := _shipping()
	assert_true(bool(cfg.get("hall_1", {}).get("enabled", false)), "HALL-1 ships ON: GPU Q31 r2b gained +0.78 at High against main")
	var applied := cfg.duplicate(true)
	HALL.apply_hall_1(applied)
	assert_ne(JSON.stringify(applied), JSON.stringify(cfg), "ON layers the candidate over the shipped sections")


func test_on_merges_nested_sections_appends_rows_and_removes_by_name() -> void:
	var cfg := {
		"hall_great_hall": {"arch_trim": {"colour": "#2f86e8", "band_m": 0.13}, "rain_ambient": 0.35},
		"hall_furnishing": {"pieces": [{"name": "FeastTable"}]},
		"hall_timber_frame": {"pieces": [{"name": "NavePost_a"}, {"name": "NavePost_b"}]},
		"hall_1": {"enabled": true,
			"merge": {"hall_great_hall": {"arch_trim": {"colour": "#d9a55a"}}},
			"append": {"hall_furnishing": {"pieces": [{"name": "Hearth"}]}},
			"remove": {"hall_timber_frame": {"pieces": ["NavePost_a"]}}}}
	HALL.apply_hall_1(cfg)
	assert_eq(cfg.hall_great_hall.arch_trim.colour, "#d9a55a")
	assert_eq(cfg.hall_great_hall.arch_trim.band_m, 0.13, "unmentioned nested keys stay")
	assert_eq(cfg.hall_great_hall.rain_ambient, 0.35)
	assert_eq((cfg.hall_furnishing.pieces as Array).map(func(r: Dictionary) -> String: return r.name), ["FeastTable", "Hearth"])
	assert_eq((cfg.hall_timber_frame.pieces as Array).map(func(r: Dictionary) -> String: return r.name), ["NavePost_b"])


func test_remove_matches_unnamed_rows_by_model() -> void:
	var cfg := {"hall_great_hall": {"pieces": [{"model": "res://a.glb"}, {"model": "res://b.glb"}]},
		"hall_1": {"enabled": true, "remove": {"hall_great_hall": {"pieces": ["res://a.glb"]}}}}
	HALL.apply_hall_1(cfg)
	assert_eq(cfg.hall_great_hall.pieces, [{"model": "res://b.glb"}])


func test_shipping_candidate_only_names_existing_sections_and_rows() -> void:
	var cfg := _shipping()
	var hall_1: Dictionary = cfg.get("hall_1", {})
	for key: String in ["merge", "append", "remove"]:
		for section: String in hall_1.get(key, {}):
			assert_true(cfg.has(section), "%s targets existing section %s" % [key, section])
	for section: String in hall_1.get("remove", {}):
		for list_key: String in hall_1.remove[section]:
			var names: Array = (cfg[section].get(list_key, []) as Array).map(func(r: Variant) -> String: return str(r.get("name", r.get("model", ""))) if r is Dictionary else "")
			for name: String in hall_1.remove[section][list_key]:
				assert_true(name in names, "remove names a real %s row: %s" % [section, name])
	for section: String in hall_1.get("append", {}):
		for list_key: String in hall_1.append[section]:
			for row: Dictionary in hall_1.append[section][list_key]:
				if row.has("model"):
					assert_true(ResourceLoader.exists(str(row.model)), "appended model is installed: " + str(row.model))
