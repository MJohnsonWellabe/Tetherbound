extends "res://tests/test_case.gd"

## Stage B Wave 4 lane 4.D. ONE WORLD FACT, TWO PAYCHEQUES.
##
## `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §7 and §10. A trainer beaten by two
## people is beaten ONCE for the world and pays BOTH of them, in full.
##
## Deterministic and pure: no networking, no scene tree, no `Game`, no ledger.
## `scripts/net/encounter_rewards.gd` decides what to ASK the ledger for, and
## that decision is arithmetic over a trainer spec and a participant list -- so
## the claim this whole lane rests on ("nothing is divided by how many people
## turned up") is provable by reading two dictionaries, without a second
## process, a socket, or a fight.
##
## The specs below are written here rather than loaded from
## `data/config/bands/*/trainers.json` on purpose: this file is asserting the
## RULE, and a rule pinned to whatever Bryn happens to pay this week starts
## failing when a designer retunes a reward. `tests/test_trainers_data.gd`
## already owns the table itself. The one place a shipped id is used is the
## world/player scope split, which is a genuine question about
## `data/progression/flag_scopes.json` and has to be asked of the real file.

const REWARDS := preload("res://scripts/net/encounter_rewards.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")

const REALM := "meadows"

## Not indices. The ENet spike's finding 2: a joiner's peer id is a large
## random 32-bit number and nothing may assume an ordering or a small value.
const PEER_HOST := 1
const PEER_GUEST := 1_369_099_083
const PEER_THIRD := 884_120_557


## A trainer who pays every kind of thing a trainer can pay: coins, two items,
## a world-scoped reward flag, and a flat XP bonus.
func _paying_trainer() -> Dictionary:
	return {
		"id": "captain_test",
		"name": "Captain Test",
		"defeat_flag": "defeated_captain_field",
		"reward": {
			"coins": 150,
			"items": [{"id": "revive", "count": 2}, {"id": "potion_small", "count": 4}],
			"flags": ["realm_key_cloudreach"],
			"xp_bonus": 400,
		},
	}


func _grant_named(grants: Array, source: String) -> Dictionary:
	for raw: Variant in grants:
		if str((raw as Dictionary).get("source", "")) == source:
			return raw as Dictionary
	return {}


# --- §7: the world fact happens ONCE ------------------------------------------------

func test_the_defeat_flag_is_one_world_intent_however_many_people_won_it() -> void:
	var spec := _paying_trainer()
	var alone: Array = REWARDS.world_facts(spec, REALM)
	# The world half does not take a participant list at all, and that is the
	# assertion: there is no argument it could vary with. Four people beating a
	# trainer is the same one fact as one person beating them.
	var defeats: int = 0
	for raw: Variant in alone:
		if str((raw as Dictionary).get("id", "")) == "defeated_captain_field":
			defeats += 1
	assert_eq(defeats, 1, "the defeat flag is committed exactly once")
	assert_eq(str((alone[0] as Dictionary).get("kind", "")), "set_world_flag",
		"and it is committed as a world intent, not written locally")
	assert_eq(str((alone[0] as Dictionary).get("realm", "")), REALM,
		"D97: stamped with an explicit realm")


func test_a_world_scoped_reward_flag_travels_with_the_world_fact_not_the_payout() -> void:
	# `realm_key_cloudreach` is world-scoped in data/progression/flag_scopes.json.
	# Granting it per participant would write the same world fact once per
	# player, which is the duplication §7's first sentence forbids.
	var spec := _paying_trainer()
	var facts: Array = REWARDS.world_facts(spec, REALM)
	var ids: Array = []
	for raw: Variant in facts:
		ids.append(str((raw as Dictionary).get("id", "")))
	assert_true(ids.has("realm_key_cloudreach"),
		"the world-scoped reward flag is one of the world's facts")
	var grants: Array = REWARDS.grants(spec, REALM, [PEER_HOST, PEER_GUEST])
	assert_true(_grant_named(grants,
		REWARDS.source_for("captain_test", "flag:realm_key_cloudreach")).is_empty(),
		"and it is NOT also handed out per participant")


func test_a_player_scoped_reward_flag_is_paid_to_each_participant_instead() -> void:
	# The mirror. `saddle_fitted_` is player-scoped by prefix: it is a fact
	# about YOUR creature, so two players who beat the trainer together each
	# need their own.
	var spec := _paying_trainer()
	(spec["reward"] as Dictionary)["flags"] = ["saddle_fitted_terrapup"]
	var facts: Array = REWARDS.world_facts(spec, REALM)
	assert_eq(facts.size(), 1, "only the defeat flag is the world's")
	var grant := _grant_named(grants_for(spec, [PEER_HOST, PEER_GUEST]),
		REWARDS.source_for("captain_test", "flag:saddle_fitted_terrapup"))
	assert_false(grant.is_empty(), "the personal flag is a per-participant grant")
	assert_eq((grant.get("peers", []) as Array).size(), 2,
		"addressed to both of them")


