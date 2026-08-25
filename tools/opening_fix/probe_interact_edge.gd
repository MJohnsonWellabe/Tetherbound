extends SceneTree
## Developer-lane probe (branch ralph/OPENING-STARTER-FOCUS). NOT Gate F tooling.
##
## Question: does a synthetic `interact` press injected the way
## tools/gate_f/operator_harness.gd injects it ever satisfy
## `Input.is_action_just_pressed("interact")` inside a `_physics_process`?
##
## interaction_arbiter.gd:271-275 polls exactly there. Every menu in the game
## polls from `_process` instead, which is why the harness's own idle-frame
## press works for menus and may not work for the world's interact verb.
##
## Runs on the bare title/empty tree -- no world needed. The question is about
## Input frame-stamping, not about the scene.

var _phys_hits := 0
var _idle_hits := 0
var _watcher: Node = null

func _initialize() -> void:
	_watcher = _Watcher.new()
	_watcher.owner_tree = self
	root.add_child(_watcher)
	_run()

func _run() -> void:
	await process_frame
	print("=== probe: interact edge visibility ===")

	# Method A: exactly what operator_harness.gd::_edge + _inject do.
	await _method_a()
	print("A  parse_input_event, idle frame held, then physics frames:")
	print("   physics-context just_pressed hits: %d" % _watcher.phys_hits)
	print("   idle-context    just_pressed hits: %d" % _watcher.idle_hits)

	_watcher.reset()

	# Method B: the same, plus Input.action_press/release alongside.
	await _method_b()
	print("B  parse_input_event + action_press, same frame shape:")
	print("   physics-context just_pressed hits: %d" % _watcher.phys_hits)
	print("   idle-context    just_pressed hits: %d" % _watcher.idle_hits)

	_watcher.reset()

	# Method C: action_press issued immediately after a physics_frame await,
	# released after the next one.
	await _method_c()
	print("C  action_press right after `await physics_frame`:")
	print("   physics-context just_pressed hits: %d" % _watcher.phys_hits)
	print("   idle-context    just_pressed hits: %d" % _watcher.idle_hits)

	quit()

func _joy_event(pressed: bool) -> InputEventJoypadButton:
	var b := InputEventJoypadButton.new()
	b.button_index = 2  # `interact`'s pad binding in project.godot
	b.pressed = pressed
	return b

func _method_a() -> void:
	Input.parse_input_event(_joy_event(true))
	await process_frame
	await physics_frame
	Input.parse_input_event(_joy_event(false))
	await process_frame
	await physics_frame

func _method_b() -> void:
	Input.parse_input_event(_joy_event(true))
	Input.action_press(&"interact", 1.0)
	await process_frame
	await physics_frame
	Input.parse_input_event(_joy_event(false))
	Input.action_release(&"interact")
	await process_frame
	await physics_frame

func _method_c() -> void:
	await physics_frame
	Input.action_press(&"interact", 1.0)
	await physics_frame
	Input.action_release(&"interact")
	await physics_frame


class _Watcher extends Node:
	var owner_tree: SceneTree = null
	var phys_hits := 0
	var idle_hits := 0

	func reset() -> void:
		phys_hits = 0
		idle_hits = 0

	func _ready() -> void:
		set_physics_process(true)
		set_process(true)

	func _physics_process(_d: float) -> void:
		if Input.is_action_just_pressed("interact"):
			phys_hits += 1

	func _process(_d: float) -> void:
		if Input.is_action_just_pressed("interact"):
			idle_hits += 1
