extends RefCounted

## Original F35 CPU-authored volumes. Y is up; directed objects face -Z.
## Like F25's fluid geometry, curved bodies have real depth-tested topology.
## This library has no world query, timing, particle lease or gameplay writer.
## One bounded surface per object; callers cache meshes outside the frame loop.
const HARD_VERTEX_CAP := 48000
const F25_GEOMETRY_PATH := "res://scripts/vfx/move_effect_geometry.gd"
const F25_SHARED_SHAPES := {
	"rock": "stone", "water": "rolling_wave", "ice": "ice_crystal", "wind": "vortex",
}
const SHAPE_KINDS := [
	"tectonic_jaw", "tide_crest", "gale_feather", "verdant_antler", "abyss_rib",
	"solar_ray", "cobra_coil", "tusk_root", "furnace_vent", "shell_cannon",
	"capra_horn", "thunder_paw", "rock", "flame", "water", "wind", "ice",
	"shadow", "psychic", "lightning", "leviathan", "solar_mane", "wind_spire",
	"shoulder_conduit",
]


class Body extends RefCounted:
	var mesh := ImmediateMesh.new()
	var vertices := 0
	var cap := HARD_VERTEX_CAP
	var clipped := false

	func _init(vertex_cap: int) -> void:
		cap = clampi(vertex_cap, 96, HARD_VERTEX_CAP)
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	func triangle(a: Vector3, b: Vector3, c: Vector3, tone: float = 1.0) -> void:
		if vertices + 3 > cap:
			clipped = true
			return
		var normal := (b - a).cross(c - a)
		if normal.length_squared() < 0.000000001:
			return
		normal = normal.normalized()
		var shade := clampf(tone, 0.35, 1.0)
		var points: Array[Vector3] = [a, b, c]
		var uv: Array[Vector2] = [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE]
		for i in 3:
			mesh.surface_set_normal(normal)
			mesh.surface_set_color(Color(shade, shade, shade, 1.0))
			mesh.surface_set_uv(uv[i])
			mesh.surface_add_vertex(points[i])
		vertices += 3

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, tone: float = 1.0) -> void:
		triangle(a, b, c, tone)
		triangle(a, c, d, tone)

	func finish() -> Mesh:
		mesh.surface_end()
		mesh.set_meta("ultimate_vertex_count", vertices)
		mesh.set_meta("ultimate_budget_clipped", clipped)
		return mesh


static func material(colour: Color, opacity: float = 1.0, lit: bool = true) -> Material:
	var out := StandardMaterial3D.new()
	var alpha := clampf(opacity, 0.0, 1.0)
	out.albedo_color = Color(colour.r, colour.g, colour.b, alpha)
	out.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	out.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.999 else BaseMaterial3D.TRANSPARENCY_DISABLED
	out.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	out.cull_mode = BaseMaterial3D.CULL_DISABLED
	out.vertex_color_use_as_albedo = true
	out.roughness = 0.72 if lit else 1.0
	out.no_depth_test = false
	# Geometry/vertex contrast carries identity on Compatibility without bloom.
	return out


static func shape(kind: String, size: float, profile: Dictionary = {}) -> Mesh:
	if kind not in SHAPE_KINDS:
		push_error("Unknown ultimate shape: %s" % kind)
		return null
	if not is_finite(size) or size <= 0.0:
		return null
	# ROOT enables this only with the landed, reviewed F25 dependency. Dynamic
	# loading avoids preloading unavailable producer files into the OFF baseline.
	# The original CPU volumes below retain a usable Compatibility fallback.
	if bool(profile.get("reuse_archetype", false)) and F25_SHARED_SHAPES.has(kind):
		var reused := _f25_shape(kind, size, profile)
		if reused != null:
			return reused
	var body := Body.new(int(profile.get("vertex_cap", HARD_VERTEX_CAP)))
	var scale := clampf(size, 0.001, 128.0)
	match kind:
		"tectonic_jaw": _tectonic_jaw(body, scale, profile)
		"tide_crest":
			_wave(body, scale, profile)
			_leviathan(body, scale * _number(profile, "leviathan_scale", 0.75, 0.1, 1.5), profile)
		"gale_feather": _feather(body, scale, profile)
		"verdant_antler": _antler(body, scale, profile)
		"abyss_rib": _nautilus(body, scale, profile)
		"solar_ray": _solar_ray(body, scale, profile)
		"cobra_coil": _cobra(body, scale, profile)
		"tusk_root": _root_tusk(body, scale, profile)
		"furnace_vent": _vent(body, scale, profile)
		"shell_cannon": _shell(body, scale, profile)
		"capra_horn": _horn(body, scale, profile)
		"thunder_paw": _paw(body, scale, profile)
		"rock": _stone(body, scale, profile)
		"flame": _flame(body, scale, profile)
		"water": _wave(body, scale, profile)
		"wind", "wind_spire": _wind(body, scale, profile)
		"ice": _crystals(body, scale, profile)
		"shadow": _shadow(body, scale, profile)
		"psychic": _psychic(body, scale, profile)
		"lightning": _lightning(body, scale, profile)
		"leviathan": _leviathan(body, scale, profile)
		"solar_mane": _mane(body, scale, profile)
		"shoulder_conduit": _grounding(body, scale, profile)
	return body.finish()


