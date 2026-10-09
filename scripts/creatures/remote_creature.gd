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
##
## ## Stage B lane 6.D: the picture of somebody else's fight
##
## Position and yaw made this body MOVE like a creature. It still died silently:
## a blow that lands on it, the fall that ends it, and the level it just gained
## are all things only its owner's process knows, so on every other peer the
## friend's creature took damage with no spark, no flash and no sound. Nothing
## here can listen for them -- there is no combat manager in this process
## driving THIS creature, and the encounter record only reaches the participants
## of that fight, so a bystander has nothing to read either.
##
## So the owner publishes. `_push_from_local_creature()` already samples the
## owner's real body every physics frame; it now also samples the numbers the
## HOST wrote onto that creature (its hit points, whether it has fallen, its
## level) and, when one of them moves, sends the DIFFERENCE as a presentation
## event. Every other peer draws it through `scripts/net/remote_presentation.gd`.
## The picture decides nothing: see that file's header for the rule and why the
## owner is the only process that can honestly publish it.

const GROUP := &"remote_creature"

const PRESENTATION := preload("res://scripts/net/remote_presentation.gd")
const PRESENCE := preload("res://scripts/creatures/companion_presence.gd")

## Smoothing half-life for the rendered position, and the gap past which the
## difference is a teleport rather than late packets. Same numbers and same
## reasoning as `remote_trainer.gd`; a creature is a little wider than a
## trainer, so the snap threshold is a metre more generous.
const INTERP_HALF_LIFE_S := 0.08
const SNAP_M := 6.0

## How far the body may sit from its owner's published position ON THE GROUND
## PLANE before that position is taken directly. Generous enough that ordinary
## interpolation and floor sliding are untouched, tight enough that the host
## never resolves a shared strike from the wrong side of an opponent.
const LATERAL_TOLERANCE_M := 0.35

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
var net_aquatic: Dictionary = {}
## The existing owner synchronizer carries input and a prediction reference.
## Position is never an authorization to move the host body during combat.
var net_combat_motion: Dictionary = {}
var _motion_scope: Dictionary = {}
var _motion_sequence := 0
var _motion_ack := 0
var _motion_received := 0
var _motion_input := Vector3.ZERO
var _motion_correction: Dictionary = {}
var aquatic := preload("res://scripts/player/swim_state.gd").new()

## The trainer body this creature belongs to, so the companion layer has
## somebody to look at and stand still beside. Resolved lazily from the
## `remote_trainer` group by owner id rather than handed in at spawn, because a
## creature proxy can be stood up before its owner's trainer body exists.
var leader: Node3D = null

## Lane 6.D. A presentation event was drawn on this body. `payload` is the one
## `remote_presentation.gd` was handed. Emitted on the VIEWER, never on the
## owner's own invisible proxy, and counted in `presentation_plays` so a smoke
## can assert that a friend's fight produced a picture here without judging what
## it looked like.
signal presentation_played(kind: String, payload: Dictionary)

var presentation_plays: int = 0
var last_presentation: String = ""
## The NAME of the effect node the last drawn event spawned, or "" when that
## kind spawns none. Recorded rather than looked for afterwards, and the first
## run of `tests/smoke_net_hearts.gd` is why: every one of these effects is a
## fraction of a second long and frees itself, so a test that waits for the
## packet to land and then scans the scene for a spark finds an empty parent and
## reports "the hook never fired". The name is the durable proof that a node
## really was built.
var last_effect: String = ""

var _render_position: Vector3 = Vector3.ZERO
var _has_render: bool = false
## `null` until the first evaluation, so the first pass always applies. See
## this file's header for why it is re-read rather than cached at `_ready()`.
var _owned_here: Variant = null
var _layer: int = 0
var _mask: int = 0
## Owner side: the last sample of the numbers this body is allowed to publish.
## Empty until the first tick, and `remote_presentation.diff()` reports nothing
## against an empty sample -- so joining a fight already in progress never
## fires a spark for damage that landed before anyone was watching.
var _sampled: Dictionary = {}
## Viewer side: the companion layer riding this body, or null on the owner's own
## proxy (which is invisible, and whose real creature has a `Presence` of its
## own through `follower_creature.gd`).
var _presence: Node = null
## Owner side: this world's `CombatManager`, resolved lazily. Never touched on a
## viewer -- that manager is running the local player's fight, not this
## creature's.
var _combat: Node = null
## Owner side: this world's `EncounterDirector`, resolved lazily. Read for one
## thing only -- which creature instance the local deployed body stands for.
var _director: Node = null


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


