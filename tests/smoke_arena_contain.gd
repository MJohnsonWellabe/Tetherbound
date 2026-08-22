extends SceneTree

## OP21-25 -- fights must stay inside a reachable arena, in the Stronghold and
## the Burrow Warrens specifically, not just the open meadow.
##
##   godot --headless --path . --script tests/smoke_arena_contain.gd
##
## tests/smoke_combat.gd's own containment check (`_the_arena_holds_you_in`)
## only ever ran in the open meadow, where the default 11m arena radius
## (data/config/combat.json's `arena.radius`) has nothing narrower than open
## ground to clip against. Every room in the Stronghold and the Burrow
## Warrens is narrower than that in at least one dimension -- Warrens `mouth`
## is 7x10m, Stronghold `tether_approach` is 16x18m -- and
## `combat_arena.gd::hold_inside()` corrects a fighter with a raw position
## WRITE, not a physics move, so it has no collision to stop it: an unclamped
## boundary does not clip a knocked-back fighter against a real wall, it
## teleports the fighter straight through to the far side. That is OP21-25's
## repro, and this file both reproduces it and proves the fix
## (`stronghold.gd`/`burrow_warrens.gd::combat_arena_bounds_at()`, read by
## `combat_manager.gd::_arena_bounds()` and applied in `_open_arena()`).
##
## Two representative fights, not the opening wild-fight harness: a Warrens
## wild creature (`mouth`, the tightest chamber with a spawn in it) and a
## Stronghold gauntlet trainer (`tether_approach`, the elite before the
## Warden). Each case, through `_prove_containment()`:
##   1. asserts the room actually SHRANK the arena below the flat default --
##      the bound is being computed and applied, not just present in code;
##   2. drives the fight's real physics -- a sustained knockback impulse plus
##      ordinary stick movement, both toward the boundary -- and asserts the
##      fighter never leaves the room's real footprint;
##   3. reverts the arena's own radius to the flat, unclamped default IN THE
##      SAME RUNNING FIGHT and repeats the identical push, asserting that the
##      fighter NOW phases outside the room -- proof this test would have
##      failed on the code before this item, not just that it passes after.

const SCENE := "res://scenes/world/meadows_playground.tscn"

const SETTLE_FRAMES := 300
## `data/config/combat.json`'s own flat `arena.radius` -- the number every
## fight asked for before OP21-25, and what Part 3 below reverts to.
const NAIVE_DEFAULT_RADIUS := 11.0
## How long to push, in physics frames, for each of the two probes below.
## 90 frames (1.5s) of a 14 units/s impulse plus full-speed stick movement
## covers the naive radius several times over in every chamber this file
## tests, so a probe that still failed to reach the boundary would itself be
## a sign this harness is not actually exercising anything.
const PUSH_FRAMES := 90

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	await _warrens_case()
	await _stronghold_case()
	_report()


## The opening decides which creature the player gets and this test is not
## the opening, so it gets one directly -- the same shortcut smoke_combat.gd,
## smoke_trainer_battle.gd and smoke_boss.gd all take for the same reason.
func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _player == null or _rig == null or _manager == null or _director == null:
		_fail("scene is missing the player, camera rig, combat manager or director")
		return false
	if _director.call("ally_instance") == null:
		_fail("the player has no creature to fight with")
		return false
	return true


## --- Burrow Warrens ---------------------------------------------------------

func _warrens_case() -> void:
	var warrens := _world.get_node_or_null(^"BurrowWarrens")
	if warrens == null:
		_fail("the world built no BurrowWarrens node; OP21-25's cave repro cannot run")
		return
	# Named by burrow_warrens.gd::_spawn_population() -- "Warrens_<species>_<n>",
	# the mouth chamber's own resident (data/config/burrow_warrens.json).
	var wild := _world.find_child("Warrens_mudsnout_1", true, false) as Node3D
	if wild == null:
		_fail("'Warrens_mudsnout_1' was never spawned; the mouth chamber has nobody to fight")
		return

	await _approach_and_engage_wild(warrens, wild)
	if not bool(_manager.call("is_fighting")):
		_fail("could not engage the warrens wild creature; nothing below this point was tested")
		return

	var ally: Node3D = _director.call("ally_body") as Node3D
	await _prove_containment("burrow warrens / mouth", warrens, ally)
	await _end_fight_if_running()


