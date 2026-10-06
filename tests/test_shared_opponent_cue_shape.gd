extends "res://tests/test_case.gd"

## F04/F10#2, guest-side lane and cue presentation (X05, #356 01:40 ruling).
## A host relays the optional ground-mark `shape` of its wild body's tell (the
## travelling lane, the guard cone, the route cue) so a guest's proxy draws
## what the host player sees. Presentation only: no hit or damage path here.

const AI := preload("res://scripts/combat/combat_ai.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
var _fixture_root: Node3D
const NATIVE_CASES := [
	"host_cue_payload_carries_the_body_shape_and_a_guest_applies_it",
	"host_route_cue_is_its_own_kind_with_a_fresh_serial",
	"a_payload_without_shape_still_presents_the_ordinary_telegraph",
	"proxy_draws_lane_and_guard_cone_then_releases_them_on_strike",
	"route_lane_is_kept_into_the_tell_and_freed_at_the_strike",
	"unset_or_malformed_shape_keys_draw_nothing_and_clear_stale_marks",
	"wild_body_reports_its_shape_and_announces_a_route_cue",
	"a_new_tell_redraws_rather_than_reusing_an_earlier_tells_marks",
	"pose_fits_one_packet_and_the_guest_keeps_the_cues_pattern_profile",
]

class WildShell extends "res://scripts/creatures/wild_creature.gd":
	func _ready() -> void:
		pass # Cue methods use an initialized tree; no creature rig is needed.


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
	_fixture_root.add_child(director)
	director.add_child(runtime)
	_fixture_root.add_child(body)
	return director


func _free_director(director: DirectorShell) -> void:
	var runtime: FakeRuntime = director.runtime
	runtime.wild.free()
	runtime.free()
	if director._shared_opponent_proxy != null:
		director._shared_opponent_proxy.free()
	director.free()


func _case_host_cue_payload_carries_the_body_shape_and_a_guest_applies_it() -> void:
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


func _case_host_route_cue_is_its_own_kind_with_a_fresh_serial() -> void:
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


func _case_a_payload_without_shape_still_presents_the_ordinary_telegraph() -> void:
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
	_mount_cue_body(proxy)
	return proxy


func _mount_cue_body(body: Node3D) -> void:
	# CreatureBody's required scene children initialize before the overridden
	# _ready. Empty meshes disclose this as cue geometry, not an art witness.
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	body.add_child(collision)
	var model := Node3D.new()
	model.name = "Model"
	body.add_child(model)
	for part: String in ["Body", "Head"]:
		var mesh := MeshInstance3D.new()
		mesh.name = part
		body.add_child(mesh)
	_fixture_root.add_child(body)


func _case_proxy_draws_lane_and_guard_cone_then_releases_them_on_strike() -> void:
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


func _case_route_lane_is_kept_into_the_tell_and_freed_at_the_strike() -> void:
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


func _case_unset_or_malformed_shape_keys_draw_nothing_and_clear_stale_marks() -> void:
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


func _case_wild_body_reports_its_shape_and_announces_a_route_cue() -> void:
	var wild := WildShell.new()
	_mount_cue_body(wild)
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


func _case_a_new_tell_redraws_rather_than_reusing_an_earlier_tells_marks() -> void:
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


func _case_pose_fits_one_packet_and_the_guest_keeps_the_cues_pattern_profile() -> void:
	# The 10 Hz pose is unreliable: over the 1392-byte ENet MTU it fragments,
	# and one lost fragment drops the pose (host log: 6992 bytes, CI #546).
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	profile["telegraph_shape"] = "lane"
	var shape := LANE_SHAPE.duplicate()
	shape["pattern"] = {"profile": profile, "origin": [0.0, 0.0, 0.0], "heading": [0.0, 0.0, 1.0], "marker": [0.0, 0.0, 4.0]}
	var director := _director(shape)
	var cue := director._shared_cue_payload("enc_1", "telegraph", 0.9)
	assert_eq(cue.shape.pattern.profile, profile, "the reliable cue carries the whole pattern profile")
	assert_true(var_to_bytes(cue).size() > 1392, "the fixture profile really exceeds one packet")
	var pose := director._shared_presentation_payload("enc_1")
	assert_false((pose.shape.pattern as Dictionary).has("profile"), "the unreliable pose carries no profile")
	assert_eq(pose.shape.pattern.marker, [0.0, 0.0, 4.0], "the pose keeps the moving marker")
	assert_true(var_to_bytes(pose).size() < 1200, "the pose fits one packet: %d bytes" % var_to_bytes(pose).size())
	var proxy := _tree_proxy()
	proxy.last_cue_serial = 4
	proxy.apply_pattern_shape(4, cue.shape)
	var moved: Dictionary = pose.shape.duplicate(true)
	moved.pattern.marker = [1.0, 0.0, 5.0]
	proxy.apply_pattern_shape(4, moved)
	assert_eq(proxy._pattern_geometry.get("profile"), profile, "a pose keeps this tell's cue profile")
	assert_eq(proxy._pattern_geometry.get("marker"), Vector3(1.0, 0.0, 5.0), "and moves its marker")
	proxy._pattern_geometry.clear()
	proxy.apply_pattern_shape(4, moved)
	assert_true(proxy._pattern_geometry.is_empty(), "a pose alone never invents a profile")
	proxy.free()
	_free_director(director)


func run_initialized_cases(tree: SceneTree) -> Dictionary:
	var completed: Array[String] = []
	for name: String in NATIVE_CASES:
		_fixture_root = Node3D.new()
		_fixture_root.process_mode = Node.PROCESS_MODE_DISABLED
		tree.root.add_child(_fixture_root)
		call("_case_" + name)
		completed.append(name)
		_fixture_root.free()
		_fixture_root = null
	return {"cases": completed, "assertions": assertion_count, "failures": failures}


func test_initialized_native_tree_preserves_all_shared_cue_assertions() -> void:
	# The unit runner executes during SceneTree._init. These production cue
	# methods need an initialized tree for transforms, marks and queued frees.
	var suffix := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://shared-cue-shape-" + suffix + ".gd"
	var log_path := ProjectSettings.globalize_path("user://shared-cue-shape-" + suffix + ".log")
	var runner := FileAccess.open(path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('''extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var test = load("res://tests/test_shared_opponent_cue_shape.gd").new()
	var result = test.run_initialized_cases(self)
	await process_frame
	print("SHARED_CUE_SHAPE_RESULT=" + JSON.stringify(result))
	quit(0 if result.failures.is_empty() and result.cases.size() == 9 and result.assertions == 74 else 1)
''')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_true(FileAccess.file_exists(log_path), "retain the real child engine log")
	if FileAccess.file_exists(log_path): combined += "\n" + FileAccess.get_file_as_string(log_path)
	var result: Dictionary = {}
	var result_count := 0
	for line: String in "\n".join(output).split("\n"):
		if line.begins_with("SHARED_CUE_SHAPE_RESULT="):
			result_count += 1
			var parsed: Variant = JSON.parse_string(line.trim_prefix("SHARED_CUE_SHAPE_RESULT="))
			if parsed is Dictionary: result = parsed
	assert_eq(result_count, 1, combined)
	assert_eq(result.get("cases", []), NATIVE_CASES, "all nine cases must run")
	assert_eq(result.get("assertions", 0), 74, "preserve every cue assertion")
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_false(combined.contains("ERROR:") or combined.contains("SCRIPT ERROR"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use") \
		or combined.contains("RID allocations") or combined.contains("RIDs of type"), combined)
	assert_eq(code, 0, combined)
