extends Node3D

## F22 ground shape. Uses the frozen strike profile; a moving camera or
## opponent cannot move a locked marker. Rendering never decides damage.
const STYLE := preload("res://scripts/combat/tell_style.gd")
const WATER_GEOMETRY := preload("res://scripts/vfx/move_effect_geometry.gd")
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
## Marker/field discs: the target's foot height carried in the marker's Y
## (F04#1). Ground sampling ran under the raised Relay deck twice. NAN: sample.
var _seat_y := NAN
var _aimed: Array = []
## P2-093/P2-063 soft style (`telegraph.soft_style`; empty = off): the same
## shape drawn as a feathered edge-lit outline, with vertex colours carrying
## the hue.
var _soft: Dictionary = {}
var _tint := Color.WHITE
## F22#4 Riverwatch round (13 Oct): a row's `cue_water` draws its field as a
## rising water surface inside the outline (the judge read "FLOOD" from the
## banner only). Presentation only; the hit area is the outline's.
var _water: MeshInstance3D = null
var _water_rise := 0.0
var _water_crest: MeshInstance3D = null
var _water_spray: Array[MeshInstance3D] = []
var _water_cast: MeshInstance3D = null
var _water_cast_progress := 0.0
var _water_wall: MeshInstance3D = null
var _water_wall_progress := 0.0
var _water_boundary: MeshInstance3D = null
var _water_origin: Array[MeshInstance3D] = []
var _water_origin_time := 0.0


static func begin(body: Node3D, profile: Dictionary, origin: Vector3,
		heading: Vector3, marker: Vector3, cfg: Dictionary, colour: Color) -> Node3D:
	var cue := new()
	cue.name = "EnemyPatternTelegraph"
	cue._body = body
	cue._profile = profile.duplicate(true)
	cue._lift = float(cfg.get("ground_lift_m", 0.09))
	cue._segments = maxi(12, int(cfg.get("segments", 48)))
	# A row may set its own fill (F04#0: the guardian's quick is an outline,
	# its Earth Fist a solid wedge) and fill in over its tell (`cue_fills`).
	cue._fill_alpha = float(profile.get("cue_fill_alpha", cfg.get("fill_alpha", 0.18)))
	cue._edge_width = float(cfg.get("edge_width_m", 0.12))
	cue._soft = STYLE.soft().duplicate(true)
	if profile.get("cue_water_spray") == true or profile.get("cue_water_crest") == true \
			or profile.get("cue_water_cast") == true or profile.get("cue_water_wall") == true:
		# Riverwatch's water occupies its existing hit outline; the warning hue
		# should describe that same water instead of competing magenta geometry.
		colour = Color(str(profile.get("cue_water_tell_colour", "#4aa9c7")))
		cue._fill_alpha = float(profile.get("cue_water_wall_fill_alpha", 0.28)) \
			if profile.get("cue_water_wall") == true else float(profile.get("cue_water_fill_alpha", 0.08))
		if not cue._soft.is_empty():
			cue._soft["fill_alpha"] = cue._fill_alpha
	cue._tint = Color(colour, 1.0)
	# Top-level BEFORE entering the tree: its vertices are world coordinates,
	# and turning top_level on afterwards keeps the parent's global transform,
	# which drew every cue under a translated parent (the Warrens guardian's
	# cone under BurrowWarrens) ~2.6 km from the fight (F04#0 judge).
	cue.top_level = true
	body.get_parent().add_child(cue)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# A deck or crate must never hide a tell (F04#1): drawn over the floor.
	material.no_depth_test = true
	material.render_priority = 1
	material.albedo_color = colour
	if not cue._soft.is_empty():
		# The hue moves to the vertices so the core line can be lifted toward
		# white; the material keeps only the alpha a filling cue tweens.
		material.albedo_color = Color(1.0, 1.0, 1.0, colour.a)
	cue._mesh = ImmediateMesh.new()
	var visual := MeshInstance3D.new()
	visual.mesh = cue._mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cue.add_child(visual)
	if profile.get("cue_water") == true and str(profile.get("telegraph_shape", "")) == "field":
		cue._add_water(float(profile.get("telegraph", 1.0)))
	if profile.get("cue_water_spray") == true and str(profile.get("telegraph_shape", "")) == "fan":
		cue._add_water_spray()
	if profile.get("cue_water_wall") == true and str(profile.get("telegraph_shape", "")) == "fan":
		cue._add_water_wall()
	if profile.get("cue_water_origin") == true:
		cue._add_water_origin()
	cue.aim(origin, heading, marker)
	var fill_s := float(profile.get("telegraph", 0.0)) if profile.get("cue_fills") == true else 0.0
	if fill_s > 0.0:
		var faint := material.albedo_color
		faint.a = colour.a * 0.25
		material.albedo_color = faint
		cue.create_tween().tween_property(material, "albedo_color:a", colour.a, fill_s)
	return cue


