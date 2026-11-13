extends "res://tests/test_case.gd"

## THINGS-CONVTIGHT (13 Nov 2026): the tighter conversation shot shipped on
## LANE-SCOUT's G-things-convtight.md (10 of 11 judged sets win, none lose).
const PATH := "res://data/config/camera.json"
const CONVERSATION := preload("res://scripts/player/conversation_camera.gd")


func _conversation() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_true(parsed is Dictionary)
	return (parsed as Dictionary).get("conversation", {})


func test_the_conversation_shot_is_the_judged_tight_one() -> void:
	var conversation := _conversation()
	assert_eq(float(conversation.get("fov", 0.0)), 36.0)
	# The judged 2.9 m arm is twoshot_v2's (ON); the plain block's distance was
	# never the one in play and stays 3.5.
	var live: Dictionary = CONVERSATION.config()
	assert_eq(float(live.get("distance", 0.0)), 2.9)
	assert_eq(float(live.get("fov", 0.0)), 36.0)
	assert_true(str(conversation.get("_why_tight_1113", "")).contains("G-things-convtight.md"))


func test_the_aftermath_shot_is_unchanged() -> void:
	var aftermath: Dictionary = (_conversation().get("profiles", {}) as Dictionary).get("aftermath", {})
	assert_eq(float(aftermath.get("distance", 0.0)), 5.2)
	assert_eq(float(aftermath.get("fov", 0.0)), 52.0)
