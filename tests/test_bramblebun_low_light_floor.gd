extends "res://tests/test_case.gd"

## MEADOWS-0912-BRAMBLEBUN-LOW-LIGHT. Bramblebun's accepted redesign uses a
## plain lit PBR material while most of the older roster is already self-lit.
## CreatureBody's shared emission-floor path deliberately affects only that
## plain-material family and samples the active albedo, but the former base
## value of zero left the rabbit with no colour-preserving fill in deep shadow
## until the world clock actually approached night.
##
## This suite pins the data contract, not the visual verdict. Production
## matched low-light/daylight captures remain required: the base must be
## present but conservative, full night must keep its accepted endpoint, and
## the clock interpolation must never create a dip below the new base floor.

const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")

const BASE_FLOOR_MIN := 0.04
const BASE_FLOOR_MAX := 0.10
const ACCEPTED_NIGHT_FLOOR := 0.22
const SAMPLE_STEP_HOURS := 0.25

var _config: Dictionary = {}
var _cycle: RefCounted


func before_each() -> void:
	_config = DAY_CYCLE.load_config()
	_cycle = DAY_CYCLE.new(_config)


func test_plain_pbr_creatures_keep_a_conservative_floor_outside_full_night() -> void:
	assert_false(_config.is_empty(), "art.json should parse")
	var environment: Dictionary = _config.get("environment", {})
	assert_true(environment.has("creature_emission_floor"),
		"the shared base environment must author the lower-light floor explicitly")
	var base_floor := float(environment.get("creature_emission_floor", 0.0))
	assert_between(base_floor, BASE_FLOOR_MIN, BASE_FLOOR_MAX,
		"the base floor must preserve colour in shadow without making a daylight creature self-lit")


func test_full_night_keeps_the_previously_accepted_endpoint() -> void:
	var night: Dictionary = _config.get("times", {}).get("night", {})
	var night_environment: Dictionary = night.get("environment", {})
	assert_almost_eq(
		float(night_environment.get("creature_emission_floor", -1.0)),
		ACCEPTED_NIGHT_FLOOR,
		0.0001,
		"the 09/03 blind-accepted full-night floor must not move to solve daytime shadow")


func test_clock_blending_never_drops_below_the_base_or_exceeds_full_night() -> void:
	var base_floor := float(_config.get("environment", {}).get("creature_emission_floor", 0.0))
	for step in int(24.0 / SAMPLE_STEP_HOURS):
		var hour := step * SAMPLE_STEP_HOURS
		var floor := _floor_at(hour, base_floor)
		assert_between(floor, base_floor, ACCEPTED_NIGHT_FLOOR,
			"hour %.2f must blend continuously between the conservative base and accepted night floor" % hour)


func _floor_at(hour: float, base_floor: float) -> float:
	var span: Dictionary = _cycle.interpolate_at(hour)
	var times: Dictionary = _config.get("times", {})
	var from_environment: Dictionary = times.get(str(span.get("from", "")), {}).get("environment", {})
	var to_environment: Dictionary = times.get(str(span.get("to", "")), {}).get("environment", {})
	var from_floor := float(from_environment.get("creature_emission_floor", base_floor))
	var to_floor := float(to_environment.get("creature_emission_floor", base_floor))
	return lerpf(from_floor, to_floor, float(span.get("t", 0.0)))
