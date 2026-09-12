extends "res://scripts/creatures/creature_body.gd"

## The player's creature, walking beside them in the world.
##
## Before this, the player's creature existed only inside a fight: the encounter
## director instanced a body, set `visible = false`, and turned it on when
## combat opened. This inverts that. GAME_DESIGN.md's pillar 2 is that the five
## become emotionally important, and a creature that only exists while you are
## hitting something with it is a weapon, not a companion (docs/decisions/D12
## says the same thing about scale).
##
## It writes no locomotion of its own. Everything here decides a direction and a
## speed and hands both to `creature_body.request_move()`, which is the same call the
## combat AI and the player's own stick go through — so a following creature walks up
## the same hills, at the same acceleration, with the same animation blending as
## a fighting one.
##
## It stops following while a fight is running, because the combat manager is
## driving the same body. Two things calling `request_move` on one creature in
## one frame is one of them silently losing.

## Beyond this the creature has been left behind by something the game did rather than
## by the player walking — a fight that ended across the meadow, a fall, a
## teleport. It gives up and reappears near the trainer rather than jogging back
## across the biome.
const LEASH := 45.0

## CP-1b. The player body does not yaw with the visible trainer model, so its basis
## cannot identify the flank. Horizontal travel is the one authoritative facing the
## follower can read without coupling itself to the trainer's presentation children.
## Remember it while the trainer stands still so the companion holds the same side.
const DEFAULT_LEADER_FACING := Vector3.FORWARD
## Clear metres between the trainer's travel axis and the companion's body
## edge. This cannot be a centre-to-centre offset: the roster's radius now
## ranges from small starters to multi-metre giants, and a fixed 1.8m centre
## target puts Terrapup's 1.464m body (plus station hysteresis) directly back
## across the third-person camera line.
const DEFAULT_SIDE_OFFSET := 1.8
## A collider radius is not the visual half-width of a Palworld-scale creature.
## Terrapup's broad shell is the concrete case: its 1.464m capsule allowed its
## nearly 4m presentation to cover the gameplay camera even at the old flank.
## Keep the authored clear gap, but size the inner visual envelope from height.
const DEFAULT_VISUAL_CLEARANCE_HEIGHT_RATIO := 0.8
const DEFAULT_BACK_OFFSET := 0.5
const DEFAULT_STATION_STOP_DISTANCE := 0.9
const DEFAULT_STATION_RESUME_DISTANCE := 1.6
const DEFAULT_FLANK_RUN_DISTANCE := 3.8
## A walking or sprinting trainer must not shed the companion back into the camera.
const DEFAULT_FLANK_WALK_SPEED := 5.2
const DEFAULT_FLANK_RUN_SPEED := 9.0

## W12-COMPANION-0904. The contextual-reaction layer (acknowledgment, victory,
## hurt, camp, care, bond) that makes the follower read as a companion rather
## than a model that appears for fights. Built once here; everything it does
## is documented in its own header.
const PRESENCE := preload("res://scripts/creatures/companion_presence.gd")


## The trainer THIS creature follows. Stage B lane 4.B: it is the body of the
## peer who owns the creature, not "the player" -- in a session every peer has
## a trainer body standing in this world, and a follower that walked to
## whichever one happened to be local would abandon its own trainer the moment
## a second player joined. `encounter_director.gd::_spawn_ally_body()` sets it
## to the owner's rig, and nothing here ever falls back to a global lookup:
## a follower with no leader stands still, which is visibly wrong and
## therefore reportable, where following the wrong trainer is neither.
var leader: Node3D = null
## The peer this creature belongs to. 1 in solo and on the host, a large
## random ENet id for a joiner (spike finding 2: peer ids are never 2, 3, 4).
## Set by the encounter director at deploy time and re-set if the session's
## peer id changes under it.
var owner_peer_id: int = 0
var _presence: Node = null

