extends SceneTree

## Minimal live scene fixture, not a full forest or two-peer acceptance run.
const CASES := preload("res://tests/helpers/stormwood_lightning_cases.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var cases := CASES.new()
	var methods := {
		"test_host_resolver_only_hits_actors_still_inside_three_metres": 6,
		"test_safe_ground_policy_refuses_ashfoot_and_accepts_open_deepwood": 2,
		"test_session_refuses_client_publication": 2,
		"test_duplicate_impact_id_does_not_damage_twice": 2,
		"test_real_worn_vest_reduces_damage_and_static_duration": 3,
		"test_full_worn_set_keeps_stagger_but_adds_no_damage_or_static": 3,
		"test_unequipping_one_piece_removes_full_set_immunity": 3,
		"test_remote_addressed_impact_does_not_use_local_gear_or_vitals": 2,
		"test_mitigation_applies_after_low_max_health_damage_cap": 1,
	}
	for method: String in methods:
		var before := cases.assertion_count
		cases.before_each()
		cases.call(method)
		cases.after_each()
		if cases.assertion_count - before != int(methods[method]):
			cases.failures.append("Case did not execute its complete assertions: " + method)
	for failure: String in cases.failures:
		push_error(failure)
	print("STORMWOOD LIGHTNING FIXTURE: assertions=", cases.assertion_count, " failures=", cases.failures.size())
	quit(0 if cases.failures.is_empty() else 1)
