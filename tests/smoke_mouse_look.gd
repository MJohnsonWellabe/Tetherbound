extends SceneTree

## Does a mouse motion event actually REACH the camera rig?
##
##   godot --headless --path . --script tests/smoke_mouse_look.gd
##
## The owner reported mouse look broken on Windows. RB1 shipped a fix. The owner
## reported it still broken. RB1's diagnosis was made by reading code and was
## never reproduced: it blamed a mouse capture dropped before the window had OS
## focus and re-asserted capture on `focus_entered`. Capture was never the
## problem, and this file exists before the second fix rather than after it.
##
## THE ACTUAL BUG: `scenes/ui/playground_hud.tscn`'s `Root` is a full-rect
## `Control`, and a plain `Control` defaults to `MOUSE_FILTER_STOP`. GUI input
## handling runs BEFORE `_unhandled_input`, so the HUD consumed every
## `InputEventMouseMotion` and `camera_rig.gd::_unhandled_input` never received
## one. No error, no warning, camera simply never turned. Gamepad look kept
## working the whole time because it is POLLED in `_process` from the `look_*`
## actions and never travels the event path — which is exactly why the report
## was "mouse look" specifically and why everything else looked fine.
##
## WHAT THIS TEST CAN AND CANNOT PROVE, stated because getting this wrong is
## what let RB1 ship unverified. The obvious test — push a motion event, assert
## the camera yaw changed — CANNOT WORK HEADLESS. The headless DisplayServer
## refuses mouse capture: set `Input.mouse_mode = MOUSE_MODE_CAPTURED` and it
## reads back `0` (VISIBLE), verified directly. `camera_rig.gd` only accumulates
## look while that reads CAPTURED, so a headless yaw assertion fails identically
## whether the bug is present or fixed, and would be worthless.
##
## So this asserts DELIVERY, which is the half the bug was in and the half that
## is provable here: a probe node's `_unhandled_input` either sees the motion or
## it does not. Confirmed to discriminate — with the fix the probe sees it, and
## with the single `mouse_filter` line removed it does not.
##
## Still only answerable on real hardware: whether Windows delivers relative
## motion to the process when the cursor is captured. Same device-layer split
## `smoke_input.gd` documents.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PROBE := "res://tests/helpers/unhandled_probe.gd"
const SETTLE_FRAMES := 240

## UI that SHOULD take the mouse while open. `game_menu.tscn` sets
## MOUSE_FILTER_STOP deliberately and must not be reported as a defect.
const MOUSE_OWNING_UI := ["GameMenu", "DialoguePanel", "NamePrompt"]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var failures: Array[String] = []

	if world.get_node_or_null(^"CameraRig") == null:
		print("FAIL: no CameraRig — mouse look cannot work and neither can movement")
		quit(1)
		return

	# --- does the event survive GUI handling and reach unhandled input? ----
	var probe := Node.new()
	probe.set_script(load(PROBE))
	world.add_child(probe)
	await process_frame

	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120.0, 0.0)
	Input.parse_input_event(motion)
	await process_frame
	await process_frame

	if not probe.seen:
		failures.append(
			"MOUSE LOOK DEAD: an InputEventMouseMotion never reached _unhandled_input. Something in the scene consumed it during GUI handling, so camera_rig.gd cannot see mouse deltas at all."
		)

	# --- and name the cause, so a regression does not need re-diagnosing ---
	for control in _gameplay_controls(world):
		if control.mouse_filter == Control.MOUSE_FILTER_STOP and _is_full_rect(control):
			failures.append(
				"'%s' is a full-rect Control with MOUSE_FILTER_STOP, visible during gameplay: GUI handling runs before _unhandled_input, so it eats mouse motion and kills look. Set mouse_filter = MOUSE_FILTER_IGNORE (2), as combat_hud.tscn, dialogue_panel.tscn and name_prompt.tscn already do."
				% world.get_path_to(control)
			)

	# --- every Control the exploration HUD owns must be MOUSE_FILTER_IGNORE ---
	# Not just the full-rect ones above: the Palworld-layout rebuild
	# (`playground_hud.gd`) builds dozens of small Controls in code -- the creature
	# block, the vitals cluster, the mounted party_strip/stamina_arc/minimap
	# widgets, the objective block -- and any ONE of them left at the
	# Control default (MOUSE_FILTER_STOP) would sit in GUI input's path the
	# same way the old bug did, even at a few dozen pixels across. A
	# recursive walk is the only check that stays true as that HUD keeps
	# growing.
	var hud: Node = world.get_node_or_null(^"PlaygroundHUD")
	if hud == null:
		failures.append("no PlaygroundHUD in the scene — cannot verify its mouse_filter subtree")
	else:
		for node in _walk(hud):
			var c := node as Control
			if c == null:
				continue
			if c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				failures.append(
					"'%s' under PlaygroundHUD is mouse_filter %d, not MOUSE_FILTER_IGNORE (2) — every Control this HUD builds must ignore the mouse or it can end up back in GUI input's path, exactly like the bug this test exists to catch."
					% [hud.get_path_to(c), c.mouse_filter]
				)

	if failures.is_empty():
		print("PASS: mouse motion reaches _unhandled_input, and no gameplay Control swallows it")
		quit(0)
	else:
		for f in failures:
			print("FAIL: %s" % f)
		quit(1)


func _gameplay_controls(world: Node) -> Array[Control]:
	var found: Array[Control] = []
	for node in _walk(world):
		var c := node as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if c.owner != null and String(c.owner.name) in MOUSE_OWNING_UI:
			continue
		found.append(c)
	return found


func _is_full_rect(c: Control) -> bool:
	var vp := c.get_viewport_rect().size
	return c.size.x >= vp.x * 0.9 and c.size.y >= vp.y * 0.9


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_walk(child))
	return out
