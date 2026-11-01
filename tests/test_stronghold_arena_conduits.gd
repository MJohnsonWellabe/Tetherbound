extends "res://tests/test_case.gd"

## P2-064 (vis-meadows, OFF until GPU-judged): with
## `stronghold.json site.conduits_stop_at_arena_wall`, the floor cables that
## used to run centre to centre across the Warden fight ring end at its wall.

const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const CONFIG := "res://data/config/stronghold.json"


func test_flag_ships_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_false(bool(cfg.site.get("conduits_stop_at_arena_wall", true)), "P2-064 candidate ships OFF")


func test_clip_moves_the_arena_end_to_its_wall_line() -> void:
	var hold: Node3D = STRONGHOLD.new()
	var arena := {"at": [0.0, 90.2], "size": [24.0, 26.0]}
	# warden_arena -> legendary_chamber runs along -x: the arena end stops at x -12.
	var a: Vector3 = hold.call("_clip_to_chamber_wall", Vector3(0, 0, 90.2), Vector3(-32, 0, 90.2), arena, true)
	assert_almost_eq(a.x, -12.0)
	assert_almost_eq(a.z, 90.2)
	# tether_approach -> warden_arena runs along +z: the arena end stops at z 77.2.
	var b: Vector3 = hold.call("_clip_to_chamber_wall", Vector3(0, 0, 90.2), Vector3(0, 0, 64), arena, false)
	assert_almost_eq(b.z, 77.2)
	assert_almost_eq(b.x, 0.0)
	hold.free()
