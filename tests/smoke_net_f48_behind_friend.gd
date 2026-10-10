extends "res://tests/smoke_net_f18_travel.gd"

# peers: 2
## F48#3: a behind friend follows the host through an unlocked portal, and
## their own progress stays honest.
##
##   tools/net/run_net_smoke.sh f48_behind_friend
##
## The host spends a Tidewake key at the Hall arch, opening it for its world.
## A guest with no key and no Tidewake progress uses that open arch with the
## ordinary controller prompt and arrives in Tidewake. The guest's own record
## gains no unlock, receipt or key, live or on disk, and once it leaves the
## host's world its personal Tidewake arch is still shut.
## Disclosed fixtures (f18_net_peer): one starter and free-play story flags per
## peer, one HomeKey per peer and the host's one Tidewake key. Everything after
## setup is the real walk/Satchel/arch path with portable save/ACK journals.

func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"],
		"F48 behind-friend peer logs have no script errors")
	if not await launch(2, "title", [], {1: ["--joiner"]}):
		quit(await finish())
		return
	for peer in 2:
		if not await _f18_pass(peer, "f18_boot_world", {}, 12000): return
	# The host carries the key; the guest is the friend who is behind.
	if not await _f18_pass(0, "f18_fixture", {"key": true}): return
	if not await _f18_pass(1, "f18_fixture", {"guest": true, "key": false}): return
	var port := int(_peers[0].hello.enet_port)
	if not await _f18_pass(0, "host", {"port": port}): return
	var guest_id := str((await _f18_observe(1)).get("character_id", ""))
	check(not guest_id.is_empty(), "the behind guest has a portable identity")
	if not await _f18_pass(1, "production_join", {"port": port, "returning_route": true,
			"character": {"character_id": guest_id}}, 12000): return
	for peer in 2:
		if not await _f18_pass(peer, "expect_peers", {"count": 2}): return
	var before := await _f18_observe(1)
	check(before.get("tidewake_key_count") == 0 and not before.get("character", {}).get("portal_unlocks", []).has("tidewake"),
		"the guest starts without a Tidewake key or unlock")
	# The host opens Tidewake for its world with its own key.
	if not await _f18_pass(0, "f18_home_key", {}, 12000): return
	var unlocked := await _f18_action(0, "f18_arch", {"arch": "tidewake", "mode": "unlock"})
	if unlocked.is_empty(): return
	var opened := await _f18_observe(0, guest_id)
	check(opened.get("world", {}).get("portal_unlocks", []).has("tidewake")
		and opened.get("world_disk", {}).get("redesign_world", {}).get("portal_unlocks", []).has("tidewake"),
		"the host's key opens Tidewake for its world, live and on disk")
	check(not opened.get("admitted", {}).get("redesign_character", {}).get("portal_unlocks", []).has("tidewake"),
		"the host's unlock is not written into the guest's admitted record")
	# The behind guest follows through the open arch.
	if not await _f18_pass(1, "f18_home_key", {}, 12000): return
	var guest_hall := await _f18_observe(1)
	check(guest_hall.get("tidewake_view", {}).get("open") == true
		and guest_hall.get("tidewake_view", {}).get("world_open") == true
		and guest_hall.get("tidewake_view", {}).get("character_open") == false,
		"the guest sees the arch open through the host's world only (%s)" % str(guest_hall.get("tidewake_view")))
	if not await _f18_pass(1, "f18_arch", {"arch": "tidewake", "mode": "enter", "realm": "water"}, 15000): return
	var travelled := await _f18_observe(0, guest_id)
	var arrived := false
	for row: Variant in travelled.get("deliveries", {}).values():
		if row is Dictionary and row.get("character_id") == guest_id and row.get("status") == "accepted" \
				and row.get("action", row.get("kind", "")) == "portal_arrival" \
				and str(row.get("intent", {}).get("entry_id", "")).begins_with("water"):
			arrived = true
	check(arrived, "the behind guest's Tidewake arrival is an accepted host journal")
	var after := await _f18_observe(1)
	check(after.get("tidewake_key_count") == 0
		and not after.get("character", {}).get("portal_unlocks", []).has("tidewake")
		and not travelled.get("admitted", {}).get("redesign_character", {}).get("portal_unlocks", []).has("tidewake"),
		"following through the arch gives the guest no key or personal unlock")
	var settled: Dictionary = await _f18_action(1, "f18_settled", {}, 3000)
	if settled.is_empty(): return
	if not await _f18_pass(1, "save_character_here", {}): return
	var saved := await _f18_observe(1)
	check(not saved.get("character_disk", {}).get("redesign_character", {}).get("portal_unlocks", []).has("tidewake"),
		"the guest's saved character holds no Tidewake unlock")
	# Away from the host's world the guest's own arch stays shut.
	if not await _f18_pass(1, "leave", {}): return
	if not await _f18_pass(0, "expect_peers", {"count": 1}): return
	var alone := await _f18_observe(1)
	check(alone.get("tidewake_view", {}).get("character_open") == false
		and alone.get("tidewake_key_count") == 0,
		"after leaving, the guest's personal Tidewake arch is still locked (%s)" % str(alone.get("tidewake_view")))
	print("F48_BEHIND_FRIEND: host-opened Tidewake arch crossed by a key-less guest; no personal unlock or key gained")
	quit(await finish())
