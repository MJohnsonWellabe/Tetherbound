extends "res://tests/test_case.gd"

## F38#16 candidate: pickup halos fade during a conversation shot.
## OFF until a GPU verdict; with it off the glow never reads the camera.
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")


class FakeRig:
	extends Node
	var talking := false
	var blend := 0.0
	func is_in_conversation() -> bool:
		return talking
	func conversation_blend() -> float:
		return blend


func test_flag_is_off_and_a_conversation_changes_nothing() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/pickup_glow.json"))
	assert_false(bool((cfg["conversation_fade_1113"] as Dictionary).get("enabled", true)))
	assert_false(PICKUP_GLOW.conversation_fade_enabled())
	var field: Node3D = PICKUP_GLOW.new()
	var rig := FakeRig.new()
	rig.add_to_group("camera_rig")
	rig.talking = true
	rig.blend = 1.0
	var host := Node.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	host.add_child(rig)
	host.add_child(field)
	assert_eq(field.conversation_fade_amount(), 0.0, "off: the glow ignores the conversation")
	host.queue_free()