static func _f25_shape(kind: String, size: float, profile: Dictionary) -> Mesh:
	if not ResourceLoader.exists(F25_GEOMETRY_PATH):
		return null
	var producer: Script = load(F25_GEOMETRY_PATH) as Script
	if producer == null:
		return null
	var frozen := profile.duplicate(true)
	# Bound the exact F25 tunable names too: its stone/vortex bodies otherwise
	# accept arbitrary segment counts. No shape call is made for unknown APIs.
	frozen["segments"] = clampi(int(profile.get("path_segments", 14)), 8, 24)
	frozen["rings"] = clampi(int(profile.get("rock_levels", 5)), 3, 7)
	frozen["curl_segments"] = clampi(int(profile.get("curl_segments", 10)), 6, 16)
	frozen["height_ratio"] = _number(profile, "height_ratio", 2.1, 0.5, 3.5)
	frozen["width_ratio"] = _number(profile, "crest_width", 1.5, 0.5, 2.5)
	frozen["turns"] = _number(profile, "spire_turns", 1.25, 0.6, 2.0)
	if kind == "ice": frozen["segments"] = clampi(int(profile.get("radial_segments", 6)), 4, 8)
	return producer.call("shape", str(F25_SHARED_SHAPES[kind]), clampf(size, 0.001, 128.0), frozen) as Mesh


static func _number(p: Dictionary, key: String, fallback: float, low: float, high: float) -> float:
	var value := float(p.get(key, fallback))
	return clampf(value, low, high) if is_finite(value) else fallback


static func _steps(p: Dictionary) -> int:
	return clampi(int(p.get("path_segments", 14)), 6, 24)


static func _sides(p: Dictionary) -> int:
	return clampi(int(p.get("radial_segments", 7)), 4, 10)


static func _details(p: Dictionary, fallback: int, maximum: int = 12) -> int:
	return clampi(int(p.get("detail_count", fallback)), 2, maximum)


## Parallel transported sweep frame avoids the horizontal-tangent flip seen
## in naïve cross(UP) tubes. Every sweep has elliptical, tapered cross-sections.
static func _sweep(b: Body, points: Array[Vector3], radii: Array[Vector2], sides: int,
		tone: float = 1.0, close_ends: bool = true) -> void:
	if points.size() < 2 or radii.size() != points.size():
		return
	var previous := Vector3.RIGHT
	var sections: Array = []
	for i in points.size():
		var tangent := points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]
		if tangent.length_squared() < 0.000001:
			tangent = Vector3.UP
		tangent = tangent.normalized()
		var side := previous - tangent * previous.dot(tangent)
		if side.length_squared() < 0.0001:
			side = tangent.cross(Vector3.FORWARD)
		if side.length_squared() < 0.0001:
			side = tangent.cross(Vector3.UP)
		side = side.normalized()
		var depth := tangent.cross(side).normalized()
		previous = side
		var section: Array[Vector3] = []
		for j in sides:
			var theta := TAU * float(j) / float(sides)
			section.append(points[i] + side * cos(theta) * radii[i].x + depth * sin(theta) * radii[i].y)
		sections.append(section)
	for i in points.size() - 1:
		for j in sides:
			var next := (j + 1) % sides
			b.quad(sections[i][j], sections[i][next], sections[i + 1][next], sections[i + 1][j],
				tone * (0.82 + 0.18 * absf(cos(TAU * float(j) / float(sides)))))
	if close_ends:
		for j in sides:
			var next := (j + 1) % sides
			b.triangle(points[0], sections[0][next], sections[0][j], tone * 0.8)
			b.triangle(points[-1], sections[-1][j], sections[-1][next], tone)


static func _curve(b: Body, controls: Array[Vector3], base: float, tip: float,
		p: Dictionary, aspect: float = 1.0, tone: float = 1.0) -> void:
	var points: Array[Vector3] = []
	var radii: Array[Vector2] = []
	var steps := _steps(p)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var radius := lerpf(base, tip, t)
		points.append(_bezier(controls, t))
		radii.append(Vector2(radius, radius * aspect))
	_sweep(b, points, radii, _sides(p), tone)


static func _bezier(c: Array[Vector3], t: float) -> Vector3:
	var inv := 1.0 - t
	return c[0] * inv * inv * inv + c[1] * 3.0 * inv * inv * t + c[2] * 3.0 * inv * t * t + c[3] * t * t * t


static func _tectonic_jaw(b: Body, s: float, p: Dictionary) -> void:
	var width := s * _number(p, "jaw_width", 1.05, 0.4, 2.0)
	var height := s * _number(p, "jaw_height", 0.7, 0.2, 1.4)
	var teeth := _details(p, 7, 11)
	# Three offset strata leave deep crenellations; the jaw is a rising horseshoe.
	for layer in 3:
		var points: Array[Vector3] = []
		var radii: Array[Vector2] = []
		for i in _steps(p) + 1:
			var t := float(i) / float(_steps(p))
			var a := lerpf(-PI * 0.88, PI * 0.88, t)
			var notch := 1.0 + 0.08 * sin(t * 33.0 + layer)
			points.append(Vector3(sin(a) * width, (0.1 + layer * 0.18) * height + 0.2 * height * cos(a), cos(a) * s * 0.68))
			radii.append(Vector2(s * 0.19 * notch, s * (0.22 - layer * 0.035)))
		_sweep(b, points, radii, 5, 0.72 + layer * 0.1)
	for i in teeth:
		var a := lerpf(-2.4, 2.4, float(i) / float(teeth - 1))
		var foot := Vector3(sin(a) * width, height * 0.64, cos(a) * s * 0.68)
		var tip := foot + Vector3(-sin(a) * s * 0.23, height * (0.5 + 0.18 * cos(a * 3.0)), -cos(a) * s * 0.24)
		_curve(b, [foot, foot + Vector3.UP * height * 0.2, tip - Vector3.UP * height * 0.15, tip], s * 0.13, s * 0.015, p, 0.72)


