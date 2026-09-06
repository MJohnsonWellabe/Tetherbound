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
##
## A third case, added by lane MP-F1-F2 (finding F2): a fight must also FORM
## inside the room, not merely be held inside one once it has. `_place_fighters()`
## stages the whole fight `deploy_offset + separation` (~7.6 m) in front of
## wherever the player engaged, and the Warden stands 5 m from the back wall of
## his own arena -- so a fight taken up beside him used to form 4-5 m OUTSIDE the
## room, where there is no floor collider at all but `stronghold.gd::
## built_floor_height_at()` still answers the room's floor height. Every body was
## seated at y 6.172 and then fell ~8 m. Measured on the unfixed tree, at the spot
## `tools/net/peer_runner.gd::_step_trainer_battle` stands a challenger on:
##
##     player    (8.49, -0.363, 7667.24)  arena_r -1.00  OUTSIDE the room
##     ally     (11.62,  6.173, 7661.71)  arena_r  0.50  inside
##     opponent (13.25, -1.124, 7665.10)  arena_r -1.00  OUTSIDE the room
##
## The player and the boss six and a half metres under the floor their fight is
## being held on, on opposite sides of a wall from the player's own creature.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const ARENA_TRAINERS := preload("res://scripts/world/trainer_npc.gd")

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
## How many assertions the Warden-Arena staging case below actually RAN. A break
## that makes a test run FEWER assertions is a function aborting, not a test
## failing, so the count is reported next to the failures on every run.
var _staging_checks: int = 0
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
	# LAST, deliberately: a trainer battle cannot be left through Run (that is
	# `smoke_trainer_battle.gd`'s own assertion), so `_end_fight_if_running()`
	# cannot clean up after this one and nothing may be staged behind it.
	await _warden_arena_staging_case()
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

	await _approach_and_engage_wild(warrens, wild, "mouth")
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


## --- the Warden Arena: where a fight FORMS ----------------------------------

## `data/config/combat.json`'s own staging numbers, read here rather than
## hard-coded, because the claim is about this room against THESE offsets and a
## designer who retunes either has to see this move with them.
const ARENA_CONFIG := "res://data/config/combat.json"
## How far off the room's floor a body may rest and still be standing on it.
## `place_on_ground()` seats at the built floor exactly (6.172 measured) and a
## settled body rests within a millimetre of it; anything past this is the fall
## this case exists to catch, which is metres.
const ON_THE_FLOOR_M := 0.35
## Long enough for a body seated on a claimed floor with no collider under it to
## be unmistakably falling. The measured drop is ~8 m, and `creature_body.gd`
## grounds on `is_on_floor()`, so 120 frames is several times what it needs.
const FALL_FRAMES := 120


