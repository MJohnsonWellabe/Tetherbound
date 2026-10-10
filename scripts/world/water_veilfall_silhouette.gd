extends MeshInstance3D

## Veilfall far silhouette (F13#5). At the First Shore sightline (~4 km) the
## scene's exponential fog took ~90% of the mountain, so it read as a pale
## cone melting into the horizon. This coarse copy of the real baked mountain
## (a polar grid of ground_height_at samples, one draw call) is shown only past
## the terrain handoff distance and writes a reduced fog amount, keeping a
## toned dark-rock value with white falls against the sky. Near and mid range
## still render the real terrain with the Veilfall rock pass.
##
## Fog colour and density are copied from the live WorldEnvironment so the
## silhouette follows day, golden and night. The same copy feeds any other
## registered material that writes its own FOG (the fall columns and spray).
## Tunables: water_veilfall.json::silhouette.
const SHADER := preload("res://shaders/water_veilfall_silhouette.gdshader")
const VISUAL_CONFIG := "res://data/config/water_veilfall_silhouette_visual.json"
const POLL_SECONDS := 0.25

var fogged_materials: Array[ShaderMaterial] = []
var _environment_node: WorldEnvironment
var _poll := 0.0
var _last_colour := Color(-1, -1, -1)
var _last_density := -1.0
var _last_enabled := false


func build(world: Node3D, config: Dictionary, centre_xz: Vector2) -> void:
	var radius := float(config.get("radius_m", 405.0))
	var rings := maxi(4, int(config.get("rings", 36)))
	var segments := maxi(8, int(config.get("segments", 96)))
	var skirt := float(config.get("skirt_y_m", -3.0))
	var far_relief: Dictionary = config.get("far_relief", {})
	var grid: Array = []
	for ring in rings + 1:
		var r := radius * float(ring) / float(rings)
		var row: Array[Vector3] = []
		for segment in segments:
			var angle := TAU * float(segment) / float(segments)
			var xz := centre_xz + Vector2(cos(angle), sin(angle)) * r
			var y := float(world.call("ground_height_at", xz.x, xz.y))
			if is_finite(y):
				y += _far_relief_height(xz - centre_xz, far_relief)
			row.append(Vector3(xz.x, y if is_finite(y) else skirt, xz.y))
		grid.append(row)
	var skirt_row: Array[Vector3] = []
	for point: Vector3 in grid[rings]:
		var out := Vector2(point.x, point.z) + (Vector2(point.x, point.z) - centre_xz).normalized() * 6.0
		skirt_row.append(Vector3(out.x, skirt, out.y))
	grid.append(skirt_row)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(1, grid.size()):
		for segment in segments:
			var next := (segment + 1) % segments
			# Winding-independent: the shader draws both sides and the normals
			# are explicit, oriented away from the ground.
			for corner: Vector2i in [Vector2i(ring - 1, segment), Vector2i(ring - 1, next), Vector2i(ring, next),
					Vector2i(ring - 1, segment), Vector2i(ring, next), Vector2i(ring, segment)]:
				surface.set_normal(_grid_normal(grid, corner.x, corner.y, segments, centre_xz))
				surface.add_vertex(grid[corner.x][corner.y])
	mesh = surface.commit()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_range_begin = float(config.get("visible_from_m", 1100.0))
	extra_cull_margin = 80.0
	var material := ShaderMaterial.new()
	material.shader = SHADER
	for key: String in config.get("shader", {}):
		if key.begins_with("_"):
			continue
		var value: Variant = config.shader[key]
		material.set_shader_parameter(key, Color(str(value)) if value is String else value)
	material.set_shader_parameter("centre_xz", centre_xz)
	material_override = material
	fogged_materials.append(material)
	# Presentation-only poll; keep it running while the tree is paused (menus,
	# captures) so the fog copy never lags a time-of-day change.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# WorldLook may swap the Environment resource, so read it through the node.
	_environment_node = world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var candidate: Variant = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_CONFIG))
	if candidate is Dictionary and bool(candidate.get("enabled", false)):
		var composition := world.get_node_or_null(str(candidate.get("source_root", ""))) as Node3D
		add_decorative_far_meshes(world, composition, candidate)


