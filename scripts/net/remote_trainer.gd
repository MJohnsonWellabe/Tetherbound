extends CharacterBody3D

## D101 -- the body another peer's trainer wears in THIS process.
##
## One of these exists per peer in the session, on every peer, under
## `<world>/Spawned/Trainers` (D97's authored container). It is deliberately
## NOT a second player: no camera, no input, no `player_controller.gd`. It has
## a model, an animation state, a nameplate and a `MultiplayerSynchronizer`.
##
## ## Authority and direction of flow
##
## `trainer_spawn.gd::_spawn_trainer()` sets this node's multiplayer authority
## to the peer it represents, INSIDE the spawn function and before the node
## enters the tree. That ordering is not stylistic: the ENet spike
## (`ralph/reports/MP-0C-SPIKE-ENET-0905/REPORT.md`, item 3) found that setting
## authority after tree entry raises nothing at all and silently changes it on
## the calling peer only, because authority is not a replicated property.
##
## So on the peer that OWNS this body, `_physics_process` copies the local
## rig's state into the replicated `net_*` properties and does nothing else --
## the body is the owner's outbound proxy, invisible and non-colliding on the
## owner's own screen because the owner already has a local rig standing in
## the same place. On every OTHER peer the same node reads those properties
## and walks the body toward them.
##
## ## Why the remote body is a CharacterBody3D that actually moves
##
## `trainer_model.gd` -- the same script the local rig uses, so a remote
## trainer looks like a trainer rather than like a capsule -- reads
## `_player.is_on_floor()`, `_player.velocity` and calls `ground_speed()` and
## `is_sprinting()` on its player. A body whose `global_position` is merely
## assigned never calls `move_and_slide()`, so `is_on_floor()` stays false
## forever and the remote trainer plays the falling clip for the whole
## session. Driving the body with a velocity that closes the gap to the
## interpolated target, through `move_and_slide()`, gives genuine floor
## contact, genuine planar velocity for the model's lean, and interpolation in
## the same step.

## ## Stage B lane 6.D: the picture of somebody else's catch
##
## A trainer body that walked around in silence is the same defect
## `remote_creature.gd`'s header describes, from the trainer's side: sealing a
## catch throws a sparkle on the local player's screen and nothing at all on
## their friend's. The owner publishes it here, as a presentation event, and
## every other peer draws it on this body through
## `scripts/net/remote_presentation.gd`. It decides nothing -- by the time this
## body hears about a catch, the host's `catch_arbiter` has already said whose
## it was.

const GROUP := &"remote_trainer"

const PRESENTATION := preload("res://scripts/net/remote_presentation.gd")

## Smoothing half-life for the remote's rendered position. Small enough that a
## walking trainer is never further behind than lane 2.C's own "seen" budget
## (1.5 m at rest, 4.0 m in motion, `tests/smoke_net_movement_two_peers.gd`),
## large enough that a dropped packet is not a visible stutter.
const INTERP_HALF_LIFE_S := 0.08
## Past this the gap is a teleport (a respawn, a relocation, a first frame
## after spawn), not late packets. Lerping across it would drag the body
## through the world at absurd speed and let `move_and_slide()` wedge it in
## geometry, so snap instead.
const SNAP_M := 5.0
## Below this the body is standing, not walking. Matches the threshold
## `trainer_model.gd::_role_for_state()` uses on the local rig.
const IDLE_SPEED := 0.15

## Set by the spawn function from the spawn data, on every peer, before the
## node enters the tree. Not replicated per-frame: they never change.
@export var peer_id: int = 0
@export var character_id: String = ""
@export var display_name: String = ""

## The replicated set (lane 2.C deliverable 4): position, yaw, animation
## state, sprint, carried. Authored into the synchronizer's
## `SceneReplicationConfig` in `remote_trainer.tscn`.
var net_position: Vector3 = Vector3.ZERO
var net_yaw: float = 0.0
var net_anim_state: String = "idle"
var net_sprinting: bool = false
var net_carried: bool = false

