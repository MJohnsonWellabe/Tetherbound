extends "res://scripts/vfx/move_effect.gd"

## Kit move effects (F25#0, shipping OFF). Every archetype is drawn from one
## shared toolkit: soft particle trails, a contact starburst, solid debris, dust
## puffs and a surface-stop helper. The inherited lifecycle keeps the host
## clock, budget lease, arrival signals, cancellation and audio unchanged;
## nothing here reads or writes damage, HP, collision or durable state.
const PARTICLES := preload("res://scripts/vfx/kit_particles.gd")
const GLOW_SHADER := preload("res://assets/vfx/shaders/kit_glow.gdshader")
const PUFF_SHADER := preload("res://assets/vfx/shaders/kit_puff.gdshader")
const STREAK_SHADER := preload("res://assets/vfx/shaders/kit_streak.gdshader")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const ROCK_TEXTURE := preload("res://assets/environment/terrain/Rock030_Color.jpg")

## Whole kit config (data/config/kit_move_effects.json), set by the library.
var tuning: Dictionary = {}
var _kit: Dictionary = {}
var _family := ""
var _trail_pool: Node
var _flash_pool: Node
var _spark_pool: Node
var _dust_pool: Node
var _pools: Array[Node] = []
var _surface := Vector3.ZERO
var _direction := Vector3.FORWARD
var _radius := 0.3
var _emit_carry: Dictionary = {}
var _impact_carry := 0.0
var _last_step := 0.0
var _contact_time := -1.0
var _spikes: Array[MeshInstance3D] = []
var _spike_heights: Array[float] = []
var _bolt: Node
var _bolt_points: Array[Vector3] = []
var _bolt_reseed := 0.0
var _source_pivot: WeakRef = null
var _source_box := AABB()
var _ground_source := Vector3.ZERO
var _ground_target := Vector3.ZERO
var _sky_point := Vector3.ZERO

func bind_source(source: Node3D) -> bool:
	if source == null or not source.has_method("model_pivot"): return false
	var pivot := source.call("model_pivot") as Node3D
	if pivot == null: return false
	var box := RENDER_BOUNDS.measure(pivot)
	if not box.size.is_finite() or box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0: return false
	_source_pivot = weakref(pivot)
	_source_box = box
	return true

func _ready() -> void:
	add_to_group("move_effect_presentation")
	top_level = true
	global_transform = Transform3D.IDENTITY
	_kit = (tuning.get("profiles", {}) as Dictionary).get(str(_row.archetype), {})
	_family = str(_kit.get("family", "projectile"))
	var budget: Dictionary = _kit.get("budget", _row.get("budget", {}))
	var limit := int(_config.get("ordinary_particle_limit", 48))
	var impact := mini(int(budget.get("impact", 24)), limit)
	var trail := mini(int(budget.get("trail", 18)), maxi(0, limit - impact))
	_lease = BUDGET.reserve(encounter_id(), impact, trail, int(_config.get("encounter_particle_cap", 384)))
	var allocation := BUDGET.allocation(_lease)
	_ground_source = _context.get("source_ground", Vector3(_from.x, _from.y - 1.0, _from.z))
	_ground_target = _context.get("target_ground", Vector3(_to.x, _to.y - 1.0, _to.z))
	_direction = (_to - _from).normalized() if not _from.is_equal_approx(_to) else Vector3.FORWARD
	_radius = clampf(float(_params.size), float(_kit.get("min_radius_m", 0.18)), float(_kit.get("max_radius_m", 2.0))) * float(_kit.get("body_scale", 1.0))
	_surface = surface_point(_from, _to, _target_box(), 0.0)
	_build_pools(int(allocation.get("impact", 0)), int(allocation.get("trail", 0)))
	_build_bodies()
	_sky_point = Vector3(_surface.x, _target_top() + float(_kit.get("sky_height_m", 5.0)), _surface.z)
	_launch_flash()
	_update_bodies(0.0)
	_play_launch()
	if _travel <= 0.0:
		_update_bodies(1.0)
		call_deferred("_finish_presentation")
	elif _context.has("travel_seconds"):
		_presentation_clock = get_tree().create_timer(_travel, false)
		_presentation_clock.timeout.connect(_finish_presentation, CONNECT_ONE_SHOT)

# --- Toolkit -----------------------------------------------------------------

## Surface-stop helper: where the from→to segment enters the target's visual
## bounds grown by `radius` (a body of that radius stops touching the skin).
static func surface_point(from: Vector3, to: Vector3, box: AABB, radius: float) -> Vector3:
	var direction := (to - from).normalized()
	if box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0:
		return to - direction * radius
	var grown := box.grow(radius)
	if grown.has_point(from): return from
	var entry: Variant = grown.intersects_segment(from, to)
	if entry is Vector3: return entry
	# Aimed above/below the box: stop at the closest approach instead.
	return to - direction * (radius + box.size.length() * 0.25)

func _target_box() -> AABB:
	var bounds: Variant = _context.get("target_visual_bounds", {})
	if bounds is Dictionary and (bounds as Dictionary).get("position") is Vector3 and (bounds as Dictionary).get("size") is Vector3:
		var box := AABB(bounds.position, bounds.size)
		if box.position.is_finite() and box.size.is_finite() and box.size.x > 0.0 and box.size.y > 0.0 and box.size.z > 0.0:
			return box
	return AABB()

func _target_top() -> float:
	var box := _target_box()
	return box.end.y if box.size.y > 0.0 else _to.y + 0.6

func _source_volume() -> AABB:
	if _source_pivot != null:
		var pivot := _source_pivot.get_ref() as Node3D
		if pivot != null and pivot.is_inside_tree(): return pivot.global_transform * _source_box
	return AABB(_from - Vector3(0.6, 0.9, 0.6), Vector3(1.2, 1.2, 1.2))

static func _hex(value: Variant, fallback: Color) -> Color:
	return Color(str(value)) if value != null and str(value) != "" else fallback

