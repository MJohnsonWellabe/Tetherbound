extends "res://tests/test_case.gd"

## F04/F10#2, guest-side lane and cue presentation (X05, #356 01:40 ruling).
## A host relays the optional ground-mark `shape` of its wild body's tell (the
## travelling lane, the guard cone, the route cue) so a guest's proxy draws
## what the host player sees. Presentation only: no hit or damage path here.

const AI := preload("res://scripts/combat/combat_ai.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")


class ProxyShell extends "res://scripts/creatures/shared_opponent_proxy.gd":
	func _ready() -> void:
		pass


class FakeBody extends Node3D:
	var shape: Dictionary = {}

	func facing() -> Vector3:
		return Vector3.FORWARD

	func presentation_shape() -> Dictionary:
		return shape.duplicate(true)


class FakeRuntime extends Node:
	var cue_serial := 0
	var telegraph_count := 0
	var strike_count := 0
	var telegraph_until_ms := 0
	var body_generation := 5
	var presentation_seq := 1
	var wild: Node3D = null

	func body() -> Node3D:
		return wild


class RecordingProxy extends Node3D:
	var body_generation := 5
	var calls: Array = []

	func apply_pose(_generation: int, _sequence: int, _feet: Vector3, _facing: Vector3) -> bool:
		return true

	func present_telegraph(serial: int, seconds: float, total: int, shape: Dictionary = {}) -> bool:
		calls.append(["telegraph", serial, seconds, total, shape])
		return true

	func present_route(serial: int, seconds: float, shape: Dictionary = {}) -> bool:
		calls.append(["route", serial, seconds, shape])
		return true

	func present_strike(serial: int, total: int) -> bool:
		calls.append(["strike", serial, total])
		return true


class DirectorShell extends "res://scripts/combat/encounter_director.gd":
	var runtime: Node = null
	var broadcast: Array[Dictionary] = []

	func _ready() -> void:
		pass

	func _is_host() -> bool:
		return true

	func _encounter_realm() -> String:
		return "stormwood"

	func _shared_host_fight(_encounter_id: String) -> Node:
		return runtime

	func _local_bound_encounter_id() -> String:
		return ""

	func _broadcast_shared_cue(payload: Dictionary) -> void:
		broadcast.append(payload.duplicate(true))


const LANE_SHAPE := {"lane_start": 0.9, "lane_length": 7.0, "lane_half_width": 0.9,
	"lane_travels": true, "lane_lock_in_s": 0.4}
const GUARD_SHAPE := {"guard_reach": 3.2, "guard_cone": 70.0}


func _director(shape: Dictionary) -> DirectorShell:
	var director := DirectorShell.new()
	var runtime := FakeRuntime.new()
	var body := FakeBody.new()
	body.shape = shape
	runtime.wild = body
	director.runtime = runtime
	return director


func _free_director(director: DirectorShell) -> void:
	var runtime: FakeRuntime = director.runtime
	runtime.wild.free()
	runtime.free()
	if director._shared_opponent_proxy != null:
		director._shared_opponent_proxy.free()
	director.free()


func test_host_cue_payload_carries_the_body_shape_and_a_guest_applies_it() -> void:
	var director := _director(LANE_SHAPE)
	var payload := director._shared_cue_payload("enc_1", "telegraph", 0.9)
	assert_eq(payload.get("shape", {}), LANE_SHAPE, "telegraph cue carries the body's lane shape")
	var strike := director._shared_cue_payload("enc_1", "strike", 0.0)
	assert_false(strike.has("shape"), "a strike cue carries no shape")
	var proxy := RecordingProxy.new()
	director._shared_opponent_proxy = proxy
	var wire: Dictionary = JSON.parse_string(JSON.stringify(payload))
	director._apply_shared_cue(wire)
	assert_eq(proxy.calls.size(), 1)
	var call: Array = proxy.calls[0]
	assert_eq(call[0], "telegraph")
	assert_almost_eq(float((call[4] as Dictionary).get("lane_length", 0.0)), 7.0)
	assert_almost_eq(float((call[4] as Dictionary).get("lane_lock_in_s", 0.0)), 0.4)
	_free_director(director)


