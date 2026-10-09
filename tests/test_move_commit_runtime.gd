extends "res://tests/test_case.gd"

const HOST := preload("res://scripts/combat/accepted_action_host.gd")
const LEGACY_ACTOR_MATH := preload("res://scripts/combat/combat_math.gd")
const WIND := {"max": 100.0, "regen_per_second": 18.0}
var host: RefCounted
var id := ""
var _saved_legacy_actor_config: Dictionary

func before_each() -> void:
	# Detached legacy resource mechanics: generation zero, no bound actor.
	# Tracked-ON production admission is a separate gameplay proof.
	_saved_legacy_actor_config = LEGACY_ACTOR_MATH.config().actor_vitals
	LEGACY_ACTOR_MATH.config().actor_vitals = _saved_legacy_actor_config.duplicate(true)
	LEGACY_ACTOR_MATH.config().actor_vitals.runtime_enabled = false
	host = HOST.new(1)
	var rec: Dictionary = host.open(1, "meadows", "wild", {
		"species_id": "bramblebun", "hp": 200.0, "hp_max": 200.0,
		"position": [2.0, 0.0, 0.0]}, "creature_a", "owner_a")
	id = rec.encounter_id

func after_each() -> void:
	LEGACY_ACTOR_MATH.config().actor_vitals = _saved_legacy_actor_config

func _owned(uid: String = "creature_a") -> Dictionary:
	return {"uid": uid, "hp": 100.0, "fainted": false,
		"known_moves": ["pebble_toss", "earth_rend"], "move_quick": "pebble_toss", "move_charged": "earth_rend"}

func _binding(uid: String = "creature_a") -> Dictionary:
	return {"character_id": "owner_a", "creature_uid": uid, "deployment_generation": 1,
		"body_instance_id": 51, "actor_generation": 0}

func _move(slot: String = "quick") -> Dictionary:
	return {"move_id": "pebble_toss" if slot == "quick" else "earth_rend", "slot": slot,
		"range": 3.0, "cone_degrees": 100.0, "power": 9.0, "windup": 0.3, "recovery": 0.2,
		"cooldown": 1.0, "wind_cost": 12.0 if slot == "quick" else 35.0,
		"energy_cost": 0.0 if slot == "quick" else 100.0, "energy_gain": 26.0}

func _start(action: int, now: int = 1000, uid: String = "creature_a", slot: String = "quick") -> Dictionary:
	return host.authorize_move_start({"encounter_id": id, "action": action, "slot": slot},
		1, _owned(uid), _binding(uid), _move(slot), WIND, now)

func _arrive(action: int, now: int = 1300, binding: Dictionary = {}) -> Dictionary:
	var start: Dictionary = host.move_commit(id, 1, action)
	return host.validate_strike({"encounter_id": id, "action": action, "slot": start.slot,
		"move_id": start.move_id, "move": start.move, "facing": Vector3.RIGHT}, 1,
		{"now_ms": now, "origin": Vector3.ZERO, "bodies": [],
		"move_actor_binding": start.binding if binding.is_empty() else binding})

func test_start_spends_once_and_impact_cannot_run_early_or_repeat() -> void:
	assert_true(_start(1).ok)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_a").wind, 88.0)
	assert_false(_start(1).ok)
	assert_false(_arrive(1, 1299).ok)
	assert_true(_arrive(1).ok)
	assert_false(_arrive(1, 1301).ok)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_a").wind, 88.0)

func test_meters_require_positive_debit_and_credit_one_actual_action_once() -> void:
	assert_true(_start(1).ok)
	assert_true(host.credit_move_hit(id, 1, 1, 10.0).is_empty())
	assert_true(_arrive(1).ok)
	assert_true(host.credit_move_hit(id, 1, 1, 0.0).is_empty())
	var credited: Dictionary = host.credit_move_hit(id, 1, 1, 10.0)
	assert_eq(credited.energy, 26.0)
	assert_eq(credited.ultimate_meter, 6.0)
	assert_true(host.credit_move_hit(id, 1, 1, 10.0).is_empty())

func test_wrong_move_or_body_lifetime_cannot_arrive() -> void:
	assert_true(_start(1).ok)
	var changed := _binding()
	changed.deployment_generation = 2
	assert_false(_arrive(1, 1300, changed).ok)
	var start: Dictionary = host.move_commit(id, 1, 1)
	var intent := {"encounter_id": id, "action": 1, "slot": "charged", "move_id": "earth_rend",
		"move": start.move, "facing": Vector3.RIGHT}
	assert_false(host.validate_strike(intent, 1, {"now_ms": 1300, "origin": Vector3.ZERO,
		"bodies": [], "move_actor_binding": start.binding}).ok)
	assert_true(_arrive(1).ok)

