extends SceneTree

## F04: a named CHARGER's lunge travels, and only real contact hits.
##
##   godot --headless --path . --script tests/smoke_charger_lunge.gd
##
## Real bodies on a real floor, real physics steps, the real combat manager's
## strike handler. No world boot: a flat collision floor and a ground source
## that answers 0, so every number below is the lunge's own and not terrain.
##
## Cases:
##   1. ordinary wild (no override): the strike is resolved at the end of the
##      wind-up exactly as before -- pinned against positions and a hit outcome
##      measured on the tree BEFORE the travelling lunge existed.
##   2. Vance's CHARGER, target straight ahead and still: the body travels,
##      stops at contact and the hit lands.
##   3. Vance's CHARGER, target out of reach straight ahead: the body travels
##      the configured lunge distance along its heading and misses.
##   4. Vance's CHARGER, target sidesteps through the tell: the heading tracks
##      the first half, locks, the body travels the full distance down the
##      locked lane and the sidestepped target is not hit.
##   5. Vance's CHARGER, a wall across its lane: the lunge stops at the wall
##      and does not hit the target standing behind it.
##   6. The tell draws a lane exactly the lunge long and the contact rule wide,
##      which tracks, then locks at the configured fraction; while charging the
##      body is neither winding up nor "open", and its recovery clock waits.
##   7. A stagger mid-charge stops it without a strike.
##   8. Disengaging mid-tell takes the lane with it.
##
## Run as a child of `tests/test_charger_lunge.gd`, so CI's unit job runs it.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")

## Measured on origin/main 835744b35 + the relay-capture merge (the tree before
## the travelling lunge) with this same harness, case 1. The ordinary wild must
## still end up exactly here. Wild/ally x,z 30 physics frames after the strike.
const ORDINARY_GOLDEN := {
	"hit": true,
	"wild_at_strike": Vector2(0.0, 0.0),
	"wild_after": Vector2(0.0, 0.319028),
	"ally_after": Vector2(0.0, 3.126248),
}
const GOLDEN_TOLERANCE := 0.002
const SIDESTEP_SPEED := 5.6

var _failures: Array[String] = []
var _checks := 0
var _record_golden := false


class Ground extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_record_golden = OS.get_cmdline_user_args().has("--record-golden")
	await _case_ordinary_wild_unchanged()
	if _record_golden:
		_report()
		return
	await _case_charger_hits_a_target_that_stays()
	await _case_charger_travels_full_distance()
	await _case_charger_misses_a_sidestep()
	await _case_charger_stops_at_a_wall()
	await _case_charger_tell_lane_and_charge_state()
	await _case_stagger_breaks_the_charge()
	await _case_disengage_takes_the_lane()
	_report()


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)
		print("  FAIL  " + message)


