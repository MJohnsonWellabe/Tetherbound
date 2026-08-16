extends SceneTree

## SC12/SC13. Can a VILLAGER actually be challenged, fought, and become the
## permanent vendor+trainer she is supposed to be afterward?
##
##   godot --headless --path . --script tests/smoke_village_trainer.gd
##
## **Headless, never under xvfb** — docs/HANDOFF.md §10, same as every other
## scene-booting test here.
##
## `tests/smoke_trainer_battle.gd` already proves the WHOLE fight lifecycle —
## prompt, sequential team, orb-throw refusal, defeat flag, reward, XP, no
## rechallenge — for a trainer `trainer_npc.gd` places and prompts itself. What
## is UNIQUE to Mira, Oskar and Tam and unproven anywhere else is the OTHER
## route into that same fight: a villager's ordinary `greeting_when` branch
## selection choosing the challenge conversation, and that conversation's last
## line (`battle:trainer_mira`) reaching `sequence_director.gd`'s NEW `battle:`
## effect rather than `trainer_npc.gd`'s own `_on_challenged` listener. This
## drives exactly that path, end to end, for Mira:
##
##   1. greeting_for() offers her Band-1 challenge once her shop is open
##   2. playing that conversation on the shared panel actually starts a fight
##      against `trainer_mira`'s real table entry
##   3. beating her sets `defeated_mira`
##   4. greeting_for() now offers her permanent BEATEN line, not the challenge
##      again and not her old standing shop branch
##   5. playing THAT conversation still opens the real ShopPanel for real —
##      D39's "the vendor branch survives becoming a trainer" made real, from
##      the villager's own beaten line rather than the branch OF31 wrote

const SCENE := "res://scenes/world/meadows_playground.tscn"
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

const SETTLE_FRAMES := 300
const BATTLE_FRAME_LIMIT := 4000

const TRAINER_ID := "trainer_mira"
const MIRA_FLAG := "mira_shop_open"
const DEFEATED_FLAG := "defeated_mira"
const CHALLENGE_CONVERSATION := "village_mira_challenge"
const BEATEN_CONVERSATION := "village_mira_beaten"

## `practice_trainer`'s own vetted-clear spot (trainers.json's own `_why_here`:
## "12m clear of every structure, villager, harvest node and prop"). Reused
## here rather than inventing a second one, since this test does not care
## where Mira herself stands — it drives the conversation directly on the
## shared panel, the same "walking up is somebody else's test" choice
## `smoke_village_smith.gd` makes — only where the PLAYER stands when the
## fight's fallback spawn (no trainer body passed) puts the opponent in front
## of them.
const CLEAR_SPOT := Vector2(13.0, 9.0)

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _game: Node = null
var _spec: Dictionary = {}

var _opponents_felled := 0


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

	if not _collect_nodes():
		_report()
		return

	await _ensure_ally()
	_stand_in_the_clear_spot()

	var progression: RefCounted = _game.get("progression")
	progression.call("set_flag", MIRA_FLAG)
	progression.call("set_flag", DEFEATED_FLAG, false)

	if not await _greeting_offers_the_challenge():
		_report()
		return
	if not await _the_challenge_starts_a_real_fight():
		_report()
		return
	await _fight_the_whole_team()
	_the_trainer_is_recorded_as_beaten()
	if not await _greeting_now_offers_the_beaten_line():
		_report()
		return
	await _the_beaten_line_still_opens_the_shop()

	_report()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_game = root.get_node_or_null(^"/root/Game")
	if _player == null or _rig == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the player, camera rig, combat manager, director or dialogue panel")
		return false
	if _game == null:
		_fail("no Game autoload; there is nobody to greet or trade with")
		return false
	return true


func _ensure_ally() -> void:
	if _director.call("ally_instance") != null:
		return
	await _director.call("adopt_starter", "terrapup")


