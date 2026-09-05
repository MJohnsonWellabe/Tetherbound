extends RefCounted

## OP-0905-20: a realm crossing froze the screen with no sign anything was
## happening -- `Game.enter_realm()`'s own `change_scene_to_file()` blocks the
## main thread while the destination scene builds. This is the whole fix: a
## minimal full-screen "Loading <realm>…" CanvasLayer, shown BEFORE that
## blocking call and removed once the destination scene has drawn a frame.
##
## Not a scene, and not an autoload: `enter_realm()` is the one and only
## caller, `change_scene_to_file()` frees the CURRENT scene (which is where a
## scene-owned node would live), so this has to be built fresh on the tree
## ROOT, survive the free/rebuild in between, and be torn down by the same
## caller once the new scene exists. A `RefCounted` holding two `static`
## functions costs less than a `.tscn` for three nodes that never change
## shape and needs no export wiring.
##
## Colors/type ride on `UITokens` (D28) rather than a second copy of the
## palette.

const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")

## Above every real menu (`UITokens.LAYER_MENU`) — a crossing started from the
## paused debug-teleport list must still show over it, not behind it.
const LAYER := UI_TOKENS.LAYER_MENU + 10

const NODE_NAME := "LoadingOverlay"


## Builds the overlay and adds it to `tree`'s root. Rendering is unaffected by
## `SceneTree.paused`, but `PROCESS_MODE_ALWAYS` keeps the door open for a
## future spinner/Tween on it without this needing revisiting.
static func build(tree: SceneTree) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = NODE_NAME
	layer.layer = LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(UI_TOKENS.BG_DEEP, 1.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(backdrop)

	var label := Label.new()
	label.name = "Message"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", UI_TOKENS.FONT_HEADING)
	label.add_theme_color_override("font_color", UI_TOKENS.TEXT_PRIMARY)
	layer.add_child(label)

	tree.root.add_child(layer)
	return layer


## Sets/updates the message on an overlay `build()` returned.
static func set_message(overlay: CanvasLayer, message: String) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	var label := overlay.get_node_or_null(^"Message") as Label
	if label != null:
		label.text = message


## Builds the overlay showing `message`, then waits two frames so it actually
## paints before the caller starts its blocking work -- the same "await
## get_tree().process_frame" beat `title_screen.gd::_enter_world` already
## proved for this exact problem, just twice: the first frame lets the
## CanvasLayer enter the tree, the second lets the backdrop/label actually
## rasterize before the thread blocks.
static func present(tree: SceneTree, message: String) -> CanvasLayer:
	var overlay := build(tree)
	set_message(overlay, message)
	await tree.process_frame
	await tree.process_frame
	return overlay


## Removes `overlay` once the destination scene has had a frame to draw, so
## the crossing never shows a blank frame between the overlay disappearing
## and the new world's first real frame.
##
## `free()` rather than `queue_free()`: this call already waited a frame past
## the scene swap specifically so it is safe to remove `overlay` right now,
## and `queue_free()` only defers the removal to the END of that same frame —
## a caller that checks "is it gone yet" the instant `dismiss()` returns would
## still find it, since the deferred delete has not run yet.
static func dismiss(tree: SceneTree, overlay: CanvasLayer) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	await tree.process_frame
	if is_instance_valid(overlay):
		overlay.free()
