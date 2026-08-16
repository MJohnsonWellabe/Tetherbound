extends SceneTree

## Can a trainer be challenged, fought through their whole team, and beaten
## once and only once?
##
##   godot --headless --path . --script tests/smoke_trainer_battle.gd
##
## `tests/test_trainers_data.gd` already proves the table: species that exist,
## flags that are unique, conversations that resolve. This proves the WIRING —
## the half that only exists once somebody is standing on Terrain3D:
##
##   - a trainer is placed where trainers.json says, and offers a prompt
##   - the prompt opens a conversation, and the conversation opens a fight
##   - the trainer's SECOND creature comes out when the first one falls, and
##     exploration never comes back in the gap
##   - an orb throw is refused, in words, at the throw itself — a CLAUDE.md
##     hard rule (trainer-owned creatures cannot be caught) that the HUD
##     hiding a button would not enforce
##   - beating the last of them sets the SB9 defeat flag and pays the reward
##     (SC15: coins and items, EXACTLY the authored amounts, once)
##   - the player's creatures gain XP for it
##   - and the trainer cannot be fought a second time, and that second attempt
##     pays out nothing at all -- the reward is not farmable
##
## It drives the real input actions rather than calling the director's
## methods, so a broken binding fails here rather than on the handheld — same
## contract as smoke_combat.gd, whose harness shape this follows.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

## Which trainer this test fights. Read by ID from the table rather than by
## index or position, so SC12/SC13 replacing the placeholder with Mira, Oskar
## and Tam is a data edit plus one constant here, not a rewrite.
const TRAINER_ID := "practice_trainer"

const SETTLE_FRAMES := 300
## A hard ceiling on the whole battle, so a director that never resolves one
## fails instead of hanging the CI job forever. Generous: this is two fights
## back to back plus the beat between them.
const BATTLE_FRAME_LIMIT := 6000

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _trainer: Node3D = null
var _spec: Dictionary = {}

var _refusals: Array[String] = []
var _opponents_felled: int = 0
var _xp_before: Array = []
## SC15: satchel counts for "coin" plus every authored reward item, taken
## BEFORE the challenge opens, so the payout can be checked for the exact
## authored amount rather than merely "some of it landed" -- and so a second,
## refused challenge attempt can be checked for paying nothing at all.
var _reward_before: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	_spec = TRAINERS.trainer(TRAINER_ID)
	if _spec.is_empty():
		_fail("trainers.json has no trainer '%s'; nothing here can run" % TRAINER_ID)
		_report()
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_seed_orbs()
	if not _collect_nodes():
		_report()
		return

	_stand_in_front_of_the_trainer()
	_snapshot_reward_counts()
	await _challenge()
	if not bool(_manager.call("is_fighting")):
		_fail("the challenge never started a fight; nothing below this point was tested")
		_report()
		return

	_the_battle_opened_against_a_trainers_creature()
	await _an_orb_throw_is_refused()
	await _fight_the_whole_team()
	_the_trainer_is_recorded_as_beaten()
	_the_reward_was_paid()
	_the_party_earned_xp()
	await _exploration_is_restored()
	await _the_trainer_cannot_be_fought_again()
	_the_second_attempt_paid_nothing()
	_report()


## The opening decides which creature the player gets and this test is not the
## opening, so it gets one directly — the same call `sequence_director.gd`
## makes once a name is confirmed. Same reasoning as smoke_combat.gd's copy.
func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


## Orbs are satchel items and Grandpa's gift is bypassed here. Seeded on
## purpose: the throw below must be refused because the creature belongs to
## somebody, not because the satchel is empty — those are different refusals
## and only one of them is the rule under test.
func _seed_orbs(count: int = 10) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("no Game autoload; nowhere to put the orbs")
		return
	var inventory: RefCounted = game.get("inventory")
	var short: int = count - int(inventory.call("count", "orb_basic"))
	if short > 0:
		inventory.call("add", "orb_basic", short)


func _progression() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


