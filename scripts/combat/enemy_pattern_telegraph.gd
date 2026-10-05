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
## Ground heights sampled during one aim(), by exact (x, z): neighbouring
## quads and each quad's two triangles share corners. The last aim()'s inputs:
## an aim() with identical inputs would rebuild the identical mesh. A wild
## creature re-aims every physics tick of its telegraph, and each rebuild
## sampled the ground ~400 times (PERF, 2026-10-05: ~125 ms a call on a host).
var _ground_seen: Dictionary = {}
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
	body.get_parent().add_child(cue)
	cue.top_level = true
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.albedo_color = colour
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
	if inputs == _aimed:
		return
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
			_quad(left, right, right + _heading * length, left + _heading * length, _fill_alpha)
			_strip(left, left + _heading * length)
			_strip(right, right + _heading * length)
			_strip(left + _heading * length, right + _heading * length)
	_mesh.surface_end()


func _disc(centre: Vector3, inner: float, outer: float, arc: float) -> void:
	var count := maxi(2, int(ceil(float(_segments) * arc / TAU)))
	for index: int in count:
		var a := -arc * 0.5 + arc * float(index) / float(count)
		var b := -arc * 0.5 + arc * float(index + 1) / float(count)
		var da := _heading.rotated(Vector3.UP, a)
		var db := _heading.rotated(Vector3.UP, b)
		_quad(centre + da * inner, centre + da * outer,
			centre + db * outer, centre + db * inner, _fill_alpha)
		_strip(centre + da * outer, centre + db * outer)
		if inner > 0.0:
			_strip(centre + da * inner, centre + db * inner)
	if arc < TAU:
		_strip(centre + _heading.rotated(Vector3.UP, -arc * 0.5) * inner,
			centre + _heading.rotated(Vector3.UP, -arc * 0.5) * outer)
		_strip(centre + _heading.rotated(Vector3.UP, arc * 0.5) * inner,
			centre + _heading.rotated(Vector3.UP, arc * 0.5) * outer)


func _strip(start: Vector3, finish: Vector3) -> void:
	var side := (finish - start).normalized().cross(Vector3.UP) * _edge_width * 0.5
	_quad(start - side, start + side, finish + side, finish - side, 0.9)


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, alpha: float) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		var ground := point.y
		if is_instance_valid(_body) and _body.has_method("_ground_height"):
			var key := Vector2(point.x, point.z)
			var measured: float
			if _ground_seen.has(key):
				measured = float(_ground_seen[key])
			else:
				measured = float(_body.call("_ground_height", point.x, point.z))
				_ground_seen[key] = measured
			if is_finite(measured):
				ground = measured
		_mesh.surface_set_color(Color(1.0, 1.0, 1.0, alpha))
		_mesh.surface_add_vertex(Vector3(point.x, ground + _lift, point.z))
