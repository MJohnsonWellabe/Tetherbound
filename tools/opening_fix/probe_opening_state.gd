extends SceneTree
## Developer-lane probe (branch ralph/OPENING-STARTER-FOCUS). NOT Gate F tooling.
##
## Boots the real Meadows and reports, once a second, the state that decides
## whether `interact` next to Grandpa can do anything:
##   beat, Grandpa's prompt enabled flag, the arbiter's winning provider,
##   the input owner, and the player's position.
##
## Then walks the player to Grandpa's marker and presses `interact`, and says
## what changed. No teleports, no granted flags.

const WORLD := "res://scenes/world/meadows_playground.tscn"

func _initialize() -> void:
	_run()

func _run() -> void:
	var packed: PackedScene = load(WORLD)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in 400:
		await physics_frame
	print("=== opening state probe ===")

	var director := _find(world, "sequence_director.gd")
	var arbiter := _find(world, "interaction_arbiter.gd")
	var player := _find(world, "player_controller.gd")
	var house := world.get_node_or_null(^"GrandpaHouse")
	print("director=%s arbiter=%s player=%s house=%s" % [
		director != null, arbiter != null, player != null, house != null])
	if house != null:
		print("marker grandpa = %s" % str(house.call("marker", "grandpa")))
		print("marker bed     = %s" % str(house.call("marker", "bed")))
		print("marker door    = %s" % str(house.call("marker", "door")))

	for tick in 12:
		_report(tick, director, arbiter, player)
		for i in 60:
			await physics_frame

	print("--- pressing interact where the player stands (advances wake -> house) ---")
	await _press_interact()
	_report(90, director, arbiter, player)
	print("--- now WAITING, without moving, to separate time from movement ---")
	for probe in 6:
		for i in 60:
			await physics_frame
		_report(900 + probe, director, arbiter, player)

	if house != null and player != null:
		var g: Vector3 = house.call("marker", "grandpa")
		print("--- nudging the player so the arbiter recomputes, then pressing ---")
		(player as Node3D).global_position = g + Vector3(1.0, 0.2, 0.0)
		for i in 60:
			await physics_frame
		_report(91, director, arbiter, player)
		await _press_interact()
		_report(92, director, arbiter, player)
		for i in 120:
			await physics_frame
		_report(93, director, arbiter, player)

	quit()

func _press_interact() -> void:
	var b := InputEventJoypadButton.new()
	b.button_index = 2
	b.pressed = true
	Input.parse_input_event(b)
	await process_frame
	await physics_frame
	var u := InputEventJoypadButton.new()
	u.button_index = 2
	u.pressed = false
	Input.parse_input_event(u)
	await process_frame
	for i in 30:
		await physics_frame

func _report(tick: int, director: Node, arbiter: Node, player: Node) -> void:
	var beat := "?"
	if director != null:
		beat = str(director.get("_beat"))
	var winner := "none"
	if arbiter != null:
		var w: Variant = arbiter.get("_winning_provider")
		if w != null and is_instance_valid(w):
			winner = str((w as Node).name) + "/" + str((w as Node).get_parent().name)
	var owner_name := "none"
	var owners := root.get_tree().get_nodes_in_group("input_owner")
	if owners.size() > 0:
		owner_name = str(owners[0].name)
	var pos := "?"
	if player != null:
		pos = "%.2f,%.2f" % [(player as Node3D).global_position.x, (player as Node3D).global_position.z]
	print("t%02d beat=%s winner=%s owner=%s pos=%s" % [tick, beat, winner, owner_name, pos])

func _find(from: Node, script_tail: String) -> Node:
	if from.get_script() != null and str(from.get_script().resource_path).ends_with(script_tail):
		return from
	for c in from.get_children():
		var r := _find(c, script_tail)
		if r != null:
			return r
	return null


