extends TestCase

## The Gate F instrumentation, checked where it can be checked without playing.
##
##   godot --headless --path . --script tests/run_tests.gd -- --only=gate_f
##
## `ralph/GATE_F_PROTOCOL.md` §1.5 freezes a candidate SHA and then forbids the
## operator to change code. Anything wrong with the harness after that point is
## a blocker and a re-freeze. So the failures worth a test here are the ones
## that would only surface halfway through a four-hour run:
##
##   * a segment step-script using an action the harness does not implement.
##     Ten segment files are being transcribed by a second agent from the
##     protocol's §E tables, against `tools/gate_f/SEGMENT_SCHEMA.md`. A typo'd
##     action is a hard stop at whatever step it sits on, hours in.
##   * the documented vocabulary and the implemented vocabulary drifting apart
##     in either direction. A documented action nobody built is a segment that
##     cannot run; an implemented action nobody documented is coverage the
##     transcriber does not know exists.
##   * the probe's POI radius drifting from the corridor probe's. Both feed the
##     same dead-travel figure, and if they disagree the chapter-wide number and
##     the per-segment number measure different worlds while looking comparable.
##   * a `vram` or fps field appearing in the telemetry. §C.1 marks both
##     [OWNER-ONLY] and requires the field to be ABSENT rather than fabricated.
##     That is a promise about honesty, and honesty promises rot silently.
##
## Deliberately NOT tested here: anything needing a live tree. `run_tests.gd`
## runs from its own `_init`, before Godot registers the main loop, so
## `Engine.get_main_loop()` is null and there is no `/root/Game` to ask. See the
## note at the foot of this file; the live half is `tests/smoke_gate_f_probe.gd`.
## Nor is whether the harness can drive the GAME: that needs a real scene, a real
## 240-frame stand-up and real input, and it is what
## `tools/gate_f/segments/selfcheck_*.json` are for. A unit test that mocked it
## would pass on a harness that presses nothing.

const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const HARNESS_PATH := "res://tools/gate_f/operator_harness.gd"
const SCHEMA_PATH := "res://tools/gate_f/SEGMENT_SCHEMA.md"
const SEGMENTS_DIR := "res://tools/gate_f/segments"
const CONFIG_PATH := "res://tools/gate_f/harness_config.json"
const CORRIDOR_PROBE_PATH := "res://tools/_probe_gate_f_corridor.gd"

## Actions the harness implements that the schema doc is not required to list
## as player-facing vocabulary. Empty on purpose: if an action exists, a
## transcriber has to be able to find out about it. Kept as a named list rather
## than an inline `[]` so that adding an exemption forces somebody to write down
## why.
const UNDOCUMENTED_ALLOWED: Array[String] = []


func _harness_source() -> String:
	return FileAccess.get_file_as_string(HARNESS_PATH)


func _schema_source() -> String:
	return FileAccess.get_file_as_string(SCHEMA_PATH)


## Every `"name":` case label in the harness's step `match`. Read from the
## source rather than from a list in the harness, because a list that had to be
## kept in step with the match is the same drift this test exists to catch.
func _implemented_actions() -> Array[String]:
	var source := _harness_source()
	var start := source.find("	match action:")
	var stop := source.find("\n		_:\n", start)
	if start < 0 or stop < 0:
		return []
	var out: Array[String] = []
	for line in source.substr(start, stop - start).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("\"") and trimmed.ends_with(":"):
			for part in trimmed.trim_suffix(":").split(","):
				var name := part.strip_edges().trim_prefix("\"").trim_suffix("\"")
				if not name.is_empty():
					out.append(name)
	return out


## Every action named in a `| \`name\` |` cell of the schema doc's tables.
func _documented_actions() -> Array[String]:
	var out: Array[String] = []
	var in_table := false
	for line in _schema_source().split("\n"):
		if line.begins_with("| Action |"):
			in_table = true
			continue
		if in_table and not line.begins_with("|"):
			in_table = false
			continue
		if not in_table or line.begins_with("|---"):
			continue
		var first := line.split("|")[1].strip_edges()
		if first.begins_with("`") and first.ends_with("`"):
			out.append(first.trim_prefix("`").trim_suffix("`"))
	return out


func test_every_documented_action_is_implemented() -> void:
	var implemented := _implemented_actions()
	assert_true(implemented.size() > 10,
		"could not parse the harness's step match at all; got %s" % str(implemented))
	for action in _documented_actions():
		assert_true(implemented.has(action),
			"SEGMENT_SCHEMA.md documents action '%s' but operator_harness.gd does not implement it -- a segment using it stops the run" % action)


