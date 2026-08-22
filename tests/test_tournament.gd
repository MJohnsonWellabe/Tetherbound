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


## And catching a fresh creature on the way to the bracket must not undo an
## entry the player already earned. The rule reads the STRONGEST
## `min_party_size` creatures, so a level-1 tag-along is irrelevant.
func test_a_freshly_caught_creature_does_not_untrain_a_ready_team() -> void:
	_fill_party(TOURNAMENT.required_party_size(), TOURNAMENT.required_level())
	assert_true(TOURNAMENT.training_ready(party))
	var tagalong: RefCounted = SPECIES.spawn("bramblebun")
	tagalong.set_level(1, PROGRESSION.config())
	assert_true(party.add(tagalong), "the party should have had room for a fourth")
	assert_true(TOURNAMENT.training_ready(party),
		"catching a level-1 creature revoked an entry the player had already earned")


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

	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_closed",
		"a fresh save should be told what a team is before anything else")

	progression.set_flag("tournament_team_ready")
	assert_eq(VILLAGE_NPCS.greeting_for(marshal, progression), "tournament_halda_train",
		"with the bodies but not the levels, she should be sending the player out to train")

	progression.set_flag("tournament_training_ready")
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


## Each round conversation ends on its own `battle:` effect, on the LAST line.
## Same contract `trainer_npc.gd` and `sequence_director.gd` both rely on: the
## fight starts when the box closes, so an effect on an earlier line drops an
## arena on top of an open dialogue box.
func test_each_round_conversation_ends_on_its_own_battle_effect() -> void:
	for entry: Variant in TOURNAMENT.rounds():
		var spec := entry as Dictionary
		var id := str(spec.get("conversation", ""))
		var lines: Array = (RUNNER.table().get(id, {}) as Dictionary).get("lines", [])
		assert_false(lines.is_empty(), "round conversation '%s' has no lines" % id)
		if lines.is_empty():
			continue
		var last: Variant = lines[lines.size() - 1]
		var effects: Array = []
		if last is Dictionary:
			var line := last as Dictionary
			if line.has("effects"):
				effects = line.get("effects", []) as Array
			elif line.has("effect"):
				effects = [str(line.get("effect", ""))]
		assert_true(effects.has("battle:%s" % str(spec.get("trainer", ""))),
			"'%s' should end on battle:%s; its last line is %s" % [id, str(spec.get("trainer", "")), str(last)])


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

## A fresh board shows the whole draw and resolves nothing. Eight names, no
## winners: the directive's "the bracket reads as real" starts here.
func test_a_fresh_board_names_every_slot_and_resolves_nothing() -> void:
	var painted := "\n".join(TOURNAMENT.board_lines(progression))
	for entry: Variant in TOURNAMENT.bracket():
		var name := str((entry as Dictionary).get("name", ""))
		assert_true(painted.contains(name), "the board never names bracket slot '%s'" % name)
	assert_true(painted.contains("...."),
		"a fresh board shows no undecided bouts at all; every result is already filled in")


## The simulated half fills in BETWEEN the player's own matches, which is the
## behaviour the directive asks for by name. Before the player's quarter-final
## the other three quarters are undecided; after it, all three have a winner.
func test_the_simulated_quarter_finals_resolve_after_the_players_own() -> void:
	var before := "\n".join(TOURNAMENT.board_lines(progression))
	for sim: Dictionary in TOURNAMENT.simulated_for("quarter"):
		var bout := "%s vs %s  --  %s" % [str(sim.get("a", "")), str(sim.get("b", "")), str(sim.get("winner", ""))]
		assert_false(before.contains(bout),
			"the board resolved '%s' before the player had fought a single bout" % bout)

	progression.set_flag("tournament_quarter_won")
	var after := "\n".join(TOURNAMENT.board_lines(progression))
	for sim: Dictionary in TOURNAMENT.simulated_for("quarter"):
		var bout := "%s vs %s  --  %s" % [str(sim.get("a", "")), str(sim.get("b", "")), str(sim.get("winner", ""))]
		assert_true(after.contains(bout),
			"the board never resolved '%s' after the player won their own quarter-final" % bout)


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
## contradict the rule the owner locked. Checked on the player's own row rather
## than by grepping for the word "lost", which no board could ever print today
## and which would therefore be an assertion that cannot fail.
func test_a_lost_bout_stays_undecided_on_the_board() -> void:
	progression.set_flag("tournament_entered")
	var quarter := TOURNAMENT.round_spec("quarter")
	var row := "You vs %s  --  ...." % str(quarter.get("opponent", ""))
	assert_true("\n".join(TOURNAMENT.board_lines(progression)).contains(row),
		"after entering and losing, the player's own bout should still read undecided; the board says:\n%s"
			% "\n".join(TOURNAMENT.board_lines(progression)))

	progression.set_flag(str(quarter.get("won_flag", "")))
	assert_false("\n".join(TOURNAMENT.board_lines(progression)).contains(row),
		"winning the bout did not change the board; the undecided row is still painted")


## The painted block has to fit the panel it is painted on, at every stage of
## the bracket. A fitted size that came out at or below zero would render
## nothing at all, and a size above the ceiling would overrun the board.
func test_the_painted_block_fits_the_board_at_every_stage() -> void:
	var stages: Array[String] = ["", "tournament_quarter_won", "tournament_semi_won", "tournament_won"]
	for flag: String in stages:
		if flag != "":
			progression.set_flag(flag)
		var lines := TOURNAMENT.board_lines(progression)
		var fitted := TOURNAMENT.pixel_size_for(lines)
		assert_true(fitted > 0.0, "the bracket fitted to a pixel size of %f; nothing would be painted" % fitted)
		assert_true(fitted <= TOURNAMENT.LABEL_PIXEL_SIZE,
			"the bracket fitted above its own ceiling and would overrun the panel")
		var longest := 0
		for line: String in lines:
			longest = maxi(longest, line.length())
		var width := float(longest) * TOURNAMENT.LABEL_GLYPH_ADVANCE * float(TOURNAMENT.LABEL_FONT_SIZE) * fitted
		assert_true(width <= TOURNAMENT.BOARD_WIDTH,
			"the widest bracket line is %.2fm wide on a %.2fm board" % [width, TOURNAMENT.BOARD_WIDTH])


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