func test_a_trainer_with_no_defeat_flag_asks_the_world_for_nothing() -> void:
	# `trainer_npc.gd` already warns about this case. Minting a payout keyed off
	# a trainer nothing can identify afterwards would write `reward::<peer>`
	# receipts no later run could ever match.
	var spec := {"id": "nameless", "reward": {"coins": 5}}
	assert_eq((REWARDS.world_facts(spec, REALM) as Array).size(), 0,
		"no defeat flag, no world fact")


func test_a_spec_with_no_id_is_refused_rather_than_paid_against_an_empty_source() -> void:
	var spec := {"defeat_flag": "defeated_mira", "reward": {"coins": 5}}
	assert_eq((REWARDS.grants(spec, REALM, [PEER_HOST]) as Array).size(), 0,
		"a payout with no trainer to key its receipts on is not made")


func test_an_intent_with_no_realm_is_refused_rather_than_guessed_at() -> void:
	# D97 again, from the other side: `world_ledger.gd` refuses a realmless
	# intent as malformed, so producing one here would turn a victory into a
	# refusal a player is shown.
	var spec := _paying_trainer()
	assert_eq((REWARDS.world_facts(spec, "") as Array).size(), 0, "no realm, no world fact")
	assert_eq((REWARDS.grants(spec, "", [PEER_HOST]) as Array).size(), 0, "no realm, no grants")


# --- §7: the personal reward happens PER PARTICIPANT ---------------------------------

func test_every_participant_is_addressed_by_every_component_of_the_payout() -> void:
	var spec := _paying_trainer()
	var grants: Array = REWARDS.grants(spec, REALM, [PEER_HOST, PEER_GUEST, PEER_THIRD])
	assert_true(grants.size() >= 4,
		"coins, two items and the xp receipt are four separate sources")
	for raw: Variant in grants:
		var grant := raw as Dictionary
		var peers: Array = grant.get("peers", []) as Array
		assert_eq(peers.size(), 3,
			"'%s' is addressed to all three" % str(grant.get("source", "")))
		assert_true(peers.has(PEER_GUEST),
			"'%s' names the joiner" % str(grant.get("source", "")))
		assert_eq(str(grant.get("kind", "")), "reward_grant",
			"'%s' is a reward_grant" % str(grant.get("source", "")))


func test_xp_is_not_divided_by_participant_count() -> void:
	# The sentence this whole lane exists for. §7: a fight that pays half as
	# much for having a friend along teaches people to play alone.
	var spec := _paying_trainer()
	assert_eq(REWARDS.xp_bonus(spec), 400, "one player is owed the authored bonus")
	# `xp_bonus()` takes no participant count, so there is no argument it could
	# be divided by -- which is the structural half of the claim. The behavioural
	# half is that the grant list carries the same receipt whoever is in it.
	for participants: Array in [[PEER_HOST], [PEER_HOST, PEER_GUEST],
			[PEER_HOST, PEER_GUEST, PEER_THIRD, 42]]:
		var xp := _grant_named(REWARDS.grants(spec, REALM, participants),
			REWARDS.source_for("captain_test", "xp"))
		assert_false(xp.is_empty(),
			"the xp receipt exists at %d participants" % participants.size())
		assert_eq((xp.get("peers", []) as Array).size(), participants.size(),
			"and it names every one of the %d" % participants.size())


func test_items_are_not_divided_by_participant_count_either() -> void:
	var spec := _paying_trainer()
	for participants: Array in [[PEER_HOST], [PEER_HOST, PEER_GUEST],
			[PEER_HOST, PEER_GUEST, PEER_THIRD, 42]]:
		var grants: Array = REWARDS.grants(spec, REALM, participants)
		var coins := _grant_named(grants, REWARDS.source_for("captain_test", "coins"))
		assert_eq(int(coins.get("count", 0)), 150,
			"each of %d participants is owed the authored 150 coin" % participants.size())
		var revives := _grant_named(grants, REWARDS.source_for("captain_test", "item:revive"))
		assert_eq(int(revives.get("count", 0)), 2,
			"and the authored 2 revives, at %d participants" % participants.size())


