extends "res://tests/test_case.gd"

## TOURNAMENT-1. The village tournament, owner-locked on 2026-08-22.
##
## Everything the tournament is made of is data spread across five files --
## a bracket in `data/config/tournament.json`, three fights in the band's
## `trainers.json`, seven conversations in the band's dialogue file, a seven-
## branch `greeting_when` ladder in `village_npcs.json`, and a recipe flag in
## `recipes_rootstone.json`. Every way that can be wrong is silent at run time:
## a branch in the wrong order means the marshal offers the final before the
## first bout; a `battle:` naming a trainer that does not exist opens a
## dialogue box and starts nothing; a simulated result revealed by a flag
## nothing sets is a bracket that never fills in.
##
## Per docs/decisions/D02 this file is pure logic only. Standing the board on
## Terrain3D is not tested here; the board's CONTENT is, because the content is
## the part the owner directive is actually about ("the board must be visible
## to the player so the bracket reads as real").

const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const SPECIES_CONFIG := "res://data/creatures/species.json"
const VILLAGE_NPCS_PATH := "res://data/config/village_npcs.json"

var progression: RefCounted = null
var party: RefCounted = null


func before_each() -> void:
	progression = PROGRESSION_STATE.new()
	party = PARTY.new()


## A real party of `count` creatures, every one at `level`. Real
## `creature_instance`s through the same `set_level()` a starter goes through,
## so the level the entry rule reads is the level the game would have written.
func _fill_party(count: int, level: int) -> void:
	for i in count:
		var creature: RefCounted = SPECIES.spawn("bramblebun")
		creature.set_level(level, PROGRESSION.config())
		party.add(creature)


