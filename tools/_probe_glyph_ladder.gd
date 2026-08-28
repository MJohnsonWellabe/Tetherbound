extends SceneTree

## HUD-SCALE. The glyph floor, rendered rather than argued.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_probe_glyph_ladder.gd -- --out=shots/hud_scale
##
## `input_glyph.gd::icon()`'s header sets this HUD's whole size floor on one
## claim: 36 authored px was "the smallest step that read clearly" for a glyph
## with baked lettering. Every HUD constant since has been scaled off that,
## and off a 0.667 content scale the owner's 1920x1080 device does not have.
##
## The claim is checkable. This draws the pad glyphs the exploration legend
## and the quick-bar actually use, plus a text sample, at every authored size
## in the ladder -- so the floor is set from a real render of the real assets
## at the real authoring resolution instead of from a remembered crop test.
## Alongside each row it prints the angular size that authored height lands at
## on the owner's panel, which is the number that does not change with render
## resolution.

const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const LADDER: Array[int] = [16, 20, 22, 24, 26, 28, 32, 36, 44, 66]
const ACTIONS: Array[String] = ["party_cycle", "creature_recall", "inventory", "map"]

const PANEL_DIAGONAL_INCHES := 7.0
const VIEW_DISTANCE_MM := 450.0

var _out_dir := "res://shots/hud_scale"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	for i in 4:
		await process_frame

	# Pinned to gamepad for `_capture_ui_survey.gd::_pin_owner_device()`'s
	# reason: under xvfb no pad is connected, so `using_gamepad()` reports the
	# keyboard half and the ladder would photograph keycaps the owner's
	# hardware never shows.
	var game := root.get_node_or_null(^"Game")
	if game != null:
		game.set("_last_input_was_gamepad", true)

	var world := Node3D.new()
	world.name = "LadderWorld"
	root.add_child(world)
	current_scene = world

	var layer := CanvasLayer.new()
	world.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("#1b2a33")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var rows := VBoxContainer.new()
	rows.position = Vector2(60.0, 40.0)
	rows.custom_minimum_size = Vector2(1800.0, 0.0)
	rows.add_theme_constant_override("separation", 12)
	layer.add_child(rows)

	var panel_w_mm := PANEL_DIAGONAL_INCHES * 25.4 * 16.0 / sqrt(16.0 * 16.0 + 9.0 * 9.0)
	var mm_per_px := panel_w_mm / 1920.0

	for px: int in LADDER:
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		line.custom_minimum_size = Vector2(1800.0, float(px) + 16.0)
		var arcmin := atan(float(px) * mm_per_px / VIEW_DISTANCE_MM) * 180.0 * 60.0 / PI
		var parts := PackedStringArray()
		parts.append("[font_size=%d]%2d px / %4.1f'[/font_size]  " % [maxi(px, 22), px, arcmin])
		for action: String in ACTIONS:
			parts.append(INPUT_GLYPH.icon(action, px, Color.WHITE))
			parts.append("  ")
		parts.append("[font_size=%d]Change Creature  Lv 1  x12[/font_size]" % px)
		line.text = "".join(parts)
		rows.add_child(line)

	for i in 20:
		await process_frame
	var img := get_root().get_texture().get_image()
	var path := "%s/glyph_ladder.png" % _out_dir
	img.save_png(ProjectSettings.globalize_path(path))
	print("wrote %s" % path)
	print("panel %.2f mm wide; 1 authored px = %.4f mm; view %.0f mm" % [panel_w_mm, mm_per_px, VIEW_DISTANCE_MM])
	quit(0)
