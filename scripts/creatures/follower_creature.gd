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

## A follower still closing on the trainer but wedged against terrain (no
## progress for this long while farther than STUCK_MIN_GAP_M from the trainer)
## takes the leash snap too. Inside LEASH it would otherwise wait forever, out
## of reach of an encounter's engage radius.
const STUCK_SNAP_S := 3.0
const STUCK_MIN_GAP_M := 12.0
const STUCK_PROGRESS_M := 0.5

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
## A multi-metre companion needs camera depth as well as lateral clearance. A
## purely sideways station leaves its near surface at the exploration camera and
## turns harmless centre motion into 30-40% frame coverage. Lead tall bodies by a
## bounded fraction of their authored height; this preserves scale and keeps them
## recognisably beside the trainer instead of pushing them off-screen sideways.
const DEFAULT_VISUAL_LEAD_HEIGHT_RATIO := 1.6
const DEFAULT_BACK_OFFSET := 0.5
const DEFAULT_STATION_STOP_DISTANCE := 0.9
const DEFAULT_STATION_RESUME_DISTANCE := 1.6
const DEFAULT_MOVING_STATION_STOP_DISTANCE := 0.35
const DEFAULT_FLANK_RUN_DISTANCE := 3.8
## A walking or sprinting trainer must not shed the companion back into the camera.
const DEFAULT_FLANK_WALK_SPEED := 5.2
const DEFAULT_FLANK_RUN_SPEED := 9.0

## W12-COMPANION-0904. The contextual-reaction layer (acknowledgment, victory,
## hurt, camp, care, bond) that makes the follower read as a companion rather
## than a model that appears for fights. Built once here; everything it does
## is documented in its own header.
const PRESENCE := preload("res://scripts/creatures/companion_presence.gd")
const INTERIOR_BEACON := preload("res://scripts/world/objective_beacon.gd")

## Placement on the trainer's floor (reviewer findings, Cloudreach narrow
## roads): the leash snap seated the body on the terrain HEIGHT ESTIMATE, which
## beside a narrow road is the floor below the drop, and the walk to the fixed
## flank station stepped off a road edge. A realm director that knows its
## collision (`cloudreach_encounter_director.gd::verified_follow_spot`) supplies
## `station_validator`; without one the station is the unchanged flank and the
## snap keeps `place_on_ground`, refusing only a seat far below the trainer.
## Revalidate a changed station at most every this many physics frames (the
## validator is tens of physics queries; never every frame).
const STATION_VALIDATE_FRAMES := 15
## A station that moved less than this since its last check is not re-checked.
const STATION_VALIDATE_MOVE_M := 0.05
## Default snap guard: a seat more than this below the trainer's feet is a floor
## under a drop, not the trainer's ground (a Meadows hillside flank never is).
const DEFAULT_SNAP_MAX_DROP_M := 6.0
## With no verified station the companion closes on the trainer and stops this
## far beyond its own radius, on the ground the trainer is standing on.
const TRAINER_FALLBACK_CLEARANCE_M := 1.0
## The trainer's capsule radius (scenes/player/player.tscn) and the extra gap a
## companion keeps from it. A large creature must never stand inside the
## trainer, e.g. stopping beside them when a dialogue opens (captures F03#1).
const TRAINER_RADIUS_M := 0.4
const TRAINER_SPACING_MARGIN_M := 0.3
## F17#6 claude-r1 judge: indoors the companion clipped through the Shrine
## Room lecterns. A node in this group, with a planar keep-clear radius in
## this meta, is ground a companion's footprint never stands on while the
## trainer is in a declared interior: the indoor station refuses it and a
## standing companion inside one walks on to its clear station. The Crossing
## Hall adds its pedestals only behind crossing_hall.json
## companion_pedestal_clearance.enabled (default OFF); nothing else joins.
const KEEP_CLEAR_GROUP := &"follower_keep_clear"
const KEEP_CLEAR_RADIUS_META := &"follower_keep_clear_radius_m"


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
var _visual_lead_height_ratio: float = DEFAULT_VISUAL_LEAD_HEIGHT_RATIO
var _back_offset: float = DEFAULT_BACK_OFFSET
var _station_stop_distance: float = DEFAULT_STATION_STOP_DISTANCE
var _station_resume_distance: float = DEFAULT_STATION_RESUME_DISTANCE
var _moving_station_stop_distance: float = DEFAULT_MOVING_STATION_STOP_DISTANCE
var _last_leader_facing: Vector3 = DEFAULT_LEADER_FACING
## True while it is closing the gap. Hysteresis: without it the creature oscillates
## between "close enough" and "too far" on the boundary and jitters in place.
var _closing: bool = false
var _stuck_s := 0.0
var _stuck_anchor := Vector3.INF