## Lane 6.D. A presentation event was drawn on this body. Emitted on the VIEWER,
## never on the owner's own invisible proxy, and counted in `presentation_plays`
## so a smoke can assert that a friend's catch produced a picture here without
## judging what it looked like.
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
## Whether this process is this body's authority. Re-read every physics frame
## rather than cached once in `_ready()`, and that is deliberate. Authority is
## a plain integer compared against `multiplayer.get_unique_id()`, and that id
## CHANGES under a node's feet: a process with no session runs on Godot's
## default `OfflineMultiplayerPeer`, where the id is 1, and it becomes a large
## random number the moment `Session.join()` installs a real peer. A body that
## decided once at `_ready()` whether it was its own would keep a stale answer
## across that swap — invisible forever, pushing the wrong rig's state. `null`
## until the first evaluation so the first pass always applies.
var _owned_here: Variant = null
var _ground_speed: float = 0.0
## Owner side: this world's `CombatManager`, resolved lazily. Never touched on a
## viewer -- that manager is running the local player's fight, not this
## trainer's.
var _combat: Node = null
## The authored collision setup, kept so the owner-side body can give it back
## if authority ever moves to another peer.
var _layer: int = 0
var _mask: int = 0


func _ready() -> void:
	add_to_group(GROUP)
	_layer = collision_layer
	_mask = collision_mask
	net_position = global_position
	_render_position = global_position
	_has_render = true
	# Ownership FIRST. `_owned_here` starts as `null` to mean "not yet asked",
	# and `bool(null)` is not a falsy read in Godot 4.7 -- it is
	# `Invalid call. Nonexistent 'bool' constructor.`, a script error printed on
	# every single trainer spawn. Nameplating before asking who owns the body
	# hit exactly that, harmlessly (the very next line re-applied it with a real
	# bool) but noisily. `_apply_ownership()` calls `_apply_nameplate()` itself,
	# so this ordering does strictly less work as well as being correct.
	#
	# Found by lane 5.B on the untouched base and left alone there rather than
	# drive-by-edited during a five-lane wave; fixed here at integration.
	_apply_ownership()
	print("[trainers] %s stands up: authority %d, this peer is %d (%s)"
		% [name, get_multiplayer_authority(), multiplayer.get_unique_id(),
			"our own proxy" if _owned_here == true else "another player"])


## Apply everything that depends on WHOSE body this is. Idempotent, and called
## again whenever the answer changes.
func _apply_ownership() -> void:
	var mine := is_multiplayer_authority()
	if _owned_here != null and bool(_owned_here) == mine:
		return
	_owned_here = mine
	if mine:
		# The owner already has a local rig standing in this spot. Drawing a
		# second trainer inside it, and colliding with it, is the classic
		# "my own body shoves me around" bug.
		visible = false
		collision_layer = 0
		collision_mask = 0
	else:
		visible = true
		collision_layer = _layer
		collision_mask = _mask
	_apply_nameplate()


## The nameplate reads the registry's display name, defensively: the peer
## registry is lane 2.A's and may not have a row yet (a spawn can beat the
## registry replication by a frame), and in solo there is no registry at all.
## An unnamed trainer is a trainer with a placeholder over their head, never a
## crash and never a blank plate.
func _apply_nameplate() -> void:
	var plate := get_node_or_null(^"Nameplate") as Label3D
	if plate == null:
		return
	var shown := display_name.strip_edges()
	if shown.is_empty():
		shown = "Trainer %d" % peer_id if peer_id != 0 else "Trainer"
	plate.text = shown
	# `== true` rather than `bool()`: this can be reached before ownership has
	# been asked, and `bool(null)` is a script error rather than a false.
	plate.visible = not (_owned_here == true)


## Late name arrival: `trainer_spawn.gd` calls this when the registry finally
## carries a display name for this peer.
func set_display_name(value: String) -> void:
	display_name = value
	_apply_nameplate()


func _physics_process(delta: float) -> void:
	_apply_ownership()
	if bool(_owned_here):
		_push_from_local_rig()
		return
	_follow(delta)


# --- the owner's side --------------------------------------------------------

func _push_from_local_rig() -> void:
	var rig := _local_rig()
	if rig == null:
		return
	net_position = rig.global_position
	net_yaw = rig.rotation.y
	net_sprinting = _bool_call(rig, &"is_sprinting")
	net_carried = _bool_call(rig, &"is_carried")
	net_anim_state = _state_of(rig)
	# Keep the proxy co-located with the rig it mirrors. Nothing renders it
	# here, but a probe or a distance check that finds this node should not see
	# a body parked at the origin.
	global_position = net_position
	_ensure_combat_link()


# --- lane 6.D: the presentation channel -------------------------------------------

