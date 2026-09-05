extends SceneTree

## Real shipping player, Fly tick and creature locomotion on real colliders.
## Isolated force/physics proof, not captain battle or final art acceptance.
const PLAYER := preload("res://scenes/player/player.tscn")
const CREATURE_BODY := preload("res://scenes/creatures/creature.tscn")
const CREATURE_MOTION := preload("res://scripts/creatures/creature_body.gd")
const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

class MotionProbe extends Node:
	var sample: Callable
	func _physics_process(_delta: float) -> void:
		sample.call()

class CreaturePilot extends Node:
	var body: CharacterBody3D
	func _physics_process(_delta: float) -> void:
		var stick := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		body.request_move(Vector3(stick.x, 0, stick.y))

class FixedView extends Node3D:
	func planar_basis() -> Basis:
		return Basis.IDENTITY

var failures: Array[String] = []
var bodies: Array[CharacterBody3D] = []
var finales: Array[Node3D] = []
var origins: Array[Vector3] = []
var samples: Array[Dictionary] = []
var ticks: Array[int] = [0, 0, 0]
var peaks: Array[float] = [0.0, 0.0, 0.0]
var proof_frames: Array[int] = [0, 0, 0]
var labels: Array[String] = ["ground player", "Fly player", "piloted creature"]
var world: Node3D
var game: Node
var flight: Node
var sample_enabled := true


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition and not failures.has(message):
		failures.append(message)
		push_error(message)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
	await process_frame


func _box(at: Vector3, size: Vector3) -> void:
	var solid := StaticBody3D.new()
	solid.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	solid.add_child(collider)
	world.add_child(solid)


func _record(body: CharacterBody3D, delta: float, index: int) -> void:
	var tick := Engine.get_physics_frames()
	_check(int(samples[index].get("tick", -1)) != tick, labels[index] + " modifier runs once per physics tick")
	samples[index] = {"tick": tick, "position": body.global_position, "motion": body.velocity * delta}
	ticks[index] += 1
	peaks[index] = maxf(peaks[index], Vector2(body.velocity.x, body.velocity.z).length())


func _observe_motion() -> void:
	if not sample_enabled:
		return
	for index in bodies.size():
		var body := bodies[index]
		if samples[index].is_empty() or body.is_on_wall():
			continue
		var moved := body.global_position - Vector3(samples[index].position)
		var expected: Vector3 = samples[index].motion
		_check(Vector2(moved.x, moved.z).distance_to(Vector2(expected.x, expected.z)) < 0.004,
			labels[index] + " displacement equals one slide, not two")
		proof_frames[index] += 1