## `func(body: Node3D, trainer: Node3D, requested: Vector3, snap: bool) -> Vector3`:
## a verified spot for this body near `requested` on the trainer's floor, or
## Vector3.INF when none. `snap` is the leash teleport (may return the trainer's
## own footprint); otherwise it is the walking station. Set by a realm director.
var station_validator: Callable = Callable()
var _indoor_station_active := false
## Last validated station, as an offset from the trainer so it moves with a
## walking trainer between checks. INF = no verified station (close on trainer).
var _station_offset: Vector3 = Vector3.ZERO
var _station_requested: Vector3 = Vector3.INF
var _station_leader: Vector3 = Vector3.INF
var _station_checked_frame: int = -STATION_VALIDATE_FRAMES
## Default snap's last rung shares the trainer's footprint; this body ignores
## that trainer's capsule until they are apart.
var _footprint_exception: Node3D = null


func configure_following(cfg: Dictionary) -> void:
	_stop_distance = float(cfg.get("stop_distance", _stop_distance))
	_resume_distance = float(cfg.get("resume_distance", _resume_distance))
	_run_distance = float(cfg.get("run_distance", _run_distance))
	_walk_speed = float(cfg.get("walk_speed", _walk_speed))
	_run_speed = float(cfg.get("run_speed", _run_speed))
	_side_offset = float(cfg.get("side_offset", _side_offset))
	_visual_clearance_height_ratio = float(cfg.get(
		"visual_clearance_height_ratio", _visual_clearance_height_ratio))
	_visual_lead_height_ratio = float(cfg.get(
		"visual_lead_height_ratio", _visual_lead_height_ratio))
	_back_offset = float(cfg.get("back_offset", _back_offset))
	_station_stop_distance = float(cfg.get("station_stop_distance", _station_stop_distance))
	_station_resume_distance = float(cfg.get("station_resume_distance", _station_resume_distance))
	_moving_station_stop_distance = float(cfg.get(
		"moving_station_stop_distance", _moving_station_stop_distance))


func set_following(value: bool) -> void:
	_following = value
	_closing = false
	_station_requested = Vector3.INF
	# The shared-footprint exception belongs to following only: combat restores
	# layer 1 below and must not find the companion passing through its trainer.
	if not value and _footprint_exception != null:
		if is_instance_valid(_footprint_exception):
			remove_collision_exception_with(_footprint_exception)
		_footprint_exception = null
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


## F17#6 r6 judge: in the Hall the following companion often stood between
## the player and the camera, and frames showed only its fur. While the camera
## is inside (or within `CAMERA_FADE_MARGIN_M` of) the body's rendered bounds
## the body fades, through the fight's own dither (`ally_occlusion_fade.gd`).
## Local presentation only: collision, placement and other peers untouched.
const CAMERA_FADE := preload("res://scripts/combat/ally_occlusion_fade.gd")
const CAMERA_FADE_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CAMERA_FADE_MARGIN_M := 0.6
const CAMERA_FADE_AMOUNT := 0.85
const CAMERA_FADE_SPEED := 5.0
var _camera_fade := 0.0
var _camera_fade_state: Dictionary = {}
var _camera_fade_bounds := AABB()
var _camera_fade_model: Node3D = null


