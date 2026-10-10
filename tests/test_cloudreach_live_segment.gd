extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/cloudreach_live_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const CHART := preload("res://scripts/combat/type_chart.gd")

class SwitchObservation extends Node:
	var party: Array = []
	var foe: RefCounted
	var index := 0
	var available := true
	var moves := MOVES.new()

	func can_switch() -> bool:
		return available

	func active_creature() -> RefCounted:
		return party[index]

	func enemy() -> RefCounted:
		return foe

	func active_matchup() -> int:
		var active: RefCounted = active_creature()
		return CHART.classify(maxf(
			CHART.multiplier_dual(moves.type_of(active.move_quick), foe.creature_type, foe.secondary_type),
			CHART.multiplier_dual(moves.type_of(active.move_charged), foe.creature_type, foe.secondary_type)))

	func switchable_indices() -> Array[int]:
		var options: Array[int] = []
		for candidate in party.size():
			if candidate != index:
				options.append(candidate)
		return options

func _switch_observation() -> SwitchObservation:
	var observation := SwitchObservation.new()
	for id: String in ["terrapup", "bramblebun", "bramblebun", "mudsnout", "bramblebun"]:
		var member: RefCounted = SPECIES.spawn(id)
		member.uid = "observed-owned-%d" % observation.party.size()
		observation.party.append(member)
	observation.foe = SPECIES.spawn("mosshell")
	return observation

func test_campaign_pilot_stops_cycling_when_all_five_observed_arrows_are_poor() -> void:
	var observation := _switch_observation()
	var pilot := SEGMENT.CampaignPilot.new(null, observation, null, null)
	for turn in 5:
		assert_true(observation.active_matchup() < 0, "actual failed Hall party lacks Water coverage")
		assert_true(pilot._should_switch(), "try each owned creature's visible arrow once")
		var before: RefCounted = observation.active_creature()
		observation.index = (observation.index + 1) % observation.party.size()
		assert_true(pilot._observe_switch(before, observation.active_creature()))
	for repeated_poll in 3:
		assert_false(pilot._should_switch(), "a full equally poor tour must return to fighting")
	observation.free()

func test_campaign_pilot_reconsiders_observed_switches_for_a_new_opponent() -> void:
	var observation := _switch_observation()
	var pilot := SEGMENT.CampaignPilot.new(null, observation, null, null)
	assert_true(pilot._should_switch())
	assert_true(pilot._observe_switch(observation.active_creature(), observation.party[1]))
	assert_false(pilot._should_switch(), "repeated same-creature poor observation is bounded")
	observation.foe = SPECIES.spawn("brooktail")
	assert_true(pilot._should_switch(), "new opponent starts a fresh observed tour")
	observation.free()

func test_refused_switch_keeps_the_current_poor_matchup_available_to_retry() -> void:
	var observation := _switch_observation()
	var pilot := SEGMENT.CampaignPilot.new(null, observation, null, null)
	assert_true(pilot._should_switch())
	assert_false(pilot._observe_switch(observation.active_creature(), observation.active_creature()), "a refused physical press changes no creature")
	assert_true(pilot._should_switch(), "a refused input must not spend the observed poor matchup")
	assert_true(pilot._observe_switch(observation.active_creature(), observation.party[1]))
	assert_false(pilot._should_switch(), "an accepted tour still remains bounded")
	observation.free()

func test_same_owned_uid_recreated_or_missing_uid_is_not_an_accepted_switch() -> void:
	var observation := _switch_observation()
	var pilot := SEGMENT.CampaignPilot.new(null, observation, null, null)
	var original: RefCounted = observation.active_creature()
	var recreated: RefCounted = SPECIES.spawn("terrapup")
	recreated.uid = ""
	assert_true(pilot._should_switch())
	assert_false(pilot._observe_switch(original, recreated), "missing owned UID cannot consume the tour")
	assert_true(pilot._should_switch())
	recreated.uid = original.uid
	assert_false(pilot._observe_switch(original, recreated), "a rebuilt reference for the same creature is not a switch")
	assert_true(pilot._should_switch(), "same-UID replacement keeps the original poor arrow eligible")
	observation.free()

func test_campaign_pilot_does_not_spend_observations_while_switching_is_unavailable() -> void:
	var observation := _switch_observation()
	var pilot := SEGMENT.CampaignPilot.new(null, observation, null, null)
	observation.available = false
	assert_false(pilot._should_switch())
	observation.available = true
	assert_true(pilot._should_switch())
	observation.foe = SPECIES.spawn("burrowback")
	assert_false(pilot._should_switch(), "neutral visible arrow needs no search")
	observation.free()


func test_live_segment_refuses_missing_context_without_creating_a_fixture() -> void:
	var segment := SEGMENT.new()
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.ok)
	assert_false(observed.completed)
	assert_true(not observed.failures.is_empty())
	assert_eq(observed.world, null)
	assert_eq(observed.game, null)


func test_party_handoff_accepts_an_earned_carrier_without_requiring_a_loaner() -> void:
	assert_true(SEGMENT.party_preserved([11, 12, 13], [11, 12, 13]))
	assert_true(SEGMENT.party_preserved([11, 12, 13, 14, 15], [11, 12, 13, 14, 15]))
	assert_false(SEGMENT.party_preserved([], []))
	assert_false(SEGMENT.party_preserved([11, 12], [11, 99]))
	assert_false(SEGMENT.party_preserved([11, 12], [11, 12, 13]))
	assert_false(SEGMENT.party_preserved([1, 2, 3, 4, 5, 6], [1, 2, 3, 4, 5, 6]))


func test_completion_fails_closed_on_any_route_failure() -> void:
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["required fight lost"]))
	assert_true(SEGMENT.verdict(true, []))


func test_campaign_segment_contains_no_fixture_or_progression_shortcuts() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/cloudreach_live_segment.gd")
	for forbidden: String in ["reset_for_new_game", "set_flag(", "inventory.add(",
		"party.add(", "set_level(", "take_damage(", "_award_victory(",
		"_begin_resolve(", "load_game(", "save_game(", "enter_realm(",
		"global_position =", "global_position=", "set_physics_process(",
		"set_process(", "rig.set(", "cycle_active("]:
		assert_false(source.contains(forbidden), "campaign helper may not inject gameplay state: " + forbidden)
