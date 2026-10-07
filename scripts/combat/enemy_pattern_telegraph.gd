extends Node3D

## F22 ground shape. Uses the frozen strike profile; a moving camera or
## opponent cannot move a locked marker. Rendering never decides damage.
var _mesh: ImmediateMesh
var _body: Node3D
var _profile: Dictionary
var _origin: Vector3
var _heading: Vector3
var _marker: Vector3
var _lift := 0.09
var _segments := 48
var _fill_alpha := 0.18
var _edge_width := 0.12
var _colour := Color.WHITE
var _water: Object
## Adjacent sections share sampled ground points within an aim(). Identical
## dry aims keep their mesh; a changing water surface must be sampled again.
var _ground_seen: Dictionary = {}
var _terrain_seen: Dictionary = {}
var _aimed: Array = []


static func begin(body: Node3D, profile: Dictionary, origin: Vector3,
		heading: Vector3, marker: Vector3, cfg: Dictionary, colour: Color) -> Node3D:
	var cue := new()
	cue.name = "EnemyPatternTelegraph"
	cue._body = body
	cue._profile = profile.duplicate(true)
	cue._lift = float(cfg.get("ground_lift_m", 0.09))
	cue._segments = maxi(12, int(cfg.get("segments", 48)))
	cue._fill_alpha = float(cfg.get("fill_alpha", 0.18))
	cue._edge_width = float(cfg.get("edge_width_m", 0.12))
	cue._colour = colour
	body.get_parent().add_child(cue)
	cue.top_level = true
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.roughness = 0.85
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 0.12
	material.render_priority = 1
	cue._mesh = ImmediateMesh.new()
	var visual := MeshInstance3D.new()
	visual.mesh = cue._mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cue.add_child(visual)
	cue.aim(origin, heading, marker)
	return cue


func aim(origin: Vector3, heading: Vector3, marker: Vector3) -> void:
	var inputs := [origin, heading, marker]
	_water = get_tree().current_scene if is_inside_tree() else null
	var queries_water := is_instance_valid(_water) and _water.has_method("water_depth_at")
	if inputs == _aimed and not queries_water:
		return
	# A water surface may change while a marker stays locked. Preserve its
	# terrain samples on that path; only water offsets need refreshing.
	if inputs != _aimed: _terrain_seen.clear()
	_aimed = inputs
	_ground_seen.clear()
	_origin = origin
	_heading = Vector3(heading.x, 0.0, heading.z).normalized()
	_marker = marker
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var shape := str(_profile.get("telegraph_shape", "cone"))
	match shape:
		"ring":
			_disc(_origin, float(_profile.get("inner_radius_m", 0.0)), float(_profile.get("range", 0.0)), TAU)
		"marker", "field":
			_disc(_marker, 0.0, float(_profile.get("marker_radius_m", 0.0)), TAU)
		"cone", "fan":
			_disc(_origin, 0.0, float(_profile.get("range", 0.0)), deg_to_rad(float(_profile.get("cone_degrees", 0.0))))
		"lane":
			var side := _heading.cross(Vector3.UP)
			var half_width := float(_profile.get("lane_half_width_m", 0.0))
			var length := float(_profile.get("lunge", 0.0))
			var left := _origin - side * half_width
			var right := _origin + side * half_width
			for rib: int in range(1, 3):
				var advance := _heading * length * float(rib) / 3.0
				_strip(left + advance, right + advance, _fill_alpha)
			_strip(left, left + _heading * length)
			_strip(right, right + _heading * length)
			_strip(left + _heading * length, right + _heading * length)
			_strip(left, right)
	_mesh.surface_end()


func _disc(centre: Vector3, inner: float, outer: float, arc: float) -> void:
	var count := maxi(2, int(ceil(float(_segments) * arc / TAU)))
	# Keep every real strike boundary. Shallow interior ribs show the occupied
	# area without covering the terrain in a uniform translucent wedge/disc.
	_arc(centre, outer, arc, count, 0.9)
	if inner > 0.0: _arc(centre, inner, arc, count, 0.9)
	for rib: int in range(1, 3):
		_arc(centre, lerpf(inner, outer, float(rib) / 3.0), arc, count, _fill_alpha)
	if arc < TAU:
		_strip(centre + _heading.rotated(Vector3.UP, -arc * 0.5) * inner,
			centre + _heading.rotated(Vector3.UP, -arc * 0.5) * outer)
		_strip(centre + _heading.rotated(Vector3.UP, arc * 0.5) * inner,
			centre + _heading.rotated(Vector3.UP, arc * 0.5) * outer)


func _arc(centre: Vector3, radius: float, arc: float, count: int, alpha: float) -> void:
	var half_width := minf(_edge_width * 0.5, radius)
	var previous: Array[Vector3] = []
	for index: int in count + 1:
		var angle := -arc * 0.5 + arc * float(index) / float(count)
		var direction := _heading.rotated(Vector3.UP, angle)
		var section: Array[Vector3] = [_ground_vertex(centre + direction * (radius - half_width)),
			_ground_vertex(centre + direction * radius) + Vector3.UP * minf(_lift, half_width),
			_ground_vertex(centre + direction * (radius + half_width))]
		if not previous.is_empty(): _ridge(previous, section, alpha)
		previous = section


func _strip(start: Vector3, finish: Vector3, alpha: float = 0.9) -> void:
	var side := (finish - start).normalized().cross(Vector3.UP) * _edge_width * 0.5
	var height := minf(_lift, _edge_width * 0.5)
	_ridge([_ground_vertex(start - side), _ground_vertex(start) + Vector3.UP * height, _ground_vertex(start + side)],
		[_ground_vertex(finish - side), _ground_vertex(finish) + Vector3.UP * height, _ground_vertex(finish + side)], alpha)


func _ridge(start: Array[Vector3], finish: Array[Vector3], alpha: float) -> void:
	var foot := _colour.darkened(0.35)
	foot.a = alpha * _colour.a * 0.2
	var crest := _colour.lightened(0.3)
	crest.a = alpha * _colour.a
	_triangle(start[0], finish[0], finish[1], foot, foot, crest)
	_triangle(start[0], finish[1], start[1], foot, crest, crest)
	_triangle(start[1], finish[1], finish[2], crest, crest, foot)
	_triangle(start[1], finish[2], start[2], crest, foot, foot)


func _triangle(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0.0: normal = -normal
	if normal.is_zero_approx(): normal = Vector3.UP
	_mesh.surface_set_normal(normal)
	_mesh.surface_set_color(ca)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(cb)
	_mesh.surface_add_vertex(b)
	_mesh.surface_set_color(cc)
	_mesh.surface_add_vertex(c)


func _ground_vertex(point: Vector3) -> Vector3:
	var key := Vector2(point.x, point.z)
	if _ground_seen.has(key): return Vector3(point.x, float(_ground_seen[key]), point.z)
	var ground := float(_terrain_seen.get(key, point.y))
	if not _terrain_seen.has(key):
		if is_instance_valid(_body) and _body.has_method("_ground_height"):
			var measured := float(_body.call("_ground_height", point.x, point.z))
			if is_finite(measured): ground = measured
		_terrain_seen[key] = ground
	# Match the state tell on a water realm: the skirt meets the visible
	# surface, while depth testing still lets creatures occlude the crest.
	if is_instance_valid(_water) and _water.has_method("water_depth_at"):
		var depth := float(_water.call("water_depth_at", Vector3(point.x, ground, point.z)))
		if is_finite(depth) and depth > 0.0: ground += depth
	ground += _lift
	_ground_seen[key] = ground
	return Vector3(point.x, ground, point.z)
