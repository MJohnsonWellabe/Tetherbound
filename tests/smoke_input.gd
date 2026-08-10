extends SceneTree

## Does pressing an action actually move the player?
##
##   godot --headless --path . --script tests/smoke_input.gd
##
## Injects input through `Input.action_press`, which is the same path a real
## key or stick deflection takes once the input map has resolved it. That
## exercises everything between an action firing and the capsule moving:
## the controller reading the action, the camera rig supplying a basis, the
## acceleration, and `move_and_slide` against terrain collision.
##
## What it deliberately CANNOT test is the device layer — whether Windows
## presents the handheld as a standard gamepad, and whether its sticks emit
## joypad events at all. If this passes and the hardware still does nothing,
## the fault is upstream of Godot and no amount of game code will fix it.
## That split is the entire point of running this.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const HOLD_FRAMES := 90


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("FAIL: no player")
		quit(1)
		return

	var failures: Array[String] = []

	# --- the camera rig, because movement silently depends on it ------------
	# `_apply_movement` only produces a direction when the rig can supply a
	# planar basis. A null rig means every input is read correctly and then
	# discarded, and the capsule sits still with no error anywhere.
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig == null:
		failures.append("no CameraRig node: movement would silently do nothing")
	elif not rig.has_method("planar_basis"):
		failures.append("CameraRig has no planar_basis(): movement direction is always zero")

	var anim: AnimationPlayer = null
	var model: Node = player.get_node_or_null(^"Model")
	if model != null and model.has_method("animation_player"):
		anim = model.call("animation_player")
	if anim == null:
		failures.append("trainer has no AnimationPlayer; cannot check locomotion animation")

	# --- forward ------------------------------------------------------------
	var start: Vector3 = player.global_position
	Input.action_press("move_forward")
	for i in HOLD_FRAMES:
		await physics_frame
	Input.action_release("move_forward")
	var moved := player.global_position - start
	var distance := Vector2(moved.x, moved.z).length()
	print("move_forward for %d frames -> travelled %.2fm  (speed %.2f m/s)" % [
		HOLD_FRAMES, distance, player.call("ground_speed")
	])
	if distance < 1.0:
		failures.append("holding move_forward moved the player %.2fm; the input path is broken" % distance)

	# --- strafe, to prove the basis is not collapsing to one axis -----------
	# Also where the walk-loop check lives (not the move_forward block above):
	# both directions stall against something in the scatter within a second
	# or so from this spawn point -- a real but separate, already-tracked
	# issue (DONE.md, RB2) that makes "still walking after N frames" an
	# unreliable thing to assert here. Checked the moment "walk" starts
	# playing instead of after a fixed hold: the owner's "no animation" bug
	# was every baked clip shipping LOOP_NONE (plays once, freezes for the
	# rest of however long the state holds) -- character_model.gd's play()
	# sets loop_mode the instant it starts a clip, so this is exercised
	# whether or not the trainer keeps moving afterwards, and isn't a race
	# against the environment.
	start = player.global_position
	Input.action_press("move_right")
	var saw_walk := false
	for i in HOLD_FRAMES:
		await physics_frame
		if not saw_walk and anim != null and anim.current_animation == "walk":
			saw_walk = true
			var clip: Animation = anim.get_animation("walk")
			print("walk started at frame %d, loop_mode=%d (want %d LOOP_LINEAR)" % [
				i, clip.loop_mode, Animation.LOOP_LINEAR])
			if clip.loop_mode != Animation.LOOP_LINEAR:
				failures.append("the walk clip is loop_mode %d, not LOOP_LINEAR -- it will play once and freeze for as long as the trainer keeps walking" % clip.loop_mode)
	if anim != null and not saw_walk:
		failures.append("move_right never made the trainer's animation report 'walk'")
	Input.action_release("move_right")
	var strafed := player.global_position - start
	var strafe_distance := Vector2(strafed.x, strafed.z).length()
	print("move_right for %d frames -> travelled %.2fm" % [HOLD_FRAMES, strafe_distance])
	if strafe_distance < 1.0:
		failures.append("holding move_right moved the player %.2fm" % strafe_distance)

	# The two directions must not be the same heading, or the camera basis is
	# degenerate and every input resolves to one axis.
	if distance > 1.0 and strafe_distance > 1.0:
		var a := Vector2(moved.x, moved.z).normalized()
		var b := Vector2(strafed.x, strafed.z).normalized()
		if absf(a.dot(b)) > 0.9:
			failures.append("forward and right produce the same heading; camera basis is degenerate")

	# --- jump ---------------------------------------------------------------
	var vitals: RefCounted = player.get("vitals")
	var stamina_before: float = vitals.stamina
	var height_before: float = player.global_position.y
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	var peak := height_before
	for i in 40:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
	print("jump -> rose %.2fm, stamina %.0f -> %.0f" % [peak - height_before, stamina_before, vitals.stamina])
	if peak - height_before < 0.4:
		failures.append("jump only rose %.2fm" % (peak - height_before))
	if vitals.stamina >= stamina_before:
		failures.append("jump did not spend stamina")

	print("")
	if failures.is_empty():
		print("input smoke: OK — actions drive the character correctly.")
		print("If the handheld still does nothing, the fault is in the DEVICE layer:")
		print("  the Ally in desktop/mouse mode, or the pad not enumerating.")
		quit(0)
	else:
		for line in failures:
			print("input smoke FAIL: %s" % line)
		quit(1)
