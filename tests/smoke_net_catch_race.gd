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
## In practice **the host has won every observed run** (three, 2026-09-06), and
## that is not surprising — the host arbitrates its own throw inside its own
## `submit_encounter_intent` call while the client's is still on the wire, so it
## is a round trip ahead by construction. Written down so nobody reads this file
## as evidence that the race is symmetric. It is evidence that the SECOND throw
## to arrive is refused, told why, and pays nothing, which is what §8 promises;
## `test_catch_arbitration.gd::test_the_order_decides_it_and_nothing_else_does`
## is where "the host's own throw loses it like anybody else's" is proven, and
## it can prove that because it is pure.
##
## ## The dice are not pinned, and the assertions are written so they need not be
##
## The host rolls with its own `_rng` (`encounter_director.gd::_encounter_roll`)
## and the same generator serves the opponent's own swings, so no seed this
## smoke could set would survive to the throw. A full-health wild is also hard
## to catch on purpose (`catching.json`: `hp_factor_full` 0.10). So the winner's
## throw usually BREAKS OUT, and every assertion here is written to hold either
## way: conservation is stated against the winner's own decision (`caught`),
## not against a hoped-for catch. Which branch a run took is printed.
##
## **Handover:** the belts are also EMPTY in this fixture — `deploy_creature`
## brings a body out without the party gaining a row, so both peers report
## `party_size` 0 throughout and the five-creature assertions below hold
## vacuously. That leaves the full-belt half — a catch that lands while the
## winner already owns five — asserted only as an invariant that a breakout
## satisfies vacuously. Closing it properly needs a way to pin the host's roll
## that does not exist today; `test_catch_arbitration.gd` pins the roll and
## `encounter_director.gd::_resolve_catch()` owns the seam, but nothing joins
## them over the wire. Recorded rather than implied.
##
## ## Setup is granted explicitly and says so
##
## Both peers deploy a creature and the fight is started with the production
## press (`engage_wild` -> `interaction_activate`), then joined by id. A smoke
## that fell over because nobody had a creature out would report "the catch was
## refused", which reads as arbitration failing when it is the fixture missing.
## No orb is spent: `catch_throw` submits the intent through the same door
## `combat_manager.gd::_submit_catch_attempt()` submits through, because a real
## orb flight needs an aim, a wind-up and a projectile that a headless process
## cannot fly. The orb ECONOMY is not what item 6 is about; everything from
## `submit_encounter_intent` onward is the shipping path.
##
## ## The debug order if it fails
##
## Both peers' `probe catch` rows are printed. Read them in this order: `submit`
## on each peer ("" means the armed throw never fired, so nothing below means
## anything; "pending" on the client is CORRECT and is not a refusal); then
## `verdict.ok` on both (two true is the duplication this file exists to catch,
## two false means neither throw reached the arbiter); then `last_refusal` on
## the loser; then `owned` on both.

## How far ahead the shared throw instant is set — long enough that both peers
## have certainly received their step message, which costs milliseconds.
const THROW_LEAD_MS := 2000.0
## Frames for a client's intent, the host's verdict and the winner's wobble to
## make the round trip. The wobble is seconds of real time
## (`catching.json` resolve/shake), so this is generous on purpose.
const SETTLE_FRAMES := 900
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
	# Granted explicitly. See the header on why this block is loud about being
	# setup rather than the thing under test.
	for i in 2:
		var deployed: Dictionary = await step(i, "deploy_creature", {})
		want(str(deployed.get("verdict", "")) == "PASS",
			"setup: peer %d deployed its own creature (%s)" % [i, str(deployed.get("detail", ""))])

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
		"setup: peer 1 travelled to the fight (%s)" % str(travelled.get("detail", "")))
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

	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

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
		"EXACTLY ONE peer's throw was granted: peer 0 ok=%s, peer 1 ok=%s"
			% [str(_won(after[0])), str(_won(after[1]))])
	if winner < 0 or loser < 0 or winner == loser:
		quit(await finish())
		return
	print("peer %d won the throw; peer %d lost it" % [winner, loser])

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
	var caught := bool((after[winner].get("verdict", {}) as Dictionary).get("caught", false))
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
	#
	# The record's FINAL phase is printed, not asserted: by the time the settle
	# above is over the fight has often ended on its own (the opponent is a live
	# AI and the record is gone), and an assertion on it would be measuring how
	# long this smoke happened to wait. What §8 step 4 actually promises the
	# loser is asserted instead, and it is exact in both directions.
	var record_after: Dictionary = await _encounter(0)
	print("the host's record at the end: phase '%s', seq %d"
		% [str(record_after.get("phase", "")), int(record_after.get("seq", 0))])
	if caught:
		want(not (after[loser].get("caught_by_other", []) as Array).is_empty(),
			"§8 step 4 told peer %d somebody else caught it (%s)"
				% [loser, str(after[loser].get("caught_by_other", []))])
	else:
		want((after[loser].get("caught_by_other", []) as Array).is_empty(),
			"the throw broke out, so peer %d was NOT told somebody caught it (%s)"
				% [loser, str(after[loser].get("caught_by_other", []))])

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
func _won(row: Dictionary) -> bool:
	if not row.has("verdict"):
		return false
	var v: Variant = row["verdict"]
	return v is Dictionary and bool((v as Dictionary).get("ok", false))


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
