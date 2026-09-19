class_name CloudreachGrassRoles
extends RefCounted

## A continuous world-space height field shared by every ordinary Cloudreach
## grass pass. Roles alter only an accepted tuft's scale; placement, yaw and
## batching remain owned by the caller.

const LOW := 0
const MEDIUM := 1
const SPARSE_TALL := 2


static func role_at(at: Vector3, config: Dictionary) -> int:
	var field_scale: float = float(config.get("grass_role_field_scale", 1.0))
	var seed: float = float(config.get("grass_role_seed", 1909))
	var phase_x: float = float(config.get("grass_role_phase_x", 0.0)) + seed * 0.017
	var phase_z: float = float(config.get("grass_role_phase_z", 0.0)) + seed * 0.029
	var x: float = at.x * field_scale
	var z: float = at.z * field_scale
	var field: float = sin(x * 0.075 + phase_x + sin(z * 0.031 + phase_z)) * 0.55
	field += sin(z * 0.051 - x * 0.023 + phase_z - phase_x) * 0.35
	field += sin(x * 0.137 + z * 0.109 + phase_x * 0.37) * 0.10
	if field >= float(config.get("grass_role_tall_threshold", 0.72)):
		return SPARSE_TALL
	if field >= float(config.get("grass_role_medium_threshold", 0.25)):
		return MEDIUM
	return LOW


static func role_name(role: int) -> StringName:
	if role == SPARSE_TALL:
		return &"sparse_tall"
	if role == MEDIUM:
		return &"medium"
	return &"low"


static func scales(at: Vector3, height_jitter: float, width_jitter: float,
		height_multiplier: float, config: Dictionary, tall_eligible: bool = true) -> Vector3:
	var role: int = role_at(at, config)
	return scales_for_role(role, height_jitter, width_jitter, height_multiplier, config,
		tall_eligible)


static func scales_for_role(role: int, height_jitter: float, width_jitter: float,
		height_multiplier: float, config: Dictionary, tall_eligible: bool = true) -> Vector3:
	if role == SPARSE_TALL and not tall_eligible:
		role = MEDIUM
	var min_height: float
	var max_height: float
	if role == SPARSE_TALL:
		min_height = float(config.get("grass_role_tall_height_min_m", 0.90))
		max_height = float(config.get("grass_role_tall_height_max_m", 1.10))
	elif role == MEDIUM:
		min_height = float(config.get("grass_role_medium_height_min_m", 0.65))
		max_height = float(config.get("grass_role_medium_height_max_m", 0.85))
	else:
		min_height = float(config.get("grass_role_low_height_min_m", 0.40))
		max_height = float(config.get("grass_role_low_height_max_m", 0.60))
	var height: float = lerpf(min_height, max_height, clampf(height_jitter, 0.0, 1.0))
	height *= height_multiplier
	var width_multiplier: float = lerpf(
		float(config.get("grass_role_width_multiplier_min", 2.5)),
		float(config.get("grass_role_width_multiplier_max", 2.9)),
		clampf(width_jitter, 0.0, 1.0))
	var width: float = height * width_multiplier
	return Vector3(width, height, width)


static func unit_jitter(value: float, range_min: float, range_max: float) -> float:
	if is_equal_approx(range_min, range_max):
		return 0.5
	return clampf(inverse_lerp(range_min, range_max, value), 0.0, 1.0)
