extends "res://tests/helpers/net_harness.gd"

# peers: 2

## REDESIGN (RD-10/RD-17/RD-21): after the Meadows the next chapter is
## TIDEWAKE, reached through the Crossing Hall's Tidewake arch (the old
## Meadows -> Cloudreach physical span is retired under the shipped config).
## The intent is unchanged: the SAME saved five enter the next chapter, for two
## peers in one session.
##
## Real host and guest processes (tools/net/run_net_smoke.sh). Each peer holds
## five creatures and saves its character. Then, before admission, each peer
## runs the DISCLOSED initial portal fixture (tools/net/portal_smoke_travel.gd
## prepare, regression "veridian_same_five": the player placed at the Hall's
## authored Tidewake Approach and grounded there by its own controller, the
## Tidewake arch open for the world -- standing in for the Warden's per-
## participant Tidewake key -- no earned credit, no permit, no ACK). After
## host/join each peer makes the real public portal request (host policy,
## permit, origin/arrival saves, host ACK). After the realm changes, each
## peer's party UIDs (`creature_instance.uid`, minted at random, so equal lists
## mean the same creatures, not look-alikes) are compared with the ones it held
## before: same five, same order, no sixth, nothing lost.
##
## Disclosed staging: the Warden fight is not played (smoke_net_veridian_choices
## and the F19 boss-delivery tests own it); the parties are granted with
## `party_grant`; the initial Hall placement/open route is the fixture above.

const FIVE := ["terrapup", "bramblebun", "trailpup", "mudsnout", "brooktail"]
const GUEST_NAME := "Same Five Guest"
const FIXTURE := "initial_hall_position_and_open_route_no_earned_credit"
const REGRESSION := "veridian_same_five"
## Tidewake's runtime realm id (biome_order.json runtime_aliases).
const TIDEWAKE := "water"
## Same production crossing budget the f15 dock proofs use for this arch.
const PORTAL_BUDGET := 10000

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
	var host_saved: Dictionary = await step(0, "save_character_here", {})
	var guest_saved: Dictionary = await step(1, "save_character_here", {})
	var host_id := str((host_saved.get("data", {}) as Dictionary).get("character_id", ""))
	var guest_id := str((guest_saved.get("data", {}) as Dictionary).get("character_id", ""))
	check(not host_id.is_empty() and not guest_id.is_empty() and host_id != guest_id,
		"two distinct stable characters (host '%s', guest '%s')" % [host_id, guest_id])

	# 2. DISCLOSED initial Hall fixture, before admission, on each peer.
	for peer in 2:
		var prepared: Dictionary = await step(peer, "enter_realm", {"realm": TIDEWAKE,
			"actual_portal_fixture": FIXTURE, "portal_regression": REGRESSION,
			"portal_prepare_only": true}, 3000)
		check(str(prepared.get("verdict", "")) == "PASS",
			"DISCLOSED FIXTURE: peer %d stands at the Hall's Tidewake arch with the route open (%s)"
				% [peer, str(prepared.get("detail", ""))])
		if str(prepared.get("verdict", "")) != "PASS":
			quit(await finish())
			return

	# 3. The session.
	var hosted: Dictionary = await step(0, "host", {"port": _port})
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 hosted (%s)" % str(hosted.get("detail", "")))
	var joined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": _port,
		 "character": {"character_id": guest_id, "display_name": GUEST_NAME}}, 6000)
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined (%s)" % str(joined.get("detail", "")))
	if str(hosted.get("verdict", "")) != "PASS" or str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# 4. Before the portal: each peer's five UIDs, in the Meadows.
	var before: Array = [[], []]
	for peer in 2:
		var who: Variant = await probe(peer, "player_identity")
		var realm := str((who as Dictionary).get("realm", "")) if who is Dictionary else ""
		check(realm == "meadows", "peer %d stands in the Meadows before the portal ('%s')" % [peer, realm])
		before[peer] = await _uids(peer)
		check((before[peer] as Array).size() == 5 and not (before[peer] as Array).has(""),
			"peer %d holds five creatures with UIDs before the portal: %s" % [peer, str(before[peer])])
	check(before[0] != before[1], "the two peers' parties are different creatures (distinct UIDs)")

	# 5. Each peer takes the Tidewake arch through the real public portal
	# request -- the guest first, as the old walk did (a client's crossing
	# needs the host's grant while the host still stands in the Meadows).
	for peer: int in [1, 0]:
		var entered: Dictionary = await step(peer, "enter_realm", {"realm": TIDEWAKE,
			"actual_portal_fixture": FIXTURE, "portal_regression": REGRESSION,
			"budget_frames": PORTAL_BUDGET}, PORTAL_BUDGET)
		check(str(entered.get("verdict", "")) == "PASS",
			"peer %d entered Tidewake through the Crossing Hall's Tidewake arch (%s)"
				% [peer, str(entered.get("detail", ""))])
		var who: Variant = await probe(peer, "player_identity")
		var realm := str((who as Dictionary).get("realm", "")) if who is Dictionary else ""
		check(realm == TIDEWAKE, "peer %d stands in Tidewake after the portal (realm '%s')" % [peer, realm])

	# 6. After: the same five, each peer.
	for peer in 2:
		var after := await _uids(peer)
		check(after == before[peer],
			"peer %d arrived in Tidewake with the SAME five (before %s, after %s)" % [peer, str(before[peer]), str(after)])
		check(after.size() == 5, "peer %d holds exactly five in Tidewake, no sixth (%d)" % [peer, after.size()])
		print("[same-five] peer %d UIDs before %s after %s" % [peer, str(before[peer]), str(after)])
	quit(await finish())


func _uids(peer: int) -> Array:
	var raw: Variant = await probe(peer, "tournament")
	if not raw is Dictionary:
		return []
	return ((raw as Dictionary).get("party_ids", []) as Array).duplicate()
