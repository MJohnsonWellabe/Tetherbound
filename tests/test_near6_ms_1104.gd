extends "res://tests/test_case.gd"

## NEAR6-MS lane (4 Nov 2026): arms for items scored 5.4-6.0. Each arm ships
## OFF until a quick CPU judge shows a gain; a judged gain flips it ON and this
## file then asserts ON with the "CPU <base> -> <cand>" score in `_why_on`.

const POST_STANCE := preload("res://scripts/characters/post_stance.gd")


func _json(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


## F38#29 P2-065: the immediate beaten bow. OFF returns no rows; ON returns
## the deeper dejected stance, which bows only the spine, neck and head.
func test_f38_29_immediate_beaten_stance() -> void:
	var cfg := _json("res://data/config/npc_post_stances.json")
	var block: Dictionary = cfg.beaten_trainer_stance.immediate_1104
	assert_false(bool(block.enabled), "F38#29 immediate bow ships OFF until judged")
	assert_eq(POST_STANCE.beaten_stance_immediate(cfg), [], "OFF attaches nothing")
	var on := cfg.duplicate(true)
	on.beaten_trainer_stance.immediate_1104.enabled = true
	var rows: Array = POST_STANCE.beaten_stance_immediate(on)
	assert_eq(rows, cfg.stances.dejected_strong, "ON uses the dejected_strong rows")
	for row: Array in rows:
		assert_true(str(row[0]) in ["Spine", "neck", "Head"], "only the spine, neck and head bow")