func _process(delta: float) -> void:
	var model := model_pivot()
	if model != _camera_fade_model:
		CAMERA_FADE.restore(_camera_fade_state)
		_camera_fade = 0.0
		_camera_fade_model = model
		_camera_fade_bounds = CAMERA_FADE_BOUNDS.measure(model) if model != null else AABB()
	if model == null or not is_inside_tree() or _camera_fade_bounds.size == Vector3.ZERO:
		return
	var camera := get_viewport().get_camera_3d()
	var inside := false
	if camera != null:
		var local := model.global_transform.affine_inverse() * camera.global_position
		inside = _camera_fade_bounds.grow(CAMERA_FADE_MARGIN_M).has_point(local)
		if not inside:
			inside = _blocks_leader_view(model, camera.global_position)
	var target := CAMERA_FADE_AMOUNT if inside else 0.0
	var next := move_toward(_camera_fade, target, CAMERA_FADE_SPEED * delta)
	if is_zero_approx(next) and is_zero_approx(_camera_fade):
		return
	_camera_fade = next
	CAMERA_FADE.apply(model, _camera_fade, _camera_fade_state,
		camera.global_position if camera != null else model.global_position)


## F38 P2-062 candidate (OFF unless combat.json `camera.occlusion_fade.follow_candidate`
## is enabled): after a won fight the large ally parked beside the trainer
## near the lens and filled half the gameplay view. The body also fades while
## the lens is within `near_margin_m` of its bounds, or while it covers the
## trainer's sample heights from the camera. Local presentation only.
static var _follow_fade_cfg: Variant = null


static func follow_fade_config() -> Dictionary:
	if _follow_fade_cfg == null:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
		var block: Variant = {}
		if parsed is Dictionary:
			block = ((parsed.get("camera", {}) as Dictionary).get("occlusion_fade", {}) as Dictionary).get("follow_candidate", {})
		_follow_fade_cfg = block if block is Dictionary else {}
	return _follow_fade_cfg


func _blocks_leader_view(model: Node3D, eye: Vector3) -> bool:
	var cfg := follow_fade_config()
	if not bool(cfg.get("enabled", false)):
		return false
	var local := model.global_transform.affine_inverse() * eye
	if _camera_fade_bounds.grow(float(cfg.get("near_margin_m", 1.5))).has_point(local):
		return true
	if leader == null or not is_instance_valid(leader):
		return false
	var base := _world_position(leader)
	for height: Variant in cfg.get("leader_heights_m", [0.5, 1.0, 1.6]):
		if CAMERA_FADE.segment_hits_ellipsoid(eye, base + Vector3.UP * float(height), model.global_transform, _camera_fade_bounds):
			return true
	return false


