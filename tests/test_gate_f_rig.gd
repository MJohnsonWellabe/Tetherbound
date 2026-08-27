extends TestCase

## The Gate F RIG fixes, tested where they can be tested without playing.
##
##   godot --headless --path . --script tests/run_tests.gd -- --only=gate_f_rig
##
## `tests/test_gate_f_instrumentation.gd` asks whether the harness's vocabulary
## and the protocol's agree. This file asks a narrower and later question: after
## the run against candidate `f082bdf6` captured 8.0% of the known issues, does
## the instrument still have the four defects that produced that number?
##
## Each test below is named for the coverage defect it guards. They are worth
## having as tests rather than as prose because every one of them was, at the
## time it was found, a thing the code *looked* like it did:
##
##   * CD-1 — a capture step under a headless process returned the string
##     "capture … skipped", which does not begin with FAIL, so `_do_step`
##     recorded PASS. 9,231 times. Nothing in the file was wrong to read.
##   * CD-2 — `shots/<id>.png` was written correctly and `.gitignore` matched
##     `shots/` unanchored, at every depth. The harness wrote the evidence and
##     git declined to commit it. Neither half looks like a defect alone.
##   * CD-3 — dialogue advance was a fixed press count. A fixed press count is
##     not a bug you can see; it is a bug you can only see the consequences of,
##     two steps later, in a different segment.
##   * GF-B-011 — thirteen of §C.1's twenty-nine event types were never emitted.
##     An enum with an unemitted member reads exactly like an enum without one.
##
## What is NOT here: whether the harness can drive the GAME. That needs a real
## scene, a real stand-up and real input, and it is what
## `tools/gate_f/segments/selfcheck_*.json` are for — specifically
## `selfcheck_dialogue` and `selfcheck_context`, which exist for these fixes.
## A unit test that mocked a modal would pass on a harness that presses nothing.

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")
const HARNESS_PATH := "res://tools/gate_f/operator_harness.gd"
const SCHEMA_PATH := "res://tools/gate_f/SEGMENT_SCHEMA.md"
const PROTOCOL_PATH := "res://ralph/GATE_F_MASTER_PROTOCOL.md"
const GITIGNORE_PATH := "res://.gitignore"


func _harness_source() -> String:
	return FileAccess.get_file_as_string(HARNESS_PATH)


# --- GF-B-002 primitive 1: the context predicate -----------------------------

func test_context_matching_handles_exact_prefix_negation_and_lists() -> void:
	assert_true(HARNESS._context_matches("world", "world"))
	assert_false(HARNESS._context_matches("world", "narrative_modal"))
	# `menu*` has to cover every tab of the pause shell. `input_context()`
	# returns `menu_backpack`, `menu_map`, … and a segment that had to name all
	# seven would name six.
	assert_true(HARNESS._context_matches("menu_backpack", "menu*"))
	assert_true(HARNESS._context_matches("menu", "menu*"))
	assert_false(HARNESS._context_matches("world", "menu*"))
	# The negation is the form most world-verb steps actually mean: not "I am
	# in the world" but "nothing has taken input away from me".
	assert_true(HARNESS._context_matches("world", "!narrative_modal"))
	assert_false(HARNESS._context_matches("narrative_modal", "!narrative_modal"))
	assert_true(HARNESS._context_matches("combat", ["world", "combat", "combat_aim"]))
	assert_false(HARNESS._context_matches("menu_map", ["world", "combat"]))
	# A list of negations must AND, not OR, or `["!menu*", "!narrative_modal"]`
	# would pass in a menu. `_context_matches` ORs the list, so this is the
	# shape that does NOT work and the schema tells transcribers to use one
	# negation or a positive list instead. Asserted so the limitation is
	# recorded rather than discovered mid-run.
	assert_true(HARNESS._context_matches("menu_map", ["!menu*", "!narrative_modal"]))


# --- GF-B-003 / CD-1: a capture that cannot be taken is a FAIL ---------------

func test_an_untakeable_capture_reports_fail_not_pass() -> void:
	var source := _harness_source()
	var start := source.find("func _step_capture(")
	assert_true(start >= 0, "operator_harness.gd has no _step_capture()")
	var body := source.substr(start, source.find("\nfunc _step_capture_seq", start) - start)
	var branch := body.find("if not _capture_available():")
	assert_true(branch >= 0, "_step_capture no longer branches on _capture_available()")
	var tail := body.substr(branch, body.find("if not _telemetry_on():", branch) - branch)
	assert_true(tail.contains("return \"FAIL"),
		"CD-1: the headless branch of _step_capture must return a string beginning FAIL. "
		+ "It returned \"capture … skipped\", which _do_step records as PASS, and the "
		+ "f082bdf6 run reported PASS for 9,231 captures it never took.")