## SC15: the satchel count for "coin" (if this trainer pays any) and every
## authored reward item, taken before the fight starts. `_the_reward_was_paid`
## and `_the_second_attempt_paid_nothing` both read against this rather than
## an absolute count, because `_seed_orbs()` above already put items in the
## satchel and a trainer could in principle reward one of those same ids.
func _snapshot_reward_counts() -> void:
	var game := root.get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	if inventory == null:
		return
	if TRAINERS.reward_coins(_spec) > 0:
		_reward_before["coin"] = int(inventory.call("count", "coin"))
	for entry: Variant in TRAINERS.reward_items(_spec):
		var id := str((entry as Dictionary).get("id", ""))
		if id != "":
			_reward_before[id] = int(inventory.call("count", id))


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _player == null or _rig == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the player, camera rig, combat manager, director or dialogue panel")
		return false

	var trainers := _world.get_node_or_null(^"Trainers")
	if trainers == null:
		_fail("the world built no Trainers node; trainers.json is not being placed")
		return false
	_trainer = trainers.call("body_for", TRAINER_ID) as Node3D
	if _trainer == null:
		_fail("trainer '%s' was never stood up in the world" % TRAINER_ID)
		return false

	# Asserted explicitly because the failure is silent: a body placed before
	# Terrain3D built its collision sits at the world origin under the terrain,
	# where everything downstream still "passes" against somebody the player
	# could never have walked to.
	var at: Array = _spec.get("position", [])
	var wanted := Vector2(float(at[0]), float(at[1]))
	var got := Vector2(_trainer.global_position.x, _trainer.global_position.z)
	if got.distance_to(wanted) > 1.0:
		_fail("trainer '%s' is at %.0f, %.0f but trainers.json puts them at %.0f, %.0f" % [
			TRAINER_ID, got.x, got.y, wanted.x, wanted.y])
		return false
	print("trainer '%s' standing at %.0f, %.0f" % [TRAINER_ID, got.x, got.y])

	if _director.call("ally_instance") == null:
		_fail("the player has no creature to fight with")
		return false
	if bool(_progression().call("has", str(_spec.get("defeat_flag", "")))):
		_fail("the defeat flag is already set on a fresh boot; the battle would be refused")
		return false

	_manager.connect("catch_refused", func(reason: String) -> void: _refusals.append(reason))
	_manager.connect("exited", func(outcome: String) -> void:
		if outcome == "won":
			_opponents_felled += 1)
	return true


## Put the player in front of the trainer rather than walking the whole
## village. smoke_combat.gd already proves a creature can be walked up to
## across open meadow; what is under test here starts at the prompt.
func _stand_in_front_of_the_trainer() -> void:
	var facing := deg_to_rad(float(_spec.get("facing_deg", 0.0)))
	var spot := _trainer.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.6
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := _trainer.global_position - _player.global_position
	to.y = 0.0
	_aim_camera_along(to)


func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


## Press interact until the challenge conversation has been opened and read to
## the end. One press per line, exactly as a player gives it.
func _challenge() -> void:
	for i in 60:
		await physics_frame

	var prompt := str(_director.call("prompt"))
	if not prompt.contains(str(_spec.get("name", ""))):
		_fail("standing in front of the trainer offered no prompt (got '%s')" % prompt)

	var presses := 0
	for i in 900:
		if bool(_manager.call("is_fighting")):
			break
		if presses == 0 or bool(_panel.call("is_open")):
			await _press("interact")
			presses += 1
			for n in 8:
				await physics_frame
			continue
		await physics_frame

	print("challenge took %d presses; conversation opened and closed" % presses)
	if presses < 2:
		_fail("the battle started without the challenge conversation being read")


func _the_battle_opened_against_a_trainers_creature() -> void:
	if not bool(_director.call("trainer_battle_active")):
		_fail("a fight started but the director does not consider it a trainer battle")
	if str(_director.call("trainer_battle_id")) != TRAINER_ID:
		_fail("the running trainer battle is '%s', not '%s'" % [
			str(_director.call("trainer_battle_id")), TRAINER_ID])
	if bool(_player.call("locomotion_enabled")):
		_fail("the trainer can still walk during a trainer battle")

	var expected: int = TRAINERS.team_of(_spec).size()
	var left: int = int(_director.call("trainer_creatures_left"))
	if left != expected - 1:
		_fail("the trainer sent out one of %d creatures but %d are queued, not %d" % [
			expected, left, expected - 1])

	# Snapshot everyone who is in this fight, before it pays out.
	for member: RefCounted in _fighters():
		_xp_before.append([member, int(member.get("level")), int(member.get("xp"))])