func _physics_process(delta: float) -> void:
	if _following:
		_tick_follow()
		_tick_stuck(delta)
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
	var leader_speed := _leader_planar_speed()
	var target := _follow_target()
	var to := target - _world_position(self)
	to.y = 0.0
	var distance := to.length()

	if leader_distance > LEASH:
		_snap_near_leader(target, leader_position)
		_closing = false
		return
	_release_footprint_exception(leader_position)

	var stop_distance := _station_stop_distance
	var resume_distance := _station_resume_distance
	var moving_stop_distance := _moving_station_stop_distance
	var validator := _station_validator_now(leader_position)
	if validator.is_valid():
		target = _validated_station(target, leader_position, validator)
		if not target.is_finite():
			# No verified station on the trainer's floor: close on the trainer
			# itself (the ground it stands on) and stop clear of its capsule.
			target = leader_position
			var clear := body_radius() + TRAINER_FALLBACK_CLEARANCE_M
			stop_distance = maxf(stop_distance, clear)
			resume_distance = maxf(resume_distance, clear + 0.7)
			moving_stop_distance = maxf(moving_stop_distance, clear)
		to = target - _world_position(self)
		to.y = 0.0
		distance = to.length()

	_closing = station_should_close(_closing, distance, leader_speed,
		stop_distance, resume_distance, moving_stop_distance)
	# Stopping "near enough" to the station must never leave the body inside the
	# trainer: keep walking to the (clear) station while too close.
	# (Not when the target is the trainer itself: that fallback already stops a
	# body radius + TRAINER_FALLBACK_CLEARANCE_M short of the capsule.)
	var gap := _world_position(self) - leader_position
	gap.y = 0.0
	if not _closing and not target.is_equal_approx(leader_position) and gap.length() < trainer_clearance():
		_closing = true
	# Nor standing within a keep-clear zone (a Hall pedestal): walk on to the
	# clear station.
	if not _closing and _indoor_station_active and not target.is_equal_approx(leader_position) \
			and keep_clear_hit(_keep_clear_zones(), _world_position(self), footprint_radius()):
		_closing = true

	if not _closing:
		# Standing with you rather than staring past you.
		face_towards(leader.global_position)
		return

	var speed := _run_speed if distance > _run_distance else _walk_speed
	if leader_speed > 0.1:
		# Matching the trainer's speed only preserves whatever lag already exists.
		# Add a bounded proportional catch-up term so the live moving station can
		# converge instead of sitting forever at the edge of its old hysteresis.
		speed = maxf(speed, minf(_run_speed,
			leader_speed + maxf(0.65, distance * 1.35)))
	# A badly hurt or hungry creature trails at a slower gait (companion_presence.gd).
	if _presence != null:
		speed *= float(_presence.call("gait_scale"))
	request_move(to / maxf(distance, 0.001), speed)


## Counts time spent closing without moving STUCK_PROGRESS_M; past
## STUCK_SNAP_S while far from the trainer, the ordinary leash snap applies.
func _tick_stuck(delta: float) -> void:
	if leader == null or not is_instance_valid(leader) or not _closing:
		_stuck_s = 0.0
		_stuck_anchor = Vector3.INF
		return
	var here := _world_position(self)
	if not _stuck_anchor.is_finite() or here.distance_to(_stuck_anchor) > STUCK_PROGRESS_M:
		_stuck_anchor = here
		_stuck_s = 0.0
		return
	_stuck_s += delta
	var gap := _world_position(leader) - here
	gap.y = 0.0
	if _stuck_s >= STUCK_SNAP_S and gap.length() > STUCK_MIN_GAP_M:
		_snap_near_leader(_follow_target(), _world_position(leader))
		_closing = false
		_stuck_s = 0.0
		_stuck_anchor = Vector3.INF


## The leash teleport. With a realm validator: its verified spot (the trainer's
## footprint as the last rung). Without: `place_on_ground` as before -- never a
## per-frame raycast, docs/decisions/D09 -- but a seat far below the trainer's
## feet is refused for the trainer's own footprint. Both rules measure against
## the trainer's FEET, so they apply only while the trainer stands on a floor:
## a flying, gliding, falling or swimming trainer's position is not ground, and
## the companion then takes plain `place_on_ground` as it always did.
func _snap_near_leader(target: Vector3, leader_position: Vector3) -> void:
	_station_requested = Vector3.INF
	if not leader_grounded():
		place_on_ground(target)
		return
	if station_validator.is_valid():
		var spot: Variant = station_validator.call(self, leader, target, true)
		if spot is Vector3 and (spot as Vector3).is_finite():
			_seat_at(spot)
			return
	if not place_on_ground(target) \
			or snap_seat_acceptable(global_position.y, leader_position.y):
		return
	# Seated on a floor far below the trainer: take the trainer's footprint.
	if not place_on_ground(leader_position) \
			or not snap_seat_acceptable(global_position.y, leader_position.y):
		_seat_at(leader_position)
	if leader is PhysicsBody3D and _footprint_exception != leader:
		add_collision_exception_with(leader)
		_footprint_exception = leader


