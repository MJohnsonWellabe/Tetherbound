extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 4 lane 4.C. THE player-visible outcome of the lane: two people
## fight one creature together, and neither of them can hit the other.
##
##   tools/net/run_net_smoke.sh shared_wild_fight
##
## ## What it asserts
##
## Peer 0 hosts and engages a wild creature through the production press. The
## host mints an encounter record (`docs/specs/MP_ENCOUNTER_PROTOCOL.md` §3) and
## announces it; peer 1 sees the announcement and JOINS the live fight (§6) --
## no reset, and the opponent does not get its health back. Both players then
## land a strike, and the health bar both of them are drawing is THE SAME
## NUMBER, because both are rendering the host's record rather than each
## decrementing a local copy.
##
## Then the rule the lane exists for (§5): peer 1 swings at peer 0's creature.
## The host REFUSES it with `friendly_target`, and peer 0's creature takes
## nothing. **Both halves are asserted.** A silent no-op -- a targeting bug that
## resolved onto the teammate and then rolled zero -- would pass the second half
## while failing the player, who would be left unable to tell "I swung at my
## friend" from "the game dropped my input".
##
## ## Why the friendly strike is submitted rather than pressed
##
## A button press always faces the opponent: `combat_manager.gd::_start_action()`
## calls `face_towards(_wild.centre())` on the way into the wind-up. So a swing
## aimed at a teammate cannot be produced by pressing a button, which is exactly
## why §5's refusal is a HOST rule and not a UI one -- 4.C must not rely on the
## UI never offering it. The harness's `strike` arm submits a `strike_intent`
## through `submit_encounter_intent()`, the same door `combat_manager.gd` itself
## submits through, with a facing of its choosing: what a modified client could
## say, said out loud.
##
## ## The geometry, and why the numbers are what they are
##
## Everything is placed relative to the OPPONENT'S OWN POSITION as the host
## reports it in the record, re-read before each phase, because the creature is
## a live AI and moves between them.
##
##   phase 1  peer 0's creature at opponent + (0, 0, -1.5)   facing +Z
##            peer 1's creature at opponent + (0, 0, +1.5)   facing -Z
##            Both inside reach (`combat.json` floors it at
##            (r+r) * body_clearance 2.75 + 0.5, about 3.25 m for two ordinary
##            bodies), and each facing directly AWAY from the other, so neither
##            is in the other's arc and both strikes are ordinary hits.
##
##   phase 2  both creatures at opponent + (8, 0, z), 1.3 m apart
##            8 m is chosen against the opponent's own `chase_speed` of
##            4.6 m/s: the whole of phase 2 is about 0.6 s of settling, so the
##            creature can close at most ~2.7 m of it and is still some 5 m
##            away -- comfortably outside its 3.25 m reach -- when peer 0's HP
##            is read. The bar is that peer 0's creature took NOTHING, and a
##            blow from the opponent landing inside the window would fail this
##            for a reason that is not the one under test. It is inside the
##            11 m arena radius, measured from an arena centred between the two
##            fighters, so `combat_arena.hold_inside()` never yanks anybody.
const NEAR_Z := 1.5
const AWAY_X := 8.0
const APART_Z := 1.1
## Frames each placement is given to settle. `remote_creature.gd` interpolates
## with a 0.08 s half-life, so 20 frames is about four half-lives -- and the
## window is deliberately short, for the reason phase 2's comment gives.
const PLACE_SETTLE := 20
const STRIKE_SETTLE := 15
## How many swings each player gets at a creature that is actively running
## around. See the loop's own comment for why this is a swing budget and not a
## retry budget.
const SWINGS := 5

