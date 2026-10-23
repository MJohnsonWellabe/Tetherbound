extends SceneTree

## 22 Oct UI lane: the Stormwood surge tag ("⚡ Calm · Sheltered") printed
## through the open pause menu. World status layers in the overlay group
## hide and return with the world HUD.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var world := Node.new()
	root.add_child(world)
	current_scene = world
	var hud := CanvasLayer.new()
	hud.name = "PlaygroundHUD"
	world.add_child(hud)
	var surge := CanvasLayer.new()
	surge.name = "SurgeStatus"
	surge.add_to_group(INPUT_OWNER.WORLD_HUD_OVERLAY_GROUP)
	world.add_child(surge)
	await process_frame
	INPUT_OWNER.set_world_hud_visible(self, false)
	if hud.visible or surge.visible:
		failures.append("menu open: HUD and surge tag hide")
	INPUT_OWNER.set_world_hud_visible(self, true)
	if not hud.visible or not surge.visible:
		failures.append("menu closed: HUD and surge tag return")
	if failures.is_empty():
		print("world hud overlay hide smoke passed")
		quit(0)
	else:
		print("FAILED: ", failures)
		quit(1)
