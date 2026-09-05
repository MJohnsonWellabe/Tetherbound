extends SceneTree

## Does AlphaPins._process reach tick() when the node is a child of a Node3D
## "world" rather than of root? Seconds, no world scene.

const ALPHA_PINS := preload("res://scripts/world/alpha_pins.gd")

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("no Game autoload"); quit(1); return

	var world := Node3D.new()
	world.name = "WorldStandIn"
	root.add_child(world)
	var player := CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3(-180.0, 0.0, 2130.0)

	# Exactly how playground_world.gd wires it: default relative player_path.
	var pins: Node = ALPHA_PINS.new()
	world.add_child(pins)
	await process_frame

	print("[m] is_processing=%s can_process=%s paused=%s clusters=%d" % [
		str(pins.is_processing()), str(pins.can_process()), str(paused),
		(pins.get("_clusters") as Array).size()])

	var map: RefCounted = game.get("map")
	var until := Time.get_ticks_msec() + 4000
	var frames := 0
	while Time.get_ticks_msec() < until and int(map.call("alpha_pin_count")) == 0:
		await process_frame
		frames += 1
	print("[m] after %d frames, pins=%d" % [frames, int(map.call("alpha_pin_count"))])
	if int(map.call("alpha_pin_count")) == 0:
		pins.call("tick")
		print("[m] hand-driven tick() -> pins=%d" % int(map.call("alpha_pin_count")))
	quit(0)
