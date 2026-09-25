extends "res://tests/helpers/net_harness.gd"

# peers: 3

## Two GUESTS see each other walk, and the host sees both. Host plus two
## clients in the Meadows.
##
##   tools/net/run_net_smoke.sh net_session_guest_sees_guest
##
## `smoke_net_movement_two_peers.gd` proves host <-> client movement, and the
## three- and four-peer session smokes prove the registry and world state, but
## nothing proved that a trainer keeps moving on a screen that holds MORE than
## one remote trainer. From the third peer on, every viewer holds two or more
## replicas, all spawned at the world's spawn point, and that is a different
## case: a guest's pose also reaches the other guest only through the host's
## SceneMultiplayer relay. A replica that stays put while its owner walks
## fails here and nowhere else.

const WALK_M := 2.0
const WALK_FRAMES := 300
const SETTLE_FRAMES := 60
const NEAR_REST_M := 1.5


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(3, "world"):
		quit(await finish())
		return
	check(_peers.size() == 3, "coordinator tracked 3 peers")

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session, "a Session exists to host/join")
	if not have_session:
		quit(await finish())
		return
	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	for i in [1, 2]:
		var joined: Dictionary = await step(i, "join", {"host": "127.0.0.1", "port": port})
		check(str(joined.get("verdict", "")) == "PASS",
			"peer %d joined on port %d (%s)" % [i, port, str(joined.get("detail", ""))])
	for i in 3:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 3})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds all three players (%s)" % [i, str(seen.get("detail", ""))])

	var ids: Array = []
	for i in 3:
		var s = await probe(i, "session")
		ids.append(int((s as Dictionary).get("peer_id", 0)) if s is Dictionary else 0)
	check(ids[1] > 1 and ids[2] > 1 and ids[1] != ids[2],
		"both guests have distinct non-host peer ids (%s)" % str(ids))

	# Every peer draws the two others, before anybody walks.
	for i in 3:
		var bodies = await _await_others(i, 2, 30)
		check(bodies.size() == 2, "peer %d draws both other players (drew %d)" % [i, bodies.size()])

	# Each guest walks while the other guest AND the host watch. The host's
	# copy matters beyond drawing: its distance checks read that body.
	for pair in [[1, 2], [2, 1]]:
		var mover: int = pair[0]
		var watchers: Array = [pair[1], 0]
		var before = await probe(mover, "position")
		var seen_before := {}
		for watcher: int in watchers:
			seen_before[watcher] = _body_for(await probe(watcher, "remote_trainers"), ids[mover])
			check(not (seen_before[watcher] as Dictionary).is_empty(),
				"peer %d holds a body for guest %d before it walks" % [watcher, mover])
		var v: Dictionary = await step(mover, "stick", {"x": 0.0, "y": -1.0, "frames": WALK_FRAMES})
		check(str(v.get("verdict", "")) == "PASS",
			"guest %d held the stick forward (%s)" % [mover, str(v.get("detail", ""))])
		var after = await probe(mover, "position")
		check(_planar(before, after) >= WALK_M,
			"guest %d walked at least %.0f m (walked %.2f m)" % [mover, WALK_M, _planar(before, after)])
		await step(pair[1], "wait", {"frames": SETTLE_FRAMES})
		var rest_owner = await probe(mover, "position")
		for watcher: int in watchers:
			var was: Dictionary = seen_before[watcher]
			var now := _body_for(await probe(watcher, "remote_trainers"), ids[mover])
			var gap := _planar(now.get("pos", null), rest_owner) if not now.is_empty() else -1.0
			check(gap >= 0.0 and gap <= NEAR_REST_M,
				"peer %d saw guest %d arrive within %.1f m of where it stopped (%.2f m)"
					% [watcher, mover, NEAR_REST_M, gap])
			var drawn_moved := _planar(was.get("pos", null), now.get("pos", null)) \
				if not was.is_empty() and not now.is_empty() else -1.0
			check(drawn_moved >= WALK_M,
				"peer %d's copy of guest %d moved at least %.0f m (moved %.2f m)"
					% [watcher, mover, WALK_M, drawn_moved])

	quit(await finish())


func _await_others(peer: int, want: int, seconds: int) -> Array:
	var deadline := Time.get_ticks_msec() + seconds * 1000
	var last: Array = []
	while Time.get_ticks_msec() < deadline:
		last = []
		var bodies = await probe(peer, "remote_trainers")
		if bodies is Dictionary:
			for key in (bodies as Dictionary).keys():
				var row: Variant = (bodies as Dictionary)[key]
				if row is Dictionary and not bool((row as Dictionary).get("mine", false)) \
						and bool((row as Dictionary).get("visible", false)):
					last.append(row)
		if last.size() == want:
			return last
		await step(peer, "wait", {"frames": 30})
	return last


static func _body_for(bodies: Variant, peer_id: int) -> Dictionary:
	if not (bodies is Dictionary):
		return {}
	var row: Variant = (bodies as Dictionary).get(str(peer_id), {})
	return row if row is Dictionary else {}


static func _planar(a: Variant, b: Variant) -> float:
	if not (a is Array) or not (b is Array) or (a as Array).size() < 3 or (b as Array).size() < 3:
		return -1.0
	return Vector2(float(a[0]) - float(b[0]), float(a[2]) - float(b[2])).length()
