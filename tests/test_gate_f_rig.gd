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
const CONFIG_PATH := "res://tools/gate_f/harness_config.json"


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

## The §C.1 event enum, parsed from `SEGMENT_SCHEMA.md`.
##
## **Not from the protocol, and that is a fix rather than a shortcut.**
## `verify-unit-tests` sparse-checks out `!/ralph/` (ci.yml: the four excluded
## trees are 1.20 GB of the 2.08 GB tip and no job reads any of them), so
## `res://ralph/GATE_F_MASTER_PROTOCOL.md` **does not exist in CI**. An earlier
## cut of this test parsed the enum from there, read an empty file, produced an
## empty list and went red on run 2579 while passing locally.
##
## It went red rather than vacuously green only because it asserts the parse
## found something first. That guard is kept below and is the important half:
## a parser that yields `[]` and then asserts over an empty set passes while
## checking nothing, which is the exact shape of dishonest test this repo has
## already shipped a real bug behind.
##
## `tools/gate_f/SEGMENT_SCHEMA.md` is in every checkout — the sibling tests in
## `test_gate_f_instrumentation.gd` already parse it — so the GF-B-011 rule now
## runs everywhere. `test_the_schema_doc_and_the_protocol_agree_on_the_enum`
## below keeps the two documents from drifting.
func _schema_event_types() -> Array[String]:
	return _event_types_in(FileAccess.get_file_as_string(SCHEMA_PATH), "| Event type |")


## Every `lower_snake` identifier in backticks in the one-column table that
## follows `header`.
func _event_types_in(text: String, header: String) -> Array[String]:
	var out: Array[String] = []
	for line in text.split("\n"):
		if not line.begins_with(header):
			continue
		if header == "| `type` |":
			# §C.1's row is one long cell: `type` | str | enum: `a`, `b`, ... |
			# so every backticked identifier on the line is a member.
			for chunk in line.split("`"):
				var member := chunk.strip_edges()
				if member.is_valid_identifier() and member == member.to_lower() \
						and not member in ["type", "str", "enum"] and not out.has(member):
					out.append(member)
			return out
		continue
	# A one-column table: read down its first cell until the table ends.
	var in_table := false
	for line in text.split("\n"):
		if line.begins_with(header):
			in_table = true
			continue
		if not in_table:
			continue
		if not line.begins_with("|"):
			break
		if line.begins_with("|---"):
			continue
		var name := line.split("|")[1].strip_edges().trim_prefix("`").trim_suffix("`")
		if name.is_valid_identifier() and name == name.to_lower() and not out.has(name):
			out.append(name)
	return out


func test_every_schema_event_type_is_emitted_by_something() -> void:
	var types := _schema_event_types()
	assert_true(types.size() >= 25,
		"could not parse the event-type table out of SEGMENT_SCHEMA.md; got %s. This assertion "
			% str(types)
		+ "exists so an unreadable or reformatted source fails LOUDLY: a parser that yields [] "
		+ "and then asserts over an empty set passes while checking nothing.")
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


