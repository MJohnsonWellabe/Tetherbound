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
## are new and physical: the creature has to actually move, the arena has to actually
## hold it, an attack has to be able to miss, and control has to come back.
##
## It drives the real input actions rather than calling the manager's methods, so
## a broken binding fails here rather than on the handheld.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
## T3-TYPECHART. Read independently of the manager so this file can grade the
## manager rather than echo it.
const CHART := preload("res://scripts/combat/type_chart.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")

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
## T3-TYPECHART. `[on_enemy, effectiveness]` for every hit that landed this run.
var _effectiveness_seen: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_leave_the_farmhouse()
	if not _collect_nodes():
		_report()
		return

	await _the_combat_buttons_say_something_outside_a_fight()
	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat; nothing below this point was tested")
		_report()
		return

	_ally = _director.call("ally_body") as Node3D
	_check_the_fight_opened()

	_the_camera_can_see_the_fight()
	await _the_creature_moves_on_the_stick()
	await _the_arena_holds_you_in()
	await _a_swing_at_empty_air_misses()
	await _a_swing_at_the_enemy_connects()
	await _the_enemy_closes_and_hits_back()
	# BEFORE the fight is resolved, not after: `_fight_to_a_finish` runs the
	# enemy to zero and the manager drops it, so this has to read both fighters
	# while they are both still standing. By here hits have landed in both
	# directions, which is what it needs.
	_the_type_chart_reaches_a_real_fight()
	await _fight_to_a_finish()
	await _hp_is_not_auto_healed_after_the_fight()
	await _exploration_is_restored()
	_report()


## `meadows_playground.tscn` now always carries a `SequenceDirector` (R0.9),
## and its `_ready()` unconditionally calls `suspend_default_starter()` in the
## one frame window that exists to call it off — the opening always decides
## which creature the player gets, never the sandbox default. This test is not the
## opening and never drives it, so the encounter director's own
## `default_starter` never spawns here either. Proving combat's WIRING does
## not need the opening's cast; it needs a creature, so this gets one directly,
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
	var start := Vector3(48.0, 0.0, -58.0)
	# Not closer: the practice cluster spawns around (41, -48), and starting
	# within ~4m of a creature trips the "spawned on top of the player"
	# tripwire on nothing worse than a terrain rebake moving y a few cm.
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO



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
	# T3-TYPECHART. Every verdict the fight actually emitted, so
	# `_the_type_chart_reaches_a_real_fight` below can check them against an
	# independent lookup instead of trusting one code path to grade itself.
	_manager.connect("hit_effectiveness", func(on_enemy: bool, effectiveness: int) -> void:
		_effectiveness_seen.append([on_enemy, effectiveness]))

	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_fail("the encounter director never spawned a wild creature")
		return false
	if _director.call("ally_instance") == null:
		_fail("the player has no creature to fight with")
		return false

	# Asserted explicitly, because the failure mode is silent: if the placement
	# raycast runs before Terrain3D has built collision it finds nothing, and the
	# creature sits at the world origin under the terrain. Everything downstream
	# then "passes" against a creature the player could never have walked up to.
	if _wild.global_position.distance_to(_player.global_position) < 4.0:
		_fail("the wild creature spawned on top of the player; it was never placed")
		return false
	print("wild creature at %.0f, %.0f, %.0f" % [
		_wild.global_position.x, _wild.global_position.y, _wild.global_position.z
	])
	return true


