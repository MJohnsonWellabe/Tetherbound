extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 4 lane 4.D. TWO PEOPLE BEAT ONE TRAINER. BOTH GET PAID.
##
##   tools/net/run_net_smoke.sh boss_rewards_each_participant
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §7, as a thing two real processes do:
##
##     **The world fact happens once. The personal reward happens per
##     participant.**
##
## ## What it asserts, and why each half needs the other
##
## Peer 0 challenges Bryn through the production path (`begin_trainer_battle()`,
## the same call `trainer_npc.gd` makes when a player presses the challenge
## prompt). Peer 1 joins that fight already in progress (§6). Peer 0 then fights
## Bryn's whole team down with real `strike_intent` submissions, so the host
## arbitrates every blow. Then:
##
##   * **once for the world** -- Bryn's `defeat_flag` is set on BOTH peers, and
##     peer 1 never fought a trainer battle of its own: it has no
##     `_trainer_spec`, it never called `_record_trainer_defeat()`, and the flag
##     it holds afterwards can only have arrived as the host's one committed
##     delta. Afterwards NEITHER peer can challenge him again, which is §7's own
##     sentence -- a second peer arriving later finds the trainer already
##     beaten, because that is what the world says.
##   * **once per participant** -- the receipt
##     `reward:trainer:practice_trainer:coins:<peer>` exists for BOTH peer ids,
##     which is the ledger's own record that the payout was made twice, to two
##     different people, rather than once for the fight.
##   * **in full, not divided** -- peer 1's satchel gains Bryn's AUTHORED 20
##     coin and 1 potion, measured as a before/after delta rather than as an
##     absolute, and so does peer 0's. §7: a fight that pays half as much for
##     having a friend along teaches people to play alone. This is the
##     assertion that fails if anybody ever "shares" a payout.
##
## The three are asserted separately on purpose. A payout that reached only the
## winner passes the world half; a world flag written twice, once per peer,
## passes the personal half; a payout that halved every amount passes both. Only
## all three together are the deliverable.
##
## ## What this smoke deliberately does NOT assert
##
## **XP.** Bryn pays no `xp_bonus` -- most of the table does not -- so there is
## no flat bonus here to divide or not divide, and asserting on the per-creature
## XP the fight already paid would be asserting on who landed the last blow.
## The claim "XP is not divided by participant count" is arithmetic and is
## proved where arithmetic belongs: `tests/test_encounter_rewards.gd`, whose
## `test_xp_is_not_divided_by_participant_count` runs it at one, two and four
## participants.
##
## **A joiner's own view of the trainer's creature.** Until wild replication
## lands (4.B's H1, restated by 4.C's F1) a joiner's opponent BODY is a local
## stand-in. Everything that decides an outcome -- and everything asserted here
## -- comes off the host's record and the world ledger, never off that body.

