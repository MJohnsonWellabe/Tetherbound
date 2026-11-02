extends "res://tests/test_case.gd"

## P2-065 (vis-meadows, OFF until GPU-judged): grunt_a borrows the grunt rig's
## `defeated` slump only while its clip_candidate is enabled.

const MODEL := preload("res://scripts/characters/character_model.gd")
const ART := "res://data/config/art.json"


func test_candidate_ships_off_and_off_keeps_grunt_a_without_defeated() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART))
	var rig: Dictionary = art.grunt_a
	assert_false(bool(rig.clip_candidate.get("enabled", true)), "ships OFF")
	var off := MODEL.with_clip_candidate(rig)
	assert_false((off.clips as Dictionary).has("defeated"))
	assert_true(ResourceLoader.exists(str(rig.clip_candidate.animation_libraries[0])), "library installed")


func test_on_maps_defeated_and_adds_the_library() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART))
	var rig: Dictionary = art.grunt_a
	rig.clip_candidate.enabled = true
	var on := MODEL.with_clip_candidate(rig)
	assert_eq(str(on.clips.defeated), "defeated")
	assert_eq(str(on.clips.idle), "idle", "existing clips kept")
	assert_true("res://assets/characters/grunt/grunt_lod0.glb" in (on.animation_libraries as Array))
	assert_false((art.grunt_a.clips as Dictionary).has("defeated"), "shipped block not mutated")