func test_host_route_cue_is_its_own_kind_with_a_fresh_serial() -> void:
	var shape := LANE_SHAPE.duplicate()
	shape["lane_travels"] = false
	shape["route_s"] = 1.1
	var director := _director(shape)
	director._on_shared_host_route(1.1, "enc_1")
	assert_eq(director.broadcast.size(), 1)
	var payload: Dictionary = director.broadcast[0]
	assert_eq(payload.get("kind"), "route")
	assert_eq(int(payload.get("cue_serial")), 1)
	assert_eq(int(payload.get("telegraph_count")), 0, "a route cue is not a telegraph")
	assert_almost_eq(float((payload.get("shape", {}) as Dictionary).get("route_s", 0.0)), 1.1)
	var proxy := RecordingProxy.new()
	director._shared_opponent_proxy = proxy
	director._apply_shared_cue(payload)
	assert_eq((proxy.calls[0] as Array)[0], "route")
	_free_director(director)


func test_a_payload_without_shape_still_presents_the_ordinary_telegraph() -> void:
	var director := _director({})
	var payload := director._shared_cue_payload("enc_1", "telegraph", 0.8)
	assert_false(payload.has("shape"), "an empty body shape is not sent")
	var proxy := RecordingProxy.new()
	director._shared_opponent_proxy = proxy
	director._apply_shared_cue(payload)
	assert_eq((proxy.calls[0] as Array)[4], {}, "older/unshaped payloads pass an empty shape")
	_free_director(director)


func _tree_proxy() -> ProxyShell:
	var proxy := ProxyShell.new()
	proxy.body_generation = 7
	proxy._pose_received = true
	# The unit runner has no live SceneTree; the lane draws outside one.
	return proxy


func test_proxy_draws_lane_and_guard_cone_then_releases_them_on_strike() -> void:
	var proxy := _tree_proxy()
	var shape := LANE_SHAPE.duplicate()
	shape.merge(GUARD_SHAPE)
	assert_true(proxy.present_telegraph(1, 0.9, 1, shape))
	var lane := proxy.shape_lane()
	var cone := proxy.shape_guard_cone()
	assert_true(lane != null, "the lane is drawn from the host's shape")
	assert_true(cone != null, "the guard cone is drawn from the host's shape")
	if cone != null:
		assert_almost_eq(float(cone.get_meta("reach")), 3.2)
		assert_almost_eq(float(cone.get_meta("cone_degrees")), 70.0)
	if lane != null:
		assert_false(bool(lane.call("is_locked")), "tracks until the host's lock point")
		proxy._advance_shape_lane(0.5)
		assert_true(bool(lane.call("is_locked")), "locks once lane_lock_in_s has passed")
	assert_true(proxy.present_strike(2, 1))
	assert_true(proxy.shape_lane() == null, "the strike hands the lane off")
	assert_true(proxy.shape_guard_cone() == null, "the strike frees the guard cone")
	if lane != null and is_instance_valid(lane):
		assert_true(bool(lane.get("_released")), "a travelling lane is released to fade, as on the host")
	proxy.free()


func test_route_lane_is_kept_into_the_tell_and_freed_at_the_strike() -> void:
	var proxy := _tree_proxy()
	var shape := LANE_SHAPE.duplicate()
	shape["lane_travels"] = false
	shape["lane_lock_in_s"] = -1.0
	shape["route_s"] = 1.1
	assert_true(proxy.present_route(1, 1.1, shape))
	var lane := proxy.shape_lane()
	assert_true(lane != null, "the route cue draws the route line")
	shape.erase("route_s")
	assert_true(proxy.present_telegraph(2, 0.8, 1, shape))
	assert_true(proxy.shape_lane() == lane, "the tell keeps the route's lane rather than redrawing it")
	assert_eq(proxy.route_count, 1)
	assert_true(proxy.present_strike(3, 1))
	assert_true(proxy.shape_lane() == null)
	assert_true(lane.is_queued_for_deletion(), "a non-travelling route line ends with its tell")
	proxy.free()


