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

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	var cfg: Dictionary = CATCH.config().get("throw", {})
	_gravity = float(cfg.get("gravity", _gravity))
	_radius = float(cfg.get("radius", _radius))
	_max_life = float(cfg.get("max_flight_time", _max_life))
	_build_placeholder()


## Placeholder art, and labelled as such. M11 replaces this with the real orb;
## nothing else in this file changes.
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
	material.emission = Color("#d9b340")
	material.emission_energy_multiplier = 0.6
	_mesh.mesh = sphere
	_mesh.material_override = material


## Launch. `target` is the creature this throw is aimed at; the orb only tests
## against that one, because a throw is at a pal, not at the world.
func launch(from: Vector3, direction: Vector3, speed: float, target: Node3D) -> void:
	global_position = from
	_velocity = direction.normalized() * speed
	_target = target
	_life = 0.0
	_spent = false


func _physics_process(delta: float) -> void:
	if _spent:
		return

	_life += delta
	_velocity.y -= _gravity * delta
	global_position += _velocity * delta
	# Spin, so a placeholder sphere still reads as an object in flight rather
	# than a decal sliding through the air.
	_mesh.rotate_x(12.0 * delta)

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
