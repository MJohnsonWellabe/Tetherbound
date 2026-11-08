extends Node3D

## F39#3 round 2 (judges, qj/F39-3-stack-v2, 3 of 3: the stepped terrace "does
## not read as drowned", "no water among the steps"). When
## `water_garden_flood.json` is enabled, a still sheet of shallow water stands
## on the flat crest the Drowned Garden terrace rises from, so the planted
## tiers come up out of the water.
##
## The sheet is one flat surface at `surface_y`, built only over the cells whose
## sampled ground lies between `surface_y - max_depth_m` and
## `surface_y - min_depth_m`. It never spans a slope, so no edge floats more
## than `max_depth_m` above the ground, and the shader's height texture (the
## real ground) feathers the shoreline. Render only: no collider, no water
## volume, no swim/depth query, no route, spawn or durable-state change. It
## reuses the installed water.gdshader and water.gd's noise textures.
const CONFIG := "res://data/config/water_garden_flood.json"
const WATER_SHADER := preload("res://shaders/water.gdshader")


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) \
		if FileAccess.file_exists(CONFIG) else {}
	return parsed if parsed is Dictionary else {}


## Builds the sheet under `world` (anything with ground_height_at(x, z)).
## Returns the number of water cells built (0 while disabled).
func build(world: Node) -> int:
	var k := settings()
	if not bool(k.get("enabled", false)) or world == null or not world.has_method("ground_height_at"):
		return 0
	var region: Array = k.region_xz
	var lo := Vector2(float(region[0]), float(region[1]))
	var hi := Vector2(float(region[2]), float(region[3]))
	var cell := float(k.get("cell_m", 0.5))
	var level := float(k.surface_y)
	var deepest := level - float(k.max_depth_m)
	var shallowest := level - float(k.min_depth_m)
	var nx := int(ceil((hi.x - lo.x) / cell))
	var nz := int(ceil((hi.y - lo.y) / cell))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := 0
	for iz in nz:
		for ix in nx:
			var a := lo + Vector2(ix * cell, iz * cell)
			var centre := a + Vector2(cell, cell) * 0.5
			if not wet(float(world.call("ground_height_at", centre.x, centre.y)), deepest, shallowest):
				continue
			cells += 1
			var b := a + Vector2(cell, 0.0)
			var c := a + Vector2(cell, cell)
			var d := a + Vector2(0.0, cell)
			for p: Vector2 in [a, c, b, a, d, c]:
				surface.set_uv(p)
				surface.add_vertex(Vector3(p.x, level, p.y))
	if cells == 0:
		return 0
	surface.generate_normals()
	var water := MeshInstance3D.new()
	water.name = "DrownedGardenFlood"
	water.mesh = surface.commit()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.material_override = _material(k, world, lo, hi, level)
	add_child(water)
	return cells


## A cell holds water when its ground sits inside the depth band.
static func wet(ground: float, deepest: float, shallowest: float) -> bool:
	return is_finite(ground) and ground >= deepest and ground <= shallowest


func _material(k: Dictionary, world: Node, lo: Vector2, hi: Vector2, level: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	var size := 128
	var floor_y := level - float(k.max_depth_m)
	var image := Image.create(size, size, false, Image.FORMAT_RF)
	for z in size:
		for x in size:
			var at := lo + (hi - lo) * Vector2(float(x) / (size - 1), float(z) / (size - 1))
			var ground := float(world.call("ground_height_at", at.x, at.y))
			# Ground height encoded 0..1 over [floor, surface], as the shader reads it.
			image.set_pixel(x, z, Color(clampf(inverse_lerp(floor_y, level, ground), 0.0, 1.0), 0.0, 0.0))
	material.set_shader_parameter("terrain_height", ImageTexture.create_from_image(image))
	material.set_shader_parameter("region", Vector4(lo.x, lo.y, hi.x - lo.x, hi.y - lo.y))
	material.set_shader_parameter("height_min", floor_y)
	material.set_shader_parameter("height_max", level)
	var look: Dictionary = k.get("surface", {})
	for key: String in look:
		var value: Variant = look[key]
		material.set_shader_parameter(key, Color(str(value)) if value is String else value)
	var donor := preload("res://scripts/world/water.gd").new()
	material.set_shader_parameter("wave_normal_a", donor.call("_noise_normal", 21, 0.05))
	material.set_shader_parameter("wave_normal_b", donor.call("_noise_normal", 22, 0.09))
	material.set_shader_parameter("foam_noise", donor.call("_noise_plain", 23, 0.11))
	donor.free()
	return material