func test_the_schema_doc_and_the_protocol_agree_on_the_enum() -> void:
	# The drift guard for the test above. SEGMENT_SCHEMA.md restates §C.1's enum
	# so the rule can be enforced in a checkout that excludes `ralph/`; this
	# checks the restatement is faithful wherever the protocol IS readable.
	#
	# In CI it cannot run, and it says so rather than passing quietly — an
	# unrunnable check reported as a pass is how a restated list starts drifting
	# from the document it claims to restate.
	var protocol := FileAccess.get_file_as_string(PROTOCOL_PATH)
	if protocol.is_empty():
		print("    (skipped: %s is not in this checkout — verify-unit-tests sparse-checks out "
			% PROTOCOL_PATH + "!/ralph/. The enum was checked against SEGMENT_SCHEMA.md only; "
			+ "run this locally or in a full checkout to verify the two agree.)")
		return
	var from_protocol := _event_types_in(protocol, "| `type` |")
	assert_true(from_protocol.size() >= 25,
		"could not parse §C.1's event enum out of %s; got %s" % [PROTOCOL_PATH, str(from_protocol)])
	var from_schema := _schema_event_types()
	for name in from_protocol:
		assert_true(from_schema.has(name),
			"§C.1 names event type '%s' and SEGMENT_SCHEMA.md's table does not. The restated list "
				% name
			+ "has drifted from the protocol, and CI enforces GF-B-011 against the restatement.")
	for name in from_schema:
		assert_true(from_protocol.has(name),
			"SEGMENT_SCHEMA.md's event table names '%s' and §C.1 does not." % name)


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
	assert_true(source.contains("_verdicts := {\"PASS\": 0, \"FAIL\": 0, \"SKIP\": 0, \"DELEGATED\": 0}"),
		"the verdict ledger must count SKIP separately from PASS and FAIL — and, since the "
		+ "2026-08-27 evidence split, DELEGATED separately from all three. A prescribed frame a "
		+ "logic lane handed to its capture lane is neither a success, a finding, nor a question "
		+ "the envelope could not ask.")
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
	# one reads the pattern text, this one asks GIT what the pattern actually
	# does — which is the thing that mattered, since a bare `shots/` reads
	# perfectly innocent and matches at every depth.
	#
	# Asked about a PATH, not a file. An earlier cut asserted on a committed
	# evidence PNG and went red on run 2579 because `verify-unit-tests`
	# sparse-checks out `!/ralph/`, so the file it named is legitimately absent
	# there. `git check-ignore` answers about paths whether or not they exist,
	# so the rule can be checked without coupling this test to any artefact.
	var run_path := "ralph/reports/gate-f-run-20260101T000000Z/S01/shots/GF-01-EXAMPLE.png"
	var out: Array = []
	var code := OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"),
		"check-ignore", "-v", run_path], out, true)
	if code > 1:
		# git could not answer — no work tree, no git on PATH. Recorded, not
		# guessed: this is the same rule the harness applies to its own
		# check-ignore call, and for the same reason. An unanswerable check
		# reported as a pass is how CD-2 survived in the first place.
		print("    (skipped: git check-ignore returned %d — no work tree or no git here. " % code
			+ "The pattern text is still checked by "
			+ "test_the_run_shots_directory_is_not_gitignored.)")
		return
	# 1 = no rule matches, which is what a Gate F run's own captures must get.
	# 0 = something still swallows them, which is CD-2 alive again.
	assert_ne(code, 0,
		("a .gitignore rule matches a Gate F run's own capture path: %s\n%s\n"
		+ "A bare directory pattern matches at ANY depth. That is CD-2: the harness wrote the "
		+ "PNGs — X07 took 79 real 1920x1080 frames — git carried none of them, and "
		+ "`git add <dir>` skipped them silently at exit 0, so fourteen per-segment evidence "
		+ "commits looked clean while carrying no frames.") % [run_path, str(out)])
	# And the rule it was written for must still work, or anchoring it broke the
	# thing it was protecting.
	var survey: Array = []
	var survey_code := OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"),
		"check-ignore", "-v", "shots/survey/example.png"], survey, true)
	assert_eq(survey_code, 0,
		"the repository-root shots/ (tools/survey.sh output) is no longer ignored; anchoring the "
		+ "pattern was supposed to narrow it, not remove it. %s" % str(survey))


# --- a capture that photographs an obstruction is not evidence ---------------

