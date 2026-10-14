extends RefCounted

## Bounded paid homestead step. The common helper drives production input only.
const HELPER := preload("res://tools/earned_saves/wip_fights/homestead_common.gd")

func run(tree: SceneTree, world: Node3D, game: Node, args: Dictionary = {}) -> Dictionary:
	var options := args.duplicate(true)
	options["step"] = "cook_feed"
	return await HELPER.new().run_step(tree, world, game, options)
