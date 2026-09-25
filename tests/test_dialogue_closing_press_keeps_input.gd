extends "res://tests/test_case.gd"

## The `interact` press that dismisses a conversation's last line must not
## also reach the world. The interaction arbiter skips a tick while any
## `input_owner` owns input; the dialogue panel used to stop owning input the
## instant its runner closed, so the same, still "just pressed", key fired the
## NPC's prompt again later in that physics tick and reopened the conversation.
## Order-dependent -- the Doss repeat-greeting flake in smoke_local_requests.

const PANEL_SCENE := preload("res://scenes/ui/dialogue_panel.tscn")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const CONVERSATION := "river_nest_doss_defeated"


func test_the_closing_press_keeps_input_until_released() -> void:
	# Stood up off-tree as test_dialogue_portraits.gd does: the @onready
	# fields bound by hand to the scene's node paths.
	var panel: Node = PANEL_SCENE.instantiate()
	for field: String in ["_box:Root/Box", "_portrait:Root/Box/Margin/Row/Portrait",
			"_speaker:Root/Box/Margin/Row/Text/Speaker", "_body:Root/Box/Margin/Row/Text/Body",
			"_hint:Root/Box/Margin/Row/Text/Hint"]:
		var pair: PackedStringArray = field.split(":")
		panel.set(pair[0], panel.get_node_or_null(NodePath(pair[1])))
	assert_true(bool(panel.call("start", CONVERSATION)), "conversation %s starts" % CONVERSATION)
	Input.action_press("interact")
	var guard := 0
	while bool(panel.call("is_open")) and guard < 32:
		panel.call("advance")
		guard += 1
	assert_false(bool(panel.call("is_open")), "the presses end the conversation")
	assert_true(bool(INPUT_OWNER._owns(panel)),
		"while the closing press is still held, the panel still owns input")
	Input.action_release("interact")
	panel.call("_physics_process", 0.0)
	assert_false(bool(INPUT_OWNER._owns(panel)), "releasing the key hands input back to the world")
	panel.free()
