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
##   (e) Fly bypass of the closed ground gate: the owned Galecrest launches
##       from the same aerie stand, climbs the aerie current by holding Jump,
##       carries on into the overlapping middle current and climbs it, glides
##       by real input to a point 40 m before the gate on its route, then
##       steers for the stair crest 25 m past the closed
##       `upper_counterweight_gate`, holding `fly_descend` once height allows.
##       SYSTEMS §8: the trainer must never stand on ground past the gate while
##       `cloudreach_upper_route_unlocked` is unset (grounded on that route's
##       corridor more than 1 m past it by arc length fails, checked every
##       frame after launch and for 1 s after). The flight must also have come
##       within 8 m of the gate plane and been refused by a
##       `cloudreach_counterweight_*` seal, and never stood on the gate's
##       masonry. At bcf46366c (gate at [-123.4, 474.5, 2481.4]) this leg
##       landed 974 m past the gate on [-650, 570, 3300].
##   (f) On-foot walk-around: with the upper route locked, walk by real input
##       from 9 m before the gate toward a point 40 m past it at the same
##       lateral offset: +/-11 m, and the widest offset per side (12-24 m)
##       where a floor-grade ray finds ground at both ends (the ridge's steep
##       outer slope has none; such offsets are skipped, never counted). Each
##       walk must reach the gate plane (within 3 m) and the trainer must never
##       stand more than 1 m past it on the stair (nearest ground route is
##       windscar_counterweight_pass). Written against bcf46366c, where the
##       barrier and piers spanned +/-10.28 m but the walkable ridge track is
##       +/-11.5 m and the route shoulders +/-21.75 m.
##   (h) Glide at the west end of the gate's counterweight beam (its masonry
##       is wider than the stair): the counterweight seal must refuse the
##       flyer, who must never be grounded on the gate's masonry or past its
##       plane.
##   (i) Recovery: with the upper route opened (fixture 8) the owned carrier
##       flies by real input over the open gate into the stair volume; the
##       flag is then cleared around it. The production recovery must put the
##       trainer back on the verified launch anchor, never inside the seal or
##       under the stair.
##   (j) The same with the flyer's recovery anchor cleared first (production
##       clear_recovery_anchor()): the fly_controller guard must carry it
##       out of the sealed volumes (not hang it), and it lands on the open
##       approach, never past the gate.
##   (e), (h) also end their flights: once refused, the flyer turns back (as
##       a player would) and must land -- not hang at the seal -- on verified
##       ground (a floor-grade ray from 6 m above the feet hits within 0.6 m)
##       that is not inside any drawn mass (an upward ray against a back-face
##       copy of each enclosing mesh crosses it an even number of times). It
##       then walks out of the ~4-5 m no-fly margin over the approach crest by
##       real input and relaunches by Jump, Jump. Every flight that ends at
##       its anchor ((a), (b), (i)) gets the same drawn-mass and launch checks.
##   (g) The Windscar beacon and its bell stay walkable before the unlock: from
##       the Windscar junction, walk by real input along the pass to the stair
##       beside the beacon, through the beacon arch to its anchor and to the
##       `side_windscar_bell` interaction (inside its interaction radius),
##       never past the gate.
##
## The gate position is data (`cloudreach_world.json` gates). F06 moved it
## from [-123.4, 474.5, 2481.4] to where the pass enters upper_cloudreach,
## [-782.5, 650, 3555], restoring the authored intent (the gate protects
## upper_cloudreach/summit; the beacon, bell and optional_loop pickups are
## Windscar content): a portcullis across the ridge's flat track, piers and
## masonry wing walls out to +/-27.28 m, and the Fly seal
## `cloudreach_counterweight_stair_1..7` plus `cloudreach_counterweight_gate_crown`.
## Legs (c), (e), (f), (h) read the gate from data and so follow it.
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
##      route from the gate, and at the (f) lateral offsets), the Windscar
##      junction for (g), the aerie launch stand (the first candidate near
##      the `windscar_flight_aerie` landmark, inside `cloudreach_aerie_lift`,
##      where production `launch_blockers()` returns ""), and summit ground
##      (points of the `summit_overlook_loop` polyline) for the summit
##      in-volume refusal.
##   3. `fly_traversal_unlocked` is set directly after (d)/(c) (the flight
##      trial is not replayed here). `cloudreach_upper_route_unlocked` is set
##      only by fixture 8.
##   4. `vitals.rest()` before each launch attempt.
##   5. Between flights the production `fly_controller.recover_to_anchor()`
##      returns the flyer to its launch anchor instead of a long glide home.
##   6. Before (b) the party is replaced by a non-carrier full five.
##   7. During (e)/(h)/(i), stamina is refilled whenever it falls below half,
##      standing in for Skyborne's free flight (`fly_stamina_multiplier` 0.0):
##      the glide to the stair behind the gate is longer than one ordinary bar.
##      Once a refused flight is 25 m below the gate the refill stops, so it
##      ends the way an ordinary flight does.
##   8. (i)/(j) only: `cloudreach_upper_route_unlocked` is set before the
##      launch and cleared again while the flyer is inside the stair volume;
##      (j) also clears the recovery anchor first.
## Every walk, jump, Fly deploy, climb and steer is the real `move_*`/`jump`
## actions through the camera rig's `planar_basis`; nothing writes a flight
## state, a velocity during flight, or a flag other than (3) and (8).

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
const WATCHDOG_S := 3300.0
const BYPASS_ROUTE_ID := "windscar_counterweight_pass"
## Leg (e) lands on the stair crest this far along the route past the gate.
const BYPASS_TARGET_PAST_M := 25.0
## (e)/(h) watch the gate plane within this lateral band of the gate point.
const GATE_WATCH_LATERAL_M := 40.0
const MIDDLE_LIFT_ID := "cloudreach_middle_lift"
const BEACON_VISUAL := "res://data/config/cloudreach_windscar_beacon_visual.json"
const BYPASS_CORRIDOR_M := 15.0
const BYPASS_CORRIDOR_DY_M := 8.0
const BYPASS_PAST_LIMIT_M := 1.0
## (f) always walks at +/-11 m (inside the ridge's +/-11.5 m flat track), then
## at the widest offset on each side, from 12 m out to 24 m, where a
## floor-grade ray finds ground both 9 m before and 40 m past the gate.
## Offsets without ground (the ridge's steep outer slope) are skipped and
## reported, never counted.
const WALK_AROUND_OFFSETS := [11.0, -11.0]
const WALK_AROUND_EDGE_MAX_M := 24

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
var _landings: Array[Vector3] = []
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
	_fly.connect("landed", _on_landed)
	_collect_gating_flags()
	_check_registration()
	_check(not bool(_flags.call("has", UPPER_FLAG)) and not bool(_flags.call("has", FLY_FLAG)),
		"fixture starts with Fly and the upper route both locked")

	await _leg_locked_launch_and_gate_walk()
	if _finished:
		return
	await _leg_gate_walk_around()
	if _finished:
		return
	await _leg_beacon_reachable_before_unlock()
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
	await _leg_gate_bypass_by_fly(stand)
	if _finished:
		return
	await _leg_gate_beam_glide(stand)
	if _finished:
		return
	await _leg_seal_closes_around_flyer(stand)
	if _finished:
		return
	await _leg_seal_closes_around_flyer(stand, true)
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
	var enclosed: String = await _inside_drawn_mass(_player.global_position)
	_check(enclosed.is_empty(), "%s: back on ground at %s, not inside a drawn mass (%s)" % [label, _player.global_position, enclosed])
	_player.get("vitals").call("rest")
	await _frames(5)
	var blockers := str(_fly.call("launch_blockers"))
	_check(blockers.is_empty(), "%s: Fly may launch again from there ('%s')" % [label, blockers])


