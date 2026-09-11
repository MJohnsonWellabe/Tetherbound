extends "res://tests/test_case.gd"

const PROPS_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/props.json"


func test_highfield_has_an_open_stock_gate_and_working_drover_story() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPS_PATH))
	assert_true(parsed is Dictionary, "Band 4 props did not parse")
	if not parsed is Dictionary:
		return
	var target: Dictionary = {}
	for raw: Variant in (parsed as Dictionary).get("clusters", []):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "highfield_drove_gate":
			target = raw as Dictionary
			break
	assert_false(target.is_empty(), "Highfield has no authored pasture identity")
	if target.is_empty():
		return
	var fence_count := 0
	var west_edge := -INF
	var east_edge := INF
	var has_wagon := false
	for raw: Variant in target.get("props", []):
		if not raw is Dictionary:
			continue
		var prop := raw as Dictionary
		var model := str(prop.get("model", ""))
		var at: Array = prop.get("at", [])
		if model.begins_with("Prop_WoodenFence") and at.size() >= 2:
			fence_count += 1
			var x := float(at[0])
			if x < 400.0:
				west_edge = maxf(west_edge, x)
			elif x > 400.0:
				east_edge = minf(east_edge, x)
		has_wagon = has_wagon or model == "Prop_Wagon"
	assert_true(fence_count >= 12, "Highfield stock boundary is too sparse to read")
	assert_true(east_edge - west_edge >= 12.0,
		"Highfield fence closed the player/herd lane through its hero gate")
	assert_true(has_wagon, "Highfield has fencing but no working drover story")
	assert_false(JSON.stringify(target).contains("#7a2430"),
		"friendly Highfield scenery leaked Team Tether oxblood")
