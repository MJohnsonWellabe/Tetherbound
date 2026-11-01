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


## P2-003 (vis-meadows, OFF until GPU-judged): `p2_003_candidate` scales the
## lit keep with its front face held, and grows the spire, only when enabled.
func test_p2_003_candidate_ships_off_and_off_returns_the_shipped_gatehouse() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_false(bool(cfg.p2_003_candidate.get("enabled", true)), "P2-003 candidate ships OFF")
	assert_eq(JSON.stringify(STRONGHOLD.p2_003_gatehouse(cfg)), JSON.stringify(cfg.hero_gatehouse))


func test_p2_003_candidate_keeps_the_keep_front_face() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var shipped: Dictionary = cfg.hero_gatehouse
	cfg.p2_003_candidate.enabled = true
	var on := STRONGHOLD.p2_003_gatehouse(cfg)
	assert_true(float(on.width_m) > float(shipped.width_m), "the keep grows")
	# The keep's depth is 0.43 of its width (glb bounds 0.73 / 1.71), centred on its offset.
	var depth_ratio := 0.7280 / 1.7101
	var front_shipped := float(shipped.offset[2]) - float(shipped.width_m) * depth_ratio * 0.5
	var front_on := float(on.offset[2]) - float(on.width_m) * depth_ratio * 0.5
	assert_true(front_on >= front_shipped - 0.1, "front face stays clear of the chambers")
	var spire: Dictionary = (on.companions as Array).filter(func(c: Dictionary) -> bool: return c.id == "spire")[0]
	assert_almost_eq(float(spire.width_m), 57.0)
	assert_eq(str(spire.path), str(shipped.companions[0].path), "unmentioned companion keys stay")
	assert_eq(JSON.stringify(cfg.hero_gatehouse), JSON.stringify(shipped), "the shipped block is not mutated")
