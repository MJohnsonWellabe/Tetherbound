extends SceneTree

## F06 / C1: closed Cloudreach chapter gates hold against Fly and on foot, on
## the production scene, production Player/FlyController and real input.
##
##   godot --headless --path . --script tests/smoke_cloudreach_closed_gate_seal.gd
##
## ACCEPTANCE §6.1 F06 ("... do not bypass a closed gate or lose an owned
## creature"); SYSTEMS §8 Flight ("No flight ... past unopened chapter gates");
## WORLD §4.2. With Fly unlocked but `cloudreach_upper_route_unlocked` NOT set
## (so the `cloudreach_upper` and `cloudreach_summit` no-fly volumes of
## data/config/cloudreach_physical_runtime.json are sealed):
##
##   (d) Before `fly_traversal_unlocked`, outside the Windscar trial volume, a
##       real Jump, Jump does not deploy Fly and the trial reason is reported.
##   (c) On foot, a held stick along the counterweight route polyline walks
##       into the closed `upper_counterweight_gate` LockedTraversalBarrier. The
##       walk reaches it (furthest point within 4 m of its plane), touches that
##       barrier, and never passes the plane.
##   (a) Owned Fly carrier (Galecrest active): deploy by real Jump, Jump from
##       the Windscar flight aerie, climb in the authored aerie current by
##       holding Jump, then hold the stick (and Jump) toward the inside of
##       `cloudreach_upper`, then toward the inside of `cloudreach_summit`.
##       The trainer never enters either restricted AABB (origin nor carried
##       silhouette), actually reaches the seal, the denial naming the volume
##       is reported through the `denied` signal / `last_denial`, no unlock
##       flag changes and the party UIDs are unchanged. The summit volume is
##       only reachable through the upper one, so it is also witnessed on its
##       own by fault injection: a trainer placed on summit ground inside the
##       sealed volume cannot launch, and the refusal names `cloudreach_summit`.
##   (b) The same flight with a full five-member party holding NO Fly carrier:
##       Maela's mentor loaner carries, the flight is equally sealed, and the
##       loaner never becomes a party member (no sixth slot, UIDs unchanged).
##
## Disclosed fixtures, not earned-route proof:
##   1. The party (Galecrest-led five for (a)/(d)/(c)) and `realm_key_cloudreach`
##      are seeded before the scene loads; `current_realm` is cloudreach.
##   2. Position writes, each followed by the production
##      `fly_controller.clear_recovery_anchor()` (a deliberate relocation is
##      not a fall): the counterweight-gate approach stand (9 m back along the
##      route from the gate), the aerie launch stand (the first candidate near
##      the `windscar_flight_aerie` landmark, inside `cloudreach_aerie_lift`,
##      where production `launch_blockers()` returns ""), and summit ground
##      (points of the `summit_overlook_loop` polyline) for the summit
##      in-volume refusal.
##   3. `fly_traversal_unlocked` is set directly after (d)/(c) (the flight
##      trial is not replayed here). `cloudreach_upper_route_unlocked` is never
##      set.
##   4. `vitals.rest()` before each launch attempt.
##   5. Between flights the production `fly_controller.recover_to_anchor()`
##      returns the flyer to its launch anchor instead of a long glide home.
##   6. Before (b) the party is replaced by a non-carrier full five.
## Every walk, jump, Fly deploy, climb and steer is the real `move_*`/`jump`
## actions through the camera rig's `planar_basis`; nothing writes a flight
## state, a velocity during flight, or a flag other than (3).

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")

