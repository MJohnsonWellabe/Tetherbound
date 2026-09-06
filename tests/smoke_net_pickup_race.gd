extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 3 lane 3.B. THE player-visible outcome of the lane: two people
## reach for the same find at the same moment, and exactly one of them gets it.
##
##   tools/net/run_net_smoke.sh pickup_race
##
## ## What it asserts
##
## Both peers stand a real `item_cache_pickup.gd` on the SAME placement id, so
## both are pressing one find. Both then press it at one shared wall-clock
## instant -- the interleaving two players hit when they reach in together, and
## the one a sequential coordinator cannot otherwise produce (see
## `peer_runner.gd::_step_pickup_take`, which holds the press until the
## deadline). D103 says exactly one of those claims may commit. So:
##
##   * exactly one peer ends up holding the item;
##   * the WORLD says the find is claimed on both peers, and the prop is gone on
##     both -- removal is driven by the delta, not by the intent, which is the
##     single change that makes the race safe;
##   * nothing is duplicated: the world holds exactly one more of the item after
##     the race than before it, across both satchels;
##   * the loser was not paid and was not left in silence.
##
## ## The two shapes of a lost race, and why the smoke accepts both
##
## `world_ledger.gd`'s own header draws this line: the deterministic
## interleavings are proven headlessly in `tests/test_world_ledger_races.gd`,
## and "the net smokes only ever prove `no duplication regardless of order`".
## This smoke holds to that, and the reason is measured rather than assumed.
##
## **Shape A**, the one this smoke normally produces: both intents are in flight
## before either delta lands, the host refuses the second `already_taken`, and
## the loser is told in a sentence. That is the interleaving the shared press
## deadline exists to create.
##
## **Shape B**: the winner's delta reaches the loser BEFORE its own press does,
## so the find is taken down under its hand and no intent is ever submitted.
## That is not a failure either -- it is the correct player experience, and it is
## what "removal is driven by the delta" produces whenever the two presses fall
## more than a frame apart. Frame phase between two processes decides which
## shape a run gets, and pinning it would mean pinning the scheduler.
##
## So both are asserted, by branch, and neither is allowed to be silence or to
## pay the loser. `already_taken` itself is also proven deterministically, and
## against `world_ledger.gd` directly, in `test_world_ledger_races.gd`.
##
## Which shape a run took is read off `press`: "submitted" means the intent
## really went out (asked of the WORLD FLAG, not of the node -- `queue_free()`
## is deferred, so a prop taken down earlier in the same frame still passes
## `is_instance_valid`), "gone" means it never did.
##
## ## Why one item and not five
##
## `claim_pickup` is a one-time world find: the flag is the whole record and
## there is nothing to split. A count above 1 would test `inventory.add`, which
## is not what is contested here. Conservation is asserted on the TOTAL across
## both satchels precisely so "the loser was paid too" fails loudly rather than
## hiding inside a bigger number.
##
## ## The debug order if it fails
##
## Both peers' `probe pickup` rows are printed on every check. Read them in this
## order: same `flag` on both (a different flag means the two peers were never
## claiming the same find); then `claimed` (false on a peer means the delta
## never reached it, so nothing downstream means anything); then `standing`
## (true after the race means `_on_delta_applied` did not fire and removal is
## still riding the intent); then the satchels; then `press` and `refusals`,
## which together say which shape the run produced.

