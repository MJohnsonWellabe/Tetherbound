extends "res://tests/test_case.gd"

## LANE-BELOW6 landing (G-below6-mushrooms, GPU High, 12 Nov 2026): the natural
## mushroom patches ship ON at the three High Perches rim placements only
## (F40#17 6.01 -> 6.94, 3/3). The open finds keep the cap that reads at distance.

const PRESENTATION := preload("res://scripts/world/mushroom_pickup_presentation.gd")
const VARIANTS := "res://data/config/mushroom_pickup_variants.json"


class Pickup extends Node3D:
	var _placement_id := ""


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(VARIANTS))


func _dressed(placement: String) -> Pickup:
	var pickup := Pickup.new()
	pickup._placement_id = placement
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	pickup.add_child(mesh)
	PRESENTATION.apply(pickup, "speed_mushroom")
	return pickup


func test_rim_flag_ships_on_with_its_verdict_and_the_open_arm_stays_off() -> void:
	var cfg := _cfg()
	var rim: Dictionary = cfg.get("perch_rim_cluster_1112", {})
	assert_true(bool(rim.get("enabled", false)), "perch_rim_cluster_1112 ships ON")
	assert_true(str(rim.get("_why_on", "")).contains("G-below6-mushrooms.md"), "ON cites its GPU verdict")
	assert_true(str(rim.get("_why_on", "")).contains("6.01 -> 6.94"), "and its judged score")
	assert_eq((rim.get("only_placements", []) as Array).size(), 3, "the three rim placements")
	assert_false(bool((cfg.get("natural_cluster_1112", {}) as Dictionary).get("enabled", true)),
		"the unscoped restyle stays OFF (Meadows finds -0.74, 0/3)")


func test_only_the_rim_placements_take_the_natural_patch() -> void:
	var rim := _dressed("cr_recovery_high_roost_flight_speed_01")
	assert_eq(rim.find_children("MushroomVariant", "Node3D", true, false).size(), 1, "a rim find shows the patch")
	var open := _dressed("some_meadow_find")
	assert_eq(open.find_children("MushroomVariant", "Node3D", true, false).size(), 0, "an open find keeps its cap")
	assert_true((open.get_child(0) as MeshInstance3D).visible, "and the cap stays visible")
	rim.free()
	open.free()
