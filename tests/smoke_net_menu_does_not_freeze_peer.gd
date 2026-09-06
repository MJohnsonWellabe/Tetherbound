extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B, `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` §17 item 16 — **menus
## without freezing others**. The row read "**owed** — no smoke yet".
##
##   tools/net/run_net_smoke.sh menu_does_not_freeze_peer
##
## ## What it asserts
##
## D102 (`docs/decisions/D102-menus-never-pause-a-multi-peer-session.md`), from
## `docs/MULTIPLAYER_DIRECTIVE.md` §13: a panel pauses the tree only when
## pausing it would stop nobody but the player who opened it. So, in one run:
##
##   * **Solo keeps true pause.** Before either peer hosts or joins anything,
##     peer 0 opens the real pause shell with the real button and its tree
##     really is paused. This half runs FIRST, deliberately: a run whose
##     multi-peer half passed because the pause had been deleted outright
##     rather than made conditional fails here.
##   * **In a session the tree is not paused.** The same peer, same button,
##     after hosting a session somebody has joined: `SceneTree.paused` is false.
##   * **The other player keeps playing** for as long as the panel is open —
##     walks on raw stick input, gathers a find through the host's ledger, and
##     builds a structure that reaches the world as a delta. Asserted with the
##     panel open on the HOST first and then on the CLIENT, because those are
##     two different worlds to freeze.
##   * **The player who opened it is still stood down.** Their world verbs do
##     nothing while it is up — `input_owner.gd`'s group, which is the whole of
##     D102's argument: the multi-peer path reuses the mechanism `build_menu.gd`
##     has relied on since OW10 rather than inventing a second gate.
##   * **And they get the world back on close**: context returns to `world` and
##     the same stick that did nothing a moment ago moves them.
##
## ## What each half proves, and what it does not
##
## `paused` is read off `SceneTree.paused` on the peer that opened the panel
## (`probe local_pause`), so the mechanism assertion is exact. The behavioural
## half is deliberately weaker than it looks and this file will not overstate
## it: `Session` and `LedgerRpc` are `PROCESS_MODE_ALWAYS`, so a peer whose tree
## was wrongly paused would still answer some network traffic, and a gather that
## succeeded through a frozen host is not proof the host was not frozen. The
## gather, the walk and the jump are here because they are what item 16 is about
## in the player's hands; `paused` is what makes it a mechanism test. Both, not
## either.
##
## ## Why the third verb is not a jump
##
## It was, and it never fired. `press` with `confirm: left_floor` reports "never
## left the floor" on every peer, and a one-peer probe run on this base
## (2026-09-06) showed the same thing **with no session and no panel open at
## all**: `on_floor` stays true and `y` never moves off 4.950 across three
## presses. So it is not D102 and not a session, and it is not this lane's to
## fix — `left_floor` had no other user in the tree, and `peer_runner.gd`'s
## `_inject()` header says its press ordering was measured against `jump`
## specifically, so one of those two has drifted since. Recorded as a finding
## with that reproduction rather than worked around silently.
##
## ## Setup is granted explicitly and says so
##
## Every find this smoke gathers is STOOD by the smoke (`pickup_stand`), never
## assumed to be lying in the meadow. A smoke that failed because nothing was
## there to pick up would report "the other player could not gather", which
## reads as the feature failing when it is the fixture missing (lane 6.A's
## smokes reported `enter_realm refused` for a key they never granted).
##
## ## The debug order if it fails
##
## Both peers' `probe local_pause` rows are printed at every stage. Read them in
## this order: `session_peers` on the peer that opened the panel (1 means the
## join never landed and every multi-peer assertion below is measuring solo);
## then `multi_peer` (false with 2 session peers means `Game.is_multi_peer()`
## disagrees with the registry); then `menu_open` and `owner` (empty means the
## button never reached `game_menu.gd::_read_actions`, so nothing after it means
## anything); then `paused`; then `context`.

