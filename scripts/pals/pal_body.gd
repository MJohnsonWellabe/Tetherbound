extends CharacterBody3D

## The physical body of a creature: how it looks, and how it moves.
##
## A CharacterBody3D rather than a Node3D because combat is piloted
## (docs/decisions/D07). Both fighters move under their own power over the same
## terrain the trainer walks on, so they need the same collision treatment. The
## earlier version faked motion by offsetting a mesh, which was fine for a fight
## in which nobody moved and is wrong now.
##
## Everything above this — the combat manager, the AI, the encounter director —
## talks to `request_move`, `add_impulse`, `face_towards` and `place_on_ground`,
## and never touches `velocity`. That is what lets the player's pal and the wild
## one share one movement implementation while being driven by a stick and by a
## state machine respectively.
##
## M11 replaces `_build_placeholder` with a rigged model. Nothing else here
## changes.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const GROUND_PROBE_UP := 12.0
const GROUND_PROBE_DOWN := 60.0

var species_id: String = ""
var display_name: String = ""

var _height: float = 1.0
var _radius: float = 0.4

## Requested movement for this physics frame, cleared after it is consumed.
## Cleared rather than latched on purpose: a driver that stops driving stops the
## creature, so a state machine that forgets to say "stand still" cannot leave a
## creature sliding across the arena forever.
var _requested: Vector3 = Vector3.ZERO
var _requested_speed: float = 0.0

## Attack lunges and knockbacks, decaying. Separate from `velocity` so being hit
## mid-stride reads as a shove rather than as a cancelled input.
var _impulse: Vector3 = Vector3.ZERO

var _speed: float = 5.0
var _acceleration: float = 34.0
var _friction: float = 30.0
var _turn_speed: float = 13.0
var _gravity: float = 26.0
var _impulse_damping: float = 9.0

## Optional arena that holds this creature inside a boundary. Null outside
## combat, which is why the wild pal can wander freely before it is engaged.
var arena: Node = null

@onready var _collision: CollisionShape3D = $Collision
@onready var _body: MeshInstance3D = $Body
@onready var _head: MeshInstance3D = $Head


func _ready() -> void:
	_load_config()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	if species_id != "" and _body != null:
		_build_placeholder()


## A hidden creature is switched off entirely — no physics, no collider.
##
## The player's pal exists in the world the whole time and is only hidden
## outside combat, so that deploying it is not a hitch in the one frame that
## most needs to be smooth. But an invisible CharacterBody3D standing inside the
## trainer is still a solid object, and two overlapping bodies resolve the
## overlap by shoving each other apart: the trainer was launched off the
## playground at 500 m/s, accelerating, on the first frame of every run.
func _on_visibility_changed() -> void:
	set_physics_process(visible)
	if _collision != null:
		# Deferred because visibility is usually flipped from inside a physics
		# callback, and changing a collider's state mid-step is not allowed.
		_collision.set_deferred("disabled", not visible)


func _load_config() -> void:
	var cfg: Dictionary = MATH.config().get("pal_movement", {})
	_speed = float(cfg.get("speed", _speed))
	_acceleration = float(cfg.get("acceleration", _acceleration))
	_friction = float(cfg.get("friction", _friction))
	_turn_speed = float(cfg.get("turn_speed", _turn_speed))
	_gravity = float(cfg.get("gravity", _gravity))
	_impulse_damping = float(cfg.get("impulse_damping", _impulse_damping))


## Configure from the species table. Safe to call before or after the node is in
## the tree; the mesh is built on whichever happens second.
func setup(id: String) -> void:
	species_id = id
	display_name = str(SPECIES.definition(id).get("display_name", id))
	if is_inside_tree() and _body != null:
		_build_placeholder()


