extends "res://tests/test_case.gd"

## P2-064 (vis-meadows, OFF until GPU-judged): with
## `stronghold.json site.conduits_stop_at_arena_wall`, the floor cables that
## used to run centre to centre across the Warden fight ring end at its wall.

const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const CONFIG := "res://data/config/stronghold.json"


func test_flag_ships_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_true(bool(cfg.site.get("conduits_stop_at_arena_wall", false)), "P2-064 candidate ships ON: cloud yardstick 1 Nov batch-1, 4.59 -> 6.25")


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


## P2-087 (vis-meadows, OFF until GPU-judged): `p2_087_grade_candidate`
## recolours lights matched by `at`, only when enabled.
func test_p2_087_grade_candidate_matches_lights_by_at() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_false(bool(cfg.p2_087_grade_candidate.get("enabled", true)), "P2-087 candidate ships OFF")
	var fill: Dictionary = {"at": [0.0, 32.0], "colour": "#fff0d8", "energy": 10.0}
	assert_eq(STRONGHOLD.p2_087_light(cfg, fill), fill, "OFF leaves every light alone")
	cfg.p2_087_grade_candidate.enabled = true
	var on := STRONGHOLD.p2_087_light(cfg, fill)
	assert_eq(str(on.colour), "#d6e2f2")
	assert_almost_eq(float(on.energy), 10.0)
	var torch: Dictionary = {"at": [0.0, 60.0], "colour": "#7d8cab"}
	assert_eq(STRONGHOLD.p2_087_light(cfg, torch), torch, "unmatched lights unchanged")


## P2-064 r2 (vis-meadows, OFF until GPU-judged): the six Warden-arena wall
## torches pool at the wall; other torches are untouched.
func test_p2_064_r2_candidate_softens_only_the_arena_torches() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_false(bool(cfg.p2_064_r2_candidate.get("enabled", true)), "P2-064 r2 ships OFF")
	var arena_torch: Dictionary = {"mount": "wall", "at": [11.4, 90.2], "energy": 12.0}
	var approach_torch: Dictionary = {"mount": "wall", "at": [7.4, 60.6], "energy": 12.0}
	cfg.p2_064_r2_candidate.enabled = true
	var on := STRONGHOLD.candidate_light(cfg, "p2_064_r2_candidate", arena_torch)
	assert_true(float(on.energy) < 12.0)
	assert_true(float(on.attenuation) > 1.0)
	assert_eq(STRONGHOLD.candidate_light(cfg, "p2_064_r2_candidate", approach_torch), approach_torch)
