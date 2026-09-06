extends SceneTree

## MP-W0-SMOKE-SWEEP-0906, Task 2. Why does `jump` not fire during the
## opening's wake-in-bed beat on a fresh New Game?
##
##   XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tools/_probe_jump_in_bed.gd
##
## Boots `scenes/world/meadows_playground.tscn` exactly like
## `tests/smoke_playground.gd` (load, add to root, 240 settle physics frames),
## then presses `jump` through a real `InputEventJoypadButton` (button 0, the
## live binding) via `Input.parse_input_event` ON a physics frame -- the same
## edge `tools/net/peer_runner.gd::_press_edge` injects, paired with
## `Input.action_press` the way that file and `operator_harness.gd::_edge`
## both do -- holds it for a few physics frames, releases, and prints one row
## per physics frame for 30 frames.
##
## Nothing in production is touched. Every private this reads
## (`_jump_buffered_for`, `_airborne_for`, `_locomotion_enabled`, ...) is read
## with `get()`; the director's lying state is read off the trainer's own
## `Model.is_lying()` plus the director's `_lying_lift_m`.
##
## HOW "was `_try_jump` reached" IS OBSERVED WITHOUT INSTRUMENTING IT.
## `player_controller.gd::_physics_process` runs `_track_airborne` (which
## zeroes `_jump_buffered_for` when `Input.is_action_just_pressed("jump")`
## reads true) and then `_try_jump`, which has four gates in order:
##   G1  `not _locomotion_enabled or input_owned`       -> return
##   G2  `not (grounded_enough and asked_recently)`     -> return
##   G3  `not vitals.try_spend_jump()`                  -> return
##   FIRE `velocity.y = _jump_velocity; _jump_buffered_for = INF;
##        _airborne_for = _coyote_time + 1.0`
## So, read at the START of the next physics step (the values are the end of
## the previous one):
##   * `_jump_buffered_for` still INF after the press frame  -> `_track_airborne`
##     never saw the press: the input never reached the controller's frame
##     (harness ordering), not a gate.
##   * `_jump_buffered_for` ~ 0.0167 (one delta) and stamina unchanged
##     -> the press WAS buffered and `_try_jump` refused at G1 or G2.
##   * stamina dropped by `jump_cost` and `_jump_buffered_for` == INF
##     -> `_try_jump` FIRED. `velocity.y` then says what happened to the
##     launch after `move_and_slide` (a ceiling contact zeroes it at once).
## Each row also prints the G1/G2 inputs directly so the refusing line can be
## named from the row, not inferred.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const WATCH_FRAMES := 30
const HOLD_FRAMES := 4

var _world: Node
var _player: CharacterBody3D
var _director: Node
var _frame := 0
var _just_pressed_seen := false


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load %s" % SCENE)
		quit(1)
		return
	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_director = _world.get_node_or_null(^"SequenceDirector")
	if _player == null:
		print("FAIL: no Player")
		quit(1)
		return
	var vitals: RefCounted = _player.get("vitals")
	print("settled after %d physics frames. beat=%s fading=%s jump_velocity=%.3f buffer_time=%.3f coyote_time=%.3f jump_cost=%s"
		% [SETTLE_FRAMES, _beat(), str(_fading()), float(_player.get("_jump_velocity")),
			float(_player.get("_buffer_time")), float(_player.get("_coyote_time")),
			str(vitals.get("_jump_cost")) if vitals != null else "?"])
	print("player at %s  model=%s" % [str(_player.global_position), str(_player.get_node_or_null(^"Model"))])
	_print_header()
	_row("settled")

	# Press on a physics frame: we are resumed from the `physics_frame` signal,
	# which SceneTree emits at the top of the physics step BEFORE any node's
	# `_physics_process`, so the controller polls this same physics frame.
	_press(true)
	for i in WATCH_FRAMES:
		await physics_frame
		_frame = i + 1
		if _frame == HOLD_FRAMES:
			_press(false)
		_row("frame")

	# Control: the same press once the trainer is stood up, so the harness
	# path itself is proven live in this very process.
	print("")
	print("--- control: stand the trainer up (director._set_player_lying(false), walk off the bed) and press again ---")
	if _director != null:
		_director.call("_set_player_lying", false)
	# Nudge the body clear of the mattress collider without teleporting into
	# geometry: the director's own BED_LEAVE_RADIUS handles the beat.
	for i in 60:
		await physics_frame
	_frame = 0
	_print_header()
	_row("stood")
	_press(true)
	for i in WATCH_FRAMES:
		await physics_frame
		_frame = i + 1
		if _frame == HOLD_FRAMES:
			_press(false)
		_row("frame")

	# Second control: inject from a PROCESS frame, which is where
	# `tools/net/peer_runner.gd`'s control loop actually runs `_press_edge`
	# (its socket poll lives on `process_frame`), then watch physics frames.
	print("")
	print("--- control 2: press from a process frame (peer_runner's own ordering), still on the bed ---")
	for i in 60:
		await physics_frame
	await process_frame
	_frame = 0
	_print_header()
	_row("proc")
	_press(true)
	for i in WATCH_FRAMES:
		await physics_frame
		_frame = i + 1
		if _frame == HOLD_FRAMES:
			_press(false)
		_row("frame")
	quit(0)


