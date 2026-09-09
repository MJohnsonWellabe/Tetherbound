extends Node

## Test-driver observer only. Production free-aim throws remain legal.
var throw: Node
var event_for: Callable
var observed := false
var invalid := false
var cancel_sent := false
var cancelled := false
var commit_frame := -1
var cancel_frame := -1
var commit_process := -1
var cancel_process := -1
var _cancel_held := false


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(throw):
		stop()
		return
	if not observed and float(throw.get("_windup")) > 0.0:
		observed = true
		commit_frame = Engine.get_physics_frames()
		commit_process = Engine.get_process_frames()
		var preview: Dictionary = throw.call("aim_report")
		invalid = throw.get("_committed_assist_point") == Vector3.INF \
			or not bool(preview.get("eligible", false)) \
			or bool(preview.get("trajectory_blocked", true))
		if invalid:
			cancel_sent = true
			_cancel_held = true
			Input.parse_input_event(event_for.call(&"menu_cancel", true))
			Input.flush_buffered_events()
	# ThrowAim.State.IDLE is zero; observe the completed native cancellation.
	if cancel_sent and not cancelled and int(throw.get("state")) == 0:
		cancelled = true
		cancel_frame = Engine.get_physics_frames()
		cancel_process = Engine.get_process_frames()
		_release_cancel()


func _release_cancel() -> void:
	if _cancel_held:
		_cancel_held = false
		Input.parse_input_event(event_for.call(&"menu_cancel", false))
		Input.flush_buffered_events()


func stop() -> void:
	set_physics_process(false)
	_release_cancel()


func _exit_tree() -> void:
	_release_cancel()
