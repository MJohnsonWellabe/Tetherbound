extends Node3D

## W09-VFX (CL-A2). The level-up flourish: the reward picture on the creature
## that just levelled.
##
## For ~1.5 s (vfx.json `level_up.duration`): a column of light through the
## body, rings that rise from its feet past its crown, gold motes climbing with
## them, and -- through body_glow.gd -- a rim glow on the body itself. Sized
## from the body's own height and radius, so a bramblebun and a tuskroot each
## get a flourish that fits.
##
## Same construction rules as vfx_burst.gd and its siblings: camera-facing
## ImmediateMesh geometry (the rings are flat in the world's XZ plane, which
## from the combat camera's raised angle reads as the classic rising ellipse),
## MIX blend, vertex colours, physics-clocked, public `advance()`, AABB stated
## up front, one draw call. Parented to the body at its feet so it follows a
## creature that is still moving and is hidden with a body the fight puts away.

const RING_SEGMENTS := 36
const MOTE_SEGMENTS := 10

var _spec: Dictionary = {}
var _height: float = 1.0
var _radius: float = 0.5
var _colour: Color = Color("#ffd77a")
var _ring_colour: Color = Color("#fff2c4")
var _beam_colour: Color = Color("#ffe9a8")
var _duration: float = 1.5
var _life: float = 0.0
var _finished: bool = false
## Two surfaces, because the two halves of this effect want opposite depth
## rules. The BEAM runs straight through the creature, so depth-tested it is
## eaten by the very body it is celebrating (impact_flash.gd paid for that
## lesson). The RINGS and MOTES orbit OUTSIDE the silhouette at 2.3x the body
## radius, and alpha_aura.gd's header is explicit about what depth testing
## buys there: "a mote passing behind the creature is correctly hidden. That
## occlusion is most of what makes the ring read as being around the animal
## in space rather than painted over it." A blind round confirmed the
## un-tested version reads as one flat annulus decal, because the ring's near
## AND far edges both drew in front. So: beam un-tested, rings and motes
## tested.
var _mesh: ImmediateMesh = null
var _instance: MeshInstance3D = null
var _solid_mesh: ImmediateMesh = null
var _solid_instance: MeshInstance3D = null
## Which surface `_tri`/`_disc`/`_ring` are currently writing into.
var _target: ImmediateMesh = null


## `height`/`radius` are the body's own gameplay size (`body_height()` /
## `body_radius()`), read by combat_vfx.gd and handed in, so this node never
## reaches into creature_body.gd for anything.
static func attach(body: Node3D, spec: Dictionary, height: float, radius: float) -> Node3D:
	if body == null or not is_instance_valid(body):
		return null
	var flourish := new()
	flourish.name = "LevelUpFlourish"
	flourish._spec = spec
	flourish._height = maxf(height, 0.3)
	flourish._radius = maxf(radius, 0.15)
	flourish._colour = Color(str(spec.get("colour", "#ffd77a")))
	flourish._ring_colour = Color(str(spec.get("ring_colour", "#fff2c4")))
	flourish._beam_colour = Color(str(spec.get("beam_colour", "#ffe9a8")))
	flourish._duration = maxf(float(spec.get("duration", 1.5)), 0.1)
	body.add_child(flourish)
	flourish.position = Vector3.ZERO
	return flourish


func finished() -> bool:
	return _finished


func duration() -> float:
	return _duration


func _ready() -> void:
	_build()


func _build() -> void:
	if _mesh != null:
		return
	var reach: float = maxf(_radius * float(_spec.get("ring_radius_scale", 1.6)) * 1.5,
		_height * float(_spec.get("beam_height_scale", 2.4)))
	var bounds := AABB(Vector3(-reach, -0.5, -reach), Vector3(reach * 2.0, reach + 1.0, reach * 2.0))

	_mesh = ImmediateMesh.new()
	_instance = MeshInstance3D.new()
	_instance.mesh = _mesh
	_instance.material_override = _material(bool(_spec.get("no_depth_test", true)))
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_instance.custom_aabb = bounds
	add_child(_instance)

	_solid_mesh = ImmediateMesh.new()
	_solid_instance = MeshInstance3D.new()
	_solid_instance.mesh = _solid_mesh
	_solid_instance.material_override = _material(false)
	_solid_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solid_instance.custom_aabb = bounds
	add_child(_solid_instance)


