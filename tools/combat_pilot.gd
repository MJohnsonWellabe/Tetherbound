extends RefCounted

## T3-COMBAT. A player, played by a machine, through the real input path.
##
## Every probe in this lane needed the same thing: something that fights a
## Tetherbound fight the way a person does — steering the creature with the
## stick, aiming with the camera, pressing the same two attack actions a
## controller sends — so that what comes back is a statement about the game and
## not about the harness. Written once here rather than three times, because
## three copies would drift and the whole point of this lane is that two runs
## can be compared.
##
## What it deliberately does NOT do:
##
## - call `combat_manager` methods to attack. Presses go through
##   `Input.action_press`, so a broken binding shows up as a fight that never
##   lands a hit rather than as a green number.
## - heal, top up energy, or reposition by assignment mid-fight.
##   `tests/smoke_combat.gd::_fight_to_a_finish` heals the ally at 40% because
##   it is testing wiring; a probe that healed would be measuring a fight the
##   player cannot have.
## - decide the outcome. It plays until the manager says the fight is over.
##
## TWO PILOTS, and the difference between them is the measurement.
##
## `BRAWLER` walks at the opponent and hits it. That is what a new player does
## with two attack buttons and no read on the enemy's tells.
##
## `SPACER` plays the beat the fight is built around: `combat.json` gives the
## opponent a 0.55s telegraph, a 0.75s rooted recovery, and a 1.0s reposition,
## and `combat_ai.gd` roots it while it recovers. So SPACER backs out of reach
## when the wind-up ring lights, and spends its charged meter into the recovery
## window rather than at the first moment the meter is full.
##
## If those two pilots produce the same result, the fight has no skill in it and
## the telegraph is decoration. If SPACER never loses anything, the fight has no
## threat in it. Neither of those is visible from one pilot alone, which is why
## there are two.

enum Pilot {
	## Close and hit. No read on the opponent at all.
	BRAWLER,
	## Respect the telegraph, punish the recovery.
	SPACER,
}

## Frames a single fight may run before the probe gives up on it. At 60Hz this
## is two minutes of fight, far past anything the ladder should produce; a fight
## that reaches it is itself the finding.
const FIGHT_FRAME_LIMIT := 7200

var tree: SceneTree = null
var manager: Node = null
var director: Node = null
var rig: Node3D = null
var pilot: Pilot = Pilot.SPACER

## Set true to let the pilot switch creatures when the HUD's own matchup arrow
## says the active one is at a disadvantage. Off by default so "does switching
## matter" is a controlled comparison rather than something baked into every
## measurement.
var use_switching: bool = false

## Live tallies, reset by `reset_tally()` and read after a fight.
var hits_dealt: int = 0
var hits_taken: int = 0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0
var misses: int = 0
## Effectiveness verdicts the fight actually emitted, as `{tier: count}` for
## hits on the enemy. The chart reaching the player, counted rather than assumed.
var verdicts_on_enemy: Dictionary = {}
var verdicts_on_ally: Dictionary = {}
var switches: int = 0
var charged_thrown: int = 0
var quick_thrown: int = 0
## Frames spent inside a fight, so a duration can be reported in seconds.
var fight_frames: int = 0

var _connected: bool = false


func _init(scene_tree: SceneTree, combat_manager: Node, encounter_director: Node,
		camera_rig: Node3D) -> void:
	tree = scene_tree
	manager = combat_manager
	director = encounter_director
	rig = camera_rig


## Attach to the manager's signals. Called once; the probes reuse one pilot
## across many fights so the connections outlive any single fight.
func listen() -> void:
	if _connected or manager == null:
		return
	_connected = true
	manager.connect("hit_landed", func(on_enemy: bool, amount: float) -> void:
		if on_enemy:
			hits_dealt += 1
			damage_dealt += amount
		else:
			hits_taken += 1
			damage_taken += amount)
	manager.connect("attack_missed", func(_by_player: bool) -> void: misses += 1)
	manager.connect("hit_effectiveness", func(on_enemy: bool, tier: int) -> void:
		var into: Dictionary = verdicts_on_enemy if on_enemy else verdicts_on_ally
		into[tier] = int(into.get(tier, 0)) + 1)


