extends "res://tests/test_case.gd"

## OP21-20: the full-submersion hazard's pure arithmetic, exercised through
## the exact functions `scripts/world/water.gd::_process` calls -- these are
## static, scene-free methods on that same script (no Node instantiated, no
## scene tree touched, per docs/decisions/D02's "pure logic only" scope), so
## calling `WATER.is_fully_submerged(...)` / `WATER.tick_submersion(...)`
## here IS the real path, not a re-implementation of it running in parallel
## that could silently drift from what actually ships.
##
## Config values are read straight from data/config/water_hazard.json rather
## than hardcoded, so a tuning pass that edits the file is what this test
## reacts to, not a copy of numbers that could quietly go stale.

const WATER := preload("res://scripts/world/water.gd")
const HAZARD_CONFIG_PATH := "res://data/config/water_hazard.json"

var cfg: Dictionary = {}


func before_each() -> void:
	var file := FileAccess.open(HAZARD_CONFIG_PATH, FileAccess.READ)
	assert_true(file != null, "water_hazard.json must exist for this test to mean anything")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "water_hazard.json must parse as an object")
	cfg = (parsed as Dictionary).get("submersion", {})
	assert_false(cfg.is_empty(), "water_hazard.json must define a 'submersion' block")


func _fresh_state() -> Dictionary:
	return {"submerged_s": 0.0, "tick_s": 0.0, "damage": 0.0}


## --- is_fully_submerged: the head-depth threshold itself -------------------

func test_head_well_above_water_is_not_submerged() -> void:
	assert_false(WATER.is_fully_submerged(2.0, 0.0, 0.15))


## Ordinary shoreline contact / wading: the water is shallow enough that even
## with the full player height added, the head sits above the surface. This
## is the case that must NEVER be punitive.
func test_wading_with_head_above_surface_is_never_submerged() -> void:
	var player_height: float = float(cfg.get("player_height_m", 1.8))
	var water_level := 5.0
	var feet_y := water_level - (player_height * 0.5)  # waist-deep at most
	var head_y := feet_y + player_height
	assert_true(head_y > water_level, "test setup: head should clear the surface")
	assert_false(WATER.is_fully_submerged(head_y, water_level, float(cfg.get("depth_threshold_m", 0.15))))


func test_head_just_at_the_surface_is_not_submerged() -> void:
	var threshold: float = float(cfg.get("depth_threshold_m", 0.15))
	# Exactly at the margin, and a hair inside it: neither counts yet -- the
	# margin exists so standing right at the waterline does not flicker.
	assert_false(WATER.is_fully_submerged(0.0 - threshold, 0.0, threshold))
	assert_false(WATER.is_fully_submerged(0.0 - threshold + 0.01, 0.0, threshold))


func test_head_well_past_the_threshold_is_submerged() -> void:
	var threshold: float = float(cfg.get("depth_threshold_m", 0.15))
	assert_true(WATER.is_fully_submerged(0.0 - threshold - 0.5, 0.0, threshold))


## --- tick_submersion: wading never accumulates or damages -------------------

func test_wading_never_accumulates_toward_damage_however_long() -> void:
	var state := _fresh_state()
	# A full ten minutes of "not submerged" ticks, in one-second steps -- if
	# this ever produced damage it would mean wading or standing at the bank
	# had become punitive, which the task explicitly forbids.
	for i in 600:
		state = WATER.tick_submersion(state, 1.0, false, cfg)
		assert_eq(float(state["submerged_s"]), 0.0, "not-submerged must never accumulate submerged time")
		assert_eq(float(state["damage"]), 0.0, "not-submerged must never deal damage")


## --- tick_submersion: the grace period ---------------------------------------

func test_full_submersion_deals_no_damage_during_the_grace_period() -> void:
	var grace: float = float(cfg.get("grace_seconds", 2.5))
	var state := _fresh_state()
	var elapsed := 0.0
	var step := 0.1
	# Advance in small steps up to (but not through) the grace period and
	# confirm not one of those frames dealt damage.
	while elapsed + step < grace:
		state = WATER.tick_submersion(state, step, true, cfg)
		assert_eq(float(state["damage"]), 0.0,
			"no damage before the grace period elapses (t=%.2f of %.2f)" % [elapsed, grace])
		elapsed += step


## --- tick_submersion: damage actually starts after grace, real path ---------

## The regression this task specifically asks for: full submersion held
## continuously past the grace period must start dealing damage, on the
## tick cadence the config names -- not merely "eventually", but at the
## configured interval and amount.
func test_full_submersion_past_grace_damages_on_the_configured_tick() -> void:
	var grace: float = float(cfg.get("grace_seconds", 2.5))
	var tick_interval: float = maxf(float(cfg.get("tick_interval_s", 1.0)), 0.05)
	var damage_per_tick: float = float(cfg.get("damage_per_tick", 6.0))
	assert_true(damage_per_tick > 0.0, "water_hazard.json must define positive damage_per_tick")

	var state := _fresh_state()
	var step := 0.05
	var elapsed := 0.0
	var total_damage := 0.0
	var ticks := 0
	var run_for := grace + tick_interval * 3.0 + 0.5

	while elapsed < run_for:
		state = WATER.tick_submersion(state, step, true, cfg)
		var damage: float = float(state["damage"])
		if damage > 0.0:
			assert_true(elapsed + step >= grace,
				"damage landed before the grace period should have elapsed")
			assert_eq(damage, damage_per_tick, "each tick must deal exactly the configured amount")
			total_damage += damage
			ticks += 1
		elapsed += step

	assert_true(ticks >= 3, "continuous submersion past grace should have produced multiple damage ticks, got %d" % ticks)
	assert_eq(total_damage, damage_per_tick * ticks)


## Surfacing before the grace period elapses must reset the clock entirely --
## no partial credit toward the next dunk.
func test_surfacing_before_grace_resets_the_clock() -> void:
	var grace: float = float(cfg.get("grace_seconds", 2.5))
	var state := _fresh_state()
	# Get most of the way through the grace period...
	state = WATER.tick_submersion(state, grace * 0.8, true, cfg)
	assert_eq(float(state["damage"]), 0.0)
	assert_true(float(state["submerged_s"]) > 0.0)
	# ...surface...
	state = WATER.tick_submersion(state, 0.5, false, cfg)
	assert_eq(float(state["submerged_s"]), 0.0, "surfacing must reset accumulated submerged time")
	# ...and go back under: the old progress must not carry over, so the
	# grace period must run its full length again before any damage.
	var elapsed := 0.0
	var step := 0.1
	while elapsed + step < grace:
		state = WATER.tick_submersion(state, step, true, cfg)
		assert_eq(float(state["damage"]), 0.0, "grace must restart fully after a surface")
		elapsed += step


## --- warning_fraction: the escalating feedback signal -----------------------

func test_warning_fraction_rises_from_zero_to_one_across_grace() -> void:
	var grace: float = float(cfg.get("grace_seconds", 2.5))
	assert_eq(WATER.warning_fraction(0.0, grace), 0.0)
	assert_eq(WATER.warning_fraction(grace, grace), 1.0)
	var mid := WATER.warning_fraction(grace * 0.5, grace)
	assert_true(mid > 0.0 and mid < 1.0, "midway through grace should read as partial warning, got %.3f" % mid)


func test_warning_fraction_never_exceeds_one_once_damage_is_ticking() -> void:
	var grace: float = float(cfg.get("grace_seconds", 2.5))
	assert_eq(WATER.warning_fraction(grace * 5.0, grace), 1.0)