func _stand_in_the_clear_spot() -> void:
	var y := float(_world.call("ground_height_at", CLEAR_SPOT.x, CLEAR_SPOT.y)) + 1.0
	_player.global_position = Vector3(CLEAR_SPOT.x, y, CLEAR_SPOT.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", 0.0)


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


## --- 1: the branch selector offers the challenge, not the shop ----------------

func _greeting_offers_the_challenge() -> bool:
	var progression: RefCounted = _game.get("progression")
	var chosen := VILLAGE_NPCS.greeting_for(_villager("Mira"), progression)
	if chosen != CHALLENGE_CONVERSATION:
		_fail("with her shop open and her unbeaten, greeting Mira should offer '%s'; got '%s'" % [
			CHALLENGE_CONVERSATION, chosen])
		return false
	print("branch: shop open, unbeaten -> %s" % chosen)
	return true


## --- 2: playing that conversation on the shared panel starts a real fight -----

func _the_challenge_starts_a_real_fight() -> bool:
	await _play(CHALLENGE_CONVERSATION)
	# `sequence_director.gd::_maybe_start_battle()` fires the frame AFTER the
	# dialogue box closes -- same deferred-start contract trainer_npc.gd uses,
	# proven with a short buffer the same way smoke_village_trade.gd waits for
	# its shop panel to appear.
	for i in 10:
		await process_frame
	if not bool(_director.call("trainer_battle_active")):
		_fail("Mira's challenge conversation closed but no trainer battle started")
		return false
	if str(_director.call("trainer_battle_id")) != TRAINER_ID:
		_fail("a trainer battle started, but against '%s' rather than '%s'" % [
			str(_director.call("trainer_battle_id")), TRAINER_ID])
		return false
	print("battle: '%s' started via the village greeting route, not trainer_npc.gd's own prompt" % TRAINER_ID)
	_manager.connect("exited", func(outcome: String) -> void:
		if outcome == "won":
			_opponents_felled += 1)
	return true


## --- 3: fight it, the same driving loop smoke_trainer_battle.gd uses ----------

func _fight_the_whole_team() -> void:
	var team_size: int = TRAINERS.team_of(_spec).size()
	var frames := 0

	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
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

	if frames >= BATTLE_FRAME_LIMIT:
		_fail("the trainer battle never resolved after %d action frames" % BATTLE_FRAME_LIMIT)
		return
	print("battle over after %d action frames; %d of %d of Mira's creatures felled" % [
		frames, _opponents_felled, team_size])
	if _opponents_felled < team_size:
		_fail("the battle ended with only %d of %d of Mira's creatures beaten" % [_opponents_felled, team_size])

	for i in 60:
		await physics_frame


## --- 4: the defeat flag, and the branch selector's next answer ----------------

func _the_trainer_is_recorded_as_beaten() -> void:
	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", DEFEATED_FLAG)):
		_fail("the battle was won but '%s' was never set" % DEFEATED_FLAG)
	else:
		print("defeat flag '%s' set" % DEFEATED_FLAG)


func _greeting_now_offers_the_beaten_line() -> bool:
	var progression: RefCounted = _game.get("progression")
	var chosen := VILLAGE_NPCS.greeting_for(_villager("Mira"), progression)
	if chosen != BEATEN_CONVERSATION:
		_fail("once beaten, greeting Mira should offer '%s'; got '%s' (still the challenge, or the shop, or her plain greeting)" % [
			BEATEN_CONVERSATION, chosen])
		return false
	print("branch: beaten -> %s" % chosen)
	return true


## --- 5: D39's rule, from the beaten line rather than the old shop branch ------

func _the_beaten_line_still_opens_the_shop() -> void:
	await _play(BEATEN_CONVERSATION)
	for i in 10:
		await process_frame
	var shop := root.get_node_or_null(^"ShopPanel")
	if shop == null:
		_fail("no ShopPanel was built; Mira's beaten line lost the shop: effect she is supposed to carry")
		return
	if not bool(shop.call("is_open")):
		_fail("the store did not open after Mira's beaten line")
	if str(shop.call("vendor_id")) != "mira":
		_fail("the store opened for '%s' rather than mira" % str(shop.call("vendor_id")))
	print("shop: still open for mira, from her BEATEN line")
	shop.call("close")


## --- driving --------------------------------------------------------------------

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
		print("smoke: OK — a villager can be greeted into a challenge, fought, beaten once, and trusted with a shop afterward.")
		quit(0)
	else:
		for line in _failures:
			print("smoke FAIL: %s" % line)
		quit(1)
