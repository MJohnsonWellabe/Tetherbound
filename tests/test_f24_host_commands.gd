extends "res://tests/test_move_commit_runtime.gd"

## Existing host transaction and canonical consumer coverage. Flags are a
## disclosed test fixture; no native, two-peer or feature activation claim.
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const DATA := preload("res://tests/test_tm_teach_transaction.gd")
var _saved_commands: Dictionary

func before_each() -> void:
	super()
	_saved_commands = COMMANDS.config()
	COMMANDS._config = _saved_commands.duplicate(true)
	COMMANDS._config.feature_flags.runtime_enabled = true

func after_each() -> void:
	COMMANDS._config = _saved_commands

func _admitted(character: String = "owner_a") -> Dictionary:
	var admitted: Dictionary = DATA.new()._before()
	admitted.character_id = character
	return admitted

func _command_view() -> Dictionary:
	return {"actor": {"character_id": "owner_a", "encounter_id": id, "creature_uid": "creature_a", "generation": 1, "hp": 100.0},
		"target": {"uid": "opponent", "generation": 1, "hp": 200.0, "hostile": true, "ownership_kind": "wild", "trainer_owned": false, "snare_immune": false},
		"snare_geometry_connected": true}

func _command_pool() -> Dictionary:
	return host.encounters[id].participants[1].tether_commands

func test_meter_uses_original_host_hit_once_and_freezes_admitted_gear() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	var frozen := MASTERY.freeze_action(MASTERY.owned_record(_owned()), "quick",
		{"character_id": "owner_a", "creature_uid": "creature_a", "encounter_id": id, "generation": 1, "action": 1}, [], MOVES.load_default())
	assert_true(frozen.ok)
	var move := MANAGER.host_move_profile(MOVES.load_default(), "player_quick", "pebble_toss", 0.5, 0.5, 1.0, 0.0, frozen.move)
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "quick"}, 1, _owned(), _binding(), move, WIND, 1000).ok)
	assert_true(_arrive(1, 1300).ok)
	assert_true(host.credit_move_hit(id, 1, 1, 0.0, "opponent", 200.0, 1, 100.0).is_empty())
	assert_eq(_command_pool().meter, 0.0)
	host.credit_move_hit(id, 1, 1, 2.0, "opponent", 200.0, 1, 100.0)
	assert_eq(_command_pool().meter, 8.0)
	host.credit_move_hit(id, 1, 1, 2.0, "opponent", 200.0, 1, 100.0)
	assert_eq(_command_pool().meter, 8.0)
	assert_true(host.move_commit(id, 1, 1).command_meter_credited)
	var changed := _admitted()
	changed.equipment.backpack = "invented-backpack"
	host.bind_tether_commands(id, 1, changed)
	assert_eq(_command_pool().tier, 0)
	assert_true(host.join(id, 2, "creature_b", "owner_b").ok)
	assert_true(host.leave(id, 1).ok)
	assert_true(host.join(id, 3, "creature_a", "owner_a").ok)
	assert_eq(host.encounters[id].participants[3].tether_commands.meter, 8.0)

func test_rally_spends_once_affects_only_owner_and_splits_wind_at_expiry() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	assert_true(_start(1).ok)
	assert_true(host.join(id, 2, "creature_b", "owner_b").ok)
	host.bind_tether_commands(id, 2, _admitted("owner_b"))
	_command_pool().meter = 100.0 # Meter setup, actual command commit below.
	var request := COMMANDS.intent(id, 1, 1, "rally")
	var verdict: Dictionary = host.commit_tether_command(request, 1, _command_view(), 2000)
	assert_true(verdict.ok, str(verdict))
	assert_eq(_command_pool().meter, 50.0)
	assert_false(host.commit_tether_command(request, 1, _command_view(), 2001).ok)
	assert_eq(_command_pool().meter, 50.0)
	assert_eq(host.tether_rally(id, 1, 7999).damage, 1.1)
	assert_eq(host.tether_rally(id, 2, 7999).damage, 1.0)
	assert_eq(host.tether_rally(id, 1, 8000).damage, 1.0)
	var pool: Dictionary = host.encounters[id].participants[1].move_resources.creature_a
	pool.wind = 0.0
	pool.wind_updated_ms = 7000
	pool.wind_ready_at_ms = 7000
	var profile := {"creature_uid": "creature_a", "max": 100.0, "regen_per_second": 10.0}
	assert_eq(host.preview_wind(id, 1, profile, 0.0, 9000).wind, 22.5)
	var forged := _command_view()
	forged.actor.character_id = "owner_b"
	assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 2, "rally"), 1, forged, 10000).ok)