func _material(no_depth_test: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = no_depth_test
	return material


func _physics_process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if _finished:
		return
	_build()
	_life += delta
	if _life >= _duration:
		_finished = true
		_mesh.clear_surfaces()
		_solid_mesh.clear_surfaces()
		queue_free()
		return
	_redraw()


func _redraw() -> void:
	_mesh.clear_surfaces()
	_solid_mesh.clear_surfaces()
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right: Vector3 = basis.x
	var up: Vector3 = basis.y

	var u: float = clampf(_life / _duration, 0.0, 1.0)
	# Overall envelope: quick in, long settle out.
	var envelope: float = minf(1.0, u * 6.0) * pow(1.0 - u, 0.8)
	var rise: float = _height * float(_spec.get("rise_scale", 1.35))

	# The beam, on the un-depth-tested surface.
	_target = _mesh
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# The column of light: a camera-facing band through the body, opaque at
	# the core and fading to the sides and toward the top.
	var beam_width: float = _radius * float(_spec.get("beam_width_scale", 1.5))
	var beam_height: float = _height * float(_spec.get("beam_height_scale", 2.4))
	var beam_alpha: float = float(_spec.get("beam_alpha", 0.5)) * envelope
	_beam(right, beam_width, beam_height, beam_alpha)

	_mesh.surface_end()

	# Rings and motes, on the depth-tested surface, so their far halves pass
	# behind the creature and the ring reads as a ring around a body.
	_target = _solid_mesh
	_solid_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# The rings: flat, rising from the feet past the crown, each on its own
	# phase so the second follows the first.
	var ring_count: int = maxi(int(_spec.get("ring_count", 2)), 1)
	var ring_radius: float = _radius * float(_spec.get("ring_radius_scale", 1.6))
	var thickness: float = float(_spec.get("ring_thickness", 0.28)) * maxf(_radius, 0.3)
	for k in ring_count:
		var phase: float = float(k) / float(ring_count) * 0.45
		var v: float = clampf((u - phase) / (1.0 - phase), 0.0, 1.0)
		if v <= 0.0 or v >= 1.0:
			continue
		var y: float = rise * (1.0 - pow(1.0 - v, 2.0))
		var r: float = ring_radius * (0.55 + 0.65 * v)
		var alpha: float = sin(v * PI) * 0.95
		_ring(Vector3(0.0, y, 0.0), r, thickness, Color(_ring_colour.r, _ring_colour.g, _ring_colour.b, alpha))

	# The motes: climbing around the body, spawning low and vanishing high.
	var motes: int = maxi(int(_spec.get("mote_count", 14)), 0)
	var mote_size: float = float(_spec.get("mote_size", 0.11)) * maxf(_radius / 0.5, 0.6)
	for i in motes:
		var offset: float = float(i) / float(maxi(motes, 1))
		var t: float = clampf(u * 1.35 - offset * 0.35, 0.0, 1.0)
		if t <= 0.0 or t >= 1.0:
			continue
		var angle: float = TAU * offset + u * 2.4 + float(i * i) * 0.31
		var swell: float = 1.15 - 0.5 * t
		var centre := Vector3(cos(angle) * _radius * swell, rise * (0.05 + t * 1.1), sin(angle) * _radius * swell)
		var alpha: float = sin(t * PI) * 0.95
		var size: float = mote_size * (0.7 + 0.5 * (1.0 - t))
		var dark := _colour.darkened(0.55)
		_disc(centre, right * size * 1.45, up * size * 1.45, Color(dark.r, dark.g, dark.b, alpha * 0.6))
		_disc(centre, right * size, up * size, Color(_colour.r, _colour.g, _colour.b, alpha))

	_solid_mesh.surface_end()


func _beam(right: Vector3, width: float, height: float, alpha: float) -> void:
	if alpha <= 0.001:
		return
	# A column: a solid core band whose alpha holds across its whole width and
	# fades only with height, flanked by two strips that fade to nothing at
	# the sides. (The first version fanned every quad from one opaque point at
	# the feet, which is a faint triangle, not a beam -- round 1 could not see
	# it at all.)
	var core_w: float = width * 0.42
	var colour := Color(_beam_colour.r, _beam_colour.g, _beam_colour.b, alpha)
	var mid := Color(_beam_colour.r, _beam_colour.g, _beam_colour.b, alpha * 0.55)
	var faint := Color(_beam_colour.r, _beam_colour.g, _beam_colour.b, 0.0)
	var steps := 4
	for i in steps:
		var y0: float = height * float(i) / float(steps)
		var y1: float = height * float(i + 1) / float(steps)
		# Bright through the body's own height, fading out above it.
		var a0: float = 1.0 - pow(float(i) / float(steps), 2.0)
		var a1: float = 1.0 - pow(float(i + 1) / float(steps), 2.0)
		var c0 := Color(colour.r, colour.g, colour.b, colour.a * a0)
		var c1 := Color(colour.r, colour.g, colour.b, colour.a * a1)
		var m0 := Color(mid.r, mid.g, mid.b, mid.a * a0)
		var m1 := Color(mid.r, mid.g, mid.b, mid.a * a1)
		var l0 := right * -width + Vector3.UP * y0
		var l1 := right * -width + Vector3.UP * y1
		var cl0 := right * -core_w + Vector3.UP * y0
		var cl1 := right * -core_w + Vector3.UP * y1
		var cr0 := right * core_w + Vector3.UP * y0
		var cr1 := right * core_w + Vector3.UP * y1
		var r0 := right * width + Vector3.UP * y0
		var r1 := right * width + Vector3.UP * y1
		# left strip
		_tri(l0, faint, cl0, m0, cl1, m1)
		_tri(l0, faint, cl1, m1, l1, faint)
		# core
		_tri(cl0, c0, cr0, c0, cr1, c1)
		_tri(cl0, c0, cr1, c1, cl1, c1)
		# right strip
		_tri(cr0, m0, r0, faint, r1, faint)
		_tri(cr0, m0, r1, faint, cr1, m1)


## Writes into whichever surface `_redraw` is currently filling (`_target`).
func _tri(p0: Vector3, c0: Color, p1: Vector3, c1: Color, p2: Vector3, c2: Color) -> void:
	_target.surface_set_color(c0)
	_target.surface_add_vertex(p0)
	_target.surface_set_color(c1)
	_target.surface_add_vertex(p1)
	_target.surface_set_color(c2)
	_target.surface_add_vertex(p2)


## A flat annulus in the XZ plane, opaque at its middle radius and transparent
## at both edges, so it reads as a soft band rather than a hard hoop.
func _ring(centre: Vector3, radius: float, thickness: float, colour: Color) -> void:
	var faint := Color(colour.r, colour.g, colour.b, 0.0)
	var inner: float = maxf(radius - thickness, 0.01)
	var outer: float = radius + thickness
	for i in RING_SEGMENTS:
		var a0: float = TAU * float(i) / float(RING_SEGMENTS)
		var a1: float = TAU * float(i + 1) / float(RING_SEGMENTS)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var i0 := centre + d0 * inner
		var i1 := centre + d1 * inner
		var m0 := centre + d0 * radius
		var m1 := centre + d1 * radius
		var o0 := centre + d0 * outer
		var o1 := centre + d1 * outer
		_tri(i0, faint, m0, colour, m1, colour)
		_tri(i0, faint, m1, colour, i1, faint)
		_tri(m0, colour, o0, faint, o1, faint)
		_tri(m0, colour, o1, faint, m1, colour)


func _disc(centre: Vector3, right: Vector3, up: Vector3, colour: Color) -> void:
	var rim := Color(colour.r, colour.g, colour.b, 0.0)
	for i in MOTE_SEGMENTS:
		var a0: float = TAU * float(i) / float(MOTE_SEGMENTS)
		var a1: float = TAU * float(i + 1) / float(MOTE_SEGMENTS)
		_tri(centre, colour, centre + right * cos(a0) + up * sin(a0), rim, centre + right * cos(a1) + up * sin(a1), rim)