const PHYSICAL_DATA := "res://data/config/cloudreach_physical_runtime.json"
const FLY_DATA := "res://data/config/fly_traversal.json"
const CARRIER_TEAM := ["galecrest", "meadowhart", "bramblebun", "mudsnout", "terrapup"]
const GROUND_TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const FLY_FLAG := "fly_traversal_unlocked"
const UPPER_FLAG := "cloudreach_upper_route_unlocked"
const GATE_ID := "upper_counterweight_gate"
const UPPER_ID := "cloudreach_upper"
const SUMMIT_ID := "cloudreach_summit"
const AERIE_LANDMARK_ID := "windscar_flight_aerie"
const AERIE_LIFT_ID := "cloudreach_aerie_lift"
const SUMMIT_ROUTE_ID := "summit_overlook_loop"
const TRIAL_REASON_PREFIX := "Complete the Windscar flight trial"
const SEAL_REASON := "This wind route is still sealed: %s."
const WATCHDOG_S := 900.0

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _fly: Node
var _flags: RefCounted
var _physical_data: Dictionary = {}
var _fly_data: Dictionary = {}
var _upper_box := AABB()
var _summit_box := AABB()
var _lift_box := AABB()
var _lift_ceiling := 0.0
var _gating_flags: Array[String] = []
var _denials: Array[String] = []
var _recoveries := 0
var _party_max_seen := 0
var _failures: Array[String] = []
var _checks := 0
var _finished := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(WATCHDOG_S).timeout.connect(func() -> void:
		if not _finished:
			_fail("%d second watchdog expired (trainer at %s)" % [int(WATCHDOG_S),
				str(_player.global_position) if _player != null else "none"])
			_report())
	_physical_data = _read_json(PHYSICAL_DATA)
	_fly_data = _read_json(FLY_DATA)
	if not _expect(not _physical_data.is_empty() and not _fly_data.is_empty(), "Cloudreach physical/Fly data readable"):
		return
	_upper_box = _box_of(_spec_in(_physical_data.get("restrictions", []), UPPER_ID))
	_summit_box = _box_of(_spec_in(_physical_data.get("restrictions", []), SUMMIT_ID))
	var lift := _spec_in(_physical_data.get("updrafts", []), AERIE_LIFT_ID)
	_lift_box = _box_of(lift)
	_lift_ceiling = minf(float(lift.get("ceiling_y", 0.0)), _lift_box.end.y) - 2.0
	if not _expect(_upper_box.has_volume() and _summit_box.has_volume() and _lift_box.has_volume(),
			"data authors the upper/summit restrictions and the aerie current"):
		return

	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("current_realm", "cloudreach")
	_game.set("pending_realm_entry", "")
	_game.set("saved_player_pose", {})
	_flags = _game.get("progression")
	_flags.call("set_flag", "realm_key_cloudreach")
	_game.set("party", _make_party(CARRIER_TEAM))

	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	for _frame in 3600:
		await physics_frame
		if bool(_world.call("shell_build_complete")):
			break
	if not _expect(bool(_world.call("shell_build_complete")), "Cloudreach shell finished building"):
		return
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	_fly = _player.get("fly_controller")
	if not _expect(_fly != null, "production trainer has a FlyController"):
		return
	for _frame in 900:
		if not _registered(UPPER_ID).is_empty() and not _registered(SUMMIT_ID).is_empty():
			break
		await physics_frame
	await _frames(30)
	_fly.connect("denied", _on_denied)
	_fly.connect("recovered", _on_recovered)
	_collect_gating_flags()
	_check_registration()
	_check(not bool(_flags.call("has", UPPER_FLAG)) and not bool(_flags.call("has", FLY_FLAG)),
		"fixture starts with Fly and the upper route both locked")

	await _leg_locked_launch_and_gate_walk()
	if _finished:
		return

	# Fixture 3: Fly is unlocked; the upper route stays sealed.
	_flags.call("set_flag", FLY_FLAG)
	await _frames(4)
	var barrier := _gate_barrier(GATE_ID)
	_check(barrier != null and not _barrier_disabled(barrier),
		"unlocking Fly leaves the counterweight gate barrier closed")
	_check(not bool(_flags.call("has", UPPER_FLAG)), "unlocking Fly does not unlock the upper route")

	var stand: Vector3 = await _find_aerie_stand()
	if _finished:
		return
	if not _expect(stand.is_finite(), "found a legal Fly launch stand at the Windscar aerie inside the aerie current"):
		return
	print("AERIE STAND %s (upper floor y=%.1f face z=%.1f, lift %s ceiling %.1f)" % [
		stand, _upper_box.position.y, _upper_box.position.z, _lift_box, _lift_ceiling])

	await _flight_leg("(a) owned Galecrest", stand, false)
	if _finished:
		return
	await _leg_summit_launch_inside()
	if _finished:
		return

	# Fixture 6: a full five with no Fly carrier.
	var ground_party: RefCounted = _make_party(GROUND_TEAM)
	var any_carrier := false
	for species: String in GROUND_TEAM:
		any_carrier = any_carrier or bool(SPECIES.fly_capability(species).get("can_carry", false))
	_game.set("party", ground_party)
	await _frames(4)
	_check(not any_carrier and int(ground_party.call("size")) == 5 and bool(ground_party.call("is_full")),
		"(b) fixture: a full five-member party with no Fly carrier")
	await _flight_leg("(b) Maela loaner", stand, true)
	if _finished:
		return

	_check(not bool(_flags.call("has", UPPER_FLAG)), "end of run: the upper route is still locked")
	_check(barrier != null and not _barrier_disabled(barrier), "end of run: the counterweight gate is still closed")
	_report()


