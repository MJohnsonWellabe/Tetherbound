extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 5 lane 5.D. THE player-visible outcome of the lane: night falls
## when everyone is in bed, not when the first person lies down.
##
##   tools/net/run_net_smoke.sh sleep_vote
##
## ## What it asserts, and why the negative half is the point
##
## Two peers host and join. Peer 0 stands a bedroll (with the tent CAMP-SHELTER-
## 0903 requires over it) and presses it. Then:
##
##   * **the day does NOT move on either peer** -- the negative half. A smoke
##     that only checked "the day advanced once both slept" would pass
##     identically if the vote did nothing at all and the first sleeper simply
##     advanced the day the way the pre-5.D code did; the day would be N+1 by
##     the end either way. Asserting the day is still N while one of two players
##     is awake is the only assertion that can tell those two worlds apart.
##   * peer 1 is marked awake in the replicated registry, and peer 0 -- the one
##     lying down -- can name it. That is D105's "a vote nobody can see the state
##     of is a vote that feels broken", checked as data rather than as a
##     screenshot.
##
## Peer 1 then sleeps too, and BOTH peers must land on the same new day. Both,
## not just the host: a host that advanced its own day and told nobody is the
## other way this can be broken, and it looks fine from the host.
##
## ## Why the day, and not the sky
##
## `Game.day` is the number D105 makes host truth and the number
## `Game.advance_day()` refuses to move on a client. The sky each peer resets to
## morning locally in `night_rest.gd::pass_the_night()`; it is downstream of
## this and not what a client could get wrong on its own.
##
## ## The trap this smoke is written around
##
## Godot installs `OfflineMultiplayerPeer` by default: with no session
## `multiplayer.is_server()` is **true** and `get_unique_id()` is **1**. A vote
## guarded that way would pass on BOTH peers here, both would advance their own
## day, and the day would still end up N+1 on both -- so the final agreement
## check alone would go green on the broken build. The mid-run day check is
## what catches it.

## Frames for one peer's vote to cross the wire and the host to tally it. The
## intent is a reliable RPC on the ledger channel over loopback (median RTT
## 6.9 ms, ENet spike), so this is two orders of magnitude of margin -- and the
## night-falls broadcast rides the same channel behind it.
const VOTE_SETTLE_FRAMES := 120


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	# The session has to exist before there is a vote to hold. The honest gate:
	# say so once and stop, rather than reporting a pile of downstream failures
	# that all mean the same thing.
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session, "a Session exists to host/join (lane 2.A)")
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

	# The day both peers start on, read from both. If they do not already agree
	# the rest of this smoke measures nothing, so this is a gate too.
	var day_before := await _day(0)
	var client_day_before := await _day(1)
	check(day_before > 0, "peer 0 reports a day (%d)" % day_before)
	check(client_day_before == day_before,
		"both peers start on the same day (host %d, client %d)" % [day_before, client_day_before])
	if day_before <= 0 or client_day_before != day_before:
		quit(await finish())
		return

	# --- one player lies down ---------------------------------------------------

	for i in 2:
		var stood: Dictionary = await step(i, "sleep_stand", {})
		check(str(stood.get("verdict", "")) == "PASS",
			"peer %d stood a bedroll under a tent (%s)" % [i, str(stood.get("detail", ""))])

	var pressed: Dictionary = await step(0, "sleep_press", {})
	check(str(pressed.get("verdict", "")) == "PASS",
		"peer 0 pressed its bedroll (%s)" % str(pressed.get("detail", "")))
	await step(0, "wait", {"frames": VOTE_SETTLE_FRAMES})
	await step(1, "wait", {"frames": VOTE_SETTLE_FRAMES})

	# THE NEGATIVE HALF. One of two players is in bed; the night must not fall.
	var day_mid_host := await _day(0)
	var day_mid_client := await _day(1)
	check(day_mid_host == day_before,
		"the day did NOT advance while only one of two players was in bed (host: %d, was %d)"
			% [day_mid_host, day_before])
	check(day_mid_client == day_before,
		"the day did NOT advance on the other peer either (client: %d, was %d)"
			% [day_mid_client, day_before])

	# And the sleeper can see what it is waiting for.
	var vote_host = await probe(0, "sleep_vote")
	var vh: Dictionary = vote_host if vote_host is Dictionary else {}
	check(bool(vh.get("mounted", false)), "peer 0 mounted the SleepVote node")
	check(bool(vh.get("sleeping_here", false)), "peer 0 is registered as lying down on its own process")
	var awake: Array = vh.get("awake", []) as Array
	check(awake.size() == 1,
		"peer 0 can name exactly 1 player still up (named %d: %s)" % [awake.size(), str(awake)])

	# The tally is the REPLICATED registry, so the client holds it too: exactly
	# one row marked sleeping, on the peer that did not press anything.
	var vote_client = await probe(1, "sleep_vote")
	var vc: Dictionary = vote_client if vote_client is Dictionary else {}
	check(not bool(vc.get("sleeping_here", false)),
		"peer 1 is NOT registered as lying down (it pressed nothing)")
	check(_sleeping_count(vc) == 1,
		"peer 1's replicated registry shows exactly 1 player asleep (shows %d: %s)"
			% [_sleeping_count(vc), str(vc.get("registry_sleeping", {}))])

	# --- the second player lies down --------------------------------------------

	var pressed_2: Dictionary = await step(1, "sleep_press", {})
	check(str(pressed_2.get("verdict", "")) == "PASS",
		"peer 1 pressed its bedroll (%s)" % str(pressed_2.get("detail", "")))
	await step(1, "wait", {"frames": VOTE_SETTLE_FRAMES})
	await step(0, "wait", {"frames": VOTE_SETTLE_FRAMES})

	var day_after_host := await _day(0)
	var day_after_client := await _day(1)
	check(day_after_host == day_before + 1,
		"the night fell once BOTH players were in bed (host: day %d, was %d)"
			% [day_after_host, day_before])
	check(day_after_client == day_after_host,
		"both peers agree on the new day (host %d, client %d)"
			% [day_after_host, day_after_client])

	# Nobody is left marked asleep afterwards, or the next night would fall the
	# moment one player lay down.
	var after_host = await probe(0, "sleep_vote")
	var ah: Dictionary = after_host if after_host is Dictionary else {}
	check(not bool(ah.get("sleeping_here", false)), "peer 0 is awake again after the night")
	check(_sleeping_count(ah) == 0,
		"the host's tally is cleared after the night (still marked: %s)"
			% str(ah.get("registry_sleeping", {})))

	quit(await finish())


func _day(peer: int) -> int:
	var value = await probe(peer, "day")
	return int(value) if value != null else -1


## How many registry rows this peer sees marked `sleeping`.
##
## `has()` before the read, deliberately: a probe that came back without the key
## would otherwise read as an empty Dictionary, count 0, and quietly satisfy the
## "cleared afterwards" check while telling us nothing at all.
func _sleeping_count(vote: Dictionary) -> int:
	if not vote.has("registry_sleeping"):
		return -1
	var marks: Dictionary = vote["registry_sleeping"]
	var n := 0
	for key: Variant in marks.keys():
		if bool(marks[key]):
			n += 1
	return n