func test_each_component_is_its_own_source_so_one_full_satchel_cannot_burn_the_rest() -> void:
	# `world_ledger.gd::_reward_grant()` guards a replay with one receipt per
	# participant per SOURCE. One source for a whole payout means the receipt
	# burnt by the coins landing also covers the potion that did not.
	var spec := _paying_trainer()
	var sources: Dictionary = {}
	for raw: Variant in REWARDS.grants(spec, REALM, [PEER_HOST, PEER_GUEST]):
		var source := str((raw as Dictionary).get("source", ""))
		assert_false(sources.has(source), "'%s' appears exactly once" % source)
		sources[source] = true
	assert_true(sources.has(REWARDS.source_for("captain_test", "coins")), "coins have a source")
	assert_true(sources.has(REWARDS.source_for("captain_test", "item:revive")),
		"and so does each item, by item id")
	assert_true(sources.has(REWARDS.source_for("captain_test", "item:potion_small")),
		"including the second one")
	assert_true(sources.has(REWARDS.source_for("captain_test", "xp")),
		"and the xp receipt is its own source too")


func test_the_same_peer_listed_twice_is_paid_once() -> void:
	# A peer that appears twice is one peer. Leaving this to the ledger to
	# notice is leaving the exact failure `reward_flag()` exists to prevent to a
	# file that is being handed the duplicate as if it were two people.
	var spec := _paying_trainer()
	var grants: Array = REWARDS.grants(spec, REALM, [PEER_GUEST, PEER_GUEST, PEER_HOST])
	var peers: Array = (grants[0] as Dictionary).get("peers", []) as Array
	assert_eq(peers.size(), 2, "three entries, two people")
	assert_eq(int(peers[0]), PEER_GUEST, "in the order they were handed over")


func test_a_payout_with_nobody_in_the_fight_is_not_made() -> void:
	assert_eq((REWARDS.grants(_paying_trainer(), REALM, []) as Array).size(), 0,
		"an empty participant list pays nobody rather than paying peer 0")
	assert_eq((REWARDS.unique_peers([0, 0]) as Array).size(), 0,
		"and peer 0 is not a peer")


func test_a_trainer_who_pays_nothing_produces_no_grants_but_still_falls() -> void:
	# Most of the table. The per-creature XP the fight already paid is what
	# those trainers are worth, and an empty grant list says so honestly --
	# while the world still records that they were beaten.
	var spec := {"id": "trainer_tam", "defeat_flag": "defeated_tam"}
	assert_eq((REWARDS.grants(spec, REALM, [PEER_HOST, PEER_GUEST]) as Array).size(), 0,
		"nothing authored, nothing granted")
	assert_eq((REWARDS.world_facts(spec, REALM) as Array).size(), 1,
		"but they are still beaten, for everybody")


func test_a_zero_count_item_row_is_skipped_rather_than_granted_as_nothing() -> void:
	var spec := _paying_trainer()
	(spec["reward"] as Dictionary)["items"] = [{"id": "revive", "count": 0},
		{"id": "", "count": 3}, {"id": "potion_small", "count": 1}]
	var grants: Array = REWARDS.grants(spec, REALM, [PEER_HOST])
	assert_true(_grant_named(grants, REWARDS.source_for("captain_test", "item:revive")).is_empty(),
		"a count of zero is not a grant")
	assert_false(_grant_named(grants,
		REWARDS.source_for("captain_test", "item:potion_small")).is_empty(),
		"and the row beside it still is one")


func test_no_two_grants_share_one_participant_list() -> void:
	# FINDING (break J). The first version of this test asserted only that a
	# grant does not alias the CALLER's array -- and `unique_peers()` already
	# returns a fresh array, so removing `_grant()`'s `duplicate()` left every
	# assertion green. The defect that line actually prevents is one array
	# shared by all four grants: correcting one component's recipients would
	# silently correct every component's, which is how a payout ends up owed to
	# somebody nothing recorded a receipt for.
	var participants: Array = [PEER_HOST, PEER_GUEST]
	var grants: Array = REWARDS.grants(_paying_trainer(), REALM, participants)
	assert_true(grants.size() >= 2, "there are several components to share an array")
	((grants[0] as Dictionary)["peers"] as Array).append(999)
	assert_eq(participants.size(), 2, "the caller's fight is untouched")
	assert_eq(((grants[1] as Dictionary)["peers"] as Array).size(), 2,
		"and the next component still owes exactly the two people who fought it")


# --- §10 / D-MP12: scaling, and never HP x players -----------------------------------