## The hard rule, at the door it is enforced at.
##
## CLAUDE.md: "Trainer-owned creatures cannot be caught." Pressing Throw must
## refuse in words, must not open the aim, and must not spend an orb — the
## enforcement is in `combat_manager._try_throw()`, not in a hidden button, so
## this presses the real action rather than inspecting the HUD.
func _an_orb_throw_is_refused() -> void:
	# Past the fight's input guard, and with the creature between actions.
	for i in 60:
		await physics_frame

	var orbs_before := int(_manager.call("orbs_left"))
	if orbs_before <= 0:
		_fail("the trainer has no orbs; the refusal under test could not be told from an empty satchel")
		return
	var refusals_before := _refusals.size()

	await _press("combat_throw")
	for i in 30:
		await physics_frame

	if bool(_manager.call("is_aiming")):
		_fail("the aim opened on a trainer's creature; catching is supposed to be refused outright")
	if int(_manager.call("orbs_left")) != orbs_before:
		_fail("a refused throw still spent an orb (%d -> %d)" % [orbs_before, int(_manager.call("orbs_left"))])
	if _refusals.size() == refusals_before:
		_fail("pressing Throw at a trainer's creature said nothing at all; a silent refusal reads as a dropped input")
		return

	var reason: String = str(_refusals[_refusals.size() - 1])
	print("throw refused: '%s'" % reason)
	if not reason.to_lower().contains("train"):
		_fail("the refusal ('%s') does not say the creature belongs to a trainer" % reason)


## Pilot the whole team down, one creature after another. Heals the player's
## creature when it gets low: this test is about wiring, not balance, and the
## same choice smoke_combat.gd makes for the same reason.
func _fight_the_whole_team() -> void:
	var team_size: int = TRAINERS.team_of(_spec).size()
	var frames := 0
	var saw_intermission := false

	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			# The beat between their creatures. Exploration must NOT be back:
			# walking away mid-challenge is the bug this window invites.
			saw_intermission = true
			if bool(_player.call("locomotion_enabled")):
				_fail("the player could walk away between the trainer's creatures")
			await physics_frame
			continue

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
		_aim_camera_along(to)
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

	if frames >= BATTLE_FRAME_LIMIT:
		_fail("the trainer battle never resolved after %d action frames" % BATTLE_FRAME_LIMIT)
		return
	print("battle over after %d action frames; %d of the trainer's %d creatures felled" % [
		frames, _opponents_felled, team_size])
	if _opponents_felled < team_size:
		_fail("the battle ended with only %d of %d of the trainer's creatures beaten; the rest were never sent out" % [
			_opponents_felled, team_size])
	if team_size > 1 and not saw_intermission:
		_fail("the trainer's creatures were never seen changing over; the team was not fought sequentially")


func _the_trainer_is_recorded_as_beaten() -> void:
	var flag := str(_spec.get("defeat_flag", ""))
	if not bool(_progression().call("has", flag)):
		_fail("the battle was won but '%s' was never set; nothing remembers it happened" % flag)
	else:
		print("defeat flag '%s' set" % flag)


## Exactly the authored coins and item counts, no more and no less. A delta
## against `_snapshot_reward_counts()`'s baseline rather than an absolute
## floor, because the fight itself spends nothing (no orb was thrown; every
## throw was refused) but a reward item could in principle share an id with
## something already seeded (`_seed_orbs()`) or otherwise already carried.
func _the_reward_was_paid() -> void:
	var game := root.get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory")
	var coins := TRAINERS.reward_coins(_spec)
	if coins > 0:
		var got: int = int(inventory.call("count", "coin")) - int(_reward_before.get("coin", 0))
		if got != coins:
			_fail("the trainer's reward promised %d coin but %d landed in the satchel" % [coins, got])
		else:
			print("reward paid: %d coin" % got)
	for entry: Variant in TRAINERS.reward_items(_spec):
		var id := str((entry as Dictionary).get("id", ""))
		var count := int((entry as Dictionary).get("count", 0))
		var got: int = int(inventory.call("count", id)) - int(_reward_before.get(id, 0))
		if got != count:
			_fail("the trainer's reward promised %d %s but %d landed in the satchel" % [count, id, got])
		else:
			print("reward paid: %d %s" % [got, id])