func test_every_implemented_action_is_documented() -> void:
	var documented := _documented_actions()
	assert_true(documented.size() > 10,
		"could not parse SEGMENT_SCHEMA.md's action tables at all; got %s" % str(documented))
	for action in _implemented_actions():
		if UNDOCUMENTED_ALLOWED.has(action):
			continue
		assert_true(documented.has(action),
			"operator_harness.gd implements action '%s' and SEGMENT_SCHEMA.md never mentions it -- the transcriber cannot use coverage they cannot find" % action)


## The `assert` step's checks, same argument as the actions above: a segment
## asserting a check the harness does not know returns "unknown assert check",
## which records a FAIL against the GAME for a defect in the step script.
func test_every_documented_assert_check_is_implemented() -> void:
	var source := _harness_source()
	# The open paren is load-bearing: a bare `func _step_assert` also matches
	# `_step_assert_context`, and if that one sorts earlier in the file this
	# test reads the wrong body and reports every documented check as missing.
	var start := source.find("func _step_assert(")
	assert_true(start >= 0, "operator_harness.gd has no _step_assert()")
	var body := source.substr(start, source.find("\n\n\n", start) - start)
	var documented := 0
	var in_table := false
	for line in _schema_source().split("\n"):
		if line.begins_with("| `check` |"):
			in_table = true
			continue
		if in_table and not line.begins_with("|"):
			break
		if not in_table or line.begins_with("|---"):
			continue
		var name := line.split("|")[1].strip_edges().trim_prefix("`").trim_suffix("`")
		if name.is_empty():
			continue
		documented += 1
		assert_true(body.contains("\"%s\":" % name),
			"SEGMENT_SCHEMA.md documents assert check '%s' and _step_assert has no case for it" % name)
	assert_true(documented >= 8, "parsed only %d assert checks out of the schema doc" % documented)


# --- segment step-scripts ----------------------------------------------------

