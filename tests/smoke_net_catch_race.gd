extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B, `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` §17 item 6 — **the
## first-successful-catch rule**. The row read: `test_catch_arbitration` (pure,
## deterministic). **No net smoke** — recorded as owed, not implied.
##
##   tools/net/run_net_smoke.sh catch_race
##
## `tests/test_catch_arbitration.gd` proves `catch_arbiter.gd` is correct as a
## pure function, with no networking at all, and that is the right place to
## prove it. What it cannot prove is that the two throws ever REACH that
## function from two processes — that the intent leaves a client, that the host
## arbitrates a remote throw against its own, and that the loser is told over
## the wire rather than left watching an orb that never lands. This file is
## that half and only that half.
##
## ## What it asserts
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §8. Two people throw at one wild
## creature inside one round trip:
##
##   * **exactly one of them owns the outcome** — one peer's `catch_attempt`
##     comes back `ok` with a decision, the other does not, and it is never
##     both and never neither;
##   * **the loser is told why**, in a sentence a player can act on, and gets no
##     decision of its own;
##   * **the creature is not duplicated** — across BOTH peers, the number of
##     creatures owned rises by exactly the number of throws the host decided
##     were catches, which is 0 or 1 and can never be 2;
##   * **the five-creature limit holds** (CLAUDE.md, a hard rule): neither peer
##     ever holds six, and a catch into a full belt goes to the release
##     ceremony's seam (`Game.pending_catch`, exactly one, never saved), which
##     is why `owned` below counts that seam beside the party.
##
## ## Why both peers throw at one wall-clock instant
##
## Lane 3.B hit this first and its answer is reused rather than reinvented. The
## coordinator talks to each peer over its own TCP control socket and awaits
## each verdict before it sends the next, so two "throw now" messages are always
## a round trip apart — the second thrower would arrive after the first was
## already resolved and be refused for a reason that is not a race. Given
## `at_unix_ms`, `catch_throw` ARMS the throw and answers immediately, so both
## peers can be armed milliseconds apart and then throw together seconds later,
## with both intents in flight before either is decided. This smoke deliberately
## does not care which of them wins: it asserts the invariant, not the winner.
##
## The client won CI run 34221457038 (2026-09-08): scheduling can put its intent
## first even though the host usually wins. A client's synchronous submit return
## stays `pending` after its real host reply has played a resolution. Read that
## completed resolution too, or this smoke incorrectly requires a host winner.
## It is evidence that the SECOND throw to arrive is refused, told why, and
## pays nothing, which is what §8 promises;
## `test_catch_arbitration.gd::test_the_order_decides_it_and_nothing_else_does`
## is where "the host's own throw loses it like anybody else's" is proven, and
## it can prove that because it is pure.
##
## ## The host RNG is pinned without changing the resolver
##
## The fixture pauses the real shared-host runtime, chooses the state whose
## next ordinary runtime roll produces the requested branch, then lets the
## shipping host arbiter consume it. The simultaneous race is pinned to break
## out; a second guest throw in that same released encounter is pinned to catch.
##
## **Handover:** each peer owns exactly its deployed starter (`deploy_creature`
## with `owned: true` before host/join admission, as the opening owns it; actor_vitals refuses an unowned
## fighter). The successful guest catch must raise that peer's count by one.
## This does not exercise a full belt or its release ceremony.
##
## ## Setup is granted explicitly and says so
##
## Both peers deploy a creature and the fight is started with the production
## press (`engage_wild` -> `interaction_activate`), then joined by id. A smoke
## that fell over because nobody had a creature out would report "the catch was
## refused", which reads as arbitration failing when it is the fixture missing.
## No orb is spent: `catch_throw` submits the intent through the same door
## `combat_manager.gd::_submit_catch_attempt()` submits through. This intent
## fixture does not test physical orb flight or orb economy; everything from
## `submit_encounter_intent` onward is the shipping path.
##
## ## The debug order if it fails
##
## Both peers' `probe catch` rows are printed. Read them in this order: `submit`
## on each peer ("" means the armed throw never fired, so nothing below means
## anything; "pending" on the client is CORRECT and is not a refusal); then
## `verdict.ok` for a synchronous answer or `resolutions` for an asynchronous
## answer (even a breakout proves admission); then `last_refusal` on
## the loser; then `owned` on both.

