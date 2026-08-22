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
##   1. a party too small to enter meets the marshal's CLOSED line, and the two
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

const SETTLE_FRAMES := 300
## A hard ceiling per ROUND, so a director that never resolves one fails
## instead of hanging the CI job forever. Generous: the final is three fights
## back to back plus the beat between each.
const ROUND_FRAME_LIMIT := 9000
## The deliberate loss is a much shorter affair — one creature has to be
## knocked over once — but it still needs a ceiling of its own.
const LOSS_FRAME_LIMIT := 3000

## Every flag this test is allowed to find already set is cleared first, so a
## seeded playground party or a stray autoload state cannot hand the test a
## tournament that is already half-won.
const FLAGS_TO_CLEAR: PackedStringArray = [
	"tournament_team_ready", "tournament_training_ready", "tournament_entered",
	"tournament_quarter_won", "tournament_semi_won", "tournament_won",
	"recipe_saddle",
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

	_clear_the_slate()
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
	return _marshal_says("tournament_halda_signup", "a team that qualifies")


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

	# "After healing your creatures" is the other half of the owner's rule.
	_heal_the_party()
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
	while bool(_director.call("trainer_battle_active")) and frames < ROUND_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			await physics_frame
			continue

		# The harness is not here to prove the player can out-fight a level-11
		# Meadowhart with a stand-in team; it is here to prove the BRACKET
		# runs. Topping the piloted creature back up is the same allowance
		# smoke_village_trainer.gd makes, for the same reason.
		var creature: RefCounted = _manager.call("active_creature")
		if creature != null and creature.hp_fraction() < 0.5:
			creature.hp = creature.max_hp

		var opponent: Node3D = _world.find_child("TrainerCreature_*", true, false) as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue

		var to := opponent.global_position - ally.global_position
		to.y = 0.0
		_rig.set("yaw", atan2(-to.x, -to.z))
		if to.length() > 2.0:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("charged_ready")):
			await _press("combat_charged")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
		else:
			await physics_frame

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