func _marshal() -> Dictionary:
	var file := FileAccess.open(VILLAGE_NPCS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == TOURNAMENT.marshal_name():
			return entry as Dictionary
	return {}


## --- the shape the owner locked -----------------------------------------------

## "Eight-slot bracket, three fought rounds." Both halves, because the whole
## point of the directive is the ratio: eight names, three fights.
func test_the_bracket_has_eight_slots_and_three_fought_rounds() -> void:
	assert_eq(TOURNAMENT.bracket().size(), 8,
		"the owner locked an eight-slot bracket; tournament.json draws %d" % TOURNAMENT.bracket().size())
	assert_eq(TOURNAMENT.rounds().size(), 3,
		"the owner locked three fought rounds; tournament.json lists %d" % TOURNAMENT.rounds().size())


## "The other four slots are named opponents whose results are simulated on the
## bracket board." Four, not three and not five: the player plus three fought
## opponents accounts for the other four slots exactly.
func test_exactly_four_slots_are_never_fought() -> void:
	var fought: Array[String] = ["You"]
	for entry: Variant in TOURNAMENT.rounds():
		fought.append(str((entry as Dictionary).get("opponent", "")))
	var simulated_names: Array[String] = []
	for entry: Variant in TOURNAMENT.bracket():
		var name := str((entry as Dictionary).get("name", ""))
		if not fought.has(name):
			simulated_names.append(name)
	assert_eq(simulated_names.size(), 4,
		"four bracket slots should be named opponents nobody fights; found %s" % str(simulated_names))


## Every bracket slot is a distinct name, and exactly one of them is the
## player. A duplicate would make the board unreadable and a missing player
## slot would make it somebody else's tournament.
func test_every_slot_is_a_distinct_name_and_one_of_them_is_you() -> void:
	var seen: Array[String] = []
	var players := 0
	for entry: Variant in TOURNAMENT.bracket():
		var slot := entry as Dictionary
		var name := str(slot.get("name", ""))
		assert_ne(name, "", "a bracket slot has no name")
		assert_false(seen.has(name), "two bracket slots are both called '%s'" % name)
		seen.append(name)
		if bool(slot.get("player", false)):
			players += 1
	assert_eq(players, 1, "the bracket should hold exactly one player slot; it holds %d" % players)


## "Use only Band 1's existing trainers." Every fought round's opponent has to
## be somebody already in the trainer table under their own name, and the round
## itself has to be a real table entry -- a `battle:` effect naming a trainer
## that does not exist opens a box and starts nothing.
func test_every_fought_round_is_a_real_trainer_and_an_existing_band_one_name() -> void:
	var band_one_names: Array[String] = []
	for entry: Variant in TRAINERS.trainers():
		band_one_names.append(str((entry as Dictionary).get("name", "")))
	for entry: Variant in TOURNAMENT.rounds():
		var spec := entry as Dictionary
		var trainer_id := str(spec.get("trainer", ""))
		assert_false(TRAINERS.trainer(trainer_id).is_empty(),
			"round '%s' names trainer '%s', which trainers.json does not define"
				% [str(spec.get("id", "")), trainer_id])
		var opponent := str(spec.get("opponent", ""))
		assert_true(band_one_names.has(opponent),
			"round '%s' is fought against '%s', who is not in the trainer table at all"
				% [str(spec.get("id", "")), opponent])
		assert_eq(str(TRAINERS.trainer(trainer_id).get("name", "")), opponent,
			"round '%s' names opponent '%s' but its trainer entry is somebody else" % [str(spec.get("id", "")), opponent])


## No round stands up a body of its own. `trainer_npc.gd::build()` places every
## row whose `placed_by` matches the group it was called with, and the world
## calls it with "" -- so a tournament round that forgot `placed_by` would put
## a second Mira in the north field forever.
func test_no_tournament_round_stands_up_a_second_body() -> void:
	for entry: Variant in TOURNAMENT.rounds():
		var trainer_id := str((entry as Dictionary).get("trainer", ""))
		assert_eq(str(TRAINERS.trainer(trainer_id).get("placed_by", "")), "tournament",
			"'%s' does not name a placer; trainer_npc.gd would stand up a duplicate body for it" % trainer_id)


## TOURNAMENT-FLOW-0903. Every round needs its own `at_ring_flag` and
## `begin_conversation` so the ceremony (ring-entrance banter, then an
## explicit begin-the-round choice) can be built for it, and the three rounds
## must not collide on the same flag or conversation id -- that would let
## entering one round's ring silently arm another's begin line.
func test_every_round_names_a_distinct_at_ring_flag_and_begin_conversation() -> void:
	var flags: Array[String] = []
	var conversations: Array[String] = []
	for entry: Variant in TOURNAMENT.rounds():
		var spec := entry as Dictionary
		var flag := str(spec.get("at_ring_flag", ""))
		var begin := str(spec.get("begin_conversation", ""))
		assert_ne(flag, "", "round '%s' names no at_ring_flag" % str(spec.get("id", "")))
		assert_ne(begin, "", "round '%s' names no begin_conversation" % str(spec.get("id", "")))
		assert_false(flags.has(flag), "two rounds share the at_ring_flag '%s'" % flag)
		assert_false(conversations.has(begin), "two rounds share the begin_conversation '%s'" % begin)
		flags.append(flag)
		conversations.append(begin)


## "The final opponent rides a Meadowhart." And Burrowback stays non-rideable
## -- the owner suggested it and then accepted Meadowhart instead, so a later
## edit quietly moving the mount is a change to a locked decision.
func test_the_final_opponent_fields_the_rideable_meadowhart() -> void:
	var final_id := str(TOURNAMENT.round_spec("final").get("trainer", ""))
	var team: Array = TRAINERS.team_of(TRAINERS.trainer(final_id))
	var species: Array[String] = []
	for member: Variant in team:
		species.append(str((member as Dictionary).get("species", "")))
	assert_true(species.has("meadowhart"),
		"the final opponent should field a Meadowhart; they field %s" % str(species))
	assert_false(SPECIES.rideable("meadowhart").is_empty(),
		"Meadowhart is not rideable in species.json; the tournament's prize points at nothing")
	assert_true(SPECIES.rideable("burrowback").is_empty(),
		"Burrowback grew a rideable block; the owner's own suggestion was overruled and it stays non-rideable")


## And the Meadowhart is sent out LAST. The send-out order is the team's own
## order (`encounter_director._send_out_next_creature()` pops the front), so a
## Meadowhart authored first would be beaten before the final has warmed up.
func test_the_meadowhart_is_the_finals_last_creature() -> void:
	var final_id := str(TOURNAMENT.round_spec("final").get("trainer", ""))
	var team: Array = TRAINERS.team_of(TRAINERS.trainer(final_id))
	assert_false(team.is_empty(), "the final fields nobody")
	if team.is_empty():
		return
	assert_eq(str((team[team.size() - 1] as Dictionary).get("species", "")), "meadowhart",
		"the Meadowhart should be the final's last creature out")


## --- the entry conditions -----------------------------------------------------

## The threshold is DATA. Code reads it; code does not carry a second copy of
## it. Assert the rule tracks the config rather than a hard-coded 3.
func test_the_party_size_threshold_comes_from_the_config() -> void:
	var wanted := int(TOURNAMENT.entry_config().get("min_party_size", 0))
	assert_true(wanted > 0, "tournament.json names no min_party_size; the entry rule has no threshold")
	assert_eq(TOURNAMENT.required_party_size(), wanted,
		"required_party_size() does not read tournament.json's own min_party_size")


## And it can never ask for more creatures than the player is allowed to own.
## CLAUDE.md's hardest rule is the five-creature cap; an entry condition above
## it would be a chapter that cannot be finished.
func test_the_threshold_can_never_exceed_the_five_creature_cap() -> void:
	assert_eq(TOURNAMENT.PARTY_CAP, PARTY.MAX_CREATURES,
		"tournament.gd's PARTY_CAP has drifted from party.gd's MAX_CREATURES")
	assert_true(TOURNAMENT.required_party_size() <= PARTY.MAX_CREATURES,
		"the tournament asks for %d creatures against a cap of %d"
			% [TOURNAMENT.required_party_size(), PARTY.MAX_CREATURES])


## FIRST-HOUR-FUN-REBUILD. Halda asks for the full permanent roster, not the
## older three-creature bracket. The cap makes this a precise, finishable rule.
func test_registration_requires_the_full_five_creature_roster() -> void:
	assert_eq(TOURNAMENT.required_party_size(), PARTY.MAX_CREATURES,
		"tournament registration should require all five permanent creature slots")
	_fill_party(PARTY.MAX_CREATURES - 1, TOURNAMENT.required_level())
	assert_false(TOURNAMENT.team_ready(party),
		"four creatures should not satisfy the full-roster registration requirement")


func test_one_creature_is_not_a_team() -> void:
	_fill_party(1, 20)
	assert_false(TOURNAMENT.team_ready(party),
		"a single creature satisfied the team condition; the marshal's whole first line is that it does not")


func test_enough_creatures_satisfies_the_team_condition() -> void:
	_fill_party(TOURNAMENT.required_party_size(), 1)
	assert_true(TOURNAMENT.team_ready(party),
		"a full-sized party did not satisfy the team condition")


## Training is a separate condition and is about LEVELS. A party of the right
## size at level 1 is not trained.
func test_a_full_but_untrained_party_is_not_allowed_to_enter() -> void:
	_fill_party(TOURNAMENT.required_party_size(), 1)
	assert_true(TOURNAMENT.team_ready(party))
	assert_false(TOURNAMENT.training_ready(party),
		"a party of level-1 creatures read as trained; the training condition does nothing")


func test_a_party_at_the_authored_level_is_trained() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	assert_true(TOURNAMENT.training_ready(party),
		"a party at exactly min_level did not satisfy the training condition")


## One level short is short. The boundary, not just the happy path -- a rule
## written with `>` instead of `>=` passes every other test in this file.
func test_one_level_below_the_threshold_is_not_trained() -> void:
	_fill_party(TOURNAMENT.required_party_size(), maxi(1, TOURNAMENT.required_level() - 1))
	assert_false(TOURNAMENT.training_ready(party),
		"a party one level below min_level read as trained")


## A full qualification roster occupies every legal creature slot. It must not
## suggest an impossible sixth-slot reserve merely to prove a sorting rule.
func test_a_ready_full_roster_cannot_add_a_sixth_creature() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	assert_true(TOURNAMENT.training_ready(party))
	var tagalong: RefCounted = SPECIES.spawn("bramblebun")
	tagalong.set_level(1, PROGRESSION.config())
	assert_false(party.add(tagalong), "a full five-creature roster must not grow a hidden sixth slot")
	assert_true(TOURNAMENT.training_ready(party),
		"rejecting an impossible sixth creature should not revoke a ready entry")


## A null party is the capture-tool / bare-test-scene case. It must read as NOT
## ready: the cautious direction here is refusing an entry, never granting one.
func test_no_party_at_all_reads_as_not_ready() -> void:
	assert_false(TOURNAMENT.team_ready(null))
	assert_false(TOURNAMENT.training_ready(null))


## --- the marshal's ladder -----------------------------------------------------

## Every conversation Halda can open has to exist, or a branch matches and the
## dialogue panel refuses to open at all.
func test_every_conversation_the_marshal_can_open_exists() -> void:
	var marshal := _marshal()
	assert_false(marshal.is_empty(),
		"village_npcs.json has no villager named '%s'; nobody runs the tournament" % TOURNAMENT.marshal_name())
	var ids: Array[String] = [str(marshal.get("greeting", ""))]
	for raw: Variant in (marshal.get("greeting_when", []) as Array):
		ids.append(str((raw as Dictionary).get("conversation", "")))
	for id: String in ids:
		assert_ne(id, "", "the marshal has a branch naming no conversation")
		assert_true(RUNNER.has(id), "the marshal opens '%s', which no dialogue file defines" % id)


## THE LOAD-BEARING ONE. Walk the whole ladder in order with a real flag store
## and a real party, and assert the marshal says the right thing at every rung.
## `greeting_when` is an ORDERED list and first match wins, so a branch in the
## wrong position offers the final before the first bout has been fought --
## which is silent, and which no other test in the repo would catch.
func test_the_marshal_walks_the_whole_ladder_in_order() -> void:
	var marshal := _marshal()
	assert_false(marshal.is_empty(), "no marshal to walk")
	if marshal.is_empty():
		return

	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_register",
		"Halda's first meeting should register the tournament requirements")

	progression.set_flag("opening:tournament_registered")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_closed",
		"after registration, an incomplete roster should be told to fill all five places")

	progression.set_flag("tournament_team_ready")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_train",
		"with the bodies but not the levels, she should be sending the player out to train")

	progression.set_flag("tournament_training_ready")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_condition",
		"a levelled team in poor condition should be told to rest and feed them, not signed up")

	# RG19-spec/D68's volatile flag, written by `tournament.gd`'s poll once the
	# entrants are rested, fed and happy.
	progression.set_flag("tournament_condition_ready")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_camp",
		"a complete ready team without camp/bed/recovery proof should be sent to make camp")

	for flag: String in ["home_built", "creature_bed_built", "player_slept_at_home"]:
		progression.set_flag(flag)
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_signup",
		"a ready team should be offered the sign-up")

	progression.set_flag("tournament_entered")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_quarter",
		"an entered player should be offered round 1")

	progression.set_flag("tournament_quarter_won")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_semi",
		"after round 1 she should be offering round 2")

	progression.set_flag("tournament_semi_won")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_final",
		"after round 2 she should be offering the final")

	progression.set_flag("tournament_won")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_champion",
		"a champion should get the champion's line, and it should carry the riding news")


