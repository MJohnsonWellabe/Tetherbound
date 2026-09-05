extends Node3D

## Dense decorative ground layers for Cloudreach's stacked cliff surfaces.
##
## Meadows can keep a camera-relative field because Terrain3D provides one
## height per XZ. Cloudreach deliberately stacks surfaces at the same XZ, so it
## uses deterministic per-plate MultiMeshes instead. The meshes themselves are
## the Meadows GrassField's production tuft, flower and bush meshes; only the
## placement source changes. Every patch has its own visibility range so the
## whole 6.5 km chapter is never submitted at once.

const GRASS_FIELD_SCRIPT := preload("res://scripts/world/grass_field.gd")
const COVER_SHADER := preload("res://shaders/cloudreach_ground_cover.gdshader")

var _grass_instances := 0
var _flower_instances := 0
var _bush_instances := 0
var _exclusions: Array[Dictionary] = []
var _active_exclusions: Array[Dictionary] = []


func build(patches: Array[Dictionary], config: Dictionary, exclusions: Array[Dictionary] = []) -> void:
	_exclusions = exclusions
	var factory := GRASS_FIELD_SCRIPT.new()
	# Seven-blade groups read as tufted ground cover at gameplay distance. The
	# former four-blade/high-density combination resolved into uniform vertical
	# noise even though its instance count was high.
	var grass_mesh := factory.call("surface_tuft_mesh", 7, 2) as ArrayMesh
	var flower_mesh := factory.call("surface_cover_mesh", "flower") as ArrayMesh
	var bush_mesh := factory.call("surface_cover_mesh", "bush") as ArrayMesh
	factory.free()

	var grass_material := _cover_material(
		Color(str(config.get("grass_base", "#334512"))),
		Color(str(config.get("grass_tip", "#84933a"))), 0.11, 0.50, false)
	var dry_grass_material := _cover_material(
		Color(str(config.get("dry_grass_base", "#4b4919"))),
		Color(str(config.get("dry_grass_tip", "#a89b42"))), 0.14, 0.50, false)
	grass_material.set_shader_parameter("grass_curve", 0.30)
	dry_grass_material.set_shader_parameter("grass_curve", 0.30)
	grass_material.set_shader_parameter("camera_clearance", true)
	dry_grass_material.set_shader_parameter("camera_clearance", true)
	var flower_material := _cover_material(
		Color(str(config.get("flower_base", "#335119"))),
		Color(str(config.get("flower_tip", "#d49ac6"))), 0.075, 0.62, false)
	var bush_material := _cover_material(
		Color(str(config.get("bush_base", "#243b16"))),
		Color(str(config.get("bush_tip", "#647a31"))), 0.055, 0.72, true)

	for patch_index in patches.size():
		var patch := patches[patch_index]
		_active_exclusions = _nearby_exclusions(patch)
		var patch_root := Node3D.new()
		patch_root.name = "CoverPatch%03d" % patch_index
		patch_root.position = _patch_origin(patch)
		add_child(patch_root)
		var area := _patch_area(patch)
		var is_route := str(patch.get("kind", "ellipse")) == "segment"
		var grass_count := mini(int(area * float(config.get("grass_density_per_m2", 0.24))),
			int(config.get("route_grass_patch_cap", 12000) if is_route
				else config.get("region_grass_patch_cap", 50000)))
		if is_route:
			grass_count=int(grass_count*0.64)
		var flower_count := mini(int(area * float(config.get("flower_density_per_m2", 0.010))),
			int(config.get("route_flower_patch_cap", 360) if is_route
				else config.get("region_flower_patch_cap", 900)))
		var bush_count := mini(int(area * float(config.get("bush_density_per_m2", 0.0025))),
			int(config.get("route_bush_patch_cap", 52) if is_route
				else config.get("region_bush_patch_cap", 130)))
		_grass_instances += _build_patch_tier(patch_root, "Grass", patch, grass_mesh,
			dry_grass_material if bool(patch.get("dry", false)) else grass_material,
			grass_count, float(config.get("grass_scale_min", 0.52)),
			float(config.get("grass_scale_max", 0.88)), config, patch_index * 31 + 7, 0)
		_flower_instances += _build_patch_tier(patch_root, "Flowers", patch, flower_mesh,
			flower_material, flower_count, float(config.get("flower_scale_min", 0.62)),
			float(config.get("flower_scale_max", 1.05)), config, patch_index * 31 + 13, 1)
		_bush_instances += _build_patch_tier(patch_root, "Understorey", patch, bush_mesh,
			bush_material, bush_count, float(config.get("bush_scale_min", 0.72)),
			float(config.get("bush_scale_max", 1.18)), config, patch_index * 31 + 19, 2)


