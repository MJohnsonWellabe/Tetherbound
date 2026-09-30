extends CanvasLayer

## F26 Ally route readout. Presentation-local and excluded from input ownership.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _label: Label


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 23)
	_label.add_theme_constant_override("outline_size", 3)
	_label.position = Vector2(20, 20)
	add_child(_label)


func _process(_delta: float) -> void:
	_label.visible = GRAPHICS.overlay_enabled()
	if not _label.visible:
		return
	var fps := Engine.get_frames_per_second()
	_label.text = "%s · %s · %d fps · %.1f ms" % [GRAPHICS.selected(), RenderingServer.get_current_rendering_method(), fps, 1000.0 / maxf(float(fps), 1.0)]
