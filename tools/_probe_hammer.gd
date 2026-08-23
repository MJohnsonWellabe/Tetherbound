extends SceneTree

## Why does hammer + interact open nothing?
##
## `playground_hud.gd::_hammer_opens_the_catalogue()` has four refusals. This
## prints which one is live at the spot `smoke_post_modal_control.gd` teleports
## to, rather than inferring it from the one that seems most likely.

const WORLD := "res://scenes/world/meadows_playground.tscn"


func _initialize() -> void:
	_run()


func _run() -> void:
	var world: Node = load(WORLD).instantiate()
	root.add_child(world)
	for _i in 240:
		await process_frame
	var game := root.get_node_or_null(^"/root/Game")
	var hud: Node = world.find_child("PlaygroundHUD", true, false)
	var arbiter: Node = world.find_child("PromptArbiter", true, false)
	if arbiter == null and hud != null:
		arbiter = hud.get("_arbiter")
	var player: Node3D = game.call("find_player") as Node3D
	for cycle in 3:
		var spot := Vector3(100.0 + cycle * 24.0, 0.0, 80.0)
		if player != null:
			player.global_position = Vector3(spot.x, player.global_position.y, spot.z)
		for _i in 30:
			await process_frame
		var winner: Variant = null
		if arbiter != null and arbiter.has_method("winning_provider"):
			winner = arbiter.call("winning_provider")
		var winner_name := "none"
		if winner != null:
			winner_name = str(winner)
			if winner is Node:
				winner_name = str((winner as Node).name) + " (" + str((winner as Node).get_class()) + ")"
		print("cycle %d at %s: equipped=%s  arbiter_winner=%s" % [
			cycle + 1, spot, str(game.get("equipped_tool")), winner_name,
		])
	quit(0)