## True while the trainer stands on a floor, so its position is its feet on
## ground. The trainer is a CharacterBody3D; anything answering `is_on_floor`
## is asked the same way (the detached unit fixture's stand-in).
func leader_grounded() -> bool:
	if leader == null or not is_instance_valid(leader) or not leader.has_method("is_on_floor"):
		return false
	return bool(leader.call("is_on_floor"))


func _seat_at(at: Vector3) -> void:
	_set_world_position(at)
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO


static func snap_seat_acceptable(seat_y: float, leader_y: float) -> bool:
	return seat_y >= leader_y - DEFAULT_SNAP_MAX_DROP_M


func _release_footprint_exception(leader_position: Vector3) -> void:
	if _footprint_exception == null:
		return
	if not is_instance_valid(_footprint_exception):
		_footprint_exception = null
		return
	var at := _world_position(self)
	var apart := Vector2(at.x - leader_position.x, at.z - leader_position.z).length()
	if apart >= body_radius() + 0.6:
		remove_collision_exception_with(_footprint_exception)
		_footprint_exception = null


## The walking station, verified by the realm validator on change and at most
## every STATION_VALIDATE_FRAMES; between checks the verified offset rides with
## the trainer. INF when the validator found no station on the trainer's floor.
func _validated_station(requested: Vector3, leader_position: Vector3, validator: Callable = Callable()) -> Vector3:
	if not validator.is_valid():
		validator = station_validator
	var frame := Engine.get_physics_frames()
	var offset := requested - leader_position
	var due := not _station_requested.is_finite()
	if not due and frame - _station_checked_frame >= STATION_VALIDATE_FRAMES:
		# Also re-ask while the last answer was "no station": after a teleport
		# the first check can run before the floor's colliders exist, and a
		# trainer who then stands still would otherwise keep the companion on
		# the close-on-trainer fallback indefinitely.
		due = not _station_offset.is_finite() \
			or _station_requested.distance_to(offset) > STATION_VALIDATE_MOVE_M \
			or _station_leader.distance_to(leader_position) > STATION_VALIDATE_MOVE_M
	if due:
		_station_checked_frame = frame
		_station_requested = offset
		_station_leader = leader_position
		var spot: Variant = validator.call(self, leader, requested, false)
		_station_offset = (spot as Vector3) - leader_position \
			if spot is Vector3 and (spot as Vector3).is_finite() else Vector3.INF
	return leader_position + _station_offset if _station_offset.is_finite() else Vector3.INF


## F17#6 r4 judge: in the Crossing Hall nave the fixed flank station put the
## companion inside the arch wall (its head showing through the stone). Meadows
## has no realm `station_validator`, so while the trainer stands inside a
## declared interior (objective_beacon.gd INTERIOR_GROUP: the Hall's nave and
## Shrine Room) the walking station goes through `_indoor_station`. Outdoors,
## and wherever a realm validator is set, behaviour is unchanged. The leash
## snap is untouched. Local follower only: no authority change.
func _station_validator_now(leader_position: Vector3) -> Callable:
	if station_validator.is_valid():
		return station_validator
	var indoors := is_inside_tree() and INTERIOR_BEACON.point_indoors(get_tree(), leader_position)
	if indoors != _indoor_station_active:
		_indoor_station_active = indoors
		_station_requested = Vector3.INF # Re-ask under the new rule at once.
	return Callable(self, "_indoor_station") if indoors else Callable()


## The requested flank if the companion's body fits there with a clear line
## from the trainer, else the nearest of seven turns round the trainer at the
## same reach, else INF (the follower then closes on the trainer). At most
## eight candidates of one ray and two shape queries, on the
## STATION_VALIDATE_FRAMES cadence.
func _indoor_station(_body: Node3D, trainer: Node3D, requested: Vector3, _snap: bool) -> Vector3:
	if not is_instance_valid(trainer) or not is_inside_tree():
		return Vector3.INF
	var origin := trainer.global_position
	var offset := Vector3(requested.x - origin.x, 0.0, requested.z - origin.z)
	var clearance := maxf(_radius, maxf(_render_half_extents.x, _render_half_extents.y))
	var reach := maxf(offset.length(), clearance + 0.6)
	var first := offset.normalized() if offset.length() > 0.01 else Vector3.BACK
	return first_clear_spot(origin, first, reach, _keep_clear_zones(), clearance,
		func(spot: Vector3) -> bool: return _indoor_spot_clear(trainer, origin, spot, clearance))


