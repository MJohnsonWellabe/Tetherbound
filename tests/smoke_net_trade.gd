extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 3 lane 3.E. THE player-visible outcome of the lane: two people
## hand each other items, and drop items on the ground for each other, and no
## stack is ever created or destroyed doing it.
##
##   tools/net/run_net_smoke.sh trade
##
## ## What it asserts
##
## Both peers stock a satchel. Then, in order:
##
##   * peer 0 OFFERS peer 1 a stack, peer 1 ACCEPTS, and the stack moves --
##     out of one satchel and into the other, in the same amount;
##   * peer 1 DROPS a stack, and BOTH peers draw it on the ground as a real
##     `dropped_item.gd` (the delta reached both, not just the dropper);
##   * peer 0 PICKS IT UP, and peer 1's screen loses the prop it was drawing
##     off the same committed flag;
##   * and the totals across both peers -- satchels plus everything lying on
##     the ground -- are IDENTICAL before and after all of it.
##
## That last one is the assertion that actually matters, and it is checked at
## every stage rather than once at the end, because "conserved overall" can hide
## a stack destroyed in step 2 and a stack minted in step 3.
##
## ## Why the ground counts toward the total
##
## A dropped stack still exists. A conservation check that only added up
## satchels would go green on a drop that lost the items entirely, which is
## exactly the defect this lane exists to make impossible -- so
## `peer_runner.gd::_dropped_counts()` reports what each process is drawing on
## the floor and it is added in. The two peers draw the SAME dropped stacks, so
## the ground is counted once (from peer 0) and not once per peer; that the two
## agree is asserted separately.
##
## ## What is deliberately NOT asserted here
##
## Race safety. Two peers grabbing the same dropped stack at the same instant is
## arbitrated by `world_ledger.gd::_claim_pickup`, and the deterministic
## interleavings that prove it are in `tests/test_world_ledger_races.gd` -- as
## `world_ledger.gd`'s own header says, the net smokes only ever prove "no
## duplication regardless of order". This proves the consumer side wired to it.
##
## ## The debug order if it fails
##
## Both peers' `probe trade` rows are printed at every stage. Read them in this
## order: the satchels (did the item move at all, and by the right amount);
## then `dropped` on each peer (a stack on one screen and not the other means
## the `item_dropped` scene op reached one process, so look at
## `dropped_item_spawner.gd`'s realm filter); then `refusals`, which is every
## sentence the host sent this peer and is usually the whole answer; then
## `outgoing`/`incoming`, where a stuck offer means the accept never crossed.

