extends "res://tests/test_case.gd"

## Cards M2 (ralph/reports/CARDS/m2/BRIDGE_GUARDIAN_REGRESSION.md): F04#2 seated
## the ally beside the player->opponent line in every trainer fight, and the
## earned five then lost the South Bridge gatekeeper (a grunt) on seed 15. The
## lateral seat stays for the named F04 fights and goes back in line for the
## rest.

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")


func test_named_ranks_sit_aside_and_the_rest_keep_the_line() -> void:
	var cfg := {"trainer_ally_lateral_ranks": ["officer", "captain", "warden"]}
	for rank: String in ["officer", "captain", "warden"]:
		assert_true(MANAGER.trainer_seats_aside(cfg, rank), "a %s's fight seats the ally aside" % rank)
	assert_false(MANAGER.trainer_seats_aside(cfg, "grunt"), "a grunt's fight keeps the in-line seat")
	assert_false(MANAGER.trainer_seats_aside(cfg, ""), "an unranked trainer (a tournament round) keeps it too")
	assert_true(MANAGER.trainer_seats_aside(cfg, null), "an untagged body keeps the lateral seat as before")
	assert_true(MANAGER.trainer_seats_aside({}, "grunt"), "without the list every trainer fight sits aside as before")


func test_the_shipped_config_and_data_route_the_bridge_guardian_in_line() -> void:
	var arena: Dictionary = MATH.config().get("arena", {})
	assert_true(float(arena.get("trainer_ally_lateral_m", 0.0)) > 0.0, "F04#2's lateral seat is still on")
	var ranks: Variant = arena.get("trainer_ally_lateral_ranks", null)
	assert_true(ranks is Array, "the named ranks are configured")
	assert_eq(str(TRAINERS.trainer("south_bridge_grunt").get("rank", "")), "grunt", "the bridge guardian is a grunt")
	assert_false(MANAGER.trainer_seats_aside(arena, TRAINERS.trainer("south_bridge_grunt").get("rank", "")),
		"so the South Bridge guardian's fight keeps the in-line seat")
	for id: String in ["relay_officer_dell", "relay_captain", "captain_riverwatch", "captain_field", "captain_ridge", "warden_aldis"]:
		assert_true(MANAGER.trainer_seats_aside(arena, TRAINERS.trainer(id).get("rank", "")),
			"%s's named fight still seats the ally aside (F04#2)" % id)
	var director := FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	assert_true(director.contains("body.set_meta(&\"trainer_rank\", str(_trainer_spec.get(\"rank\", \"\")))"),
		"the director tags each trainer body with its trainer's rank")
