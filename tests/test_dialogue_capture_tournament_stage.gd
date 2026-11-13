extends "res://tests/test_case.gd"

## LANE-THINGS, 13 Nov 2026 (F38#16, GPU 3/3: Mira's tournament-round frame
## showed a lattice wall and no speaker). A tournament round's lines are staged
## by tournament_dialogue_presentation.gd at the round's own spot, with a copy
## of the opponent; the dialogue capture must leave the player at that post
## rather than walk them to the opponent's home body.

const TOOL := "res://tools/phase2_capture_dialogue.gd"
const STAGING := "res://scripts/world/tournament_dialogue_presentation.gd"


func test_the_capture_leaves_staged_conversations_at_their_post() -> void:
	var code := FileAccess.get_file_as_string(TOOL)
	assert_true(code.contains("func _staged_at_post(row: Dictionary) -> bool:"), "the staged check exists")
	var frame := code.substr(code.find("func _frame_speaker(row: Dictionary) -> String:"), 600)
	assert_true(frame.contains("if _staged_at_post(row):") and frame.contains("return \"staged\""),
		"a staged conversation is not walked to the home body")
	assert_true(code.contains("if post_body != null and not _staged_at_post(row):"),
		"and its post frame is not re-seated onto the home body")


func test_the_staging_script_still_keeps_the_conversations_the_capture_reads() -> void:
	var code := FileAccess.get_file_as_string(STAGING)
	assert_true(code.contains("var _conversations: Dictionary = {}"), "the capture reads _conversations")
	assert_true(code.contains("camera.call(\"begin\", proxy"), "the staging frames its own copy of the speaker")
	var tool: GDScript = load(TOOL)
	assert_true(tool != null, "the capture tool still parses")
