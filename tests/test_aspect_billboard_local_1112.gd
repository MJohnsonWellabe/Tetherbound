extends "res://tests/test_case.gd"

## vfx.json aspect_billboard_local_1112 (LANE-THINGS, 12 Nov 2026;
## G-things-creature-closeout.md): the aspect motes face the lens for Ashtusk
## and Stormtrail only; Riftfrill and Nightburrow lost and keep the old drawing.

const ASPECT := preload("res://scripts/creatures/vfx/aspect_vfx.gd")


func _block() -> Dictionary:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/vfx.json"))
	return doc.get("aspect_billboard_local_1112", {})


func test_ships_on_for_the_two_judged_winners() -> void:
	var block := _block()
	assert_true(bool(block.get("enabled", false)), "flag ON")
	assert_eq(block.get("species", []), ["ashtusk", "stormtrail"])
	for id: String in ["ashtusk", "stormtrail"]:
		assert_true(ASPECT.billboard_local_for(block, id), "%s motes face the lens" % id)
	for id: String in ["riftfrill", "nightburrow"]:
		assert_false(ASPECT.billboard_local_for(block, id), "%s keeps the old drawing" % id)


func test_empty_list_means_every_variant_and_off_means_none() -> void:
	assert_true(ASPECT.billboard_local_for({"enabled": true}, "riftfrill"))
	assert_true(ASPECT.billboard_local_for({"enabled": true, "species": []}, "nightburrow"))
	assert_false(ASPECT.billboard_local_for({"enabled": false, "species": ["ashtusk"]}, "ashtusk"))
