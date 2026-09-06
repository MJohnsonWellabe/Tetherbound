extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 3 lane 3.D. THE player-visible outcome of the lane: two people
## share one chest, and neither can silently overwrite the other.
##
##   tools/net/run_net_smoke.sh storage_concurrency
##
## ## What it asserts
##
## Both peers stand a real `storage_container.gd` on the SAME
## `placed_buildings` record, both hold ten wood, and both press "store 5" from
## the SAME revision -- the interleaving two players hit when they press within
## one round trip of each other. D103 says exactly one of those writes may
## land. So:
##
##   * exactly one commits: the chest holds 5 wood, not 10, on both peers and
##     in the world record;
##   * the loser is TOLD, with the `stale_revision` sentence a player can act
##     on, not silently dropped and not silently overwritten;
##   * no wood is created or destroyed: the twenty that existed before the race
##     still exist after it, split between two satchels and one chest;
##   * the loser can then press again and it works -- a refusal is a "look
##     again", not a lockout.
##
## ## Why the revision is pinned rather than raced on the wire
##
## `storage_transfer` takes the revision the presser was looking at, the same
## way the panel hands the container the row the player pressed. Pinning both
## peers to revision 0 is what makes the race REPRODUCIBLE in a container: left
## to packet timing, the coordinator's own TCP round trip is slower than the
## loopback ENet hop, so the second peer to be told to press would always have
## seen the first one's delta already and the two writes would serialise --
## the smoke would assert nothing and pass every time. Everything else on both
## sides is the shipping path: the real `Game.ledger`, the real `storage_txn`
## intent, the real `submit_deposit`, the real delta.
##
## ## The debug order if it fails
##
## Both peers' `probe storage` rows are printed on every check. Read them in
## this order: same `container` key on both (a different key means the record
## address diverged, and the two peers were never writing the same chest);
## then `revision` (1 after the race -- 2 means both writes landed and D103's
## single-writer rule is broken); then `chest` vs `record` on each peer (a
## disagreement means the delta reached the live node but not `WorldState`, or
## the other way round); then the satchels.

