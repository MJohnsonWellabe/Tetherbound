extends RefCounted

## F06: a companion is never lost to a fall in Cloudreach.
##
## The trainer has a grounded-fall rule (`cloudreach_physical_runtime.gd`: more
## than 100 m below Fly's safe anchor, recover to it) and a map-wide kill plane
## (`cloudreach_world_runtime.gd::_mount_fall_recovery`, the trainer only). The
## active companion had neither, and two things in the shared follower put it
## over the edge and kept it there (`follower_creature.gd`):
##   - its camera-safe station is a fixed flank several metres beside the
##     trainer, and `_tick_follow()` walks straight at it with no look at the
##     ground in between, so a trainer near a Cloudreach road edge parks its
##     companion's station over open air;
##   - its leash re-teleport is planar (`leader_gap.y = 0.0`), so a companion
##     falling straight down under that station never reads as far away and
##     falls forever.
## Those are shared-file fixes. This is the realm's own catch, the companion
## twin of the trainer's walker rule, run by the physical runtime every
## physics frame.
##
## ## What is recovered, and when
##
## Only the body `encounter_director.ally_body()` returns, and only while it is
## FOLLOWING: combat, the ride (`riding_controller.gd`) and the finale's creature
## pilot (`cloudreach_world_runtime.gd`) all switch following off while they own
## the body, and each has its own fall handling. Only while the trainer stands
## on floor, on foot: flying, carried or airborne, there is no ground beside the
## trainer to put the companion on yet, and the rule simply waits for landing.
##
## Two depths, both measured against the trainer's own ground rather than
## Fly's safe anchor. The anchor does not advance under a rider and the
## placement target is the trainer anyway, so the trainer's feet are the
## reference that can never be stale:
##   - a FALL: more than `fall_drop_m` (100, as the trainer's rule) below the
##     trainer. Immediate.
##   - STRANDED: more than `stranded_drop_m` below for `stranded_s`. The
##     steep-shoulder slide in the report stopped some 30 m down, on ground,
##     where a 100 m rule never looks and the follower can never climb back.
##
## ## Multiplayer
##
## Every process recovers only its OWN deployed creature. `ally_body()` is the
## local `follower_creature.gd` body by construction, and `recoverable()` also
## demands `is_local_deployment()`: another peer's creature in this process is a
## `remote_creature.gd` copy that answers false and is driven purely by the
## owner's replicated `net_position`. The owner's recovery reaches every other
## peer through that same channel (the copy snaps when the jump is large), so a
## remote copy is never "recovered" here against its owner. Authority is not
## asked with `is_multiplayer_authority()`: the local follower is never given a
## per-peer authority, so on a client it would answer false for its own body.
##
## Nothing here is durable: a position correction, no flag, no save field.
##
## Tunables: `data/config/cloudreach_physical_runtime.json::companion_fall_recovery`.
## The defaults below match it.

const DEFAULT_FALL_DROP_M := 100.0
const DEFAULT_STRANDED_DROP_M := 20.0
const DEFAULT_STRANDED_S := 3.0
## Clear metres between the trainer's capsule and the companion's.
const DEFAULT_CLEARANCE_M := 0.6
## After a search finds no clear spot, wait this long before the next one:
## the search is 24 ray + shape queries and must not run every frame.
const DEFAULT_RETRY_S := 0.25
## Until the shared follower stops walking off edges, one road edge can mean a
## recovery every few seconds. Every one is counted; the line is spaced out.
const DEFAULT_MESSAGE_COOLDOWN_S := 30.0
## Rays for a spot start this far above the trainer's feet and end this far
## below: a spot must be on the trainer's own level, never a ledge under it.
const PROBE_UP_M := 2.5
const PROBE_DOWN_M := 3.0
const SETTLE_LIFT_M := 0.05
const TRAINER_RADIUS_FALLBACK := 0.4
const ANGLE_STEPS := 12
const MESSAGE := "Your companion scrambled back to your side."