# --- (f): on foot around the ends of the closed gate -------------------------------

func _leg_gate_walk_around() -> void:
	var label := "(f) walk around"
	var spec := _gate_spec(GATE_ID)
	if not _require(not spec.is_empty(), "%s: %s is authored" % [label, GATE_ID]):
		return
	var gate := _vec3(spec["position"])
	var along := _route_direction_at(str(spec.get("requires_unlock", "")), gate)
	if not _require(along.length() > 0.5, "%s: the gate sits on its route" % label):
		return
	var right := Vector3.UP.cross(along).normalized()
	var line: Array[Vector3] = []
	for raw: Variant in _route_polyline(BYPASS_ROUTE_ID):
		line.append(_vec3(raw))
	var others: Array = []
	for raw: Variant in (_world.call("config_data") as Dictionary).get("routes", []):
		var route := raw as Dictionary
		if str(route.get("id", "")) == BYPASS_ROUTE_ID or str(route.get("traversal_mode", "ground")) != "ground":
			continue
		var other: Array[Vector3] = []
		for point: Variant in route.get("polyline", []):
			other.append(_vec3(point))
		others.append(other)
	var tps := Engine.physics_ticks_per_second
	var attempted := 0
	var offsets: Array[float] = []
	for raw_offset: Variant in WALK_AROUND_OFFSETS:
		offsets.append(float(raw_offset))
	for side: float in [1.0, -1.0]:
		for step in range(WALK_AROUND_EDGE_MAX_M, 11, -1):
			var probe := side * float(step)
			if not is_nan(_ray_ground(gate - along * 9.0 + right * probe, gate.y + 30.0, 100.0)) \
					and not is_nan(_ray_ground(gate + along * 40.0 + right * probe, gate.y + 45.0, 120.0)):
				offsets.append(probe)
				break
	print("%s offsets with ground at both ends: %s" % [label, str(offsets)])
	for offset: float in offsets:
		var start_xz := gate - along * 9.0 + right * offset
		var goal_xz := gate + along * 40.0 + right * offset
		var start_y := _ray_ground(start_xz, gate.y + 30.0, 100.0)
		var goal_y := _ray_ground(goal_xz, gate.y + 45.0, 120.0)
		print("%s offset %.0f: start %s ground %s, goal %s ground %s" % [label, offset,
			Vector2(start_xz.x, start_xz.z), str(start_y), Vector2(goal_xz.x, goal_xz.z), str(goal_y)])
		if is_nan(start_y) or is_nan(goal_y):
			print("%s offset %.0f: no walkable ground at the start or goal; skipped, not counted" % [label, offset])
			continue
		var seated: bool = await _seat_exact(Vector3(start_xz.x, start_y, start_xz.z), "%s %.0f" % [label, offset])
		if not seated:
			continue
		attempted += 1
		var start := _player.global_position
		var max_past := -INF
		var at_max := Vector3.INF
		var furthest := -INF
		for _frame in 25 * tps:
			_steer_toward(Vector3(goal_xz.x, 0.0, goal_xz.z))
			await physics_frame
			var at := _player.global_position
			furthest = maxf(furthest, (at - gate).dot(along))
			if _player.is_on_floor() and _on_stair(at, line, others):
				var past := (at - gate).dot(along)
				if past > max_past:
					max_past = past
					at_max = at
			if Vector2(goal_xz.x - at.x, goal_xz.z - at.z).length() < 1.5:
				break
			if at.y < start.y - 60.0 or float(_player.get("vitals").get("health")) <= 0.0:
				break
		_release_all()
		await _frames(10)
		print("%s offset %.0f: end %s on_floor=%s furthest_along=%.2f max_grounded_past_plane_on_stair=%.1f at %s" % [
			label, offset, _player.global_position, _player.is_on_floor(), furthest, max_past, at_max])
		_check(furthest >= -3.0,
			"%s: at %.0f m lateral offset the walk actually reached the gate plane (furthest %.2f m along)" % [label, offset, furthest])
		_check(max_past <= BYPASS_PAST_LIMIT_M,
			"%s: on foot at %.0f m lateral offset the trainer never stands more than 1 m past the closed gate plane on the stair (max %.1f m at %s)" % [
				label, offset, max_past, str(at_max)])
	_check(attempted >= 2, "%s: the walk-around ran on at least two offsets (%d of %d with ground)" % [label, attempted, offsets.size()])
	_check(not bool(_flags.call("has", UPPER_FLAG)), "%s: the upper route is still locked" % label)


## Grounded "on the stair": nearest authored ground route in plan is the locked
## pass, within its shoulders, and not far above it.
func _on_stair(at: Vector3, line: Array[Vector3], others: Array) -> bool:
	var progress := _route_progress(line, at)
	var h := float(progress["h"])
	if h > 25.0 or float(progress["dy"]) > 8.0 or float(progress["dy"]) < -60.0:
		return false
	for other: Variant in others:
		var points: Array[Vector3] = other
		if points.size() >= 2 and float(_route_progress(points, at)["h"]) <= h:
			return false
	return true