func test_the_capture_preflight_exists_and_blocks() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _preflight_capture("),
		"CD-1: there is no capture pre-flight; a segment can still be launched without a display server")
	var start := source.find("func _preflight_capture(")
	var body := source.substr(start, source.find("\n## Can this process read back", start) - start)
	# The three separate questions. They fail separately and a pre-flight that
	# only asked the first would pass on a box whose renderer is broken.
	assert_true(body.contains("_capture_available()"),
		"the pre-flight must ask DisplayServer, not trust the --gatef-capture flag")
	assert_true(body.contains("capture_smoke.png"),
		"§A.4 gates the capture lane on tools/capture_diag_minimal.gd; the pre-flight must "
		+ "check its artefact, or a segment started around run_segment.sh skips the gate")
	assert_true(body.contains("_preflight_png()"),
		"the pre-flight must prove THIS process can read back and encode a frame")
	assert_true(body.contains("_blocked = why"),
		"a failed pre-flight must BLOCK the segment, not warn and continue")
	assert_true(body.contains("BLOCKER.md"),
		"a blocked segment must leave a file whose NAME says so")


func test_the_preflight_only_gates_segments_that_plan_evidence() -> void:
	# A logic-only self-check must not be blocked. Blocking a segment that
	# declares no captures would be the mirror-image mistake: making the rig
	# refuse work it can legitimately do.
	var plan: Array = HARNESS._plan_captures([
		{"id": "A-01", "action": "boot", "args": {"scene": "world"}},
		{"id": "A-02", "action": "wait", "args": {"seconds": 1}},
	])
	assert_eq(plan.size(), 0, "a segment with no capture steps must plan no captures")


func test_capture_seq_is_planned_frame_by_frame() -> void:
	# CD-2's ledger is only useful if a sequence that wrote three of twenty
	# frames reads as seventeen absences rather than one.
	var plan: Array = HARNESS._plan_captures([
		{"id": "A-01", "action": "capture", "args": {"id": "SHOT", "class": "defect"}},
		{"id": "A-02", "action": "capture_seq", "args": {"id": "SEQ", "hz": 4, "seconds": 0.75}},
	])
	assert_eq(plan.size(), 4, "one capture plus a 4 Hz / 0.75 s sequence is 1 + 3 planned frames")
	assert_eq(str((plan[0] as Dictionary)["id"]), "SHOT")
	assert_eq(str((plan[0] as Dictionary)["class"]), "defect")
	assert_eq(str((plan[1] as Dictionary)["id"]), "SEQ-000")
	assert_eq(str((plan[3] as Dictionary)["id"]), "SEQ-002")
	# The step id travels with the plan: an absent capture has to name the step
	# that would have written it, or the ledger says nothing actionable.
	assert_eq(str((plan[3] as Dictionary)["step"]), "A-02")


func test_a_capture_step_with_no_explicit_id_is_still_planned() -> void:
	# `capture` defaults its shot id to the STEP id. A plan that missed that
	# would report a taken shot as unplanned and a planned one as absent.
	var plan: Array = HARNESS._plan_captures([
		{"id": "A-07", "action": "capture", "args": {}},
	])
	assert_eq(plan.size(), 1)
	assert_eq(str((plan[0] as Dictionary)["id"]), "A-07")


# --- GF-B-003 / CD-2: the closing inventory, and git ------------------------

func test_the_closing_inventory_runs_as_code() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _write_inventory("),
		"§M's closing inventory must be code; as a sentence addressed to a human it produced "
		+ "a 'complete' run with no prescribed screenshot in it anywhere")
	assert_true(source.contains("_write_inventory()"), "_write_inventory is never called")
	var start := source.find("func _write_inventory(")
	var body := source.substr(start, source.length() - start)
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("_file_bytes("),
		"CD-2: `exists` must be read off DISK. A manifest row naming a file that is not there "
		+ "is exactly the claim the coverage review found.")
	assert_true(body.contains("var complete :="),
		"`complete` must be a computed field, not a copied claim")
	assert_true(body.contains("INCOMPLETE.md"),
		"an incomplete segment must leave a file whose NAME says so")


