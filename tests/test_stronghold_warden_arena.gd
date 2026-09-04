extends "res://tests/test_case.gd"

## W-4 / R-2 (docs/specs/GATE3_ENCOUNTER_CONTRACTS.md sec5.2, sec7.2), the data
## half. `tests/smoke_boss.gd` proves both in a real booted world (the readout
## nodes stand, the prompts are enabled, the geometry is where it says); this
## file checks the CONFIG that drives them without paying for a world boot, so
## a future edit that quietly breaks the numbers fails fast in the 28-minute
## suite rather than only in a smoke run.

const STRONGHOLD_PATH := "res://data/config/stronghold.json"
const CLIMAX_PATH := "res://data/config/stronghold_climax.json"
const TRAINERS_PATH := "res://data/config/bands/band5_stronghold_approach/trainers.json"
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")

const FORBIDDEN_WORDS := ["legendary", "veridian", "stag", "living power", "power source"]


func _load(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## W-4: the arena's own combat ring is 11m (spec: 24x26m room, ring fits with a
## metre to spare). The two brazier baskets this pass adds must stand outside
## it -- and they are added to `gate_source` (no light of their own) rather
## than `braziers`, specifically so this dressing does not spend the Hall's
## own `EXTERIOR_OMNI_BUDGET`.
func test_warden_arena_braziers_stand_outside_the_combat_ring() -> void:
	var config := _load(STRONGHOLD_PATH)
	var chambers: Array = config.get("chambers", [])
	var arena: Dictionary = {}
	for entry: Variant in chambers:
		if str((entry as Dictionary).get("id", "")) == "warden_arena":
			arena = entry as Dictionary
	assert_false(arena.is_empty(), "stronghold.json has no 'warden_arena' chamber")
	var at: Array = arena.get("at", [0.0, 0.0])
	var centre := Vector2(float(at[0]), float(at[1]))

	var gate_source: Array = config.get("hall_occupation", {}).get("gate_source", [])
	var found := 0
	for entry: Variant in gate_source:
		var spec: Dictionary = entry as Dictionary
		var pos: Array = spec.get("at", [])
		if pos.size() < 2:
			continue
		var here := Vector2(float(pos[0]), float(pos[1]))
		if here.distance_to(centre) < 20.0:
			found += 1
			assert_true(here.distance_to(centre) > 11.0,
				"a Warden Arena brazier at %s stands inside the 11m combat ring" % str(here))
	assert_eq(found, 2, "expected 2 brazier baskets near the Warden Arena threshold, found %d" % found)

	# The braziers array itself (real OmniLights, counted against the Hall's
	# light budget) must be unchanged by this pass -- the whole point of
	# putting the new pair in `gate_source` instead.
	var braziers: Array = config.get("hall_occupation", {}).get("braziers", [])
	assert_eq(braziers.size(), 11, "hall_occupation.braziers grew; the arena dressing was meant to cost zero omnis")


## R-2: the mechanism (`_place_readout`) is shared with SG40's reveal; this
## checks the SECOND config entry it now has to be reachable for.
func test_duty_board_config_is_a_standalone_readout() -> void:
	var config := _load(CLIMAX_PATH)
	var board: Dictionary = config.get("duty_board", {})
	assert_false(board.is_empty(), "stronghold_climax.json has no 'duty_board' entry")
	assert_eq(str(board.get("mark", "")), "",
		"the duty board names a stronghold mark; the waystop is not one of them, only 'fallback' should be set")
	assert_eq(board.get("fallback", []).size(), 2, "the duty board has no fallback world coordinate")
	assert_eq(str(board.get("conversation", "")), "stronghold_duty_board")

	var reveal: Dictionary = config.get("reveal", {})
	assert_false(reveal.is_empty(), "the duty board must not have replaced the existing reveal entry")
	assert_eq(str(reveal.get("conversation", "")), "stronghold_reveal")


## The board exists to tell the truth about what is coming: a garrison count
## that does not match the actual gauntlet would undercut the readiness layer
## it is there to give.
func test_duty_board_names_the_real_garrison_numbers() -> void:
	var conversation: Dictionary = RUNNER.table().get("stronghold_duty_board", {})
	assert_false(conversation.is_empty(), "'stronghold_duty_board' is not in the merged dialogue table")
	assert_ne(str(conversation.get("speaker", "")), "", "the duty board has no speaker")
	assert_true(ResourceLoader.exists(str(conversation.get("portrait", ""))),
		"the duty board's portrait is not really on disk")

	var spoken := ""
	for line: Variant in (conversation.get("lines", []) as Array):
		spoken += (str(line) if typeof(line) == TYPE_STRING else str((line as Dictionary).get("text", ""))) + "\n"
	assert_ne(spoken.strip_edges(), "", "the duty board has no lines")

	var trainers := _load(TRAINERS_PATH)
	var by_name := {}
	for entry: Variant in (trainers.get("trainers", []) as Array):
		var t: Dictionary = entry as Dictionary
		by_name[str(t.get("name", ""))] = (t.get("team", []) as Array).size()
	var expected := {"Patrolman Verrick": 2, "Warder Solene": 3, "Keeper Hald": 3, "Warden Aldis": 5}
	for label: String in expected:
		assert_true(by_name.has(label), "trainers.json no longer has '%s'; the board's numbers cannot be checked" % label)
		if by_name.has(label):
			assert_eq(int(by_name[label]), int(expected[label]),
				"'%s' fields %d; the duty board would be lying if it still said %d" % [
					label, int(by_name[label]), int(expected[label])])

	for forbidden: String in FORBIDDEN_WORDS:
		assert_false(spoken.to_lower().contains(forbidden),
			"the duty board says '%s'; §32 puts that reveal in the stronghold's own arena readout, not here" % forbidden)
