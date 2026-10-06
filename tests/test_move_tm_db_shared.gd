extends "res://tests/test_case.gd"

## PERF (F26#5): move_db.gd and tm_db.gd `load_default()` hand every caller one
## parsed table instead of re-reading the JSON. Party validation called them
## once per creature on every save and snapshot, and the re-parse held a co-op
## host's frames after world facts landed. A shared table must stay read-only
## for callers: each lookup is a copy, as each private instance used to be.

const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")


func test_load_default_returns_one_shared_table() -> void:
	assert_true(MOVE_DB.load_default() == MOVE_DB.load_default(), "moves.json parsed once")
	assert_true(TM_DB.load_default() == TM_DB.load_default(), "tms.json parsed once")


func test_a_caller_editing_a_move_cannot_change_it_for_others() -> void:
	var moves: RefCounted = MOVE_DB.load_default()
	var id := str((moves.call("move_ids") as Array)[0])
	var power := float(moves.call("power", id))
	var mine: Dictionary = moves.call("move", id)
	mine["power"] = power + 100.0
	mine["display_name"] = "edited"
	assert_eq(float(MOVE_DB.load_default().call("power", id)), power)
	assert_true(str(MOVE_DB.load_default().call("display_name", id)) != "edited")


func test_a_caller_editing_a_tm_cannot_change_it_for_others() -> void:
	var tms: RefCounted = TM_DB.load_default()
	var id := str((tms.call("tm_ids") as Array)[0])
	var types: Array = tms.call("compatible_types", id)
	var before := types.size()
	types.append("not_a_type")
	var record: Dictionary = tms.call("tm", id)
	record["move_id"] = "edited"
	assert_eq((TM_DB.load_default().call("compatible_types", id) as Array).size(), before)
	assert_false(bool(TM_DB.load_default().call("is_compatible", id, "not_a_type")))
	assert_true(str(TM_DB.load_default().call("move_id", id)) != "edited")
