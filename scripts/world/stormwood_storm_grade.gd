extends Node

## F41 chapter-wide storm light grade (stormwood_look.json `storm_grade`, OFF
## until judged). GPU SW13 and SW19 judges (15/15): "the scene does not carry
## the storm". Two parts, both following the surge phase every frame:
## - a camera-relative rim: a shadowless directional light that always comes
##   from beyond the subject toward the camera, a little above, so trunks,
##   creatures and the trainer get a lit edge in every view (the r26 rim was
##   world-fixed and lit edges in some views only), its colour and energy per
##   phase and lifted by the surge flash at Break;
## - a per-phase world grade: environment brightness, contrast and saturation,
##   eased between phases.
## Presentation only; reduced motion keeps the grade and drops the pulse.
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")

var config: Dictionary = {}
var _rim: DirectionalLight3D
var _surge: Node
var _env: Environment
var _grade := Vector3(1.0, 1.0, 1.0)
var _rim_energy := 0.0
var _rim_colour := Color.WHITE


func _ready() -> void:
	_rim = DirectionalLight3D.new()
	_rim.name = "StormPhaseRim"
	_rim.shadow_enabled = false
	_rim.light_specular = float(config.get("rim_specular", 0.5))
	_rim.light_energy = 0.0
	get_parent().add_child.call_deferred(_rim)


func _look(phase: String) -> Dictionary:
	return (config.get("phases", {}) as Dictionary).get(phase, {})


func _process(delta: float) -> void:
	var world := get_parent()
	if world == null:
		return
	if _surge == null or not is_instance_valid(_surge):
		_surge = world.find_child("StormwoodSurge", true, false)
	if _env == null:
		var look := world.get_node_or_null("WorldLook")
		if look != null:
			var holder := look.get_node_or_null(look.get("environment_path")) as WorldEnvironment
			if holder != null:
				_env = holder.environment
	var phase := str(_surge.get("phase")) if _surge != null else "calm"
	var flash := float(_surge.call("flash_level")) if _surge != null and _surge.has_method("flash_level") else 0.0
	if MOTION_PREFS.reduced_motion():
		flash = 0.0
	var look_cfg := _look(phase)
	var ease := clampf(delta * float(config.get("ease_per_s", 0.8)), 0.0, 1.0)
	var target_rim := float(look_cfg.get("rim_energy", 0.6))
	_rim_energy = lerpf(_rim_energy, target_rim, ease)
	_rim_colour = _rim_colour.lerp(Color(str(look_cfg.get("rim_colour", "#a9b8ff"))), ease)
	if _rim != null and _rim.is_inside_tree():
		_rim.light_color = _rim_colour
		_rim.light_energy = _rim_energy * (1.0 + flash * float(config.get("flash_rim_gain", 2.0)))
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			var forward := -camera.global_transform.basis.z
			forward.y = 0.0
			if forward.length() > 0.01:
				forward = forward.normalized()
				var elevation := deg_to_rad(float(config.get("rim_elevation_deg", 22.0)))
				# Travel toward the camera from beyond the subject, slightly down.
				var travel := (-forward * cos(elevation) + Vector3.DOWN * sin(elevation)).normalized()
				_rim.global_transform = Transform3D(Basis.looking_at(travel, Vector3.UP), Vector3.ZERO)
	if _env != null:
		var grade: Array = look_cfg.get("grade", [1.0, 1.0, 1.0])
		_grade = _grade.lerp(Vector3(float(grade[0]), float(grade[1]), float(grade[2])), ease)
		_env.adjustment_enabled = true
		_env.adjustment_brightness = _grade.x
		_env.adjustment_contrast = _grade.y
		_env.adjustment_saturation = _grade.z
