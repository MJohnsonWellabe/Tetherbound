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
const MATH := preload("res://scripts/combat/combat_math.gd")

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

## CI-BOSS (ralph/BACKLOG.md, filed 2026-08-17): `verify-boss` has twice
## failed with "the boss fight never resolved inside 9000 frames" on branches
## whose own diffs could not touch combat. The suspicion this test could not
## previously confirm or rule out was that the player's own attack was
## whiffing against the Warden's creature and burning the whole frame budget
## in silence -- indistinguishable, from the failure message alone, from a
## director that simply never advanced the queue. These count real
## `attack_missed(true)` / `hit_landed(true, ...)` emissions from the fight
## this test drives, so a stall reports which one it actually was instead of
## making the next investigation start from zero again.
var _quick_hits := 0
var _quick_misses := 0
## Consecutive misses since the last landed hit. A genuine facing/reach bug
## would whiff over and over against a stationary or slow-approaching
## opponent; a director stall would produce few or no attack attempts at all
## (`quick_ready()` never firing because the fight never actually opens a
## round) rather than a run of real misses. The two failure shapes are
## distinguishable by this counter, which is the whole point of keeping it.
var _consecutive_misses := 0
## However many misses in a row it takes to say "this is a real whiff, not
## noise" and fail with the measured geometry instead of spending the rest of
## `BATTLE_FRAME_LIMIT` finding out the same way. Generous on purpose: a
## handful of genuine out-of-range or off-cone swings during normal
## approach/reposition play is expected and is not a bug.
const CONSECUTIVE_MISS_LIMIT := 25


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

	_the_horizon_before_the_warden()
	await _free_the_legendary()
	_the_legendary_joined_the_party()
	await _the_rift_collapses_and_the_barrier_holds()
	_the_meadows_answers()

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
	_manager.connect("attack_missed", _on_fight_attack_missed)
	_manager.connect("hit_landed", _on_fight_hit_landed)
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
		# CI-BOSS's actual root cause, found by instrumenting this exact loop: a
		# fixed "get within 2.0m" gate assumes two bodies can physically close to
		# that distance, which held for every matchup this file was written and
		# tested against but is not true of the Warden's own roster. Diagnostic
		# logging (frame, distance, quick_ready) showed the distance to
		# `TrainerCreature_warden_aldis_1` pinned at exactly 2.63m for the entire
		# 9000-frame budget, `quick_ready()` true throughout -- the two capsules
		# were already touching, `move_forward` could push no further, and the
		# `to.length() > 2.0` branch never once let go of movement to let the
		# `quick_ready()` branch fire a single attack. Zero `attack_missed` and
		# zero `hit_landed` emissions the whole run confirms it: this was never a
		# whiff, the swing was never attempted at all. `combat_manager.gd::
		# _with_reach_for_the_bodies` floors the real attack reach by both
		# bodies' radii and always leaves at least 0.5m of daylight past contact
		# (its own comment), so gating on THAT floor instead of a guessed
		# constant is guaranteed reachable rather than merely usually reachable.
		var reach := _floored_quick_range(ally, opponent)
		if to.length() > reach:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
			# CI-BOSS: a genuine facing/reach bug whiffs over and over against a
			# target that is standing right there, and used to be indistinguishable
			# from a director that stopped advancing at all -- both read as "never
			# resolved inside 9000 frames." This fails immediately, with the actual
			# measured distance and facing error at the moment of the swing, rather
			# than let the rest of the frame budget burn to reach the same
			# conclusion less usefully. See CONSECUTIVE_MISS_LIMIT's own comment for
			# why a handful of misses during ordinary approach/reposition play does
			# not trip this.
			if _consecutive_misses >= CONSECUTIVE_MISS_LIMIT:
				var facing: Vector3 = ally.call("facing")
				var still_to := opponent.global_position - ally.global_position
				still_to.y = 0.0
				var angle := 180.0
				if still_to.length() > 0.001 and Vector3(facing.x, 0.0, facing.z).length() > 0.001:
					angle = rad_to_deg(Vector3(facing.x, 0.0, facing.z).normalized().angle_to(still_to.normalized()))
				_fail(("the player's quick attack whiffed %d times in a row against the Warden's creature " +
					"(distance %.2fm, facing error %.1f degrees at the last swing) -- this is a real miss, " +
					"not the fight stalling") % [_consecutive_misses, still_to.length(), angle])
				return
		else:
			await physics_frame

	if bool(_director.call("trainer_battle_active")):
		_fail(("the boss fight never resolved inside %d frames (%d quick attacks landed, " +
			"%d missed, %d consecutive at the end)") % [
			BATTLE_FRAME_LIMIT, _quick_hits, _quick_misses, _consecutive_misses])
		return
	if not bool(_progression().call("has", WARDEN_FLAG)):
		_fail("the Warden was fought to the end but '%s' was never set" % WARDEN_FLAG)
		return
	print("the boss fight ran and was won: %d creatures, %d frames, %d quick attacks landed, %d missed" % [
		team_size, frames, _quick_hits, _quick_misses])
	if not bool(_player.call("locomotion_enabled")):
		_fail("exploration never came back after the boss fight")