## TOURNAMENT-FLOW-0903, owner playtest 2026-09-03 item 2: "Starting the
## tournament was hard even after I had everything. I had to talk to the
## starter several times." A team built, trained, fed, rested and camped
## before the player ever walked up to Halda used to hear the registration
## briefing FIRST regardless -- a throwaway conversation that only repeated
## what the player had already done -- and only offered sign-up on a second
## visit. Fixed so a fully ready team's first-ever conversation with her is
## the sign-up itself.
func test_a_team_that_is_already_ready_before_ever_meeting_the_marshal_is_offered_sign_up_in_one_visit() -> void:
	var marshal := _marshal()
	assert_false(marshal.is_empty(), "no marshal to walk")
	if marshal.is_empty():
		return
	for flag: String in ["tournament_team_ready", "tournament_training_ready",
			"tournament_condition_ready", "home_built", "creature_bed_built", "player_slept_at_home"]:
		progression.set_flag(flag)
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_signup",
		"a fully ready team's very first conversation with the marshal should be the sign-up, not the registration briefing")


## And a team that is ready on BODIES but not yet on levels, condition or camp
## before that first meeting should land straight on the specific branch that
## names what is actually missing -- never the generic register speech, which
## would just repeat a checklist the player has already half-finished.
func test_a_team_ready_but_untrained_before_ever_meeting_the_marshal_skips_registration() -> void:
	var marshal := _marshal()
	if marshal.is_empty():
		return
	progression.set_flag("tournament_team_ready")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_train",
		"a team-ready-but-untrained party's first meeting should name training, not the register speech")


## The one case the register branch is still FOR: a player who has not even
## assembled a team yet. That is a genuinely fresh start, and the full
## checklist is the right thing to say once.
func test_a_genuinely_fresh_player_still_gets_the_registration_briefing_first() -> void:
	var marshal := _marshal()
	if marshal.is_empty():
		return
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_register",
		"a player with no team yet should still meet the registration briefing first")