func grass_instance_count() -> int:
	return _grass_instances


func flower_instance_count() -> int:
	return _flower_instances


func bush_instance_count() -> int:
	return _bush_instances


func _build_patch_tier(parent: Node3D, label: String, patch: Dictionary, mesh: ArrayMesh,
		material: ShaderMaterial, requested: int, scale_min: float, scale_max: float,
		config: Dictionary, seed_value: int, tier: int) -> int:
	if requested <= 0 or mesh == null:
		return 0
	var origin := parent.position
	var transforms: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + int(patch.get("seed", 0)) * 1009
	var attempts := 0
	var max_attempts := maxi(requested * 7, 32)
	while transforms.size() < requested and attempts < max_attempts:
		attempts += 1
		var at := _sample_patch(patch, rng, float(config.get("path_clearance_m", 1.8)))
		if is_nan(at.y):
			continue
		if _excluded(at, true):
			continue
		# One continuous asymmetric planting field across adjacent geometry
		# chunks. Per-patch phase previously made visible parallel planting bands.
		var frequency:=float(config.get("cluster_frequency",0.16))
		var cluster:=sin(at.x*frequency*0.61+sin(at.z*frequency*0.39))
		cluster+=sin(at.z*frequency*0.47-at.x*frequency*0.23)*0.8
		cluster+=sin(at.x*frequency*1.9+at.z*frequency*1.2)*0.22
		var threshold := float(config.get("cluster_threshold", -0.18)) + float(tier) * 0.34
		if cluster < threshold:
			continue
		var scale_value := rng.randf_range(scale_min, scale_max)
		if tier==0 and str(patch.get("kind",""))=="segment":
			var axis: Vector3=(patch["b"] as Vector3)-(patch["a"] as Vector3)
			axis.y=0
			var lateral: float=Vector3.UP.cross(axis.normalized()).dot(at-(patch["a"] as Vector3))
			# Short wear-edge growth gives way to distinct tall shoulder clumps.
			# The two sides have different phases, not matching luminous rails.
			var mass:=0.5+0.5*sin(at.x*0.17+at.z*0.11+signf(lateral)*1.9)
			scale_value*=lerpf(0.30,1.0,smoothstep(0.22,0.80,mass))
			if absf(lateral)<3.6:
				scale_value*=0.68
		var width_scale := scale_value * rng.randf_range(0.82, 1.16)
		if tier == 0:
			# The shared Meadows tuft mesh is authored at real blade width. Height
			# variation must not also shrink every blade/spread into sub-pixel lines.
			width_scale = rng.randf_range(1.6, 2.3)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
			Vector3(width_scale, scale_value, width_scale))
		transforms.append(Transform3D(basis, at - origin))
	if transforms.is_empty():
		return 0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var instances := MultiMeshInstance3D.new()
	instances.name = label
	instances.multimesh = mm
	instances.material_override = material
	instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instances.visibility_range_end = float(config.get("visibility_range_m", 360.0))
	instances.visibility_range_end_margin = 42.0
	instances.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(instances)
	return transforms.size()


func _nearby_exclusions(patch: Dictionary) -> Array[Dictionary]:
	var centre := _patch_origin(patch)
	var radius := 0.0
	if str(patch.get("kind", "")) == "segment":
		radius = (patch["a"] as Vector3).distance_to(patch["b"]) * 0.5 + float(patch["half_width"])
	else:
		var half: Vector2 = patch["half"]
		radius = maxf(half.x, half.y)
	var nearby: Array[Dictionary] = []
	for exclusion: Dictionary in _exclusions:
		var at: Vector3
		var extra := 10.0
		if str(exclusion.get("kind", "")) == "segment":
			var a: Vector3 = exclusion["a"]
			var b: Vector3 = exclusion["b"]
			var ab := b - a
			var t := clampf((centre - a).dot(ab) / maxf(ab.length_squared(), 0.01), 0, 1)
			at = a.lerp(b, t)
		else:
			at = exclusion["centre"]
			extra = (exclusion["half"] as Vector2).length()
		if at.distance_to(centre) < radius + extra + 4.0:
			nearby.append(exclusion)
	return nearby


