extends "res://scripts/creatures/creature_body.gd"

## Stage B lane 4.B -- the body ANOTHER peer's deployed creature wears in THIS
## process, and the outbound proxy the owner pushes its own creature's state
## through.
##
## The shape is deliberately `remote_trainer.gd`'s, not a second invention:
## lane 2.C already landed this pattern for trainer bodies and the brief for
## this lane says to follow it. One of these exists per DEPLOYED creature per
## peer in the session, on every peer, under D97's authored
## `Spawned/Creatures` container. It is spawned only through
## `encounter_director.gd::_spawn_deployed_creature()`, which sets its
## multiplayer authority to the owning peer INSIDE the spawn function and
## before the node enters the tree.
##
## ## Whose body is whose
##
## `owner_peer_id` is the peer that owns the creature. On that peer this node
## is an OUTBOUND PROXY: invisible, non-colliding, standing exactly where the
## owner's real `follower_creature.gd` body stands, copying that body's
## position and yaw into the replicated `net_*` properties every physics
## frame. On every other peer the same node is the thing the player actually
## sees, and it walks toward those properties.
##
## That split is why the owner keeps piloting its own creature with the exact
## code it uses in solo: the local `follower_creature.gd` body is untouched by
## the session, and this node never drives it.
##
## ## Why authority is re-read every frame
##
## Verbatim the reason `remote_trainer.gd` gives, and it is the trap this
## project has already paid for once. Authority is a plain integer compared
## against `multiplayer.get_unique_id()`, and that id CHANGES under a node's
## feet: a process with no session runs on Godot's default
## `OfflineMultiplayerPeer`, where the id is 1, and it becomes a large random
## number the moment `Session.join()` installs a real peer. A body that
## decided once at `_ready()` whether it was its own would keep a stale answer
## across that swap.

const GROUP := &"remote_creature"

## Smoothing half-life for the rendered position, and the gap past which the
## difference is a teleport rather than late packets. Same numbers and same
## reasoning as `remote_trainer.gd`; a creature is a little wider than a
## trainer, so the snap threshold is a metre more generous.
const INTERP_HALF_LIFE_S := 0.08
const SNAP_M := 6.0

## Set by the spawn function from the spawn data, on every peer, before the
## node enters the tree. Never replicated per-frame: they do not change for
## the life of the body (a peer that swaps creature gets a new body).
var owner_peer_id: int = 0
var owner_character_id: String = ""
var deploy_species: String = ""
var deploy_shiny: bool = false

## The replicated set. Position and yaw are what this body is interpolated
## toward; nothing else needs to cross the wire, because the animator derives
## its gait from the velocity that interpolation produces.
var net_position: Vector3 = Vector3.ZERO
var net_yaw: float = 0.0

var _render_position: Vector3 = Vector3.ZERO
var _has_render: bool = false
## `null` until the first evaluation, so the first pass always applies. See
## this file's header for why it is re-read rather than cached at `_ready()`.
var _owned_here: Variant = null
var _layer: int = 0
var _mask: int = 0


func _ready() -> void:
	super()
	add_to_group(GROUP)
	add_to_group(DEPLOYED_GROUP)
	# Layer 0, not the authored layer: a deployed creature is never solid to a
	# trainer in this game, and `follower_creature.gd::set_following()` already
	# says why -- a creature that can stand in the way is a creature that walls
	# its trainer in, and two CharacterBody3D capsules aimed at each other stop
	# dead. That defect is worse across the wire, not better, because the
	# trainer being walled in is not the one who can move the creature. The
	# MASK is kept, so the proxy still walks over the world rather than through
	# it.
	_layer = 0
	_mask = collision_mask
	collision_layer = 0
	if deploy_species != "":
		# After `super()`, which is the same ordering
		# `encounter_director.gd::_spawn_ally_body()` uses on the local body:
		# instantiate, enter the tree, then `setup()`.
		setup(deploy_species, deploy_shiny)
	net_position = global_position
	_render_position = global_position
	_has_render = true
	_apply_ownership()
	print("[creatures] %s stands up: owner %d, authority %d, this peer is %d (%s)"
		% [name, owner_peer_id, get_multiplayer_authority(), multiplayer.get_unique_id(),
			"our own proxy" if bool(_owned_here) else "another player's creature"])


## `creature_body.gd` switches physics off with visibility, because a hidden
## creature there is a creature that has been put away. A proxy hidden on its
## OWNER's screen is the opposite: it is the one body that must keep ticking,
## because ticking is how it pushes its owner's state onto the wire. The
## collider still follows visibility, which is the half of the parent's
## behaviour that was protecting the trainer from being shoved around.
func _on_visibility_changed() -> void:
	set_physics_process(true)
	if _collision != null:
		_collision.set_deferred("disabled", not visible)


## Never the local player's own piloted creature: that is always the
## `follower_creature.gd` body the encounter director stands up. Read by
## `playground_hud.gd` to pick its own creature out of the deployed group
## without going through a node name.
func is_local_deployment() -> bool:
	return false


func _apply_ownership() -> void:
	var mine := is_multiplayer_authority()
	if _owned_here != null and bool(_owned_here) == mine:
		return
	_owned_here = mine
	if mine:
		# The owner already has a real creature standing in this spot. Drawing
		# a second one inside it, and colliding with it, is the same bug
		# `remote_trainer.gd` avoids for trainers.
		visible = false
		collision_layer = 0
		collision_mask = 0
	else:
		visible = true
		collision_layer = _layer
		collision_mask = _mask


func _physics_process(delta: float) -> void:
	_apply_ownership()
	if bool(_owned_here):
		_push_from_local_creature()
		return
	_follow(delta)


# --- the owner's side ---------------------------------------------------------

## Copy the owner's real deployed body. Deliberately reads the
## `deployed_creature` group rather than reaching into the encounter director:
## the same decoupling `playground_hud.gd` keeps, and it survives a world that
## mounts its director somewhere else.
func _push_from_local_creature() -> void:
	var body := _local_deployed_body()
	if body == null:
		return
	net_position = body.global_position
	net_yaw = body.rotation.y
	# Keep the proxy co-located with the body it mirrors: nothing renders it
	# here, but a probe or a distance check that finds this node must not see a
	# body parked where it spawned.
	global_position = net_position
	rotation.y = net_yaw


func _local_deployed_body() -> Node3D:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(DEPLOYED_GROUP):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if node.has_method("is_local_deployment") and bool(node.call("is_local_deployment")):
			return node as Node3D
	return null


# --- every other peer's side --------------------------------------------------

func _follow(delta: float) -> void:
	if not _has_render:
		_render_position = net_position
		_has_render = true
	if _render_position.distance_to(net_position) > SNAP_M:
		_render_position = net_position
		global_position = net_position
		velocity = Vector3.ZERO
		rotation.y = net_yaw
		return

	var weight := clampf(1.0 - exp(-delta / maxf(INTERP_HALF_LIFE_S, 0.001)), 0.0, 1.0)
	_render_position = _render_position.lerp(net_position, weight)
	rotation.y = lerp_angle(rotation.y, net_yaw, weight)

	# Driven through `move_and_slide()` rather than by assigning the transform,
	# for `remote_trainer.gd`'s measured reason: a body whose position is only
	# assigned never gets floor contact, and the animation layer reads real
	# planar velocity.
	var to := _render_position - global_position
	velocity = to / maxf(delta, 0.0001)
	move_and_slide()
	if _animator != null:
		_animator.call("tick", delta, Vector2(velocity.x, velocity.z).length(), _speed)