## TOURNAMENT-FLOW-0903, owner playtest 2026-09-03 item 3: "you enter then you
## choose to start the battle then it announces you won and announces the
## next round." Walk the ceremony half of the ladder: the ring-entrance
## banter is offered first, the explicit begin-the-round line only once the
## player is actually at_ring, and winning moves straight to the NEXT round's
## own banter (not its begin line) so the same two-step ceremony repeats.
func test_the_marshal_offers_the_explicit_begin_choice_only_once_the_player_is_at_ring() -> void:
	var marshal := _marshal()
	assert_false(marshal.is_empty(), "no marshal to walk")
	if marshal.is_empty():
		return

	progression.set_flag("tournament_entered")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_quarter",
		"entering the draw should first offer the opponent's ring-entrance banter")
	progression.set_flag("tournament_quarter_at_ring")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_quarter_begin",
		"once at ring, the marshal's ladder should offer the explicit begin-the-round line")

	progression.set_flag("tournament_quarter_won")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_semi",
		"winning the quarter should move straight to the semi-final's own ring-entrance banter")
	progression.set_flag("tournament_semi_at_ring")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_semi_begin",
		"once at ring for the semi, the marshal should offer its begin-the-round line")

	progression.set_flag("tournament_semi_won")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_final",
		"winning the semi should move straight to the final's own ring-entrance banter")
	progression.set_flag("tournament_final_at_ring")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_final_begin",
		"once at ring for the final, the marshal should offer its begin-the-round line")

	progression.set_flag("tournament_won")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_champion",
		"winning the final should still hand off to the champion's line")


## A round lost after reaching the ring must not repeat the ceremony's banter
## half -- `at_ring_flag` is a contract flag, never cleared, so a retry lands
## straight back on the begin-the-round line rather than making the player sit
## through the opponent's pre-fight speech again.
func test_a_lost_round_retried_from_the_ring_skips_the_banter_and_offers_begin_again() -> void:
	var marshal := _marshal()
	if marshal.is_empty():
		return
	progression.set_flag("tournament_entered")
	progression.set_flag("tournament_quarter_at_ring")
	# Fought and lost: quarter_won stays unset, at_ring stays set.
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_quarter_begin",
		"a round lost after entering the ring should go straight back to the begin-the-round line, not repeat the banter")


## RG19-spec/D68. Condition gates ENTRY, not the bracket. A team that tires
## out or goes hungry between rounds must still be offered the round it is in
## the middle of -- being sent back out to feed somebody with a bout half
## fought is the one way this gate could brick a run.
func test_a_hungry_team_mid_bracket_is_still_offered_its_round() -> void:
	var marshal := _marshal()
	if marshal.is_empty():
		return
	for flag: String in ["tournament_team_ready", "tournament_training_ready",
			"tournament_condition_ready", "tournament_entered"]:
		progression.set_flag(flag)
	progression.set_flag("tournament_condition_ready", false)
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_quarter",
		"a team that went hungry mid-bracket was sent back out instead of being offered its round")


## "You can lose and retry after healing your creatures." Losing sets no flag
## (`encounter_director._finish_trainer_battle(false)` records nothing), so the
## proof is that the SAME round is still on offer with the flag state a loss
## leaves behind.
func test_a_lost_round_is_still_on_offer() -> void:
	var marshal := _marshal()
	if marshal.is_empty():
		return
	progression.set_flag("tournament_team_ready")
	progression.set_flag("tournament_training_ready")
	progression.set_flag("tournament_entered")
	progression.set_flag("tournament_quarter_won")
	# Round 2 fought and lost: nothing was written.
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_semi",
		"after losing round 2 the marshal should offer round 2 again, not move on and not lock the player out")


## The effects on a conversation's own LAST line, whether authored as a single
## `effect` string or an `effects` array. Shared by every ceremony test below
## so the two authoring shapes are read the same way everywhere.
func _last_line_effects(conversation_id: String) -> Array:
	var lines: Array = (RUNNER.table().get(conversation_id, {}) as Dictionary).get("lines", [])
	if lines.is_empty():
		return []
	var last: Variant = lines[lines.size() - 1]
	if not last is Dictionary:
		return []
	var line := last as Dictionary
	if line.has("effects"):
		return line.get("effects", []) as Array
	if line.has("effect"):
		return [str(line.get("effect", ""))]
	return []


## TOURNAMENT-FLOW-0903, owner playtest 2026-09-03 item 3: "you enter then you
## choose to start the battle". Each round is now TWO conversations -- the
## ring-entrance banter (`conversation`) and the explicit begin-the-round line
## (`begin_conversation`) -- and it is `begin_conversation` that has to end on
## the `battle:` effect, not the banter. Same contract `trainer_npc.gd` and
## `sequence_director.gd` both rely on: the fight starts when the box closes,
## so an effect on an earlier line drops an arena on top of an open dialogue
## box.
func test_each_rounds_begin_conversation_ends_on_its_own_battle_effect() -> void:
	for entry: Variant in TOURNAMENT.rounds():
		var spec := entry as Dictionary
		var id := str(spec.get("begin_conversation", ""))
		assert_ne(id, "", "round '%s' names no begin_conversation" % str(spec.get("id", "")))
		var effects := _last_line_effects(id)
		assert_true(effects.has("battle:%s" % str(spec.get("trainer", ""))),
			"'%s' should end on battle:%s; its last line's effects are %s" % [id, str(spec.get("trainer", "")), str(effects)])


## And the ring-entrance banter must NOT end on that effect -- the whole point
## of splitting the round in two is that hearing the opponent's pre-fight line
## does not, by itself, start the fight. It sets `at_ring_flag` instead, which
## is what actually gates `begin_conversation` in village_npcs.json's ladder.
func test_each_rounds_banter_conversation_sets_at_ring_and_starts_no_battle() -> void:
	for entry: Variant in TOURNAMENT.rounds():
		var spec := entry as Dictionary
		var id := str(spec.get("conversation", ""))
		var at_ring_flag := str(spec.get("at_ring_flag", ""))
		assert_ne(at_ring_flag, "", "round '%s' names no at_ring_flag" % str(spec.get("id", "")))
		var effects := _last_line_effects(id)
		assert_true(effects.has("flag:%s" % at_ring_flag),
			"'%s' should end on flag:%s so entering the ring does not itself start the fight; its effects are %s"
				% [id, at_ring_flag, str(effects)])
		assert_false(effects.has("battle:%s" % str(spec.get("trainer", ""))),
			"'%s' still starts the fight on its own; the explicit begin-the-round choice would do nothing" % id)


