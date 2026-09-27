extends RefCounted
## Reuse shorter overlapping sections from the installed rock family instead
## of stretching one small boulder over an entire mountain's height. Aspect
## is a target: narrowed sections and the instance cap can exceed it.
const BOUNDS := preload("res://scripts/world/building_prefabs.gd")

static func build(parent: Node3D, size: Vector3, seed_value: int,
		family: Array, config: Dictionary) -> bool:
	var width := minf(size.x, size.z)
	if not bool(config.get("enabled", false)) or width <= 0.0 \
			or size.y / width < float(config.get("minimum_aspect", 3.2)):
		return false
	var overlap := clampf(float(config.get("overlap", 0.45)), 0.25, 0.6)
	var aspect := maxf(1.5, float(config.get("section_aspect", 3.2)))
	var count := clampi(ceili((size.y / (width * aspect) - overlap) / (1.0 - overlap)),
		2, clampi(int(config.get("max_sections", 8)), 2, 12))
	var section_height := size.y / (1.0 + float(count - 1) * (1.0 - overlap))
	var stride := section_height * (1.0 - overlap)
	for i in count:
		var rock := (family[posmod(seed_value + i, family.size())] as PackedScene).instantiate() as Node3D
		var bounds: AABB = BOUNDS.new().combined_aabb(rock)
		var width_scale := 0.88 + 0.04 * sin(float(seed_value) * 0.37 + float(i) * 1.71)
		rock.scale = Vector3(size.x * width_scale, section_height, size.z * width_scale) / bounds.size
		var shift := Vector3(sin(seed_value * 0.61 + i * 2.17) * size.x * 0.03,
			float(i) * stride, cos(seed_value * 0.43 + i * 1.93) * size.z * 0.03)
		rock.position = shift - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * rock.scale
		rock.name = "RockSection%02d" % i
		parent.add_child(rock)
	parent.set_meta("rock_section_count", count)
	return true
