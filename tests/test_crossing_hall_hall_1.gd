extends "res://tests/test_case.gd"

## HALL-1 (F17#6 GPU swing): one `hall_1` flag layers a candidate over the
## shipped Hall config before anything is built. OFF ships main unchanged.

const HALL := preload("res://scripts/world/crossing_hall.gd")
const CONFIG := "res://data/config/crossing_hall.json"


func _shipping() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary


func test_shipping_config_keeps_hall_1_off_and_unchanged() -> void:
	var cfg := _shipping()
	assert_false(bool(cfg.get("hall_1", {}).get("enabled", true)), "HALL-1 ships OFF until judged")
	var applied := cfg.duplicate(true)
	HALL.apply_hall_1(applied)
	assert_eq(JSON.stringify(applied), JSON.stringify(cfg), "OFF leaves every section as shipped")


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


func test_shipping_candidate_only_names_existing_sections_and_rows() -> void:
	var cfg := _shipping()
	var hall_1: Dictionary = cfg.get("hall_1", {})
	for key: String in ["merge", "append", "remove"]:
		for section: String in hall_1.get(key, {}):
			assert_true(cfg.has(section), "%s targets existing section %s" % [key, section])
	for section: String in hall_1.get("remove", {}):
		for list_key: String in hall_1.remove[section]:
			var names: Array = (cfg[section].get(list_key, []) as Array).map(func(r: Variant) -> String: return str(r.get("name", "")) if r is Dictionary else "")
			for name: String in hall_1.remove[section][list_key]:
				assert_true(name in names, "remove names a real %s row: %s" % [section, name])
	for section: String in hall_1.get("append", {}):
		for list_key: String in hall_1.append[section]:
			for row: Dictionary in hall_1.append[section][list_key]:
				if row.has("model"):
					assert_true(ResourceLoader.exists(str(row.model)), "appended model is installed: " + str(row.model))
