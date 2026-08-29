extends SceneTree

## T2-BUILDPLACE diagnostic: why does the proven-reachable (18.99,-1.01)
## coordinate land near Mira but the live prompt still reads "Put <ally>
## away" instead of her greeting? Prints Mira's actual live position, the
## player's position after teleporting to the authored coordinate, the
## real 3D distance between them, and the live prompt/winning provider,
## with and without a deployed healthy ally.
##
##   godot --headless --path . --script tools/gate_f/probe_mira_position_check.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const AT := Vector2(18.99, -1.01)


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	var player: Node3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if game == null or player == null:
		print("PROBE FAIL: no Game/Player")
		quit(1)
		return
	var director := world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")

	var mira := world.find_child("Mira", true, false)
	if mira == null:
		# Search the whole tree, not just the world subtree.
		mira = _find_by_name(root, "Mira")
	if mira == null:
		print("PROBE FAIL: no node named Mira anywhere in the tree")
		quit(1)
		return
	print("Mira live position: %s" % str((mira as Node3D).global_position))

	var y := float(world.call("ground_height_at", AT.x, AT.y)) if world.has_method("ground_height_at") else 0.0
	player.global_position = Vector3(AT.x, y + 0.2, AT.y)
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	print("player position after teleport to authored coord: %s" % str(player.global_position))
	print("3D distance to Mira: %.2f m" % player.global_position.distance_to((mira as Node3D).global_position))

	var arbiter := world.find_child("InteractionArbiter", true, false)
	if arbiter == null:
		arbiter = _find_by_script(root, "interaction_arbiter.gd")
	for i in 20:
		await physics_frame
	print("")
	print("--- no ally deployed ---")
	if arbiter != null and arbiter.has_method("prompt"):
		print("live prompt: \"%s\"" % str(arbiter.call("prompt")))
	var provider: Object = arbiter.call("winning_provider") if arbiter != null and arbiter.has_method("winning_provider") else null
	print("winning provider: %s" % (str((provider as Node).name) if provider is Node else str(provider)))

	# --- now deploy a healthy ally (the shape S03 is actually in at S03-52:
	# the starter caught in S02, alive, following the player) ---
	var party: RefCounted = game.get("party")
	if int(party.call("size")) == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup")
		party.call("add", creature)
	party.call("set_active", 0)
	for i in 10:
		await physics_frame
	# Same physical press S03-09a/RIG-13 already use.
	await _tap("creature_recall")
	for i in 30:
		await physics_frame
	print("")
	print("--- healthy ally deployed (creature_recall pressed) ---")
	if arbiter != null and arbiter.has_method("prompt"):
		print("live prompt: \"%s\"" % str(arbiter.call("prompt")))
	provider = arbiter.call("winning_provider") if arbiter != null and arbiter.has_method("winning_provider") else null
	print("winning provider: %s" % (str((provider as Node).name) if provider is Node else str(provider)))

	quit(0)


func _tap(action: String) -> void:
	var down := _joy_event_for(action, true)
	if down == null:
		return
	Input.parse_input_event(down)
	for i in 2:
		await process_frame
	Input.parse_input_event(_joy_event_for(action, false))
	for i in 5:
		await process_frame


func _joy_event_for(action: String, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			var out := InputEventJoypadButton.new()
			out.device = 0
			out.button_index = button.button_index
			out.pressed = pressed
			return out
		var motion := event as InputEventJoypadMotion
		if motion != null:
			var out := InputEventJoypadMotion.new()
			out.device = 0
			out.axis = motion.axis
			out.axis_value = motion.axis_value if pressed else 0.0
			return out
	return null


func _find_by_name(node: Node, name: String) -> Node:
	if str(node.name) == name:
		return node
	for child in node.get_children():
		var found := _find_by_name(child, name)
		if found != null:
			return found
	return null


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null
