extends SceneTree

## SE25/SE27, end to end: can the relay captain be beaten, and does beating
## him actually free the captive?
##
##   godot --headless --path . --script tests/smoke_relay.gd
##
## `tests/test_trainers_data.gd` proves the four relay entries are well-formed
## and `tests/test_dialogue_runner.gd` proves the rescue conversation grants
## the Gear once and names no legendary. Neither of those boots a world. This
## is the chain that only exists once everybody is standing on Terrain3D:
##
##   1. the captain is standing at the relay site, where relay_site.json puts
##      him, with the captive BEHIND him — the rescue cannot be walked to
##      without the fight
##   2. before the fight, greeting the captive opens her held line and grants
##      nothing at all
##   3. the captain's team is fought down and `relay_captain_defeated` is set
##   4. greeting her now opens the rescue, which puts `mill_bridge_gear` in
##      the satchel and sets `captive_rescued`
##   5. she stops standing at the relay
##   6. and the same person is standing in the VILLAGE, on changed dialogue,
##      in a square that was built before any of this happened (SG46, §14)
##
## `tests/smoke_trainer_battle.gd` owns the trainer-battle rules themselves
## (sequential send-out, the catching refusal, the unfarmable reward); this
## file deliberately does not re-test them. It drives the real input actions
## for the same reason that one does.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const CHARACTER_IDENTITY := preload("res://scripts/save/character_identity.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const CAPTAIN_ID := "relay_captain"
const CAPTAIN_FLAG := "relay_captain_defeated"
const CAPTIVE_NAME := "Sela"
const RESCUE_FLAG := "captive_rescued"
const GEAR_ID := "mill_bridge_gear"

const SETTLE_FRAMES := 300
## Three creatures at levels 11-12, so a longer ceiling than the two-creature
## practice battle's. Still a ceiling: a director that never resolves must fail
## rather than hang.
const BATTLE_FRAME_LIMIT := 12000

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
var _arbiter: Node = null
var _captain: Node3D = null
var _spec: Dictionary = {}
var _opponents_felled := 0
var _rescue_only := false
var _activated_id := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_rescue_only = OS.get_cmdline_user_args().has("--rescue-only")
	_spec = TRAINERS.trainer(CAPTAIN_ID)
	if _spec.is_empty():
		_fail("trainers.json has no trainer '%s'" % CAPTAIN_ID)
		_report()
		return

	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("no Game autoload before relay world boot")
		_report()
		return
	if _rescue_only:
		# Match the title screen's real new-game order: identity first, then the
		# in-place run reset, then the world scene.  The rescue fixture deliberately
		# skips the already-covered captain battle and declares its earned flag.
		var local: Object = game.get("local")
		local.set("character_id", CHARACTER_IDENTITY.mint())
		local.set("display_name", "Relay Rescue Smoke")
		local.set("chosen_character", "trainer")
		game.set("save_system", SAVE_GAME.new("user://smoke_relay_rescue/"))
		game.call("reset_for_new_game")
		game.get("progression").call("set_flag", CAPTAIN_FLAG)
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	if _rescue_only:
		current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	_the_captive_is_behind_the_captain()
	if _rescue_only:
		await _rescue_only_flow()
		_report()
		return
	await _the_captive_cannot_be_freed_yet()

	_stand_in_front_of(_captain, float(_spec.get("facing_deg", 0.0)))
	await _challenge()
	if not bool(_manager.call("is_fighting")):
		_fail("challenging the captain never started a fight; nothing below this was tested")
		_report()
		return
	await _fight_the_whole_team()
	_the_captain_is_recorded_as_beaten()

	await _free_the_captive()
	_the_gear_is_in_the_satchel()
	await _she_is_no_longer_at_the_relay()
	_she_is_in_the_village_saying_something_new()
	_report()


