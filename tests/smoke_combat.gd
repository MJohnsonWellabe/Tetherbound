extends SceneTree

## Can a whole fight be fought, start to finish, in the real scene?
##
##   godot --headless --path . --script tests/smoke_combat.gd
##
## tests/test_combat_math.gd and tests/test_combat_ai.gd already prove the
## arithmetic and the decision table. This proves the WIRING, which is where M1's
## actual bugs lived: every number was right while the ground was a checkerboard
## and the collision was a 64m bubble.
##
## Combat is piloted (docs/decisions/D07), so the things that can silently break
## are new and physical: the pal has to actually move, the arena has to actually
## hold it, an attack has to be able to miss, and control has to come back.
##
## It drives the real input actions rather than calling the manager's methods, so
## a broken binding fails here rather than on the handheld.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")

## Long enough for the terrain to load, collision to build, and the director to
## place both creatures.
const SETTLE_FRAMES := 240
## A hard ceiling on the fight, so a manager that never resolves fails instead of
## hanging the CI job forever.
const FIGHT_FRAME_LIMIT := 2500

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _misses: int = 0
var _hits_on_enemy: int = 0
var _hits_on_ally: int = 0


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

	await _walk_to_the_wild_pal()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat; nothing below this point was tested")
		_report()
		return

	_ally = _director.call("ally_body") as Node3D
	_check_the_fight_opened()

	await _the_pal_moves_on_the_stick()
	await _the_arena_holds_you_in()
	await _a_swing_at_empty_air_misses()
	await _a_swing_at_the_enemy_connects()
	await _the_enemy_closes_and_hits_back()
	await _fight_to_a_finish()
	await _exploration_is_restored()
	_report()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null or _rig == null:
		_fail("scene is missing the player, the camera rig, the combat manager or the director")
		return false

	_manager.connect("attack_missed", func(_by_player: bool) -> void: _misses += 1)
	_manager.connect("hit_landed", func(on_enemy: bool, _amount: float) -> void:
		if on_enemy:
			_hits_on_enemy += 1
		else:
			_hits_on_ally += 1)

	_wild = _director.call("wild_pal") as Node3D
	if _wild == null:
		_fail("the encounter director never spawned a wild pal")
		return false
	if _director.call("ally_instance") == null:
		_fail("the player has no pal to fight with")
		return false

	# Asserted explicitly, because the failure mode is silent: if the placement
	# raycast runs before Terrain3D has built collision it finds nothing, and the
	# creature sits at the world origin under the terrain. Everything downstream
	# then "passes" against a pal the player could never have walked up to.
	if _wild.global_position.distance_to(_player.global_position) < 4.0:
		_fail("the wild pal spawned on top of the player; it was never placed")
		return false
	print("wild pal at %.0f, %.0f, %.0f" % [
		_wild.global_position.x, _wild.global_position.y, _wild.global_position.z
	])
	return true


## Walk over and stand next to it, rather than teleporting. Reaching the creature
## is part of the encounter and a wild pal spawned somewhere unreachable is a
## real failure.
func _walk_to_the_wild_pal() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1200:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_aim_camera_along(to)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame

	var final := _player.global_position.distance_to(_wild.global_position)
	print("approached to %.1fm (engage range %.1fm)" % [final, engage_range])
	if final > engage_range:
		_fail("could not walk within engage range of the wild pal (got to %.1fm)" % final)


## Point the camera so that "forward" means this direction. Steering through the
## camera rather than by setting positions is deliberate: it is the same path the
## player's stick takes, so a broken planar_basis fails here.
func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _engage() -> void:
	if str(_director.call("prompt")) == "":
		_fail("no engage prompt appeared next to the wild pal")
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	# Wait out flow.input_guard. The button that engages is also the charged
	# attack, and the manager ignores input briefly so one press is not both.
	for i in 30:
		await physics_frame


