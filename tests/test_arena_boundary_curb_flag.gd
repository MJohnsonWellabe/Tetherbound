extends "res://tests/test_case.gd"

## F38#28 candidate: the Warden arena's edge as a stone curb. OFF until a GPU
## verdict; with it off no fight gets the curb style.
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")


func _arena_cfg() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	return (parsed["arena"] as Dictionary).duplicate(true)


func test_flag_is_off_and_no_fight_gets_the_curb() -> void:
	var cfg := _arena_cfg()
	assert_false(bool((cfg["boundary_curb_1113"] as Dictionary).get("enabled", true)))
	for trainer: String in ["warden_aldis", "south_bridge_grunt", ""]:
		var out: Dictionary = MANAGER.arena_boundary_for(cfg.duplicate(true), trainer)
		assert_false(out.has("boundary_style"), "%s keeps the ring" % trainer)


func test_on_only_the_listed_trainer_gets_it_and_the_radius_is_kept() -> void:
	var cfg := _arena_cfg()
	(cfg["boundary_curb_1113"] as Dictionary)["enabled"] = true
	var warden: Dictionary = MANAGER.arena_boundary_for(cfg.duplicate(true), "warden_aldis")
	assert_eq(str(warden.get("boundary_style", "")), "curb")
	assert_eq(float(warden.get("radius", 0.0)), float(cfg.get("radius", -1.0)))
	var grunt: Dictionary = MANAGER.arena_boundary_for(cfg.duplicate(true), "south_bridge_grunt")
	assert_false(grunt.has("boundary_style"))


func test_the_curb_is_a_ring_of_blocks_on_the_floor_at_the_radius() -> void:
	var curb: Dictionary = _arena_cfg()["boundary_curb_1113"]
	var blocks: Array[Transform3D] = ARENA.curb_transforms(11.0, curb, 72, false)
	var lines: Array[Transform3D] = ARENA.curb_transforms(11.0, curb, 72, true)
	assert_eq(blocks.size(), 72)
	for i in [0, 18, 36, 54]:
		var at: Vector3 = blocks[i].origin
		assert_almost_eq(Vector2(at.x, at.z).length(), 11.0, 0.001)
		assert_true(at.y > 0.0 and at.y < float(curb.get("height_m", 0.13)), "the block rests on the floor")
		assert_true(lines[i].origin.y > at.y, "the inlay sits on the block's top")
		# The block's long side (local x) runs along the circle, at right angles to the radius.
		assert_almost_eq(blocks[i].basis.x.normalized().dot(Vector3(at.x, 0.0, at.z).normalized()), 0.0, 0.001)
	var arena: Node3D = ARENA.new()
	arena.set("radius", 11.0)
	arena.call("_build_curb", curb)
	assert_true(arena.get_node_or_null("BoundaryCurb") != null and arena.get_node_or_null("BoundaryInlay") != null)
	assert_true(arena.get_node_or_null("Boundary") == null, "no glowing wall")
	arena.free()
