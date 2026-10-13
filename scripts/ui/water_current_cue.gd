extends Control

## Local read-only HUD. Arrow shape and text carry the cue without colour or
## motion dependence. No input handlers, RPCs, physics writes or saved flags.
const POLICY := preload("res://scripts/ui/water_current_cue_policy.gd")
const STATE := preload("res://scripts/player/swim_state.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var _world: Node3D
var _cfg: Dictionary
var _direction := Vector2.ZERO
var _text := ""
var _scale := 1.0


static func install(world: Node3D) -> void:
	var cfg := POLICY.config()
	if not bool(cfg.get("enabled", false)) or bool(world.get("simulation_only")):
		return
	var layer := CanvasLayer.new()
	layer.name = "WaterCurrentCue"
	layer.layer = 5
	world.add_child(layer)
	var cue := new()
	cue._world = world
	cue._cfg = cfg
	cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cue.focus_mode = Control.FOCUS_NONE
	cue.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(cue)


func _process(_delta: float) -> void:
	visible = false
	if not is_instance_valid(_world) or get_tree().paused or INPUT_OWNER.current(get_tree()) != null:
		return
	var game := get_node_or_null("/root/Game")
	if game == null or not POLICY.preferred(game.call("_preferences")):
		return
	var player: CharacterBody3D = _world.call("local_rig")
	if player == null:
		return
	var vitals: RefCounted = player.get("vitals")
	if vitals != null and vitals.is_dead():
		return
	var swim: Node = player.get("swim_controller")
	if swim == null or int(swim.state.mode) not in [STATE.Mode.HUMAN, STATE.Mode.MOUNTED]:
		return
	var combat := _world.get_node_or_null("CombatManager")
	var encounters := _world.get_node_or_null("EncounterDirector")
	if (combat != null and combat.is_fighting()) or (encounters != null and encounters.trainer_battle_active()):
		return
	var subject: Node3D = player
	var riding := _world.get_node_or_null("RidingController")
	if riding != null and riding.is_mounted():
		if bool(riding.diving):
			return
		subject = riding.mount_body()
	if not is_instance_valid(subject):
		return
	var flow: Vector3 = _world.call("current_at", subject.global_position)
	if not flow.is_finite() or flow.length() < float(_cfg.minimum_speed_m_s):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind(subject.global_position):
		return
	var raster := get_viewport_rect()
	var anchor := camera.unproject_position(subject.global_position)
	if not raster.has_point(anchor):
		return
	_direction = POLICY.direction(flow, camera.global_basis)
	if _direction == Vector2.ZERO:
		return
	_scale = raster.size.y / 720.0
	var offset: Array = _cfg.offset_px_720
	position = anchor + Vector2(float(offset[0]), float(offset[1])) * _scale
	position = position.clamp(Vector2(100, 60) * _scale, raster.size - Vector2(100, 80) * _scale)
	_text = str(_cfg.strong_label) if flow.length() >= float(_cfg.strong_speed_m_s) else str(_cfg.label)
	visible = true
	queue_redraw()


func _draw() -> void:
	var foreground := Color(str(_cfg.foreground))
	var background := Color(str(_cfg.background))
	var length := float(_cfg.arrow_length_px_720) * _scale
	var width := float(_cfg.arrow_width_px_720) * _scale
	var side := Vector2(-_direction.y, _direction.x)
	var tip := _direction * length * 0.5
	var tail := -_direction * length * 0.5
	var neck := tip - _direction * width
	var arrow := PackedVector2Array([tip, neck + side * width, neck + side * width * 0.33,
		tail + side * width * 0.33, tail - side * width * 0.33, neck - side * width * 0.33, neck - side * width])
	draw_circle(Vector2.ZERO, length * 0.65, background)
	draw_colored_polygon(arrow, foreground)
	var font := ThemeDB.fallback_font
	var font_size := maxi(1, roundi(float(_cfg.font_size_px_720) * _scale))
	var text_size := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(-text_size.x * 0.5, length * 0.65 + text_size.y)
	draw_style_box(_label_box(background), Rect2(Vector2(-text_size.x * 0.5 - 6, length * 0.65 + 5), text_size + Vector2(12, 5)))
	draw_string(font, baseline, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, foreground)


func _label_box(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(4)
	return box