static func _wave(b: Body, s: float, p: Dictionary) -> void:
	var across := _steps(p)
	var curl := clampi(int(p.get("curl_segments", 10)), 6, 16)
	var width := s * _number(p, "crest_width", 1.5, 0.5, 2.5)
	var thickness := s * _number(p, "crest_thickness", 0.07, 0.03, 0.18)
	# Closed curling water volume; tapered ends and a serrated foam lip.
	for x in across:
		for y in curl:
			var u0 := float(x) / float(across)
			var u1 := float(x + 1) / float(across)
			var v0 := float(y) / float(curl)
			var v1 := float(y + 1) / float(curl)
			for face in [-1.0, 1.0]:
				var a := _wave_point(u0, v0, s, width, thickness * face)
				var c := _wave_point(u1, v1, s, width, thickness * face)
				var right := _wave_point(u1, v0, s, width, thickness * face)
				var left := _wave_point(u0, v1, s, width, thickness * face)
				if face > 0.0: b.quad(a, left, c, right, 0.74 + v0 * 0.26)
				else: b.quad(a, right, c, left, 0.68 + v0 * 0.18)
		for edge_v in [0.0, 1.0]:
			b.quad(_wave_point(float(x) / across, edge_v, s, width, -thickness),
				_wave_point(float(x + 1) / across, edge_v, s, width, -thickness),
				_wave_point(float(x + 1) / across, edge_v, s, width, thickness),
				_wave_point(float(x) / across, edge_v, s, width, thickness))
	for edge_u in [0.0, 1.0]:
		for y in curl:
			b.quad(_wave_point(edge_u, float(y) / curl, s, width, -thickness),
				_wave_point(edge_u, float(y + 1) / curl, s, width, -thickness),
				_wave_point(edge_u, float(y + 1) / curl, s, width, thickness),
				_wave_point(edge_u, float(y) / curl, s, width, thickness))


static func _wave_point(u: float, v: float, s: float, width: float, depth: float) -> Vector3:
	var a := lerpf(-PI * 0.48, PI * 0.86, v)
	var envelope := 0.6 + 0.4 * sin(u * PI)
	var radius := s * envelope * (0.94 - v * 0.26) + depth
	return Vector3(lerpf(-width, width, u), s * envelope + sin(a) * radius,
		-cos(a) * radius + sin(u * PI * 5.0) * s * v * 0.035)


static func _leviathan(b: Body, s: float, p: Dictionary) -> void:
	var points: Array[Vector3] = []
	var radii: Array[Vector2] = []
	for i in _steps(p) + 1:
		var t := float(i) / float(_steps(p))
		points.append(Vector3(0, s * (0.18 + sin(t * PI) * 1.12), s * (1.1 - 2.3 * t)))
		var width := s * (0.075 + 0.36 * pow(sin(t * PI), 0.7))
		radii.append(Vector2(width, width * 0.7))
	_sweep(b, points, radii, _sides(p), 0.88)
	# Forked flukes, swept pectoral fins and a dorsal crest silhouette.
	for sign_x in [-1.0, 1.0]:
		_curve(b, [Vector3(0, s * 0.24, s), Vector3(sign_x * s * 0.3, s * 0.35, s * 1.18),
			Vector3(sign_x * s * 0.58, s * 0.48, s * 1.12), Vector3(sign_x * s * 0.75, s * 0.53, s * 0.88)],
			s * 0.19, s * 0.015, p, 0.18)
		_curve(b, [Vector3(sign_x * s * 0.27, s * 1.04, -s * 0.1), Vector3(sign_x * s * 0.65, s * 0.8, s * 0.1),
			Vector3(sign_x * s * 0.92, s * 0.52, s * 0.28), Vector3(sign_x * s * 1.0, s * 0.46, s * 0.4)],
			s * 0.18, s * 0.02, p, 0.16)
	_curve(b, [Vector3(0, s * 1.37, 0), Vector3(0, s * 1.68, s * 0.22),
		Vector3(0, s * 1.7, s * 0.43), Vector3(0, s * 1.46, s * 0.55)], s * 0.1, s * 0.015, p, 0.22)


static func _feather(b: Body, s: float, p: Dictionary) -> void:
	var length := s * _number(p, "feather_length", 2.0, 0.7, 3.0)
	var width := s * _number(p, "feather_width", 0.44, 0.15, 0.85)
	var barbs := _details(p, 9, 12)
	_curve(b, [Vector3(0, -length * 0.45, 0), Vector3(s * 0.08, 0, -s * 0.12),
		Vector3(s * 0.12, length * 0.3, -s * 0.2), Vector3(0, length * 0.55, -s * 0.28)], s * 0.035, s * 0.012, p)
	for i in barbs:
		var t := float(i) / float(barbs)
		var spread := width * pow(sin((t * 0.86 + 0.06) * PI), 0.7)
		for side in [-1.0, 1.0]:
			var root := Vector3(s * 0.08 * sin(t * PI), lerpf(-length * 0.38, length * 0.43, t), -s * t * 0.24)
			_curve(b, [root, root + Vector3(side * spread * 0.3, length * 0.07, -s * 0.01),
				root + Vector3(side * spread * 0.82, length * 0.1, -s * 0.05),
				root + Vector3(side * spread, length * 0.13, -s * 0.09)],
				s * 0.045, s * 0.005, p, 0.3, 0.83 + t * 0.17)