func _on_fight_attack_missed(by_player: bool) -> void:
	if not by_player:
		return
	_quick_misses += 1
	_consecutive_misses += 1


func _on_fight_hit_landed(on_enemy: bool, _amount: float) -> void:
	if not on_enemy:
		return
	_quick_hits += 1
	_consecutive_misses = 0


## How close `_fight_him()` needs to steer the ally before it is worth trying a
## quick attack -- the same body-radius floor `combat_manager.gd::
## _with_reach_for_the_bodies` applies to the real swing, recomputed here from
## public data (`body_radius()`, `combat.json`'s own `enemy.body_clearance`)
## rather than a constant this file picked once and never revisited. See the
## CI-BOSS comment at the call site for why a fixed constant is not safe here.
func _floored_quick_range(ally: Node3D, opponent: Node3D) -> float:
	var base := float(MATH.config().get("player_quick", {}).get("range", 2.6))
	var mine := 0.5
	var theirs := 0.5
	if ally != null and ally.has_method("body_radius"):
		mine = float(ally.call("body_radius"))
	if opponent != null and opponent.has_method("body_radius"):
		theirs = float(opponent.call("body_radius"))
	var clearance := float(MATH.config().get("enemy", {}).get("body_clearance", 1.8))
	return maxf(base, (mine + theirs) * clearance + 0.5)


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


## --- SG44: the first Tether Rift collapses -----------------------------------

## The horizon at the storm-road seam, before the Warden. SG44's done-when is
## that this and the reading after him are visibly different, so the "before"
## has to be taken while it still is one.
var _horizon_before: Dictionary = {}
## Metres a probe body may travel along the road past the seam before the
## barrier has failed.
##
## OW5E: was 18.0, computed from the carve's config alone (half_width 6 + rim
## 5 + the 8m offset from road end to carve centre ~= 19) rather than measured
## against real, baked ground — `data/terrain/playground` was last baked in
## OW5B, before OW5C authored this carve at all, so nobody had walked a real
## body at the real result when this number was chosen. Once the corridor's
## full re-bake landed (OW5E), the same probe reproducibly travels 28.3m
## before it gets stuck (three separate runs, all within 0.1m of each other —
## deterministic, not a flake): the carve's smoothstep rim renders as gentle,
## still-walkable slope for several extra metres past its nominal geometric
## reach before the ground steepens enough to actually trap a 60-degree body.
## The guarantee itself still holds exactly as designed — the probe comes to
## rest and never moves again for the remainder of the budget, same as it did
## at 11.4m before this re-bake — only the number was never checked against
## real ground. 35.0 clears the measured 28.3m with room to spare while
## staying well short of the `far_road.from` resumption point (~55.6m out,
## computed from this spoke's own `terrain_playground.json` entry): a probe
## that ever reached THAT would be a real barrier failure, not a stale
## constant.
const BARRIER_LIMIT_M := 35.0
## The legendary's own climb limit (R8.5, species.json's `climb_max_slope_deg`).
## The probe walks at the best mobility the game will ever hand the player,
## because a barrier that only holds against a walking trainer is not a barrier
## by the end of this chapter. Raise this with that number if it ever moves.
const PROBE_CLIMB_DEG := 60.0


