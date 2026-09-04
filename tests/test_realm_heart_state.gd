extends "res://tests/test_case.gd"

const REALM_HEARTS := preload("res://autoload/realm_heart_state.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")

const CONFIG := {
	"hearts": {
		"meadows": {
			"earned_flag": "heart_meadows_earned",
			"placed_flag": "heart_meadows_placed",
			"power": {"max_stamina_multiplier": 2.0},
		},
		"cloudreach": {
			"earned_flag": "heart_cloudreach_earned",
			"placed_flag": "heart_cloudreach_placed",
			"power": {"max_stamina_multiplier": 1.5},
		},
	},
	"realms": {
		"meadows": {"scene": "res://meadows.tscn", "entry_key_flag": ""},
		"cloudreach": {"scene": "res://cloudreach.tscn", "entry_key_flag": "key_cloudreach"},
	},
}

var hearts: RefCounted
var progression: RefCounted


func before_each() -> void:
	hearts = REALM_HEARTS.new(CONFIG)
	progression = PROGRESSION.new()


func test_an_unearned_heart_cannot_be_placed_or_activated() -> void:
	assert_false(hearts.place("meadows", progression))
	assert_false(hearts.activate("meadows", progression))
	assert_eq(hearts.active_id(), "")


func test_an_earned_heart_can_be_placed_and_activated() -> void:
	progression.set_flag("heart_meadows_earned")
	assert_true(hearts.place("meadows", progression))
	assert_true(progression.has("heart_meadows_placed"))
	assert_true(hearts.activate("meadows", progression))
	assert_eq(hearts.active_id(), "meadows")
	assert_eq(hearts.stamina_capacity_multiplier(), 2.0)


func test_activating_another_heart_replaces_the_first() -> void:
	for id in ["meadows", "cloudreach"]:
		progression.set_flag("heart_%s_earned" % id)
		assert_true(hearts.place(id, progression))
	assert_true(hearts.activate("meadows", progression))
	assert_true(hearts.activate("cloudreach", progression))
	assert_eq(hearts.active_id(), "cloudreach")
	assert_eq(hearts.stamina_capacity_multiplier(), 1.5)


func test_save_round_trip_preserves_the_single_active_selection() -> void:
	progression.set_flag("heart_meadows_earned")
	hearts.place("meadows", progression)
	hearts.activate("meadows", progression)
	var reloaded: RefCounted = REALM_HEARTS.new(CONFIG)
	reloaded.load_data(hearts.save_data(), progression)
	assert_eq(reloaded.active_id(), "meadows")
	assert_eq(reloaded.stamina_capacity_multiplier(), 2.0)


func test_load_refuses_a_power_whose_heart_is_not_placed() -> void:
	var before: int = hearts.revision
	hearts.load_data({"active_id": "meadows"}, progression)
	assert_eq(hearts.active_id(), "")
	assert_true(hearts.revision > before)


func test_realm_scene_and_key_are_data_driven() -> void:
	assert_eq(hearts.scene_for_realm("cloudreach"), "res://cloudreach.tscn")
	assert_eq(hearts.entry_key_for_realm("cloudreach"), "key_cloudreach")
	assert_eq(hearts.scene_for_realm("unknown"), "")