var _following: bool = false
## Metres. Kept well clear of the trainer's own capsule: a follower that stands
## on top of the player is a follower that shoves the camera around.
var _stop_distance: float = 3.0
var _resume_distance: float = 4.0
var _run_distance: float = DEFAULT_FLANK_RUN_DISTANCE
var _walk_speed: float = DEFAULT_FLANK_WALK_SPEED
var _run_speed: float = DEFAULT_FLANK_RUN_SPEED
var _side_offset: float = DEFAULT_SIDE_OFFSET
var _visual_clearance_height_ratio: float = DEFAULT_VISUAL_CLEARANCE_HEIGHT_RATIO
var _back_offset: float = DEFAULT_BACK_OFFSET
var _station_stop_distance: float = DEFAULT_STATION_STOP_DISTANCE
var _station_resume_distance: float = DEFAULT_STATION_RESUME_DISTANCE
var _last_leader_facing: Vector3 = DEFAULT_LEADER_FACING
## True while it is closing the gap. Hysteresis: without it the creature oscillates
## between "close enough" and "too far" on the boundary and jitters in place.
var _closing: bool = false


func configure_following(cfg: Dictionary) -> void:
	_stop_distance = float(cfg.get("stop_distance", _stop_distance))
	_resume_distance = float(cfg.get("resume_distance", _resume_distance))
	_run_distance = float(cfg.get("run_distance", _run_distance))
	_walk_speed = float(cfg.get("walk_speed", _walk_speed))
	_run_speed = float(cfg.get("run_speed", _run_speed))
	_side_offset = float(cfg.get("side_offset", _side_offset))
	_visual_clearance_height_ratio = float(cfg.get(
		"visual_clearance_height_ratio", _visual_clearance_height_ratio))
	_back_offset = float(cfg.get("back_offset", _back_offset))
	_station_stop_distance = float(cfg.get("station_stop_distance", _station_stop_distance))
	_station_resume_distance = float(cfg.get("station_resume_distance", _station_resume_distance))


func set_following(value: bool) -> void:
	_following = value
	_closing = false
	if value and _presence != null:
		_presence.call("on_event", "deploy")
	# Off every physics layer while following, so it can never wall the trainer
	# in. It only re-closes the gap once past `_stop_distance` and has no idea
	# whether "close enough" also means "standing in the way" — reversing
	# direction on foot leaves it briefly ahead rather than behind, and two
	# solid CharacterBody3D capsules aimed straight at each other simply stop
	# dead. Confirmed as the real, intermittent cause of RB3's
	# smoke_aggression.gd failure (a frozen trainer 60-70m short, never a
	# pathing or aggression-timing bug). Restored once combat takes over,
	# because `wild_creature.gd`'s `_spaced_config()` keeps the two fighters apart
	# by real collision, not just by distance math, and dropping that turned
	# up as a *different* flake in `smoke_catching.gd` ("the creature moved 4.04m
	# on the stick while aiming") the first time this was tried scoped wider,
	# to the whole lifetime of the body rather than just the following state.
	collision_layer = 0 if value else 1


func is_following() -> bool:
	return _following


## True while closing the gap to the trainer (the presence layer reads it so it
## never starts a reaction on a creature that is mid-walk).
func is_closing() -> bool:
	return _following and _closing


func presence() -> Node:
	return _presence


## True: a `follower_creature.gd` body is, by construction, the creature THIS
## process pilots -- `encounter_director.gd` only ever builds one for the local
## player. `remote_creature.gd` answers false. Together they let
## `playground_hud.gd` pick the local player's own creature out of
## `DEPLOYED_GROUP` without asking for a node called "AllyCreature".
func is_local_deployment() -> bool:
	return true


func _ready() -> void:
	super()
	add_to_group(DEPLOYED_GROUP)
	_presence = PRESENCE.new()
	_presence.name = "Presence"
	add_child(_presence)
	_presence.call("setup", self)


func _physics_process(delta: float) -> void:
	if _following:
		_tick_follow()
	# The presence layer ticks after the follow logic and before integration:
	# its one gameplay request (the short walk up to the trainer) has to be the
	# last `request_move` of the frame to be the one honoured, and it must see
	# the body still standing where the follow logic left it. It runs whether
	# following or not -- the post-victory reaction plays in the fight's own
	# result pause, when nothing else drives this body.
	if _presence != null:
		_presence.call("tick", delta)
	# The body integrates whatever was requested above. Calling super LAST is
	# required: `request_move` is cleared every frame by design, so a request
	# made after integration would be thrown away. Same rule as wild_creature.gd.
	super(delta)