const ITEM := "wood"
const EACH := 10
const DEPOSIT := 5
## Frames for the losing peer's delta and refusal to make the round trip.
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

	# --- one chest, one record, two processes ---------------------------------

	var before_count = await probe(1, "placed_building_count")
	var placed: Dictionary = await step(0, "storage_place", {"realm": "meadows"})
	check(str(placed.get("verdict", "")) == "PASS",
		"peer 0 planted a chest record through the ledger (%s)" % str(placed.get("detail", "")))
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	var host_count = await probe(0, "placed_building_count")
	var client_count = await probe(1, "placed_building_count")
	check(int(host_count) == int(before_count) + 1,
		"the chest record exists on the host (%d -> %d)" % [int(before_count), int(host_count)])
	check(int(client_count) == int(host_count),
		"the `place_building` delta reached the client too (host %d, client %d)"
			% [int(host_count), int(client_count)])
	if int(client_count) != int(host_count):
		quit(await finish())
		return
	var index := int(host_count) - 1

	for i in 2:
		var bound: Dictionary = await step(i, "storage_bind", {"index": index, "realm": "meadows"})
		check(str(bound.get("verdict", "")) == "PASS",
			"peer %d stood a chest on record %d (%s)" % [i, index, str(bound.get("detail", ""))])
		var granted: Dictionary = await step(i, "storage_grant", {"item": ITEM, "n": EACH})
		check(str(granted.get("verdict", "")) == "PASS",
			"peer %d holds %d %s (%s)" % [i, EACH, ITEM, str(granted.get("detail", ""))])

	var start := [await probe(0, "storage"), await probe(1, "storage")]
	check(start[0] is Dictionary and start[1] is Dictionary, "both peers report a bound chest")
	if not (start[0] is Dictionary and start[1] is Dictionary):
		quit(await finish())
		return
	check(_key(start[0]) == _key(start[1]),
		"both peers name the same container ('%s' / '%s')" % [_key(start[0]), _key(start[1])])
	for i in 2:
		check(_revision(start[i]) == 0,
			"peer %d would quote revision 0 for a chest nobody has written (got %d)"
				% [i, _revision(start[i])])
		check(_chest(start[i]) == 0, "peer %d's chest starts empty (got %d)" % [i, _chest(start[i])])
	var total := _satchel(start[0]) + _satchel(start[1])
	check(total >= EACH * 2,
		"the %s in the world before the race: %d" % [ITEM, total])

	# --- the race -------------------------------------------------------------

	# Both presses quote revision 0. Whichever the host arbitrates second is the
	# one D103 must refuse; which of the two that is is genuinely up to packet
	# order, and this smoke deliberately does not care -- it asserts the
	# invariant, not the winner.
	var client_press: Dictionary = await step(1, "storage_transfer",
		{"direction": "deposit", "item": ITEM, "n": DEPOSIT, "revision": 0})
	check(str(client_press.get("verdict", "")) == "PASS",
		"peer 1 pressed store (%s)" % str(client_press.get("detail", "")))
	var host_press: Dictionary = await step(0, "storage_transfer",
		{"direction": "deposit", "item": ITEM, "n": DEPOSIT, "revision": 0})
	check(str(host_press.get("verdict", "")) == "PASS",
		"peer 0 pressed store (%s)" % str(host_press.get("detail", "")))
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var after := [await probe(0, "storage"), await probe(1, "storage")]
	for i in 2:
		check(after[i] is Dictionary, "peer %d still reports its chest after the race" % i)
	if not (after[0] is Dictionary and after[1] is Dictionary):
		quit(await finish())
		return
	print("peer 0 storage: %s" % str(after[0]))
	print("peer 1 storage: %s" % str(after[1]))

	# Exactly one write landed. Two would be D103's whole point missed.
	check(_chest(after[0]) == DEPOSIT,
		"the chest holds one deposit's worth on the host: %d (expected %d)"
			% [_chest(after[0]), DEPOSIT])
	check(_chest(after[1]) == _chest(after[0]),
		"both peers draw the same chest (host %d, client %d)" % [_chest(after[0]), _chest(after[1])])
	for i in 2:
		check(_record(after[i]) == _chest(after[i]),
			"peer %d's world record agrees with the chest it draws (record %d, node %d)"
				% [i, _record(after[i]), _chest(after[i])])
		check(_revision(after[i]) == 1,
			"peer %d has the container at revision %d; 1 is one commit, 2 would be both"
				% [i, _revision(after[i])])

	# Nothing was created and nothing was destroyed. This is the assertion the
	# net smokes exist for (world_ledger.gd's header: "no duplication regardless
	# of order"), and the one an optimistic panel would break.
	var conserved := _satchel(after[0]) + _satchel(after[1]) + _chest(after[0])
	check(conserved == total,
		"the %s is conserved across the race: %d before, %d after (satchels %d/%d, chest %d)"
			% [ITEM, total, conserved, _satchel(after[0]), _satchel(after[1]), _chest(after[0])])

	# One peer paid, one did not.
	var winner := -1
	var loser := -1
	for i in 2:
		if _satchel(after[i]) == _satchel(start[i]) - DEPOSIT:
			winner = i
		elif _satchel(after[i]) == _satchel(start[i]):
			loser = i
	check(winner >= 0 and loser >= 0 and winner != loser,
		"exactly one peer's satchel paid for the deposit (peer 0: %d -> %d, peer 1: %d -> %d)"
			% [_satchel(start[0]), _satchel(after[0]), _satchel(start[1]), _satchel(after[1])])
	if winner < 0 or loser < 0 or winner == loser:
		quit(await finish())
		return

	# The loser was told, in a sentence, and told the machine-readable reason.
	var told := _refusal_text(after[loser])
	check(not told.is_empty(),
		"peer %d (the loser) was given a sentence to show the player, not silence" % loser)
	check(told.to_lower().contains("someone else"),
		"peer %d's refusal reads like something a player can act on: '%s'" % [loser, told])
	check(_stale(after[loser]),
		"peer %d's refusal is `stale_revision` (codes seen: '%s')"
			% [loser, str((after[loser] as Dictionary).get("last", {}))])

	# --- and it is a "look again", not a lockout -------------------------------

	# The loser presses again, this time reading the revision live the way the
	# panel does. A refusal that could not be recovered from would be a chest
	# the joiner can never use.
	var retry: Dictionary = await step(loser, "storage_transfer",
		{"direction": "deposit", "item": ITEM, "n": DEPOSIT})
	check(str(retry.get("verdict", "")) == "PASS",
		"peer %d pressed store again (%s)" % [loser, str(retry.get("detail", ""))])
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var retried := [await probe(0, "storage"), await probe(1, "storage")]
	if not (retried[0] is Dictionary and retried[1] is Dictionary):
		check(false, "both peers still report a chest after the retry")
		quit(await finish())
		return
	check(_chest(retried[0]) == DEPOSIT * 2,
		"the second, honest write landed: chest holds %d (expected %d)"
			% [_chest(retried[0]), DEPOSIT * 2])
	check(_chest(retried[1]) == _chest(retried[0]),
		"both peers still draw the same chest after the retry (%d / %d)"
			% [_chest(retried[0]), _chest(retried[1])])
	check(_satchel(retried[loser]) == _satchel(after[loser]) - DEPOSIT,
		"peer %d's satchel paid for the retry (%d -> %d)"
			% [loser, _satchel(after[loser]), _satchel(retried[loser])])
	var conserved_again := _satchel(retried[0]) + _satchel(retried[1]) + _chest(retried[0])
	check(conserved_again == total,
		"the %s is still conserved after the retry: %d before, %d after"
			% [ITEM, total, conserved_again])

	quit(await finish())


