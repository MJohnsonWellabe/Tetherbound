extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B row 8. **§17 ITEM 8: A BOSS ENCOUNTER TOGETHER.**
##
##   tools/net/run_net_smoke.sh shared_boss
##
## Two real processes, both piloting a creature, in the Warden's own fight.
##
## ## Why this file exists at all, given row 7
##
## `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` carried row 8 as **owed** with
## its reason written out: the multi-participant payout path is the one row 7
## already proves, `smoke_boss` / `smoke_gate_e_finale` / `smoke_cloudreach_finale`
## are green solo, and "the payout path is shared" is **an argument, not
## evidence**. So this file deliberately asserts nothing row 7 asserts. There is
## no coin here, no potion, no per-participant receipt for an item, and no
## `_gained()` delta. Row 7 owns that claim and keeps it.
##
## What a BOSS is different about, and what is therefore asserted here:
##
##   1. **ONE record, not two fights.** Peer 0 challenges; peer 1 joins that
##      `encounter_id` (§6). Peer 1's own `trainer_battle_active` stays FALSE
##      and its `trainer_battle_id` stays empty -- it is in the fight without
##      running one -- while its `bound_id` is peer 0's record id. Two peers
##      each running their own Warden battle would satisfy "both fought the
##      boss" and is exactly the failure this asserts against.
##   2. **The boss's HP is host truth** (§5, §3: "the `hp` on this record is
##      THE hit points"). Both peers swing; the SAME number falls; both peers
##      read it equal to the thousandth.
##   3. **Scaling is composition-first and NEVER HP x players** (§10 / D-MP12).
##      The assertion with teeth, and the one no existing smoke makes: at two
##      participants the Warden's creature carries its AUTHORED `max_hp`
##      untouched, while its `attack` and `defence` carry the multiplier
##      `data/config/multiplayer.json` configures. See the block below.
##   4. **The world fact happens once.** The climax's own three flags --
##      `defeated_warden`, and the two the Warden's `reward.flags` names --
##      land on BOTH peers with NO per-participant receipt, because D99 scopes
##      all three to the WORLD and `encounter_rewards.gd::world_facts()`
##      commits them once for it. A flag paid per participant would carry a
##      `reward:...:<peer>` receipt for each, and this asserts there is none.
##   5. **Friendly fire between the two pilots is refused** (§5), in the boss
##      fight and not only in a wild one, with the refusal sentence and the
##      untouched teammate asserted separately.
##
## ## The scaling assertion, and why it is shaped this way
##
## §10's forbidden knob is HP x players. `multiplayer.json` records that there
## is deliberately no hp key and none a future edit could use as one. That is a
## comment; this is the test that makes it cost something.
##
## Three numbers, from three places, compared:
##
##   * **authored** -- the Warden's team entry rebuilt through the production
##     `trainer_npc.gd::creature_for()`, UNSCALED. It is fully deterministic
##     (`creature_instance.gd::from_species` rolls no level, no IV and no
##     trait), so it is the same authored source the fight itself read;
##   * **live** -- the creature actually on the field, after
##     `encounter_director.gd::_scale_opponent_for_the_session()`;
##   * **configured** -- `by_participants["2"]`, read by this file straight out
##     of `data/config/multiplayer.json`, not through the code that applies it.
##     A code/config divergence fails here rather than agreeing with itself.
##
## Then: `live.max_hp == authored.max_hp` exactly, `live.attack ==
## authored.attack * configured`, same for defence, and the configured row for
## two players names ONLY `stat_multiplier` and `attack_cooldown_multiplier`.
## Add an `hp_multiplier` to that row and apply it and the first fails; add the
## key without applying it and the last fails. Fold hp into the stat multiplier
## and the first fails.
##
## **The multiplier is asserted to be greater than 1.0 first.** At 1.0 the
## attack and defence comparisons are `authored == authored` -- true over no
## scaling at all -- and the HP assertion would pass a build that scaled nothing
## and a build that scaled everything. That check is the one that keeps the
## other three honest.
##
## The scaling reads happen BEFORE the fight is finished, for a mechanical
## reason: winning it uses `win_trainer_battle`'s `enemy_hp_ceiling` allowance,
## which pulls the opponent's `hp` down. It never touches `max_hp`, `attack` or
## `defence` -- the three this asserts on -- but reading them afterwards would
## invite the next reader to assume it might.
##
## ### FINDING F1, CLOSED: the stat multiplier and the cooldown now reach the
## ### creature, and this file asserts it
##
## This file used to PRINT the other two thirds of §10 -- the modest stat
## multiplier and the shorter attack cooldown -- and deliberately assert no
## direction on them, because on the tree row 8 shipped against they reached
## nothing at all in any trainer or boss battle:
##
##   * `encounter_director.gd::_scale_opponent_for_the_session()` was called from
##     exactly one place -- `_send_out_next_creature()`, immediately after the
##     creature was popped off the trainer's queue and BEFORE `_start_fight()`
##     opened or resumed the record it reads its multiplier off;
##   * so the FIRST creature found no record and returned on `_encounter` being
##     empty, and every creature after it found the participant list §9 empties
##     at each round boundary -- re-stamped through `scaling_for(0)`, the
##     identity -- and returned on the scaler's own `is_equal_approx` guard.
##
## Measured on the Warden, twice: his opening burrowback carried attack 27.750 /
## defence 42.550 and his galecrest 51.800 / 27.750, each exactly its authored
## number, while the record beside them said `stat_multiplier` 1.1. Nothing had
## caught it because the only tests of §10 -- `test_encounter_rewards.gd`'s
## scaling block -- test `scaling_for()` and `host.scaling()`, the TABLE and the
## RECORD, and no test had ever asserted that the multiplier reaches a creature.
##
## Lane MP-F1-F2 fixed it (D100: the scaling call moved to after the record is
## live, and an UNSCALED BASE is kept on the director so a row that is re-derived
## on every join, leave and landed strike cannot compound). The assertions below
## are now the direction they refused to take: at two participants the live
## creature's attack and defence are its authored numbers times
## `stat_multiplier`, and the BODY's own combat config -- the number the swing
## timer reads, not the one sitting on the instance -- is its authored cooldown
## times `attack_cooldown_multiplier`. `tests/smoke_encounter_scaling.gd` is the
## same claim driven over three rounds, three participant counts and a leave in
## one process; this file is the half of it that runs over a real ENet link
## against the real `session.gd`.
##
## ### Why the HP reads happen on the boss's SECOND creature
##
## Two assertions, at the two moments a `hp x players` edit could fire:
##
##   * when the second player ARRIVES, against the creature already on the field
##     -- the record's row moves to the two-player one on that same line, so this
##     is the first place added health would show;
##   * when the next creature is SENT OUT with two participants already in the
##     fight -- the send-out path, which is where a future edit would most
##     naturally be made.
##
## The second creature also gives the print above a real cooldown to report
## against: the galecrest authors `attack_cooldown` 0.9 and the opening burrowback
## authors none (finding F3), so a measurement taken on the opener would compare
## 0.0 to 0.0 and say nothing.
##
## ## Which fight this proves, stated plainly
##
## **The Warden's own row**, `warden_aldis`: rank `warden`, the only entry in
## `trainers.json`'s `boss_ranks`, five creatures at levels 18/18/19/19/20, and
## the encounter record therefore stamped `kind: "boss"` by
## `encounter_director.gd:2941`. It is driven through `begin_trainer_battle()`,
## which is the same call `stronghold_climax.gd` makes and the same call
## `smoke_boss.gd` drives -- `data/config/stronghold_climax.json` says it in its
## own words: "There is no boss combat mode and there is no boss script."
##
## What this does NOT prove, and the report says so too: the WALK. The Warden
## Arena, its dialogue, the machine gate behind him and the legendary chamber
## are `smoke_boss.gd`'s ground and stay solo. Row 8 is about two pilots in the
## fight, and the fight is the Warden's.