func test_charged_refusal_has_no_cost_and_does_not_replace_original() -> void:
	assert_true(_start(1).ok)
	assert_true(_arrive(1).ok)
	host.credit_move_hit(id, 1, 1, 10.0)
	var before: Dictionary = host.record(id).duplicate(true)
	assert_eq(_start(2, 2200, "creature_a", "charged").code, "insufficient_energy")
	assert_eq(host.record(id), before)
	assert_eq(host.move_commit(id, 1).action, 1)

func test_switch_retains_each_creatures_resources_and_cooldown() -> void:
	assert_true(_start(1).ok)
	assert_true(_arrive(1).ok)
	host.credit_move_hit(id, 1, 1, 10.0)
	assert_true(_start(2, 1500, "creature_b").ok)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_b").energy, 0.0)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_a").energy, 26.0)
	assert_eq(_start(3, 1999).code, "recovering")
	assert_true(_start(3, 2000).ok)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_a").energy, 26.0)

func test_admission_refuses_unknown_loadout_without_any_mutation() -> void:
	var owned := _owned()
	owned.known_moves = []
	var before: Dictionary = host.record(id).duplicate(true)
	assert_false(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "quick"},
		1, owned, _binding(), _move(), WIND, 1000).ok)
	assert_eq(host.record(id), before)

func test_unsaved_mastery_and_resources_survive_peer_replacement_and_close() -> void:
	assert_true(host.join(id, 2, "creature_b", "owner_b").ok)
	assert_true(_start(1).ok)
	assert_true(_arrive(1).ok)
	host.credit_move_hit(id, 1, 1, 10.0, "opponent_a", 200.0)
	var original: Dictionary = host.move_mastery_outcome(id, 1, 1)
	assert_eq(original.outcome.applied_damage, 10.0)
	assert_eq(host.pending_move_mastery().size(), 1)
	assert_true(host.leave(id, 1).ok)
	assert_eq(host.pending_move_mastery()[0].peer, "owner_a")
	assert_eq(host.move_mastery_outcome(id, "owner_a", 1).outcome, original.outcome)
	assert_true(host.join(id, 3, "creature_a", "owner_a").ok)
	assert_eq(host.move_resource_snapshot(id, 3, "creature_a").energy, 26.0)
	assert_eq(host.pending_move_mastery()[0].peer, 3)
	host.close(id)
	host.forget(id)
	assert_false(host.record(id).is_empty(), "unsaved landed use fences source disposal")
	assert_false(host.acknowledge_move_mastery(id, 3, 1, "wrong-original"))
	assert_true(host.acknowledge_move_mastery(id, 3, 1, original.outcome.action_id))
	assert_true(host.pending_move_mastery().is_empty())
	host.forget(id)
	assert_true(host.record(id).is_empty())

