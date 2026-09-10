extends RefCounted

const CONFIG_PATH := "res://data/config/terrain_stormwood.json"
var config: Dictionary
var _hills := FastNoiseLite.new()
var _detail := FastNoiseLite.new()

func _init(override: Dictionary = {}) -> void:
	config = override if not override.is_empty() else load_config()
	_hills.seed = int(config.get("seed", 20260906))
	_hills.frequency = float(config.get("hills_frequency", 0.0018))
	_detail.seed = _hills.seed + 41
	_detail.frequency = float(config.get("detail_frequency", 0.018))

static func load_config() -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return value if value is Dictionary else {}

func height_at(x: float, z: float) -> float:
	var h := float(config.get("base_height", 28))
	h += _hills.get_noise_2d(x,z) * float(config.get("hills_amplitude",14))
	h += _detail.get_noise_2d(x,z) * float(config.get("detail_amplitude",1.4))
	for name: String in ["ridge", "deepwood", "dynamo"]:
		var shape: Dictionary = config[name]
		var c: Array = shape.centre
		var r: Array = shape.radius
		var d := Vector2((x-float(c[0]))/float(r[0]),(z-float(c[1]))/float(r[1])).length()
		h += float(shape.height) * (1.0-smoothstep(0.0,1.0,d))
	var gate: Dictionary = config.rootgate
	var wall := 1.0-smoothstep(35.0,140.0,absf(z-float(gate.z)))
	var pass_factor := smoothstep(float(gate.pass_half_width),float(gate.pass_half_width)+65.0,absf(x-float(gate.pass_x)))
	h += float(gate.ridge_height)*wall*pass_factor
	var sink: Dictionary = config.glass_sink
	var centre: Array = sink.centre
	var distance := Vector2(x-float(centre[0]),z-float(centre[1])).length()
	var outer := float(sink.outer_radius)
	if distance < outer:
		h = lerpf(float(sink.floor_y),h,smoothstep(outer-110.0,outer,distance))
		var island := 1.0-smoothstep(float(sink.island_radius)-18.0,float(sink.island_radius)+20.0,distance)
		h = lerpf(h,float(sink.island_y),island)
	# Civilian structures are real walkable rooms, so the terrain beneath a
	# room and its doorway approach must be one physical floor. Each authored
	# pad is an oriented rectangle around the building's measured collider
	# footprint, with enough flat ground beyond local +Z for the door/arch
	# approach. Outside that rectangle it eases back into this same landform;
	# there is no raised slab and no highest-corner floating building.
	for value: Variant in config.get("settlement_pads", []):
		if not value is Dictionary:
			continue
		var pad := value as Dictionary
		var weight := settlement_pad_weight(x, z, pad)
		if weight > 0.0:
			h = lerpf(h, float(pad.get("height", h)), weight)
	return h


## 1 inside a pad's authored floor/approach rectangle, smoothstep to 0 over
## `blend_m` outside it. `inner_min`/`inner_max` are in building-local X/Z;
## village.gd uses the same Y rotation convention when placing the prefab.
static func settlement_pad_weight(x: float, z: float, pad: Dictionary) -> float:
	var centre_value: Array = pad.get("centre", [])
	var inner_min_value: Array = pad.get("inner_min", [])
	var inner_max_value: Array = pad.get("inner_max", [])
	if centre_value.size() < 2 or inner_min_value.size() < 2 or inner_max_value.size() < 2:
		return 0.0
	var centre := Vector2(float(centre_value[0]), float(centre_value[1]))
	# A placement maps local X/Z to world with rotated(-yaw), so rotated(yaw)
	# is the exact inverse needed to ask which part of the pad this point is in.
	var local := (Vector2(x, z) - centre).rotated(deg_to_rad(float(pad.get("yaw_deg", 0.0))))
	return settlement_pad_weight_local(local, pad)


static func settlement_pad_weight_local(local: Vector2, pad: Dictionary) -> float:
	var inner_min_value: Array = pad.get("inner_min", [])
	var inner_max_value: Array = pad.get("inner_max", [])
	if inner_min_value.size() < 2 or inner_max_value.size() < 2:
		return 0.0
	var inner_min := Vector2(float(inner_min_value[0]), float(inner_min_value[1]))
	var inner_max := Vector2(float(inner_max_value[0]), float(inner_max_value[1]))
	var outside := Vector2(
		maxf(maxf(inner_min.x - local.x, local.x - inner_max.x), 0.0),
		maxf(maxf(inner_min.y - local.y, local.y - inner_max.y), 0.0)
	).length()
	var blend := float(pad.get("blend_m", 0.0))
	if outside <= 0.0:
		return 1.0
	if blend <= 0.0 or outside >= blend:
		return 0.0
	return 1.0 - smoothstep(0.0, blend, outside)

func normal_at(x: float, z: float) -> Vector3:
	return Vector3(height_at(x-2,z)-height_at(x+2,z),4,height_at(x,z-2)-height_at(x,z+2)).normalized()

func slope_degrees_at(x: float, z: float) -> float:
	return rad_to_deg(acos(clampf(normal_at(x,z).y,-1,1)))
