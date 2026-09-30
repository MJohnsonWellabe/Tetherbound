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
	if hit == null or hit.get_collision_count() == 0 or hit.get_collision_count() >= CONTACTS \
			or not _registered_body_contract():
		return false
	var ceiling := _foot(pose) + _cap.shape.radius * (1.0 - cos(_body.floor_max_angle)) + _body.safe_margin
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
			return false
	return true

func _start_clear(pose: Transform3D) -> bool:
	# Explicit actual overlap query. No raised origin, shape shrink or floor RID exclusion.
	if not _registered_body_contract() or not _spend():
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
	if not _registered_body_contract() or overlaps.size() >= CONTACTS or Time.get_ticks_usec() > _deadline:
		_stop_geometry("starting overlap saturation/deadline")
		return false
	# Identity of an overlapping floor shape does not prove there is no wall
	# contact in that same concave shape. Refuse ALL exact-shape intersections,
	# including a legitimate floor touch that this backend reports as overlap.
	# Only recovery SKIN contact outside the unshrunk capsule may be floor-classified.
	if not overlaps.is_empty():
		return false
	var recovery := _motion(pose, Vector3.ZERO, true)
	if refused() or recovery.hit == null:
		return false
	var hit: PhysicsTestMotionResult3D = recovery.hit
	# Zero-motion recovery must itself be shallow at this supplied pose.
	# Do not silently admit a large recovery displacement after an overlap miss.
	if hit.get_travel().length() > _body.safe_margin + CONTACT_EPS:
		return false
	if not recovery.blocked and overlaps.is_empty() and hit.get_collision_count() == 0:
		return true
	if not _floor_contacts(hit, pose, true):
		return false # Deep, side, elevated, missing or ambiguous contacts refuse.
	return true # Provisional floor/skin classification, NOT a collision theorem.


func _supported_step(direction: Vector3) -> bool:
	var pose := _body.global_transform
	var forward := direction.normalized() * _probe
	var sweep := _motion(pose, forward)
	if refused():
		return false
	var landing := pose.translated(forward)
	var drop := _body.floor_snap_length
	if sweep.blocked:
		# Read-only counterpart of production's bounded step probes. Never apply poses.
		if _motion(pose, Vector3.UP * _step_height).blocked or refused():
			return false
		var raised := pose.translated(Vector3.UP * _step_height)
		if not _start_clear(raised) or _motion(raised, forward).blocked or refused():
			return false
		landing = raised.translated(forward)
		drop = _step_height # Production _try_step_up drops only STEP_HEIGHT.
	if not _start_clear(landing):
		return false
	var support := _motion(landing, Vector3.DOWN * drop, true)
	if not support.blocked or support.hit == null or refused():
		return false
	var travel: Vector3 = support.hit.get_travel()
	if not travel.is_finite() or absf(travel.x) > _body.safe_margin + CONTACT_EPS \
			or absf(travel.z) > _body.safe_margin + CONTACT_EPS or travel.y > _body.safe_margin + CONTACT_EPS \
			or -travel.y > drop + _body.safe_margin + CONTACT_EPS:
		return false
	landing = landing.translated(travel)
	var rise := _foot(landing) - _foot(pose)
	# Sweep depths belong to UNSAFE advance; travel gives the SAFE landing.
	# Keep swept support identity/normal/foot-band guards, then independently
	# apply the unchanged shallow depth bound via ZERO motion at that safe pose.
	# _start_clear also retains exact unshrunk overlap refusal at the safe pose.
	return rise <= _step_height + _body.safe_margin + CONTACT_EPS \
		and rise >= -_body.floor_snap_length - _body.safe_margin - CONTACT_EPS \
		and _floor_contacts(support.hit, landing, false) and _start_clear(landing) and not refused()


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
		var distance := maxf(0.0, displacement.length() - (tolerance if index < 0 else THRESHOLD_RADIUS))
		var direction := Vector3(displacement.x, 0.0, displacement.y).normalized()
		var result := _motion(_body.global_transform, direction * distance)
		if refused():
			return false
		if not result.blocked and _supported_step(direction):
			_route.append(candidate)
			if index >= 0:
				_route.append(point)
			return true
	_stop_geometry("no admitted direct/existing-road leg; uneven floor or multiple bends may be incomplete")
	return false


func _native_tick(_delta: float) -> void:
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