## Entering is what `tournament_entered` means, and the sign-up line is the one
## place it is written. A ladder whose sign-up sets nothing offers the sign-up
## forever.
func test_the_sign_up_line_is_what_writes_tournament_entered() -> void:
	var lines: Array = (RUNNER.table().get("tournament_halda_signup", {}) as Dictionary).get("lines", [])
	var found := false
	for raw: Variant in lines:
		if not raw is Dictionary:
			continue
		var line := raw as Dictionary
		var effects: Array = (line.get("effects", []) as Array).duplicate()
		if str(line.get("effect", "")) != "":
			effects.append(str(line.get("effect", "")))
		if effects.has("flag:tournament_entered"):
			found = true
	assert_true(found, "the sign-up conversation never sets tournament_entered")


## The opening controller waits for this actual dialogue effect before it
## advances its own handoff. Pin the effect to the first Registrar visit rather
## than treating proximity to Halda as registration.
func test_the_registrar_briefing_writes_the_opening_registration_handoff() -> void:
	var lines: Array = (RUNNER.table().get("tournament_halda_register", {}) as Dictionary).get("lines", [])
	var found := false
	for raw: Variant in lines:
		if not raw is Dictionary:
			continue
		var line := raw as Dictionary
		var effects: Array = (line.get("effects", []) as Array).duplicate()
		if str(line.get("effect", "")) != "":
			effects.append(str(line.get("effect", "")))
		if effects.has("flag:opening:tournament_registered"):
			found = true
	assert_true(found, "Halda's first registration briefing never sets opening:tournament_registered")


## TOURNAMENT-FLOW-0903, owner playtest 2026-09-03 item 2: "even after I had
## everything, I had to talk to the starter several times". The register
## branch is narrowed to fire only while the team is not yet team-ready
## (below), so `tournament_halda_signup`, `_camp`, `_condition` and `_train`
## can each be a player's FIRST-EVER conversation with Halda. Every one of
## them has to write the opening handoff itself, or a team that was ready
## before it ever met her would never trip it at all.
func test_every_branch_that_can_be_a_first_meeting_writes_the_opening_registration_handoff() -> void:
	for id: String in ["tournament_halda_signup", "tournament_halda_camp",
			"tournament_halda_condition", "tournament_halda_train"]:
		assert_true(_last_line_effects(id).has("flag:opening:tournament_registered"),
			"'%s' can be the player's first meeting with the marshal but never writes opening:tournament_registered" % id)


## Qualification is intentionally a compact camp, not legacy house architecture
## or a Workbench gate. These are the durable existing-system proof flags that
## the ordered sign-up branch is allowed to require.
func test_tournament_sign_up_requires_compact_camp_and_care_not_a_workbench() -> void:
	var marshal := _marshal()
	var signup: Dictionary = {}
	for raw: Variant in (marshal.get("greeting_when", []) as Array):
		var branch := raw as Dictionary
		if str(branch.get("conversation", "")) == "tournament_halda_signup":
			signup = branch
			break
	assert_false(signup.is_empty(), "Halda has no tournament sign-up branch")
	var required: Array = signup.get("if_flag", []) as Array
	for flag: String in ["tournament_team_ready", "tournament_training_ready", "tournament_condition_ready", "home_built", "creature_bed_built", "player_slept_at_home"]:
		assert_true(required.has(flag), "tournament sign-up does not require '%s'" % flag)
	assert_false(required.has("workbench_built"), "the Workbench must remain optional for tournament qualification")
	assert_false(required.has("wall_built") or required.has("roof_built") or required.has("door_built"),
		"tournament qualification must not restore mandatory house architecture")


## --- the prize ----------------------------------------------------------------

## "Winning grants the saddle recipe." Granted by WINNING -- the final round's
## own `reward.flags` -- and not by a conversation, so a champion who never
## walks back to the marshal still has it.
func test_winning_the_final_grants_the_saddle_pattern() -> void:
	var final_id := str(TOURNAMENT.round_spec("final").get("trainer", ""))
	assert_true(TRAINERS.reward_flags(TRAINERS.trainer(final_id)).has("recipe_saddle"),
		"the final's reward.flags does not grant recipe_saddle; the tournament pays out nothing lasting")


## And the win itself is recorded on the contract flag, by the same defeat-flag
## machinery every other trainer in the chapter uses.
func test_the_final_is_what_sets_the_tournament_won_contract_flag() -> void:
	var final_id := str(TOURNAMENT.round_spec("final").get("trainer", ""))
	assert_eq(str(TRAINERS.trainer(final_id).get("defeat_flag", "")), "tournament_won",
		"the final's defeat_flag is not tournament_won; the contract flag would never fire")


## "Plus an NPC line telling the player the mount can be ridden." A prize
## nobody explains is a recipe row that appears from nowhere.
func test_the_champions_line_says_the_mount_can_be_ridden() -> void:
	var said := ""
	for raw: Variant in (RUNNER.table().get("tournament_halda_champion", {}) as Dictionary).get("lines", []):
		said += (str((raw as Dictionary).get("text", "")) if raw is Dictionary else str(raw)) + " "
	said = said.to_lower()
	assert_true(said.contains("meadowhart"),
		"the champion's line never names the creature that can be ridden")
	assert_true(said.contains("carry you") or said.contains("ride") or said.contains("ridden"),
		"the champion's line never says the Meadowhart can be ridden")
	assert_true(said.contains("saddle"), "the champion's line never mentions the saddle it just handed over")


## --- the South Bridge hand-off ------------------------------------------------

## "The tournament happens BEFORE Oskar's South Bridge fight" -- so Oskar is no
## longer the gatekeeper and the grunt is. Asserted here as well as in
## test_trainers_data.gd because it is the tournament that caused the move.
func test_the_bridge_key_moved_off_the_tournaments_finalist() -> void:
	var oskar_items: Array[String] = []
	for item: Variant in TRAINERS.reward_items(TRAINERS.trainer("trainer_oskar")):
		oskar_items.append(str((item as Dictionary).get("id", "")))
	assert_false(oskar_items.has("south_bridge_key"),
		"Oskar still gates the South Bridge; the directive frees him to be the tournament's final")
	var grunt_items: Array[String] = []
	for item: Variant in TRAINERS.reward_items(TRAINERS.trainer("south_bridge_grunt")):
		grunt_items.append(str((item as Dictionary).get("id", "")))
	assert_true(grunt_items.has("south_bridge_key"),
		"nobody hands over the South Bridge Key any more; Gate 1 is unopenable")