func setup(id: String, is_shiny: bool = false) -> void:
	# A host-authorized switch keeps this node but starts a new creature sample.
	# Comparing two owned creatures' HP would invent damage or level feedback.
	_sampled.clear()
	super.setup(id, is_shiny)


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
	_apply_presence(mine)


## Lane 6.D. A body this process DRAWS gets the companion layer; the owner's own
## invisible proxy does not, because the owner's real `follower_creature.gd`
## body already carries one and two reacting to the same creature is one
## creature reacting twice.
func _apply_presence(mine: bool) -> void:
	if mine:
		if _presence != null and is_instance_valid(_presence):
			_presence.queue_free()
		_presence = null
		return
	if _presence != null and is_instance_valid(_presence):
		return
	_presence = PRESENCE.new()
	_presence.name = "Presence"
	add_child(_presence)
	_presence.call("setup", self)
	_presence.call("set_remote", true)


## The companion layer's `blocked_reason()` needs somebody to stand beside. A
## creature proxy can be stood up before its owner's trainer body exists, so the
## answer is resolved on demand and re-resolved if that body goes away.
func _resolve_leader() -> void:
	if leader != null and is_instance_valid(leader):
		return
	leader = null
	if owner_peer_id == 0 or not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for body in tree.get_nodes_in_group(&"remote_trainer"):
		if body is Node3D and is_instance_valid(body) \
				and int((body as Node3D).get("peer_id")) == owner_peer_id:
			leader = body as Node3D
			return


func _physics_process(delta: float) -> void:
	_apply_ownership()
	if bool(_owned_here):
		_push_from_local_creature(delta)
		return
	_follow(delta)


# --- the owner's side ---------------------------------------------------------

## Copy the owner's real deployed body. Deliberately reads the
## `deployed_creature` group rather than reaching into the encounter director:
## the same decoupling `playground_hud.gd` keeps, and it survives a world that
## mounts its director somewhere else.
func _push_from_local_creature(delta: float = 0.0) -> void:
	var body := _local_deployed_body()
	if body == null:
		return
	if _director == null or not is_instance_valid(_director):
		_director = PRESENTATION.find_encounter_director(self)
	var sample: Dictionary = _director.call("local_combat_motion_sample", body, delta) if _director != null else {}
	if sample.is_empty():
		net_combat_motion = {}
		_motion_scope = {}
		_motion_ack = 0
	else:
		if sample.scope != _motion_scope:
			_motion_scope = sample.scope.duplicate(true)
			_motion_sequence = 0
			_motion_ack = 0
		_motion_sequence += 1
		sample["sequence"] = _motion_sequence
		sample["correction_ack"] = _motion_ack
		net_combat_motion = sample
	net_position = body.global_position
	net_yaw = body.rotation.y
	net_aquatic = body.get_meta("water_aquatic", {}).duplicate(true)
	# Keep the proxy co-located with the body it mirrors: nothing renders it
	# here, but a probe or a distance check that finds this node must not see a
	# body parked where it spawned.
	global_position = net_position
	rotation.y = net_yaw
	_ensure_combat_link()
	_publish_presentation()


## Owner side only. The one moment with no number to sample: the fight ended in
## a win, which is what the companion layer celebrates. `exited` is emitted on
## every participant when `combat_manager.gd` finishes resolving -- on a client
## because the host's record said the fight was over -- so what crosses the wire
## here is a picture of the host's verdict, never a verdict.
func _ensure_combat_link() -> void:
	if _combat != null and is_instance_valid(_combat):
		return
	_combat = PRESENTATION.find_combat_manager(self)
	if _combat == null:
		return
	if not _combat.is_connected("exited", _on_local_combat_exited):
		_combat.connect("exited", _on_local_combat_exited)


func _on_local_combat_exited(outcome: String) -> void:
	if outcome != "won" and outcome != "caught":
		return
	broadcast_presentation(PRESENTATION.KIND_VICTORY, {"outcome": outcome})


## Lane 6.D, owner side. Sample the numbers the host has already written onto
## the creature this body stands for, and publish what moved.
##
## The instance is the director's `ally_instance()` -- the object the local
## deployed body was built around, and the same one `combat_manager.gd` damages
## whether the blow was rolled here (the host) or delivered by
## `apply_host_enemy_hit` (a client). So every number that leaves this function
## is host truth that has already landed; nothing is decided here and nothing is
## rolled here.
func _publish_presentation() -> void:
	var creature: Variant = _local_creature_instance()
	var announced := str(get_meta(&"creature_uid", ""))
	if not announced.is_empty() and (creature == null or str(creature.get("uid")) != announced):
		_sampled.clear()
		return
	var after: Dictionary = PRESENTATION.sample(creature)
	var before := _sampled
	_sampled = after
	for raw: Variant in PRESENTATION.diff(before, after):
		var event: Dictionary = raw
		broadcast_presentation(str(event.get("kind", "")), event)