# --- (d) + (c): locked launch, then the on-foot gate ----------------------------

func _leg_locked_launch_and_gate_walk() -> void:
	var spec := _gate_spec(GATE_ID)
	if not _require(not spec.is_empty(), "%s is authored in cloudreach_world.json" % GATE_ID):
		return
	var required := str(spec.get("requires_unlock", ""))
	_check(required == UPPER_FLAG, "%s is held by %s (%s)" % [GATE_ID, UPPER_FLAG, required])
	var gate := _vec3(spec["position"])
	var along := _route_direction_at(required, gate)
	if not _require(along.length() > 0.5, "the gate sits on a %s route polyline" % required):
		return
	var barrier := _gate_barrier(GATE_ID)
	if not _require(barrier != null, "the production LockedTraversalBarrier exists at %s" % gate):
		return
	_check(not _barrier_disabled(barrier), "(c) the counterweight barrier is closed while %s is unset" % UPPER_FLAG)
	var stand := gate - along * 9.0
	var seated: bool = await _seat(stand + Vector3.UP * 4.0, "gate approach")
	if not _require(seated, "(c) the trainer stands on the counterweight route 9 m before the gate"):
		return

	# (d) Fly is locked and no trial is authorized here.
	var trial: Dictionary = _physical_data.get("trial", {})
	var trial_box := AABB(_vec3(trial.get("bounds_position", [0, 0, 0])), _vec3(trial.get("bounds_size", [0, 0, 0])))
	_check(not trial_box.has_point(_player.global_position),
		"(d) the stand %s is outside the Windscar trial volume %s" % [_player.global_position, trial_box])
	_check(not bool(_fly.get("_trial_enabled")), "(d) no flight-trial authorization is active")
	var active: RefCounted = (_game.get("party") as RefCounted).call("active")
	_check(active != null and bool(SPECIES.fly_capability(str(active.get("species_id"))).get("can_carry", false)),
		"(d) the active companion is a real Fly carrier, so only the lock can refuse")
	_player.get("vitals").call("rest")
	var blockers := str(_fly.call("launch_blockers"))
	_check(blockers.begins_with(TRIAL_REASON_PREFIX), "(d) launch_blockers names the flight trial ('%s')" % blockers)
	var uids := _party_uids()
	var before := _gating_state()
	_denials.clear()
	await _deploy()
	var deployed := bool(_fly.call("is_flying"))
	await _frames(60)
	_check(not deployed and not bool(_fly.call("is_flying")),
		"(d) a real Jump, Jump does not deploy Fly before %s (state %s)" % [FLY_FLAG, str(_fly.get("state"))])
	_check(not _denial_starting(TRIAL_REASON_PREFIX).is_empty(),
		"(d) the refusal is reported through the denied signal (%s)" % str(_denials))
	_check(not bool(_flags.call("has", FLY_FLAG)), "(d) the refused launch does not grant Fly")
	_check_unlocks_unchanged("(d)", before)
	_check_party_same("(d)", uids)

	# (c) Walk into the barrier along the route.
	seated = await _seat(stand + Vector3.UP * 4.0, "gate approach (walk)")
	if not _require(seated, "(c) re-seated at the gate approach"):
		return
	var tps := Engine.physics_ticks_per_second
	var start := _player.global_position
	var furthest := -INF
	var touched_frame := -1
	var walls: Dictionary = {}
	var lowest := start.y
	for frame in 14 * tps:
		_steer_toward(gate + along * 14.0)
		await physics_frame
		var at := _player.global_position
		furthest = maxf(furthest, (at - gate).dot(along))
		lowest = minf(lowest, at.y)
		for index in _player.get_slide_collision_count():
			var hit := _player.get_slide_collision(index)
			var collider: Object = hit.get_collider()
			if collider == barrier and touched_frame < 0:
				touched_frame = frame
			if absf(hit.get_normal().y) < 0.5 and collider is Node:
				var path := str((collider as Node).get_path())
				if not walls.has(path):
					walls[path] = true
					print("GATE WALK contact %s at=%s normal=%s" % [path, at, hit.get_normal()])
		if touched_frame >= 0 and frame - touched_frame >= 2 * tps:
			break
		if float(_player.get("vitals").get("health")) <= 0.0 or at.y < start.y - 20.0:
			break
	_release_all()
	await _frames(10)
	var lateral := (_player.global_position - gate) - along * (_player.global_position - gate).dot(along)
	lateral.y = 0.0
	print("GATE WALK gate=%s along=%s stand=%s end=%s furthest=%.2f lateral=%.2f touched_frame=%d" % [
		gate, along, start, _player.global_position, furthest, lateral.length(), touched_frame])
	_check(furthest < 0.0, "(c) walking into the closed counterweight gate never passes its plane (furthest %.2f m)" % furthest)
	_check(furthest > -4.0, "(c) the walk actually reached the barrier rather than stalling short (%.2f m)" % furthest)
	_check(touched_frame >= 0, "(c) what held the walk is the LockedTraversalBarrier itself")
	_check(_player.is_on_floor() and float(_player.get("vitals").get("health")) > 0.0 and lowest > start.y - 20.0,
		"(c) the trainer is still standing on the route, alive, at %s" % _player.global_position)
	_check(not bool(_flags.call("has", UPPER_FLAG)), "(c) the gate's unlock flag is untouched")
	_check_party_same("(c)", uids)


