extends "res://tests/test_case.gd"

## The opening must not be able to end with a dead solo party and no way back.
##
## CAP-1, from the Gate F capstone's own full run
## (`ralph/reports/gate-f-capstone-1/CAP-1-FINDING.md`): reproduced on four
## fresh new games, two of which ended unrecoverable. The tutorial catch had two
## protections and needed three.
##
## `max_catch_failures` guarantees the catch on the second LANDED throw and
## `catch_orb_floor` guarantees the orbs to keep throwing -- and neither one
## bounds the fight the throws happen inside. `data/config/catching.json` is
## explicit that the creature is undefended while you aim and that the opponent
## does not stop attacking it, so a run of MISSED throws ends with the starter
## fainted. At that beat that is terminal, and this is the part worth pinning
## down because it is spread over four systems that are each individually right:
##
##   * `creature_instance.heal()` refuses a fainted creature outright (D40), so
##     no potion helps;
##   * the creature bed that would rest it is a buildable whose materials need
##     Tam's tools, which are past the road gate, which is past this catch;
##   * `night_rest.gd` -> `game_state.complete_creature_bed_rests()` heals only
##     creatures actually put to bed, so sleeping does not help either;
##   * and `encounter_director.gd::_engageable()` then offers no fight anywhere
##     in the game, so the beat waits forever on a catch that cannot be
##     attempted.
##
## `opening.json`'s `faint_recovery_fraction` is the floor under that, held by
## the director between fights. This covers what a behavioural run cannot pin
## down on its own -- that the config still carries a floor, that it is wired
## behind the opening's own beat so it cannot follow the player out, and that
## the party predicate and un-fainter it is built on still mean what it needs
## them to mean.

const DIRECTOR_PATH := "res://scripts/story/sequence_director.gd"
const ENCOUNTER_PATH := "res://scripts/combat/encounter_director.gd"
const OPENING_CONFIG := "res://data/config/opening.json"

const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s is missing" % path)
	if file == null:
		return ""
	return file.get_as_text()


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	assert_true(start >= 0, "the source has no %s" % signature)
	if start < 0:
		return ""
	var end := source.find("\nfunc ", start + 1)
	return source.substr(start, (end - start) if end > start else -1)


func _encounter() -> Dictionary:
	var file := FileAccess.open(OPENING_CONFIG, FileAccess.READ)
	assert_true(file != null, "data/config/opening.json is missing")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "opening.json does not parse as an object")
	if not (parsed is Dictionary):
		return {}
	return (parsed as Dictionary).get("encounter", {})


# --- the config --------------------------------------------------------------

func test_the_opening_configures_a_floor_under_a_wiped_tutorial_party() -> void:
	var encounter := _encounter()
	assert_true(encounter.has("faint_recovery_fraction"),
		"opening.json's encounter beat has no faint_recovery_fraction; losing the "
		+ "tutorial fight strands the player at rung 4 of 27 with nothing in the "
		+ "chapter able to un-faint their only creature (CAP-1)")
	var fraction := float(encounter.get("faint_recovery_fraction", 0.0))
	assert_true(fraction > 0.0,
		"faint_recovery_fraction is %f; a floor of zero is no floor" % fraction)
	# A fraction, not a multiplier. `creature_instance.revive()` clamps anyway,
	# but a value above 1 here would mean the config disagrees with itself about
	# what the number is.
	assert_true(fraction <= 1.0,
		"faint_recovery_fraction is %f, more than a full heal" % fraction)


# --- what the floor is built on ----------------------------------------------

## `all_fainted()` is the predicate that decides the floor fires at all, and
## until this fix nothing in the whole game called it -- only tests did. A
## regression in it would silently disarm the floor rather than break loudly.
func test_the_wipe_predicate_still_distinguishes_a_wipe_from_a_bad_day() -> void:
	var party: RefCounted = PARTY.new()
	var starter: RefCounted = SPECIES.spawn("ripplet")
	var second: RefCounted = SPECIES.spawn("bramblebun")
	party.call("add", starter)
	party.call("add", second)

	starter.call("take_damage", float(starter.get("max_hp")) * 10.0)
	assert_true(bool(starter.get("fainted")))
	assert_false(bool(party.call("all_fainted")),
		"one creature still standing is not a wipe; the opening must not hand out "
		+ "a free heal in the middle of a fight the player can still walk out of")

	second.call("take_damage", float(second.get("max_hp")) * 10.0)
	assert_true(bool(party.call("all_fainted")))


## The floor un-faints through D40's dedicated `revive()`, which refuses a
## creature that is still standing. That refusal is what lets the floor sweep
## the whole party without a per-member fainted check of its own.
func test_the_configured_fraction_puts_a_fainted_starter_back_on_its_feet() -> void:
	var fraction := float(_encounter().get("faint_recovery_fraction", 0.0))
	var starter: RefCounted = SPECIES.spawn("ripplet")
	var full := float(starter.get("max_hp"))
	starter.call("take_damage", full * 10.0)
	assert_true(bool(starter.get("fainted")))
	assert_almost_eq(float(starter.get("hp")), 0.0)

	starter.call("revive", fraction)

	assert_false(bool(starter.get("fainted")),
		"the opening's own floor left the starter fainted, which is the whole defect")
	assert_almost_eq(float(starter.get("hp")), full * fraction)

	# And it cannot top up a creature it is not about.
	var restored := float(starter.get("hp"))
	starter.call("take_damage", 5.0)
	assert_almost_eq(float(starter.call("revive", fraction)), 0.0,
		0.0001, "revive() acted on a creature that had not fainted")
	assert_almost_eq(float(starter.get("hp")), restored - 5.0)


