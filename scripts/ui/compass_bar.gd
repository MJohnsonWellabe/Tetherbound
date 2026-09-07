extends Control

## Exploration navigation at a glance. The centre notch is the camera's
## current bearing; the heading tape scrolls beneath it. A selected map
## destination is drawn on the same tape and clamps to an edge chevron when it
## falls outside the visible 120-degree window.

const HALF_ARC_DEG := 60.0
const MINOR_STEP_DEG := 15
const MAJOR_STEP_DEG := 45
const EDGE_INSET := 26.0
const YAW_EPSILON := 0.002
const MOVE_EPSILON := 0.05

const DIRECTIONS := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

var _map_state: RefCounted = null
var _player_pos := Vector3.ZERO
var _look_yaw := 0.0
var _has_sample := false
var _last_map_revision := -1
var _font: Font = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(560.0, 82.0)
	_font = load(UITokens.FONT_PATH)


## Extra arguments preserve the old HUD/realm-runtime configure seam while
## callers move from a terrain-backed minimap to this data-only compass.
func configure(map_state: RefCounted, _unused_terrain: Texture2D = null, _unused_span_m: float = 0.0) -> void:
	_map_state = map_state
	_last_map_revision = -1
	queue_redraw()


func update_view(player_pos: Vector3, look_yaw_rad: float, _unused_creature_pos: Variant = null) -> void:
	var moved := not _has_sample or player_pos.distance_to(_player_pos) > MOVE_EPSILON
	var turned := not _has_sample or absf(angle_difference(_look_yaw, look_yaw_rad)) > YAW_EPSILON
	var revision := int(_map_state.get("revision")) if _map_state != null else -1
	_player_pos = player_pos
	_look_yaw = look_yaw_rad
	_has_sample = true
	if moved or turned or revision != _last_map_revision:
		_last_map_revision = revision
		queue_redraw()


func set_dim(dim: float) -> void:
	modulate = Color(1.0, 1.0, 1.0, clampf(dim, 0.0, 1.0))


static func heading_degrees(yaw_rad: float) -> float:
	# Project yaw 0 faces world +Z (south); compass 0 is world -Z (north).
	# Positive project yaw turns toward +X, so compass degrees decrease from
	# south toward east rather than following mathematical angle direction.
	return fposmod(180.0 - rad_to_deg(yaw_rad), 360.0)


static func bearing_degrees(from: Vector2, to: Vector2) -> float:
	var offset := to - from
	if offset.length_squared() <= 0.0001:
		return 0.0
	return heading_degrees(atan2(offset.x, offset.y))


static func signed_heading_delta(heading_deg: float, bearing_deg: float) -> float:
	return rad_to_deg(angle_difference(deg_to_rad(heading_deg), deg_to_rad(bearing_deg)))


