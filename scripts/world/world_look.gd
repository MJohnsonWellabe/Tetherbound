extends Node

## Applies data/config/art.json to the scene's light and environment.
##
## These values existed in the config for a whole art pass and nothing read
## them. The scene kept the sun and environment it was authored with, so every
## "the lighting is too flat" fix was written into a file the game ignored — and
## the blind critic measured the result: the darkest one percent of an entire
## exploration frame was luminance 129, a mid-tone, where the references reach
## single digits.
##
## So the rule the rest of the project already follows applies here too: if a
## number can be argued about, it lives in data, and something must actually
## read it.

const CONFIG_PATH := "res://data/config/art.json"

@export var sun_path: NodePath
@export var environment_path: NodePath


func _ready() -> void:
	var cfg := _load()
	if cfg.is_empty():
		push_warning("art.json missing or unreadable; the scene keeps its authored look")
		return
	_apply_sun(cfg.get("sun", {}))
	_apply_environment(cfg.get("environment", {}), cfg.get("sky", {}))


func _load() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## The single highest-leverage thing in the whole art pass.
##
## `05-spawn-low-sun` was the only survey frame with real darks and was, by the
## critic's own reading, visibly the best-looking one — which shows the gap is a
## sun angle and a shadow, not a fidelity ceiling.
func _apply_sun(cfg: Dictionary) -> void:
	var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
	if sun == null or cfg.is_empty():
		return

	sun.rotation = Vector3(
		deg_to_rad(float(cfg.get("pitch_deg", -46.0))),
		deg_to_rad(float(cfg.get("yaw_deg", -40.0))),
		0.0
	)
	sun.light_energy = float(cfg.get("energy", 1.25))
	sun.light_color = Color(str(cfg.get("colour", "#fff3e0")))
	sun.light_angular_distance = float(cfg.get("angular_distance", 0.6))

	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = float(cfg.get("shadow_max_distance", 220.0))
	# Normal bias fights the acne a heightmap terrain produces at grazing angles.
	# Raise it if the ground looks striped; lower it if small props stop casting.
	sun.shadow_normal_bias = float(cfg.get("shadow_normal_bias", 1.4))
	sun.shadow_bias = float(cfg.get("shadow_bias", 0.06))
	sun.shadow_blur = float(cfg.get("shadow_blur", 1.0))


func _apply_environment(cfg: Dictionary, sky_cfg: Dictionary) -> void:
	var holder: WorldEnvironment = get_node_or_null(environment_path) as WorldEnvironment
	if holder == null or holder.environment == null:
		return
	var env := holder.environment

	if not sky_cfg.is_empty() and env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
		var sky := env.sky.sky_material as ProceduralSkyMaterial
		sky.sky_top_color = Color(str(sky_cfg.get("top_colour", "#3b6f93")))
		sky.sky_horizon_color = Color(str(sky_cfg.get("horizon_colour", "#b9c8cf")))
		sky.ground_horizon_color = Color(str(sky_cfg.get("ground_horizon_colour", "#b9c8cf")))
		sky.ground_bottom_color = Color(str(sky_cfg.get("ground_bottom_colour", "#4a5648")))
		sky.sun_angle_max = float(sky_cfg.get("sun_angle_max_deg", 24.0))
		sky.sun_curve = float(sky_cfg.get("sun_curve", 0.18))

	if cfg.is_empty():
		return

	# ACES holds highlights on sunlit grass instead of clipping them to white,
	# which was the single worst thing about the previous prototype's look.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = float(cfg.get("exposure", 1.0))
	env.tonemap_white = float(cfg.get("white", 6.0))
	env.ambient_light_energy = float(cfg.get("ambient_energy", 1.0))
	# Ambient from the sky, dialled DOWN. Full-strength sky ambient fills every
	# shadow back in, which is precisely how a scene ends up with no darks.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = float(cfg.get("ambient_sky_contribution", 0.55))

	env.ssao_enabled = bool(cfg.get("ssao_enabled", true))
	env.ssao_intensity = float(cfg.get("ssao_intensity", 1.6))
	env.ssao_radius = float(cfg.get("ssao_radius", 1.2))

	env.fog_enabled = bool(cfg.get("fog_enabled", true))
	env.fog_light_color = Color(str(cfg.get("fog_colour", "#c4d2d8")))
	env.fog_density = float(cfg.get("fog_density", 0.0016))
	# Sky affect at zero, deliberately. Fog that tints the sky produces the hard
	# grey band the critic found across `03-rise-overlook`, where the terrain rose
	# out of a white void.
	env.fog_sky_affect = float(cfg.get("fog_sky_affect", 0.0))
	env.fog_aerial_perspective = float(cfg.get("aerial_perspective", 0.4))