func _add_water(rise_s: float) -> void:
	var radius := float(_profile.get("marker_radius_m", 0.0)) + float(_profile.get("target_radius_m", 0.0))
	if radius <= 0.0:
		return
	var disc := CylinderMesh.new()
	disc.top_radius = radius * 0.96
	disc.bottom_radius = radius * 0.96
	disc.height = 0.06
	disc.radial_segments = 40
	var spread: bool = _profile.get("cue_water_spread") == true
	var crest: bool = _profile.get("cue_water_crest") == true
	var wall: bool = _profile.get("cue_water_wall") == true
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if wall:
		material.albedo_color = Color(0.08, 0.43, 0.67,
			float(_profile.get("cue_water_floor_opacity", 0.55)))
	elif crest:
		material.albedo_color = Color(0.10, 0.48, 0.71,
			float(_profile.get("cue_water_floor_opacity", 0.55)))
	elif spread:
		material.albedo_color = Color(0.16, 0.57, 0.78, 0.35)
	else:
		material.albedo_color = Color(0.22, 0.52, 0.68, 0.25)
	if spread or crest or wall:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 0.08
	material.metallic_specular = 0.9
	material.emission_enabled = true
	material.emission = Color(0.12, 0.3, 0.42)
	disc.material = material
	_water = MeshInstance3D.new()
	_water.mesh = disc
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if spread:
		# The outline shows the full danger area while water spreads into it.
		# Start above the floor instead of hiding the first tell frames below it.
		_water.scale = Vector3(0.15, 1.0, 0.15)
		_water_rise = 0.12
	add_child(_water)
	if wall:
		# The whole hit footprint and its vertical boundary are present from the
		# first tell frame; neither visual changes the locked field collision.
		_water_rise = 0.20
		_add_water_boundary(radius)
	elif crest:
		# The full danger footprint exists on the first tell frame. A separate
		# foaming lip moves outward; its scale never defines the damage radius.
		_water_rise = 0.20
		_add_water_crest(radius, rise_s)
	elif spread:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_water, "scale", Vector3.ONE, maxf(0.1, rise_s))
		tween.tween_property(self, "_water_rise", 0.20, maxf(0.1, rise_s))
		tween.tween_property(material, "albedo_color:a", 0.58, maxf(0.1, rise_s))
	else:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, "_water_rise", 0.22, maxf(0.1, rise_s))
		tween.tween_property(material, "albedo_color:a", 0.6, maxf(0.1, rise_s))
	if _profile.get("cue_water_cast") == true:
		_add_water_cast(rise_s)


func _add_water_spray() -> void:
	var radius := maxf(0.15, float(_profile.get("cue_water_spray_radius_m", 0.48)))
	var length := maxf(0.5, float(_profile.get("range", 8.0)))
	var stream := WATER_GEOMETRY.shape("water_stream", radius,
		{"height_ratio": length / radius, "widen": true})
	var material := WATER_GEOMETRY.authored_material("water_stream",
		{"opacity": float(_profile.get("cue_water_spray_opacity", 0.85)),
		 "foam_colour": "#e3faff", "flow_speed": 3.6}, Color("#2186b4"))
	for _index in 3:
		var visual := MeshInstance3D.new()
		visual.mesh = stream
		visual.material_override = material
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(visual)
		_water_spray.append(visual)