# --- reading a `probe storage` row ------------------------------------------------

func _key(row: Variant) -> String:
	return str((row as Dictionary).get("container", "")) if row is Dictionary else ""


func _revision(row: Variant) -> int:
	return int((row as Dictionary).get("revision", -1)) if row is Dictionary else -1


func _chest(row: Variant) -> int:
	return _count_in(row, "chest")


func _record(row: Variant) -> int:
	return _count_in(row, "record")


func _satchel(row: Variant) -> int:
	return _count_in(row, "satchel")


func _count_in(row: Variant, key: String) -> int:
	if not (row is Dictionary):
		return -1
	var map: Variant = (row as Dictionary).get(key, {})
	if not (map is Dictionary):
		return -1
	return int((map as Dictionary).get(ITEM, 0))


## The sentence the loser was given, from either half of the answer: a host
## refuses its own press synchronously, a client is told later on
## `storage_refused`.
func _refusal_text(row: Variant) -> String:
	if not (row is Dictionary):
		return ""
	var last: Dictionary = (row as Dictionary).get("last", {}) as Dictionary
	var direct := str(last.get("reason", ""))
	if not direct.is_empty():
		return direct
	for entry: Variant in ((row as Dictionary).get("refusals", []) as Array):
		if not str(entry).is_empty():
			return str(entry)
	return ""


## Whether that refusal was D103's `stale_revision`. A host that refused its own
## press carries the code directly; a client only ever sees the sentence, so the
## sentence is what stands in for the code there.
func _stale(row: Variant) -> bool:
	if not (row is Dictionary):
		return false
	var last: Dictionary = (row as Dictionary).get("last", {}) as Dictionary
	if str(last.get("code", "")) == "stale_revision":
		return true
	return bool(last.get("pending", false)) and not _refusal_text(row).is_empty()
