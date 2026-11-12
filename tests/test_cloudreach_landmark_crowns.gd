extends "res://tests/test_case.gd"

## F40#3 (LANE-MESHY): `landmark_crowns_1111` builds aviary-family gold domes on the
## Old Wind Observatory and the Windscar Beacon. Presentation only.

const CROWNS := preload("res://scripts/world/cloudreach_landmark_crowns.gd")


func _raw() -> Dictionary:
	return (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json")) as Dictionary).landmark_crowns_1111


func test_config_is_scoped_and_names_both_landmarks() -> void:
	var raw := _raw()
	assert_eq(str(raw.get("scope", "")), "client_presentation")
	assert_true(raw.has("observatory") and raw.has("beacon"))
	if not bool(raw.enabled):
		assert_true(CROWNS.config().is_empty(), "OFF returns no crowns")


func test_dome_is_a_collisionless_gold_ribbed_crown() -> void:
	var raw := _raw()
	var parent := Node3D.new()
	var crown := CROWNS.dome(parent, "TestCrown", Vector3.UP * 16.2, 6.4, raw)
	assert_eq(crown.position, Vector3.UP * 16.2)
	var ribs := crown.find_children("AviaryRib*", "", true, false)
	assert_true(ribs.size() >= 12, "meridian ribs built (%d)" % ribs.size())
	assert_true(crown.find_child("CrownShell", true, false) is MeshInstance3D)
	assert_eq(crown.find_children("*", "CollisionShape3D", true, false).size(), 0, "no collider")
	assert_eq(crown.find_children("*", "StaticBody3D", true, false).size(), 0, "no body")
	var gold := Color(str(raw.gold))
	assert_true(gold.r > gold.b and gold.h * 360.0 > 30.0 and gold.h * 360.0 < 55.0, "gold, not red")
	parent.free()


## F40#3 landing (LANE-BELOW6, 12 Nov 2026): GPU High 6.00 -> 6.33 on the new
## approach stands; the crowns ship ON and cite that verdict.
func test_crowns_ship_on_with_their_verdict() -> void:
	var raw := _raw()
	assert_true(bool(raw.get("enabled", false)), "landmark_crowns_1111 ships ON (judged)")
	assert_true(str(raw.get("_why_on", "")).contains("G-below6-f40-3-landmarks.md"), "it cites its GPU verdict")
	assert_false(CROWNS.config().is_empty(), "ON returns the crown settings")