func test_snare_canonical_status_has_one_shared_slow_and_own_catch_grant() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	assert_true(_start(1).ok)
	_command_pool().meter = 100.0
	for defect: String in ["trainer", "boss", "geometry", "generation"]:
		var view := _command_view()
		match defect:
			"trainer": view.target.trainer_owned = true
			"boss": view.target.snare_immune = true
			"geometry": view.snare_geometry_connected = false
			"generation": view.actor.generation = 2
		assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 1, "snare"), 1, view, 2000).ok, defect)
		assert_eq(_command_pool().meter, 100.0)
	var verdict: Dictionary = host.commit_tether_command(COMMANDS.intent(id, 1, 1, "snare"), 1, _command_view(), 2000)
	assert_true(verdict.ok, str(verdict))
	assert_eq(_command_pool().meter, 40.0)
	assert_eq(host.record(id).opponent.hp, 200.0, "trainer command never damages")
	var status: Dictionary = host.record(id).opponent.tether_snare
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_a", 4999).catch_bonus, 0.1)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_b", 4999).catch_bonus, 0.0)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_b", 4999).movement, 0.6)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 2, "owner_a", 4999).movement, 1.0)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_a", 5000).movement, 1.0)
	assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 2, "tag_combo"), 1, _command_view(), 2500).ok)
	assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 2, "item_throw"), 1, _command_view(), 2500).ok)

func test_equipped_authored_pouches_bind_each_upgrade_on_the_same_participant() -> void:
	var ids := ["", "rootiron_command_pouch", "tidesteel_command_pouch", "skyglass_command_pouch", "stormglass_command_pouch"]
	for tier: int in 5:
		var authority := HOST.new(1)
		var record: Dictionary = authority.open(1, "meadows", "wild", {"hp": 100.0, "hp_max": 100.0}, "creature_a", "owner_a")
		var admitted := _admitted()
		admitted.equipment.backpack = ids[tier]
		authority.bind_tether_commands(record.encounter_id, 1, admitted)
		assert_eq(authority.record(record.encounter_id).participants[1].tether_commands.tier, tier)
		var profile := COMMANDS.tier_profile(tier)
		assert_true(float(profile.meter_rate) >= 1.0)
		assert_true(int(profile.pouch_size) >= 1 and int(profile.pouch_size) <= 3)

func test_rally_can_commit_on_current_owned_deployment_before_its_first_move() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	assert_true(_start(1).ok)
	_command_pool().meter = 100.0
	var current := _command_view()
	current.actor.creature_uid = "creature_b"
	current.actor.generation = 2
	assert_true(host.commit_tether_command(COMMANDS.intent(id, 2, 1, "rally"), 1, current, 2000).ok)
	var binding := _binding("creature_b")
	binding.deployment_generation = 2
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 2, "slot": "quick"}, 1, _owned("creature_b"), binding, _move(), WIND, 3000).ok)
	assert_eq(host.encounters[id].participants[1].move_resources.creature_b.tether_rally_until_ms, 8000)

func test_every_joint_damage_event_is_attributed_to_one_of_the_two_owned_creatures() -> void:
	var target := {"uid": "opponent", "generation": 1, "hp": 200.0, "hostile": true,
		"position": Vector3(2, 0, 0), "defence": 10.0, "type": "Ground", "secondary_type": ""}
	var actors: Array = []
	var moves: Array = []
	for index: int in 2:
		var uid := "creature_a" if index == 0 else "creature_b"
		var actor := {"character_id": "owner_a", "encounter_id": id, "creature_uid": uid,
			"generation": index + 1, "action": index + 1, "hp": 100.0, "attack": 20.0, "position": Vector3.ZERO,
			"facing": Vector3.RIGHT, "bonus_product": 1.0}
		actors.append(actor)
		var frozen := MASTERY.freeze_action(MASTERY.owned_record(_owned(uid)), "quick", actor, [], MOVES.load_default())
		assert_true(frozen.ok, str(frozen))
		if not frozen.ok: return
		moves.append(MANAGER.host_move_profile(MOVES.load_default(), "player_quick", "pebble_toss", 0.5, 0.5, 1.0, 0.0, frozen.move))
	var effect := {"kind": "tag_combo", "character_id": "owner_a", "encounter_id": id,
		"target_uid": target.uid, "target_generation": target.generation,
		"strikes": [COMMANDS.joint_strike(actors[0], target, "joint-original", "outgoing", 0.5),
			COMMANDS.joint_strike(actors[1], target, "joint-original", "incoming", 1.5)]}
	var view := {"actors": actors, "rolls": [0.5, 0.5], "target": target}
	var plan := COMMANDS.stage_joint_attack(effect, moves, view, preload("res://scripts/combat/combat_math.gd").config())
	assert_true(plan.ok, str(plan))
	if not plan.ok: return
	assert_eq(plan.strikes.size(), 2)
	for strike: Dictionary in plan.strikes:
		assert_true(float(strike.actual_hp_debit) > 0.0)
		assert_eq(strike.source_kind, "creature")
		assert_true(["creature_a", "creature_b"].has(strike.attacker_uid))
		assert_eq(strike.character_id, "owner_a")
		assert_eq(strike.parent_action_id, "joint-original")
	var forged := effect.duplicate(true)
	forged.strikes[0].source_kind = "trainer"
	assert_false(COMMANDS.stage_joint_attack(forged, moves, view, preload("res://scripts/combat/combat_math.gd").config()).ok)
	view.actors[1].character_id = "owner_b"
	assert_false(COMMANDS.stage_joint_attack(effect, moves, view, preload("res://scripts/combat/combat_math.gd").config()).ok)
