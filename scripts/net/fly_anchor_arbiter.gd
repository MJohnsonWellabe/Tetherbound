extends RefCounted

## Stage B Wave 6 lane 6.C. WHERE A FLIER IS ALLOWED TO PUT THEIR FEET DOWN.
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §2 is one rule: **no peer may author
## both an action and the position it was measured against.** The protocol
## states it about a strike, because a strike is where it was first going to be
## broken, but a Fly landing is the same shape wearing different clothes. A
## client that ends a glide sets `safe_anchor` to wherever its own body happens
## to be standing, and every later `recover_to_anchor()` teleports it back
## there -- so an anchor a client authors alone is a client-authored teleport
## destination, valid for the whole rest of the session. The exact thing §2
## exists to stop.
##
## So the host decides. A client PROPOSES an anchor; this file is the rule the
## host applies to that proposal, and the anchor a client finally commits is
## the one the HOST hands back, computed from the host's own ground.
##
## ## Pure, and why
##
## No scene tree, no `multiplayer`, no player. `catch_arbiter.gd`'s header
## gives the reason and it holds here for the same money: everything this
## decision turns on is a handful of numbers the host already has, so the
## decision can be a function of them, be read in one screen, and be exercised
## by a test with no networking at all. The two things it CANNOT do itself --
## cast a ray, and know who sent the packet -- are done by the caller and
## handed in as `ground_y`, `ground_normal_y` and `sender`.
##
## ## What the host is really checking
##
## Three questions, and only the second is about geometry:
##
##   1. **Is this peer allowed to speak for this body?** The sender id, against
##      the body's owner. A peer proposing an anchor for somebody else's
##      trainer is not a landing, it is a shove.
##   2. **Is there floor there, in the host's own world?** Not the client's:
##      the host raycasts under the claim in the realm the host holds that peer
##      in, and refuses a claim hanging in the air, one on a wall, and one over
##      ground the host has no collision for.
##   3. **Is the claim anywhere near where the host thinks that peer IS?** The
##      host's copy of the body is walked through the host's own
##      `move_and_slide()` (`remote_trainer.gd::_follow()`), so its position is
##      the host's simulation rather than the client's assertion. A claim far
##      from it is a teleport request wearing a landing's clothes, and is
##      refused whatever the ground under it looks like.
##
## The accepted anchor is then rebuilt: the claim's X and Z, and the host's own
## ground height. A client cannot commit its own Y even on a claim that passes.

## How far, horizontally, a claimed anchor may sit from the host's own position
## for that peer. Generous on purpose: the host's copy of a client's body is an
## interpolated follower (`remote_trainer.gd::INTERP_HALF_LIFE_S`), and the
## moment a flight ends is exactly the moment that body is furthest behind --
## it has just stopped being position-assigned in the air and is re-acquiring
## the floor. Six metres is well outside that lag and far inside "somewhere
## else entirely". TUNABLE, `data/config/fly_traversal.json`.
const DEFAULT_MAX_DRIFT_M := 6.0
## How far, vertically, the claim may sit from the ground the host found under
## it. A landing puts feet on floor; a couple of metres covers a body settling
## and a shallow step, and refuses a claim floating over the same XZ.
const DEFAULT_MAX_HEIGHT_M := 2.5
## How deep below the claim the host looks for floor before calling it air.
const DEFAULT_PROBE_M := 6.0
## The steepest ground a landing may be committed to, as the cosine of the
## slope. `player_controller`'s own body uses 45 degrees; a landing anchor is a
## place `recover_to_anchor()` will later drop a trainer onto, so it holds the
## same bar rather than a looser one.
const DEFAULT_MIN_NORMAL_Y := 0.7071
## Lifted off the found ground so the committed anchor is a hair above the
## surface rather than inside it -- the same 8 cm `fly_controller.gd`'s own
## recovery already adds to its ray hit.
const GROUND_EPSILON_M := 0.08

const CODE_OK := "ok"
const CODE_NOT_YOURS := "not_yours"
const CODE_MALFORMED := "malformed"
const CODE_WRONG_REALM := "wrong_realm"
const CODE_NO_GROUND := "no_ground"
const CODE_NOT_FLOOR := "not_floor"
const CODE_TOO_HIGH := "too_high"
const CODE_TOO_FAR := "too_far"
const CODE_SEALED := "sealed"