## The requested flank, else the nearest of seven turns at the same reach,
## that is outside every keep-clear zone and passes `physics_clear`; with
## zones, then a second ring 1.75x out (between two pedestals every turn at
## the first reach can fall inside one). INF when none.
static func first_clear_spot(origin: Vector3, first: Vector3, reach: float, zones: Array,
		clearance: float, physics_clear: Callable) -> Vector3:
	for ring: float in ([1.0, 1.75] if not zones.is_empty() else [1.0]):
		for turn: float in [0.0, 45.0, -45.0, 90.0, -90.0, 135.0, -135.0, 180.0]:
			var spot := origin + first.rotated(Vector3.UP, deg_to_rad(turn)) * reach * ring
			spot.y = origin.y
			if not keep_clear_hit(zones, spot, clearance) and bool(physics_clear.call(spot)):
				return spot
	return Vector3.INF


## The keep-clear zones as [planar centre (Vector2), radius], read from
## KEEP_CLEAR_GROUP. Empty outside a tree or when nothing has joined.
func _keep_clear_zones() -> Array:
	var zones: Array = []
	if not is_inside_tree():
		return zones
	for node: Node in get_tree().get_nodes_in_group(KEEP_CLEAR_GROUP):
		var zone := node as Node3D
		if zone != null and zone.is_inside_tree():
			zones.append([Vector2(zone.global_position.x, zone.global_position.z),
				float(zone.get_meta(KEEP_CLEAR_RADIUS_META, 0.0))])
	return zones


## True when a footprint of this radius centred at `at` overlaps any zone.
static func keep_clear_hit(zones: Array, at: Vector3, footprint: float) -> bool:
	var planar := Vector2(at.x, at.z)
	for zone: Array in zones:
		if planar.distance_to(zone[0]) < float(zone[1]) + maxf(0.0, footprint):
			return true
	return false


func _indoor_spot_clear(trainer: Node3D, origin: Vector3, spot: Vector3, clearance: float) -> bool:
	var space := get_world_3d().direct_space_state
	var exclude: Array[RID] = [get_rid()]
	if trainer is CollisionObject3D:
		exclude.append((trainer as CollisionObject3D).get_rid())
	var ray := PhysicsRayQueryParameters3D.create(origin + Vector3.UP, spot + Vector3.UP, collision_mask, exclude)
	if not space.intersect_ray(ray).is_empty():
		return false
	var sphere := SphereShape3D.new()
	sphere.radius = clearance
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.collision_mask = collision_mask
	query.exclude = exclude
	# Low (above the floor) and high (the head): both must be clear of walls.
	for height: float in [clearance + 0.15, maxf(clearance + 0.15, body_height() - clearance)]:
		query.transform = Transform3D(Basis(), spot + Vector3.UP * height)
		if not space.intersect_shape(query, 1).is_empty():
			return false
	return true


func _leader_planar_speed() -> float:
	if not leader is CharacterBody3D:
		return 0.0
	var body := leader as CharacterBody3D
	return Vector2(body.velocity.x, body.velocity.z).length()


## The broad stop/resume band is correct when both bodies are stationary, but
## R10 proved it lets a moving leader carry the target 1.6m back toward the
## camera before the follower responds. While the station itself is moving,
## hold a tight bounded error; travel already suppresses visible idle jitter.
static func station_should_close(was_closing: bool, distance: float,
		leader_speed: float, stop_distance: float, resume_distance: float,
		moving_stop_distance: float) -> bool:
	if leader_speed > 0.1:
		return distance > moving_stop_distance
	return distance > stop_distance if was_closing else distance > resume_distance


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
		+ _safe_camera_forward() * resolved_forward_offset()


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


