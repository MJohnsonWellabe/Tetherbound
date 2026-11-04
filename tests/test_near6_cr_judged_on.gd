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
