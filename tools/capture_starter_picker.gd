extends SceneTree

## The orb picker, on screen, for the blind visual pass `SA0-orbs` needs before
## it can be marked done (conventions.md: any new UI a player can see gets a
## render and a critique, not just a look).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_starter_picker.gd
##
## Opens the real `StarterPicker` node in the real meadows scene directly,
## the way `diagnose_frame.gd` poses a real camera in the real scene rather
## than building a stand-in — this is what a player actually sees once
## Grandpa's briefing closes, not a mockup of it. Two frames: the picker as it
## opens (orb 1 selected) and after moving to orb 3, so the critic can judge
## the selection highlight as well as the default state.
##
## Writes shots/_diag/starter_picker_*.png. Not part of the survey; delete
## when the question is answered.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PICKER_SCRIPT := "res://scripts/ui/starter_picker.gd"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 300

var _world: Node = null
var _picker: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_picker = _find_by_script(root, PICKER_SCRIPT) as CanvasLayer
	if _picker == null:
		print("no StarterPicker in the booted scene")
		quit(1)
		return

	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var species: Array[String] = ["terrapup", "ripplet", "galewisp"]
	_picker.call("open", species)
	# A few seconds of spin so the turntable is doing something in the shot,
	# not frozen on frame zero.
	for i in 90:
		await process_frame
	await RenderingServer.frame_post_draw
	await _shoot("starter_picker_default")

	Input.action_press("ui_right")
	Input.parse_input_event(_action_event("ui_right", true))
	await physics_frame
	await physics_frame
	Input.action_release("ui_right")
	Input.parse_input_event(_action_event("ui_right", false))
	for i in 40:
		await physics_frame
	await RenderingServer.frame_post_draw
	await _shoot("starter_picker_selected_third")

	print("wrote %s/starter_picker_default.png and _selected_third.png" % OUT_DIR)
	quit(0)


func _action_event(action: String, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _shoot(name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		print("no image for %s" % name)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, name])


func _find_by_script(node: Node, path: String) -> Node:
	var script: Script = node.get_script() as Script
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null