## --- Stronghold -------------------------------------------------------------

func _stronghold_case() -> void:
	var stronghold := _world.get_node_or_null(^"Stronghold")
	if stronghold == null:
		_fail("the world built no Stronghold node; OP21-25's fortress repro cannot run")
		return
	var trainers: Node = stronghold.call("trainers_node")
	var elite: Node3D = trainers.call("body_for", "stronghold_elite") as Node3D if trainers != null else null
	if elite == null:
		_fail("'stronghold_elite' was never stood up in the tether approach")
		return
	print("stronghold_elite stands at %s" % str(elite.global_position))

	await _challenge(stronghold, elite, "tether_approach")
	if not bool(_manager.call("is_fighting")):
		_fail("could not challenge the stronghold elite; nothing below this point was tested")
		return

	var ally: Node3D = _director.call("ally_body") as Node3D
	await _prove_containment("stronghold / tether_approach", stronghold, ally)
	await _end_fight_if_running()


## --- the shared proof -------------------------------------------------------

## Three parts, described in this file's header. `building` is whichever room
## script (`stronghold.gd` or `burrow_warrens.gd`) hosts the fight;
## `participant` is the body being pushed around, always the player's own
## creature so the same probe works whether the opponent is a wild animal or
## a trainer's.
func _prove_containment(label: String, building: Node, participant: Node3D) -> void:
	var arena: Node = _manager.call("arena")
	if arena == null or participant == null:
		_fail("%s: no arena was opened, or the ally has no body to push around" % label)
		return
	if not building.has_method("combat_arena_bounds_at"):
		_fail("%s: the building has no combat_arena_bounds_at(); the fix is not wired up" % label)
		return

	var centre: Vector3 = arena.global_position
	print("%s: fight opened at player %s, arena centre %s" % [
		label, str(_player.global_position), str(centre)])

	# Part 1: the shrink happened.
	var bound: float = float(building.call("combat_arena_bounds_at", centre.x, centre.z))
	if bound <= 0.0:
		_fail("%s: the fight's own centre (%s) is not recognised as inside any chamber" % [label, str(centre)])
		return
	if bound >= NAIVE_DEFAULT_RADIUS - 0.01:
		_fail(("%s: the room affords %.1fm of radius, no smaller than the flat %.1fm default; " +
			"this case does not exercise the shrink at all") % [label, bound, NAIVE_DEFAULT_RADIUS])
		return
	var configured: float = float(arena.get("radius"))
	if configured > bound + 0.01:
		_fail("%s: the arena's live radius is %.1fm but the room only affords %.1fm; the shrink was not applied"
			% [label, configured, bound])
		return
	print("%s: arena shrank to %.1fm (room affords %.1fm, flat default is %.1fm)" % [
		label, configured, bound, NAIVE_DEFAULT_RADIUS])

	# Part 2: FIX ACTIVE. Push the ally hard toward the wall -- knockback
	# impulse plus ordinary stick movement together -- along the building's
	# own local +X (its LATERAL axis). Both test chambers' passages run
	# along the layout spine (local Z: mouth->hall, courtyard->
	# tether_approach->warden_arena all vary only in depth per each config's
	# own `_comment_frame`/`_comment_site`), so local Z leads through an open
	# doorway into the next room -- a real leak, but not the one this file is
	# after. Local X has no passage in either test chamber, only solid rock/
	# masonry, and it is also the tighter of the two dimensions in both
	# (`mouth` 7 wide vs. 10 deep; `tether_approach` 16 wide vs. 18 deep), so
	# it is the direction most likely to expose an actual wall-clip.
	var push: Vector3 = building.global_transform.basis.x
	push.y = 0.0
	push = push.normalized() if push.length() > 0.01 else Vector3.FORWARD

	var furthest := await _push_and_measure(participant, push, centre)
	if furthest > configured + 1.0:
		_fail("%s: pushed %.1fm from the arena centre against a %.1fm boundary; the fix leaks" % [
			label, furthest, configured])
	if not is_instance_valid(participant):
		_fail("%s: the ally did not survive the fix-active push" % label)
		return
	var after_fix: Vector3 = participant.global_position
	if float(building.call("combat_arena_bounds_at", after_fix.x, after_fix.z)) <= 0.0:
		_fail("%s: the ally ended up outside every known chamber even WITH the fix applied" % label)
	else:
		print("%s: held to %.1fm against a %.1fm boundary, still inside the room" % [label, furthest, configured])

	# Part 3: FIX DISABLED. `hold_inside()` is a raw position WRITE with no
	# collision check -- that is the actual defect, independent of how a
	# fighter gets far from centre in the first place (an open doorway inside
	# the mathematical radius, a single large physics step, anything). So this
	# puts the ally at exactly that precondition -- well past the room, the
	# same distance a shove through an unblocked doorway would reach -- and
	# lets ONE physics tick run `creature_body.gd`'s own
	# `if arena != null: arena.call("hold_inside", self)`, unchanged and
	# un-mocked. With the arena's radius put back to the flat default, in
	# this same running fight, that one correction is asserted to land
	# outside every known chamber. If it does NOT, the pass above proves
	# nothing -- a room `hold_inside` could not be tricked into overshooting
	# would pass with or without the clamp -- so a clean landing here is
	# itself asserted as a FAILURE: landing outside a real wall is exactly
	# what OP21-25 reported.
	arena.set("radius", NAIVE_DEFAULT_RADIUS)
	participant.global_position = centre + push * (NAIVE_DEFAULT_RADIUS * 3.0)
	if participant is CharacterBody3D:
		(participant as CharacterBody3D).velocity = Vector3.ZERO
	await physics_frame
	if not is_instance_valid(participant):
		_fail("%s: the ally did not survive the fix-disabled probe" % label)
		return

	var after_disabled: Vector3 = participant.global_position
	var corrected_distance := (after_disabled - centre).length()
	var still_legal := float(building.call("combat_arena_bounds_at", after_disabled.x, after_disabled.z)) > 0.0
	if still_legal:
		_fail(("%s: reverting the arena to the flat %.1fm default did not reproduce OP21-25 -- " +
			"hold_inside() corrected the ally to %.1fm from centre and it is STILL inside the room, so this " +
			"test cannot tell a fixed build from a broken one here") % [
			label, NAIVE_DEFAULT_RADIUS, corrected_distance])
	else:
		print(("%s: confirmed -- with the flat %.1fm default, hold_inside() corrects a displaced ally to " +
			"%.1fm from centre, OUTSIDE the room (OP21-25 reproduced); the fix is what prevents it") % [
			label, NAIVE_DEFAULT_RADIUS, corrected_distance])

	# Restore, and put the ally back at the (real, clamped) centre -- the
	# fight is about to be walked away from cleanly by `_end_fight_if_running()`.
	arena.set("radius", configured)
	participant.global_position = centre
	if participant is CharacterBody3D:
		(participant as CharacterBody3D).velocity = Vector3.ZERO