static func _antler(b: Body, s: float, p: Dictionary) -> void:
	var height := s * _number(p, "antler_height", 1.8, 0.6, 2.8)
	var branches := _details(p, 5, 7)
	for side in [-1.0, 1.0]:
		_curve(b, [Vector3(side * s * 0.14, 0, 0), Vector3(side * s * 0.32, height * 0.38, s * 0.08),
			Vector3(side * s * 0.85, height * 0.82, s * 0.18), Vector3(side * s * 0.75, height, -s * 0.1)],
			s * 0.13, s * 0.018, p, 0.88, 0.8)
		for i in branches:
			var t := 0.24 + 0.64 * float(i) / float(branches)
			var root := Vector3(side * s * lerpf(0.3, 0.78, t), height * t, s * 0.08)
			var tip := root + Vector3(side * s * (0.28 + t * 0.2), height * 0.31, -s * (0.12 + t * 0.24))
			_curve(b, [root, root + Vector3(side * s * 0.16, height * 0.12, -s * 0.03), tip - Vector3.UP * height * 0.1, tip],
				s * 0.065, s * 0.012, p, 0.8)
			if bool(p.get("canopy_leaves", true)):
				_leaf(b, tip, Vector3(side * s * 0.22, s * 0.08, -s * 0.28), s * 0.11, p)
	# Curved root braces create a canopy, not a freestanding generic fork.
	for side in [-1.0, 1.0]:
		_curve(b, [Vector3.ZERO, Vector3(side * s * 0.22, -s * 0.08, s * 0.12),
			Vector3(side * s * 0.52, -s * 0.1, s * 0.3), Vector3(side * s * 0.7, -s * 0.1, s * 0.42)], s * 0.12, s * 0.025, p, 0.8, 0.7)


static func _leaf(b: Body, root: Vector3, direction: Vector3, width: float, p: Dictionary) -> void:
	var points: Array[Vector3] = []
	var radii: Array[Vector2] = []
	for i in _steps(p) + 1:
		var t := float(i) / float(_steps(p))
		points.append(root + direction * t + Vector3.UP * width * sin(t * PI))
		var w := width * maxf(0.02, sin(t * PI))
		radii.append(Vector2(w, w * 0.2))
	_sweep(b, points, radii, 4)


static func _nautilus(b: Body, s: float, p: Dictionary) -> void:
	var turns := _number(p, "nautilus_turns", 1.65, 1.0, 2.5)
	var points: Array[Vector3] = []
	var radii: Array[Vector2] = []
	var steps := _steps(p) * 2
	for i in steps + 1:
		var t := float(i) / float(steps)
		var a := t * TAU * turns
		var radius := s * lerpf(0.06, 0.88, t * t)
		points.append(Vector3(cos(a) * radius, s * 0.95 + sin(a) * radius, -s * t * 0.1))
		radii.append(Vector2(s * lerpf(0.018, 0.2, t), s * lerpf(0.012, 0.26, t)))
	_sweep(b, points, radii, _sides(p), 0.75)
	var ribs := _details(p, 7, 9)
	for i in ribs:
		var a := lerpf(0.2, 5.7, float(i) / float(ribs - 1))
		var inner := Vector3(cos(a), sin(a), 0) * s * 0.48 + Vector3.UP * s * 0.95
		var outer := Vector3(cos(a), sin(a), 0) * s * 1.02 + Vector3.UP * s * 0.95
		_curve(b, [inner, inner + Vector3(0, 0, -s * 0.43), outer + Vector3(0, 0, -s * 0.38), outer], s * 0.06, s * 0.025, p, 0.75)
	# Mouth tendrils sweep forward to make the nautilus read in profile.
	for i in 4:
		var root := points[-1]
		var tip := root + Vector3(s * (float(i) - 1.5) * 0.18, -s * 0.35, -s * 0.7)
		_curve(b, [root, root + Vector3(0, 0, -s * 0.25), tip + Vector3.UP * s * 0.2, tip], s * 0.065, s * 0.008, p)


static func _solar_ray(b: Body, s: float, p: Dictionary) -> void:
	var reach := s * _number(p, "ray_length", 1.8, 0.6, 2.7)
	var width := s * _number(p, "ray_width", 0.23, 0.06, 0.5)
	var points: Array[Vector3] = []
	var radii: Array[Vector2] = []
	for i in _steps(p) + 1:
		var t := float(i) / float(_steps(p))
		points.append(Vector3(s * sin(t * PI) * 0.2, reach * t, -s * t * t * 0.35))
		var edge := width * maxf(0.015, pow(sin(t * PI), 0.75))
		radii.append(Vector2(edge, edge * 0.2))
	_sweep(b, points, radii, 4)
	# Twin inner ridges are geometry, so the ray remains legible without glow.
	for side in [-1.0, 1.0]:
		_curve(b, [Vector3.ZERO, Vector3(side * width * 0.25, reach * 0.3, -s * 0.05),
			Vector3(side * width * 0.45 + s * 0.08, reach * 0.7, -s * 0.13), Vector3(0, reach, -s * 0.35)], s * 0.025, s * 0.006, p)


