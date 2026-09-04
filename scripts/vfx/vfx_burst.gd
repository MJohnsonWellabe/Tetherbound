extends Node3D

## W09-VFX (CL-A2). One timed burst of motes and streaks thrown out from a
## point: the hit spark, the KO puff and the catch-success sparkle are all
## this node with a different `spec` from data/config/vfx.json.
##
## Built the way every effect in a Tetherbound fight is already built, for the
## reasons their own headers paid for (impact_flash.gd, telegraph_glow.gd,
## alpha_aura.gd, move_projectile.gd):
##
##   * Camera-facing ImmediateMesh geometry, NOT GPUParticles3D/CPUParticles3D.
##     The survey renders under software OpenGL, where particle behaviour is
##     not something to rely on -- and a burst that only appears on the
##     developer's machine cannot be judged, so under docs/AGENT_WORKFLOW.md
##     it cannot ship. The "particles" here are a fixed array of positions
##     computed from the burst's age; there is no allocation in the loop.
##   * MIX blend, vertex-coloured, unshaded: additive renders at a fraction of
##     its strength on the Compatibility renderer that ships.
##   * Advanced on the PHYSICS clock so "five ticks after the hit" is the same
##     picture in every capture, and so the tree pause `_capture_*` tools use
##     for their shutter freezes it exactly where it is. `advance()` is public
##     so a headless fixture with no running clock can drive the whole life of
##     the node by hand (tests/test_combat_vfx.gd).
##   * Deterministic from the particle index and `seed`, so two runs of the
##     same fight draw the same spray.
##   * The AABB is stated up front: an ImmediateMesh has no bounds until it
##     first draws and can be culled before it says how big it is.

const MOTE_SEGMENTS := 10

var _spec: Dictionary = {}
var _colour: Color = Color("#ffd27a")
var _core_colour: Color = Color("#fff6df")
var _scale: float = 1.0
var _alpha: float = 1.0
var _seed: int = 0
var _life: float = 0.0
var _duration: float = 0.5
var _count: int = 12
var _finished: bool = false

## Per particle: [direction (Vector3), speed (float), size (float), streak (bool)].
var _particles: Array = []

var _mesh: ImmediateMesh = null
var _instance: MeshInstance3D = null


## Spawn one under `host` at world position `at`. `spec` is one of vfx.json's
## burst blocks; `colour` the tint this burst carries (the move's element for a
## hit); `scale` a size multiplier already folded from damage and body size by
## combat_vfx.gd. Returns the node so a caller (or a capture tool) can find it.
static func spawn(host: Node, at: Vector3, spec: Dictionary, colour: Color, scale: float, seed: int = 0) -> Node3D:
	var burst := new()
	burst._spec = spec
	burst._colour = colour
	burst._core_colour = Color(str(spec.get("core_colour", "#fff6df")))
	burst._scale = maxf(scale, 0.05)
	burst._alpha = clampf(float(spec.get("alpha", 1.0)), 0.0, 1.0)
	burst._seed = seed
	burst._duration = maxf(float(spec.get("duration", 0.5)), 0.05)
	burst._count = maxi(int(spec.get("count", 12)), 1)
	burst._init_particles()
	if host != null:
		host.add_child(burst)
	# A detached fixture (the unit runner never enters a tree) has no global
	# transform chain to place against; a local position under a host at the
	# origin means the same thing there.
	if burst.is_inside_tree():
		burst.global_position = at
	else:
		burst.position = at
	return burst


func burst_scale() -> float:
	return _scale


func colour() -> Color:
	return _colour


func finished() -> bool:
	return _finished


func duration() -> float:
	return _duration


func _ready() -> void:
	_build()


func _build() -> void:
	if _mesh != null:
		return
	_mesh = ImmediateMesh.new()
	_instance = MeshInstance3D.new()
	_instance.mesh = _mesh
	_instance.material_override = _material()
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var reach: float = _reach()
	_instance.custom_aabb = AABB(Vector3.ONE * -reach, Vector3.ONE * reach * 2.0)
	add_child(_instance)


