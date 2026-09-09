extends SceneTree
const SAVE := preload("res://scripts/save/save_game.gd")
var began := 0
func _init() -> void:
	call_deferred("run")
func run() -> void:
	await process_frame
	var game: Node = root.get_node("Game")
	game.set("save_system", SAVE.new("user://realm_load_%d" % OS.get_process_id()))
	game.call("reset_for_new_game")
	var world: Node = load("res://scenes/world/meadows_playground.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	for i in 30:
		await physics_frame
	world.tree_exiting.connect(func(): print("[realm_load] outgoing exit begins at=", Time.get_ticks_msec()-began))
	world.tree_exited.connect(func(): print("[realm_load] outgoing exit ends at=", Time.get_ticks_msec()-began))
	print("[realm_load] BASELINE actual enter_realm; isolated diagnostic bypass_gate only, all world content retained")
	began = Time.get_ticks_msec()
	var ok: bool = await game.call("enter_realm", "cloudreach", "meadows_gate", true)
	print("[realm_load] RESULT ok=", ok, " elapsed=", Time.get_ticks_msec()-began, " realm=", game.get("current_realm"), " pending=", game.get("pending_realm_entry"))
	if current_scene != null:
		print("[realm_load] destination nodes=", current_scene.find_children("*", "", true, false).size())
	quit(0 if ok else 1)
