extends "res://tests/test_case.gd"

## Creatures-ralph (2 Nov 2026, coordinator option 2): the fight-camera pair
## midpoint leans toward the ally only when a fighter's remake renders longer
## than the installed model it replaced (`framing_length_ratio` > 1). Every
## fight within installed footprints keeps `midpoint_bias` exactly.

const FIGHT_CAMERA := preload("res://scripts/combat/fight_camera.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _fight_config() -> Dictionary:
	return FIGHT_CAMERA.config()


func test_bias_is_the_configured_midpoint_within_installed_footprints() -> void:
	var config := _fight_config()
	assert_true(config.has("midpoint_bias"), "the fight camera config carries midpoint_bias")
	var base := float(config.get("midpoint_bias", 0.5))
	assert_eq(base, 0.5, "the shipped pair midpoint is the true midpoint")
	assert_eq(FIGHT_CAMERA.midpoint_bias_for(config, 1.0, 1.0), base, "no declared ratio keeps the midpoint")
	assert_eq(FIGHT_CAMERA.midpoint_bias_for(config, 0.9, 1.0), base, "a shorter body never moves the midpoint")


func test_a_longer_remake_leans_the_midpoint_toward_the_ally() -> void:
	var config := _fight_config()
	var long: Dictionary = config.get("long_body_bias", {})
	assert_true(bool(long.get("enabled", false)), "long_body_bias ships ON")
	var leaned := FIGHT_CAMERA.midpoint_bias_for(config, 1.0, 1.18)
	assert_true(leaned < 0.5, "a longer foe leans the midpoint toward the ally (%.3f)" % leaned)
	assert_true(leaned >= float(long.get("min_bias", 0.3)), "the lean stops at min_bias")
	assert_eq(FIGHT_CAMERA.midpoint_bias_for(config, 1.09, 1.0), FIGHT_CAMERA.midpoint_bias_for(config, 1.0, 1.09),
		"the lean depends on the longest fighter, not its side")


func test_disabled_bias_changes_nothing() -> void:
	var config := _fight_config().duplicate(true)
	var long: Dictionary = (config.get("long_body_bias", {}) as Dictionary).duplicate()
	long["enabled"] = false
	config["long_body_bias"] = long
	assert_eq(FIGHT_CAMERA.midpoint_bias_for(config, 1.5, 1.5), float(config.get("midpoint_bias", 0.5)),
		"with the flag OFF every fight keeps midpoint_bias")


func test_only_declared_remakes_carry_a_ratio() -> void:
	for id: String in SPECIES.table():
		var ratio := float(SPECIES.placeholder(id).get("framing_length_ratio", 1.0))
		assert_true(ratio >= 1.0, "%s: a framing ratio only ever declares a longer body" % id)
