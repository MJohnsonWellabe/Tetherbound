extends SceneTree

## Native API/physics instrumentation fixture, NOT a campaign coverage claim.
const OBSERVER := preload("res://tests/helpers/four_biome_road_coverage_observer.gd")
const CREATURE := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
var checks := 0
var failures: Array[String] = []

class CameraRig extends Node3D:
	var yaw := 0.0
	var pitch := 0.0
	func planar_basis() -> Basis: return Basis.IDENTITY

class Population extends Node:
	var bodies: Array = []
	func wild_creatures() -> Array: return bodies

func _initialize() -> void:
	_run.call_deferred()

func _check(passed: bool, label: String) -> void:
	checks += 1
	if not passed: failures.append(label)
	print("PASS: " if passed else "FAIL: ", label)

func _box(world: Node3D, label: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	world.add_child(body)
	body.position = at
	return body

func _axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_Y
	event.axis_value = value
	Input.parse_input_event(event)

func _sample(observer: RefCounted, body: Node3D, player: CharacterBody3D, camera: Camera3D) -> Dictionary:
	return observer._body_sample(body, player, camera, player.global_position,
		-camera.global_basis.z, camera.get_viewport().get_visible_rect().size)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var world := Node3D.new()
	world.name = "NativeCoverageFixture"
	root.add_child(world)
	current_scene = world
	_box(world, "Floor", Vector3(0, -0.1, -15), Vector3(100, 0.2, 100))
	var rig := CameraRig.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var camera := Camera3D.new()
	rig.add_child(camera)
	camera.position = Vector3(0, 3, 6)
	camera.fov = 70
	camera.look_at(Vector3(0, 1, -12))
	camera.make_current()
	var player: CharacterBody3D = PLAYER.instantiate()
	player.name = "Player"
	player.camera_rig_path = NodePath("../CameraRig")
	player.position = Vector3(0, 0.2, 0)
	world.add_child(player)
	var director := Population.new()
	director.name = "EncounterDirector"
	world.add_child(director)
	var body: CharacterBody3D = CREATURE.instantiate()
	body.set_script(WILD)
	body.name = "ActualWildBramblebun"
	world.add_child(body)
	body.populate("bramblebun", player)
	body.position = Vector3(0, 0, -12)
	body.set_physics_process(false)
	director.bodies.append(body)
	for frame in 12: await physics_frame
	var observer := OBSERVER.new()
	_check(player.is_on_floor(), "Actual packed player is supported by native floor")
	_check(OBSERVER.eligible_body(body), "Actual packed living wild satisfies eligibility API")
	var clear := _sample(observer, body, player, camera)
	print("CLEAR sample=", clear)
	_check(clear.credited and clear.framed and clear.los.clear and clear.los.checked,
		"Actual camera projection and physics ray credit clear forward body")
	_check(float(clear.height_m) == body.body_height() and float(clear.projected_height_px_at_720p) >= 15,
		"Actual species height meets unchanged projected-height threshold")
	var blocker := _box(world, "ActualOpaqueBlocker", Vector3(0, 2, -3), Vector3(4, 5, 0.6))
	for frame in 3: await physics_frame
	var occluded := _sample(observer, body, player, camera)
	_check(not occluded.credited and occluded.los.checked and not occluded.los.clear \
		and str(occluded.los.blocker).ends_with("ActualOpaqueBlocker"), "Actual collider occludes centre ray and prevents credit")
	blocker.free()
	body.position = Vector3(0, 0, 20)
	for frame in 3: await physics_frame
	var behind := _sample(observer, body, player, camera)
	_check(not behind.forward and not behind.credited and not behind.los.checked,
		"Body behind actual camera/player fails forward-half-plane credit")
	body.position = Vector3(40, 0, -12)
	for frame in 3: await physics_frame
	var side := _sample(observer, body, player, camera)
	print("OFFSCREEN policy diagnostic=", side)
	_check(side.forward and not side.framed and not side.credited,
		"Forward but off-frustum body cannot count as visible to actual camera")
	body.position = Vector3(0, 0, -20)
	body.instance.take_damage(float(body.instance.max_hp))
	_check(not OBSERVER.eligible_body(body), "Actual fainted CreatureInstance is ineligible")
	body.instance.heal_fully() # Explicit fixture restoration, no campaign state.
	body.hide()
	_check(not OBSERVER.eligible_body(body), "Hidden actual body is ineligible")
	body.show()
	var path := "user://native_road_coverage_%d.jsonl" % Time.get_ticks_usec()
	_check(observer.start(self, path, func(_scene: Node3D, _player: CharacterBody3D) -> bool: return true),
		"Observer starts on a unique scratch evidence path")
	_check(physics_frame.is_connected(observer._observe), "Observer registers its actual physics-frame callback")
	for frame in 3: await physics_frame
	_axis(-1)
	for frame in 240:
		await physics_frame
		if float(observer.result().observed_travel_m) >= 11.0: break
	_axis(0)
	for frame in 8: await physics_frame
	var summary: Dictionary = observer.stop()
	_check(int(summary.samples) >= 1 and float(summary.observed_travel_m) >= 10,
		"Actual player input crosses unchanged 10m spacing and records native sample")
	_check(summary.failures.is_empty() and not summary.complete_coverage,
		"Native observation remains explicitly incomplete coverage")
	_check(not physics_frame.is_connected(observer._observe) and observer._file == null,
		"Stop disconnects callback and closes evidence file")
	var before := FileAccess.get_file_as_string(path)
	var records: Array = []
	for line: String in before.split("\n", false): records.append(JSON.parse_string(line))
	_check(not records.is_empty() and records.front().kind == "contract" and records.back().kind == "summary",
		"Evidence file contains contract, observations and flushed terminal summary")
	var native_samples := 0
	for row: Dictionary in records:
		if str(row.kind) == "sample":
			native_samples += 1
			_check(row.context == "outdoor" and row.bodies.size() == 1 and row.bodies[0].body_id == body.get_instance_id(),
				"Written sample preserves actual body identity and classifier result")
	_check(native_samples == int(summary.samples), "Written native sample count equals returned summary")
	observer.stop()
	_check(FileAccess.get_file_as_string(path) == before, "Repeated stop cannot append duplicate evidence")
	var refusing := OBSERVER.new()
	_check(not refusing.start(self, path) and FileAccess.get_file_as_string(path) == before,
		"Existing evidence path is refused without overwriting")
	print("EVIDENCE path=", ProjectSettings.globalize_path(path))
	print("live road observer checks=", checks, " failures=", failures)
	world.free()
	quit(0 if failures.is_empty() else 1)
