extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B lane 4.B. THE player-visible outcome of the lane: two people in one
## Meadows each have their OWN creature standing beside them, and each of them
## can see the other's.
##
##   tools/net/run_net_smoke.sh deploy_two_creatures
##
## ## What it asserts
##
## Both peers boot the Meadows and form a session (the handshake block below is
## `tests/smoke_net_movement_two_peers.gd`'s, verbatim -- one handshake, one
## shape, so a change to how a session forms breaks both smokes together rather
## than leaving this one quietly testing an older protocol).
##
## Each peer then deploys its own creature through the game's own door
## (`encounter_director.gd`, via the runner's `deploy_creature` step). After
## that, in EACH process:
##
##   * exactly one deployed body answers `is_local_deployment()` -- the
##     `follower_creature.gd` this peer pilots itself, in solo's own code path;
##   * exactly one deployed body is owned by the OTHER peer, is visible, and
##     carries THAT peer's multiplayer authority;
##   * the local peer's own outbound proxy exists, carries the local peer's
##     authority and is not drawn (the owner already has a real creature
##     standing in that spot);
##   * so exactly two OWNERS have a creature out, one each.
##
## ## Why authority and not presence
##
## Stated because the project has already paid for it once. Godot installs an
## `OfflineMultiplayerPeer` by default, where `multiplayer.is_server()` is true
## and `get_unique_id()` is 1 with no session at all, so a body can be spawned
## by the wrong process, or spawned by the right one with authority left on the
## host, and NOTHING reports it. A creature whose authority is not its owner's
## never receives its owner's transform: it stands exactly where it spawned,
## forever. On screen that is a frozen creature, which reads as a creature that
## is idle. `check`ing that a body merely exists would pass in that world.
##
## The debug order if it fails: does the other peer's body exist at all
## (`deployed_creatures` has an entry with `local` false), is its `authority`
## the OTHER peer's id, and only then whether it is visible or where it stands.

## Frames to let the spawn packet, the first synchronizer delta and the
## proxy's own snap-to-target land on the far side. Ten interpolation
## half-lives plus the reliable spawn's round trip; the ENet spike measured a
## 6.9 ms median loopback RTT, so this is two orders of magnitude of margin.
const SETTLE_FRAMES := 90


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
		"a Session exists to host/join (lane 2.A); without it there are no creature bodies to own")
	if not have_session:
		quit(await finish())
		return

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
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
	# --- end of the copied handshake ------------------------------------------

	# The real peer ids, read off each process rather than assumed: only the
	# listen server is 1 and a joiner's id is a large random 32-bit number
	# (ENet spike finding 2). Every assertion below compares against these.
	var ids: Array[int] = []
	for i in 2:
		var row = await probe(i, "session")
		ids.append(int((row as Dictionary).get("peer_id", 0)) if row is Dictionary else 0)
	check(ids[0] == 1, "peer 0 is the listen server (id %d)" % ids[0])
	check(ids[1] != 0 and ids[1] != ids[0],
		"peer 1 has its own distinct peer id (%d)" % ids[1])

	# Each peer puts ITS OWN creature out, through the game's own door.
	for i in 2:
		var out: Dictionary = await step(i, "deploy_creature", {"species": "terrapup"})
		check(str(out.get("verdict", "")) == "PASS",
			"peer %d deployed its own creature (%s)" % [i, str(out.get("detail", ""))])

	# Let the spawns and the first deltas land on both sides.
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	for viewer in 2:
		var mine_id := ids[viewer]
		var other_id := ids[1 - viewer]
		var raw = await probe(viewer, "deployed_creatures")
		var bodies: Dictionary = raw if raw is Dictionary else {}

		var local_rows := _rows_where(bodies, "local", true)
		check(local_rows.size() == 1,
			"peer %d pilots exactly 1 creature of its own (got %d: %s)"
				% [viewer, local_rows.size(), _names(bodies)])

		var owners := _owners(bodies)
		check(owners.size() == 2,
			"peer %d sees creatures belonging to 2 owners (got %d: %s)"
				% [viewer, owners.size(), str(owners)])
		check(owners.has(mine_id) and owners.has(other_id),
			"peer %d sees a creature for itself (%d) and for the other player (%d), got %s"
				% [viewer, mine_id, other_id, str(owners)])

		# The other player's creature: present, owned by them, carrying THEIR
		# authority, and actually drawn.
		var theirs := _creature_proxy_for(bodies, other_id)
		check(not theirs.is_empty(),
			"peer %d holds a replicated body for peer %d's creature" % [viewer, other_id])
		if not theirs.is_empty():
			check(int(theirs.get("authority", 0)) == other_id,
				"peer %d's copy of peer %d's creature carries THAT peer's authority (got %d)"
					% [viewer, other_id, int(theirs.get("authority", 0))])
			check(not bool(theirs.get("mine", true)),
				"peer %d does not claim authority over peer %d's creature" % [viewer, other_id])
			check(bool(theirs.get("visible", false)),
				"peer %d actually draws peer %d's creature" % [viewer, other_id])
			check(str(theirs.get("species", "")) != "",
				"peer %d's copy of peer %d's creature is a real species ('%s')"
					% [viewer, other_id, str(theirs.get("species", ""))])

		# This peer's own outbound proxy: same node in every process, its own
		# authority, and deliberately NOT drawn -- the owner already has a real
		# creature standing in that spot.
		var own_proxy := _creature_proxy_for(bodies, mine_id)
		check(not own_proxy.is_empty(),
			"peer %d holds its own outbound creature proxy" % viewer)
		if not own_proxy.is_empty():
			check(int(own_proxy.get("authority", 0)) == mine_id,
				"peer %d's own creature proxy carries its own authority (got %d)"
					% [viewer, int(own_proxy.get("authority", 0))])
			check(not bool(own_proxy.get("visible", true)),
				"peer %d does not draw a second copy of its own creature" % viewer)

	quit(await finish())


## Rows in a `deployed_creatures` probe whose `key` equals `value`.
func _rows_where(bodies: Dictionary, key: String, value: Variant) -> Array:
	var out: Array = []
	for name in bodies.keys():
		var row: Variant = bodies[name]
		if row is Dictionary and (row as Dictionary).get(key) == value:
			out.append(row)
	return out


## The replicated proxy (never the local piloted body) belonging to `peer_id`,
## or {} when there is none.
##
## Named `_creature_proxy_for` rather than `_proxy_for`: the base class
## (`net_harness.gd`) already declares `_proxy_for(target_port: int) -> int`,
## its own unrelated udp_proxy helper for Contract §9's simulated network
## conditions. Two independently-developed lanes gave two unrelated helpers
## the same name, and a same-named override with a mismatched signature is a
## GDScript PARSE ERROR -- this file failed to load at all until renamed.
func _creature_proxy_for(bodies: Dictionary, peer_id: int) -> Dictionary:
	for name in bodies.keys():
		var row: Variant = bodies[name]
		if not (row is Dictionary):
			continue
		var d: Dictionary = row
		if bool(d.get("local", false)):
			continue
		if int(d.get("owner", 0)) == peer_id:
			return d
	return {}


## The distinct peer ids that have a creature out, as this process sees it.
func _owners(bodies: Dictionary) -> Array:
	var out: Array = []
	for name in bodies.keys():
		var row: Variant = bodies[name]
		if not (row is Dictionary):
			continue
		var id := int((row as Dictionary).get("owner", 0))
		if id != 0 and not out.has(id):
			out.append(id)
	return out


static func _names(bodies: Dictionary) -> String:
	return ", ".join(PackedStringArray(bodies.keys()))
