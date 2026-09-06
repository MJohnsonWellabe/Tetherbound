extends RefCounted

## Pure Water base terrain. No nodes, Terrain3D, state or random calls.
## The baker and depth queries share this surface; sparse region membership
## controls only where analytic seabed is represented, never island identity.
## Trails/arenas must be explicit later modifiers: this does not grade a hike.

const CONFIG_PATH := "res://data/config/water_world.json"

var _config: Dictionary = {}
var _sea_level := 0.0
var _seabed_depth := 65.0
var _outer_slope := 0.35
var _region_pitch := 256.0
var _regions: Dictionary = {}
var _ids: Array[String] = []
var _cx := PackedFloat64Array()
var _cz := PackedFloat64Array()
var _radius := PackedFloat64Array()
var _peak := PackedFloat64Array()
var _power := PackedFloat64Array()
var _beach_width := PackedFloat64Array()
var _inner_height := PackedFloat64Array()
var _sectors: Array = []


static func load_config(path: String = CONFIG_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _init(config: Dictionary = {}) -> void:
	_config = (config if not config.is_empty() else load_config()).duplicate(true)
	var terrain: Dictionary = _config.get("terrain", {})
	_sea_level = float(terrain.get("sea_level_m", 0.0))
	_seabed_depth = maxf(0.0, float(terrain.get("seabed_depth_m", 65.0)))
	_outer_slope = maxf(0.0001, float(terrain.get("outer_shore_slope", 0.35)))
	_region_pitch = maxf(0.001, float(terrain.get("region_size", 256)) * float(terrain.get("vertex_spacing", 1.0)))
	for pair: Array in terrain.get("region_locations", []):
		_regions[Vector2i(int(pair[0]), int(pair[1]))] = true
	for spec: Dictionary in _config.get("islands", []):
		var centre: Array = spec.get("center_xz_m", [])
		var radius := float(spec.get("shore_radius_m", 0.0))
		if centre.size() != 2 or radius <= 0.0:
			continue
		_ids.append(str(spec.get("id", "")))
		_cx.append(float(centre[0]))
		_cz.append(float(centre[1]))
		_radius.append(radius)
		_peak.append(float(spec.get("peak_height_m", 0.0)))
		_power.append(maxf(0.001, float(spec.get("peak_power", 1.65))))
		_beach_width.append(clampf(float(spec.get("coast_beach_width_m", 4.0)), 0.001, radius * 0.999))
		_inner_height.append(float(spec.get("coast_inner_height_m", 12.0)))
		# Compile each sector once, avoiding JSON lookups per terrain texel.
		var sectors: Array = []
		for sector: Dictionary in spec.get("landing_sectors", []):
			sectors.append([
				deg_to_rad(float(sector.get("angle_deg", 0.0))),
				deg_to_rad(maxf(0.0, float(sector.get("half_width_deg", 7.5)))),
				deg_to_rad(maxf(0.0001, float(sector.get("feather_deg", 3.0)))),
				clampf(float(sector.get("beach_width_m", 28.0)), 0.001, radius * 0.999),
				float(sector.get("inner_height_m", 3.0)),
			])
		_sectors.append(sectors)


func water_level() -> float:
	return _sea_level


func seabed_height() -> float:
	return _sea_level - _seabed_depth


## No sparse list means an unrestricted analytic field, useful for isolated
## island authoring. The production config explicitly lists its baked regions.
func has_terrain_region_at(x: float, z: float) -> bool:
	if not is_finite(x) or not is_finite(z):
		return false
	if _regions.is_empty():
		return true
	return _regions.has(Vector2i(floori(x / _region_pitch), floori(z / _region_pitch)))


func height_at(x: float, z: float) -> float:
	if not is_finite(x) or not is_finite(z):
		return NAN
	var best := seabed_height()
	if not has_terrain_region_at(x, z):
		return best
	var reach := _seabed_depth / _outer_slope
	for index in _ids.size():
		var dx := x - _cx[index]
		var dz := z - _cz[index]
		var extent := _radius[index] + reach
		if absf(dx) > extent or absf(dz) > extent:
			continue
		best = maxf(best, _height_for(index, dx, dz))
	return best


## Island membership is dry land by default; callers may explicitly include
## a shoreline apron. Open water returns "", not a falsely claimed island.
func island_id_at(x: float, z: float, shore_margin_m: float = 0.0) -> String:
	if not is_finite(x) or not is_finite(z):
		return ""
	var found := ""
	var highest := -INF
	for index in _ids.size():
		var dx := x - _cx[index]
		var dz := z - _cz[index]
		var radius := _radius[index] + maxf(0.0, shore_margin_m)
		if dx * dx + dz * dz > radius * radius:
			continue
		var height := _height_for(index, dx, dz)
		if height > highest:
			highest = height
			found = _ids[index]
	return found


## Navigation/recovery may need a nearby island while swimming. This resolves
## distance to shoreline, which differs from nearest centre for unequal radii.
func nearest_island_id(x: float, z: float) -> String:
	if not is_finite(x) or not is_finite(z):
		return ""
	var containing := island_id_at(x, z)
	if not containing.is_empty():
		return containing
	var nearest := ""
	var distance := INF
	for index in _ids.size():
		var gap := sqrt(pow(x - _cx[index], 2.0) + pow(z - _cz[index], 2.0)) - _radius[index]
		if gap < distance:
			distance = gap
			nearest = _ids[index]
	return nearest


func normal_at(x: float, z: float, step: float = 1.0) -> Vector3:
	var sample_step := maxf(0.001, step)
	return Vector3(
		height_at(x - sample_step, z) - height_at(x + sample_step, z),
		2.0 * sample_step,
		height_at(x, z - sample_step) - height_at(x, z + sample_step)
	).normalized()


func slope_degrees_at(x: float, z: float, step: float = 1.0) -> float:
	return rad_to_deg(acos(clampf(normal_at(x, z, step).y, -1.0, 1.0)))


func _height_for(index: int, dx: float, dz: float) -> float:
	var r := sqrt(dx * dx + dz * dz)
	var radius := _radius[index]
	if r > radius:
		return _sea_level - minf(_seabed_depth, (r - radius) * _outer_slope)
	var width := _beach_width[index]
	var inner := _inner_height[index]
	var angle := atan2(dz, dx)
	var strongest := 0.0
	for sector: Array in _sectors[index]:
		var distance := absf(wrapf(angle - float(sector[0]), -PI, PI))
		var weight := 1.0 - smoothstep(float(sector[1]), float(sector[1]) + float(sector[2]), distance)
		if weight > strongest:
			strongest = weight
			width = lerpf(_beach_width[index], float(sector[3]), weight)
			inner = lerpf(_inner_height[index], float(sector[4]), weight)
	var interior_radius := radius - width
	if r >= interior_radius:
		return _sea_level + inner * (radius - r) / width
	var factor := maxf(0.0, 1.0 - (r / interior_radius) * (r / interior_radius))
	return _sea_level + inner + (_peak[index] - inner) * pow(factor, _power[index])
