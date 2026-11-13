extends "res://tests/test_case.gd"

## THINGS-BEDROOMWOOD (13 Nov 2026): the wood in Grandpa's house (floor, loft,
## stairs, ceiling) ships with the judged cooler tint (LANE-SCOUT
## G-things-bedroomwood.md: F38#19 6.64 -> 7.15, 3/3, menus identical).
const PATH := "res://data/config/building_prefabs.json"


func _prefabs() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_true(parsed is Dictionary)
	return (parsed as Dictionary).get("prefabs", {})


func test_the_farmhouse_wood_is_the_judged_tint() -> void:
	var wood: Dictionary = (_prefabs().get("farmhouse_shell", {}) as Dictionary).get("interior_floor_material", {})
	assert_eq(str(wood.get("tint", "")), "#7f8a92")
	assert_true(str(wood.get("_why_tint_1113", "")).contains("G-things-bedroomwood.md"))
	# The texture and its crop are the ones the judges saw.
	assert_true(str(wood.get("albedo", "")).ends_with("T_WoodTrim_BaseColor.png"))


func test_the_tint_is_cooler_than_it_is_warm() -> void:
	var wood: Dictionary = (_prefabs().get("farmhouse_shell", {}) as Dictionary).get("interior_floor_material", {})
	var tint := Color(str(wood.get("tint", "#ffffff")))
	assert_true(tint.b >= tint.r, "a warm tint over the orange wood atlas is what read as overcooked")
