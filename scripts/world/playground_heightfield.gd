extends RefCounted

## The M1 playground's shape, as a pure function of position.
##
## Separated from the Terrain3D import so it can be unit tested without the
## engine's terrain system, and so the same recipe can be re-baked at a
## different resolution without touching the importer.
##
## This is a fixed, seeded recipe for ONE authored test area. It is not a world
## generator and nothing calls it at runtime — `build_playground_terrain.gd`
## bakes it to disk once. The real Meadows is authored geography and replaces
## this entirely; see docs/decisions/D05-terrain3d-and-authored-geography.md.

const CONFIG_PATH := "res://data/config/terrain_playground.json"

var _config: Dictionary = {}
var _hills := FastNoiseLite.new()
var _detail := FastNoiseLite.new()


func _init(config: Dictionary = {}) -> void:
	_config = config if not config.is_empty() else load_config()

	var seed_value := int(_config.get("seed", 0))
	var hills: Dictionary = _config.get("hills", {})
	var detail: Dictionary = _config.get("detail", {})

	_hills.seed = seed_value
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hills.frequency = float(hills.get("frequency", 0.0035))
	_hills.fractal_octaves = int(hills.get("octaves", 4))

	# A different seed, or the two layers share their peaks and the detail
	# reinforces the hills instead of breaking them up.
	_detail.seed = seed_value + 1
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	_detail.frequency = float(detail.get("frequency", 0.018))
	_detail.fractal_octaves = int(detail.get("octaves", 3))


static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("terrain_playground.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Ground height in metres at a world XZ position.
func height_at(x: float, z: float) -> float:
	var hills: Dictionary = _config.get("hills", {})
	var detail: Dictionary = _config.get("detail", {})

	var height := _hills.get_noise_2d(x, z) * float(hills.get("amplitude", 15.0))
	height += _detail.get_noise_2d(x, z) * float(detail.get("amplitude", 2.2))

	height -= _valley_depth(x, z)
	height += _rise_height(x, z)
	height = _apply_spawn_pad(x, z, height)

	return height


func _valley_depth(x: float, z: float) -> float:
	var valley: Dictionary = _config.get("valley", {})
	if valley.is_empty():
		return 0.0
	var centre: Array = valley.get("centre", [0.0, 0.0])
	var radius := float(valley.get("radius", 150.0))
	if radius <= 0.0:
		return 0.0
	var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
	if distance >= radius:
		return 0.0
	# smoothstep rather than a linear cone, so the basin has no crease at its rim.
	var falloff := 1.0 - smoothstep(0.0, 1.0, distance / radius)
	return falloff * float(valley.get("depth", 22.0))


func _rise_height(x: float, z: float) -> float:
	var rises: Dictionary = _config.get("rises", {})
	var peaks: Array = rises.get("peaks", [])
	var sharpness := float(rises.get("sharpness", 2.1))
	var total := 0.0
	for entry: Variant in peaks:
		var peak: Dictionary = entry
		var centre: Array = peak.get("centre", [0.0, 0.0])
		var radius := float(peak.get("radius", 60.0))
		if radius <= 0.0:
			continue
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance >= radius:
			continue
		var t := 1.0 - (distance / radius)
		# pow above 1 steepens the flanks while keeping the summit rounded,
		# which is what makes these testable slopes rather than smooth domes.
		total += pow(smoothstep(0.0, 1.0, t), 1.0 / sharpness) * float(peak.get("height", 40.0))
	return total


func _apply_spawn_pad(x: float, z: float, height: float) -> float:
	var pad: Dictionary = _config.get("spawn_pad", {})
	if pad.is_empty():
		return height
	var centre: Array = pad.get("centre", [0.0, 0.0])
	var radius := float(pad.get("radius", 34.0))
	if radius <= 0.0:
		return height
	var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
	if distance >= radius:
		return height
	# Pull toward the height at the pad's own centre, strongest in the middle.
	var strength := float(pad.get("flatten", 0.85)) * (1.0 - smoothstep(0.0, 1.0, distance / radius))
	var centre_height := _raw_height(float(centre[0]), float(centre[1]))
	return lerpf(height, centre_height, strength)


## Height before the spawn pad flattening, used as the pad's own target so the
## pad does not recurse into itself.
func _raw_height(x: float, z: float) -> float:
	var hills: Dictionary = _config.get("hills", {})
	var detail: Dictionary = _config.get("detail", {})
	var height := _hills.get_noise_2d(x, z) * float(hills.get("amplitude", 15.0))
	height += _detail.get_noise_2d(x, z) * float(detail.get("amplitude", 2.2))
	height -= _valley_depth(x, z)
	height += _rise_height(x, z)
	return height


## Surface slope in degrees, sampled by central difference. Used to drive the
## ground colour and to sanity-check that the playground actually contains
## slopes worth testing against.
func slope_degrees_at(x: float, z: float, step: float = 1.0) -> float:
	var dx := height_at(x + step, z) - height_at(x - step, z)
	var dz := height_at(x, z + step) - height_at(x, z - step)
	var normal := Vector3(-dx, 2.0 * step, -dz).normalized()
	return rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