func test_the_run_shots_directory_is_not_gitignored() -> void:
	var text := FileAccess.get_file_as_string(GITIGNORE_PATH)
	assert_false(text.contains("\nshots/\n"),
		"CD-2: an unanchored `shots/` in .gitignore matches EVERY shots directory at every "
		+ "depth, including ralph/reports/gate-f-run-*/<segment>/shots/. The harness wrote the "
		+ "PNGs and git silently declined to track them, which is why a full Gate F run landed "
		+ "on the branch with no prescribed screenshot in it. Anchor it: /shots/")
	assert_true(text.contains("\n/shots/\n"),
		"the repository-root survey output should still be ignored, anchored")


# --- GF-B-002 / CD-3: dialogue by predicate ---------------------------------

func test_dialogue_advance_is_a_predicate_not_a_press_count() -> void:
	var source := _harness_source()
	var start := source.find("func _step_advance_dialogue(")
	assert_true(start >= 0, "CD-3: there is no advance_dialogue_until_closed")
	var body := source.substr(start, source.find("\n## Which advanceable panel", start) - start)
	assert_true(body.contains("_line_signature("),
		"the loop must turn on what the PANEL says, not on a counter")
	assert_true(body.contains("_settle_until("),
		"each press must be followed by a wait for the line to change or the panel to close")
	assert_true(body.contains("if not _is_open(owner):\n\t\t\tbreak"),
		"CD-3's over-press half: the loop must stop the moment the panel closes. An extra "
		+ "`interact` lands on the interaction arbiter and re-opens the conversation the "
		+ "previous press ended.")
	assert_true(body.contains("RE-OPENED"),
		"a modal that closes and re-opens must be reported as such, not as a pass")
	assert_true(body.contains("BLOCKER advance_dialogue_until_closed"),
		"advancing nothing must be a loud failure at THIS step: the presses would otherwise "
		+ "go into the world")


func test_the_advance_button_is_read_off_the_panel() -> void:
	# `dialogue_panel.gd` advances on `interact` from `_physics_process`;
	# `starter_picker.gd` polls `menu_confirm`; `name_prompt.gd` is a letter
	# grid and is not advanceable at all. A harness that picked one button for
	# all three walked past Grandpa and then sat in front of the starter picker
	# for a whole budget — which is how this was found in the first place.
	var source := _harness_source()
	var start := source.find("static func _panel_kind(")
	assert_true(start >= 0, "_panel_kind is gone; the button is being guessed again")
	var body := source.substr(start, source.find("\nfunc _is_open(", start) - start)
	for panel in ["dialogue_panel.gd", "starter_picker.gd", "name_prompt.gd"]:
		assert_true(body.contains(panel), "_panel_kind does not recognise %s" % panel)
	var advance := source.substr(source.find("func _step_advance_dialogue("))
	advance = advance.substr(0, advance.find("\n## Which advanceable panel"))
	assert_true(advance.contains("type_name"),
		"the naming prompt must be refused with a pointer at `type_name`; pressing confirm "
		+ "through a letter grid types one letter per press and never finds Done")


# --- GF-B-002 primitive 3: walking to a thing --------------------------------

func test_the_entity_walk_reuses_the_repos_one_navigator() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _step_move_to_entity("),
		"GF-B-002: there is no move_to_entity")
	# Both walks must go through the same loop, and that loop through
	# stick_navigator.gd. A second copy of the navigator is one that stops
	# being fixed.
	assert_true(source.contains("func _walk_loop("), "the shared walk loop is gone")
	var loop := source.substr(source.find("func _walk_loop("))
	loop = loop.substr(0, loop.find("\n\n\n"))
	assert_true(loop.contains("NAVIGATOR.new("),
		"the walk must route through tests/helpers/stick_navigator.gd, the repo's one walker "
		+ "that detours around geometry")
	assert_true(loop.contains("target_fn.call()"),
		"the target must be re-asked every frame, or move_to_entity cannot track a creature "
		+ "that moves")
	var entity := source.substr(source.find("func _step_move_to_entity("))
	entity = entity.substr(0, entity.find("\n## Find one live entity"))
	assert_true(entity.contains("_find_entity("), "move_to_entity does not resolve by identity")
	assert_true(entity.contains("return \"FAIL"),
		"an entity that is not in the world must FAIL naming the search. A coordinate walk "
		+ "cannot tell 'I arrived and nothing was here' from 'I arrived'.")


# --- GF-B-011: every §C.1 event type is emitted somewhere --------------------

