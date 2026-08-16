extends SceneTree

## R8.3 / SG40 / R8.4 — the chapter's climax, end to end in a real world.
##
##   godot --headless --path . --script tests/smoke_boss.gd
##
## `tests/test_trainers_data.gd` proves the Warden's TABLE (a full team, levels
## above the captains, the flag R8.4 gates on) and `tests/test_dialogue_runner.gd`
## proves the WORDS (the reveal exists here and nowhere earlier, he argues
## rather than gloats). Neither of them shows the half that only exists once
## somebody is standing on Terrain3D, and that half is what this file drives:
##
##   - the Warden is REACHABLE: a real body, on real ground, offering a real
##     challenge prompt the director agrees can be taken up
##   - the reveal is on the threshold and readable BEFORE him — and the
##     legendary chamber's lever is refused until he has fallen, which is the
##     one place §28's order could otherwise be walked around
##   - the fight RUNS and can be WON, through the ordinary trainer substrate
##   - the legendary is freed, `legendary_freed` is set, and it is set ONCE
##   - its voluntary join reaches the party
##   - and with a full belt it does NOT quietly vanish: R4.10's release
##     ceremony opens on `Game.pending_catch` instead, which is the seam that
##     system already ships (see tests/smoke_release.gd)
##
## The two belt cases cannot both be true of one boot, so the second half
## re-runs the ending against a full party after the first has resolved.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

const WARDEN_ID := "warden_aldis"
const FREED_FLAG := "legendary_freed"
const WARDEN_FLAG := "defeated_warden"

const SETTLE_FRAMES := 300
## A hard ceiling on the boss fight, so a director that never resolves fails
## instead of hanging CI. Five creatures back to back, generously.
const BATTLE_FRAME_LIMIT := 9000
## Frames the climax's own stage machine gets to walk §28's order.
const SEQUENCE_FRAMES := 900

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _climax: Node = null
var _spec: Dictionary = {}
var _flag_writes: int = 0


func _init() -> void:
	_run()


func _run() -> void:
	_spec = TRAINERS.trainer(WARDEN_ID)
	if _spec.is_empty():
		print("FAIL: trainers.json has no '%s'; there is no boss fight" % WARDEN_ID)
		quit(1)
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	_the_warden_is_reachable()
	_the_reveal_is_on_the_threshold()
	_the_chamber_is_shut_until_he_falls()

	await _challenge_him()
	await _fight_him()
	_he_stays_beaten()

	await _free_the_legendary()
	_the_legendary_joined_the_party()

	await _a_full_belt_opens_the_ceremony_instead()
	_report()


## The opening decides which creature the player gets and this test is not the
## opening, so it gets one directly — the same call `sequence_director.gd`
## makes once a name is confirmed, and the same shortcut smoke_combat.gd and
## smoke_trainer_battle.gd both take for the same reason.
func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_climax = _world.get_node_or_null(^"StrongholdClimax")
	if _game == null or _player == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the Game autoload, the player, the manager, the director or the panel")
		return false
	if _climax == null:
		_fail("the world built no StrongholdClimax node; the chapter has no ending")
		return false
	if _director.call("ally_instance") == null:
		_fail("the player has no creature to fight with")
		return false
	return true


## R8.3, first claim: he is somewhere a player can get to, and the game agrees
## he can be fought. A boss standing at the world origin under the terrain
## "passes" every downstream check while being unreachable, so the position is
## asserted against the mark the climax resolved rather than assumed.
func _the_warden_is_reachable() -> void:
	var body: Node3D = _climax.call("warden_body") as Node3D
	if body == null:
		_fail("the Warden was never stood up in the world")
		return
	if body.global_position.length() < 1.0:
		_fail("the Warden is at the world origin; his mark did not resolve")
	if not bool(_director.call("can_challenge", _spec)):
		_fail("the director refuses to let the Warden be challenged on a fresh boot")
	print("the Warden stands at %.0f, %.0f and can be challenged" % [
		body.global_position.x, body.global_position.z])


## SG40. The readout is on the threshold of the arena — the player reads what
## is at the far end of the cables BEFORE the Warden opens his mouth, which is
## §28's order and not a preference.
func _the_reveal_is_on_the_threshold() -> void:
	var readout := _world.find_child("TetherReadout", true, false) as Node3D
	if readout == null:
		_fail("no Tether readout in the world; SG40's reveal has nothing to be read from")
		return
	var prompt := readout.get_node_or_null(^"ReadoutPrompt")
	if prompt == null or not bool(prompt.get("enabled")):
		_fail("the readout offers no prompt; the reveal is unreachable")
		return
	var body: Node3D = _climax.call("warden_body") as Node3D
	if body != null:
		var to_warden := Vector2(body.global_position.x, body.global_position.z)
		var here := Vector2(readout.global_position.x, readout.global_position.z)
		if here.distance_to(to_warden) < 1.0:
			_fail("the readout is standing on top of the Warden; it is meant to be met first")
	print("the reveal readout is standing and readable before the fight")


