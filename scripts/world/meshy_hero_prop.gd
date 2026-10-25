extends RefCounted

## Shared fitting for the Stormwood Meshy hero props (tb/meshy-1024
## ae67083ec). Each GLB is unit-normalised, so callers fit it to its prompt
## size; `glow` adds the blue-vein next pass to its painted crystal or
## lightning veins. Presentation only.
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const GLOW_SHADER := preload("res://shaders/blue_vein_glow.gdshader")


static func load_model(path: String) -> Node3D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	return scene.instantiate() as Node3D if scene != null else null


## Uniform scale that makes the model `height_m` tall, with its lowest point
## at local y = 0 (minus `sink_m`).
static func fit_height(model: Node3D, height_m: float, sink_m: float = 0.0) -> AABB:
	var bounds := BOUNDS.measure(model)
	var factor := height_m / maxf(0.01, bounds.size.y)
	model.scale = Vector3.ONE * factor
	model.position.y = -bounds.position.y * factor - sink_m
	return bounds


static func glow(model: Node, colour: Color, energy: float) -> Array[ShaderMaterial]:
	var passes: Array[ShaderMaterial] = []
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.mesh.get_surface_count():
			var source := visual.get_active_material(surface) as BaseMaterial3D
			if source == null or source.albedo_texture == null:
				continue
			var lit := source.duplicate() as BaseMaterial3D
			var veins := ShaderMaterial.new()
			veins.shader = GLOW_SHADER
			veins.set_shader_parameter("albedo_tex", source.albedo_texture)
			veins.set_shader_parameter("glow_colour", colour)
			veins.set_shader_parameter("glow_energy", energy)
			lit.next_pass = veins
			visual.set_surface_override_material(surface, lit)
			passes.append(veins)
	return passes
