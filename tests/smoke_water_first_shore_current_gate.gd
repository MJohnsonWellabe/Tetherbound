extends SceneTree

## One disclosed initial position fixture in the First Shore current; movement
## afterwards uses ordinary forward action input. Existing lesson flag is posed
## to compare the same swimmer before/after opening, not to prove earning it.
const WATER := preload("res://scenes/world/water_archipelago.tscn")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	var world := WATER.instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 180000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await physics_frame
	if not world.shell_build_complete():
		push_error("First Shore current smoke: world build timeout")
		quit(1)
		return
	var docks := world.get_node("WaterDocks")
	_check(docks.get_node_or_null("first_shore_to_reedhaven_dockBarrier") == null,
		"the ineffective First Shore fence and collider are absent")
	var notice := docks.get_node("FirstShoreCurrentNotice/PaintedRouteNotice") as Label3D
	_check(notice.text.contains("STRONG CURRENT"), "closed route notice")
	for dock: Dictionary in world.config.docks:
		if str(dock.id) != "first_shore_to_reedhaven_dock" and not str(dock.unlock_flag).is_empty():
			_check(docks.get_node_or_null(str(dock.id) + "Barrier") != null, "other dock retained: " + str(dock.id))
	var player := world.get_node("Player") as CharacterBody3D
	var rig := world.get_node("CameraRig")
	# Authored sheltered-current centre. x=0 here falls on its priority/edge
	# transition over the direct route, where forward thrust can balance flow.
	player.global_position = Vector3(-9.6, 0.3, 220)
	player.velocity = Vector3.ZERO
	rig.yaw = PI
	for frame in 20:
		await physics_frame
	var start := player.global_position
	_forward(true)
	for frame in 180:
		await physics_frame
	_forward(false)
	var closed := player.global_position
	print("CLOSED forward attempt: ", start, " -> ", closed)
	_check(closed.z < start.z - 1.0, "existing adverse water pushes the forward swimmer back")
	game.world.flags.set_flag("water_swim_lesson_complete")
	for frame in 20:
		await physics_frame
	var opened_start := player.global_position
	_forward(true)
	for frame in 180:
		await physics_frame
	_forward(false)
	var opened := player.global_position
	print("OPEN forward attempt: ", opened_start, " -> ", opened)
	_check(opened.z > opened_start.z + 3.0, "the same swimmer makes forward progress after the existing flag opens it")
	_check(notice.text.contains("CHANNEL OPEN"), "existing notice persists and reports open route")
	print("First Shore current gate smoke: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func _forward(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = &"move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

func _check(condition: bool, message: String) -> void:
	print("PASS: " if condition else "FAIL: ", message)
	if not condition:
		failures.append(message)
