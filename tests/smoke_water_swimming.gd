extends SceneTree

## Production Water scene/body/input smoke. The initial fixture starts on the
## lesson's west safe landing; all subsequent movement uses real action input.
## Zero stamina is an explicit exhaustion fixture. Combat pause exercises the
## production locomotion handoff, not a complete encounter or victory path.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")

var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var swimming: Node
var assertions := 0
var finished := false
var observed_swim_distance := 0.0
var lesson_distance := 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(180.0).timeout.connect(func() -> void:
		if not finished:
			_fail("180 second watchdog expired"))
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_water_swimming_fixture")
	# Explicit realm fixture: this does not prove key spending or gate traversal.
	game.current_realm = "water"
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 600:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _expect(bool(world.call("shell_build_complete")), "Water shell failed to build"):
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	if not _expect(swimming != null, "production player has no SwimController"):
		return
	var config: Dictionary = world.get("config")
	var lesson: Dictionary = config.swim_lesson
	var west := _anchor(config, str(lesson.start_anchor))
	var east := _anchor(config, str(lesson.end_anchor))
	if not _expect(west.is_finite() and east.is_finite(), "lesson safe anchors missing"):
		return
	# The only position write: set the test-owned starting fixture on real terrain.
	west.y = float(world.call("ground_height_at", west.x, west.z)) + 0.15
	if not _expect(is_finite(west.y), "west landing has no baked Terrain3D height"):
		return
	player.global_position = west
	player.velocity = Vector3.ZERO
	await _frames(45)
	if not _expect(player.is_on_floor() and not swimming.is_swimming(), "initial safe landing did not settle dry"):
		return
	var vitals: RefCounted = player.get("vitals")
	var first := _vector(lesson.surface_polyline[0])
	var last := _vector(lesson.surface_polyline[-1])
	if not await _move_to(first, 0.4, 900):
		return
	if not _expect(swimming.is_swimming(), "walking off lesson beach did not enter swimming"):
		return
	var crossing_health: float = vitals.health
	var crossing_stamina: float = vitals.stamina
	observed_swim_distance = 0.0
	if not await _move_to(last, 0.4, 1500):
		return
	lesson_distance = observed_swim_distance
	if not _expect(observed_swim_distance >= 58.0, "actual lesson swim shorter than 58m: %.3f" % observed_swim_distance):
		return
	if not _expect(float(vitals.stamina) < crossing_stamina, "60m swimming did not spend real player stamina"):
		return
	if not _expect(float(vitals.stamina) / float(vitals.max_stamina) >= 0.15, "level-zero lesson left under 15 percent stamina"):
		return
	if not _expect(is_equal_approx(float(vitals.health), crossing_health), "normal lesson crossing damaged health"):
		return
	# Exhaustion fixture changes resources, never the controller or movement state.
	vitals.stamina = 0.0
	var health_before_drowning: float = vitals.health
	await _frames(60)
	if not _expect(float(vitals.health) < health_before_drowning and float(vitals.health) > 0.0,
		"zero stamina failed gradual drowning: before=%s after=%s" % [health_before_drowning, vitals.health]):
		return
	if not _expect(bool(swimming.snapshot().drowning), "drowning feedback state was not set"):
		return
	player.call("set_locomotion_enabled", false)
	await _frames(2)
	var paused_health: float = vitals.health
	var paused_stamina: float = vitals.stamina
	await _frames(120)
	if not _expect(int(swimming.snapshot().mode) == 3, "combat locomotion handoff did not pause swimming"):
		return
	if not _expect(is_equal_approx(float(vitals.health), paused_health) and is_equal_approx(float(vitals.stamina), paused_stamina),
		"combat pause changed health or stamina"):
		return
	player.call("set_locomotion_enabled", true)
	if not await _move_to(east, 0.8, 900):
		return
	await _frames(10)
	if not _expect(not swimming.is_swimming() and not bool(swimming.snapshot().drowning), "reaching dry landing did not stop drowning"):
		return
	var landed_health: float = vitals.health
	await _frames(120)
	if not _expect(is_equal_approx(float(vitals.health), landed_health), "health continued draining on safe land"):
		return
	finished = true
	print("WATER SWIMMING OK assertions=%d actual_lesson_swim_m=%.3f final_health=%.3f" % [assertions, lesson_distance, vitals.health])
	quit(0)


func _move_to(target: Vector3, tolerance: float, frame_limit: int) -> bool:
	var previous := player.global_position
	for _frame in frame_limit:
		var offset := target - player.global_position
		offset.y = 0.0
		if offset.length() <= tolerance:
			_action(false)
			await _frames(2)
			return true
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
		if swimming.is_swimming():
			var moved := player.global_position - previous
			moved.y = 0.0
			observed_swim_distance += moved.length()
		previous = player.global_position
		if float(player.get("vitals").health) <= 0.0:
			return _fail("died while moving toward %s from %s" % [target, player.global_position])
	return _fail("movement timed out target=%s actual=%s velocity=%s aquatic=%s" % [target, player.global_position, player.velocity, swimming.snapshot()])


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _anchor(config: Dictionary, id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.id) == id:
			return _vector(anchor.safe_position)
	return Vector3.INF


func _vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _expect(condition: bool, message: String) -> bool:
	assertions += 1
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	_action(false)
	finished = true
	push_error("WATER SWIMMING: " + message)
	quit(1)
	return false
