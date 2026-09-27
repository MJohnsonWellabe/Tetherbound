extends RefCounted

## One button tap as the net proof runner injects it: the physical InputEvent
## AND the paired polled state (`peer_runner.gd`'s header says why both), held
## for `frames` physics frames. Lifted out of `peer_runner.gd` unchanged except
## for the ordering fix below, so `tests/smoke_peer_runner_press_edge.gd` can
## drive the exact sequence the runner uses.
##
## F11#3 (Stormwood, 2026-09-26): `Input.parse_input_event` queues the physical
## event until the next *process* frame, while `Input.action_press` is
## immediate. Releasing after one *physics* frame let a slow process frame (the
## host ran several physics ticks in it) flush the queued press AFTER the
## release, which reads as a second `just_pressed`: every toggle prompt (the
## Spark socket) flipped twice. `tap()` now lets that flush happen right after
## the press, while the polled press still holds.


## One edge of one action. Ported from `tools/gate_f/operator_harness.gd::_edge`,
## trimmed to the event kinds a net smoke needs (no mouse aiming).
static func edge(binding_of: Callable, action: String, pressed: bool) -> Dictionary:
	var a := StringName(action)
	if not InputMap.has_action(a):
		return {"ok": false, "why": "no input action '%s' in the live InputMap" % action}
	var binding: InputEvent = binding_of.call(a)
	if binding == null:
		return {"ok": false, "why": "action '%s' has no physical binding to inject" % action}
	if binding is InputEventJoypadButton:
		var b := InputEventJoypadButton.new()
		b.button_index = (binding as InputEventJoypadButton).button_index
		b.pressed = pressed
		Input.parse_input_event(b)
	elif binding is InputEventJoypadMotion:
		var m := InputEventJoypadMotion.new()
		m.axis = (binding as InputEventJoypadMotion).axis
		m.axis_value = (binding as InputEventJoypadMotion).axis_value if pressed else 0.0
		Input.parse_input_event(m)
	elif binding is InputEventKey:
		var k := InputEventKey.new()
		k.keycode = (binding as InputEventKey).keycode
		k.physical_keycode = (binding as InputEventKey).physical_keycode
		k.pressed = pressed
		Input.parse_input_event(k)
	elif binding is InputEventMouseButton:
		var mb := InputEventMouseButton.new()
		mb.button_index = (binding as InputEventMouseButton).button_index
		mb.pressed = pressed
		Input.parse_input_event(mb)
	else:
		return {"ok": false, "why": "action '%s' binds an event type this harness cannot synthesize (%s)"
			% [action, binding.get_class()]}
	if pressed:
		Input.action_press(a, 1.0)
	else:
		Input.action_release(a)
	return {"ok": true}


## Press, flush, hold `frames` physics frames, release. One idle frame right
## after the press lets the queued physical event land while the polled press
## holds, so both read as the same single edge. Measured with
## `tests/smoke_peer_runner_press_edge.gd` from a physics-frame resume and an
## idle one, with and without a stall: exactly one edge every time. Holding a
## physics frame first and flushing just before the release still read two
## edges from a physics-frame resume under the stall.
static func tap(tree: SceneTree, binding_of: Callable, action: String, frames: int) -> Dictionary:
	var down := edge(binding_of, action, true)
	if not bool(down.get("ok", false)):
		return down
	await tree.process_frame
	for i in maxi(1, frames):
		await tree.physics_frame
	var up := edge(binding_of, action, false)
	await tree.process_frame
	await tree.physics_frame
	return {"ok": bool(up.get("ok", false)), "why": str(up.get("why", ""))}