## --- the board ----------------------------------------------------------------

func test_a_fresh_board_names_the_draw_and_decides_nothing() -> void:
	var state := TOURNAMENT.bracket_state(progression)
	assert_eq(state.size(), 4, "a bracket of eight has four columns: 8, 4, 2 and 1")
	var draw: Array = state[0]
	assert_eq(draw.size(), 8, "the draw should hold all eight slots")
	for entry: Variant in TOURNAMENT.bracket():
		var name := str((entry as Dictionary).get("name", ""))
		var found := false
		for slot: Variant in draw:
			found = found or str((slot as Dictionary).get("name", "")) == name
		assert_true(found, "the draw never names bracket slot '%s'" % name)
	for depth in [1, 2, 3]:
		for slot: Variant in (state[depth] as Array):
			assert_false(bool((slot as Dictionary).get("decided", false)),
				"a fresh board has already decided a round-%d bout" % depth)
			assert_eq(str((slot as Dictionary).get("name", "")), "",
				"a fresh board already names a round-%d winner" % depth)


## THE owner ruling, 2026-08-22, on the first render of this board: "it should
## only fill in after events not be filled in from the start."
##
## The board this replaced printed "You vs Tam" in the semi-finals and "You vs
## Oskar" in the final from the moment the draw opened -- pairings that only
## exist if the quarter-finals have already been fought. A slot may not carry
## a name until BOTH bouts feeding it are decided.
func test_a_later_round_names_nobody_until_its_feeders_are_decided() -> void:
	progression.set_flag("tournament_entered")
	var after_entry := TOURNAMENT.bracket_state(progression)
	for slot: Variant in (after_entry[1] as Array):
		assert_eq(str((slot as Dictionary).get("name", "")), "",
			"entering the draw filled a quarter-final result in before a punch was thrown")

	# The player wins their own quarter. That decides THEIR semi-final place
	# and, by the simulated results, the other three -- but not the final,
	# whose feeders are two undecided semi-finals.
	progression.set_flag("tournament_quarter_won")
	var after_quarter := TOURNAMENT.bracket_state(progression)
	for slot: Variant in (after_quarter[1] as Array):
		assert_true(bool((slot as Dictionary).get("decided", false)),
			"the quarter-final column should be full once the player has won theirs")
	for slot: Variant in (after_quarter[2] as Array):
		assert_eq(str((slot as Dictionary).get("name", "")), "",
			"a semi-final winner was named before any semi-final was fought")
	assert_eq(str(((after_quarter[3] as Array)[0] as Dictionary).get("name", "")), "",
		"the champion was named before the final existed")

	progression.set_flag("tournament_semi_won")
	var after_semi := TOURNAMENT.bracket_state(progression)
	assert_eq(str(((after_semi[2] as Array)[0] as Dictionary).get("name", "")),
		TOURNAMENT.player_slot_name(),
		"winning the semi-final should put the player through on the board")
	assert_eq(str(((after_semi[3] as Array)[0] as Dictionary).get("name", "")), "",
		"the champion was named before the final was fought")

	progression.set_flag("tournament_won")
	assert_eq(str(((TOURNAMENT.bracket_state(progression)[3] as Array)[0] as Dictionary).get("name", "")),
		TOURNAMENT.player_slot_name(),
		"winning the final should crown the player on the board")


## The simulated half fills in BETWEEN the player's own matches, which is the
## behaviour the directive asks for by name.
func test_the_simulated_quarter_finals_resolve_after_the_players_own() -> void:
	for slot: Variant in (TOURNAMENT.bracket_state(progression)[1] as Array):
		assert_false(bool((slot as Dictionary).get("decided", false)),
			"the board resolved a quarter-final before the player had fought a single bout")

	progression.set_flag("tournament_quarter_won")
	var winners: Array[String] = []
	for slot: Variant in (TOURNAMENT.bracket_state(progression)[1] as Array):
		winners.append(str((slot as Dictionary).get("name", "")))
	for sim: Dictionary in TOURNAMENT.simulated_for("quarter"):
		assert_true(winners.has(str(sim.get("winner", ""))),
			"the board never put '%s' through after the player won their own quarter-final"
				% str(sim.get("winner", "")))


## Every simulated bout's `reveal_after` has to be a flag something actually
## sets, or that half of the board is blank forever. The flags that can set it
## are the rounds' own `won_flag`s.
func test_every_simulated_result_waits_on_a_flag_a_round_actually_sets() -> void:
	var writable: Array[String] = []
	for entry: Variant in TOURNAMENT.rounds():
		writable.append(str((entry as Dictionary).get("won_flag", "")))
	for entry: Variant in TOURNAMENT.simulated():
		var sim := entry as Dictionary
		var flag := str(sim.get("reveal_after", ""))
		assert_true(writable.has(flag),
			"'%s vs %s' waits on '%s', which no fought round ever sets"
				% [str(sim.get("a", "")), str(sim.get("b", "")), flag])


## Every round's `won_flag` is the trainer's own `defeat_flag`. Two names for
## one fact is how a board stops agreeing with the fight that filled it in.
func test_each_rounds_win_flag_is_its_trainers_defeat_flag() -> void:
	for entry: Variant in TOURNAMENT.rounds():
		var spec := entry as Dictionary
		var trainer := TRAINERS.trainer(str(spec.get("trainer", "")))
		assert_eq(str(spec.get("won_flag", "")), str(trainer.get("defeat_flag", "")),
			"round '%s' watches '%s' but its trainer writes '%s'"
				% [str(spec.get("id", "")), str(spec.get("won_flag", "")), str(trainer.get("defeat_flag", ""))])