func _press(pressed: bool) -> void:
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_A   # button 0: the live `jump` binding in project.godot
	b.pressed = pressed
	Input.parse_input_event(b)
	if pressed:
		Input.action_press(&"jump", 1.0)
	else:
		Input.action_release(&"jump")
	# What the controller's `_track_airborne` will read on THIS physics frame.
	_just_pressed_seen = Input.is_action_just_pressed("jump")
	print("  [%s jump on physics frame %d/engine %d] is_action_pressed=%s is_action_just_pressed=%s in_physics_frame=%s"
		% ["press" if pressed else "release", _frame, Engine.get_physics_frames(),
			str(Input.is_action_pressed("jump")), str(_just_pressed_seen),
			str(Engine.is_in_physics_frame())])


func _beat() -> String:
	return str(_director.call("beat")) if _director != null and _director.has_method("beat") else "?"


func _fading() -> bool:
	return _director != null and _director.has_method("is_fading") and bool(_director.call("is_fading"))


func _lying() -> String:
	var model := _player.get_node_or_null(^"Model")
	if model == null or not model.has_method("is_lying"):
		return "?"
	return str(bool(model.call("is_lying")))


func _lying_lift() -> String:
	if _director == null:
		return "?"
	return "%.3f" % float(_director.get("_lying_lift_m"))


func _owner() -> String:
	var script: GDScript = load("res://scripts/ui/input_owner.gd")
	var node: Node = script.call("current", self)
	return "none" if node == null else str(node.name)


func _print_header() -> void:
	print("frame | on_floor | vel.y   | loco | carried | lying | lift  | fading | beat  | owner | stamina | jbuf     | airborne | jp | try_jump")


func _row(tag: String) -> void:
	var vitals: RefCounted = _player.get("vitals")
	var jbuf := float(_player.get("_jump_buffered_for"))
	var airborne := float(_player.get("_airborne_for"))
	var loco := bool(_player.call("locomotion_enabled"))
	var carried := bool(_player.call("is_carried"))
	var stamina := float(vitals.get("stamina")) if vitals != null else -1.0
	var verdict := _try_jump_verdict(jbuf, airborne, loco, stamina)
	# `jp` is `Input.is_action_just_pressed("jump")` read HERE, at the top of
	# this physics step -- the same poll `_track_airborne` makes a moment later.
	print("%5s %d | %s | %+7.3f | %s | %s | %s | %s | %s | %s | %s | %7.2f | %8s | %8.3f | %s | %s"
		% [tag, _frame, str(_player.is_on_floor()), _player.velocity.y, str(loco), str(carried),
			_lying(), _lying_lift(), str(_fading()), _beat(), _owner(), stamina,
			("INF" if jbuf == INF else "%.4f" % jbuf), airborne,
			str(Input.is_action_just_pressed("jump")), verdict])


var _stamina_before_press := -1.0


func _try_jump_verdict(jbuf: float, airborne: float, loco: bool, stamina: float) -> String:
	if _frame == 0:
		_stamina_before_press = stamina
		return "-"
	var coyote := float(_player.get("_coyote_time"))
	var cost := float((_player.get("vitals") as RefCounted).get("_jump_cost"))
	if stamina <= _stamina_before_press - cost + 0.001 and airborne > coyote:
		return "FIRED (stamina -%.0f, airborne consumed)" % cost
	if jbuf == INF:
		if _frame == 1:
			# Expected on the frame right after an injected edge: Godot 4.7's
			# Input::action_press stamps pressed_physics_frame = physics_frames + 1
			# ("the earliest we can react to it is the next physics tick"), and
			# parse_input_event queues under use_accumulated_input until the next
			# main-loop iteration, so the controller's own poll sees the press on
			# the NEXT physics step. Not a gate. A jbuf still INF on frame 2 with
			# stamina unchanged would be the real "never buffered" case.
			return "not yet: press stamped for the next physics tick (Input::action_press: physics_frames+1)"
		if _frame == 2 and stamina >= _stamina_before_press - 0.001:
			return "NOT BUFFERED: _track_airborne saw no just_pressed (or set_locomotion_enabled(false) cleared it)"
		return "-"
	if not loco:
		return "refused G1 (_locomotion_enabled false) line 769"
	if not _player.is_on_floor() and airborne > coyote:
		return "refused G2 (not grounded_enough) line 773"
	if jbuf > float(_player.get("_buffer_time")):
		return "refused G2 (buffer expired) line 773"
	if stamina < cost:
		return "refused G3 (try_spend_jump: stamina %.1f < %.1f) line 775" % [stamina, cost]
	return "buffered, gates all open?! (would have fired)"