func _add_water_origin() -> void:
	# An elevated charge at the attacker, with no ground footprint or path over
	# safe space. The separate warning mesh still defines the entire hit area.
	var radius := clampf(float(_profile.get("cue_water_origin_radius_m", 0.23)), 0.12, 0.38)
	var bubble_mesh := WATER_GEOMETRY.shape("bubble", radius, {"segments": 12, "rings": 6})
	var bubble_material := WATER_GEOMETRY.authored_material("bubble",
		{"opacity": 0.82, "rim_colour": "#e5fbff", "rim_power": 1.5,
		 "film_strength": 0.18, "center_opacity": 0.12, "flow_speed": 1.4},
		Color("#1888c1"))
	for _index in 3:
		var bubble := MeshInstance3D.new()
		bubble.mesh = bubble_mesh
		bubble.material_override = bubble_material
		bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(bubble)
		_water_origin.append(bubble)


func _add_water_wall() -> void:
	# One curling front travels from Brooktail through the unchanged 50-degree
	# fan. The cyan ground fan remains visible at its full hit size throughout.
	var length := maxf(0.5, float(_profile.get("range", 8.0)))
	var height := maxf(0.6, float(_profile.get("cue_water_wall_height_m", 1.8)))
	var half_angle := deg_to_rad(float(_profile.get("cone_degrees", 50.0))) * 0.5
	# The curled mesh has depth ahead of its centre. Stop its front inside the
	# hit sector and narrow its rear edge so no water marks ground outside the
	# real 50-degree fan.
	var end_fraction := clampf(float(_profile.get("cue_water_wall_end_fraction", 0.72)), 0.3, 0.72)
	var width_fraction := clampf(float(_profile.get("cue_water_wall_width_fraction", 0.6)), 0.2, 0.6)
	var half_width := length * end_fraction * sin(half_angle) * width_fraction
	_water_wall = MeshInstance3D.new()
	_water_wall.mesh = WATER_GEOMETRY.shape("rolling_wave", height,
		{"width_ratio": half_width / height, "segments": 24, "curl_segments": 12})
	_water_wall.material_override = WATER_GEOMETRY.authored_material("rolling_wave",
		{"opacity": float(_profile.get("cue_water_wall_opacity", 0.85)),
		 "body_opacity_factor": float(_profile.get("cue_water_wall_body_opacity_factor", 1.0)),
		 "foam_colour": "#e3faff", "flow_speed": 3.6}, Color("#2186b4"))
	_water_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water_wall)
	create_tween().tween_property(self, "_water_wall_progress", 1.0,
		maxf(0.1, float(_profile.get("telegraph", 0.9))))


func _add_water_boundary(radius: float) -> void:
	# The crown geometry begins at 0.35 * size. Size it so that ground-level
	# foot is exactly the hit radius, then curl the lip inward, never onto safe
	# ground. Ground water marks the unsafe interior.
	var crown_size := radius / 0.35
	_water_boundary = MeshInstance3D.new()
	_water_boundary.mesh = WATER_GEOMETRY.shape("splash_crown", crown_size,
		{"crown_petals": 16, "crown_rows": 8,
		 "crown_gap": float(_profile.get("cue_water_wall_crown_gap", 0.0)),
		 "crown_taper": float(_profile.get("cue_water_wall_crown_taper", 0.0)),
		 "crown_height_ratio": float(_profile.get("cue_water_wall_height_ratio", 0.85)) * 0.35,
		 "crown_flare_ratio": -0.03})
	_water_boundary.material_override = WATER_GEOMETRY.authored_material("splash_crown",
		{"opacity": float(_profile.get("cue_water_wall_opacity", 0.82)),
		 "body_opacity_factor": float(_profile.get("cue_water_wall_body_opacity_factor", 1.0)),
		 "foam_colour": "#e3faff", "flow_speed": 2.6}, Color("#2186b4"))
	_water_boundary.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water_boundary)