func _build_placeholder() -> void:
	var look: Dictionary = SPECIES.placeholder(species_id)
	_height = float(look.get("height", 1.0))
	_radius = float(look.get("radius", 0.4))
	var colour := Color(str(look.get("colour", "#cccccc")))

	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85

	var torso := CapsuleMesh.new()
	torso.radius = _radius
	torso.height = maxf(_height, _radius * 2.0 + 0.01)
	_body.mesh = torso
	_body.material_override = material
	_body.position = Vector3(0.0, _height * 0.5, 0.0)

	# A smaller sphere forward and high, so the capsule has a front. Without it
	# there is no reading which way a creature is facing — and in a fight where
	# attacks are aimed, facing is the information the player needs most.
	var snout := SphereMesh.new()
	snout.radius = _radius * 0.55
	snout.height = _radius * 1.1
	_head.mesh = snout
	_head.material_override = material
	_head.position = Vector3(0.0, _height * 0.82, _radius * 0.9)

	var shape := CapsuleShape3D.new()
	shape.radius = _radius
	shape.height = maxf(_height, _radius * 2.0 + 0.01)
	_collision.shape = shape
	_collision.position = Vector3(0.0, _height * 0.5, 0.0)


func body_height() -> float:
	return _height


## Where an attack aimed at this creature should be measured to: the middle of
## the body rather than the point between its feet.
func centre() -> Vector3:
	return global_position + Vector3.UP * (_height * 0.5)


## Facing, on the horizontal plane. This is what an attack is aimed along.
func facing() -> Vector3:
	var forward := global_transform.basis.z
	forward.y = 0.0
	return Vector3.FORWARD if forward.length() < 0.01 else forward.normalized()


## --- driving --------------------------------------------------------------

## Ask to move in a world-space direction this frame. Must be called every frame
## the creature should be moving; see `_requested`.
func request_move(direction: Vector3, speed: float = -1.0) -> void:
	_requested = Vector3(direction.x, 0.0, direction.z)
	if _requested.length() > 1.0:
		_requested = _requested.normalized()
	_requested_speed = _speed if speed < 0.0 else speed


func add_impulse(direction: Vector3, strength: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() < 0.01:
		return
	_impulse += flat.normalized() * strength


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		# Small downward bias, the same trick the trainer uses, so the creature
		# stays pinned to slopes instead of skipping off every crest.
		velocity.y = -2.0

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if _requested.length() < 0.01:
		horizontal = horizontal.move_toward(Vector3.ZERO, _friction * delta)
	else:
		horizontal = horizontal.move_toward(_requested * _requested_speed, _acceleration * delta)
		_turn_towards(_requested, delta)

	_impulse = _impulse.move_toward(Vector3.ZERO, _impulse_damping * _impulse.length() * delta)

	velocity.x = horizontal.x + _impulse.x
	velocity.z = horizontal.z + _impulse.z
	move_and_slide()

	if arena != null:
		arena.call("hold_inside", self)

	_requested = Vector3.ZERO


func _turn_towards(direction: Vector3, delta: float) -> void:
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, _turn_speed * delta)


## Turn to face a world point, immediately. Used when a fight is arranged and by
## the peaceful idle; combat turning goes through `_turn_towards`.
func face_towards(point: Vector3) -> void:
	var to := point - global_position
	to.y = 0.0
	if to.length() < 0.01:
		return
	rotation.y = atan2(to.x, to.z)


## Move to an x/z position and sit on whatever is under it.
##
## A downward ray rather than a terrain height lookup, so this works over the
## terrain, over a rock, and over anything built later, and so it does not have
## to know Terrain3D exists.
func place_on_ground(target: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var world := get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state
	if space == null:
		return false

	var from := Vector3(target.x, target.y + GROUND_PROBE_UP, target.z)
	var to := from + Vector3.DOWN * GROUND_PROBE_DOWN
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		# No ground found. Leaving it where it is beats teleporting it into the
		# sky, and the caller gets told so it can pick somewhere else.
		return false
	global_position = hit["position"]
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO
	return true
