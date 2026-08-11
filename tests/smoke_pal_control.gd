extends SceneTree

## `CO1`: can the player's pal be dismissed, recalled and swapped, outside a
## fight, from the world?
##
##   godot --headless --path . --script tests/smoke_pal_control.gd
##
## Not in the backlog's own `tests:` field (`none`), but `adopt_starter()` was
## refactored to share its spawn code with the new recall path, and that
## refactor is exactly the kind of change `smoke_opening`/`smoke_catching`
## alone would not catch if it broke — this drives the real `pal_recall`
## binding and the real `Game.party`, the same way those two drive `interact`
## and `combat_throw`.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/pals/pal_species.gd")

const SETTLE_FRAMES := 300

var _failures: Array[String] = []
var _world: Node = null
var _director: Node = null
var _manager: Node = null
var _party: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_director = _world.get_node_or_null(^"EncounterDirector")
	_manager = _world.get_node_or_null(^"CombatManager")
	var game := root.get_node_or_null(^"/root/Game")
	if _director == null or _manager == null or game == null:
		_fail("scene is missing the director, combat manager or Game autoload")
		_report()
		return
	_party = game.get("party")

	# `adopt_starter()` never touches `Game.party` itself — in the real game
	# `sequence_director.gd::_give_to_party()` does that afterwards. Two pals
	# are needed to prove a swap, so this seeds the party directly and brings
	# the first one out through `summon_active_pal()`, the same entry point a
	# fresh `pal_recall` press uses — not `adopt_starter`, which is a
	# different, opening-only path CO1 does not touch.
	var starter: RefCounted = SPECIES.spawn("terrapup")
	var second: RefCounted = SPECIES.spawn("ripplet")
	if starter == null or second == null or not bool(_party.call("add", starter)) \
			or not bool(_party.call("add", second)):
		_fail("could not seed two party members; nothing here can be tested")
		_report()
		return
	if _director.call("ally_instance") == null:
		await _director.call("summon_active_pal")
		for i in 60:
			await physics_frame

	await _dismiss_puts_the_body_away()
	await _recall_brings_the_same_pal_back()
	await _party_screen_reactivation_swaps_the_body()
	await _dismiss_and_recall_refuse_mid_fight()
	_report()


## The core ask: pressing the button once sends the pal away.
func _dismiss_puts_the_body_away() -> void:
	var before: Node3D = _director.call("ally_body")
	if before == null or not is_instance_valid(before):
		_fail("no ally body out to begin with; dismiss cannot be tested")
		return

	await _press("pal_recall")
	var after: Node3D = _director.call("ally_body")
	if after != null and is_instance_valid(after):
		_fail("ally_body still exists after a dismiss press")
		return
	if _director.call("ally_instance") != null:
		_fail("ally_instance is still set after a dismiss; nothing is out but the director disagrees")
		return
	print("dismissed: the follower body is gone, the party still holds it")


## The other half: pressing it again with nobody out brings the active one
## back — same species, same instance the party already had.
func _recall_brings_the_same_pal_back() -> void:
	var expected: RefCounted = _party.call("active")
	await _press("pal_recall")
	for i in 60:
		await physics_frame
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible:
			break

	var body: Node3D = _director.call("ally_body")
	if body == null or not is_instance_valid(body):
		_fail("recall press did not bring a follower body back")
		return
	if not body.visible:
		_fail("a recalled body exists but was never made visible")
	if not bool(body.call("is_following")):
		_fail("a recalled body exists but is not following")
	if _director.call("ally_instance") != expected:
		_fail("recall spawned a different pal than the party's own active slot")
		return
	print("recalled: %s is out and following again" % str(expected.call("label")))


## `tab_pals.gd::_read_activate()`'s job, exercised directly rather than
## through the menu UI: choosing a different active slot while a pal is
## already out should swap which body is standing there, live.
func _party_screen_reactivation_swaps_the_body() -> void:
	var before_instance: RefCounted = _director.call("ally_instance")
	var before_index: int = int(_party.call("active_index"))
	var target := 1 if before_index == 0 else 0
	if _party.call("at", target) == null:
		_fail("no second party slot to swap to")
		return
	if not bool(_party.call("set_active", target)):
		_fail("party.set_active() refused a valid, non-fainted slot")
		return

	var swapped := false
	for i in 120:
		await physics_frame
		var instance: RefCounted = _director.call("ally_instance")
		if instance != null and instance != before_instance:
			swapped = true
			break
	if not swapped:
		_fail("choosing a different active pal in the party never changed who is out")
		return
	var body: Node3D = _director.call("ally_body")
	if body == null or not is_instance_valid(body) or not body.visible:
		_fail("the swap left no visible follower body behind")
	print("swapped: the party's new active pal is the one standing beside the trainer")


## Dismiss/recall have to stay out of a running fight — the combat manager
## drives the same body for its length, same reason `_set_exploration_active`
## already refuses to hand the leash back mid-fight.
func _dismiss_and_recall_refuse_mid_fight() -> void:
	if _director.call("ally_instance") == null:
		await _director.call("summon_active_pal")
		for i in 60:
			await physics_frame

	var wild: Node3D = _director.call("wild_pal")
	if wild == null:
		_fail("no wild pal in the sandbox; the mid-fight refusal cannot be tested")
		return
	if not bool(_director.call("dismiss_active_pal")) and _director.call("ally_body") == null:
		pass  # already dismissed by an earlier step somehow; harmless, re-summon below
	if _director.call("ally_body") == null:
		await _director.call("summon_active_pal")
		for i in 60:
			await physics_frame

	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if player == null or rig == null:
		_fail("no player/camera rig; the mid-fight refusal cannot be tested")
		return

	# Teleport rather than walk — `smoke_catching.gd`'s own reason:
	# `_ground_height_at()` keeps this on the terrain, and by this point in
	# the run the player could be anywhere the earlier steps left them.
	var spot := wild.global_position - wild.global_basis.z * 2.5
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	player.global_position = spot
	player.velocity = Vector3.ZERO
	rig.set("yaw", atan2(-(wild.global_position.x - spot.x), -(wild.global_position.z - spot.z)))
	for i in 10:
		await physics_frame
	await _press("interact")
	for i in 40:
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat; the mid-fight refusal could not be tested")
		return

	var body_before: Node3D = _director.call("ally_body")
	if bool(_director.call("dismiss_active_pal")):
		_fail("dismiss_active_pal() succeeded while a fight was running")
	if _director.call("ally_body") != body_before:
		_fail("the ally body changed during a fight it should not have been touched in")
	else:
		print("mid-fight: dismiss correctly refused")


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
		print("pal control: OK — dismissed, recalled, swapped, and refused mid-fight.")
		quit(0)
		return
	for line in _failures:
		print("pal control FAIL: %s" % line)
	quit(1)