static func _mane(b: Body, s: float, p: Dictionary) -> void:
	var petals := _details(p, 11, 12)
	for i in petals:
		var a := TAU * float(i) / float(petals)
		var radial := Vector3(cos(a), sin(a), 0)
		_curve(b, [radial * s * 0.32, radial * s * 0.75 + Vector3(0, 0, -s * 0.12),
			radial * s * 1.15 + Vector3(-radial.y, radial.x, 0) * s * 0.12,
			radial * s * 1.42 + Vector3(0, 0, -s * 0.25)], s * 0.17, s * 0.008, p, 0.3)
	# Angular cheek/ear rays imply a lion face; central window preserves the actor.
	for side in [-1.0, 1.0]:
		_curve(b, [Vector3(side * s * 0.18, s * 0.3, 0), Vector3(side * s * 0.24, s * 0.55, -s * 0.08),
			Vector3(side * s * 0.47, s * 0.7, 0), Vector3(side * s * 0.5, s * 0.53, 0)], s * 0.1, s * 0.012, p, 0.55)


static func _cobra(b: Body, s: float, p: Dictionary) -> void:
	var turns := _number(p, "coil_turns", 1.35, 0.75, 2.2)
	var steps := _steps(p) * 2
	var points: Array[Vector3] = []
	var radii: Array[Vector2] = []
	for i in steps + 1:
		var t := float(i) / float(steps)
		var a := t * TAU * turns
		var r := s * (0.78 - t * 0.42)
		points.append(Vector3(cos(a) * r, s * (0.1 + t * 1.75), sin(a) * r))
		var radius := s * (0.045 + sin(t * PI * 0.75) * 0.14)
		radii.append(Vector2(radius, radius * 0.72))
	_sweep(b, points, radii, _sides(p), 0.82)
	var neck: Vector3 = points[-1]
	# Flared twin hood lobes and snout: no plain torus masquerading as a serpent.
	for side in [-1.0, 1.0]:
		_curve(b, [neck - Vector3.UP * s * 0.34, neck + Vector3(side * s * 0.37, -s * 0.16, 0),
			neck + Vector3(side * s * 0.33, s * 0.18, -s * 0.05), neck + Vector3(0, s * 0.2, -s * 0.12)],
			s * 0.09, s * 0.075, p, 0.32)
	_curve(b, [neck, neck + Vector3(0, s * 0.15, -s * 0.14),
		neck + Vector3(0, s * 0.18, -s * 0.34), neck + Vector3(0, s * 0.12, -s * 0.46)], s * 0.17, s * 0.085, p, 0.65)
	for i in 5:
		var root: Vector3 = points[clampi(2 + floori(float(i * (steps - 4)) / 5.0), 1, steps - 1)]
		_zigzag(b, root, root + Vector3(s * 0.3, s * 0.18, -s * 0.35), s * 0.023, p, i)


static func _root_tusk(b: Body, s: float, p: Dictionary) -> void:
	var height := s * _number(p, "tusk_height", 1.55, 0.5, 2.5)
	_curve(b, [Vector3(0, 0, s * 0.25), Vector3(-s * 0.18, height * 0.25, -s * 0.08),
		Vector3(-s * 0.12, height * 0.85, -s * 0.5), Vector3(s * 0.25, height, -s * 0.62)], s * 0.26, s * 0.015, p, 0.8, 0.9)
	var roots := _details(p, 5, 7)
	for i in roots:
		var a := TAU * float(i) / float(roots) + 0.2
		var radial := Vector3(cos(a), 0, sin(a))
		var root := Vector3(0, s * 0.22, s * 0.2)
		var end := radial * s * (0.85 + 0.12 * sin(i * 2.2)) + Vector3.UP * s * 0.03
		_curve(b, [root, root + radial * s * 0.35, end - radial * s * 0.1 + Vector3.UP * s * 0.15, end], s * 0.14, s * 0.018, p, 0.75, 0.73)
		var twig := end * 0.68 + Vector3.UP * s * 0.08
		_curve(b, [twig, twig + radial * s * 0.15, end + Vector3(-radial.z, 0, radial.x) * s * 0.18,
			end + Vector3(-radial.z, 0, radial.x) * s * 0.35], s * 0.06, s * 0.012, p, 0.7)


