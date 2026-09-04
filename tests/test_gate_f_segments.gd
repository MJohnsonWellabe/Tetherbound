extends TestCase

## The Gate 3 step-scripts, checked against the one rule a run cannot check for
## itself: **no fight in a Gate 3 segment may be driven by a press count.**
##
##   godot --headless --path . --script tests/run_tests.gd -- --only=gate_f_segments
##
## ## Why this file exists
##
## `tools/gate_f/SEGMENT_SCHEMA.md` names the failure mode in its own words:
## "a fight's length is a function of both levels, the type chart and a +/-10%
## roll on every hit, so a counted run of `combat_quick` presses is right for
## exactly one matchup". It then measured what that costs -- a water pilot
## spending every press budgeted for THREE creatures on the first one, the
## handover presses landing mid-round and being refused by the commitment
## guard, and the fight lost to a single faint with three untouched creatures
## on the belt. **Every one of those steps reported PASS**, because a `press`
## step only ever asserts that input was injected.
##
## That is why this is a unit test and not a run verdict. The defect is
## invisible to the run: `press combat_quick, times: 34` passes whether it won
## the fight, lost the fight, or emptied itself into a party wipe. Closure-plan
## row CL-H1 found the same shape in all four Gate 3 segments at once (S06's
## Dorn, S07's Hess, S08's wild meadowhart, S09's Corr), so the guard belongs
## in the suite where a re-introduction is caught before a four-hour run pays
## for it.
##
## Deliberately scoped to the GATE 3 segments named below rather than to every
## file in the directory. S02-S05 and X03/X04/X06/X07 still carry counted
## combat blocks; they are Gate 2 / matrix segments owned elsewhere, and a test
## that failed on files this lane cannot fix would be a test nobody can keep
## green. Adding a segment to `GATE3_SEGMENTS` is how the rule is extended.

const SEGMENTS_DIR := "res://tools/gate_f/segments"

## The Gate 3 journey segments and their capture twins. CL-H1's own list.
const GATE3_SEGMENTS: Array[String] = [
	"S06", "S06C", "S07", "S07C", "S08", "S08C", "S09", "S09C",
]

## The predicate-driven fight actions. `fight_until_resolved` drives a fight to
## its end; `chip_to_floor` drives one deliberately NOT to its end, reading the
## target's live HP so a catch still has something to throw an orb at. Both read
## real game state between presses, which is exactly what a `times:` count
## cannot do.
const PREDICATE_COMBAT_ACTIONS: Array[String] = [
	"fight_until_resolved", "chip_to_floor",
]


