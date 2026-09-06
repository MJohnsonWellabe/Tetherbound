extends "res://tests/test_case.gd"

## Stage B Wave 4 lane 4.C. THE ONE RULE, proven without a network.
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §2: **no peer may author both a hit and
## the position it landed on**, and §5: a `strike_intent` whose resolved target
## is another participant's creature or trainer is REFUSED with `friendly_target`
## before any roll -- never a damage number of zero, because a silent no-op
## passes the weaker half of the test while hiding a targeting bug.
##
## No networking, no scene tree, no `Game`. `scripts/net/encounter_host.gd` is
## pure and takes every position as a value, so two players standing beside each
## other is two `Vector3`s in an array here.
##
## Positions are laid out on the X axis at Y=0 and the moves have a 90-degree
## cone, so every case below is readable as a number line: the striker stands at
## the origin facing +X, and whatever is nearest along +X is what the swing
## resolves onto.

const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")

const HOST_PEER := 1
## The joiner's id is a large random 32-bit number, never an index -- the ENet
## spike's finding 2, restated here so nothing in this file can accidentally
## depend on peer ids being small or ordered.
const PEER_B := 1_369_099_083
const STRANGER := 42

## A quick attack's own shape, from `data/config/combat.json`'s numbers rather
## than invented ones: 2.6 m of reach through a 90-degree arc.
const QUICK := {"range": 2.6, "cone_degrees": 90.0, "power": 9.0, "is_quick": true}

var host: RefCounted = null
var encounter_id: String = ""


func before_each() -> void:
	host = ENCOUNTER_HOST.new(HOST_PEER)
	var record: Dictionary = host.call("open", HOST_PEER, "meadows", "wild", {
		"species_id": "bramblebun", "level": 4, "hp": 30.0, "hp_max": 30.0,
		"position": [2.0, 0.0, 0.0],
	})
	encounter_id = str(record["encounter_id"])
	host.call("join", encounter_id, PEER_B)


## The host's own view, with whatever bodies the case wants in it. Every
## position here is the HOST's -- that is the whole point of the argument
## existing.
func _view(origin: Vector3, bodies: Array = [], now_ms: int = 10_000) -> Dictionary:
	return {"now_ms": now_ms, "origin": origin, "bodies": bodies}


func _body(owner_peer_id: int, at: Vector3, role: String = "creature") -> Dictionary:
	return {"owner_peer_id": owner_peer_id, "position": at, "role": role}


func _strike(facing: Vector3, origin: Variant = null) -> Dictionary:
	var intent := {"encounter_id": encounter_id, "move": QUICK, "facing": facing}
	if origin != null:
		intent["origin"] = origin
	return intent


# --- §5: friendly fire is a refusal ------------------------------------------------

func test_a_strike_onto_a_teammates_creature_is_refused_not_zeroed() -> void:
	# Peer B's creature stands 1.2 m in front of the striker; the opponent is
	# further out at 2.0 m and behind it. The nearest thing the swing lands on
	# is the teammate.
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT),
		HOST_PEER,
		_view(Vector3.ZERO, [_body(PEER_B, Vector3(1.2, 0.0, 0.0))]))

	assert_false(bool(verdict.get("ok", true)),
		"a swing that resolves onto a teammate is refused, not resolved for zero damage")
	assert_eq(str(verdict.get("code", "")), "friendly_target")
	assert_false(str(verdict.get("reason", "")).is_empty(),
		"the striker is told why, in a sentence a player can be shown")
	# The other half of the assertion, and the reason a silent no-op would pass
	# a weaker test: no hit was authorised at all, so nothing downstream can
	# roll damage against anybody.
	assert_true((verdict.get("delta", {}) as Dictionary).is_empty(),
		"a refused strike authorises no hit against anyone")