static func _vent(b: Body, s: float, p: Dictionary) -> void:
	var height := s * _number(p, "vent_height", 1.3, 0.5, 2.0)
	var vents := _details(p, 3, 5)
	for i in vents:
		var offset := Vector3((float(i) - float(vents - 1) * 0.5) * s * 0.5, 0, absf(float(i) - 1.0) * s * 0.12)
		var end := offset + Vector3(s * 0.1, height * (0.78 + 0.13 * i), -s * 0.17)
		_pipe(b, [offset, offset + Vector3.UP * height * 0.3, end - Vector3.UP * height * 0.22, end], s * 0.23, s * 0.14, p)
		# Swept ivory furnace tusk guards the open vent mouth.
		_curve(b, [offset + Vector3(0, s * 0.06, -s * 0.18), offset + Vector3(0, s * 0.38, -s * 0.4),
			end + Vector3(0, s * 0.2, -s * 0.34), end + Vector3(0, s * 0.35, -s * 0.23)], s * 0.11, s * 0.008, p)
	for i in 3:
		var level := s * (0.12 + i * 0.22)
		_curve(b, [Vector3(-s * 0.76, level, s * 0.04), Vector3(-s * 0.24, level - s * 0.07, -s * 0.08),
			Vector3(s * 0.24, level - s * 0.07, -s * 0.08), Vector3(s * 0.76, level, s * 0.04)], s * 0.075, s * 0.075, p, 0.75, 0.75)


## Hollow curved artillery, with outside/inside walls and an annular lip.
## This is an open barrel rather than a filled cylinder facing the camera.
static func _pipe(b: Body, controls: Array[Vector3], root_radius: float,
		mouth_radius: float, p: Dictionary) -> void:
	var outer: Array[Vector3] = []
	var inner: Array[Vector3] = []
	var steps := _steps(p)
	var sides := _sides(p)
	var wall := _number(p, "pipe_wall_ratio", 0.22, 0.1, 0.4)
	var previous := Vector3.RIGHT
	for i in steps + 1:
		var t := float(i) / float(steps)
		var center := _bezier(controls, t)
		var tangent := (_bezier(controls, minf(t + 0.01, 1.0)) - _bezier(controls, maxf(t - 0.01, 0.0))).normalized()
		var side := previous - tangent * previous.dot(tangent)
		if side.length_squared() < 0.00001: side = tangent.cross(Vector3.FORWARD)
		if side.length_squared() < 0.00001: side = tangent.cross(Vector3.UP)
		side = side.normalized()
		previous = side
		var up := tangent.cross(side).normalized()
		var radius := lerpf(root_radius, mouth_radius, t) * (1.0 + 0.05 * sin(t * TAU * 3.0))
		for j in sides:
			var a := TAU * float(j) / float(sides)
			var radial := side * cos(a) + up * sin(a)
			outer.append(center + radial * radius)
			inner.append(center + radial * radius * (1.0 - wall))
	for i in steps:
		for j in sides:
			var next := (j + 1) % sides
			var a := i * sides + j
			var c := (i + 1) * sides + next
			var right := i * sides + next
			var left := (i + 1) * sides + j
			b.quad(outer[a], outer[right], outer[c], outer[left], 0.86)
			b.quad(inner[a], inner[left], inner[c], inner[right], 0.48)
	for j in sides:
		var next := (j + 1) % sides
		b.quad(outer[steps * sides + j], outer[steps * sides + next],
			inner[steps * sides + next], inner[steps * sides + j])
		b.quad(outer[next], outer[j], inner[j], inner[next], 0.7)


static func _shell(b: Body, s: float, p: Dictionary) -> void:
	var plates := _details(p, 5, 7)
	# Nested vaulted shell ribs carry unequal scutes and leave open negative space.
	for i in plates:
		var z := lerpf(s * 0.65, -s * 0.65, float(i) / float(plates - 1))
		var width := s * (0.75 + 0.2 * sin(float(i) * PI / float(plates - 1)))
		_curve(b, [Vector3(-width, s * 0.1, z), Vector3(-width * 0.9, s * 0.92, z),
			Vector3(width * 0.9, s * 0.92, z), Vector3(width, s * 0.1, z)], s * 0.16, s * 0.16, p, 0.6, 0.76 + i * 0.035)
		_curve(b, [Vector3(0, s * 0.76, z + s * 0.05), Vector3(s * 0.1, s * 0.94, z),
			Vector3(0, s * 1.04, z - s * 0.07), Vector3(0, s * 0.86, z - s * 0.13)], s * 0.08, s * 0.025, p, 0.65)
	for side in [-1.0, 1.0]:
		_pipe(b, [Vector3(side * s * 0.35, s * 0.55, s * 0.36), Vector3(side * s * 0.46, s * 0.94, -s * 0.1),
			Vector3(side * s * 0.58, s * 1.1, -s * 0.62), Vector3(side * s * 0.64, s * 1.03, -s * 1.12)], s * 0.22, s * 0.19, p)


static func _horn(b: Body, s: float, p: Dictionary) -> void:
	var height := s * _number(p, "horn_height", 1.8, 0.7, 2.8)
	for side in [-1.0, 1.0]:
		var root := Vector3(side * s * 0.22, 0, 0)
		var tip := Vector3(side * s * 0.72, height, s * 0.32)
		_curve(b, [root, Vector3(side * s * 0.65, height * 0.24, s * 0.42),
			Vector3(side * s * 0.9, height * 0.76, s * 0.62), tip], s * 0.18, s * 0.012, p, 0.8, 0.92)
		var fork := Vector3(side * s * 0.66, height * 0.6, s * 0.41)
		_curve(b, [fork, fork + Vector3(side * s * 0.18, height * 0.12, 0),
			fork + Vector3(side * s * 0.37, height * 0.27, -s * 0.24), fork + Vector3(side * s * 0.32, height * 0.39, -s * 0.35)], s * 0.075, s * 0.008, p)
		for i in 4:
			var t := 0.17 + i * 0.135
			var center := _bezier([root, Vector3(side * s * 0.65, height * 0.24, s * 0.42),
				Vector3(side * s * 0.9, height * 0.76, s * 0.62), tip], t)
			_curve(b, [center + Vector3(-s * 0.11, 0, -s * 0.08), center + Vector3(-s * 0.05, s * 0.04, -s * 0.14),
				center + Vector3(s * 0.05, s * 0.04, -s * 0.14), center + Vector3(s * 0.11, 0, -s * 0.08)], s * 0.025, s * 0.025, p)