## R8.4's gate, and the single place §28's order is enforced in the world: the
## lever is refused while the Warden is still on his feet.
func _the_chamber_is_shut_until_he_falls() -> void:
	var prompt := _world.find_child("MachinePrompt", true, false)
	if prompt == null:
		_fail("no machine control in the Legendary Chamber; the legendary can never be freed")
		return
	if bool(prompt.get("enabled")):
		_fail("the tether machine can be shut down with the Warden still standing; §28's order is walkable around")
	if bool(_progression().call("has", FREED_FLAG)):
		_fail("'%s' is already set on a fresh boot" % FREED_FLAG)
	print("the machine refuses to be touched before the Warden falls")


## Walk up and take up the challenge, through the real prompt and the real
## conversation — the same route `smoke_trainer_battle.gd` drives, because the
## claim under test is that the boss uses it unchanged.
func _challenge_him() -> void:
	var body: Node3D = _climax.call("warden_body") as Node3D
	if body == null:
		return
	var facing := body.rotation.y
	var spot := body.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.6
	var ground := float(_world.call("ground_height_at", spot.x, spot.z))
	if not is_nan(ground):
		spot.y = ground + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := body.global_position - _player.global_position
	to.y = 0.0
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.set("yaw", atan2(-to.x, -to.z))
	for i in 60:
		await physics_frame

	var prompt := str(_director.call("prompt"))
	if not prompt.contains(str(_spec.get("name", ""))):
		_fail("standing in front of the Warden offered no challenge prompt (got '%s')" % prompt)

	var presses := 0
	for i in 1400:
		if bool(_manager.call("is_fighting")):
			break
		if presses == 0 or bool(_panel.call("is_open")):
			await _press("interact")
			presses += 1
			for n in 6:
				await physics_frame
			continue
		await physics_frame

	if not bool(_manager.call("is_fighting")):
		_fail("the Warden's challenge never opened a fight")
		return
	if presses < 2:
		_fail("the fight started without his dialogue being read; §28 puts the warning before the battle")
	if str(_director.call("trainer_battle_id")) != WARDEN_ID:
		_fail("the running battle is '%s', not the Warden's" % str(_director.call("trainer_battle_id")))
	print("the challenge took %d presses and opened the boss fight" % presses)


## Fight the whole team down. The player's creature is topped up between
## strikes and the opponent's HP is pulled low so a level-1 starter can finish
## a level-20 ace inside a CI budget: this test is about WIRING, not balance,
## the same allowance `smoke_trainer_battle.gd` makes for the same reason. Every
## faint, every send-out and every payout still goes through the real code.
func _fight_him() -> void:
	var team_size: int = TRAINERS.team_of(_spec).size()
	var frames := 0
	var sent := 1
	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			if bool(_player.call("locomotion_enabled")):
				_fail("the player could walk away between the Warden's creatures")
			await physics_frame
			continue

		var mine: RefCounted = _manager.call("active_creature")
		if mine != null:
			mine.hp = mine.max_hp

		var opponent := _world.find_child("TrainerCreature_%s_*" % WARDEN_ID, true, false) as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue
		var theirs: RefCounted = opponent.get("instance")
		if theirs != null and theirs.hp > 6.0:
			theirs.hp = 6.0

		var to := opponent.global_position - ally.global_position
		to.y = 0.0
		var rig := _world.get_node_or_null(^"CameraRig") as Node3D
		if rig != null:
			rig.set("yaw", atan2(-to.x, -to.z))
		if to.length() > 2.0:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
		else:
			await physics_frame

	if bool(_director.call("trainer_battle_active")):
		_fail("the boss fight never resolved inside %d frames" % BATTLE_FRAME_LIMIT)
		return
	if not bool(_progression().call("has", WARDEN_FLAG)):
		_fail("the Warden was fought to the end but '%s' was never set" % WARDEN_FLAG)
		return
	print("the boss fight ran and was won: %d creatures, %d frames" % [team_size, frames])
	if not bool(_player.call("locomotion_enabled")):
		_fail("exploration never came back after the boss fight")