## How far the fastest particle can get in the burst's life, plus its size:
## the bound stated to the renderer before the first draw.
func _reach() -> float:
	var speed: float = float(_spec.get("speed", 4.0)) * (1.0 + float(_spec.get("speed_variance", 0.4)))
	var gravity: float = absf(float(_spec.get("gravity", 0.0)))
	var travel: float = speed * _duration + 0.5 * gravity * _duration * _duration
	return (travel + float(_spec.get("size", 0.2)) * 3.0 + float(_spec.get("core_size", 0.3))) * _scale + 0.5


func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	material.vertex_color_use_as_albedo = true
	# Same call impact_flash.gd made and documented: this burst originates at
	# a creature's collision centre, inside a model that is often larger than
	# its collider, so a depth-tested spray can be swallowed by the very body
	# it is a reaction to. TUNABLE per spec.
	material.no_depth_test = bool(_spec.get("no_depth_test", true))
	return material


## A small deterministic hash in [0, 1) from the particle index and a salt --
## no RandomNumberGenerator, so the same seed draws the same spray every run.
func _rand(index: int, salt: int) -> float:
	var h: int = (index * 73856093) ^ (salt * 19349663) ^ (_seed * 83492791) ^ 0x5bd1e995
	h = h ^ (h >> 13)
	h = (h * 1274126177) & 0x7fffffff
	h = h ^ (h >> 16)
	return float(h & 0xffffff) / float(0x1000000)


func _init_particles() -> void:
	_particles.clear()
	var speed: float = float(_spec.get("speed", 4.0))
	var speed_variance: float = float(_spec.get("speed_variance", 0.4))
	var size: float = float(_spec.get("size", 0.2))
	var size_variance: float = float(_spec.get("size_variance", 0.4))
	var streak_fraction: float = clampf(float(_spec.get("streak_fraction", 0.0)), 0.0, 1.0)
	var spread: float = deg_to_rad(clampf(float(_spec.get("spread_degrees", 360.0)), 5.0, 360.0))
	var up_bias: float = float(_spec.get("up_bias", 0.25))
	for i in _count:
		# Fibonacci sphere with a per-index jitter: evenly spread, never a
		# visible lattice, and stable from run to run.
		var y: float = 1.0 - 2.0 * (float(i) + 0.5) / float(_count)
		var radius: float = sqrt(maxf(0.0, 1.0 - y * y))
		var phi: float = float(i) * 2.399963 + _rand(i, 1) * 0.9
		var direction := Vector3(cos(phi) * radius, y, sin(phi) * radius)
		# Narrow the cone toward straight up when the spec asks for less than a
		# full sphere; at 360 this is the identity.
		if spread < TAU - 0.001:
			var t: float = spread / TAU
			direction = Vector3(direction.x * t, direction.y, direction.z * t).normalized()
		direction.y += up_bias
		direction = direction.normalized()
		var this_speed: float = speed * (1.0 + (_rand(i, 2) * 2.0 - 1.0) * speed_variance)
		var this_size: float = size * (1.0 + (_rand(i, 3) * 2.0 - 1.0) * size_variance)
		var streak: bool = _rand(i, 4) < streak_fraction
		_particles.append([direction, this_speed, maxf(this_size, 0.01), streak])


func _physics_process(delta: float) -> void:
	advance(delta)


## The whole life of the node, one step at a time. Public so a fixture with no
## clock can walk it; `_physics_process` is just this on the physics tick.
func advance(delta: float) -> void:
	if _finished:
		return
	_build()
	_life += delta
	if _life >= _duration:
		_finished = true
		_mesh.clear_surfaces()
		queue_free()
		return
	_redraw()


