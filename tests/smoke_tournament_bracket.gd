extends SceneTree

## TOURNAMENT-1 / Gate B. Can the village tournament actually be **fought**,
## start to finish, by a player standing in the world?
##
##   godot --headless --path . --script tests/smoke_tournament_bracket.gd
##
## **Headless, never under xvfb** — docs/HANDOFF.md §10, same as every other
## scene-booting test here.
##
## `tests/test_tournament.gd` proves the tournament as DATA: eight slots, three
## fought rounds, the marshal's ladder in order, the thresholds, the board's
## text at every stage, the saddle pattern hanging off the final's own reward.
## Every one of those assertions reads a JSON file or calls a static function.
## Not one of them starts a fight, and so the thing the player actually does —
## sign up, win three battles in a row against real creatures on real ground,
## and walk away champion — was until now proven nowhere at all.
##
## This drives that path end to end:
##
##   1. after the first-registration briefing, a party too small to enter meets
##      the marshal's CLOSED line, and the two
##      entry flags are still unwritten
##   2. a party of the authored size but under the authored level meets her
##      TRAIN line — the entry condition is a reason, not a wall
##   3. a qualifying party makes `scripts/world/tournament.gd`'s own poll write
##      `tournament_team_ready` and `tournament_training_ready`, and her
##      SIGN-UP line appears
##   4. signing up sets `tournament_entered`, and the board in the field
##      changes what it says
##   5. the quarter-final is LOST on purpose — the owner's own rule
##      (`ralph/OWNER_DIRECTIVES_2026-08-22.md` §2: "You can lose and retry
##      after healing your creatures") — and the round is still on offer
##      afterward, with nothing consumed and no flag set
##   6. all three rounds are then fought and won for real, through the
##      marshal's dialogue and `encounter_director.begin_trainer_battle()`,
##      felling every creature on every authored team
##   7. each round pays its authored coins EXACTLY once
##   8. winning the final sets `tournament_won`, grants `recipe_saddle`, and
##      makes the saddle recipe genuinely known to the game
##   9. the marshal's champion line takes over, and greeting her again pays
##      nothing a second time
##
## The fights are driven with real input actions rather than by calling the
## manager's methods, so a broken binding fails here rather than on the
## handheld — the same contract `smoke_trainer_battle.gd` and
## `smoke_village_trainer.gd` hold, and this file follows their harness shape
## deliberately rather than inventing a third one.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
## The fight's own reach numbers, read rather than guessed. See
## `_load_attack_ranges()` for why this file may not carry its own.
const COMBAT_CONFIG := "res://data/config/combat.json"

const SETTLE_FRAMES := 300
## A hard ceiling per ROUND, so a director that never resolves one fails
## instead of hanging the CI job forever. Generous: the final is three fights
## back to back plus the beat between each.
const ROUND_FRAME_LIMIT := 9000
## The deliberate loss is a much shorter affair — one creature has to be
## knocked over once — but it still needs a ceiling of its own.
const LOSS_FRAME_LIMIT := 3000
## Frames a round may go without the opponent losing HP before this file calls
## it stuck. Comfortably longer than the beat between one of a trainer's
## creatures falling and the next stepping up (`trainers.json`'s
## `send_out_seconds`, 1.6s ≈ 96 frames) plus a charged attack's own wind-up,
## and far shorter than the round ceiling -- so a genuine stall is reported
## with its state rather than as a timeout with none.
const STALL_FRAMES := 900

## Every flag this test is allowed to find already set is cleared first, so a
## seeded playground party or a stray autoload state cannot hand the test a
## tournament that is already half-won.
const FLAGS_TO_CLEAR: PackedStringArray = [
	"tournament_team_ready", "tournament_training_ready", "tournament_entered",
	"tournament_quarter_won", "tournament_semi_won", "tournament_won",
	"tournament_condition_ready", "recipe_saddle", "opening:tournament_registered",
	"home_built", "creature_bed_built", "player_slept_at_home",
]

