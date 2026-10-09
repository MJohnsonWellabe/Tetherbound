extends "res://tests/helpers/stick_navigator.gd"

## Native route checks for real opening stick travel. Real M1 remains OPEN until executed.
## No collider representation, terrain sampler, visibility graph or pose writes.
## Road choices are provisional; only real stick travel can establish traversal.
const MAX_ROAD_INPUTS := 64
const MAX_HOUSES := 16
const MAX_CHOICES := 8
const MAX_PLANS := 256
const MAX_QUERIES_FRAME := 96
const MAX_QUERIES_LIFETIME := 250000
const MAX_REQUESTS := 24000
const MAX_CONFIG_BYTES := 1048576
const MAX_EDGE := 180.0
const FRAME_QUERY_US := 10000 # Cooperative; cannot interrupt a slow native call.
const CONTACTS := 8
const THRESHOLD_RADIUS := 0.25
## An intermediate heading the trainer came within this distance of (the same cap
## as set_approach_radius) and then failed to close on for CIRCLE_FRAMES driven
## frames (the same length as the unchanged 90-frame stall cap) is released.
const CIRCLE_RADIUS := 1.65
const CIRCLE_FRAMES := 90
const CONTACT_EPS := 0.00001 # Numerical comparison only, never a smaller shape.
const LOW_PROP_RISE := 0.05
## Coordinator ruling 2026-10-04 (F02#1 Oskar refusal on a loaded runner): a
## wall-clock cooperative deadline is host speed, not geometry. Exceeding one
## releases the stick and retries on the next physics frame, bounded by this
## many CONSECUTIVE deferred frames (a frame count, never wall time). Deferred
## frames still spend the caller's unchanged walk budget. Identity, count and
## contact-saturation guards stay hard refusals.
const MAX_DEFERRAL_FRAMES := 30

## A physics_frame signal resumes BEFORE NativeTick and the controller. A
## submitted attempt is finished only by its corresponding actual callback epoch.
## This keeps nested coroutine resumes from spending walking frames without
## crossing the real pre/controller/post movement callbacks.
## Completion spends one attempt, including a deferred/refused pre check; only
## the unchanged successful production post check can set _checked_start.
class StepEpoch extends RefCounted:
	var issued := 0
	var completed := 0
	var in_flight := 0
	var pre_frame := -1
	func request() -> int:
		issued += 1
		return issued
	func begin(token: int, frame: int) -> bool:
		if frame < 0 or token < 0 or token > issued or (token > 0 and token <= completed) or in_flight > 0:
			return false
		in_flight = token
		pre_frame = frame
		return true
	func finish(frame: int) -> void:
		if in_flight > 0 and frame == pre_frame:
			completed = in_flight
		in_flight = 0

var _step_epoch := StepEpoch.new()
var _requested_step := 0

## Frame-counted deferral ledger for the cooperative deadline (see
## MAX_DEFERRAL_FRAMES). One deferral per physics frame at most.
class DeadlineDeferral extends RefCounted:
	var total := 0
	var consecutive := 0
	var this_frame := false
	var last_where := ""
	## Call once at the start of every physics frame.
	func new_frame() -> void:
		if not this_frame:
			consecutive = 0
		this_frame = false
	## Records a deferral; false once the consecutive-frame bound is exhausted.
	func defer(where: String) -> bool:
		last_where = where
		if not this_frame:
			this_frame = true
			total += 1
			consecutive += 1
			print("OPENING_NAV_DEFERRAL " + JSON.stringify({"where": where, "total": total,
				"consecutive": consecutive, "cap_frames": MAX_DEFERRAL_FRAMES}))
		return consecutive <= MAX_DEFERRAL_FRAMES

class NativeTick extends Node:
	var navigator: WeakRef
	var records: Array[Dictionary] = []
	var flush_pending := false
	func flush_records() -> void:
		# Snapshots contain values only. Never read a later body pose here.
		flush_pending = false
		var batch: Array[Dictionary] = records
		records = []
		for record: Dictionary in batch: # At most two queued records.
			var began: int = Time.get_ticks_usec()
			var encoded := JSON.stringify(record)
			var formatted: int = Time.get_ticks_usec()
			print("OPENING_PRODUCTION_OBSERVATION " + encoded)
			var emitted: int = Time.get_ticks_usec()
			print("OPENING_PRODUCTION_LOG_COST " + JSON.stringify({"requests": record.requests,
				"serialization_us": formatted - began, "observation_print_us": emitted - formatted,
				"outside_physics_cap": true, "cost_line_print_measured": false}))
	func _physics_process(delta: float) -> void:
		var nav: RefCounted = navigator.get_ref()
		if nav == null:
			queue_free()
		else:
			nav.call("_native_tick", delta)
			if not bool(nav.get("_production_steering")):
				nav.call("_finish_step_epoch")

var _body: CharacterBody3D
var _cap: CollisionShape3D
var _world: Node3D
var _tick: NativeTick
var _roads: Array[Vector2] = []
var _authored_roads: Dictionary = {}
var _guided_road: Array[Vector2] = []
var _guided_label := ""
var _provisional_path: Array[Vector2] = []
var _recipes: Dictionary = {}
var _route: Array[Vector2] = []
var _goal := Vector2.INF
var _arrival := 0.05
var _requested := false
var _raw := false
var _request := Vector3.ZERO
var _owns_input := false
var _reason := ""
var _queries := 0
var _total_queries := 0
var _requests := 0
var _plans := 0
var _deadline := 0
var _owner := -1
var _body_rid: RID
var _capsule_index := -1
var _step_height := 0.0
var _probe := 0.0
var _departure: Array[Vector2] = []
var _departure_floor := 0.0
var _departure_house: Node3D
var _departure_leaf: CollisionShape3D
var _leaf_pose := Transform3D.IDENTITY
var _leaf_shape: BoxShape3D
var _leaf_size := Vector3.ZERO
var _house_pose := Transform3D.IDENTITY
var _completed_house: Node3D
var _progress_at := Vector3.ZERO
var _stalled := 0
var _circle_at := Vector2.INF
var _circle_best := INF
var _circle_frames := 0
var _checked_start := false
var _deferral := DeadlineDeferral.new()
## True from a deadline deferral until this frame's callbacks finish. Later
## refusals in the same callback are artifacts of the blocked queries.
var _deferred := false


func _init(tree: SceneTree, player: Node3D, rig: Node3D, drive: Callable, production_steering: bool = false) -> void:
	super(tree, player, rig, drive)
	_production_steering = production_steering
	_contact_init()
	_body = player as CharacterBody3D
	_world = player.get_parent() as Node3D
	_cap = player.get_node_or_null(^"Collision") as CollisionShape3D
	var terrain: Variant = _config("res://data/config/terrain_playground.json")
	var village: Variant = _config("res://data/config/village.json")
	var recipes: Variant = _config("res://data/config/building_prefabs.json")
	if not terrain is Dictionary or not terrain.get("paths") is Dictionary \
			or not terrain.paths.get("routes") is Array or terrain.paths.routes.size() > 8 \
			or not village is Dictionary or not village.get("road_plan") is Dictionary \
			or not recipes is Dictionary or not recipes.get("prefabs") is Dictionary:
		_stop_geometry("missing bounded authored road/room data")
		return
	_recipes = recipes.prefabs
	for road: Variant in terrain.paths.routes:
		if not road is Dictionary or not road.get("points") is Array or road.points.size() > MAX_ROAD_INPUTS:
			_stop_geometry("invalid authored road")
			return
		var authored: Array[Vector2] = []
		for pair: Variant in road.points:
			if not _append_road(pair):
				return
			authored.append(_roads.back())
		if _production_steering:
			var label := str(road.get("label", ""))
			if label.is_empty() or label.length() > 256 or _authored_roads.has(label):
				_stop_geometry("missing/duplicate/excessive authored road label")
				return
			_authored_roads[label] = authored
	for key: String in ["road_start", "road_end"]:
		if not _append_road(village.road_plan.get(key)):
			return
	if _body == null or _world == null or _cap == null:
		_stop_geometry("missing real trainer body/capsule/world")
		return
	var constants: Dictionary = _body.get_script().get_script_constant_map()
	_step_height = float(constants.get("STEP_HEIGHT", 0.0))
	_probe = float(constants.get("STEP_FORWARD_PROBE", 0.0))
	if _step_height != 0.35 or _probe != 0.25:
		_stop_geometry("production step contract changed")
		return
	_tick = NativeTick.new()
	_tick.name = "OpeningNativeQueryHarness"
	_tick.navigator = weakref(self)
	_tick.process_thread_group = Node.PROCESS_THREAD_GROUP_INHERIT # Same group as the actual trainer.
	_tick.process_physics_priority = _body.process_physics_priority - 1
	_world.add_child(_tick)
	_progress_at = _player.global_position
	if _production_steering:
		_observer = ProductionObserve.new()
		_observer.name = "OpeningProductionObservationHarness"
		_observer.navigator = weakref(self)
		_observer.process_thread_group = Node.PROCESS_THREAD_GROUP_INHERIT
		_observer.process_physics_priority = _body.process_physics_priority + 1
		_world.add_child(_observer)
		if not _production_contract():
			return
		_recoveries_at_start = int(_body.call("unstick_count"))
		if _recoveries_at_start != 0:
			_stop_geometry("production route started after an actual recovery attempt")