## The instance this proxy's owner has out.
##
## The director first, and `Game.party.active()` only as the fallback -- which
## is the opposite of the obvious order, and the first run of
## `tests/smoke_net_hearts.gd` is why: `adopt_starter()` stands a body on a fresh
## instance WITHOUT adding it to the party, so `active()` is null through the
## whole opening and the sampler published nothing. See
## `remote_presentation.gd::find_encounter_director()`.
##
## The position half of this file still deliberately reads the
## `deployed_creature` group rather than the director (see
## `_local_deployed_body()`): a body's position is a fact about the body, and
## which INSTANCE it stands for is not.
func _local_creature_instance() -> Variant:
	if _director == null or not is_instance_valid(_director):
		_director = PRESENTATION.find_encounter_director(self)
	if _director != null and _director.has_method("ally_instance"):
		var instance: Variant = _director.call("ally_instance")
		if instance != null:
			return instance
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return null
	var party: Variant = game.get("party")
	if party == null or not (party as Object).has_method("active"):
		return null
	return (party as Object).call("active")


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

## One current scope/correction on the existing body, not another action or
## distance ledger. Scope replacement retires old input, impulses and ACKs.
func bind_host_combat_motion(scope: Dictionary) -> bool:
	if scope == _motion_scope: return false
	_motion_scope = scope.duplicate(true)
	_motion_received = 0
	_motion_input = Vector3.ZERO
	_motion_correction = {}
	_impulse = Vector3.ZERO
	velocity = Vector3.ZERO
	cancel_combat_burst()
	return true


func host_combat_motion_correction() -> Dictionary:
	return _motion_correction.duplicate(true)


func apply_owner_combat_correction(projection: Dictionary, body: Node3D) -> void:
	if not is_multiplayer_authority() or not is_instance_valid(body) or _director == null \
		or not _director.call("_guest_combat_motion_current", projection.get("scope", {}), body): return
	var scope: Dictionary = projection.scope
	if scope != _motion_scope:
		_motion_scope = scope.duplicate(true)
		_motion_sequence = 0
		_motion_ack = 0
	var correction: Dictionary = projection.get("correction", {})
	if correction.is_empty(): return
	var sequence: Variant = correction.get("sequence")
	var accepted: Variant = correction.get("position")
	var reference: Variant = correction.get("sample_position")
	if not sequence is int or sequence <= _motion_ack or sequence > _motion_sequence \
		or not accepted is Vector3 or not reference is Vector3 \
		or not accepted.is_finite() or not reference.is_finite(): return
	# Keep prediction made AFTER the acknowledged sample. Applying the raw
	# older host position here would repeatedly erase one network trip of input.
	teleport_body(body, body.global_position + (accepted as Vector3) - (reference as Vector3))
	_motion_ack = sequence


func _follow_combat(delta: float) -> bool:
	if _director == null or not is_instance_valid(_director):
		_director = PRESENTATION.find_encounter_director(self)
	if _director == null: return false
	var context: Dictionary = _director.call("host_combat_motion_context", owner_peer_id, self)
	if context.get("combat") != true:
		if not _motion_scope.is_empty():
			bind_host_combat_motion({})
			set_contact_partner(null)
			arena = null
			collision_layer = _layer
		return false
	if context.get("valid") != true:
		_motion_input = Vector3.ZERO
		velocity = Vector3.ZERO
		return true
	var changed := bind_host_combat_motion(context.scope)
	collision_layer = 1 # Same combat layer as the owner's follower body.
	if contact_partner != context.opponent: set_contact_partner(context.opponent, CONTACT_SPACING.ROLE_ALLY)
	arena = context.arena
	var sample := net_combat_motion
	var fresh := false
	var reference := global_position
	var sequence: Variant = sample.get("sequence")
	var direction: Variant = sample.get("direction")
	var position: Variant = sample.get("position")
	var yaw: Variant = sample.get("yaw")
	var valid: bool = sample.size() == 6 and sample.get("scope") == _motion_scope \
		and sequence is int and sequence > 0 and direction is Vector3 and direction.is_finite() \
		and absf(float(direction.y)) <= 0.000001 and direction.length_squared() <= 1.000001 \
		and position is Vector3 and position.is_finite() and (yaw is int or yaw is float) and is_finite(float(yaw)) \
		and sample.get("correction_ack") is int
	if not valid:
		_motion_input = Vector3.ZERO
	elif sequence > _motion_received and sample.correction_ack == int(_motion_correction.get("sequence", 0)):
		_motion_received = sequence
		_motion_input = direction
		reference = position
		fresh = true
	elif sequence < _motion_received or int(sample.correction_ack) > int(_motion_correction.get("sequence", 0)):
		_motion_input = Vector3.ZERO
	# An outstanding correction cannot admit a replacement input. Existing
	# accepted input and authored Burst/impulse still advance on host physics.
	if context.paused != true:
		request_move(_motion_input if context.walking == true else Vector3.ZERO, float(context.speed))
		super._physics_process(delta)
	_render_position = global_position
	_has_render = true
	if fresh:
		_motion_correction = {"sequence":_motion_received, "position":global_position, "sample_position":reference}
	if fresh or changed: _director.call("publish_host_combat_motion", owner_peer_id, self)
	if _presence != null and is_instance_valid(_presence):
		_resolve_leader()
		_presence.call("tick", delta)
	return true