func _redraw() -> void:
	_mesh.clear_surfaces()
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right: Vector3 = basis.x
	var up: Vector3 = basis.y
	var forward: Vector3 = -basis.z

	var u: float = clampf(_life / _duration, 0.0, 1.0)
	# Fast out, then slowing: distance follows an eased curve rather than a
	# constant speed, which is what a thrown spark does once drag has it.
	var eased: float = 1.0 - pow(1.0 - u, 2.2)
	var fade: float = pow(1.0 - u, 1.3) * _alpha
	var gravity: float = float(_spec.get("gravity", 0.0))
	var grow: float = float(_spec.get("grow", 0.0))
	var streak_length: float = float(_spec.get("streak_length", 2.5))
	var drop: float = 0.5 * gravity * _life * _life

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# The core: a bright flash at the point of contact that is gone quickly.
	var core_duration: float = maxf(float(_spec.get("core_duration", 0.18)), 0.01)
	if _life < core_duration:
		var core_u: float = _life / core_duration
		var core_size: float = float(_spec.get("core_size", 0.3)) * _scale * (1.0 + 0.6 * core_u)
		var core_alpha: float = (1.0 - core_u) * _alpha
		_disc(Vector3.ZERO, right * core_size, up * core_size,
			Color(_core_colour.r, _core_colour.g, _core_colour.b, core_alpha))

	for i in _particles.size():
		var particle: Array = _particles[i]
		var direction: Vector3 = particle[0]
		var speed: float = particle[1]
		var size: float = particle[2] * _scale * (1.0 + grow * u)
		var streak: bool = particle[3]
		var position: Vector3 = direction * speed * _scale * eased * _duration
		position.y -= drop
		# Later-index particles fade a touch earlier, so the spray thins
		# rather than vanishing all at once.
		var alpha: float = fade * (0.7 + 0.3 * _rand(i, 5))
		var colour := Color(_colour.r, _colour.g, _colour.b, alpha)
		if streak:
			var velocity: Vector3 = direction * speed * _scale * (1.0 - u)
			velocity.y -= gravity * _life
			var tail_dir: Vector3 = velocity.normalized() if velocity.length() > 0.001 else direction
			var tail: Vector3 = position - tail_dir * size * streak_length
			_streak(position, tail, size * 0.45, forward, colour)
		else:
			_disc(position, right * size, up * size, colour)
	_mesh.surface_end()


## A soft mote: an opaque centre fanned out to a fully transparent rim, the
## shape alpha_aura.gd settled on after flat quads came back as hard-edged
## squares beside the creature.
func _disc(centre: Vector3, right: Vector3, up: Vector3, colour: Color) -> void:
	var rim := Color(colour.r, colour.g, colour.b, 0.0)
	for i in MOTE_SEGMENTS:
		var a0: float = TAU * float(i) / float(MOTE_SEGMENTS)
		var a1: float = TAU * float(i + 1) / float(MOTE_SEGMENTS)
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(centre)
		_mesh.surface_set_color(rim)
		_mesh.surface_add_vertex(centre + right * cos(a0) + up * sin(a0))
		_mesh.surface_set_color(rim)
		_mesh.surface_add_vertex(centre + right * cos(a1) + up * sin(a1))


## A camera-facing streak from `head` to `tail`: bright at the head, transparent
## at the tail, so it reads as motion rather than as a line.
func _streak(head: Vector3, tail: Vector3, width: float, forward: Vector3, colour: Color) -> void:
	var along: Vector3 = tail - head
	if along.length() < 0.0001:
		return
	var side: Vector3 = along.cross(forward)
	if side.length() < 0.0001:
		side = along.cross(Vector3.UP)
	side = side.normalized() * width
	var faint := Color(colour.r, colour.g, colour.b, 0.0)
	var a := head + side
	var b := head - side
	var c := tail - side
	var d := tail + side
	_mesh.surface_set_color(colour)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(colour)
	_mesh.surface_add_vertex(b)
	_mesh.surface_set_color(faint)
	_mesh.surface_add_vertex(c)
	_mesh.surface_set_color(colour)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(faint)
	_mesh.surface_add_vertex(c)
	_mesh.surface_set_color(faint)
	_mesh.surface_add_vertex(d)