const ITEM := "wood"
const EACH := 10
const GIFT := 4
const DROP := 3
## Frames for an intent's delta -- and, for a trade, the offer and the accept
## before it -- to make the round trip.
const SETTLE_FRAMES := 120


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

	# --- who is who -------------------------------------------------------------
	#
	# Peer ids are large random 32-bit numbers, never indices (ENet spike finding
	# 2), so the offer has to be addressed with the id the OTHER process reports
	# for itself rather than with a 0 or a 1.
	var ids := [_peer_id(await probe(0, "session")), _peer_id(await probe(1, "session"))]
	check(ids[0] != 0 and ids[1] != 0 and ids[0] != ids[1],
		"both peers report a distinct peer id (%d / %d)" % [ids[0], ids[1]])
	if ids[0] == 0 or ids[1] == 0 or ids[0] == ids[1]:
		quit(await finish())
		return

	for i in 2:
		var granted: Dictionary = await step(i, "storage_grant", {"item": ITEM, "n": EACH})
		check(str(granted.get("verdict", "")) == "PASS",
			"peer %d holds %d %s (%s)" % [i, EACH, ITEM, str(granted.get("detail", ""))])

	var start := await _snapshot()
	check(not start.is_empty(), "both peers report a trade state to start from")
	if start.is_empty():
		quit(await finish())
		return
	var total := _total(start)
	check(total == EACH * 2,
		"the %s in the world before anybody trades: %d (expected %d)" % [ITEM, total, EACH * 2])

	# --- offer and accept ---------------------------------------------------------

	var offered: Dictionary = await step(0, "trade_offer",
		{"to": ids[1], "item": ITEM, "n": GIFT})
	check(str(offered.get("verdict", "")) == "PASS",
		"peer 0 offered %d %s to peer 1 (%s)" % [GIFT, ITEM, str(offered.get("detail", ""))])
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	var pending = await probe(1, "trade")
	check(pending is Dictionary and not (pending as Dictionary).get("incoming", {}).is_empty(),
		"peer 1 is holding an offer to answer")
	# Nothing may have moved yet. An offer that pays before it is accepted is
	# the exact bug the no-escrow design exists to make impossible.
	var mid := await _snapshot()
	check(_total(mid) == total,
		"nothing moved while the offer was merely OUT: %d before, %d now" % [total, _total(mid)])
	check(_satchel(mid, 0) == EACH,
		"peer 0 still carries all %d %s while its offer is unanswered (has %d)"
			% [EACH, ITEM, _satchel(mid, 0)])

	var accepted: Dictionary = await step(1, "trade_accept", {})
	check(str(accepted.get("verdict", "")) == "PASS",
		"peer 1 accepted the offer (%s)" % str(accepted.get("detail", "")))
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var traded := await _snapshot()
	print("after the trade -- peer 0: %s" % str(traded[0]))
	print("after the trade -- peer 1: %s" % str(traded[1]))
	check(_satchel(traded, 0) == EACH - GIFT,
		"the giver paid exactly once: peer 0 has %d %s (expected %d)"
			% [_satchel(traded, 0), ITEM, EACH - GIFT])
	check(_satchel(traded, 1) == EACH + GIFT,
		"the receiver was paid exactly once: peer 1 has %d %s (expected %d)"
			% [_satchel(traded, 1), ITEM, EACH + GIFT])
	check(_total(traded) == total,
		"the %s is conserved across the trade: %d before, %d after" % [ITEM, total, _total(traded)])

	# --- drop and pick up ------------------------------------------------------------

	var dropped: Dictionary = await step(1, "item_drop", {"item": ITEM, "n": DROP})
	check(str(dropped.get("verdict", "")) == "PASS",
		"peer 1 dropped %d %s (%s)" % [DROP, ITEM, str(dropped.get("detail", ""))])
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var lying := await _snapshot()
	print("after the drop -- peer 0: %s" % str(lying[0]))
	print("after the drop -- peer 1: %s" % str(lying[1]))
	check(_satchel(lying, 1) == EACH + GIFT - DROP,
		"the dropper's satchel is lighter by exactly the drop: peer 1 has %d %s (expected %d)"
			% [_satchel(lying, 1), ITEM, EACH + GIFT - DROP])
	# The `item_dropped` op is `scene` scope and every peer draws it off the same
	# delta. A stack on the dropper's screen only would mean the drop was drawn
	# locally instead of committed, which is the whole class of bug this lane
	# had to avoid.
	for i in 2:
		check(_ground(lying, i) == DROP,
			"peer %d draws the dropped stack on the ground: %d %s (expected %d)"
				% [i, _ground(lying, i), ITEM, DROP])
	check(_total(lying) == total,
		"the %s is conserved across the drop: %d before, %d after (a stack on the floor still exists)"
			% [ITEM, total, _total(lying)])

	var picked: Dictionary = await step(0, "item_pickup", {})
	check(str(picked.get("verdict", "")) == "PASS",
		"peer 0 picked the dropped stack up (%s)" % str(picked.get("detail", "")))
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var done := await _snapshot()
	print("after the pickup -- peer 0: %s" % str(done[0]))
	print("after the pickup -- peer 1: %s" % str(done[1]))
	check(_satchel(done, 0) == EACH - GIFT + DROP,
		"the finder was paid exactly once: peer 0 has %d %s (expected %d)"
			% [_satchel(done, 0), ITEM, EACH - GIFT + DROP])
	check(_satchel(done, 1) == EACH + GIFT - DROP,
		"the dropper was not re-paid: peer 1 has %d %s (expected %d)"
			% [_satchel(done, 1), ITEM, EACH + GIFT - DROP])
	for i in 2:
		check(_ground(done, i) == 0,
			"peer %d's screen no longer draws the claimed stack (still draws %d)"
				% [i, _ground(done, i)])

	# THE assertion. Everything above could be individually right and this still
	# wrong if a stack were minted in one step and lost in another.
	check(_total(done) == total,
		"the %s is conserved end to end: %d before everything, %d after everything"
			% [ITEM, total, _total(done)])

	quit(await finish())


# --- reading the two peers ---------------------------------------------------------

## Both peers' `trade` probes, or an empty Array if either is missing. Asserting
## on a null probe would read `int(null)` as 0 and quietly pass a conservation
## check against a peer that answered nothing at all.
func _snapshot() -> Array:
	var rows: Array = []
	for i in 2:
		var row = await probe(i, "trade")
		if not (row is Dictionary):
			check(false, "peer %d answered the `trade` probe" % i)
			return []
		rows.append(row as Dictionary)
	return rows


## What peer `i` is carrying. `has()` before `get()` on purpose: a probe that
## silently lost its `satchel` key would otherwise read as an empty bag and
## every count below it would compare 0 against 0.
func _satchel(rows: Array, i: int) -> int:
	if rows.size() <= i or not (rows[i] as Dictionary).has("satchel"):
		check(false, "peer %d's trade probe carries a `satchel`" % i)
		return -1
	return int(((rows[i] as Dictionary).get("satchel", {}) as Dictionary).get(ITEM, 0))


## What peer `i` is drawing on the floor.
func _ground(rows: Array, i: int) -> int:
	if rows.size() <= i or not (rows[i] as Dictionary).has("dropped"):
		check(false, "peer %d's trade probe carries a `dropped`" % i)
		return -1
	return int(((rows[i] as Dictionary).get("dropped", {}) as Dictionary).get(ITEM, 0))


## Every `wood` in the world: both satchels plus the ground, counted ONCE (both
## peers draw the same dropped stacks, and that they agree is asserted where the
## drop happens rather than smuggled into the total).
func _total(rows: Array) -> int:
	if rows.size() < 2:
		return -1
	return _satchel(rows, 0) + _satchel(rows, 1) + _ground(rows, 0)


static func _peer_id(session: Variant) -> int:
	if not (session is Dictionary):
		return 0
	return int((session as Dictionary).get("peer_id", 0))
