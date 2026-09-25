extends RefCounted

## F03, Juno's lost companion: the pure decisions behind leading the freed
## Meadowhart home. `scripts/world/lost_companion_reunion.gd` owns the body,
## the prompt and the network; everything it decides frame to frame is asked
## here so `tests/test_lost_companion_escort.gd` can check it without a
## SceneTree. All distances are FLAT (x/z): the pasture climbs, and height must
## never break a leash or deny an arrival.

const PHASE_HELD := "held"
const PHASE_WAITING := "waiting"
const PHASE_ESCORTING := "escorting"
const PHASE_REUNITED := "reunited"

## Default refusal lines. `lost_companion_reunion.json`'s `refusal_lines`
## overrides any of them by code.
const REASONS := {
	"not_freed": "The Tether patrol is still holding her.",
	"returned": "She is already home with Juno.",
	"busy": "Someone else is already leading the Meadowhart home.",
	"already": "She is already following you.",
	"far": "Move closer to the Meadowhart.",
}


## Where the Meadowhart is in her story. The return fact outranks everything:
## a reunited Meadowhart stays with Juno even if a stale escort is still live.
static func phase(defeated: bool, returned: bool, escorting: bool) -> String:
	if returned:
		return PHASE_REUNITED
	if not defeated:
		return PHASE_HELD
	return PHASE_ESCORTING if escorting else PHASE_WAITING


## The host's answer to one tap on "Lead the Meadowhart home". `escort_peer`
## is the current leader (0 = nobody), `requester` the peer who pressed,
## `distance` how far (flat) that peer's body stands from her, and `reach` the
## furthest a press is honoured from -- the leash, so a press the local prompt
## offered is never refused merely because the host's copy of the body lags.
static func start_verdict(defeated: bool, returned: bool, escort_peer: int,
		requester: int, distance: float, reach: float) -> Dictionary:
	var code := ""
	if returned:
		code = "returned"
	elif not defeated:
		code = "not_freed"
	elif escort_peer != 0 and escort_peer == requester:
		code = "already"
	elif escort_peer != 0:
		code = "busy"
	elif distance > reach:
		code = "far"
	if code.is_empty():
		return {"ok": true, "code": "", "reason": ""}
	return {"ok": false, "code": code, "reason": str(REASONS.get(code, ""))}


static func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


## She has fallen (or been left) too far behind the leader.
static func leash_broken(creature: Vector3, leader: Vector3, leash_m: float) -> bool:
	return flat_distance(creature, leader) > leash_m


## She is close enough to Juno to count as home.
static func arrived(creature: Vector3, owner: Vector3, radius_m: float) -> bool:
	return flat_distance(creature, owner) <= radius_m


## Should the host give up this escort? The leader disconnected (no body),
## crossed into another realm, or outran the leash.
static func should_cancel(leader_present: bool, leader_realm: String, world_realm: String,
		distance: float, leash_m: float) -> bool:
	if not leader_present:
		return true
	if not leader_realm.is_empty() and not world_realm.is_empty() and leader_realm != world_realm:
		return true
	return distance > leash_m


## The point she walks toward: `follow_m` behind the leader on her own side.
## Already inside that distance, she holds where she is rather than walking
## into the player.
static func trailing_point(leader: Vector3, creature: Vector3, follow_m: float) -> Vector3:
	var away := Vector3(creature.x - leader.x, 0.0, creature.z - leader.z)
	if away.length() <= follow_m:
		return creature
	var at := leader + away.normalized() * follow_m
	at.y = creature.y
	return at


## One kinematic step toward `to`: speed grows with the gap (`gain` per
## metre) and is capped at `max_speed`, and she never overshoots. Height is
## left to the caller, which snaps it to the ground.
static func follow_step(from: Vector3, to: Vector3, delta: float, max_speed: float,
		gain: float) -> Vector3:
	var gap := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var distance := gap.length()
	if distance <= 0.0001 or delta <= 0.0:
		return from
	var speed := minf(max_speed, distance * gain)
	var step := minf(distance, speed * delta)
	return from + gap / distance * step