## Decide one landing-anchor proposal. Host-side only.
##
## `params` is host truth plus exactly two client-supplied numbers, and those
## two are an INPUT to the host's own test rather than a result of it -- the
## same bargain `catch_arbiter.gd::attempt()` strikes with `launch_point` and
## `direction`:
##
##     {
##       "peer":            int,     # the body's owner, off the host's node
##       "sender":          int,     # multiplayer.get_remote_sender_id()
##       "claim":           Vector3, # CLIENT: where it says it landed
##       "claim_realm":     String,  # CLIENT: the realm it says that is in
##       "host_position":   Vector3, # the host's own position for that body
##       "host_realm":      String,  # the realm the host holds that body in
##       "ground_y":        float,   # host raycast; NAN when nothing was hit
##       "ground_normal_y": float,   # host raycast
##       "restricted":      String,  # non-empty when the host knows the claim
##                                   # is inside a sealed volume; "" when the
##                                   # host has no opinion (see the caller)
##     }
##
## Returns `{"ok", "code", "reason", "anchor": Vector3}`. `reason` is written
## to be shown to the player who was refused, because they are about to be put
## back somewhere and a silent teleport is the worse bug.
##
## `has()` before every `get()`, for `catch_arbiter.gd`'s measured reason: a
## missing key read straight through `get()` is null, `float(null)` is 0.0, and
## a malformed proposal would otherwise be silently decided as a claim to have
## landed at the world origin -- which, on a world whose origin is real ground,
## would pass.
static func verdict(params: Dictionary) -> Dictionary:
	for required: String in ["peer", "sender", "claim", "claim_realm",
			"host_position", "host_realm", "ground_y", "ground_normal_y"]:
		if not params.has(required):
			return _refuse(CODE_MALFORMED,
				"That landing did not say where it was.", params)

	var peer := int(params["peer"])
	var sender := int(params["sender"])
	if peer == 0 or sender != peer:
		return _refuse(CODE_NOT_YOURS,
			"That landing was not yours to claim.", params)

	var claim_realm := str(params["claim_realm"])
	var host_realm := str(params["host_realm"])
	if claim_realm.is_empty() or claim_realm != host_realm:
		return _refuse(CODE_WRONG_REALM,
			"You are not standing in the place that landing was for.", params)

	var claim: Vector3 = params["claim"]
	var host_position: Vector3 = params["host_position"]
	var drift := Vector2(claim.x - host_position.x, claim.z - host_position.z).length()
	if drift > _tunable(params, "max_drift_m", DEFAULT_MAX_DRIFT_M):
		return _refuse(CODE_TOO_FAR,
			"The wind put you down somewhere else.", params)

	var ground_y := float(params["ground_y"])
	if is_nan(ground_y):
		return _refuse(CODE_NO_GROUND,
			"There is nothing to stand on there.", params)
	if float(params["ground_normal_y"]) < _tunable(params, "min_normal_y", DEFAULT_MIN_NORMAL_Y):
		return _refuse(CODE_NOT_FLOOR,
			"That slope is too steep to land on.", params)
	if absf(claim.y - ground_y) > _tunable(params, "max_height_m", DEFAULT_MAX_HEIGHT_M):
		return _refuse(CODE_TOO_HIGH,
			"You are not on the ground you say you are.", params)

	var sealed := str(params.get("restricted", ""))
	if not sealed.is_empty():
		return _refuse(CODE_SEALED,
			"This wind route is still sealed: %s." % sealed, params)

	return {
		"ok": true,
		"code": CODE_OK,
		"reason": "",
		# The host's ground, never the claim's Y. A proposal that passes every
		# other test still does not get to choose its own height.
		"anchor": Vector3(claim.x, ground_y + GROUND_EPSILON_M, claim.z),
	}


## How deep the CALLER should probe for ground, so the host's ray and this
## file's tolerances cannot drift apart in two places.
static func probe_depth_m(config: Dictionary = {}) -> float:
	return _tunable({"config": config}, "probe_m", DEFAULT_PROBE_M)


static func _tunable(params: Dictionary, key: String, fallback: float) -> float:
	var config: Variant = params.get("config", {})
	if not (config is Dictionary) or not (config as Dictionary).has(key):
		return fallback
	return float((config as Dictionary)[key])


## The refused anchor is deliberately the host's own position for that peer,
## not `Vector3.INF` and not the claim: a caller that ignores `ok` and commits
## the returned anchor anyway lands the player where the HOST already thinks
## they are, which is the safe failure rather than a silent teleport.
static func _refuse(code: String, reason: String, params: Dictionary) -> Dictionary:
	var fallback: Variant = params.get("host_position", Vector3.ZERO)
	return {
		"ok": false,
		"code": code,
		"reason": reason,
		"anchor": fallback if fallback is Vector3 else Vector3.ZERO,
	}