## The prior test already proves a re-challenge cannot open a second battle
## at all; this proves the reward specifically follows from that -- a
## trainer marked `rechallenge: true` later, or a director regression that
## re-ran `_pay_trainer_reward()` on an already-flagged trainer, would show
## up here as coins or items increasing with no second fight to explain them.
func _the_second_attempt_paid_nothing() -> void:
	var game := root.get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory")
	var coins := TRAINERS.reward_coins(_spec)
	if coins > 0:
		var now: int = int(inventory.call("count", "coin"))
		var expected: int = int(_reward_before.get("coin", 0)) + coins
		if now != expected:
			_fail("the coin count changed after the refused re-challenge (%d -> %d); the reward paid twice" % [
				expected, now])
	for entry: Variant in TRAINERS.reward_items(_spec):
		var id := str((entry as Dictionary).get("id", ""))
		var count := int((entry as Dictionary).get("count", 0))
		var now: int = int(inventory.call("count", id))
		var expected: int = int(_reward_before.get(id, 0)) + count
		if now != expected:
			_fail("the '%s' count changed after the refused re-challenge (%d -> %d); the reward paid twice" % [
				id, expected, now])
	print("re-challenge granted nothing; the reward paid exactly once")


func _the_party_earned_xp() -> void:
	if _xp_before.is_empty():
		_fail("nobody was in the fight to earn anything; the snapshot was empty")
		return
	var earned := false
	for before: Array in _xp_before:
		var member: RefCounted = before[0]
		var level_now := int(member.get("level"))
		var xp_now := int(member.get("xp"))
		if level_now > int(before[1]) or xp_now > int(before[2]):
			earned = true
			print("%s: level %d xp %d -> level %d xp %d" % [
				member.call("label"), int(before[1]), int(before[2]), level_now, xp_now])
	if not earned:
		_fail("nobody who fought gained a single point of XP for beating a trainer")


## Everyone the fight pays: the creature that is out, then the rest of the
## living party behind it. Mirrors `encounter_director._fight_party()` — this
## test drives the real world, and in it the deployed creature is the one the
## opening would have put in the party, so the two lists are the same list.
func _fighters() -> Array[RefCounted]:
	var out: Array[RefCounted] = []
	var ally: RefCounted = _director.call("ally_instance")
	if ally != null:
		out.append(ally)
	var game := root.get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party != null:
		for member: Variant in party.call("members"):
			var creature := member as RefCounted
			if creature != null and creature != ally:
				out.append(creature)
	return out


func _exploration_is_restored() -> void:
	for i in 120:
		await physics_frame
	if not bool(_player.call("locomotion_enabled")):
		_fail("the trainer cannot walk after the battle ended")
	if _manager.call("arena") != null:
		_fail("the arena was never cleaned up")
	if bool(_director.call("trainer_battle_active")):
		_fail("the director still thinks a trainer battle is running")

	# And the bodies go with it: a trainer's creature is not wild and must not
	# be left standing in the meadow to be engaged afterwards.
	for i in 240:
		await physics_frame
		if _world.find_child("TrainerCreature_*", true, false) == null:
			break
	if _world.find_child("TrainerCreature_*", true, false) != null:
		_fail("a trainer's creature is still in the world after the battle")


## Beaten once, and only once. The prompt still works — they are a person, not
## a used-up switch — but pressing it opens their defeated line and no arena.
func _the_trainer_cannot_be_fought_again() -> void:
	var conversation := TRAINERS.conversation_for(_spec, _progression())
	if conversation != str(_spec.get("defeated", "")):
		_fail("a beaten trainer still opens their challenge conversation ('%s')" % conversation)
	if bool(_director.call("can_challenge", _spec)):
		_fail("the director would take a beaten trainer's challenge a second time")

	_stand_in_front_of_the_trainer()
	for i in 60:
		await physics_frame
	for i in 6:
		await _press("interact")
		for n in 20:
			await physics_frame
		if bool(_manager.call("is_fighting")) or bool(_director.call("trainer_battle_active")):
			_fail("a beaten trainer started a second battle")
			return
	print("re-challenge refused; the trainer greets instead")


## Hold for two physics frames before releasing. `is_action_just_pressed` is
## scoped to the frame the press landed in, and pressing between frames can put
## it in the frame that has already run.
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
		print("trainer battle: OK — a trainer can be challenged, fought through their team, beaten once, and not again.")
		quit(0)
		return
	for line in _failures:
		print("trainer battle FAIL: %s" % line)
	quit(1)
