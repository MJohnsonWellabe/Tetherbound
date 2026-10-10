extends Node3D

const CONFIG_PATH := "res://data/config/stormwood_glass_sink.json"
const SURFACE := preload("res://shaders/stormwood_glass_sink.gdshader")

## The Glass Sink's glass is the basin surface itself. It follows the same
## authored heightfield as the collision, with no plane bridging the crater.
func build(world: Node3D, field: RefCounted) -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var terrain_config: Dictionary = field.get("config")
	var sink: Dictionary = terrain_config.glass_sink
	var centre := Vector2(float(sink.centre[0]), float(sink.centre[1]))
	var inner := float(sink.island_radius) - 12.0
	var outer := float(sink.outer_radius) - 2.0
	var radii := PackedFloat32Array()
	var radius := inner
	while radius < outer:
		radii.append(radius)
		var wall := radius < float(sink.island_radius) + 24.0 or radius > outer - 116.0
		radius += float(config.wall_step_m if wall else config.floor_step_m)
		# Do not step past the start of the outer wall with floor-sized cells.
		if not wall:
			radius = minf(radius, outer - 114.0)
	radii.append(outer)
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("basin_centre", centre)
	material.set_shader_parameter("inner_radius", inner)
	material.set_shader_parameter("outer_radius", outer)
	for key: String in ["glass_colour", "facet_colour", "seam_colour"]:
		material.set_shader_parameter(key, Color(str(config[key])))
	for key: String in ["fracture_scale", "seam_width", "roughness", "metallic"]:
		material.set_shader_parameter(key, float(config[key]))
	var segments := maxi(96, int(config.angular_segments))
	var sectors := maxi(1, int(config.sectors))
	var lift := float(config.surface_lift_m)
	for sector in sectors:
		var start := sector * segments / sectors
		var finish := (sector + 1) * segments / sectors
		var columns := finish - start + 1
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		var indices := PackedInt32Array()
		for ring in radii.size():
			for angular in range(start, finish + 1):
				var angle := TAU * float(angular) / float(segments)
				var point := centre + Vector2(cos(angle), sin(angle)) * radii[ring]
				var height := float(world.call("ground_height_at", point.x, point.y))
				vertices.append(Vector3(point.x, height + lift, point.y))
				normals.append(field.call("normal_at", point.x, point.y))
		for ring in radii.size() - 1:
			for column in columns - 1:
				var a := ring * columns + column
				var b := a + columns
				indices.append_array(PackedInt32Array([a, b, a + 1, a + 1, b, b + 1]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var surface := MeshInstance3D.new()
		surface.name = "GroundedGlassSector%02d" % sector
		surface.mesh = mesh
		surface.material_override = material
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(surface)
