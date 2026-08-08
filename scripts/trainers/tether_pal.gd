extends "res://scripts/pals/wild_pal.gd"

## A creature an opposing trainer owns.
##
## Physically the same thing as a wild pal — it fights with the same brain, the
## same body, the same arithmetic, and `CombatManager` cannot tell the two apart
## and should not have to. Three things differ, and each is one of this
## milestone's requirements:
##
##   1. IT CANNOT BE CAUGHT. `is_trainer_owned()` below is what makes CLAUDE.md's
##      hard rule true in the running game. `catch_math.can_be_caught()` has
##      taken an `already_owned` argument since M3 and NOTHING HAS EVER PASSED
##      `true` FOR IT — the rule was written, documented and unreachable, because
##      until this milestone there was no creature in the world that anybody else
##      owned. `combat_manager` now asks the opponent, twice: before the aim
##      opens, and again when the orb lands.
##   2. IT DOES NOT WANDER AND IT DOES NOT AMBUSH. It stands at its trainer's
##      heel until it is sent out. `aggressive` is forced false regardless of what
##      the species says, or a Team Tether Cindertail would charge the player
##      across the meadow on its own and start a fight its trainer was not part
##      of.
##   3. IT MAY BE TETHERED. The grade from `data/config/trainers.json` multiplies
##      its BEAT TIMINGS — telegraph, recovery, reposition, cooldown, chase speed
##      — and nothing else. No stat is touched here and none can be: `_tethered()`
##      only knows the timing keys' names.
##
## Extends `wild_pal.gd` rather than copying it. The alternative was a second
## opponent implementation, which is a second place to fix every combat bug and a
## second thing to forget when the AI changes.

const DRESS := preload("res://scripts/trainers/tether_dress.gd")

## The tether grade this creature is fielded on, from `tether_data.tether_grade`.
var tether: Dictionary = {}

## Which trainer fielded it, so a fight can be attributed without a search.
var owner_id: String = ""

var _collar: Node3D = null


## True, always, for anything wearing this script.
##
## Duck-typed on purpose: `combat_manager` asks `has_method("is_trainer_owned")`,
## so a plain wild pal answers "no" by not having the method rather than by
## carrying a flag that somebody has to remember to set to false. There is no way
## to construct a trainer-owned creature that forgets to say so, and no way to
## give a wild one the answer by accident.
func is_trainer_owned() -> bool:
	return true


## Take a creature the trainer already owns.
##
## Deliberately NOT `populate()`. That one spawns its own instance from the
## species table, which would give this body a different creature from the one
## `trainer_battle` is tracking — two objects, one health bar between them,
## exactly the bug `wild_pal.hand_instance_to_owner()` exists because of.
func adopt(id: String, live: RefCounted, player: Node3D, grade: Dictionary, trainer_id: String) -> bool:
	setup(id)
	_player = player
	instance = live
	tether = grade
	owner_id = trainer_id
	# Whatever species.json says. See (2) in the header.
	aggressive = false
	_aggro_cfg = {}
	home = global_position
	_dress()
	return instance != null


func _dress() -> void:
	if _collar != null and is_instance_valid(_collar):
		_collar.queue_free()
		_collar = null
	if not bool(tether.get("live", false)):
		return
	_collar = DRESS.collar(self, body_height(), body_radius())


## --- standing at heel ------------------------------------------------------

## Hold station and watch. No wandering, no chasing, no engaging.
##
## `wild_pal._tick_peaceful` wanders around a home point and, for an aggressive
## species, closes on the trainer and starts a fight. Neither is right for a
## creature standing beside its handler: a Team Tether team drifting off across
## the meadow between challenges is a team the player fights one member of, in a
## field, by accident.
func _tick_peaceful(_delta: float) -> void:
	if _player == null:
		return
	if global_position.distance_to(_player.global_position) <= _notice_range * 1.6:
		face_towards(_player.global_position)


## --- the tether ------------------------------------------------------------

## Apply the grade to the numbers the AI runs on.
##
## `_combat_cfg` is what `wild_pal._enter()` and `AI.speed_for()` actually read —
## NOT `_spaced_config()`, which only floors the spacing by the two bodies. So the
## tether is applied here, once, when the fight opens.
##
## DUPLICATED BEFORE IT IS TOUCHED. `MATH.config()` hands back its own cached
## Dictionary, and scaling that in place would speed up every creature in the
## game, permanently, from one Team Tether encounter.
func set_engaged(value: bool, opponent: Node3D = null) -> void:
	super(value, opponent)
	if value:
		_combat_cfg = _tethered(_combat_cfg)
		# `wild_pal.set_engaged` has already read `first_attack_delay` out of the
		# untethered config to set the opening beat, so it is re-read here. The
		# opening pause is the player's moment to read the situation and a tethered
		# creature gives them less of it.
		_cooldown = float(_combat_cfg.get("first_attack_delay", 1.5))


## The `enemy` block with the tether's multipliers applied.
##
## Public and static-shaped so `tests/test_trainer_battle.gd` can assert the one
## thing that matters about it: that the Warden's punish window is genuinely
## shorter than a wild creature's, and that NO STAT KEY IS TOUCHED. The list of
## keys below is exhaustive and is the whole mechanism — there is nowhere here
## for an hp or attack multiplier to be added without it being obvious.
static func tethered_config(base: Dictionary, grade: Dictionary) -> Dictionary:
	var beat := maxf(0.05, float(grade.get("beat_scale", 1.0)))
	var cooldown := maxf(0.05, float(grade.get("cooldown_scale", 1.0)))
	var chase := maxf(0.05, float(grade.get("chase_scale", 1.0)))

	var out := base.duplicate()
	# The two the player reads: how long the warning lasts, and how long the
	# opening lasts.
	out["telegraph"] = float(base.get("telegraph", 0.55)) * beat
	out["recovery"] = float(base.get("recovery", 0.75)) * beat
	out["reposition_time"] = float(base.get("reposition_time", 1.0)) * beat
	# How soon it comes again.
	out["attack_cooldown"] = float(base.get("attack_cooldown", 1.1)) * cooldown
	out["first_attack_delay"] = float(base.get("first_attack_delay", 1.5)) * cooldown
	# How much backing off buys.
	out["chase_speed"] = float(base.get("chase_speed", 4.6)) * chase
	out["reposition_speed"] = float(base.get("reposition_speed", 3.8)) * chase
	return out


func _tethered(base: Dictionary) -> Dictionary:
	return tethered_config(base, tether)


## --- lifecycle -------------------------------------------------------------

## Recalled. The body goes away; the instance stays with `trainer_battle`, which
## is the only thing that owns it.
##
## Distinct from `wild_pal.revive_at_home()` — a recalled creature is not put
## back on a hillside and is not healed. Whether it comes back at all is the
## battle's decision, made in `trainer_battle.restore()`.
func recall() -> void:
	visible = false
	rotation = Vector3.ZERO
	set_engaged(false)
	arena = null


## Sent out. The reverse.
func send_out(at: Vector3, facing_towards: Vector3) -> void:
	visible = true
	rotation = Vector3.ZERO
	set_physics_process(true)
	revive_animation()
	if not place_on_ground(at):
		global_position = at
	face_towards(facing_towards)
	home = global_position
	_dress()
