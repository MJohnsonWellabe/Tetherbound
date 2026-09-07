extends RefCounted

## Stage B Wave 4 lane 4.C. CATCH ARBITRATION: exactly one player wins.
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §8. Two people throw an orb at the same
## creature in the same second. One of them keeps it, the other is TOLD why --
## never both, never neither, and never a silent loser whose fight simply ends.
##
## ## Pure, and why that is the whole reason arbitration is cheap
##
## No scene tree, no `multiplayer`, no orb node. `catch_math.gd::resolve()` was
## already a pure function of six values, five of which the host can hold or
## re-derive (§1), and `orb.gd::closest_approach_ahead()` re-derives the sixth
## from launch parameters alone. So no peer ever has to be trusted with the
## number that decides a catch, and
## `tests/test_catch_arbitration.gd` can prove "two simultaneous attempts, one
## owner" deterministically with no networking at all.
##
## ## First committed attempt owns the outcome
##
## `attempt()` claims and decides in ONE call. That is not a convenience: a
## `claim()` a caller could forget to pair with a `decide()`, or two claims
## interleaved between a check and a set, is exactly the race this file exists
## to close. There is one entry point, it is not re-entrant, and the second
## caller in the same window gets `already_resolving`.
##
## ## The window is a backstop, not the refusal
##
## A second attempt is refused for as long as the first is UNRESOLVED, which
## normally means the few seconds `catching.json` spends on the wobble; the
## winner calls `release()` when the sequence ends. `catch_arbitration_window_ms`
## only decides how long a thrower who disconnected mid-wobble can wedge
## everybody else's fight -- see the config comment for the arithmetic.

const CATCH := preload("res://scripts/combat/catch_math.gd")
const ORB := preload("res://scripts/combat/orb.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")

## `encounter_id` -> `{"peer": int, "at_ms": int, "decision": Dictionary}`.
## One entry per fight, ever: that is the invariant the whole file is.
var claims: Dictionary = {}

## Overridable so a unit test can pin the window without editing config; every
## real caller leaves it alone and gets `multiplayer.json`'s number.
var window_ms: int = -1


func _init(window_override_ms: int = -1) -> void:
	window_ms = window_override_ms


func _window_ms() -> int:
	return window_ms if window_ms >= 0 else ENCOUNTER_HOST.catch_arbitration_window_ms()


## Who currently owns the catch on this fight, or 0. A claim older than the
## window has lapsed and is not an owner -- read lazily here rather than swept,
## so a pure object needs no clock of its own.
func owner_of(encounter_id: String, now_ms: int) -> int:
	var claim: Dictionary = claims.get(encounter_id, {})
	if claim.is_empty():
		return 0
	if now_ms - int(claim.get("at_ms", 0)) >= _window_ms():
		return 0
	return int(claim.get("peer", 0))


## The winner's own decision, for the presentation it is about to play.
## Empty for anybody else, including after the window lapses.
func decision_for(encounter_id: String, peer_id: int) -> Dictionary:
	var claim: Dictionary = claims.get(encounter_id, {})
	if claim.is_empty() or int(claim.get("peer", 0)) != peer_id:
		return {}
	return (claim.get("decision", {}) as Dictionary).duplicate()


## The winner's wobble finished (either way), or the fight ended. Frees the
## fight for another throw. A peer that does not own the claim cannot release
## it, so a losing peer's own cleanup cannot cancel the winner's claim.
func release(encounter_id: String, peer_id: int) -> void:
	var claim: Dictionary = claims.get(encounter_id, {})
	if claim.is_empty() or int(claim.get("peer", 0)) != peer_id:
		return
	claims.erase(encounter_id)


func forget(encounter_id: String) -> void:
	claims.erase(encounter_id)


# --- the one entry point -----------------------------------------------------------