func _add_water_crest(radius: float, rise_s: float) -> void:
	var size := clampf(radius * 0.24, 0.45, 0.9)
	_water_crest = MeshInstance3D.new()
	_water_crest.mesh = WATER_GEOMETRY.shape("splash_crown", size,
		{"crown_petals": 12, "crown_rows": 6, "crown_gap": 0.05,
		 "crown_taper": 0.25, "crown_height_ratio": float(_profile.get("cue_water_crest_height_ratio", 0.9)),
		 "crown_flare_ratio": radius / size - 0.35})
	_water_crest.material_override = WATER_GEOMETRY.authored_material("splash_crown",
		{"opacity": float(_profile.get("cue_water_crest_opacity", 0.82)),
		 "foam_colour": "#e3faff", "flow_speed": 2.6}, Color("#2186b4"))
	_water_crest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_water_crest.scale = Vector3.ONE * clampf(float(_profile.get("cue_water_crest_start_scale", 0.7)), 0.3, 1.0)
	add_child(_water_crest)
	create_tween().tween_property(_water_crest, "scale", Vector3.ONE, maxf(0.1, rise_s))


func _add_water_cast(rise_s: float) -> void:
	# A visible current travels from Brooktail to the already marked Flood.
	# This is presentation only; the field outline remains the entire hit area.
	var width := maxf(0.08, float(_profile.get("cue_water_cast_radius_m", 0.24)))
	_water_cast = MeshInstance3D.new()
	_water_cast.mesh = WATER_GEOMETRY.shape("water_stream", width,
		{"height_ratio": 1.0 / width, "widen": true})
	_water_cast.material_override = WATER_GEOMETRY.authored_material("water_stream",
		{"opacity": float(_profile.get("cue_water_cast_opacity", 0.92)),
		 "foam_colour": "#e3faff", "flow_speed": 4.0}, Color("#2186b4"))
	_water_cast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_water_cast.visible = false
	add_child(_water_cast)
	var travel := minf(maxf(0.1, rise_s * 0.55),
		maxf(0.1, float(_profile.get("cue_water_cast_travel_s", 0.4))))
	create_tween().tween_property(self, "_water_cast_progress", 1.0, travel)


func _process(delta: float) -> void:
	if not _water_origin.is_empty() and _heading.length_squared() > 0.0:
		_water_origin_time += delta
		var radius := clampf(float(_profile.get("cue_water_origin_radius_m", 0.23)), 0.12, 0.38)
		var height := float(_profile.get("cue_water_origin_height_m", 1.55))
		var forward := float(_profile.get("cue_water_origin_forward_m", 0.45))
		var anchor := _origin + Vector3.UP * height + _heading * forward
		var side := _heading.cross(Vector3.UP).normalized()
		var duration := maxf(0.1, float(_profile.get("telegraph", 0.9)))
		for index in _water_origin.size():
			var phase := fposmod(_water_origin_time / duration + float(index) / 3.0, 1.0)
			var bubble := _water_origin[index]
			bubble.position = anchor + side * ((float(index) - 1.0) * radius * 1.4) \
				+ Vector3.UP * (phase * 0.38) + _heading * (phase * 0.14)
			bubble.scale = Vector3.ONE * (0.65 + 0.35 * sin(PI * phase))
	if _water != null and _marker.is_finite():
		var floor_y := _seat_y if is_finite(_seat_y) else _marker.y
		_water.position = Vector3(_marker.x, floor_y - 0.05 + _water_rise, _marker.z)
		if _water_crest != null:
			_water_crest.position = Vector3(_marker.x, floor_y + 0.09, _marker.z)
		if _water_boundary != null:
			_water_boundary.position = Vector3(_marker.x, floor_y + 0.09, _marker.z)
	if _water_wall != null and _heading.length_squared() > 0.0:
		var length := maxf(0.5, float(_profile.get("range", 8.0)))
		var half_angle := deg_to_rad(float(_profile.get("cone_degrees", 50.0))) * 0.5
		var end_fraction := clampf(float(_profile.get("cue_water_wall_end_fraction", 0.72)), 0.3, 0.72)
		var start := minf(length * end_fraction,
			maxf(2.0, float(_profile.get("cue_water_wall_start_m", 2.0))))
		var reach := lerpf(start, length * end_fraction, _water_wall_progress)
		_water_wall.position = _origin + _heading * (reach * cos(half_angle)) + Vector3.UP * 0.10
		_water_wall.quaternion = Quaternion(Vector3.FORWARD, _heading)
		_water_wall.scale = Vector3(reach / (length * end_fraction), 1.0, 1.0)
	if _water_cast != null and _marker.is_finite():
		var source := _origin + Vector3.UP * float(_profile.get("cue_water_cast_origin_height_m", 0.85))
		var target := _marker + Vector3.UP * float(_profile.get("cue_water_cast_target_height_m", 0.25))
		var path := target - source
		var reach := path.length() * _water_cast_progress
		_water_cast.visible = reach > 0.05
		if _water_cast.visible:
			var direction := path.normalized()
			_water_cast.position = source + direction * reach * 0.5
			_water_cast.quaternion = Quaternion(Vector3.UP, direction)
			_water_cast.scale = Vector3(1.0, reach, 1.0)


