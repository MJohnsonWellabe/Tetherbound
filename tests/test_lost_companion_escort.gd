extends "res://tests/test_case.gd"

# F03, Juno's lost companion. Beating the Tether patrol frees the stray
# Meadowhart; the ACTIVITY is leading her home to Juno yourself. These are the
# pure decisions the world node (`scripts/world/lost_companion_reunion.gd`)
# makes every frame -- start/refuse, follow, leash, arrival -- plus the data
# joints that make the return, not the patrol win, the counted completion.
# Unit tests have no SceneTree, so everything here is a static rule.

const RULES := preload("res://scripts/world/lost_companion_escort_rules.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const DIALOGUE := preload("res://scripts/story/dialogue_runner.gd")

const CONFIG := "res://data/config/lost_companion_reunion.json"
const OBJECTIVES := "res://data/progression/objectives.json"


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_phase_follows_the_two_world_facts_and_the_live_escort() -> void:
	assert_eq(RULES.phase(false, false, false), RULES.PHASE_HELD, "an unbeaten patrol still holds her")
	assert_eq(RULES.phase(true, false, false), RULES.PHASE_WAITING, "freed but not led home: she waits by the patrol")
	assert_eq(RULES.phase(true, false, true), RULES.PHASE_ESCORTING)
	assert_eq(RULES.phase(true, true, false), RULES.PHASE_REUNITED)
	assert_eq(RULES.phase(true, true, true), RULES.PHASE_REUNITED, "the return fact outranks a stale escort")
	# A legacy/odd save with only the return fact still shows the reunion.
	assert_eq(RULES.phase(false, true, false), RULES.PHASE_REUNITED)


func test_one_tap_starts_an_escort_only_when_she_is_free_and_nobody_else_leads() -> void:
	var ok := RULES.start_verdict(true, false, 0, 7, 3.0, 40.0)
	assert_true(bool(ok.get("ok", false)), "a freed, waiting Meadowhart can be led by the presser")
	var held := RULES.start_verdict(false, false, 0, 7, 3.0, 40.0)
	assert_false(bool(held.get("ok", true)))
	assert_eq(str(held.get("code", "")), "not_freed")
	var home := RULES.start_verdict(true, true, 0, 7, 3.0, 40.0)
	assert_false(bool(home.get("ok", true)))
	assert_eq(str(home.get("code", "")), "returned", "a returned Meadowhart cannot be led again")
	var busy := RULES.start_verdict(true, false, 9, 7, 3.0, 40.0)
	assert_false(bool(busy.get("ok", true)), "only one escort at a time")
	assert_eq(str(busy.get("code", "")), "busy")
	assert_false(str(busy.get("reason", "")).strip_edges().is_empty(), "a refused press says why")
	var again := RULES.start_verdict(true, false, 7, 7, 3.0, 40.0)
	assert_false(bool(again.get("ok", true)), "the leader pressing again is not a second escort")
	assert_eq(str(again.get("code", "")), "already")
	var far := RULES.start_verdict(true, false, 0, 7, 55.0, 40.0)
	assert_false(bool(far.get("ok", true)), "the host refuses a press from beyond the leash")
	assert_eq(str(far.get("code", "")), "far")


func test_leash_and_arrival_are_flat_distances() -> void:
	assert_false(RULES.leash_broken(Vector3(0, 0, 0), Vector3(39.9, 0, 0), 40.0))
	assert_true(RULES.leash_broken(Vector3(0, 0, 0), Vector3(40.1, 0, 0), 40.0))
	assert_false(RULES.leash_broken(Vector3(0, 0, 0), Vector3(0, 90, 10), 40.0), "height does not break the leash")
	assert_true(RULES.arrived(Vector3(0, 0, 0), Vector3(5.9, 0, 0), 6.0))
	assert_false(RULES.arrived(Vector3(0, 0, 0), Vector3(6.1, 0, 0), 6.0))
	assert_true(RULES.arrived(Vector3(0, 0, 0), Vector3(3, 12, 4), 6.0), "arrival ignores height")


func test_escort_cancels_when_the_leader_is_gone_elsewhere_or_too_far() -> void:
	assert_false(RULES.should_cancel(true, "meadows", "meadows", 10.0, 40.0))
	assert_true(RULES.should_cancel(false, "meadows", "meadows", 10.0, 40.0), "a disconnected leader ends it")
	assert_true(RULES.should_cancel(true, "cloudreach", "meadows", 10.0, 40.0), "another realm ends it")
	assert_true(RULES.should_cancel(true, "meadows", "meadows", 41.0, 40.0), "outrunning her ends it")


func test_the_trailing_point_sits_behind_the_leader_at_the_follow_distance() -> void:
	var leader := Vector3(10, 0, 0)
	var creature := Vector3(0, 0, 0)
	var at := RULES.trailing_point(leader, creature, 3.0)
	assert_almost_eq(at.x, 7.0, 0.001, "she trails 3 m behind on her own side")
	assert_almost_eq(at.z, 0.0, 0.001)
	# Already inside the follow distance: she stays put rather than walking into the player.
	var close := RULES.trailing_point(leader, Vector3(8.5, 0, 0), 3.0)
	assert_almost_eq(close.x, 8.5, 0.001)


func test_follow_step_never_outruns_its_speed_or_overshoots() -> void:
	var step := RULES.follow_step(Vector3.ZERO, Vector3(100, 0, 0), 0.1, 9.0, 3.0)
	assert_almost_eq(step.x, 0.9, 0.001, "far behind she moves at the configured top speed")
	var near := RULES.follow_step(Vector3.ZERO, Vector3(0.1, 0, 0), 0.5, 9.0, 3.0)
	assert_true(near.x <= 0.1 + 0.0001, "she never overshoots her trailing point")
	var still := RULES.follow_step(Vector3(1, 0, 1), Vector3(1, 0, 1), 0.1, 9.0, 3.0)
	assert_almost_eq(still.distance_to(Vector3(1, 0, 1)), 0.0, 0.0001)


func test_tunables_live_in_config_and_are_coherent() -> void:
	var config := _config()
	for key: String in ["follow_distance_m", "leash_m", "arrival_radius_m", "prompt_radius_m",
			"max_speed_mps", "catchup_gain"]:
		assert_true(float(config.get(key, 0.0)) > 0.0, "lost_companion_reunion.json lacks positive '%s'" % key)
		assert_true(config.has("_why_" + key), "'%s' has no _why note" % key)
	assert_false(str(config.get("prompt_label", "")).strip_edges().is_empty(), "no escort prompt label")
	assert_true(float(config.get("leash_m", 0.0)) > float(config.get("follow_distance_m", 0.0)) * 3.0,
		"the leash must be well beyond the follow distance")
	assert_true(float(config.get("arrival_radius_m", 0.0)) < float(config.get("leash_m", 0.0)))


func test_the_return_is_the_counted_world_completion() -> void:
	var config := _config()
	var returned := str(config.get("return_flag", ""))
	assert_eq(returned, "lost_creature_rue_returned")
	assert_eq(PROGRESSION_STATE.scope_of(returned), "world", "the return is one world fact")
	assert_eq(str(config.get("defeat_flag", "")), "defeated_lost_creature_rue", "the patrol win still frees her")
	var objective := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES))
	for raw: Variant in ((parsed as Dictionary).get("local", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "band4_lost_creature":
			objective = raw
	assert_eq(str(objective.get("flag_id", "")), returned, "the log completes on the return, not the patrol win")
	var juno: Dictionary = TRAINERS.trainer("pasture_drover_juno").get("dialogue_after", {}) as Dictionary
	assert_eq(str(juno.get("flag", "")), returned, "Juno thanks the player once her Meadowhart is home")
	var ack := str(config.get("acknowledgement", ""))
	assert_false(ack.is_empty(), "no acknowledgement conversation on return")
	assert_true(DIALOGUE.table().has(ack), "acknowledgement '%s' is not a conversation" % ack)