## The walk, and the two bars it is judged against.
##
## Both numbers are `smoke_net_movement_two_peers.gd`'s, measured rather than
## chosen: 300 frames of full stick, and 2 m as the bar. That file's own header
## carries why it is 2 m and not 20 -- a fresh boot starts inside Grandpa's
## farmhouse and forward from the spawn is a wall about three metres away, so
## the client walks 2.42 m and the host 14.61 m on the identical hold (measured
## on this base, 2026-09-06). **90 frames measures nothing**: the first run of
## this smoke used it and both peers reported 0.00 m with no panel open at all,
## which is a fixture defect that would have read as the feature failing.
##
## `STILL_M` is this harness's own `DEFAULT_NEAR_REST_M`. The bar is not only
## the constant, though: a stood-down walk is also required to be under half of
## THAT PEER's own free walk, measured in this same run, so the assertion stays
## a comparison rather than a fixed number that a slower machine could pass by
## being slow.
const MOVE_FRAMES := 300
const MOVED_M := 2.0
const STILL_M := DEFAULT_NEAR_REST_M
const SUPPRESSED_FRACTION := 0.5

## Frames for a gathered find or a placed structure to commit on the host and
## come back.
const SETTLE_FRAMES := 240

## Where each peer stood when the session formed. Every measured walk starts
## from here, teleported back first, so the geometry under a walk is identical
## every time and a peer that walked itself into a corner on one leg does not
## silently fail the next. A teleport is a harness act, not a game verb, so it
## works the same whether the peer's world verbs are stood down or not -- which
## is exactly what makes it safe to use on the peer holding the panel.
var _home: Array = [Vector3.INF, Vector3.INF]
## Each peer's own free walk, measured once with nothing open. The
## denominator of the suppression assertion.
var _free: Array = [0.0, 0.0]

var _asserts := 0


func _initialize() -> void:
	_run()


## Every assertion goes through here rather than through `check()` directly, so
## the run reports HOW MANY assertions ran. A test that passes while running
## fewer assertions than it should is the failure mode this project has already
## paid for twice (`int(null)` is 0, which aborts a branch rather than failing
## it), and a count is the cheapest thing that makes it visible.
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

	# ---------------------------------------------------------------------
	# Half one: SOLO STILL PAUSES. Before anybody hosts or joins anything.
	# ---------------------------------------------------------------------
	var solo_before: Dictionary = await _pause_row(0, "peer 0, solo, before opening")
	want(not bool(solo_before.get("multi_peer", true)),
		"peer 0 is not in a multi-peer session yet (session_peers=%d)"
			% int(solo_before.get("session_peers", -1)))
	want(not bool(solo_before.get("paused", true)),
		"and its tree is running")

	var solo_open: Dictionary = await step(0, "menu_toggle", {"open": true})
	want(str(solo_open.get("verdict", "")) == "PASS",
		"peer 0 opened the pause shell with the real button (%s)" % str(solo_open.get("detail", "")))
	var solo_up: Dictionary = await _pause_row(0, "peer 0, solo, panel open")
	want(bool(solo_up.get("menu_open", false)), "the shell reports itself open")
	want(bool(solo_up.get("paused", false)),
		"SOLO KEEPS TRUE PAUSE: peer 0's tree is paused with no session (paused=%s)"
			% str(solo_up.get("paused", false)))

	var solo_shut: Dictionary = await step(0, "menu_toggle", {"open": false})
	want(str(solo_shut.get("verdict", "")) == "PASS",
		"peer 0 closed it again (%s)" % str(solo_shut.get("detail", "")))
	var solo_after: Dictionary = await _pause_row(0, "peer 0, solo, panel shut")
	want(not bool(solo_after.get("paused", true)), "and the world came back")

	# ---------------------------------------------------------------------
	# The session. Same handshake block every net smoke uses.
	# ---------------------------------------------------------------------
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	want(have_session, "a Session exists to host/join; without it there is nothing to freeze")
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

	# --- the baseline, with nothing open -------------------------------------
	#
	# Measured before any panel exists, on both peers. Without it, "it did not
	# move" below could mean the stick never worked in this scene at all -- and
	# on the first run of this smoke that is exactly what it meant.
	for i in 2:
		_home[i] = await _pos(i)
		want(_home[i] != Vector3.INF, "peer %d has a position to walk from" % i)
	for i in 2:
		_free[i] = await _walk(i)
		want(_free[i] >= MOVED_M,
			"peer %d walks %.2f m in %d frames with nothing open (bar %.1f m)"
				% [i, _free[i], MOVE_FRAMES, MOVED_M])

	# The host opening a panel and a client opening one are two different worlds
	# to freeze, so both are run. `opener` holds the panel; `other` keeps playing.
	await _panel_round(0, 1, "host_find")
	await _panel_round(1, 0, "client_find")

	print("assertions run: %d" % _asserts)
	quit(await finish())