func _excluded(at: Vector3, local_only: bool = false) -> bool:
	for exclusion: Dictionary in (_active_exclusions if local_only else _exclusions):
		if str(exclusion.get("kind", "")) == "segment":
			var a: Vector3 = exclusion["a"]
			var b: Vector3 = exclusion["b"]
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var t := clampf(Vector2(at.x - a.x, at.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01), 0, 1)
			var nearest := a.lerp(b, t)
			if absf(nearest.y - at.y) < 3.0 and Vector2(at.x - nearest.x, at.z - nearest.z).length() < float(exclusion["half_width"]):
				return true
			continue
		var centre: Vector3 = exclusion["centre"]
		if absf(at.y - centre.y) > 3.0:
			continue
		var local := Vector2(at.x - centre.x, at.z - centre.z).rotated(-float(exclusion["rotation"]))
		var half: Vector2 = exclusion["half"]
		if str(exclusion.get("kind",""))=="ellipse":
			if (local/half).length_squared()<=1.0:
				return true
			continue
		if absf(local.x) <= half.x and absf(local.y) <= half.y:
			return true
	return false


func _sample_patch(patch: Dictionary, rng: RandomNumberGenerator, path_clearance: float) -> Vector3:
	var kind := str(patch.get("kind", "ellipse"))
	if kind == "segment":
		var a: Vector3 = patch.get("a", Vector3.ZERO)
		var b: Vector3 = patch.get("b", Vector3.ZERO)
		var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
		if flat.length_squared() < 0.01:
			return Vector3(NAN, NAN, NAN)
		var right := Vector3.UP.cross(flat.normalized()).normalized()
		var half_width := float(patch.get("half_width", 20.0))
		var clear := float(patch.get("path_half_width", 4.0)) + path_clearance
		if half_width <= clear:
			return Vector3(NAN, NAN, NAN)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lateral := rng.randf_range(clear, half_width * 0.92) * side
		var t := rng.randf_range(0.02, 0.98)
		var at:=a.lerp(b,t)+right*lateral
		# Two-dimensional lobes avoid a route aligned with a phase gradient
		# turning a low-frequency field into one uninterrupted bright rail.
		var edge_mass:=sin(at.x*0.49+side*1.7)*cos(at.z*0.43-side*0.7)
		edge_mass+=0.35*sin(at.x*0.91+at.z*0.77)
		var worn_width:=clear+minf(2.0,half_width-clear)*(0.5+0.5*sin(at.x*0.27+at.z*0.31))
		if edge_mass < 0.05 or absf(lateral)<worn_width:
			return Vector3(NAN,NAN,NAN)
		return at + Vector3.UP * float(patch.get("surface_offset_y", -0.64))
	var centre: Vector3 = patch.get("centre", Vector3.ZERO)
	var half: Vector2 = patch.get("half", Vector2(20.0, 20.0))
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf()) * 0.88
	if radius < float(patch.get("inner_clear_fraction", 0.0)):
		return Vector3(NAN, NAN, NAN)
	return centre + Vector3(cos(angle) * half.x * radius, 0.08,
		sin(angle) * half.y * radius)


func _patch_origin(patch: Dictionary) -> Vector3:
	if str(patch.get("kind", "ellipse")) == "segment":
		var a: Vector3 = patch.get("a", Vector3.ZERO)
		var b: Vector3 = patch.get("b", Vector3.ZERO)
		return a.lerp(b, 0.5)
	return patch.get("centre", Vector3.ZERO)


func _patch_area(patch: Dictionary) -> float:
	if str(patch.get("kind", "ellipse")) == "segment":
		var a: Vector3 = patch.get("a", Vector3.ZERO)
		var b: Vector3 = patch.get("b", Vector3.ZERO)
		return a.distance_to(b) * float(patch.get("half_width", 20.0)) * 1.45
	var half: Vector2 = patch.get("half", Vector2(20.0, 20.0))
	return PI * half.x * half.y * 0.76


func _cover_material(base: Color, tip: Color, wind: float, soften: float,
		cut_leaves: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = COVER_SHADER
	material.set_shader_parameter("tint_base", base)
	material.set_shader_parameter("tint_tip", tip)
	material.set_shader_parameter("wind_strength", wind)
	material.set_shader_parameter("normal_soften", soften)
	material.set_shader_parameter("leaf_cut", 1.0 if cut_leaves else 0.0)
	return material
