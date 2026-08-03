extends Node3D

## A thrown orb, in flight.
##
## A real projectile on a real arc. GAME_DESIGN.md §15 forbids throwing without
## player aim, and a hitscan gives nothing to aim: the arc is what turns "press
## the button while looking at it" into a throw that can be judged, led, and
## missed.
##
## It integrates its own position rather than being a RigidBody3D. The flight is
## a parabola and a handful of sphere checks, the tuning has to be readable in
## data/config/catching.json, and a physics body would put the arc at the mercy
## of engine defaults nobody has a reason to trust.

const CATCH := preload("res://scripts/combat/catch_math.gd")

## Struck the target. `offset` is metres from its centre of mass, which is what
## the accuracy half of the catch formula reads.
signal struck(target: Node3D, offset: float)
## Hit the ground, or ran out of flight time, without touching anything.
signal missed()

var _velocity: Vector3 = Vector3.ZERO
var _gravity: float = 14.0
var _radius: float = 0.42
var _life: float = 0.0
var _max_life: float = 4.0
var _target: Node3D = null
var _spent: bool = false

## How many times the orb's own radius the readable halo is drawn at, and how
## wide the trail gets at its head. Presentation only — the collision radius the
## catch maths reads is untouched by both.
const HALO_SCALE := 5.5
const TRAIL_WIDTH := 1.1
## Flight positions kept for the trail. About a third of a second at 60Hz.
const TRAIL_POINTS := 20

const HALO_SEGMENTS := 18

var _halo: MeshInstance3D = null
var _halo_mesh: ImmediateMesh = null
var _trail: MeshInstance3D = null
var _trail_mesh: ImmediateMesh = null
var _path: PackedVector3Array = PackedVector3Array()

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	var cfg: Dictionary = CATCH.config().get("throw", {})
	_gravity = float(cfg.get("gravity", _gravity))
	_radius = float(cfg.get("radius", _radius))
	_max_life = float(cfg.get("max_flight_time", _max_life))
	_build_placeholder()


## Placeholder art, and labelled as such. M11 replaces this with the real orb;
## nothing else in this file changes.
##
## But it has to be VISIBLE, which it was not. The blind critic diffed
## `combat/08-orb-in-flight` against the frame before it and found no
## projectile, no trail and no arc anywhere in the image — the largest change in
## the frame was a creature repositioning. A 42cm sphere twelve metres away is
## about four pixels, and four gold pixels over sunlit grass is nothing. The
## signature mechanic of the game was invisible in the frame named after it.
##
## So: a camera-facing halo several times the orb's physical size, and a ribbon
## trail behind it. The COLLISION radius is untouched — the orb still tests at
## exactly the size the catch maths reads, and only the glow around it is
## larger, because an aim you cannot see is not a skill.
func _build_placeholder() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = _radius * 0.5
	sphere.height = _radius
	var material := StandardMaterial3D.new()
	# Gold from the palette board, and emissive so a small fast object stays
	# readable against sunlit grass — which is the entire background of every
	# throw in the Meadows.
	material.albedo_color = Color("#d9b340")
	material.emission_enabled = true
	material.emission = Color("#ffe9a8")
	material.emission_energy_multiplier = 2.2
	_mesh.mesh = sphere
	_mesh.material_override = material

	# A disc with alpha falling to nothing at its rim, rebuilt each frame facing
	# the camera. It was a QuadMesh with a flat colour, which is exactly what it
	# looked like: a hard-edged opaque tan SQUARE hanging in the middle of the
	# frame, drawn over the trainer. A glow needs a gradient or it is a sticker.
	_halo_mesh = ImmediateMesh.new()
	_halo = MeshInstance3D.new()
	_halo.mesh = _halo_mesh
	_halo.material_override = _glow(Color(1.0, 0.85, 0.45, 1.0))
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)

	_trail_mesh = ImmediateMesh.new()
	_trail = MeshInstance3D.new()
	_trail.mesh = _trail_mesh
	_trail.material_override = _glow(Color(1.0, 0.82, 0.40, 1.0))
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The trail is in WORLD space: it is where the orb has been, not where the
	# orb is, so it must not inherit the orb's motion.
	_trail.top_level = true
	add_child(_trail)