func _segment_files() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(SEGMENTS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			out.append(SEGMENTS_DIR.path_join(name))
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


func test_there_is_at_least_one_segment_script() -> void:
	# A green suite over an empty directory would be the "passes because the
	# feature is absent" failure ralph/conventions.md names.
	assert_true(_segment_files().size() >= 2,
		"tools/gate_f/segments/ holds %d step-scripts; the two self-checks alone should be there"
			% _segment_files().size())


func test_every_segment_script_is_well_formed() -> void:
	var vocabulary := _implemented_actions()
	for path in _segment_files():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true(typeof(parsed) == TYPE_DICTIONARY, "%s is not a JSON object" % path)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var segment := parsed as Dictionary
		assert_eq(str(segment.get("id", "")), path.get_file().get_basename(),
			"%s: the segment's `id` must match its filename -- run_segment.sh names the output directory from the file and the harness stamps `segment` from the key, and a mismatch is two names for one run" % path)
		var steps: Array = segment.get("steps", []) as Array
		assert_true(steps.size() > 0, "%s has no steps" % path)
		var seen_ids: Dictionary = {}
		for raw: Variant in steps:
			assert_true(typeof(raw) == TYPE_DICTIONARY, "%s: a step is not an object" % path)
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var step := raw as Dictionary
			var id := str(step.get("id", ""))
			assert_false(id.is_empty(), "%s: a step has no id; a defect cannot be cited against it" % path)
			assert_false(seen_ids.has(id), "%s: duplicate step id '%s'" % [path, id])
			seen_ids[id] = true
			var action := str(step.get("action", ""))
			assert_true(vocabulary.has(action),
				"%s step %s: action '%s' is not implemented by operator_harness.gd" % [path, id, action])
			assert_false(str(step.get("expected", "")).is_empty(),
				"%s step %s: no `expected`. The operator's verdict is against the step's stated expectation, and a step with none cannot be judged." % [path, id])


## §J: teleport only in DIAG segments. The harness refuses an unmarked one at
## run time; this catches it before the run, which is the cheaper place.
func test_no_segment_teleports_without_declaring_it_diagnostic() -> void:
	for path in _segment_files():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		for raw: Variant in ((parsed as Dictionary).get("steps", []) as Array):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var step := raw as Dictionary
			if str(step.get("action", "")) != "teleport":
				continue
			assert_true(bool(step.get("diag", false)),
				"%s step %s teleports without \"diag\": true. Teleport is DIAG-only (protocol §J); a walked route is the evidence." % [path, str(step.get("id", "?"))])


# --- honesty -----------------------------------------------------------------

## §C.1: `vram` is "not recorded -- [OWNER-ONLY]; field intentionally absent
## rather than fabricated", and the `perf` row carries CPU shape only because
## device fps is [OWNER-ONLY] too.
##
## Checked against the SOURCE rather than against a produced file: a run that
## happened not to emit the field proves nothing about the next one, and the
## point is that there is no code path that could.
func test_the_telemetry_can_never_report_vram_or_a_device_frame_rate() -> void:
	for path in [HARNESS_PATH, "res://scripts/debug/gate_f_probe.gd"]:
		var source := FileAccess.get_file_as_string(path)
		for line in source.split("\n"):
			# Comments are where both fields are DISCUSSED, at length and on
			# purpose. It is a written field name in emitted data that is banned.
			if line.strip_edges().begins_with("#"):
				continue
			assert_false(line.contains("\"vram\""),
				"%s writes a \"vram\" field. §C.1 requires it to be absent, not fabricated: %s" % [path, line.strip_edges()])
			assert_false(line.contains("\"fps\"") or line.contains("\"frames_per_second\""),
				"%s writes an fps field. Device frame rate is [OWNER-ONLY]; this container has a software rasteriser: %s" % [path, line.strip_edges()])


## The corridor probe's `NOTICE_M` and the live probe's `POI_RADIUS_M` both
## express §F's 30 m. Two constants, one definition; this is the test that stops
## them diverging while both keep reporting "dead travel".
func test_the_poi_radius_matches_the_corridor_probes() -> void:
	assert_almost_eq(PROBE.POI_RADIUS_M, 30.0, 0.001,
		"§F fixes the POI radius at 30 m")
	var source := FileAccess.get_file_as_string(CORRIDOR_PROBE_PATH)
	var found := false
	for line in source.split("\n"):
		if line.begins_with("const NOTICE_M"):
			found = true
			var value := float(line.split(":=")[1].strip_edges())
			assert_almost_eq(value, PROBE.POI_RADIUS_M, 0.001,
				"tools/_probe_gate_f_corridor.gd::NOTICE_M is %.1f and gate_f_probe.gd::POI_RADIUS_M is %.1f. Both feed a dead-travel figure the protocol compares; they cannot differ." % [value, PROBE.POI_RADIUS_M])
	assert_true(found, "could not find NOTICE_M in %s" % CORRIDOR_PROBE_PATH)


## The probe must not be an autoload. §2 is explicit, and the prime directive
## depends on it: a shipped build must not carry the instrumentation at all.
func test_the_probe_is_not_wired_into_the_shipped_build() -> void:
	var project := FileAccess.get_file_as_string("res://project.godot")
	assert_false(project.contains("gate_f_probe"),
		"project.godot references gate_f_probe. The probe is loaded by the harness only; an autoload would run it in the shipped game.")


## Telemetry activates only under a CLI flag. If the harness could write with no
## `--gatef-out`, "telemetry off leaves zero new files" would stop being true
## the first time somebody ran it without the flag.
func test_telemetry_is_gated_on_the_output_flag() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _telemetry_on() -> bool:\n\treturn not _out_dir.is_empty()"),
		"the harness's telemetry gate is not `_out_dir` being non-empty any more; acceptance item 5 depends on it")
	for guard in ["func _emit(", "func _write_trace_row(", "func _close_outputs("]:
		var start := source.find(guard)
		assert_true(start >= 0, "harness has no %s" % guard)
		var head := source.substr(start, 220)
		assert_true(head.contains("_telemetry_on()"),
			"%s does not check _telemetry_on() before writing" % guard)


# --- config ------------------------------------------------------------------