static func _paw(b: Body, s: float, p: Dictionary) -> void:
	var width := s * _number(p, "paw_width", 0.78, 0.4, 1.4)
	var depth := s * _number(p, "paw_depth", 0.72, 0.3, 1.4)
	# A flattened, broad polygonal pad. Four separate knuckles and hooked claws
	# remain readable through white-violet grounding accents, with no bear mesh.
	_pad(b, Vector3(0, s * 0.18, 0), Vector3(width, s * 0.27, depth), 9, 0.72)
	for i in 4:
		var x := lerpf(-width * 0.72, width * 0.72, float(i) / 3.0)
		var z := -depth * (0.86 + 0.11 * sin(float(i + 1) * PI / 5.0))
		_pad(b, Vector3(x, s * 0.2, z), Vector3(width * 0.24, s * 0.25, depth * 0.32), 7, 0.86)
		_curve(b, [Vector3(x, s * 0.23, z - depth * 0.2), Vector3(x, s * 0.25, z - depth * 0.35),
			Vector3(x, s * 0.15, z - depth * 0.47), Vector3(x, s * 0.06, z - depth * 0.44)], s * 0.064, s * 0.01, p, 0.68)
	_grounding(b, s, p)


static func _pad(b: Body, center: Vector3, extent: Vector3, sides: int, tone: float) -> void:
	var sections: Array = []
	for level in 4:
		var y := float([-0.8, -0.25, 0.5, 0.92][level])
		var r := float([0.58, 1.0, 0.94, 0.5][level])
		var section: Array[Vector3] = []
		for j in sides:
			var a := TAU * float(j) / float(sides)
			section.append(center + Vector3(cos(a) * extent.x * r, y * extent.y, -sin(a) * extent.z * r))
		sections.append(section)
	for level in 3:
		for j in sides:
			var next := (j + 1) % sides
			b.quad(sections[level][j], sections[level][next], sections[level + 1][next], sections[level + 1][j], tone + level * 0.05)
	for j in sides:
		var next := (j + 1) % sides
		b.triangle(center - Vector3.UP * extent.y * 0.8, sections[0][next], sections[0][j], tone * 0.8)
		b.triangle(center + Vector3.UP * extent.y * 0.92, sections[3][j], sections[3][next], tone)


static func _grounding(b: Body, s: float, p: Dictionary) -> void:
	var branches := _details(p, 4, 6)
	for i in branches:
		var a := lerpf(-PI * 0.9, PI * 0.9, float(i) / float(branches - 1))
		var root := Vector3(sin(a) * s * 0.65, s * 0.1, cos(a) * s * 0.54)
		var end := root + Vector3(sin(a) * s * 0.5, -s * 0.05, cos(a) * s * 0.5)
		_zigzag(b, root, end, s * 0.027, p, i)


static func _stone(b: Body, s: float, p: Dictionary) -> void:
	# Unequal layered convex strata retain a boulder silhouette at low detail.
	var levels := clampi(int(p.get("rock_levels", 5)), 3, 7)
	var sides := clampi(int(p.get("radial_segments", 8)), 5, 10)
	var sections: Array = []
	for level in levels + 1:
		var t := float(level) / float(levels)
		var radius := s * maxf(0.035, pow(sin(t * PI), 0.66))
		var section: Array[Vector3] = []
		for j in sides:
			var a := TAU * float(j) / float(sides) + sin(level * 1.7) * 0.09
			var ridge := 1.0 + 0.13 * sin(j * 3.71 + level * 1.9)
			section.append(Vector3(cos(a) * radius * ridge, s * lerpf(-0.7, 0.88, t), -sin(a) * radius * ridge * 0.85))
		sections.append(section)
	for level in levels:
		for j in sides:
			var next := (j + 1) % sides
			b.quad(sections[level][j], sections[level][next], sections[level + 1][next], sections[level + 1][j], 0.68 + level * 0.04)
	for j in sides:
		b.triangle(Vector3(0, -s * 0.7, 0), sections[0][(j + 1) % sides], sections[0][j], 0.7)
		b.triangle(Vector3(0, s * 0.88, 0), sections[-1][j], sections[-1][(j + 1) % sides])


static func _flame(b: Body, s: float, p: Dictionary) -> void:
	var tongues := _details(p, 5, 7)
	var height := s * _number(p, "flame_height", 2.0, 0.6, 3.0)
	for i in tongues:
		var angle := TAU * float(i) / float(tongues)
		var radial := Vector3(cos(angle), 0, sin(angle))
		var foot := radial * s * (0.13 if i == 0 else 0.4)
		var reach := height * (1.0 - 0.08 * i)
		_curve(b, [foot, foot + Vector3.UP * reach * 0.32 - radial * s * 0.18,
			foot + Vector3.UP * reach * 0.78 + radial * s * 0.32,
			foot + Vector3.UP * reach - radial * s * 0.22], s * (0.25 - i * 0.014), s * 0.009, p, 0.68, 0.82 + i * 0.025)