## A LOSS leaves the bout UNDECIDED on the board, not lost. The round stays
## open and the marshal offers it again, so a board that closed the bout would
## contradict the rule the owner locked.
func test_a_lost_bout_stays_undecided_on_the_board() -> void:
	progression.set_flag("tournament_entered")
	var players_place := (TOURNAMENT.bracket_state(progression)[1] as Array)[0] as Dictionary
	assert_false(bool(players_place.get("decided", false)),
		"after entering and losing, the player's own bout should still read undecided")

	progression.set_flag(str(TOURNAMENT.round_spec("quarter").get("won_flag", "")))
	players_place = (TOURNAMENT.bracket_state(progression)[1] as Array)[0] as Dictionary
	assert_eq(str(players_place.get("name", "")), TOURNAMENT.player_slot_name(),
		"winning the bout did not put the player through on the board")


## Every name the bracket can show has to fit the slot cell it is painted in,
## at every stage. A name that overruns its cell is a defect nobody notices in
## a headless run and everybody notices in a frame.
func test_every_painted_name_fits_its_slot_at_every_stage() -> void:
	var stages: Array[String] = ["", "tournament_entered", "tournament_quarter_won",
		"tournament_semi_won", "tournament_won"]
	for flag: String in stages:
		if flag != "":
			progression.set_flag(flag)
		var fitted := TOURNAMENT.fitted_pixel_size(progression)
		assert_true(fitted > 0.0, "the bracket fitted to a pixel size of %f; nothing would be painted" % fitted)
		assert_true(fitted <= TOURNAMENT.NAME_PIXEL_SIZE,
			"the bracket fitted above its own ceiling and would overrun the slot")
		for column: Variant in TOURNAMENT.bracket_state(progression):
			for entry: Variant in (column as Array):
				var name := str((entry as Dictionary).get("name", ""))
				var width := float(name.length()) * TOURNAMENT.LABEL_GLYPH_ADVANCE \
					* float(TOURNAMENT.NAME_FONT_SIZE) * fitted
				assert_true(width <= TOURNAMENT.SLOT_WIDTH,
					"'%s' is %.2fm wide in a %.2fm slot" % [name, width, TOURNAMENT.SLOT_WIDTH])


## The four columns must not overlap each other or hang off the panel.
func test_the_columns_fit_across_the_panel() -> void:
	var half := TOURNAMENT.BOARD_WIDTH * 0.5
	var previous := -half
	for x: float in TOURNAMENT.COLUMN_X:
		var left := x - TOURNAMENT.SLOT_WIDTH * 0.5
		var right := x + TOURNAMENT.SLOT_WIDTH * 0.5
		assert_true(left >= previous,
			"a bracket column starting at %.2fm overlaps the one before it" % left)
		assert_true(right <= half,
			"a bracket column reaching %.2fm hangs off a %.2fm board" % [right, TOURNAMENT.BOARD_WIDTH])
		previous = right


## The one line the board says out loud tracks the bracket. It is the only
## reading of the tournament's state a player gets without walking up close.
func test_the_boards_spoken_line_tracks_the_bracket() -> void:
	assert_true(TOURNAMENT.status_line(progression).contains("open"),
		"before entering, the board should say the draw is open")
	progression.set_flag("tournament_entered")
	assert_true(TOURNAMENT.status_line(progression).contains("Mira"),
		"after entering, the board should name the first opponent")
	progression.set_flag("tournament_quarter_won")
	progression.set_flag("tournament_semi_won")
	assert_true(TOURNAMENT.status_line(progression).contains("Oskar"),
		"in the final, the board should name the finalist")
	progression.set_flag("tournament_won")
	assert_true(TOURNAMENT.status_line(progression).to_lower().contains("champion"),
		"a won tournament should read as won")


## --- TOURNAMENT-FLOW-0903: the win/next-round announcement --------------------

## Owner playtest 2026-09-03 item 3: "it announces you won and announces the
## next round." Pure and static, same reason `status_line()` is: a test should
## be able to pin the exact wording without a node standing in a world.
func test_round_result_message_names_the_next_round() -> void:
	var msg := TOURNAMENT.round_result_message(0)
	assert_true(msg.contains("Semi-final"),
		"winning the quarter-final should announce the semi-final by name: '%s'" % msg)
	assert_true(msg.contains("Tam"),
		"winning the quarter-final should name the next opponent: '%s'" % msg)

	var msg2 := TOURNAMENT.round_result_message(1)
	assert_true(msg2.contains("Final"),
		"winning the semi-final should announce the final by name: '%s'" % msg2)
	assert_true(msg2.contains("Oskar"),
		"winning the semi-final should name the finalist: '%s'" % msg2)


## "Or the championship." The last round's win has no next round to name, so
## it announces the title instead.
func test_round_result_message_announces_the_championship_for_the_final_round() -> void:
	var msg := TOURNAMENT.round_result_message(TOURNAMENT.rounds().size() - 1)
	assert_true(msg.to_lower().contains("champion"),
		"winning the final should announce the championship, not a round that does not exist: '%s'" % msg)


## An out-of-range index (the capture-tool / bare-call case) must not crash a
## polling node; an empty string is the cautious, silent answer.
func test_round_result_message_is_empty_for_an_out_of_range_index() -> void:
	assert_eq(TOURNAMENT.round_result_message(-1), "")
	assert_eq(TOURNAMENT.round_result_message(TOURNAMENT.rounds().size()), "")


## --- the board's own placement ------------------------------------------------

## The board stands where the fights happen and does not contest a prompt that
## was already there. Bryn's challenge reaches 4.2m and the board's statement
## reaches 2.6m; closer than the sum of those and the player standing between
## them gets whichever the arbiter happens to pick.
func test_the_board_does_not_contest_the_practice_trainers_prompt() -> void:
	var bryn: Array = TRAINERS.trainer("practice_trainer").get("position", [])
	assert_eq(bryn.size(), 2, "the practice trainer has no position to measure against")
	if bryn.size() != 2:
		return
	var apart := TOURNAMENT.board_position().distance_to(Vector2(float(bryn[0]), float(bryn[1])))
	assert_true(apart > 4.2 + TOURNAMENT.PROMPT_RADIUS,
		"the board stands %.1fm from Bryn; their prompts overlap" % apart)