func test_solo_is_the_identity_row() -> void:
	var row: Dictionary = ENCOUNTER_HOST.scaling_for(1)
	assert_almost_eq(float(row.get("stat_multiplier", 0.0)), 1.0,
		0.0001, "one player scales nothing")
	assert_almost_eq(float(row.get("attack_cooldown_multiplier", 0.0)), 1.0,
		0.0001, "and swings at the authored rate")


func test_more_people_make_the_opponent_modestly_stronger_and_faster() -> void:
	var two: Dictionary = ENCOUNTER_HOST.scaling_for(2)
	var four: Dictionary = ENCOUNTER_HOST.scaling_for(4)
	assert_true(float(two["stat_multiplier"]) > 1.0, "two players is harder than one")
	assert_true(float(four["stat_multiplier"]) > float(two["stat_multiplier"]),
		"and four is harder than two")
	assert_true(float(two["stat_multiplier"]) < 1.5,
		"MODEST: §10 asks for an edge, not a second fight")
	assert_true(float(two["attack_cooldown_multiplier"]) < 1.0,
		"one body facing two people swings more often")


func test_there_is_no_hp_multiplier_to_reach_for() -> void:
	# §10's one outright prohibition, asserted as an ABSENCE rather than as a
	# value of 1.0: a key that is present and set to 1.0 is a key somebody
	# eventually tries at 1.5.
	for count in [1, 2, 3, 4, 9]:
		var row: Dictionary = ENCOUNTER_HOST.scaling_for(count)
		assert_false(row.has("hp_multiplier"),
			"no hp multiplier at %d participants" % count)
		assert_false(row.has("hp"), "and no hp key at %d participants" % count)


func test_a_group_bigger_than_the_table_clamps_to_the_hardest_row() -> void:
	# The direction a missing row has to fail in. Falling back to the identity
	# would make the fight get EASIER the more people joined.
	var four: Dictionary = ENCOUNTER_HOST.scaling_for(4)
	var nine: Dictionary = ENCOUNTER_HOST.scaling_for(9)
	assert_almost_eq(float(nine["stat_multiplier"]), float(four["stat_multiplier"]),
		0.0001, "nine players are scaled as four, never as one")


func test_a_count_of_zero_or_less_is_read_as_one_player() -> void:
	assert_almost_eq(float(ENCOUNTER_HOST.scaling_for(0)["stat_multiplier"]),
		1.0, 0.0001, "an empty fight is not a scaled one")


# --- §10 / H6: the opponent's swings are spread across the participants --------------

func test_the_opponent_prefers_whoever_it_has_hit_least() -> void:
	# §10's own words: targeting is spread across participants "rather than one
	# player tanking by standing still". Nearest-only is exactly that failure --
	# whoever steps closest absorbs the whole fight and the other one watches.
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "boss", {"species_id": "tuskroot", "hp_max": 100.0})
	var id := str(rec["encounter_id"])
	host.join(id, PEER_GUEST)
	# The host's creature is nearer on every single swing.
	var candidates: Array = [
		{"peer_id": PEER_HOST, "distance": 1.0},
		{"peer_id": PEER_GUEST, "distance": 4.0},
	]
	var picks: Array = []
	for i in 4:
		var pick: Dictionary = host.pick_struck(id, candidates)
		picks.append(int(pick.get("peer_id", 0)))
		host.note_struck(id, int(pick.get("peer_id", 0)))
	assert_eq(host.struck_count(id, PEER_HOST), 2, "the host took half of them")
	assert_eq(host.struck_count(id, PEER_GUEST), 2, "and the joiner took the other half")
	assert_ne(int(picks[0]), int(picks[1]), "consecutive swings do not land on the same player")


func test_distance_still_breaks_a_tie() -> void:
	# Spread is the first key, not the only one: with everybody equally hit,
	# the creature swings at what is in front of it.
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "trainer", {"species_id": "mudsnout", "hp_max": 40.0})
	var id := str(rec["encounter_id"])
	host.join(id, PEER_GUEST)
	var pick: Dictionary = host.pick_struck(id, [
		{"peer_id": PEER_GUEST, "distance": 6.0},
		{"peer_id": PEER_HOST, "distance": 1.2},
	])
	assert_eq(int(pick.get("peer_id", 0)), PEER_HOST, "nobody hit yet, so the nearer one takes it")


func test_a_swing_that_reached_one_person_lands_on_that_person() -> void:
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "wild", {"species_id": "mudsnout", "hp_max": 40.0})
	var id := str(rec["encounter_id"])
	host.join(id, PEER_GUEST)
	host.note_struck(id, PEER_GUEST)
	host.note_struck(id, PEER_GUEST)
	var pick: Dictionary = host.pick_struck(id, [{"peer_id": PEER_GUEST, "distance": 2.0}])
	assert_eq(int(pick.get("peer_id", 0)), PEER_GUEST,
		"a solo fight, and a swing only one person is in reach of, are the same case")
	assert_true((host.pick_struck(id, []) as Dictionary).is_empty(),
		"a swing that reached nobody hits nobody")