# --- (a)/(b): real flights at the sealed volumes -----------------------------------

func _flight_leg(label: String, stand: Vector3, loaner_expected: bool) -> void:
	var seated: bool = await _seat(stand, label + " launch stand")
	if not _require(seated, "%s: the trainer stands on the aerie launch stand" % label):
		return
	var party: RefCounted = _game.get("party")
	var uids := _party_uids()
	var before := _gating_state()
	_player.get("vitals").call("rest")
	var blockers := str(_fly.call("launch_blockers"))
	_check(blockers.is_empty(), "%s: the aerie stand is a legal launch ('%s')" % [label, blockers])
	_denials.clear()
	_recoveries = 0
	_party_max_seen = int(party.call("size"))
	await _deploy()
	if not _require(bool(_fly.call("is_flying")),
			"%s: Jump, then Jump airborne, deploys Fly (state %s, denials %s)" % [label, str(_fly.get("state")), str(_denials)]):
		return
	_check_carrier(label, loaner_expected, uids)

	# Climb in the authored aerie current by holding Jump.
	var tps := Engine.physics_ticks_per_second
	var climb_from := _player.global_position.y
	Input.action_press("jump")
	for _frame in 25 * tps:
		await physics_frame
		if not bool(_fly.call("is_flying")) or _player.global_position.y >= _lift_ceiling - 6.0:
			break
	print("%s CLIMB from %.1f to %s (state %s)" % [label, climb_from, _player.global_position, str(_fly.get("state"))])
	_check(bool(_fly.call("is_flying")) and _player.global_position.y > climb_from + 60.0,
		"%s: holding Jump in the aerie current climbs (%.1f -> %.1f m)" % [label, climb_from, _player.global_position.y])

	# Toward the inside of the upper volume, straight north of the stand.
	var upper_target := Vector3(stand.x, _upper_box.position.y + 140.0, _upper_box.position.z + 250.0)
	var upper: Dictionary = await _push(label + " -> upper", upper_target, UPPER_ID, 50.0, 3.0)
	_assert_sealed(label + " toward cloudreach_upper", upper, UPPER_ID, true)
	if not loaner_expected:
		# Toward the inside of the summit volume; it lies wholly behind the
		# upper one, so the seal met is the upper volume's.
		var summit_target := Vector3(stand.x, _summit_box.position.y + 200.0, _summit_box.position.z + 450.0)
		var summit: Dictionary = await _push(label + " -> summit", summit_target, UPPER_ID, 12.0, 3.0)
		_assert_sealed(label + " toward cloudreach_summit", summit, UPPER_ID, false)
	if loaner_expected:
		_check_loaner_not_owned(label + " at the seal", uids)
	_check_unlocks_unchanged(label, before)
	_check_party_same(label, uids)
	_check(_party_max_seen <= 5 and int(party.call("size")) == 5, "%s: never a sixth party slot during flight (max %d)" % [label, _party_max_seen])
	await _end_flight(label)
	if loaner_expected:
		_check_loaner_not_owned(label + " after landing", uids)
	_check_party_same(label + " after landing", uids)



