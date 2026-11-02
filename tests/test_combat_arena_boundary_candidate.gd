extends "res://tests/test_case.gd"

## P2-064 r2 (vis-meadows, OFF until GPU-judged): combat.json
## `arena.boundary_per_trainer_candidate` changes only the listed trainer's
## ring look, never its radius.

const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const CONFIG := "res://data/config/combat.json"


func _arena() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return (parsed.arena as Dictionary).duplicate(true)


func test_candidate_ships_off_and_off_changes_nothing() -> void:
	var arena := _arena()
	assert_false(bool(arena.boundary_per_trainer_candidate.get("enabled", true)), "ships OFF")
	var before := JSON.stringify(arena)
	assert_eq(JSON.stringify(COMBAT.arena_boundary_for(arena, "warden_aldis")), before)


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