var fall_drop_m := DEFAULT_FALL_DROP_M
var stranded_drop_m := DEFAULT_STRANDED_DROP_M
var stranded_s := DEFAULT_STRANDED_S
var clearance_m := DEFAULT_CLEARANCE_M
var retry_s := DEFAULT_RETRY_S
var message_cooldown_s := DEFAULT_MESSAGE_COOLDOWN_S
var recoveries := 0
var last_spot := Vector3.INF
var _stranded_for := 0.0
var _retry_left := 0.0
var _message_left := 0.0
var _announce := false


func configure(cfg: Dictionary) -> void:
	fall_drop_m = float(cfg.get("fall_drop_m", fall_drop_m))
	stranded_drop_m = float(cfg.get("stranded_drop_m", stranded_drop_m))
	stranded_s = float(cfg.get("stranded_s", stranded_s))
	clearance_m = float(cfg.get("clearance_m", clearance_m))
	retry_s = float(cfg.get("retry_s", retry_s))
	message_cooldown_s = float(cfg.get("message_cooldown_s", message_cooldown_s))


## True once for a recovery the player should be told about: never more than
## one line per `message_cooldown_s`, however many recoveries it covers.
func take_announcement() -> bool:
	var announce := _announce
	_announce = false
	return announce


## This process's own following companion, never a remote copy.
static func recoverable(body: Node) -> bool:
	if not body is CharacterBody3D or not is_instance_valid(body) or not body.is_inside_tree():
		return false
	if not body.has_method("is_local_deployment") or not bool(body.call("is_local_deployment")):
		return false
	if not body.has_method("is_following") or not bool(body.call("is_following")):
		return false
	return (body as Node3D).is_visible_in_tree()


## One physics frame. `world` is the realm root holding `EncounterDirector`,
## `CombatManager` and `RidingController`. True when it moved the companion.
func tick(delta: float, trainer: CharacterBody3D, flying: bool, world: Node) -> bool:
	_message_left = maxf(0.0, _message_left - delta)
	_retry_left = maxf(0.0, _retry_left - delta)
	if trainer == null or not is_instance_valid(trainer) or world == null:
		return false
	var director := world.get_node_or_null(^"EncounterDirector")
	var body: Node = director.call("ally_body") if director != null and director.has_method("ally_body") else null
	if not recoverable(body) or _owned_elsewhere(world, body):
		_stranded_for = 0.0
		return false
	var companion := body as CharacterBody3D
	# Only a trainer standing on ground has somewhere beside them to stand.
	# A stranding is measured against ground the trainer stands on, so an
	# airborne stretch starts it over.
	var carried := trainer.has_method("is_carried") and bool(trainer.call("is_carried"))
	if flying or carried or not trainer.is_on_floor():
		_stranded_for = 0.0
		return false
	var below := trainer.global_position.y - companion.global_position.y
	if below > fall_drop_m:
		return recover(companion, trainer)
	if below > stranded_drop_m:
		_stranded_for += delta
		if _stranded_for >= stranded_s:
			return recover(companion, trainer)
		return false
	_stranded_for = 0.0
	return false


## A fight or a ride owns the body even if following were somehow left on.
func _owned_elsewhere(world: Node, body: Node) -> bool:
	var manager := world.get_node_or_null(^"CombatManager")
	if manager != null and manager.has_method("is_fighting") and bool(manager.call("is_fighting")):
		return true
	var director := world.get_node_or_null(^"EncounterDirector")
	if director != null and director.has_method("trainer_battle_active") and bool(director.call("trainer_battle_active")):
		return true
	var riding := world.get_node_or_null(^"RidingController")
	return riding != null and riding.has_method("is_mounted") and bool(riding.call("is_mounted")) \
		and riding.call("mount_body") == body


func recover(companion: CharacterBody3D, trainer: CharacterBody3D) -> bool:
	if _retry_left > 0.0:
		return false
	var spot := find_spot(companion, trainer)
	if spot == Vector3.INF:
		# Nowhere clear here. The trainer moves; look again shortly.
		_retry_left = retry_s
		return false
	# The body's own placement API clears its velocity and pending impulse.
	# Its height comes from the realm's surface index, which on Cloudreach's
	# stacked shoulders is not the collider top (the saddle smoke measured a
	# metre's difference), so the verified ray floor is written back over it.
	# It refuses where the index has no answer; the spot is still verified,
	# so only the impulse it would have cleared is cleared here instead.
	if not bool(companion.call("place_on_ground", spot)) and "_impulse" in companion:
		companion.set("_impulse", Vector3.ZERO)
	companion.global_position = spot
	companion.velocity = Vector3.ZERO
	_stranded_for = 0.0
	recoveries += 1
	last_spot = spot
	if _message_left <= 0.0:
		_announce = true
		_message_left = message_cooldown_s
	return true


