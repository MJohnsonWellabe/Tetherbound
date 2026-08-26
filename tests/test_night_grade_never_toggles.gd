extends "res://tests/test_case.gd"

## The colour-grade pass must be ON at every hour, and must never be switched.
##
## WHAT THIS DOES AND DOES NOT FIX -- read this first, because the commit that
## added this file got it wrong and the correction matters more than the claim.
##
## IT DOES NOT FIX THE CRIMSON NIGHT. A twelve-hour sweep re-run with this change
## in place still reads R/B 3.43 at hour 22.00 against 0.53 at 20.50 -- unchanged
## from before it. Whatever turns the world red at night is still there and is
## still being chased. Nothing in this file may be cited as evidence that it is
## fixed.
##
## WHAT IT DOES FIX is a real but smaller thing: `world_look.gd::_blend_dict` has
## no meaningful blend for a boolean and snaps one at `t >= 0.5`. `night` was the
## only preset declaring `adjustment_enabled`, `golden` sits at hour 18 and
## `night` at hour 0, so the flag flipped at exactly hour 21.0 on that segment and
## flipped back on `day -> golden` -- twice per 600-second day. Two consequences,
## both removed here: the whole colour-grade pass switched on and off mid-blend,
## and night's own grade (saturation 0.72, contrast 1.08) arrived all at once at
## hour 21 instead of easing in. It now lerps from the base block's 1.0.
##
## THE ONE MEASUREMENT THAT STILL STANDS behind keeping the pass always on:
## `tools/_probe_night_crimson.gd` shot one pinned, frozen frame at hour 22 twice,
## changing nothing but this flag -- grade on, R/B 0.44, a correct cool night;
## grade off, R/B 2.82 on identical geometry and shadows. So the grade being on is
## PROTECTIVE at that hour even though it is not the whole story, and a preset
## being able to switch it off mid-blend is worth preventing on those grounds
## alone.
##
## WHAT THIS FILE PINS. Two independent halves, each of which fails on its own:
## the code may not derive the flag from config, and no preset may declare it.
## Either alone closes the toggle; both together mean reverting one does not
## silently reopen it. The config half genuinely failed on the tree as it stood
## before this branch, which is what makes it a test rather than a restatement.
##
## Deliberately a source-and-config test, per docs/decisions/D02: this harness is
## pure logic, not scenes and not rendering.

const LOOK_SOURCE := "res://scripts/world/world_look.gd"
const ART_CONFIG := "res://data/config/art.json"


## The code half: the flag is a constant, not a config lookup.
func test_world_look_never_reads_the_grade_flag_from_config() -> void:
	var source := FileAccess.get_file_as_string(LOOK_SOURCE)
	assert_false(source.is_empty(), "could not read %s" % LOOK_SOURCE)
	assert_true(source.contains("env.adjustment_enabled = true"),
		"%s must set adjustment_enabled to a constant true. Toggling it at runtime turns the frame red under the Compatibility renderer (D01); see this file's header for the measurement." % LOOK_SOURCE)
	assert_false(source.contains("cfg.get(\"adjustment_enabled\""),
		"%s reads adjustment_enabled back from config. That is the toggle: _blend_dict snaps a boolean at t >= 0.5, so a per-preset value flips the flag mid-blend and the frame goes red from that moment on." % LOOK_SOURCE)


## The config half: every preset inherits one no-op grade rather than
## introducing or removing the pass.
func test_no_time_of_day_preset_declares_the_grade_flag() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ART_CONFIG))
	assert_true(typeof(parsed) == TYPE_DICTIONARY, "art.json is not a JSON object")
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var art := parsed as Dictionary

	var base: Dictionary = art.get("environment", {})
	assert_true(base.has("adjustment_enabled"),
		"art.json's base `environment` block must declare adjustment_enabled, so every time-of-day preset merges over the SAME value instead of some presets having the key and others not.")
	assert_eq(bool(base.get("adjustment_enabled", false)), true,
		"art.json's base adjustment_enabled must be true. The grade pass stays on at every hour; a preset that wants no grade sets the three values to 1.0, which is identity.")
	for key: String in ["adjustment_brightness", "adjustment_contrast", "adjustment_saturation"]:
		assert_true(base.has(key),
			"art.json's base `environment` block must declare %s, so a preset's own value lerps in from a no-op rather than appearing all at once when some other key snaps." % key)
		assert_almost_eq(float(base.get(key, -1.0)), 1.0, 0.0001,
			"art.json's base %s must be 1.0 (identity). The base block is what an ungraded hour looks like." % key)

	var times: Dictionary = art.get("times", {})
	for name: String in times.keys():
		if name.begins_with("_"):
			continue
		var entry: Variant = times[name]
		if not entry is Dictionary:
			continue
		var env: Dictionary = (entry as Dictionary).get("environment", {})
		assert_false(env.has("adjustment_enabled"),
			"art.json's `%s` preset declares adjustment_enabled. A per-preset value is exactly what _blend_dict snaps at t >= 0.5, which is the toggle that turns the frame red. Grade with the three VALUES instead -- they lerp." % name)