func test_idle_wind_ticks_each_uid_and_switched_burst_spends_current_creature() -> void:
	assert_true(_start(1).ok)
	assert_true(_arrive(1).ok)
	var profile: Dictionary = WIND.duplicate()
	profile["creature_uid"] = "creature_b" # The director resolves this from its actual deployed body.
	var burst: Dictionary = host.authorize_burst(id, 1, {"action": 2, "direction": [1.0, 0.0, 0.0]},
		profile, 30.0, 1500, 3.0, 0.2, 0.6)
	assert_true(burst.ok)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_a").wind, 88.0)
	assert_eq(host.move_resource_snapshot(id, 1, "creature_b").wind, 70.0)
	host.advance_wind(id, 2500)
	assert_almost_eq(host.move_resource_snapshot(id, 1, "creature_a").wind, 95.2, 0.001)
	assert_almost_eq(host.move_resource_snapshot(id, 1, "creature_b").wind, 73.6, 0.001)
	assert_true(_start(3, 2500, "creature_b").ok)
	assert_almost_eq(host.move_resource_snapshot(id, 1, "creature_b").wind, 61.6, 0.001,
		"burst and subsequent attack consume the same UID pool")
	var commands := preload("res://scripts/combat/tether_commands.gd")
	var previous: Dictionary = commands.config()
	commands._config = previous.duplicate(true)
	commands._config.feature_flags.runtime_enabled = true
	var manager := preload("res://scripts/combat/combat_manager.gd").new()
	var throw_aim := preload("res://scripts/combat/throw_aim.gd").new()
	manager._throw = throw_aim
	var species := preload("res://scripts/creatures/creature_species.gd")
	var first := species.spawn("terrapup")
	var second := species.spawn("terrapup")
	first.energy = 23.0
	second.energy = 35.0
	manager._party = [first, second]
	manager._party_wind = [70.0, 60.0]
	manager._party_wind_quiet = [0.0, 0.0]
	manager._party_ultimate = {str(first.uid):20.0, str(second.uid):30.0}
	manager._quick_cooldown = 0.8
	manager._charged_cooldown = 1.4
	manager._player_poise = 7.0
	manager._player_poise_quiet_left = 3.0
	manager._player_stagger_critical_ready = true
	manager._activate_party_member(1)
	assert_eq(manager._party_wind, [70.0, 60.0], "switch never refills Wind")
	manager._quick_cooldown = 0.2
	manager._charged_cooldown = 0.6
	manager._player_poise = 9.0
	manager._player_poise_quiet_left = 4.0
	manager._input_guard = 10.0
	manager._tick_active(0.25)
	var wind_after_tick: Array = manager._party_wind.duplicate()
	manager._activate_party_member(0)
	assert_almost_eq(manager._quick_cooldown, 0.55, 0.0001)
	assert_almost_eq(manager._charged_cooldown, 1.15, 0.0001)
	assert_eq(manager._player_poise, 7.0, "return restores the actual UID's poise")
	assert_almost_eq(manager._player_poise_quiet_left, 2.75, 0.0001)
	assert_true(manager._player_stagger_critical_ready)
	assert_eq(manager._party_wind, wind_after_tick)
	assert_eq(manager._party_ultimate, {str(first.uid):20.0, str(second.uid):30.0})
	assert_eq(first.energy, 23.0)
	assert_eq(second.energy, 35.0)
	manager._activate_party_member(1)
	assert_almost_eq(manager._quick_cooldown, 0.0, 0.0001)
	assert_almost_eq(manager._charged_cooldown, 0.35, 0.0001)
	assert_eq(manager._player_poise, 9.0)
	manager.free()
	throw_aim.free()
	commands._config = previous


func test_f33_charm_gain_frozen_in_the_accepted_action_scales_the_meter_once_and_is_capped() -> void:
	# F33: the host freezes the owner's Charm into the accepted move
	# (encounter_director `_host_move_start` -> creature_gear.freeze_move_profile);
	# the landed credit multiplies the ordinary gain by it, bounded by the
	# gear.json cap. Nothing else changes.
	var gear := preload("res://scripts/creatures/creature_gear.gd")
	var cap := float(gear.config().limits.ultimate_gain_multiplier_cap)
	var charmed := gear.freeze_move_profile(_move("quick"), {"harness": "", "charm": "skyglass_charm_plus_3"}, gear.config())
	assert_true(float(charmed.gear_ultimate_gain_multiplier) > 1.0, "a Charm raises ultimate gain")
	assert_true(float(charmed.power_multiplier) > 1.0, "and move power, in the same frozen action")
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "quick"},
		1, _owned(), _binding(), charmed, WIND, 1000).ok)
	assert_true(_arrive(1).ok)
	var credited: Dictionary = host.credit_move_hit(id, 1, 1, 10.0)
	assert_almost_eq(float(credited.ultimate_meter), 6.0 * minf(float(charmed.gear_ultimate_gain_multiplier), cap), 0.0001)
	assert_true(host.credit_move_hit(id, 1, 1, 10.0).is_empty(), "still credited once")
	var forged := _move("quick")
	forged["gear_ultimate_gain_multiplier"] = 50.0
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 2, "slot": "quick"},
		1, _owned(), _binding(), forged, WIND, 2000).ok)
	assert_true(_arrive(2, 2300).ok)
	var before := float(host.move_resource_snapshot(id, 1, "creature_a").ultimate_meter)
	var capped: Dictionary = host.credit_move_hit(id, 1, 2, 10.0)
	assert_almost_eq(float(capped.ultimate_meter) - before, 6.0 * cap, 0.0001, "never above the gear.json cap")


func test_f33_no_charm_keeps_the_ordinary_gain_and_power() -> void:
	var gear := preload("res://scripts/creatures/creature_gear.gd")
	var plain := gear.freeze_move_profile(_move("quick"), gear.empty_slots(), gear.config())
	assert_eq(float(plain.power_multiplier), 1.0)
	assert_eq(float(plain.gear_ultimate_gain_multiplier), 1.0)
	assert_true(_start(1).ok)
	assert_true(_arrive(1).ok)
	assert_eq(host.credit_move_hit(id, 1, 1, 10.0).ultimate_meter, 6.0)


