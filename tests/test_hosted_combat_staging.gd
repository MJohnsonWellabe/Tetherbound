extends "res://tests/test_case.gd"

const STAGING := preload("res://tests/helpers/hosted_combat_staging.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")

func test_tamsin_fixture_clears_both_scaled_bodies_and_remains_inside_quick_reach() -> void:
	var mine := float(SPECIES.placeholder("terrapup").get("radius", 0.0))
	for species in ["stormraven", "voltwig"]:
		var theirs := float(SPECIES.placeholder(species).get("radius", 0.0))
		assert_true(1.25 < mine + theirs,
			"the old finishing fixture intersects the current two gameplay bodies")
		var gap := STAGING.distance_for(mine, theirs)
		assert_true(gap > mine + theirs, "the fixture must leave both bodies clear")
		var profile := MANAGER.host_move_profile(MOVES.new(), "player_quick",
			"pebble_toss", mine, theirs)
		assert_true(gap < float(profile.get("range", 0.0)),
			"a correctly staged shot must fit the unchanged host quick profile")

func test_staging_follows_new_body_sizes_without_a_new_distance_constant() -> void:
	var normal := STAGING.distance_for(1.46, 1.14)
	var grown := STAGING.distance_for(2.92, 2.28)
	assert_true(grown > normal, "larger bodies require larger fixture clearance")
	assert_true(grown > 2.92 + 2.28, "growth must preserve nonintersecting bodies")