## Do the fight buttons admit they are doing nothing?
##
## `combat_manager.gd::_read_player_input()` is only reachable from
## `_tick_active()`, so with no fight running quick attack, charged attack and
## the orb throw produced no animation, no message and no orb spent. A blind
## playtest pressed all three, got absolute silence, and read them as broken
## buttons rather than as unavailable ones.
##
## Driven with the real actions and read off the HUD's own message strip, not
## off the manager: the claim being tested is "the player is told", and a check
## that drained `Game.take_pending_world_message()` itself would pass on a
## message that never reached the screen.
func _the_combat_buttons_say_something_outside_a_fight() -> void:
	if bool(_manager.call("is_fighting")):
		_fail("a fight is already running before the engage step; this check is measuring the wrong state")
		return
	var game := root.get_node_or_null(^"Game")
	var hud := _world.get_node_or_null(^"PlaygroundHUD")
	var message := hud.find_child("Message", true, false) as Label \
			if hud != null else null
	if game == null or message == null:
		_fail("no Game autoload or no HUD message strip; the refusal has nowhere to be said")
		return

	var quick := await _refusal_after(game, message, "combat_quick")
	if quick.is_empty():
		_fail("pressed `combat_quick` with no fight running and nothing was said at all")
	else:
		print("outside a fight, combat_quick says: '%s'" % quick)

	var throw := await _refusal_after(game, message, "combat_throw")
	if throw.is_empty():
		_fail("pressed `combat_throw` with no fight running and nothing was said at all")
	else:
		print("outside a fight, combat_throw says: '%s'" % throw)

	# The other half of the contract. LMB/RMB and LT/RT are also
	# build_place/build_cancel and build_rotate_left/right (project.godot), so a
	# refusal that fired while a piece was armed would talk over the build
	# placer on every rotate.
	game.set("pending_build", "camp")
	var while_building := await _refusal_after(game, message, "combat_quick")
	game.set("pending_build", "")
	if not while_building.is_empty():
		_fail("with a build armed, `combat_quick` still said '%s'; that press belongs to the placer"
			% while_building)
	else:
		print("with a build armed, the same press stays quiet")


## Press one action from a clean slate and hand back whatever the HUD then says.
func _refusal_after(game: Node, message: Label, action: String) -> String:
	game.call("take_pending_world_message")
	message.text = ""
	message.visible = false
	for i in 3:
		await physics_frame

	await _press(action)
	for i in 10:
		await physics_frame
	return str(message.text) if message.visible else ""


## Walk over and stand next to it, rather than teleporting. Reaching the creature
## is part of the encounter and a wild creature spawned somewhere unreachable is a
## real failure.
func _walk_to_the_wild_creature() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	# 1800 frames covers the practice cluster's far edge (~65m from the origin
	# since spawns.json moved it to [30, -40] r15) with slack for slopes.
	for i in 1800:
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
		_fail("could not walk within engage range of the wild creature (got to %.1fm)" % final)


## Point the camera so that "forward" means this direction. Steering through the
## camera rather than by setting positions is deliberate: it is the same path the
## player's stick takes, so a broken planar_basis fails here.
func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _engage() -> void:
	if str(_director.call("prompt")) == "":
		_fail("no engage prompt appeared next to the wild creature")
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
		_fail("the player's creature was never deployed")
		return
	if _manager.call("arena") == null:
		_fail("no arena was opened")

	# The camera is supposed to be on the creature now, not the trainer. Checked by
	# where the rig actually is rather than by reading a private field, so a rig
	# that stores the right target and follows the wrong one still fails.
	var to_creature := _rig.global_position.distance_to(_ally.global_position)
	var to_trainer := _rig.global_position.distance_to(_player.global_position)
	if to_creature > to_trainer:
		_fail("the camera is still following the trainer (%.1fm) not the creature (%.1fm)" % [to_trainer, to_creature])


## Can the camera actually see the fight?
##
## Two survey frames once came back showing nothing but green because the camera
## had ended up inside a bush. Every check in this file passed on those frames:
## the fight was running, both creatures were alive, the HUD was correct. Only
## looking at the pixels caught it.
##
## So this asks the question directly — is anything solid standing between the
## camera and the creature the player is driving.
func _the_camera_can_see_the_fight() -> void:
	if _ally == null:
		return
	var camera: Camera3D = _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		_fail("the camera rig has no camera")
		return

	var eye := camera.global_position
	var subject: Vector3 = _ally.call("centre")
	var query := PhysicsRayQueryParameters3D.create(eye, subject)
	query.collide_with_areas = false
	query.exclude = [(_ally as CollisionObject3D).get_rid()]
	var blocked: Dictionary = _rig.get_world_3d().direct_space_state.intersect_ray(query)

	var distance := eye.distance_to(subject)
	print("camera %.1fm from the creature, line of sight %s" % [
		distance, "blocked" if not blocked.is_empty() else "clear"
	])
	if not blocked.is_empty():
		_fail("something solid is between the camera and the player's creature; the fight is not visible")
	# Inside the creature is its own kind of blind.
	if distance < 1.0:
		_fail("the camera is %.2fm from the creature; it is inside the creature" % distance)