func reset_tally() -> void:
	hits_dealt = 0
	hits_taken = 0
	damage_dealt = 0.0
	damage_taken = 0.0
	misses = 0
	verdicts_on_enemy = {}
	verdicts_on_ally = {}
	switches = 0
	charged_thrown = 0
	quick_thrown = 0
	fight_frames = 0


## Point the camera so that "forward" means this direction — the same path the
## player's right stick takes, so a broken planar basis breaks the pilot too.
func aim_along(direction: Vector3) -> void:
	if rig == null:
		return
	var flat := direction
	flat.y = 0.0
	if flat.length() < 0.001:
		return
	rig.set("yaw", atan2(-flat.x, -flat.z))


## Walk the TRAINER to a world position under real stick input. Used to reach a
## staged encounter rather than teleporting onto it, because a creature standing
## somewhere the player cannot walk to is a fight that does not exist.
## `target` may be a Vector3 or a Node3D. Pass the NODE when walking to a
## creature: a wild creature wanders, and an aggressive one closes on the
## trainer, so a position snapshotted before the walk is a spot the creature has
## already left by the time you arrive. That cost this lane one probe row —
## "6.1m away after covering 8.6m" against an Ashtusk that had walked out from
## under its own coordinates.
func walk_trainer_to(player: CharacterBody3D, target: Variant, within: float,
		max_frames: int = 1200) -> float:
	for i in max_frames:
		# A creature that started the fight itself has already ended the walk.
		if manager != null and bool(manager.call("is_fighting")):
			break
		var to := _where(target) - player.global_position
		to.y = 0.0
		if to.length() <= within:
			break
		aim_along(to)
		Input.action_press("move_forward")
		await tree.physics_frame
	Input.action_release("move_forward")
	for i in 6:
		await tree.physics_frame
	var flat := _where(target) - player.global_position
	flat.y = 0.0
	return flat.length()


func _where(target: Variant) -> Vector3:
	if target is Node3D and is_instance_valid(target as Node3D):
		return (target as Node3D).global_position
	return target as Vector3 if target is Vector3 else Vector3.ZERO


## Fight the fight that is already running, to its end.
##
## Returns a dictionary describing what happened. `outcome` is the manager's own
## word, never this file's opinion of it.
func fight_to_the_end() -> Dictionary:
	var frames := 0
	var ally_body: Node3D = director.call("ally_body") as Node3D
	while bool(manager.call("is_fighting")) and frames < FIGHT_FRAME_LIMIT:
		ally_body = director.call("ally_body") as Node3D
		var foe_body: Node3D = manager.call("enemy_body") as Node3D
		if ally_body == null or foe_body == null or not is_instance_valid(foe_body):
			await tree.physics_frame
			frames += 1
			continue
		await _act(ally_body, foe_body)
		frames += 1
	fight_frames += frames
	Input.action_release("move_forward")
	Input.action_release("move_back")
	return {
		"outcome": str(manager.call("outcome")),
		"frames": frames,
		"timed_out": frames >= FIGHT_FRAME_LIMIT,
	}