## Whether this proxy must be PLACED at `target` rather than driven toward it.
##
## The render target is interpolated toward `net_position` every frame, but the
## body is moved with `move_and_slide()`, so the world can stop the BODY while
## `_render_position` goes on tracking the owner perfectly. Once that happens
## nothing recovers it: the render target stays within one lerp of the owner's
## position, so a snap test that only compares `_render_position` to
## `net_position` never fires again, and the body stays wherever it snagged.
##
## On a creature that is not cosmetic. `encounter_director.gd::_host_strike()`
## resolves the protocol's own step-2 geometry from `striker.call("centre")` --
## THIS body's `global_position` on the host -- and then scores the swing with
## `_connects_now_or_recently()`. A snagged proxy therefore makes the host
## ACCEPT a guest's strike, with a valid receipt on the right encounter and the
## right peer id, and resolve it as `hit = false` against a creature it is
## holding somewhere else entirely. Measured in MEADOWS-PAYOFFS/tournament: a
## guest seated 1.4 m from the opponent was held 8.86 m away by the host after
## 28 placements, 0 of 6 swings landing, while every host swing landed first
## try. MEADOWS-PAYOFFS/river-sela-mill reproduced the same zero-damage result
## through ordinary movement input rather than placement.
##
## So the body's OWN divergence from the owner is a snap condition too. Hard
## placement is already this function's answer to a teleport; a proxy the world
## has pinned is the same problem arriving slowly, and the owner's real body is
## where `net_position` says regardless.
static func needs_snap(render_position: Vector3, body_position: Vector3,
		target: Vector3, snap_m: float) -> bool:
	return render_position.distance_to(target) > snap_m \
		or body_position.distance_to(target) > snap_m


## Teleport a kinematic body without a kinematic sweep. Setting
## `global_position` on a CharacterBody3D is taken by the physics server as one
## kinematic motion across the whole jump, which stretches the body's cached
## shape bounds along it; the next `move_and_slide()` then queries collision
## over those stretched bounds -- against Terrain3D's heightmap that measured
## about 2.9 s for a 3.5 km snap to Deep Watch and starved a host's heartbeat.
## Committing the new transform while the body is briefly STATIC makes it an
## instant jump.
static func teleport_body(body: PhysicsBody3D, at: Vector3) -> void:
	body.global_position = at
	if not body.is_inside_tree():
		return
	var rid := body.get_rid()
	var mode := PhysicsServer3D.body_get_mode(rid)
	if mode != PhysicsServer3D.BODY_MODE_KINEMATIC:
		return
	PhysicsServer3D.body_set_mode(rid, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, body.global_transform)
	PhysicsServer3D.body_set_mode(rid, mode)
	PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, body.global_transform)


