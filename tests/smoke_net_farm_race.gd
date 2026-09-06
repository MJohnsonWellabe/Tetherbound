extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 6 lane 6.E. THE player-visible outcome of the farm half of the
## lane: two people pick the same ripe berry bed at the same moment, and exactly
## one lot of berries comes out of it.
##
##   tools/net/run_net_smoke.sh farm_race
##
## ## Why this bed and not a Cloudreach act
##
## Lane 6.E's audit found five unconverted world writers and converted four of
## them. The farm bed is the one whose defect is a DUPLICATION -- before this
## lane both players got the full yield off one crop, because picking paid the
## satchel and rewrote the bed locally on whichever peer pressed. The Cloudreach
## chapter conversion (the lane's largest, ~100 world flags) is a DIVERGENCE
## rather than a duplication, and proving it end to end costs four Meadows-class
## world builds in one run -- the exact shape lane 6.A shipped twice and could
## not run either time. This smoke costs two. The reasoning and the handover for
## a Cloudreach net smoke are in
## `ralph/reports/MP-6E-CLOUDREACH-0906/REPORT.md`.
##
## ## What it asserts
##
## Both peers stand a real `farm_plot.gd` on the SAME index in the SAME realm,
## with a crop ripe on the same day -- so both name the same claim id,
## `farm:meadows:<index>#<ripe_on_day>`, and both are pressing one crop. Both
## then press at one shared wall-clock instant (`peer_runner.gd::_press_farm_at`
## holds the press until the deadline), which is the interleaving two players
## hit when they reach in together. D103 says exactly one of those claims may
## commit. So:
##
##   * exactly one peer's satchel gained the yield;
##   * nothing was duplicated: the world holds exactly one yield more across
##     BOTH satchels than it did before the race;
##   * the WORLD says the crop is claimed on both peers, and the bed reads as
##     worked soil again on both -- the mirror is driven by the delta, not by
##     the press, which is what keeps two screens showing one farm without a
##     farm op in `WorldState`;
##   * the loser was not paid and was not left in silence.
##
## ## The two shapes of a lost race
##
## The same pair `smoke_net_pickup_race.gd` documents, and for the same reason
## (frame phase between two processes, which pinning would mean pinning the
## scheduler):
##
## **Shape A** -- both intents in flight before either delta lands; the host
## refuses the second `already_taken` and the loser is told in a sentence.
## **Shape B** -- the winner's delta reaches the loser first, the loser's own
## `_on_delta_applied` has already returned the bed to worked soil, and the
## press finds nothing ripe to pick. That is not a failure; it is the correct
## picture of a lost race, and `press` says which shape a run took.
##
## Deterministic `already_taken` is proven against `world_ledger.gd` directly in
## `tests/test_world_ledger_races.gd`; this smoke proves the invariant across
## two real processes, never the winner.
##
## ## SETUP, named so a setup failure cannot be read as the feature
##
## `farm_stand` writes the bed's `{state, ripe_on_day}` record directly with
## `Game.set_farm_plot()`. That direct write is lane 6.E's one recorded
## unconverted farm mutation -- `WorldState` has no farm op and the two files
## that would need one are outside this lane. Here it is the harness PLANTING A
## CROP, not the feature under test. If `farm_stand` fails, the bed was never
## ripe and nothing below means anything; the checks say so in those words.
##
## ## The debug order if it fails
##
## Both peers' `probe farm` rows are printed on every check. Read them in this
## order: same `flag` on both (a different flag means the two peers were never
## picking the same crop cycle); then `claimed` (false on a peer means the delta
## never reached it); then `state` (still `ripe` after the race means
## `_on_delta_applied` did not fire and the mirror is still riding the press);
## then the satchels; then `press` and `refusals`.

