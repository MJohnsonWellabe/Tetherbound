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
const CONTACT_EPS := 0.00001 # Numerical comparison only, never a smaller shape.

class NativeTick extends Node:
	var navigator: WeakRef
	func _physics_process(delta: float) -> void:
		var nav: RefCounted = navigator.get_ref()
		if nav == null:
			queue_free()
		else:
			nav.call("_native_tick", delta)

var _body: CharacterBody3D
var _cap: CollisionShape3D
var _world: Node3D
var _tick: NativeTick
var _roads: Array[Vector2] = []
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
var _checked_start := false


func _init(tree: SceneTree, player: Node3D, rig: Node3D, drive: Callable) -> void:
	super(tree, player, rig, drive)
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
		for pair: Variant in road.points:
			if not _append_road(pair):
				return
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


func _stop_geometry(reason: String) -> void:
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
	_goal = Vector2.INF
	_arrival = 0.05
	_stalled = 0
	_checked_start = false
	if is_instance_valid(_player):
		_progress_at = _player.global_position
	_drive.call(0.0, 0.0)


func set_approach_radius(value: float) -> void:
	if not is_finite(value) or value <= 0.0 or value > 1.65:
		_stop_geometry("invalid original approach radius")
	else:
		_arrival = value


func step(point: Vector3) -> void:
	_request = point
	_raw = false
	_requested = not refused()
	await _tree.physics_frame # Queries execute only in NativeTick, after this signal.


func push_once(direction: Vector3) -> void:
	# Preserve deliberate prompt shuffles through the same real stick seam.
	_request = direction
	_raw = true
	_requested = not refused()


func walk_to(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:
	reset()
	_arrival = close_enough
	if budget <= 0 or budget > 3600 or not point.is_finite() \
			or not is_finite(close_enough) or close_enough <= 0.0 or close_enough > 1.65:
		_stop_geometry("invalid bounded walk request")
		return false
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


func _spend() -> bool:
	_queries += 1
	_total_queries += 1
	if refused() or _queries > MAX_QUERIES_FRAME or _total_queries > MAX_QUERIES_LIFETIME \
			or Time.get_ticks_usec() > _deadline:
		_stop_geometry("native query count/lifetime/cooperative deadline cap")
		return false
	return true


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
	if not _registered_body_contract() or Time.get_ticks_usec() > _deadline \
			or hit.get_collision_count() >= CONTACTS:
		_stop_geometry("native query body identity/deadline/contact saturation")
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
				or normal.dot(Vector3.UP) < cos(_body.floor_max_angle) \
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
	if not _registered_body_contract() or overlaps.size() >= CONTACTS or Time.get_ticks_usec() > _deadline:
		_stop_geometry("starting overlap saturation/deadline")
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
	if refused() or recovery.hit == null:
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
	if refused():
		_contact_mark(&"forward_motion_refused")
		return false
	var landing := pose.translated(forward)
	var drop := _body.floor_snap_length
	if sweep.blocked:
		# Read-only counterpart of production's bounded step probes. Never apply poses.
		_contact_stage_at(&"step_up")
		if _motion(pose, Vector3.UP * _step_height).blocked or refused():
			_contact_mark(&"step_up_blocked_or_refused")
			return false
		var raised := pose.translated(Vector3.UP * _step_height)
		_contact_stage_at(&"raised_start_clear")
		if not _start_clear(raised):
			return false
		_contact_stage_at(&"raised_forward")
		if _motion(raised, forward).blocked or refused():
			_contact_mark(&"raised_forward_blocked_or_refused")
			return false
		landing = raised.translated(forward)
		drop = _step_height # Production _try_step_up drops only STEP_HEIGHT.
	_contact_stage_at(&"landing_start_clear")
	if not _start_clear(landing):
		return false
	_contact_stage_at(&"support_down")
	var support := _motion(landing, Vector3.DOWN * drop, true)
	if not support.blocked or support.hit == null or refused():
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
	return not refused()


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
		if refused():
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
	_requests += 1
	_queries = 0
	_deadline = Time.get_ticks_usec() + FRAME_QUERY_US
	if refused() or _requests > MAX_REQUESTS or not _request.is_finite():
		_stop_geometry("native request/lifetime/finite-input cap")
		return
	if not can_walk():
		_drive.call(0.0, 0.0)
		return
	if not _trainer_contract() or not _start_clear(_body.global_transform):
		_stop_geometry("actual starting overlap cannot be classified as shallow support floor")
		return
	if not _body.is_on_floor():
		_stop_geometry("trainer not grounded; aerial/stream/recovery case is incomplete")
		return
	_checked_start = true
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
		elif not _route.is_empty():
			_route[_route.size() - 1] = point # Live target, still checked locally.
		if not _route.is_empty() and _xz(_player.global_position).distance_to(_route[0]) <= THRESHOLD_RADIUS:
			_route.pop_front()
		if _route.is_empty() and not _choose(point, tolerance):
			return
		var at := _route[0]
		direction = Vector3(at.x - _player.global_position.x, 0.0, at.y - _player.global_position.z)
	if direction.length_squared() <= 0.000001:
		_drive.call(0.0, 0.0)
		return
	if not _supported_step(direction):
		# Recheck live geometry every input; additions, raw shapes and owner edits
		# are observed natively. A blocked local leg gets one new bounded choice.
		_route.clear()
		if _raw or not _choose(_goal, THRESHOLD_RADIUS if not _departure.is_empty() else _arrival) or not _supported_step(Vector3(_route[0].x - _player.global_position.x, 0.0, _route[0].y - _player.global_position.z)):
			_stop_geometry("native local floor/clearance incomplete; no blind fallback")
			return
		direction = Vector3(_route[0].x - _player.global_position.x, 0.0, _route[0].y - _player.global_position.z)
	_stalled += 1
	if _player.global_position.distance_to(_progress_at) >= 0.08:
		_progress_at = _player.global_position
		_stalled = 0
	if _stalled > 90:
		_stop_geometry("real stick travel made no progress within 90 requested frames")
		return
	_owns_input = true
	if refused() or Time.get_ticks_usec() > _deadline:
		_stop_geometry("native callback cooperative deadline before stick input")
		return
	_push(direction.normalized() * clampf(direction.length() / EASE_METRES, EASE_FLOOR, 1.0))


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