## First spot around the trainer, starting on the side away from the drop,
## with walkable physics floor at the trainer's level, room for the companion's
## own capsule and a clear line from the trainer. INF when there is none.
func find_spot(companion: CharacterBody3D, trainer: CharacterBody3D) -> Vector3:
	var space := trainer.get_world_3d().direct_space_state
	var base := trainer.global_position
	var radius := float(companion.call("body_radius")) if companion.has_method("body_radius") else 1.0
	var ring := radius + _trainer_radius(trainer) + clearance_m
	var away := base - companion.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	var exclude: Array[RID] = [companion.get_rid(), trainer.get_rid()]
	for distance: float in [ring, ring + 1.5]:
		for i in ANGLE_STEPS:
			# 0, +30, -30, +60, -60 ... degrees from the away direction.
			var turn := ceilf(i / 2.0) * (TAU / ANGLE_STEPS) * (1.0 if i % 2 == 1 else -1.0)
			var candidate := base + away.rotated(Vector3.UP, turn) * distance
			var floor_y := _walkable_floor(space, candidate, base.y, companion, exclude, radius)
			if is_nan(floor_y):
				continue
			var spot := Vector3(candidate.x, floor_y + SETTLE_LIFT_M, candidate.z)
			if _capsule_fits(space, companion, spot, exclude) and _line_clear(space, base, spot, companion, exclude):
				return spot
	return Vector3.INF


## The height to seat the capsule at over `at`, or NAN. On a slope of angle
## theta a capsule of radius r whose lowest point sits on the centre-ray hit
## cuts into the uphill side; its bottom sphere clears the plane only when
## lifted by r * (1/cos(theta) - 1). Without it no spot on a moderate slope
## ever fit a large body (about 21 degrees for a 1.46 m radius).
func _walkable_floor(space: PhysicsDirectSpaceState3D, at: Vector3, level: float,
		companion: CharacterBody3D, exclude: Array[RID], radius: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, level + PROBE_UP_M, at.z),
		Vector3(at.x, level - PROBE_DOWN_M, at.z), companion.collision_mask, exclude)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return NAN
	var up := (hit["normal"] as Vector3).y
	if up < cos(companion.floor_max_angle) or up <= 0.0:
		return NAN
	return (hit["position"] as Vector3).y + radius * (1.0 / up - 1.0)


func _capsule_fits(space: PhysicsDirectSpaceState3D, companion: CharacterBody3D, spot: Vector3,
		exclude: Array[RID]) -> bool:
	var collision := companion.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.shape == null:
		return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.collision_mask = companion.collision_mask
	query.transform = Transform3D(Basis.IDENTITY, spot + collision.position + Vector3.UP * SETTLE_LIFT_M)
	query.exclude = exclude
	return space.intersect_shape(query, 1).is_empty()


## Nothing solid between the trainer's chest and the spot: never through a
## wall, a closed gate's barrier or a thin rock fin.
func _line_clear(space: PhysicsDirectSpaceState3D, base: Vector3, spot: Vector3,
		companion: CharacterBody3D, exclude: Array[RID]) -> bool:
	var query := PhysicsRayQueryParameters3D.create(base + Vector3.UP * 1.0, spot + Vector3.UP * 1.0,
		companion.collision_mask, exclude)
	return space.intersect_ray(query).is_empty()


static func _trainer_radius(trainer: CharacterBody3D) -> float:
	var collision := trainer.get_node_or_null(^"Collision") as CollisionShape3D
	if collision != null and collision.shape is CapsuleShape3D:
		return (collision.shape as CapsuleShape3D).radius
	return TRAINER_RADIUS_FALLBACK