## Camera-only envelope for the Riverwatch signature. The fight camera already
## frames an optional third subject; these eight world points reserve the full
## danger shape plus visible dodge room without changing its collision.
func signature_frame_points() -> PackedVector3Array:
	var points := PackedVector3Array()
	if _profile.get("cue_water_wall") != true:
		return points
	var clearance := maxf(0.0, float(_profile.get("cue_water_camera_clearance_m", 0.6)))
	var feet: Array[Vector3] = []
	var height := 0.0
	if _water_wall != null and _heading.length_squared() > 0.0:
		var length := maxf(0.5, float(_profile.get("range", 8.0)))
		var half_width := length * tan(deg_to_rad(float(_profile.get("cone_degrees", 50.0))) * 0.5)
		var side := _heading.cross(Vector3.UP).normalized()
		var back := _origin - _heading * clearance
		var front := _origin + _heading * (length + clearance)
		feet = [back - side * clearance, back + side * clearance,
			front - side * (half_width + clearance), front + side * (half_width + clearance)]
		height = maxf(0.6, float(_profile.get("cue_water_wall_height_m", 1.8)))
	elif _water_boundary != null and _marker.is_finite():
		var radius := maxf(0.1, float(_profile.get("marker_radius_m", 0.0))
			+ float(_profile.get("target_radius_m", 0.0)) + clearance)
		feet = [_marker + Vector3(radius, 0, 0), _marker + Vector3(0, 0, radius),
			_marker + Vector3(-radius, 0, 0), _marker + Vector3(0, 0, -radius)]
		height = radius * float(_profile.get("cue_water_wall_height_ratio", 0.85))
	if feet.size() != 4:
		return points
	for up in [0.0, height]:
		for foot: Vector3 in feet:
			points.append(foot + Vector3.UP * up)
	return points


func aim(origin: Vector3, heading: Vector3, marker: Vector3) -> void:
	var inputs := [origin, heading, marker]
	if inputs == _aimed:
		return
	_aimed = inputs
	_ground_seen.clear()
	_origin = origin
	_heading = Vector3(heading.x, 0.0, heading.z).normalized()
	_marker = marker
	if not _water_spray.is_empty():
		var length := maxf(0.5, float(_profile.get("range", 8.0)))
		var spacing := deg_to_rad(float(_profile.get("projectile_spacing_degrees", 16.0)))
		for index in _water_spray.size():
			var direction := _heading.rotated(Vector3.UP, (float(index) - 1.0) * spacing)
			var spray := _water_spray[index]
			spray.position = _origin + direction * (length * 0.5) + Vector3.UP * 0.65
			spray.quaternion = Quaternion(Vector3.UP, direction)
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var shape := str(_profile.get("telegraph_shape", "cone"))
	_seat_y = NAN
	if not _soft.is_empty():
		_aim_soft(shape)
		_mesh.surface_end()
		return
	match shape:
		"ring":
			_disc(_origin, float(_profile.get("inner_radius_m", 0.0)), float(_profile.get("range", 0.0)), TAU)
		"marker", "field":
			_seat_y = _marker.y
			# The hit area: marker radius plus the target's own radius (F04#1).
			_disc(_marker, 0.0, float(_profile.get("marker_radius_m", 0.0)) + float(_profile.get("target_radius_m", 0.0)), TAU)
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