func test_a_degenerate_frame_is_measured_and_failed() -> void:
	# The defects lane reported X07's `hall` and `the_rise` audit cameras end up
	# INSIDE masonry. Checked against the recovered frames that diagnosis does
	# not hold — `hall-gameplay` is a clean exterior at mean luma 72.8 and 2.4%
	# dark, and all six `the_rise` frames share ONE camera position with four of
	# them wide, fully-lit vistas. A camera inside solid geometry is black at
	# every yaw.
	#
	# Two of the six are still useless, so the check is on the IMAGE rather than
	# on a physics query: it catches a buried camera, an occluded near field, a
	# fade caught mid-frame and a black screen alike, without needing to know
	# which.
	var source := _harness_source()
	assert_true(source.contains("static func _frame_stats("),
		"every prescribed capture must carry its own luminance statistics — finding the two bad "
		+ "frames among X07's 79 otherwise means opening them one at a time")
	assert_true(source.contains("func _degenerate_reason("), "there is no degenerate-frame check")
	var cap := source.substr(source.find("func _step_capture("))
	cap = cap.substr(0, cap.find("\nfunc _step_capture_seq"))
	assert_true(cap.contains("row[\"luma\"] = stats"),
		"the statistics must reach the manifest row whatever the verdict")
	assert_true(cap.contains("return \"FAIL capture %s is a degenerate frame."),
		"a frame that photographs an obstruction is not evidence and must FAIL")


func test_the_degenerate_thresholds_separate_night_from_useless() -> void:
	# The calibration, pinned. Mean luminance does NOT separate these: the two
	# darkest frames in X07's set are legitimate NIGHT captures and are darker
	# in the mean than the degenerate pair. What separates them is that a night
	# scene keeps its contrast — sky, moon, silhouette — and an obstruction does
	# not. Both conditions must trip together or a night audit frame is thrown
	# away as broken.
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	assert_true(typeof(cfg) == TYPE_DICTIONARY, "harness_config.json is not a JSON object")
	var dark_gate := float((cfg as Dictionary).get("degenerate_dark_fraction", -1.0))
	var spread_gate := float((cfg as Dictionary).get("degenerate_stddev", -1.0))
	# Measured on X07's own frames, by the same code that applies the gate.
	var night_dark := 0.584
	var night_spread := 41.1
	var bad_dark := 0.755
	var bad_spread := 29.0
	var next_darkest_dark := 0.284
	assert_true(dark_gate > night_dark and dark_gate < bad_dark,
		"degenerate_dark_fraction (%.3f) must sit between the legitimate night frames (%.3f) and "
			% [dark_gate, night_dark]
		+ "the degenerate ones (%.3f)" % bad_dark)
	assert_true(spread_gate > bad_spread and spread_gate < night_spread,
		"degenerate_stddev (%.1f) must sit between the degenerate frames' spread (%.1f) and the "
			% [spread_gate, bad_spread]
		+ "night frames' (%.1f)" % night_spread)
	# And the gate must be an AND, or the night frames fail on darkness alone.
	var source := _harness_source()
	var body := source.substr(source.find("func _degenerate_reason("))
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("or spread >= float(_cfg[\"degenerate_stddev\"])"),
		"both conditions must hold for a frame to be called degenerate; darkness alone would "
		+ "throw away every legitimate night capture (the next-darkest 75 frames sit at %.3f dark)"
			% next_darkest_dark)

# --- run-2 BLOCKER, finding 1: two clocks that were both wall clock ----------

func test_route_and_the_recorder_are_driven_by_play_time_not_wall_time() -> void:
	# §D takes elapsed time, `since_interaction_s` and every dead-travel
	# interval out of route.csv *precisely because* "harness wall time lies" —
	# and until 2026-08-28 route.csv's `t` and its 2 Hz cadence WERE harness
	# wall time, as was §H's "PNG every 2 s". On a box where one rendered frame
	# costs 6.465 s that inflates every duration by ~388x, and fires the 0.5 Hz
	# recorder on every rendered frame: S01 planned ~90 frames and was on course
	# for ~5,400, about 10 GB, into 23 GB free.
	var source := _harness_source()
	assert_true(source.contains("func _play_t() -> float:"),
		"there must be a play clock distinct from the wall clock")
	assert_true(source.contains("Engine.get_physics_frames() - _t0_frames"),
		"play time is the elapsed time the GAME believes in, counted in physics steps — not an "
		+ "accumulator, which would miss the steps a slow rendered frame packs in")
	var trace := source.substr(source.find("func _write_trace_row("))
	trace = trace.substr(0, trace.find("\n\n\n"))
	assert_true(trace.contains("_play_t()") and not trace.contains("_wall_t()"),
		"route.csv's `t` must be play time; §D's whole point is that it is not wall time")
	var tick := source.substr(source.find("func _tick(delta: float) -> void:"))
	tick = tick.substr(0, tick.find("\n\n\n"))
	assert_true(tick.contains("if _play_t() >= _next_trace_t:"),
		"the 2 Hz trace cadence must be 2 Hz of PLAY")
	var rec := source.substr(source.find("func _recorder_tick() -> void:"))
	rec = rec.substr(0, rec.find("\n\n\n"))
	assert_true(rec.contains("_play_t() >= _record_next_t"),
		"§H's 'PNG every 2 s' must be 2 s of PLAY, or a slow box records every frame it draws")
	assert_false(rec.contains("_wall_t()"),
		"nothing in the recorder cadence may read wall time")


