extends "res://tests/test_case.gd"

## F41#24 root_finish_1110 (LANE-MESHY): ships ON (GPU +0.82, 10 Nov); it rounds, thins,
## shortens and sinks the canopy roots.

const COVER := preload("res://scripts/world/stormwood_ground_cover.gd")


func _finish() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_ground_finish.json"))


func test_ships_on_and_off_keeps_the_old_root() -> void:
	var finish := _finish()
	assert_true(bool(finish.root_finish_1110.get("enabled", false)), "root_finish_1110 ships ON after its judged gain")
	assert_true(str(finish.root_finish_1110.get("_why_on", "")).contains("+0.82"), "the judged gain is recorded")
	finish.root_finish_1110.enabled = false
	assert_true(COVER.root_finish(finish).is_empty(), "OFF passes no shape")
	var cover := COVER.new()
	var shipped: ArrayMesh = cover._canopy_roots({})
	assert_eq(shipped.surface_get_array_len(0), 3 * 7 * 4 * 6, "OFF keeps the 4-arc, 7-segment root")
	cover.free()


func test_on_root_is_rounder_smaller_and_lower() -> void:
	var finish := _finish()
	finish.root_finish_1110.enabled = true
	var shape := COVER.root_finish(finish)
	var cover := COVER.new()
	var old_mesh: ArrayMesh = cover._canopy_roots({})
	var new_mesh: ArrayMesh = cover._canopy_roots(shape)
	assert_eq(new_mesh.surface_get_array_len(0), 3 * int(shape.segments) * int(shape.arcs) * 6, "rounder: more arcs and segments")
	var old_box := old_mesh.get_aabb()
	var new_box := new_mesh.get_aabb()
	assert_true(new_box.end.y < old_box.end.y * 0.7, "lower (%.3f vs %.3f)" % [new_box.end.y, old_box.end.y])
	assert_true(new_box.size.x * new_box.size.z < old_box.size.x * old_box.size.z, "shorter reach")
	assert_true(new_box.position.y < old_box.position.y, "sunk into the ground")
	assert_true(Color(str(shape.tint_wood)).get_luminance() < Color("#3c3929").get_luminance(), "darker wood")
	cover.free()
