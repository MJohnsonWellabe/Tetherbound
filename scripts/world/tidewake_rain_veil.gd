extends GPUParticles3D

## close-1024 `rain_veil_candidate` (OFF in play): the shared WorldWeather ring
## falls 6.5-20 m around the player in 0.9 m streaks, so from any eye more than
## a few tens of metres off (the Veilfall vista, a flyer) Tidewake rain reads
## as clear weather under a grey sky. A far layer centred on the active camera:
## longer, wider streaks in a wide ring that keeps its own inner radius clear
## of the lens. Presentation only; weather state is unchanged.

var _cfg: Dictionary = {}


func configure(cfg: Dictionary) -> void:
	_cfg = cfg
	name = "TidewakeRainVeil"
	var inner := float(cfg.get("inner_radius_m", 25.0))
	var outer := float(cfg.get("outer_radius_m", 140.0))
	var height := float(cfg.get("ring_height_m", 80.0))
	var fall := float(cfg.get("fall_speed_m_s", 24.0))
	amount = int(cfg.get("amount", 6000))
	lifetime = float(cfg.get("lifetime_s", 2.4))
	preprocess = lifetime
	local_coords = true
	emitting = false
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3(-outer - 2.0, -height - fall * lifetime, -outer - 2.0),
		Vector3(outer * 2.0 + 4.0, height * 2.0 + fall * lifetime, outer * 2.0 + 4.0))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process.emission_ring_axis = Vector3.UP
	process.emission_ring_height = height
	process.emission_ring_radius = outer
	process.emission_ring_inner_radius = inner
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 3.0
	process.gravity = Vector3.ZERO
	process.initial_velocity_min = fall * 0.9
	process.initial_velocity_max = fall * 1.1
	var colour := Color(str(cfg.get("colour", "#d4dde699")))
	process.color = colour
	process_material = process
	var streak := BoxMesh.new()
	var size: Array = cfg.get("streak_size_m", [0.12, 5.0])
	streak.size = Vector3(float(size[0]), float(size[1]), float(size[0]))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = colour
	streak.material = material
	draw_pass_1 = streak


func set_raining(raining: bool) -> void:
	emitting = raining
	visible = raining
	_follow()


func _process(_delta: float) -> void:
	if visible:
		_follow()


func _follow() -> void:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera != null:
		global_position = camera.global_position + Vector3(0.0, float(_cfg.get("lift_m", 20.0)), 0.0)
