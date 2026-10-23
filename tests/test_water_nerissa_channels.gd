extends "res://tests/test_case.gd"

## BOSSES §4.11 Channel Cycle / Pressure Rise, as rules: cadence per phase,
## once-per-wave 10% max-HP damage, the full-tell exit test, no wave over a
## creature tell, sides, and the safe half of the chamber.

const RULES := preload("res://scripts/world/water_nerissa_channel_rules.gd")


func _rules() -> RefCounted:
	return RULES.new(RULES.load_config().duplicate(true))


## Steps the rules in 0.05 s ticks until `want` is returned (or `limit` s pass);
## returns the elapsed time at that transition.
func _run_until(rules: RefCounted, want: String, limit: float = 30.0, tell: bool = false,
		ally := Vector2(5.0, 0.0), creatures: Dictionary = {}, outer_legal: Dictionary = {}) -> float:
	var t := 0.0
	while t < limit:
		t += 0.05
		if str(rules.call("advance", 0.05, tell, ally, creatures, outer_legal)) == want:
			return t
	return -1.0


func test_phases_follow_the_roster() -> void:
	var cfg := RULES.load_config()
	assert_eq(RULES.phase_for(cfg, 0), "channel_cycle", "Cannonback fights in Channel Cycle")
	assert_eq(RULES.phase_for(cfg, 1), "channel_cycle", "Mirejaw fights in Channel Cycle")
	assert_eq(RULES.phase_for(cfg, 2), "pressure_rise", "Pressure Rise begins with Riverdrake")
	assert_eq(RULES.phase_for(cfg, 3), "", "Riptusk (Break Tether) fights without sweeps")
	assert_false(bool(cfg.get("enabled", true)), "the sweeps ship OFF until judged")


func test_channel_cycle_cadence_is_bosses_exact() -> void:
	var rules := _rules()
	rules.call("set_send_out", 0)
	var announce := _run_until(rules, "announce")
	assert_true(announce > 0.0, "a wave is announced")
	var fire := _run_until(rules, "fire")
	assert_almost_eq(fire, 1.2, 0.051, "Channel Cycle announces for 1.2 s")
	var drain := _run_until(rules, "drain")
	assert_almost_eq(drain, 0.8, 0.051, "and stays active 0.8 s")
	var idle := _run_until(rules, "idle")
	assert_almost_eq(idle, 1.6, 0.051, "then drains 1.6 s")


func test_pressure_rise_cadence_and_alternation() -> void:
	var rules := _rules()
	rules.call("set_send_out", 2)
	assert_eq(str(rules.call("phase")), "pressure_rise", "Riverdrake runs Pressure Rise")
	_run_until(rules, "announce")
	var first := int(rules.get("side"))
	assert_almost_eq(_run_until(rules, "fire"), 1.0, 0.051, "Pressure Rise announces for 1.0 s")
	assert_almost_eq(_run_until(rules, "drain"), 0.8, 0.051, "active 0.8 s")
	assert_almost_eq(_run_until(rules, "idle"), 1.2, 0.051, "recovery 1.2 s")
	_run_until(rules, "announce")
	assert_eq(int(rules.get("side")), -first, "Pressure Rise alternates sides")


func test_channel_cycle_announces_on_the_allys_side() -> void:
	var rules := _rules()
	rules.call("set_send_out", 0)
	_run_until(rules, "announce", 30.0, false, Vector2(-5.0, 0.0))
	assert_eq(int(rules.get("side")), -1, "the first sweep is on the piloted creature's side")
	_run_until(rules, "announce", 30.0, false, Vector2(-5.0, 0.0))
	assert_eq(int(rules.get("side")), -1, "Channel Cycle does not alternate on its own")


func test_damage_is_ten_percent_once_per_wave_and_only_in_the_lane() -> void:
	var rules := _rules()
	rules.call("set_send_out", 0)
	_run_until(rules, "announce", 30.0, false, Vector2(5.0, 0.0))
	assert_eq(float(rules.call("damage_for", "far", Vector2(5.0, 0.0), 200.0)), 0.0, "no damage while announced")
	_run_until(rules, "fire")
	assert_almost_eq(float(rules.call("damage_for", "a", Vector2(5.0, 0.0), 200.0)), 20.0, 0.001,
		"a struck creature loses 10% of its max HP")
	assert_eq(float(rules.call("damage_for", "b", Vector2(0.0, 0.0), 200.0)), 0.0, "the ring centre is safe")
	assert_eq(float(rules.call("damage_for", "c", Vector2(-5.0, 0.0), 200.0)), 0.0, "the other side is safe")
	_run_until(rules, "drain")
	assert_eq(float(rules.call("damage_for", "a", Vector2(5.0, 0.0), 200.0)), 0.0, "no damage while draining")


func test_full_tell_exit_test_suppresses_damage() -> void:
	var rules := _rules()
	var lane: Dictionary = rules.get("config").lane
	var middle := (float(lane.inner_m) + float(lane.outer_m)) * 0.5
	assert_true(bool(rules.call("can_escape", Vector2(middle, 0.0), 1, true)), "mid-lane at 5.6 m/s gets out in time")
	# A creature pinned against a wall-side lane, with its only exit further
	# than 5.6 m/s x the tell, cannot leave: that wave may not hurt it.
	var wide: Dictionary = rules.get("config").duplicate(true)
	wide.lane.outer_m = float(lane.inner_m) + 20.0
	var trapped := RULES.new(wide)
	trapped.call("set_send_out", 0)
	var stuck := Vector2(float(lane.inner_m) + 15.0, 0.0)
	assert_false(bool(trapped.call("can_escape", stuck, 1, false)), "8+ m from the only legal exit is not escapable in 1.2 s")
	_run_until(trapped, "announce", 30.0, false, stuck, {"stuck": stuck}, {"stuck": false})
	_run_until(trapped, "fire")
	assert_eq(float(trapped.call("damage_for", "stuck", stuck, 200.0)), 0.0, "an unescapable creature takes no damage")
	assert_true(float(trapped.call("damage_for", "other", stuck, 200.0)) > 0.0, "only the exempted creature is spared")


func test_no_wave_over_a_creature_tell() -> void:
	var rules := _rules()
	rules.call("set_send_out", 0)
	assert_eq(_run_until(rules, "announce", 10.0, true), -1.0, "no wave starts while a creature tell runs")
	_run_until(rules, "announce")
	rules.call("advance", 0.05, true, Vector2(5.0, 0.0), {})
	_run_until(rules, "fire")
	assert_eq(float(rules.call("damage_for", "a", Vector2(5.0, 0.0), 200.0)), 0.0,
		"a wave that overlapped a creature tell strikes nobody (no forced combo)")


func test_riptusk_turns_sweeps_off_and_half_the_ring_stays_safe() -> void:
	var rules := _rules()
	rules.call("set_send_out", 2)
	_run_until(rules, "announce")
	rules.call("set_send_out", 3)
	assert_eq(str(rules.get("state")), "off", "Riptusk's send-out stops the sweeps")
	assert_eq(str(rules.call("advance", 5.0, false, Vector2.ZERO, {})), "", "and none restart")
	var lane: Dictionary = rules.get("config").lane
	# The chamber is 42 m across: one lane is at most a third of either half.
	assert_true(float(lane.outer_m) - float(lane.inner_m) <= 42.0 * 0.5 / 3.0 + 0.01,
		"one side channel covers well under half the chamber")