func test_the_run_records_which_clock_each_consumer_reads() -> void:
	# The instrument said neither, and a reader had to infer it from source —
	# which is how it went unnoticed through every run since the harness was
	# written.
	var source := _harness_source()
	assert_true(source.contains("\"clocks\": {"),
		"RUN_METADATA.json must say which clock each consumer reads")
	assert_true(source.contains("\"route_csv_t\": \"play"),
		"and it must name route.csv's `t` specifically, since that is the one §D reads")
	assert_true(source.contains("\"cost_gate_and_disk_gate\": \"wall"),
		"the gates about the BOX must stay on wall time; they are not questions about the game")


# --- run-2 BLOCKER, finding 2: the cost gate priced the wrong scene ----------

func test_the_cost_gate_reprices_after_every_boot_not_only_the_first() -> void:
	# For every journey segment the FIRST boot is the title screen. Measured on
	# one box, one segment, one day: 0.0065 s/frame on the empty tree, 0.0465
	# re-priced on the title (what the gate used — 505 s predicted for S01), and
	# 6.465 in the Meadows (70,197 s). 139x under-price. Every capture-bearing
	# segment should have blocked; two did.
	var source := _harness_source()
	assert_false(source.contains("_reprice_done"),
		"the re-price must not be a one-shot: the scene the segment spends its hours in is the one "
		+ "that comes up SECOND")
	assert_true(source.contains("await _reprice(\"boot:%s\" % which, ms)"),
		"every boot must re-price, and the price must be named for the scene it was taken in")
	assert_true(source.contains("static func _predict_frames_from("),
		"a re-price must cost the frames that are LEFT; re-charging for a boot already paid for "
		+ "would refuse work that is genuinely affordable")
	assert_true(source.contains("func _cost_recheck() -> void:"),
		"and it must re-check as the price changes, not only when a scene changes")


func test_a_wait_stops_when_the_cost_gate_trips_mid_step() -> void:
	# S01-09 asks for 10,800 physics frames — 19.4 hours at the measured price.
	# A gate that could only act at the next STEP boundary would watch all of it
	# go past.
	var source := _harness_source()
	var body := source.substr(source.find("func _step_wait(args: Dictionary) -> String:"))
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("if not _blocked.is_empty():"),
		"`wait` is where the protocol's hours live and must honour a mid-step abort")
	assert_true(body.contains("FAIL waited %d of %d physics frames"),
		"and it must say how far it got, not report a completed wait")


func test_the_frame_cost_probe_cannot_become_the_cost_it_measures() -> void:
	var source := _harness_source()
	var body := source.substr(source.find("func _measure_frame_cost() -> float:"))
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("cost_probe_budget_s"),
		"20 frames is 0.12 s at 6 ms and over two minutes at 6.465 s — EVERY time a scene comes up")
	assert_true(body.contains("cost_probe_min_frames"),
		"and it must still take enough samples to mean something")


# --- run-2 BLOCKER, finding 3: disk was a ceiling nobody had priced ----------