func test_unset_or_malformed_shape_keys_draw_nothing_and_clear_stale_marks() -> void:
	var proxy := _tree_proxy()
	assert_true(proxy.present_telegraph(1, 0.9, 1, {}))
	assert_true(proxy.shape_lane() == null)
	assert_true(proxy.shape_guard_cone() == null)
	assert_true(proxy.present_telegraph(2, 0.9, 2, {"lane_length": NAN, "lane_half_width": 0.9,
		"guard_reach": "far"}))
	assert_true(proxy.shape_lane() == null, "a non-finite length draws no lane")
	assert_true(proxy.shape_guard_cone() == null, "a non-numeric reach draws no cone")
	var shape := LANE_SHAPE.duplicate()
	shape.merge(GUARD_SHAPE)
	assert_true(proxy.present_telegraph(3, 0.9, 3, shape))
	assert_true(proxy.present_telegraph(4, 0.9, 4, {}))
	assert_true(proxy.shape_lane() == null, "a later unshaped tell clears the old lane")
	assert_true(proxy.shape_guard_cone() == null, "a later unshaped tell clears the old cone")
	proxy.free()


func test_wild_body_reports_its_shape_and_announces_a_route_cue() -> void:
	var wild := WILD.new()
	wild._combat_cfg = {"route_cue_seconds": 1.1, "lunge": 6.0, "guard_stance": true,
		"range": 3.0, "cone_degrees": 80.0}
	var routes: Array = []
	var tells: Array = []
	wild.route_cue_started.connect(func(seconds: float) -> void: routes.append(seconds))
	wild.telegraph_started.connect(func(seconds: float) -> void: tells.append(seconds))
	assert_eq(wild.presentation_shape(), {}, "no shape outside a tell")
	wild._enter(AI.Intent.TELEGRAPH)
	assert_eq(routes.size(), 1, "a route cue is announced at telegraph entry")
	assert_eq(tells.size(), 0, "the tell proper waits for the route cue")
	if routes.size() == 1:
		assert_almost_eq(float(routes[0]), 1.1)
	var shape := wild.presentation_shape()
	assert_almost_eq(float(shape.get("lane_length", 0.0)), 6.0)
	assert_false(bool(shape.get("lane_travels", true)))
	assert_almost_eq(float(shape.get("guard_reach", 0.0)), 3.0)
	assert_almost_eq(float(shape.get("guard_cone", 0.0)), 80.0)
	assert_almost_eq(float(shape.get("route_s", 0.0)), 1.1)
	wild._combat_cfg = {}
	wild._enter(AI.Intent.RECOVER)
	wild._enter(AI.Intent.TELEGRAPH)
	assert_eq(routes.size(), 1, "an ordinary tell announces no route cue")
	assert_eq(tells.size(), 1, "an ordinary tell announces itself at entry")
	assert_eq(wild.presentation_shape(), {}, "an ordinary tell draws nothing")
	wild.free()


func test_a_new_tell_redraws_rather_than_reusing_an_earlier_tells_marks() -> void:
	# A catch pause ends a tell on the host with no strike cue to the guests.
	var proxy := _tree_proxy()
	var shape := LANE_SHAPE.duplicate()
	shape.merge(GUARD_SHAPE)
	assert_true(proxy.present_telegraph(1, 0.9, 1, shape))
	var old_lane := proxy.shape_lane()
	var old_cone := proxy.shape_guard_cone()
	proxy._advance_shape_lane(0.5)
	assert_true(bool(old_lane.call("is_locked")))
	var next := LANE_SHAPE.duplicate()
	next["lane_length"] = 5.5
	next["guard_reach"] = 2.0
	next["guard_cone"] = 40.0
	assert_true(proxy.present_telegraph(2, 0.9, 2, next))
	assert_true(proxy.shape_lane() != old_lane, "the next tell draws its own lane")
	assert_false(bool(proxy.shape_lane().call("is_locked")), "and it tracks again")
	assert_almost_eq(float(proxy.shape_lane().call("lane_length")), 5.5)
	assert_true(proxy.shape_guard_cone() != old_cone, "the next tell draws its own cone")
	assert_almost_eq(float(proxy.shape_guard_cone().get_meta("reach")), 2.0)
	var stale := proxy.shape_lane()
	assert_true(proxy.present_route(3, 1.1, next))
	assert_true(proxy.shape_lane() != stale, "a route cue always starts a fresh lane")
	proxy._clear_shape()
	assert_true(proxy.shape_lane() == null and proxy.shape_guard_cone() == null,
		"the catch-absorb path clears every mark")
	proxy.free()
