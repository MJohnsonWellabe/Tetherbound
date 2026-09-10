extends SceneTree

## Rendered synthetic proof. Actual shared admission/support and native roaming;
## the candidate overrides only admission and its existing clearance predicate.
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const RIG := preload("res://scripts/player/camera_rig.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const OUTPUT := "res://shots/creature-ribbon/round-measurement-corrected-20260909"

class Ribbon extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 0.0 if absf(x) < 6.0 and absf(z) < 30.0 else NAN
	func ground_height_near(at: Vector3) -> float:
		return ground_height_at(at.x, at.z)

class ProbeDirector extends "res://scripts/combat/cloudreach_encounter_director.gd":
	var candidate := false
	var admission_receipts: Array[Dictionary] = []
	func _ready() -> void:
		pass
	func _physics_process(_delta: float) -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _find_wild_spawn(wild: Node3D, requested: Vector3, centre: Vector3) -> Vector3:
		if not candidate:
			return super(wild, requested, centre)
		for offset in [0.0, 8.0, -8.0, 16.0, -16.0]:
			var proposed := requested + Vector3(0, 0, offset)
			var safe := super(wild, proposed, centre)
			if safe.is_finite() and _presented_clear(wild, safe, wild.rotation.y):
				admission_receipts.append({"requested": requested, "accepted": safe})
				return safe
		return Vector3.INF
	func _wild_destination_supported(at: Vector3, wild: Node3D) -> bool:
		if not super(at, wild):
			return false
		if not candidate:
			return true
		var direction := at - wild.global_position
		var heading := atan2(direction.x, direction.z) if direction.length() > 0.01 else wild.rotation.y
		# Check the entire turn and short translation, not just a future endpoint.
		var turn := wrapf(heading - wild.rotation.y, -PI, PI)
		for i in 13:
			if not _presented_clear(wild, wild.global_position, wild.rotation.y + turn * i / 12.0):
				return false
		var steps := maxi(1, ceili(direction.length() / 0.5))
		for i in steps + 1:
			if not _presented_clear(wild, wild.global_position.lerp(at, float(i) / steps), heading):
				return false
		return true
	func _presented_clear(wild: Node3D, at: Vector3, heading: float) -> bool:
		var rectangle := envelope(wild, at, heading)
		# This fixture reserves the central two metres as the trainer's route.
		for point in rectangle:
			if point.x < 1.0 or point.x > 6.0 or absf(point.y) > 30.0:
				return false
		for other: Node3D in _wild_creatures:
			if other != wild and is_instance_valid(other) \
					and overlaps(rectangle, envelope(other, other.global_position, other.rotation.y), 0.5):
				return false
		return true
	static func envelope(body: Node3D, at: Vector3, heading: float) -> Array[Vector2]:
		var model: Node3D = body.get_node("Model")
		var bounds: AABB = model.transform * preload("res://scripts/characters/render_bounds.gd").measure(model)
		var result: Array[Vector2] = []
		for uv in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
			var local := Vector3(bounds.position.x + bounds.size.x * uv.x, 0, bounds.position.z + bounds.size.z * uv.y)
			var world_point := at + Basis(Vector3.UP, heading) * local
			result.append(Vector2(world_point.x, world_point.z))
		return result
	static func overlaps(a: Array[Vector2], b: Array[Vector2], gap: float = 0.0) -> bool:
		for polygon in [a, b]:
			for i in 2:
				var edge: Vector2 = polygon[i + 1] - polygon[i]
				var axis := Vector2(-edge.y, edge.x).normalized()
				var low_a := INF
				var high_a := -INF
				var low_b := INF
				var high_b := -INF
				for point in a:
					low_a = minf(low_a, point.dot(axis))
					high_a = maxf(high_a, point.dot(axis))
				for point in b:
					low_b = minf(low_b, point.dot(axis))
					high_b = maxf(high_b, point.dot(axis))
				if high_a + gap <= low_b or high_b + gap <= low_a:
					return false
		return true

var failures: Array[String] = []
var fixture: Ribbon
var player: Node3D
var rig: Node3D
var director: ProbeDirector

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(60.0, true, false, true).timeout.connect(func() -> void:
		push_error("Ribbon proof 60 second watchdog")
		quit(1))
	if DisplayServer.get_name() == "headless":
		push_error("Ribbon proof requires Compatibility rendering")
		quit(1)
		return
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUTPUT)):
		push_error("Refusing existing ribbon output")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for candidate in [false, true]:
		if not await _case(candidate):
			break
	print("RIBBON_PROOF_RESULT ", JSON.stringify({"failures": failures}))
	quit(0 if failures.is_empty() else 1)

