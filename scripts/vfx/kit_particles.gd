extends MultiMeshInstance3D

## Presentation-only CPU particle pool for the kit move effects: one MultiMesh
## draw, a fixed instance count taken from the effect's admitted budget lease,
## manual integration on the presentation clock. Positions are world space
## (the owning effect is top_level at identity). No gameplay state.
enum Mode { BILLBOARD, STREAK, SOLID }

var mode := Mode.BILLBOARD
var ground_y := -INF
var _pos: Array[Vector3] = []
var _vel: Array[Vector3] = []
var _age: PackedFloat32Array = PackedFloat32Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _s0: PackedFloat32Array = PackedFloat32Array()
var _s1: PackedFloat32Array = PackedFloat32Array()
var _col: Array[Color] = []
var _gravity: PackedFloat32Array = PackedFloat32Array()
var _drag: PackedFloat32Array = PackedFloat32Array()
var _spin: Array[Vector3] = []
var _rot: Array[Basis] = []
var _stretch: PackedFloat32Array = PackedFloat32Array()
var _fade_in: PackedFloat32Array = PackedFloat32Array()
var _axis: Array[Vector3] = []
var _next := 0
var _rest := Vector3.ZERO

func setup(capacity: int, mesh: Mesh, material: Material, particle_mode: int, rest: Vector3) -> void:
	mode = particle_mode
	_rest = rest
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = maxi(0, capacity)
	multimesh = multi
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if mode == Mode.SOLID else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Moved every frame: detail_cull.gd must not range it by its spawn spread.
	set_meta(&"detail_cull_skip", true)
	for i in multi.instance_count:
		_pos.append(rest)
		_vel.append(Vector3.ZERO)
		_age.append(1.0)
		_life.append(0.0)
		_s0.append(0.0)
		_s1.append(0.0)
		_col.append(Color(0, 0, 0, 0))
		_gravity.append(0.0)
		_drag.append(0.0)
		_spin.append(Vector3.ZERO)
		_rot.append(Basis.IDENTITY)
		_stretch.append(0.0)
		_fade_in.append(0.0)
		_axis.append(Vector3.ZERO)
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.0001), rest))
		multi.set_instance_color(i, Color(0, 0, 0, 0))

func capacity() -> int:
	return multimesh.instance_count if multimesh != null else 0

## Fields: life, size0, size1, colour, gravity, drag, spin, stretch, fade_in.
func emit(position: Vector3, velocity: Vector3, opts: Dictionary) -> void:
	var n := capacity()
	if n == 0: return
	var i := _next
	_next = (_next + 1) % n
	_pos[i] = position
	_vel[i] = velocity
	_age[i] = 0.0
	_life[i] = maxf(0.01, float(opts.get("life", 0.4)))
	_s0[i] = float(opts.get("size0", 0.2))
	_s1[i] = float(opts.get("size1", _s0[i]))
	_col[i] = opts.get("colour", Color.WHITE)
	_gravity[i] = float(opts.get("gravity", 0.0))
	_drag[i] = float(opts.get("drag", 0.0))
	_spin[i] = opts.get("spin", Vector3.ZERO)
	_rot[i] = opts.get("basis", Basis.IDENTITY)
	_stretch[i] = float(opts.get("stretch", 0.06))
	_fade_in[i] = float(opts.get("fade_in", 0.08))
	_axis[i] = opts.get("axis", Vector3.ZERO)
	if ground_y > -INF:
		_pos[i].y = maxf(_pos[i].y, ground_y + _current_size(i) * (0.87 if mode == Mode.SOLID else 0.5))
	_write(i)

## A motionless streak segment with an explicit axis (bolt/arc segments).
func emit_fixed(centre: Vector3, axis: Vector3, width: float, colour: Color, life: float) -> void:
	emit(centre, Vector3.ZERO, {"life": life, "size0": width, "size1": width, "colour": colour, "axis": axis, "fade_in": 0.0})

func alive() -> int:
	var count := 0
	for i in capacity():
		if _age[i] < _life[i]: count += 1
	return count

func step(delta: float) -> void:
	for i in capacity():
		if _age[i] >= _life[i]: continue
		_age[i] += delta
		_vel[i] += Vector3.DOWN * _gravity[i] * delta
		_vel[i] *= maxf(0.0, 1.0 - _drag[i] * delta)
		_pos[i] += _vel[i] * delta
		if mode == Mode.SOLID:
			_rot[i] = _rot[i].rotated(_spin[i].normalized() if not _spin[i].is_zero_approx() else Vector3.UP, _spin[i].length() * delta).orthonormalized()
		# A rotated solid chunk's box can reach sqrt(3)/2 of its size below centre.
		var rest_y := ground_y + _current_size(i) * (0.87 if mode == Mode.SOLID else 0.5)
		if ground_y > -INF and _pos[i].y < rest_y:
			# Debris lands and skids on the frozen ground plane, never under it.
			_pos[i].y = rest_y
			_vel[i] = Vector3(_vel[i].x * 0.45, absf(_vel[i].y) * 0.22, _vel[i].z * 0.45)
			_spin[i] *= 0.5
		_write(i)

func _current_size(i: int) -> float:
	var u := clampf(_age[i] / _life[i], 0.0, 1.0)
	var size := lerpf(_s0[i], _s1[i], u)
	# Solid debris shrinks away at the end of its life instead of going translucent.
	if mode == Mode.SOLID: size *= 1.0 - smoothstep(0.8, 1.0, u)
	return size

func _write(i: int) -> void:
	var dead := _age[i] >= _life[i]
	var u := clampf(_age[i] / _life[i], 0.0, 1.0)
	var size := _current_size(i)
	var fade := (1.0 if _fade_in[i] <= 0.0 else minf(1.0, _age[i] / _fade_in[i])) * (1.0 - smoothstep(0.55, 1.0, u))
	if mode == Mode.SOLID: fade = 1.0
	var c := _col[i]
	c.a *= fade
	if dead:
		# Parked above the rest point (ground/caster), zero-sized.
		var parked := _pos[i]
		if ground_y > -INF: parked.y = maxf(parked.y, ground_y + 0.01)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.0001), parked))
		multimesh.set_instance_color(i, Color(0, 0, 0, 0))
		return
	var basis := Basis.IDENTITY.scaled(Vector3.ONE * size)
	if mode == Mode.STREAK:
		var speed := _vel[i].length()
		var axis := _vel[i] / speed if speed > 0.001 else Vector3.UP
		var length := maxf(size, speed * _stretch[i])
		if not _axis[i].is_zero_approx():
			axis = _axis[i].normalized()
			length = _axis[i].length()
		basis = Basis(axis * length, Vector3(0, size, 0), Vector3(0, 0, size))
	elif mode == Mode.SOLID:
		basis = _rot[i].scaled(Vector3.ONE * size)
	multimesh.set_instance_transform(i, Transform3D(basis, _pos[i]))
	multimesh.set_instance_color(i, c)