## The whole point of the change. If the stick does not move the creature, combat is
## still the menu it used to be.
func _the_creature_moves_on_the_stick() -> void:
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
	print("creature moved %.1fm on the stick" % travelled)
	if travelled < 1.0:
		_fail("the stick moved the creature %.2fm; combat is not actually piloted" % travelled)


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
		_fail("the creature reached %.1fm from the centre of an %.1fm arena; the boundary leaks" % [furthest, radius])


## Attacks have to be missable, or spacing is decoration.
##
## The miss this proves is an OUT-OF-RANGE one. It used to be a facing miss —
## turn away and swing at nothing — but the design took facing off the skill
## list: the creature now turns toward its opponent as every swing starts
## (combat_manager's windup auto-face), because "I was fifteen degrees off"
## on a 7-inch handheld read as noise, not skill. Range and timing are the
## skills that remain, so range is what must still be able to say no. This
## also caught a real flake: with auto-face in place, the old version of this
## test hit or missed depending on how far the walk-away drifted, and it
## passed locally while failing on CI.
func _a_swing_at_empty_air_misses() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var hp_before: float = foe.hp
	var misses_before := _misses

	# Stage the gap directly, the same way the walking tests stage their start
	# points: put the creature across the arena from the enemy. The input under
	# test is the attack press, not the walk that would get it there — racing
	# the enemy's chase across the arena on real inputs is exactly the
	# nondeterminism that made this test flap.
	var arena: Node3D = _manager.call("arena") as Node3D
	var centre: Vector3 = arena.global_position if arena != null else _ally.global_position
	var radius: float = float(arena.get("radius")) if arena != null else 11.0
	var out := centre - _wild.global_position
	out.y = 0.0
	if out.length() < 0.5:
		out = Vector3(1, 0, 0)
	var target := centre + out.normalized() * (radius - 1.5)
	# Re-grounded rather than trusting the arena centre's own height (D09: ask
	# the world, never carry a Y across a horizontal move) -- the same bug
	# `combat_manager.gd::_stand_the_trainer_aside` already paid for once. On
	# rolling terrain a 9.5m horizontal jump can land well off `centre`'s own
	# height; carrying it forward embedded the creature under a one-sided heightfield
	# collider with no floor to catch it, and it fell through the world for the
	# rest of the fight -- the actual cause behind this file's own flake entry,
	# found by watching real position/velocity logs across ~20 runs rather than
	# reasoning about it (`ralph/BACKLOG.md` LP1, `ralph/PROMPT.md`'s R4.11/RB3
	# precedent).
	if not bool(_ally.call("place_on_ground", target)):
		_ally.global_position = target
	if _ally is CharacterBody3D:
		(_ally as CharacterBody3D).velocity = Vector3.ZERO
	for i in 3:
		await physics_frame

	await _press("combat_quick")
	for i in 30:
		await physics_frame

	if foe.hp < hp_before:
		_fail("an attack from across the arena still damaged the enemy; range is not real")
	if _misses == misses_before:
		_fail("an out-of-range swing was not reported as a miss; the player gets no feedback")
	else:
		print("a swing from out of range missed, as it should")


func _a_swing_at_the_enemy_connects() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var creature: RefCounted = _manager.call("active_creature")
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
	var energy_before: float = creature.energy
	await _press("combat_quick")
	for i in 25:
		await physics_frame

	if foe.hp >= hp_before:
		_fail("a quick attack at point-blank range did no damage (%.1f -> %.1f)" % [hp_before, foe.hp])
	else:
		print("quick attack: enemy %.1f -> %.1f hp" % [hp_before, foe.hp])
	# Energy is earned by connecting, not by pressing. That is what ties the
	# charged attack to positioning rather than to button-mashing.
	if creature.energy <= energy_before:
		_fail("a landed quick attack built no energy (%.1f -> %.1f)" % [energy_before, creature.energy])