## The §C.1 enum, parsed from the protocol rather than listed here.
func _schema_event_types() -> Array[String]:
	var out: Array[String] = []
	for line in FileAccess.get_file_as_string(PROTOCOL_PATH).split("\n"):
		if not line.begins_with("| `type` |"):
			continue
		for chunk in line.split("`"):
			var name := chunk.strip_edges()
			# The enum members are bare lower_snake words between backticks;
			# the row's prose ("str", "enum:", "ENV-OK") is not.
			if name.is_empty() or name != name.to_lower():
				continue
			# The enum members are bare `lower_snake` identifiers. The row also
			# carries table punctuation and prose between backticks, and a
			# parser that kept those reported "|" as an unemitted event type.
			if not name.is_valid_identifier():
				continue
			if name in ["type", "str", "enum"]:
				continue
			if not out.has(name):
				out.append(name)
		break
	return out


func test_every_schema_event_type_is_emitted_by_something() -> void:
	var types := _schema_event_types()
	assert_true(types.size() >= 25,
		"could not parse §C.1's event enum out of GATE_F_MASTER_PROTOCOL.md; got %s" % str(types))
	var source := _harness_source()
	var missing: Array[String] = []
	for name in types:
		# `_emit("<type>"` or an `_event_type_for` case returning it. Both are
		# real emission paths.
		if source.contains("_emit(\"%s\"" % name) or source.contains("return \"%s\"" % name):
			continue
		missing.append(name)
	assert_true(missing.is_empty(),
		("GF-B-011: §C.1 names these event types and nothing in operator_harness.gd ever emits "
		+ "them: %s. An enum with an unemitted member reads exactly like an enum without one — "
		+ "a Phase B reader querying type == 'gather' cannot tell 'the player never gathered' "
		+ "from 'the harness never says that word'.") % str(missing))


func test_the_expensive_detectors_do_not_run_every_frame() -> void:
	# §3 asks whether the instrumentation costs more than about 1 ms/frame. An
	# inventory walk, a landmark list and a per-member condition summary on
	# every physics frame is how an instrument starts measuring itself.
	var source := _harness_source()
	assert_true(source.contains("const SLOW_WATCH_EVERY"),
		"the GF-B-011 detectors must be sub-sampled; three whole state walks at 60 Hz is cost "
		+ "the run would then have to explain")
	var watch := source.substr(source.find("func _watch_slow("))
	watch = watch.substr(0, watch.find("\n## Prime the change detectors"))
	assert_true(watch.contains("inventory_snapshot"), "_watch_slow is not where the inventory walk lives")


func test_the_new_detectors_are_seeded_on_boot() -> void:
	# A boot must not report every item already in the satchel as newly
	# gathered, nor every landmark on a loaded save as newly discovered. The
	# existing detectors have had `_seed_change_detection` since they were
	# written; the new ones have to join it or S02 onward opens with a burst of
	# fabricated events.
	var source := _harness_source()
	var seed := source.substr(source.find("func _seed_change_detection("))
	seed = seed.substr(0, seed.find("\n# --- input-cell snapshots"))
	for field in ["_prev_inventory", "_prev_placed", "_prev_landmarks", "_prev_condition",
			"_prev_satiety", "_prev_dialogue_line"]:
		assert_true(seed.contains(field),
			"_seed_change_detection does not prime %s; a boot will emit a fabricated event for it"
				% field)


# --- CD-8: the freeze record must carry the feature flags --------------------

func test_the_run_records_the_config_feature_flags() -> void:
	var source := _harness_source()
	assert_true(source.contains("\"config_flags\": _config_flags()"),
		"CD-8: §1.2 requires the freeze record to name graphics settings and it names none. "
		+ "That is how a full Gate F run happened with the procedural grass field silently off. "
		+ "A run cannot amend a freeze record it did not write, so it must record what the "
		+ "build it is playing actually had on.")
	var flags := source.substr(source.find("func _config_flags("))
	flags = flags.substr(0, flags.find("\n## Walk a parsed config"))
	assert_true(flags.contains("res://data/config"),
		"_config_flags must read data/config/, not a list kept in the harness — a list in the "
		+ "harness is a list that goes stale against the configs it claims to describe")


func test_the_feature_flag_walk_finds_nested_switches() -> void:
	# The grass field's own shape is `{"grass": {"enabled": false}}`. A walk
	# that only looked at the top level of each config would report "no flags
	# in this file" for precisely the flag CD-8 exists about.
	var source := _harness_source()
	assert_true(source.contains("func _collect_flags("), "there is no recursive flag walk")
	var walk := source.substr(source.find("func _collect_flags("))
	walk = walk.substr(0, walk.find("\n\n\n"))
	assert_true(walk.contains("depth + 1"), "_collect_flags does not recurse")
	assert_true(walk.contains("TYPE_BOOL"), "_collect_flags does not keep booleans")