## The Warden. Constants rather than reads of the table, on row 7's precedent:
## a designer who retunes him turns this into a legible one-line failure instead
## of a smoke that silently asserts whatever the file happens to say.
const BOSS := "warden_aldis"
const BOSS_RANK := "warden"
const AUTHORED_TEAM_SIZE := 5
const DEFEAT_FLAG := "defeated_warden"
## The Warden's `reward.flags`. D99 scopes both to the WORLD
## (`data/progression/flag_scopes.json`), which is why they are asserted as
## world facts committed once and never as per-participant grants.
const REWARD_FLAGS: Array[String] = ["realm_key_cloudreach", "realm_heart_meadows_earned"]

const CONFIG_PATH := "res://data/config/multiplayer.json"
## The only two keys the two-player scaling row is allowed to carry. §10 forbids
## HP x players outright, so a third key here is a finding whether or not
## anything reads it yet.
const ALLOWED_SCALING_KEYS: Array[String] = ["stat_multiplier", "attack_cooldown_multiplier"]

## How many swings each peer may take to land one blow on the boss, and (at twice
## this) how many placement attempts it may make to get one swing away. Same
## reasoning as `smoke_net_shared_wild_fight`'s own SWINGS: the opponent is a live
## body that repositions, a swing at where it was genuinely misses (D07), and a
## player who misses swings again. The claim is that the peer CAN land a blow on
## the shared record, not that any particular swing connects.
##
## A swing is only submitted once the HOST holds the creature within
## `SWING_REACH_M` of the boss, so an attempt spent waiting for the host's view
## to catch up is a re-place and not one of these.
const SWINGS := 14
const PLACE_SETTLE := 20
const STRIKE_SETTLE := 30
## Metres along Z each creature stands off the boss, on opposite sides, so
## neither is ever in the other's arc during the shared-damage half.
const NEAR_Z := 1.6
## The friendly-fire staging: how far along Z the striker stands off the victim.
const APART_Z := 1.5
## How many times the friendly-fire staging is re-attempted. Neither creature can
## be parked -- see that block's own comment -- so the placement is retried until
## the host holds them within reach of each other and the boss has left the window
## alone.
##
## HEADROOM, from a measurement rather than a guess: across three consecutive
## green runs the staging succeeded after 4, 1 and 1 attempts. The 4 is the one
## worth sizing for -- the boss's own attack cooldown (0.9 s, ~54 frames) is close
## to the measured window, so a run can lose several attempts in a row to the boss
## acting in them. 12 leaves three times the worst measurement observed. Raising
## the cap is deliberately the whole change: shortening the window would be the
## other lever and is the named next step if this ever exhausts, but it would
## change what the passing runs exercised, and a cap that is never reached cannot.
const FRIENDLY_TRIES := 12
## A short settle for that staging, for the same reason: a long one gives each
## manager time to pull its creature back.
const FRIENDLY_SETTLE := 8
## What "within one swing" means here, used by both halves: the gate the
## shared-damage loop waits for before it submits, and the diagnostic the
## friendly-fire staging is reported against.
## `combat_manager.gd::_with_reach_for_the_bodies` floors the real quick reach at
## (r + r) * body_clearance 2.75 + 0.5, a little over 3 m for two ordinary bodies;
## 4.0 is that with room for two of unequal size. Deliberately CONSERVATIVE
## against the boss, whose body is larger than an ordinary one: runs that landed a
## blow from 5.2 m are on record, so a gate at 4.0 never lets through a swing that
## could not reach.
const SWING_REACH_M := 4.0

