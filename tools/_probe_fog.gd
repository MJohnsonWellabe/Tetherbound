extends SceneTree

## OWNER_DIRECTIVES_2026-08-22 section 3: "The village and the roads out of it
## start revealed." What does a FRESH save's map actually show right now?
const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in 240:
		await physics_frame
	var game: Node = root.get_node_or_null(^"Game")
	game.call("reset_for_new_game")
	for _i in 60:
		await physics_frame
	var m: Node = game.get("map")
	print("cells revealed on a fresh save: %.4f%% of the grid" % (float(m.call("discovered_fraction")) * 100.0))
	var lms: Array = m.call("landmarks")
	var known := 0
	for l: Variant in lms:
		if bool((l as Dictionary).get("discovered", false)):
			known += 1
	print("landmarks: %d authored, %d discovered on a fresh save" % [lms.size(), known])
	for l: Variant in lms:
		var d := l as Dictionary
		print("   %-22s cat=%-8s discovered=%s" % [str(d.get("id")), str(d.get("category")), str(d.get("discovered"))])
	quit(0)