## Owner side only. `catch_resolved` fires on the peer that threw the orb; in a
## session its `success` came back from the host (`apply_host_catch_verdict`),
## so what is published is a picture of the arbiter's answer, never an answer.
func _ensure_combat_link() -> void:
	if _combat != null and is_instance_valid(_combat):
		return
	_combat = PRESENTATION.find_combat_manager(self)
	if _combat == null:
		return
	if not _combat.is_connected("catch_resolved", _on_local_catch_resolved):
		_combat.connect("catch_resolved", _on_local_catch_resolved)


func _on_local_catch_resolved(success: bool, _shakes: int) -> void:
	if not success:
		# A failed catch is the creature breaking out, which is a picture on the
		# CREATURE, not on the trainer. This lane does not invent one for it.
		return
	broadcast_presentation(PRESENTATION.KIND_CATCH)


## Publish one presentation event about THIS body to every other peer.
##
## Only the owner may call it (an `authority` RPC is refused at the far end
## otherwise), and it draws nothing here: the owner's proxy is invisible and the
## owner's own screen already showed the picture. `_can_present()` is what keeps
## solo a no-op -- with no session `is_multiplayer_authority()` is true for every
## node and `rpc()` on an `OfflineMultiplayerPeer` is an error, which is the trap
## this file's authority comment already warns about from the other side.
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


## Draw one event on this body. Public so a headless test can drive it without a
## session; the counter and the signal are the assertion.
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


## The rig the LOCAL peer drives, through the one door D101 names. Falls back
## to the `local_player` group when `Game` is unreachable (a bare-scene test
## that never mounted the autoload), and never returns a remote body: the
## group is authored only on `scenes/player/local_rig.tscn`.
func _local_rig() -> Node3D:
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("local_player"):
		var rig := game.call("local_player") as Node3D
		if rig != null and is_instance_valid(rig):
			return rig
	if is_inside_tree():
		var tree := get_tree()
		if tree != null:
			return tree.get_first_node_in_group(&"local_player") as Node3D
	return null


static func _bool_call(node: Object, method: StringName) -> bool:
	if node == null or not node.has_method(method):
		return false
	return bool(node.call(method))


## The animation state the owner is actually in, named rather than re-derived
## on each viewer. `trainer_model.gd::_role_for_state()` picks the same five
## states from the same three facts; replicating the STATE rather than the
## facts means a remote never plays a walk cycle because its own floor query
## happened to disagree with the owner's.
static func _state_of(rig: Node3D) -> String:
	if _bool_call(rig, &"is_carried"):
		return "carried"
	if rig.has_method("is_on_floor") and not bool(rig.call("is_on_floor")):
		var vy: float = 0.0
		var v: Variant = rig.get("velocity")
		if v is Vector3:
			vy = (v as Vector3).y
		return "jump" if vy > 0.0 else "fall"
	var speed: float = 0.0
	if rig.has_method("ground_speed"):
		speed = float(rig.call("ground_speed"))
	if speed <= IDLE_SPEED:
		return "idle"
	return "sprint" if _bool_call(rig, &"is_sprinting") else "walk"


# --- every other peer's side -------------------------------------------------

func _follow(delta: float) -> void:
	if not _has_render:
		_render_position = net_position
		_has_render = true
	if _render_position.distance_to(net_position) > SNAP_M:
		# A teleport, not late packets. See SNAP_M.
		_render_position = net_position
		global_position = net_position
		velocity = Vector3.ZERO
		_ground_speed = 0.0
		rotation.y = net_yaw
		return

	var weight := clampf(1.0 - exp(-delta / maxf(INTERP_HALF_LIFE_S, 0.001)), 0.0, 1.0)
	_render_position = _render_position.lerp(net_position, weight)
	rotation.y = lerp_angle(rotation.y, net_yaw, weight)

	if net_carried:
		# A carried trainer's transform belongs to whatever carries them; do
		# not fight it with a floor query. `player_controller.gd` runs no
		# locomotion while carried either.
		global_position = _render_position
		velocity = Vector3.ZERO
		_ground_speed = 0.0
		return

	var to := _render_position - global_position
	velocity = to / maxf(delta, 0.0001)
	move_and_slide()
	_ground_speed = Vector2(velocity.x, velocity.z).length()


# --- what `trainer_model.gd` asks a player for -------------------------------

## Deliberately the same names `player_controller.gd` exposes, because
## `trainer_model.gd` is shared between the two and calls them by name.
func ground_speed() -> float:
	if net_anim_state == "idle":
		return 0.0
	return _ground_speed


func is_sprinting() -> bool:
	return net_sprinting


func is_carried() -> bool:
	return net_carried


func animation_state() -> String:
	return net_anim_state
