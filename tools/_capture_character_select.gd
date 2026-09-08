extends SceneTree

## Capture the production new-game character picker for blind visual comparison.
## This intentionally enters the screen through TitleScreen's real picker builder
## so portraits, copy, focus and layout follow the same path as Start New Game.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_character_select.gd -- \
##     --out=res://shots/character-select.png
##
## Never combine a rendering driver with --headless; see AGENT_WORKFLOW.md.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const DEFAULT_OUT := "res://shots/character-select.png"
const WIDTH := 1280
const HEIGHT := 800


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("character-select capture needs a real Compatibility render context")
		quit(1)
		return
	root.size = Vector2i(WIDTH, HEIGHT)
	DisplayServer.window_set_size(Vector2i(WIDTH, HEIGHT))
	var output := DEFAULT_OUT
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			output = argument.trim_prefix("--out=")
			if not output.begins_with("res://"):
				output = "res://" + output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))

	var packed := load(TITLE_SCENE) as PackedScene
	if packed == null:
		push_error("could not load %s" % TITLE_SCENE)
		quit(1)
		return
	var title := packed.instantiate()
	root.add_child(title)
	current_scene = title
	for _frame in 12:
		await process_frame
	title.call("_show_character_select", Callable(self, "_chosen"), Callable(self, "_back"))
	for _frame in 8:
		await process_frame

	var heading := _find_label(title, "Choose Your Character")
	var visible_buttons := 0
	for candidate: Node in title.find_children("*", "Button", true, false):
		if candidate is Button and (candidate as Button).is_visible_in_tree():
			visible_buttons += 1
	if heading == null or not heading.is_visible_in_tree() or visible_buttons != 5:
		push_error("character picker not ready: heading=%s visible_buttons=%d" % [heading, visible_buttons])
		quit(1)
		return

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() != WIDTH or image.get_height() != HEIGHT:
		push_error("character-select viewport returned the wrong image")
		quit(1)
		return
	var error := image.save_png(output)
	if error != OK:
		push_error("character-select save_png failed (%d)" % error)
		quit(1)
		return
	print("character select -> %s (%dx%d, %d visible buttons)" % [output, WIDTH, HEIGHT, visible_buttons])
	quit(0)


func _find_label(parent: Node, expected: String) -> Label:
	for candidate: Node in parent.find_children("*", "Label", true, false):
		if candidate is Label and (candidate as Label).text == expected:
			return candidate as Label
	return null


func _chosen(_character_id: String) -> void:
	pass


func _back() -> void:
	pass