func _glow_material(colour: Color = Color.WHITE, opacity: float = 1.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GLOW_SHADER
	material.set_shader_parameter("opacity", opacity * _peer_opacity)
	material.set_shader_parameter("tint_mul", colour)
	return material

func _puff_material(opacity: float = 1.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = PUFF_SHADER
	material.set_shader_parameter("opacity", opacity * _peer_opacity)
	return material

func _streak_material(taper: float = 1.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = STREAK_SHADER
	material.set_shader_parameter("opacity", _peer_opacity)
	material.set_shader_parameter("taper", taper)
	return material

func _rock_material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = ROCK_TEXTURE
	material.albedo_color = tint
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.9
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Faceted chunks self-shadow into black under the Meadows sun; a faint
	# emission of their own tint keeps the rock legible in shade.
	material.disable_receive_shadows = true
	material.emission_enabled = true
	material.emission = tint.darkened(0.6)
	material.emission_energy_multiplier = 0.15
	return material

func _solid_material(kind: String, tint: Color) -> Material:
	match kind:
		"rock": return _rock_material(tint)
		"ice":
			var ice := StandardMaterial3D.new()
			ice.albedo_color = tint
			ice.vertex_color_use_as_albedo = true
			ice.metallic = 0.2
			ice.roughness = 0.12
			ice.emission_enabled = true
			ice.emission = tint.lerp(Color.WHITE, 0.3)
			ice.emission_energy_multiplier = 0.55
			ice.rim_enabled = true
			ice.rim = 0.8
			ice.cull_mode = BaseMaterial3D.CULL_DISABLED
			ice.disable_receive_shadows = true
			return ice
		_:
			var chip := StandardMaterial3D.new()
			chip.albedo_color = tint
			chip.vertex_color_use_as_albedo = true
			chip.roughness = 0.5
			chip.emission_enabled = kind in ["ember", "crystal", "spark"]
			chip.emission = tint
			chip.emission_energy_multiplier = 1.4 if kind == "ember" else 0.8
			chip.cull_mode = BaseMaterial3D.CULL_DISABLED
			chip.disable_receive_shadows = true
			return chip

## Faceted chunk of unit diameter: jittered octahedron (rock/crystal/ember),
## a long bipyramid (ice/shard) or a flat leaf/petal.
static func chunk_mesh(kind: String, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var tips: Array[Vector3] = []
	var ring: Array[Vector3] = []
	var sides := 5 if kind in ["rock", "ember"] else 4
	var length := 0.5
	var girth := 0.42
	if kind in ["ice", "shard", "crystal"]:
		length = 0.5
		girth = 0.2
	if kind == "leaf":
		length = 0.5
		girth = 0.3
	for s in sides:
		var a := TAU * float(s) / float(sides) + rng.randf_range(-0.25, 0.25)
		var r := girth * rng.randf_range(0.75, 1.0)
		ring.append(Vector3(cos(a) * r, rng.randf_range(-0.08, 0.08), sin(a) * r * (0.25 if kind == "leaf" else 1.0)))
	tips.append(Vector3(rng.randf_range(-0.06, 0.06), length * rng.randf_range(0.8, 1.0), 0))
	tips.append(Vector3(rng.randf_range(-0.06, 0.06), -length * rng.randf_range(0.55, 0.9), 0))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in sides:
		var a := ring[s]
		var b := ring[(s + 1) % sides]
		_tri(tool, tips[0], b, a)
		_tri(tool, tips[1], a, b)
	return tool.commit()

static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, centre: Vector3 = Vector3.ZERO) -> void:
	# Flat facet with an explicit outward normal (away from the chunk's axis).
	var normal := (b - a).cross(c - a).normalized()
	var out := (a + b + c) / 3.0 - centre
	out.y *= 0.3
	if normal.dot(out) < 0.0:
		normal = -normal
		var swap := b
		b = c
		c = swap
	for v: Vector3 in [a, b, c]:
		tool.set_color(Color.WHITE)
		tool.set_normal(normal)
		tool.add_vertex(v)

## Tall jagged rock spike, base at y=0, height 1, unit base diameter.
static func spike_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var sides := 6
	var levels := [0.0, 0.35, 0.7]
	var rings: Array = []
	for l in levels.size():
		var ring: Array[Vector3] = []
		var shrink := 1.0 - float(levels[l]) * 0.85
		var lean := Vector3(rng.randf_range(-0.06, 0.06), 0, rng.randf_range(-0.06, 0.06)) * float(l)
		for s in sides:
			var a := TAU * float(s) / float(sides) + rng.randf_range(-0.2, 0.2)
			var r := 0.5 * shrink * rng.randf_range(0.78, 1.05)
			ring.append(Vector3(cos(a) * r, float(levels[l]), sin(a) * r) + lean)
		rings.append(ring)
	var tip := Vector3(rng.randf_range(-0.08, 0.08), 1.0, rng.randf_range(-0.08, 0.08))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in rings.size() - 1:
		var lower: Array[Vector3] = rings[l]
		var upper: Array[Vector3] = rings[l + 1]
		for s in sides:
			var n := (s + 1) % sides
			var axis := Vector3(0, (float(levels[l]) + float(levels[l + 1])) * 0.5, 0)
			_tri(tool, lower[s], upper[s], upper[n], axis)
			_tri(tool, lower[s], upper[n], lower[n], axis)
	var top: Array[Vector3] = rings[rings.size() - 1]
	for s in sides: _tri(tool, top[s], tip, top[(s + 1) % sides], Vector3(0, 0.6, 0))
	return tool.commit()

func _quad() -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	return quad

func _pool(capacity: int, mesh: Mesh, material: Material, mode: int, grounded: bool = false) -> Node:
	var pool := PARTICLES.new()
	pool.setup(capacity, mesh, material, mode, _ground_target + Vector3.UP * 0.05)
	if grounded: pool.ground_y = _ground_target.y
	add_child(pool)
	_pools.append(pool)
	return pool

func _build_pools(impact: int, trail: int) -> void:
	var impact_cfg: Dictionary = _kit.get("impact", {})
	var trail_cfg: Dictionary = _kit.get("trail", {})
	var trail_kind := str(trail_cfg.get("kind", "glow"))
	if _family == "bolt":
		# Bolt segments draw from this effect's own trail lease.
		var bolt_cap := mini(16, trail)
		trail -= bolt_cap
		_bolt = _pool(bolt_cap, _quad(), _streak_material(0.0), PARTICLES.Mode.STREAK)
	if _family == "slash":
		# Claw rakes draw from this effect's own trail lease.
		var claw_cap := mini(12, trail)
		trail -= claw_cap
		_bolt = _pool(claw_cap, _quad(), _streak_material(0.0), PARTICLES.Mode.STREAK)
	if trail > 0:
		_trail_pool = _pool(trail, _quad(), _puff_material() if trail_kind == "puff" else _glow_material(), PARTICLES.Mode.BILLBOARD)
	# Impact slots: flash cores, starburst sparks, solid debris, dust puffs.
	var flashes := mini(4, impact)
	var sparks := mini(int(impact_cfg.get("sparks", 8)), maxi(0, impact - flashes))
	var debris := mini(int((impact_cfg.get("debris", {}) as Dictionary).get("count", 6)), maxi(0, impact - flashes - sparks))
	var dust := maxi(0, impact - flashes - sparks - debris)
	_flash_pool = _pool(flashes, _quad(), _glow_material(), PARTICLES.Mode.BILLBOARD)
	_spark_pool = _pool(sparks, _quad(), _streak_material(), PARTICLES.Mode.STREAK)
	var debris_cfg: Dictionary = impact_cfg.get("debris", {})
	var debris_kind := str(debris_cfg.get("kind", "rock"))
	# The debris pool is the inherited `_motes`: ground-settling assertions
	# inspect exactly these instances against the frozen ground height.
	_motes = _pool(debris, chunk_mesh(debris_kind, int(_context.get("seed", 0)) + 7),
		_solid_material(debris_kind, _hex(debris_cfg.get("colour"), _colour)), PARTICLES.Mode.SOLID, true) as MultiMeshInstance3D
	_dust_pool = _pool(dust, _quad(), _puff_material(), PARTICLES.Mode.BILLBOARD, true)

func _launch_flash() -> void:
	var cfg: Dictionary = _kit.get("launch", {})
	var at := _source_volume().get_center() if _family == "self" else _from
	var colour := _hex(cfg.get("colour"), _colour.lerp(Color.WHITE, 0.4))
	_flash_pool.call("emit", at, Vector3.ZERO, {"life": 0.22, "size0": float(cfg.get("size", 0.7)), "size1": float(cfg.get("size", 0.7)) * 1.6, "colour": colour, "fade_in": 0.01})
	for i in mini(4, int(_spark_pool.call("capacity"))) if _family != "self" else 0:
		_spark_pool.call("emit", at, (_direction + _jitter(0.5)).normalized() * 4.0,
			{"life": 0.18, "size0": 0.05, "size1": 0.02, "colour": colour, "drag": 4.0, "stretch": 0.06, "fade_in": 0.0})
	if _family in ["ground", "ground_body"] and _dust_pool != null:
		for i in mini(3, int(_dust_pool.call("capacity"))):
			_dust_pool.call("emit", _ground_source + _jitter(0.3) * Vector3(1, 0, 1), Vector3.UP * 0.8 + _jitter(0.5), _dust_opts(0.7))

# --- Bodies --------------------------------------------------------------------

func _build_bodies() -> void:
	var body_cfg: Dictionary = _kit.get("body", {})
	var kind := str(body_cfg.get("kind", "none"))
	if kind in ["none", "mote_crescent", "funnel", "wave_wall"]: return
	var count := int(_params.count) if _family == "projectile" else 1
	for i in count:
		var body := MeshInstance3D.new()
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var colour := _hex(body_cfg.get("colour"), _colour)
		match kind:
			"rock":
				body.mesh = chunk_mesh("rock", int(_context.get("seed", 0)) + i)
				body.material_override = _rock_material(colour)
				body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				body.set_meta("diameter", 2.0)
			"ice":
				body.mesh = chunk_mesh("ice", int(_context.get("seed", 0)) + i)
				body.material_override = _solid_material("ice", colour)
				body.set_meta("diameter", 2.6)
			"orb", "fire_core":
				var sphere := SphereMesh.new()
				sphere.radius = 0.5
				sphere.height = 1.0
				sphere.radial_segments = 24
				sphere.rings = 12
				body.mesh = sphere
				var material := StandardMaterial3D.new()
				material.albedo_color = colour
				material.emission_enabled = true
				material.emission = _hex(body_cfg.get("emission"), colour)
				material.emission_energy_multiplier = float(body_cfg.get("emission_energy", 1.2))
				material.rim_enabled = true
				material.rim = 1.0
				material.rim_tint = 0.2
				material.roughness = 0.35
				if body_cfg.has("marble"):
					var noise := NoiseTexture2D.new()
					noise.seamless = true
					noise.noise = FastNoiseLite.new()
					noise.noise.frequency = 0.02
					noise.noise.fractal_octaves = 4
					var ramp := Gradient.new()
					ramp.set_color(0, colour.darkened(0.45))
					ramp.set_color(1, colour.lightened(0.45))
					noise.color_ramp = ramp
					material.albedo_texture = noise
					material.emission_texture = noise
					material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
					material.albedo_color = Color.WHITE
				if kind == "fire_core":
					material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				body.material_override = material
				body.set_meta("diameter", 2.0)
			"bubble":
				var bubble := SphereMesh.new()
				bubble.radius = 0.5
				bubble.height = 1.0
				body.mesh = bubble
				body.material_override = GEOMETRY.authored_material("bubble", _row.body, colour)
				body.set_meta("diameter", 2.0)
			"crescent", "wave", "vortex":
				var shape := {"crescent": "crescent", "wave": "rolling_wave", "vortex": "vortex"}[kind] as String
				body.mesh = GEOMETRY.shape(shape, 1.0, _row.body)
				var surface := {"crescent": "wind_surface", "wave": "water_stream", "vortex": "wind_surface"}[kind] as String
				body.material_override = GEOMETRY.authored_material(surface, _row.body, colour)
				body.set_meta("diameter", 1.0)
		# Soft additive halo around glowing bodies (no outline, no card edge).
		if body_cfg.has("halo"):
			var halo := MeshInstance3D.new()
			halo.mesh = _quad()
			halo.material_override = _glow_material(_hex(body_cfg.halo, colour), float(body_cfg.get("halo_opacity", 0.8)))
			halo.scale = Vector3.ONE * float(body_cfg.get("halo_scale", 2.6))
			halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			body.add_child(halo)
		add_child(body)
		body.top_level = true
		_bodies.append(body)

func _body_end(index: int) -> Vector3:
	return surface_point(_from, _to, _target_box(), _radius * (1.15 if index >= 0 else 1.0))

func _path(t: float, index: int) -> Vector3:
	var end := _body_end(index)
	var side := _direction.cross(Vector3.UP).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	var count := maxi(1, _bodies.size())
	var lane := float(index) - float(count - 1) * 0.5
	var fan := sin(t * PI)
	var spread := float(_kit.get("volley_spread_m", 0.45))
	var point := _from.lerp(end, t) + side * lane * spread * fan + Vector3.UP * (float(_kit.get("arc_m", 0.35)) * fan + absf(lane) * 0.12 * fan * float(index % 2 * 2 - 1))
	if _family == "ground_body":
		point.y = lerpf(_ground_source.y, _ground_target.y, t) + _radius * 0.55
		point.y = lerpf(_from.y, point.y, smoothstep(0.0, 0.2, t))
	return point

func _update_bodies(t: float) -> void:
	var grow := lerpf(float(_kit.get("launch_scale", 0.45)), 1.0, smoothstep(0.0, 0.18, t))
	for i in _bodies.size():
		var body := _bodies[i]
		var stagger := clampf(t * (1.0 + 0.08 * float(i)) - 0.08 * float(i), 0.0, 1.0)
		body.global_position = _path(stagger, i)
		var diameter := float(body.get_meta("diameter", 2.0))
		body.scale = Vector3.ONE * _radius * diameter * grow * float((_kit.get("body", {}) as Dictionary).get("core_scale", 1.0))
		var face := _direction
		match str((_kit.get("body", {}) as Dictionary).get("kind", "")):
			"ice":
				# Long axis (mesh Y) along the flight direction.
				body.global_basis = Basis(Quaternion(Vector3.UP, face)) * Basis.from_scale(body.scale)
			"rock":
				body.rotation = Vector3(t * 9.0 + i, t * 6.0, t * 4.0 + i * 0.7)
			"crescent", "wave", "vortex":
				var flat := Vector3(face.x, 0, face.z).normalized() if Vector3(face.x, 0, face.z).length() > 0.01 else Vector3.FORWARD
				var spin := Basis(Vector3.UP, _elapsed * 14.0) if str(_kit.body.kind) == "vortex" else Basis.IDENTITY
				body.global_basis = Basis.looking_at(flat, Vector3.UP) * spin * Basis.from_scale(body.scale)
		body.visible = not _arrived

# --- Per-frame -------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _arrived and _presentation_clock != null:
		_elapsed = maxf(0.0, _travel - _presentation_clock.time_left)
	else:
		_elapsed += delta
	var step := clampf(_elapsed - _last_step, 0.0, 0.1)
	_last_step = _elapsed
	var t := clampf(_elapsed / maxf(_travel, 0.00001), 0.0, 1.0)
	if not _arrived:
		_update_bodies(t)
		_travel_frame(t, step)
		if _presentation_clock == null and _elapsed >= _travel: _finish_presentation()
	else:
		_after_frame(_elapsed - _travel, step)
	for pool: Node in _pools: pool.call("step", step)
	_update_spikes()
	var linger := float(_kit.get("linger_s", 1.0))
	if _arrived and _elapsed - _travel >= linger:
		var alive := 0
		for pool: Node in _pools:
			if pool != _bolt: alive += int(pool.call("alive"))
		if alive == 0 or _elapsed - _travel >= linger:
			_retire_contact_drawing()
			queue_free()

func _rate_emit(rate: float, step: float, key: String = "main") -> int:
	var carry := float(_emit_carry.get(key, 0.0)) + rate * step
	var n := int(carry)
	_emit_carry[key] = carry - float(n)
	return n

func _trail_opts(scale: float) -> Dictionary:
	var cfg: Dictionary = _kit.get("trail", {})
	var gain := float(tuning.get("trail_scale", 1.8))
	return {"life": float(cfg.get("life", 0.28)), "size0": _radius * float(cfg.get("size", 1.6)) * scale * gain,
		"size1": _radius * float(cfg.get("end_size", 0.5)) * scale * gain,
		"colour": _hex(cfg.get("colour"), _colour), "gravity": float(cfg.get("gravity", 0.0)),
		"drag": 2.0, "fade_in": 0.02}

func _jitter(amount: float) -> Vector3:
	return Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * amount

func _travel_frame(t: float, step: float) -> void:
	var cfg: Dictionary = _kit.get("trail", {})
	var rate := float(cfg.get("rate", 60.0))
	match _family:
		"projectile", "ground_body":
			var n := _rate_emit(rate * maxi(1, _bodies.size()), step)
			for k in n:
				if _bodies.is_empty() or _trail_pool == null: break
				var body := _bodies[_rng.randi() % _bodies.size()]
				var opts := _trail_opts(1.0)
				var envelope := float(cfg.get("envelope", 0.0))
				var behind := 0.0 if envelope > 0.0 else 0.4
				_trail_pool.call("emit", body.global_position - _direction * _radius * behind + _jitter(_radius * maxf(0.25, envelope)),
					-_direction * float(cfg.get("speed", 0.6)) + _jitter(0.35) + Vector3.UP * float(cfg.get("rise", 0.0)), opts)
			_particle_body(t, step)
			if _family == "ground_body" and _dust_pool != null:
				for k in _rate_emit(18.0, step, "dust"):
					var at := _ground_source.lerp(_ground_target, t)
					_dust_pool.call("emit", at + _jitter(0.2) * Vector3(1, 0, 1), Vector3.UP * 0.6 + _jitter(0.4), _dust_opts(0.6))
		"stream":
			# Mouth-to-surface flow: the stream front reaches the surface at contact.
			var distance := _from.distance_to(_surface)
			var speed := distance / maxf(_travel * 0.75, 0.05)
			for k in _rate_emit(rate, step):
				if _trail_pool == null: break
				var spread := float(_kit.get("cone_spread", 0.18))
				var dir := (_direction + _jitter(spread)).normalized()
				var opts := _trail_opts(1.0)
				opts.life = distance / speed * _rng.randf_range(0.9, 1.0)
				opts.size0 = _radius * float(cfg.get("size", 0.6)) * float(tuning.get("trail_scale", 1.8))
				opts.size1 = _radius * float(cfg.get("end_size", 2.4)) * float(tuning.get("trail_scale", 1.8))
				opts.drag = 0.0
				_trail_pool.call("emit", _from + _jitter(0.05), dir * speed, opts)
		"radial":
			if t < 0.92:
				var distance := _from.distance_to(_surface)
				for k in _rate_emit(rate, step):
					if _trail_pool == null: break
					var dir := (_direction + _jitter(float(_kit.get("cone_spread", 0.5)))).normalized()
					var opts := _trail_opts(1.0)
					opts.life = _travel * _rng.randf_range(0.6, 1.0)
					opts.drag = 0.0
					# Each ember flies mouth to surface in a fixed fraction of the travel.
					var flight := maxf(_travel * 0.45, 0.05)
					opts.life = flight
					_trail_pool.call("emit", _from, dir * distance / flight * _rng.randf_range(0.9, 1.0), opts)
		"ground":
			# A travelling eruption: rock chips and dust kicked up along the ground.
			var at := _ground_source.lerp(_ground_target.lerp(_surface_ground(), 0.5), t)
			for k in _rate_emit(rate, step):
				if _trail_pool == null: break
				var opts := _dust_opts(_rng.randf_range(0.5, 1.3))
				_trail_pool.call("emit", at - _direction * _rng.randf_range(0.0, 0.6) + _jitter(0.35) * Vector3(1, 0, 1) + Vector3.UP * 0.1, Vector3.UP * _rng.randf_range(0.8, 2.0) + _jitter(0.6), opts)
			if _motes != null:
				for k in _rate_emit(14.0, step, "chips"):
					_motes.call("emit", at + Vector3.UP * 0.15 + _jitter(0.2) * Vector3(1, 0, 1),
						Vector3.UP * _rng.randf_range(2.0, 3.2) + _jitter(0.8), _debris_opts(0.6))
		"bolt":
			if str(_kit.get("bolt", "chain")) == "sky":
				# A charge mote climbs from the caster and gathers over the target.
				var head := _from.lerp(_sky_point, t)
				head.y += sin(t * PI) * 1.0
				for k in _rate_emit(rate, step):
					if _trail_pool == null: break
					_trail_pool.call("emit", head + _jitter(0.12), _jitter(0.3), _trail_opts(1.0))
				if t > 0.55 and _trail_pool != null:
					for k in _rate_emit(rate * 0.5, step, "cloud"):
						var cloud := _sky_point + Vector3(_rng.randf_range(-1.2, 1.2), _rng.randf_range(-0.2, 0.3), _rng.randf_range(-1.2, 1.2))
						var opts := _trail_opts(2.4)
						opts.colour = _hex((_kit.get("trail", {}) as Dictionary).get("cloud_colour"), Color("#8796b8"))
						_trail_pool.call("emit", cloud, _jitter(0.2), opts)
			else:
				var front := _from.lerp(_surface, t)
				_draw_bolt(_from, front, step)
				for k in _rate_emit(rate, step):
					if _trail_pool == null: break
					_trail_pool.call("emit", front + _jitter(0.08), _jitter(0.8), _trail_opts(1.0))
		"self":
			_aura_frame(step, 1.0)
		"slash":
			# Claw streaks fly from the caster's forelimbs to the target.
			for k in _rate_emit(rate, step):
				if _trail_pool == null: break
				var head := _from.lerp(_surface, t)
				_trail_pool.call("emit", head + _jitter(0.18), -_direction * 0.4 + _jitter(0.2), _trail_opts(1.0))

## Bodies drawn wholly from soft particles (no card/ribbon mesh): a crescent
## of glowing motes, a rotating dust funnel, or a foaming wave wall.
func _particle_body(t: float, step: float) -> void:
	var kind := str((_kit.get("body", {}) as Dictionary).get("kind", ""))
	if kind not in ["mote_crescent", "funnel", "wave_wall"] or _trail_pool == null: return
	var cfg: Dictionary = _kit.get("body", {})
	var head := _path(t, 0)
	var side := _direction.cross(Vector3.UP).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	var colour := _hex(cfg.get("colour"), _colour)
	var accent := _hex(cfg.get("accent"), colour.lerp(Color.WHITE, 0.5))
	var size := float(cfg.get("mote_size", 0.45)) * float(tuning.get("trail_scale", 1.8))
	for k in _rate_emit(float(cfg.get("rate", 120.0)), step, "body"):
		var at := head
		var velocity := Vector3.ZERO
		var u := _rng.randf()
		match kind:
			"mote_crescent":
				# Arc bowed forward, horns trailing; thickest at the centre.
				var a := lerpf(-1.2, 1.2, u)
				var span := float(cfg.get("span_m", 1.1))
				# Vertical blade in the travel plane, horns swept back.
				at = head + Vector3.UP * sin(a) * span - _direction * (1.0 - cos(a)) * span * 0.7 + side * sin(a) * span * 0.25
				velocity = -_direction * 0.4
			"funnel":
				var h := u * float(cfg.get("height_m", 2.2))
				var angle := _elapsed * 9.0 + u * 14.0 + _rng.randf() * 0.6
				var r := lerpf(0.18, float(cfg.get("top_radius_m", 0.9)), u)
				at = Vector3(head.x, lerpf(_ground_source.y, _ground_target.y, t) + h, head.z) + Vector3(cos(angle), 0, sin(angle)) * r
				velocity = Vector3(-sin(angle), 0.6, cos(angle)) * 2.4
			"wave_wall":
				# A rolling crest in the travel plane: tall at the front, a curl
				# tipping forward over it, a long foaming back slope behind.
				var back := u * float(cfg.get("span_m", 1.6))
				var h := float(cfg.get("height_m", 1.4)) * pow(1.0 - u, 0.6) * _rng.randf_range(0.5, 1.0)
				at = Vector3(head.x, lerpf(_ground_source.y, _ground_target.y, t) + 0.15 + h, head.z) - _direction * back + _direction * h * 0.25 + side * _rng.randf_range(-0.5, 0.5)
				velocity = _direction * 1.2 + Vector3.UP * 0.5
		var centre := 1.0 - absf(u - 0.5) * 1.4
		_trail_pool.call("emit", at, velocity + _jitter(0.15), {"life": float(cfg.get("life", 0.22)),
			"size0": size * maxf(0.55, centre), "size1": size * maxf(0.55, centre) * 0.8, "colour": accent if _rng.randf() < 0.3 else colour,
			"fade_in": 0.02, "drag": 1.5})

func _surface_ground() -> Vector3:
	return Vector3(_surface.x, _ground_target.y, _surface.z)

func _dust_opts(scale: float) -> Dictionary:
	var cfg: Dictionary = _kit.get("impact", {})
	return {"life": _rng.randf_range(0.7, 1.1) * float(cfg.get("dust_life", 1.0)), "size0": 0.35 * scale * float(cfg.get("dust_size", 1.0)),
		"size1": 1.1 * scale * float(cfg.get("dust_size", 1.0)), "colour": _hex(cfg.get("dust_colour"), Color("#b9a78a")),
		"drag": 2.2, "gravity": -0.25, "fade_in": 0.05}

func _debris_opts(scale: float) -> Dictionary:
	var cfg: Dictionary = (_kit.get("impact", {}) as Dictionary).get("debris", {})
	return {"life": _rng.randf_range(0.9, 1.3) * float(cfg.get("life", 1.0)), "size0": float(cfg.get("size", 0.16)) * scale * _rng.randf_range(0.6, 1.3),
		"size1": float(cfg.get("size", 0.16)) * scale * 0.8, "colour": Color.WHITE,
		"gravity": float(cfg.get("gravity", 9.0)), "drag": 0.4,
		"spin": _jitter(9.0), "basis": Basis.from_euler(_jitter(PI))}

func _draw_bolt(a: Vector3, b: Vector3, step: float) -> void:
	if _bolt == null or a.distance_to(b) < 0.3: return
	_bolt_reseed -= step
	if _bolt_reseed > 0.0 and not _bolt_points.is_empty(): return
	_bolt_reseed = 0.12
	_bolt_points.clear()
	var segments := 6
	var side := (b - a).cross(Vector3.UP).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	var up := (b - a).cross(side).normalized()
	var jag := a.distance_to(b) * 0.06
	for s in segments + 1:
		var u := float(s) / float(segments)
		var p := a.lerp(b, u)
		if s > 0 and s < segments: p += side * _rng.randf_range(-jag, jag) + up * _rng.randf_range(-jag, jag)
		_bolt_points.append(p)
	var cfg: Dictionary = _kit.get("bolt_style", {})
	var core := _hex(cfg.get("core"), Color("#fff8d8"))
	var glow := _hex(cfg.get("glow"), _colour)
	var width := float(cfg.get("width", 0.09))
	for s in segments:
		var p := _bolt_points[s]
		var q := _bolt_points[s + 1]
		var mid := (p + q) * 0.5
		var axis := (q - p) * 1.08
		_bolt.call("emit_fixed", mid, axis, width * 4.0, glow, 0.2)
		_bolt.call("emit_fixed", mid, axis, width, core, 0.2)
	# One forked branch for a living arc.
	var from_index := _rng.randi_range(2, segments - 2)
	var branch_end := _bolt_points[from_index] + (side * _rng.randf_range(-1.0, 1.0) + up * _rng.randf_range(-0.6, 0.6)) * jag * 6.0 + (b - a) * 0.08
	_bolt.call("emit_fixed", (_bolt_points[from_index] + branch_end) * 0.5, branch_end - _bolt_points[from_index], width * 2.0, glow, 0.2)

func _aura_frame(step: float, intensity: float) -> void:
	if _trail_pool == null: return
	var cfg: Dictionary = _kit.get("trail", {})
	var box := _source_volume()
	var centre := box.get_center()
	for k in _rate_emit(float(cfg.get("rate", 40.0)) * intensity, step):
		# Whole-body volume (feet to crown, snout to tail), centred on its midpoint.
		var at := centre + Vector3(_rng.randf_range(-0.5, 0.5) * box.size.x, _rng.randf_range(-0.5, 0.3) * box.size.y,
			_rng.randf_range(-0.5, 0.5) * box.size.z)
		var outward := (at - centre) * Vector3(1, 0, 1)
		var opts := _trail_opts(1.0)
		opts.size0 = float(cfg.get("size", 0.32)) * float(tuning.get("trail_scale", 1.8))
		opts.size1 = float(cfg.get("end_size", 0.12)) * float(tuning.get("trail_scale", 1.8))
		opts.drag = 0.6
		_trail_pool.call("emit", at, Vector3.UP * float(cfg.get("rise", 0.7)) + outward.normalized() * 0.15 + _jitter(0.12), opts)

# --- Contact -------------------------------------------------------------------

func _contact_position() -> Vector3:
	if _family == "self": return _source_volume().get_center()
	if _family == "ground": return _surface_ground()
	if _family == "bolt" and str(_kit.get("bolt", "chain")) == "sky":
		return Vector3(_surface.x, _target_top(), _surface.z)
	return _surface

func _build_impact() -> void:
	if _impact != null: return
	_impact = Node3D.new()
	add_child(_impact)
	_contact_time = _elapsed
	for body: MeshInstance3D in _bodies: body.visible = false
	var cfg: Dictionary = _kit.get("impact", {})
	var at := _contact_position()
	# Pull the visual a hair toward the caster so it sits on, not inside, the skin.
	if _family not in ["self", "ground"]: at -= _direction * 0.06
	_impact.global_position = at
	var scale := float(cfg.get("scale", 1.0)) * float(tuning.get("impact_scale", 1.6)) * maxf(1.0, float(_params.get("impact_scale", 1.0)) * 0.8)
	var flash_colour := _hex(cfg.get("flash_colour"), _colour.lerp(Color.WHITE, 0.5))
	# Starburst: a bright core plus a wider soft bloom, then radial spark streaks.
	_flash_pool.call("emit", at, Vector3.ZERO, {"life": 0.22, "size0": 0.45 * scale, "size1": 0.8 * scale, "colour": Color(1, 1, 1, 0.85), "fade_in": 0.01})
	_flash_pool.call("emit", at, Vector3.ZERO, {"life": 0.5, "size0": 1.3 * scale, "size1": 2.2 * scale, "colour": Color(flash_colour, 0.9), "fade_in": 0.01})
	var back := -_direction if _family not in ["self"] else Vector3.UP
	if _family == "self":
		# Self effects burst soft glowing motes outward from the whole body.
		var box := _source_volume()
		for i in mini(8, int(_trail_pool.call("capacity")) if _trail_pool != null else 0):
			var dir := _jitter(1.0).normalized()
			_trail_pool.call("emit", at + dir * box.size.length() * 0.2, dir * 2.2 + Vector3.UP * 0.6,
				{"life": 0.5, "size0": 0.55, "size1": 0.2, "colour": flash_colour, "fade_in": 0.01, "drag": 2.5})
	for i in int(_spark_pool.call("capacity")) if _family != "self" else 0:
		var dir := (_jitter(1.0).normalized() + back * float(cfg.get("backscatter", 0.45)) + Vector3.UP * 0.25).normalized()
		_spark_pool.call("emit", at, dir * _rng.randf_range(5.0, 9.0) * scale * float(cfg.get("spark_speed", 1.0)),
			{"life": _rng.randf_range(0.3, 0.5), "size0": 0.13 * scale, "size1": 0.05 * scale,
			"colour": _hex(cfg.get("spark_colour"), flash_colour), "drag": 3.0, "gravity": float(cfg.get("spark_gravity", 4.0)),
			"stretch": 0.11, "fade_in": 0.01})
	var debris_cfg: Dictionary = cfg.get("debris", {})
	var debris_from := at
	if bool(debris_cfg.get("from_ground", false)): debris_from = _surface_ground() + Vector3.UP * 0.2
	for i in int(_motes.multimesh.instance_count) if _motes != null else 0:
		var dir := (_jitter(1.0).normalized() * Vector3(1, 0, 1) + Vector3.UP * _rng.randf_range(0.8, 1.6) + back * 0.6).normalized()
		_motes.call("emit", debris_from + _jitter(0.15), dir * _rng.randf_range(2.5, 4.5) * float(debris_cfg.get("speed", 1.0)), _debris_opts(scale))
	var dust_at := _surface_ground() if bool(cfg.get("dust_on_ground", true)) and _family != "self" else at
	for i in int(_dust_pool.call("capacity")):
		var dir := (_jitter(1.0) * Vector3(1, 0.3, 1)).normalized()
		var opts := _dust_opts(scale)
		_dust_pool.call("emit", dust_at.lerp(at, _rng.randf() * 0.6) + dir * 0.25, dir * _rng.randf_range(1.0, 2.2) + Vector3.UP * 0.5, opts)
	if _family == "ground": _raise_spikes()
	if _family == "slash" and _bolt != null: _claw_marks(at - _direction * 0.12)
	if _family == "bolt":
		if str(_kit.get("bolt", "chain")) == "sky":
			_bolt_points.clear()
			_draw_bolt(_sky_point, at, 1.0)
		else:
			_bolt_points.clear()
			_draw_bolt(_from, at, 1.0)

func _after_frame(age: float, step: float) -> void:
	var cfg: Dictionary = _kit.get("after", {})
	match _family:
		"self":
			if age < float(cfg.get("hold_s", 0.85)): _aura_frame(step, maxf(0.3, 1.0 - age))
		"stream":
			if age < 0.22:
				_travel_frame(1.0, step)
		"bolt":
			if age < float(cfg.get("bolt_hold_s", 0.3)):
				if str(_kit.get("bolt", "chain")) == "sky": _draw_bolt(_sky_point, _contact_position(), step)
				else: _draw_bolt(_from, _contact_position(), step)
	# Lingering soft remnant (embers, mist, sparkles) through the aftermath.
	if cfg.has("remnant_rate") and age < float(cfg.get("remnant_s", 0.8)) and _trail_pool != null:
		for k in _rate_emit(float(cfg.remnant_rate), step, "remnant"):
			var opts := _trail_opts(1.0)
			opts.colour = _hex(cfg.get("remnant_colour"), _colour)
			opts.life = 0.6
			opts.size0 = float(cfg.get("remnant_size", 0.25))
			opts.size1 = opts.size0 * 0.4
			_trail_pool.call("emit", _contact_position() + _jitter(0.45), Vector3.UP * 0.6 + _jitter(0.25), opts)

## Parallel curved claw rakes across the struck surface, drawn as dense soft
## additive motes (no flat card), so they read as glowing cuts over the coat.
func _claw_marks(at: Vector3) -> void:
	var cfg: Dictionary = _kit.get("claws", {})
	var claws := int(cfg.get("count", 3))
	var per := maxi(2, int(_bolt.call("capacity")) / maxi(1, claws))
	var side := _direction.cross(Vector3.UP).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	# Rakes are drawn across the struck surface as the local viewer sees it.
	var camera := get_viewport().get_camera_3d() if get_viewport() != null else null
	if camera != null: side = camera.global_basis.x.normalized()
	var length := float(cfg.get("length_m", 1.3))
	var colour := _hex(cfg.get("colour"), Color.WHITE)
	for c in claws:
		var offset := (float(c) - float(claws - 1) * 0.5) * float(cfg.get("gap_m", 0.26))
		var points: Array[Vector3] = []
		for k in per + 1:
			var u := float(k) / float(per) - 0.5
			# Diagonal sweep across the struck surface, bowed toward the caster.
			points.append(at + side * (u * length * 0.75 + offset) + Vector3.UP * (-u * length * 0.85 + offset * 0.3) - _direction * (0.2 * (1.0 - 4.0 * u * u)))
		for k in per:
			var w := float(cfg.get("width_m", 0.14)) * (1.0 - absf(float(k) + 0.5 - float(per) * 0.5) / float(per))
			_bolt.call("emit_fixed", (points[k] + points[k + 1]) * 0.5, (points[k + 1] - points[k]) * 1.15, w, colour, float(cfg.get("life", 0.6)))
			if _trail_pool != null:
				_trail_pool.call("emit", points[k], -_direction * 0.3, {"life": 0.55, "size0": w * 3.5, "size1": w * 1.5,
					"colour": colour, "fade_in": 0.01, "drag": 2.0})

func _raise_spikes() -> void:
	var cfg: Dictionary = _kit.get("spikes", {})
	var count := int(cfg.get("count", 5))
	var box := _target_box()
	var centre := _surface_ground()
	var reach := Vector2(0.9, 0.9)
	if box.size.x > 0.0:
		centre = Vector3(box.get_center().x, _ground_target.y, box.get_center().z)
		# Ellipse just outside the measured footprint: spikes ring the body, never pierce it.
		reach = Vector2(box.size.x, box.size.z) * 0.5 + Vector2.ONE * float(cfg.get("clearance_m", 0.3))
	var material := _rock_material(_hex(cfg.get("colour"), Color("#8b7a62")))
	material.emission_enabled = false
	material.disable_receive_shadows = false
	for i in count:
		var spike := MeshInstance3D.new()
		spike.mesh = spike_mesh(int(_context.get("seed", 0)) * 31 + i)
		spike.material_override = material
		spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(spike)
		spike.top_level = true
		var angle := TAU * float(i) / float(count) + _rng.randf_range(-0.25, 0.25)
		var ring := float(cfg.get("ring_scale", 0.95))
		var at := centre + Vector3(cos(angle) * reach.x, 0, sin(angle) * reach.y) * ring * _rng.randf_range(1.0, 1.12)
		if bool(cfg.get("front_first", true)) and i == 0:
			var front := -Vector3(_direction.x, 0, _direction.z).normalized()
			at = centre + Vector3(front.x * reach.x, 0, front.z * reach.y) * ring
		spike.global_position = at - Vector3.UP * 0.05
		var outward := (at - centre).normalized()
		spike.global_basis = Basis(outward.cross(Vector3.UP).normalized() if not outward.cross(Vector3.UP).is_zero_approx() else Vector3.RIGHT, deg_to_rad(float(cfg.get("lean_deg", 16.0))))
		spike.set_meta("width", float(cfg.get("width", 0.42)) * _rng.randf_range(0.8, 1.2))
		_spikes.append(spike)
		_spike_heights.append(float(cfg.get("height", 1.4)) * _rng.randf_range(0.7, 1.15))

func _update_spikes() -> void:
	if _spikes.is_empty() or _contact_time < 0.0: return
	var age := _elapsed - _contact_time
	var cfg: Dictionary = _kit.get("spikes", {})
	var rise := clampf(age / float(cfg.get("rise_s", 0.12)), 0.0, 1.0)
	var sink := smoothstep(float(cfg.get("hold_s", 0.75)), float(_kit.get("linger_s", 1.05)), age)
	for i in _spikes.size():
		var spike := _spikes[i]
		var height := _spike_heights[i] * (1.0 - pow(1.0 - rise, 3.0)) * (1.0 - sink)
		var width := float(spike.get_meta("width"))
		var b := spike.global_basis.orthonormalized()
		spike.global_basis = Basis(b.x * width, b.y * maxf(0.001, height), b.z * width)
		spike.visible = height > 0.01

func _retire_contact_drawing() -> void:
	if _contact_retired: return
	for spike: MeshInstance3D in _spikes: spike.visible = false
	for pool: Node in _pools: (pool as Node3D).visible = false
	super._retire_contact_drawing()

func cancel_presentation() -> void:
	_retire_contact_drawing()
	super.cancel_presentation()

func diagnostic_receipt() -> Dictionary:
	var counts := {}
	for pool: Node in _pools: counts[pool.name] = int(pool.call("alive"))
	return {"candidate": "kit_effect", "family": _family, "surface_contact": [_surface.x, _surface.y, _surface.z],
		"alive": counts, "lease": BUDGET.allocation(_lease), "arrived": _arrived}
