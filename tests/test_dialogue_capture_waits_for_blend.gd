extends "res://tests/test_case.gd"

## The dialogue capture must not take its frame while the conversation camera
## is still easing in (GPU re-score, 11 Nov: 9 of 11 Tidewake dialogue frames
## were taken at blend 0.41 to 0.74).

const TOOL := "res://tools/phase2_capture_dialogue.gd"


func test_the_capture_waits_for_the_conversation_blend() -> void:
	var code := FileAccess.get_file_as_string(TOOL)
	var start := code.find("func _settle_dialogue_capture()")
	assert_true(start >= 0, "the settle step exists")
	var body := code.substr(start, code.find("\nfunc ", start + 1) - start)
	assert_true(body.contains("conversation_blend\")) < 1.0"), "the settle step waits on the rig's blend")
	assert_true(body.contains("await physics_frame"), "it waits on physics ticks, the clock the blend runs on")
	assert_true(body.contains("BLEND_WAIT_MAX_TICKS"), "the wait is bounded")
	assert_true(body.contains("push_warning"), "a timeout is logged")


func test_the_wait_covers_the_configured_blend_time() -> void:
	var script: GDScript = load(TOOL)
	var ticks := int(script.get_script_constant_map().get("BLEND_WAIT_MAX_TICKS", 0))
	var camera: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/camera.json"))
	var blend_s := float(camera.conversation.get("blend_time", 0.45))
	var hz := float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60))
	assert_true(float(ticks) / hz >= blend_s * 3.0, "the bound is at least three blend times (%d ticks, %.2f s blend)" % [ticks, blend_s])


func test_the_manifest_records_the_wait() -> void:
	var code := FileAccess.get_file_as_string(TOOL)
	for field: String in ["conversation_camera_blend\"]", "conversation_camera_blend_wait_ticks", "conversation_camera_blend_timed_out"]:
		assert_true(code.contains(field), "the manifest keeps %s" % field)