static func tape_x(delta_deg: float, width: float) -> float:
	return width * 0.5 + clampf(delta_deg, -HALF_ARC_DEG, HALF_ARC_DEG) / HALF_ARC_DEG * (width * 0.5 - EDGE_INSET)


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	var tape := Rect2(Vector2(18.0, 8.0), Vector2(size.x - 36.0, 52.0))
	draw_style_box(UITokens.panel_box(), box)
	draw_rect(tape, Color(UITokens.BG_DEEP, 0.82), true)
	draw_line(Vector2(tape.position.x, tape.end.y), Vector2(tape.end.x, tape.end.y), Color(UITokens.TEAL, 0.55), 2.0)

	var heading := heading_degrees(_look_yaw)
	var first_tick := int(floor((heading - HALF_ARC_DEG) / MINOR_STEP_DEG)) * MINOR_STEP_DEG
	var last_tick := int(ceil((heading + HALF_ARC_DEG) / MINOR_STEP_DEG)) * MINOR_STEP_DEG
	for raw_deg in range(first_tick, last_tick + MINOR_STEP_DEG, MINOR_STEP_DEG):
		var wrapped := fposmod(float(raw_deg), 360.0)
		var delta := signed_heading_delta(heading, wrapped)
		if absf(delta) > HALF_ARC_DEG + 0.01:
			continue
		var x := tape_x(delta, tape.size.x) + tape.position.x
		var major := posmod(raw_deg, MAJOR_STEP_DEG) == 0
		var tick_top := tape.position.y + (7.0 if major else 16.0)
		draw_line(Vector2(x, tick_top), Vector2(x, tape.position.y + 25.0), UITokens.TEXT_SECONDARY, 2.0 if major else 1.0)
		if major and _font != null:
			var direction_index := posmod(int(round(wrapped / MAJOR_STEP_DEG)), DIRECTIONS.size())
			_draw_centred_text(Vector2(x, tape.position.y + 46.0), DIRECTIONS[direction_index], 24, UITokens.TEXT_PRIMARY)

	# Fixed centre notch: the tape moves, the player's actual forward does not.
	var centre_x := size.x * 0.5
	var notch := PackedVector2Array([
		Vector2(centre_x, 2.0), Vector2(centre_x - 8.0, 12.0), Vector2(centre_x + 8.0, 12.0),
	])
	draw_colored_polygon(notch, UITokens.WARNING)

	var destination := _destination_marker()
	if destination.is_empty():
		_draw_centred_text(Vector2(centre_x, size.y - 8.0), "%03d°" % int(round(heading)), 20, UITokens.TEXT_SECONDARY)
		return
	var target: Vector2 = destination.get("position", Vector2.ZERO)
	var here := Vector2(_player_pos.x, _player_pos.z)
	var target_bearing := bearing_degrees(here, target)
	var delta := signed_heading_delta(heading, target_bearing)
	var marker_x := tape.position.x + tape_x(delta, tape.size.x)
	var clamped := absf(delta) > HALF_ARC_DEG
	_draw_destination_marker(Vector2(marker_x, tape.position.y + 28.0), signf(delta), clamped)
	var distance := int(round(here.distance_to(target)))
	var label := str(destination.get("display_name", "Destination"))
	if label.is_empty():
		label = "Destination"
	# Quest prose belongs in the objective card; the narrow navigation tape
	# needs a glanceable noun. Keep short authored place names, collapse long
	# sentences so bearing and distance never clip at handheld width.
	if label.length() > 24:
		label = "OBJECTIVE"
	_draw_centred_text(Vector2(centre_x, size.y - 7.0), "%s  ·  %d m" % [label, distance], 21, UITokens.WARNING)


func _destination_marker() -> Dictionary:
	if _map_state == null or not _map_state.has_method("landmarks"):
		return {}
	var objective: Dictionary = {}
	for marker: Dictionary in (_map_state.call("landmarks") as Array):
		var marker_id := str(marker.get("id", ""))
		if marker_id == "destination":
			return marker
		if marker_id == "objective":
			objective = marker
	return objective


func _draw_destination_marker(at: Vector2, direction: float, clamped: bool) -> void:
	if clamped:
		var outward := 1.0 if direction >= 0.0 else -1.0
		var points := PackedVector2Array([
			at + Vector2(outward * 10.0, 0.0),
			at + Vector2(-outward * 4.0, -8.0),
			at + Vector2(-outward * 4.0, 8.0),
		])
		draw_colored_polygon(points, UITokens.WARNING)
		return
	var r := 7.0
	var diamond := PackedVector2Array([
		at + Vector2.UP * r, at + Vector2.RIGHT * r,
		at + Vector2.DOWN * r, at + Vector2.LEFT * r,
	])
	draw_colored_polygon(diamond, UITokens.WARNING)
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), UITokens.TEXT_PRIMARY, 1.5, true)


func _draw_centred_text(baseline: Vector2, text: String, font_size: int, colour: Color) -> void:
	if _font == null:
		return
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var at := baseline - Vector2(width * 0.5, 0.0)
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, UITokens.OUTLINE_SIZE, UITokens.OUTLINE)
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, colour)