## The opening decides which creature the player gets and this test is not the
## opening. Levelled up to the captain's own band afterwards: this file is
## about the rescue chain, and a starter grinding a level-12 team down over
## twelve thousand frames tests the encounter director's patience, not SE27.
## Same "wiring, not balance" call `smoke_trainer_battle.gd` makes when it
## heals the player's creature mid-fight.
func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null:
		return
	if director.call("ally_instance") == null:
		await director.call("adopt_starter", "terrapup")
	var ally: RefCounted = director.call("ally_instance")
	if ally != null:
		var progression_config: Dictionary = load("res://scripts/creatures/progression.gd").config()
		ally.call("set_level", 16, progression_config)
		ally.set("hp", float(ally.get("max_hp")))


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_arbiter = get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null or _manager == null or _director == null \
			or _panel == null or _arbiter == null:
		_fail("the scene is missing the player, camera rig, combat manager, director, dialogue panel or interaction arbiter")
		return false
	_arbiter.connect("activated", _on_provider_activated)

	var trainers := _world.get_node_or_null(^"Trainers")
	if trainers == null:
		_fail("the world built no Trainers node")
		return false
	_captain = trainers.call("body_for", CAPTAIN_ID) as Node3D
	if _captain == null and not _rescue_only:
		_fail("the relay captain was never stood up in the world")
		return false

	# A body placed before Terrain3D built its collision sits at the origin
	# under the terrain, where everything downstream still "passes" against
	# somebody the player could never have walked to.
	if _captain != null:
		var at: Array = _spec.get("position", [])
		var wanted := Vector2(float(at[0]), float(at[1]))
		var got := Vector2(_captain.global_position.x, _captain.global_position.z)
		if got.distance_to(wanted) > 1.0:
			_fail("the captain is at %.0f, %.0f but trainers.json puts him at %.0f, %.0f" % [
				got.x, got.y, wanted.x, wanted.y])
			return false
		print("captain standing at %.0f, %.0f" % [got.x, got.y])

	if _captive_body() == null:
		_fail("nobody named '%s' is standing at the relay; the rescue has no subject" % CAPTIVE_NAME)
		return false
	if _progression() == null:
		_fail("no Game autoload; there is no flag store to record any of this against")
		return false
	if bool(_progression().call("has", CAPTAIN_FLAG)) != _rescue_only:
		_fail("'%s' must match the declared rescue-only fixture (%s)" % [CAPTAIN_FLAG, str(_rescue_only)])
		return false

	_manager.connect("exited", func(outcome: String) -> void:
		if outcome == "won":
			_opponents_felled += 1)
	return true


func _relay_npcs() -> Node:
	return _world.get_node_or_null(^"RelayNPCs")


func _village_npcs() -> Node:
	return _world.get_node_or_null(^"VillageNPCs")


func _captive_body() -> Node3D:
	var relay := _relay_npcs()
	return relay.get_node_or_null(NodePath(CAPTIVE_NAME)) as Node3D if relay != null else null


func _progression() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


func _inventory() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("inventory") if game != null else null


## The geography IS the gate here. There is no locked door at the relay and
## there should not be one: the captain simply stands between the road and the
## captive, and `relay_site.json` says so in words. This checks the words are
## true of the placed bodies — she is further along the approach bearing than
## he is, and not so far that she is somewhere else entirely.
func _the_captive_is_behind_the_captain() -> void:
	var her := _captive_body()
	if her == null or _captain == null:
		return
	var bearing := Vector2(0.565, -0.826)  # quarry -> stronghold, old_quarry.json
	var him := Vector2(_captain.global_position.x, _captain.global_position.z)
	var hers := Vector2(her.global_position.x, her.global_position.z)
	var along := (hers - him).dot(bearing)
	if along <= 0.0:
		_fail("the captive is not past the captain on the approach bearing (%.1fm); the fight can be walked around" % along)
	elif along > 20.0:
		_fail("the captive is %.1fm past the captain; that is a different place, not the far end of one site" % along)
	else:
		print("captive stands %.1fm past the captain on the approach bearing" % along)


## §32 and SE27's gate: before the captain falls she has nothing to give.
## Greeting her must open her HELD line, and the satchel must be untouched by
## it — a `give:` effect on the wrong branch would hand out the Gear from the
## far side of a fight the player has not had.
func _the_captive_cannot_be_freed_yet() -> void:
	var before := int(_inventory().call("count", GEAR_ID))
	await _greet(_captive_body())
	if bool(_progression().call("has", RESCUE_FLAG)):
		_fail("greeting the captive before the captain was beaten rescued her anyway")
	var after := int(_inventory().call("count", GEAR_ID))
	if after != before:
		_fail("greeting the held captive granted %d %s" % [after - before, GEAR_ID])
	else:
		print("held captive greeted: nothing granted, as intended")