func _tick_follow() -> void:
	if leader == null or not is_instance_valid(leader):
		return

	_update_leader_facing()
	var leader_position := _world_position(leader)
	var leader_gap := leader_position - _world_position(self)
	leader_gap.y = 0.0
	var leader_distance := leader_gap.length()
	var target := _follow_target()
	var to := target - _world_position(self)
	to.y = 0.0
	var distance := to.length()

	if leader_distance > LEASH:
		# Never a raycast — docs/decisions/D09. `place_on_ground` asks the world
		# first and only falls back to a ray for things the terrain does not know
		# about.
		place_on_ground(target)
		_closing = false
		return

	if _closing:
		_closing = distance > _station_stop_distance
	else:
		_closing = distance > _station_resume_distance

	if not _closing:
		# Standing with you rather than staring past you.
		face_towards(leader.global_position)
		return

	var speed := _run_speed if distance > _run_distance else _walk_speed
	# A badly hurt or hungry creature trails at a slower gait (companion_presence.gd).
	if _presence != null:
		speed *= float(_presence.call("gait_scale"))
	request_move(to / maxf(distance, 0.001), speed)


func _update_leader_facing() -> void:
	if not leader is CharacterBody3D:
		return
	var body := leader as CharacterBody3D
	var travel := Vector3(body.velocity.x, 0.0, body.velocity.z)
	if travel.length_squared() > 0.0025:
		_last_leader_facing = travel.normalized()


func _follow_target() -> Vector3:
	var right := _safe_flank_right()
	return _world_position(leader) + right * resolved_side_offset() \
		- _last_leader_facing * _back_offset


## Movement-facing alone swings the right flank behind the fixed exploration
## camera during a forward-right turn. Keep the same side, but use the current
## gameplay camera's horizontal right axis when available so changing travel
## direction never asks a large companion to cross the view. Detached tests and
## stripped fixtures retain the movement-facing fallback.
func _safe_flank_right() -> Vector3:
	var travel_right := _last_leader_facing.cross(Vector3.UP).normalized()
	if not is_inside_tree():
		return travel_right
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return travel_right
	var camera_right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z)
	if camera_right.length_squared() <= 0.001:
		return travel_right
	camera_right = camera_right.normalized()
	return camera_safe_flank_right(travel_right, camera_right)


static func camera_safe_flank_right(travel_right: Vector3, camera_right: Vector3) -> Vector3:
	var safe := Vector3(camera_right.x, 0.0, camera_right.z)
	if safe.length_squared() <= 0.001:
		return travel_right.normalized()
	safe = safe.normalized()
	return -safe if safe.dot(travel_right) < 0.0 else safe


func formation_target() -> Vector3:
	return _follow_target()


## The authored `side_offset` is clearance beyond the creature's visual envelope,
## not a centre distance. Height is deliberately allowed to dominate the collider
## radius: changing a creature's gameplay scale must widen its camera-safe station,
## never shrink that creature to fit an offset authored for a smaller roster.
func resolved_side_offset() -> float:
	return _side_offset + visual_flank_extent()


func visual_flank_extent() -> float:
	return maxf(body_radius(), body_height() * _visual_clearance_height_ratio)


## Presence reactions share this body with the follow controller, and their move
## request runs later in the same physics tick. A fixed 2.2m acknowledgment walk
## therefore used to pull a large companion straight back inside the camera-safe
## flank the follower had just reached. Small bodies retain the authored approach;
## large bodies acknowledge from no nearer than their resolved side clearance.
func safe_presence_approach_distance(authored_distance: float) -> float:
	return maxf(authored_distance, resolved_side_offset())


## The unit fixture is deliberately detached and treats local positions as world
## positions. Production nodes are always in-tree and take the normal global path.
func _world_position(node: Node3D) -> Vector3:
	return node.global_position if node.is_inside_tree() else node.position
