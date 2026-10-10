extends "res://tests/test_case.gd"

## A real initialized tree is essential: PartyStrip's off-tree test fallback
## sets alpha to one immediately and cannot reproduce a restarted Tween.
const STRIP := preload("res://scripts/ui/party_strip.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const MOTION := preload("res://scripts/ui/motion_prefs.gd")


func _strip(tree: SceneTree, enabled: bool, compact: bool = true) -> Control:
	var strip := STRIP.new()
	strip.progression_feedback_enabled = false
	tree.root.add_child(strip)
	strip.set_compact(compact)
	strip.set("_stable_compact_pin_reveal", enabled)
	return strip


func _repeat_pins(tree: SceneTree, strip: Control) -> void:
	var original: Tween = strip.get("_tween")
	assert_true(original != null, "fixture uses the live animated reveal path")
	var elapsed := 0.0
	var frames := 0
	while elapsed < TOKENS.T_PARTY_REVEAL * 3.0 and frames < 2000:
		var alpha := strip.modulate.a
		strip.call("set_pinned", true)
		assert_true(strip.get("_tween") == original, "repeated pin preserves the original tween")
		assert_almost_eq(strip.modulate.a, alpha, 0.00001, "pin does not reset partially revealed alpha")
		await tree.process_frame
		elapsed += tree.root.get_process_delta_time()
		frames += 1
	assert_true(elapsed >= TOKENS.T_PARTY_REVEAL * 3.0, "observed more than a complete reveal duration")
	assert_true(strip.visible)
	assert_almost_eq(strip.modulate.a, 1.0, 0.001, "repeated combat polls let the roster finish revealing")


func _case_live_repeated_pin() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var reduced_before := MOTION.reduced_motion()
	MOTION.set_reduced_motion(false)
	assert_true(STRIP.compact_pin_candidate_enabled(), "P2-088 passed its judge and ships on")
	var strip := _strip(tree, true)
	strip.call("set_pinned", true)
	await _repeat_pins(tree, strip)
	var first: Tween = strip.get("_tween")
	strip.call("set_pinned", false)
	assert_false(bool(strip.get("_pinned")))
	assert_almost_eq(float(strip.get("_fade_timer")), TOKENS.T_PARTY_FADE)
	assert_true(strip.visible, "unpin keeps the ordinary grace period")
	strip.call("set_pinned", true)
	assert_true(bool(strip.get("_pinned")))
	assert_true(strip.get("_tween") != first, "a new pin transition still starts its normal reveal")
	await _repeat_pins(tree, strip)
	strip.free()

	# Control cases exercise that same live-tree path. A paused/manual tween
	# step gives a nonzero midpoint without frame timing assumptions.
	for settings: Array in [[false, true], [true, false]]:
		var baseline := _strip(tree, bool(settings[0]), bool(settings[1]))
		baseline.call("set_pinned", true)
		var old: Tween = baseline.get("_tween")
		assert_true(old != null)
		if old != null:
			old.pause()
			old.custom_step(TOKENS.T_PARTY_REVEAL * 0.5)
			assert_true(baseline.modulate.a > 0.0, "control reached a partial reveal")
			baseline.call("set_pinned", true)
			assert_true(baseline.get("_tween") != old, "disabled candidate or exploration keeps baseline behavior")
			assert_almost_eq(baseline.modulate.a, 0.0)
		baseline.free()
	MOTION.set_reduced_motion(reduced_before)


func test_repeated_combat_pins_in_a_live_tree() -> void:
	# The unit runner invokes tests from SceneTree._init. Follow the existing
	# initialized-child convention used by test_combat_aftermath_focus.gd.
	var runner_path := "user://combat-roster-pin-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_combat_roster_pin_visual.gd").new()\n\tawait test._case_live_repeated_pin()\n\tprint("COMBAT_ROSTER_PIN_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	runner.close()
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", ProjectSettings.globalize_path(runner_path), "--log-file",
		ProjectSettings.globalize_path("user://combat-roster-pin-child.log")], output, true)
	var text := "\n".join(output)
	var marker := text.find("COMBAT_ROSTER_PIN_RESULT=")
	assert_true(marker >= 0, "child reported a result: %s" % text.right(600))
	if marker < 0:
		return
	var raw: Variant = JSON.parse_string(text.substr(marker + "COMBAT_ROSTER_PIN_RESULT=".length()).get_slice("\n", 0))
	var result: Dictionary = raw if raw is Dictionary else {}
	assert_eq(result.get("failures", ["unparsed"]), [])
	assert_true(int(result.get("assertions", 0)) >= 20)
	assert_eq(code, 0, "live-tree child exited cleanly")
