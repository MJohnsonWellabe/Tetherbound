extends SceneTree

## Can a wild pal be caught, and does the cost of trying actually apply?
##
##   godot --headless --path . --script tests/smoke_catching.gd
##
## tests/test_catch_math.gd already proves the odds. This proves the wiring, and
## the wiring is where the design lives: aiming hands control to the trainer and
## leaves your pal undefended, the orb is a real projectile that can miss, and a
## faint ends the opportunity rather than lowering the odds.
##
## It drives the real input actions, so a broken binding fails here rather than
## on the handheld.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")

const SETTLE_FRAMES := 300
## Attempts before giving up on catching a weakened target. With a common
## species at a sliver of health this is far more than the odds require; if it
## runs out, something is wrong with the wiring rather than with the dice.
const MAX_ATTEMPTS := 25

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _refusals: Array[String] = []
var _resolutions: Array[bool] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_leave_the_farmhouse()
	_seed_orbs()
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

	await _aiming_hands_control_to_the_trainer()
	await _aiming_abandons_your_pal()
	await _a_throw_at_the_sky_misses_and_still_costs_an_orb()
	await _a_weakened_pal_can_be_caught()
	await _a_fainted_pal_cannot_be_caught()
	_report()


## `meadows_playground.tscn` now always carries a `SequenceDirector` (R0.9),
## and its `_ready()` unconditionally calls `suspend_default_starter()` in the
## one frame window that exists to call it off — the opening always decides
## which pal the player gets, never the sandbox default. This test is not the
## opening and never drives it, so the encounter director's own
## `default_starter` never spawns here either. Proving catching's WIRING does
## not need the opening's cast; it needs a pal, so this gets one directly,
## the same call `sequence_director.gd` makes once a name is confirmed.
func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