# --- the derail rule ---------------------------------------------------------

func test_a_context_failure_skips_the_rest_rather_than_continuing() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _context_guard("), "there is no context guard")
	var guard := source.substr(source.find("func _context_guard("))
	guard = guard.substr(0, guard.find("\n## Does `have` satisfy"))
	assert_true(guard.contains("_derailed = "),
		"a failed require_context must derail the segment; running the next forty steps anyway "
		+ "collects forty fabrications, each a world control pressed at whatever owns input")
	assert_true(guard.contains("\"skip\":"),
		"steps after a derail must be SKIPPED — absence, labelled — not run and not silently dropped")
	assert_true(guard.contains("action == \"boot\"") and guard.contains("resync"),
		"a segment must be able to resynchronise, or one bad step voids everything after it")
	# The guard runs BEFORE the action. That ordering is the whole point.
	var do_step := source.substr(source.find("func _do_step("))
	do_step = do_step.substr(0, do_step.find("\n\tmatch action:"))
	assert_true(do_step.contains("_context_guard(step)"),
		"the guard must run before the `match action:` that performs the step")


func test_the_verdict_ledger_counts_skips_separately() -> void:
	# A SKIP is not a pass and not a finding. Folding it into either is how a
	# derailed segment reads as executed.
	var source := _harness_source()
	assert_true(source.contains("_verdicts := {\"PASS\": 0, \"FAIL\": 0, \"SKIP\": 0}"),
		"the verdict ledger must count SKIP separately from PASS and FAIL")
	assert_true(source.contains("\"skipped\": int(_verdicts[\"SKIP\"])"),
		"INVENTORY.json must report the skips, or a derailed segment reads as executed")


# --- CD-4: matrix cells probed out of context --------------------------------

func test_a_matrix_cell_out_of_context_is_skipped_and_not_counted() -> void:
	var source := _harness_source()
	var start := source.find("func _step_probe_cell(")
	assert_true(start >= 0, "operator_harness.gd has no _step_probe_cell()")
	var body := source.substr(start, source.find("\nfunc _step_assert(", start) - start)
	assert_true(body.contains("intended_context"),
		"CD-4: a cell must name the context it is ABOUT. 303 of X01's 418 cells (72.5%) were "
		+ "injected in a context other than the one the step names, and the matrix's headline "
		+ "'1085 PASS / 118 FAIL' therefore describes mostly nothing.")
	assert_true(body.contains("SKIPPED (context not reached)"),
		"an out-of-context cell must be SKIPPED — never PASS and never FAIL. Those are different "
		+ "facts and the run conflated them.")
	assert_true(body.contains("\"context_before\": context_before"),
		"context_before must be a first-class field, so counting in-context coverage is one "
		+ "query rather than a regex over `expected`")
	# The distinction from require_context is the point: a 418-cell matrix that
	# derailed at the first drift would be worse evidence, not better.
	assert_false(body.contains("_derailed = "),
		"a probe_cell must NOT derail the segment; it skips the cell and moves on")


func test_a_skipped_step_is_a_verdict_of_its_own() -> void:
	var source := _harness_source()
	var do_step := source.substr(source.find("func _do_step("))
	do_step = do_step.substr(0, do_step.find("\n\n\n"))
	assert_true(do_step.contains("if actual.begins_with(\"SKIPPED\"):"),
		"a step reporting SKIPPED must record verdict SKIP, not PASS")
	assert_true(do_step.contains("verdict = \"SKIP\""), "SKIPPED does not map to the SKIP verdict")


# --- CD-5: reaching a thing, not a coordinate --------------------------------

func test_arrival_at_an_entity_is_a_3d_question() -> void:
	var source := _harness_source()
	var loop := source.substr(source.find("func _walk_loop("))
	loop = loop.substr(0, loop.find("\n\n\n"))
	assert_true(loop.contains("close_3d"),
		"CD-5: move_to compares x/z only. Grandpa's bed is 0.89 m from him in plan view and 3.3 m "
		+ "above him, so S02-15 'arrived' and pressed `interact` 31 times through the floor.")
	assert_true(loop.contains("m of that is vertical"),
		"a walk that cannot close a vertical gap must report the gap, not report an arrival")
	var entity := source.substr(source.find("func _step_move_to_entity("))
	entity = entity.substr(0, entity.find("\n## Find one live entity"))
	assert_true(entity.contains("walk[\"close_3d\"] = bool(args.get(\"close_3d\", true))"),
		"an entity walk must default to a 3D arrival; an entity has a height")


func test_interact_is_never_pressed_without_a_live_prompt() -> void:
	var source := _harness_source()
	var start := source.find("func _step_interact_with(")
	assert_true(start >= 0, "CD-5: there is no interact_with")
	var body := source.substr(start, source.find("\n## Turn the camera.", start) - start)
	assert_true(body.contains("arbiter.call(\"prompt\")"),
		"interact_with must read interaction_arbiter.gd's live prompt — it is the one place "
		+ "`interact` is read outside combat, and `prompt()` is already public")
	assert_true(body.contains("was NOT pressed"),
		"a press with no live prompt must not happen, and must say so. S02-32 pressed `interact` "
		+ "once at a walked-to coordinate where the chapter's first wild fight was meant to "
		+ "stage; S02-34 then measured input_context=world and the segment carried on.")
	assert_true(body.contains("m of that is vertical") or body.contains("m vertical"),
		"the failure must name how far the entity was and how much of it was vertical")
	assert_true(body.contains("winning_provider"),
		"a prompt from the wrong provider is how a step meaning to talk to Grandpa opens a chest")


# --- CD-7: a segment is priced before it is launched -------------------------

func test_a_segment_is_costed_in_frames_before_launch() -> void:
	var source := _harness_source()
	assert_true(source.contains("static func _predict_frames("),
		"CD-7: `wait` is priced in RENDERED frames in capture mode. X07 stopped at step 184 of "
		+ "266 with two {\"seconds\": 90} steps still ahead of it — about 31 more hours.")
	assert_true(source.contains("func _measure_frame_cost("),
		"the cost must be MEASURED on this box, not assumed")
	assert_true(source.contains("\"predicted_segment_cost_s\": snappedf(_predicted_cost_s, 0.1)"),
		"RUN_METADATA.json must carry the prediction and the measurement it came from")
	var pre := source.substr(source.find("func _preflight_capture("))
	pre = pre.substr(0, pre.find("\n## What the freeze record claims"))
	assert_true(pre.contains("segment_cost_ceiling_s"),
		"the pre-flight must refuse a segment predicted over the ceiling")
	assert_true(pre.contains("not a shorter wait") or pre.contains("not "),
		"the refusal should say what the fix is")


func test_the_cost_model_prices_the_expensive_steps() -> void:
	# The three step kinds that dominate a capture-mode segment. A model that
	# missed `wait` would predict X07 as cheap, which is the whole failure.
	var frames: int = HARNESS._predict_frames([
		{"id": "A-01", "action": "wait", "args": {"seconds": 90}},
	])
	assert_eq(frames, 5400, "90 seconds must price as 5400 physics frames")
	var walk: int = HARNESS._predict_frames([
		{"id": "A-02", "action": "move_to", "args": {"at": [0, 0]}},
	])
	assert_eq(walk, 2400, "a move_to with no explicit budget must price at the default walk budget")
	var seq: int = HARNESS._predict_frames([
		{"id": "A-03", "action": "capture_seq", "args": {"hz": 5, "seconds": 2}},
	])
	assert_true(seq >= 10, "a 5 Hz / 2 s sequence is ten frames plus their gaps, not free")


# --- CD-8b: the freeze record and the evidence must agree --------------------

func test_the_freeze_record_is_cross_checked_against_reality() -> void:
	var source := _harness_source()
	assert_true(source.contains("func _freeze_display_claim("),
		"CD-8b: the candidate freeze record said display_server = 'X11 under xvfb-run' and every "
		+ "frame manifest in the run said 'headless: this process has no display server' — 9,231 "
		+ "times. Nothing reconciled them for the length of the run.")
	var pre := source.substr(source.find("func _preflight_capture("))
	pre = pre.substr(0, pre.find("\n## What the freeze record claims"))
	assert_true(pre.contains("contradiction"),
		"the pre-flight must write back what it OBSERVED and fail on a contradiction. A metadata "
		+ "field asserting a capability is not evidence that the capability existed.")


# --- CD-6's second half: the inventory snapshot was all zeros ----------------

func test_the_probe_reads_the_inventory_count_key_the_game_writes() -> void:
	# `autoload/inventory.gd` stores a stack as `{"id": ..., "n": ...}` and every
	# reader in the game uses `n`. The probe read `count`, got the default 0 for
	# every occupied slot, and reported `{"axe": 0, "berries": 0, "orb_basic": 0}`
	# — the right item ids with every quantity zero — on S03's save event, for a
	# save that actually held orb_basic ×15, potion_small ×3, berries ×5,
	# revive ×2. It also silently disabled the gather and craft detectors, which
	# compare two snapshots that were always equal.
	var probe := FileAccess.get_file_as_string("res://scripts/debug/gate_f_probe.gd")
	var start := probe.find("func inventory_snapshot(")
	assert_true(start >= 0, "gate_f_probe.gd has no inventory_snapshot()")
	var body := probe.substr(start, probe.find("\n\n\n", start) - start)
	assert_true(body.contains("stack.get(\"n\""),
		"inventory_snapshot must read the stack's `n`; `count` is not a key inventory.gd writes")
	assert_false(body.contains("stack.get(\"count\""),
		"inventory_snapshot still reads `count`, which is always absent and therefore always 0")
	var inventory := FileAccess.get_file_as_string("res://autoload/inventory.gd")
	assert_true(inventory.contains("{\"id\": id, \"n\": put}"),
		"inventory.gd no longer builds stacks as {id, n}; this test's premise has changed and the "
		+ "probe needs re-checking against it")


func test_a_save_and_a_load_can_carry_a_measured_duration() -> void:
	var source := _harness_source()
	for action in ["_step_await_save", "_step_await_load"]:
		assert_true(source.contains("func %s(" % action),
			"CD-6: no save or load event in the run carried duration_ms, so §18's required "
			+ "save/load timings do not exist. %s is missing." % action)
	assert_true(source.contains("_emit(\"save\", {\"duration_ms\""),
		"await_save must emit a save event carrying the measured duration")
	assert_true(source.contains("_emit(\"load\", {\"duration_ms\""),
		"await_load must emit a load event carrying the measured duration")
	# It must not save anything itself: §7's whole point is that the operator
	# saves the way a player does.
	var body := source.substr(source.find("func _step_await_save("))
	body = body.substr(0, body.find("\n## Wait for a production load"))
	assert_false(body.contains("save_game"),
		"await_save must WATCH for the artefact, never call the serializer — that would prove the "
		+ "serializer works and nothing about whether the Save tab reaches it")


# --- the runner's own gate ---------------------------------------------------

func test_the_runner_refuses_a_capture_segment_in_logic_mode() -> void:
	var runner := FileAccess.get_file_as_string("res://tools/gate_f/run_segment.sh")
	assert_true(runner.contains("segment_plans_captures"),
		"CD-1's regression: a segment JSON containing a capture step must not be launchable by a "
		+ "runner path with no xvfb invocation. Every segment of the f082bdf6 run went through "
		+ "this script without --capture.")
	assert_true(runner.contains("--allow-no-capture"),
		"there must be an explicit, recorded way to run one for its logic anyway")
	assert_true(runner.contains("INVENTORY.json"),
		"the runner should read the harness's inventory verdict out loud; a batch script watching "
		+ "exit codes must not have to open a JSON file to learn a segment produced nothing")


func test_missing_evidence_fails_the_process_but_a_failed_expectation_does_not() -> void:
	var source := _harness_source()
	assert_true(source.contains("quit(1 if (not _harness_errors.is_empty() or _evidence_missing) else 0)"),
		"§1.6: a failed EXPECTATION is the evidence Gate F collects and must not fail the process. "
		+ "A missing ARTEFACT is the absence of evidence and must.")
	assert_true(source.contains("_evidence_missing = absent > 0"),
		"CD-2's regression: fail the segment if any manifest row claims a capture whose file is absent")


# --- the pre-flight's two kinds of refusal are not interchangeable ----------

func test_the_no_capture_acknowledgement_cannot_waive_a_cost_breach() -> void:
	# `--gatef-allow-no-capture` says "I know this invocation cannot take
	# pictures". It does not say "ignore the ceiling", and an earlier cut of
	# `_preflight_capture` ran all four reasons to refuse through one string —
	# so the display-server message overwrote the cost message, and the
	# acknowledgement flag waved through a cost breach. That combination would
	# have reproduced X07's fifteen wasted hours with a flag on it.
	var source := _harness_source()
	var pre := source.substr(source.find("func _preflight_capture("))
	pre = pre.substr(0, pre.find("\n## What the freeze record claims"))
	assert_true(pre.contains("var capture_why :=") and pre.contains("var hard_why :="),
		"the pre-flight must keep 'cannot take pictures' and 'must not start at all' apart")
	# The acknowledgement clears only the capture reason.
	assert_true(pre.contains("if not capture_why.is_empty() and _allow_no_capture:"),
		"--gatef-allow-no-capture must only be able to clear a CAPTURE reason")
	assert_false(pre.contains("if _allow_no_capture:\n\t\t_preflight[\"verdict\"] = \"DEGRADED"),
		"the acknowledgement must not be a blanket override of every refusal")
	var gate := pre.substr(pre.find("if predicted > ceiling:"))
	gate = gate.substr(0, gate.find("\n\tif not _capture_available():"))
	assert_true(gate.contains("hard_why = "),
		"a cost breach must be a hard refusal, not a capture one")


func test_a_degraded_preflight_never_reads_as_a_pass() -> void:
	var source := _harness_source()
	var pre := source.substr(source.find("func _preflight_capture("))
	pre = pre.substr(0, pre.find("\n## What the freeze record claims"))
	assert_true(pre.contains("DEGRADED (--gatef-allow-no-capture)"),
		"an acknowledged capture failure must carry its own verdict word")
	assert_true(pre.contains("if not str(_preflight.get(\"degraded_why\", \"\")).is_empty():"),
		"a degraded pre-flight must return before it can be stamped PASS")
	var inv := source.substr(source.find("func _write_inventory("))
	inv = inv.substr(0, inv.find("\n\n\n"))
	assert_true(inv.contains("degraded_why"),
		"a DEGRADED run can never be complete, however much of it happened to write")


# --- CD-2's real mechanism: evidence git will not carry ----------------------

func test_the_inventory_asks_whether_git_will_carry_the_captures() -> void:
	# CD-2 was never a harness defect. The 2026-08-27 run's X07 took 79 real
	# 1920x1080 PNGs; `.gitignore` held a bare `shots/`, which matches at ANY
	# depth, and git carried none of them. `git add <dir>` skips ignored
	# contents silently — exit 0, no output — so fourteen per-segment evidence
	# commits looked clean while carrying no frames.
	#
	# An inventory that only checks the working tree cannot see that. A file
	# that exists and can never be committed is not evidence: it lives on a
	# container that gets reclaimed.
	var source := _harness_source()
	assert_true(source.contains("func _uncommittable("),
		"the closing inventory must ask whether git will actually take what was written")
	var body := source.substr(source.find("func _uncommittable("))
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("\"check-ignore\""),
		"ask git rather than reimplementing gitignore matching — every subtlety that made CD-2 "
		+ "possible lives in that command, and a second implementation is a second set of answers")
	assert_true(body.contains("_git_check = \"unknown:"),
		"a git that cannot answer must be recorded as UNKNOWN, never as clean. This check exists "
		+ "because a silent success was mistaken for a real one; it must not repeat that shape.")
	# ...and an unanswerable check must not fail every run either. That would be
	# this lane's own mistake in mirror image: making the rig refuse work it can
	# do. Only a real, named ignore counts.
	assert_true(body.contains("return out")
		and not body.contains("return [{\"file\": \"*\""),
		"an unanswerable git check must not be reported as an uncommittable file")
	var inv := source.substr(source.find("func _write_inventory("))
	inv = inv.substr(0, inv.find("\n\n\n"))
	assert_true(inv.contains("and uncommittable.is_empty()"),
		"a segment whose captures git will not carry cannot be complete")
	assert_true(inv.contains("or not uncommittable.is_empty()"),
		"uncommittable evidence must exit non-zero, like any other missing artefact")


func test_the_gitignore_shots_rule_is_the_one_that_was_wrong() -> void:
	# Belt and braces with test_the_run_shots_directory_is_not_gitignored: that
	# one checks the pattern text, this one checks the actual behaviour through
	# git, on the path that matters.
	var probe := "ralph/reports/gate-f-selfcheck/rig-2026-08-27/selfcheck_capture/shots/SC-C-title.png"
	assert_true(FileAccess.file_exists("res://%s" % probe),
		"the committed capture evidence is gone; this test's premise has changed")
	var out: Array = []
	var code := OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"),
		"check-ignore", "-v", probe], out, true)
	# 1 = not ignored, which is what it must be. 0 would mean a rule still
	# swallows the run evidence; 128 means git could not answer here.
	assert_ne(code, 0,
		"a .gitignore rule matches the committed Gate F capture evidence: %s" % str(out))