## Walkable ground under (x, z) by a physics ray from `top_y`; NAN when none.
func _ray_ground(xz: Vector3, top_y: float, depth: float) -> float:
	var from := Vector3(xz.x, top_y, xz.z)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * depth,
		_player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < cos(_player.floor_max_angle):
		return NAN
	return (hit["position"] as Vector3).y


## Fixture 2 with a measured height: stand exactly on ground a ray found.
func _seat_exact(at: Vector3, label: String) -> bool:
	_release_all()
	if bool(_fly.call("is_flying")):
		_fly.call("recover_to_anchor", "Smoke fixture relocation.")
		await _frames(2)
	_fly.call("clear_recovery_anchor")
	_player.global_position = at + Vector3.UP * 0.4
	_player.velocity = Vector3.ZERO
	await _frames(45)
	var standing := _player.is_on_floor() and not bool(_fly.call("is_flying"))
	print("SEAT %s: asked %s -> %s on_floor=%s" % [label, at, _player.global_position, standing])
	return standing


# --- (g): the Windscar beacon and bell stay walkable before the unlock -------------

func _leg_beacon_reachable_before_unlock() -> void:
	var label := "(g) beacon on foot"
	var line: Array[Vector3] = []
	for raw: Variant in _route_polyline(BYPASS_ROUTE_ID):
		line.append(_vec3(raw))
	var spec := _gate_spec(GATE_ID)
	if not _require(line.size() >= 2 and not spec.is_empty(), "%s: the pass and its gate are authored" % label):
		return
	var gate := _vec3(spec["position"])
	var along := _route_direction_at(str(spec.get("requires_unlock", "")), gate)
	var beacon := _read_json(BEACON_VISUAL)
	var anchor_xz: Array = beacon.get("anchor_xz", [])
	var heading_raw: Array = beacon.get("stand_heading_xz", [])
	var bell := _vec3(_spec_in(_physical_data.get("interactions", []), "side_windscar_bell").get("position", [0, 0, 0]))
	if not _require(anchor_xz.size() == 2 and heading_raw.size() == 2 and bell != Vector3.ZERO,
			"%s: beacon anchor, arch heading and side_windscar_bell are authored" % label):
		return
	var anchor := Vector3(float(anchor_xz[0]), bell.y, float(anchor_xz[1]))
	var heading := Vector2(float(heading_raw[0]), float(heading_raw[1])).normalized() * float(beacon.get("forward_offset_m", 15.0))
	var arch := anchor + Vector3(heading.x, 0.0, heading.y)
	var on_route := _line_point_at(line, float(_route_progress(line, arch)["s"]))
	_check(not bool(_flags.call("has", UPPER_FLAG)), "%s: the upper route is locked" % label)
	var seated: bool = await _seat(line[0] + Vector3.UP * 2.0, label + " junction")
	if not _require(seated, "%s: the trainer stands on the Windscar junction %s" % [label, line[0]]):
		return
	var furthest_past := -INF
	var results: Dictionary = {}
	for step: Array in [["stair beside the beacon", on_route, 2.0], ["beacon arch", arch, 1.5],
			["beacon anchor", anchor, 2.0], ["side_windscar_bell", bell, 3.0]]:
		var closest: float = await _walk_toward(Vector3(step[1]), float(step[2]), 90.0)
		results[str(step[0])] = closest
		var past := (_player.global_position - gate).dot(along)
		furthest_past = maxf(furthest_past, past)
		print("%s reached %s: closest %.2f m, now %s on_floor=%s" % [label, step[0], closest, _player.global_position, _player.is_on_floor()])
	_check(float(results.get("beacon anchor", INF)) <= 2.0 and _player.global_position.distance_to(bell) < 30.0,
		"%s: the Windscar beacon crown is walkable before %s (closest %.2f m)" % [label, UPPER_FLAG, float(results.get("beacon anchor", INF))])
	var radius := float(_physical_data.get("interaction_radius_m", 3.8))
	_check(float(results.get("side_windscar_bell", INF)) <= radius - 0.5 and _player.is_on_floor(),
		"%s: the trainer stands within the bell's %.1f m interaction radius (closest %.2f m)" % [label, radius, float(results.get("side_windscar_bell", INF))])
	_check(furthest_past < 0.0, "%s: the whole walk stays on the open side of the gate (furthest %.1f m)" % [label, furthest_past])
	_check(not bool(_flags.call("has", UPPER_FLAG)), "%s: the upper route is still locked" % label)


## Real-input walk toward `target` until within `tolerance` or `seconds`.
## Returns the closest horizontal approach; never fails by itself.
func _walk_toward(target: Vector3, tolerance: float, seconds: float) -> float:
	var closest := INF
	for _frame in int(seconds * Engine.physics_ticks_per_second):
		var offset := target - _player.global_position
		offset.y = 0.0
		closest = minf(closest, offset.length())
		if offset.length() <= tolerance:
			break
		_steer_toward(target)
		await physics_frame
		if float(_player.get("vitals").get("health")) <= 0.0:
			break
	_release_all()
	await _frames(10)
	return closest


# --- (e)/(h): Fly at the closed gate from the legal side ----------------------------

func _leg_gate_bypass_by_fly(stand: Vector3) -> void:
	var label := "(e) Fly bypass"
	var ctx := _gate_context(label)
	if ctx.is_empty():
		return
	var gate: Vector3 = ctx["gate"]
	var along: Vector3 = ctx["along"]
	var line: Array[Vector3] = ctx["line"]
	var s_gate := float(ctx["s_gate"])
	# The landing: the stair crest BYPASS_TARGET_PAST_M along the route past
	# the closed gate, confirmed as walkable ground behind it.
	var target := _line_point_at(line, s_gate + BYPASS_TARGET_PAST_M)
	var target_past := float(_route_progress(line, target)["s"]) - s_gate
	var target_ground := _ray_ground(target, target.y + 6.0, 18.0)
	print("%s TARGET %s past_gate_along_route=%.1f m plane_distance=%.1f m ground=%s" % [
		label, target, target_past, (target - gate).dot(along), str(target_ground)])
	if not _require(target_past > 10.0 and not is_nan(target_ground) and absf(target_ground - target.y) < 3.0,
			"%s: %s is walkable ground on the stair behind the closed gate" % [label, target]):
		return
	# Come in along the route from the open side, as a player flying over the
	# gate would, then press on toward the stair behind it.
	var approach := gate - along * 40.0
	var stats: Dictionary = await _seal_flight(label, stand, ctx, approach, Vector3(target.x, target_ground, target.z))
	if stats.is_empty():
		return
	_check(float(stats["max_past"]) <= BYPASS_PAST_LIMIT_M,
		"%s: SYSTEMS §8 -- with %s unset the trainer never stands on ground past the closed counterweight gate plane (max grounded %.1f m past it at %s; flight: %s)" % [
			label, UPPER_FLAG, float(stats["max_past"]), str(stats["max_past_at"]), stats["why"]])
	_check(float(stats["closest_plane"]) <= 8.0,
		"%s: the flight actually reached the closed gate (closest %.1f m from its plane within +/-%.0f m lateral)" % [
			label, float(stats["closest_plane"]), GATE_WATCH_LATERAL_M])
	_check(not str(stats["seal_denial"]).is_empty(),
		"%s: the counterweight seal refused the flight ('%s'; denials %s)" % [label, stats["seal_denial"], str(stats["denials"])])
	_check(not bool(stats["on_gate"]), "%s: never grounded on the closed gate's masonry (%s)" % [label, str(stats["on_gate_at"])])
	await _assert_settled(label, stats)
	await _walk_out_and_relaunch(label, ctx)


