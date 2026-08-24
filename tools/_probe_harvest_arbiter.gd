extends SceneTree

## GATEB-PATH diagnostic. Who owns the interact button beside an authored
## harvest node, and why the node's own prompt is not the answer.
##
##   godot --headless --path . --script tools/_probe_harvest_arbiter.gd
##
## Boots the world, stands the player at the material route's first authored
## wood stop, and dumps every offer the arbiter is looking at. Deliberately
## relocates the player rather than walking: this is a probe of the ARBITER, not
## of travel, and it exists so the real harness does not have to spend seven
## minutes of preamble to answer one question.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HARVEST_NODE_PATH := "res://scripts/world/harvest_node.gd"
const AT := Vector2(16.0, -28.0)


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in 240:
		await physics_frame

	var game := root.get_node_or_null(^"/root/Game")
	var arbiter := get_first_node_in_group("interaction_arbiter")
	var player := _find_player(world)
	if game == null or arbiter == null or player == null:
		print("PROBE: missing game/arbiter/player")
		quit(1)
		return

	var node: Node3D = null
	for candidate: Node in get_nodes_in_group("harvestable"):
		var script := candidate.get_script() as Script
		if script == null or script.resource_path != HARVEST_NODE_PATH:
			continue
		if not candidate is Node3D:
			continue
		if Vector2((candidate as Node3D).global_position.x,
				(candidate as Node3D).global_position.z).distance_to(AT) <= 3.0:
			node = candidate as Node3D
			break
	if node == null:
		print("PROBE: no authored harvest node near %s" % AT)
		quit(1)
		return
	print("PROBE node %s at %s item=%s stock=%s" % [
		node.name, node.global_position, str(node.call("resource_item")),
		str(node.call("resource_amount"))])

	# Stand a metre and a bit away, the distance the failing run reported.
	var spot := node.global_position + Vector3(1.2, 0.0, 0.0)
	spot.y = player.global_position.y
	player.global_position = spot
	for _i in 30:
		await physics_frame

	var prompt := node.get_node_or_null(^"Interactable") as Node3D
	print("PROBE prompt %s enabled=%s radius=%s label='%s' at %s" % [
		str(prompt), str(prompt.get("enabled")), str(prompt.get("radius")),
		str(prompt.get("label")), str(prompt.global_position)])
	print("PROBE prompt's own offer from the player: %s" % str(
		prompt.call("interaction_offer", player.global_position)))
	print("PROBE arbiter winner=%s prompt='%s' offer=%s" % [
		str(arbiter.call("winning_provider")), str(arbiter.call("prompt")),
		str(arbiter.call("winner"))])
	print("PROBE equipped_tool=%s" % str(game.get("equipped_tool")))

	var providers: Array = arbiter.get("_providers") as Array
	print("PROBE %d registered providers; the ones bidding right now:" % providers.size())
	for provider: Variant in providers:
		if provider == null or not is_instance_valid(provider):
			continue
		var offer: Variant = provider.call("interaction_offer", player.global_position)
		if offer is Dictionary and not (offer as Dictionary).is_empty():
			print("   %s -> %s" % [str(provider), str(offer)])
	quit(0)


func _find_player(node: Node) -> Node3D:
	if node is CharacterBody3D and node.has_method("locomotion_enabled"):
		return node as Node3D
	for child: Node in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null