## One frame of play.
func _act(ally_body: Node3D, foe_body: Node3D) -> void:
	var to := foe_body.global_position - ally_body.global_position
	to.y = 0.0
	var gap := to.length()
	var reach := _reach(ally_body, foe_body)

	if use_switching and _should_switch():
		if bool(manager.call("cycle_active", 1)):
			switches += 1
			for i in 4:
				await tree.physics_frame
			return

	# The whole difference between the two pilots. SPACER treats the wind-up
	# ring as information; BRAWLER never looks at it.
	if pilot == Pilot.SPACER and bool(manager.call("enemy_is_winding_up")) \
			and gap < _enemy_reach(ally_body, foe_body) + 0.8:
		aim_along(-to)
		Input.action_press("move_forward")
		await tree.physics_frame
		Input.action_release("move_forward")
		return

	aim_along(to)
	# Comfortably inside reach rather than on its edge, so a knockback or the
	# opponent's own step does not turn the swing into a whiff.
	if gap > reach * 0.8:
		Input.action_press("move_forward")
		await tree.physics_frame
		Input.action_release("move_forward")
		return

	# In range. Which button, and when.
	if bool(manager.call("charged_ready")) and _charged_is_worth_it():
		charged_thrown += 1
		await press("combat_charged")
		return
	if bool(manager.call("quick_ready")):
		quick_thrown += 1
		await press("combat_quick")
		return
	await tree.physics_frame


## SPACER spends the meter into the punish window the AI's own recovery opens;
## BRAWLER spends it the instant it is full.
func _charged_is_worth_it() -> bool:
	if pilot == Pilot.BRAWLER:
		return true
	return bool(manager.call("enemy_is_rooted")) or not bool(manager.call("enemy_is_winding_up"))


## The HUD's own arrow, not a private lookup: if the game tells the player the
## matchup is bad, the pilot acts on exactly that.
func _should_switch() -> bool:
	if not bool(manager.call("can_switch")):
		return false
	if int(manager.call("active_matchup")) >= 0:
		return false
	var options: Array = manager.call("switchable_indices")
	return not options.is_empty()


## How far the player's quick attack ACTUALLY reaches between these two bodies.
##
## Not `combat.json`'s flat `player_quick.range`. `combat_manager.gd::
## _with_reach_for_the_bodies()` grows the reach with the two creatures' radii,
## because `enemy.body_clearance` (2.75) already holds them that far apart:
## against a Meadowhart the real reach is 4.63m, not the configured 2.6m.
##
## This cost the lane a whole ladder run and is worth recording. A pilot closing
## to a fraction of the FLAT 2.6m is trying to stand 1.56m from a creature whose
## own capsule stops it at 1.50m — so against a large opponent it walks into the
## body forever and never presses attack. The symptom in the log was a rung
## reported as a loss with **0 hits dealt and 22 taken in 59.8 seconds**, which
## reads exactly like a brutal fight and was actually a broken measurement. Any
## probe that closes on a distance must ask the same question the manager asks.
func _reach(ally_body: Node3D, foe_body: Node3D) -> float:
	return _spaced(float(_config().get("player_quick", {}).get("range", 2.6)),
		ally_body, foe_body)


## The same, for the opponent's swing — `wild_creature.gd::_spaced_config()`
## floors its `range` off the identical clearance rule, so the distance SPACER
## has to be outside of to dodge a wind-up grows with the bodies too.
func _enemy_reach(ally_body: Node3D, foe_body: Node3D) -> float:
	return _spaced(float(_config().get("enemy", {}).get("range", 2.6)),
		ally_body, foe_body)


func _spaced(base: float, ally_body: Node3D, foe_body: Node3D) -> float:
	var mine := 0.5
	var theirs := 0.5
	if ally_body != null and ally_body.has_method("body_radius"):
		mine = float(ally_body.call("body_radius"))
	if foe_body != null and foe_body.has_method("body_radius"):
		theirs = float(foe_body.call("body_radius"))
	var clearance := float(_config().get("enemy", {}).get("body_clearance", 1.35))
	return maxf(base, (mine + theirs) * clearance + 0.5)


## `combat_math.gd` caches the parsed file itself, but this is read four times
## per physics frame across a whole ladder, so the script lookup is held too.
var _math: GDScript = null


func _config() -> Dictionary:
	if _math == null:
		_math = load("res://scripts/combat/combat_math.gd") as GDScript
	return _math.call("config")


## Hold for two physics frames before releasing: `is_action_just_pressed` is
## scoped to the frame the press landed in.
func press(action: String) -> void:
	Input.action_press(action)
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release(action)
	await tree.physics_frame