## Put the body where its owner says it is, whenever physics has lost it.
##
## `move_and_slide()` is how this proxy gets floor contact and a real planar
## velocity for the animator, and that is worth keeping. What it also does is
## let anything with a collision shape -- the opponent, the other player's
## creature, a rock -- stop this body short of where its owner actually is. The
## proxy keeps its collision MASK (see `_ready()`), so it collides against the
## world even though nothing collides with it.
##
## That is not cosmetic. `encounter_director.gd::_host_strike()` resolves the
## protocol's step-2 geometry from THIS body on the host, so a proxy held short
## makes the host score a peer's swing from the wrong place.
##
## Measured, with the owner's published position read straight off the wire on
## the receiving peer (`ralph/reports/MEADOWS-PAYOFFS/proxy-ground-plane`):
##
##     own        = (-24.52, 1.20, -20.97)   the owner's real creature
##     host_net   = (-24.52, 1.20, -20.97)   what this peer RECEIVED -- exact
##     host_holds = (-25.69, 1.20, -21.88)   where this peer was HOLDING it
##
## Replication was perfect to the centimetre and the follow was 1.4-2.3 m out,
## never converging. Note the height already agreed exactly, every sample: the
## error is purely lateral, which is why an earlier attempt that snapped the
## whole vector made it WORSE -- forcing y fought gravity and the body
## oscillated between 1.2 m and 3.7 m.
##
## So take the lateral position, which is authoritative and arrives correct,
## and leave the vertical to the floor query that was doing its job.
func _hold_replicated_ground_plane() -> void:
	var here := global_position
	var lateral_error := Vector2(_render_position.x - here.x, _render_position.z - here.z)
	if lateral_error.length() <= LATERAL_TOLERANCE_M:
		return
	# The OWNER's whole position, height included. Correcting only the ground
	# plane was measured next and was worse in a new way: pinned laterally every
	# frame, the body climbed whatever was blocking it and sat 3.44 m in the air
	# (own y 1.20, this peer 4.64) while x and z matched exactly. The owner has
	# already done its own ground query for this creature -- its height agreed
	# with this peer's to the centimetre in every sample before any of this --
	# so there is nothing left for a floor query here to contribute except a
	# fight it loses.
	#
	# `move_and_slide()` above still runs, and still gives the animator the real
	# planar velocity it reads. Only the resting place is taken.
	global_position = _render_position
	velocity = Vector3.ZERO


func _follow(delta: float) -> void:
	if _follow_combat(delta): return
	if not net_aquatic.is_empty():
		aquatic.owner_peer_id = get_multiplayer_authority()
		aquatic.apply_remote_snapshot(net_aquatic, get_multiplayer_authority())
	if not _has_render:
		_render_position = net_position
		_has_render = true
	if needs_snap(_render_position, global_position, net_position, SNAP_M):
		_render_position = net_position
		teleport_body(self, net_position)
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
	_hold_replicated_ground_plane()
	if _animator != null:
		_animator.call("tick", delta, Vector2(velocity.x, velocity.z).length(), _speed)
	if _presence != null and is_instance_valid(_presence):
		# After the follow step and before the next frame's, which is the order
		# `follower_creature.gd` ticks its own: the presence layer's only
		# gameplay effect is on the model pivot, and it must read the velocity
		# this frame actually produced.
		_resolve_leader()
		_presence.call("tick", delta)


# --- lane 6.D: the presentation channel -------------------------------------------

## Publish one presentation event about THIS body to every other peer.
##
## Only the owner may call it (an `authority` RPC is refused at the far end
## otherwise), and it draws nothing here: the owner's proxy is invisible and the
## owner's real body already played the picture locally. Solo, and in a session
## of one, this is a no-op with nobody to tell -- and `_can_present()` is what
## keeps it one, because with no session at all `is_multiplayer_authority()` is
## true for every node and `rpc()` on an `OfflineMultiplayerPeer` is an error.
func broadcast_presentation(kind: String, payload: Dictionary = {}) -> void:
	if not PRESENTATION.is_kind(kind) or not bool(_owned_here):
		return
	if not _can_present():
		return
	rpc("_rpc_presentation", kind, payload)


## Owner -> everybody else. Presentation only; see `remote_presentation.gd`.
@rpc("authority", "call_remote", "reliable")
func _rpc_presentation(kind: String, payload: Dictionary) -> void:
	play_presentation(kind, payload)


## Draw one event on this body. Public so a headless test can drive it without
## a session; the counter and the signal are the assertion.
func play_presentation(kind: String, payload: Dictionary = {}) -> Node:
	if not PRESENTATION.is_kind(kind):
		return null
	presentation_plays += 1
	last_presentation = kind
	var spawned := PRESENTATION.play(self, kind, payload)
	last_effect = str(spawned.name) if spawned != null else ""
	presentation_played.emit(kind, payload)
	return spawned


func _can_present() -> bool:
	if not is_inside_tree():
		return false
	var api := multiplayer
	if api == null or not api.has_multiplayer_peer():
		return false
	var game := get_node_or_null(^"/root/Game")
	return game != null and bool(game.call("is_multi_peer"))
