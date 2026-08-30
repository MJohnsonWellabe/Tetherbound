extends SceneTree

## T5-CARE: can the player build themselves into a box they cannot leave?
##
##   godot --headless --path . --script tools/_play_t5_strand.gd
##
## The lane brief's question: *is there a case where a piece can be placed
## somewhere that strands or clips the player?* `build_placer.gd::
## evaluate_placement()` refuses a placement for exactly three reasons --
## occupied, too steep, cannot afford -- and none of them is "this would seal
## the player in". So the answer is not in the refusal list; it is in whether
## the failsafe downstream catches it.
##
## This walls the player in with real placements through the real placer, then
## drives the stick and reports whether they get out, how long it takes, and
## which mechanism did it (`_unwedge`'s deflection, `_recover_if_entombed`'s
## teleport, or nothing).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const PATCH := Vector2(30.0, -40.0)
## How long to push against the walls before calling it stranded. The failsafe's
## own detection window is `movement.json::unstick.detect_seconds`.
const ESCAPE_FRAMES := 900


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	game.set("free_build", true)  # the walls are the subject, not their price
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("T5> BLOCKED: no player")
		quit(1)
		return

	var ground := float(world.call("ground_height_at", PATCH.x, PATCH.y))
	player.global_position = Vector3(PATCH.x, ground + 1.0, PATCH.y)
	player.velocity = Vector3.ZERO
	for i in 120:
		await physics_frame
	var start := player.global_position
	print("")
	print("T5> === stranding test ===")
	print("T5> player stood on the Practice Meadow build patch at %s" % str(start))

	# Ring them with walls, using the world's own registration path so the
	# pieces are as real as any the player places.
	var placed := 0
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var offset := Vector3(sin(angle), 0.0, cos(angle)) * 1.3
		var spot := start + offset
		spot.y = float(world.call("ground_height_at", spot.x, spot.z))
		game.call("register_building", "wall", spot, rad_to_deg(-angle), false)
		placed += 1
	var placer := _find_placer(world)
	if placer == null:
		print("T5> BLOCKED: no BuildPlacer to stand the walls up")
		quit(1)
		return
	placer.call("restore_from_game", game)
	for i in 60:
		await physics_frame
	print("T5> ringed the player with %d wall pieces at 1.3m" % placed)

	# Now push. Full stick, sweeping direction, the way a boxed-in player does.
	var escaped := false
	var frames := 0
	var how := "never got out"
	while frames < ESCAPE_FRAMES:
		var angle := TAU * float(frames % 240) / 240.0
		_push_stick(Vector2(sin(angle), cos(angle)))
		await physics_frame
		frames += 1
		var moved := Vector2(player.global_position.x, player.global_position.z) \
			.distance_to(Vector2(start.x, start.z))
		if moved > 3.0:
			escaped = true
			how = "walked/was recovered clear after %.1fs" % (float(frames) / 60.0)
			break
		if player.global_position.y < ground - 5.0:
			escaped = false
			how = "fell THROUGH the floor after %.1fs" % (float(frames) / 60.0)
			break
	_release_stick()

	var final := player.global_position
	print("T5> after %.1fs of stick: %s" % [float(frames) / 60.0, how])
	print("T5> player ended at %s (%.2fm from where they were sealed in)" % [
		str(final), Vector2(final.x, final.z).distance_to(Vector2(start.x, start.z))])
	if escaped:
		print("T5> VERDICT: PASS — a player who walls themselves in gets out. "
			+ "Nothing in the placer refuses the placement, but the entombment "
			+ "failsafe in player_controller.gd is what saves them.")
	else:
		print("T5> VERDICT: FAIL — the player is sealed in and stayed in for %.0fs. "
			% (float(frames) / 60.0)
			+ "Building can strand you and nothing recovers it.")
	quit(0)


func _push_stick(dir: Vector2) -> void:
	for axis_entry: Variant in [[JOY_AXIS_LEFT_X, dir.x], [JOY_AXIS_LEFT_Y, dir.y]]:
		var event := InputEventJoypadMotion.new()
		event.axis = (axis_entry as Array)[0]
		event.axis_value = float((axis_entry as Array)[1])
		Input.parse_input_event(event)


func _release_stick() -> void:
	_push_stick(Vector2.ZERO)


func _find_placer(world: Node) -> Node:
	for node in world.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("build_placer.gd"):
			return node
	return null