const CROP := "berries"
## Well clear of `data/config/farm.json`'s own beds, which are numbered from 0.
const BED_INDEX := 90
const YIELD := 3
## How far ahead the shared press instant is set. Long enough that the second
## peer has certainly received its step message before the first peer presses.
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

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"SETUP: a Session exists to host/join (lane 2.A); without it there is no second peer to race")
	if not have_session:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"SETUP: peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"SETUP: peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"SETUP: peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])

	# --- one ripe bed, two hands ---------------------------------------------

	for i in 2:
		var stood: Dictionary = await step(i, "farm_stand",
			{"index": BED_INDEX, "realm": "meadows", "crop_item": CROP, "yield": YIELD})
		check(str(stood.get("verdict", "")) == "PASS",
			"SETUP: peer %d planted a ripe crop on bed %d (%s)"
				% [i, BED_INDEX, str(stood.get("detail", ""))])

	var start := [await probe(0, "farm"), await probe(1, "farm")]
	check(start[0] is Dictionary and start[1] is Dictionary,
		"SETUP: both peers report a bed")
	if not (start[0] is Dictionary and start[1] is Dictionary):
		quit(await finish())
		return
	check(_flag(start[0]) == _flag(start[1]),
		"SETUP: both peers name the same crop cycle ('%s' / '%s')"
			% [_flag(start[0]), _flag(start[1])])
	for i in 2:
		check(_state(start[i]) == "ripe",
			"SETUP: peer %d's bed is ripe before the race (state '%s')" % [i, _state(start[i])])
		check(not _claimed(start[i]),
			"SETUP: peer %d's world does not yet say bed %d is picked" % [i, BED_INDEX])
	var total_before := _held(start[0]) + _held(start[1])
	print("the %s in the world before the race: %d (peer 0: %d, peer 1: %d)"
		% [CROP, total_before, _held(start[0]), _held(start[1])])

	# --- the race -------------------------------------------------------------

	var press_at := Time.get_unix_time_from_system() * 1000.0 + PRESS_LEAD_MS
	for i in 2:
		var armed: Dictionary = await step(i, "farm_pick", {"at_unix_ms": press_at})
		check(str(armed.get("verdict", "")) == "PASS",
			"peer %d armed its pick (%s)" % [i, str(armed.get("detail", ""))])
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var after := [await probe(0, "farm"), await probe(1, "farm")]
	for i in 2:
		check(after[i] is Dictionary, "peer %d still reports its bed after the race" % i)
	if not (after[0] is Dictionary and after[1] is Dictionary):
		quit(await finish())
		return
	print("peer 0 farm: %s" % str(after[0]))
	print("peer 1 farm: %s" % str(after[1]))

	# The commit reached both worlds, and the bed reads as worked soil on both.
	# A peer whose world says "picked" while its own bed still reads ripe is the
	# bug this conversion removes: the mirror riding the press instead of the
	# delta.
	for i in 2:
		check(_claimed(after[i]),
			"peer %d's world records the crop on bed %d as picked" % [i, BED_INDEX])
		check(_state(after[i]) == "tilled",
			"peer %d's bed went back to worked soil off the delta (state '%s')"
				% [i, _state(after[i])])

	# Nothing was created and nothing was destroyed. This is the assertion that
	# fails on `main` before this lane: both peers were paid the full yield.
	var total_after := _held(after[0]) + _held(after[1])
	check(total_after == total_before + YIELD,
		"exactly one crop was picked: %d %s before, %d after (peer 0: %d -> %d, peer 1: %d -> %d)"
			% [total_before, CROP, total_after, _held(start[0]), _held(after[0]),
				_held(start[1]), _held(after[1])])

	var winner := -1
	var loser := -1
	for i in 2:
		if _held(after[i]) == _held(start[i]) + YIELD:
			winner = i
		elif _held(after[i]) == _held(start[i]):
			loser = i
	check(winner >= 0 and loser >= 0 and winner != loser,
		"exactly one peer walked away with the crop (peer 0: %d -> %d, peer 1: %d -> %d)"
			% [_held(start[0]), _held(after[0]), _held(start[1]), _held(after[1])])
	if winner < 0 or loser < 0 or winner == loser:
		quit(await finish())
		return
	print("peer %d picked the crop; peer %d lost it" % [winner, loser])

	if _press(after[loser]) != "submitted":
		check(_press(after[loser]) == "gone" and _refusals(after[loser]).is_empty(),
			"peer %d (the loser) submitted nothing because the crop was already picked (press: '%s', refusals: %s)"
				% [loser, _press(after[loser]), str(_refusals(after[loser]))])
		print("peer %d lost by shape B: the delta cleared the bed before its press landed" % loser)
	else:
		check(_code(after[loser]) == "already_taken",
			"peer %d (the loser) was refused with `already_taken` (refusals: %s)"
				% [loser, str(_refusals(after[loser]))])
		var told := _reason(after[loser])
		check(not told.is_empty(),
			"peer %d (the loser) was given a sentence to show the player, not silence" % loser)
		check(told.to_lower().contains("someone else"),
			"peer %d's refusal reads like something a player can act on: '%s'" % [loser, told])
		print("peer %d lost by shape A: refused `already_taken` -- '%s'" % [loser, told])

	check(_refusals(after[winner]).is_empty(),
		"peer %d (the winner) was not also refused (refusals: %s)"
			% [winner, str(_refusals(after[winner]))])

	quit(await finish())


# --- reading a `probe farm` row ----------------------------------------------
#
# Every reader answers a sentinel for a row that is not a Dictionary rather than
# indexing into one, so a probe that came back null fails an assertion instead of
# aborting the run with fewer assertions than it should have had.

func _flag(row: Variant) -> String:
	return str((row as Dictionary).get("flag", "")) if row is Dictionary else ""


func _claimed(row: Variant) -> bool:
	return bool((row as Dictionary).get("claimed", false)) if row is Dictionary else false


func _state(row: Variant) -> String:
	return str((row as Dictionary).get("state", "")) if row is Dictionary else ""


## How much of the contested crop this peer's satchel holds -- addressed by item
## identity, never by slot number (CLAUDE.md).
func _held(row: Variant) -> int:
	if not (row is Dictionary):
		return -1
	var map: Variant = (row as Dictionary).get("satchel", {})
	if not (map is Dictionary):
		return -1
	return int((map as Dictionary).get(CROP, 0))


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