## (h) Glide at the west end of the gate's counterweight beam: its masonry is
## wider than the stair, and a flyer standing on it could walk the beam and
## step off behind the gate. The gate-crown seal must refuse it.
func _leg_gate_beam_glide(stand: Vector3) -> void:
	var label := "(h) beam-end glide"
	var ctx := _gate_context(label)
	if ctx.is_empty():
		return
	var gate: Vector3 = ctx["gate"]
	var along: Vector3 = ctx["along"]
	var right := Vector3.UP.cross(along).normalized()
	var spec: Dictionary = ctx["spec"]
	var width := float(spec.get("opening_width_m", 16.0))
	# Beam top: _build_progression_gates' counterweight, (width + 4) wide, top
	# 9.7 m above the gate point; aim at its west end.
	var beam_end := gate - right * ((width + 4.0) * 0.5 - 0.7)
	beam_end.y = gate.y + 9.7
	print("%s TARGET west beam end %s" % [label, beam_end])
	var approach := beam_end - along * 40.0
	var stats: Dictionary = await _seal_flight(label, stand, ctx, approach, beam_end)
	if stats.is_empty():
		return
	_check(not bool(stats["on_gate"]), "%s: never grounded on the closed gate's masonry (%s; flight: %s)" % [
		label, str(stats["on_gate_at"]), stats["why"]])
	_check(float(stats["max_plane_past"]) <= BYPASS_PAST_LIMIT_M,
		"%s: never grounded past the closed gate plane within +/-%.0f m lateral (max %.1f m at %s)" % [
			label, GATE_WATCH_LATERAL_M, float(stats["max_plane_past"]), str(stats["max_plane_past_at"])])
	_check(float(stats["closest_seal"]) <= 2.0,
		"%s: the glide actually reached the seal round the beam end (closest %.2f m from a counterweight volume; %.1f m from the beam end)" % [
			label, float(stats["closest_seal"]), float(stats["closest_beam"])])
	_check(not str(stats["seal_denial"]).is_empty(),
		"%s: the counterweight seal refused the glide ('%s'; denials %s)" % [label, stats["seal_denial"], str(stats["denials"])])
	await _assert_settled(label, stats)
	await _walk_out_and_relaunch(label, ctx)


## (i) Recovery check: the seal closing around a flyer already inside it --
## the state a trainer reloading a pre-unlock save mid-flight, or a flag
## reverted under them, would be in. Fixture 8 opens the upper route, the
## owned carrier flies by real input over the open gate into the stair volume,
## and fixture 8 then clears the flag. The production recovery must put the
## trainer back on the verified launch anchor: not left hanging inside the
## seal, not dropped through the stair.
func _leg_seal_closes_around_flyer(stand: Vector3, without_anchor: bool = false) -> void:
	var label := "(j) seal closes around a flyer with no anchor" if without_anchor else "(i) seal closes around a flyer"
	var ctx := _gate_context(label)
	if ctx.is_empty():
		return
	var gate: Vector3 = ctx["gate"]
	var along: Vector3 = ctx["along"]
	var line: Array[Vector3] = ctx["line"]
	var s_gate := float(ctx["s_gate"])
	var target := _line_point_at(line, s_gate + 20.0)
	var stair: Array[AABB] = []
	for spec: Dictionary in _physical_data.get("restrictions", []):
		if str(spec.get("id", "")).begins_with("cloudreach_counterweight_stair"):
			stair.append(_box_of(spec))
	if not _require(not stair.is_empty(), "%s: the counterweight stair seal is authored" % label):
		return
	var before := _gating_state()
	var uids := _party_uids()
	_flags.call("set_flag", UPPER_FLAG)
	await _frames(4)
	var watch := {"max_past": -INF, "at": Vector3.INF}
	var near := {"closest_plane": INF, "closest_beam": INF, "max_plane_past": -INF, "max_plane_past_at": Vector3.INF,
		"on_gate": false, "on_gate_at": Vector3.INF}
	var launched: bool = await _launch_and_climb(label, stand, ctx, target, watch, near)
	if not launched:
		_flags.call("set_flag", UPPER_FLAG, false)
		return
	var anchor: Vector3 = _fly.get("safe_anchor")
	var approach := gate - along * 40.0
	var heading_for := approach
	var inside_at := Vector3.INF
	var tps := Engine.physics_ticks_per_second
	for _frame in 200 * tps:
		if not bool(_fly.call("is_flying")):
			break
		_bypass_stamina_fixture()
		var offset := heading_for - _player.global_position
		offset.y = 0.0
		if heading_for == approach and offset.length() < 15.0:
			heading_for = target
		_steer_toward(heading_for)
		await physics_frame
		var at := _player.global_position
		if heading_for == target and at.y > target.y + 10.0 and (at - gate).dot(along) > 5.0:
			for box: AABB in stair:
				if box.has_point(at):
					inside_at = at
			if inside_at.is_finite():
				break
	_release_all()
	if not _require(inside_at.is_finite() and bool(_fly.call("is_flying")),
			"%s: flew by real input into the open stair volume at least 5 m past the gate (%s)" % [label, str(inside_at)]):
		_flags.call("set_flag", UPPER_FLAG, false)
		return
	var recoveries_before := _recoveries
	var denials_from := _denials.size()
	if without_anchor:
		await _escape_without_anchor(label, ctx, inside_at, before, uids)
		return
	_flags.call("set_flag", UPPER_FLAG, false)
	for _frame in 5 * tps:
		await physics_frame
		if not bool(_fly.call("is_flying")) and _player.is_on_floor():
			break
	await _frames(10)
	var end := _player.global_position
	var reasons := _denials.slice(denials_from)
	print("%s re-sealed with the flyer inside at %s (%.1f m past the plane); end %s anchor %s recoveries +%d denials %s" % [
		label, inside_at, (inside_at - gate).dot(along), end, anchor, _recoveries - recoveries_before, str(reasons)])
	var named := false
	for reason: String in reasons:
		named = named or reason.contains("cloudreach_counterweight_")
	_check(named, "%s: the re-closed seal reports itself (%s)" % [label, str(reasons)])
	_check(_recoveries > recoveries_before, "%s: the production recovery took the flyer out of the sealed volume" % label)
	_check(not bool(_fly.call("is_flying")) and _player.is_on_floor() and end.distance_to(anchor) < 1.5
		and _on_verified_top_surface(end),
		"%s: it stands on the verified launch anchor %s, not inside the seal or under the stair (%s)" % [label, anchor, end])
	var enclosed: String = await _inside_drawn_mass(end)
	_check(enclosed.is_empty(), "%s: the anchor %s is not inside a drawn mass (%s)" % [label, end, enclosed])
	_check(not bool(_flags.call("has", UPPER_FLAG)), "%s: the upper route is locked again" % label)
	_check_unlocks_unchanged(label, before)
	_check_party_same(label, uids)


