extends "res://tests/test_case.gd"

## P2-064 r2 (vis-meadows; ON since 13 Nov 2026): combat.json
## `arena.boundary_per_trainer_candidate` changes only the listed trainer's
## ring look, never its radius.

const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const CONFIG := "res://data/config/combat.json"


func _arena() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return (parsed.arena as Dictionary).duplicate(true)


func test_candidate_ships_on_with_its_verdict_and_off_changes_nothing() -> void:
	var arena := _arena()
	# ON since 13 Nov 2026 (G-things-wardenring-f41-13-closeout.md: F38#28
	# Medium 7.05 -> 7.52, 3/3, no set loses).
	assert_true(bool(arena.boundary_per_trainer_candidate.get("enabled", false)), "ships ON")
	assert_true(str(arena.boundary_per_trainer_candidate.get("_why_on", "")).contains("G-things-wardenring"))
	arena.boundary_per_trainer_candidate.enabled = false
	var before := JSON.stringify(arena)
	assert_eq(JSON.stringify(COMBAT.arena_boundary_for(arena, "warden_aldis")), before)


func test_the_shipped_ring_is_softer_for_the_warden_and_nobody_else() -> void:
	var arena := _arena()
	var warden := COMBAT.arena_boundary_for(arena.duplicate(true), "warden_aldis")
	assert_almost_eq(float(warden.boundary_alpha), 0.12)
	assert_almost_eq(float(warden.boundary_height), 0.45)
	var other := COMBAT.arena_boundary_for(arena.duplicate(true), "south_bridge_grunt")
	assert_almost_eq(float(other.boundary_alpha), float(arena.boundary_alpha))


func test_on_softens_the_warden_ring_only() -> void:
	var arena := _arena()
	arena.boundary_per_trainer_candidate.enabled = true
	var radius: float = float(arena.radius)
	var warden := COMBAT.arena_boundary_for(arena.duplicate(true), "warden_aldis")
	assert_almost_eq(float(warden.boundary_alpha), 0.12)
	assert_almost_eq(float(warden.radius), radius, 0.0001, "radius unchanged")
	var other := COMBAT.arena_boundary_for(arena.duplicate(true), "south_bridge_grunt")
	assert_almost_eq(float(other.boundary_alpha), float(arena.boundary_alpha))
	var wild := COMBAT.arena_boundary_for(arena.duplicate(true), "")
	assert_almost_eq(float(wild.boundary_alpha), float(arena.boundary_alpha))