## T3-TYPECHART's integration seam, checked against a real fight rather than
## against the arithmetic alone.
##
## `tests/test_type_chart.gd` owns the chart's own behaviour: the table, the
## magnitudes, the multiplier's path through combat_math. What it structurally
## CANNOT check is the two lines in `combat_manager.gd` that look the
## multiplier up and hand it to `rolled_damage` -- delete either argument and
## every one of those 270 assertions still passes while the mechanic is silently
## switched off in the shipped game. That is exactly the failure this repo has
## collected before: a system that exists, is tested, and never reaches the
## player.
##
## So this asserts AGREEMENT rather than a particular outcome. Which types meet
## here depends on what the director spawned, so demanding a strong hit would
## be flaky; demanding that the verdict the fight emitted matches an
## independent lookup over the same two creatures is deterministic whatever
## spawns, and it is false the moment the manager stops consulting the chart or
## starts consulting it with the wrong arguments.
func _the_type_chart_reaches_a_real_fight() -> void:
	if _effectiveness_seen.is_empty():
		_fail("the fight landed %d hits and emitted no type verdict at all -- "
			% (_hits_on_enemy + _hits_on_ally)
			+ "combat_manager is not consulting the type chart")
		return

	var foe: RefCounted = _manager.call("enemy")
	var creature: RefCounted = _director.call("ally_instance")
	if foe == null or creature == null:
		return

	# The same lookup the manager performs, done here from the raw data.
	var moves: RefCounted = MOVE_DB.load_default()
	var on_foe := CHART.effectiveness(
		str(moves.call("type_of", str(creature.move_quick))), str(foe.creature_type))
	var on_ally := CHART.effectiveness(
		str(moves.call("type_of", str(foe.move_quick))), str(creature.creature_type))

	for entry: Variant in _effectiveness_seen:
		var on_enemy: bool = bool((entry as Array)[0])
		var reported: int = int((entry as Array)[1])
		var expected: int = on_foe if on_enemy else on_ally
		# The player's CHARGED move can be a different type from its quick one
		# (Mosshell and Reedwing ship that way, and any TM creates it), so a
		# player-side hit is allowed to report the charged move's verdict too.
		# The enemy AI has one attack and no such latitude.
		if on_enemy and reported != expected:
			var charged := CHART.effectiveness(
				str(moves.call("type_of", str(creature.move_charged))), str(foe.creature_type))
			if reported == charged:
				continue
		if reported != expected:
			_fail("the fight reported effectiveness %d for a hit %s, but %s vs %s is %d"
				% [reported, "on the enemy" if on_enemy else "on the ally",
					str(creature.creature_type), str(foe.creature_type), expected])
			return

	# The HUD's own accessor, checked on the same pair. This is the arrow the
	# player reads before committing, and it is a different code path from the
	# per-hit verdict above -- it takes the BEST of the two equipped moves,
	# where a hit reports the one actually thrown.
	var quick := CHART.multiplier(
		str(moves.call("type_of", str(creature.move_quick))), str(foe.creature_type))
	var charged_mult := CHART.multiplier(
		str(moves.call("type_of", str(creature.move_charged))), str(foe.creature_type))
	var expected_arrow := CHART.classify(maxf(quick, charged_mult))
	var reported_arrow: int = int(_manager.call("active_matchup"))
	if reported_arrow != expected_arrow:
		_fail("the HUD's matchup arrow reports %d for %s vs %s; the chart says %d"
			% [reported_arrow, str(creature.creature_type), str(foe.creature_type), expected_arrow])
		return

	# Printed rather than asserted: WHICH types meet here is the director's
	# choice, not this test's, so a mirror matchup (verdicts all 0) is a
	# legitimate run. What is asserted above is that the fight and the chart
	# agree; that the chart itself produces non-neutral verdicts is
	# tests/test_type_chart.gd's job, where the pairing can be pinned.
	print("type chart reached the fight: %d verdicts, ally %s vs foe %s (hit %d / %d, arrow %d)"
		% [_effectiveness_seen.size(), str(creature.creature_type), str(foe.creature_type),
			on_foe, on_ally, reported_arrow])