func _stand_in_front_of(who: Node3D, facing_deg: float) -> void:
	var facing := deg_to_rad(facing_deg)
	var spot := who.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.6
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := who.global_position - _player.global_position
	to.y = 0.0
	_aim_camera_along(to)


func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


## This smoke discloses a near-site fixture rather than claiming the earned
## kilometres between rescue locations. Seed on supported ground using the
## live body's world facing; ordinary movement still has to win its exact
## provider below.
func _seed_near_npc(who: Node3D) -> void:
	var facing := who.global_transform.basis.z
	facing.y = 0.0
	if facing.length_squared() < 0.01:
		facing = Vector3.FORWARD
	facing = facing.normalized()
	var spot := who.global_position + facing * 2.6
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	_aim_camera_along(who.global_position - spot)


## Move with ordinary input until this exact provider owns the actionable
## interaction, then activate it once. Relocated NPCs cannot inherit a stale
## fixed offset from their former site.
func _approach_prompt(prompt: Node3D) -> bool:
	if not is_instance_valid(prompt):
		Input.action_release("move_forward")
		_fail("the exact live interaction target is missing")
		return false
	for i in 1800:
		if not is_instance_valid(prompt):
			Input.action_release("move_forward")
			_fail("the interaction target disappeared during its ordinary approach")
			return false
		var winner: Dictionary = _arbiter.call("winner") as Dictionary
		if bool(prompt.get("enabled")) and _arbiter.call("winning_provider") == prompt \
				and bool(winner.get("actionable", false)):
			Input.action_release("move_forward")
			_player.velocity = Vector3.ZERO
			return true
		var to := prompt.global_position - _player.global_position
		to.y = 0.0
		_aim_camera_along(to)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	_fail("the exact live prompt never won an actionable offer during ordinary movement")
	return false


func _press_prompt(prompt: Node3D) -> bool:
	if not await _approach_prompt(prompt):
		return false
	_activated_id = 0
	var expected := prompt.get_instance_id()
	await _press("interact")
	if _activated_id != expected:
		_fail("physical Interact activated a different provider than the exact offered target")
		return false
	return true


## Approach the exact provider, press it once, then advance only dialogue that
## is actually open, one press per line.
func _greet(who: Node3D) -> void:
	if who == null:
		_fail("nobody to greet")
		return
	_seed_near_npc(who)
	var prompt := who.get_node_or_null(^"Interactable") as Node3D
	if not await _press_prompt(prompt):
		return
	for i in 90:
		if bool(_panel.call("is_open")):
			break
		await physics_frame
	if not bool(_panel.call("is_open")):
		_fail("the exact provider for '%s' opened no dialogue" % who.name)
		return
	for i in 64:
		if not bool(_panel.call("is_open")):
			break
		await _press("interact")
		for n in 6:
			await physics_frame
	if bool(_panel.call("is_open")):
		_fail("dialogue with '%s' did not close within its line budget" % who.name)
	# The panel's effects are drained by sequence_director.gd on its own
	# frames; give it several after the box closes.
	for i in 30:
		await physics_frame


func _challenge() -> void:
	for i in 60:
		await physics_frame
	for i in 900:
		if bool(_manager.call("is_fighting")):
			break
		if bool(_panel.call("is_open")) or i == 0:
			await _press("interact")
			for n in 8:
				await physics_frame
			continue
		await physics_frame


## Pilot the captain's whole team down. Heals the player's creature when it
## gets low, for the reason smoke_combat.gd and smoke_trainer_battle.gd both
## already do: this is a wiring test.
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
		_aim_camera_along(to)
		var reach := maxf(float(_manager.call("combat_move_reach", "quick")),
			float(_manager.call("combat_move_reach", "charged")))
		if to.length() > reach:
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
		_fail("the captain's battle never resolved after %d action frames" % BATTLE_FRAME_LIMIT)
		return
	print("captain beaten after %d action frames; %d of %d creatures felled" % [
		frames, _opponents_felled, team_size])
	if _opponents_felled < team_size:
		_fail("the fight ended with only %d of %d of the captain's creatures beaten" % [
			_opponents_felled, team_size])
	for i in 180:
		await physics_frame


