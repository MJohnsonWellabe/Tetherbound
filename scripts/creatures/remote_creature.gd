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
	var after: Dictionary = PRESENTATION.sample(_local_creature_instance())
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

func _follow(delta: float) -> void:
	if not net_aquatic.is_empty():
		aquatic.owner_peer_id = get_multiplayer_authority()
		aquatic.apply_remote_snapshot(net_aquatic, get_multiplayer_authority())
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