func _check_the_fight_opened() -> void:
	if bool(_player.call("locomotion_enabled")):
		_fail("the trainer can still walk during a fight")
	if _ally == null or not _ally.visible:
		_fail("the player's pal was never deployed")
		return
	if _manager.call("arena") == null:
		_fail("no arena was opened")

	# The camera is supposed to be on the pal now, not the trainer. Checked by
	# where the rig actually is rather than by reading a private field, so a rig
	# that stores the right target and follows the wrong one still fails.
	var to_pal := _rig.global_position.distance_to(_ally.global_position)
	var to_trainer := _rig.global_position.distance_to(_player.global_position)
	if to_pal > to_trainer:
		_fail("the camera is still following the trainer (%.1fm) not the pal (%.1fm)" % [to_trainer, to_pal])


## The whole point of the change. If the stick does not move the pal, combat is
## still the menu it used to be.
func _the_pal_moves_on_the_stick() -> void:
	var before := _ally.global_position
	var away := _ally.global_position - _wild.global_position
	away.y = 0.0
	_aim_camera_along(away)
	Input.action_press("move_forward")
	for i in 45:
		await physics_frame
		_aim_camera_along(away)
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame

	var travelled := before.distance_to(_ally.global_position)
	print("pal moved %.1fm on the stick" % travelled)
	if travelled < 1.0:
		_fail("the stick moved the pal %.2fm; combat is not actually piloted" % travelled)


## The arena is a soft wall, not a flee trigger. Walking into it must hold you
## inside and must not end the fight.
func _the_arena_holds_you_in() -> void:
	var arena: Node3D = _manager.call("arena") as Node3D
	if arena == null:
		return
	var radius := float(arena.get("radius"))
	var furthest := 0.0

	for leg in [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]:
		_aim_camera_along(leg)
		Input.action_press("move_forward")
		for i in 150:
			await physics_frame
			_aim_camera_along(leg)
			var offset := _ally.global_position - arena.global_position
			offset.y = 0.0
			furthest = maxf(furthest, offset.length())
			if not bool(_manager.call("is_fighting")):
				break
		Input.action_release("move_forward")
		if not bool(_manager.call("is_fighting")):
			break

	print("pushed to %.1fm from the arena centre (radius %.1fm)" % [furthest, radius])
	if not bool(_manager.call("is_fighting")):
		_fail("walking into the arena boundary ended the fight; Run is supposed to be the only way out")
		return
	# A small overshoot is the correction happening after the move, not a leak.
	if furthest > radius + 1.0:
		_fail("the pal reached %.1fm from the centre of an %.1fm arena; the boundary leaks" % [furthest, radius])


## Aimed attacks have to be missable, or aiming is decoration.
func _a_swing_at_empty_air_misses() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var hp_before: float = foe.hp
	var misses_before := _misses

	# Face away from the opponent and swing at nothing.
	var away := _ally.global_position - _wild.global_position
	away.y = 0.0
	_aim_camera_along(away)
	Input.action_press("move_forward")
	for i in 30:
		await physics_frame
		_aim_camera_along(away)
	Input.action_release("move_forward")

	await _press("combat_quick")
	for i in 30:
		await physics_frame

	if foe.hp < hp_before:
		_fail("an attack swung away from the opponent still damaged it")
	if _misses == misses_before:
		_fail("swinging at empty air was not reported as a miss; the player gets no feedback")
	else:
		print("a swing at empty air missed, as it should")