## §8. Claim the fight and decide the catch, atomically.
##
## `params` is host truth and nothing else:
##
##     {
##       "kind":            String,   # the record's kind; only "wild" is catchable
##       "phase":           String,   # the record's phase
##       "opponent_fainted":bool,
##       "species_id":      String,   # the record's species, for the catch rate
##       "hp_fraction":     float,    # from the record's hp, never a client's
##       "body_radius":     float,    # the HOST's body
##       "target_position": Vector3,  # the HOST's own position for the creature
##       "launch_point":    Vector3,  # from the intent -- launch PARAMETERS, not
##       "direction":       Vector3,  # an outcome; see the note below
##       "orb_id":          String,   # the orb the thrower actually SPENT
##       "roll":            float,    # the HOST's `_rng.randf()`
##     }
##
## `launch_point` and `direction` are the two values that DO come from the
## thrower, and they are safe to take because they are inputs to a computation
## the host runs itself, not a result. The host re-derives the closest approach
## with `orb.gd::closest_approach_ahead(launch_point, direction,
## host_target_position)` -- its OWN position for the creature, never the
## thrower's -- so the worst a lying thrower can do is claim to have thrown from
## somewhere they were not, which moves the ray away from the creature and makes
## their own throw worse. §2 again: no peer authors both the shot and the target
## it was measured against.
##
## `orb_id` is the orb the thrower actually spent, carried in the intent for the
## reason `combat_manager.gd`'s own comment at `_on_orb_struck` gives: the
## satchel has already lost that orb by the time this resolves, and re-querying
## "best available" can price a greater-orb throw at the basic multiplier.
##
## Returns `world_ledger.gd`'s verdict shape. On `ok` the delta carries the
## whole decision: `caught`, `chance`, `shakes`, `offset`, and `orb_id` echoed.
func attempt(encounter_id: String, peer_id: int, params: Dictionary,
		now_ms: int) -> Dictionary:
	if encounter_id.is_empty():
		return _refuse(peer_id, "malformed", "That throw did not say which fight it was for.")
	# `has()` before `get()`, for the reason the friendly-fire path states: a
	# missing key read through `get()` is null, `float(null)` is 0.0, and a
	# catch resolved at chance 0.0 would look like an honest failed throw
	# instead of a malformed intent.
	for required: String in ["kind", "phase", "target_position", "launch_point",
			"direction", "orb_id", "roll"]:
		if not params.has(required):
			return _refuse(peer_id, "malformed",
				"That throw was missing something the world needed.")

	# §8: catching is available in WILD combat only. Enforced here and not by
	# hiding a button -- 4.C must not rely on the UI never offering it, and a
	# second route into a throw is exactly the kind of thing a later milestone
	# adds without reading this file.
	if str(params["kind"]) != "wild":
		return _refuse(peer_id, "not_catchable", "You can't catch a trained creature.")
	var phase := str(params["phase"])
	if phase == "resolving" or phase == "done":
		return _refuse(peer_id, "wrong_phase", "That fight is already over.")
	if bool(params.get("opponent_fainted", false)):
		return _refuse(peer_id, "fainted", "It's out cold — too late to catch it.")

	# THE RACE, closed in three lines. Everything above is a property of the
	# fight and would answer the same for both throwers; this is the part that
	# cannot answer the same for both.
	var holder := owner_of(encounter_id, now_ms)
	if holder != 0 and holder != peer_id:
		return _refuse(peer_id, "already_resolving",
			"Somebody else's orb got there first.")
	if holder == peer_id:
		# The same peer throwing twice inside its own unresolved attempt. Not a
		# race and not a second outcome: it is told the same thing the other
		# loser is told, because the alternative is one player getting two rolls
		# by mashing.
		return _refuse(peer_id, "already_resolving", "Your orb is still shaking.")

	var offset := ORB.closest_approach_ahead(
		ENCOUNTER_HOST.to_vec3(params["launch_point"]),
		ENCOUNTER_HOST.to_vec3(params["direction"]),
		ENCOUNTER_HOST.to_vec3(params["target_position"])
	)
	var radius := maxf(0.01, float(params.get("body_radius", 0.5)))
	var decision: Dictionary = CATCH.resolve(
		SPECIES.catch_rate(str(params.get("species_id", ""))),
		clampf(float(params.get("hp_fraction", 1.0)), 0.0, 1.0),
		str(params["orb_id"]),
		offset,
		radius,
		float(params["roll"]),
		float(params.get("skill_bonus", 0.0))
	)
	decision["offset"] = offset
	decision["orb_id"] = str(params["orb_id"])
	claims[encounter_id] = {"peer": peer_id, "at_ms": now_ms, "decision": decision}
	return {
		"ok": true, "kind": "catch_attempt", "peer": peer_id, "code": "",
		"reason": "", "pending": false, "delta": decision.duplicate(),
	}


static func _refuse(peer_id: int, code: String, reason: String) -> Dictionary:
	return {
		"ok": false, "kind": "catch_attempt", "peer": peer_id, "code": code,
		"reason": reason, "pending": false, "delta": {},
	}