## Fixture-only rescue path.  The captain defeat is declared because the normal
## path above already proves that battle; this path isolates sequence ordering,
## inventory-capacity refusal, persistence, and the real mill gate.
func _rescue_only_flow() -> void:
	var inventory := _inventory()
	var progression := _progression()
	var her := _captive_body()
	if her == null:
		_fail("rescue-only fixture has no Sela after declaring captain defeat")
		return

	# A non-stackable axe fills the actual 24-slot satchel without inventing a
	# fixture item or bypassing Inventory.add().
	var remainder := int(inventory.call("add", "axe", int(inventory.call("slot_count"))))
	if remainder != 0 or not bool(inventory.call("is_full")):
		_fail("rescue-only fixture could not fill the 24-slot satchel (remainder %d, used %d)" % [
			remainder, int(inventory.call("used_slots"))])
		return
	await _greet(her)
	if bool(progression.call("has", RESCUE_FLAG)) or int(inventory.call("count", GEAR_ID)) != 0 \
			or int(inventory.call("count", "axe")) != 24:
		_fail("full satchel rescue was not refused atomically (flag=%s gear=%d axe=%d)" % [
			str(progression.call("has", RESCUE_FLAG)), int(inventory.call("count", GEAR_ID)),
			int(inventory.call("count", "axe"))])
	else:
		print("full 24-slot satchel: Sela stayed and no Gear/rescue flag was published")

	# Use the production save/load boundary for the refused state when available.
	var game := root.get_node_or_null(^"/root/Game")
	if game != null and bool(game.call("save_game", 0)):
		# Destroy the in-memory refusal state before loading; a successful reload
		# must restore the saved full axe satchel while the rescue stays refused.
		inventory.call("remove", "axe", int(inventory.call("count", "axe")))
		if int(inventory.call("count", "axe")) != 0:
			_fail("disk witness failed to clear the in-memory axe satchel")
			return
		if not bool(game.call("load_game", 0)):
			_fail("refused rescue state could not reload through Game.load_game")
		else:
			inventory = _inventory()
			progression = _progression()
			if bool(progression.call("has", RESCUE_FLAG)) or int(inventory.call("count", "axe")) != 24 \
					or int(inventory.call("count", GEAR_ID)) != 0:
				_fail("reload changed the refused rescue state")
			her = _captive_body()
	else:
		_fail("refused rescue checkpoint could not save through Game.save_game")

	if her == null:
		_fail("Sela disappeared before the retry after refused-state reload")
		return
	if not bool(inventory.call("remove", "axe", 1)):
		_fail("rescue-only fixture could not free one satchel slot")
		return
	await _greet(her)
	if not bool(_progression().call("has", RESCUE_FLAG)):
		_fail("freeing one slot did not allow the real Sela rescue")
		return
	if int(_inventory().call("count", GEAR_ID)) != 1:
		_fail("successful rescue did not grant exactly one Gear into the freed slot")
	else:
		print("one freed slot: Sela rescue granted exactly one Gear")
	await _she_is_no_longer_at_the_relay()

	# The repeat conversation is now unreachable at the relay; the body has moved
	# through the existing village NPC refresh path, so the same Gear cannot recur.
	if _captive_body() != null:
		_fail("Sela remained at the relay after successful rescue")
	var village_sela := _village_npcs().get_node_or_null(NodePath(CAPTIVE_NAME)) if _village_npcs() != null else null
	if village_sela == null:
		_fail("Sela did not appear in the village after successful rescue")
	else:
		var gear_before_repeat := int(_inventory().call("count", GEAR_ID))
		await _greet(village_sela)
		if int(_inventory().call("count", GEAR_ID)) != gear_before_repeat:
			_fail("re-greeting rescued Sela granted duplicate Gear")
		else:
			print("village re-greeting did not repeat the rescue reward")

	var crossing := _world.get_node_or_null(^"MillCrossing")
	var prompt := crossing.get_node_or_null(^"Interactable") if crossing != null else null
	if crossing == null or prompt == null:
		_fail("world has no authored MillCrossing/Interactable to exercise the Gear gate")
		return
	var gate_before := bool(crossing.call("is_open"))
	if gate_before:
		_fail("MillCrossing was already open before consuming the rescue Gear")
		return
	# Seed from the crossing's authored route direction, not global Z. Ordinary
	# movement below still has to make the exact gate provider win.
	var near: Vector2 = crossing.call("near_point", 9.9)
	var stand := Vector3(near.x, 0.0, near.y)
	stand.y = float(_world.call("ground_height_at", stand.x, stand.z)) + 1.0
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	if not await _press_prompt(prompt):
		return
	for i in 60:
		if bool(crossing.call("is_open")):
			break
		await physics_frame
	if not bool(crossing.call("is_open")) or not bool(_progression().call("has", "mill_crossing_restored")):
		_fail("MillCrossing did not open through its actual interactable/item_gate path")
	elif int(_inventory().call("count", GEAR_ID)) != 0:
		_fail("MillCrossing did not consume exactly one rescue Gear")
	else:
		print("MillCrossing opened through the real item gate and consumed one Gear")