func _config(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_CONFIG_BYTES:
		_stop_geometry("authored configuration byte cap/read refusal")
		return null
	return JSON.parse_string(file.get_as_text())


func _append_road(pair: Variant) -> bool:
	if not pair is Array or pair.size() != 2 or _roads.size() >= MAX_ROAD_INPUTS \
			or not (pair[0] is int or pair[0] is float) or not (pair[1] is int or pair[1] is float):
		_stop_geometry("invalid/excessive authored road coordinates")
		return false
	var point := Vector2(float(pair[0]), float(pair[1]))
	if not point.is_finite():
		_stop_geometry("nonfinite road coordinate")
		return false
	_roads.append(point)
	return true


func refused() -> bool:
	return not _reason.is_empty()


func refusal_reason() -> String:
	return _reason


## Internal stop test: refused, or deferred for the rest of this frame.
func _halted() -> bool:
	return refused() or _deferred


## Total frames deferred on the cooperative deadline (logged per deferral).
func deferral_count() -> int:
	return _deferral.total


func _stop_geometry(reason: String) -> void:
	if _deferred:
		# Downstream of a deadline deferral: release only, never refuse.
		_requested = false
		_owns_input = false
		_drive.call(0.0, 0.0)
		return
	if not refused():
		_reason = reason
	_requested = false
	_owns_input = false
	_drive.call(0.0, 0.0)


func reset() -> void:
	# Sticky refusal, departure and all lifetime allowances survive reset.
	_requested = false
	_owns_input = false
	_route.clear()
	_guided_road.clear()
	_guided_label = ""
	_provisional_path.clear()
	_goal = Vector2.INF
	_arrival = 0.05
	_stalled = 0
	_observed_choice = 0
	_retry_at = STALL_FRAMES
	_avoid_tangent = Vector3.ZERO
	_avoid_retry = 0
	_checked_start = false
	_circle_at = Vector2.INF
	if is_instance_valid(_player):
		_progress_at = _player.global_position
	_drive.call(0.0, 0.0)


## A peaceful wild stops and watches while the trainer is within notice range
## (wild_creature.gd::_tick_peaceful). One standing on an intermediate road
## heading puts that heading inside its body; tangent avoidance then circles it,
## and circling reads as displacement progress, so stall/retry never fires (CI
## gate-b-core: 7 failing attempts in 6 runs, the trainer circling (21,-37.5) or
## (30,-40) beside Wild_bramblebun_0 / Wild_mudsnout_1070 until its budget or the
## lifetime request cap ran out). Release a heading the trainer came within
## CIRCLE_RADIUS of and then failed to close on. Final targets are never released.
func heading_circled(at: Vector2) -> bool:
	if not is_instance_valid(_player):
		return false
	var gap := _xz(_player.global_position).distance_to(at)
	if at != _circle_at:
		_circle_at = at
		_circle_best = gap
		_circle_frames = 0
		return false
	if gap < _circle_best - PROGRESS:
		_circle_best = gap
		_circle_frames = 0
		return false
	_circle_frames += 1
	return _circle_best <= CIRCLE_RADIUS and _circle_frames >= CIRCLE_FRAMES


func set_approach_radius(value: float) -> void:
	if not is_finite(value) or value <= 0.0 or value > 1.65:
		_stop_geometry("invalid original approach radius")
	else:
		_arrival = value


func step(point: Vector3) -> void:
	_request = point
	_raw = false
	_requested = not refused()
	var token := _step_epoch.request()
	_requested_step = token
	var last_frame := Engine.get_physics_frames()
	var waiting_frames := 0
	while _step_epoch.completed < token and not refused():
		await _tree.physics_frame
		if _step_epoch.completed >= token or refused():
			break
		var frame := Engine.get_physics_frames()
		if frame <= last_frame:
			# Do not re-consume a physics-frame emission from a nested await.
			await _tree.process_frame
			continue
		last_frame = frame
		waiting_frames += 1
		if waiting_frames > MAX_DEFERRAL_FRAMES:
			_stop_geometry("requested native walking step did not complete its callback epoch within 30 physics frames")
			break


func _finish_step_epoch() -> void:
	_step_epoch.finish(Engine.get_physics_frames())


func push_once(direction: Vector3) -> void:
	# Preserve deliberate prompt shuffles through the same real stick seam.
	_request = direction
	_raw = true
	_requested = not refused()
	_requested_step = 0


func walk_to(point: Vector3, budget: int, close_enough: float = 0.8, authored_road: String = "", end_road_at_goal: bool = false, provisional_path: Array[Vector2] = []) -> bool:
	reset()
	_arrival = close_enough
	if budget <= 0 or budget > 3600 or not point.is_finite() \
			or not is_finite(close_enough) or close_enough <= 0.0 or close_enough > 1.65:
		_stop_geometry("invalid bounded walk request")
		return false
	if end_road_at_goal and authored_road.is_empty():
		_stop_geometry("road exit requested without an authored road")
		return false
	if not provisional_path.is_empty():
		if not _production_steering or not authored_road.is_empty() or provisional_path.size() > MAX_CHOICES:
			_stop_geometry("invalid bounded provisional path")
			return false
		var previous := _xz(_player.global_position)
		for at: Vector2 in provisional_path:
			if not at.is_finite() or previous.distance_to(at) > MAX_EDGE:
				_stop_geometry("nonfinite/out-of-scope provisional path")
				return false
			previous = at
		_provisional_path.assign(provisional_path)
	if not authored_road.is_empty():
		if not _production_steering or not _authored_roads.has(authored_road) \
				or (_authored_roads[authored_road] as Array).is_empty():
			_stop_geometry("requested authored road is unavailable in production steering")
			return false
		_guided_road.assign(_authored_roads[authored_road])
		if end_road_at_goal:
			_guided_road.assign(_road_prefix_to_goal(_guided_road, _xz(point)))
			if _guided_road.is_empty():
				_stop_geometry("missing/malformed bounded authored road prefix")
				return false
		_guided_label = authored_road
	var walked := 0
	var held := 0
	while walked < budget and not refused():
		if not can_walk():
			held += 1
			_drive.call(0.0, 0.0)
			_requested = false
			if held > 36000:
				return false
			await _tree.physics_frame
			continue
		if _checked_start and not departure_pending(point) and not refused() \
				and _xz(_player.global_position).distance_to(_xz(point)) <= close_enough:
			_requested = false
			_drive.call(0.0, 0.0)
			return true
		walked += 1
		await step(point)
	_requested = false
	_drive.call(0.0, 0.0)
	return false


func authored_road_points(label: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if _production_steering and _authored_roads.has(label):
		points.assign(_authored_roads[label])
	return points


## Authored approach coordinates are headings only, never a clearance proof.
## Read by stable id: several existing house walks intentionally have no label.
func authored_approach_points(id: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if not _production_steering or id.is_empty():
		return points
	var terrain: Variant = _config("res://data/config/terrain_playground.json")
	if not terrain is Dictionary or not terrain.get("paths") is Dictionary \
			or not terrain.paths.get("approaches") is Array \
			or terrain.paths.approaches.size() > MAX_ROAD_INPUTS:
		_stop_geometry("missing/excessive authored approach data")
		return points
	var found := false
	for entry: Variant in terrain.paths.approaches:
		if not entry is Dictionary or str(entry.get("id", "")) != id:
			continue
		if found or not entry.get("points") is Array \
				or entry.points.size() < 2 or entry.points.size() > MAX_ROAD_INPUTS:
			_stop_geometry("duplicate/malformed authored approach")
			return []
		found = true
		for pair: Variant in entry.points:
			if not pair is Array or pair.size() != 2 \
					or not (pair[0] is int or pair[0] is float) \
					or not (pair[1] is int or pair[1] is float):
				_stop_geometry("malformed authored approach coordinate")
				return []
			var at := Vector2(float(pair[0]), float(pair[1]))
			if not at.is_finite() or (not points.is_empty() \
					and (points.back().distance_to(at) <= CONTACT_EPS \
					or points.back().distance_to(at) > MAX_EDGE)):
				_stop_geometry("invalid authored approach edge")
				return []
			points.append(at)
	if not found:
		_stop_geometry("requested authored approach is unavailable")
	return points


func uses_production_steering() -> bool:
	return _production_steering


## A slice of the existing polyline, in either direction. Projections supply
## headings only; neither the road nor its unwalked join is certified clear.
static func road_slice(road: Array[Vector2], from: Vector2, to: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if road.size() < 2 or road.size() > MAX_ROAD_INPUTS or not from.is_finite() or not to.is_finite():
		return result
	var lengths: Array[float] = [0.0]
	var start := Vector2.INF
	var finish := Vector2.INF
	var start_distance := INF
	var finish_distance := INF
	var start_arc := 0.0
	var finish_arc := 0.0
	for index in road.size() - 1:
		var a := road[index]
		var b := road[index + 1]
		var length := a.distance_to(b)
		if not a.is_finite() or not b.is_finite() or length <= CONTACT_EPS or length > MAX_EDGE:
			return []
		var first := Geometry2D.get_closest_point_to_segment(from, a, b)
		var last := Geometry2D.get_closest_point_to_segment(to, a, b)
		if from.distance_squared_to(first) < start_distance:
			start_distance = from.distance_squared_to(first)
			start = first
			start_arc = lengths[index] + a.distance_to(first)
		if to.distance_squared_to(last) < finish_distance:
			finish_distance = to.distance_squared_to(last)
			finish = last
			finish_arc = lengths[index] + a.distance_to(last)
		lengths.append(lengths[index] + length)
	if from.distance_to(start) > MAX_EDGE or to.distance_to(finish) > MAX_EDGE:
		return []
	result.append(start)
	var forward := finish_arc >= start_arc
	for offset in road.size():
		var index := offset if forward else road.size() - 1 - offset
		if lengths[index] > minf(start_arc, finish_arc) + CONTACT_EPS \
				and lengths[index] < maxf(start_arc, finish_arc) - CONTACT_EPS:
			result.append(road[index])
	if result.back().distance_to(finish) > CONTACT_EPS:
		result.append(finish)
	return result


## A local errand may leave a long authored road at the node nearest its goal.
## Only an explicit production-road request uses this prefix. Default full-road
## and predictive walks remain unchanged; no invented waypoint or geometry proof.
static func _road_prefix_to_goal(road: Array[Vector2], goal: Vector2) -> Array[Vector2]:
	if road.is_empty() or road.size() > MAX_ROAD_INPUTS or not goal.is_finite():
		return []
	for index in road.size():
		if not road[index].is_finite() or (index > 0 and road[index - 1].distance_to(road[index]) > MAX_EDGE):
			return []
	var exit := 0
	for index in road.size():
		if goal.distance_squared_to(road[index]) < goal.distance_squared_to(road[exit]):
			exit = index
	if goal.distance_to(road[exit]) > MAX_EDGE:
		return []
	var prefix: Array[Vector2] = []
	for index in range(exit + 1):
		prefix.append(road[index])
	return prefix


func _spend() -> bool:
	if refused() or _deferred:
		return false
	_queries += 1
	_total_queries += 1
	if _queries > MAX_QUERIES_FRAME or _total_queries > MAX_QUERIES_LIFETIME:
		_stop_geometry("native query per-frame/lifetime count cap")
		return false
	if Time.get_ticks_usec() > _deadline:
		_defer_deadline("native query budget")
		return false
	return true


## A cooperative wall-clock deadline was exceeded: release the stick and retry
## next frame, up to MAX_DEFERRAL_FRAMES consecutive frames, then refuse.
func _defer_deadline(where: String) -> void:
	if refused() or _deferred:
		return
	if not _deferral.defer(where):
		_stop_geometry("cooperative deadline exceeded on %d consecutive frames (%s; %d deferred frames total)" % [
			_deferral.consecutive, where, _deferral.total])
		return
	_deferred = true
	_requested = false
	_owns_input = false
	_production_driven = false
	_checked_start = false
	if _production_steering and OS.get_thread_caller_id() == OS.get_main_thread_id():
		_production_stop_input()
	else:
		_drive.call(0.0, 0.0)


func _motion(pose: Transform3D, motion: Vector3, recover: bool = false) -> Dictionary:
	if _contact_enabled:
		_contact_query_kind = &"zero_recovery" if recover and motion == Vector3.ZERO else &"body_test_motion"
		_contact_query_pose = pose
		_contact_rejected_pose = pose
		_contact_leg = motion
		_contact_native_pose = pose
		_contact_native_leg = motion
		_contact_recovery = recover
		_contact_blocked = false
		_contact_hit = null
		_contact_overlaps = null
	if not pose.origin.is_finite() or not motion.is_finite() or motion.length() > MAX_EDGE \
			or not _registered_body_contract() or not _spend():
		return {"blocked": true, "hit": null}
	var parameters := PhysicsTestMotionParameters3D.new()
	parameters.from = pose
	parameters.motion = motion
	parameters.margin = _body.safe_margin
	parameters.recovery_as_collision = recover
	parameters.max_collisions = CONTACTS
	# Default empty extra exclusions; same registered body/mask as test_move.
	# No fresh KinematicCollision3D owner lookup, shape clone or body replacement.
	var hit := PhysicsTestMotionResult3D.new()
	var blocked := PhysicsServer3D.body_test_motion(_body_rid, parameters, hit)
	if _contact_enabled:
		_contact_hit = hit
		_contact_blocked = blocked
	# Check AFTER each native call too; one call can exceed the cooperative cap.
	# Same three refusals as before, reported separately so a failing run says
	# which one fired (F02#3 r3 could not tell a slow host from a crowd).
	if not _registered_body_contract():
		_stop_geometry("native query body identity changed")
		return {"blocked": true, "hit": null}
	if hit.get_collision_count() >= CONTACTS:
		_stop_geometry("native query contact saturation (%d contacts)" % hit.get_collision_count())
		return {"blocked": true, "hit": null}
	if Time.get_ticks_usec() > _deadline:
		_defer_deadline("native query cooperative frame deadline")
		return {"blocked": true, "hit": null}
	var safe := hit.get_collision_safe_fraction()
	var unsafe := hit.get_collision_unsafe_fraction()
	if not is_finite(safe) or not is_finite(unsafe) or safe < 0.0 or unsafe > 1.0 \
			or safe > unsafe or not hit.get_travel().is_finite():
		_stop_geometry("invalid native motion fractions/travel")
		return {"blocked": true, "hit": null}
	return {"blocked": blocked, "hit": hit}

func _trainer_contract() -> bool:
	if not is_instance_valid(_body) or not is_instance_valid(_cap) or not _cap.shape is CapsuleShape3D \
			or _cap.get_parent() != _body or _cap.disabled or _body.get_shape_owners().size() != 1:
		_stop_geometry("changed/missing real capsule ownership")
		return false
	_owner = int(_body.get_shape_owners()[0])
	_body_rid = _body.get_rid()
	if _body.shape_owner_get_owner(_owner) != _cap or _body.shape_owner_get_shape_count(_owner) != 1 \
			or _body.shape_owner_get_shape(_owner, 0) != _cap.shape \
			or _body.shape_owner_get_transform(_owner) != _cap.transform \
			or _body.is_shape_owner_disabled(_owner) != _cap.disabled \
			or not (_body.global_transform.basis * _cap.transform.basis).is_equal_approx((_body.global_transform.basis * _cap.transform.basis).orthonormalized()) \
			or not (_body.global_transform.basis * _cap.transform.basis).y.is_equal_approx(Vector3.UP) \
			or not _cap.transform.origin.is_finite() or not is_equal_approx(_cap.shape.radius, 0.4) or not is_equal_approx(_cap.shape.height, 1.8) \
			or _cap.transform.origin != Vector3(0.0, 0.9, 0.0) \
			or _body.collision_mask == 0 or _body.up_direction != Vector3.UP or not is_finite(_body.safe_margin) or _body.safe_margin <= 0.0 \
			or not is_finite(_body.floor_max_angle) or _body.floor_max_angle <= 0.0 or _body.floor_max_angle >= PI / 2.0 \
			or not is_finite(_body.floor_snap_length) or _body.floor_snap_length <= 0.0:
		_stop_geometry("changed capsule transform/owner/floor/skin contract")
		return false
	_capsule_index = _body.shape_owner_get_shape_index(_owner, 0)
	return _registered_body_contract()


func _registered_body_contract() -> bool:
	# Bounded trainer-only registration checks, before/after each native query.
	if not is_instance_valid(_body) or not is_instance_valid(_cap) \
			or not _body.is_inside_tree() or not _body_rid.is_valid() \
			or _body.get_rid() != _body_rid or _body.get_world_3d() == null \
			or not _body.get_world_3d().space.is_valid() or not _cap.shape is CapsuleShape3D \
			or _body.get_shape_owners().size() != 1 or int(_body.get_shape_owners()[0]) != _owner:
		_stop_geometry("missing/replaced actual registered trainer")
		return false
	if _cap.get_parent() != _body or _cap.disabled or _body.is_shape_owner_disabled(_owner) \
			or _body.shape_owner_get_owner(_owner) != _cap \
			or _body.shape_owner_get_shape_count(_owner) != 1 \
			or _body.shape_owner_get_shape(_owner, 0) != _cap.shape \
			or _body.shape_owner_get_transform(_owner) != _cap.transform \
			or _capsule_index < 0 or _body.shape_owner_get_shape_index(_owner, 0) != _capsule_index \
			or PhysicsServer3D.body_get_shape_count(_body_rid) != 1 or _capsule_index != 0 \
			or _body.shape_find_owner(_capsule_index) != _owner \
			or PhysicsServer3D.body_get_object_instance_id(_body_rid) != _body.get_instance_id() \
			or PhysicsServer3D.body_get_space(_body_rid) != _body.get_world_3d().space \
			or PhysicsServer3D.body_get_collision_mask(_body_rid) != _body.collision_mask \
			or PhysicsServer3D.body_get_shape(_body_rid, _capsule_index) != _cap.shape.get_rid() \
			or PhysicsServer3D.body_get_shape_transform(_body_rid, _capsule_index) != _cap.transform:
		_stop_geometry("actual trainer RID/mask/capsule owner registration diverged")
		return false
	return true


func _foot(pose: Transform3D) -> float:
	return (pose * _body.shape_owner_get_transform(_owner)).origin.y - _cap.shape.height * 0.5


func _paired_floor_skin(hit: PhysicsTestMotionResult3D, index: int, pose: Transform3D) -> bool:
	# Actual stationary grounded recovery only, after exact unshrunk overlap refusal.
	# Do not reorient native normals or admit predicted/staged landing contacts.
	if _contact_staged or pose != _body.global_transform or not _body.is_on_floor() \
			or hit.get_travel() != Vector3.ZERO or hit.get_collision_safe_fraction() != 1.0 \
			or hit.get_collision_unsafe_fraction() != 1.0:
		return false
	var normal: Vector3 = hit.get_collision_normal(index)
	var point: Vector3 = hit.get_collision_point(index)
	var floor_cos: float = cos(_body.floor_max_angle)
	var skin: float = _body.safe_margin
	var capsule: CapsuleShape3D = _cap.shape as CapsuleShape3D
	var radius: float = capsule.radius
	var center: Vector3 = (pose * _body.shape_owner_get_transform(_owner)).origin \
			- Vector3.UP * (capsule.height * 0.5 - radius)
	var shell: float = radius + skin
	# The opposed normal must point out of the bottom cap, within the same skin.
	# Its counterpart must point into that cap. A wall/ceiling normal cannot substitute.
	if normal.dot(Vector3.UP) > -floor_cos or not hit.get_collider_rid(index).is_valid() \
			or hit.get_collider_shape(index) < 0 \
			or (center - point + normal * shell).length() > skin + CONTACT_EPS:
		return false
	var foot: float = _foot(pose)
	var ceiling: float = foot + radius * (1.0 - floor_cos) + skin
	# Diameter squared of a skin-thick spherical cap; no new distance allowance.
	var patch_diameter_squared: float = 4.0 * (shell * shell - radius * radius)
	for other in hit.get_collision_count(): # At most seven contacts; no new native query.
		if other == index or hit.get_collider_rid(other) != hit.get_collider_rid(index) \
				or hit.get_collider_id(other) != hit.get_collider_id(index) \
				or hit.get_collider_shape(other) != hit.get_collider_shape(index) \
				or hit.get_collision_local_shape(other) != _capsule_index:
			continue
		var support: Vector3 = hit.get_collision_normal(other)
		var support_point: Vector3 = hit.get_collision_point(other)
		var depth: float = hit.get_collision_depth(other)
		if not support.is_finite() or not support_point.is_finite() or not is_finite(depth) \
				or depth < -CONTACT_EPS or depth > skin + CONTACT_EPS \
				or absf(support.length_squared() - 1.0) > 0.001 \
				or support.dot(Vector3.UP) < floor_cos \
				or support_point.y < foot - skin - CONTACT_EPS \
				or support_point.y > ceiling + CONTACT_EPS:
			continue
		var separation: Vector3 = point - support_point
		if (center - support_point - support * shell).length() <= skin + CONTACT_EPS \
				and separation.length_squared() <= patch_diameter_squared \
				and absf(support.dot(separation)) <= CONTACT_EPS:
			return true # Paired live floor skin only; actual controller still owns travel.
	return false


func _floor_contacts(hit: PhysicsTestMotionResult3D, pose: Transform3D, shallow: bool) -> bool:
	if _contact_enabled:
		_contact_hit = hit
		_contact_rejected_pose = pose
		_contact_shallow = shallow
		_contact_index = -1
	if hit == null or hit.get_collision_count() == 0 or hit.get_collision_count() >= CONTACTS \
			or not _registered_body_contract():
		_contact_mark(&"floor_missing_saturated_or_registration")
		return false
	var ceiling: float = _foot(pose) + _cap.shape.radius * (1.0 - cos(_body.floor_max_angle)) + _body.safe_margin
	for index in hit.get_collision_count():
		var normal := hit.get_collision_normal(index)
		var contact := hit.get_collision_point(index)
		var depth := hit.get_collision_depth(index)
		if not normal.is_finite() or not contact.is_finite() or not is_finite(depth) \
				or depth < -CONTACT_EPS or (shallow and depth > _body.safe_margin + CONTACT_EPS) \
				or hit.get_collision_local_shape(index) != _capsule_index \
				or absf(normal.length_squared() - 1.0) > 0.001 \
				or (normal.dot(Vector3.UP) < cos(_body.floor_max_angle)
					and (not shallow or not _paired_floor_skin(hit, index, pose))) \
				or contact.y < _foot(pose) - _body.safe_margin - CONTACT_EPS \
				or contact.y > ceiling + CONTACT_EPS:
			if _contact_enabled:
				_contact_index = index
			_contact_mark(&"floor_contact_guard")
			return false
	return true


func _start_clear_impl(pose: Transform3D) -> bool:
	# Explicit actual overlap query. No raised origin, shape shrink or floor RID exclusion.
	if _contact_enabled:
		_contact_query_kind = &"intersect_shape"
		_contact_query_pose = pose
		_contact_rejected_pose = pose
		_contact_leg = Vector3.ZERO
		_contact_overlaps = null
	if not _registered_body_contract() or not _spend():
		_contact_mark(&"overlap_contract_or_budget")
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _body.shape_owner_get_shape(_owner, 0)
	query.transform = pose * _body.shape_owner_get_transform(_owner)
	query.collision_mask = _body.collision_mask
	query.margin = 0.0
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [_body_rid] # Self only. Never exclude a support/blocking body.
	var overlaps := _body.get_world_3d().direct_space_state.intersect_shape(query, CONTACTS)
	if _contact_enabled:
		_contact_overlaps = overlaps
	if not _registered_body_contract() or overlaps.size() >= CONTACTS:
		_stop_geometry("starting overlap saturation/registration")
		_contact_mark(&"overlap_saturation_registration_or_deadline")
		return false
	if Time.get_ticks_usec() > _deadline:
		_defer_deadline("starting overlap query deadline")
		_contact_mark(&"overlap_saturation_registration_or_deadline")
		return false
	# Identity of an overlapping floor shape does not prove there is no wall
	# contact in that same concave shape. Refuse ALL exact-shape intersections,
	# including a legitimate floor touch that this backend reports as overlap.
	# Only recovery SKIN contact outside the unshrunk capsule may be floor-classified.
	if not overlaps.is_empty():
		_contact_mark(&"exact_overlap")
		return false
	var recovery := _motion(pose, Vector3.ZERO, true)
	if _halted() or recovery.hit == null:
		_contact_mark(&"zero_recovery_missing_or_refused")
		return false
	var hit: PhysicsTestMotionResult3D = recovery.hit
	# Zero-motion recovery must itself be shallow at this supplied pose.
	# Do not silently admit a large recovery displacement after an overlap miss.
	if hit.get_travel().length() > _body.safe_margin + CONTACT_EPS:
		_contact_mark(&"zero_recovery_travel")
		return false
	if not recovery.blocked and overlaps.is_empty() and hit.get_collision_count() == 0:
		return true
	if not _floor_contacts(hit, pose, true):
		return false # Deep, side, elevated, missing or ambiguous contacts refuse.
	return true # Provisional floor/skin classification, NOT a collision theorem.


func _supported_step_from(pose: Transform3D, direction: Vector3) -> bool:
	var forward := direction.normalized() * _probe
	if _contact_enabled:
		_contact_probe_pose = pose
		_contact_forward = forward
	_contact_stage_at(&"forward")
	var sweep := _motion(pose, forward)
	if _halted():
		_contact_mark(&"forward_motion_refused")
		return false
	var landing := pose.translated(forward)
	var drop := _body.floor_snap_length
	if sweep.blocked:
		# Read-only counterpart of production's bounded step probes. Never apply poses.
		_contact_stage_at(&"step_up")
		if _motion(pose, Vector3.UP * _step_height).blocked or _halted():
			_contact_mark(&"step_up_blocked_or_refused")
			return false
		var raised := pose.translated(Vector3.UP * _step_height)
		_contact_stage_at(&"raised_start_clear")
		if not _start_clear(raised):
			return false
		_contact_stage_at(&"raised_forward")
		if _motion(raised, forward).blocked or _halted():
			_contact_mark(&"raised_forward_blocked_or_refused")
			return false
		landing = raised.translated(forward)
		drop = _step_height # Production _try_step_up drops only STEP_HEIGHT.
	_contact_stage_at(&"landing_start_clear")
	if not _start_clear(landing):
		return false
	_contact_stage_at(&"support_down")
	var support := _motion(landing, Vector3.DOWN * drop, true)
	if not support.blocked or support.hit == null or _halted():
		_contact_mark(&"support_missing_or_refused")
		return false
	var travel: Vector3 = support.hit.get_travel()
	if not travel.is_finite() or absf(travel.x) > _body.safe_margin + CONTACT_EPS \
			or absf(travel.z) > _body.safe_margin + CONTACT_EPS or travel.y > _body.safe_margin + CONTACT_EPS \
			or -travel.y > drop + _body.safe_margin + CONTACT_EPS:
		_contact_mark(&"support_travel_guard")
		return false
	landing = landing.translated(travel)
	var rise := _foot(landing) - _foot(pose)
	# Sweep depths belong to UNSAFE advance; travel gives the SAFE landing.
	# Keep swept support identity/normal/foot-band guards, then independently
	# apply the unchanged shallow depth bound via ZERO motion at that safe pose.
	# _start_clear also retains exact unshrunk overlap refusal at the safe pose.
	_contact_stage_at(&"rise_bounds")
	if not (rise <= _step_height + _body.safe_margin + CONTACT_EPS \
		and rise >= -_body.floor_snap_length - _body.safe_margin - CONTACT_EPS):
		_contact_mark(&"rise_bounds")
		return false
	_contact_stage_at(&"support_floor_contacts")
	if not _floor_contacts(support.hit, landing, false):
		return false
	_contact_stage_at(&"safe_landing_start_clear")
	if not _start_clear(landing):
		return false
	return not _halted()


func _choose(point: Vector2, tolerance: float) -> bool:
	_plans += 1
	if _plans > MAX_PLANS or _xz(_player.global_position).distance_to(point) > MAX_EDGE:
		_stop_geometry("bounded route scope/plan lifetime cap")
		return false
	_route.clear()
	var from := _xz(_player.global_position)
	var candidates: Array[Vector2] = []
	for road: Vector2 in _roads:
		if road.distance_to(from) > 0.5 and road.distance_to(from) <= MAX_EDGE \
				and road.distance_to(point) <= MAX_EDGE:
			candidates.append(road)
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return from.distance_to(a) + a.distance_to(point) < from.distance_to(b) + b.distance_to(point))
	# First direct, then at most eight existing road nodes. No all-pairs graph.
	for index in range(-1, mini(MAX_CHOICES, candidates.size())):
		var candidate := point if index < 0 else candidates[index]
		var displacement := candidate - from
		var direction := Vector3(displacement.x, 0.0, displacement.y).normalized()
		# An entire fixed-height sweep hits ordinary rising terrain. Choose only
		# a provisional heading from the current production-length step; repeat
		# its unchanged capsule/floor/clearance guards before every stick input.
		# This is never a certificate for the unwalked remainder of a road leg.
		if _supported_step(direction):
			_route.append(candidate)
			if index >= 0:
				_route.append(point)
			return true
		if _halted():
			return false
	_stop_geometry("no admitted direct/existing-road leg; uneven floor or multiple bends may be incomplete")
	return false


func _native_tick_impl(_delta: float) -> void:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		# Never access a physics space from a changed sub-thread group.
		_reason = "native harness no longer runs on the main physics thread"
		_requested = false
		_drive.call_deferred(0.0, 0.0)
		return
	if not _requested:
		if _owns_input:
			_drive.call(0.0, 0.0)
			_owns_input = false
		return
	_requested = false
	if not _step_epoch.begin(_requested_step, Engine.get_physics_frames()):
		_stop_geometry("native walking request/callback epoch diverged")
		return
	_requested_step = 0
	_checked_start = false
	_requests += 1
	_queries = 0
	_deadline = Time.get_ticks_usec() + FRAME_QUERY_US
	if _halted() or _requests > MAX_REQUESTS or not _request.is_finite():
		_stop_geometry("native request/lifetime/finite-input cap")
		return
	if not can_walk():
		if _production_steering:
			_checked_start = false
		_drive.call(0.0, 0.0)
		return
	if not _trainer_contract() or not (_production_live_check(false) if _production_steering else _start_clear(_body.global_transform)):
		_stop_geometry("actual starting overlap cannot be classified as shallow support floor")
		return
	if not _body.is_on_floor():
		_stop_geometry("trainer not grounded; aerial/stream/recovery case is incomplete")
		return
	_checked_start = not _production_steering
	if _production_steering:
		if not _production_contract():
			return
		_production_pending = true
		_production_before = _body.global_position
		_production_driven = false
	var direction := _request
	if not _raw:
		if not _prepare_departure(_request):
			return
		if not _departure.is_empty() and _xz(_player.global_position).distance_to(_departure[0]) <= THRESHOLD_RADIUS:
			if _departure.size() == 2 and absf(_foot(_body.global_transform) - _departure_floor) > _step_height:
				_stop_geometry("actual door floor not reached")
				return
			_departure.pop_front()
			_route.clear()
			if _departure.is_empty():
				_completed_house = _departure_house
		var point := _departure[0] if not _departure.is_empty() else _xz(_request)
		var tolerance := THRESHOLD_RADIUS if not _departure.is_empty() else _arrival
		if _departure.is_empty() and _xz(_player.global_position).distance_to(point) <= tolerance:
			_drive.call(0.0, 0.0)
			_owns_input = false
			return
		if _goal == Vector2.INF or _goal.distance_to(point) > 0.5:
			_goal = point
			_route.clear()
			if _production_steering:
				_observed_choice = 0
				_retry_at = STALL_FRAMES
		elif not _route.is_empty():
			_route[_route.size() - 1] = point # Live target, still checked locally.
		if not _route.is_empty() and _xz(_player.global_position).distance_to(_route[0]) <= THRESHOLD_RADIUS:
			_route.pop_front()
		elif _production_steering and _departure.is_empty() and _route.size() > 1 and heading_circled(_route[0]):
			_route.pop_front() # Intermediate road heading only; the live target stays last.
		if _production_steering and _departure.is_empty() and _stalled >= _retry_at:
			_observed_choice += 1
			_retry_at += STALL_FRAMES # Does not reset the unchanged 90-frame stall cap.
			_route.clear()
		if _route.is_empty() and not _choose_route(point, tolerance):
			return
		var at := _route[0]
		direction = Vector3(at.x - _player.global_position.x, 0.0, at.y - _player.global_position.z)
	if direction.length_squared() <= 0.000001:
		_drive.call(0.0, 0.0)
		return
	if not _production_steering and not _supported_step(direction):
		# Recheck live geometry every input; additions, raw shapes and owner edits
		# are observed natively. A blocked local leg gets one new bounded choice.
		_route.clear()
		if _raw or not _choose(_goal, THRESHOLD_RADIUS if not _departure.is_empty() else _arrival) or not _supported_step(Vector3(_route[0].x - _player.global_position.x, 0.0, _route[0].y - _player.global_position.z)):
			_stop_geometry("native local floor/clearance incomplete; no blind fallback")
			return
		direction = Vector3(_route[0].x - _player.global_position.x, 0.0, _route[0].y - _player.global_position.z)
	if not _production_steering:
		_stalled += 1
		if _player.global_position.distance_to(_progress_at) >= 0.08:
			_progress_at = _player.global_position
			_stalled = 0
		if _stalled > 90:
			_stop_geometry("real stick travel made no progress within 90 requested frames")
			return
	if _production_steering:
		var steering_began: int = Time.get_ticks_usec()
		direction = _production_heading(direction)
		_production_steering_us = Time.get_ticks_usec() - steering_began
		if _halted():
			return
	if refused() or _deferred:
		return
	if Time.get_ticks_usec() > _deadline:
		_defer_deadline("native callback deadline before stick input")
		return
	_owns_input = true
	if _production_steering:
		_production_driven = true
	_push(direction.normalized() * clampf(direction.length() / EASE_METRES, EASE_FLOOR, 1.0))
	if _production_steering:
		# parse_input_event queues the real joypad events under Godot's default
		# accumulated/agile input. Deliver them before this frame's controller.
		# Dispatch cost is included in the unchanged pre/post callback allowance.
		var flush_began: int = Time.get_ticks_usec()
		Input.flush_buffered_events()
		_production_flush_us = Time.get_ticks_usec() - flush_began
		_production_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Time.get_ticks_usec() > _deadline:
			_defer_deadline("production input dispatch deadline")


func departure_pending(target: Vector3) -> bool:
	# Metadata only here; no direct-space query from SceneTree.physics_frame.
	return not _prepare_departure(target) or not _departure.is_empty() or refused()


func _leaf(house: Node3D) -> CollisionShape3D:
	if house == _world.get_node_or_null(^"GrandpaHouse"):
		return house.get("_door_gate_shape") as CollisionShape3D
	var door := house.get_node_or_null(^"Door")
	return door.get("_gate_shape") as CollisionShape3D if door != null else null


func _open_leaf(leaf: CollisionShape3D) -> bool:
	if not is_instance_valid(leaf) or not leaf.disabled or leaf.shape == null or not leaf.get_parent() is CollisionObject3D:
		return false
	var body := leaf.get_parent() as CollisionObject3D
	var owners := body.get_shape_owners()
	if owners.size() > 4:
		return false
	for owner: int in owners:
		if body.shape_owner_get_owner(owner) == leaf:
			return body.shape_owner_get_shape_count(owner) == 1 and body.shape_owner_get_shape(owner, 0) == leaf.shape \
				and body.shape_owner_get_transform(owner) == leaf.transform \
				and body.is_shape_owner_disabled(owner) == leaf.disabled
	return false


func _prepare_departure(target: Vector3) -> bool:
	if refused():
		return false
	if not is_instance_valid(_world) or not target.is_finite():
		_stop_geometry("missing mounted world/nonfinite departure target")
		return false
	if not _departure.is_empty():
		if not is_instance_valid(_departure_house) or _leaf(_departure_house) != _departure_leaf \
				or not _open_leaf(_departure_leaf) or _departure_leaf.global_transform != _leaf_pose \
				or _departure_leaf.shape != _leaf_shape or _leaf_shape.size != _leaf_size \
				or _departure_house.global_transform != _house_pose:
			_stop_geometry("mandatory mounted doorway replaced/moved/closed/owner-diverged")
			return false
		return true
	var houses := _tree.get_nodes_in_group("village_road_houses")
	var grandpa := _world.get_node_or_null(^"GrandpaHouse") as Node3D
	if houses.size() > MAX_HOUSES:
		_stop_geometry("authored containing-house cap")
		return false
	if grandpa != null:
		houses.append(grandpa)
	for candidate: Node in houses:
		if not candidate is Node3D or not _world.is_ancestor_of(candidate):
			continue
		var house := candidate as Node3D
		var width := 0.0
		var depth := 0.0
		var height := 3.0
		if house == grandpa:
			var constants: Dictionary = house.get_script().get_script_constant_map()
			width = float(constants.get("INNER_W", 0.0)) * 0.5
			depth = float(constants.get("INNER_D", 0.0)) * 0.5
			height = float(constants.get("FLOOR_H", 0.0)) + float(constants.get("LOFT_H", 0.0))
		else:
			var label := str(house.name)
			var recipe: Dictionary = _recipes.get(label.substr(0, label.rfind("_")), {})
			var room: Dictionary = recipe.get("room", {})
			if room.is_empty() or house.get_node_or_null(^"Interior") == null:
				continue
			width = float(room.get("inner_half_w", 0.0))
			depth = float(room.get("inner_half_d", 0.0))
		if not is_finite(width) or not is_finite(depth) or width <= 0.0 or depth <= 0.0:
			_stop_geometry("invalid actual room metadata")
			return false
		# Authored room identity only, never collider bounds or clearance admission.
		var local_at := house.to_local(_player.global_position)
		var local_target := house.to_local(target)
		var within := absf(local_at.x) <= width + 0.4 and absf(local_at.z) <= depth + 0.4 \
			and local_at.y >= -0.4 and local_at.y <= height
		var target_within := absf(local_target.x) <= width + 0.4 and absf(local_target.z) <= depth + 0.4
		if not within:
			if _completed_house == house:
				_completed_house = null
			continue
		if target_within or _completed_house == house:
			continue
		if not house.global_transform.basis.is_equal_approx(house.global_transform.basis.orthonormalized()):
			_stop_geometry("scaled/sheared containing-house metadata incomplete")
			return false
		var door := house.get_node_or_null(^"Door") as Node3D
		if house != grandpa and (door == null or door.get_script() == null \
				or door.get_script().resource_path != "res://scripts/world/village_door.gd" or not bool(door.call("is_open"))):
			_stop_geometry("actual containing village doorway is not open")
			return false
		var leaf := _leaf(house)
		if not _open_leaf(leaf) or not leaf.shape is BoxShape3D:
			_stop_geometry("containing house has no actual open, owner-verified leaf")
			return false
		var leaf_pose := leaf.global_transform
		if not leaf_pose.basis.is_equal_approx(leaf_pose.basis.orthonormalized()) \
				or absf(leaf_pose.basis.y.dot(Vector3.UP) - 1.0) > CONTACT_EPS:
			_stop_geometry("tilted/scaled mounted door floor incomplete")
			return false
		var normal := _xz(house.global_transform.basis.x) if house == grandpa else _xz(door.global_transform.basis.z)
		var threshold := _xz(leaf_pose.origin)
		if normal.dot(threshold - _xz(house.global_position)) < 0.0:
			normal = -normal
		normal = normal.normalized()
		var front := threshold + normal * 2.4
		if house == grandpa:
			front = _xz(house.call("marker", "door"))
		_departure = [threshold, front]
		_departure_floor = leaf_pose.origin.y - (leaf.shape as BoxShape3D).size.y * 0.5
		_departure_house = house
		_departure_leaf = leaf
		_leaf_pose = leaf_pose
		_leaf_shape = leaf.shape as BoxShape3D
		_leaf_size = _leaf_shape.size
		_house_pose = house.global_transform
		_route.clear()
		return true
	return true


func _xz(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


# Temporary opt-in diagnosis. Pool construction is outside physics callbacks.
# Existing result objects are retained; output is built only after refusal.
const CONTACT_DIAGNOSTIC_LIMIT := 8

class ContactDiagnostic extends RefCounted:
	var probe_pose: Transform3D
	var forward: Vector3
	var stage: StringName
	var reason: StringName
	var query_kind: StringName
	var query_pose: Transform3D
	var leg: Vector3
	var native_pose: Transform3D
	var native_leg: Vector3
	var recovery: bool
	var blocked: bool
	var hit: PhysicsTestMotionResult3D
	var overlaps: Variant
	var rejected_pose: Transform3D
	var contact_index: int
	var shallow: bool

var _contact_enabled := false
var _contact_pool: Array[ContactDiagnostic] = []
var _contact_count := 0
var _contact_emitted := false
var _contact_active := false
var _contact_staged := false
var _contact_probe_pose := Transform3D.IDENTITY
var _contact_forward := Vector3.ZERO
var _contact_stage: StringName = &"actual_start"
var _contact_reason: StringName = &""
var _contact_query_kind: StringName = &""
var _contact_query_pose := Transform3D.IDENTITY
var _contact_leg := Vector3.ZERO
var _contact_native_pose := Transform3D.IDENTITY
var _contact_native_leg := Vector3.ZERO
var _contact_recovery := false
var _contact_blocked := false
var _contact_hit: PhysicsTestMotionResult3D
var _contact_overlaps: Variant = null
var _contact_rejected_pose := Transform3D.IDENTITY
var _contact_index := -1
var _contact_shallow := false


func _contact_init() -> void:
	_contact_enabled = OS.get_cmdline_user_args().has("--opening-contact-diagnostics")
	if _contact_enabled:
		for index in CONTACT_DIAGNOSTIC_LIMIT:
			_contact_pool.append(ContactDiagnostic.new())


func _contact_mark(reason: StringName) -> void:
	if _contact_enabled and _contact_reason == &"":
		_contact_reason = reason


func _contact_stage_at(stage: StringName) -> void:
	if _contact_enabled:
		_contact_stage = stage


func _contact_capture() -> void:
	if not _contact_enabled or _contact_count >= CONTACT_DIAGNOSTIC_LIMIT:
		return
	var record: ContactDiagnostic = _contact_pool[_contact_count]
	_contact_count += 1
	record.probe_pose = _contact_probe_pose
	record.forward = _contact_forward
	record.stage = _contact_stage
	record.reason = _contact_reason
	record.query_kind = _contact_query_kind
	record.query_pose = _contact_query_pose
	record.leg = _contact_leg
	record.native_pose = _contact_native_pose
	record.native_leg = _contact_native_leg
	record.recovery = _contact_recovery
	record.blocked = _contact_blocked
	record.hit = _contact_hit
	record.overlaps = _contact_overlaps
	record.rejected_pose = _contact_rejected_pose
	record.contact_index = _contact_index
	record.shallow = _contact_shallow


func _contact_vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _contact_pose(value: Transform3D) -> Dictionary:
	return {"origin": _contact_vector(value.origin), "basis_x": _contact_vector(value.basis.x),
		"basis_y": _contact_vector(value.basis.y), "basis_z": _contact_vector(value.basis.z)}


func _contact_dump() -> void:
	if not _contact_enabled or _contact_emitted or _contact_count == 0:
		return
	_contact_emitted = true # At most eight records per navigator lifetime.
	# No geometry query, ray, terrain height lookup or new native motion here.
	for record_index in _contact_count:
		var record: ContactDiagnostic = _contact_pool[record_index]
		var report: Dictionary = {"record": record_index, "staged": _contact_staged,
			"stage": String(record.stage), "query_kind": String(record.query_kind),
			"reason": String(record.reason), "sticky_refusal": _reason,
			"probe_pose": _contact_pose(record.probe_pose), "forward": _contact_vector(record.forward),
			"query_pose": _contact_pose(record.query_pose), "leg": _contact_vector(record.leg),
			"recovery_as_collision": record.recovery, "blocked": record.blocked,
			"rejected_pose": _contact_pose(record.rejected_pose), "failed_contact_index": record.contact_index,
			"shallow_required": record.shallow, "request": _contact_vector(_request),
			"goal": [ _goal.x, _goal.y ], "raw": _raw, "arrival": _arrival,
			"queries": _queries, "total_queries": _total_queries, "requests": _requests, "plans": _plans}
		var valid_body: bool = is_instance_valid(_body)
		var valid_capsule: bool = is_instance_valid(_cap) and _cap.shape is CapsuleShape3D
		var foot: float = NAN
		var upper: float = NAN
		if valid_body:
			report["live_pose"] = _contact_pose(_body.global_transform)
			report["body"] = {"floor_angle": _body.floor_max_angle, "snap": _body.floor_snap_length,
				"safe_margin": _body.safe_margin, "up": _contact_vector(_body.up_direction),
				"is_on_floor": _body.is_on_floor(), "mask": _body.collision_mask,
				"rid": str(_body_rid), "owner": _owner, "local_shape": _capsule_index}
		if valid_body and valid_capsule:
			var capsule: CapsuleShape3D = _cap.shape as CapsuleShape3D
			foot = (record.rejected_pose * _cap.transform).origin.y - capsule.height * 0.5
			upper = foot + capsule.radius * (1.0 - cos(_body.floor_max_angle)) + _body.safe_margin
			report["capsule"] = {"radius": capsule.radius, "height": capsule.height,
				"owner_transform": _contact_pose(_cap.transform), "disabled": _cap.disabled}
			report["limits"] = {"foot": foot, "contact_lower": foot - _body.safe_margin - CONTACT_EPS,
				"contact_upper": upper + CONTACT_EPS, "shallow_depth": _body.safe_margin + CONTACT_EPS,
				"max_rise": _step_height, "probe": _probe, "eps": CONTACT_EPS}
		if is_instance_valid(_world):
			var terrain: Object = _world.get("_terrain")
			if is_instance_valid(terrain):
				report["terrain_collision_metadata"] = {"mode": terrain.get("collision_mode"),
					"radius": terrain.get("collision_radius"), "shape_size": terrain.get("collision_shape_size")}
		if record.hit != null:
			var hit: PhysicsTestMotionResult3D = record.hit
			var contacts: Array = []
			for index in mini(CONTACTS, hit.get_collision_count()):
				var normal: Vector3 = hit.get_collision_normal(index)
				var point: Vector3 = hit.get_collision_point(index)
				var depth: float = hit.get_collision_depth(index)
				var contact: Dictionary = {"index": index, "normal": _contact_vector(normal),
					"point": _contact_vector(point), "depth": depth, "local_shape": hit.get_collision_local_shape(index),
					"collider_id": hit.get_collider_id(index), "collider_rid": str(hit.get_collider_rid(index)),
					"collider_shape": hit.get_collider_shape(index), "finite": normal.is_finite() and point.is_finite() and is_finite(depth)}
				if valid_body and valid_capsule and record.reason == &"floor_contact_guard":
					contact["guard_failures"] = {"depth_negative": depth < -CONTACT_EPS,
						"shallow_depth": record.shallow and depth > _body.safe_margin + CONTACT_EPS,
						"local_shape": hit.get_collision_local_shape(index) != _capsule_index,
						"unit_normal": absf(normal.length_squared() - 1.0) > 0.001,
						"floor_cone": normal.dot(Vector3.UP) < cos(_body.floor_max_angle),
						"below_foot": point.y < foot - _body.safe_margin - CONTACT_EPS,
						"above_band": point.y > upper + CONTACT_EPS}
				contacts.append(contact)
			report["motion"] = {"from": _contact_pose(record.native_pose), "leg": _contact_vector(record.native_leg),
				"travel": _contact_vector(hit.get_travel()),
				"safe": hit.get_collision_safe_fraction(), "unsafe": hit.get_collision_unsafe_fraction(),
				"contact_count": hit.get_collision_count(), "contacts": contacts}
		if record.overlaps is Array:
			var overlaps: Array = []
			for index in mini(CONTACTS, record.overlaps.size()):
				var overlap: Dictionary = record.overlaps[index]
				var collider: Object = overlap.get("collider")
				overlaps.append({"rid": str(overlap.get("rid")), "collider_id": overlap.get("collider_id"),
					"shape": overlap.get("shape"), "path": str((collider as Node).get_path()) if is_instance_valid(collider) and collider is Node else "<raw>"})
			report["overlaps"] = overlaps
		print("OPENING_CONTACT_DIAG " + JSON.stringify(report, "", true, true))


func _native_tick(delta: float) -> void:
	_deferral.new_frame()
	_deferred = false
	if _production_steering:
		var began: int = Time.get_ticks_usec()
		_production_delta = delta
		_production_flush_us = 0
		_production_input = Vector2.ZERO
		_production_live_pre_us = 0
		_production_live_post_us = 0
		_production_steering_us = 0
		_production_hint_source = &"none"
		_production_hint_normal = Vector3.ZERO
		_production_prediction_motion = Vector3.ZERO
		_production_heading_vector = Vector3.ZERO
		_production_controller_observed = false
		_observed_live = null
		_production_live_phase = &"unavailable"
		if OS.get_thread_caller_id() != OS.get_main_thread_id():
			_native_tick_impl(delta) # Uses the existing deferred stop on wrong thread.
			return
		if _production_pending:
			_stop_geometry("production post-physics observation did not complete")
		else:
			_native_tick_impl(delta)
		_production_pre_end = Time.get_ticks_usec()
		_pre_observe_us = _production_pre_end - began
		if _production_pending and _pre_observe_us > FRAME_QUERY_US:
			_defer_deadline("production pre callback deadline")
		if refused() and OS.get_thread_caller_id() == OS.get_main_thread_id():
			_production_stop_input()
			var record: Dictionary = _production_record()
			if not record.is_empty():
				record["timing"] = {"pre_us": _pre_observe_us, "input_flush_us": _production_flush_us,
					"live_pre_us": _production_live_pre_us, "stage": "pre_refused", "callback_cap_us": FRAME_QUERY_US}
		return
	if not _contact_enabled or not _requested or OS.get_thread_caller_id() != OS.get_main_thread_id():
		_native_tick_impl(delta)
		return
	_contact_count = 0 # First eight failed probes in this callback, not earlier successful callbacks.
	_native_tick_impl(delta)
	if refused():
		_contact_dump() # Formatting/allocation happens only after the callback refused.


func _supported_step(direction: Vector3) -> bool:
	return _supported_step_at(_body.global_transform, direction)


func _supported_step_at(pose: Transform3D, direction: Vector3) -> bool:
	if not _contact_enabled:
		return _supported_step_from(pose, direction)
	_contact_active = true
	_contact_reason = &""
	_contact_index = -1
	_contact_shallow = false
	var admitted: bool = _supported_step_from(pose, direction)
	if not admitted:
		_contact_capture()
	_contact_active = false
	return admitted


func _start_clear(pose: Transform3D) -> bool:
	if not _contact_enabled:
		return _start_clear_impl(pose)
	if not _contact_active:
		_contact_probe_pose = pose
		_contact_forward = Vector3.ZERO
		_contact_stage = &"actual_start"
		_contact_reason = &""
		_contact_index = -1
		_contact_shallow = false
		_contact_hit = null
	var admitted: bool = _start_clear_impl(pose)
	if not admitted and not _contact_active:
		_contact_capture()
	return admitted


# Diagnostic only: virtual query pose, registered real trainer, no body pose write.
# Call once from a main-thread node physics callback; never from physics_frame.
func diagnose_supported_pose(pose: Transform3D, direction: Vector3) -> bool:
	if not _contact_enabled or OS.get_thread_caller_id() != OS.get_main_thread_id():
		return false
	_contact_staged = true
	_contact_count = 0
	_queries = 0
	_deadline = Time.get_ticks_usec() + FRAME_QUERY_US
	var admitted: bool = _trainer_contract() and _start_clear(pose) and _supported_step_at(pose, direction)
	_contact_dump()
	print("OPENING_CONTACT_STAGED_RESULT " + JSON.stringify({"staged": true, "acceptance_credit": false,
		"admitted": admitted, "refusal": _reason, "queries": _queries, "failed_records": _contact_count}, "", true, true))
	_contact_staged = false
	return admitted


# Opt-in M1 observation, not a predictive certificate. Default diagnostics above
# remain byte-for-byte intact. Production owns every movement/collision response.
class ProductionObserve extends Node:
	var navigator: WeakRef
	func _physics_process(_delta: float) -> void:
		var nav: RefCounted = navigator.get_ref()
		if nav == null:
			queue_free()
		else:
			nav.call("_production_observe")
			# A deferred/refused pre check still spends its original one-frame
			# attempt. It never earns _checked_start or an arrival witness.
			nav.call("_finish_step_epoch")

var _production_steering := false
var _observer: ProductionObserve
var _production_pending := false
var _production_driven := false
var _production_before := Vector3.ZERO
var _production_delta := 0.0
var _pre_observe_us := 0
var _production_pre_end := 0
var _production_flush_us := 0
var _production_input := Vector2.ZERO
var _production_live_pre_us := 0
var _production_live_post_us := 0
var _production_steering_us := 0
var _production_hint_source: StringName = &"none"
var _production_hint_normal := Vector3.ZERO
var _production_prediction_motion := Vector3.ZERO
var _production_heading_vector := Vector3.ZERO
var _avoid_tangent := Vector3.ZERO
var _avoid_retry := 0
var _production_controller_observed := false
var _production_live_phase: StringName = &"unavailable"
var _recoveries_at_start := -1
var _observed_choice := 0
var _retry_at := STALL_FRAMES
var _observed_frames := 0
var _observed_distance := 0.0
var _observed_wall_frames := 0
var _observed_ceiling_frames := 0
var _observed_slide_depth := 0.0
var _observed_live: PhysicsTestMotionResult3D
var _recorded_frame := -1
var _recorded_failure := false
var _production_check_is_post := false
var _failed_pre_sample: Dictionary = {}


func _production_contract() -> bool:
	if not is_instance_valid(_body) or not is_instance_valid(_tick) or not is_instance_valid(_observer) \
			or _body.get_script().resource_path != "res://scripts/player/player_controller.gd" \
			or not _body.has_method("unstick_count") or not _body.is_physics_processing() or not _body.can_process() \
			or _body.process_thread_group != Node.PROCESS_THREAD_GROUP_INHERIT \
			or _tick.process_thread_group != Node.PROCESS_THREAD_GROUP_INHERIT \
			or _observer.process_thread_group != Node.PROCESS_THREAD_GROUP_INHERIT \
			or _body.get_parent() != _world or _tick.get_parent() != _world or _observer.get_parent() != _world \
			or _tick.process_physics_priority != _body.process_physics_priority - 1 \
			or _observer.process_physics_priority != _body.process_physics_priority + 1 \
			or _body.max_slides <= 0 or _body.max_slides > CONTACTS:
		_stop_geometry("production body/callback order/observation bound changed")
		return false
	return true


func _observed_live_clear() -> bool:
	# Actual registered pose only. No cast, future support query, terrain special
	# case or normal-cone admission. A shallow wall/ceiling contact is observed;
	# the unchanged production controller must actually resolve it.
	if not _production_contract() or int(_body.call("unstick_count")) != _recoveries_at_start:
		_stop_geometry("actual production recovery attempt; route cannot claim ordinary traversal")
		return false
	if not _body.global_position.is_finite() or not _body.velocity.is_finite():
		_stop_geometry("nonfinite actual production pose/velocity")
		return false
	var result: Dictionary = _motion(_body.global_transform, Vector3.ZERO, true)
	_observed_live = result.hit as PhysicsTestMotionResult3D
	if _observed_live == null:
		return false
	if _observed_live.get_travel().length() > _body.safe_margin + CONTACT_EPS:
		_capture_failed_pre_sample()
		_stop_geometry("deep actual overlap: zero-motion recovery exceeds unchanged skin")
		return false
	for index in _observed_live.get_collision_count():
		var normal: Vector3 = _observed_live.get_collision_normal(index)
		var point: Vector3 = _observed_live.get_collision_point(index)
		var depth: float = _observed_live.get_collision_depth(index)
		if not normal.is_finite() or not point.is_finite() or not is_finite(depth) \
				or depth < -CONTACT_EPS or depth > _body.safe_margin + CONTACT_EPS \
				or absf(normal.length_squared() - 1.0) > 0.001 \
				or _observed_live.get_collision_local_shape(index) != _capsule_index:
			_stop_geometry("invalid/deep actual live contact or changed trainer local shape")
			return false
	return not _halted()


func _production_live_check(post: bool) -> bool:
	var began: int = Time.get_ticks_usec()
	_production_check_is_post = post
	_observed_live = null
	var clear: bool = _observed_live_clear()
	_production_live_phase = (&"post" if post else &"pre") if _observed_live != null else &"unavailable"
	if post:
		_production_live_post_us = Time.get_ticks_usec() - began
	else:
		_production_live_pre_us = Time.get_ticks_usec() - began
	return clear


## Failure evidence only: the first rejected PRE pose, never a new admission.
## Keep the original body-motion result and spend the same bounded query budget.
func _capture_failed_pre_sample() -> void:
	if not _production_steering or _production_check_is_post or _queries != 1 or not _failed_pre_sample.is_empty():
		return
	var began := Time.get_ticks_usec()
	var pose := _body.global_transform
	_failed_pre_sample = {"acceptance": false, "phase": "original_pre",
		"trigger": "zero-motion recovery exceeds unchanged skin", "complete": false,
		"configured_backend": str(ProjectSettings.get_setting("physics/3d/physics_engine", "<unset>")),
		"server_class": PhysicsServer3D.get_class(), "backend_identity_proven": false,
		"body_pose": _failed_sample_transform(pose), "query_mask": _body.collision_mask,
		"query_margin": 0.0, "query_motion": [0.0, 0.0, 0.0],
		"excluded_self_only": str(_body_rid), "queries_before": _queries,
		"capsule": {"rid": str(_cap.shape.get_rid()), "radius": _cap.shape.radius,
			"height": _cap.shape.height},
		"query_pose": _failed_sample_transform(pose * _body.shape_owner_get_transform(_owner)),
		"raw_pairs_are_not_a_penetration_certificate": true}
	if _queries + 2 > MAX_QUERIES_FRAME or _total_queries + 2 > MAX_QUERIES_LIFETIME:
		_failed_pre_sample["skipped"] = "insufficient unchanged query allowance"
		return
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _body.shape_owner_get_shape(_owner, 0)
	query.transform = pose * _body.shape_owner_get_transform(_owner)
	query.collision_mask = _body.collision_mask
	query.margin = 0.0
	query.motion = Vector3.ZERO
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [_body_rid]
	if not _registered_body_contract() or not _spend():
		return
	var space := _body.get_world_3d().direct_space_state
	var pairs: Array[Vector3] = space.collide_shape(query, CONTACTS)
	var raw_pairs: Array = []
	for point: Vector3 in pairs:
		raw_pairs.append(_contact_vector(point))
	_failed_pre_sample["collide_shape_points"] = raw_pairs
	_failed_pre_sample["pair_limit"] = CONTACTS
	_failed_pre_sample["pair_limit_reached"] = pairs.size() >= CONTACTS * 2
	if not _registered_body_contract() or Time.get_ticks_usec() > _deadline:
		_failed_pre_sample["incomplete"] = "registration/deadline after collide_shape"
		return
	if not _spend():
		return
	var rest: Dictionary = space.get_rest_info(query)
	_failed_pre_sample["rest_info"] = {} if rest.is_empty() else {
		"rid": str(rest.get("rid", RID())), "collider_id": rest.get("collider_id", 0),
		"shape": rest.get("shape", -1), "point": _contact_vector(rest.get("point", Vector3.ZERO)),
		"normal": _contact_vector(rest.get("normal", Vector3.ZERO))}
	if not _registered_body_contract() or Time.get_ticks_usec() > _deadline:
		_failed_pre_sample["incomplete"] = "registration/deadline after get_rest_info"
		return
	var geometry: Array = []
	for index in _observed_live.get_collision_count():
		var rid := _observed_live.get_collider_rid(index)
		var shape_index := _observed_live.get_collider_shape(index)
		if not rid.is_valid() or shape_index < 0 or shape_index >= PhysicsServer3D.body_get_shape_count(rid):
			geometry.append({"index": index, "unavailable": true})
			continue
		var shape := PhysicsServer3D.body_get_shape(rid, shape_index)
		var shape_type := PhysicsServer3D.shape_get_type(shape)
		# Mesh/heightfield shape data can be huge. Capture bounded primitive data.
		var data: Variant = PhysicsServer3D.shape_get_data(shape) if shape_type in [
			PhysicsServer3D.SHAPE_BOX, PhysicsServer3D.SHAPE_CAPSULE,
			PhysicsServer3D.SHAPE_SPHERE, PhysicsServer3D.SHAPE_CYLINDER] else "<unsupported bounded geometry>"
		var body_pose: Transform3D = PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
		var local_pose := PhysicsServer3D.body_get_shape_transform(rid, shape_index)
		geometry.append({"index": index, "rid": str(rid), "shape_index": shape_index,
			"path": _production_collider_path(_observed_live.get_collider(index)),
			"shape_rid": str(shape), "shape_type": shape_type,
			"shape_data": _contact_vector(data) if data is Vector3 else str(data),
			"body_pose": _failed_sample_transform(body_pose),
			"shape_local_pose": _failed_sample_transform(local_pose),
			"shape_world_pose": _failed_sample_transform(body_pose * local_pose)})
	_failed_pre_sample["original_motion_contact_geometry"] = geometry
	_failed_pre_sample["queries_after"] = _queries
	_failed_pre_sample["elapsed_us"] = Time.get_ticks_usec() - began
	_failed_pre_sample["complete"] = _registered_body_contract() and Time.get_ticks_usec() <= _deadline


func _failed_sample_transform(pose: Transform3D) -> Dictionary:
	return {"origin": _contact_vector(pose.origin), "basis_x": _contact_vector(pose.basis.x),
		"basis_y": _contact_vector(pose.basis.y), "basis_z": _contact_vector(pose.basis.z)}


func _production_stop_input() -> void:
	# Refusal remains sticky. Flush the ordinary zero-stick event before another
	# controller can consume an earlier queued command; no action/pose writes.
	_checked_start = false
	_drive.call(0.0, 0.0)
	Input.flush_buffered_events()


func _production_wall_normals(hit: PhysicsTestMotionResult3D) -> Array[Vector3]:
	var walls: Array[Vector3] = []
	if hit == null or hit.get_collision_count() >= CONTACTS:
		_stop_geometry("missing/saturated provisional native steering contacts")
		return walls
	for index in hit.get_collision_count(): # Same unsaturated result, no new query.
		var normal: Vector3 = hit.get_collision_normal(index)
		var point: Vector3 = hit.get_collision_point(index)
		var depth: float = hit.get_collision_depth(index)
		if not normal.is_finite() or not point.is_finite() or not is_finite(depth) \
				or depth < -CONTACT_EPS or absf(normal.length_squared() - 1.0) > 0.001 \
				or hit.get_collision_local_shape(index) != _capsule_index:
			_stop_geometry("invalid provisional native steering contact/shape")
			return []
		# Floor-cone classification selects headings only; it admits no overlap,
		# ground, predicted travel or cached slide. Swept depth is not live depth.
		var horizontal := Vector3(normal.x, 0.0, normal.z)
		if normal.dot(_body.up_direction) < cos(_body.floor_max_angle) \
				and horizontal.length_squared() > CONTACT_EPS:
			walls.append(horizontal.normalized())
		elif _is_prop_collider(hit.get_collider(index)) \
				and is_low_prop_climb(point.y - _foot(_body.global_transform), _step_height):
			# A low prop (a woodpile log, a crate) reads as floor on its rounded
			# top: production steps up onto it and leaves the floor stepping off
			# the far side. Steer round it like a wall, away from the contact.
			var away := Vector3(_body.global_position.x - point.x, 0.0, _body.global_position.z - point.z)
			if away.length_squared() > CONTACT_EPS:
				walls.append(away.normalized())
	return walls


## A prop contact rising above the walking foot by more than numerical skin:
## clutter the controller would climb rather than walk on. Only Props colliders
## reach this (terrain never does; walkable treads are excluded by meta), so
## the floor-cone allowance terrain needs does not apply: the trainer_camp
## campfire stone ring is lower than 0.15 m and was climbed, then stepped off
## (gate B galewisp, CI render 37239859189). No upper bound: the woodpile's box
## is exactly STEP_HEIGHT tall. `step_height` must still be a real positive step.
static func is_low_prop_climb(rise: float, step_height: float) -> bool:
	return is_finite(rise) and is_finite(step_height) and step_height > 0.0 and rise > LOW_PROP_RISE


## Only clutter colliders under the world's authored Props root are steered
## round this way. Terrain and houses live elsewhere; the Props root also holds
## walkable trail treads (props.gd marks them `walkable_segment`), which are
## ground to walk onto, not obstacles.
func _is_prop_collider(collider: Object) -> bool:
	var props := _world.get_node_or_null(^"Props") if _world != null else null
	return props != null and collider is Node and props.is_ancestor_of(collider as Node) \
		and not bool((collider as Node).get_meta(&"walkable_segment", false))


func _production_heading(direction: Vector3) -> Vector3:
	var wanted := Vector3(direction.x, 0.0, direction.z).normalized()
	var walls := _production_wall_normals(_observed_live) # Actual pre pose result.
	_production_hint_source = &"live_pre"
	if _halted():
		return Vector3.ZERO
	if walls.is_empty():
		# ONE advisory cast from the real pose, covering the ordinary step plus
		# the actual controller's acceleration-bounded turning distance. A
		# one-step warning can arrive while cached momentum still moves inward.
		# _motion charges the SAME query/lifetime/deadline caps and unchanged
		# capsule, mask, skin and no extra exclusions. This is never clearance.
		var vitals: RefCounted = _body.get("vitals")
		if vitals == null or not vitals.has_method("move_speed_scale"):
			_stop_geometry("missing production ground-speed state")
			return Vector3.ZERO
		var reach := ordinary_avoidance_reach(float(_body.get("_walk_speed")), float(_body.get("_sprint_speed")),
			float(vitals.call("move_speed_scale")), Vector2(_body.velocity.x, _body.velocity.z).length(),
			float(_body.get("_max_speed")), _production_delta, float(_body.get("_ground_accel")),
			MAX_EDGE if _raw else direction.length())
		if not is_finite(reach) or reach <= 0.0 or reach > MAX_EDGE:
			_stop_geometry("invalid bounded provisional production step")
			return Vector3.ZERO
		# A position walk ends at the current route waypoint. Geometry beyond it
		# cannot justify steering away from this leg (the shop counter is beyond
		# the axial entry point). Raw directional requests retain their horizon.
		# This caps an advisory cast only; actual pre/post validation is unchanged.
		if not _raw:
			reach = minf(reach, direction.length())
		_production_prediction_motion = wanted * reach
		var predicted: Dictionary = _motion(_body.global_transform, _production_prediction_motion)
		_production_hint_source = &"prospective_step"
		if _halted():
			return Vector3.ZERO
		walls = _production_wall_normals(predicted.hit as PhysicsTestMotionResult3D)
		if _halted():
			return Vector3.ZERO
	var opposing := Vector3.ZERO
	var incoming := -CONTACT_EPS
	for wall: Vector3 in walls:
		if wanted.dot(wall) < incoming:
			incoming = wanted.dot(wall)
			opposing = wall
	if opposing == Vector3.ZERO:
		_production_heading_vector = wanted
		return direction
	var tangent := Vector3(-opposing.z, 0.0, opposing.x)
	if _avoid_tangent == Vector3.ZERO:
		if tangent.dot(wanted) < 0.0:
			tangent = -tangent
	else:
		# Keep the prior hand while it yields an outward heading. The existing
		# 26-frame retry reverses the preference; no stall/budget reset here.
		if tangent.dot(_avoid_tangent) < 0.0:
			tangent = -tangent
		if _avoid_retry != _observed_choice:
			tangent = -tangent
	_production_hint_normal = opposing
	for choice in 2: # Two headings, below unchanged MAX_CHOICES; no native query.
		var along := tangent if choice == 0 else -tangent
		var heading := wall_heading(along, opposing, _production_hint_source == &"live_pre")
		var outward := true
		for wall: Vector3 in walls: # At most seven reported normals, no dedup.
			if heading.dot(wall) < -CONTACT_EPS:
				outward = false
				break
		if outward:
			_avoid_tangent = along
			_avoid_retry = _observed_choice
			_production_heading_vector = heading
			return heading * direction.length() # Preserve original stick easing.
	_stop_geometry("no bounded outward provisional stick heading")
	return Vector3.ZERO


## The configured walk/sprint target and cached momentum bound an ordinary
## horizontal step. The 120m/s emergency ceiling still bounds actual movement.
static func ordinary_preview_reach(walk: float, sprint: float, scale: float, momentum: float, ceiling: float, delta: float) -> float:
	for value: float in [walk, sprint, scale, momentum, ceiling, delta]:
		if not is_finite(value):
			return NAN
	if walk <= 0.0 or sprint < walk or scale <= 0.0 or momentum < 0.0 or ceiling <= 0.0 or delta <= 0.0:
		return NAN
	var speed := maxf(maxf(walk, sprint) * scale, momentum)
	return minf(speed, ceiling) * delta if is_finite(speed) else NAN


## Steering horizon only. The original one-step helper and actual movement,
## overlap, contact, query, deadline and waypoint guards keep their contracts.
static func ordinary_avoidance_reach(walk: float, sprint: float, scale: float, momentum: float,
		ceiling: float, delta: float, acceleration: float, waypoint_distance: float) -> float:
	var step := ordinary_preview_reach(walk, sprint, scale, momentum, ceiling, delta)
	if not is_finite(step) or not is_finite(acceleration) or acceleration <= 0.0 \
			or not is_finite(waypoint_distance) or waypoint_distance <= 0.0:
		return NAN
	var speed := step / delta
	var horizon := step + speed * speed / (2.0 * acceleration)
	return minf(horizon, waypoint_distance) if is_finite(horizon) else NAN


## A prospective surface needs a tangent, not a lateral shove toward an
## unreported opposite wall. Live shallow contact keeps the original relief.
static func wall_heading(along: Vector3, opposing: Vector3, live: bool) -> Vector3:
	return (along + opposing * (0.25 if live else 0.0)).normalized()


func _choose_route(point: Vector2, tolerance: float) -> bool:
	if not _production_steering:
		return _choose(point, tolerance)
	_plans += 1
	var from: Vector2 = _xz(_body.global_position)
	if _plans > MAX_PLANS or from.distance_to(point) > MAX_EDGE or _observed_choice >= MAX_CHOICES:
		_stop_geometry("observed route scope/plan/candidate cap")
		return false
	_route.clear()
	if not _provisional_path.is_empty() and _departure.is_empty():
		var nearest := 0
		for index in _provisional_path.size():
			if from.distance_squared_to(_provisional_path[index]) < from.distance_squared_to(_provisional_path[nearest]):
				nearest = index
		var previous := from
		for index in range(nearest, _provisional_path.size()):
			if from.distance_to(_provisional_path[index]) > MAX_EDGE or previous.distance_to(_provisional_path[index]) > MAX_EDGE:
				_stop_geometry("provisional path exceeds unchanged edge scope")
				return false
			_route.append(_provisional_path[index])
			previous = _provisional_path[index]
		if previous.distance_to(point) > MAX_EDGE:
			_stop_geometry("provisional final heading exceeds unchanged edge scope")
			return false
		_route.append(point)
		return true # Only a heading list; both original actual-pose guards run.
	if not _guided_road.is_empty() and _departure.is_empty():
		# Follow the current named painted road from its nearest authored node.
		# A hint changes stick headings, never certifies geometry or resets the
		# walking/stall/query caps. Actual controller and all observations still run.
		var nearest := 0
		for index in _guided_road.size():
			if from.distance_squared_to(_guided_road[index]) < from.distance_squared_to(_guided_road[nearest]):
				nearest = index
		var previous: Vector2 = from
		for index in range(nearest, _guided_road.size()):
			if from.distance_to(_guided_road[index]) > MAX_EDGE or previous.distance_to(_guided_road[index]) > MAX_EDGE:
				_stop_geometry("authored road hint exceeds unchanged edge scope")
				return false
			_route.append(_guided_road[index])
			previous = _guided_road[index]
		if previous.distance_to(point) > MAX_EDGE:
			_stop_geometry("authored road final heading exceeds unchanged edge scope")
			return false
		_route.append(point)
		return true # Provisional headings only; no query/cache/dedup shortcut.
	if _observed_choice == 0 or not _departure.is_empty():
		_route.append(point) # Provisional requested road/door/camp heading only.
		return true
	var candidates: Array[Vector2] = []
	for road: Vector2 in _roads:
		if road.distance_to(from) > 0.5 and road.distance_to(from) <= MAX_EDGE and road.distance_to(point) <= MAX_EDGE:
			candidates.append(road)
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return from.distance_to(a) + a.distance_to(point) < from.distance_to(b) + b.distance_to(point))
	if _observed_choice - 1 >= candidates.size():
		_stop_geometry("actual steering stalled with no remaining authored road choice")
		return false
	_route.append(candidates[_observed_choice - 1])
	_route.append(point)
	return true # Does not certify either future leg or silently succeed at it.


func _production_observe() -> void:
	if OS.get_thread_caller_id() != OS.get_main_thread_id():
		_reason = "production observation no longer runs on the main physics thread"
		_requested = false
		_drive.call_deferred(0.0, 0.0)
		return
	if not _production_pending:
		return
	var began: int = Time.get_ticks_usec()
	_production_pending = false
	# One 10ms allowance for the two harness callbacks' own work, excluding the
	# intervening production controller. Native query counts share the frame cap.
	# After a deferred pre callback the stick is released and the controller's
	# actual movement is still validated in full, on its own allowance.
	_deadline = began + (FRAME_QUERY_US if _deferred else maxi(0, FRAME_QUERY_US - _pre_observe_us))
	_deferred = false
	_checked_start = false
	if refused():
		_production_stop_input()
		_production_record()
		return
	_production_controller_observed = true
	var contract_began: int = Time.get_ticks_usec()
	var contract_ok: bool = _trainer_contract()
	var contract_us: int = Time.get_ticks_usec() - contract_began
	var slides_began: int = Time.get_ticks_usec()
	var live_ok: bool = contract_ok and _production_live_check(true)
	# A deadline deferral in the live query defers ONLY that query. Every check
	# below reads cached controller state (no native query), so it still runs
	# this frame and still refuses hard (independent review M1).
	var live_deferred := _deferred
	_deferred = false
	if not contract_ok or (not live_ok and not live_deferred):
		_stop_geometry("invalid actual production landing/registration")
	elif not _body.is_on_floor():
		_stop_geometry("actual production walk lost grounded floor")
	else:
		var count: int = _body.get_slide_collision_count()
		var contacts := 0
		_observed_slide_depth = 0.0
		if count > CONTACTS:
			_stop_geometry("actual production slide observation cap")
		else:
			for slide in count:
				var collision: KinematicCollision3D = _body.get_slide_collision(slide)
				if collision == null or not is_finite(collision.get_depth()) or collision.get_depth() < -CONTACT_EPS:
					_stop_geometry("invalid actual production slide result")
					break
				contacts += collision.get_collision_count()
				if contacts > CONTACTS:
					_stop_geometry("actual production contact observation cap")
					break
				# Swept depths describe UNSAFE motion; only the live ZERO-motion
				# result above is used to reject deep current-body overlap.
				_observed_slide_depth = maxf(_observed_slide_depth, collision.get_depth())
				for index in collision.get_collision_count():
					var normal: Vector3 = collision.get_normal(index)
					var point: Vector3 = collision.get_position(index)
					# Owner identity is valid here: get_slide_collision returns the
					# body's populated cache, not a fresh ownerless test_move result.
					if collision.get_local_shape(index) != _cap or not normal.is_finite() or not point.is_finite():
						_stop_geometry("invalid actual slide contact/shape owner")
						break
				if _halted():
					break
	var slides_us: int = Time.get_ticks_usec() - slides_began - _production_live_post_us
	var movement_began: int = Time.get_ticks_usec()
	if not _halted():
		# Cached real velocity is computed by move_and_slide before the production
		# step-up. Read it; never write it. Additional motion must fit that actual
		# controller's step/drop bounds, so a respawn/pose jump cannot earn travel.
		var speed_cap: float = float(_body.get("_max_speed"))
		var slide_motion: Vector3 = _body.get_real_velocity() * _production_delta
		var extra: Vector3 = _body.global_position - _production_before - slide_motion
		var skin: float = _body.safe_margin + CONTACT_EPS
		if not is_finite(_production_delta) or _production_delta <= 0.0 or not is_finite(speed_cap) or speed_cap <= 0.0 \
				or not slide_motion.is_finite() or not extra.is_finite() \
				or speed_cap * _production_delta > MAX_EDGE \
				or slide_motion.length() > speed_cap * _production_delta + _body.floor_snap_length + skin \
				or _xz(extra).length() > maxf(_probe, speed_cap * _production_delta) + skin \
				or extra.y > _step_height + skin or extra.y < -_body.floor_snap_length - skin:
			_stop_geometry("actual movement exceeded production slide/step/drop bounds")
	if not _halted():
		_observed_frames += 1
		_observed_distance += _body.global_position.distance_to(_production_before)
		_observed_wall_frames += int(_body.is_on_wall())
		_observed_ceiling_frames += int(_body.is_on_ceiling())
		if _production_driven:
			_stalled += 1
			if _xz(_body.global_position).distance_to(_xz(_progress_at)) >= PROGRESS:
				_progress_at = _body.global_position
				_stalled = 0
				_retry_at = STALL_FRAMES
			if _stalled > 90:
				_stop_geometry("real production stick travel made no progress within 90 requested frames")
		_checked_start = not _halted() and not live_deferred # Only AFTER actual controller movement.
	var movement_us: int = Time.get_ticks_usec() - movement_began
	var snapshot_began: int = Time.get_ticks_usec()
	var record: Dictionary = _production_record()
	var snapshot_us: int = Time.get_ticks_usec() - snapshot_began
	if not record.is_empty():
		record["timing"] = {"pre_us": _pre_observe_us, "input_flush_us": _production_flush_us,
			"live_pre_us": _production_live_pre_us, "between_callbacks_us": began - _production_pre_end,
			"provisional_steering_us": _production_steering_us,
			"post_contract_us": contract_us, "live_post_us": _production_live_post_us,
			"slide_validation_us": slides_us, "movement_progress_us": movement_us,
			"snapshot_us": snapshot_us, "post_us": Time.get_ticks_usec() - began,
			"callback_cap_us": FRAME_QUERY_US, "stage": "post",
			"serialization_and_print": "deferred; excluded; snapshot included",
			"between_callbacks": "controller and other nodes; excluded; not controller-only"}
		record["callback_own_us"] = _pre_observe_us + Time.get_ticks_usec() - began
		record["checked_start"] = _checked_start
	# Last success check includes snapshot scheduling and all timing metadata.
	# Only refused cleanup/terminal diagnostic updates may follow this guard.
	if Time.get_ticks_usec() > _deadline:
		_checked_start = false
		_defer_deadline("production observation callback deadline")
	if refused():
		_production_stop_input()
		if record.is_empty():
			snapshot_began = Time.get_ticks_usec()
			record = _production_record()
			snapshot_us = Time.get_ticks_usec() - snapshot_began
			if not record.is_empty():
				record["timing"] = {"pre_us": _pre_observe_us, "input_flush_us": _production_flush_us,
					"live_pre_us": _production_live_pre_us, "between_callbacks_us": began - _production_pre_end,
					"post_contract_us": contract_us, "live_post_us": _production_live_post_us,
					"slide_validation_us": slides_us, "movement_progress_us": movement_us,
					"snapshot_us": snapshot_us, "post_us": Time.get_ticks_usec() - began,
					"callback_cap_us": FRAME_QUERY_US, "stage": "post_refused",
					"terminal_snapshot_after_refusal": true}
		else:
			_recorded_failure = true
			record["refusal"] = _reason # Replace the queued sample, never a duplicate.
		if not record.is_empty():
			record["callback_own_us"] = _pre_observe_us + Time.get_ticks_usec() - began
			record["checked_start"] = false


func _production_record() -> Dictionary:
	# First eight observations, each 90th, and one terminal failure. Bounded
	# formatting, never a per-frame history or an acceptance/no-snag assertion.
	if not is_instance_valid(_body) or (refused() and _recorded_failure):
		return {}
	if not refused() and (_recorded_frame == _observed_frames or (_observed_frames > 8 and _observed_frames % 90 != 0)):
		return {}
	if not is_instance_valid(_tick) or _tick.records.size() >= 2:
		_stop_geometry("production diagnostic queue cap")
		return {}
	_recorded_frame = _observed_frames
	_recorded_failure = refused()
	var contacts: Array = []
	if _observed_live != null:
		for index in mini(CONTACTS, _observed_live.get_collision_count()):
			contacts.append({"normal": _contact_vector(_observed_live.get_collision_normal(index)),
				"point": _contact_vector(_observed_live.get_collision_point(index)),
				"depth": _observed_live.get_collision_depth(index), "local_shape": _observed_live.get_collision_local_shape(index),
				"collider_rid": str(_observed_live.get_collider_rid(index)), "collider_shape": _observed_live.get_collider_shape(index),
				"collider_path": _production_collider_path(_observed_live.get_collider(index))})
	var slides: Array = []
	var slide_point_counts: Array[int] = []
	if _production_controller_observed:
		for slide in mini(CONTACTS, _body.get_slide_collision_count()):
			var cached: KinematicCollision3D = _body.get_slide_collision(slide)
			slide_point_counts.append(cached.get_collision_count() if cached != null else -1)
	for slide in (mini(CONTACTS, _body.get_slide_collision_count()) if _production_controller_observed else 0):
		var collision: KinematicCollision3D = _body.get_slide_collision(slide)
		if collision == null:
			break
		for index in mini(CONTACTS - slides.size(), collision.get_collision_count()):
			slides.append({"slide": slide, "normal": _contact_vector(collision.get_normal(index)),
				"point": _contact_vector(collision.get_position(index)), "swept_depth": collision.get_depth(),
				"collider_rid": str(collision.get_collider_rid(index)), "collider_shape": collision.get_collider_shape_index(index),
				"collider_path": _production_collider_path(collision.get_collider(index))})
		if slides.size() == CONTACTS:
			break
	var record: Dictionary = {"acceptance": false,
		"frame": _observed_frames, "player": _contact_vector(_body.global_position), "request": _contact_vector(_request),
		"on_floor": _body.is_on_floor(), "on_wall": _body.is_on_wall(), "on_ceiling": _body.is_on_ceiling(),
		"actual_delta": _contact_vector(_body.global_position - _production_before) if _production_controller_observed else [],
		"slide_motion": _contact_vector(_body.get_real_velocity() * _production_delta) if _production_controller_observed else [],
		"progress_m": _observed_distance, "stall_frames": _stalled, "wall_frames": _observed_wall_frames,
		"ceiling_frames": _observed_ceiling_frames,
		"slide_count": _body.get_slide_collision_count() if _production_controller_observed else -1,
		"swept_depth": _observed_slide_depth if _production_controller_observed else -1.0, "slide_contacts": slides,
		"safe_margin": _body.safe_margin, "floor_angle": _body.floor_max_angle, "snap": _body.floor_snap_length, "mask": _body.collision_mask,
		"recoveries": int(_body.call("unstick_count")) if _body.has_method("unstick_count") else -1,
		"live_recovery_travel": _contact_vector(_observed_live.get_travel()) if _observed_live != null else [],
		"live_contacts": contacts, "queries": _queries, "total_queries": _total_queries,
		"requests": _requests, "plans": _plans, "provisional_choice": _observed_choice, "refusal": _reason,
		"physics_frame": Engine.get_physics_frames(), "delivered_input": [_production_input.x, _production_input.y],
		"controller_wanted_dir": _contact_vector(_body.get("_wanted_dir")) if _production_controller_observed else [],
		"controller_observation_available": _production_controller_observed,
		"live_state_phase": _production_live_phase,
		"authored_road_hint": _guided_label, "slide_point_counts": slide_point_counts,
		"provisional_steering": {"source": _production_hint_source, "acceptance": false,
			"prediction_motion": _contact_vector(_production_prediction_motion),
			"wall_normal": _contact_vector(_production_hint_normal),
			"heading": _contact_vector(_production_heading_vector), "retry_choice": _avoid_retry},
		"slide_contacts_are_capped_prefix": true,
		"diagnostic_output_outside_physics_cap": true}
	if not _failed_pre_sample.is_empty():
		record["failed_original_pre_sample"] = _failed_pre_sample
	_tick.records.append(record)
	if not _tick.flush_pending:
		_tick.flush_pending = true
		_tick.call_deferred("flush_records")
	return record


func _production_collider_path(collider: Object) -> String:
	return str((collider as Node).get_path()) if is_instance_valid(collider) and collider is Node else "<raw>"