## `smoke_boss.gd`'s allowance, by its own name and for its own stated reason.
## The Warden fields five creatures at levels 18-20 and a headless peer fights
## with the starter `deploy_creature` adopts.
const ENEMY_HP_CEILING := 6.0
## Frames the REMAINING four creatures are given, after the scaling and shared-
## damage reads have been taken on the second. `win_trainer_battle` leaves itself
## 240 frames of margin below whatever it is handed. Measured with the ceiling on:
## 856-898 frames for those four, and 1138 for all five when an earlier revision
## fought the whole team in one call -- so this is roughly five times the measured
## cost, deliberately loose because it is a ceiling and not a target.
const BATTLE_FRAMES := 5400
## Frames for ONE of his rounds, when the arm is asked to stop early.
const ROUND_FRAMES := 2400


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

	# What the configured multiplier for two players IS, read out of the data
	# file rather than out of the code that applies it.
	var row := _configured_scaling_row("2")
	check(not row.is_empty(),
		"data/config/multiplayer.json configures a scaling row for 2 participants (%s)" % str(row))
	var configured_stat := float(row.get("stat_multiplier", 1.0))
	var configured_cooldown := float(row.get("attack_cooldown_multiplier", 1.0))
	# THE CHECK THAT KEEPS THE OTHER THREE HONEST. At 1.0 every comparison
	# below is `authored == authored` and would pass a build that scaled
	# nothing at all.
	check(configured_stat > 1.0,
		"and that row's stat_multiplier is above 1.0 (%.4f) -- otherwise every"
		% configured_stat
		+ " comparison below is authored-against-itself and proves nothing")
	# §10's forbidden knob, asserted against the DATA as well as the behaviour.
	var stray: Array = []
	for key: Variant in row.keys():
		if str(key).begins_with("_"):
			continue
		if not ALLOWED_SCALING_KEYS.has(str(key)):
			stray.append(str(key))
	check(stray.is_empty(),
		"the two-player scaling row names only %s -- §10 forbids HP x players, so a new key here"
			% str(ALLOWED_SCALING_KEYS)
		+ " is a finding whether or not anything reads it yet (stray: %s)" % str(stray))

	# --- who the boss is, before anybody fights him ---------------------------
	var before: Array = []
	for i in 2:
		before.append(await _boss(i))
	for i in 2:
		var b: Dictionary = before[i]
		check(bool(b.get("is_boss", false)),
			"peer %d reads '%s' as a BOSS -- rank '%s' is in trainers.json's boss_ranks"
				% [i, BOSS, BOSS_RANK])
		check(int(b.get("team_size", 0)) == AUTHORED_TEAM_SIZE,
			"peer %d sees his authored team of %d (got %d)"
				% [i, AUTHORED_TEAM_SIZE, int(b.get("team_size", 0))])
		check(str(b.get("defeat_flag", "")) == DEFEAT_FLAG,
			"peer %d sees his defeat flag '%s' (got '%s')"
				% [i, DEFEAT_FLAG, str(b.get("defeat_flag", ""))])
		check((b.get("reward_flags", []) as Array) == REWARD_FLAGS,
			"peer %d sees the climax's own two reward flags %s (got %s)"
				% [i, str(REWARD_FLAGS), str(b.get("reward_flags", []))])
	var pre_reward: Array = []
	for i in 2:
		pre_reward.append(await _reward_state(i))
		check(not bool((pre_reward[i] as Dictionary).get("beaten", true)),
			"peer %d's world does not say the Warden has fallen yet" % i)

	# --- peer 0 takes the challenge -------------------------------------------
	var began: Dictionary = await step(0, "trainer_battle", {"trainer": BOSS})
	check(str(began.get("verdict", "")) == "PASS",
		"peer 0 challenged the Warden through begin_trainer_battle() (%s)"
			% str(began.get("detail", "")))
	if str(began.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var opened: Dictionary = await _boss(0)
	var record: Dictionary = opened.get("record", {}) as Dictionary
	var encounter_id := str(record.get("id", ""))
	check(not encounter_id.is_empty(), "the host minted an encounter record for the boss fight")
	check(str(record.get("kind", "")) == "boss",
		"and it is stamped kind 'boss', not 'trainer' (got '%s')" % str(record.get("kind", "")))
	check(str(record.get("realm", "")) == "meadows",
		"with an explicit realm (D97), got '%s'" % str(record.get("realm", "")))
	check(str(opened.get("battle_id", "")) == BOSS,
		"the running battle is the Warden's (got '%s')" % str(opened.get("battle_id", "")))

	# --- peer 1 joins THAT record (§6) ----------------------------------------
	var where := _vec(record.get("position", []))
	check(where != Vector3.INF, "the record says where the boss is standing")
	if where != Vector3.INF:
		var walked: Dictionary = await step(1, "teleport",
			{"at": [where.x + 3.0, where.y + 1.0, where.z + 3.0]})
		check(str(walked.get("verdict", "")) == "PASS",
			"peer 1 travelled to the boss fight (%s)" % str(walked.get("detail", "")))
	var joined_fight: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(joined_fight.get("verdict", "")) == "PASS",
		"peer 1 joined the boss fight already in progress (%s)" % str(joined_fight.get("detail", "")))

	# --- 1. ONE record, not two fights ----------------------------------------
	var host_live: Dictionary = await _boss(0)
	var host_rec: Dictionary = host_live.get("record", {}) as Dictionary
	check((host_rec.get("participants", []) as Array).size() == 2,
		"the host's ONE record holds 2 participants (got %d)"
			% (host_rec.get("participants", []) as Array).size())
	check(str(host_rec.get("id", "")) == encounter_id,
		"and it is still the same record the challenge minted ('%s' -> '%s')"
			% [encounter_id, str(host_rec.get("id", ""))])
	check(str(host_rec.get("phase", "")) == "active",
		"joining did not change the phase (got '%s')" % str(host_rec.get("phase", "")))
	var guest_live: Dictionary = await _boss(1)
	check(str((guest_live.get("record", {}) as Dictionary).get("bound_id", "")) == encounter_id,
		"peer 1's fight is bound to the SAME record id (got '%s')"
			% str((guest_live.get("record", {}) as Dictionary).get("bound_id", "")))
	# The assertion "not two fights" is this pair, and it is the boss half of
	# what row 7 asserted about a trainer: peer 1 is IN the Warden's fight
	# without running one, so nothing it ends up holding can have come from a
	# battle of its own.
	check(not bool(guest_live.get("battle_active", true)),
		"peer 1 is in the boss fight but is NOT running a trainer battle of its own")
	check(str(guest_live.get("battle_id", "")).is_empty(),
		"and holds no boss battle id of its own (got '%s')" % str(guest_live.get("battle_id", "")))
	check(int(guest_live.get("creatures_left", -1)) == 0,
		"and has no roster of the Warden's to send out (got %d)"
			% int(guest_live.get("creatures_left", -1)))

	# The record's row is re-derived the moment participants changes (§10), and
	# that is asserted here, on the record the join just changed. Since D100 the
	# creature already standing on the field moves with it; the stat and cooldown
	# comparisons are still taken on his SECOND creature, for finding F3's reason
	# rather than F1's -- his opener authors no `attack_cooldown` and a
	# measurement on it would compare 0.0 to 0.0.
	var joined_scaling: Dictionary = host_rec.get("scaling", {}) as Dictionary
	check(absf(float(joined_scaling.get("stat_multiplier", -1.0)) - configured_stat) < 0.0001,
		"the join re-derived the record's scaling row to the two-player one (%.4f, configured %.4f)"
			% [float(joined_scaling.get("stat_multiplier", -1.0)), configured_stat])
	# §10's forbidden knob, asserted at the moment it would fire: a second player
	# ARRIVING must not add health to the creature already being fought. The
	# record's row moved to the two-player one on the line above, so this is the
	# first place a `hp x players` edit could show itself.
	var opener: Dictionary = (host_live.get("authored", {}) as Dictionary).get(
		str((host_live.get("live", {}) as Dictionary).get("species_id", "")), {}) as Dictionary
	check(not opener.is_empty(),
		"his opening creature is one of the authored five (species '%s', authored %s)"
			% [str((host_live.get("live", {}) as Dictionary).get("species_id", "")),
			   str((host_live.get("authored", {}) as Dictionary).keys())])
	check(not opener.is_empty()
			and absf(float(host_rec.get("hp_max", -1.0)) - float(opener.get("max_hp", -2.0))) < 0.001,
		"and the join did NOT add health to the creature already on the field:"
		+ " record hp_max %.3f, authored %.3f (x %.4f would be %.3f)"
			% [float(host_rec.get("hp_max", -1.0)), float(opener.get("max_hp", -2.0)),
			   configured_stat, float(opener.get("max_hp", -2.0)) * configured_stat])

	# --- his second creature comes out, with two people already fighting ------
	var first_down: Dictionary = await step(0, "win_trainer_battle",
		{"budget_frames": ROUND_FRAMES, "enemy_hp_ceiling": ENEMY_HP_CEILING,
		 "stop_when_creatures_left": AUTHORED_TEAM_SIZE - 2}, ROUND_FRAMES)
	check(str(first_down.get("verdict", "")) == "PASS",
		"the two of them put his first creature down and he sent out his second (%s)"
			% str(first_down.get("detail", "")))
	if str(first_down.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	host_live = await _boss(0)
	host_rec = host_live.get("record", {}) as Dictionary
	check(str(host_rec.get("id", "")) == encounter_id,
		"it is STILL the one record -- a new round swaps the opponent, never the record"
		+ " ('%s' -> '%s')" % [encounter_id, str(host_rec.get("id", ""))])
	check((host_rec.get("participants", []) as Array).size() == 2,
		"and both peers are still participants in it (got %d)"
			% (host_rec.get("participants", []) as Array).size())

	# --- 3. NEVER HP x PLAYERS ------------------------------------------------
	# Read at two participants, on a creature the host scaled while two people
	# were fighting it, and before a single point of the ceiling allowance
	# reaches it.
	var live: Dictionary = host_live.get("live", {}) as Dictionary
	var authored_all: Dictionary = host_live.get("authored", {}) as Dictionary
	var species := str(live.get("species_id", ""))
	check(not species.is_empty(),
		"the host has the Warden's SECOND creature on the field (species '%s')" % species)
	var authored: Dictionary = authored_all.get(species, {}) as Dictionary
	check(not authored.is_empty(),
		"and '%s' is one of the Warden's authored five (authored: %s)"
			% [species, str(authored_all.keys())])
	if authored.is_empty():
		quit(await finish())
		return

	# Printed unconditionally, so a red scaling assertion below carries the
	# reason with it rather than needing a second run to find out.
	print("scaling gate: %s" % str(host_live.get("scaling_gate", {})))
	print("live: %s" % str(live))
	print("authored: %s" % str(authored))
	var authored_hp := float(authored.get("max_hp", -1.0))
	var live_hp := float(live.get("max_hp", -2.0))
	check(authored_hp > 0.0, "the authored creature has real hit points (%.3f)" % authored_hp)
	# THE ROW. Two people are fighting him and his health is exactly what one
	# person's would be.
	check(absf(live_hp - authored_hp) < 0.001,
		"§10 / D-MP12: at 2 participants the boss's max_hp is its AUTHORED %.3f, not multiplied"
			% authored_hp
		+ " (live %.3f; a stat_multiplier of %.4f folded into hp would give %.3f)"
			% [live_hp, configured_stat, authored_hp * configured_stat])
	check(absf(float(host_rec.get("hp_max", -2.0)) - authored_hp) < 0.001,
		"and §3's record -- the number both HUDs draw -- carries that same authored hp_max"
		+ " (record %.3f, authored %.3f)" % [float(host_rec.get("hp_max", -2.0)), authored_hp])

	# --- the OTHER two thirds of §10, now asserted (finding F1, closed) -------
	#
	# The same three numbers, in the same direction the header describes. Every
	# one is authored x the CONFIGURED row, so a code/config divergence fails
	# here rather than agreeing with itself, and `configured_stat > 1.0` has
	# already been asserted above -- without it these three would be
	# `authored == authored` and would pass a build that scaled nothing.
	var authored_attack := float(authored.get("attack", 0.0))
	var authored_defence := float(authored.get("defence", 0.0))
	check(absf(float(live.get("attack", -1.0)) - authored_attack * configured_stat) < 0.001,
		"§10: at 2 participants his creature's attack is the authored %.3f x %.4f = %.3f (live %.3f)"
			% [authored_attack, configured_stat, authored_attack * configured_stat,
			   float(live.get("attack", -1.0))])
	check(absf(float(live.get("defence", -1.0)) - authored_defence * configured_stat) < 0.001,
		"and its defence is the authored %.3f x %.4f = %.3f (live %.3f)"
			% [authored_defence, configured_stat, authored_defence * configured_stat,
			   float(live.get("defence", -1.0))])
	# Finding F3 is why this is asserted on his SECOND creature and why the
	# authored number is checked first: the opening burrowback authors no
	# `attack_cooldown` at all, so a cooldown measurement taken on it would
	# compare 0.0 to 0.0 and say nothing. The galecrest authors 0.9.
	var authored_cooldown := float(authored.get("attack_cooldown", 0.0))
	check(authored_cooldown > 0.0,
		"his second creature authors a real attack_cooldown (%.3f) -- without one this comparison"
			% authored_cooldown
		+ " is 0.0 against 0.0 and proves nothing (finding F3)")
	# THE BODY's number, not the instance's. `wild_creature.gd::set_engaged()`
	# snapshots its combat config when the fight opens, which is before §10's
	# record exists, so an override written afterwards reaches no swing at all
	# unless the body is told to re-read it. Asserting the instance's own
	# `combat_override` would pass a build in which the multiplier was written
	# and then never read -- which is a different bug wearing F1's clothes.
	var live_cooldown := float(live.get("body_attack_cooldown", -1.0))
	check(absf(live_cooldown - maxf(0.1, authored_cooldown * configured_cooldown)) < 0.001,
		"and the BODY swings on the authored %.3f x %.4f = %.3f (live %.3f) -- read off its own"
			% [authored_cooldown, configured_cooldown,
			   maxf(0.1, authored_cooldown * configured_cooldown), live_cooldown]
		+ " combat config, which is the number the swing timer uses")

	# The row the host actually stamped on the record when `participants` last
	# changed -- so a host that scaled the creature correctly but told the
	# record something else fails here.
	var stamped: Dictionary = host_rec.get("scaling", {}) as Dictionary
	check(absf(float(stamped.get("stat_multiplier", -1.0)) - configured_stat) < 0.0001,
		"the record's own stamped scaling row agrees with the config (stamped %.4f, configured %.4f)"
			% [float(stamped.get("stat_multiplier", -1.0)), configured_stat])
	check(absf(float(stamped.get("attack_cooldown_multiplier", -1.0)) - configured_cooldown) < 0.0001,
		"and so does its cooldown multiplier (stamped %.4f, configured %.4f)"
			% [float(stamped.get("attack_cooldown_multiplier", -1.0)), configured_cooldown])
	check(not stamped.has("hp_multiplier") and not stamped.has("hp"),
		"and it carries no hp knob at all (%s)" % str(stamped.keys()))

	# --- 2. the boss's HP is host truth, and both peers reduce the same number -
	#
	# Peer 1's LOCAL stand-in is moved onto where the host holds the boss first.
	# FINDING F10, and it is why: a joiner is bound to `nearest_live_wild()` --
	# whichever ambient creature happened to be closest when it joined -- and its
	# own combat manager keeps pulling its creature back to that body. Wild bodies
	# are not replicated (the acceptance file's first known-open), so how far that
	# is from the real fight is a lottery over the seeded spawn table. Measured:
	# two runs landed a blow in 1-3 swings and a third could not land one in 14,
	# with the same code, because that run's nearest wild was further away.
	#
	# Moving it changes no outcome -- §2 resolves every strike against HOST
	# positions, which is what makes the drift cosmetic to begin with -- and it is
	# exactly what wild replication will do for free when it lands. Retrying past
	# a bad draw instead would be turning 0-for-1 into green, which is a finding
	# and not a pass.
	var boss_seat := _vec((host_rec.get("position", []) as Array))
	if boss_seat != Vector3.INF:
		var seated: Dictionary = await step(1, "place_stand_in",
			{"at": [boss_seat.x, boss_seat.y, boss_seat.z], "settle": PLACE_SETTLE})
		check(str(seated.get("verdict", "")) == "PASS",
			"peer 1's local stand-in was moved onto where the host holds the boss (%s)"
				% str(seated.get("detail", "")))
	else:
		check(false, "the record says where the boss is, to seat peer 1's stand-in on")

	var hp_before := float(host_rec.get("hp", -1.0))
	check(hp_before > 0.0, "the record says the boss is standing at %.1f hp" % hp_before)
	for mover in 2:
		var host_hp := hp_before
		var swings := 0
		var attempts := 0
		var last_gap := INF
		# Placement attempts and SWINGS are counted separately, and a swing is
		# only submitted once the HOST holds this peer's creature within reach of
		# the boss. Aiming from where a creature was ASKED to stand is what made
		# the third run red: the host resolves against its own position for the
		# striking creature (§5 step 2), so that is the position the geometry has
		# to be right in. A placement the host has not caught up on yet is a
		# re-place, not a wasted swing.
		while attempts < SWINGS * 2 and swings < SWINGS and host_hp >= hp_before - 0.001:
			attempts += 1
			var view: Dictionary = (await _boss(0)).get("record", {}) as Dictionary
			var boss_at := _vec(view.get("position", []))
			if boss_at == Vector3.INF:
				break
			# Each creature on its own side of the boss, facing it -- and
			# therefore facing directly away from the other player's creature, so
			# neither is ever in the other's arc during this half. `exact`, and
			# the boss's OWN y off the record: inside the Warden Arena the terrain
			# height under the floor is metres below it, so `place_on_ground`
			# dropped both creatures 6-8 m above the fight (finding F2).
			var side := -NEAR_Z if mover == 0 else NEAR_Z
			var stand := boss_at + Vector3(0.0, 0.0, side)
			var placed: Dictionary = await step(mover, "place_creature",
				{"at": [stand.x, stand.y, stand.z], "exact": true,
				 "face": [boss_at.x, boss_at.y, boss_at.z], "settle": PLACE_SETTLE})
			if str(placed.get("verdict", "")) != "PASS":
				check(false, "peer %d stood its creature beside the boss (%s)"
					% [mover, str(placed.get("detail", ""))])
				break
			# Where the HOST holds this peer's creature, and where it holds the
			# boss, both read as late as possible.
			var fresh: Dictionary = (await _boss(0)).get("record", {}) as Dictionary
			var aim := _vec(fresh.get("position", []))
			if aim == Vector3.INF:
				aim = boss_at
			var really_at := await _host_view_of_creature(mover)
			if really_at == Vector3.INF:
				continue
			last_gap = really_at.distance_to(aim)
			if last_gap >= SWING_REACH_M:
				# The host does not hold this creature beside the boss yet. Place
				# it again rather than swinging into empty grass.
				continue
			swings += 1
			var toward := aim - really_at
			var struck: Dictionary = await step(mover, "strike",
				{"facing": [toward.x, toward.y, toward.z], "slot": "quick",
				 "settle": STRIKE_SETTLE})
			if str(struck.get("verdict", "")) != "PASS":
				check(false, "peer %d swung at the boss (%s)" % [mover, str(struck.get("detail", ""))])
				break
			host_hp = float(((await _boss(0)).get("record", {}) as Dictionary).get("hp", -1.0))

		check(host_hp < hp_before - 0.001,
			"peer %d landed a blow on the SHARED boss: %.1f -> %.1f on the host, in %d swing(s)"
				% [mover, hp_before, host_hp, swings]
			+ " over %d placement attempt(s); the host last held its creature %.2f m from the boss"
				% [attempts, last_gap])
		var guest_hp := float(((await _boss(1)).get("record", {}) as Dictionary).get("hp", -1.0))
		# §3: the record's hp is THE hit points and both peers render it. A client
		# decrementing its own copy "for responsiveness" diverges here by exactly
		# one blow.
		check(absf(guest_hp - host_hp) < 0.001,
			"and both peers draw the same boss health bar after it (host %.3f, guest %.3f)"
				% [host_hp, guest_hp])
		hp_before = host_hp

	# --- 5. friendly fire between the two pilots, in the BOSS fight -----------
	#
	# One loop, because three separate things have to be true of the SAME window
	# and none of them can be arranged once and relied on afterwards:
	#
	#   1. **the two creatures are within one swing of each other.** Neither can
	#      be parked: a joiner's own combat manager keeps its creature beside its
	#      LOCAL stand-in (the acceptance file's first known-open) and the host's
	#      keeps its own beside the boss, so a placement drifts back within a few
	#      dozen frames -- measured at 10.33 m apart on attempt 2, which read as
	#      "no refusal", i.e. a swing that never reached the teammate. That is a
	#      failure in the direction that LOOKS like the feature working. So the
	#      staging moves the body it CAN move to the body it cannot: peer 1's
	#      creature is read through the `deployed_creatures` probe on PEER 0 --
	#      where the HOST holds it, not where peer 1 says it is, because the
	#      host's number is what the refusal is decided against (§5 step 2) --
	#      and peer 0's creature is placed beside that.
	#   2. **the swing reached the host.**
	#   3. **the BOSS did not hit the victim during the window.** FINDING F9:
	#      this is a live boss fight and the victim's creature is a legal target
	#      for the boss, which struck it for 14.6 hp inside a 30-frame settle on
	#      one run. Reading "took nothing" across a window the boss also acted in
	#      is not a weaker assertion, it is a WRONG one, and retrying until it
	#      happens to pass would be worse. So the host's own tally is used to
	#      exclude it: `pick_struck` counts every participant it chooses, and
	#      `host_pick_struck_participant`'s header says a pick IS a hit on this
	#      path -- so a tally that did not move is the host stating the boss
	#      landed nothing on that peer in that window.
	#
	# PEER 1 swings, at peer 0's creature. The client is the striker
	# deliberately: a client's refusal has to travel back over the wire and
	# arrive as a sentence (`note_encounter_refusal`), which is the half 7.A's
	# finding F7 showed can be lost under jitter. A host striker's refusal is only
	# its own return value (finding F4) and would test less.
	#
	# No `check()` inside the loop, so the assertion COUNT is the same whether it
	# takes one attempt or eight; everything is asserted once, afterwards, on the
	# last window.
	var host_peer_id := int((await _boss(0)).get("local_peer_id", 1))
	var guest_at := Vector3.INF
	var host_creature_at := Vector3.INF
	var victim_hp := -1.0
	var victim_after := -2.0
	var boss_before := -1.0
	var boss_after := -2.0
	var struck_before := -1
	var struck_after := -2
	var friendly: Dictionary = {}
	var refusal: Dictionary = {}
	var staged := 0
	var clean := false
	while staged < FRIENDLY_TRIES and not clean:
		staged += 1
		guest_at = await _host_view_of_guest_creature()
		if guest_at == Vector3.INF:
			break
		var stand := guest_at + Vector3(0.0, 0.0, APART_Z)
		var placed: Dictionary = await step(0, "place_creature",
			{"at": [stand.x, stand.y, stand.z], "exact": true,
			 "face": [guest_at.x, guest_at.y, guest_at.z], "settle": FRIENDLY_SETTLE})
		if str(placed.get("verdict", "")) != "PASS":
			break
		# Both ends re-read after the placement, off the host's own view.
		guest_at = await _host_view_of_guest_creature()
		var mine: Dictionary = await _encounter(0)
		host_creature_at = _vec(mine.get("my_creature_pos", []))
		if guest_at == Vector3.INF or host_creature_at == Vector3.INF:
			continue
		if guest_at.distance_to(host_creature_at) >= SWING_REACH_M:
			continue

		var pre: Dictionary = await _boss(0)
		struck_before = _struck(pre, host_peer_id)
		boss_before = float((pre.get("record", {}) as Dictionary).get("hp", -1.0))
		victim_hp = float(mine.get("my_creature_hp", -1.0))
		var at_teammate := host_creature_at - guest_at
		at_teammate.y = 0.0
		friendly = await step(1, "strike",
			{"facing": [at_teammate.x, 0.0, at_teammate.z], "slot": "quick",
			 "settle": STRIKE_SETTLE})
		var post: Dictionary = await _boss(0)
		struck_after = _struck(post, host_peer_id)
		boss_after = float((post.get("record", {}) as Dictionary).get("hp", -1.0))
		victim_after = float((await _encounter(0)).get("my_creature_hp", -1.0))
		refusal = (await _boss(1)).get("refusal", {}) as Dictionary
		clean = str(friendly.get("verdict", "")) == "PASS" and struck_after == struck_before

	check(guest_at != Vector3.INF and host_creature_at != Vector3.INF,
		"the host holds a position for both pilots' creatures (peer 1's %s / peer 0's %s)"
			% [str(guest_at), str(host_creature_at)])
	var apart := guest_at.distance_to(host_creature_at) \
		if guest_at != Vector3.INF and host_creature_at != Vector3.INF else INF
	# A diagnostic bound, not the claim. Its only job is to make "the swing never
	# reached the teammate" legible if the refusal assertion fails: a swing that
	# fell short is refused by nothing, which reads exactly like the feature
	# working.
	check(apart < SWING_REACH_M,
		"the two pilots' creatures are within one swing of each other after %d attempt(s)"
			% staged + " (%.2f m of %.2f m)" % [apart, SWING_REACH_M])
	check(victim_hp > 0.0, "peer 0's creature is alive to be swung at (%.1f hp)" % victim_hp)
	check(str(friendly.get("verdict", "")) == "PASS",
		"peer 1's swing at its teammate's creature reached the host (%s)"
			% str(friendly.get("detail", "")))
	# The client's own local answer is `pending`, and `pending` is the host being
	# ASKED, not the host saying no. Asserted so nothing here can mistake the two.
	var local_answer: Dictionary = (friendly.get("data", {}) as Dictionary)
	check(bool(local_answer.get("pending", false)) and not bool(local_answer.get("ok", true)),
		"and the client's own local answer was `pending` -- the host being asked, not a refusal"
		+ " (ok=%s pending=%s code='%s')" % [str(local_answer.get("ok", true)),
			str(local_answer.get("pending", false)), str(local_answer.get("code", ""))])
	# HALF ONE: the host said no, out loud, with §5's own code, and the sentence
	# reached the striker.
	check(str(refusal.get("code", "")) == "friendly_target",
		"the host refused it with `friendly_target` in the BOSS fight (got code '%s', reason '%s')"
			% [str(refusal.get("code", "")), str(refusal.get("reason", ""))])
	check(not str(refusal.get("reason", "")).is_empty(),
		"and the sentence a player can be shown travelled back to the striker")
	# HALF TWO: asserted alongside the refusal, never instead of it -- a silent
	# no-op passes this line while hiding a targeting bug. The window it is
	# measured over is one the BOSS did not act in, which is what the loop above
	# was establishing; if it never found one, this says so instead of reporting
	# the boss's damage as the friendly swing's.
	check(clean,
		"and it is measured over a window the boss itself did not act in --"
		+ " `pick_struck` chose peer %d %d time(s) before and %d after, over %d attempt(s)"
			% [host_peer_id, struck_before, struck_after, staged])
	check(absf(victim_after - victim_hp) < 0.001,
		"peer 0's creature took nothing from it (%.3f before, %.3f after)"
			% [victim_hp, victim_after])
	check(absf(boss_after - boss_before) < 0.001,
		"and the boss took nothing from it either -- a refused strike is refused BEFORE any"
		+ " roll (%.3f before, %.3f after)" % [boss_before, boss_after])

	# --- and the five of them go down -----------------------------------------
	var won: Dictionary = await step(0, "win_trainer_battle",
		{"budget_frames": BATTLE_FRAMES, "enemy_hp_ceiling": ENEMY_HP_CEILING}, BATTLE_FRAMES)
	check(str(won.get("verdict", "")) == "PASS",
		"the two of them fought the Warden's whole team of %d down (%s)"
			% [AUTHORED_TEAM_SIZE, str(won.get("detail", ""))])
	if str(won.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# --- 4. the world fact happens ONCE ---------------------------------------
	var after: Array = []
	for i in 2:
		after.append(await _reward_state(i))
	for i in 2:
		check(bool((after[i] as Dictionary).get("beaten", false)),
			"peer %d's world says the Warden has fallen ('%s')" % [i, DEFEAT_FLAG])
		check(not bool((after[i] as Dictionary).get("can_challenge", true)),
			"and peer %d is not offered a second Warden fight" % i)
		for flag: String in REWARD_FLAGS:
			var held: Dictionary = await step(i, "assert", {"check": "flag_set", "flag": flag})
			check(str(held.get("verdict", "")) == "PASS",
				"peer %d holds the climax's world flag '%s' (%s)"
					% [i, flag, str(held.get("detail", ""))])
	# ONCE, and not once per participant. D99 scopes all three of the Warden's
	# flags to the WORLD, so `encounter_rewards.gd::world_facts()` commits them
	# as world facts and `grants_for()` deliberately skips them. A flag paid the
	# way coins are would leave a `reward:<source>:<peer>` receipt per peer --
	# which is precisely what row 7 asserts EXISTS for coins, and what must not
	# exist here.
	var receipts: Dictionary = (after[0] as Dictionary).get("receipts", {}) as Dictionary
	var session_peers: Array = (after[0] as Dictionary).get("session_peers", []) as Array
	check(session_peers.size() == 2, "the host still knows about 2 peers (got %d)" % session_peers.size())
	for flag: String in REWARD_FLAGS:
		var source := "trainer:%s:flag:%s" % [BOSS, flag]
		var per: Dictionary = receipts.get(source, {}) as Dictionary
		var paid := 0
		for key: Variant in per.keys():
			if bool(per[key]):
				paid += 1
		check(paid == 0,
			"'%s' was committed as a WORLD fact, not paid per participant -- no peer carries a"
				% flag
			+ " '%s' receipt (found %d of %d: %s)" % [source, paid, per.size(), str(per)])

	check(await assert_all_hashes_equal(600),
		"contract §7 state_hash agrees across both peers after the boss fell")

	quit(await finish())


## This peer's view of the boss fight, from `tools/net/peer_runner.gd`'s `boss`
## probe: the host record, the creature actually on the field, the same team
## entry rebuilt UNSCALED, and the last refusal this peer was given.
func _boss(peer: int) -> Dictionary:
	var value = await probe(peer, "boss", {"trainer": BOSS})
	return value if value is Dictionary else {}


## How many times the host has picked `peer_id` to be struck in this fight, off
## the record's own `struck_counts`. JSON turns the integer keys into strings on
## the way through the coordinator, so the lookup is by `str()`.
##
## `0` when the tally exists but names no entry for that peer, which is what "the
## boss has not picked them yet" honestly is. `-1` only when there is no tally at
## all -- a probe that answered nothing must not read as a real count of zero.
func _struck(view: Dictionary, peer_id: int) -> int:
	var counts: Variant = (view.get("record", {}) as Dictionary).get("struck_counts", {})
	if typeof(counts) != TYPE_DICTIONARY:
		return -1
	var key := str(peer_id)
	if not (counts as Dictionary).has(key):
		return 0
	return int((counts as Dictionary)[key])


## Where the HOST holds `peer`'s creature -- the body the host resolves a strike
## against (§5 step 2). A peer's own report of where its creature is standing is
## deliberately not used: the two differ by the replication half-life, and it is
## the host's number every arbitration is decided on.
##
## Peer 0's is the host's own local deployment, read off the `encounter` probe.
## Peer 1's is its visible proxy in the host's tree, read off
## `deployed_creatures` on PEER 0 -- which is why this helper is asked of the
## host in both cases and never of the peer being asked about.
##
## `Vector3.INF` when the host holds no such body, so a caller can tell that
## apart from a position at the origin.
func _host_view_of_creature(peer: int) -> Vector3:
	if peer == 0:
		return _vec((await _encounter(0)).get("my_creature_pos", []))
	return await _host_view_of_guest_creature()


## The other pilot's visible proxy in the host's tree. Kept as its own function
## because the friendly-fire half asks for it by name.
func _host_view_of_guest_creature() -> Vector3:
	var raw = await probe(0, "deployed_creatures")
	if not (raw is Dictionary):
		return Vector3.INF
	for name: Variant in (raw as Dictionary).keys():
		var row: Dictionary = (raw as Dictionary)[name] as Dictionary
		if bool(row.get("mine", true)) or bool(row.get("local", true)):
			continue
		if not bool(row.get("visible", false)):
			continue
		return _vec(row.get("pos", []))
	return Vector3.INF


## The `encounter` probe, used for exactly one thing this file cannot get from
## `boss`: where each peer's OWN creature is standing and what health it has,
## which the friendly-fire half is about.
func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return value if value is Dictionary else {}


## The `trainer_reward` probe, asked ONLY about the Warden's flags. No item and
## no coin: row 7 owns the payout claim and this file does not restate it.
func _reward_state(peer: int) -> Dictionary:
	var sources: Array = []
	for flag: String in REWARD_FLAGS:
		sources.append("trainer:%s:flag:%s" % [BOSS, flag])
	var value = await probe(peer, "trainer_reward",
		{"trainer": BOSS, "sources": sources, "items": []})
	return value if value is Dictionary else {}


## `by_participants[<count>]` out of `data/config/multiplayer.json`, read by
## this file directly. Deliberately NOT through `encounter_host.gd::
## scaling_for()`: that is the code under test, and a smoke that asked it what
## the config says would agree with itself when the two diverged.
##
## `{}` when anything is missing, so a caller can tell "no row" from "a row of
## nothing" with `is_empty()` rather than reading `float(null)`.
func _configured_scaling_row(count: String) -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var encounter: Variant = (parsed as Dictionary).get("encounter", {})
	if typeof(encounter) != TYPE_DICTIONARY:
		return {}
	var scaling: Variant = (encounter as Dictionary).get("scaling", {})
	if typeof(scaling) != TYPE_DICTIONARY:
		return {}
	var rows: Variant = (scaling as Dictionary).get("by_participants", {})
	if typeof(rows) != TYPE_DICTIONARY:
		return {}
	var row: Variant = (rows as Dictionary).get(count, {})
	return row as Dictionary if typeof(row) == TYPE_DICTIONARY else {}


## Vector3.INF when `raw` is not the three-float array the probe promises, so a
## shape failure is a legible out-of-range rather than a `float(null)` that
## aborts the check around it.
func _vec(raw: Variant) -> Vector3:
	if typeof(raw) != TYPE_ARRAY or (raw as Array).size() != 3:
		return Vector3.INF
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
