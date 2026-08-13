extends "res://tests/test_case.gd"

## `scripts/ui/audio_cues.gd` -- the cue map resolves to real files, and the
## static, headless-safe surface (`play`, `should_play`) does not crash or
## lie about its own rate limit. `play()`'s scene-tree/audio-device half is
## out of scope for this pure headless harness (docs/decisions/D02); that half
## is exercised end to end by `smoke_menu.gd` and `smoke_free_build.gd`
## driving the wired call sites in game_menu.gd/build_menu.gd/build_placer.gd.

const AUDIO_CUES := preload("res://scripts/ui/audio_cues.gd")


func test_every_cue_resolves_to_a_file_on_disk() -> void:
	for cue in AUDIO_CUES.CUE_PATHS.keys():
		var path: String = AUDIO_CUES.CUE_PATHS[cue]
		assert_true(ResourceLoader.exists(path), "missing cue file for '%s' at %s" % [cue, path])


func test_cue_map_has_the_nine_named_cues() -> void:
	var expected: Array[String] = [
		"ui_focus", "ui_accept", "ui_cancel", "ui_tab", "ui_error",
		"aim_enter", "build_snap", "build_place", "capture_success",
	]
	assert_eq(AUDIO_CUES.CUE_PATHS.size(), expected.size())
	for cue in expected:
		assert_true(AUDIO_CUES.CUE_PATHS.has(cue), "cue map missing '%s'" % cue)


func test_play_does_not_crash_headless_called_twice() -> void:
	AUDIO_CUES.play(&"ui_accept")
	AUDIO_CUES.play(&"ui_accept")
	assert_true(true, "reaching this line means play() did not crash headless")


func test_play_unknown_cue_does_not_crash() -> void:
	AUDIO_CUES.play(&"not_a_real_cue")
	assert_true(true, "reaching this line means an unknown cue was ignored, not errored")


# --- should_play: the pure rate-limit boundary --------------------------------


func test_should_play_is_true_on_first_ask() -> void:
	assert_true(AUDIO_CUES.should_play(&"__test_first_ask", 0.0))


func test_should_play_is_false_inside_the_window() -> void:
	var cue := &"__test_inside_window"
	assert_true(AUDIO_CUES.should_play(cue, 10.0))
	assert_false(AUDIO_CUES.should_play(cue, 10.0 + AUDIO_CUES.MIN_INTERVAL_S - 0.01))


func test_should_play_is_true_exactly_at_the_window_edge() -> void:
	var cue := &"__test_at_edge"
	assert_true(AUDIO_CUES.should_play(cue, 20.0))
	assert_true(AUDIO_CUES.should_play(cue, 20.0 + AUDIO_CUES.MIN_INTERVAL_S))


func test_should_play_is_true_again_well_after_the_window() -> void:
	var cue := &"__test_well_after"
	assert_true(AUDIO_CUES.should_play(cue, 30.0))
	assert_true(AUDIO_CUES.should_play(cue, 30.0 + AUDIO_CUES.MIN_INTERVAL_S * 5.0))


func test_should_play_rate_limits_independently_per_cue() -> void:
	assert_true(AUDIO_CUES.should_play(&"__test_cue_a", 40.0))
	# A different cue at the same instant is unaffected by cue A's own limit.
	assert_true(AUDIO_CUES.should_play(&"__test_cue_b", 40.0))