func test_new_system_hud_never_exposes_unadmitted_or_foreign_uid_resources() -> void:
	var commands := preload("res://scripts/combat/tether_commands.gd")
	var previous: Dictionary = commands.config()
	commands._config = previous.duplicate(true)
	commands._config.feature_flags.ui_enabled = true
	var manager := preload("res://scripts/combat/combat_manager.gd").new()
	manager._moves = preload("res://scripts/creatures/move_db.gd").load_default()
	var species := preload("res://scripts/creatures/creature_species.gd")
	var first: RefCounted = species.spawn("terrapup")
	var second: RefCounted = species.spawn("ripplet")
	manager._party.assign([first, second])
	manager._active_index = 0
	manager._apply_move_resources({"creature_uid":first.uid, "ultimate_meter":36.0, "energy":26.0})
	var before: Dictionary = manager._party_ultimate.duplicate(true)
	assert_eq(manager.new_system_combat_snapshot(), {"active":false}, "idle HUD stays hidden")
	manager.state = manager.State.ACTIVE
	assert_eq(manager.new_system_combat_snapshot(), {"active":false}, "resources alone cannot impersonate admitted deployment")
	# Detached production deployment/resource projection, not a played fight.
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	director._deployment_identity = {1:{"character_id":"owner_a", "creature_uid":first.uid, "generation":1}}
	manager._encounter_link = director
	manager._encounter_id = id
	manager._tether_command_view = {"encounter_id":id, "character_id":"owner_a", "meter":25.0}
	manager._initialize_wind()
	var view: Dictionary = manager.new_system_combat_snapshot()
	assert_true(view.get("active") == true)
	assert_eq(view.get("ultimate_meter"), 36.0)
	assert_false(view.get("ultimate_available", true), "shipping flag-off ultimate is never presented as available")
	assert_eq(view.get("creature_uid"), first.uid)
	view.commands.meter = 100.0
	assert_eq(manager._tether_command_view.meter, 25.0, "returned command view cannot mutate the manager")
	manager._tether_command_view.encounter_id = "prior-encounter"
	assert_eq(manager.new_system_combat_snapshot(), {"active":false}, "prior encounter cannot supply a current view")
	manager._tether_command_view.encounter_id = id
	manager._active_index = 1
	assert_eq(manager.new_system_combat_snapshot(), {"active":false}, "switch never exposes the previous creature's acknowledged meter")
	director._deployment_identity[1].creature_uid = second.uid
	assert_eq(manager.new_system_combat_snapshot(), {"active":false}, "new UID waits for its own acknowledged pool")
	assert_eq(manager._party_ultimate, before, "HUD reads never transfer or spend a pool")
	manager._apply_move_resources({"creature_uid":"foreign-creature", "ultimate_meter":100.0})
	assert_eq(manager._party_ultimate, before, "foreign UID cannot populate the owner's displayed resources")
	assert_eq(first.energy, 26.0)
	assert_eq(second.energy, 0.0)
	director.free()
	manager.free()
	commands._config = previous

func test_accepted_manager_windup_waits_for_real_time_despite_physics_catchup() -> void:
	var manager := preload("res://scripts/combat/combat_manager.gd").new()
	var frozen := _move()
	frozen["accepted_action"] = 1
	var received_ms := Time.get_ticks_msec()
	manager.call("_begin_move_presentation", frozen)
	var deadline := int(manager.get("_accepted_strike_not_before_ms"))
	assert_true(deadline >= received_ms + 300, "the frozen duration is a local real-time floor")
	assert_eq(manager.get("_pending_move"), frozen, "timing does not rewrite the accepted profile")
	manager.call("_tick_action", 10.0)
	assert_eq(int(manager.get("_action")), 1, "accelerated physics leaves the accepted move in WINDUP")
	while Time.get_ticks_msec() < deadline:
		OS.delay_msec(1)
	manager.call("_tick_action", 0.0)
	assert_eq(int(manager.get("_action")), 2, "the original strike boundary proceeds after the floor")
	assert_almost_eq(float(manager.get("_action_timer")), float(frozen.recovery), 0.0001,
		"the full original recovery follows the strike")
	manager.call("_tick_action", 0.0)
	assert_eq(int(manager.get("_action")), 2, "no duplicate strike at the elapsed deadline")
	manager.call("_tick_action", float(frozen.recovery))
	assert_eq(int(manager.get("_action")), 0)
	frozen.erase("accepted_action")
	manager.call("_begin_move_presentation", frozen)
	assert_eq(int(manager.get("_accepted_strike_not_before_ms")), 0, "offline actions reset the fence")
	manager.call("_tick_action", 10.0)
	assert_eq(int(manager.get("_action")), 2, "offline wind-up retains delta timing")
	manager.free()