## Where the player stands to fight. `practice_trainer`'s own vetted-clear spot
## (trainers.json's `_why_here`: "12m clear of every structure, villager,
## harvest node and prop"), which is the same north-field clearing the
## tournament ground itself sits in — so the opponent's fallback spawn has
## somewhere legal to stand. Reused rather than invented, exactly as
## `smoke_village_trainer.gd` reuses it.
const CLEAR_SPOT := Vector2(13.0, 9.0)

## The species the stand-in team is built from, and the level they are raised
## to. The level is read from the tournament's own config at run time rather
## than written here — an entry threshold the test hard-codes is an entry
## threshold that silently stops testing the day it is tuned.
const TEAM_SPECIES: PackedStringArray = ["terrapup", "bramblebun", "mudsnout"]

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _board: Node = null
var _game: Node = null

var _felled := 0
var _exit_connected := false

## `combat.json`'s `player_quick.lunge`: how close the harness closes before
## it starts throwing punches. See `_load_attack_ranges()`.
var _engage_distance := 3.6
var _combat_cfg_cache: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return
	_load_attack_ranges()

	_clear_the_slate()
	# The first Halda conversation is covered as data by test_tournament. This
	# bracket smoke starts just after that briefing so its first rung can keep
	# exercising the incomplete-team refusal and every fought round after it.
	(_game.get("progression") as RefCounted).call("set_flag", "opening:tournament_registered")
	await _ensure_ally()
	_reduce_the_party_to_the_ally()
	_stand_in_the_clear_spot()

	if not await _a_small_party_is_told_the_tournament_is_closed():
		_report()
		return
	if not await _an_untrained_party_is_told_what_to_go_and_do():
		_report()
		return
	if not await _a_ready_party_is_offered_the_sign_up():
		_report()
		return
	if not await _signing_up_enters_the_draw():
		_report()
		return
	if not await _a_lost_round_can_be_retried():
		_report()
		return

	for entry: Variant in TOURNAMENT.rounds():
		if not await _fight_and_win(entry as Dictionary):
			_report()
			return

	_the_champion_holds_the_saddle_pattern()
	if not await _the_marshal_congratulates_the_champion():
		_report()
		return
	await _the_champions_line_pays_nothing_twice()

	_report()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_board = _world.get_node_or_null(^"Tournament")
	_game = root.get_node_or_null(^"/root/Game")
	if _player == null or _rig == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the player, camera rig, combat manager, director or dialogue panel")
		return false
	if _board == null:
		_fail("the world stood up no Tournament node; there is no bracket board in the field")
		return false
	if _game == null:
		_fail("no Game autoload; there is nobody to enter the tournament")
		return false
	return true


## How close this harness gets before it starts swinging.
##
## Deliberately the LUNGE, not the range, and the harness deliberately does
## not decide whether a swing is in reach -- the fight does. Two rounds of
## this file stalled on that distinction:
##
## * the first version closed to a hard-coded 2.0m before it would attack,
##   which is tighter than `player_quick.range` (2.6);
## * the second read `player_quick.range` and still deadlocked at 2.9m
##   against the tournament final's Meadowhart, because
##   `combat_manager.gd::_with_reach_for_the_bodies()` RAISES a move's
##   effective range to `(mine + theirs) * body_clearance + 0.5` for large
##   bodies. A big creature spaces itself further out AND reaches further,
##   so the flat number in the config is a floor, not the answer -- and the
##   swing the harness refused to throw would have landed.
##
## So the rule is now: close to within lunge distance, then swing whenever an
## attack is off cooldown and let the fight judge it. Every iteration either
## hits or approaches, and the harness holds no opinion the game can
## contradict.
func _load_attack_ranges() -> void:
	var file := FileAccess.open(COMBAT_CONFIG, FileAccess.READ)
	if file == null:
		_fail("combat.json is missing; the harness has no reach to drive to")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("combat.json is not a JSON object")
		return
	var cfg := parsed as Dictionary
	var quick: Dictionary = cfg.get("player_quick", {})
	_engage_distance = maxf(
		float(quick.get("lunge", 3.6)),
		float(quick.get("range", 2.6)))


