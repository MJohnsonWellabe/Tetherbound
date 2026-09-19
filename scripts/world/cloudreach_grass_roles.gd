class_name CloudreachGrassRoles
extends RefCounted

## A continuous world-space role field shared by every ordinary Cloudreach
## grass pass. Roles alter only an accepted tuft's scale; placement, yaw and
## batching remain owned by the caller.

const LOW := 0
const MEDIUM := 1
const SPARSE_TALL := 2

static var _distance_noise: FastNoiseLite
static var _value_noise: FastNoiseLite
static var _cached_seed: int = -2147483648
static var _cached_frequency: float = -1.0
static var _cached_jitter: float = -1.0


static func role_at(at: Vector3, config: Dictionary) -> int:
	var seed: int = int(config.get("grass_role_seed", 1909))
	var frequency: float = float(config.get("grass_role_cell_frequency", 0.10))
	var jitter: float = float(config.get("grass_role_cell_jitter", 1.0))
	_ensure_noises(seed, frequency, jitter)
	var radius: float = _distance_noise.get_noise_2d(at.x, at.z) + 1.0
	var cell_value: float = _value_noise.get_noise_2d(at.x, at.z)
	if radius <= float(config.get("grass_role_tall_radius", 0.15)) \
			and cell_value > float(config.get("grass_role_tall_cell_value_min", 0.20)):
		return SPARSE_TALL
	if radius <= float(config.get("grass_role_medium_radius", 0.32)):
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


static func _ensure_noises(seed: int, frequency: float, jitter: float) -> void:
	if _distance_noise != null and _value_noise != null and seed == _cached_seed \
			and is_equal_approx(frequency, _cached_frequency) \
			and is_equal_approx(jitter, _cached_jitter):
		return
	_cached_seed = seed
	_cached_frequency = frequency
	_cached_jitter = jitter
	_distance_noise = FastNoiseLite.new()
	_distance_noise.seed = seed
	_distance_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_distance_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_distance_noise.frequency = frequency
	_distance_noise.cellular_jitter = jitter
	_distance_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_distance_noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	_value_noise = FastNoiseLite.new()
	_value_noise.seed = seed
	_value_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	_value_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_value_noise.frequency = frequency
	_value_noise.cellular_jitter = jitter
	_value_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_value_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