## Without this the fight is a punching bag with a health bar.
func _the_enemy_closes_and_hits_back() -> void:
	var creature: RefCounted = _manager.call("active_creature")

	# Start watching from a clean beat.
	#
	# The previous step ends at point-blank range, so the enemy is usually
	# already mid-wind-up when this one begins. Opening the window there means
	# the telegraph started before anyone was looking: the blow lands on the
	# first or second frame, the assertion sees only RECOVER, and the test
	# reports "the enemy attacked with no visible wind-up" about a wind-up that
	# happened correctly and unobserved. That failed once and the fight was fine.
	#
	# So wait for the enemy to be un-rooted first. Everything after that point is
	# a complete beat, and a strike with no telegraph in it is then a real bug.
	for i in 240:
		if not bool(_manager.call("is_fighting")) or not bool(_manager.call("enemy_is_rooted")):
			break
		await physics_frame

	var hp_before: float = creature.hp
	var saw_telegraph := false
	var saw_opening := false
	var struck_unannounced := false

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
		if creature.hp < hp_before:
			# Ordering matters more than occurrence: a wind-up that arrives after
			# the damage is not a warning.
			struck_unannounced = not saw_telegraph
			break

	if creature.hp >= hp_before:
		_fail("the enemy never landed a hit in 15 seconds of standing still")
	else:
		print("enemy dealt damage: ally %.1f -> %.1f hp" % [hp_before, creature.hp])
	if struck_unannounced or not saw_telegraph:
		_fail("the enemy attacked with no visible wind-up; the fight has no warning")
	if not saw_opening:
		_fail("the enemy was never seen recovering; there is no window to punish")


func _fight_to_a_finish() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var frames := 0
	while bool(_manager.call("is_fighting")) and frames < FIGHT_FRAME_LIMIT:
		var creature: RefCounted = _manager.call("active_creature")
		# Keep the ally alive long enough to win: heal it rather than tune the
		# fight, because this test is about wiring, not balance.
		if creature != null and creature.hp_fraction() < 0.4:
			creature.hp = creature.max_hp

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


## R2.5: `encounter_director.gd` used to call `_ally.heal_fully()` on the way
## out of every fight, an M2 placeholder for a healing system, camp rest and
## potions that did not exist yet. All three exist now, so a win must leave
## the party's HP exactly where the fight left it — not full again — and this
## checks the real post-fight signal chain (`_on_combat_exited`), not the
## removed call directly, so a regression that re-adds healing anywhere in
## that path fails here.
func _hp_is_not_auto_healed_after_the_fight() -> void:
	var creature: RefCounted = _director.call("ally_instance")
	if creature == null:
		_fail("no ally instance to check post-fight HP against")
		return
	var hp_at_win: float = creature.hp
	if hp_at_win >= float(creature.max_hp):
		_fail("the ally is at full HP already at the moment of victory; " +
			"the earlier damage-taken check should have prevented this")
		return
	for i in 60:
		await physics_frame
	var hp_after: float = creature.hp
	if hp_after != hp_at_win:
		_fail("the ally's HP changed from %.1f to %.1f after the fight ended with no potion or rest — something is still auto-healing" % [
			hp_at_win, hp_after
		])
	else:
		print("post-fight HP held at %.1f, no auto-heal" % hp_after)


func _exploration_is_restored() -> void:
	for i in 120:
		await physics_frame

	if not bool(_player.call("locomotion_enabled")):
		_fail("the trainer cannot walk after the fight ended")
	# The deployed body returns to being the visible exploration follower. This
	# used to assert the opposite, so restoring the intended post-fight follower
	# lifecycle in c34bd6f9 made a healthy teardown fail CI.
	if _ally == null or not is_instance_valid(_ally) or not _ally.visible:
		_fail("the player's creature was not restored as the visible follower after the fight")
	elif not bool(_ally.call("is_following")):
		_fail("the player's creature is visible after the fight but is not following the trainer")
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
