extends "res://tests/test_case.gd"

## An explicitly disabled runtime must preserve ordinary legacy behavior.
## These exercise the real live CreatureInstance consumers, not trait helpers.
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const DEFINITION := {"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0}
var _original_config: Dictionary = {}

func before_each() -> void:
	_original_config = TRAITS.config()

func after_each() -> void:
	TRAITS._config = _original_config

func test_legacy_gentle_does_not_activate_new_healing_bonus() -> void:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.set("traits_initialized", false)
	creature.set("trait_primary", "gentle")
	creature.set("max_hp", 100.0)
	creature.set("hp", 20.0)
	assert_eq(float(creature.call("heal", 10.0)), 10.0,
		"an uninitialized legacy trait must retain the previous healing amount")
	assert_eq(float(creature.get("hp")), 30.0)

func test_legacy_sturdy_does_not_add_new_defence_multiplier() -> void:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.set("traits_initialized", false)
	creature.set("trait_primary", "sturdy")
	creature.set("defence", 20.0)
	assert_eq(float(creature.call("effective_defence", PROGRESSION.config())), 20.0,
		"the legacy intrinsic stat already carries its old trait treatment")

func test_initialized_projection_does_not_enable_passive_traits() -> void:
	TRAITS._config = _original_config.duplicate(true)
	TRAITS._config.runtime_enabled = false
	assert_false(TRAITS.runtime_enabled(), "the explicit disabled fixture remains off")
	for id: String in ["gentle", "sturdy", "hardy"]:
		var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
		creature.call("_apply_level_stats", PROGRESSION.config())
		var baseline_max := float(creature.get("max_hp"))
		creature.set("hp", baseline_max * 0.4)
		creature.set("traits_initialized", true)
		creature.set("trait_primary", id)
		creature.set("rolled_traits", [id] as Array[String])
		creature.set("taught_traits", {})
		creature.call("_apply_level_stats", PROGRESSION.config())
		assert_almost_eq(float(creature.get("max_hp")), baseline_max,
			0.0001, "data adoption must not activate Hardy")
		assert_almost_eq(float(creature.get("hp")), baseline_max * 0.4)
		creature.set("max_hp", 100.0)
		creature.set("hp", 20.0)
		creature.set("defence", 20.0)
		assert_eq(float(creature.call("heal", 10.0)), 10.0,
			"an initialized normalized row must still honor the inactive gate")
		assert_eq(float(creature.call("effective_defence", PROGRESSION.config())), 20.0)

func test_initialized_shipped_traits_apply_once_and_preserve_hp_fraction() -> void:
	assert_true(TRAITS.runtime_enabled(), "the shipped trait consumers are active")
	for id: String in ["gentle", "sturdy", "hardy"]:
		var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
		creature.call("_apply_level_stats", PROGRESSION.config())
		var baseline_max := float(creature.get("max_hp"))
		creature.set("hp", baseline_max * 0.4)
		creature.set("traits_initialized", true)
		creature.set("trait_primary", id)
		creature.set("rolled_traits", [id] as Array[String])
		creature.set("taught_traits", {})
		var expected_max := baseline_max * (1.05 if id == "hardy" else 1.0)
		for recompute: int in 3:
			creature.call("_apply_level_stats", PROGRESSION.config())
			assert_almost_eq(float(creature.get("max_hp")), expected_max)
			assert_almost_eq(float(creature.get("hp")), expected_max * 0.4)
		creature.set("hp", 20.0)
		creature.set("defence", 20.0)
		assert_almost_eq(float(creature.call("heal", 10.0)), 10.5 if id == "gentle" else 10.0)
		assert_almost_eq(float(creature.call("effective_defence", PROGRESSION.config())), 21.0 if id == "sturdy" else 20.0)
