extends "res://tests/test_case.gd"

const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")
var _command_authority: RefCounted = null


func before_each() -> void:
	_command_authority = _admission_fixture(1)


func after_each() -> void:
	_command_authority = null


## Host-owned actor/admission fixture only. The production Session→gear
## producer remains unwired; this does not prove portable equipped gear.
func _admission_fixture(tier: int) -> RefCounted:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {"hp": 100.0, "hp_max": 100.0, "card": {"uid": "wild-a"}}, "owned-a", "character-a")
	host.bind_actor_vitals(str(record.encounter_id), 1, "character-a", {"uid": "owned-a", "hp": 60.0, "max_hp": 100.0, "fainted": false}, 3)
	record.participants[1]["command_admission"] = {"character_id": "character-a", "profile": COMMANDS.gear_profile(tier)}
	return host


func _stage(state: Dictionary, intent: Dictionary, context: Dictionary, authority: RefCounted = null) -> Dictionary:
	return COMMANDS.stage(state, intent, context, _command_authority if authority == null else authority)

## Pure host fixtures, not an earned meter/player/transport proof. The host
## fixture seeds its own meter; no client baseline or hit grants state here.
func _state(tier: int = 1) -> Dictionary:
	var state := COMMANDS.empty_state("1:1", "character-a", tier)
	state.meter = 100.0
	return state


func _intent(command: String = "rally", sequence: int = 1) -> Dictionary:
	return {"encounter_id": "1:1", "generation": 3, "sequence": sequence, "command_id": command}


func _host() -> Dictionary:
	return {"encounter_id": "1:1", "character_id": "character-a", "generation": 3, "peer_id": 1,
		"phase": "active", "participant": true, "active_uid": "owned-a", "owned_uids": ["owned-a", "owned-b"],
		"active_alive": true, "now_ms": 1000, "command_allowed": true,
		"opponent_kind": "wild", "opponent_owned": false, "snare_immune": false,
		"opponent_alive": true, "opponent_uid": "wild-a"}


func test_command_scope_refuses_foreign_stale_claimed_and_malformed_without_mutation() -> void:
	var state := _state()
	var baseline := state.duplicate(true)
	for field: String in ["character_id", "encounter_id", "active_uid"]:
		var host := _host()
		host[field] = "foreign"
		assert_false(_stage(state, _intent(), host).ok)
	for generation: Variant in [2, 3.0, "3", -1]:
		var host := _host()
		host.generation = generation
		assert_false(_stage(state, _intent(), host).ok)
	for field: String in ["tier", "meter", "hit", "owned_uids"]:
		var request := _intent()
		request[field] = 100
		assert_false(_stage(state, request, _host()).ok, "client cannot append authority/baseline claims")
	for field: String in ["meter", "revision", "receipts", "gear", "rally_until_ms"]:
		var malformed := state.duplicate(true)
		malformed[field] = "not-state"
		assert_false(_stage(malformed, _intent(), _host()).ok)
	var malformed := state.duplicate(true)
	malformed.receipts["3:1"] = "not-a-receipt"
	assert_false(_stage(malformed, _intent(), _host()).ok)
	var upgraded := state.duplicate(true)
	upgraded.gear = COMMANDS.gear_profile(4)
	assert_false(_stage(upgraded, _intent("snare"), _host()).ok, "another valid tier cannot replace the canonical tier-one admission")
	var detached: Dictionary = _command_authority.command_gear_anchor("1:1", 1, "character-a", "owned-a", 3)
	detached.tier = 4
	assert_eq(_command_authority.command_gear_anchor("1:1", 1, "character-a", "owned-a", 3).tier, 1)
	assert_false(ENCOUNTER_HOST.presentation_snapshot(_command_authority.record("1:1")).participants[1].has("command_admission"))
	var host := _host()
	host.owned_uids = ["owned-a", "owned-a"]
	assert_false(_stage(state, _intent(), host).ok)
	assert_eq(state, baseline, "all refusals leave the host meter and effects untouched")