## (j) M3: the same closing seal around a flyer whose recovery anchor is gone
## (fixture: production clear_recovery_anchor(), as a deliberate relocation
## leaves it). Before the guard the flyer hung in the air forever; now the
## sealed wind carries it out along the shortest horizontal way out of the
## closed volumes. Then it steers by real input back over the open approach
## and lands there.
func _escape_without_anchor(label: String, ctx: Dictionary, inside_at: Vector3, before: Dictionary,
		uids: Array[String]) -> void:
	var gate: Vector3 = ctx["gate"]
	var along: Vector3 = ctx["along"]
	var line: Array[Vector3] = ctx["line"]
	var s_gate := float(ctx["s_gate"])
	var right := Vector3.UP.cross(along).normalized()
	_fly.call("clear_recovery_anchor")
	_flags.call("set_flag", UPPER_FLAG, false)
	var tps := Engine.physics_ticks_per_second
	var home := gate - along * 18.0
	var watch := {"max_past": -INF, "at": Vector3.INF}
	var near := {"closest_plane": INF, "closest_beam": INF, "max_plane_past": -INF, "max_plane_past_at": Vector3.INF,
		"on_gate": false, "on_gate_at": Vector3.INF}
	var start := _player.global_position
	var depth_start := (_fly.call("sealed_exit", start) as Vector3).length()
	var left_after := -1.0
	var recoveries_before := _recoveries
	for frame in 90 * tps:
		if not bool(_fly.call("is_flying")):
			break
		var offset := home - _player.global_position
		offset.y = 0.0
		if offset.length() > 1.5:
			_steer_toward(home)
		else:
			_release_move()
		if left_after >= 0.0:
			Input.action_press("fly_descend")
		await physics_frame
		_watch_gate(line, s_gate, gate, along, right, home, watch, near)
		if left_after < 0.0 and (_fly.call("sealed_exit", _player.global_position) as Vector3) == Vector3.ZERO:
			left_after = float(frame) / float(tps)
			print("%s out of the sealed volume after %.2f s at %s" % [label, left_after, _player.global_position])
	_release_all()
	await _frames(30)
	var end := _player.global_position
	print("%s re-sealed inside at %s, %.1f m from the nearest way out; end %s flying=%s left_after=%.2f s recoveries +%d" % [
		label, start, depth_start, end, bool(_fly.call("is_flying")), left_after, _recoveries - recoveries_before])
	_check(depth_start > 0.0, "%s: the fixture closed the seal with the flyer inside it (%.1f m from a way out)" % [label, depth_start])
	_check(left_after >= 0.0 and left_after < 10.0,
		"%s: the flyer did not hang -- the guard carried it out of the sealed volume (%.2f s)" % [label, left_after])
	_check(float(watch["max_past"]) <= BYPASS_PAST_LIMIT_M and float(near["max_plane_past"]) <= BYPASS_PAST_LIMIT_M,
		"%s: it never stood past the closed gate (route %.1f m, plane %.1f m)" % [
			label, float(watch["max_past"]), float(near["max_plane_past"])])
	_check(not bool(_fly.call("is_flying")) and _player.is_on_floor() and _on_verified_top_surface(end),
		"%s: it landed on verified ground on the open approach at %s" % [label, end])
	var enclosed: String = await _inside_drawn_mass(end)
	_check(enclosed.is_empty(), "%s: the landing %s is not inside a drawn mass (%s)" % [label, end, enclosed])
	_check(not bool(_flags.call("has", UPPER_FLAG)), "%s: the upper route is locked again" % label)
	_check_unlocks_unchanged(label, before)
	_check_party_same(label, uids)
	await _walk_out_and_relaunch(label, ctx)


## After a refused flight lands on the approach: the ~4-5 m no-fly margin the
## axis-aligned slices lay over the approach crest is not a trap. At the
## landing the counterweight seal is the only restriction (production
## _restricted_reason, the same test launch_blockers makes); the trainer walks
## out by real input to the last flat pad before the gate and may launch again
## there. (The 20-degree stair itself refuses every launch for "room
## overhead": the 0.7 m flight capsule, tangent at the feet, cuts into any
## upslope. That is production behaviour everywhere on the ramp.)
func _walk_out_and_relaunch(label: String, ctx: Dictionary) -> void:
	var gate: Vector3 = ctx["gate"]
	var along: Vector3 = ctx["along"]
	var line: Array[Vector3] = ctx["line"]
	var s_gate := float(ctx["s_gate"])
	var here := _player.global_position
	var here_seal := str(_fly.call("_restricted_reason", here, here))
	print("%s landing: %.1f m before the plane, restriction '%s', launch_blockers '%s'" % [
		label, -(here - gate).dot(along), here_seal, str(_fly.call("launch_blockers"))])
	_check(here_seal.is_empty() or here_seal.contains("cloudreach_counterweight_"),
		"%s: at the landing the only restriction is the counterweight seal's ('%s')" % [label, here_seal])
	var pad := Vector3.INF
	for point: Vector3 in line:
		if float(_route_progress(line, point)["s"]) < s_gate - 20.0:
			pad = point
	var closest: float = await _walk_toward(pad, 1.5, 60.0)
	_player.get("vitals").call("rest")
	await _frames(20)
	var out := _player.global_position
	var after_seal := str(_fly.call("_restricted_reason", out, out))
	var after_blockers := str(_fly.call("launch_blockers"))
	print("%s walked out to %s (pad %s): restriction '%s', launch_blockers '%s'" % [label, out, pad, after_seal, after_blockers])
	_check(closest <= 1.5 and after_seal.is_empty() and after_blockers.is_empty(),
		"%s: walked out by real input to the pad %s (%.1f m) and may launch again ('%s')" % [
			label, pad, closest, after_blockers])
	if not after_blockers.is_empty():
		return
	await _deploy()
	var relaunched := bool(_fly.call("is_flying"))
	_check(relaunched, "%s: a real Jump, Jump relaunches Fly from the pad (state %s)" % [label, str(_fly.get("state"))])
	await _end_flight(label + " relaunch")