## How far ahead the shared throw instant is set — long enough that both peers
## have certainly received their step message, which costs milliseconds.
const THROW_LEAD_MS := 2000.0
## Frames for a client's intent, the host's verdict and the winner's wobble to
## make the round trip. The wobble is seconds of real time
## (`catching.json` resolve/shake), so this is generous on purpose.
const SETTLE_FRAMES := 900
## One poll of the guest's confirmed grant. The settle above is spent in steps
## this short, never as one `wait`: a step's coordinator deadline is wall clock
## at a nominal 60 Hz (`step_budget_frames` 3000 -> 55 s), CI peers measured
## ~10 physics fps here (run 37032778311, NET_RUN `timeout_before_finish` on
## both 900-frame waits), and a peer's control loop is serial -- the next
## `probe catch` queued behind the still-running wait and came back empty.
const GRANT_POLL_FRAMES := 15
## Where each peer stands relative to the opponent when it throws.
const THROW_STANDOFF_M := 4.0

var _asserts := 0


func _initialize() -> void:
	_run()


## See `smoke_net_menu_does_not_freeze_peer.gd`: every assertion goes through
## here so the run reports HOW MANY ran. A test that passes while running fewer
## assertions than it should is a failure this project has already paid for.
func want(condition: bool, message: String) -> void:
	_asserts += 1
	check(condition, message)


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	want(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var ctx = await probe(i, "input_context")
		want(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	want(have_session, "a Session exists to host/join; without it there is no race to run")
	if not have_session:
		quit(await finish())
		return

	# The original disclosed starter must exist before the admission snapshot.
	# PARTY_SEAM.add is local setup, not permission to add a new admitted UID.
	for i in 2:
		var deployed: Dictionary = await step(i, "deploy_creature", {"owned": true})
		want(str(deployed.get("verdict", "")) == "PASS",
			"setup: peer %d deployed its own creature (%s)" % [i, str(deployed.get("detail", ""))])

	var hosted: Dictionary = await step(0, "host", {})
	want(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	want(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		want(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])

	# --- setup: one fight, two participants -----------------------------------
	var engaged: Dictionary = await step(0, "engage_wild", {})
	want(str(engaged.get("verdict", "")) == "PASS",
		"setup: peer 0 engaged a wild creature (%s)" % str(engaged.get("detail", "")))
	if str(engaged.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var record: Dictionary = await _encounter(0)
	var encounter_id := str(record.get("id", ""))
	want(not encounter_id.is_empty(), "setup: the host minted an encounter record for that fight")
	want(str(record.get("kind", "")) == "wild",
		"setup: and it is a WILD encounter, the only kind §8 lets anybody catch (got '%s')"
			% str(record.get("kind", "")))
	var where := _vec(record.get("opponent_pos", []))
	want(where != Vector3.INF, "setup: the record says where the host holds the opponent")
	if encounter_id.is_empty() or where == Vector3.INF:
		quit(await finish())
		return

	# The joiner walks to the fight before joining it, for the reason
	# `smoke_net_shared_wild_fight.gd` gives: `join_encounter()` picks this
	# peer's NEAREST wild as the body it fights beside, because wild bodies are
	# not replicated (4.B's H1).
	var travelled: Dictionary = await step(1, "teleport",
		{"at": [where.x + THROW_STANDOFF_M, where.y + 1.0, where.z]})
	want(str(travelled.get("verdict", "")) == "PASS",
		"setup: peer 1 travelled to the fight (%s)%s" % [str(travelled.get("detail", "")),
			"" if travelled.get("verdict") == "PASS" else " " + str(travelled.get("data", {}))])
	var joined_fight: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	want(str(joined_fight.get("verdict", "")) == "PASS",
		"setup: peer 1 joined the fight already in progress (%s)" % str(joined_fight.get("detail", "")))

	var both: Dictionary = await _encounter(0)
	want((both.get("participants", []) as Array).size() == 2,
		"setup: the host's record holds 2 participants (got %d)"
			% (both.get("participants", []) as Array).size())
	want(str(both.get("phase", "")) == "active",
		"setup: the fight is active, so a throw is legal (phase '%s')" % str(both.get("phase", "")))

	var before := [await _catch_row(0, "peer 0 before the race"),
		await _catch_row(1, "peer 1 before the race")]
	for i in 2:
		want(before[i].has("owned"), "peer %d reports what it owns before the race" % i)
		want(int(before[i].get("party_size", 99)) <= 5,
			"peer %d starts inside the five-creature limit (%d)" % [i, int(before[i].get("party_size", 99))])
	var owned_before := int(before[0].get("owned", -1)) + int(before[1].get("owned", -1))
	print("creatures owned across both peers before the race: %d (peer 0: %d, peer 1: %d)"
		% [owned_before, int(before[0].get("owned", -1)), int(before[1].get("owned", -1))])

	# --- the race -------------------------------------------------------------
	#
	# Both throws are pinned to ONE wall-clock instant, so both intents are in
	# flight before either is decided. Where the host holds the opponent is read
	# once and handed to both peers, so they aim at the same creature: a client
	# has no replicated body to aim at (4.B's H1), and the host re-derives the
	# closest approach against its own position anyway (`catch_arbiter.gd`).
	var aim: Dictionary = await _encounter(0)
	var target := _vec(aim.get("opponent_pos", []))
	want(target != Vector3.INF, "the record still says where the opponent is, to aim at")
	if target == Vector3.INF:
		quit(await finish())
		return
	# Pin the race to a real breakout. The runtime is paused first so its AI
	# cannot consume the selected roll; both throws below still use the normal
	# host arbiter and preserve the simultaneous-order invariant.
	var breakout_seed: Dictionary = await step(0, "catch_fixture_rng", {"caught": false})
	want(str(breakout_seed.get("verdict", "")) == "PASS",
		"fixture selected a next host runtime roll at or above the configured maximum catch chance (%s)"
			% str(breakout_seed.get("detail", "")))
	if str(breakout_seed.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var throw_at := Time.get_unix_time_from_system() * 1000.0 + THROW_LEAD_MS
	for i in 2:
		var armed: Dictionary = await step(i, "catch_throw",
			{"at_unix_ms": throw_at, "target": [target.x, target.y, target.z],
				"orb_id": "orb_basic"})
		want(str(armed.get("verdict", "")) == "PASS",
			"peer %d armed its throw (%s)" % [i, str(armed.get("detail", ""))])
	# §8: a granted throw HOLDS the fight while the winner's orb shakes, and
	# that is the state the loser is refused against. It is polled for rather
	# than read once at the end: the wobble is ~3.9 s of real time
	# (`catching.json` resolve: absorb 0.45 + first shake 0.9 + 2 x 0.85 +
	# settle 0.8) and the record has moved on again by the time the settle
	# below is over -- the first run of this file asserted the END state and
	# read phase '' because the fight itself had finished.
	var held := ""
	for i in 40:
		await step(0, "wait", {"frames": 30})
		var live: Dictionary = await _encounter(0)
		var phase := str(live.get("phase", ""))
		if phase != "active" and not phase.is_empty():
			held = phase
			break
	want(held == "catching",
		"the granted throw HELD the fight while its orb shook (§8): the host's record went to '%s'"
			% held)

	# Do not give the resumed wild AI two unconditional 900-frame windows here.
	# The breakout must be observed as a completed resolution, then the next
	# fixture roll is seeded while this same encounter is still alive.
	var race_completed := false
	for _race_poll in 120:
		await step(0, "wait", {"frames": 15})
		var poll_zero: Variant = await probe(0, "catch")
		var poll_one: Variant = await probe(1, "catch")
		if not poll_zero is Dictionary or not poll_one is Dictionary:
			continue
		var poll_zero_row: Dictionary = poll_zero
		var poll_one_row: Dictionary = poll_one
		var zero_resolved := not (poll_zero_row.get("resolutions", []) as Array).is_empty()
		var one_resolved := not (poll_one_row.get("resolutions", []) as Array).is_empty()
		var zero_refused := not (poll_zero_row.get("refusals", []) as Array).is_empty()
		var one_refused := not (poll_one_row.get("refusals", []) as Array).is_empty()
		if (zero_resolved or one_resolved) and (zero_refused or one_refused):
			race_completed = true
			break
	want(race_completed, "the simultaneous catch race completed before checking its live encounter")

	var after := [await _catch_row(0, "peer 0 after the race"),
		await _catch_row(1, "peer 1 after the race")]
	for i in 2:
		want(after[i].has("submit"), "peer %d still answers a catch probe after the race" % i)
		want(str(after[i].get("submit", "")) != "",
			"peer %d's armed throw really fired (submit '%s')" % [i, str(after[i].get("submit", ""))])
	if not (after[0].has("submit") and after[1].has("submit")):
		quit(await finish())
		return
	# `pending` is not a refusal: it is what a client's `submit()` returns while
	# the host answers. Stated as its own assertion so a future harness change
	# that started treating it as failure fails HERE, with that sentence, rather
	# than as a mystery on the client only.
	want(str(after[0].get("submit", "")) == "answered",
		"the host's own throw was arbitrated in the call (submit '%s')" % str(after[0].get("submit", "")))
	want(str(after[1].get("submit", "")) == "pending",
		"the client's throw went out and waited for the host -- 'pending', which is not a refusal (submit '%s')"
			% str(after[1].get("submit", "")))

	# --- EXACTLY ONE OWNER ----------------------------------------------------
	var winner := -1
	var loser := -1
	for i in 2:
		if _won(after[i]):
			winner = i
		else:
			loser = i
	want(winner >= 0 and loser >= 0 and winner != loser,
		"EXACTLY ONE peer's throw was granted: peer 0 admitted=%s, peer 1 admitted=%s"
			% [str(_won(after[0])), str(_won(after[1]))])
	if winner < 0 or loser < 0 or winner == loser:
		quit(await finish())
		return
	print("peer %d won the throw; peer %d lost it" % [winner, loser])
	var caught := _caught(after[winner])
	# Capture the authoritative boundary immediately after the completed
	# breakout. Waiting through the later invariant checks lets the live AI
	# defeat both participants and makes this same-fight assertion meaningless.
	var record_after: Dictionary = await _encounter(0)
	print("the host's record after the race: phase '%s', seq %d"
		% [str(record_after.get("phase", "")), int(record_after.get("seq", 0))])
	var seeded: Dictionary = {}
	want(not caught and str(record_after.get("phase", "")) == "active",
		"the seeded simultaneous race broke out and released this same encounter")
	if caught or str(record_after.get("phase", "")) != "active":
		quit(await finish())
		return
	seeded = await step(0, "catch_fixture_rng", {"caught": true})
	want(str(seeded.get("verdict", "")) == "PASS",
		"fixture paused host AI and selected a next runtime roll below the configured minimum catch chance (%s)"
			% str(seeded.get("detail", "")))
	if str(seeded.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var winner_resolutions: Array = after[winner].get("resolutions", []) as Array
	want(winner_resolutions.size() == 1,
		"peer %d's granted throw played exactly one completed resolution (got %s)"
			% [winner, str(winner_resolutions)])
	want((after[winner].get("refusals", []) as Array).is_empty(),
		"peer %d's granted throw was never also refused" % winner)

	# --- THE LOSER IS TOLD WHY ------------------------------------------------
	want(_code(after[loser]) == "already_resolving",
		"peer %d (the loser) was refused with `already_resolving` (got '%s')"
			% [loser, _code(after[loser])])
	var told := _reason(after[loser])
	want(not told.is_empty(),
		"peer %d (the loser) was given a sentence to show the player, not silence" % loser)
	want(told.to_lower().contains("somebody else") or told.to_lower().contains("someone else"),
		"and it reads like something a player can act on: '%s'" % told)
	want(not bool((after[loser].get("verdict", {}) as Dictionary).get("caught", false)),
		"peer %d (the loser) holds no decision of its own" % loser)
	want((after[loser].get("resolutions", []) as Array).is_empty(),
		"peer %d (the loser) never played a catch resolution (got %s)"
			% [loser, str(after[loser].get("resolutions", []))])
	want(not (after[loser].get("refusals", []) as Array).is_empty(),
		"and the refusal reached the player through `catch_refused`, not only the log (%s)"
			% str(after[loser].get("refusals", [])))

	# And the winner was not ALSO refused: a peer that holds the decision and
	# was told it lost would mean the two halves of the answer disagree.
	want(_code(after[winner]) != "already_resolving",
		"peer %d (the winner) was not also refused (last refusal: %s)"
			% [winner, str(after[winner].get("last_refusal", {}))])

	# --- NOT DUPLICATED -------------------------------------------------------
	print("the host's roll on peer %d's throw: %s"
		% [winner, "CAUGHT" if caught else "broke out"])
	var owned_after := int(after[0].get("owned", -1)) + int(after[1].get("owned", -1))
	want(owned_after == owned_before + (1 if caught else 0),
		"exactly %d creature(s) entered the world: %d owned before, %d after (peer 0: %d -> %d, peer 1: %d -> %d)"
			% [1 if caught else 0, owned_before, owned_after,
				int(before[0].get("owned", -1)), int(after[0].get("owned", -1)),
				int(before[1].get("owned", -1)), int(after[1].get("owned", -1))])
	want(int(after[loser].get("owned", -1)) == int(before[loser].get("owned", -1)),
		"peer %d (the loser) gained nothing: %d -> %d"
			% [loser, int(before[loser].get("owned", -1)), int(after[loser].get("owned", -1))])

	# --- THE FIVE-CREATURE LIMIT ----------------------------------------------
	for i in 2:
		want(int(after[i].get("party_size", 99)) <= 5,
			"peer %d still owns at most five creatures (%d) -- there is no sixth slot and no storage"
				% [i, int(after[i].get("party_size", 99))])
		if bool(after[i].get("party_full", false)):
			want(int(after[i].get("party_size", 99)) == 5,
				"peer %d's belt reports full at exactly five (%d)"
					% [i, int(after[i].get("party_size", 99))])

	# --- and §8 step 4 told the loser the right thing -------------------------
	if caught:
		want(not (after[loser].get("caught_by_other", []) as Array).is_empty(),
			"§8 step 4 told peer %d somebody else caught it (%s)"
				% [loser, str(after[loser].get("caught_by_other", []))])
	else:
		want((after[loser].get("caught_by_other", []) as Array).is_empty(),
			"the throw broke out, so peer %d was NOT told somebody caught it (%s)"
				% [loser, str(after[loser].get("caught_by_other", []))])

	# --- a deterministic second guest claim in the same fight ------------------
	var race_claim := str((after[winner].get("finish_reply", {}) as Dictionary).get("claim_id", ""))
	if caught or str(seeded.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	# The fixture pauses the actual authority body before reading this position,
	# so the normal guest throw is aimed at the same current centre the host will
	# validate.  It supplies no outcome data.
	var positive_record := await _encounter(0)
	var positive_target := _vec(positive_record.get("opponent_pos", []))
	var guest_before_positive := await _catch_row(1, "guest before deterministic catch")
	var canonical_card: Dictionary = positive_record.get("opponent_card", {}) as Dictionary
	want(positive_target != Vector3.INF and not canonical_card.is_empty(),
		"the paused host record supplies a current target and canonical capture card")
	if positive_target == Vector3.INF or canonical_card.is_empty():
		quit(await finish())
		return
	var guest_throw: Dictionary = await step(1, "catch_throw",
		{"target": [positive_target.x, positive_target.y, positive_target.z], "orb_id": "orb_basic"})
	want(str(guest_throw.get("verdict", "")) == "PASS",
		"guest submitted its ordinary catch throw through CombatManager (%s)" % str(guest_throw.get("detail", "")))
	var positive_held := false
	for _positive_poll in 40:
		await step(0, "wait", {"frames": 15})
		if str((await _encounter(0)).get("phase", "")) == "catching":
			positive_held = true
			break
	want(positive_held, "the guest's admitted throw held the host encounter during the real wobble")
	var host_during_positive := await _catch_row(0, "host during deterministic wobble")
	want(host_during_positive.get("host_caught", null) == true,
		"the host's actual arbiter decision is CAUGHT before the guest can receive it")
	var guest_during_positive := await _catch_row(1, "guest during deterministic wobble")
	want(int(guest_during_positive.get("owned", -1)) == int(guest_before_positive.get("owned", -2)),
		"guest received no creature before host finish confirmation (%d -> %d)"
			% [int(guest_before_positive.get("owned", -2)), int(guest_during_positive.get("owned", -1))])
	want(not str(guest_during_positive.get("claim_id", "")).is_empty(),
		"the admitted wobble is bound to an explicit host claim id")
	want(str(guest_during_positive.get("claim_id", "")) != race_claim,
		"the second guest throw received a fresh claim within the same encounter")
	# The same 2 x SETTLE_FRAMES window the guest used to get (it ran on through
	# the host's wait too), polled in short steps so a slow peer cannot outlive
	# its step deadline and swallow the read below. Pending catch presentation
	# contributes to `owned`, so it cannot end the wait for actual ownership.
	# The original UID and durable receipt must settle; the unchanged short
	# tail still catches a duplicate just behind that first completed grant.
	var grant_uid := str(canonical_card.get("uid", ""))
	var grant_traits: Dictionary = host_during_positive.get("original_trait_packet", {})
	var grant_offer := JSON.stringify([grant_traits.get("captured_from", {}).get("world_namespace", ""),
		guest_during_positive.get("claim_id", ""), grant_uid]).sha256_text()
	var grant_receipt := preload("res://scripts/net/foundation_capture_rules.gd").receipt(
		grant_offer, str(guest_before_positive.get("character_id", "")))
	for _grant_poll in range(0, 2 * SETTLE_FRAMES, GRANT_POLL_FRAMES):
		await step(1, "wait", {"frames": GRANT_POLL_FRAMES})
		var grant_poll: Variant = await probe(1, "catch")
		var grant_host_accepted := false
		if grant_poll is Dictionary:
			for raw: Variant in grant_poll.get("reward_deliveries", {}).values():
				if not raw is Dictionary or raw.get("kind") != "creature_training" or raw.get("status") != "accepted" \
					or raw.get("character_id") != guest_before_positive.get("character_id"): continue
				var mirror: Dictionary = raw.get("after", {}).get("redesign_character", {}).get("creatures", {}).get(grant_uid, {})
				var matches := not mirror.is_empty()
				for field: String in ["traits_initialized", "rolled_traits", "taught_traits", "captured_from"]:
					if mirror.get(field) != grant_traits.get(field): matches = false
				if matches and raw.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).count(grant_receipt) == 1:
					grant_host_accepted = true
		if grant_poll is Dictionary \
				and grant_host_accepted \
				and int((grant_poll as Dictionary).get("party_size", -1)) > int(guest_before_positive.get("party_size", -1)) \
				and (grant_poll as Dictionary).get("live_owned_traits", {}).has(grant_uid) \
				and (grant_poll as Dictionary).get("canonical_owned_traits", {}).has(grant_uid) \
				and (grant_poll as Dictionary).get("disk_owned_traits", {}).has(grant_uid) \
				and (grant_poll as Dictionary).get("transaction_receipts", []).count(grant_receipt) == 1 \
				and (grant_poll as Dictionary).get("disk_transaction_receipts", []).count(grant_receipt) == 1:
			break
	await step(1, "wait", {"frames": GRANT_POLL_FRAMES * 4})
	var guest_after_positive := await _catch_row(1, "guest after host finish confirmation")
	var host_after_positive := await _catch_row(0, "host after guest finish confirmation")
	want(int(guest_after_positive.get("owned", -1)) == int(guest_before_positive.get("owned", -2)) + 1,
		"guest received exactly one creature only after the confirmed caught finish")
	want(int(host_after_positive.get("owned", -1)) == int(after[0].get("owned", -2)),
		"host did not receive the guest's confirmed capture")
	# Only the card(s) this grant added: the guest also owns its deployed
	# starter, which was on the belt before the catch.
	var before_uids: Array = []
	for card: Variant in guest_before_positive.get("owned_cards", []) as Array:
		if card is Dictionary: before_uids.append(str((card as Dictionary).get("uid", "")))
	var delivered_cards: Array = []
	for card: Variant in guest_after_positive.get("owned_cards", []) as Array:
		if card is Dictionary and not before_uids.has(str((card as Dictionary).get("uid", ""))): delivered_cards.append(card)
	want(delivered_cards.size() == 1 and _same_capture_identity(canonical_card, delivered_cards[0] as Dictionary)
		and int((delivered_cards[0] as Dictionary).get("caught_on_day", 0)) >= 1,
		"guest received the host-confirmed canonical identity and stats; only caught_on_day is stamped at grant")
	if preload("res://scripts/creatures/traits.gd").runtime_enabled() and delivered_cards.size() == 1:
		var uid: String = delivered_cards[0].uid
		want(uid == canonical_card.get("uid"), "ordinary guest catch preserves the exact host-confirmed original UID")
		var original: Dictionary = host_during_positive.get("original_trait_packet", {})
		want(preload("res://scripts/save/water_capture_codec.gd").valid_capture_traits(original), "host ordinary catch retains a valid original 0–3 trait packet")
		var original_offer := JSON.stringify([original.get("captured_from", {}).get("world_namespace", ""),
			guest_during_positive.get("claim_id", ""), uid]).sha256_text()
		var token := preload("res://scripts/net/foundation_capture_rules.gd").receipt(original_offer, guest_after_positive.get("character_id", ""))
		for carrier: String in ["transaction_receipts", "disk_transaction_receipts"]:
			want(guest_after_positive.get(carrier, []).count(token) == 1, carrier + " holds exactly the original ordinary catch receipt")
		for field: String in ["traits_initialized", "rolled_traits", "taught_traits"]:
			want(guest_after_positive.get("live_owned_traits", {}).get(uid, {}).get(field) == original.get(field), "actual guest caught instance retains host " + field)
		for carrier: String in ["canonical_owned_traits", "disk_owned_traits"]:
			for field: String in ["traits_initialized", "rolled_traits", "taught_traits", "captured_from"]:
				want(guest_after_positive.get(carrier, {}).get(uid, {}).get(field) == original.get(field), carrier + " retains original " + field)
		var accepted := false
		for row: Variant in host_after_positive.get("reward_deliveries", {}).values():
			if not row is Dictionary or row.get("kind") != "creature_training" or row.get("status") != "accepted" \
				or row.get("character_id") != guest_after_positive.get("character_id"): continue
			var mirror: Dictionary = row.get("after", {}).get("redesign_character", {}).get("creatures", {}).get(uid, {})
			var matches := true
			for field: String in ["traits_initialized", "rolled_traits", "taught_traits", "captured_from"]:
				if mirror.get(field) != original.get(field): matches = false
			if matches and not mirror.is_empty() and row.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).count(token) == 1: accepted = true
		want(accepted, "host accepted owner BOOL-save/ACK row carries the original ordinary catch traits")
		var stable_id: String = guest_after_positive.get("character_id", "")
		for change: Dictionary in [{"action": "leave", "args": {}}, {"action": "wipe_character", "args": {}},
			{"action": "foundations_state", "args": {"mode": "clear_world"}},
			{"action": "production_join", "args": {"host": "127.0.0.1", "port": port,
				"returning_route": true, "character": {"character_id": stable_id}}}]:
			var changed: Dictionary = await step(1, change.action, change.args, 6000)
			want(changed.get("verdict") == "PASS", "ordinary caught-trait rejoin uses existing " + str(change.action))
			if changed.get("verdict") != "PASS":
				quit(await finish())
				return
		for peer in 2:
			var seen_again := await step(peer, "expect_peers", {"count": 2})
			want(seen_again.get("verdict") == "PASS", "both actual peers admit the same-ID caught-trait rejoin")
		var restored := await _catch_row(1, "guest original caught traits after disk rejoin")
		want(restored.get("character_id") == stable_id and restored.get("party_size") == guest_after_positive.get("party_size"),
			"same-ID disk rejoin retains exactly the original guest party count")
		for carrier: String in ["transaction_receipts", "disk_transaction_receipts"]:
			want(restored.get(carrier, []).count(token) == 1, "same-ID rejoin keeps one original receipt in " + carrier)
		for carrier: String in ["canonical_owned_traits", "disk_owned_traits", "live_owned_traits"]:
			for field: String in ["traits_initialized", "rolled_traits", "taught_traits"]:
				want(restored.get(carrier, {}).get(uid, {}).get(field) == original.get(field), "same UID disk rejoin preserves " + carrier + " " + field)
		for carrier: String in ["canonical_owned_traits", "disk_owned_traits"]:
			want(restored.get(carrier, {}).get(uid, {}).get("captured_from") == original.get("captured_from"), "same-ID rejoin preserves original wild source in " + carrier)

	print("assertions run: %d" % _asserts)
	quit(await finish())


# --- reading peers -----------------------------------------------------------

func _catch_row(peer: int, why: String) -> Dictionary:
	var row: Variant = await probe(peer, "catch")
	if not (row is Dictionary):
		_asserts += 1
		check(false, "%s: probe catch returned nothing (peer dead or probe missing)" % why)
		return {}
	print("%s: %s" % [why, str(row)])
	return row as Dictionary


func _encounter(peer: int) -> Dictionary:
	var row: Variant = await probe(peer, "encounter")
	return (row as Dictionary) if row is Dictionary else {}


## `has()` before `get()` throughout: a missing key read through `get()` is
## null, and `bool(null)` is false — which would silently read "this peer lost"
## for a peer whose probe returned nothing at all.
static func _won(row: Dictionary) -> bool:
	if not row.has("verdict"):
		return false
	var v: Variant = row["verdict"]
	if not (v is Dictionary):
		return false
	if not bool((v as Dictionary).get("pending", false)):
		return bool((v as Dictionary).get("ok", false))
	# apply_host_catch_verdict only starts the resolution on an admitted throw;
	# refusals return before _play_catch_decision. Its catch_resolved signal is
	# therefore evidence of the client's asynchronous grant, including breakouts.
	# Pending without a completed host response remains unproven, never a win.
	return not (row.get("resolutions", []) as Array).is_empty()


## `caught_on_day` is stamped by the owning grant and care/HP may tick while the
## real wobble runs. The capture identity is the immutable card plus its
## generated combat stats, moves, traits and nickname.
static func _same_capture_identity(host_card: Dictionary, delivered: Dictionary) -> bool:
	for key in ["species_id", "display_name", "nickname", "creature_type", "secondary_type",
		"trait_primary", "trait_secondary", "move_quick", "move_charged", "shiny"]:
		if host_card.get(key) != delivered.get(key):
			return false
	for key in ["iv_hp", "iv_attack", "iv_defence", "base_hp", "base_attack", "base_defence",
		"max_hp", "attack", "defence", "level"]:
		if not is_equal_approx(float(host_card.get(key, NAN)), float(delivered.get(key, NAN))):
			return false
	return true


static func _caught(row: Dictionary) -> bool:
	var resolutions: Array = row.get("resolutions", []) as Array
	return resolutions.size() == 1 and bool((resolutions[0] as Dictionary).get("caught", false))


## The code this peer was refused with.
##
## A CLIENT's local verdict carries `code: "pending"` -- `ledger_rpc.gd`'s own
## "the host is answering" shape, not a refusal, and the first run of this file
## read it as one and went red with `got 'pending'` while the real refusal sat
## in `last_refusal` one line away. So a pending verdict is skipped outright:
## whatever the host eventually said is what this peer was told.
func _code(row: Dictionary) -> String:
	if row.has("verdict") and row["verdict"] is Dictionary:
		var v := row["verdict"] as Dictionary
		if not bool(v.get("pending", false)):
			var c := str(v.get("code", ""))
			if not c.is_empty():
				return c
	if row.has("last_refusal") and row["last_refusal"] is Dictionary:
		return str((row["last_refusal"] as Dictionary).get("code", ""))
	return ""


func _reason(row: Dictionary) -> String:
	if row.has("verdict") and row["verdict"] is Dictionary:
		var vr := row["verdict"] as Dictionary
		if not bool(vr.get("pending", false)):
			var r := str(vr.get("reason", ""))
			if not r.is_empty():
				return r
	for raw: Variant in (row.get("refusals", []) as Array):
		if not str(raw).is_empty():
			return str(raw)
	if row.has("last_refusal") and row["last_refusal"] is Dictionary:
		return str((row["last_refusal"] as Dictionary).get("reason", ""))
	return ""


func _vec(raw: Variant) -> Vector3:
	if not (raw is Array) or (raw as Array).size() != 3:
		return Vector3.INF
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