## How many times to ask peer 1 for the host's verdict on its friendly swing
## before calling it lost. Each poll is a coordinator round trip to the peer, so
## this is generous in wall-clock without being a fixed wait: a refusal that
## arrives on the first poll costs one, and the assertion below still fails if
## none ever arrives. Sized so the loop outlasts 7.A's jitter profile (150 ms
## delay / 30 ms jitter) rather than only loopback.
const REFUSAL_POLLS := 40


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
	check(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var ctx = await probe(i, "input_context")
		check(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it there are no remote bodies to see")
	if not have_session:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])
	# --- end of the copied handshake block ------------------------------------

	# Both players need a creature out before either can fight with one.
	for i in 2:
		var deployed: Dictionary = await step(i, "deploy_creature", {})
		check(str(deployed.get("verdict", "")) == "PASS",
			"peer %d deployed its own creature (%s)" % [i, str(deployed.get("detail", ""))])

	# --- peer 0 starts a fight ------------------------------------------------
	var engaged: Dictionary = await step(0, "engage_wild", {})
	check(str(engaged.get("verdict", "")) == "PASS",
		"peer 0 engaged a wild creature (%s)" % str(engaged.get("detail", "")))
	if str(engaged.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var host_view: Dictionary = await _encounter(0)
	var encounter_id := str(host_view.get("id", ""))
	check(not encounter_id.is_empty(), "the host minted an encounter record for that fight")
	check(str(host_view.get("kind", "")) == "wild",
		"and it is a wild encounter (got '%s')" % str(host_view.get("kind", "")))
	check(str(host_view.get("realm", "")) != "",
		"stamped with an explicit realm (D97), got '%s'" % str(host_view.get("realm", "")))
	var full_hp := float(host_view.get("opponent_hp", -1.0))
	check(full_hp > 0.0, "the record carries the opponent's hit points (%.1f)" % full_hp)

	# --- peer 1 joins it (§6) -------------------------------------------------
	var guest_before: Dictionary = await _encounter(1)
	check((guest_before.get("joinable", []) as Array).has(encounter_id),
		"peer 1 was told the fight exists and can be joined (announced ids: %s)"
			% str(guest_before.get("joinable", [])))

	# The joiner travels to the fight before joining it. Two things depend on
	# this and both are real rather than harness convenience: `join_encounter()`
	# picks this peer's NEAREST wild as the body it fights beside (4.B's H1 --
	# wilds are not replicated, so a joiner has no copy of the host's), and
	# `combat_arena.hold_inside()` will hold this peer's creature inside an
	# arena centred wherever that body is. A player who joined a fight from
	# across the meadow would be fighting a different creature in a different
	# field; a player who walks over first picks the same spawn out of the same
	# seeded table, a couple of metres from where the host has it.
	var here := _vec(host_view.get("opponent_pos", []))
	check(here != Vector3.INF, "the announcement says where the fight is happening")
	var travelled: Dictionary = await step(1, "teleport",
		{"at": [here.x - 2.5, here.y + 1.0, here.z]})
	check(str(travelled.get("verdict", "")) == "PASS",
		"peer 1 travelled to the fight (%s)" % str(travelled.get("detail", "")))

	var joined_fight: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(joined_fight.get("verdict", "")) == "PASS",
		"peer 1 joined the fight already in progress (%s)" % str(joined_fight.get("detail", "")))

	var after_join_host: Dictionary = await _encounter(0)
	check((after_join_host.get("participants", []) as Array).size() == 2,
		"the host's record now holds 2 participants (got %d)"
			% (after_join_host.get("participants", []) as Array).size())
	check(str(after_join_host.get("phase", "")) == "active",
		"joining did not change the phase (got '%s')" % str(after_join_host.get("phase", "")))
	check(float(after_join_host.get("opponent_hp", -1.0)) <= full_hp + 0.001,
		"and it did not refill the opponent -- no reset for the player already fighting")
	var guest_after: Dictionary = await _encounter(1)
	check(str(guest_after.get("bound_id", "")) == encounter_id,
		"peer 1's fight is bound to the SAME record (got '%s')" % str(guest_after.get("bound_id", "")))

	# --- both land a strike, and the bar is one number ------------------------
	var hp_before := float(after_join_host.get("opponent_hp", -1.0))
	for mover in 2:
		var host_hp := hp_before
		var swings := 0
		# Up to SWINGS swings, each one a fresh read of where the host holds the
		# opponent, a step back into reach of it, and a real `strike_intent`.
		#
		# NOT a weakened assertion, and the reason is worth stating because "run
		# it again until it passes" is exactly the shape of one. The opponent is
		# a live AI that chases whichever creature it is engaged with at
		# `chase_speed` 4.6 m/s, so between the frame this smoke reads its
		# position and the frame the host resolves the swing it has genuinely
		# moved -- and a swing at where a creature was a moment ago genuinely
		# misses, which is `docs/decisions/D07`'s whole point ("attacks are aimed
		# and can miss"). A player who misses swings again. The claim under test
		# is that peer `mover` CAN land a blow on the shared opponent and that
		# both peers then read the same bar, not that any particular swing of a
		# moving target connects; a peer whose strikes never reached the host, or
		# were refused, or landed only on its own copy, fails this in every
		# swing.
		while swings < SWINGS and host_hp >= hp_before - 0.001:
			swings += 1
			var view: Dictionary = await _encounter(0)
			var opponent := _vec(view.get("opponent_pos", []))
			check(opponent != Vector3.INF, "the record says where the host holds the opponent")
			if opponent == Vector3.INF:
				break
			# Each creature stands on its own side of the opponent, facing it --
			# and therefore facing directly away from the other player's
			# creature, so neither is ever in the other's arc here.
			var side := -NEAR_Z if mover == 0 else NEAR_Z
			var stand := opponent + Vector3(0.0, 0.0, side)
			var placed: Dictionary = await step(mover, "place_creature",
				{"at": [stand.x, stand.y, stand.z],
				 "face": [opponent.x, opponent.y, opponent.z], "settle": PLACE_SETTLE})
			check(str(placed.get("verdict", "")) == "PASS",
				"peer %d stood its creature beside the opponent (%s)"
					% [mover, str(placed.get("detail", ""))])

			# The facing is taken from the LAST possible read, so a swing that
			# misses missed because the creature moved, not because the smoke
			# aimed at a stale number it could have refreshed.
			var fresh := _vec((await _encounter(0)).get("opponent_pos", []))
			var aim_at := opponent if fresh == Vector3.INF else fresh
			var toward := aim_at - stand
			var struck: Dictionary = await step(mover, "strike",
				{"facing": [toward.x, toward.y, toward.z], "slot": "quick",
				 "settle": STRIKE_SETTLE})
			check(str(struck.get("verdict", "")) == "PASS",
				"peer %d swung at the opponent (%s)" % [mover, str(struck.get("detail", ""))])
			host_hp = float((await _encounter(0)).get("opponent_hp", -1.0))

		check(host_hp < hp_before - 0.001,
			"peer %d landed a blow on the shared opponent within %d swings: %.1f -> %.1f on the host"
				% [mover, swings, hp_before, host_hp])
		var guest_hp := float((await _encounter(1)).get("opponent_hp", -1.0))
		# §3: the record's hp is THE hit points, and both peers render it. A
		# client that decremented its own copy "for responsiveness" would
		# diverge here by exactly one blow.
		check(absf(guest_hp - host_hp) < 0.001,
			"both peers draw the same health bar after it (host %.3f, guest %.3f)"
				% [host_hp, guest_hp])
		hp_before = host_hp

	# --- §5: peer 1 swings at peer 0's creature -------------------------------
	var stage: Dictionary = await _encounter(0)
	var opponent_now := _vec(stage.get("opponent_pos", []))
	if opponent_now == Vector3.INF:
		check(false, "the record still says where the opponent is")
		quit(await finish())
		return
	var victim_spot := opponent_now + Vector3(AWAY_X, 0.0, 0.0)
	var v_placed: Dictionary = await step(0, "place_creature",
		{"at": [victim_spot.x, victim_spot.y, victim_spot.z], "settle": PLACE_SETTLE})
	check(str(v_placed.get("verdict", "")) == "PASS",
		"peer 0's creature stepped clear of the opponent (%s)" % str(v_placed.get("detail", "")))
	# Peer 1's creature is placed relative to where peer 0's creature ACTUALLY
	# came to rest, not to where it was asked to stand. A body dropped onto
	# sloping ground settles and slides -- measured at over 2 m across a
	# 20-frame settle -- and chaining the second placement off the first's real
	# position is what keeps the two of them within one swing of each other
	# whatever the ground did to the first.
	var settled := _vec((await _encounter(0)).get("my_creature_pos", []))
	var striker_spot := (victim_spot if settled == Vector3.INF else settled) \
		+ Vector3(0.0, 0.0, APART_Z)
	var s_placed: Dictionary = await step(1, "place_creature",
		{"at": [striker_spot.x, striker_spot.y, striker_spot.z], "settle": PLACE_SETTLE})
	check(str(s_placed.get("verdict", "")) == "PASS",
		"peer 1's creature stood next to it (%s)" % str(s_placed.get("detail", "")))

	var victim_before: Dictionary = await _encounter(0)
	var victim_hp := float(victim_before.get("my_creature_hp", -1.0))
	check(victim_hp > 0.0, "peer 0's creature is alive to be swung at (%.1f hp)" % victim_hp)

	# The facing is derived from where the two creatures ACTUALLY ended up, not
	# from where they were asked to stand. Bodies settle onto sloping ground and
	# slide while they do, and a swing aimed at the intended spot rather than
	# the real one can miss its own target's cone -- which would fail this for
	# the wrong reason, and would fail it by NOT refusing, i.e. in exactly the
	# direction that looks like the feature working.
	var victim_at := _vec(victim_before.get("my_creature_pos", []))
	var striker_at := _vec((await _encounter(1)).get("my_creature_pos", []))
	check(victim_at != Vector3.INF and striker_at != Vector3.INF,
		"both creatures report where they are standing")
	var at_teammate := victim_at - striker_at
	at_teammate.y = 0.0
	# A diagnostic bound, not the claim. Its only job is to make "the swing
	# never reached the teammate" legible if the refusal assertion below fails:
	# a swing that fell short would be refused by nothing, which reads exactly
	# like the feature working. The real reach for two ordinary bodies is
	# `combat.json`'s floor of (r + r) * body_clearance 2.75 + 0.5, a little
	# over 3 m; 4.0 is that with room for two bodies of unequal size.
	check(at_teammate.length() < 4.0,
		"the two creatures are within one swing of each other (%.2f m apart)"
			% at_teammate.length())

	var friendly: Dictionary = await step(1, "strike",
		{"facing": [at_teammate.x, 0.0, at_teammate.z], "slot": "quick",
		 "settle": STRIKE_SETTLE})
	check(str(friendly.get("verdict", "")) == "PASS",
		"peer 1's swing at its teammate reached the host (%s)" % str(friendly.get("detail", "")))

	# POLLED, not read once after a fixed settle. This was a flake and a jitter
	# failure and they were the same defect.
	#
	# The refusal is the HOST's answer and it comes back over the wire, so the
	# only thing `STRIKE_SETTLE` frames buys is "probably long enough on
	# loopback". Measured: this smoke ran 5 of 7 on one branch against 6 of 7 on
	# its untouched base, and under 7.A's proxy at 150 ms delay / 30 ms jitter
	# / 1 % loss it lost the refusal MESSAGE every time while the safety itself
	# held (7.A finding F7, recorded and deliberately not tuned). Both were one
	# read landing before the answer arrived.
	#
	# This is a fix at the cause and NOT a widened tolerance: the assertion
	# still fails if the refusal never comes, if it comes with the wrong code,
	# or if it comes without a sentence. What it no longer does is fail because
	# a round trip took longer than a quarter of a second. Same shape as the
	# `engage` binding poll in `peer_runner.gd::_step_engage` -- on a client,
	# `submit()` answers `{"ok": false, "pending": true}` and the verdict
	# follows a round trip later, so a single read of a host's answer is the
	# "pending is not a refusal" trap wearing a different hat.
	var refusal: Dictionary = {}
	var refusal_polls := 0
	while refusal_polls < REFUSAL_POLLS:
		refusal_polls += 1
		refusal = ((await _encounter(1)).get("refusal", {}) as Dictionary)
		if not str(refusal.get("code", "")).is_empty():
			break
	# HALF ONE: the host said no, out loud, with the code §5 names.
	check(str(refusal.get("code", "")) == "friendly_target",
		"the host refused it with `friendly_target` after %d poll(s) (got code '%s', reason '%s')"
			% [refusal_polls, str(refusal.get("code", "")), str(refusal.get("reason", ""))])
	check(not str(refusal.get("reason", "")).is_empty(),
		"and gave the striker a sentence a player can be shown")

	# HALF TWO: the teammate took nothing. Asserted alongside the refusal and
	# never instead of it -- a silent no-op passes this line while hiding a
	# targeting bug, which is the whole reason both halves are here.
	var victim_after := float((await _encounter(0)).get("my_creature_hp", -1.0))
	check(absf(victim_after - victim_hp) < 0.001,
		"peer 0's creature took nothing from it (%.3f before, %.3f after)"
			% [victim_hp, victim_after])

	# And the opponent took nothing either: a refused strike is refused BEFORE
	# any roll, so there is no blow for it to have landed somewhere else.
	var opponent_after := float((await _encounter(0)).get("opponent_hp", -1.0))
	check(absf(opponent_after - hp_before) < 0.001,
		"and the opponent took nothing from it either (%.3f before, %.3f after)"
			% [hp_before, opponent_after])

	quit(await finish())


## This peer's view of the fight, from `tools/net/peer_runner.gd`'s `encounter`
## probe: the record it is rendering, its own creature, and the last refusal it
## was given.
func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return value if value is Dictionary else {}


## An `[x, y, z]` from a probe. `Vector3.INF` when the field is missing, so
## "the record said nothing" is distinguishable from "the origin".
static func _vec(value: Variant) -> Vector3:
	if not (value is Array) or (value as Array).size() != 3:
		return Vector3.INF
	var a: Array = value
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