## --- RG19-spec/D68: the condition gate ----------------------------------------

## The owner's own entry rule: "They have to be well rested, well fed, and
## happy." A team at the size and level thresholds is still not in, and that
## is the whole point of the third condition.
func test_a_levelled_team_in_poor_condition_is_not_allowed_in() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	assert_true(TOURNAMENT.team_ready(party), "the team is the authored size")
	assert_true(TOURNAMENT.training_ready(party), "the team is at the authored level")
	assert_false(TOURNAMENT.condition_ready(party),
		"a team that has never slept, eaten or been cared for was tournament-ready")


func test_a_rested_fed_happy_team_is_allowed_in() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	_bring_the_party_into_condition()
	assert_true(TOURNAMENT.condition_ready(party),
		"a rested, fed and happy team was still refused: %s"
			% str(TOURNAMENT.readiness_report(party)))


## One creature out of condition refuses the whole team, because the team is
## what is entered.
func test_one_creature_out_of_condition_holds_the_team_back() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	_bring_the_party_into_condition()
	party.at(0).set("nourishment", 0.0)
	assert_false(TOURNAMENT.condition_ready(party), "a starving entrant was waved through")


## And the refusal has to SAY what to fix -- 26-RG19 asks for a readiness
## summary rather than a vague "not ready".
func test_the_readiness_report_names_the_creature_and_the_problem() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	_bring_the_party_into_condition()
	party.at(0).set("nourishment", 0.0)
	var report := TOURNAMENT.readiness_report(party)
	assert_eq(report.size(), 1, "the report should name exactly the one creature that is not ready")
	assert_true(report[0].contains(str(party.at(0).call("label"))),
		"the report does not name the creature it is about: %s" % report[0])
	assert_true(report[0].contains("feed"), "the report does not say what to do: %s" % report[0])
	assert_true(TOURNAMENT.readiness_report(party).size() < 2)


## A ready team's report is empty -- nothing to fix, nothing to say.
func test_a_ready_team_has_nothing_to_report() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	_bring_the_party_into_condition()
	assert_eq(TOURNAMENT.readiness_report(party).size(), 0)


## A full qualified roster has no sixth slot to sneak an unready creature into.
## Refusing that impossible add preserves the existing five entrants' condition.
func test_an_impossible_sixth_creature_cannot_disqualify_a_ready_team() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	_bring_the_party_into_condition()
	var stray: RefCounted = SPECIES.spawn("bramblebun")
	CONDITION.start(stray, CONDITION.config())
	assert_false(party.add(stray), "the party must reject a sixth creature at the five-creature cap")
	assert_true(TOURNAMENT.condition_ready(party),
		"rejecting an impossible sixth creature should leave the ready five qualified")


## --- TUTORIAL-CHAIN (OP23-04): "feed your team" on its own ------------------
##
## Owner directive 2026-08-23 section 2 keeps the ~1.1/min satiety drain and
## adds a taught rung before sign-up. That rung waits on `team_fed()`, which is
## the FED third of the condition gate asked on its own -- so the objective can
## say "feed your team" and be telling the truth about why it is open.
##
## Verified to fail against pre-TUTORIAL-CHAIN `main`: `team_fed` did not
## exist.

## A caught creature starts at `nourishment.start` (70), which is deliberately
## ABOVE `fed_at` (0.55) so the meter is not empty the moment you own something
## -- so "never eaten" is not the same as "hungry", and the rung is honest
## about that: it opens when the team has DRAINED, which at 1.1/minute is about
## fourteen minutes into owning them, well inside the opening ladder.
func test_a_team_that_has_drained_below_the_threshold_is_not_fed() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	assert_true(TOURNAMENT.team_fed(party),
		"a freshly caught team should start fed; creature_condition.json's "
			+ "nourishment.start is above fed_at on purpose")
	var cfg: Dictionary = CONDITION.config()
	var below := float(cfg.get("nourishment", {}).get("max", 100.0)) \
		* float(cfg.get("nourishment", {}).get("fed_at", 0.55)) - 1.0
	for i in int(party.size()):
		party.at(i).set("nourishment", below)
	assert_false(TOURNAMENT.team_fed(party),
		"a team below the fed threshold still read as fed")


func test_a_fed_team_reads_fed_even_while_it_is_tired() -> void:
	# The whole reason this is separate from `condition_ready()`: a team that
	# has eaten but not slept must CLOSE the feed rung and leave the rest one
	# open, not sit under a line telling them to find food they already ate.
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	var cfg: Dictionary = CONDITION.config()
	for i in int(party.size()):
		party.at(i).set("nourishment", float(cfg.get("nourishment", {}).get("max", 100.0)))
	assert_true(TOURNAMENT.team_fed(party), "a fully fed team read as unfed")
	assert_false(TOURNAMENT.condition_ready(party),
		"this test needs the team to still be OUT of overall condition to mean anything")


func test_one_hungry_entrant_holds_the_feed_step_open() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	_bring_the_party_into_condition()
	assert_true(TOURNAMENT.team_fed(party))
	party.at(0).set("nourishment", 0.0)
	assert_false(TOURNAMENT.team_fed(party),
		"one starving entrant did not reopen the feed step; the team is what is entered")


func test_no_party_at_all_is_not_fed() -> void:
	assert_false(TOURNAMENT.team_fed(party),
		"an empty party read as a fed team, which would tick the rung before the "
			+ "player owns anything to feed")


## Every entrant, in condition. Rested through the same call the creature bed
## makes, fed and cheered to the configured maxima.
func _bring_the_party_into_condition() -> void:
	var cfg: Dictionary = CONDITION.config()
	for i in int(party.size()):
		var creature: RefCounted = party.at(i)
		creature.set("nourishment", float(cfg.get("nourishment", {}).get("max", 100.0)))
		creature.set("happiness", float(cfg.get("happiness", {}).get("max", 100.0)))
		CONDITION.note_rest_completed(creature, cfg)