const ITEM := "berries"
const PICKUP_ID := "net_race_cache"
## How far ahead the shared press instant is set. Long enough that the second
## peer has certainly received its step message before the first peer presses --
## the coordinator's two TCP hops are milliseconds, this is seconds.
const PRESS_LEAD_MS := 2000.0
## Frames for the winner's delta and the loser's refusal to make the round trip.
const SETTLE_FRAMES := 300


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var ctx = await probe(i, "input_context")
		check(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	# A session has to exist before anyone can see anyone. This is the honest
	# gate: if it is not there, say so once and stop, rather than reporting a
	# pile of downstream failures that all mean the same thing.
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it there are no remote bodies to see")
	if not have_session:
		quit(await finish())
		return

	# Actually form the session. This smoke was written before lane 2.A landed,
	# so it could only assert that a Session class existed; with 2.A merged the
	# two processes must really host and join, or every check below reads "0
	# remote bodies" and means only that nobody ever connected.
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

	# --- one find, two hands --------------------------------------------------

	for i in 2:
		var stood: Dictionary = await step(i, "pickup_stand",
			{"id": PICKUP_ID, "item": ITEM, "realm": "meadows", "count": 1})
		check(str(stood.get("verdict", "")) == "PASS",
			"peer %d stood the cache '%s' (%s)" % [i, PICKUP_ID, str(stood.get("detail", ""))])

	var start := [await probe(0, "pickup"), await probe(1, "pickup")]
	check(start[0] is Dictionary and start[1] is Dictionary, "both peers report a standing find")
	if not (start[0] is Dictionary and start[1] is Dictionary):
		quit(await finish())
		return
	check(_flag(start[0]) == _flag(start[1]),
		"both peers name the same find ('%s' / '%s')" % [_flag(start[0]), _flag(start[1])])
	for i in 2:
		check(_standing(start[i]), "peer %d's find is standing before the race" % i)
		check(not _claimed(start[i]),
			"peer %d's world does not yet say '%s' is taken" % [i, PICKUP_ID])
	var total_before := _held(start[0]) + _held(start[1])
	print("the %s in the world before the race: %d (peer 0: %d, peer 1: %d)"
		% [ITEM, total_before, _held(start[0]), _held(start[1])])

	# --- the race -------------------------------------------------------------

	# Both presses are pinned to ONE wall-clock instant. `pickup_take` with a
	# deadline ARMS the press and answers immediately, so both peers can be
	# armed -- one coordinator round trip each, milliseconds apart -- and then
	# both press together seconds later, with both intents in flight before
	# either delta lands. Which of the two the host arbitrates first is
	# genuinely up to packet order, and this smoke deliberately does not care:
	# it asserts the invariant, not the winner.
	var press_at := Time.get_unix_time_from_system() * 1000.0 + PRESS_LEAD_MS
	for i in 2:
		var armed: Dictionary = await step(i, "pickup_take", {"at_unix_ms": press_at})
		check(str(armed.get("verdict", "")) == "PASS",
			"peer %d armed its press (%s)" % [i, str(armed.get("detail", ""))])
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var after := [await probe(0, "pickup"), await probe(1, "pickup")]
	for i in 2:
		check(after[i] is Dictionary, "peer %d still reports its find after the race" % i)
	if not (after[0] is Dictionary and after[1] is Dictionary):
		quit(await finish())
		return
	print("peer 0 pickup: %s" % str(after[0]))
	print("peer 1 pickup: %s" % str(after[1]))

	# The commit reached both worlds, and the prop is gone on both. A peer whose
	# world says "claimed" while the prop still stands is the bug this lane
	# exists to remove: removal riding the intent instead of the delta.
	for i in 2:
		check(_claimed(after[i]),
			"peer %d's world records '%s' as taken" % [i, PICKUP_ID])
		check(not _standing(after[i]),
			"peer %d's prop was taken down by the delta, not left standing" % i)

	# Nothing was created and nothing was destroyed. This is the assertion the
	# net smokes exist for (world_ledger.gd's header: "no duplication regardless
	# of order"), and the one an optimistic pickup would break.
	var total_after := _held(after[0]) + _held(after[1])
	check(total_after == total_before + 1,
		"exactly one %s entered the world: %d before, %d after (peer 0: %d -> %d, peer 1: %d -> %d)"
			% [ITEM, total_before, total_after, _held(start[0]), _held(after[0]),
				_held(start[1]), _held(after[1])])

	# One peer holds it, the other does not.
	var winner := -1
	var loser := -1
	for i in 2:
		if _held(after[i]) == _held(start[i]) + 1:
			winner = i
		elif _held(after[i]) == _held(start[i]):
			loser = i
	check(winner >= 0 and loser >= 0 and winner != loser,
		"exactly one peer walked away with the find (peer 0: %d -> %d, peer 1: %d -> %d)"
			% [_held(start[0]), _held(after[0]), _held(start[1]), _held(after[1])])
	if winner < 0 or loser < 0 or winner == loser:
		quit(await finish())
		return
	print("peer %d won the find; peer %d lost it" % [winner, loser])

	# A lost race has exactly two legal shapes, and which one a run produces is
	# frame phase, not correctness. See this file's header. Both are asserted;
	# neither is allowed to be silence, and neither pays the loser.
	if _press(after[loser]) != "submitted":
		# Shape B: the winner's delta reached this peer before its own press
		# did, so the find was taken down under its hand and no intent was ever
		# submitted. `standing == false` is already asserted above; what this
		# adds is that the press really did land on an absent find rather than
		# quietly succeeding.
		check(_press(after[loser]) == "gone" and _refusals(after[loser]).is_empty(),
			"peer %d (the loser) submitted nothing because the find was already taken down (press: '%s', refusals: %s)"
				% [loser, _press(after[loser]), str(_refusals(after[loser]))])
		print("peer %d lost by shape B: the delta took the find down before its press landed" % loser)
	else:
		# Shape A: both intents were in flight before either delta landed, so
		# the host arbitrated and refused this one. This is the interleaving
		# `world_ledger.gd` writes `already_taken` for.
		check(_code(after[loser]) == "already_taken",
			"peer %d (the loser) was refused with `already_taken` (refusals: %s)"
				% [loser, str(_refusals(after[loser]))])
		var told := _reason(after[loser])
		check(not told.is_empty(),
			"peer %d (the loser) was given a sentence to show the player, not silence" % loser)
		check(told.to_lower().contains("someone else"),
			"peer %d's refusal reads like something a player can act on: '%s'" % [loser, told])
		print("peer %d lost by shape A: refused `already_taken` -- '%s'" % [loser, told])

	# And the winner was not also refused: a peer that both holds the item and
	# was told it lost would mean the two halves of the answer disagree.
	check(_refusals(after[winner]).is_empty(),
		"peer %d (the winner) was not also refused (refusals: %s)"
			% [winner, str(_refusals(after[winner]))])

	quit(await finish())


# --- reading a `probe pickup` row -------------------------------------------------

func _flag(row: Variant) -> String:
	return str((row as Dictionary).get("flag", "")) if row is Dictionary else ""


func _standing(row: Variant) -> bool:
	return bool((row as Dictionary).get("standing", false)) if row is Dictionary else false


func _claimed(row: Variant) -> bool:
	return bool((row as Dictionary).get("claimed", false)) if row is Dictionary else false


## How much of the contested item this peer's satchel holds -- addressed by item
## identity, never by slot number (CLAUDE.md).
func _held(row: Variant) -> int:
	if not (row is Dictionary):
		return -1
	var map: Variant = (row as Dictionary).get("satchel", {})
	if not (map is Dictionary):
		return -1
	return int((map as Dictionary).get(ITEM, 0))


## What this peer's press found: "submitted" or "gone". See the header.
func _press(row: Variant) -> String:
	return str((row as Dictionary).get("press", "")) if row is Dictionary else ""


func _refusals(row: Variant) -> Array:
	return ((row as Dictionary).get("refusals", []) as Array) if row is Dictionary else []


func _code(row: Variant) -> String:
	for raw: Variant in _refusals(row):
		var entry := raw as Dictionary
		if not str(entry.get("code", "")).is_empty():
			return str(entry.get("code", ""))
	return ""


func _reason(row: Variant) -> String:
	for raw: Variant in _refusals(row):
		var entry := raw as Dictionary
		if not str(entry.get("reason", "")).is_empty():
			return str(entry.get("reason", ""))
	return ""
