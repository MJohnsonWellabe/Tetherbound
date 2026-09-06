extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 7 lane 7.A. **§17 ITEM 22: LATE-JOIN A MODIFIED WORLD.**
##
##   tools/net/run_net_smoke.sh late_join_modified_world
##
## The row this closes says "a peer joins after the world has changed and holds
## the same world as the host". Every earlier net smoke joins into a world
## nobody has touched yet, so every one of them would pass against a snapshot
## that carried nothing at all -- an empty world equals an empty world. This
## one changes the world FIRST, on the host alone, and only then lets anybody
## in.
##
## ## Why the assertion is a diff and not a spot-check
##
## The obvious version of this smoke asks three questions -- is the building
## there, is the pickup gone, is the flag set -- and passes. It would also pass
## against a snapshot that carried exactly those three keys and dropped the
## other seven, which is the failure this row exists to catch: a world key
## added by a later lane and never added to `world_snapshot()` is invisible to
## any spot-check written before that key existed.
##
## So the assertion is a **key-by-key diff of the host's whole world
## dictionary against the joiner's** -- `Game.world_snapshot()` on both ends,
## which is literally the payload `session.gd::_rpc_snapshot` puts on the wire,
## asked of the joiner after it has applied it. A key the host has and the
## joiner does not is a failure naming that key, whether or not this file knew
## the key existed. The three spot-checks are kept underneath it, because a
## diff that passes tells you nothing about whether the change ever happened.
##
## `clock_elapsed_seconds` is the one key excluded, for contract §7's own
## reason: it advances with wall time in both processes and is re-synced
## by `_rpc_clock` on its own schedule, so it is never equal at an instant.
##
## ## The shape of the run
##
##   1. peer 0 boots the Meadows and hosts. Peer 1 is booted but NOT joined --
##      it is a cold process holding its own untouched world, which is what
##      makes step 3's "before" reading meaningful;
##   2. the host changes the world three ways, each through a different
##      seam so the snapshot is exercised broadly rather than deeply: a
##      BUILDING placed (`placed_buildings`), a one-shot pickup TAKEN
##      (`flags`, and the record a joiner needs to not re-draw the prop), and
##      a world story FLAG set (`flags`, through the ledger);
##   3. both worlds are read BEFORE the join and shown to disagree -- the
##      negative control built into the run rather than asserted from a
##      previous wave, since "the joiner would have had this world anyway" is
##      the one way this smoke could be vacuous;
##   4. peer 1 joins;
##   5. the whole world dictionary is diffed. Then the three spot-checks, and
##      the contract's own `state_hash` equality on top.
##
## ## Negative control (contract §11)
##
## Recorded in `ralph/reports/MP-7A-RELIABILITY-0906/REPORT.md`: the run at
## step 3 IS the control, and it is inside the file rather than beside it --
## `check(before_diff.size() > 0)` fails the smoke if the two worlds already
## agreed before the join, which is exactly the state in which the step-5 diff
## proves nothing.

## The building the host places. `floor` is the cheapest record in
## `data/buildings.json` and the one `smoke_net_shared_building.gd` already
## uses, so a failure here is never about which building was chosen.
const BUILDING_ID := "floor"

## The one-shot cache the host takes. Its id is namespaced to this smoke so it
## can never collide with an authored find or with lane 3.B's race cache.
const PICKUP_ID := "net_late_join_cache"
const PICKUP_ITEM := "berries"

## A world-scope story flag. Deliberately one the game does not author, so a
## world that happened to have it set for a real reason cannot make this pass.
const WORLD_FLAG := "smoke_late_join_world_marker"