func _report() -> void:
	print("smoke_charger_lunge: %d checks, %d failed" % [_checks, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


func _vance_charger() -> Dictionary:
	var spec := TRAINERS.trainer("relay_captain")
	var team: Array = TRAINERS.team_of(spec)
	for member: Variant in team:
		var combat: Dictionary = (member as Dictionary).get("combat", {}) as Dictionary
		if float(combat.get("preferred_range", 0.0)) >= 4.5:
			var clean := {}
			for key: Variant in combat.keys():
				if not str(key).begins_with("_"):
					clean[key] = combat[key]
			return clean
	return {}


## One staged fight: a flat floor, the wild at the origin facing +Z, the ally
## `ally_at` away, and a manager wired exactly as `begin()` wires the strike.
func _stage(species: String, override: Dictionary, trainer_owned: bool, ally_at: Vector3,
		wall_z: float = -1.0) -> Dictionary:
	var world := Ground.new()
	world.name = "LungeWorld"
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(floor_body)
	if wall_z > 0.0:
		var wall := StaticBody3D.new()
		var wall_shape := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = Vector3(12.0, 3.0, 0.3)
		wall_shape.shape = wall_box
		wall.add_child(wall_shape)
		wall.position = Vector3(0.0, 1.5, wall_z)
		world.add_child(wall)

	# The director's own recipe: the shared body scene, the script chosen here.
	var wild: Node3D = CREATURE_SCENE.instantiate()
	wild.set_script(WILD)
	wild.set("trainer_owned", trainer_owned)
	wild.set("combat_override", override.duplicate(true))
	world.add_child(wild)
	wild.call("populate", species, null)
	wild.call("place_on_ground", Vector3.ZERO)

	var ally: Node3D = CREATURE_SCENE.instantiate()
	ally.set_script(BODY)
	world.add_child(ally)
	ally.call("setup", "terrapup")
	ally.call("place_on_ground", ally_at)

	var enemy: RefCounted = wild.instance
	var creature: RefCounted = SPECIES.spawn("terrapup")
	creature.hp = 100000.0
	creature.max_hp = 100000.0
	var manager := COMBAT.new()
	manager.set("_moves", MOVE_DB.new())
	manager.set("_enemy", enemy)
	manager.set("_wild", wild)
	manager.set("_ally_body", ally)
	manager.set("_arena", world)
	manager.set("_party", [creature] as Array[RefCounted])
	manager.set("_active_index", 0)
	manager.set("state", COMBAT.State.ACTIVE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	manager.set("_rng", rng)

	var log := {"hits": 0, "misses": 0, "strike_frames": [], "wild_at_strike": null,
		"lunge_from": null, "lunge_heading": null}
	if wild.has_signal("lunge_started"):
		wild.connect("lunge_started", func(heading: Vector3, _distance: float) -> void:
			log.lunge_from = wild.global_position
			log.lunge_heading = heading)
	# Connected before the manager so the position is read before any impulse.
	wild.strike_ready.connect(func() -> void:
		(log.strike_frames as Array).append(Engine.get_physics_frames())
		if log.wild_at_strike == null:
			log.wild_at_strike = wild.global_position)
	wild.strike_ready.connect(manager._on_enemy_strike)
	manager.hit_landed.connect(func(on_enemy: bool, _damage: float) -> void:
		if not on_enemy:
			log.hits += 1)
	manager.attack_missed.connect(func(by_player: bool) -> void:
		if not by_player:
			log.misses += 1)

	for i in 10:
		await physics_frame
		_release_hitstop(manager)
	wild.set("_rng", _seeded(7))
	wild.set_engaged(true, ally)
	wild.face_towards(ally.global_position)
	return {"world": world, "wild": wild, "ally": ally, "manager": manager, "log": log}


func _seeded(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## The manager is not in the tree here, so its own clock never ends a hitstop.
## Ending it on the next frame is the same for every case and every tree.
func _release_hitstop(manager: Node) -> void:
	if float(manager.get("_hitstop_left")) > 0.0:
		manager.call("_end_hitstop")


func _teardown(stage: Dictionary) -> void:
	(stage.wild as Node).call("set_engaged", false)
	(stage.manager as Node).free()
	(stage.world as Node).queue_free()
	for i in 3:
		await physics_frame


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _lunging(wild: Node) -> bool:
	return wild.has_method("is_lunging") and bool(wild.call("is_lunging"))


## Starts a wind-up now and runs until the strike resolves (or a frame cap).
## `sidestep` moves the ally +X at SIDESTEP_SPEED from the first tell frame.
func _run_one_attack(stage: Dictionary, sidestep: bool = false, after_frames: int = 30) -> Dictionary:
	var wild: Node3D = stage.wild
	var ally: Node3D = stage.ally
	var manager: Node = stage.manager
	var log: Dictionary = stage.log
	wild.set("_cooldown", 0.0)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	var tell_start := wild.global_position
	var heading_at_start: Vector3 = wild.call("facing")
	var tell_end := Vector3.INF
	var heading_at_tell_end := Vector3.ZERO
	var burst_seen := false
	var lunge_frames := 0
	var physics_hz := float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0))
	for frame in 400:
		if sidestep:
			ally.global_position += Vector3(SIDESTEP_SPEED / physics_hz, 0.0, 0.0)
		await physics_frame
		_release_hitstop(manager)
		if bool(wild.call("combat_burst_active")):
			burst_seen = true
		if _lunging(wild):
			lunge_frames += 1
		if tell_end == Vector3.INF and int(wild.call("intent")) != AI.Intent.TELEGRAPH:
			tell_end = wild.global_position
			heading_at_tell_end = wild.call("facing")
		if not (log.strike_frames as Array).is_empty():
			break
	var wild_at_strike: Vector3 = log.wild_at_strike if log.wild_at_strike != null else wild.global_position
	for i in after_frames:
		await physics_frame
		_release_hitstop(manager)
	return {
		"hit": int(log.hits) > 0, "missed": int(log.misses) > 0,
		"strikes": (log.strike_frames as Array).size(),
		"tell_start": tell_start, "tell_end": tell_end,
		"heading_at_start": heading_at_start, "heading": heading_at_tell_end,
		"wild_at_strike": wild_at_strike, "wild_after": wild.global_position,
		"ally_after": ally.global_position, "burst_seen": burst_seen,
		"lunge_frames": lunge_frames,
		"lunge_from": log.lunge_from if log.lunge_from != null else tell_end,
		"lunge_heading": log.lunge_heading if log.lunge_heading != null else heading_at_tell_end,
	}


func _case_ordinary_wild_unchanged() -> void:
	var stage := await _stage("bramblebun", {}, false, Vector3(0.0, 0.0, 3.0))
	var wild: Node3D = stage.wild
	var cfg: Dictionary = wild.call("combat_config")
	_check(not bool(cfg.get("lunge_travels", false)), "an ordinary wild's config carries no lunge_travels")
	var out := await _run_one_attack(stage)
	print("ordinary: hit=%s strikes=%d wild_at_strike=%s wild_after=%s ally_after=%s" % [
		out.hit, out.strikes, _flat(out.wild_at_strike), _flat(out.wild_after), _flat(out.ally_after)])
	if _record_golden:
		print("GOLDEN {\"hit\": %s, \"wild_at_strike\": Vector2(%.4f, %.4f), \"wild_after\": Vector2(%.4f, %.4f), \"ally_after\": Vector2(%.4f, %.4f)}" % [
			str(out.hit).to_lower(), out.wild_at_strike.x, out.wild_at_strike.z,
			out.wild_after.x, out.wild_after.z, out.ally_after.x, out.ally_after.z])
		await _teardown(stage)
		return
	_check(out.strikes == 1, "ordinary wild strikes exactly once (got %d)" % out.strikes)
	_check(not out.burst_seen and out.lunge_frames == 0, "ordinary wild never starts a travelling lunge")
	_check(bool(out.hit) == bool(ORDINARY_GOLDEN.hit), "ordinary wild hit outcome unchanged (hit=%s)" % out.hit)
	for key: String in ["wild_at_strike", "wild_after", "ally_after"]:
		var got := _flat(out[key])
		var want: Vector2 = ORDINARY_GOLDEN[key]
		_check(got.distance_to(want) <= GOLDEN_TOLERANCE,
			"ordinary wild %s unchanged: got %s, pre-change %s" % [key, got, want])
	await _teardown(stage)


## `ally_z` / `wall_z` are multiples of the pair's real attack spacing (the
## body-floored preferred range the AI telegraphs from), so the geometry is the
## fight's own rather than a guess that goes stale when radii change.
func _charger_stage(ally_z: float, wall_z: float = -1.0) -> Dictionary:
	var override := _vance_charger()
	_check(not override.is_empty(), "Vance's CHARGER block is found in band3 trainers.json")
	_check(bool(override.get("lunge_travels", false)), "Vance's CHARGER opts into lunge_travels")
	var spacing := _spacing(override)
	return await _stage("tuskroot", override, true, Vector3(0.0, 0.0, ally_z * spacing),
		wall_z * spacing if wall_z > 0.0 else -1.0)


## The preferred range a Tuskroot telegraphs from against a Terrapup.
func _spacing(override: Dictionary) -> float:
	var merged: Dictionary = (MATH.config().get("enemy", {}) as Dictionary).duplicate(true)
	merged.merge(override, true)
	return float(WILD.spaced_config_for(merged, _radius_of("tuskroot"), _radius_of("terrapup")).preferred_range)


var _radii := {}


func _radius_of(species: String) -> float:
	if not _radii.has(species):
		var body: Node3D = CREATURE_SCENE.instantiate()
		body.set_script(BODY)
		root.add_child(body)
		body.call("setup", species)
		_radii[species] = float(body.call("body_radius"))
		body.free()
	return float(_radii[species])


func _lunge_distance(stage: Dictionary) -> float:
	return float((stage.wild as Node).call("combat_config").get("lunge", 0.0))


func _case_charger_hits_a_target_that_stays() -> void:
	var stage := await _charger_stage(1.0)
	var wild: Node3D = stage.wild
	var reach := (float(wild.call("body_radius")) + float((stage.ally as Node).call("body_radius"))) \
		* float(MATH.config().get("charger_lunge", {}).get("contact_scale", 1.0))
	var out := await _run_one_attack(stage, false, 0)
	var travelled := _flat(out.wild_at_strike).distance_to(_flat(out.lunge_from))
	var gap := _flat(out.wild_at_strike).distance_to(_flat((stage.ally as Node3D).global_position))
	print("charger/stays: hit=%s travelled=%.2f gap_at_strike=%.2f reach=%.2f lunge_frames=%d" % [
		out.hit, travelled, gap, reach, out.lunge_frames])
	_check(out.strikes == 1, "charger resolves exactly one strike (got %d)" % out.strikes)
	_check(out.lunge_frames > 0, "charger strike is a travelling lunge")
	_check(travelled > 1.0, "charger body actually travels before contact (%.2f m)" % travelled)
	_check(travelled < _lunge_distance(stage) - 0.5, "charger stops at contact, short of the full lunge (%.2f m)" % travelled)
	_check(gap <= reach + 0.3 and gap >= reach - 0.3,
		"charger stopped where it reached the target (gap %.2f, reach %.2f)" % [gap, reach])
	_check(out.hit and not out.missed, "a target that stays in the lane is hit")
	await _teardown(stage)


func _case_charger_travels_full_distance() -> void:
	var stage := await _charger_stage(2.5)
	# Out of preferred range on purpose: the wind-up is forced, so the lunge
	# runs its whole length with nobody at the end of it.
	var out := await _run_one_attack(stage, false, 0)
	var lunge := _lunge_distance(stage)
	var delta := _flat(out.wild_at_strike) - _flat(out.lunge_from)
	var heading := _flat(out.lunge_heading).normalized()
	var along := delta.dot(heading)
	var across := absf(delta.cross(heading))
	print("charger/full: hit=%s along=%.3f across=%.3f lunge=%.2f" % [out.hit, along, across, lunge])
	_check(absf(along - lunge) <= 0.08, "charger travels its configured lunge (%.3f m of %.2f)" % [along, lunge])
	_check(across <= 0.05, "charger travels along its heading (%.3f m off line)" % across)
	_check(out.missed and not out.hit, "nothing at the end of the lane: a miss is reported")
	await _teardown(stage)


func _case_charger_misses_a_sidestep() -> void:
	var stage := await _charger_stage(1.0)
	var out := await _run_one_attack(stage, true, 0)
	var lunge := _lunge_distance(stage)
	var delta := _flat(out.wild_at_strike) - _flat(out.lunge_from)
	var heading := _flat(out.lunge_heading).normalized()
	var along := delta.dot(heading)
	var across := absf(delta.cross(heading))
	var tracked := _flat(out.lunge_heading).angle_to(_flat(out.heading_at_start))
	print("charger/sidestep: hit=%s along=%.3f across=%.3f tracked=%.1fdeg" % [
		out.hit, along, across, rad_to_deg(absf(tracked))])
	_check(absf(tracked) > deg_to_rad(5.0), "the heading tracks the sidestep during the first half of the tell")
	_check(absf(along - lunge) <= 0.08, "a sidestepped charger still runs its whole lane (%.3f m of %.2f)" % [along, lunge])
	_check(across <= 0.05, "the charge holds its locked heading (%.3f m off line)" % across)
	_check(out.missed and not out.hit, "a target that sidestepped out of the lane is not hit")
	await _teardown(stage)


func _case_charger_stops_at_a_wall() -> void:
	var stage := await _charger_stage(1.0, 0.5)
	var wall_z := 0.5 * _spacing(_vance_charger())
	var out := await _run_one_attack(stage, false, 0)
	var travelled := _flat(out.wild_at_strike).distance_to(_flat(out.lunge_from))
	var clear := wall_z - 0.15 - float((stage.wild as Node).call("body_radius"))
	print("charger/wall: hit=%s travelled=%.2f wall_clear=%.2f" % [out.hit, travelled, clear])
	_check(out.strikes == 1, "a walled lunge still resolves once (got %d)" % out.strikes)
	_check(out.lunge_frames > 0 and travelled <= clear + 0.1,
		"the lunge stops at the wall (%.2f m, wall face at %.2f)" % [travelled, clear])
	_check(out.missed and not out.hit, "the target behind the wall is not hit")
	await _teardown(stage)


func _lane(wild: Node) -> Node:
	var lane := wild.find_child("LungeLane", true, false)
	return lane if lane != null and not lane.is_queued_for_deletion() else null


func _case_charger_tell_lane_and_charge_state() -> void:
	var stage := await _charger_stage(1.0)
	var wild: Node3D = stage.wild
	var manager: Node = stage.manager
	var cfg: Dictionary = MATH.config().get("charger_lunge", {})
	wild.set("_cooldown", 0.0)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	var lane := _lane(wild)
	_check(lane != null, "the CHARGER tell draws a lane")
	if lane == null:
		await _teardown(stage)
		return
	_check(absf(float(lane.call("lane_length")) - _lunge_distance(stage)) < 0.0001,
		"the lane is exactly the configured lunge long (%.2f)" % float(lane.call("lane_length")))
	var half := float(wild.call("body_radius")) * float(cfg.get("contact_scale", 1.2))
	_check(absf(float(lane.call("lane_half_width")) - half) < 0.0001, "the lane is the contact rule's width")
	_check(not bool(lane.call("is_locked")), "the lane tracks at the start of the tell")
	var physics_hz := float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0))
	var tell := float((wild.call("combat_config") as Dictionary).get("telegraph", 0.8))
	var lock_frames := -1
	var charging_checked := false
	var recovery_seen := -1.0
	var recovery_steady := true
	for frame in 200:
		await physics_frame
		_release_hitstop(manager)
		if lock_frames < 0 and lane != null and is_instance_valid(lane) and bool(lane.call("is_locked")):
			lock_frames = frame + 1
		if bool(wild.call("is_lunging")):
			if not charging_checked:
				charging_checked = true
				_check(not bool(wild.call("is_winding_up")), "a charging body is not reported as winding up")
				_check(not bool(wild.call("is_rooted")), "a charging body is not reported as open")
				recovery_seen = float(wild.get("_beat_left"))
			elif absf(float(wild.get("_beat_left")) - recovery_seen) > 0.0001:
				recovery_steady = false
		if not (stage.log.strike_frames as Array).is_empty():
			break
	var expected_lock := tell * float(cfg.get("face_lock_fraction", 0.5)) * physics_hz
	print("charger/tell: locked after %d frames (expected ~%.0f), recovery held at %.2f" % [
		lock_frames, expected_lock, recovery_seen])
	_check(lock_frames > 0 and absf(float(lock_frames) - expected_lock) <= 2.0,
		"the heading locks at the configured fraction of the tell (%d frames)" % lock_frames)
	_check(charging_checked, "the charge was observed")
	_check(recovery_steady and absf(recovery_seen - float((wild.call("combat_config") as Dictionary).get("recovery", 0.9))) < 0.02,
		"the recovery window waits for the charge to stop (held at %.2f)" % recovery_seen)
	_check(bool(wild.call("is_rooted")), "after the charge the recovery is the punish window")
	await _teardown(stage)


func _case_stagger_breaks_the_charge() -> void:
	var stage := await _charger_stage(2.5)
	var wild: Node3D = stage.wild
	wild.set("_cooldown", 0.0)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	for frame in 120:
		await physics_frame
		if bool(wild.call("is_lunging")):
			break
	_check(bool(wild.call("is_lunging")), "the charge started")
	_check(bool(wild.call("apply_poise_damage", 0.0, true)), "a forced break staggers the charger")
	_check(not bool(wild.call("is_lunging")) and not bool(wild.call("combat_burst_active")),
		"a broken charge stops where it is")
	for frame in 30:
		await physics_frame
	_check((stage.log.strike_frames as Array).is_empty(), "a broken charge strikes nothing")
	await _teardown(stage)


func _case_disengage_takes_the_lane() -> void:
	var stage := await _charger_stage(1.0)
	var wild: Node3D = stage.wild
	wild.set("_cooldown", 0.0)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	for frame in 5:
		await physics_frame
	_check(_lane(wild) != null, "the lane is up mid-tell")
	wild.call("set_engaged", false)
	_check(_lane(wild) == null, "disengaging removes the lane")
	await _teardown(stage)