## Holds the stick toward `target` (and Jump) for at most `max_s`, and for
## `hold_s` more once the seal has been reported. Never fails by itself.
func _push(label: String, target: Vector3, seal_id: String, max_s: float, hold_s: float) -> Dictionary:
	var tps := Engine.physics_ticks_per_second
	var reason := SEAL_REASON % seal_id
	var denials_from := _denials.size()
	var radius := float(_fly_data.get("collision_radius_m", 0.7))
	var height := float(_fly_data.get("collision_height_m", 4.5))
	var party: RefCounted = _game.get("party")
	var stats := {
		"start": _player.global_position, "end": _player.global_position,
		"in_upper": false, "in_summit": false, "body_upper": false, "body_summit": false,
		"closest_upper": INF, "closest_summit": INF, "max_z": -INF,
		"first_seal_frame": -1, "last_denial_seen": "", "stopped_flying": false, "frames": 0,
	}
	_party_max_seen = maxi(_party_max_seen, int(party.call("size")))
	Input.action_press("jump")
	for frame in int(max_s * tps):
		if not bool(_fly.call("is_flying")):
			stats["stopped_flying"] = true
			break
		_steer_toward(target)
		await physics_frame
		stats["frames"] = frame + 1
		var at := _player.global_position
		var body := AABB(at - Vector3(radius, 0.0, radius), Vector3(2.0 * radius, height, 2.0 * radius))
		if _upper_box.has_point(at):
			stats["in_upper"] = true
		if _summit_box.has_point(at):
			stats["in_summit"] = true
		if body.intersects(_upper_box):
			stats["body_upper"] = true
		if body.intersects(_summit_box):
			stats["body_summit"] = true
		stats["closest_upper"] = minf(float(stats["closest_upper"]), _distance_to_box(at, _upper_box))
		stats["closest_summit"] = minf(float(stats["closest_summit"]), _distance_to_box(at, _summit_box))
		stats["max_z"] = maxf(float(stats["max_z"]), at.z)
		_party_max_seen = maxi(_party_max_seen, int(party.call("size")))
		if str(_fly.get("last_denial")) == reason:
			stats["last_denial_seen"] = reason
		if int(stats["first_seal_frame"]) < 0 and _denials.slice(denials_from).has(reason):
			stats["first_seal_frame"] = frame
			print("%s SEAL first reported at frame %d at %s" % [label, frame, at])
		if int(stats["first_seal_frame"]) >= 0 and frame - int(stats["first_seal_frame"]) >= int(hold_s * tps):
			break
	_release_all()
	await _frames(2)
	stats["end"] = _player.global_position
	var count := 0
	for seen: String in _denials.slice(denials_from):
		if seen == reason:
			count += 1
	stats["seal_denials"] = count
	stats["all_denials"] = _denials.slice(denials_from)
	print("%s PUSH target=%s %s" % [label, target, str(stats)])
	return stats


func _assert_sealed(label: String, stats: Dictionary, seal_id: String, must_reach: bool) -> void:
	_check(not bool(stats["in_upper"]) and not bool(stats["in_summit"]),
		"%s: the trainer never enters the restricted upper or summit AABB (end %s, max z %.2f)" % [label, stats["end"], float(stats["max_z"])])
	_check(not bool(stats["body_upper"]) and not bool(stats["body_summit"]),
		"%s: the carried silhouette never overlaps a restricted AABB" % label)
	if must_reach:
		_check(float(stats["closest_upper"]) <= 2.0,
			"%s: the flight actually reached the sealed volume (closest %.2f m)" % [label, float(stats["closest_upper"])])
	_check(int(stats["seal_denials"]) > 0 and str(stats["last_denial_seen"]) == SEAL_REASON % seal_id,
		"%s: the denial '%s' is reported (signal %d, last_denial '%s', all %s)" % [
			label, SEAL_REASON % seal_id, int(stats["seal_denials"]), str(stats["last_denial_seen"]), str(stats["all_denials"])])
	_check(not bool(stats["stopped_flying"]), "%s: the flyer was held at the seal, still flying (not landed past it)" % label)


func _check_carrier(label: String, loaner_expected: bool, uids: Array[String]) -> void:
	var party: RefCounted = _game.get("party")
	var carrier := str(_fly.call("carrier_species_id"))
	var used_loaner := bool(_fly.call("last_flight_used_mentor_loaner"))
	if loaner_expected:
		var loaner_species := str((_fly_data.get("mentor_loaner", {}) as Dictionary).get("species_id", ""))
		_check(used_loaner and carrier == loaner_species,
			"%s: Maela's mentor loaner carries (%s, used_loaner %s)" % [label, carrier, used_loaner])
		_check_loaner_not_owned(label + " at launch", uids)
	else:
		var active: RefCounted = party.call("active")
		_check(not used_loaner and active != null and _fly.call("eligible_creature") == active
			and carrier == str(active.get("species_id")),
			"%s: the owned active %s carries, not the loaner (used_loaner %s)" % [label, carrier, used_loaner])