## Drive `participant` in `direction` for `PUSH_FRAMES` frames under both a
## sustained knockback impulse (`add_impulse`, the same call a hit reaction
## makes) and ordinary stick movement (`request_move`), and hand back how far
## from `centre` it ever got. Two channels because a fix that only guards one
## of them is still a leak -- OP21-25 names movement, switching, knockback
## and teleport as one lifecycle, not knockback alone.
func _push_and_measure(participant: Node3D, direction: Vector3, centre: Vector3) -> float:
	var furthest := 0.0
	for i in PUSH_FRAMES:
		if not is_instance_valid(participant):
			break
		if participant.has_method("add_impulse"):
			participant.call("add_impulse", direction, 14.0)
		if participant.has_method("request_move"):
			participant.call("request_move", direction)
		await physics_frame
		if not is_instance_valid(participant):
			break
		var offset: Vector3 = participant.global_position - centre
		offset.y = 0.0
		furthest = maxf(furthest, offset.length())
	return furthest


## --- getting into each fight ------------------------------------------------

## Teleported to within engage range rather than walked -- these two rooms
## sit hundreds of metres from where the player starts, and smoke_boss.gd's
## `_challenge_him()` already establishes that a direct approach is the
## accepted way to reach remote authored content in this test suite; what is
## under test here is containment, not traversal. The approach offset is
## along the BUILDING's own local axis (not a bare world-space nudge), so it
## stays correct regardless of the room's own site rotation
## (`burrow_warrens.json`'s 54.5-degree `site.yaw_deg`, in this case).
func _approach_and_engage_wild(building: Node3D, wild: Node3D) -> void:
	var back: Vector3 = -building.global_transform.basis.z
	back.y = 0.0
	back = back.normalized() if back.length() > 0.01 else Vector3.BACK
	var spot := wild.global_position + back * 2.0
	# The BUILDING's own `ground_height_at()`, not the world's: the world's
	# copy is raw Terrain3D height, which several metres underground (or
	# behind a fortress's own high walls) answers with the surrounding
	# hillside/sky, not the floor the wild creature is actually standing on.
	spot.y = _floor_height(building, spot)
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := wild.global_position - _player.global_position
	to.y = 0.0
	_aim_camera_along(to)

	var prompt := ""
	for i in 90:
		await physics_frame
		prompt = str(_director.call("prompt"))
		if prompt != "":
			break
	# Not asserted: the prompt string is a UI nicety and its own timing is
	# covered by smoke_combat.gd. `is_fighting()` after the press below, in
	# the caller, is the real gate on whether the engage worked.
	if prompt != "":
		print("warrens engage prompt: '%s'" % prompt)
	await _press("interact")
	for i in 30:
		await physics_frame