func _case(candidate: bool) -> bool:
	seed(740)
	fixture = Ribbon.new()
	root.add_child(fixture)
	current_scene = fixture
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(12, 0.2, 60)
	collision.shape = shape
	floor.add_child(collision)
	floor.position.y = -0.1
	fixture.add_child(floor)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("657361")
	mesh.material_override = mat
	floor.add_child(mesh)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.shadow_enabled = true
	fixture.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("8097a2")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	fixture.add_child(environment)
	rig = RIG.new()
	rig.name = "CameraRig"
	var rig_camera := Camera3D.new()
	rig_camera.name = "Camera3D"
	rig.add_child(rig_camera)
	fixture.add_child(rig)
	player = PLAYER.instantiate()
	player.position = Vector3(0, 0.1, -20)
	fixture.add_child(player)
	rig.set_process(false)
	rig.set_physics_process(false)
	var camera := Camera3D.new()
	camera.position = Vector3(-18, 13, 18)
	fixture.add_child(camera)
	camera.look_at(Vector3(2, 2, 0))
	camera.make_current()
	director = ProbeDirector.new()
	director.realm_world = fixture
	director._player = player
	director.candidate = candidate
	fixture.add_child(director)
	for i in 3:
		await physics_frame
	var bodies: Array[Node3D] = []
	var capsules: Array[Vector2] = []
	var initial_scales: Array[Vector3] = []
	var max_scale_deviation := 0.0
	var exact_deviation_logged := false
	for i in 2:
		var body := director.spawn_wild("water_cragclaw", Vector3(3.5, 0, 0),
			{"site_anchor": Vector3(3.5, 0, 0), "aggressive": false, "wander_radius": 3.0})
		if body == null:
			return await _fail("Admission removed a required body", candidate)
		director.keep_trainer_corridor_clear(body, player)
		body.get("_rng").seed = 740 + i
		body.set("_pause_left", 1.5)
		bodies.append(body)
		var capsule: CapsuleShape3D = body.get_node("Collision").shape
		capsules.append(Vector2(capsule.radius, capsule.height))
		initial_scales.append(body.scale)
	var label := "B" if candidate else "A"
	var initial: Array[Vector3] = [bodies[0].global_position, bodies[1].global_position]
	print("RIBBON_INITIAL ", label, " poses=", initial,
		" overlap=", _overlap(bodies), " admitted=", director.admission_receipts,
		" capsules=", capsules, " envelopes=", [ProbeDirector.envelope(bodies[0], initial[0], 0), ProbeDirector.envelope(bodies[1], initial[1], 0)])
	print("RIBBON_SETUP yaws=", [bodies[0].rotation.y, bodies[1].rotation.y], " seed=740 pause_left=1.5")
	print("RIBBON_INITIAL_SCALES ", initial_scales)
	if not candidate and not _overlap(bodies):
		return await _fail("Negative control did not expose visible-envelope crowding", candidate)
	if candidate and (_overlap(bodies) or not _route_clear(bodies)):
		return await _fail("Candidate initial presentation is not separated with clear route", candidate)
	await _capture(label + "_initial")
	var nav := NAV.new(self, player, rig, _stick)
	var started := Time.get_ticks_msec()
	var travelled := [0.0, 0.0]
	var excursion := [0.0, 0.0]
	var last: Array[Vector3] = initial.duplicate()
	while Time.get_ticks_msec() - started < 15000:
		if player.global_position.z < 20:
			nav.step(Vector3(0, 0, 20))
		else:
			_stick(0, 0)
		await physics_frame
		for i in 2:
			var capsule: CapsuleShape3D = bodies[i].get_node("Collision").shape
			var scale_delta: Vector3 = (bodies[i].scale - initial_scales[i]).abs()
			max_scale_deviation = maxf(max_scale_deviation, maxf(scale_delta.x, maxf(scale_delta.y, scale_delta.z)))
			var capsule_delta := maxf(absf(capsule.radius - capsules[i].x), absf(capsule.height - capsules[i].y))
			if not exact_deviation_logged and max_scale_deviation > 0.0:
				exact_deviation_logged = true
				print("RIBBON_FLOAT_DEVIATION max_scale=%.12f capsule=%.12f yaw=%.12f" % [max_scale_deviation, capsule_delta, bodies[i].rotation.y])
			if max_scale_deviation > 0.00001 or capsule_delta > 0.00001:
				print("RIBBON_INVARIANT body=", i, " elapsed=", Time.get_ticks_msec() - started,
					" capsule_before=", capsules[i], " radius_now=%.12f height_now=%.12f" % [capsule.radius, capsule.height],
					" scale_now=%.12f,%.12f,%.12f" % [bodies[i].scale.x, bodies[i].scale.y, bodies[i].scale.z],
					" yaw=%.12f" % bodies[i].rotation.y)
				return await _fail("Body scale or capsule changed", candidate)
			travelled[i] += bodies[i].global_position.distance_to(last[i])
			excursion[i] = maxf(excursion[i], Vector2(bodies[i].global_position.x - initial[i].x, bodies[i].global_position.z - initial[i].z).length())
			last[i] = bodies[i].global_position
		if candidate and (_overlap(bodies) or not _route_clear(bodies)):
			print("RIBBON_VIOLATION elapsed=", Time.get_ticks_msec() - started,
				" player=", player.global_position, " bodies=", last,
				" yaws=", [bodies[0].rotation.y, bodies[1].rotation.y])
			return await _fail("Candidate native motion violated presented separation or route clearance", candidate)
	_stick(0, 0)
	await _capture(label + "_final")
	print("RIBBON_FINAL ", label, " travel=", travelled, " horizontal_excursion=", excursion, " player=", player.global_position, " max_scale_deviation=%.12f" % max_scale_deviation)
	for body in bodies:
		if not body.is_on_floor():
			return await _fail("Required actor lost ground support", candidate)
	if candidate and (excursion[0] <= 0.5 or excursion[1] <= 0.5 or player.global_position.z < 18):
		return await _fail("Separated candidate failed sustained movement or trainer crossing", candidate)
	fixture.queue_free()
	await process_frame
	return true

func _route_clear(bodies: Array[Node3D]) -> bool:
	for body in bodies:
		for point in ProbeDirector.envelope(body, body.global_position, body.rotation.y):
			if point.x < 1 or point.x > 6 or absf(point.y) > 30:
				return false
	return true

func _overlap(bodies: Array[Node3D]) -> bool:
	return ProbeDirector.overlaps(ProbeDirector.envelope(bodies[0], bodies[0].global_position, bodies[0].rotation.y),
		ProbeDirector.envelope(bodies[1], bodies[1].global_position, bodies[1].rotation.y), 0.5)

func _stick(x: float, y: float) -> void:
	for pair in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, y]]:
		var event := InputEventJoypadMotion.new()
		event.axis = int(pair[0])
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUTPUT + "/" + label + ".png")
	if error != OK:
		failures.append("Capture failed: " + label + " error=" + str(error))

func _fail(reason: String, candidate: bool) -> bool:
	_stick(0, 0)
	failures.append(reason)
	print("FAIL: ", reason)
	await _capture("B_failure" if candidate else "A_failure")
	return false