func _a_swing_at_the_enemy_connects() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var pal: RefCounted = _manager.call("active_pal")
	var quick: Dictionary = MATH.config().get("player_quick", {})
	var reach := float(quick.get("range", 2.6))

	# Close the distance under stick control, then swing.
	for i in 400:
		var to := _wild.global_position - _ally.global_position
		to.y = 0.0
		if to.length() <= reach * 0.55:
			break
		_aim_camera_along(to)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")

	var hp_before: float = foe.hp
	var energy_before: float = pal.energy
	await _press("combat_quick")
	for i in 25:
		await physics_frame

	if foe.hp >= hp_before:
		_fail("a quick attack at point-blank range did no damage (%.1f -> %.1f)" % [hp_before, foe.hp])
	else:
		print("quick attack: enemy %.1f -> %.1f hp" % [hp_before, foe.hp])
	# Energy is earned by connecting, not by pressing. That is what ties the
	# charged attack to positioning rather than to button-mashing.
	if pal.energy <= energy_before:
		_fail("a landed quick attack built no energy (%.1f -> %.1f)" % [energy_before, pal.energy])


## Without this the fight is a punching bag with a health bar.
func _the_enemy_closes_and_hits_back() -> void:
	var pal: RefCounted = _manager.call("active_pal")
	var hp_before: float = pal.hp
	var saw_telegraph := false
	var saw_opening := false

	# Stand still and let it come. Long enough for it to close, commit, recover
	# and come again.
	for i in 900:
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			break
		if bool(_manager.call("enemy_is_winding_up")):
			saw_telegraph = true
		elif bool(_manager.call("enemy_is_rooted")):
			saw_opening = true
		if pal.hp < hp_before:
			break

	if pal.hp >= hp_before:
		_fail("the enemy never landed a hit in 15 seconds of standing still")
	else:
		print("enemy dealt damage: ally %.1f -> %.1f hp" % [hp_before, pal.hp])
	if not saw_telegraph:
		_fail("the enemy attacked with no visible wind-up; the fight has no warning")
	if not saw_opening:
		_fail("the enemy was never seen recovering; there is no window to punish")


func _fight_to_a_finish() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var frames := 0
	while bool(_manager.call("is_fighting")) and frames < FIGHT_FRAME_LIMIT:
		var pal: RefCounted = _manager.call("active_pal")
		# Keep the ally alive long enough to win: heal it rather than tune the
		# fight, because this test is about wiring, not balance.
		if pal != null and pal.hp_fraction() < 0.4:
			pal.hp = pal.max_hp

		var to := _wild.global_position - _ally.global_position
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
		frames += 1

	if frames >= FIGHT_FRAME_LIMIT:
		_fail("the fight never resolved after %d action frames" % FIGHT_FRAME_LIMIT)
		return
	if not foe.fainted:
		_fail("combat ended with outcome '%s' but the enemy is still standing" % str(_manager.call("outcome")))
	else:
		print("enemy fainted after %d action frames; outcome '%s'" % [frames, str(_manager.call("outcome"))])
	print("tally: %d hits on the enemy, %d on the ally, %d misses" % [
		_hits_on_enemy, _hits_on_ally, _misses
	])


func _exploration_is_restored() -> void:
	for i in 120:
		await physics_frame

	if not bool(_player.call("locomotion_enabled")):
		_fail("the trainer cannot walk after the fight ended")
	if _ally != null and _ally.visible:
		_fail("the player's pal is still standing in the world after the fight")
	if _manager.call("arena") != null:
		_fail("the arena was never cleaned up")
	if _world.get_node_or_null(^"CombatArena") != null:
		_fail("the arena boundary is still in the scene after the fight")

	var to_trainer := _rig.global_position.distance_to(_player.global_position)
	if to_trainer > 4.0:
		_fail("the camera did not return to the trainer (%.1fm away)" % to_trainer)

	# And you can actually move again.
	var before := _player.global_position
	Input.action_press("move_forward")
	for i in 60:
		await physics_frame
	Input.action_release("move_forward")
	if before.distance_to(_player.global_position) < 1.0:
		_fail("the trainer did not move after the fight; input was not restored")


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
		print("combat: OK — a fight can be entered, piloted, won and left.")
		quit(0)
		return
	for line in _failures:
		print("combat FAIL: %s" % line)
	quit(1)
