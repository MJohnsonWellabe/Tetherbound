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
## Stage B lane 6.B/6.C. Riding and Fly are the two verbs that put a trainer
## somewhere their own legs did not take them, and both are drawn on a remote
## body out of these three files -- the saddle through the riding controller's
## own attach, the carrier bird through the fly controller's own builder, and
## the landing rule through the arbiter. Nothing here re-implements any of them.
const RIDING := preload("res://scripts/world/riding_controller.gd")
const FLY := preload("res://scripts/player/fly_controller.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ANCHOR_ARBITER := preload("res://scripts/net/fly_anchor_arbiter.gd")
const SWIM_STATE := preload("res://scripts/player/swim_state.gd")

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
## Wave 6 lane 6.A. The realm this body was spawned INTO, stamped by
## `trainer_spawn.gd::_spawn_trainer()` from the spawn data. Deliberately not
## replicated per-frame and deliberately not "the realm its owner is in": when
## the owner crosses a boundary the host despawns this body and spawns a new
## one in the destination, so this value is fixed for the body's whole life
## and a body whose realm disagrees with its owner's is a body that should
## already be gone.
@export var net_realm: String = ""

## The replicated set (lane 2.C deliverable 4): position, yaw, animation
## state, sprint, carried. Authored into the synchronizer's
## `SceneReplicationConfig` in `remote_trainer.tscn`.
var net_position: Vector3 = Vector3.ZERO
var net_yaw: float = 0.0
var net_anim_state: String = "idle"
var net_sprinting: bool = false
var net_carried: bool = false
var net_aquatic: Dictionary = {}
## Personal character level, owner-published like their equipment. The host
## recomputes the capped bonus; a throw intent never carries a catch bonus.
var net_catching_level: int = 0
var aquatic := SWIM_STATE.new()

## --- Stage B lane 6.B: one player is on their creature ------------------------
##
## `net_carried` above already said "this trainer is cargo" -- it is the flag
## `player_controller.set_carrier()` raises, and lane 2.C replicated it so a
## carried body would not fight a floor query. It was never enough to DRAW a
## ride, and the two things it was missing are the two below.
##
## Missing 1: which creature. A viewer that only knows "carried" has to guess,
## and the honest answer is not a guess at all -- the mount is this peer's own
## deployed creature, and every process already holds exactly one of those per
## owner (`remote_creature.gd::owner_peer_id`). So `net_riding` is the whole of
## what has to cross the wire; `_mount_body()` resolves the rest locally, by
## owner, and never by a node name.
##
## Missing 2: WHERE on the creature. The seat is the species' `mount_offset`
## and it is replicated rather than re-read from the data, because the offset a
## viewer draws must be the offset the owner is actually sitting at -- a body
## seated by two different readings of the same file is a rider who slides.
var net_riding: bool = false
var net_mount_offset: Vector3 = Vector3.ZERO
## Whether the owner's deployed creature is wearing the saddle its owner built.
## Published from the trainer rather than the creature because the creature
## proxy's replicated set is authored in `encounter_director.gd`, which this
## lane does not own -- and because "fitted" is a flag in the OWNER's
## progression store that no other process can read at all (OP-0904-3: what you
## built has to be visible on the animal).
var net_creature_saddled: bool = false

## --- Stage B lane 6.C: one player is in the air -------------------------------
##
## A flying trainer used to replicate as a trainer falling: `_state_of()` sees
## a body off the floor with no upward velocity and calls it "fall", and the
## viewer walked its copy into the ground with `move_and_slide()` because that
## is what a body with no fly state does. So a friend gliding over Cloudreach
## read, on every other screen, as a friend who had stepped off a cliff.
##
## `net_fly_state` is the controller's own state word, not a re-derivation:
## "glide", "climb", "descent", "exhausted". `net_fly_species` is the carrier,
## so every viewer builds the same bird from the same `fly_capability` block.
var net_flying: bool = false
var net_fly_state: String = ""
var net_fly_species: String = ""

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
## Viewer side, lanes 6.B/6.C. The last drawn value of each replicated flag, so
## the pose doors are only called when the answer changes; the mount and the
## carrier art, so neither is looked up or rebuilt every frame.
var _rode_last: bool = false
var _flew_last: bool = false
var _flew_species: String = ""
var _fly_seconds: float = 0.0
var _fly_capability: Dictionary = {}
var _carrier_art: Node3D = null
var _carrier_rig: Skeleton3D = null
var _mount: Node3D = null
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
	# Lane 6.B. Tick AFTER the creature bodies, which run at the default 0.
	#
	# A rider's drawn position is read off the mount (`_follow()`), so if this
	# body ticks first it reads where the animal was LAST frame and the rider
	# is drawn one frame of the mount's motion out of the saddle. Measured on
	# `tests/smoke_net_riding.gd`: 0.23-0.33 m adrift while the mount was being
	# driven, and 0.00 m the moment it stopped -- the signature of an ordering
	# problem rather than of interpolation. Priority is the honest fix; the
	# alternative is every reader of this body having to know it is stale.
	process_physics_priority = 1
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
	_push_ride(rig)
	_push_flight(rig)
	var swimming: Node = rig.get("swim_controller")
	net_aquatic = swimming.call("snapshot") if swimming != null else {}
	var skills_game := get_node_or_null("/root/Game")
	if skills_game != null and skills_game.get("local") != null:
		net_catching_level = int(skills_game.get("local").skills.level("catching"))
	# Keep the proxy co-located with the rig it mirrors. Nothing renders it
	# here, but a probe or a distance check that finds this node should not see
	# a body parked at the origin.
	global_position = net_position
	_ensure_combat_link()


# --- lane 6.B, owner side: what the ride looks like from outside ---------------

## Publish the ride. The mount itself is deliberately NOT published: it is this
## peer's own deployed creature, every process already holds exactly one of
## those per owner, and a replicated node reference would only be a second way
## to disagree about which body that is.
##
## The saddle is published whether or not a ride is in progress, and that is
## OP-0904-3's rule rather than an oversight: `riding_controller.gd`'s own
## header records that the saddle used to be attached on mount and torn off on
## dismount, which made the visible proof of the craft invisible in every
## moment a player would look at their creature. It is worn from the fit
## onwards, and that has to be true on a friend's screen too.
func _push_ride(rig: Node3D) -> void:
	var carrier: Node3D = null
	if rig.has_method("carrier"):
		carrier = rig.call("carrier") as Node3D
	var riding := carrier != null and is_instance_valid(carrier)
	net_riding = riding
	if riding and rig.has_method("carry_offset"):
		net_mount_offset = rig.call("carry_offset")
	var body := _local_deployed_body()
	# `saddle_is_fitted()` reads the LOCAL progression store, which is this
	# peer's own -- the only process that can answer the question at all.
	net_creature_saddled = body != null \
		and RIDING.saddle_is_fitted(str(body.get("species_id")))


## Publish the flight. `is_flying()` and `state` are the controller's own; the
## carrier species comes through its one public accessor, so a viewer builds
## the bird from the same capability block the owner is hanging off.
func _push_flight(rig: Node3D) -> void:
	var fly: Variant = rig.get("fly_controller")
	if fly == null or not (fly is Object) or not (fly as Object).has_method("is_flying"):
		net_flying = false
		net_fly_state = ""
		net_fly_species = ""
		return
	var controller := fly as Object
	net_flying = bool(controller.call("is_flying"))
	net_fly_state = str(controller.get("state")) if net_flying else ""
	net_fly_species = str(controller.call("carrier_species_id")) if net_flying else ""


## The creature body this peer has out, by group rather than through the
## encounter director -- the same decoupling `remote_creature.gd` keeps, and
## for its reason: a body's species is a fact about the body.
func _local_deployed_body() -> Node3D:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(&"deployed_creature"):
		if not is_instance_valid(node) or not (node is Node3D):
			continue
		if node.has_method("is_local_deployment") and bool(node.call("is_local_deployment")):
			return node as Node3D
	return null


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
	if not net_aquatic.is_empty():
		aquatic.owner_peer_id = get_multiplayer_authority()
		aquatic.apply_remote_snapshot(net_aquatic, get_multiplayer_authority())
	_apply_ride_and_flight(delta)
	if net_riding:
		var mount := _mount_body()
		if mount != null:
			# THE WHOLE OF LANE 6.B'S FIRST HALF: the rider and the mount are
			# one thing on this screen, because the rider's transform is READ
			# OFF the mount rather than interpolated toward a position that
			# happens to be near it.
			#
			# Two bodies each walking toward their own replicated target is two
			# bodies with two independent errors, and the error is largest
			# exactly when the mount is moving -- which is the whole time
			# anybody is watching. The result is a rider who floats a little
			# behind the animal, sinks into its shoulders on a turn and pops
			# back when it stops. `player_controller._ride()` does not have that
			# problem on the owner's screen for the same reason this does not
			# have it here: it takes the carrier's transform, not a copy of it.
			global_position = mount.to_global(net_mount_offset)
			_render_position = global_position
			velocity = Vector3.ZERO
			_ground_speed = 0.0
			# Face the way the mount faces, exactly as the local ride does --
			# on the MODEL, so the body's own yaw is still whatever the owner
			# last replicated and dismounting does not spin the trainer.
			var art := get_node_or_null(^"Model") as Node3D
			if art != null:
				art.global_rotation.y = mount.global_rotation.y
			return
		# No mount body yet (a creature spawn that has not landed, an owner
		# whose creature was despawned mid-ride). Fall through and interpolate
		# toward the replicated position, which is where the owner's rig is:
		# a rider drawn beside their animal for a frame beats a rider left
		# standing at the last place the animal was.
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

	if net_carried or net_flying or aquatic.mode != SWIM_STATE.Mode.LAND:
		# A carried trainer's transform belongs to whatever carries them; do
		# not fight it with a floor query. `player_controller.gd` runs no
		# locomotion while carried either.
		#
		# Lane 6.C adds flight to the same branch, and it is the same sentence:
		# a gliding trainer's transform belongs to the glide. Driving this body
		# with `move_and_slide()` toward a target hundreds of metres up a
		# Cloudreach face would push a ground-shaped capsule through whatever
		# it clipped on the way, and a flier who snags on a ledge nobody else
		# can see is worse than a flier who is simply where their owner says.
		global_position = _render_position
		velocity = Vector3.ZERO
		_ground_speed = 0.0
		return

	var to := _render_position - global_position
	velocity = to / maxf(delta, 0.0001)
	move_and_slide()
	_ground_speed = Vector2(velocity.x, velocity.z).length()


## The seat, re-applied after every physics tick in the frame has run.
##
## The second half of the ordering fix `_ready()`'s `process_physics_priority`
## is the first half of, and they cover different observers.
##
## Priority decides what anything reading this body DURING physics sees, and it
## is what took the measured seat error from 0.23 m to 0.00 m. This decides
## what the RENDERER sees: `_process` runs after every physics tick in the
## frame and before it is drawn, which is the moment a drawn position wants to
## be settled, and it holds even in a frame that carried no physics tick at all
## (a rendering frame between two ticks, which at 60 Hz physics and a faster
## display is most of them).
##
## It simulates nothing and owns nothing. `_follow()` is still where the ride
## is applied; deleting this function costs a frame of smoothness rather than
## the feature.
func _process(_delta: float) -> void:
	if _owned_here == true or not net_riding:
		return
	var mount := _mount_body()
	if mount == null:
		return
	global_position = mount.to_global(net_mount_offset)
	_render_position = global_position
	var art := get_node_or_null(^"Model") as Node3D
	if art != null:
		art.global_rotation.y = mount.global_rotation.y


# --- lanes 6.B/6.C, viewer side: the pictures ---------------------------------

## Everything about this body that is a PICTURE of the ride or the flight
## rather than a position: the seated pose, the saddle on the animal, the
## carrier bird overhead, the hanging pose under it.
##
## Driven off the replicated flags every frame rather than hooked to a
## transition, for `riding_controller.gd`'s own stated reason: a gate set once
## when something changed is a gate that is wrong the first time something else
## touches it -- and here the something else is real. A creature proxy is
## despawned and respawned by its owner, a body can arrive mid-ride from a
## `spawn = true` property, and a peer that joins while a friend is already in
## the air has never seen the transition at all. Each of the three doors below
## is idempotent, so asking every frame costs a comparison.
func _apply_ride_and_flight(delta: float) -> void:
	var art := get_node_or_null(^"Model")
	if net_riding != _rode_last:
		_rode_last = net_riding
		if art != null and art.has_method("set_riding"):
			# The owner's own trainer is posed by
			# `player_controller.set_carrier()`; this is the same door, called
			# from the same fact. Without it a remote rider stands bolt upright
			# on the creature's back -- which is OP-0904-3 exactly, the owner's
			# own riding bug, reopened on somebody else's screen.
			art.call("set_riding", net_riding)
	RIDING.set_worn_saddle(_mount_body(), net_creature_saddled)
	_apply_flight_art(art, delta)


## The carrier bird, and the trainer hanging off it.
##
## Built through `fly_controller.gd`'s own static builder, so a friend's
## carrier is the same model, the same height and the same wingbeat as the one
## its owner is looking up at. Rebuilt when the species changes and freed the
## moment the flight ends -- a bird left behind on a landed trainer is a bird
## that follows them around the meadow.
func _apply_flight_art(art: Node, delta: float) -> void:
	if net_flying:
		_fly_seconds += delta
	if net_flying == _flew_last and net_fly_species == _flew_species:
		if net_flying:
			FLY.pose_carrier_wings(_carrier_rig, _fly_capability, _fly_seconds)
			FLY.align_carrier_grip(_carrier_art, _carrier_rig, art,
				_fly_capability.get("grip_bones", []))
		return
	_flew_last = net_flying
	_flew_species = net_fly_species
	if is_instance_valid(_carrier_art):
		_carrier_art.queue_free()
	_carrier_art = null
	_carrier_rig = null
	_fly_capability = {}
	if art != null and art.has_method("set_fly_hang"):
		art.call("set_fly_hang", net_flying, FLY.hang_pose())
	if not net_flying:
		_fly_seconds = 0.0
		return
	_fly_capability = SPECIES.fly_capability(net_fly_species)
	_carrier_art = FLY.make_carrier_art(_fly_capability)
	if _carrier_art == null:
		return
	add_child(_carrier_art)
	_carrier_rig = FLY.carrier_skeleton(_carrier_art)


## The creature body this trainer is sitting on: the deployed proxy belonging
## to the SAME peer this body does. Resolved by owner id, never by node name --
## `encounter_director.gd` names those bodies and this file does not get a vote
## -- and re-resolved whenever the answer stops being valid, because a creature
## proxy outlives neither a dismiss nor a realm crossing.
func _mount_body() -> Node3D:
	if _mount != null and is_instance_valid(_mount):
		return _mount
	_mount = null
	if peer_id == 0 or not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	for body in tree.get_nodes_in_group(&"remote_creature"):
		if body is Node3D and is_instance_valid(body) \
				and int((body as Node3D).get("owner_peer_id")) == peer_id:
			_mount = body as Node3D
			return _mount
	return null


# --- lane 6.C: the host decides where a client may land -----------------------
#
# `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §2, applied to a landing.
# `scripts/net/fly_anchor_arbiter.gd`'s header carries the whole argument for
# why a Fly anchor is the same shape of problem as a strike; what lives here is
# only the transport, because this node is the one thing in the project that
# already exists once per peer, on every peer, with a path the host can address.
#
# Both directions are `any_peer` and both check the sender explicitly, rather
# than leaning on node authority. Authority here belongs to the CLIENT (it is
# that peer's body), so an `authority` reply from the host would be refused at
# the far end -- and an `any_peer` call that trusted whoever sent it would let
# any peer answer for the host. The sender id is checked in both.

## Client -> host. Called by this peer's own `fly_controller.gd` on its own
## outbound proxy. Silent in solo: `_can_present()` is the same "is there
## actually a session" guard the presentation channel uses, and with no session
## `rpc()` on an `OfflineMultiplayerPeer` is an error rather than a no-op.
func request_landing_anchor(claim: Vector3, realm: String) -> void:
	if not bool(_owned_here) or not _can_present():
		return
	rpc_id(1, "_rpc_request_landing_anchor",
		[claim.x, claim.y, claim.z], realm)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_landing_anchor(claim: Array, realm: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	var params := _anchor_params(sender, claim, realm)
	var answer: Dictionary = ANCHOR_ARBITER.verdict(params)
	var anchor: Vector3 = answer.get("anchor", Vector3.ZERO)
	print("[fly] peer %d claimed a landing at %s -- %s (%s)"
		% [sender, str(params.get("claim", Vector3.ZERO)),
			"granted" if bool(answer.get("ok", false)) else "refused",
			str(answer.get("code", ""))])
	if sender <= 0:
		return
	rpc_id(sender, "_rpc_landing_anchor_verdict", bool(answer.get("ok", false)),
		[anchor.x, anchor.y, anchor.z], str(answer.get("code", "")),
		str(answer.get("reason", "")))


## Everything the arbiter is handed, gathered here so the rule itself stays a
## pure function of numbers (see that file's header).
##
## The host's own position for this peer is `global_position`, NOT `net_position`
## -- and the difference is the whole point. `net_position` is what the client
## SAID; `global_position` is where the host's own `move_and_slide()` in
## `_follow()` has actually put this body against the host's own collision. §2's
## rule is that the host tests an intent against its own copy, so it is the
## host's copy that is read here.
func _anchor_params(sender: int, claim: Array, realm: String) -> Dictionary:
	var claimed := Vector3.ZERO
	if claim.size() == 3:
		claimed = Vector3(float(claim[0]), float(claim[1]), float(claim[2]))
	var config: Dictionary = FLY.landing_anchor_config()
	var ground_y := NAN
	var normal_y := 0.0
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space != null and claim.size() == 3:
		var depth: float = ANCHOR_ARBITER.probe_depth_m(config)
		var query := PhysicsRayQueryParameters3D.create(
			claimed + Vector3.UP * 2.0, claimed + Vector3.DOWN * depth,
			_mask, [get_rid()])
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			ground_y = (hit["position"] as Vector3).y
			normal_y = (hit["normal"] as Vector3).y
	return {
		"peer": peer_id,
		"sender": sender,
		"claim": claimed,
		"claim_realm": realm,
		"host_position": global_position,
		"host_realm": net_realm,
		"ground_y": ground_y,
		"ground_normal_y": normal_y,
		# The host's swept no-fly volumes are the CLIENT's realm's authoring and
		# this node has no reader for them; the client already enforces them on
		# itself every frame of the glide (`fly_controller._restricted_reason`).
		# Left empty rather than guessed at, and said so rather than implied.
		"restricted": "",
		"config": config,
	}


## Host -> client, on the client's own body. Handed straight to the fly
## controller, which is the only thing that owns `safe_anchor`.
@rpc("any_peer", "call_remote", "reliable")
func _rpc_landing_anchor_verdict(ok: bool, anchor: Array, code: String, reason: String) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		# Only the host answers. A peer that is not the host sending a verdict
		# is a peer trying to move somebody else's trainer.
		return
	if not bool(_owned_here):
		return
	var at := Vector3.ZERO
	if anchor.size() == 3:
		at = Vector3(float(anchor[0]), float(anchor[1]), float(anchor[2]))
	var rig := _local_rig()
	var fly: Variant = rig.get("fly_controller") if rig != null else null
	if fly == null or not (fly is Object) or not (fly as Object).has_method("apply_anchor_verdict"):
		return
	(fly as Object).call("apply_anchor_verdict", ok, at, code, reason)


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