## The surface actually walked at (x, z): the first static floor a short ray
## meets from just above the attacker's level, skipping creature and trainer
## bodies, else the ground query. F04#1 judge (2026-10-11): the Relay fight
## stands on a flat built platform over sloping terrain, so marks seated on
## the terrain query ran under the deck (a hairline lane) or through the
## creatures (a floating marker). Out of the tree (unit fixtures) it is the
## query unchanged. Shared with lunge_lane.gd.
static func walked_floor(body: Node3D, x: float, z: float, query: float, above: float) -> float:
	if body == null or not body.is_inside_tree():
		return query
	var space := body.get_world_3d().direct_space_state
	var top := (maxf(query, above) if is_finite(query) else above) + 1.5
	# Reach at least as far down as the ground query: a hovering attacker
	# (F04#1 Galecrest) put the 6 m ray's end above the Relay deck, so the
	# disc at the target fell through to the terrain under it.
	var bottom := minf(top - 6.0, (query if is_finite(query) else above) - 0.5)
	var exclude: Array[RID] = []
	if body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	for _try in 4:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z))
		ray.collide_with_areas = false
		ray.exclude = exclude
		ray.collision_mask = 0x7FFFFFFF  # not the camera-only occluder layer
		var hit := space.intersect_ray(ray)
		if hit.is_empty():
			return query
		if hit.collider is CharacterBody3D or hit.collider is RigidBody3D:
			exclude.append(hit.rid)
			continue
		return float((hit.position as Vector3).y)
	return query


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
		_vertex(point, Color(1.0, 1.0, 1.0, alpha))


func _vertex(point: Vector3, colour: Color) -> void:
	var ground := point.y
	if is_finite(_seat_y):
		ground = _seat_y
	elif is_instance_valid(_body) and _body.has_method("_ground_height"):
		var key := Vector2(point.x, point.z)
		var measured: float
		if _ground_seen.has(key):
			measured = float(_ground_seen[key])
		else:
			measured = walked_floor(_body, point.x, point.z,
				float(_body.call("_ground_height", point.x, point.z)), _origin.y)
			_ground_seen[key] = measured
		if is_finite(measured):
			ground = measured
	_mesh.surface_set_color(colour)
	_mesh.surface_add_vertex(Vector3(point.x, ground + _lift, point.z))


## Soft style: the same shapes as `aim`'s match, as a faint wash, a glow band
## feathering inward from each edge, and a thin lit core line on the edge.
func _aim_soft(shape: String) -> void:
	match shape:
		"ring":
			_soft_disc(_origin, float(_profile.get("inner_radius_m", 0.0)), float(_profile.get("range", 0.0)), TAU)
		"marker", "field":
			_seat_y = _marker.y
			_soft_disc(_marker, 0.0, float(_profile.get("marker_radius_m", 0.0)) + float(_profile.get("target_radius_m", 0.0)), TAU)
		"cone", "fan":
			_soft_disc(_origin, 0.0, float(_profile.get("range", 0.0)), deg_to_rad(float(_profile.get("cone_degrees", 0.0))))
		"lane":
			var side := _heading.cross(Vector3.UP)
			var half_width := float(_profile.get("lane_half_width_m", 0.0))
			var length := float(_profile.get("lunge", 0.0))
			var left := _origin - side * half_width
			var right := _origin + side * half_width
			var far_left := left + _heading * length
			var far_right := right + _heading * length
			var feather := minf(float(_soft.get("feather_m", 0.3)), half_width * float(_soft.get("feather_max_fraction", 0.35)))
			_soft_fill([left, right, far_right, far_left])
			_soft_edge(left, far_left, side, feather)
			_soft_edge(right, far_right, -side, feather)
			_soft_edge(far_left, far_right, -_heading, minf(feather, length * 0.4))