static func _wind(b: Body, s: float, p: Dictionary) -> void:
	var strands := _details(p, 3, 5)
	var height := s * _number(p, "spire_height", 2.1, 0.8, 3.0)
	var turns := _number(p, "spire_turns", 1.25, 0.6, 2.0)
	for strand in strands:
		var points: Array[Vector3] = []
		var radii: Array[Vector2] = []
		for i in _steps(p) * 2 + 1:
			var t := float(i) / float(_steps(p) * 2)
			var angle := t * TAU * turns + TAU * float(strand) / float(strands)
			var radius := s * lerpf(0.14, 0.86, t)
			points.append(Vector3(cos(angle) * radius, height * t, sin(angle) * radius))
			var width := s * (0.04 + 0.08 * sin(t * PI))
			radii.append(Vector2(width, width * 0.25))
		_sweep(b, points, radii, 4, 0.86 + strand * 0.04)


static func _crystals(b: Body, s: float, p: Dictionary) -> void:
	var crystals := _details(p, 5, 7)
	for i in crystals:
		var a := TAU * float(i) / float(crystals)
		var root := Vector3(cos(a), 0, sin(a)) * s * (0.1 if i == 0 else 0.48)
		var height := s * (1.6 if i == 0 else 0.8 + 0.3 * sin(i * 2.7))
		var points: Array[Vector3] = [root, root + Vector3.UP * height * 0.2,
			root + Vector3(cos(a) * s * 0.1, height * 0.72, sin(a) * s * 0.1),
			root + Vector3(cos(a) * s * 0.18, height, sin(a) * s * 0.18)]
		var radii: Array[Vector2] = [Vector2.ONE * s * 0.1, Vector2.ONE * s * 0.22,
			Vector2.ONE * s * 0.17, Vector2.ONE * s * 0.002]
		_sweep(b, points, radii, 5, 0.84 + i * 0.02)


static func _shadow(b: Body, s: float, p: Dictionary) -> void:
	# Three hooked shadow claws carve an open travelling maw, rather than a ball.
	var hooks := _details(p, 3, 5)
	for i in hooks:
		var a := TAU * float(i) / float(hooks)
		var radial := Vector3(cos(a), sin(a), 0)
		_curve(b, [radial * s * 0.75 + Vector3(0, 0, s * 0.4), radial * s * 0.92,
			radial * s * 0.48 + Vector3(0, 0, -s * 0.7), radial * s * 0.12 + Vector3(0, 0, -s * 1.0)],
			s * 0.15, s * 0.014, p, 0.46, 0.7 + i * 0.08)


static func _psychic(b: Body, s: float, p: Dictionary) -> void:
	# Disconnected bowed orbital diamonds with an angular axial prism.
	var facets := _details(p, 4, 6)
	for i in facets:
		var a := TAU * float(i) / float(facets)
		var radial := Vector3(cos(a), sin(a), 0)
		var tangent := Vector3(-radial.y, radial.x, 0)
		var root := radial * s * 0.72
		_curve(b, [root - tangent * s * 0.4, root + radial * s * 0.15 - tangent * s * 0.14 + Vector3(0, 0, -s * 0.2),
			root + radial * s * 0.15 + tangent * s * 0.14 + Vector3(0, 0, -s * 0.2), root + tangent * s * 0.4], s * 0.065, s * 0.015, p, 0.52)
	var points: Array[Vector3] = [Vector3(0, -s * 0.65, 0), Vector3.ZERO, Vector3(0, s * 0.65, 0)]
	var radii: Array[Vector2] = [Vector2.ONE * s * 0.006, Vector2(s * 0.24, s * 0.16), Vector2.ONE * s * 0.006]
	_sweep(b, points, radii, 4)


static func _lightning(b: Body, s: float, p: Dictionary) -> void:
	var height := s * _number(p, "bolt_height", 2.2, 0.6, 3.5)
	var width := s * _number(p, "bolt_width", 0.055, 0.015, 0.15)
	_zigzag(b, Vector3.UP * height, Vector3.ZERO, width, p, 0)
	var forks := _details(p, 4, 6)
	for i in forks:
		var root := Vector3(0, height * (0.25 + i * 0.13), 0)
		var a := i * 2.399963
		var end := root + Vector3(cos(a), -0.8, sin(a)) * s * (0.4 + i * 0.06)
		_zigzag(b, root, end, width * 0.46, p, i + 1)


static func _zigzag(b: Body, start: Vector3, end: Vector3, width: float,
		p: Dictionary, phase: int) -> void:
	var points: Array[Vector3] = []
	var radii: Array[Vector2] = []
	var steps := clampi(int(p.get("bolt_segments", 7)), 4, 10)
	var tangent := (end - start).normalized()
	var side := tangent.cross(Vector3.UP)
	if side.length_squared() < 0.001: side = Vector3.RIGHT
	side = side.normalized()
	var reach := start.distance_to(end)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var noise := sin(float(i) * 5.71 + float(phase) * 1.37)
		points.append(start.lerp(end, t) + side * reach * noise * sin(t * PI) * 0.12)
		var radius := width * lerpf(1.0, 0.28, t)
		radii.append(Vector2(radius, radius * 0.65))
	_sweep(b, points, radii, 4)