func _glow(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Depth test ON, unlike the impact flash. An orb passing behind the trainer's
	# shoulder should go behind it; punching through would read as the orb being
	# painted on the lens.
	material.no_depth_test = false
	material.albedo_color = colour
	material.vertex_color_use_as_albedo = true
	return material


## A camera-facing disc, bright at the centre and gone at the rim.
func _draw_halo() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right: Vector3 = basis.x * _radius * HALO_SCALE * 0.5
	var up: Vector3 = basis.y * _radius * HALO_SCALE * 0.5

	_halo_mesh.clear_surfaces()
	_halo_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in HALO_SEGMENTS:
		var a: float = TAU * float(i) / float(HALO_SEGMENTS)
		var b: float = TAU * float(i + 1) / float(HALO_SEGMENTS)
		_halo_mesh.surface_set_color(Color(1.0, 0.92, 0.66, 0.85))
		_halo_mesh.surface_add_vertex(Vector3.ZERO)
		_halo_mesh.surface_set_color(Color(1.0, 0.78, 0.32, 0.0))
		_halo_mesh.surface_add_vertex(right * cos(a) + up * sin(a))
		_halo_mesh.surface_set_color(Color(1.0, 0.78, 0.32, 0.0))
		_halo_mesh.surface_add_vertex(right * cos(b) + up * sin(b))
	_halo_mesh.surface_end()


## Redraw the trail from the recorded flight path, tapering to nothing at the
## oldest end so it reads as motion rather than as a wire.
func _draw_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _path.size() < 2:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in _path.size():
		var t: float = float(i) / float(_path.size() - 1)
		var point: Vector3 = _path[i]
		# Widen towards the head. A constant-width ribbon reads as a rope.
		var to_camera: Vector3 = (camera.global_position - point).normalized()
		var along: Vector3 = (_path[mini(i + 1, _path.size() - 1)] - _path[maxi(i - 1, 0)])
		if along.length() < 0.0001:
			along = _velocity
		var side: Vector3 = along.cross(to_camera).normalized() * _radius * TRAIL_WIDTH * t
		var alpha: float = t * t * 0.85
		_trail_mesh.surface_set_color(Color(1.0, 0.82, 0.40, alpha))
		_trail_mesh.surface_add_vertex(point + side)
		_trail_mesh.surface_set_color(Color(1.0, 0.82, 0.40, alpha))
		_trail_mesh.surface_add_vertex(point - side)
	_trail_mesh.surface_end()


## Launch. `target` is the creature this throw is aimed at; the orb only tests
## against that one, because a throw is at a pal, not at the world.
func launch(from: Vector3, direction: Vector3, speed: float, target: Node3D) -> void:
	global_position = from
	_velocity = direction.normalized() * speed
	_target = target
	_life = 0.0
	_spent = false
	_path = PackedVector3Array([from])


func _physics_process(delta: float) -> void:
	if _spent:
		return

	_life += delta
	_velocity.y -= _gravity * delta
	global_position += _velocity * delta
	# Spin, so a placeholder sphere still reads as an object in flight rather
	# than a decal sliding through the air.
	_mesh.rotate_x(12.0 * delta)

	_draw_halo()
	_path.append(global_position)
	while _path.size() > TRAIL_POINTS:
		_path.remove_at(0)
	_draw_trail()

	if _check_target():
		return
	if _life >= _max_life or _hit_ground():
		_finish_with_miss()


func _check_target() -> bool:
	if _target == null or not is_instance_valid(_target) or not _target.visible:
		return false
	var centre: Vector3 = _target.call("centre") if _target.has_method("centre") \
		else _target.global_position
	var body_radius := 0.5
	if _target.has_method("body_radius"):
		body_radius = float(_target.call("body_radius"))

	var offset := global_position.distance_to(centre)
	if offset > body_radius + _radius:
		return false

	_spent = true
	# Reported as distance from the centre, clamped at the body's own radius, so
	# the accuracy bonus is scored against the creature rather than against the
	# orb's generous collision sphere. Widening `radius` to forgive the input
	# must not silently make every throw count as dead centre.
	struck.emit(_target, minf(offset, body_radius))
	return true


## Ground test by raycast along the step just travelled, rather than by sampling
## a height. Over Terrain3D the ground can move a long way inside one frame of a
## fast projectile, and a point check tunnels straight through hillsides.
func _hit_ground() -> bool:
	var world := get_world_3d()
	if world == null:
		return false
	var from := global_position - _velocity * get_physics_process_delta_time()
	var query := PhysicsRayQueryParameters3D.create(from, global_position)
	query.collide_with_areas = false
	if _target != null and _target is CollisionObject3D:
		query.exclude = [(_target as CollisionObject3D).get_rid()]
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	global_position = hit["position"]
	return true


func _finish_with_miss() -> void:
	_spent = true
	missed.emit()


func stop() -> void:
	_spent = true
	_velocity = Vector3.ZERO
	if _trail_mesh != null:
		_trail_mesh.clear_surfaces()
	if _halo_mesh != null:
		_halo_mesh.clear_surfaces()