## H1: the trainer's feet are not inside any drawn mass. For each large mesh
## whose box holds the feet, a temporary back-face trimesh copy of exactly
## what is drawn is cast against upwards from just above the feet; an odd
## number of crossings means the feet are enclosed. Returns the enclosing
## mesh's path, or "".
func _inside_drawn_mass(at: Vector3) -> String:
	var probe := at + Vector3.UP * 0.3
	var candidates: Array[MeshInstance3D] = []
	for node: Node in _world.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		var box := mesh_instance.global_transform * mesh_instance.get_aabb()
		if minf(box.size.x, box.size.z) < 12.0 or not box.grow(0.1).has_point(probe):
			continue
		candidates.append(mesh_instance)
	for mesh_instance: MeshInstance3D in candidates:
		var shape := mesh_instance.mesh.create_trimesh_shape()
		if shape == null:
			continue
		shape.backface_collision = true
		var body := StaticBody3D.new()
		body.collision_layer = 1 << 30
		body.collision_mask = 0
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		_world.add_child(body)
		body.global_transform = mesh_instance.global_transform
		await physics_frame
		var crossings := 0
		var from := probe
		for i in 64:
			var query := PhysicsRayQueryParameters3D.create(from, probe + Vector3.UP * 1200.0, 1 << 30)
			query.hit_back_faces = true
			var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty():
				break
			crossings += 1
			from = (hit["position"] as Vector3) + Vector3.UP * 0.02
		body.queue_free()
		await physics_frame
		if crossings % 2 == 1:
			return "%s (%d crossings above the feet)" % [str(mesh_instance.get_path()), crossings]
	return ""


## Condition 2: a refused flight ends -- it is not left hanging at a seal --
## on verified ground: landed on a floor with nothing solid over the trainer's
## head, or put back on the verified anchor by the production recovery.
func _assert_settled(label: String, stats: Dictionary) -> void:
	_check(bool(stats["ended"]), "%s: the refused flight ended instead of hanging at the seal (%s)" % [label, stats["why"]])
	_check(bool(stats["verified_ground"]) and _player.is_on_floor(),
		"%s: it ended on verified ground at %s, not inside or under geometry (recoveries %d)" % [
			label, str(stats["end"]), int(stats["recoveries"])])
	var enclosed: String = await _inside_drawn_mass(_player.global_position)
	_check(enclosed.is_empty(), "%s: the landing %s is not inside a drawn mass (%s)" % [
		label, _player.global_position, enclosed])


