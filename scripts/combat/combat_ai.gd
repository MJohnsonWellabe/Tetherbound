extends RefCounted

## The wild creature's combat brain.
##
## Pure: it is handed a snapshot of the situation and returns what to do. No
## nodes, no timers of its own, no access to the scene. The node layer measures
## the distance, applies the movement and counts down the clocks.
##
## That split exists because this is the part of M2 most likely to be wrong.
## "The enemy never lets up", "it backs off too far", "it attacks the instant I
## finish attacking" are all things the owner will say, and each of them is a
## question about this decision table. Being able to ask that question in a unit
## test rather than by playing a fight and squinting is worth the indirection.
##
## The behaviour it implements is the smallest thing that is not a punching bag:
##
##   CLOSE      walk towards the player's creature until inside preferred range
##   TELEGRAPH  rooted, winding up, visible
##   RECOVER    rooted, vulnerable — this is the player's punish window
##   REPOSITION back off and circle, so the fight is not two creatures standing
##              in each other's faces trading hits
##
## Not implemented on purpose: feints, blocking, retreating on low health,
## reacting to the player's wind-up. Every one of those is a reason for the
## fight to feel unfair before it has been played once.

enum Intent {
	CLOSE,
	TELEGRAPH,
	RECOVER,
	REPOSITION,
	IDLE,
}


## Decide what the opponent should be doing.
##
## `state` is what it is doing now, `distance` is the horizontal gap to the
## player's creature, and the three timers are how long is left in the current beat.
## Returns the intent for this frame; the caller starts a new beat whenever the
## returned intent differs from the one it was in.
static func decide(
	state: Intent,
	distance: float,
	timer: float,
	cooldown: float,
	cfg: Dictionary
) -> Intent:
	var preferred := float(cfg.get("preferred_range", 2.1))

	match state:
		Intent.TELEGRAPH:
			# A committed wind-up runs to completion. An enemy that can cancel
			# its own telegraph makes the telegraph worthless, and the telegraph
			# is the only warning the fight gives.
			return Intent.TELEGRAPH if timer > 0.0 else Intent.RECOVER

		Intent.RECOVER:
			# Rooted until recovery ends. This is the window the player is meant
			# to punish, and shortening it under pressure would delete the only
			# reason to watch what the opponent is doing.
			return Intent.RECOVER if timer > 0.0 else Intent.REPOSITION

		Intent.REPOSITION:
			if timer > 0.0:
				return Intent.REPOSITION
			return Intent.CLOSE

		_:
			# CLOSE or IDLE: attack if in reach and off cooldown, otherwise walk in.
			if distance <= preferred and cooldown <= 0.0:
				return Intent.TELEGRAPH
			return Intent.CLOSE


## How long the beat that was just entered should last.
static func duration_for(intent: Intent, cfg: Dictionary) -> float:
	match intent:
		Intent.TELEGRAPH:
			return float(cfg.get("telegraph", 0.55))
		Intent.RECOVER:
			return float(cfg.get("recovery", 0.75))
		Intent.REPOSITION:
			return float(cfg.get("reposition_time", 1.0))
		_:
			return 0.0


## Is the opponent rooted this frame? Rooted beats are what the player pushes
## against; if the answer were never true the fight would have no rhythm.
static func is_rooted(intent: Intent) -> bool:
	return intent == Intent.TELEGRAPH or intent == Intent.RECOVER


## Where to move, as a unit direction, given the direction towards the target.
##
## Repositioning goes backwards and sideways at once rather than straight back:
## a straight retreat is a rubber band that snaps the fight back to the same
## spot, whereas an arc moves it around the arena. `side_sign` is +1 or -1 and
## is chosen once per reposition by the caller, so the opponent commits to a
## direction instead of jittering between them.
static func movement_for(intent: Intent, towards_target: Vector3, side_sign: float) -> Vector3:
	var forward := Vector3(towards_target.x, 0.0, towards_target.z)
	if forward.length() < 0.001:
		return Vector3.ZERO
	forward = forward.normalized()

	match intent:
		Intent.CLOSE:
			return forward
		Intent.REPOSITION:
			var side := forward.cross(Vector3.UP).normalized() * signf(side_sign)
			return (-forward * 0.65 + side * 0.75).normalized()
		_:
			return Vector3.ZERO


static func speed_for(intent: Intent, cfg: Dictionary) -> float:
	match intent:
		Intent.CLOSE:
			return float(cfg.get("chase_speed", 4.6))
		Intent.REPOSITION:
			return float(cfg.get("reposition_speed", 3.8))
		_:
			return 0.0
