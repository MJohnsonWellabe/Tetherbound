extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_reedhaven_segment.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")


func test_result_never_reports_success_before_explicit_segment_completion() -> void:
	var segment := SEGMENT.new()
	assert_false(segment.result().ok)
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["missing production prompt"]))
	assert_true(SEGMENT.verdict(true, []))


func test_each_named_stop_uses_the_live_item_database_tool_contract() -> void:
	var pickup_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_pickups.json"))
	var item_db: RefCounted = ITEM_DB.new()
	var rows: Dictionary = {}
	for row: Dictionary in pickup_data.harvest:
		rows[str(row.id)] = row
	for id: String in SEGMENT.STOPS:
		assert_true(rows.has(id), id)
		var row: Dictionary = rows.get(id, {})
		var item := str(row.get("item_id", ""))
		var production_tool := str(item_db.gathered_with(item))
		assert_eq(str(row.get("gather_action", "")), production_tool, id)
		assert_eq(str(SEGMENT.STOP_TOOLS.get(id, "")), production_tool, id)