## A trainer on a real top surface: a floor-grade ray from 6 m above the feet
## hits within 0.6 m of them, so nothing solid lies over the trainer (not
## under the world or inside a mesh).
func _on_verified_top_surface(at: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 6.0, at + Vector3.DOWN * 1.0,
		_player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and absf((hit["position"] as Vector3).y - at.y) <= 0.6 \
		and (hit["normal"] as Vector3).y >= cos(_player.floor_max_angle)


func _gate_context(label: String) -> Dictionary:
	var spec := _gate_spec(GATE_ID)
	if not _require(not spec.is_empty(), "%s: %s is authored" % [label, GATE_ID]):
		return {}
	var gate := _vec3(spec["position"])
	var along := _route_direction_at(str(spec.get("requires_unlock", "")), gate)
	var line: Array[Vector3] = []
	for raw: Variant in _route_polyline(BYPASS_ROUTE_ID):
		line.append(_vec3(raw))
	if not _require(along.length() > 0.5 and line.size() >= 2, "%s: the gate sits on %s" % [label, BYPASS_ROUTE_ID]):
		return {}
	var at_gate := _route_progress(line, gate)
	_check(float(at_gate["h"]) < 2.0, "%s: the gate lies on the %s polyline (%.2f m off)" % [label, BYPASS_ROUTE_ID, float(at_gate["h"])])
	if not _require(not bool(_flags.call("has", UPPER_FLAG)) and bool(_flags.call("has", FLY_FLAG)),
			"%s: Fly unlocked, %s unset" % [label, UPPER_FLAG]):
		return {}
	return {"spec": spec, "gate": gate, "along": along, "line": line, "s_gate": float(at_gate["s"])}


## Seat on the aerie stand, launch the owned carrier by real Jump, Jump, climb
## the aerie current and then the overlapping middle current (Jump held),
## recording each frame with _watch_gate. False on a precondition failure.
func _launch_and_climb(label: String, stand: Vector3, ctx: Dictionary, target: Vector3, watch: Dictionary,
		near: Dictionary) -> bool:
	var gate: Vector3 = ctx["gate"]
	var along: Vector3 = ctx["along"]
	var line: Array[Vector3] = ctx["line"]
	var s_gate := float(ctx["s_gate"])
	var right := Vector3.UP.cross(along).normalized()
	var seated: bool = await _seat(stand, label + " launch stand")
	if not _require(seated, "%s: the trainer stands on the aerie launch stand" % label):
		return false
	var party: RefCounted = _game.get("party")
	var active: RefCounted = party.call("active")
	_check(active != null and str(active.get("species_id")) == "galecrest", "%s: the owned Galecrest is active" % label)
	_player.get("vitals").call("rest")
	var blockers := str(_fly.call("launch_blockers"))
	_check(blockers.is_empty(), "%s: the aerie stand is a legal launch ('%s')" % [label, blockers])
	_denials.clear()
	_landings.clear()
	_recoveries = 0
	await _deploy()
	if not _require(bool(_fly.call("is_flying")), "%s: Jump, then Jump airborne, deploys Fly (state %s, denials %s)" % [
			label, str(_fly.get("state")), str(_denials)]):
		return false
	_check(not bool(_fly.call("last_flight_used_mentor_loaner")), "%s: the owned carrier flies, not the loaner" % label)
	var tps := Engine.physics_ticks_per_second
	var climb_from := _player.global_position.y
	Input.action_press("jump")
	for _frame in 25 * tps:
		await physics_frame
		_watch_gate(line, s_gate, gate, along, right, target, watch, near)
		if not bool(_fly.call("is_flying")) or _player.global_position.y >= _lift_ceiling - 6.0:
			break
	print("%s CLIMB from %.1f to %s" % [label, climb_from, _player.global_position])
	# The stair behind the gate sits above what a glide from the aerie current
	# alone can reach, so carry on (Jump still held) into the authored middle
	# current where it overlaps the aerie one, and climb to its ceiling.
	var middle := _spec_in(_physical_data.get("updrafts", []), MIDDLE_LIFT_ID)
	var middle_box := _box_of(middle)
	var middle_ceiling := minf(float(middle.get("ceiling_y", 0.0)), middle_box.end.y) - 2.0
	var overlap := middle_box.intersection(_lift_box)
	var into_middle := overlap.get_center() if overlap.has_volume() else middle_box.get_center()
	for _frame in 40 * tps:
		var offset := into_middle - _player.global_position
		offset.y = 0.0
		if offset.length() > 6.0:
			_steer_toward(into_middle)
		else:
			_release_move()
		await physics_frame
		_watch_gate(line, s_gate, gate, along, right, target, watch, near)
		_bypass_stamina_fixture()
		if not bool(_fly.call("is_flying")) or _player.global_position.y >= middle_ceiling - 6.0:
			break
	_release_all()
	print("%s MIDDLE CURRENT at %s (ceiling %.1f)" % [label, _player.global_position, middle_ceiling])
	return bool(_fly.call("is_flying"))


## Launch the owned carrier from the aerie stand, climb the aerie current and
## then the overlapping middle current, glide by real input to `approach`,
## then toward `target` (holding fly_descend once the height to spare allows,
## and over the target), until the flight ends. Returns what happened; the
## caller asserts. Empty on a precondition failure.
func _seal_flight(label: String, stand: Vector3, ctx: Dictionary, approach: Vector3, target: Vector3) -> Dictionary:
	var gate: Vector3 = ctx["gate"]
	var along: Vector3 = ctx["along"]
	var line: Array[Vector3] = ctx["line"]
	var s_gate := float(ctx["s_gate"])
	var right := Vector3.UP.cross(along).normalized()
	var uids := _party_uids()
	var before := _gating_state()
	var watch := {"max_past": -INF, "at": Vector3.INF}
	var near := {"closest_plane": INF, "closest_beam": INF, "max_plane_past": -INF, "max_plane_past_at": Vector3.INF,
		"on_gate": false, "on_gate_at": Vector3.INF, "closest_seal": INF, "seal_boxes": _counterweight_seal_boxes()}
	var launched: bool = await _launch_and_climb(label, stand, ctx, target, watch, near)
	if not launched:
		return {}
	var tps := Engine.physics_ticks_per_second

	var speed := float(_fly_data.get("speed_mps", 16.0))
	var sink := float(_fly_data.get("sink_mps", 2.0))
	var ended_frame := -1
	var settling := false
	var heading_for := approach
	# Once a counterweight seal has refused it with nothing to land on below,
	# the flyer turns back, as a player would, to land on the open approach.
	var home := gate - along * 18.0
	var refused_frame := -1
	for frame in 300 * tps:
		if not bool(_fly.call("is_flying")):
			ended_frame = frame
			break
		if not settling:
			_bypass_stamina_fixture()
		var offset := heading_for - _player.global_position
		offset.y = 0.0
		if heading_for == approach and offset.length() < 15.0:
			heading_for = target
			print("%s over the approach at %s; now toward %s" % [label, _player.global_position, target])
			offset = heading_for - _player.global_position
			offset.y = 0.0
		if refused_frame < 0 and _seal_denied():
			refused_frame = frame
		# Refused: keep coming down while there is ridge-top ground below to
		# land on; with only void or cliff below, turn back to the approach.
		if heading_for == target and refused_frame >= 0 and frame % 15 == 0 \
				and is_nan(_ray_ground(_player.global_position, _player.global_position.y, 160.0)):
			heading_for = home
			print("%s refused at %s; turning back to land at %s" % [label, _player.global_position, home])
			offset = heading_for - _player.global_position
			offset.y = 0.0
		var horizontal := offset.length()
		var aim := home if heading_for == home else target
		if horizontal > (1.5 if heading_for == home else 12.0):
			_steer_toward(heading_for)
		else:
			_release_move()
		var to_target := Vector2(aim.x - _player.global_position.x, aim.z - _player.global_position.z).length()
		var spare := (_player.global_position.y - aim.y) - (to_target / speed * sink + 15.0)
		if heading_for != approach and (horizontal <= 12.0 or spare > 0.0):
			Input.action_press("fly_descend")
		else:
			Input.action_release("fly_descend")
		await physics_frame
		_watch_gate(line, s_gate, gate, along, right, target, watch, near)
		if not settling and heading_for == target and _player.global_position.y < minf(target.y, gate.y) - 25.0 and _seal_denied():
			# Refused and well below the gate: let the flight end the way an
			# ordinary one does -- stamina runs down (fixture 7 stops) and the
			# carrier lands or the verified-anchor recovery takes over.
			print("%s refused and now %.0f m below the gate; letting the flight settle" % [label, gate.y - _player.global_position.y])
			settling = true
		if frame % (5 * tps) == 0:
			print("%s GLIDE t=%.0fs at=%s state=%s stamina=%.1f to_target=%.1f m" % [label, float(frame) / tps,
				_player.global_position, str(_fly.get("state")), float(_player.get("vitals").get("stamina")), to_target])
	_release_all()
	for _frame in tps:
		await physics_frame
		_watch_gate(line, s_gate, gate, along, right, target, watch, near)
	var end := _player.global_position
	var why := "still flying after 300 s"
	if not _landings.is_empty():
		why = "landed at %s" % _landings[_landings.size() - 1]
	if _recoveries > 0:
		why += "; recovered to the anchor %d time(s)" % _recoveries
	if not _denials.is_empty():
		why += "; denials %s" % str(_denials)
	var seal_denial := ""
	for reason: String in _denials:
		if reason.contains("cloudreach_counterweight_"):
			seal_denial = reason
			break
	var end_progress := _route_progress(line, end)
	print("%s END at %s on_floor=%s flying=%s ended_frame=%d why: %s | route: past_gate=%.1f m off_route=%.1f m dy=%.1f m, gate-plane distance=%.1f m, closest to plane %.1f m, closest to target %.1f m" % [
		label, end, _player.is_on_floor(), bool(_fly.call("is_flying")), ended_frame, why,
		float(end_progress["s"]) - s_gate, float(end_progress["h"]), float(end_progress["dy"]), (end - gate).dot(along),
		float(near["closest_plane"]), float(near["closest_beam"])])
	_check(not bool(_flags.call("has", UPPER_FLAG)), "%s: the upper route is still locked" % label)
	_check_unlocks_unchanged(label, before)
	_check_party_same(label, uids)
	return {"ended": ended_frame >= 0 and not bool(_fly.call("is_flying")),
		"verified_ground": _on_verified_top_surface(end), "recoveries": _recoveries,
		"max_past": watch["max_past"], "max_past_at": watch["at"], "why": why, "denials": _denials.duplicate(),
		"seal_denial": seal_denial, "closest_plane": near["closest_plane"], "closest_beam": near["closest_beam"],
		"max_plane_past": near["max_plane_past"], "max_plane_past_at": near["max_plane_past_at"],
		"on_gate": near["on_gate"], "on_gate_at": near["on_gate_at"], "end": end,
		"closest_seal": near["closest_seal"]}


func _counterweight_seal_boxes() -> Array:
	var out: Array = []
	for spec: Dictionary in _physical_data.get("restrictions", []):
		if str(spec.get("id", "")).begins_with("cloudreach_counterweight_"):
			out.append(_box_of(spec))
	return out


func _seal_denied() -> bool:
	for reason: String in _denials:
		if reason.contains("cloudreach_counterweight_"):
			return true
	return false


## Per-frame record for (e)/(h): the route-corridor watch, plus the closest
## the flyer came to the gate plane (within GATE_WATCH_LATERAL_M of it) and to
## the target, any grounded frame past the plane in that band, and any
## grounded frame on the gate's own masonry (top faces 9-9.7 m above it).
func _watch_gate(line: Array[Vector3], s_gate: float, gate: Vector3, along: Vector3, right: Vector3,
		target: Vector3, watch: Dictionary, near: Dictionary) -> void:
	_watch_bypass(line, s_gate, watch)
	var at := _player.global_position
	var rel := at - gate
	var plane := rel.dot(along)
	var lateral := rel.dot(right)
	near["closest_beam"] = minf(float(near["closest_beam"]), at.distance_to(target))
	for box: Variant in near.get("seal_boxes", []):
		near["closest_seal"] = minf(float(near.get("closest_seal", INF)), _distance_to_box(at, box as AABB))
	if absf(lateral) <= GATE_WATCH_LATERAL_M:
		near["closest_plane"] = minf(float(near["closest_plane"]), absf(plane))
	if not _player.is_on_floor() or bool(_fly.call("is_flying")):
		return
	if absf(lateral) <= GATE_WATCH_LATERAL_M and plane > float(near["max_plane_past"]):
		near["max_plane_past"] = plane
		near["max_plane_past_at"] = at
	if absf(plane) <= 2.5 and absf(lateral) <= 29.0 and rel.y >= 7.0:
		near["on_gate"] = true
		near["on_gate_at"] = at


## Fixture 7: keep the flyer's stamina full, standing in for Skyborne's free
## flight (`fly_stamina_multiplier` 0.0). The gliding distance from the
## aerie to the stair behind the gate exceeds one bar of ordinary stamina, and
## a seal that only holds while stamina runs out is not a seal.
func _bypass_stamina_fixture() -> void:
	var vitals: RefCounted = _player.get("vitals")
	if float(vitals.get("stamina")) < float(vitals.get("max_stamina")) * 0.5:
		vitals.call("rest")


## Records the furthest a GROUNDED trainer stood past the gate along the locked
## route, counting only ground on that route's corridor (so the aerie, which
## is on the far side of the infinite gate plane but nowhere near the stair,
## does not count).
func _watch_bypass(line: Array[Vector3], s_gate: float, watch: Dictionary) -> void:
	if not _player.is_on_floor() or bool(_fly.call("is_flying")):
		return
	var at := _player.global_position
	var progress := _route_progress(line, at)
	if float(progress["h"]) > BYPASS_CORRIDOR_M or absf(float(progress["dy"])) > BYPASS_CORRIDOR_DY_M:
		return
	var past := float(progress["s"]) - s_gate
	if past > float(watch["max_past"]):
		watch["max_past"] = past
		watch["at"] = at


## The polyline point at plan arc length `s` (height interpolated).
func _line_point_at(line: Array[Vector3], s: float) -> Vector3:
	var run := 0.0
	for i in line.size() - 1:
		var length := Vector2(line[i + 1].x - line[i].x, line[i + 1].z - line[i].z).length()
		if run + length >= s and length > 0.0:
			return line[i].lerp(line[i + 1], clampf((s - run) / length, 0.0, 1.0))
		run += length
	return line[line.size() - 1]


## Closest point on the polyline in plan: arc length `s` to it, horizontal
## distance `h` from it, and height `dy` above the polyline there.
func _route_progress(line: Array[Vector3], p: Vector3) -> Dictionary:
	var best := {"s": 0.0, "h": INF, "dy": INF}
	var run := 0.0
	var flat := Vector3(p.x, 0.0, p.z)
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var fa := Vector3(a.x, 0.0, a.z)
		var fb := Vector3(b.x, 0.0, b.z)
		var q := Geometry3D.get_closest_point_to_segment(flat, fa, fb)
		var length := fa.distance_to(fb)
		var t := 0.0 if length < 0.001 else fa.distance_to(q) / length
		var h := flat.distance_to(q)
		if h < float(best["h"]):
			best = {"s": run + fa.distance_to(q), "h": h, "dy": p.y - lerpf(a.y, b.y, t)}
		run += length
	return best


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


func _on_landed(at: Vector3, _species_id: String) -> void:
	_landings.append(at)


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