## Every key the harness defaults must exist in the config file, and vice versa.
## A key in one and not the other is a tunable that silently does nothing --
## which is worse than no config, because somebody will change it and believe
## the run changed.
func test_the_harness_config_and_its_defaults_agree() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	assert_true(typeof(parsed) == TYPE_DICTIONARY, "%s is not a JSON object" % CONFIG_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var config := parsed as Dictionary
	var source := _harness_source()
	var start := source.find("var _cfg := {")
	assert_true(start >= 0, "the harness has no _cfg defaults block")
	var block := source.substr(start, source.find("\n}", start) - start)
	var defaults: Array[String] = []
	for line in block.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("\""):
			defaults.append(trimmed.split("\"")[1])
	assert_true(defaults.size() >= 5, "parsed only %d default keys" % defaults.size())
	for key in defaults:
		assert_true(config.has(key),
			"harness_config.json has no '%s'; the harness would silently use its built-in default" % key)
	for key: Variant in config.keys():
		if str(key).begins_with("_comment"):
			continue
		assert_true(defaults.has(str(key)),
			"harness_config.json sets '%s' and the harness reads no such key -- editing it would change nothing" % str(key))


## §G's GF-01 rows carry `hud: "as shipped"`, which is neither `on` nor `off`.
## The manifest must record it verbatim: a harness that coerced it to a boolean
## would file the title screen as an ordinary HUD-on gameplay frame, and the
## whole point of that row is that the title has no HUD to speak of.
func test_the_hud_field_is_recorded_verbatim_and_never_coerced() -> void:
	var source := _harness_source()
	assert_true(source.contains('"hud": str(args.get("hud", "on"))'),
		"the capture manifest row no longer stores `hud` as a plain string; §G's \"as shipped\" would be lost")
	# The coercion this guards against, in the shapes it would actually take.
	for shape in ['hud == "on"', 'hud == "off"', 'hud_on', 'bool(args.get("hud"']:
		assert_false(source.contains(shape),
			"operator_harness.gd looks like it interprets `hud` (%s); §G authors three values, not two" % shape)
	# And at least one segment really does use it, or this test guards nothing.
	var seen := false
	for path in _segment_files():
		if FileAccess.get_file_as_string(path).contains('"hud": "as shipped"'):
			seen = true
	assert_true(seen, "no segment uses `hud: \"as shipped\"`, so nothing here is actually being protected")


## §L.1's KBM parity row. `_physical_binding` prefers joypad, so every
## dual-bound action resolved to its pad binding and the keyboard half was
## unreachable while the cell read as covered. `device` makes it reachable; a
## miss must be a recorded FAIL rather than a fallback, because a silent
## fallback is exactly how that stayed invisible.
func test_a_named_device_never_silently_falls_back_to_another() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _physical_binding(action: StringName, device: String = \"\") -> InputEvent:"),
		"_physical_binding no longer takes a device; §L.1's KBM half becomes unreachable again")
	var start := source.find("func _physical_binding")
	var body := source.substr(start, source.find("\n\n\n", start) - start)
	assert_true(body.contains("if not device.is_empty():\n\t\treturn by_kind.get(device) as InputEvent"),
		"a named device must return that device's binding or null -- never walk the preference order")
	assert_true(source.contains("device_miss"),
		"a named-device miss must be reported as a FAIL the run records, not a harness error and not a fallback")


## The four checks §E.6.13's restoration checklist and §E.4/§L.6-T01 need. All
## four values were already on the event fields; without the checks, X05 records
## the numbers and verdicts nothing -- a save/load that dropped every building
## would read as PASS.
func test_the_restoration_checks_exist_and_take_comparators() -> void:
	var source := _harness_source()
	var start := source.find("func _step_assert")
	var body := source.substr(start, source.find("\n\n\n", start) - start)
	for check in ["mouse_captured", "satiety", "clock_hour", "placed_buildings"]:
		assert_true(body.contains("\"%s\":" % check),
			"_step_assert has no '%s' case; the value is on the event and nothing can verdict it" % check)
	assert_true(source.contains("func _compare("),
		"the numeric checks need a named comparator helper (equals/at_least/at_most)")
	var cmp_start := source.find("func _compare(")
	var cmp := source.substr(cmp_start, source.find("\n\n\n", cmp_start) - cmp_start)
	assert_true(cmp.contains("at_least") and cmp.contains("at_most") and cmp.contains("equals"),
		"_compare must offer all three comparators")
	assert_true(cmp.contains("named no comparator"),
		"a check with no comparator must FAIL saying so, not silently compare against zero")
	# The midnight wrap. 23.9 and 0.1 are 0.2 apart; a plain subtraction says
	# 23.8 and a save/load restoration check would fail across midnight.
	assert_true(body.contains("fmod(absf(have - want) + 12.0, 24.0) - 12.0"),
		"clock_hour must wrap across midnight, or a restoration check fails at 23:xx for arithmetic reasons")


