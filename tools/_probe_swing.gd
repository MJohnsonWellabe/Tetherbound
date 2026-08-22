extends SceneTree

## Why did an interact press on a harvest node not start the axe swing?
const SCENE := "res://scenes/world/meadows_playground.tscn"
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in 300:
		await physics_frame
	var game: Node = root.get_node_or_null(^"Game")
	print("game=", game)
	var player: Node3D = game.call("find_player") as Node3D
	print("player=", player)
	var hold: Node3D = player.get("tool_hold") if player != null else null
	print("tool_hold=", hold)
	if hold != null:
		print("  has swing=", hold.has_method("swing"),
			" has would_connect=", hold.has_method("would_connect"),
			" has is_swinging=", hold.has_method("is_swinging"))
	# put an axe in hand the way the hotbar does
	var inv: RefCounted = game.get("inventory")
	inv.call("add", "axe", 1)
	game.set("equipped_tool", "axe")
	for _i in 30:
		await physics_frame
	print("equipped_tool=", game.get("equipped_tool"), " prop=", hold.call("prop_node"))

	# find a wood harvest_node and stand on top of it
	var target: Node3D = null
	for n in get_nodes_in_group("harvestable"):
		var sc := (n as Node).get_script() as Script
		if sc != null and sc.resource_path == "res://scripts/world/harvest_node.gd" \
				and str(n.get("_item_id")) == "wood":
			target = n as Node3D
			break
	print("target=", target, " at ", target.global_position if target != null else "n/a")
	if target == null:
		quit(1)
		return
	player.global_position = target.global_position + Vector3(1.2, 0.0, 0.0)
	for _i in 20:
		await physics_frame
	print("dist=", player.global_position.distance_to(target.global_position))
	print("would_connect=", hold.call("would_connect", target))
	print("swing_answers_the_prompt=", HARVEST_LOGIC.swing_answers_the_prompt(target, game))
	print("is_swinging after=", hold.call("is_swinging"))
	quit(0)
