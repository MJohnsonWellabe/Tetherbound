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
var _captain: Node3D = null
var _spec: Dictionary = {}
var _opponents_felled := 0


func _init() -> void:
	_run()


func _run() -> void:
	_spec = TRAINERS.trainer(CAPTAIN_ID)
	if _spec.is_empty():
		_fail("trainers.json has no trainer '%s'" % CAPTAIN_ID)
		_report()
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	_the_captive_is_behind_the_captain()
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
	if _player == null or _rig == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the player, camera rig, combat manager, director or dialogue panel")
		return false

	var trainers := _world.get_node_or_null(^"Trainers")
	if trainers == null:
		_fail("the world built no Trainers node")
		return false
	_captain = trainers.call("body_for", CAPTAIN_ID) as Node3D
	if _captain == null:
		_fail("the relay captain was never stood up in the world")
		return false

	# A body placed before Terrain3D built its collision sits at the origin
	# under the terrain, where everything downstream still "passes" against
	# somebody the player could never have walked to.
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
	if bool(_progression().call("has", CAPTAIN_FLAG)):
		_fail("'%s' is already set on a fresh boot" % CAPTAIN_FLAG)
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
	if her == null:
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


## Walk up to somebody and read whatever they say to the end, one press per
## line, exactly as a player gives it.
func _greet(who: Node3D) -> void:
	if who == null:
		_fail("nobody to greet")
		return
	_stand_in_front_of(who, rad_to_deg(who.rotation.y))
	for i in 60:
		await physics_frame
	var lines := 0
	for i in 40:
		await _press("interact")
		for n in 10:
			await physics_frame
		if bool(_panel.call("is_open")):
			lines += 1
			continue
		if lines > 0:
			break
	if lines == 0:
		_fail("standing in front of '%s' and pressing interact opened nothing" % who.name)
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
		_fail("the captain's battle never resolved after %d action frames" % BATTLE_FRAME_LIMIT)
		return
	print("captain beaten after %d action frames; %d of %d creatures felled" % [
		frames, _opponents_felled, team_size])
	if _opponents_felled < team_size:
		_fail("the fight ended with only %d of %d of the captain's creatures beaten" % [
			_opponents_felled, team_size])
	for i in 180:
		await physics_frame


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


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("relay: OK — the captain is beaten, the captive is freed, the Gear is carried, and she is in the village saying something new.")
		quit(0)
		return
	for line in _failures:
		print("relay FAIL: %s" % line)
	quit(1)
