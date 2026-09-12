extends "res://tests/test_case.gd"

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")


class DummyEnemy extends RefCounted:
	var hp := 100.0
	var max_hp := 100.0


func test_poise_tuning_is_complete_and_safe() -> void:
	var poise: Dictionary = MATH.config().get("poise", {})
	assert_true(float(poise.get("max", 0.0)) > 0.0)
	assert_true(float(poise.get("regen_delay", 0.0)) > 0.0)
	assert_true(float(poise.get("regen_per_second", 0.0)) > 0.0)
	assert_true(float(poise.get("stagger_seconds", 0.0)) >= 0.5)
	assert_almost_eq(float(poise.get("crit_scale", 0.0)), 1.5, 0.001)
	assert_true(bool(poise.get("interrupt_on_charged_into_telegraph", false)))


func test_a_hit_during_player_windup_cancels_the_committed_swing() -> void:
	var manager := MANAGER.new()
	manager.call("_reset_player_poise")
	manager.set("_action", MANAGER.Action.WINDUP)
	manager.set("_action_timer", 0.4)
	manager.set("_pending_move", {"power": 38.0})
	manager.set("_buffered_attack", "quick")
	manager.set("_buffer_left", 0.3)

	var staggered_now: bool = manager.call("_take_player_poise_damage", 1.0)
	assert_false(staggered_now, "an ordinary nick should interrupt without emptying full poise")
	assert_eq(int(manager.get("_action")), MANAGER.Action.READY)
	assert_true((manager.get("_pending_move") as Dictionary).is_empty(), "cancelled move cannot resolve later")
	assert_eq(str(manager.get("_buffered_attack")), "", "mashing during the lost swing cannot auto-restart it")
	assert_almost_eq(float(manager.get("_action_timer")), 0.0, 0.001)
	manager.free()


func test_empty_player_poise_roots_then_arms_exactly_one_critical() -> void:
	var manager := MANAGER.new()
	manager.call("_reset_player_poise")
	var broke: bool = manager.call("_take_player_poise_damage", 1000.0)
	assert_true(broke)
	assert_eq(int(manager.get("_action")), MANAGER.Action.STAGGER)
	assert_true(bool(manager.call("_consume_player_stagger_critical")))
	assert_false(bool(manager.call("_consume_player_stagger_critical")), "the punish multiplier is spent by one hit")
	manager.free()


func test_wild_poise_break_cancels_telegraph_without_emitting_a_strike() -> void:
	var wild := WILD.new()
	var opponent := Node3D.new()
	wild.set("engaged", true)
	wild.set("_opponent", opponent)
	wild.set("_combat_cfg", MATH.config().get("enemy", {}).duplicate(true))
	wild.call("_reset_poise")
	wild.set("_intent", AI.Intent.TELEGRAPH)
	wild.set("_beat_left", 0.4)
	var strikes := [0]
	wild.strike_ready.connect(func() -> void: strikes[0] += 1)

	assert_true(bool(wild.apply_poise_damage(0.0, true)))
	assert_true(wild.is_staggered())
	assert_false(wild.is_winding_up(), "stagger replaces the telegraph before its strike edge")
	assert_eq(int(wild.intent()), AI.Intent.RECOVER)
	assert_eq(strikes[0], 0, "cancelling a telegraph must never resolve its blow")
	assert_true(wild.consume_stagger_critical())
	assert_false(wild.consume_stagger_critical())
	wild.free()
	opponent.free()


func test_wild_poise_regenerates_only_after_the_quiet_delay() -> void:
	var wild := WILD.new()
	var opponent := Node3D.new()
	wild.set("engaged", true)
	wild.set("_opponent", opponent)
	wild.set("_combat_cfg", MATH.config().get("enemy", {}).duplicate(true))
	wild.call("_reset_poise")
	wild.apply_poise_damage(10.0)
	var hurt_fraction := wild.poise_fraction()
	wild.call("_tick_poise", 1.0)
	assert_almost_eq(wild.poise_fraction(), hurt_fraction, 0.001)
	wild.call("_tick_poise", 1.1)
	assert_true(wild.poise_fraction() > hurt_fraction, "poise starts refilling after two seconds without a hit")
	wild.free()
	opponent.free()