func _run() -> void:
	await process_frame
	game = root.get_node("Game")
	game.set_process(false)
	game.saved_player_pose = {}
	game.current_realm = "cloudreach"
	game.progression.set_flag("fly_traversal_unlocked")
	game.party.add(SPECIES.spawn("galecrest"))
	game.party.set_active(game.party.size() - 1)
	world = Node3D.new()
	world.name = "EnvironmentVelocityFixture"
	root.add_child(world)
	current_scene = world
	var view := FixedView.new()
	view.name = "CameraRig"
	world.add_child(view)
	for index in 3:
		var origin := Vector3(index * 120.0, 0, 0)
		origins.append(origin)
		_box(origin + Vector3(0, -0.5, 0), Vector3(80, 1, 80))
		_box(origin + Vector3(0, 4, 8), Vector3(25, 8, 1))
		var body: CharacterBody3D
		if index < 2:
			body = PLAYER.instantiate()
		else:
			body = CREATURE_BODY.instantiate()
			body.set_script(CREATURE_MOTION)
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.4
			capsule.height = 1.8
			body.get_node("Collision").shape = capsule
			body.get_node("Collision").position.y = 0.9
		body.position = origin + Vector3(0, 0.1, 0)
		world.add_child(body)
		bodies.append(body)
		samples.append({})
		var flags := FLAGS.new()
		var data := FINALE.read_config()
		data.arena_origin = [origin.x, origin.y, origin.z]
		for flag: String in data.requires_flags:
			flags.set_flag(flag)
		var finale := FINALE.new()
		finale.setup(flags, Callable(), func() -> CharacterBody3D: return body,
			func() -> bool: return index == 2, Callable(), data)
		world.add_child(finale)
		finale.encounter_started("captain_veyra_storm_anchor")
		finale.set_process(false)
		finale.elapsed = 2.0
		finales.append(finale)
	await _frames(15)
	_check(bodies[0].is_on_floor() and bodies[2].is_on_floor(), "ground paths settle on real collision floors")
	# Deployment presentation/input is independently exercised by smoke_fly_traversal.
	# This fixture seeds deployed state to hold a precise, repeatable wind altitude.
	flight = bodies[1].fly_controller
	bodies[1].position.y = 3.0
	bodies[1].velocity = Vector3.ZERO
	flight._creature = game.party.active()
	flight.state = "glide"
	flight.config.sink_mps = 0.0
	var probe := MotionProbe.new()
	probe.process_physics_priority = 100
	probe.sample = _observe_motion
	world.add_child(probe)
	var pilot := CreaturePilot.new()
	pilot.body = bodies[2]
	pilot.process_physics_priority = -100
	world.add_child(pilot)
	for index in 3:
		_check(bodies[index].register_environment_velocity_modifier(&"summit_finale", finales[index], finales[index].apply_hazards), labels[index] + " registers production finale")
		bodies[index].register_environment_velocity_modifier(&"fixture_probe", world, _record.bind(index), 1000)
	await _frames(150)
	_check(flight.is_flying(), "Fly path remained deployed during forces")
	for index in 3:
		_check(peaks[index] >= 6.5 and peaks[index] <= 7.05, labels[index] + " wind reaches but never exceeds authored 7 m/s cap")
		_check(bodies[index].position.z > 3.5 and bodies[index].position.z < 7.2, labels[index] + " wind moves body and actual wall stops it")
		_check(ticks[index] >= 145 and proof_frames[index] > 20, labels[index] + " continuous single-slide measurement has sufficient frames")
	# Move to the authored lee pockets; no direct velocity edits after this reset.
	sample_enabled = false
	for index in 3:
		bodies[index].position = origins[index] + Vector3(-20, 3.0 if index == 1 else 0.1, -12)
		bodies[index].velocity = Vector3.ZERO
	await _frames(35)
	for index in 3:
		_check(Vector2(bodies[index].velocity.x, bodies[index].velocity.z).length() < 0.02, labels[index] + " authored lee pocket sheds drift")
		_check(Vector2(bodies[index].position.x - origins[index].x + 20, bodies[index].position.z + 12).length() < 1.2, labels[index] + " lee recovery stays inside shelter")
	var before_input: Array[Vector3] = []
	for body: CharacterBody3D in bodies:
		before_input.append(body.position)
	var press := InputEventAction.new()
	press.action = "move_right"
	press.pressed = true
	press.strength = 1.0
	Input.parse_input_event(press)
	await _frames(20)
	press = InputEventAction.new()
	press.action = "move_right"
	press.pressed = false
	Input.parse_input_event(press)
	for index in 3:
		_check(bodies[index].position.x > before_input[index].x + 0.2, labels[index] + " actual input still drives locomotion with force hook installed")
	# Owner tree-exit is automatic cleanup, even when bodies survive that owner.
	for finale: Node3D in finales:
		finale.queue_free()
	await _frames(3)
	for index in 3:
		_check(not bodies[index]._environment_velocity._entries.has(&"summit_finale"), labels[index] + " world-owned modifier clears on owner exit")
		bodies[index].clear_environment_velocity_modifier(&"fixture_probe")
		bodies[index].clear_environment_velocity_modifiers()
	world.queue_free()
	await process_frame
	await process_frame
	print("ENVIRONMENT VELOCITY %s: production ground/Fly/creature, capped wind, collision wall, lee, single-slide, owner cleanup" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