func _segment(id: String) -> Dictionary:
	var path := "%s/%s.json" % [SEGMENTS_DIR, id]
	assert_true(FileAccess.file_exists(path), "%s: the Gate 3 segment list names a file that is not there" % path)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(typeof(parsed) == TYPE_DICTIONARY, "%s is not a JSON object" % path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _steps(id: String) -> Array:
	return _segment(id).get("steps", []) as Array


## CL-H1. The rule itself.
##
## A `press` step naming `combat_quick` is a blind fight step whether or not it
## carries `times:` -- one blind swing asserts no more about the fight than
## thirty-four do -- so the check is on the control, not on the count.
func test_no_gate3_segment_fights_with_a_combat_quick_press_block() -> void:
	for id in GATE3_SEGMENTS:
		for raw: Variant in _steps(id):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var step := raw as Dictionary
			if str(step.get("action", "")) != "press":
				continue
			var args: Dictionary = step.get("args", {}) as Dictionary
			var control := str(args.get("control", ""))
			if control != "combat_quick":
				continue
			var times := maxi(1, int(args.get("times", 1)))
			assert_true(false, ("%s step %s drives a fight with `press combat_quick, times: %d`. "
				+ "SEGMENT_SCHEMA.md names this failure mode: a press step asserts only that input was "
				+ "injected, so a counted block reports PASS whether it won, lost, or wiped the party. "
				+ "Use `fight_until_resolved` for a fight that must end, or `chip_to_floor` for a catch "
				+ "chip that must not.") % [id, str(step.get("id", "?")), times])


## The other half of the same rule, and the reason it is a separate test: a
## segment that answered the check above by DELETING its fights would pass it.
## Every Gate 3 segment that engages anything must still drive that engagement
## by predicate.
func test_every_gate3_segment_drives_its_combat_by_predicate() -> void:
	for id in GATE3_SEGMENTS:
		var engages := 0
		var predicates := 0
		for raw: Variant in _steps(id):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var step := raw as Dictionary
			var action := str(step.get("action", ""))
			if PREDICATE_COMBAT_ACTIONS.has(action):
				predicates += 1
			var args: Dictionary = step.get("args", {}) as Dictionary
			if action == "assert" and str(args.get("check", "")) == "combat_running":
				engages += 1
		assert_true(engages == 0 or predicates > 0, ("%s asserts `combat_running` %d time(s) and then "
			+ "drives no fight by predicate: it holds %d `fight_until_resolved`/`chip_to_floor` steps. "
			+ "A segment that starts a fight has to have something that finishes it.")
			% [id, engages, predicates])


## CL-H1's second ask: a party-health gate before each challenge.
##
## `active_creature_alive` is the check `encounter_director.gd::can_challenge()`
## silently refuses on. Without it, a scripted challenge against a fainted lead
## opens the `trainer_no_usable_creature` conversation instead of a fight, and
## every step downstream measures the wrong thing while reporting PASS -- 2.11
## found exactly that on S08.
func test_every_gate3_fight_is_preceded_by_a_party_health_gate() -> void:
	for id in GATE3_SEGMENTS:
		var steps := _steps(id)
		for i in steps.size():
			if typeof(steps[i]) != TYPE_DICTIONARY:
				continue
			var step := steps[i] as Dictionary
			if not PREDICATE_COMBAT_ACTIONS.has(str(step.get("action", ""))):
				continue
			var gated := false
			var back := i - 1
			while back >= 0 and not gated:
				if typeof(steps[back]) == TYPE_DICTIONARY:
					var earlier := steps[back] as Dictionary
					var args: Dictionary = earlier.get("args", {}) as Dictionary
					if str(earlier.get("action", "")) == "assert" \
							and str(args.get("check", "")) == "active_creature_alive":
						gated = true
					# Only the run-up to THIS fight counts: a gate before the
					# previous fight says nothing about the party's state after
					# that fight resolved.
					if PREDICATE_COMBAT_ACTIONS.has(str(earlier.get("action", ""))):
						break
				back -= 1
			assert_true(gated, ("%s step %s starts a fight with no `active_creature_alive` assert between it "
				+ "and the previous fight. CL-H1: a challenge thrown at a fainted lead is refused silently, "
				+ "and every step after it measures a world that is not fighting.")
				% [id, str(step.get("id", "?"))])


## CL-H2. A `battle:`-effect conversation advanced by a fixed press count is
## the same defect one layer up: too few presses leave `input_context` on
## `narrative_modal` where the next step expects combat (G3-BAND5 measured
## exactly that at the outer watch), too many re-open the panel. Any press
## block immediately before a fight has to be the predicate advance instead.
func test_no_gate3_fight_is_reached_through_a_counted_dialogue_block() -> void:
	for id in GATE3_SEGMENTS:
		var steps := _steps(id)
		for i in steps.size():
			if typeof(steps[i]) != TYPE_DICTIONARY:
				continue
			var step := steps[i] as Dictionary
			if not PREDICATE_COMBAT_ACTIONS.has(str(step.get("action", ""))):
				continue
			# Walk back over the staging steps (waits, captures, asserts, the
			# opening charged/recentre press) to the engage that started this
			# fight, and fail on a counted `interact` block on the way.
			var back := i - 1
			while back >= 0:
				if typeof(steps[back]) != TYPE_DICTIONARY:
					back -= 1
					continue
				var earlier := steps[back] as Dictionary
				var action := str(earlier.get("action", ""))
				if PREDICATE_COMBAT_ACTIONS.has(action) or action == "move_to" or action == "move_to_entity":
					break
				var args: Dictionary = earlier.get("args", {}) as Dictionary
				if action == "press" and str(args.get("control", "")) == "interact" \
						and int(args.get("times", 1)) > 1:
					assert_true(false, ("%s step %s advances the conversation into %s's fight with "
						+ "`times: %d`. CL-H2: use `advance_dialogue_until_closed`, which reads the panel's "
						+ "own line and stops when it closes.")
						% [id, str(earlier.get("id", "?")), str(step.get("id", "?")),
							int(args.get("times", 1))])
					break
				back -= 1


## CL-H1's third ask, and the one a press count can hide completely: the
## recovery has to name the item, not a cell. `focus_move`-by-offset was
## measured landing on the wrong item three times in one run (GAME-9/RIG-24)
## once acquisitions and spends had shifted the grid.
func test_gate3_revives_are_addressed_by_item_identity() -> void:
	for id in GATE3_SEGMENTS:
		var reviving := false
		for raw: Variant in _steps(id):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var step := raw as Dictionary
			var args: Dictionary = step.get("args", {}) as Dictionary
			if str(step.get("action", "")) == "focus_item" and str(args.get("item", "")) == "revive":
				reviving = true
			if str(step.get("action", "")) == "focus_move":
				# A satchel cursor move by direction is only safe where nothing
				# is being addressed by identity around it.
				assert_false(reviving and str(args.get("direction", "")) in ["left", "right"],
					"%s step %s moves the satchel cursor by direction inside a revive sequence; address the item by identity"
						% [id, str(step.get("id", "?"))])
		assert_true(reviving, ("%s has no `focus_item {item: \"revive\"}` step. CL-H1 asks every Gate 3 "
			+ "segment for a post-faint recovery addressed BY ITEM IDENTITY; a segment with none cannot "
			+ "recover a fainted belt at all, which is how G3-BAND2 walked a party at (0,0,0,0) HP for 450 s "
			+ "into a dungeon and lost its whole satchel.") % id)


## CL-H7. `map_landmarks.json` puts `the_long_water` at (-150,4200) with a 52 m
## radius. S07 asserted that region at (150,3500) -- 728 m out, on the
## corridor's approach to the river -- and the assert could never pass. The
## coverage was not deleted: it moved to the Old Mill Crossing, which really is
## inside the circle. This pins BOTH halves, because a "fix" that just removed
## the assert would otherwise look identical.
func test_the_long_water_is_only_asserted_from_inside_the_long_water() -> void:
	var landmarks: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/map_landmarks.json"))
	assert_true(typeof(landmarks) == TYPE_DICTIONARY, "map_landmarks.json is not a JSON object")
	if typeof(landmarks) != TYPE_DICTIONARY:
		return
	var centre := Vector2.ZERO
	var radius := 0.0
	for raw: Variant in ((landmarks as Dictionary).get("regions", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var region := raw as Dictionary
		if str(region.get("id", "")) != "the_long_water":
			continue
		var at: Array = region.get("centre", []) as Array
		centre = Vector2(float(at[0]), float(at[1]))
		radius = float(region.get("radius", 0.0))
	assert_true(radius > 0.0, "map_landmarks.json has no `the_long_water` region with a radius")

	for id in ["S07", "S07C"]:
		var steps := _steps(id)
		var walked := Vector2(NAN, NAN)
		var asserted := false
		for raw: Variant in steps:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var step := raw as Dictionary
			var args: Dictionary = step.get("args", {}) as Dictionary
			if str(step.get("action", "")) == "move_to":
				var at: Array = args.get("at", []) as Array
				if at.size() >= 2:
					walked = Vector2(float(at[0]), float(at[1]))
			if str(step.get("action", "")) != "assert":
				continue
			if str(args.get("check", "")) != "region_is" or str(args.get("equals", "")) != "the_long_water":
				continue
			asserted = true
			assert_false(is_nan(walked.x),
				"%s step %s asserts `the_long_water` before any walk has placed the player"
					% [id, str(step.get("id", "?"))])
			var gap := walked.distance_to(centre)
			assert_true(gap <= radius, ("%s step %s asserts region `the_long_water` at (%.1f,%.1f), which is "
				+ "%.0f m from the region's own centre (%.1f,%.1f) and its %.0f m radius. CL-H7: the assert "
				+ "has to stand where the region is.")
				% [id, str(step.get("id", "?")), walked.x, walked.y, gap, centre.x, centre.y, radius])
		if id == "S07":
			assert_true(asserted, ("S07 asserts `the_long_water` nowhere. CL-H7 moved the assert to the Old "
				+ "Mill Crossing rather than deleting it -- band 3's whole subject is the river as a regional "
				+ "barrier, and a chapter that never checks the player entered it has no evidence of that."))
