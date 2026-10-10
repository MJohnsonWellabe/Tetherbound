extends "res://tests/smoke_net_veridian_relic_key.gd"

# peers: 4
## F48#2: a four-peer session completes one biome boss, and every participant
## receives their own key and relic.
##
##   tools/net/run_net_smoke.sh f48_four_peer_boss --peers=4
##
## Four real ENet processes, four saved characters. The host challenges the
## Warden (warden_aldis) through the production press; the three guests join
## that same fight; the host fights it down with real host-arbitrated strike
## intents (win_trainer_battle). Then, on EVERY peer: exactly one Tidewake
## portal key in its own satchel and the Meadows relic once in its own
## character, and its world holds the earned Heart once. A guest's rewards
## survive a leave and a returning-route rejoin.
## Disclosed fixtures: party_grant seeds each home before networking;
## explore_at stands each trainer in the Warden arena; dismiss_dialogue
## continues story lines; win_trainer_battle's enemy_hp_ceiling as in
## smoke_net_veridian_relic_key.
const PEERS := 4
var _ids: Array[String] = []
var _completed := false


func _run() -> void:
	heartbeat_silence_tolerance_s = 240.0
	if await launch(PEERS, "world"):
		await _flow()
	# A script error aborts _flow silently; only a completed flow passes.
	check(_completed, "the four-peer flow ran to its end")
	quit(await finish())


func _flow() -> void:
	_port = int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	check(_port > 0, "host reported its ENet port (%d)" % _port)
	if _port <= 0: return
	for peer in PEERS:
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 0})
		for species: String in PARTY:
			var granted: Dictionary = await step(peer, "party_grant", {"species": species, "level": 18})
			check(str(granted.get("verdict", "")) == "PASS", "FIXTURE: peer %d received %s" % [peer, species])
		_ids.append(str(((await step(peer, "save_character_here", {})).get("data", {}) as Dictionary).get("character_id", "")))
	var distinct := {}
	for id: String in _ids: distinct[id] = true
	check(distinct.size() == PEERS and not distinct.has(""), "four distinct stable characters (%s)" % str(_ids))
	if not _pass(await step(0, "host", {"port": _port}), "host hosted"): return
	for peer in range(1, PEERS):
		var joined: Dictionary = await step(peer, "join", {"host": "127.0.0.1", "port": _port,
			"character": {"character_id": _ids[peer], "display_name": "Relic Guest %d" % peer}}, 6000)
		if not _pass(joined, "guest %d joined" % peer): return
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 0})
	for peer in PEERS:
		if not _pass(await step(peer, "expect_peers", {"count": PEERS}), "peer %d sees four peers" % peer): return
	for peer in PEERS:
		var keys0 := await _keys(peer)
		var relics0 := await _relics_held(peer)
		check(keys0 == 0 and not relics0.has(RELIC), "peer %d holds no key or Meadows relic before the Warden" % peer)
	# The Warden, shared by all four.
	for peer in PEERS:
		await step(peer, "deploy_creature", {})
	var hold: Variant = await probe(0, "stronghold")
	var markers: Dictionary = (hold as Dictionary).get("markers", {}) as Dictionary if hold is Dictionary else {}
	var arena: Array = markers.get("warden_arena", []) as Array
	check(arena.size() == 3, "the Hall names its Warden arena (%s)" % str(arena))
	if arena.size() != 3: return
	for peer in PEERS:
		var offset: float = [-2.0, 2.0, -2.0, 2.0][peer]
		var depth: float = [0.0, 0.0, 2.5, 2.5][peer]
		await step(peer, "explore_at", {"at": [float(arena[0]) + offset, float(arena[2]), float(arena[1]) + depth], "settle": 60})
	if not _pass(await step(0, "trainer_battle", {"trainer": WARDEN_TRAINER, "settle": 45}), "host challenged the Warden"): return
	var record: Variant = await probe(0, "encounter")
	var encounter_id := str((record as Dictionary).get("id", "")) if record is Dictionary else ""
	for peer in range(1, PEERS):
		if not _pass(await step(peer, "join_encounter", {"encounter_id": encounter_id}), "guest %d joined the Warden's fight" % peer): return
	var count := 0
	for _poll in 30:
		var after_join: Variant = await probe(0, "encounter")
		count = ((after_join as Dictionary).get("participants", []) as Array).size() if after_join is Dictionary else 0
		if count == PEERS: break
		await step(0, "wait", {"frames": 10})
	check(count == PEERS, "the Warden's record holds all four participants (%d)" % count)
	var won: Dictionary = await step(0, "win_trainer_battle",
		{"budget_frames": BATTLE_FRAMES, "enemy_hp_ceiling": ENEMY_HP_CEILING, "self_hp_topups": false}, BATTLE_FRAMES + 900)
	if not _pass(won, "four peers felled the Warden"): return
	for peer in PEERS:
		await step(peer, "wait", {"frames": 120})
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 30})
	for peer in PEERS:
		await _want_paid(peer, "after the Warden")
	# A guest leaves and returns by its character: still exactly one each.
	if not _pass(await step(3, "leave", {}), "guest 3 left"): return
	if not _pass(await step(0, "expect_peers", {"count": PEERS - 1}), "host sees three peers"): return
	if not _pass(await step(3, "production_join", {"host": "127.0.0.1", "port": _port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _ids[3]}}, 15000), "guest 3 rejoined"): return
	await step(3, "wait", {"frames": 240})
	await _want_paid(3, "after guest 3's rejoin")
	_completed = true
	print("F48_FOUR_PEER_BOSS: four participants, one Warden, one key and one relic each")


func _want_paid(peer: int, label: String) -> void:
	var ok := false
	var heart: Dictionary = {}
	var keys := -1
	var relics: Array = []
	for _poll in POLLS:
		heart = await _heart(peer)
		keys = await _keys(peer)
		relics = await _relics_held(peer)
		if bool(heart.get("earned_in_world", false)) and keys == 1 and relics.count(RELIC) == 1:
			ok = true
			break
		await step(peer, "wait", {"frames": 10})
	check(ok, "%s: peer %d holds its own Tidewake key (x%d) and Meadows relic (%s); world Heart earned (%s)"
		% [label, peer, keys, str(relics), str(heart)])


func _pass(result: Dictionary, label: String) -> bool:
	var ok := str(result.get("verdict", "")) == "PASS"
	check(ok, "%s: %s" % [label, str(result.get("detail", ""))])
	return ok