func _check_loaner_not_owned(label: String, uids: Array[String]) -> void:
	var party: RefCounted = _game.get("party")
	var loaner: RefCounted = _fly.call("eligible_creature")
	var members: Array = party.call("members")
	_check(loaner != null and not members.has(loaner) and not uids.has(str(loaner.get("uid")))
		and int(party.call("size")) == 5,
		"%s: the loaner is not a party member and there is no sixth slot (party %d)" % [label, int(party.call("size"))])


func _end_flight(label: String) -> void:
	_release_all()
	if bool(_fly.call("is_flying")):
		# Fixture 5.
		var back := bool(_fly.call("recover_to_anchor", "Smoke fixture: back to the launch stand."))
		_check(back, "%s: fixture return to the launch anchor" % label)
	await _frames(30)
	print("%s END at %s flying=%s recoveries=%d" % [label, _player.global_position, bool(_fly.call("is_flying")), _recoveries])


## The summit volume on its own: a trainer standing inside it is refused.
func _leg_summit_launch_inside() -> void:
	var stands: Array[Vector3] = []
	for raw: Variant in _route_polyline(SUMMIT_ROUTE_ID):
		var at := _vec3(raw)
		if _summit_box.has_point(at) and not _upper_box.has_point(at):
			stands.append(at)
	if not _require(not stands.is_empty(), "(a) summit ground points inside %s exist in the route data" % SUMMIT_ID):
		return
	var reason := SEAL_REASON % SUMMIT_ID
	var chosen := Vector3.INF
	for at: Vector3 in stands:
		var seated: bool = await _seat(at, "summit ground")
		if not seated:
			continue
		_player.get("vitals").call("rest")
		var blockers := str(_fly.call("launch_blockers"))
		print("SUMMIT STAND %s blockers '%s'" % [_player.global_position, blockers])
		if blockers == reason:
			chosen = _player.global_position
			break
	if not _require(chosen.is_finite(), "(a) a summit stand where production launch_blockers names %s" % SUMMIT_ID):
		return
	var uids := _party_uids()
	var before := _gating_state()
	_denials.clear()
	await _deploy()
	var deployed := bool(_fly.call("is_flying"))
	await _frames(60)
	_check(not deployed and not bool(_fly.call("is_flying")),
		"(a) inside the sealed summit volume a real Jump, Jump does not deploy Fly (state %s)" % str(_fly.get("state")))
	_check(_denials.has(reason), "(a) the refusal names %s through the denied signal (%s)" % [SUMMIT_ID, str(_denials)])
	_check_unlocks_unchanged("(a) summit in-volume", before)
	_check_party_same("(a) summit in-volume", uids)