## How far this pairing can actually hit, measured the way the GAME measures it.
##
## `_engage_distance` is read from combat.json's `player_quick` alone (lunge 3.6 /
## range 2.6) and so is a constant. The game's reach is not: `combat_manager.gd::
## _with_reach_for_the_bodies` grows the player's range with the bodies in the
## fight -- `(mine + theirs) * enemy.body_clearance + 0.5` -- and
## `wild_creature.gd::_spaced_config` grows the enemy's the same way, for the
## reason its own comment gives: a creature spaced further out than it can reach
## "whiffs forever".
##
## VIS-MAKE raised `body_clearance` 1.8 -> 2.75 to stop the combatants
## interpenetrating (four blind rounds: "a Bramblebun is embedded in the
## Terrapup's face"). That is correct and the game handles it -- both sides' reach
## grew with it. This harness did not, so it stood at 4.2m with a ready attack
## refusing to use it, walked forward into a spacing floor that pushed back, and
## reported a stall the game would never show a player:
##
##   Quarter-final stalled: 901 frames without the opponent losing HP --
##   4.2m away, quick_ready=true charged_ready=false committed=false
##
## Intermittent because it depends on which species are drawn: only pairings
## whose spaced distance exceeds 3.6m could trip it.
func _reach_for(ally: Node3D, opponent: Node3D) -> float:
	var mine := 0.5
	var theirs := 0.5
	if ally.has_method("body_radius"):
		mine = float(ally.call("body_radius"))
	if opponent.has_method("body_radius"):
		theirs = float(opponent.call("body_radius"))
	var clearance: float = float(_combat_config().get("enemy", {}).get("body_clearance", 1.35))
	return maxf(_engage_distance, (mine + theirs) * clearance + 0.5)