func test_a_leaver_stops_being_a_target_and_stops_being_counted() -> void:
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "boss", {"species_id": "tuskroot", "hp_max": 100.0})
	var id := str(rec["encounter_id"])
	host.join(id, PEER_GUEST)
	host.note_struck(id, PEER_GUEST)
	assert_eq(host.struck_count(id, PEER_GUEST), 1, "the joiner has taken one")
	host.leave(id, PEER_GUEST)
	assert_eq(host.struck_count(id, PEER_GUEST), 0,
		"and leaving forgets it, so a rejoin is not owed a free pass")
	assert_eq(host.participant_count(id), 1, "the fight goes on for whoever is left (§9)")


# --- §10: the record carries the scaling, and re-derives it --------------------------

func test_the_record_is_stamped_with_its_own_scaling_row() -> void:
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "boss", {"species_id": "tuskroot", "hp_max": 100.0})
	var id := str(rec["encounter_id"])
	assert_true(rec.has("scaling"), "the record says what it is scaled by")
	assert_almost_eq(float(host.scaling(id)["stat_multiplier"]), 1.0, 0.0001,
		"one participant, identity")


func test_a_mid_fight_join_re_derives_the_scaling() -> void:
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "boss", {"species_id": "tuskroot", "hp_max": 100.0})
	var id := str(rec["encounter_id"])
	var solo := float(host.scaling(id)["stat_multiplier"])
	host.join(id, PEER_GUEST)
	assert_true(float(host.scaling(id)["stat_multiplier"]) > solo,
		"§10: re-derived when `participants` changes, a mid-fight join included")
	host.leave(id, PEER_GUEST)
	assert_almost_eq(float(host.scaling(id)["stat_multiplier"]), solo, 0.0001,
		"and again when somebody leaves")


func test_the_opponents_hit_points_are_never_touched_by_a_join() -> void:
	# The prohibition, asserted where it would actually bite. A join must not
	# move the bar -- neither up (HP x players) nor down (a reset), and §6 says
	# the same thing about the phase.
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "boss",
		{"species_id": "tuskroot", "hp": 61.5, "hp_max": 100.0})
	var id := str(rec["encounter_id"])
	host.join(id, PEER_GUEST)
	assert_almost_eq(host.opponent_hp(id), 61.5, 0.0001,
		"the boss has the hit points it had a moment ago")
	assert_almost_eq(float((host.record(id)["opponent"] as Dictionary)["hp_max"]), 100.0,
		0.0001, "and the same maximum it was authored with")


# --- one record, several creatures ---------------------------------------------------

func test_the_trainers_next_creature_is_the_same_fight_and_the_same_participants() -> void:
	# A record minted per round drops a joiner between rounds and pays them for
	# none of a boss they fought two thirds of.
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "boss",
		{"species_id": "burrowback", "hp": 40.0, "hp_max": 40.0})
	var id := str(rec["encounter_id"])
	host.join(id, PEER_GUEST)
	assert_true(host.set_opponent(id, {"species_id": "tuskroot", "hp": 90.0, "hp_max": 90.0}),
		"their next creature steps up")
	assert_eq(str((host.record(id)["opponent"] as Dictionary)["species_id"]), "tuskroot",
		"the record now describes the creature on the field")
	assert_almost_eq(host.opponent_hp(id), 90.0, 0.0001, "with its own hit points")
	assert_eq(host.participant_count(id), 2, "and both of them are still in the fight")
	assert_eq(str(host.record(id)["encounter_id"]), id, "under the same id")
	assert_eq(str(host.phase(id)), "active", "still active -- a send-out is not a reset")


func test_a_finished_fight_does_not_get_another_creature() -> void:
	var host := ENCOUNTER_HOST.new(PEER_HOST)
	var rec: Dictionary = host.open(PEER_HOST, REALM, "trainer",
		{"species_id": "bramblebun", "hp": 20.0, "hp_max": 20.0})
	var id := str(rec["encounter_id"])
	host.close(id)
	assert_false(host.set_opponent(id, {"species_id": "tuskroot", "hp_max": 90.0}),
		"a fight that is over stays over")


func grants_for(spec: Dictionary, participants: Array) -> Array:
	return REWARDS.grants(spec, REALM, participants)
