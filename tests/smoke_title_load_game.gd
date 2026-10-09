extends SceneTree

## OP21-23 regression. `smoke_title_new_game.gd` proves New Game end to end
## through the real title scene and a physical pad press. Nothing equivalent
## existed for Load Game — the owner reproduction of "reaches the menu but
## never enters a playable world" therefore had no honest test standing
## between it and a silent re-break.
##
## This drives the full lifecycle: boot the real Meadows, dirty and save real
## state to an isolated slot, scramble live memory the way returning to the
## title does, then boot the real title scene and press a physical pad
## through Load Game -> a save slot, exactly the way a player would. It
## asserts the scene transition completes, the real Player/CameraRig exist
## and own control again, GUI focus has left the menu, and the saved
## position/day/party/inventory actually came back rather than whatever the
## fresh in-memory state already held.
##
##   godot --headless --path . --script tests/smoke_title_load_game.gd

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const TEST_DIR := "user://title_load_smoke_saves/"
const TEST_SLOT := 3
const SETTLE_FRAMES := 240

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_wipe_test_dir()
	var ok := await _create_a_real_save()
	if ok:
		await _load_it_through_the_title_screen()
	_wipe_test_dir()
	_finish()


## Boot the real Meadows, put the player and party into a state a fresh boot
## would never already match, and save it through Game's real save_game().
func _create_a_real_save() -> bool:
	var packed := load(WORLD_SCENE) as PackedScene
	var world: Node3D = packed.instantiate() as Node3D if packed != null else null
	if world == null:
		_fail("could not load the real Meadows scene")
		return false
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	var model := player.get_node_or_null(^"Model") as Node3D if player != null else null
	if game == null or player == null or rig == null or model == null:
		_fail("the real Game/Player/CameraRig lifecycle was not available")
		return false

	# Never touch a player's real save directory from a regression.
	game.set("save_system", SAVE_GAME.new(TEST_DIR))

	var ground := float(world.call("ground_height_at", 60.0, 24.0))
	player.global_position = Vector3(60.0, ground + 1.0, 24.0)
	player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	model.global_rotation.y = 0.837
	rig.set("yaw", 0.512)
	rig.set("pitch", -0.221)
	rig.rotation = Vector3(-0.221, 0.512, 0.0)
	await process_frame

	game.day = 6
	(game.get("inventory") as RefCounted).call("add", "berries", 4)
	(game.get("party") as RefCounted).call("add", game.call("make_creature", "terrapup", "Loaded"))

	_expected_position = player.global_position
	_expected_model_yaw = model.global_rotation.y
	_expected_camera_yaw = float(rig.get("yaw"))
	_expected_camera_pitch = float(rig.get("pitch"))
	_expected_day = game.day
	_expected_party_size = int((game.get("party") as RefCounted).call("size"))
	_expected_berries = int((game.get("inventory") as RefCounted).call("count", "berries"))

	if not bool(game.call("save_game", TEST_SLOT)):
		_fail("Game.save_game could not write the isolated title-load slot")
		return false

	# Now scramble live memory the way arriving back at the title does, and
	# tear the world down entirely -- title time genuinely has no Player.
	game.call("reset_for_new_game")
	root.remove_child(world)
	world.queue_free()
	current_scene = null
	for i in 5:
		await process_frame
	return true


var _expected_position: Vector3
var _expected_model_yaw: float
var _expected_camera_yaw: float
var _expected_camera_pitch: float
var _expected_day: int
var _expected_party_size: int
var _expected_berries: int


func _load_it_through_the_title_screen() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing after teardown")
		return
	if not bool(game.call("has_save", TEST_SLOT)):
		_fail("the save just written is not visible to has_save()")
		return

	var packed := load(TITLE_SCENE) as PackedScene
	var title := packed.instantiate() if packed != null else null
	if title == null:
		_fail("real title scene did not instantiate")
		return
	root.add_child(title)
	current_scene = title
	await process_frame

	var focused := root.get_viewport().gui_get_focus_owner() as Button
	if focused == null or focused.text != "Start New Game":
		_fail("title did not focus Start New Game; got %s" % str(focused))
		return

	var down := _pad_button_for(&"ui_down")
	var accept := _pad_button_for(&"ui_accept")
	if down < 0 or accept < 0:
		_fail("ui_down/ui_accept have no physical joypad binding")
		return

	# D-pad Down from Start New Game -> Load Game, then press it.
	await _pad(down)
	focused = root.get_viewport().gui_get_focus_owner() as Button
	if focused == null or focused.text != "Load Game":
		_fail("physical D-pad Down did not move focus onto Load Game; got %s" % str(focused))
		return
	if focused.disabled:
		_fail("Load Game is disabled even though a real save was just written")
		return
	await _pad(accept)

	# _show_load_slots() auto-focuses the first non-empty slot button, which
	# is the one this test just wrote -- no further navigation needed.
	focused = root.get_viewport().gui_get_focus_owner() as Button
	if focused == null or focused.disabled:
		_fail("opening Load Game did not leave a real save slot focused")
		return
	await _pad(accept)

	for i in 20:
		if current_scene != null and current_scene.scene_file_path == WORLD_SCENE:
			break
		await process_frame
	if current_scene == null or current_scene.scene_file_path != WORLD_SCENE:
		_fail("Load Game did not transition from title to Meadows")
		return

	var world := current_scene as Node3D
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	var model := player.get_node_or_null(^"Model") as Node3D if player != null else null
	if player == null or rig == null or model == null:
		_fail("Meadows loaded through the title but has no real Player/CameraRig")
		return

	# Give the loaded pose's deferred apply (player_controller._ready ->
	# Game.apply_loaded_player_pose) a chance to land, then settle physics.
	for i in 10:
		await physics_frame

	if root.get_viewport().gui_get_focus_owner() != null:
		_fail("GUI focus did not leave the title's menu after entering the world")

	if not bool(player.call("locomotion_enabled")):
		_fail("the player cannot move after a title Load Game -- world control never handed off")

	if player.global_position.distance_to(_expected_position) > 0.05:
		_fail("loaded position did not match the save: expected %s, got %s" % [_expected_position, player.global_position])
	if absf(angle_difference(model.global_rotation.y, _expected_model_yaw)) > 0.01:
		_fail("loaded trainer facing did not match the save")
	if absf(angle_difference(float(rig.get("yaw")), _expected_camera_yaw)) > 0.01 \
			or absf(float(rig.get("pitch")) - _expected_camera_pitch) > 0.01:
		_fail("loaded camera view did not match the save")

	if game.day != _expected_day:
		_fail("loaded day did not match the save: expected %d, got %d" % [_expected_day, game.day])
	var party: RefCounted = game.get("party")
	if int(party.call("size")) != _expected_party_size:
		_fail("loaded party size did not match the save: expected %d, got %d" % [_expected_party_size, int(party.call("size"))])
	var inventory: RefCounted = game.get("inventory")
	if int(inventory.call("count", "berries")) != _expected_berries:
		_fail("loaded inventory did not match the save: expected %d berries, got %d" % [_expected_berries, int(inventory.call("count", "berries"))])


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


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("title load game: OK -- physical pad activation loaded a real save and entered Meadows")
	quit(0 if _failures.is_empty() else 1)