## §E.7's pin-and-freeze. The 2026-08-23 crimson artefact came from a pin the
## day cycle undid during the settle; the freeze is what makes the pin hold.
func test_pin_clock_freezes_both_clocks_and_is_diag_only() -> void:
	var source := _harness_source()
	var start := source.find("func _step_pin_clock")
	assert_true(start >= 0, "no pin_clock action; §E.7's regional audit has no way to pin the light")
	var body := source.substr(start, source.find("\n\n\n", start) - start)
	# BOTH nodes and BOTH process kinds. The look re-blends on idle; the weather
	# rolls its own preset on a timer. Stopping one leaves the other free to
	# move the light, which is the failure being prevented.
	assert_true(body.contains("look.set_process(false)") and body.contains("look.set_physics_process(false)"),
		"pin_clock must stop WorldLook's idle AND physics processing")
	assert_true(body.contains("weather_node.set_process(false)")
			and body.contains("weather_node.set_physics_process(false)"),
		"pin_clock must stop WorldWeather too -- it rolls its own preset on a timer")
	# Through the game's own appliers, not a second interpolation.
	assert_true(body.contains('look.call("apply_time"'), "the preset path must go through apply_time()")
	assert_true(body.contains('look.call("_apply_blended"'),
		"the hour path must go through _apply_blended(), the same continuous path world_look.gd::_process uses")
	assert_true(source.contains("pin_clock refused: step is not marked"),
		"pin_clock must be DIAG-only, refused with a recorded FAIL like teleport")


## §H. The continuous record has to be continuous: a recorder that only ran
## between explicit start/stop pairs would leave the rest of a segment blank.
func test_the_continuous_recorder_has_a_segment_baseline_and_forced_frames() -> void:
	var source := _harness_source()
	assert_true(source.contains('_record_baseline_hz = float(segment.get("record_hz", _cfg["record_default_hz"]))'),
		"the §H baseline must come from the segment's own top-level record_hz, defaulting from config")
	assert_true(source.contains("func _force_frame("),
		"§H requires a forced frame on every JSONL event")
	var emit_start := source.find("func _emit(")
	var emit_body := source.substr(emit_start, source.find("\n\n\n", emit_start) - emit_start)
	assert_true(emit_body.contains("_force_frame(type)"),
		"_emit must ask for a frame; otherwise 'a frame on every JSONL event' is not implemented")
	# frames/, not shots/. The §G plan is evidence-of-record and must not be
	# diluted by the cadence stream.
	assert_true(source.contains('"frames/%s/%09.2f.png"'),
		"§H files continuous frames as frames/<segment>/<t>.png, zero-padded so the directory sorts by time")
	var frame_start := source.find("func _write_frame(")
	var frame_body := source.substr(frame_start, source.find("\n\n\n", frame_start) - frame_start)
	assert_false(frame_body.contains("_manifest.append"),
		"the recorder must not write into shots/manifest.json -- §G's plan is evidence-of-record")
	# Deterministic collision rule.
	assert_true(source.contains("_capture_step_active"),
		"capture and the recorder must not race for the same framebuffer; the prescribed shot wins")
	var rec_start := source.find("func _recorder_tick(")
	var rec_body := source.substr(rec_start, source.find("\n\n\n", rec_start) - rec_start)
	assert_true(rec_body.contains("_capture_step_active"),
		"_recorder_tick must stand down while a capture step is running")


## §3's last clause and §H's: if the instrumentation costs frame time, say so.
## The check is that the code cannot report a difference it did not measure.
func test_the_overhead_note_cannot_report_a_delta_it_did_not_measure() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _overhead_verdict("),
		"the overhead note must classify a delta rather than asserting it is fine")
	var start := source.find("func _overhead_verdict(")
	var body := source.substr(start, source.find("\n\n\n", start) - start)
	assert_true(body.contains("OVER the ~1 ms/frame"),
		"a delta over ~1 ms/frame must say so plainly (§3's last clause)")
	assert_true(body.contains("below the noise floor"),
		"a delta smaller than the measurement's own noise must be reported as such, never as zero")
	assert_true(body.contains("NOT thinned"),
		"the note must state that the trace was not thinned to make the number look better")
	# Three conditions, each run twice, reversed. One window per condition
	# produced -0.607 ms/frame -- telemetry apparently making the game faster.
	assert_true(source.contains('var order := ["off", "telemetry", "recording", "recording", "telemetry", "off"]'),
		"the overhead probe must run each condition twice in reversed order; a single ordered pair measures drift")


# --- why the live-state checks are not here ---------------------------------
#
# `run_tests.gd` runs every test file from its own `_init`, before Godot has
# registered the main loop: `Engine.get_main_loop()` returns a null Object and
# `... as SceneTree` yields null, so there is no tree, no `/root/Game`, and no
# way to ask the probe anything about live state. Measured, not assumed -- the
# first cut of this file had three such tests and all three passed by returning
# early on a null tree, which is exactly the assertion-that-cannot-fail
# `ralph/conventions.md` says shipped a real bug on this project for weeks.
#
# That is also `docs/decisions/D02`'s stated scope for this runner: pure logic,
# not scenes. The live-state half lives in `tests/smoke_gate_f_probe.gd`, which
# is a SceneTree script and therefore has a tree to ask.
