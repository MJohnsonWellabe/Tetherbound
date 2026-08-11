extends SceneTree

## The orb picker, on screen, for the blind visual pass `SA0-orbs` needs before
## it can be marked done (conventions.md: any new UI a player can see gets a
## render and a critique, not just a look).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_starter_picker.gd
##
## Loads `starter_picker.tscn` directly rather than the full meadows scene.
## The picker is self-contained — three SubViewports, each with its own
## World3D, added straight under a CanvasLayer — and does not need Terrain3D,
## the 23,452-instance scatter or the village to exist behind it. The first
## attempt at this script booted the full playground first (matching
## `diagnose_frame.gd`'s pattern) and the whole process died silently, no
## error, partway through the picker's own render; the full world was never
## proven innocent, but there was no reason to keep paying its render cost
## while narrowing down a SubViewport question, so this drops it.
##
## Writes shots/_diag/starter_picker_*.png. Not part of the survey; delete
## when the question is answered.

const SCENE := "res://scenes/ui/starter_picker.tscn"
const OUT_DIR := "res://shots/_diag"

var _picker: CanvasLayer = null
var _backdrop: ColorRect = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# A plain meadow-green field behind the picker so the shot reads as "a
	# panel over the world" rather than "a panel over nothing" — the picker
	# itself never draws a full-screen background, the meadow does.
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.36, 0.46, 0.24)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop_layer := CanvasLayer.new()
	backdrop_layer.layer = 0
	root.add_child(backdrop_layer)
	backdrop_layer.add_child(_backdrop)

	_picker = (load(SCENE) as PackedScene).instantiate() as CanvasLayer
	root.add_child(_picker)
	for i in 5:
		await process_frame

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
	await process_frame
	await process_frame
	Input.action_release("ui_right")
	Input.parse_input_event(_action_event("ui_right", false))
	for i in 40:
		await process_frame
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