func test_the_opponent_standing_nearer_than_the_teammate_is_an_ordinary_hit() -> void:
	# Same two bodies, swapped along the number line: the opponent is at 2.0 m
	# and the teammate at 2.4 m, both inside the 2.6 m reach and both in the
	# arc. The swing resolved onto the opponent, so there is nothing friendly
	# about it -- refusing here would teach two players to fight from opposite
	# sides of the field to stay out of each other's arcs.
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT),
		HOST_PEER,
		_view(Vector3.ZERO, [_body(PEER_B, Vector3(2.4, 0.0, 0.0))]))

	assert_true(bool(verdict.get("ok", false)),
		"a strike that lands on the opponent first is not friendly fire")
	var delta: Dictionary = verdict.get("delta", {})
	assert_true(delta.has("hit"), "an accepted strike says whether it connected")
	assert_true(bool(delta.get("hit", false)), "and it connected")
	assert_eq(str(delta.get("target", "")), "opponent")


func test_a_wild_body_in_the_arc_is_not_a_friendly_target() -> void:
	# `owner_peer_id` 0 is 4.B's "belongs to nobody" -- a wild creature standing
	# in the way. Swinging through one is not friendly fire; the whole rule is
	# about the people you are fighting BESIDE.
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT),
		HOST_PEER,
		_view(Vector3.ZERO, [_body(0, Vector3(1.0, 0.0, 0.0))]))

	assert_true(bool(verdict.get("ok", false)), "a wild body in the arc refuses nothing")
	assert_true(bool((verdict.get("delta", {}) as Dictionary).get("hit", false)),
		"and the swing still reaches the opponent behind it")


func test_a_creature_belonging_to_somebody_outside_the_fight_is_not_a_teammate() -> void:
	# A third player's creature standing in the meadow, not in this encounter.
	# Out of scope for §5's refusal -- and asserted, because the alternative
	# reading (refuse on any owned body) would make a busy village square
	# un-fightable.
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT),
		HOST_PEER,
		_view(Vector3.ZERO, [_body(STRANGER, Vector3(1.0, 0.0, 0.0))]))

	assert_true(bool(verdict.get("ok", false)),
		"a non-participant's creature is not a friendly target")


func test_a_teammates_trainer_is_as_protected_as_their_creature() -> void:
	# §5 says "another participant's creature OR TRAINER". The body's role is
	# reported but never gates the refusal, and this is the assertion that says
	# so.
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT),
		HOST_PEER,
		_view(Vector3.ZERO, [_body(PEER_B, Vector3(1.0, 0.0, 0.0), "trainer")]))

	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "friendly_target")


# --- §2: the host's own position decides, and a lying origin only ever costs ---------

func test_the_host_position_decides_the_hit_not_the_one_in_the_intent() -> void:
	# The peer claims to be standing right on top of the creature. The host has
	# it eight metres away, well outside the 2.6 m reach and with nothing in
	# the history to fall back on. §2: a peer that lies about its position gets
	# a strike that MISSES, not a strike that hits.
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT, Vector3(1.9, 0.0, 0.0)),
		HOST_PEER,
		_view(Vector3(-8.0, 0.0, 0.0)))

	assert_true(bool(verdict.get("ok", false)),
		"a swing at nothing is a legal swing, not a refusal")
	assert_false(bool((verdict.get("delta", {}) as Dictionary).get("hit", true)),
		"but it connects with nothing, because the host measured from its own copy")


func test_an_honestly_late_peer_gets_the_latency_tolerance() -> void:
	# The creature was at 2.0 m 100 ms ago and has since run to 9.0 m. The
	# striker swung at where it VISIBLY was, and reports standing where the
	# host has it. §5 step 3: that must land.
	var tolerance := int(ENCOUNTER_HOST.strike_latency_tolerance_ms())
	assert_true(tolerance >= 100,
		"this case needs a tolerance wider than the 100 ms lag it simulates (config says %d)"
			% tolerance)
	host.call("note_opponent_position", encounter_id, Vector3(2.0, 0.0, 0.0), 9_900)
	host.call("note_opponent_position", encounter_id, Vector3(9.0, 0.0, 0.0), 10_000)

	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT, Vector3.ZERO),
		HOST_PEER,
		_view(Vector3.ZERO, [], 10_000))

	assert_true(bool(verdict.get("ok", false)))
	assert_true(bool((verdict.get("delta", {}) as Dictionary).get("hit", false)),
		"a player on a laggy link who swung at where the creature was must land it")
	assert_eq(int((verdict.get("delta", {}) as Dictionary).get("connected_at_ms", 0)), 9_900,
		"and the host says WHICH of its own ticks the swing was judged against")


