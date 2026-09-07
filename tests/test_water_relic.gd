extends "res://tests/test_case.gd"

const REALM_HEARTS := preload("res://autoload/realm_heart_state.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")

var relics: RefCounted
var progression: RefCounted

func before_each() -> void:
	relics = REALM_HEARTS.new()
	progression = PROGRESSION.new()

func test_compass_uses_the_production_named_relic_and_tunable_guard() -> void:
	var water: Dictionary = relics.heart("water")
	assert_eq(water.get("display_name"), "Tideglass Compass")
	assert_eq(relics.earned_flag("water"), "realm_relic_water_earned")
	assert_eq(relics.placed_flag("water"), "realm_relic_water_placed")
	assert_eq(water.power.display_name, "Tidal Guard")
	assert_eq(water.power.incoming_damage_multiplier, 0.9)
	assert_false(str(water.get("display_name")).contains("Heart"))

func test_compass_cannot_be_placed_unearned_or_activated_unplaced() -> void:
	assert_false(relics.place("water", progression))
	assert_false(relics.activate("water", progression))
	assert_eq(relics.active_id(), "")
	progression.set_flag("realm_relic_water_earned")
	assert_false(relics.activate("water", progression))
	assert_true(relics.place("water", progression))
	assert_true(progression.has("realm_relic_water_placed"))
	assert_true(relics.activate("water", progression))
	assert_eq(relics.active_id(), "water")

func test_compass_replaces_each_older_power_without_stacking() -> void:
	for id in ["meadows", "cloudreach", "stormwood", "water"]:
		progression.set_flag(relics.earned_flag(id))
		assert_true(relics.place(id, progression))
	for previous in ["meadows", "cloudreach", "stormwood"]:
		assert_true(relics.activate(previous, progression))
		assert_eq(relics.active_id(), previous)
		assert_true(relics.activate("water", progression))
		assert_eq(relics.active_id(), "water")
		assert_eq(relics.stamina_capacity_multiplier(), 1.0)
		var power: Dictionary = relics.active_power()
		assert_eq(power.incoming_damage_multiplier, 0.9)
		assert_eq(float(power.get("fly_stamina_multiplier", 1.0)), 1.0)
		assert_eq(float(power.get("cooldown_multiplier", 1.0)), 1.0)
	assert_true(relics.activate("meadows", progression))
	assert_eq(float(relics.active_power().get("incoming_damage_multiplier", 1.0)), 1.0)
	assert_eq(relics.stamina_capacity_multiplier(), 2.0)

func test_save_round_trip_preserves_only_the_placed_compass_selection() -> void:
	progression.set_flag("realm_relic_water_earned")
	assert_true(relics.place("water", progression))
	assert_true(relics.activate("water", progression))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(relics.save_data()))
	var restored := REALM_HEARTS.new()
	var restored_flags := PROGRESSION.new()
	restored_flags.load_data(JSON.parse_string(JSON.stringify(progression.save_data())))
	restored.load_data(saved, restored_flags)
	assert_eq(restored.active_id(), "water")
	assert_eq(restored.active_power().incoming_damage_multiplier, 0.9)
	assert_eq(restored.save_data(), {"active_id": "water"})
	restored.load_data(saved, PROGRESSION.new())
	assert_eq(restored.active_id(), "")
	assert_true(restored.active_power().is_empty())