## Contract §7's reason, restated as code: this key advances with wall time in
## both processes independently of anything the snapshot carries.
const VOLATILE_WORLD_KEYS: Array[String] = ["clock_elapsed_seconds"]


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var host_port := int(host_hello.get("enet_port", 0))
	check(host_port > 0, "host reported its ENet port in hello (%d)" % host_port)
	if host_port <= 0:
		quit(await finish())
		return

	# 1. The host hosts. Peer 1 stays out.
	var hosted: Dictionary = await step(0, "host", {"port": host_port})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a listen server (%s)" % str(hosted.get("detail", "")))
	if str(hosted.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# 2. Change the world, on the host, with nobody connected.
	var built: Dictionary = await step(0, "build_place", {"id": BUILDING_ID})
	check(str(built.get("verdict", "")) == "PASS",
		"the host placed a '%s' (%s)" % [BUILDING_ID, str(built.get("detail", ""))])

	var stood: Dictionary = await step(0, "pickup_stand",
		{"id": PICKUP_ID, "item": PICKUP_ITEM, "count": 1, "realm": "meadows"})
	check(str(stood.get("verdict", "")) == "PASS",
		"the host stood a one-shot cache (%s)" % str(stood.get("detail", "")))
	var took: Dictionary = await step(0, "pickup_take", {})
	check(str(took.get("verdict", "")) == "PASS",
		"the host took it (%s)" % str(took.get("detail", "")))
	var claimed: Dictionary = await step(0, "wait_flag",
		{"flag": _pickup_flag(), "scope": "world", "budget_frames": 600})
	check(str(claimed.get("verdict", "")) == "PASS",
		"the world records the cache as taken (%s)" % str(claimed.get("detail", "")))

	var flagged: Dictionary = await step(0, "story_flag", {"flag": WORLD_FLAG, "scope": "world"})
	check(str(flagged.get("verdict", "")) == "PASS",
		"the host set a world story flag (%s)" % str(flagged.get("detail", "")))
	var flag_landed: Dictionary = await step(0, "wait_flag",
		{"flag": WORLD_FLAG, "scope": "world", "budget_frames": 600})
	check(str(flag_landed.get("verdict", "")) == "PASS",
		"the world flag committed on the host (%s)" % str(flag_landed.get("detail", "")))

	# 3. The negative control, inside the run: the two worlds must DISAGREE
	# before the join, or step 5 proves nothing.
	var host_world_before := await _world_of(0)
	var joiner_world_before := await _world_of(1)
	check(not host_world_before.is_empty(),
		"the host answered a world_snapshot probe (%d keys)" % host_world_before.size())
	check(not joiner_world_before.is_empty(),
		"the un-joined peer answered a world_snapshot probe (%d keys)" % joiner_world_before.size())
	var before_diff := _diff_worlds(host_world_before, joiner_world_before)
	check(before_diff.size() > 0,
		"BEFORE the join the two worlds disagree, so the after-diff is not vacuous (differing keys: %s)"
			% str(before_diff))

	# 4. Join, late, into the changed world.
	var joined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": "late-joiner", "display_name": "Late"}}, 6000)
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined a world that had already changed (%s)" % str(joined.get("detail", "")))
	if str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# 5. THE ASSERTION: the whole world, key by key.
	var host_world := await _world_of(0)
	var joiner_world := await _world_of(1)
	check(not joiner_world.is_empty(),
		"the late joiner answered a world_snapshot probe after joining (%d keys)" % joiner_world.size())

	var missing := _missing_keys(host_world, joiner_world)
	check(missing.is_empty(),
		"every world key the host holds is present on the late joiner (missing: %s)" % str(missing))

	var after_diff := _diff_worlds(host_world, joiner_world)
	check(after_diff.is_empty(),
		"the late joiner's world equals the host's key by key (differing: %s)" % str(after_diff))
	if not after_diff.is_empty():
		_dump_world_diff(host_world, joiner_world, after_diff)

	# The three spot-checks, UNDER the diff -- they say the change happened at
	# all, which a diff of two identical empty worlds could not.
	var host_buildings = await probe(0, "placed_building_rows")
	var joiner_buildings = await probe(1, "placed_building_rows")
	check(host_buildings is Array and (host_buildings as Array).size() > 0,
		"the host holds at least one building record (%s)" % str(host_buildings))
	check(str(host_buildings) == str(joiner_buildings),
		"the late joiner holds the same building records as the host (host %s / joiner %s)"
			% [str(host_buildings), str(joiner_buildings)])

	var joiner_claimed: Dictionary = await step(1, "assert",
		{"check": "flag_set", "flag": _pickup_flag()})
	check(str(joiner_claimed.get("verdict", "")) == "PASS",
		"the late joiner knows the cache was already taken (%s)" % str(joiner_claimed.get("detail", "")))

	var joiner_flag: Dictionary = await step(1, "assert", {"check": "flag_set", "flag": WORLD_FLAG})
	check(str(joiner_flag.get("verdict", "")) == "PASS",
		"the late joiner holds the world story flag (%s)" % str(joiner_flag.get("detail", "")))

	# And the contract's own detector, over the same two processes.
	check(await assert_all_hashes_equal(600),
		"contract §7 state_hash agrees across host and late joiner")

	quit(await finish())


## `item_cache_pickup.gd::flag_id()`'s shape, restated here rather than
## preloaded: the coordinator is a plain SceneTree script with no game
## autoloads, and the peers are the ones that hold the class. If the shape ever
## changes, `wait_flag` fails naming this exact string, which is a legible
## failure rather than a silent one.
func _pickup_flag() -> String:
	# `item_cache_pickup.gd::FLAG_PREFIX` + the placement id, which is the
	# meadows-realm branch of that function.
	return "cache:%s" % PICKUP_ID


## `Game.world_snapshot()` off one peer, as a Dictionary. `{}` on any failure,
## never `null` -- an `int(null)` abort is how a smoke silently runs fewer
## assertions than it should (lane 7.A's own trap list), so every caller here
## can ask `is_empty()` and get a real answer.
func _world_of(peer: int) -> Dictionary:
	var raw = await probe(peer, "world_snapshot")
	return (raw as Dictionary) if raw is Dictionary else {}


## Keys the host holds that the joiner does not hold AT ALL. Separated from the
## value diff on purpose: a missing key is a snapshot that does not carry that
## part of the world, and a differing value is a snapshot that carries it
## wrongly. Those are different defects and should not report as one line.
func _missing_keys(host: Dictionary, joiner: Dictionary) -> Array:
	var out: Array = []
	for key: Variant in host.keys():
		if str(key) in VOLATILE_WORLD_KEYS:
			continue
		if not joiner.has(key):
			out.append(str(key))
	out.sort()
	return out


## Every key on which the two worlds differ, in either direction. Compared as
## canonical JSON (sorted keys) so two dictionaries holding the same data in a
## different insertion order are equal -- which they legitimately are, since
## one was built by play and the other by `load_data()`.
func _diff_worlds(host: Dictionary, joiner: Dictionary) -> Array:
	var keys: Dictionary = {}
	for key: Variant in host.keys():
		keys[str(key)] = true
	for key2: Variant in joiner.keys():
		keys[str(key2)] = true
	var out: Array = []
	for key3: String in keys.keys():
		if key3 in VOLATILE_WORLD_KEYS:
			continue
		if _canonical(host.get(key3)) != _canonical(joiner.get(key3)):
			out.append(key3)
	out.sort()
	return out


func _canonical(value: Variant) -> String:
	return JSON.stringify(value, "", true, true)


## A failing diff writes both sides into the run directory, so the evidence is
## the two worlds rather than a list of key names somebody then has to
## reproduce the run to see. Contract §7 does the same for a desync.
func _dump_world_diff(host: Dictionary, joiner: Dictionary, keys: Array) -> void:
	var doc := {"differing_keys": keys, "host": {}, "joiner": {}}
	for key: Variant in keys:
		(doc["host"] as Dictionary)[str(key)] = host.get(str(key))
		(doc["joiner"] as Dictionary)[str(key)] = joiner.get(str(key))
	var path := _run_dir.path_join("late-join-world-diff.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(doc, "\t"))
		f.close()
		print("coordinator: wrote the world diff to %s" % path)
