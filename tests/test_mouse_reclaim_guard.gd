extends "res://tests/test_case.gd"

## Playtest (2026-09-29): the mouse stopped turning the camera after the build menu and
## after trading with Oskar. Panels restore the mouse on close only when nothing else
## owns input at that instant, so a close inside another panel's ownership window left
## the mouse free for good. The world now hands it back once nothing owns input.
## The headless display server cannot report a real mouse mode, so this pins the
## wiring in source (the repo's own convention for engine-only behaviour).

const WORLD_PATH := "res://scripts/world/playground_world.gd"
const BUILD_MENU_PATH := "res://scripts/ui/build_menu.gd"


func test_the_world_reclaims_the_mouse_when_no_panel_owns_input() -> void:
	var src := FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(src.contains("func _reclaim_mouse_if_released() -> void:"), "the safety net exists")
	assert_true(src.contains("_reclaim_mouse_if_released()\n\tif _vegetation == null"),
		"_process runs it every MOUSE_GUARD_INTERVAL, before the vegetation gate")
	var body := src.substr(src.find("func _reclaim_mouse_if_released() -> void:"), 700)
	assert_true(body.contains("INPUT_OWNER.current(get_tree()) != null"), "it waits for input ownership to end")
	assert_true(body.contains("_mouse_wanted_elsewhere()"), "and for every panel that wants the cursor")
	assert_true(body.contains("Input.mouse_mode = Input.MOUSE_MODE_CAPTURED"), "then re-captures for camera look")
	assert_true(body.contains("\"headless\""), "and is a no-op where the mode cannot be observed")


func test_the_build_menu_restores_by_ownership_not_by_a_cached_mode() -> void:
	var src := FileAccess.get_file_as_string(BUILD_MENU_PATH)
	var close_at := src.find("func close(play_cue: bool = true) -> void:")
	assert_true(close_at >= 0, "close() exists")
	var body := src.substr(close_at, 1400)
	assert_true(body.contains("INPUT_OWNER.current(tree) == null"), "close() checks the live ownership graph")
	assert_true(body.contains("Input.mouse_mode = Input.MOUSE_MODE_CAPTURED"), "and captures once nothing owns the screen")