## Bryn. `smoke_trainer_battle.gd`'s trainer, for its reason: he is the one
## standalone trainer placed by `trainer_npc.gd`'s own system, and his team of
## two is short enough to fight down twice in a net smoke's step budget.
const TRAINER := "practice_trainer"
const DEFEAT_FLAG := "trainer_defeated_practice"
## What `data/config/bands/band1_lower_meadows/trainers.json` says Bryn owes.
## Constants here rather than read from the table, so a designer retuning the
## reward turns this into a legible one-line failure instead of a smoke that
## silently asserts whatever the file happens to say.
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

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
	check(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var ctx = await probe(i, "input_context")
		check(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session, "a Session exists to host/join (lane 2.A)")
	if not have_session:
		quit(await finish())
		return

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
	# --- end of the handshake block -------------------------------------------

	for i in 2:
		var out: Dictionary = await step(i, "deploy_creature", {})
		check(str(out.get("verdict", "")) == "PASS",
			"peer %d deployed its own creature (%s)" % [i, str(out.get("detail", ""))])

	# What each peer owns BEFORE anybody fights. Every payout assertion below is
	# a delta against this, never an absolute: the opening hands out a starting
	# satchel and an absolute would be asserting on that instead.
	var before: Array = []
	for i in 2:
		before.append(await _reward_state(i))
	check((before[0] as Dictionary).size() > 0 and (before[1] as Dictionary).size() > 0,
		"both peers answered the reward probe before the fight")
	for i in 2:
		check(not bool((before[i] as Dictionary).get("beaten", true)),
			"peer %d has not beaten Bryn yet" % i)
		check(bool((before[i] as Dictionary).get("can_challenge", false)),
			"peer %d could challenge Bryn right now" % i)

	# --- peer 0 takes the challenge -------------------------------------------
	var began: Dictionary = await step(0, "trainer_battle", {"trainer": TRAINER})
	check(str(began.get("verdict", "")) == "PASS",
		"peer 0 challenged Bryn (%s)" % str(began.get("detail", "")))
	if str(began.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var record = await probe(0, "encounter")
	var rec: Dictionary = record if record is Dictionary else {}
	var encounter_id := str(rec.get("id", ""))
	check(not encounter_id.is_empty(), "the host minted an encounter record for the battle")
	check(str(rec.get("kind", "")) == "trainer",
		"and it is a TRAINER encounter, not a wild one (got '%s')" % str(rec.get("kind", "")))
	check(str(rec.get("realm", "")) == "meadows",
		"stamped with an explicit realm (D97), got '%s'" % str(rec.get("realm", "")))

	# --- peer 1 joins the fight already in progress (§6) -----------------------
	var where: Array = rec.get("opponent_pos", []) as Array
	if where.size() == 3:
		var walked: Dictionary = await step(1, "teleport",
			{"at": [float(where[0]) + 3.0, float(where[1]), float(where[2]) + 3.0]})
		check(str(walked.get("verdict", "")) == "PASS",
			"peer 1 travelled to the fight (%s)" % str(walked.get("detail", "")))
	var joined_fight: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(joined_fight.get("verdict", "")) == "PASS",
		"peer 1 joined the trainer battle already in progress (%s)"
			% str(joined_fight.get("detail", "")))

	var during = await probe(0, "encounter")
	var live: Dictionary = during if during is Dictionary else {}
	check((live.get("participants", []) as Array).size() == 2,
		"the host's record now holds 2 participants (got %d)"
			% (live.get("participants", []) as Array).size())
	check(str(live.get("phase", "")) == "active",
		"joining did not change the phase (got '%s')" % str(live.get("phase", "")))

	var guest_during = await probe(1, "trainer_reward")
	check(not bool((guest_during as Dictionary).get("battle_active", true)),
		"peer 1 is in the FIGHT but is not running a trainer battle of its own -- "
		+ "so any defeat flag it ends up holding can only have come from the host")

	# --- and peer 0 fights Bryn's team down ------------------------------------
	var won: Dictionary = await step(0, "win_trainer_battle", {}, 6000)
	check(str(won.get("verdict", "")) == "PASS",
		"peer 0 beat Bryn's whole team (%s)" % str(won.get("detail", "")))
	if str(won.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var after: Array = []
	for i in 2:
		after.append(await _reward_state(i))

	# --- ONCE for the world ----------------------------------------------------
	for i in 2:
		check(bool((after[i] as Dictionary).get("beaten", false)),
			"peer %d's world says Bryn has been beaten ('%s')" % [i, DEFEAT_FLAG])
		check(not bool((after[i] as Dictionary).get("can_challenge", true)),
			"and peer %d is offered a greeting rather than a second battle" % i)

	# --- ONCE PER PARTICIPANT --------------------------------------------------
	var peers: Array = (after[0] as Dictionary).get("session_peers", []) as Array
	check(peers.size() == 2, "the host knows about 2 peers to pay (got %d)" % peers.size())
	for source: String in [COINS_SOURCE, POTION_SOURCE]:
		var receipts: Dictionary = ((after[0] as Dictionary).get("receipts", {})
			as Dictionary).get(source, {}) as Dictionary
		check(receipts.size() == 2,
			"the ledger holds a '%s' receipt slot for each peer (got %d)"
				% [source, receipts.size()])
		var paid := 0
		for key: Variant in receipts.keys():
			if bool(receipts[key]):
				paid += 1
		check(paid == 2,
			"'%s' was paid to BOTH participants, once each (got %d of 2): %s"
				% [source, paid, str(receipts)])

	# --- IN FULL, not divided --------------------------------------------------
	for i in 2:
		var gained_coin := _gained(before[i], after[i], "coin")
		check(gained_coin == AUTHORED_COINS,
			"peer %d gained Bryn's authored %d coin, not a share of it (got %d)"
				% [i, AUTHORED_COINS, gained_coin])
		var gained_potion := _gained(before[i], after[i], "potion_small")
		check(gained_potion == AUTHORED_POTIONS,
			"peer %d gained the authored %d potion, not a share of it (got %d)"
				% [i, AUTHORED_POTIONS, gained_potion])

	quit(await finish())


func _reward_state(peer: int) -> Dictionary:
	var value = await probe(peer, "trainer_reward",
		{"trainer": TRAINER, "sources": [COINS_SOURCE, POTION_SOURCE],
		 "items": ["coin", "potion_small"]})
	return value if value is Dictionary else {}


## What this peer's satchel gained. A DELTA, never an absolute -- the opening
## hands out a starting satchel and every peer's differs.
func _gained(before: Variant, after: Variant, item: String) -> int:
	var was := int(((before as Dictionary).get("satchel", {}) as Dictionary).get(item, 0))
	var now := int(((after as Dictionary).get("satchel", {}) as Dictionary).get(item, 0))
	return now - was