## One player opens a panel; the other keeps playing throughout.
func _panel_round(opener: int, other: int, find_id: String) -> void:
	print("--- peer %d holds a panel open; peer %d keeps playing ---" % [opener, other])

	var opened: Dictionary = await step(opener, "menu_toggle", {"open": true})
	want(str(opened.get("verdict", "")) == "PASS",
		"peer %d opened the pause shell in a session (%s)" % [opener, str(opened.get("detail", ""))])

	var up: Dictionary = await _pause_row(opener, "peer %d, in session, panel open" % opener)
	want(bool(up.get("multi_peer", false)),
		"peer %d knows somebody else is here (session_peers=%d)"
			% [opener, int(up.get("session_peers", -1))])
	want(bool(up.get("menu_open", false)), "peer %d's shell reports itself open" % opener)
	want(not bool(up.get("paused", true)),
		"D102: peer %d's panel did NOT pause the tree in a session (paused=%s)"
			% [opener, str(up.get("paused", true))])
	want(not str(up.get("owner", "")).is_empty(),
		"and the panel owns input through input_owner.gd's group (owner '%s')"
			% str(up.get("owner", "")))
	want(str(up.get("context", "")).begins_with("menu"),
		"peer %d's input context says the shell has the screen (got '%s')"
			% [opener, str(up.get("context", ""))])

	# --- the other player keeps playing, for the whole time it is open --------

	# MOVING.
	var moved := await _walk(other)
	want(moved >= MOVED_M,
		"peer %d KEPT MOVING while peer %d held a panel open: %.2f m (bar %.1f m; it walks %.2f m with nothing built in the way)"
			% [other, opener, moved, MOVED_M, _free[other]])

	# GATHERING. Setup granted explicitly: the find is STOOD by this smoke.
	# Nothing here assumes the meadow happened to have one lying about.
	var stood: Dictionary = await step(other, "pickup_stand",
		{"id": find_id, "item": "berries", "realm": "meadows", "count": 1})
	want(str(stood.get("verdict", "")) == "PASS",
		"setup: a find was stood for peer %d to gather (%s)" % [other, str(stood.get("detail", ""))])
	var held_before := _held(await probe(other, "pickup"))
	var took: Dictionary = await step(other, "pickup_take", {})
	want(str(took.get("verdict", "")) == "PASS",
		"peer %d pressed the find (%s)" % [other, str(took.get("detail", ""))])
	await step(other, "wait", {"frames": SETTLE_FRAMES})
	var after_take: Variant = await probe(other, "pickup")
	want(after_take is Dictionary, "peer %d still reports its find" % other)
	want(_held(after_take) == held_before + 1,
		"peer %d KEPT GATHERING: its satchel went %d -> %d berries with peer %d's panel open"
			% [other, held_before, _held(after_take), opener])
	want(bool((after_take as Dictionary).get("claimed", false)),
		"and the WORLD recorded the claim, so it went through the host's ledger rather than staying local")

	# ACTING. A structure is a world-changing act that leaves this peer, is
	# arbitrated by the host and comes back as a delta that plants a node --
	# distinct from the gather above, which only sets a flag.
	#
	# It is placed LAST of the other player's three verbs on purpose: both
	# peers spawn on the same point, so a floor planted at it is standing in
	# the way of every walk measured afterwards. That is why "kept moving" is
	# judged against the fixed 2 m bar and not against this peer's own free
	# walk -- the first run of this file did the latter and went red at 3.09 m
	# against a 14.57 m baseline, which was the previous round's floor, not
	# the feature.
	var built_before := int(await probe(other, "placed_building_count"))
	var built: Dictionary = await step(other, "build_place", {"id": "floor"})
	want(str(built.get("verdict", "")) == "PASS",
		"peer %d KEPT ACTING: it built with peer %d's panel open (%s)"
			% [other, opener, str(built.get("detail", ""))])
	await step(other, "wait", {"frames": SETTLE_FRAMES})
	var built_after := int(await probe(other, "placed_building_count"))
	want(built_after == built_before + 1,
		"and the structure reached the world through the host: %d -> %d records"
			% [built_before, built_after])

	# --- and the player holding it is stood down -----------------------------

	var drift := await _walk(opener)
	want(drift <= STILL_M and drift <= _free[opener] * SUPPRESSED_FRACTION,
		"peer %d's own world verbs are stood down while its panel is open: %.2f m on a full stick hold (bar %.1f m, and under half of the %.2f m it walks free)"
			% [opener, drift, STILL_M, _free[opener]])

	var still_up: Dictionary = await _pause_row(opener, "peer %d, panel still open" % opener)
	want(not bool(still_up.get("paused", true)),
		"peer %d's tree is still running after all of that" % opener)
	want(bool(still_up.get("menu_open", false)),
		"peer %d's panel was open for the whole of it, not only at the start" % opener)

	# --- close, and the world comes back -------------------------------------

	var shut: Dictionary = await step(opener, "menu_toggle", {"open": false})
	want(str(shut.get("verdict", "")) == "PASS",
		"peer %d closed the panel (%s)" % [opener, str(shut.get("detail", ""))])
	var down: Dictionary = await _pause_row(opener, "peer %d, panel shut" % opener)
	want(not bool(down.get("paused", true)), "peer %d's tree is running after the close" % opener)
	want(str(down.get("context", "")) == "world",
		"peer %d is back in the world context (got '%s')" % [opener, str(down.get("context", ""))])

	var back := await _walk(opener)
	want(back >= MOVED_M,
		"and peer %d got the world back: %.2f m on the same hold that moved it %.2f m a moment ago"
			% [opener, back, drift])