func _warden_arena_staging_case() -> void:
	var stronghold: Node3D = _world.get_node_or_null(^"Stronghold") as Node3D
	if stronghold == null:
		_fail("the world built no Stronghold node; the Warden Arena staging case cannot run")
		return
	var warden := _body_for_trainer("warden_aldis")
	if warden == null:
		_fail("'warden_aldis' was never stood up; the Warden Arena staging case cannot run")
		return
	var spec: Dictionary = ARENA_TRAINERS.trainer("warden_aldis")
	if spec.is_empty():
		_fail("trainers.json has no 'warden_aldis'")
		return

	var floor_y := float(stronghold.call("built_floor_height_at",
		warden.global_position.x, warden.global_position.z))
	if is_nan(floor_y):
		_fail("the stronghold claims no floor under the Warden himself; nothing below can be measured")
		return
	print("warden_aldis stands at %s; his arena's floor is y=%.3f" % [
		str(warden.global_position), floor_y])

	# The spot `tools/net/peer_runner.gd::_step_trainer_battle()` stands a
	# challenger on, and the spot F2 was measured at: beside him, a stride out
	# on each axis. Chosen because it is the configuration that was measured
	# rather than one invented here -- and it is a spot a player who walked past
	# him can stand on, which is the whole reason it matters.
	_player.global_position = warden.global_position + Vector3(2.0, 0.0, 2.0)
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	var start_radius := float(stronghold.call("combat_arena_bounds_at",
		_player.global_position.x, _player.global_position.z))
	_staging_check(start_radius > 0.0,
		"the challenger does not even start inside the Warden Arena (%s, radius %.2f); this probe would prove nothing"
			% [str(_player.global_position), start_radius])
	if start_radius <= 0.0:
		return

	# Two fights already happened above and this case is not about surviving a
	# third: the ally is put back on its feet exactly the way every other combat
	# smoke in this repo tops its creature up, so `can_challenge()` refuses for a
	# reason that is about the Warden rather than about the last two rooms.
	await _revive_the_ally()

	# The production call. `stronghold_climax.gd` makes exactly this one, and
	# `data/config/stronghold_climax.json` says so in its own words: "There is no
	# boss combat mode and there is no boss script." The dialogue in front of it
	# is `smoke_boss.gd`'s ground; this case is about the geometry the fight
	# forms on.
	var began := bool(_director.call("begin_trainer_battle", spec, warden))
	_staging_check(began,
		("begin_trainer_battle('warden_aldis') refused (fighting: %s, battle active: %s, no usable ally: %s, "
			+ "too low: %s, already beaten: %s); nothing below this point was tested")
			% [str(_manager.call("is_fighting")), str(_director.call("trainer_battle_active")),
			   str(_director.call("no_usable_ally")), str(_director.call("too_low_to_challenge", spec)),
			   str(ARENA_TRAINERS.already_beaten(spec, _progression_store()))])
	if not began:
		return
	for i in 45:
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("the Warden challenge did not open a fight; nothing below this point was tested")
		return

	var ally: Node3D = _director.call("ally_body") as Node3D
	var opponent := _world.find_child("TrainerCreature_warden_aldis_*", true, false) as Node3D
	if ally == null or opponent == null:
		_fail("the Warden fight opened without both bodies on the field")
		return

	# THE CHECK THAT KEEPS THE THREE BELOW HONEST. Containment only ever
	# SHORTENS the staging along the axis the fight formed on, so the axis is
	# still readable off the opponent -- and this asserts that the room really
	# does end before the full, unshortened staging span reaches. Without it,
	# a room that happened to be big enough would pass the floor checks below
	# while proving nothing at all about containment.
	var axis := opponent.global_position - _player.global_position
	axis.y = 0.0
	if axis.length() < 0.01:
		_fail("the fight formed on top of the player; there is no staging axis to measure")
		return
	axis = axis.normalized()
	var cfg: Dictionary = _arena_staging_config()
	var span := float(cfg.get("deploy_offset", 2.6)) + float(cfg.get("separation", 5.0))
	var uncontained := _player.global_position + axis * span
	var uncontained_r := float(stronghold.call("combat_arena_bounds_at", uncontained.x, uncontained.z))
	_staging_check(uncontained_r <= 0.0,
		("the unshortened staging point %s is still inside the Warden Arena (radius %.2f), so this case "
			+ "cannot tell a contained fight from an uncontained one -- combat.json's deploy_offset+separation "
			+ "is %.2f m and the room has grown past it") % [str(uncontained), uncontained_r, span])
	if uncontained_r > 0.0:
		return
	print("the full %.2f m staging span reaches %s, which the room does NOT claim (radius %.2f)" % [
		span, str(uncontained), uncontained_r])

	_every_body_stands_in_the_arena(stronghold, floor_y, ally, opponent, "as the fight opened")
	for i in FALL_FRAMES:
		await physics_frame
	_every_body_stands_in_the_arena(stronghold, floor_y, ally, opponent,
		"after %d frames" % FALL_FRAMES)


## The player, their creature and the Warden's creature: all three inside the
## room the challenge was taken up in, and all three standing on its floor.
##
## Both halves are asserted separately on purpose. "Inside the room" alone would
## pass a body seated on the floor CLAIM in mid-air over the margin; "on the
## floor" alone would pass a body that had walked out of the room onto ground
## that happens to be at the same height.
func _every_body_stands_in_the_arena(stronghold: Node3D, floor_y: float,
		ally: Node3D, opponent: Node3D, when: String) -> void:
	var failures_before := _failures.size()
	for row: Array in [["the player", _player], ["their creature", ally],
			["the Warden's creature", opponent]]:
		var who := str(row[0])
		var body: Node3D = row[1] as Node3D
		var alive := body != null and is_instance_valid(body)
		_staging_check(alive, "%s left the field %s" % [who, when])
		if not alive:
			continue
		var at := body.global_position
		var radius := float(stronghold.call("combat_arena_bounds_at", at.x, at.z))
		_staging_check(radius > 0.0,
			("%s is OUTSIDE the Warden Arena %s, at %s -- the room does not claim that spot, "
				+ "so the floor it was seated on has no collider under it") % [who, when, str(at)])
		var drop := absf(at.y - floor_y)
		_staging_check(drop <= ON_THE_FLOOR_M,
			"%s is %.3f m off the Warden Arena's floor %s (body y %.3f, floor y %.3f)"
				% [who, drop, when, at.y, floor_y])
	if _failures.size() == failures_before:
		print("all three bodies stand inside the Warden Arena, on its floor, %s" % when)


