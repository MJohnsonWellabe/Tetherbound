extends "res://tests/helpers/net_harness.gd"

# peers: 2

## A GUEST beats a trainer on its own. The host journals the guest's reward.
##
##   tools/net/run_net_smoke.sh client_trainer_rewards
##
## `smoke_net_boss_rewards_each_participant.gd`'s trainer (Bryn), with the
## roles turned round: peer 1 -- the client -- challenges him through the
## production path and fights his whole team down; peer 0, the host, never
## fights and never joins. Before `trainer_victory`, a client's local win
## submitted only the world facts and paid itself, so the durable per-character
## reward journal the downstream legendary offer reads named nobody.
##
## What it asserts:
##   * the defeat is ONE world fact on both peers;
##   * the host's journal holds accepted `trainer:practice_trainer:*` rows for
##     exactly peer 1's stable character, and for no other character;
##   * peer 1's satchel gained the authored payout exactly once (the local
##     self-payment and the host delivery never both land), and peer 0 gained
##     nothing.

const TRAINER := "practice_trainer"
const AUTHORED_COINS := 20
const AUTHORED_POTIONS := 1
const COINS_SOURCE := "trainer:%s:coins" % TRAINER
const POTION_SOURCE := "trainer:%s:item:potion_small" % TRAINER


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session, "a Session exists to host/join")
	if not have_session:
		quit(await finish())
		return
	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])
	for i in 2:
		var out: Dictionary = await step(i, "deploy_creature", {})
		check(str(out.get("verdict", "")) == "PASS",
			"peer %d deployed its own creature (%s)" % [i, str(out.get("detail", ""))])

	var guest_character := await _guest_character()
	check(not guest_character.is_empty(), "the host's registry names peer 1's stable character")

	var before: Array = []
	for i in 2:
		before.append(await _reward_state(i))
		check(not bool((before[i] as Dictionary).get("beaten", true)), "peer %d has not beaten Bryn yet" % i)

	# --- the CLIENT takes the challenge and wins alone --------------------------
	var began: Dictionary = await step(1, "trainer_battle", {"trainer": TRAINER})
	check(str(began.get("verdict", "")) == "PASS", "peer 1 (client) challenged Bryn (%s)" % str(began.get("detail", "")))
	if str(began.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var host_during = await probe(0, "trainer_reward", {"trainer": TRAINER})
	check(not bool((host_during as Dictionary).get("battle_active", true)),
		"the host is not running a trainer battle of its own")
	var won: Dictionary = await step(1, "win_trainer_battle", {}, 6000)
	check(str(won.get("verdict", "")) == "PASS", "peer 1 beat Bryn's whole team (%s)" % str(won.get("detail", "")))
	if str(won.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var host_world: Dictionary = {}
	var guest_world: Dictionary = {}
	for _attempt in 120:
		host_world = await _world_snapshot(0)
		guest_world = await _world_snapshot(1)
		if _settled(host_world, guest_world, guest_character):
			break
		await process_frame
	for _settle in 60:
		await physics_frame
	var after: Array = []
	for i in 2:
		after.append(await _reward_state(i))

	# --- once for the world -----------------------------------------------------
	for i in 2:
		check(bool((after[i] as Dictionary).get("beaten", false)),
			"peer %d's world says Bryn has been beaten" % i)

	# --- the journal names exactly the fighter ----------------------------------
	var host_deliveries: Dictionary = host_world.get("reward_deliveries", {}) as Dictionary
	check((guest_world.get("reward_deliveries", {}) as Dictionary) == host_deliveries,
		"host and guest hold the same durable reward journal")
	for source: String in [COINS_SOURCE, POTION_SOURCE]:
		check(_characters(host_deliveries, source, true) == [guest_character],
			"'%s' has an accepted delivery for exactly peer 1's character %s (got %s)"
				% [source, guest_character, str(_characters(host_deliveries, source, true))])
		check(_characters(host_deliveries, source, false) == [guest_character],
			"'%s' journals no row for anybody else, accepted or pending (got %s)"
				% [source, str(_characters(host_deliveries, source, false))])

	# --- paid once, in full, to the fighter only ---------------------------------
	check(_gained(before[1], after[1], "coin") == AUTHORED_COINS,
		"peer 1 gained Bryn's authored %d coin exactly once (got %d)"
			% [AUTHORED_COINS, _gained(before[1], after[1], "coin")])
	check(_gained(before[1], after[1], "potion_small") == AUTHORED_POTIONS,
		"peer 1 gained the authored %d potion exactly once (got %d)"
			% [AUTHORED_POTIONS, _gained(before[1], after[1], "potion_small")])
	check(_gained(before[0], after[0], "coin") == 0,
		"peer 0, who never fought, gained no coin (got %d)" % _gained(before[0], after[0], "coin"))
	check(_gained(before[0], after[0], "potion_small") == 0,
		"peer 0 gained no potion (got %d)" % _gained(before[0], after[0], "potion_small"))
	quit(await finish())


func _guest_character() -> String:
	var guest = await probe(1, "session")
	var guest_id := int((guest as Dictionary).get("peer_id", 0)) if guest is Dictionary else 0
	var host = await probe(0, "session")
	if not host is Dictionary:
		return ""
	for raw: Variant in ((host as Dictionary).get("rows", []) as Array):
		if raw is Dictionary and int((raw as Dictionary).get("peer_id", 0)) == guest_id:
			return str((raw as Dictionary).get("character_id", ""))
	return ""


func _reward_state(peer: int) -> Dictionary:
	var value = await probe(peer, "trainer_reward",
		{"trainer": TRAINER, "sources": [COINS_SOURCE, POTION_SOURCE],
		 "items": ["coin", "potion_small"]})
	return value if value is Dictionary else {}


func _world_snapshot(peer: int) -> Dictionary:
	var value = await probe(peer, "world_snapshot")
	return value if value is Dictionary else {}


func _settled(host_world: Dictionary, guest_world: Dictionary, character: String) -> bool:
	var host_deliveries: Dictionary = host_world.get("reward_deliveries", {}) as Dictionary
	if host_deliveries != (guest_world.get("reward_deliveries", {}) as Dictionary):
		return false
	for source: String in [COINS_SOURCE, POTION_SOURCE]:
		if not _characters(host_deliveries, source, true).has(character):
			return false
	return true


func _characters(deliveries: Dictionary, source: String, accepted_only: bool) -> Array[String]:
	var out: Array[String] = []
	for raw: Variant in deliveries.values():
		if raw is not Dictionary:
			continue
		var row := raw as Dictionary
		if str(row.get("source", "")) != source:
			continue
		if accepted_only and str(row.get("status", "")) != "accepted":
			continue
		var character := str(row.get("character_id", ""))
		if not character.is_empty() and not out.has(character):
			out.append(character)
	out.sort()
	return out


func _gained(before: Variant, after: Variant, item: String) -> int:
	var was := int(((before as Dictionary).get("satchel", {}) as Dictionary).get(item, 0))
	var now := int(((after as Dictionary).get("satchel", {}) as Dictionary).get(item, 0))
	return now - was