func _soft_disc(centre: Vector3, inner: float, outer: float, arc: float) -> void:
	var count := maxi(2, int(ceil(float(_segments) * arc / TAU)))
	var feather := minf(float(_soft.get("feather_m", 0.3)), (outer - inner) * float(_soft.get("feather_max_fraction", 0.35)))
	for index: int in count:
		var a := -arc * 0.5 + arc * float(index) / float(count)
		var b := -arc * 0.5 + arc * float(index + 1) / float(count)
		var da := _heading.rotated(Vector3.UP, a)
		var db := _heading.rotated(Vector3.UP, b)
		_soft_fill([centre + da * inner, centre + da * outer, centre + db * outer, centre + db * inner])
		_soft_arc(centre, da, db, outer, -feather)
		if inner > 0.0:
			_soft_arc(centre, da, db, inner, feather)
	if arc < TAU:
		for sign: float in [-1.0, 1.0]:
			var direction := _heading.rotated(Vector3.UP, sign * arc * 0.5)
			# Toward the inside of the arc: the rotation's tangent, reversed
			# on the positive side.
			var inward := Vector3.UP.cross(direction) * -sign
			_soft_edge(centre + direction * inner, centre + direction * outer, inward,
				minf(feather, outer * sin(minf(arc * 0.5, PI * 0.5)) * 0.5))


## The faint interior wash: enough that the zone does not read as an empty
## selector outline, too little to hide a body standing in it.
func _soft_fill(points: Array) -> void:
	var wash := Color(_tint, float(_soft.get("fill_alpha", 0.05)))
	for index: int in [0, 1, 2, 0, 2, 3]:
		_vertex(points[index], wash)


## One arc segment's edge at `radius`: the glow band runs `feather` metres
## radially (negative = inward), plus a thin feathered rim outside it.
func _soft_arc(centre: Vector3, da: Vector3, db: Vector3, radius: float, feather: float) -> void:
	var glow := Color(_tint, float(_soft.get("edge_alpha", 0.7)))
	var clear := Color(_tint, 0.0)
	var core := Color(STYLE.core_colour(_tint, _soft), float(_soft.get("core_alpha", 0.95)))
	var half_core := float(_soft.get("core_width_m", 0.07)) * 0.5
	var rim := float(_soft.get("outer_feather_m", 0.1))
	var out := -signf(feather) if feather != 0.0 else 1.0
	_band(centre + da * radius, centre + db * radius, centre + db * (radius + feather),
		centre + da * (radius + feather), glow, clear)
	_band(centre + da * (radius - out * half_core), centre + db * (radius - out * half_core),
		centre + db * (radius + out * half_core), centre + da * (radius + out * half_core), core, core)
	_band(centre + da * (radius + out * half_core), centre + db * (radius + out * half_core),
		centre + db * (radius + out * (half_core + rim)), centre + da * (radius + out * (half_core + rim)), core, Color(core, 0.0))


## A straight edge from `start` to `finish`; `inward` (unit, flat) points into
## the danger zone.
func _soft_edge(start: Vector3, finish: Vector3, inward: Vector3, feather: float) -> void:
	var glow := Color(_tint, float(_soft.get("edge_alpha", 0.7)))
	var core := Color(STYLE.core_colour(_tint, _soft), float(_soft.get("core_alpha", 0.95)))
	var half_core := inward * float(_soft.get("core_width_m", 0.07)) * 0.5
	var rim := inward * float(_soft.get("outer_feather_m", 0.1))
	_band(start, finish, finish + inward * feather, start + inward * feather, glow, Color(_tint, 0.0))
	_band(start + half_core, finish + half_core, finish - half_core, start - half_core, core, core)
	_band(start - half_core, finish - half_core, finish - half_core - rim, start - half_core - rim, core, Color(core, 0.0))


## A quad whose first two corners carry `near` and last two `far`.
func _band(a: Vector3, b: Vector3, c: Vector3, d: Vector3, near: Color, far: Color) -> void:
	_vertex(a, near)
	_vertex(b, near)
	_vertex(c, far)
	_vertex(a, near)
	_vertex(c, far)
	_vertex(d, far)