## Presentation-only crag crowns interrupt the analytic mountain's cone at
## long distance. The profile returns to the exact physical terrain outside
## each crown; trails, falls sampling, collision and the near scene are intact.
static func _far_relief_height(local_xz: Vector2, settings: Dictionary) -> float:
	if not bool(settings.get("enabled", false)):
		return 0.0
	var height := 0.0
	for spec: Dictionary in settings.get("peaks", []):
		var raw: Array = spec.get("offset_xz_m", [0.0, 0.0])
		if raw.size() != 2:
			continue
		var radius := maxf(1.0, float(spec.get("radius_m", 1.0)))
		var distance := local_xz.distance_to(Vector2(float(raw[0]), float(raw[1])))
		var crown := pow(maxf(0.0, 1.0 - distance / radius), float(spec.get("power", 0.85)))
		height = maxf(height, crown * float(spec.get("height_m", 0.0)))
	return height


## Reuse only visible crag/cap surfaces. Never duplicate the source hierarchy:
## it contains PhysicalCragSupport bodies that must remain owned by the near
## composition. Sharing Mesh resources also prevents a second geometry recipe
## from drifting away from the existing grounded formations.
func add_decorative_far_meshes(world: Node3D, composition: Node3D, settings: Dictionary) -> int:
	if not bool(settings.get("enabled", false)) or composition == null:
		return 0
	var accepted: Array = settings.get("mesh_names", [])
	var receiver_inverse := _transform_under(self, world).affine_inverse()
	var count := 0
	for child: Node in composition.find_children("*", "MeshInstance3D", true, false):
		var source := child as MeshInstance3D
		if str(source.name) not in accepted or source.mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.name = "Far_%s_%s" % [source.get_parent().name, source.name]
		copy.mesh = source.mesh
		copy.transform = receiver_inverse * _transform_under(source, world)
		var distant := (material_override as ShaderMaterial).duplicate() as ShaderMaterial
		distant.set_shader_parameter("shelf_cap", str(source.name) == "VegetatedShelfCap")
		copy.material_override = distant
		fogged_materials.append(distant)
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Shelf caps end sooner than the main mountain copy begins. Match the
		# source's own handoff or they disappear for the 900–1100m interval.
		copy.visibility_range_begin = source.visibility_range_end
		copy.extra_cull_margin = extra_cull_margin
		add_child(copy)
		count += 1
	return count


## Composed local transforms work both in production and in detached unit
## fixtures, without asking the scene tree for global transforms.
static func _transform_under(node: Node3D, ancestor: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != ancestor:
		if current is Node3D:
			result = (current as Node3D).transform * result
		current = current.get_parent()
	return result


func _grid_normal(grid: Array, ring: int, segment: int, segments: int, centre_xz: Vector2) -> Vector3:
	var point: Vector3 = grid[ring][segment]
	var inner: Vector3 = grid[maxi(ring - 1, 0)][segment]
	var outer: Vector3 = grid[mini(ring + 1, grid.size() - 1)][segment]
	var left: Vector3 = grid[ring][(segment + segments - 1) % segments]
	var right: Vector3 = grid[ring][(segment + 1) % segments]
	var normal := (outer - inner).cross(right - left)
	if ring == 0 or normal.length_squared() < 0.0001:
		return Vector3.UP
	normal = normal.normalized()
	if normal.y < 0.0:
		normal = -normal
	# A face never leans back toward the island centre.
	var away := Vector3(point.x - centre_xz.x, 0.0, point.z - centre_xz.y).normalized()
	if normal.y < 0.2 and normal.dot(away) < 0.0:
		normal = (normal + away).normalized()
	return normal


func register_fogged(material: ShaderMaterial) -> void:
	if material != null and not fogged_materials.has(material):
		fogged_materials.append(material)
		_last_density = -1.0


func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0.0 or _environment_node == null or _environment_node.environment == null:
		return
	_poll = POLL_SECONDS
	var environment := _environment_node.environment
	var colour := environment.fog_light_color
	var density := environment.fog_density
	var enabled := environment.fog_enabled
	if colour == _last_colour and is_equal_approx(density, _last_density) and enabled == _last_enabled:
		return
	_last_colour = colour
	_last_density = density
	_last_enabled = enabled
	for material in fogged_materials:
		# The fog uniforms are plain linear vec3s: convert here, once.
		var linear := colour.srgb_to_linear()
		material.set_shader_parameter("fog_colour", Vector3(linear.r, linear.g, linear.b))
		material.set_shader_parameter("fog_density", density)
		material.set_shader_parameter("fog_enabled", enabled)