func test_the_preflight_prices_disk_as_well_as_time() -> void:
	# At §H's planned cadences the eighteen segments were ~25 GB before the
	# frame-cost multiplier, into a container with 23 GB free, doubled again by
	# the copy `.git` has to carry.
	var source := _harness_source()
	assert_true(source.contains("func _price_disk("),
		"a segment that cannot fit its evidence must refuse, exactly as one that cannot afford "
		+ "its time does")
	var body := source.substr(source.find("func _price_disk("))
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("_preflight.get(\"png_bytes\"")
		and body.contains("_evidence_png_bytes"),
		"bytes per PNG must be MEASURED, and the pre-flight self-test is only the FLOOR: it "
		+ "photographs an empty tree. On S01C it was 10,596 bytes against a real title frame of "
		+ "65,297 — a 6x under-estimate, which is the same mistake as pricing a segment's time "
		+ "against the cheapest possible scene. Once a real evidence frame exists, use it.")
	assert_true(body.contains("_inside_work_tree()"),
		"evidence has to be committable to survive the container, so the .git copy is part of the "
		+ "bill — but only where the run directory actually is inside a work tree")
	assert_true(body.contains("if not _capture_available()"),
		"a process that cannot render writes no frames; disk must never be a reason to refuse a "
		+ "logic lane")
	var free := source.substr(source.find("func _free_bytes("))
	free = free.substr(0, free.find("\n\n\n"))
	assert_true(free.contains("return 0.0"),
		"a df that cannot answer must read as NOT GATED, never as no room. A disk check that "
		+ "refused every run it could not measure would be this lane's own mistake in mirror image.")


func test_a_disk_breach_is_a_hard_refusal_the_acknowledgement_cannot_waive() -> void:
	var source := _harness_source()
	var pre := source.substr(source.find("func _preflight_capture("))
	pre = pre.substr(0, pre.find("\n## What the freeze record claims"))
	var disk := pre.substr(pre.find("\tif plans_evidence:\n\t\tvar disk := _price_disk(frames)"))
	disk = disk.substr(0, disk.find("\n\n"))
	assert_true(disk.contains("hard_why = disk_why"),
		"disk has nothing to do with whether this invocation can take pictures, so "
		+ "--gatef-allow-no-capture must not be able to waive it")


# --- the §H/§G evidence split (owner decision, 2026-08-27) -------------------

func test_a_logic_lane_hands_its_captures_over_rather_than_failing_them() -> void:
	# Round 1 made an untakeable capture a FAIL, which was right when the
	# alternative was 9,231 false PASSes. With the lanes split the question moves
	# one level up: a segment is judged against what ITS LANE owes, and the debt
	# is checked over the whole run directory. Debt transferred and recorded —
	# never debt erased.
	var source := _harness_source()
	assert_true(source.contains("if _evidence_lane == \"logic\" and (action == \"capture\" or action == \"capture_seq\"):"),
		"a logic lane must not execute a prescribed capture")
	assert_true(source.contains("_verdicts[\"DELEGATED\"]"),
		"and the verdict must be its own word: a delegation is neither a pass, a finding, nor a "
		+ "question the envelope could not ask")
	assert_true(source.contains("_write_text(_out_dir.path_join(\"DELEGATED.md\")"),
		"a reader scanning the run directory must see the debt without opening anything, the same "
		+ "way INCOMPLETE.md works")


func test_an_unbacked_delegation_is_a_blocker_at_step_one() -> void:
	# The failure this guards is CD-1's shape one level up: a debt discharged by
	# not mentioning it.
	var source := _harness_source()
	assert_true(source.contains("func _check_evidence_lane("),
		"the handover has to be REAL before a step runs")
	var body := source.substr(source.find("func _check_evidence_lane("))
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("does not exist or does not parse"),
		"a handover to a file that is not there is a debt that has quietly stopped existing")
	assert_true(body.contains("Only a\" + \"\n\t\t\t\t+ \" capture lane can accept a capture debt.")
		or body.contains("capture lane can accept a capture debt"),
		"only a capture lane may accept a capture debt")
	assert_true(body.contains("does not accept: %s")
		or body.contains("\\\"owes\\\" list does not "),
		"an unaccepted delegation is how a segment would become capture-incomplete forever without "
		+ "anything ever saying so")
	assert_true(body.contains("no capture step in this segment"),
		"and a capture lane that claims an id it never shoots is CD-1 wearing a different hat")


