extends "res://tests/test_case.gd"

const ITEM_DB := preload("res://autoload/item_db.gd")
const CUSTOM_PATH := "res://tests/fixtures/custom_station_catalogue.json"

## The configuration override is detached fixture input only; no authored
## feature flag is changed. Exercise the actual ItemDB constructor boundary.
class EnabledStationDb extends "res://autoload/item_db.gd":
	func _read(path: String) -> Dictionary:
		if path == CUSTOM_PATH: return super._read(BUILDABLES_PATH)
		var raw := super._read(path)
		if path == "res://data/config/stations.json": raw["runtime_enabled"] = true
		return raw

class DisabledStationDb extends EnabledStationDb:
	func _read(path: String) -> Dictionary:
		var raw := super._read(path)
		if path in ["res://data/config/stations.json", "res://data/config/forward_camps.json"]:
			raw["runtime_enabled"] = false
		return raw

func _catalogue() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ITEM_DB.BUILDABLES_PATH))

func test_shipped_station_catalogue_contains_live_stations_and_preserves_ordinary_buildables() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stations.json"))
	assert_eq(config.get("runtime_enabled"), true)
	var live := ITEM_DB.new()
	for id: String in ["forge", "den", "kitchen", "greenhouse"]:
		assert_false(live.buildable(id).is_empty(), id + " is available in the ordinary catalogue")
	var legacy := DisabledStationDb.new()
	assert_eq(legacy.buildables(), _catalogue().buildables, "disabled fixture retains the original catalogue")
	assert_eq(live.buildable("tent"), legacy.buildable("tent"))

func test_only_canonical_item_db_buildables_path_can_select_station_overlay() -> void:
	var catalogue := _catalogue()
	var canonical := EnabledStationDb.new()
	assert_false(canonical.buildable("forge").is_empty(), "explicit fixture gate selects the authored canonical station catalogue")
	assert_eq(canonical.buildable("tent"), ITEM_DB.new().buildable("tent"))
	var custom := EnabledStationDb.new(ITEM_DB.ITEMS_PATH, CUSTOM_PATH)
	assert_eq(custom.buildables(), catalogue.buildables, "custom fixture path retains its raw legacy catalogue even with gate true")
	assert_true(custom.buildable("forge").is_empty())