## A beaten boss is beaten for good — the same rule every trainer in the table
## keeps, and worth asserting on the one fight the whole chapter ends at.
func _he_stays_beaten() -> void:
	if bool(_director.call("can_challenge", _spec)):
		_fail("the Warden can be fought a second time; the chapter's last fight is farmable")


## R8.4, in §28's order. The lever is now live; pulling it frees the legendary,
## which then offers to join, and the machinery fails last.
func _free_the_legendary() -> void:
	var prompt := _world.find_child("MachinePrompt", true, false)
	if prompt == null:
		_fail("the machine control vanished")
		return
	for i in 30:
		await physics_frame
	if not bool(prompt.get("enabled")):
		_fail("the machine is still refused with the Warden beaten; the legendary can never be freed")
		return

	_watch_the_flag()
	prompt.call("interaction_activate")

	for i in SEQUENCE_FRAMES:
		await physics_frame
		if bool(_panel.call("is_open")):
			await _press("interact")
			continue
		if bool(_progression().call("has", FREED_FLAG)) and _game.get("pending_catch") == null:
			# Give the stage machine a few frames past the freeing to finish
			# the join and the failure beats.
			for n in 90:
				await physics_frame
				if bool(_panel.call("is_open")):
					await _press("interact")
			break

	if not bool(_progression().call("has", FREED_FLAG)):
		_fail("the lever was pulled but '%s' was never set; SG44's world event would never fire" % FREED_FLAG)
		return
	if _flag_writes > 1:
		_fail("'%s' was set %d times; the world event would fire more than once" % [FREED_FLAG, _flag_writes])
	if not bool(_climax.call("legendary_is_freed")):
		_fail("the climax does not consider the legendary freed")
	var body: Node3D = _climax.call("legendary_body") as Node3D
	if body == null:
		_fail("there is no legendary body in the chamber")
	elif body.get_node_or_null(^"ContainmentVFX") != null:
		_fail("the containment cage is still standing around a freed legendary")
	print("the legendary is freed and '%s' is set once" % FREED_FLAG)


## §28 step 3: it VOLUNTARILY joins. On a belt with room, that means it is
## simply on the belt — no orb was thrown and nothing was caught.
func _the_legendary_joined_the_party() -> void:
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("no party to join")
		return
	var species := ""
	for member: Variant in (party.call("members") as Array):
		if str((member as RefCounted).get("species_id")) == "veridian":
			species = "veridian"
	if species == "":
		_fail("the freed legendary never reached the party; §28's voluntary join did not happen")
		return
	if int(party.call("size")) > 5:
		_fail("the party holds %d; the five-creature limit is a hard rule" % int(party.call("size")))
	print("the legendary joined the party voluntarily")


## The other half of §28 step 4, and the one that matters most: with the belt
## already full the legendary must NOT be dropped and must NOT be a sixth. It
## goes onto `Game.pending_catch`, which is R4.10's ceremony seam — the same
## seam `tests/smoke_release.gd` drives from the other side.
func _a_full_belt_opens_the_ceremony_instead() -> void:
	var party: RefCounted = _game.get("party")
	if party == null:
		return
	while not bool(party.call("is_full")):
		var filler: RefCounted = _game.call("make_creature", "terrapup", "Filler")
		if filler == null:
			_fail("could not fill the belt for the full-belt case")
			return
		party.call("add", filler)

	# Re-run the ending's hand-over with a full belt. The stage machine has
	# already finished, so this drives the same private step it drives.
	_climax.call("_hand_over_the_legendary")
	for i in 30:
		await process_frame

	if int(party.call("size")) != 5:
		_fail("the full-belt hand-over changed the party to %d; it must never add a sixth" % int(party.call("size")))
		return
	if _game.get("pending_catch") == null:
		_fail("with a full belt the legendary went nowhere; R4.10's release ceremony was never offered")
		return
	var menu: CanvasLayer = _game.call("menu")
	if menu != null:
		for i in 90:
			await process_frame
			if bool(menu.call("is_open")):
				break
		if not bool(menu.call("is_open")):
			_fail("the pending legendary never opened the release ceremony")
			return
	print("a full belt hands the legendary to R4.10's release ceremony instead of dropping it")


func _watch_the_flag() -> void:
	var progression := _progression()
	if progression == null or not progression.has_signal("flag_set"):
		return
	progression.connect("flag_set", func(flag: String) -> void:
		if flag == FREED_FLAG:
			_flag_writes += 1)


func _progression() -> RefCounted:
	return _game.get("progression") as RefCounted if _game != null else null


func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await physics_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("boss smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