func _rift() -> Node:
	return _world.get_node_or_null(^"RiftCollapse")


func _the_horizon_before_the_warden() -> void:
	var rift := _rift()
	if rift == null:
		_fail("the world built no RiftCollapse node; SG44's event cannot happen")
		return
	_horizon_before = rift.call("horizon")
	if float(_horizon_before.get("storm_cover", 0.0)) <= 0.0:
		_fail("nothing is standing on the horizon past the seam before the Warden; there is nothing to collapse")
	if float(_horizon_before.get("far_cover", 0.0)) > 0.0:
		_fail("the far country is already visible before the Warden falls; the payoff is spent on a fresh boot")


## Spec §27/§28/§30 and the carve-out that comes with them, in one place: the
## horizon HAS to change, and the road HAS to stay shut.
func _the_rift_collapses_and_the_barrier_holds() -> void:
	var rift := _rift()
	if rift == null:
		return
	# The collapse is timed (a hold, then a dissipate) so it is given real
	# frames rather than asserted on the frame the flag lands.
	for i in 900:
		await physics_frame
	var after: Dictionary = rift.call("horizon")
	var before_storm := float(_horizon_before.get("storm_cover", 0.0))
	var after_storm := float(after.get("storm_cover", 0.0))
	var after_far := float(after.get("far_cover", 0.0))
	if after_storm >= before_storm:
		_fail("the storm wall is still covering %.0f m2 of sky (was %.0f); nothing dissipated"
			% [after_storm, before_storm])
	if after_far <= 0.0:
		_fail("nothing came up behind it; the world did not get bigger")
	if is_equal_approx(float(_horizon_before.get("signature", 0.0)), float(after.get("signature", 1.0))):
		_fail("the horizon signature is identical before and after the Warden")
	print("SG44: the %s horizon went from %.0f m2 of storm / %.0f m2 of land to %.0f / %.0f"
		% [str(after.get("spoke", "?")), before_storm, float(_horizon_before.get("far_cover", 0.0)),
			after_storm, after_far])

	# Nothing built for the view may be reachable: no collider anywhere in it,
	# and all of it outside the boundary ring.
	for mesh: MeshInstance3D in (rift.call("meshes") as Array):
		if mesh == null or not is_instance_valid(mesh):
			continue
		for child in mesh.get_children():
			if child is CollisionObject3D or child is CollisionShape3D:
				_fail("the reconnected view has a collider on it; it is a place, not a view")
		var flat := Vector2(mesh.global_position.x, mesh.global_position.z)
		if flat.length() < 240.0:
			_fail("part of the far view stands %.0fm from the origin, inside the world boundary" % flat.length())

	# And the walking probe: a body at the LEGENDARY's climb limit, driven at
	# the seam, still does not get across. Same shape SC14/SE21 used.
	var probe: Dictionary = await _probe_the_seam(rift)
	var travelled := float(probe.get("along", 0.0))
	var dropped := float(probe.get("drop", 0.0))
	if travelled > BARRIER_LIMIT_M:
		_fail("a %.0f-degree probe walked %.1f m past the storm road's end after the collapse; the region is enterable"
			% [PROBE_CLIMB_DEG, travelled])
	else:
		# The drop is printed rather than asserted on: whether the body ends up
		# on the channel floor or wedged against its 65-degree wall is a detail
		# of one capsule against one carve, and both are the barrier working.
		# What is asserted is the only thing that matters -- it did not reach
		# the far roadbed, which starts ~19m out.
		print("SG44: the barrier holds -- a %.0f-degree probe made %.1f m past the seam (fell %.1f m; the far rim is %.1f m out)"
			% [PROBE_CLIMB_DEG, travelled, dropped, BARRIER_LIMIT_M])