## R10 proved that leading along travel is not camera depth: on a diagonal its
## lateral component cancels part of the flank, then reverses on the next turn,
## forcing a multi-metre creature to traverse back through the gameplay view.
## Use the active camera's horizontal look direction so forward clearance stays
## invariant during left/right motion. Detached fixtures retain travel heading.
func _safe_camera_forward() -> Vector3:
	var fallback := Vector3(_last_leader_facing.x, 0.0, _last_leader_facing.z)
	if not is_inside_tree():
		return fallback.normalized()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return fallback.normalized()
	var camera_forward := Vector3(-camera.global_basis.z.x, 0.0,
		-camera.global_basis.z.z)
	return camera_depth_forward(camera_forward, fallback)


static func camera_depth_forward(camera_forward: Vector3,
		fallback_forward: Vector3) -> Vector3:
	var safe := Vector3(camera_forward.x, 0.0, camera_forward.z)
	if safe.length_squared() > 0.001:
		return safe.normalized()
	var fallback := Vector3(fallback_forward.x, 0.0, fallback_forward.z)
	return fallback.normalized() if fallback.length_squared() > 0.001 else DEFAULT_LEADER_FACING


func formation_target() -> Vector3:
	return _follow_target()


## The authored `side_offset` is clearance beyond the creature's visual envelope,
## not a centre distance. Height is deliberately allowed to dominate the collider
## radius: changing a creature's gameplay scale must widen its camera-safe station,
## never shrink that creature to fit an offset authored for a smaller roster.
func resolved_side_offset() -> float:
	return maxf(_side_offset + visual_flank_extent(), trainer_clearance())


## The widest horizontal reach of this body's footprint (collider or rendered
## half-extent, whichever is larger), so size scales the gap by species.
func footprint_radius() -> float:
	var half: Variant = get("_render_half_extents")
	var reach := body_radius()
	if half is Vector2: reach = maxf(reach, maxf((half as Vector2).x, (half as Vector2).y))
	return reach


## The nearest this companion's centre may stand to the trainer's.
func trainer_clearance() -> float:
	return trainer_clearance_for(footprint_radius())


static func trainer_clearance_for(footprint: float) -> float:
	return TRAINER_RADIUS_M + maxf(0.0, footprint) + TRAINER_SPACING_MARGIN_M


func visual_flank_extent() -> float:
	return maxf(body_radius(), body_height() * _visual_clearance_height_ratio)


## Positive is ahead along gameplay-camera depth. The ordinary half-step-back
## authoring remains in the equation, but a tall visual body earns enough extra
## depth to keep its near surface out of the third-person camera. This does not
## alter body scale, collision, gait, or the lateral beside-player clearance.
func resolved_forward_offset() -> float:
	return body_height() * _visual_lead_height_ratio - _back_offset


func resolved_station_distance() -> float:
	return Vector2(resolved_side_offset(), resolved_forward_offset()).length()


## Presence reactions share this body with the follow controller, and their move
## request runs later in the same physics tick. A fixed 2.2m acknowledgment walk
## therefore used to pull a large companion straight back inside the camera-safe
## flank the follower had just reached. Small bodies retain the authored approach;
## large bodies acknowledge from no nearer than their complete resolved station.
func safe_presence_approach_distance(authored_distance: float) -> float:
	return maxf(authored_distance, resolved_station_distance())


## The unit fixture is deliberately detached and treats local positions as world
## positions. Production nodes are always in-tree and take the normal global path.
func _world_position(node: Node3D) -> Vector3:
	return node.global_position if node.is_inside_tree() else node.position


func _set_world_position(at: Vector3) -> void:
	if is_inside_tree():
		global_position = at
	else:
		position = at
