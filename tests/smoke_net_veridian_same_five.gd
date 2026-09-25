extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F05 (ACCEPTANCE §6.1, card M4): "the gate opens ... and the SAME five enter
## Cloudreach through the physical crossing", for two peers in one session.
##
## Real host and guest processes (tools/net/run_net_smoke.sh). Each peer holds
## five creatures; the host commits the Warden's world facts through the story
## ledger (`defeated_warden`, `legendary_freed`, `realm_key_cloudreach` -- all
## world-scope), so the rift collapses and the span appears on BOTH peers. Each
## peer then WALKS (peer_runner `move_to`: the navigator drives the player's own
## movement input, no teleport) from the storm road onto the span and on into
## the far trigger, whose `body_entered` is the only caller of
## `Game.enter_realm("cloudreach", ...)` on this path. After the realm changes,
## each peer's party UIDs (`creature_instance.uid`, minted at random, so equal
## lists mean the same creatures, not look-alikes) are compared with the ones it
## held before the walk: same five, same order, no sixth, nothing lost.
##
## Disclosed staging: the fight itself is not played (smoke_net_veridian_choices
## plays it); the parties are granted with `party_grant`; each peer is placed on
## the storm road 20 m short of the span with `teleport`, then walks. The span's
## coordinates are the production scene's own (RiftCrossing near/far anchors and
## trigger, read from the built scene; see NEAR/FAR/TRIGGER), and the proof that
## the walk went THROUGH the trigger is the realm change it alone causes.

const FIVE := ["terrapup", "bramblebun", "trailpup", "mudsnout", "brooktail"]
const WORLD_FACTS := ["defeated_warden", "legendary_freed", "realm_key_cloudreach"]
const GUEST_NAME := "Same Five Guest"
## RiftCrossing on meadows_playground (headless build, flags set): near anchor
## (-33.38, 7523.14), far anchor (-34.78, 7548.10), trigger (-35.34, 7558.09).
const NEAR := Vector2(-33.38, 7523.14)
const FAR := Vector2(-34.78, 7548.10)
const TRIGGER := Vector2(-35.34, 7558.09)
## 20 m back down the span's own axis from the near anchor.
const ROAD := Vector2(-32.26, 7503.17)
const SPAN_WAIT_FRAMES := 1200
const REALM_POLLS := 60

var _port := 0


func _init_budgets() -> void:
	super._init_budgets()
	_budgets["smoke_step_budget_s_2peer"] = 1500.0
	_budgets["hello_budget_s"] = 360.0


func _initialize() -> void:
	_run()


func _run() -> void:
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

	# 4. Before the walk: each peer's five UIDs, in the Meadows.
	var before: Array = [[], []]
	for peer in 2:
		var who: Variant = await probe(peer, "player_identity")
		var realm := str((who as Dictionary).get("realm", "")) if who is Dictionary else ""
		check(realm == "meadows", "peer %d stands in the Meadows before the walk ('%s')" % [peer, realm])
		before[peer] = await _uids(peer)
		check((before[peer] as Array).size() == 5 and not (before[peer] as Array).has(""),
			"peer %d holds five creatures with UIDs before the walk: %s" % [peer, str(before[peer])])
	check(before[0] != before[1], "the two peers' parties are different creatures (distinct UIDs)")

	# 5. Each peer walks over the span into the far trigger.
	for peer in 2:
		await step(peer, "teleport", {"at": [ROAD.x, 2.0, ROAD.y], "settle": 60})
		var leg1: Dictionary = await step(peer, "move_to", {"x": NEAR.x, "z": NEAR.y, "close_enough": 1.5, "budget_frames": 1800})
		check(str(leg1.get("verdict", "")) == "PASS", "peer %d walked the storm road onto the span (%s)" % [peer, str(leg1.get("detail", ""))])
		var leg2: Dictionary = await step(peer, "move_to", {"x": FAR.x, "z": FAR.y, "close_enough": 1.5, "budget_frames": 1800})
		check(str(leg2.get("verdict", "")) == "PASS", "peer %d walked the span to the far rim (%s)" % [peer, str(leg2.get("detail", ""))])
		# Into the trigger: the scene changes under this step, so its own
		# verdict is not the proof; the realm below is.
		await step(peer, "move_to", {"x": TRIGGER.x, "z": TRIGGER.y, "close_enough": 0.5, "budget_frames": 900})
		var realm := ""
		for i in REALM_POLLS:
			var who: Variant = await probe(peer, "player_identity")
			realm = str((who as Dictionary).get("realm", "")) if who is Dictionary else ""
			if realm == "cloudreach":
				break
			await step(peer, "wait", {"frames": 30})
		check(realm == "cloudreach", "peer %d entered Cloudreach through the far trigger (realm '%s')" % [peer, realm])

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