func test_a_lying_origin_loses_the_latency_tolerance_it_would_have_had() -> void:
	# The identical history, the identical host origin, the identical swing --
	# the ONE thing changed is that the peer reports standing 40 m from where
	# the host has it. It is not late, it is claiming a position, so it gets
	# only the present-tick test and the retro window closes.
	host.call("note_opponent_position", encounter_id, Vector3(2.0, 0.0, 0.0), 9_900)
	host.call("note_opponent_position", encounter_id, Vector3(9.0, 0.0, 0.0), 10_000)

	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT, Vector3(40.0, 0.0, 0.0)),
		HOST_PEER,
		_view(Vector3.ZERO, [], 10_000))

	assert_true(bool(verdict.get("ok", false)))
	assert_false(bool((verdict.get("delta", {}) as Dictionary).get("hit", true)),
		"the intent's origin can only ever cost the striker its tolerance, never win a hit")


func test_a_sample_older_than_the_tolerance_is_gone_rather_than_stale() -> void:
	# A retro window with no cutoff would let a swing land against a position
	# the creature left five seconds ago -- a ghost hit on empty grass to every
	# other player watching. The samples are pruned on the way IN.
	var tolerance := int(ENCOUNTER_HOST.strike_latency_tolerance_ms())
	host.call("note_opponent_position", encounter_id, Vector3(2.0, 0.0, 0.0), 10_000)
	host.call("note_opponent_position", encounter_id, Vector3(9.0, 0.0, 0.0),
		10_000 + tolerance + 50)

	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT, Vector3.ZERO),
		HOST_PEER,
		_view(Vector3.ZERO, [], 10_000 + tolerance + 50))

	assert_false(bool((verdict.get("delta", {}) as Dictionary).get("hit", true)),
		"a position older than the tolerance is not a position the swing can land on")

	# The prune itself, asserted separately from the behaviour above -- and
	# that separation is not decoration. Breaking the prune left this test
	# green, because `_connects_now_or_recently` applies the same cutoff again
	# when it reads. Two guards is right (a history that grows for the length
	# of a fight is a leak whether or not anything reads the old end of it),
	# but a test that only pins one of them was reporting on the pair.
	var record: Dictionary = host.call("record", encounter_id)
	var samples: Array = ((record.get("opponent", {}) as Dictionary).get("samples", []) as Array)
	assert_eq(samples.size(), 1,
		"the sample that fell out of the window is dropped on the way in, not merely skipped")


func test_a_history_that_stopped_being_written_still_cannot_be_read() -> void:
	# The path the prune alone does not cover, and the reason the read has its
	# own cutoff: samples are pruned relative to the NEWEST sample, so a host
	# that stops sampling (the opponent body despawned, the fight went to
	# another phase) leaves the last few in the array indefinitely. A strike
	# arriving two seconds later must not land on where the creature was when
	# the sampling stopped.
	var tolerance := int(ENCOUNTER_HOST.strike_latency_tolerance_ms())
	host.call("note_opponent_position", encounter_id, Vector3(2.0, 0.0, 0.0), 10_000)
	# Nothing further is written. The opponent's live position is far away.
	host.call("set_phase", encounter_id, "active")
	var record: Dictionary = host.call("record", encounter_id)
	(record["opponent"] as Dictionary)["position"] = [40.0, 0.0, 0.0]

	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT, Vector3.ZERO),
		HOST_PEER,
		_view(Vector3.ZERO, [], 10_000 + tolerance * 4))

	assert_false(bool((verdict.get("delta", {}) as Dictionary).get("hit", true)),
		"a stale history is refused at the READ as well as pruned at the write")