func test_hitstop_uses_the_three_authored_beats() -> void:
	var manager := MANAGER.new()
	assert_almost_eq(float(manager.call("_hitstop_seconds", true, false)), 0.03, 0.001)
	assert_almost_eq(float(manager.call("_hitstop_seconds", false, false)), 0.07, 0.001)
	assert_almost_eq(float(manager.call("_hitstop_seconds", true, true)), 0.12, 0.001)
	manager.free()


func test_host_record_stamps_hp_and_break_state_atomically() -> void:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {
		"species_id": "bramblebun", "hp": 100.0, "hp_max": 100.0,
	})
	var encounter_id := str(record.get("encounter_id", ""))
	host.set_opponent_hp(encounter_id, 82.0, 100.0, {
		"poise": 0.0, "poise_max": 40.0, "staggered": true,
		"critical_ready": true, "stagger_left": 0.55,
	})
	var opponent: Dictionary = (host.record(encounter_id) as Dictionary).get("opponent", {})
	assert_almost_eq(float(opponent.get("hp", -1.0)), 82.0, 0.001)
	assert_almost_eq(float(opponent.get("poise", -1.0)), 0.0, 0.001)
	assert_almost_eq(float(opponent.get("poise_max", -1.0)), 40.0, 0.001)
	assert_true(bool(opponent.get("staggered", false)))
	assert_true(bool(opponent.get("critical_ready", false)))
	assert_almost_eq(float(opponent.get("stagger_left", -1.0)), 0.55, 0.001)


func test_observer_record_applies_authoritative_stagger_once() -> void:
	var manager := MANAGER.new()
	var link := Node.new()
	var wild := WILD.new()
	wild.set("engaged", true)
	wild.set("_combat_cfg", MATH.config().get("enemy", {}).duplicate(true))
	wild.call("_reset_poise")
	var enemy := DummyEnemy.new()
	manager.set("_encounter_link", link)
	manager.set("_encounter_id", "fight-1")
	manager.set("_encounter_seq", 1)
	manager.set("_wild", wild)
	manager.set("_enemy", enemy)
	var announcements := [0]
	manager.staggered.connect(func(on_enemy: bool) -> void:
		if on_enemy:
			announcements[0] += 1)
	var record := {"encounter_id": "fight-1", "seq": 2, "phase": "active", "opponent": {
		"hp": 90.0, "hp_max": 100.0, "poise": 0.0, "poise_max": 40.0,
		"staggered": true, "critical_ready": true, "stagger_left": 0.45,
	}}
	manager.apply_encounter_record(record)
	assert_true(wild.is_staggered())
	assert_almost_eq(wild.poise_fraction(), 0.0, 0.001)
	assert_almost_eq(wild.stagger_seconds_left(), 0.45, 0.001)
	assert_eq(announcements[0], 1)
	manager.apply_encounter_record(record)
	assert_eq(announcements[0], 1, "a duplicate authoritative record cannot announce stagger twice")
	manager.free()
	wild.free()
	link.free()


func test_strike_authors_record_sync_quietly_before_their_verdict() -> void:
	var manager := MANAGER.new()
	var link := Node.new()
	var wild := WILD.new()
	wild.set("engaged", true)
	wild.set("_combat_cfg", MATH.config().get("enemy", {}).duplicate(true))
	wild.call("_reset_poise")
	manager.set("_encounter_link", link)
	manager.set("_encounter_id", "fight-2")
	manager.set("_wild", wild)
	manager.set("_enemy", DummyEnemy.new())
	var announcements := [0]
	manager.staggered.connect(func(_on_enemy: bool) -> void: announcements[0] += 1)
	manager.apply_encounter_record({"encounter_id": "fight-2", "seq": 1,
		"phase": "active", "opponent": {"hp": 90.0, "hp_max": 100.0,
			"poise": 0.0, "staggered": true, "critical_ready": true,
			"stagger_left": 0.5}}, true)
	assert_true(wild.is_staggered(), "quiet affects presentation, never authoritative state")
	assert_eq(announcements[0], 0, "the richer strike verdict owns the author's one announcement")
	manager.free()
	wild.free()
	link.free()
