extends Control

## Does not participate in row sizing or input. The existing strip owns layout.
var state: Dictionary = {}
var tick_data: Dictionary = {}
var tick_left := 0.0
var elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE


func update_state(value: Dictionary, tick: Dictionary, seconds: float) -> void:
	state = value
	if state.is_empty():
		tick_data.clear()
		tick_left = 0.0
		for content: Node in get_parent().get_children():
			if content != self and content is CanvasItem:
				content.modulate.a = 1.0
	if not tick.is_empty():
		tick_data = tick
		tick_left = seconds
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	tick_left = maxf(0, tick_left - delta)
	var row := get_parent() as Control
	if row != null and not state.is_empty():
		row.modulate.a = 1.0
		for content: Node in row.get_children():
			if content != self and content is CanvasItem:
				content.modulate.a = 0.0
	if not state.is_empty():
		queue_redraw()


func _draw() -> void:
	if state.is_empty():
		return
	draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color(0.05, 0.12, 0.15, 1.0))
	var font := ThemeDB.fallback_font
	var portrait: Texture2D = state.get("portrait")
	if portrait != null:
		draw_texture_rect(portrait, Rect2(7, 7, 27, 27), false)
	else:
		draw_rect(Rect2(8, 9, 23, 23), Color(0.22, 0.55, 0.5))
	var name := "%s  Lv%d" % [state.get("label", ""), int(state.get("level", 1))]
	draw_string(font, Vector2(40, 21), name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 128, 18, Color(0.95, 0.98, 0.97))
	var tag := "KO" if bool(state.get("fainted", false)) else ("REST" if bool(state.get("resting", false)) else "")
	if tick_left > 0 and int(tick_data.get("xp", 0)) > 0:
		tag = "+%d XP" % int(tick_data.xp)
	var tag_color := Color(1, 0.55, 0.5) if tag == "KO" else Color(0.84, 1, 0.78)
	draw_string(font, Vector2(size.x - 82, 21), tag, HORIZONTAL_ALIGNMENT_RIGHT, 72, 16, tag_color)
	var bond_text := "Bond %d/5" % int(state.get("bond", 0))
	var bond_light := 0.7 + 0.3 * sin(elapsed * TAU / maxf(0.1, float(state.get("pulse_seconds", 1.6)))) if bool(state.get("bond_near", false)) else 1.0
	for index in 5:
		var earned := index < int(state.get("bond", 0))
		var next := index == int(state.get("bond", 0))
		var lit := earned or (next and (bool(state.get("bond_near", false)) or (tick_left > 0 and tick_data.has("bond_reason"))))
		draw_circle(Vector2(9 + index * 5, 40), 1.6, Color(0.65, 0.95, 0.8, bond_light) if lit else Color(0.18, 0.3, 0.29))
	if tick_left > 0 and tick_data.has("bond_reason"):
		bond_text = "Bond grows: " + str(tick_data.bond_reason)
	var progress := "EXP %d/%d · %s" % [int(state.get("xp", 0)), int(state.get("xp_to_next", 1)), bond_text]
	draw_string(font, Vector2(40, 38), progress, HORIZONTAL_ALIGNMENT_LEFT, size.x - 47, 16, Color(0.67, 0.86, 0.83))
	draw_rect(Rect2(size.x - 39, 6, 29, 3), Color(0.15, 0.2, 0.2))
	draw_rect(Rect2(size.x - 39, 6, 29 * float(state.get("hp_fraction", 1)), 3), Color(0.36, 0.8, 0.4))
	var xp_fraction := clampf(float(state.get("xp", 0)) / maxf(1, float(state.get("xp_to_next", 1))), 0, 1)
	var pulse := 0.72 + 0.28 * sin(elapsed * TAU / maxf(0.1, float(state.get("pulse_seconds", 1.6)))) if bool(state.get("near", false)) else 1.0
	draw_rect(Rect2(6, size.y - 5, maxf(0, size.x - 12), 3), Color(0.07, 0.11, 0.13, 0.9))
	draw_rect(Rect2(6, size.y - 5, maxf(0, size.x - 12) * xp_fraction, 3), Color(0.39, 0.84, 0.81, pulse))
