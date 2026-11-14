extends "res://tests/test_case.gd"

## F38#16 candidate: pickup halos fade during a conversation shot.
## OFF until a GPU verdict; with it off the glow never reads the camera.
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")


func test_flag_is_off_and_the_glow_does_not_fade() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/pickup_glow.json"))
	assert_false(bool((cfg["conversation_fade_1113"] as Dictionary).get("enabled", true)))
	assert_false(PICKUP_GLOW.conversation_fade_enabled())
	var field: Node3D = PICKUP_GLOW.new()
	assert_eq(field.conversation_fade_amount(), 0.0, "off: the glow never fades")
	field.free()