func _combat_config() -> Dictionary:
	if not _combat_cfg_cache.is_empty():
		return _combat_cfg_cache
	var file := FileAccess.open("res://data/config/combat.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_combat_cfg_cache = parsed as Dictionary
	return _combat_cfg_cache


func _clear_the_slate() -> void:
	var progression: RefCounted = _game.get("progression")
	for flag: String in FLAGS_TO_CLEAR:
		progression.call("set_flag", flag, false)


func _ensure_ally() -> void:
	if _director.call("ally_instance") != null:
		return
	await _director.call("adopt_starter", TEAM_SPECIES[0])


## Down to exactly one creature: the one the director is already piloting.
##
## The party is emptied and the ALLY INSTANCE put back rather than simply
## trimmed, because the playground seeds a party of its own and the director
## holds a reference to whichever instance it adopted. Clearing the party
## without restoring that instance leaves the fight piloting a creature the
## party does not contain, which is not a state the game can reach and not a
## state worth testing.
func _reduce_the_party_to_the_ally() -> void:
	var party: RefCounted = _game.get("party")
	var ally: RefCounted = _director.call("ally_instance")
	party.call("clear")
	if ally != null:
		party.call("add", ally)
	else:
		_fail("no ally creature after adopting a starter; there is nobody to fight with")


func _stand_in_the_clear_spot() -> void:
	var y := float(_world.call("ground_height_at", CLEAR_SPOT.x, CLEAR_SPOT.y)) + 1.0
	_player.global_position = Vector3(CLEAR_SPOT.x, y, CLEAR_SPOT.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", 0.0)


## --- 1: too few creatures ------------------------------------------------------

func _a_small_party_is_told_the_tournament_is_closed() -> bool:
	# One creature: the state a player who has just been given their starter is
	# genuinely in, and the first thing Halda ever answers.
	await _let_the_board_poll()
	var progression: RefCounted = _game.get("progression")
	if bool(progression.call("has", "tournament_team_ready")):
		_fail("a party of %d creatures wrote tournament_team_ready; the entry condition is not being applied" % int((_game.get("party") as RefCounted).call("size")))
		return false
	return _marshal_says("tournament_halda_closed", "a party too small to enter")


## --- 2: enough bodies, not enough training -------------------------------------

func _an_untrained_party_is_told_what_to_go_and_do() -> bool:
	_fill_the_party()
	await _let_the_board_poll()
	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", "tournament_team_ready")):
		_fail("a party of %d did not write tournament_team_ready, which the marshal's train branch depends on" % TOURNAMENT.required_party_size())
		return false
	if bool(progression.call("has", "tournament_training_ready")):
		_fail("a party of level-1 creatures wrote tournament_training_ready; the level threshold is not being applied")
		return false
	return _marshal_says("tournament_halda_train", "a team that is not trained yet")


## --- 3: a qualifying party -----------------------------------------------------

func _a_ready_party_is_offered_the_sign_up() -> bool:
	_raise_the_party_to(TOURNAMENT.required_level())
	await _let_the_board_poll()
	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", "tournament_training_ready")):
		_fail("a party of %d creatures at level %d did not write tournament_training_ready" % [
			TOURNAMENT.required_party_size(), TOURNAMENT.required_level()])
		return false

	# RG19-spec/D68. Levelled is not the same as ready: the entrants have to
	# be rested, fed and happy, and a team that has only been raised is none
	# of the three.
	if bool(progression.call("has", "tournament_condition_ready")):
		_fail("a team that has never slept, eaten or been cared for wrote tournament_condition_ready")
		return false
	if not _marshal_says("tournament_halda_condition", "a levelled team in poor condition"):
		return false
	var report := TOURNAMENT.readiness_report(_game.get("party"))
	if report.is_empty():
		_fail("the marshal refused the team but the readiness report names nothing to fix")
		return false
	print("condition: refused, and the report says -> %s" % report[0])

	await _bring_the_team_into_condition()
	if not bool(progression.call("has", "tournament_condition_ready")):
		_fail("a rested, fed and happy team still did not write tournament_condition_ready: %s"
			% str(TOURNAMENT.readiness_report(_game.get("party"))))
		return false
	# The camp/bed/recovery path is exercised by Gate A. This bracket harness
	# stages those durable completion flags after proving the live five-creature
	# condition poll, then continues with the tournament's own sign-up and fights.
	for flag: String in ["home_built", "creature_bed_built", "player_slept_at_home"]:
		progression.call("set_flag", flag)
	return _marshal_says("tournament_halda_signup", "a team that qualifies")


## Feed and rest the team the way a player does: real food through
## `creature_condition.feed()` and a real completed night through the same
## `Game.complete_creature_bed_rests()` the player's own bed calls.
func _bring_the_team_into_condition() -> void:
	var party: RefCounted = _game.get("party")
	var cfg: Dictionary = CONDITION.config()
	var food: Dictionary = {}
	var items: RefCounted = _game.get("items")
	if items != null:
		food = (items.call("definition", "berries") as Dictionary).get("creature_food", {})
	if food.is_empty():
		_fail("berries carry no creature_food block; there is nothing to feed the team")
		return
	var rested := 0
	for i in int(party.call("size")):
		var creature: RefCounted = party.call("at", i)
		if creature == null:
			continue
		# Feed until full, the same call the backpack makes per berry.
		for _bite in 12:
			if not bool(CONDITION.feed(creature, cfg, food).get("accepted", false)):
				break
		# The night in the bed, through the same call
		# `Game.complete_creature_bed_rests()` makes when the player sleeps.
		#
		# Deliberately NOT by setting `resting` on the party and calling that
		# method: `creature_instance.gd` says the bed system owns that flag and
		# party.gd only respects it, and setting it on a creature that is
		# DEPLOYED in the world -- which the ally is, in this test -- leaves
		# the director holding a body it has been told is asleep in a bed
		# somewhere. The first version of this helper did exactly that and the
		# next fight jammed with the piloted creature permanently mid-commit
		# (`quick_ready=false charged_ready=false` for 901 frames at 1.4m).
		# The bed's own end-to-end path is Gate A's to prove
		# (`smoke_gate_a_rest_torch.gd`); this file needs the CONDITION a night
		# produces, not a pretend bed.
		CONDITION.note_rest_completed(creature, cfg)
		rested += 1
	_game.get("party").set("revision", int(_game.get("party").get("revision")) + 1)
	await _let_the_board_poll()
	print("condition: fed the team and rested them -- %d creature(s) ready" % rested)


## --- 4: signing up -------------------------------------------------------------

func _signing_up_enters_the_draw() -> bool:
	var progression: RefCounted = _game.get("progression")
	var before := TOURNAMENT.status_line(progression)
	await _play("tournament_halda_signup")
	if not bool(progression.call("has", "tournament_entered")):
		_fail("Halda's sign-up conversation played but tournament_entered was never set")
		return false
	await _let_the_board_poll()
	var after := TOURNAMENT.status_line(progression)
	if after == before:
		_fail("the board still reads '%s' after signing up; the bracket does not track the player" % after)
		return false
	print("signed up: the board went from '%s' to '%s'" % [before, after])
	return true


## --- 5: losing, and being allowed to come back ---------------------------------
##
## The owner's rule is that a loss costs the fight and nothing else. Proven the
## only way it can honestly be proven: by losing one.

func _a_lost_round_can_be_retried() -> bool:
	var spec := TOURNAMENT.round_spec("quarter")
	var conversation := str(spec.get("conversation", ""))
	var won_flag := str(spec.get("won_flag", ""))
	if not await _open_the_round(spec):
		return false

	# Drive nothing and hand the opponent the win: the piloted creature is put
	# on its last sliver of HP and left standing there. This is a REAL loss
	# through the ordinary damage path, not a call to `_begin_resolve`.
	var frames := 0
	while bool(_director.call("trainer_battle_active")) and frames < LOSS_FRAME_LIMIT:
		frames += 1
		var creature: RefCounted = _manager.call("active_creature")
		if creature != null and not bool(creature.get("fainted")):
			creature.set("hp", 1.0)
		await physics_frame
	if frames >= LOSS_FRAME_LIMIT:
		_fail("the quarter-final never resolved when the player stood still for %d frames" % LOSS_FRAME_LIMIT)
		return false
	for i in 60:
		await physics_frame

	var progression: RefCounted = _game.get("progression")
	if bool(progression.call("has", won_flag)):
		_fail("the quarter-final was LOST but '%s' was set anyway" % won_flag)
		return false
	if not _marshal_says(conversation, "a round that was lost"):
		return false
	print("loss: the quarter-final is still on offer, and '%s' is still unset" % won_flag)

	# "After healing your creatures" is the other half of the owner's rule --
	# and RG19-spec/D68 means a knocked-out creature also lost its rest, so
	# getting back into the ring is healing AND caring for them.
	_heal_the_party()
	await _bring_the_team_into_condition()
	return true


## --- 6-7: fight each round for real, and check the payout ----------------------

func _fight_and_win(spec: Dictionary) -> bool:
	var label := str(spec.get("label", "?"))
	var trainer_id := str(spec.get("trainer", ""))
	var won_flag := str(spec.get("won_flag", ""))
	var trainer := TRAINERS.trainer(trainer_id)
	if trainer.is_empty():
		_fail("%s names trainer '%s', which trainers.json does not define" % [label, trainer_id])
		return false

	var coins_before := _coins()
	if not await _open_the_round(spec):
		return false

	var team_size: int = TRAINERS.team_of(trainer).size()
	var felled_before := _felled
	var frames := 0
	# Stall detection. A fight that stops making progress -- nobody losing HP,
	# nobody closing distance -- must fail with a DIAGNOSIS rather than by
	# silently burning the frame ceiling, which is what the first version of
	# this file did and which says nothing about why. Progress is "the
	# opponent took damage, or somebody was felled": either resets the clock.
	var last_opponent_hp := INF
	var felled_at_last_progress := _felled
	var stalled := 0
	while bool(_director.call("trainer_battle_active")) and frames < ROUND_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			# Between rounds of the same trainer, or the beat before their next
			# creature steps up. Not progress, but not a stall either -- the
			# director's own clock is running.
			stalled += 1
			if stalled > STALL_FRAMES:
				_fail("%s stalled: no fight running and no progress for %d frames (battle still active against '%s', %d of %d felled)" % [
					label, stalled, str(_director.call("trainer_battle_id")), _felled - felled_before, team_size])
				return false
			await physics_frame
			continue

		# The harness is not here to prove the player can out-fight a level-11
		# Meadowhart with a stand-in team; it is here to prove the BRACKET
		# runs. Topping the piloted creature back up is the same allowance
		# smoke_village_trainer.gd makes, for the same reason.
		var creature: RefCounted = _manager.call("active_creature")
		if creature != null and creature.hp_fraction() < 0.5:
			creature.hp = creature.max_hp

		# Ask the FIGHT which body it is fighting. `find_child` returns the
		# first name match in tree order, which is not the same thing: on the
		# round after a loss the previous round's body can still be in the
		# tree awaiting free, and this loop then aimed the camera, measured
		# its engage distance and walked the ally toward a corpse while the
		# live opponent stood somewhere else entirely -- an intermittent
		# stall, at full enemy HP, that reported itself as the piloted
		# creature being stuck mid-commit.
		var opponent: Node3D = _manager.call("enemy_body") as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			stalled += 1
			if stalled > STALL_FRAMES:
				_fail("%s stalled: a fight is running but %s for %d frames" % [
					label,
					"the opponent's body is missing" if opponent == null else "the ally has no body on the field",
					stalled])
				return false
			await physics_frame
			continue

		# Progress, or the lack of it.
		var enemy: RefCounted = _manager.call("enemy")
		var enemy_hp: float = float(enemy.get("hp")) if enemy != null else INF
		if enemy_hp < last_opponent_hp or _felled > felled_at_last_progress:
			last_opponent_hp = enemy_hp
			felled_at_last_progress = _felled
			stalled = 0
		else:
			stalled += 1
			if stalled > STALL_FRAMES:
				# `quick_ready=false charged_ready=false` alone cannot tell a
				# creature rooted mid-commit from one that is merely on
				# cooldown, and that ambiguity cost a whole diagnosis pass
				# once already. Name the state machine directly.
				var piloted: RefCounted = _manager.call("active_creature")
				_fail(("%s stalled: %d frames without the opponent losing HP -- %.1f HP left, %.1fm away, "
					+ "quick_ready=%s charged_ready=%s committed=%s manager_state=%s piloted=%s "
					+ "piloted_hp=%s fainted=%s resting=%s, %d of %d felled") % [
					label, stalled, enemy_hp,
					ally.global_position.distance_to(opponent.global_position),
					str(_manager.call("quick_ready")), str(_manager.call("charged_ready")),
					str(_manager.call("player_is_committed")), str(_manager.get("state")),
					str(piloted.get("species_id")) if piloted != null else "<none>",
					str(piloted.get("hp")) if piloted != null else "-",
					str(piloted.get("fainted")) if piloted != null else "-",
					str(piloted.get("resting")) if piloted != null else "-",
					_felled - felled_before, team_size])
				return false

		var to := opponent.global_position - ally.global_position
		to.y = 0.0
		_rig.set("yaw", atan2(-to.x, -to.z))
		# Attack when the GAME says the swing would reach, not when an
		# invented constant says so. The first version of this loop closed to
		# a hard-coded 2.0m before it would throw a punch, which is TIGHTER
		# than `combat.json`'s own `player_quick.range` (2.6) and tighter than
		# the enemy AI's `preferred_range` (2.1) -- so against a trainer whose
		# creature holds its spacing, the harness stood at 2.6m with both
		# attacks charged and refused to use either, closing nothing and
		# hitting nothing until the round's frame ceiling ran out. That is
		# what the stall report above was built to catch, and it caught it on
		# the tournament final.
		var distance := to.length()
		# STALL BREAKER. Closing is the first choice, but it must not be the ONLY
		# one. `player_quick.lunge` is 3.6m: the attack CARRIES the fighter
		# forward, so at a standoff a ready swing is how you close, not something
		# to save until after you have closed. The harness stood at 4.2m with
		# `quick_ready=true` and walked into a spacing floor that pushed back for
		# 901 frames, which is a deadlock no player would sit in -- they would
		# swing. So once pushing has stopped making progress, swing.
		#
		# Kept behind the stall counter rather than applied always, so the normal
		# path is still "close, then hit", and this only fires in the state that
		# was previously unrecoverable.
		if stalled > 120 and bool(_manager.call("quick_ready")):
			await _press("combat_quick")
		elif distance > _reach_for(ally, opponent):
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("charged_ready")):
			await _press("combat_charged")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
		else:
			# Nothing is off cooldown: keep the pressure on rather than
			# standing still, which also closes any remaining gap.
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")

	if frames >= ROUND_FRAME_LIMIT:
		_fail("%s never resolved after %d action frames" % [label, ROUND_FRAME_LIMIT])
		return false
	for i in 60:
		await physics_frame

	var felled := _felled - felled_before
	if felled < team_size:
		_fail("%s ended with only %d of %s's %d creatures beaten" % [
			label, felled, str(spec.get("opponent", "?")), team_size])
		return false

	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", won_flag)):
		_fail("%s was won but '%s' was never set" % [label, won_flag])
		return false

	var paid := _coins() - coins_before
	var owed := TRAINERS.reward_coins(trainer)
	if paid != owed:
		_fail("%s paid %d coins; its authored reward is %d" % [label, paid, owed])
		return false

	await _let_the_board_poll()
	print("%s: won in %d action frames, %d creatures felled, %d coins paid, board now reads '%s'" % [
		label, frames, felled, paid, TOURNAMENT.status_line(progression)])
	return true


## --- 8-9: the prize, and the steady state --------------------------------------

func _the_champion_holds_the_saddle_pattern() -> void:
	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", "recipe_saddle")):
		_fail("the tournament was won but 'recipe_saddle' was never granted")
		return
	if not bool(_game.call("recipe_known", "saddle")):
		_fail("'recipe_saddle' is set but the saddle recipe still does not read as known")
		return
	print("prize: the saddle pattern is granted and the recipe reads as known")


func _the_marshal_congratulates_the_champion() -> bool:
	return _marshal_says("tournament_halda_champion", "the champion")


func _the_champions_line_pays_nothing_twice() -> void:
	var coins_before := _coins()
	await _play("tournament_halda_champion")
	for i in 30:
		await physics_frame
	if bool(_director.call("trainer_battle_active")):
		_fail("greeting the champion's marshal started another fight; the bracket is farmable")
		return
	var paid := _coins() - coins_before
	if paid != 0:
		_fail("greeting Halda again after winning paid another %d coins" % paid)
		return
	print("steady state: the champion's line pays nothing and starts nothing")


## --- driving --------------------------------------------------------------------

## Which conversation the marshal's own `greeting_when` ladder picks right now,
## checked through `village_npcs.greeting_for()` — the production selector, not
## a copy of its rules.
func _marshal_says(expected: String, situation: String) -> bool:
	var progression: RefCounted = _game.get("progression")
	var chosen := VILLAGE_NPCS.greeting_for(_villager(TOURNAMENT.marshal_name()), progression)
	if chosen != expected:
		_fail("with %s, greeting %s should offer '%s'; got '%s'" % [
			situation, TOURNAMENT.marshal_name(), expected, chosen])
		return false
	print("branch: %s -> %s" % [situation, chosen])
	return true


## Play the round's conversation and confirm it actually opened that round's
## fight against that round's trainer.
func _open_the_round(spec: Dictionary) -> bool:
	var conversation := str(spec.get("conversation", ""))
	var trainer_id := str(spec.get("trainer", ""))
	await _play(conversation)
	# `sequence_director.gd::_maybe_start_battle()` fires the frame AFTER the
	# dialogue box closes — the same deferred-start contract every villager
	# challenge uses.
	for i in 10:
		await process_frame
	if not bool(_director.call("trainer_battle_active")):
		_fail("'%s' closed but no tournament battle started" % conversation)
		return false
	if str(_director.call("trainer_battle_id")) != trainer_id:
		_fail("'%s' started a battle against '%s' rather than '%s'" % [
			conversation, str(_director.call("trainer_battle_id")), trainer_id])
		return false
	if not _exit_connected:
		_manager.connect("exited", func(outcome: String) -> void:
			if outcome == "won":
				_felled += 1)
		_exit_connected = true
	return true


func _play(conversation_id: String) -> void:
	if not bool(_panel.call("start", conversation_id)):
		_fail("the dialogue panel refused to start '%s'" % conversation_id)
		return
	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await process_frame
		_panel.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 64:
		_fail("'%s' never closed" % conversation_id)


## The board writes its entry flags from `_process`, on the same polling idiom
## every other flag-reading node here uses. A few frames is all it needs, and
## waiting for them is what makes this test drive the real node rather than
## calling its rule directly.
func _let_the_board_poll() -> void:
	for i in 10:
		await process_frame


## Catch up to the authored entry size, at level 1 -- bodies, not training.
## Species are cycled rather than indexed off the party's current size, so this
## keeps working whatever the starter turned out to be and whatever
## `min_party_size` is tuned to next.
func _fill_the_party() -> void:
	var party: RefCounted = _game.get("party")
	var i := 0
	while int(party.call("size")) < TOURNAMENT.required_party_size() and i < 16:
		var species := TEAM_SPECIES[i % TEAM_SPECIES.size()]
		var creature: RefCounted = _game.call("make_creature", species)
		if creature != null:
			party.call("add", creature)
		i += 1
	if int(party.call("size")) < TOURNAMENT.required_party_size():
		_fail("could not build a party of %d; got %d" % [
			TOURNAMENT.required_party_size(), int(party.call("size"))])


func _raise_the_party_to(level: int) -> void:
	var cfg: Dictionary = PROGRESSION.config()
	var party: RefCounted = _game.get("party")
	for i in int(party.call("size")):
		var creature: RefCounted = party.call("at", i)
		if creature != null:
			creature.call("set_level", level, cfg)
			creature.call("heal_fully")
	party.set("revision", int(party.get("revision")) + 1)


func _heal_the_party() -> void:
	var party: RefCounted = _game.get("party")
	for i in int(party.call("size")):
		var creature: RefCounted = party.call("at", i)
		if creature != null:
			creature.call("heal_fully")
	party.set("revision", int(party.get("revision")) + 1)


func _coins() -> int:
	var inventory: RefCounted = _game.get("inventory")
	return int(inventory.call("count", "coin")) if inventory != null else 0


func _villager(who: String) -> Dictionary:
	var file := FileAccess.open(VILLAGERS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == who:
			return entry as Dictionary
	return {}


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("smoke: OK — the tournament can be entered, lost, retried, fought through all three rounds and won, once.")
		quit(0)
	else:
		for line in _failures:
			print("smoke FAIL: %s" % line)
		quit(1)