func test_command_replay_snare_scope_and_sequence_bound_never_spend_twice() -> void:
	var cfg := COMMANDS.config()
	var original_limit: Variant = cfg.receipt_limit_per_player
	cfg.receipt_limit_per_player = 1
	var state := _state()
	var baseline := state.duplicate(true)
	var first := _stage(state, _intent("snare"), _host())
	assert_true(first.ok)
	assert_eq(state, baseline, "staging publishes no slow/catch chance/meter debit")
	assert_eq(first.effect.hp_damage, 0.0)
	assert_eq(first.effect.poise_damage, 0.0)
	var accepted: Dictionary = first.state # Simulated host acceptance, not a live transaction.
	assert_true(_stage(accepted, _intent("snare"), _host()).duplicate)
	assert_eq(accepted.meter, 40.0)
	assert_false(_stage(accepted, _intent("rally"), _host()).ok, "same sequence cannot become another command")
	assert_eq(_stage(accepted, _intent("rally", 2), _host()).code, "receipt_budget")
	for field: String in ["opponent_kind", "opponent_owned", "snare_immune", "opponent_alive"]:
		var host := _host()
		host[field] = "trainer" if field == "opponent_kind" else field != "opponent_alive"
		assert_false(_stage(state, _intent("snare"), host).ok)
	_command_authority.record("1:1").kind = "trainer"
	assert_false(_stage(state, _intent("snare"), _host()).ok, "wild claim cannot override the canonical trainer encounter")
	_command_authority.record("1:1").kind = "wild"
	assert_eq(COMMANDS.snare_catch_bonus(accepted, "character-a", "wild-a", 1001), 0.1)
	assert_eq(COMMANDS.snare_catch_bonus(accepted, "character-b", "wild-a", 1001), 0.0)
	assert_eq(COMMANDS.snare_catch_bonus(accepted, "character-a", "other-wild", 1001), 0.0)
	assert_eq(COMMANDS.snare_catch_bonus(accepted, "character-a", "wild-a", 4000), 0.0)
	var capped := _state()
	capped.last_sequence = 2147483646
	assert_true(_stage(capped, _intent("rally", 2147483647), _host()).ok)
	assert_false(_stage(capped, _intent("rally", 2147483648), _host()).ok, "sequence exhaustion never wraps")
	assert_eq(state, baseline)
	cfg.receipt_limit_per_player = original_limit


func test_command_gear_combo_and_pouch_apply_only_admitted_own_support() -> void:
	_command_authority = _admission_fixture(4)
	assert_true(COMMANDS.gear_profile(0).is_empty())
	assert_true(COMMANDS.gear_profile(5).is_empty())
	assert_eq(COMMANDS.gear_profile(1).pouch_size, 1)
	assert_eq(COMMANDS.gear_profile(4).pouch_size, 3)
	assert_true(COMMANDS.landed_gain("quick", 4) > COMMANDS.landed_gain("quick", 1))
	assert_eq(COMMANDS.landed_gain("damage_taken", 4), 0.0)
	assert_eq(COMMANDS.landed_gain("ultimate", 4), 0.0)
	assert_eq(COMMANDS.landed_gain("tag_switch", 4), 0.0)
	var state := _state(4)
	state.last_landed_ms = 500
	state.last_landed_uid = "owned-a"
	var host := _host()
	host.merge({"next_uid": "owned-b", "next_alive": true, "switch_allowed": true, "switch_ready_ms": 0})
	var combo := _stage(state, _intent("tag_switch"), host)
	assert_true(combo.ok)
	assert_eq(combo.effect.hp_damage, 0.0, "trainer proposal never becomes an HP damage event")
	for strike: Dictionary in combo.effect.creature_strikes:
		assert_eq(strike.source_kind, "creature")
		assert_true(host.owned_uids.has(strike.source_uid))
	host.next_uid = "foreign-creature"
	assert_false(_stage(state, _intent("tag_switch"), host).ok)
	host.next_uid = "owned-b"
	host.now_ms = 1501
	assert_false(_stage(state, _intent("tag_switch"), host).ok)
	host = _host()
	host.merge({"item_use_ready": true, "pouch_item_id": "potion_small", "pouch_item_kind": "consumable",
		"item_deals_damage": false, "pouch_item_index": 2, "earlier_pouch_slots_empty": true})
	assert_false(_stage(_state(1), _intent("item_throw"), host, _admission_fixture(1)).ok, "base tier cannot select third pouch slot")
	assert_true(_stage(state, _intent("item_throw"), host).effect.requires_item_commit)
	host.pouch_item_kind = "orb"
	assert_false(_stage(state, _intent("item_throw"), host).ok, "orbs retain aim/consumption authority")
	host.pouch_item_kind = "consumable"
	host.item_deals_damage = true
	assert_false(_stage(state, _intent("item_throw"), host).ok)
