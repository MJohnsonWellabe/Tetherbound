extends "res://tests/test_case.gd"
## `combat_run` / `creature_recall` is an EDGE (`is_action_just_pressed`). A
## disengage pressed on a tick whose input the manager does not read -- hitstop
## after a hit, the opening `input_guard`, a burst awaiting the host -- used to
## be lost outright: a creature under steady attack made leaving a wild fight a
## lottery (smoke_net_shared_wild_fight: the host's single Run, pressed while
## the opponent kept striking, never withdrew it). The press is now kept for
## `flow.flee_buffer` seconds and honoured when input is read again.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TICK := 1.0 / 60.0

class Fighter extends Node3D:
	signal strike_ready
	signal telegraph_started(seconds: float)
	var instance: RefCounted
	var arena: Node
	var engaged := false
	var target: Node3D
	var velocity := Vector3.ZERO
	func face_towards(at: Vector3) -> void:
		rotation.y = atan2(at.x - global_position.x, at.z - global_position.z)
	func place_on_ground(at: Vector3) -> bool:
		global_position = at
		return true
	func set_engaged(value: bool, other: Node3D = null) -> void:
		engaged = value
		target = other
	func centre() -> Vector3:
		return global_position + Vector3.UP

class ThrowAdapter extends Node:
	var busy := false
	func arm(_player: Node3D, _enemy: Node3D, _camera: Node) -> void:
		pass
	func disarm() -> void:
		pass
	func is_busy() -> bool:
		return busy
	func is_aiming() -> bool:
		return busy

class Manager extends "res://scripts/combat/combat_manager.gd":
	## The disengage EDGE for this tick. Injected `Input` edges are not
	## observable from a deferred call, so the edge is the test's to set.
	var run_edge := false
	func _flee_pressed() -> bool:
		return run_edge
	func _ready() -> void:
		set_physics_process(false)
		_throw = ThrowAdapter.new()
		add_child(_throw)
	func _open_arena() -> void:
		_arena = Node3D.new()
		add_child(_arena)
	func _arena_bounds(_at: Vector3) -> float:
		return -1.0
	func _take_camera() -> void:
		pass
	func _release_camera() -> void:
		pass
	func _stand_the_trainer_aside(_forward: Vector3) -> void:
		pass
	func _update_combat_camera_framing(_delta: float) -> void:
		pass
	func _update_ally_occlusion_fade(_delta: float) -> void:
		pass
	func _drive_player_creature() -> void:
		pass

var fixture: Node3D
var manager: Manager

func _setup_fixture() -> void:
	fixture = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	var player := Fighter.new()
	var enemy := Fighter.new()
	var ally := Fighter.new()
	manager = Manager.new()
	for node in [player, enemy, ally, manager]:
		fixture.add_child(node)
	enemy.position = Vector3(10, 0, 0)
	enemy.instance = SPECIES.spawn("terrapup")
	ally.instance = SPECIES.spawn("terrapup")
	var party: Array[RefCounted] = [ally.instance]
	assert_true(manager.begin(player, enemy, ally, party), "an ordinary wild fight begins")

func _free_fixture() -> void:
	fixture.free()

## One press edge, true for exactly one tick, as `is_action_just_pressed` is.
func _press_during(tick: Callable) -> void:
	manager.run_edge = true
	tick.call()
	manager.run_edge = false

func _fled() -> bool:
	return manager.state == manager.State.RESOLVING and manager._outcome == "fled"

func _case_a_run_pressed_during_hitstop_is_honoured_after_it() -> void:
	manager._input_guard = 0.0
	manager._hitstop_left = 0.08
	_press_during(func() -> void: manager._tick_active(TICK))
	assert_false(_fled(), "nothing resolves while the fight is frozen for a hit")
	for _i in 6:
		if _fled():
			break
		manager._tick_active(TICK)
	assert_true(_fled(), "the Run pressed during hitstop withdraws once the freeze ends")

func _case_a_run_pressed_during_the_opening_guard_survives_it() -> void:
	assert_true(manager._input_guard > 0.0, "a new fight opens with its input guard up")
	_press_during(func() -> void: manager._tick_active(TICK))
	for _i in 30:
		if _fled():
			break
		manager._tick_active(TICK)
	assert_true(_fled(), "the Run pressed inside the guard is honoured when it drops")

func _case_a_stale_run_expires() -> void:
	manager._input_guard = 0.0
	manager._hitstop_left = 5.0
	_press_during(func() -> void: manager._tick_active(TICK))
	for _i in 60:
		manager._tick_active(TICK)
	manager._hitstop_left = 0.0
	manager._tick_active(TICK)
	assert_false(_fled(), "a Run older than flow.flee_buffer is not acted on seconds later")

func _case_a_run_while_aiming_is_the_aims_not_the_fights() -> void:
	manager._input_guard = 0.2
	(manager._throw as ThrowAdapter).busy = true
	_press_during(func() -> void: manager._tick_active(TICK))
	(manager._throw as ThrowAdapter).busy = false
	for _i in 30:
		manager._tick_active(TICK)
	assert_false(_fled(), "Run cancels an aim; it is not also buffered into a withdrawal")

const CASES := ["_case_a_run_pressed_during_hitstop_is_honoured_after_it",
	"_case_a_run_pressed_during_the_opening_guard_survives_it", "_case_a_stale_run_expires",
	"_case_a_run_while_aiming_is_the_aims_not_the_fights"]

func test_flee_buffer_in_an_initialized_tree() -> void:
	# run_tests runs in SceneTree._init before Engine.get_main_loop exists; the
	# fight needs a live tree, so the cases run in an isolated child process
	# (test_combat_realm_owned_begin.gd's convention).
	var runner_path := "user://combat-flee-buffer-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_combat_flee_buffer.gd").new()\n\tfor method in test.CASES:\n\t\ttest._setup_fixture()\n\t\ttest.call(method)\n\t\ttest._free_fixture()\n\tprint("FLEE_BUFFER_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	runner.close()
	var output: Array = []
	var log_path := ProjectSettings.globalize_path("user://combat-flee-buffer-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", ProjectSettings.globalize_path(runner_path), "--log-file", log_path], output, true)
	var text := "\n".join(output)
	var marker := text.find("FLEE_BUFFER_RESULT=")
	assert_true(marker >= 0, "the child run reported a result: %s" % text.right(600))
	if marker < 0:
		return
	var parsed: Variant = JSON.parse_string(text.substr(marker + "FLEE_BUFFER_RESULT=".length()).get_slice("\n", 0))
	var result: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	assert_eq(result.get("failures", ["unparsed"]), [], "every flee-buffer case passes")
	assert_true(int(result.get("assertions", 0)) >= 8, "the cases asserted (%s)" % str(result.get("assertions")))
	assert_eq(code, 0, "the child exited cleanly")