# --- the wiring --------------------------------------------------------------

func test_the_floor_is_held_every_frame_beside_the_orb_floor() -> void:
	var source := _source(DIRECTOR_PATH)
	assert_true(source.contains("func _hold_the_tutorial_team_floor("),
		"sequence_director.gd has no _hold_the_tutorial_team_floor")
	var process := _function_body(source, "func _process(")
	assert_true(process.contains("_hold_the_tutorial_team_floor()"),
		"the team floor is not held per frame. Reacting to the fight's own 'lost' "
		+ "outcome instead would miss the case the capstone actually chained "
		+ "through: a save made in the stranded state, loaded fresh")


func test_the_floor_cannot_follow_the_player_out_of_the_opening() -> void:
	var body := _function_body(_source(DIRECTOR_PATH), "func _hold_the_tutorial_team_floor(")
	# The opening's encounter beat ends permanently at the first catch. Without
	# this gate the floor would revive a wiped party anywhere in the chapter --
	# the South Bridge, the Warden -- and quietly delete the game's stakes.
	assert_true(body.contains("BEATS.ENCOUNTER"),
		"the team floor does not check the opening's beat; it would follow the "
		+ "player into every fight in the game")
	assert_true(body.contains("faint_recovery_fraction"),
		"the team floor hardcodes its own fraction instead of reading opening.json; "
		+ "CLAUDE.md keeps tunables in data")
	assert_true(body.contains("all_fainted"),
		"the team floor does not check for a wipe, so it would heal a party that "
		+ "still had a creature standing")


func test_the_floor_never_reaches_into_a_running_fight() -> void:
	var body := _function_body(_source(DIRECTOR_PATH), "func _hold_the_tutorial_team_floor(")
	# `combat_manager.gd::_begin_resolve("lost")` decides the outcome on the same
	# frame the faint happens and then plays it out. A creature standing back up
	# inside that window contradicts a result the manager has already committed
	# to -- the same lie `catching.json`'s resolve block refuses to tell.
	assert_true(body.contains("is_fighting"),
		"the team floor does not check that the fight is over; it would un-faint "
		+ "the creature underneath the outcome CombatManager has already decided")
	assert_true(body.contains("trainer_battle_active"),
		"the team floor ignores trainer battles, whose rounds resolve between "
		+ "fights and would see a revived creature mid-battle")


## The recovery has to be visible, or it has not happened as far as the player
## is concerned. `combat_manager.gd::_finish()` hides the deployed body on the
## way out of every fight and only a handoff shows it again.
func test_a_revived_follower_becomes_visible_again_without_a_new_fight() -> void:
	var source := _source(ENCOUNTER_PATH)
	assert_true(source.contains("func _show_a_revived_follower("),
		"encounter_director.gd never re-shows a follower that stopped being "
		+ "fainted, so both the opening's floor and a Revive used from the belt "
		+ "leave an invisible creature walking beside the trainer")
	var process := _function_body(source, "func _process(")
	assert_true(process.contains("_show_a_revived_follower()"),
		"the follower is never re-shown on the frame loop, so the only repair is "
		+ "walking into another fight")
	var body := _function_body(source, "func _show_a_revived_follower(")
	assert_true(body.contains("is_fighting") and body.contains("trainer_battle_active"),
		"the re-show does not stand off the two states that own the body's "
		+ "visibility themselves")
	assert_true(body.contains("resting"),
		"the re-show would bring a resting creature out of its bed")


## D40's own words: "so a new game starts with the tool the new rule requires."
## The 2026-08-28 opening rewrite dropped the gift line while D40 stayed live,
## which is why the capstone's exit save carries orbs and nothing else.
func test_the_opening_still_hands_over_the_revives_d40_requires() -> void:
	var file := FileAccess.open("res://data/dialogue/opening.json", FileAccess.READ)
	assert_true(file != null, "data/dialogue/opening.json is missing")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary)
	if not (parsed is Dictionary):
		return
	var conversations: Dictionary = (parsed as Dictionary).get("conversations", {})
	var effects: Array = []
	for id: String in conversations:
		for raw: Variant in (conversations[id] as Dictionary).get("lines", []) as Array:
			if raw is Dictionary:
				effects.append(str((raw as Dictionary).get("effect", "")))
	var gives_revives := false
	for effect: String in effects:
		if effect.begins_with("give:revive:"):
			gives_revives = true
	assert_true(gives_revives,
		"the opening hands over no Revives. D40 made `revive` the ONLY item that "
		+ "un-faints (potions refuse outright), so without this the player's answer "
		+ "to a fainted creature before the road gate is nothing at all")