func _the_captain_is_recorded_as_beaten() -> void:
	if not bool(_progression().call("has", CAPTAIN_FLAG)):
		_fail("the captain was beaten but '%s' was never set; SE27 waits on that flag forever" % CAPTAIN_FLAG)
	else:
		print("'%s' set" % CAPTAIN_FLAG)


func _free_the_captive() -> void:
	var her := _captive_body()
	if her == null:
		_fail("the captive vanished before she could be freed")
		return
	await _greet(her)
	if not bool(_progression().call("has", RESCUE_FLAG)):
		_fail("the rescue conversation ran but '%s' was never set" % RESCUE_FLAG)
	else:
		print("'%s' set" % RESCUE_FLAG)


func _the_gear_is_in_the_satchel() -> void:
	var count := int(_inventory().call("count", GEAR_ID))
	if count != 1:
		_fail("the rescue should leave exactly one %s in the satchel; found %d" % [GEAR_ID, count])
	else:
		print("%s in the satchel" % GEAR_ID)


func _she_is_no_longer_at_the_relay() -> void:
	for i in 180:
		await physics_frame
		if _captive_body() == null:
			break
	if _captive_body() != null:
		_fail("the captive is still standing at the relay after being rescued")
	else:
		print("the relay is empty of her")


## SG46 / spec §14. The square was built before the rescue happened, so this
## is the real check: she has to appear in an already-built village without a
## reload, and say something she was not saying before.
func _she_is_in_the_village_saying_something_new() -> void:
	var village := _village_npcs()
	if village == null:
		_fail("the world built no VillageNPCs node")
		return
	var her := village.get_node_or_null(NodePath(CAPTIVE_NAME))
	if her == null:
		_fail("'%s' never appeared in the village after being rescued" % CAPTIVE_NAME)
		return
	print("'%s' is standing in the village" % CAPTIVE_NAME)

	var spec := _village_spec(CAPTIVE_NAME)
	if spec.is_empty():
		_fail("village_npcs.json has no entry named '%s'" % CAPTIVE_NAME)
		return
	var now := VILLAGE_NPCS.greeting_for(spec, _progression())
	var before := str(spec.get("greeting", ""))
	if now == before:
		_fail("the rescued villager still opens her pre-rescue greeting ('%s')" % now)
	else:
		print("her greeting changed: '%s' -> '%s'" % [before, now])


func _village_spec(who: String) -> Dictionary:
	var file := FileAccess.open("res://data/config/village_npcs.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
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


func _on_provider_activated(provider: Object) -> void:
	_activated_id = provider.get_instance_id() if is_instance_valid(provider) else 0


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		if _rescue_only:
			print("relay rescue: OK — full-bag retry, disk restore, relocation and Gear gate")
			quit(0)
			return
		print("relay: OK — the captain is beaten, the captive is freed, the Gear is carried, and she is in the village saying something new.")
		quit(0)
		return
	for line in _failures:
		print("relay FAIL: %s" % line)
	quit(1)