## The opening's staging wakes the player in Grandpa's bed; this test bypasses
## the opening and needs open meadow between it and the wild creatures, not a
## farmhouse wall. Placed near the practice cluster (data/config/spawns.json).
func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return
	var start := Vector3(42.0, 0.0, -52.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO



## Orbs are satchel items now — in the real game Grandpa hands them over in
## the opening, which this test deliberately bypasses. Seed what he would give.
func _seed_orbs(count: int = 15) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("no Game autoload; nowhere to put the orbs")
		return
	var inventory: RefCounted = game.get("inventory")
	var short: int = count - int(inventory.call("count", "orb_basic"))
	if short > 0:
		inventory.call("add", "orb_basic", short)


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null or _rig == null:
		_fail("scene is missing the player, camera rig, combat manager or director")
		return false

	_manager.connect("catch_refused", func(reason: String) -> void: _refusals.append(reason))
	_manager.connect("catch_resolved", func(success: bool, _shakes: int) -> void: _resolutions.append(success))

	_wild = _director.call("wild_pal") as Node3D
	if _wild == null:
		_fail("no wild pal to throw at")
		return false
	if int(_manager.call("orbs_left")) <= 0:
		_fail("the trainer starts with no orbs; nothing here can run")
		return false
	return true


func _walk_to_the_wild_pal() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1500:
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


func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _engage() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 40:
		await physics_frame


## Combat is piloted, so the aim has to take the camera off the pal and put it
## behind the trainer. If it does not, the player is aiming from somewhere they
## are not standing.
func _aiming_hands_control_to_the_trainer() -> void:
	await _press("combat_throw")
	for i in 20:
		await physics_frame

	if not bool(_manager.call("is_aiming")):
		_fail("pressing Throw did not open the aim")
		return
	var to_trainer := _rig.global_position.distance_to(_player.global_position)
	var to_pal := _rig.global_position.distance_to(_ally.global_position)
	if to_trainer > to_pal:
		_fail("aiming left the camera on the pal (%.1fm) rather than the trainer (%.1fm)" % [to_pal, to_trainer])
	print("aim opened: camera %.1fm from the trainer, %.1fm from the pal" % [to_trainer, to_pal])

	# Backing out is free and must spend nothing.
	var before := int(_manager.call("orbs_left"))
	await _press("combat_run")
	for i in 20:
		await physics_frame
	if bool(_manager.call("is_aiming")):
		_fail("could not cancel out of the aim")
	if not bool(_manager.call("is_fighting")):
		_fail("cancelling the aim ended the whole fight")
	if int(_manager.call("orbs_left")) != before:
		_fail("cancelling an aim spent an orb")


## The cost that makes throwing a decision. If the stick still drives the pal
## while you are lining up a throw, catching is free and the right play is to
## throw constantly.
func _aiming_abandons_your_pal() -> void:
	await _press("combat_throw")
	for i in 20:
		await physics_frame
	if not bool(_manager.call("is_aiming")):
		_fail("could not re-open the aim")
		return

	var before := _ally.global_position
	Input.action_press("move_forward")
	for i in 45:
		await physics_frame
	Input.action_release("move_forward")
	var moved := before.distance_to(_ally.global_position)
	if moved > 0.75:
		_fail("the pal moved %.2fm on the stick while aiming; aiming is supposed to abandon it" % moved)
	else:
		print("pal stayed put while aiming (%.2fm drift)" % moved)


## Aim at the sky and let go. The orb is a projectile: it has to be able to go
## nowhere, and doing so still has to cost something.
func _a_throw_at_the_sky_misses_and_still_costs_an_orb() -> void:
	if not bool(_manager.call("is_aiming")):
		await _press("combat_throw")
		for i in 20:
			await physics_frame

	# Straight up and behind. Nothing to hit.
	_rig.set("pitch", deg_to_rad(20.0))
	var away := _player.global_position - _wild.global_position
	away.y = 0.0
	_aim_camera_along(away)
	for i in 5:
		await physics_frame

	var orbs_before := int(_manager.call("orbs_left"))
	var refusals_before := _refusals.size()
	var resolutions_before := _resolutions.size()

	await _press("combat_throw")
	for i in 300:
		await physics_frame
		if _refusals.size() > refusals_before or _resolutions.size() > resolutions_before:
			break

	if int(_manager.call("orbs_left")) >= orbs_before:
		_fail("a thrown orb cost nothing (%d before, %d after)" % [orbs_before, int(_manager.call("orbs_left"))])
	if _resolutions.size() > resolutions_before:
		_fail("an orb thrown away from the target still resolved as a catch attempt")
	elif _refusals.size() > refusals_before:
		print("a throw at nothing missed: '%s'" % _refusals[-1])
	else:
		_fail("an orb thrown at nothing never resolved at all; it is still in the air")


func _a_weakened_pal_can_be_caught() -> void:
	var foe: RefCounted = _manager.call("enemy")
	# Weakened directly rather than by fighting: this test is about the throw,
	# and grinding a pal down through combat would be testing M2 again.
	foe.hp = foe.max_hp * 0.08

	var caught := false
	for attempt in MAX_ATTEMPTS:
		if not bool(_manager.call("is_fighting")):
			break
		# Top the satchel back up. Running dry mid-test would report as
		# "catching is broken" when it only means the starting supply is small.
		if int(_manager.call("orbs_left")) <= 1:
			_seed_orbs()
		foe.hp = foe.max_hp * 0.08
		# Keep the player's pal standing. Aiming genuinely abandons it — that is
		# the whole design and _aiming_abandons_your_pal asserts it — so a test
		# that throws twenty-five times in a row will get its pal knocked out and
		# report "catching is broken" when catching was working perfectly.
		var pal: RefCounted = _manager.call("active_pal")
		if pal != null:
			pal.hp = pal.max_hp

		var resolutions_before := _resolutions.size()
		if not await _throw_at_the_target():
			continue
		for i in 400:
			await physics_frame
			if _resolutions.size() > resolutions_before:
				break
		if _resolutions.size() > resolutions_before and _resolutions[-1]:
			caught = true
			break

	if not caught:
		_fail("could not catch a pal at 8%% health in %d throws" % MAX_ATTEMPTS)
		return

	print("caught it after %d resolved throws" % _resolutions.size())
	for i in 300:
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			break
	if bool(_manager.call("is_fighting")):
		_fail("a successful catch did not end the fight")
	if str(_manager.call("outcome")) != "caught":
		_fail("caught a pal but the fight ended as '%s'" % str(_manager.call("outcome")))
	var kept: Array = _director.call("caught")
	if kept.is_empty():
		_fail("the caught pal was not kept anywhere; M4 has nothing to attach to")
	if not bool(_player.call("locomotion_enabled")):
		_fail("the trainer cannot walk after a catch")


## §15: over-damaging a pal ENDS the capture opportunity. A refusal, not long
## odds — and the player has to be told which it was.
func _a_fainted_pal_cannot_be_caught() -> void:
	# Wait for the practice pal to be back on its feet, then walk over and
	# engage it again. Waiting for a prompt without moving would never work: the
	# fight left the trainer at the arena edge, and the pal respawns at its own
	# home some distance away. The wait covers the respawn delay, which is data
	# now (spawns.json respawn_seconds) rather than M2's hardcoded 6 seconds.
	var respawn := float((_director.call("spawns_config") as Dictionary).get("respawn_seconds", 45.0))
	var budget := int(ceil(respawn * float(Engine.physics_ticks_per_second))) + 900
	for i in budget:
		await physics_frame
		if _wild.visible and bool(_wild.call("is_alive")):
			break
	if not (_wild.visible and bool(_wild.call("is_alive"))):
		_fail("the wild pal never came back after being caught; the fainted case could not be tested")
		return

	await _walk_to_the_wild_pal()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_fail("could not re-engage after a catch; the fainted case could not be tested")
		return

	var foe: RefCounted = _manager.call("enemy")
	foe.take_damage(foe.max_hp * 2.0)
	await physics_frame

	var refusals_before := _refusals.size()
	await _press("combat_throw")
	for i in 30:
		await physics_frame

	if bool(_manager.call("is_aiming")):
		_fail("the aim opened on a fainted pal; the capture opportunity is supposed to be over")
	if _refusals.size() == refusals_before:
		_fail("throwing at a fainted pal was silently ignored, with no reason given")
	else:
		print("a throw at a fainted pal was refused: '%s'" % _refusals[-1])


func _throw_at_the_target() -> bool:
	if not bool(_manager.call("is_aiming")):
		if not await _open_aim():
			return false

	# The aim camera glides into its combat position over several frames
	# (`aim.retarget_lag` in catching.json) rather than cutting instantly.
	# Reading the camera's eye before it arrives means aiming from wherever it
	# used to be, not from where the throw is actually about to come from.
	for i in 15:
		await physics_frame

	_aim_at_the_target()
	for i in 4:
		await physics_frame

	await _press("combat_throw")
	return true


## Press Throw until the aim actually opens, or give up.
##
## `throw_aim.gd` enforces a silent cooldown after every throw resolves
## (`throw.cooldown` in catching.json, 0.9s by default) — `try_begin_aim()`
## just returns false while it is running, with no signal at all, so a single
## press timed against a throw that just resolved is a coin flip. Left alone,
## that burns most of `MAX_ATTEMPTS` on presses that never opened an aim at
## all rather than on throws that missed.
func _open_aim() -> bool:
	var cooldown := float(CATCH.config().get("throw", {}).get("cooldown", 0.9))
	var frame_time := 1.0 / float(Engine.physics_ticks_per_second)
	var budget := int(ceil(cooldown / frame_time)) + 60
	while budget > 0:
		await _press("combat_throw")
		budget -= 4
		for i in 6:
			await physics_frame
			budget -= 1
		if bool(_manager.call("is_aiming")):
			return true
	return false


## Point the camera so a thrown orb lands on the target.
##
## Aimed from the CAMERA's eye, not the trainer's hand — they sit about a
## shoulder's width apart (`aim.shoulder_offset` in catching.json), and
## `_aim_direction()` in throw_aim.gd builds its ray from the eye. Aiming from
## the hand disagrees with the code actually driving the throw and sends it
## wide by exactly that offset.
##
## No drop compensation, deliberately: `_aim_direction()` snaps the throw
## straight to the target's centre whenever the camera's ray passes within a
## body-width of it, discarding any elevation this function adds on top of
## that. Arcing the aim to compensate for drop only risks pushing the ray
## outside that snap window; aiming straight at the (leaded) centre keeps it
## inside instead and lets the snap do the rest.
##
## Leaded, because the target keeps moving between this call and the moment
## the orb actually leaves the hand — the settle above plus
## `throw.release_windup` — so this aims at where it will be, not where it
## was when the camera turned.
func _aim_at_the_target() -> void:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var eye := camera.global_position

	var velocity := Vector3.ZERO
	if _wild is CharacterBody3D:
		velocity = (_wild as CharacterBody3D).velocity
	var release_windup := float(CATCH.config().get("throw", {}).get("release_windup", 0.18))
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + release_windup
	var predicted: Vector3 = (_wild.call("centre") as Vector3) + velocity * lead_time

	var to := predicted - eye
	_aim_camera_along(Vector3(to.x, 0.0, to.z))
	var flat := Vector2(to.x, to.z).length()
	_rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))


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
		print("catching: OK — a throw can be aimed, missed, and landed.")
		quit(0)
		return
	for line in _failures:
		print("catching FAIL: %s" % line)
	quit(1)