## The room's own floor under `spot`, falling back to `spot`'s own Y (the
## reference point, e.g. a body already correctly standing on that floor) if
## the building has no opinion -- never the world's raw terrain height, which
## is wrong for anything buried or roofed.
func _floor_height(building: Node3D, spot: Vector3) -> float:
	if building.has_method("ground_height_at"):
		var h := float(building.call("ground_height_at", spot.x, spot.z))
		if not is_nan(h):
			return h
	return spot.y


## Same shortcut as smoke_boss.gd's `_challenge_him()`: stand in front of the
## trainer, then press interact until their conversation resolves into a
## fight or the frame budget runs out.
## `chamber_id` biases the approach spot toward that chamber's own marker
## rather than the trainer's facing (smoke_boss.gd's `_challenge_him()` uses
## facing, which works in the Warden's cavernous room but overshoots the
## FAR wall in `tether_approach` -- 18m deep with the elite already standing
## 5m past its own centre -- landing the fight's own centre past the chamber
## and into the (still gated) passage beyond it, recognised by no room at
## all. Leaning toward the chamber's centre instead is guaranteed to move
## further INTO the room, never out of it.
func _challenge(building: Node3D, trainer: Node3D, chamber_id: String) -> void:
	var lean := Vector3.FORWARD
	if building.has_method("marker") and bool(building.call("has_marker", chamber_id)):
		var to_centre: Vector3 = building.call("marker", chamber_id) - trainer.global_position
		to_centre.y = 0.0
		if to_centre.length() > 0.5:
			lean = to_centre.normalized()
	var spot := trainer.global_position + lean * 2.6
	spot.y = _floor_height(building, spot)
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := trainer.global_position - _player.global_position
	to.y = 0.0
	_aim_camera_along(to)
	for i in 30:
		await physics_frame

	var presses := 0
	for i in 900:
		if bool(_manager.call("is_fighting")):
			break
		if presses == 0 or (_panel != null and bool(_panel.call("is_open"))):
			await _press("interact")
			presses += 1
			for n in 6:
				await physics_frame
			continue
		await physics_frame


func _aim_camera_along(direction: Vector3) -> void:
	if direction.length() > 0.01:
		_rig.set("yaw", atan2(-direction.x, -direction.z))


## Leave cleanly through Run -- "the only way out" per combat_arena.gd's own
## header -- so the second case does not open against a fight still winding
## down from the first.
func _end_fight_if_running() -> void:
	if not bool(_manager.call("is_fighting")):
		return
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await _press("combat_run")
		for n in 10:
			await physics_frame
	if bool(_manager.call("is_fighting")):
		_fail("could not leave the fight through Run to set up the next case")
	else:
		print("fight ended cleanly through Run")
	for i in 20:
		await physics_frame


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
		print("arena containment: OK -- Warrens and Stronghold fights hold participants inside a reachable, legal room.")
		quit(0)
		return
	for line in _failures:
		print("arena containment FAIL: %s" % line)
	quit(1)