## `combat.json`'s `arena` block, read the same way `combat_manager.gd` reads it.
func _arena_staging_config() -> Dictionary:
	var file := FileAccess.open(ARENA_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var block: Variant = (parsed as Dictionary).get("arena", {})
	return block as Dictionary if block is Dictionary else {}


## The Warden is placed by `stronghold_climax.gd`, not by the stronghold's own
## gauntlet node, so he is found the way `tools/net/peer_runner.gd` finds him --
## by asking every node in the world that answers to `body_for`.
func _body_for_trainer(trainer_id: String) -> Node3D:
	for node in _world.find_children("*", "Node3D", true, false):
		if not is_instance_valid(node) or not node.has_method("body_for"):
			continue
		var found: Variant = node.call("body_for", trainer_id)
		if found != null and is_instance_valid(found):
			return found as Node3D
	return null


## Put the player's creature back on its feet between cases. The same allowance
## `smoke_boss.gd` and `smoke_trainer_battle.gd` make (`mine.hp = mine.max_hp`),
## for the same reason: these files test WIRING, not whether a starter can
## survive three rooms of the fortress back to back.
func _revive_the_ally() -> void:
	var ally: RefCounted = _director.call("ally_instance") as RefCounted
	if ally != null:
		ally.set("fainted", false)
		ally.set("hp", float(ally.get("max_hp")))
	if _director.call("ally_body") == null:
		await _director.call("adopt_starter", "terrapup")
	for i in 20:
		await physics_frame


func _progression_store() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("progression") as RefCounted if game != null else null


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
func _approach_and_engage_wild(building: Node3D, wild: Node3D, chamber_id := "") -> void:
	# Put the resident back on its own chamber's marker before measuring
	# anything off it.
	#
	# This spawns `aggressive: true` (data/config/burrow_warrens.json) and has
	# been charging since world load, so where it stands at this instant is a
	# function of how many physics frames the host got through -- not of
	# anything this file tests. `spot` below is computed FROM that body, so the
	# drift lands on the player, and `_floor_height()` cannot catch it: outside
	# the footprint `ground_height_at()` answers with the hillside above rather
	# than NaN, so the fallback never fires and the player is placed underground.
	#
	# Measured, three local runs of this file plus CI run 2463: the arena centre
	# walked to local z = 6.50, 8.41, 10.09 against a `mouth` chamber that ends
	# at z = 11, affording 0.9m, 1.6m and 0.5m of radius. CI reached z = 11.03 --
	# 3cm past the wall -- with the player at local x = -5.10 against a wall at
	# -3.5, i.e. inside solid rock, 2m below the cave floor. `combat_arena_bounds_at()`
	# then returned -1.0 and the run went red on a branch that touches no
	# gameplay code. The margin shrinks as the host slows, so this is a cliff
	# edge rather than a rare flake.
	#
	# The marker is the chamber's own centre (`burrow_warrens.gd:144`), which is
	# the furthest point from every wall it has, so the fight opens with room to
	# spare on every host. Nothing about the containment assertions changes --
	# all three parts below run against the same real physics; only WHERE the
	# fight starts stops being a race.
	if chamber_id != "" and building.has_method("marker"):
		wild.global_position = building.call("marker", chamber_id)
		if wild is CharacterBody3D:
			(wild as CharacterBody3D).velocity = Vector3.ZERO
		await physics_frame

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


## One assertion of the Warden-Arena staging case, counted whether it passes or
## fails, so a run that silently stopped asserting is visible in the report.
func _staging_check(ok: bool, message: String) -> void:
	_staging_checks += 1
	if not ok:
		_fail(message)


func _report() -> void:
	print("")
	print("Warden Arena staging: %d assertion(s) run" % _staging_checks)
	if _failures.is_empty():
		print("arena containment: OK -- Warrens and Stronghold fights FORM inside a reachable, legal room and hold participants inside it.")
		quit(0)
		return
	for line in _failures:
		print("arena containment FAIL: %s" % line)
	quit(1)
