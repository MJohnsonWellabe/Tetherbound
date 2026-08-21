extends SceneTree

## Production-faithful Gate A front-door regression.
##
## Boots the real configured title scene, lets it own focus, presses its
## focused Start New Game button through a physical joypad binding, and waits
## for the real Meadows scene transition.  The pure state/reset contract lives
## in test_title_new_game.gd; this is the scene/controller seam that caught the
## missing Game.reset_for_new_game method.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if str(ProjectSettings.get_setting("application/run/main_scene", "")) != TITLE_SCENE:
		_fail("configured main scene is not the title")
		_finish()
		return

	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing")
		_finish()
		return
	# Dirty the exact state New Game must not carry into the Meadows.
	game.day = 9
	game.inventory.add("berries", 7)
	game.party.add(game.make_creature("terrapup", "Old Run"))
	game.progression.set_flag("warden_defeated")
	game.placed_buildings = [{"id": "camp", "position": [1.0, 0.0, 1.0], "yaw_deg": 0.0}]

	var packed := load(TITLE_SCENE) as PackedScene
	var title := packed.instantiate() if packed != null else null
	if title == null:
		_fail("real title scene did not instantiate")
		_finish()
		return
	root.add_child(title)
	current_scene = title
	await process_frame

	var focused := root.get_viewport().gui_get_focus_owner() as Button
	if focused == null or focused.text != "Start New Game":
		_fail("title did not focus Start New Game; got %s" % str(focused))
		_finish()
		return
	var button_index := _pad_button_for(&"ui_accept")
	if button_index < 0:
		_fail("ui_accept has no physical joypad binding")
		_finish()
		return
	await _pad(button_index)

	# change_scene_to_file() is requested after one title frame.  World _ready()
	# is intentionally allowed to finish: seeing only a queued path would repeat
	# the old false-positive where the title never actually reached Meadows.
	for i in 20:
		if current_scene != null and current_scene.scene_file_path == WORLD_SCENE:
			break
		await process_frame
	if current_scene == null or current_scene.scene_file_path != WORLD_SCENE:
		_fail("Start New Game did not transition from title to Meadows")

	if game.day != 1 or game.inventory.used_slots() != 0 or game.party.size() != 0:
		_fail("Start New Game carried day, inventory, or party state into Meadows")
	# The opening is allowed to set its own fresh-boot flags while world _ready()
	# runs.  What must be gone are the exact old-run values seeded above.
	if game.progression.has("warden_defeated"):
		_fail("Start New Game carried the old Warden victory into Meadows")
	for raw: Variant in game.placed_buildings:
		if typeof(raw) == TYPE_DICTIONARY and str((raw as Dictionary).get("id", "")) == "camp":
			_fail("Start New Game carried the old camp into Meadows")
			break
	_finish()


func _pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _pad_button_for(action: StringName) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("title new game: OK -- physical pad activation reset live state and entered Meadows")
	quit(0 if _failures.is_empty() else 1)