# --- the intents that are not strikes at all ------------------------------------------

func test_a_peer_that_is_not_in_the_fight_cannot_strike_into_it() -> void:
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT), STRANGER, _view(Vector3.ZERO))
	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "not_participant")


func test_a_strike_naming_no_live_encounter_is_refused() -> void:
	var verdict: Dictionary = host.call("validate_strike",
		{"encounter_id": "no-such-fight", "move": QUICK, "facing": Vector3.RIGHT},
		HOST_PEER, _view(Vector3.ZERO))
	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "unknown_encounter")


func test_an_intent_missing_its_move_is_malformed_rather_than_resolved_at_the_origin() -> void:
	# The trap this assertion exists for: a missing key read through `get()`
	# comes back null, `Vector3(null)` is the world origin and `float(null)` is
	# 0.0, so a malformed intent silently becomes a swing with no reach resolved
	# at (0,0,0) instead of a refusal. `has()` before `get()` is what stops that,
	# and this is the test that keeps it there.
	var no_move: Dictionary = host.call("validate_strike",
		{"encounter_id": encounter_id, "facing": Vector3.RIGHT},
		HOST_PEER, _view(Vector3.ZERO))
	assert_false(bool(no_move.get("ok", true)))
	assert_eq(str(no_move.get("code", "")), "malformed")

	var no_facing: Dictionary = host.call("validate_strike",
		{"encounter_id": encounter_id, "move": QUICK},
		HOST_PEER, _view(Vector3.ZERO))
	assert_false(bool(no_facing.get("ok", true)))
	assert_eq(str(no_facing.get("code", "")), "malformed")


func test_a_strike_into_a_fight_that_is_resolving_is_refused() -> void:
	host.call("set_phase", encounter_id, "resolving")
	var verdict: Dictionary = host.call("validate_strike",
		_strike(Vector3.RIGHT), HOST_PEER, _view(Vector3.ZERO))
	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "wrong_phase")


# --- §6 and §9: joining and leaving do not reset a fight ------------------------------

func test_joining_a_live_fight_changes_nothing_but_who_is_in_it() -> void:
	var fresh: RefCounted = ENCOUNTER_HOST.new(HOST_PEER)
	var record: Dictionary = fresh.call("open", HOST_PEER, "meadows", "wild",
		{"species_id": "bramblebun", "hp": 30.0, "hp_max": 30.0})
	var id := str(record["encounter_id"])
	fresh.call("set_opponent_hp", id, 11.0, 30.0)

	var verdict: Dictionary = fresh.call("join", id, PEER_B)
	assert_true(bool(verdict.get("ok", false)), "a second player joins a live fight")
	assert_almost_eq(float(fresh.call("opponent_hp", id)), 11.0, 0.001,
		"joining does not heal the opponent -- no reset, for anyone already fighting")
	assert_eq(str(fresh.call("phase", id)), "active", "and does not change the phase")
	assert_eq((fresh.call("participants_of", id) as Array).size(), 2)


func test_the_last_participant_leaving_ends_the_fight_with_the_hp_it_has() -> void:
	host.call("set_opponent_hp", encounter_id, 4.0, 30.0)
	host.call("leave", encounter_id, PEER_B)
	assert_eq(str(host.call("phase", encounter_id)), "active",
		"one player walking away does not end a fight somebody else is still in")
	assert_eq((host.call("participants_of", encounter_id) as Array).size(), 1)

	host.call("leave", encounter_id, HOST_PEER)
	assert_eq(str(host.call("phase", encounter_id)), "done")
	assert_almost_eq(float(host.call("opponent_hp", encounter_id)), 4.0, 0.001,
		"a creature that heals instantly because everyone walked away is an exploit")