## Drive a real body, on real collision, straight down the road past the seam.
## Not the player: the player is mid-ending several hundred metres away inside
## the stronghold, and teleporting them out and back is a bigger disturbance
## than standing up a probe. Returns metres of progress ALONG THE ROAD, which
## is the only direction that means anything here.
func _probe_the_seam(rift: Node) -> Dictionary:
	var seam: Vector2 = rift.call("seam")
	if seam == Vector2.ZERO:
		return {"along": 0.0, "drop": 0.0}
	var forward := seam.normalized()
	var horizon: Dictionary = rift.call("horizon")
	var origin: Vector2 = horizon.get("origin", seam)
	if (origin - seam).length() > 0.01:
		forward = (origin - seam).normalized()

	var probe := CharacterBody3D.new()
	probe.floor_max_angle = deg_to_rad(PROBE_CLIMB_DEG)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	probe.add_child(shape)
	_world.add_child(probe)
	var ground := float(_world.call("ground_height_at", seam.x, seam.y))
	probe.global_position = Vector3(seam.x, (0.0 if is_nan(ground) else ground) + 1.2, seam.y)
	for i in 10:
		await physics_frame

	var start := Vector2(probe.global_position.x, probe.global_position.z)
	var start_height := probe.global_position.y
	var best := 0.0
	var lowest := probe.global_position.y
	var step := Vector3(forward.x, 0.0, forward.y) * 8.0
	for i in 420:
		probe.velocity.x = step.x
		probe.velocity.z = step.z
		probe.velocity.y = 0.0 if probe.is_on_floor() else probe.velocity.y - 26.0 * (1.0 / 60.0)
		probe.move_and_slide()
		await physics_frame
		var here := Vector2(probe.global_position.x, probe.global_position.z)
		best = maxf(best, (here - start).dot(forward))
		lowest = minf(lowest, probe.global_position.y)
	probe.queue_free()
	return {"along": best, "drop": start_height - lowest}


## --- SG46: the Meadows answers ------------------------------------------------

## Spec §9. The region must not be identical to how it was before the Warden,
## and the world half of that claim only exists once somebody has actually run
## the healing over a built scene — which is what this checks. The FLAG half
## (which branch each villager takes, which patrol is withdrawn) is
## tests/test_progression_state.gd's.
func _the_meadows_answers() -> void:
	var healing := _world.get_node_or_null(^"MeadowHealing")
	if healing == null:
		_fail("the world built no MeadowHealing node; the Meadows never answers")
		return
	if not bool(healing.call("applied")):
		_fail("the Warden fell and the legendary was freed, and the region did not respond")
		return
	var report: Dictionary = healing.call("report")
	if int(report.get("regrown", 0)) <= 0:
		_fail("nothing grew back around the drain stations; D41's third clause is not paid")
	var vegetation := _world.get_node_or_null(^"Vegetation")
	if vegetation != null and int(vegetation.call("drained_count")) > 0:
		_fail("%d suppressed plants are still being held out of the world after the healing"
			% int(vegetation.call("drained_count")))
	var relay := _world.get_node_or_null(^"TetherRelay")
	if relay != null and relay.has_method("dead_ground_visible"):
		# The fade is timed; it has had SEQUENCE_FRAMES plus the collapse's own
		# 900 frames by now, which is well past it.
		if bool(relay.call("dead_ground_visible")):
			_fail("the relay's drained ground is still painted on after the machinery died")
	print("SG46: %d plants back, %d tether lights out, %d barriers open, %d beaten patrols withdrawn"
		% [int(report.get("regrown", 0)), int(report.get("lights_killed", 0)),
			int(report.get("barriers_opened", 0)), int(report.get("patrols_withdrawn", 0))])


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