func _find_aerie_stand() -> Vector3:
	var aerie := Vector3.INF
	for raw: Variant in (_world.call("config_data") as Dictionary).get("landmarks", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == AERIE_LANDMARK_ID:
			aerie = _vec3((raw as Dictionary)["position"])
	if not aerie.is_finite():
		return Vector3.INF
	var candidates: Array[Vector3] = []
	var stone := _world.find_child("LaunchStone", true, false) as Node3D
	if stone != null:
		candidates.append(Vector3(stone.global_position.x, aerie.y, stone.global_position.z))
	candidates.append(aerie)
	for offset: Vector3 in [Vector3(0, 0, -6), Vector3(-6, 0, 0), Vector3(6, 0, 0), Vector3(0, 0, 6), Vector3(-10, 0, -10), Vector3(10, 0, -10)]:
		candidates.append(aerie + offset)
	for at: Vector3 in candidates:
		if not _lift_box.has_point(at + Vector3.UP * 2.0):
			print("AERIE CANDIDATE %s outside %s" % [at, AERIE_LIFT_ID])
			continue
		var seated: bool = await _seat(at, "aerie candidate")
		if not seated:
			continue
		var here := _player.global_position
		if not _lift_box.has_point(here) or _upper_box.has_point(here) or _summit_box.has_point(here):
			print("AERIE CANDIDATE settled at %s outside the current or inside a seal" % here)
			continue
		_player.get("vitals").call("rest")
		var blockers := str(_fly.call("launch_blockers"))
		print("AERIE CANDIDATE %s blockers '%s'" % [here, blockers])
		if blockers.is_empty():
			return here
	return Vector3.INF


# --- shared checks ------------------------------------------------------------------

func _check_registration() -> void:
	var list: Array = _fly.get("restrictions")
	for id: String in [UPPER_ID, SUMMIT_ID]:
		var spec := _spec_in(_physical_data.get("restrictions", []), id)
		var entry := _registered(id)
		_check(not entry.is_empty(), "%s is registered with the production trainer's Fly controller (%d restrictions)" % [id, list.size()])
		if entry.is_empty():
			continue
		var bounds: AABB = entry["bounds"]
		_check(bounds.is_equal_approx(_box_of(spec)) and str(entry["requires_flag"]) == UPPER_FLAG
			and str(spec.get("requires_flag", "")) == UPPER_FLAG,
			"%s is registered as authored: %s behind %s" % [id, bounds, str(entry["requires_flag"])])
	var lift_found := false
	for draft: Dictionary in (_fly.get("updrafts") as Array):
		lift_found = lift_found or str(draft.get("id", "")) == AERIE_LIFT_ID
	_check(lift_found, "%s is registered with the Fly controller" % AERIE_LIFT_ID)


func _collect_gating_flags() -> void:
	var seen: Dictionary = {}
	for field: String in ["restrictions", "updrafts"]:
		for raw: Variant in _physical_data.get(field, []):
			seen[str((raw as Dictionary).get("requires_flag", ""))] = true
	for field: String in ["interactions", "landing_objectives", "ground_triggers"]:
		for raw: Variant in _physical_data.get(field, []):
			seen[str((raw as Dictionary).get("completion_flag", ""))] = true
	var world_config: Dictionary = _world.call("config_data")
	for raw: Variant in world_config.get("gates", []):
		seen[str((raw as Dictionary).get("requires_unlock", ""))] = true
	for raw: Variant in world_config.get("unlocks", []):
		seen[str((raw as Dictionary).get("id", ""))] = true
	seen[str(_fly_data.get("unlock_flag", FLY_FLAG))] = true
	seen.erase("")
	_gating_flags.clear()
	for flag: Variant in seen.keys():
		_gating_flags.append(str(flag))
	_gating_flags.sort()


func _gating_state() -> Dictionary:
	var state: Dictionary = {}
	for flag: String in _gating_flags:
		state[flag] = bool(_flags.call("has", flag))
	state["_all"] = _all_flags()
	return state


func _check_unlocks_unchanged(label: String, before: Dictionary) -> void:
	var changed: Array[String] = []
	for flag: String in _gating_flags:
		if bool(_flags.call("has", flag)) != bool(before.get(flag, false)):
			changed.append(flag)
	var was: Array = before.get("_all", [])
	var now := _all_flags()
	var added: Array[String] = []
	var removed: Array[String] = []
	for flag: String in now:
		if not was.has(flag):
			added.append(flag)
	for flag: Variant in was:
		if not now.has(str(flag)):
			removed.append(str(flag))
	print("%s FLAGS added=%s removed=%s" % [label, str(added), str(removed)])
	_check(changed.is_empty(), "%s: no unlock/gate/completion flag changed (%s)" % [label, str(changed)])


func _all_flags() -> Array[String]:
	var out: Array[String] = []
	for flag: Variant in (_flags.call("all_set") as Array):
		out.append(str(flag))
	out.sort()
	return out


func _check_party_same(label: String, uids: Array[String]) -> void:
	var now := _party_uids()
	_check(now == uids, "%s: the same party UIDs, same order, no sixth (%d)" % [label, now.size()])


func _party_uids() -> Array[String]:
	var party: RefCounted = _game.get("party")
	var out: Array[String] = []
	for i in int(party.call("size")):
		out.append(str((party.call("at", i) as RefCounted).get("uid")))
	return out


func _make_party(team: Array) -> RefCounted:
	var party: RefCounted = PARTY.new()
	for species: Variant in team:
		party.call("add", SPECIES.spawn(str(species)))
	party.call("set_active", 0)
	return party


# --- world helpers ------------------------------------------------------------------

## Fixture 2: a deliberate relocation, seated on the nearest authored surface
## to `at` (its Y disambiguates stacked roads). True once standing.
func _seat(at: Vector3, label: String) -> bool:
	_release_all()
	if bool(_fly.call("is_flying")):
		_fly.call("recover_to_anchor", "Smoke fixture relocation.")
		await _frames(2)
	var ground := float(_world.call("ground_height_near", at))
	if is_nan(ground):
		print("SEAT %s: no authored ground near %s" % [label, at])
		return false
	_fly.call("clear_recovery_anchor")
	_player.global_position = Vector3(at.x, ground + 0.4, at.z)
	_player.velocity = Vector3.ZERO
	await _frames(45)
	var standing := _player.is_on_floor() and not bool(_fly.call("is_flying"))
	print("SEAT %s: asked %s ground %.2f -> %s on_floor=%s" % [label, at, ground, _player.global_position, standing])
	return standing


func _gate_spec(id: String) -> Dictionary:
	for raw: Variant in (_world.call("config_data") as Dictionary).get("gates", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw
	return {}


func _gate_barrier(id: String) -> Node:
	var spec := _gate_spec(id)
	var gates := _world.get_node_or_null(^"TraversalGates")
	if spec.is_empty() or gates == null:
		return null
	var at := _vec3(spec["position"])
	for gate: Node in gates.get_children():
		if gate is Node3D and (gate as Node3D).global_position.distance_to(at) < 0.5:
			return gate.get_node_or_null(^"LockedTraversalBarrier")
	return null


func _barrier_disabled(barrier: Node) -> bool:
	var shapes := barrier.find_children("*", "CollisionShape3D", true, false)
	if shapes.is_empty():
		return true
	return (shapes[0] as CollisionShape3D).disabled


func _route_polyline(id: String) -> Array:
	for raw: Variant in (_world.call("config_data") as Dictionary).get("routes", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return (raw as Dictionary).get("polyline", [])
	return []


## As tests/smoke_cloudreach_saddle_remount.gd: the horizontal direction of the
## route segment the gate sits on. ZERO when none is found.
func _route_direction_at(flag: String, at: Vector3) -> Vector3:
	for raw: Variant in (_world.call("config_data") as Dictionary).get("routes", []):
		if not raw is Dictionary or str((raw as Dictionary).get("requires_unlock", "")) != flag:
			continue
		var line: Array = (raw as Dictionary).get("polyline", [])
		for i in line.size() - 1:
			var a := _vec3(line[i])
			var b := _vec3(line[i + 1])
			if Geometry3D.get_closest_point_to_segment(at, a, b).distance_to(at) < 2.0:
				var d := b - a
				d.y = 0.0
				return d.normalized()
	return Vector3.ZERO


func _registered(id: String) -> Dictionary:
	for entry: Dictionary in (_fly.get("restrictions") as Array):
		if str(entry.get("id", "")) == id:
			return entry
	return {}


func _spec_in(list: Variant, id: String) -> Dictionary:
	if list is Array:
		for raw: Variant in list:
			if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
				return raw
	return {}


func _box_of(spec: Dictionary) -> AABB:
	if not spec.has("position") or not spec.has("size"):
		return AABB()
	return AABB(_vec3(spec["position"]), _vec3(spec["size"]))


func _distance_to_box(p: Vector3, box: AABB) -> float:
	var q := Vector3(clampf(p.x, box.position.x, box.end.x), clampf(p.y, box.position.y, box.end.y),
		clampf(p.z, box.position.z, box.end.z))
	return p.distance_to(q)


func _denial_starting(prefix: String) -> String:
	for reason: String in _denials:
		if reason.begins_with(prefix):
			return reason
	return ""


func _on_denied(reason: String) -> void:
	_denials.append(reason)


func _on_recovered(_reason: String) -> void:
	_recoveries += 1


# --- input ----------------------------------------------------------------------------

func _deploy() -> void:
	await _tap("jump")
	await _frames(6)
	await _tap("jump")
	await _frames(3)


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _steer_toward(target: Vector3) -> void:
	var offset := target - _player.global_position
	offset.y = 0.0
	if offset.length() < 0.05:
		_release_move()
		return
	var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
	Input.action_press("move_right", maxf(local.x, 0.0))
	Input.action_press("move_left", maxf(-local.x, 0.0))
	Input.action_press("move_back", maxf(local.z, 0.0))
	Input.action_press("move_forward", maxf(-local.z, 0.0))


func _release_move() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)


func _release_all() -> void:
	_release_move()
	for action: String in ["jump", "fly_descend"]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _frames(count: int) -> void:
	for _i in count:
		await physics_frame


# --- data + reporting -------------------------------------------------------------------

func _read_json(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


func _vec3(raw: Variant) -> Vector3:
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _expect(ok: bool, message: String) -> bool:
	_check(ok, message)
	if not ok:
		_report()
	return ok


## A leg-level precondition: recorded as a failure, the leg stops, the run
## continues to the next leg and reports at the end.
func _require(ok: bool, message: String) -> bool:
	_check(ok, message)
	return ok


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL %s" % message)


func _report() -> void:
	if _finished:
		return
	_finished = true
	_release_all()
	print("CLOUDREACH CLOSED GATE SEAL %s checks=%d failures=%d" % [
		"OK" if _failures.is_empty() else "FAIL", _checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
