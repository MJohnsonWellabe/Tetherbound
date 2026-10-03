extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Two actual network peers retain the SAME five when entering Cloudreach.
## WORLD/RD-17 and F18 replace the historical F05 physical crossing with the
## Crossing Hall portal; the retired far trigger is no longer an entry source.
##
## Real host and guest processes (tools/net/run_net_smoke.sh). Each peer holds
## five creatures; the host commits the Warden's world facts through the story
## ledger (`defeated_warden`, `legendary_freed`, `realm_key_cloudreach` -- all
## world-scope). Each peer uses the actual authored Hall arch request, owner
## BOOL-save, consumed host permit and saved grounded arrival ACK. Afterward,
## each peer's party UIDs (`creature_instance.uid`, minted at random, so equal
## lists mean the same creatures, not look-alikes) are compared with the ones it
## held before entry: same five, same order, no sixth, nothing lost.
##
## Disclosed staging: the fight itself is not played (smoke_net_veridian_choices
## plays it); parties are granted before initial Hall placement and opening the
## canonical route, then saved before host/join admission. These initial
## mechanics fixtures claim no earned chapter credit. No admitted owner pose or
## party is changed to obtain a portal permit. The original 6000-frame crossing
## budget includes initial placement cost and the actual saved transition.

const FIVE := ["terrapup", "bramblebun", "trailpup", "mudsnout", "brooktail"]
const WORLD_FACTS := ["defeated_warden", "legendary_freed", "realm_key_cloudreach"]
const GUEST_NAME := "Same Five Guest"
const PORTAL_FIXTURE := "initial_hall_position_and_open_route_no_earned_credit"
const SPAN_WAIT_FRAMES := 1200

var _port := 0


func _init_budgets() -> void:
	super._init_budgets()
	_budgets["smoke_step_budget_s_2peer"] = 1500.0
	_budgets["hello_budget_s"] = 360.0


func _initialize() -> void:
	_run()