## Teleport a peer back to where it stood when the session formed, so every
## measured walk starts from identical, known-good geometry. See `_home`.
func _go_home(peer: int) -> void:
	var at: Vector3 = _home[peer]
	if at == Vector3.INF:
		return
	await step(peer, "teleport", {"at": [at.x, at.y, at.z]})


## One measured walk: home, then a full stick hold forward. Returns the
## horizontal distance covered.
func _walk(peer: int) -> float:
	await _go_home(peer)
	var from := await _pos(peer)
	await step(peer, "stick", {"stick": "left", "x": 0.0, "y": -1.0, "frames": MOVE_FRAMES})
	var to := await _pos(peer)
	return _dist(from, to)


# --- reading peers -----------------------------------------------------------

## `probe local_pause`, printed on every read. See the header's debug order.
func _pause_row(peer: int, why: String) -> Dictionary:
	var row: Variant = await probe(peer, "local_pause")
	if not (row is Dictionary):
		_asserts += 1
		check(false, "%s: probe local_pause returned nothing (peer dead or probe missing)" % why)
		return {}
	print("%s: %s" % [why, str(row)])
	return row as Dictionary


func _pos(peer: int) -> Vector3:
	var raw: Variant = await probe(peer, "position")
	if not (raw is Array) or (raw as Array).size() != 3:
		return Vector3.INF
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


## Horizontal distance. Height is left out on purpose: a body settling onto
## Terrain3D can gain or lose half a metre of Y with the stick untouched, and
## this smoke is asking whether the player WALKED.
func _dist(a: Vector3, b: Vector3) -> float:
	if a == Vector3.INF or b == Vector3.INF:
		return -1.0
	return Vector2(a.x - b.x, a.z - b.z).length()


## Berries in this peer's satchel, addressed by item identity and never by slot
## number (CLAUDE.md). `has()` before `get()`: a missing key read through `get()`
## is null and `int(null)` is 0, which would make a probe that returned nothing
## look like an empty satchel.
func _held(row: Variant) -> int:
	if not (row is Dictionary) or not (row as Dictionary).has("satchel"):
		return -1
	var map: Variant = (row as Dictionary)["satchel"]
	if not (map is Dictionary):
		return -1
	return int((map as Dictionary).get("berries", 0))