func test_the_lane_check_runs_before_the_cost_probe() -> void:
	# A typo in a delegation should not cost a frame-cost measurement, which on
	# the Gate F container is tens of seconds.
	var source := _harness_source()
	var pre := source.substr(source.find("func _preflight_capture("))
	pre = pre.substr(0, pre.find("\n## What the freeze record claims"))
	assert_true(pre.find("var lane_why := _check_evidence_lane(steps)")
		< pre.find("var frame_cost := await _measure_frame_cost()"),
		"the cheap check goes first")


func test_the_freeze_record_may_describe_lanes_and_still_binds_without_them() -> void:
	# CD-8b must keep working. A run that is headless for its logic lane and X11
	# for its capture lane cannot be described by one flat display_server — but a
	# record with NO lanes block must still bind every segment by its flat claim,
	# so a run that wants a logic lane has to say so in the freeze record BEFORE
	# the run. Amending a freeze record mid-run to get a segment to start is the
	# sin CD-8b exists to prevent, and the run-2 operator proved the refusal works
	# by running into it and NOT editing the record.
	var source := _harness_source()
	var body := source.substr(source.find("func _freeze_display_claim("))
	body = body.substr(0, body.find("\n\n\n"))
	assert_true(body.contains("record.get(\"lanes\", {})"),
		"the freeze record may carry a per-lane display-server claim")
	assert_true(body.contains("(all lanes; the record declares none)"),
		"and a record with no lanes block must still bind every segment by its flat claim")
	var pre := source.substr(source.find("func _preflight_capture("))
	pre = pre.substr(0, pre.find("\n## What the freeze record claims"))
	assert_true(pre.contains("contradiction") and pre.contains("hard_why = claimed"),
		"the contradiction is still a HARD refusal, not one the acknowledgement flag can waive")


func test_the_worked_split_pair_declares_both_halves() -> void:
	var logic := JSON.parse_string(FileAccess.get_file_as_string(
		"res://tools/gate_f/segments/S01.json")) as Dictionary
	var capture := JSON.parse_string(FileAccess.get_file_as_string(
		"res://tools/gate_f/segments/S01C.json")) as Dictionary
	assert_eq(str(logic.get("evidence_lane", "")), "logic")
	assert_eq(str(logic.get("capture_lane", "")), "S01C")
	assert_eq(float(logic.get("record_hz", -1.0)), 0.0,
		"a logic lane keeps no continuous record; that is the thing the split removes")
	assert_eq(str(capture.get("evidence_lane", "")), "capture")
	assert_true((capture.get("owes", []) as Array).has("GF-01-TITLE-01"),
		"the capture lane must accept the id the logic lane hands it")
	var takes := false
	for raw: Variant in (capture.get("steps", []) as Array):
		var step: Dictionary = raw
		if str(step.get("action", "")) == "capture" \
				and str((step.get("args", {}) as Dictionary).get("id", "")) == "GF-01-TITLE-01":
			takes = true
	assert_true(takes, "and it must actually shoot it")


func test_the_run_level_inventory_checks_the_debt_was_paid() -> void:
	var ledger := FileAccess.get_file_as_string("res://tools/gate_f/run_inventory.py")
	assert_false(ledger.is_empty(), "the run-level ledger must exist")
	assert_true(ledger.contains("unpaid_delegations"),
		"a delegation nobody paid is a run-level deficiency even where every segment is complete")
	assert_true(ledger.contains("check-ignore"),
		"and it must ask git the same question the per-segment inventory does — evidence git will "
		+ "not carry dies with the container")
	assert_true(ledger.contains("os.path.getsize"),
		"present must mean present ON DISK, not present in a manifest row")