func _run() -> void:
	# Both peers change realm after hello, and the host stands a Meadows shell
	# up (then folds it) when the guest leaves -- a blocking scene build, the
	# same ~85 s single frame smoke_net_join_by_address.gd allows for. The
	# peer is working, not hung; the other scene-changing smokes use 240 s.
	heartbeat_silence_tolerance_s = 240.0
	if not await launch(2, "world"):
		quit(await finish())
		return
	# Retired physical-route regression only; shipping redesign crossings stay off.
	for peer in 2:
		var legacy: Dictionary = await step(peer, "legacy_physical_crossings_fixture", {"regression": "veridian_same_five"})
		check(str(legacy.get("verdict", "")) == "PASS", "disclosed retired-path fixture enabled in peer %d" % peer)
		if str(legacy.get("verdict", "")) != "PASS":
			quit(await finish())
			return
	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	_port = int(host_hello.get("enet_port", 0))
	check(_port > 0, "host reported its ENet port in hello (%d)" % _port)
	if _port <= 0:
		quit(await finish())
		return

	# 1. Two saved characters, five creatures each.
	for peer in 2:
		for species: String in FIVE:
			var granted: Dictionary = await step(peer, "party_grant", {"species": species, "level": 18})
			check(str(granted.get("verdict", "")) == "PASS",
				"FIXTURE: peer %d received a level-18 %s" % [peer, species])
	for peer in 2:
		var prepared: Dictionary = await step(peer, "enter_realm", {"realm": "cloudreach",
			"actual_portal_fixture": PORTAL_FIXTURE, "portal_regression": "veridian_same_five", "portal_prepare_only": true})
		check(prepared.get("verdict") == "PASS", "Disclosed initial Hall placement/open canonical route after five-party fixture and before save/admission")
		if prepared.get("verdict") != "PASS":
			quit(await finish())
			return
	var host_saved: Dictionary = await step(0, "save_character_here", {})
	var guest_saved: Dictionary = await step(1, "save_character_here", {})
	var host_id := str((host_saved.get("data", {}) as Dictionary).get("character_id", ""))
	var guest_id := str((guest_saved.get("data", {}) as Dictionary).get("character_id", ""))
	check(not host_id.is_empty() and not guest_id.is_empty() and host_id != guest_id,
		"two distinct stable characters (host '%s', guest '%s')" % [host_id, guest_id])

	# 2. The session.
	var hosted: Dictionary = await step(0, "host", {"port": _port})
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 hosted (%s)" % str(hosted.get("detail", "")))
	var joined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": _port,
		 "character": {"character_id": guest_id, "display_name": GUEST_NAME}}, 6000)
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined (%s)" % str(joined.get("detail", "")))
	if str(hosted.get("verdict", "")) != "PASS" or str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# 3. The Warden's world facts, committed once by the host; both see them.
	for flag: String in WORLD_FACTS:
		var committed: Dictionary = await step(0, "story_flag", {"flag": flag, "scope": "world"})
		check(str(committed.get("verdict", "")) == "PASS", "world fact '%s' committed (%s)" % [flag, str(committed.get("detail", ""))])
	for peer in 2:
		for flag: String in WORLD_FACTS:
			var seen: Dictionary = await step(peer, "wait_flag", {"flag": flag}, 1800)
			check(str(seen.get("verdict", "")) == "PASS", "peer %d sees '%s' (%s)" % [peer, flag, str(seen.get("detail", ""))])
		# The rift collapses and the span appears (hold + dissipate + appear).
		await step(peer, "wait", {"frames": SPAN_WAIT_FRAMES})

	# 4. Before entry: each peer's five UIDs, in the Meadows.
	var before: Array = [[], []]
	for peer in 2:
		var who: Variant = await probe(peer, "player_identity")
		var realm := str((who as Dictionary).get("realm", "")) if who is Dictionary else ""
		check(realm == "meadows", "peer %d stands in the Meadows before portal entry ('%s')" % [peer, realm])
		before[peer] = await _uids(peer)
		check((before[peer] as Array).size() == 5 and not (before[peer] as Array).has(""),
			"peer %d holds five creatures with UIDs before portal entry: %s" % [peer, str(before[peer])])
	check(before[0] != before[1], "the two peers' parties are different creatures (distinct UIDs)")

	# 5. The guest enters first while the host owns the destination shell.
	# The helper uses only the actual public arch transaction after admission.
	for peer: int in [1, 0]:
		var entered: Dictionary = await step(peer, "enter_realm", {"realm": "cloudreach",
			"actual_portal_fixture": PORTAL_FIXTURE, "portal_regression": "veridian_same_five"}, 6000)
		check(entered.get("verdict") == "PASS", "peer %d completed actual Hall portal owner-save/permit/grounded arrival (%s)" % [peer, str(entered.get("detail", ""))])
		if entered.get("verdict") != "PASS":
			quit(await finish())
			return
		var who: Variant = await probe(peer, "player_identity")
		var realm: String = str((who as Dictionary).get("realm", "")) if who is Dictionary else ""
		check(realm == "cloudreach", "peer %d entered Cloudreach through its actual Hall portal (realm '%s')" % [peer, realm])

	# 6. After: the same five, each peer.
	for peer in 2:
		var after := await _uids(peer)
		check(after == before[peer],
			"peer %d arrived in Cloudreach with the SAME five (before %s, after %s)" % [peer, str(before[peer]), str(after)])
		check(after.size() == 5, "peer %d holds exactly five in Cloudreach, no sixth (%d)" % [peer, after.size()])
		print("[same-five] peer %d UIDs before %s after %s" % [peer, str(before[peer]), str(after)])
	quit(await finish())


func _uids(peer: int) -> Array:
	var raw: Variant = await probe(peer, "tournament")
	if not raw is Dictionary:
		return []
	return ((raw as Dictionary).get("party_ids", []) as Array).duplicate()
