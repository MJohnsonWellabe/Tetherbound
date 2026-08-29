extends SceneTree

## RG7. Real Meadows save/load lifecycle: production opening grant, production
## villager gift, physical one-shot pickups, exact trainer/view pose, and live
## control after an in-world load.
##
##   godot --headless --path . --script tests/smoke_save_persistence.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const BEATS := preload("res://scripts/story/opening_beats.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const SEQUENCE := preload("res://scripts/story/sequence_director.gd")

const TEST_DIR := "user://test_saves_rg7/"
const TEST_SLOT := 4
const SETTLE_FRAMES := 300
const STARTER_NAME := "Keepsake"
const TM_ID := "tm_stone_rush"
const TM_NODE := ^"TM_tm_stone_rush"
const GIFT_FLAG := "tam_tools_given"

var _failures: Array[String] = []
var _world: Node3D = null
var _game: Node = null
var _player: CharacterBody3D = null
var _model: Node3D = null
var _rig: Node3D = null
var _director: Node = null
var _dialogue: CanvasLayer = null
var _picker: CanvasLayer = null
var _name_prompt: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	_wipe_test_dir()
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_fail("could not load %s" % SCENE)
		_report()
		return
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	if not _collect_nodes():
		_report()
		return

	# Never touch a player's real save directory from a regression.
	_game.set("save_system", SAVE_GAME.new(TEST_DIR))

	await _earn_the_starter_through_the_production_sequence()
	await _receive_tams_real_one_time_gift()
	await _take_authored_one_shot_pickups()
	await _round_trip_the_live_world()

	_wipe_test_dir()
	_report()


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_model = _player.get_node_or_null(^"Model") as Node3D if _player != null else null
	_dialogue = get_first_node_in_group("dialogue_panel") as CanvasLayer
	_director = _find_by_script(_world, "res://scripts/story/sequence_director.gd")
	_picker = _find_by_script(_world, "res://scripts/ui/starter_picker.gd") as CanvasLayer
	_name_prompt = _find_by_script(_world, "res://scripts/ui/name_prompt.gd") as CanvasLayer
	if _game == null or _player == null or _model == null or _rig == null:
		_fail("the real Game/Player/Model/CameraRig lifecycle was not available")
	if _director == null or _dialogue == null or _picker == null or _name_prompt == null:
		_fail("the opening's production director or panels were not available")
	return _failures.is_empty()


func _earn_the_starter_through_the_production_sequence() -> void:
	# The bed prompt's callback is the production wake transition. UI input to
	# that callback is independently covered by smoke_opening; this test stays
	# focused on the state which crosses the save boundary.
	_director.call("_on_bed_activated")
	await process_frame
	await _play_conversation(BEATS.conversation_for(BEATS.HOUSE))
	for i in 30:
		if bool(_picker.call("is_open")):
			break
		await process_frame
	if str(_director.call("beat")) != BEATS.CHOOSE or not bool(_picker.call("is_open")):
		_fail("Grandpa's real briefing did not reach the starter picker")
		return

	# Use the panels' own confirmation functions so they close before emitting
	# exactly the production signals SequenceDirector listens to.
	_picker.call("_confirm")
	await process_frame
	if not bool(_name_prompt.call("is_open")):
		_fail("choosing an orb did not open the mandatory name prompt")
		return
	_name_prompt.call("_on_field_text_changed", STARTER_NAME)
	_name_prompt.call("_confirm")

	var party: RefCounted = _game.get("party")
	for i in 600:
		if int(party.call("size")) == 1:
			break
		await physics_frame
	if int(party.call("size")) != 1:
		_fail("the production starter adoption never reached Game.party")
		return
	if str(party.call("at", 0).get("nickname")) != STARTER_NAME:
		_fail("the adopted starter lost the name entered through NamePrompt")
	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", SEQUENCE.STARTER_GRANTED_FLAG)):
		_fail("starter adoption did not record its durable one-shot flag")

	# Naming deliberately returns to Grandpa. Take the production first-catch
	# conversation through the shared panel so its effect advances to walk_out
	# and its Orb reward is persisted with the same save.
	if str(_director.call("beat")) != BEATS.RETURN_STARTER:
		_fail("naming should return to Grandpa before the first catch, got '%s'" % str(_director.call("beat")))
		return
	await _play_conversation(BEATS.conversation_for(BEATS.RETURN_STARTER))
	if BEATS.index_of(str(_director.call("beat"))) < BEATS.index_of(BEATS.WALK_OUT):
		_fail("the opening did not reach its post-starter world state")


func _receive_tams_real_one_time_gift() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var before := int(inventory.call("count", "axe"))
	await _play_conversation("village_tam_tools")
	if int(inventory.call("count", "axe")) != before + 1:
		_fail("Tam's production conversation did not grant its real tool gift")
	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", GIFT_FLAG)):
		_fail("Tam's gift did not write %s before saving" % GIFT_FLAG)


func _take_authored_one_shot_pickups() -> void:
	var tm := _world.get_node_or_null(TM_NODE) as Node3D
	var key := _world.get_node_or_null(^"GateKey") as Node3D
	if tm == null or key == null:
		_fail("the authored TM or gate-key pickup was absent before collection")
		return
	var tm_prompt := tm.get_node_or_null(^"Interactable")
	var key_prompt := key.get_node_or_null(^"Interactable")
	if tm_prompt == null or key_prompt == null:
		_fail("a one-shot pickup had no production interaction prompt")
		return
	tm_prompt.emit_signal("activated")
	key_prompt.emit_signal("activated")
	await process_frame
	await process_frame
	var inventory: RefCounted = _game.get("inventory")
	if int(inventory.call("count", TM_ID)) != 1:
		_fail("the physical TM interaction did not add exactly one inventory item")
	if int(inventory.call("count", "castle_gate_key")) != 1:
		_fail("the physical key interaction did not add exactly one inventory item")


func _round_trip_the_live_world() -> void:
	# An arbitrary safe wilderness point, deliberately unrelated to spawn, bed,
	# camp, or a checkpoint. Let physics settle before capturing the exact pose.
	var xz := Vector2(42.0, 35.0)
	var ground := float(_world.call("ground_height_at", xz.x, xz.y))
	_player.global_position = Vector3(xz.x, ground + 1.0, xz.y)
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	_model.global_rotation.y = 1.274
	_rig.set("yaw", -1.137)
	_rig.set("pitch", -0.413)
	_rig.rotation = Vector3(-0.413, -1.137, 0.0)
	await process_frame
	var expected_position := _player.global_position
	var expected_model_yaw := _model.global_rotation.y
	var expected_camera_yaw := float(_rig.get("yaw"))
	var expected_camera_pitch := float(_rig.get("pitch"))
	var inventory: RefCounted = _game.get("inventory")
	var expected_tm_count := int(inventory.call("count", TM_ID))

	if not bool(_game.call("save_game", TEST_SLOT)):
		_fail("Game.save_game could not write the isolated RG7 slot")
		return

	# Make every assertion capable of failing: move, rotate, add a duplicate,
	# and clear progression before loading through the production Game seam.
	_player.global_position = Vector3(-90.0, 40.0, 80.0)
	_player.velocity = Vector3(4.0, -12.0, 3.0)
	_model.global_rotation.y = -2.0
	_rig.set("yaw", 2.4)
	_rig.set("pitch", 0.2)
	inventory.call("add", TM_ID, 1)
	(_game.get("progression") as RefCounted).call("load_data", {})
	if not bool(_game.call("load_game", TEST_SLOT)):
		_fail("Game.load_game could not apply the isolated RG7 slot")
		return
	for i in 5:
		await physics_frame

	if _player.global_position.distance_to(expected_position) > 0.001:
		_fail("exact position did not round-trip: expected %s, got %s" % [expected_position, _player.global_position])
	if absf(angle_difference(_model.global_rotation.y, expected_model_yaw)) > 0.0001:
		_fail("trainer facing did not round-trip exactly")
	if absf(angle_difference(float(_rig.get("yaw")), expected_camera_yaw)) > 0.0001 \
			or absf(float(_rig.get("pitch")) - expected_camera_pitch) > 0.0001:
		_fail("camera view did not round-trip exactly")
	if _player.velocity.length() > 0.05:
		_fail("load retained a pre-load motion impulse: %s" % _player.velocity)

	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", SEQUENCE.STARTER_GRANTED_FLAG)) \
			or BEATS.index_of(str(_director.call("beat"))) < BEATS.index_of(BEATS.WALK_OUT):
		_fail("loading replayed or rewound the completed opening/starter opportunity")
	if bool(_picker.call("is_open")) or bool(_director.call("is_fading")):
		_fail("loading a completed opening resurrected its picker or opening fade")
	if int((_game.get("party") as RefCounted).call("size")) != 1:
		_fail("starter state did not restore as exactly one owned creature")

	var tam_greeting := VILLAGE_NPCS.greeting_for(_tam(), progression)
	if tam_greeting == "village_tam_tools":
		_fail("Tam offered his one-time tool gift again after load")
	if int((_game.get("inventory") as RefCounted).call("count", TM_ID)) != expected_tm_count:
		_fail("the consumed TM duplicated or disappeared across load")
	if _world.get_node_or_null(TM_NODE) != null:
		_fail("the consumed TM respawned as a visible/actionable world prop")
	if _world.get_node_or_null(^"GateKey") != null:
		_fail("the equivalent consumed key pickup respawned after load")

	if not bool(_player.call("locomotion_enabled")):
		_fail("player locomotion remained locked after load")
	var before_move := _player.global_position
	Input.action_press("move_forward")
	for i in 30:
		await physics_frame
	Input.action_release("move_forward")
	for i in 5:
		await physics_frame
	if _player.global_position.distance_to(before_move) < 0.15:
		_fail("world controls did not move the trainer after load")

	# The title-screen path loads Game before Meadows exists. Rebuild the actual
	# world with the loaded state still resident and prove its async Terrain3D
	# startup cannot overwrite the slot's pose or restage the opening.
	await _reconstruct_world_and_verify_startup_pose(
		expected_position, expected_model_yaw, expected_camera_yaw, expected_camera_pitch)


func _reconstruct_world_and_verify_startup_pose(
		expected_position: Vector3,
		expected_model_yaw: float,
		expected_camera_yaw: float,
		expected_camera_pitch: float,
) -> void:
	_world.queue_free()
	for i in 10:
		await process_frame
	var packed := load(SCENE) as PackedScene
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	if not _collect_nodes():
		return
	if _player.global_position.distance_to(expected_position) > 0.001:
		_fail("title-before-world startup overwrote the saved position: expected %s, got %s" % [
			expected_position, _player.global_position])
	if absf(angle_difference(_model.global_rotation.y, expected_model_yaw)) > 0.0001:
		_fail("title-before-world startup overwrote the saved trainer facing")
	if absf(angle_difference(float(_rig.get("yaw")), expected_camera_yaw)) > 0.0001 \
			or absf(float(_rig.get("pitch")) - expected_camera_pitch) > 0.0001:
		_fail("title-before-world startup overwrote the saved camera view")
	if BEATS.index_of(str(_director.call("beat"))) < BEATS.index_of(BEATS.WALK_OUT) \
			or bool(_director.call("is_fading")) or bool(_picker.call("is_open")):
		_fail("a reconstructed loaded world replayed the completed opening")
	if _world.get_node_or_null(TM_NODE) != null or _world.get_node_or_null(^"GateKey") != null:
		_fail("a reconstructed loaded world respawned a consumed one-shot pickup")


func _play_conversation(id: String) -> void:
	if not bool(_dialogue.call("start", id)):
		_fail("dialogue panel refused production conversation '%s'" % id)
		return
	await _finish_open_conversation()


func _finish_open_conversation() -> void:
	var guard := 0
	while bool(_dialogue.call("is_open")) and guard < 96:
		await process_frame
		_dialogue.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 96:
		_fail("a production conversation never closed")


func _tam() -> Dictionary:
	var file := FileAccess.open("res://data/config/village_npcs.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for raw: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == "Tam":
			return raw as Dictionary
	return {}


func _find_by_script(from: Node, path: String) -> Node:
	if from.get_script() != null and str(from.get_script().resource_path) == path:
		return from
	for child in from.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


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


func _report() -> void:
	Input.action_release("move_forward")
	print("")
	if _failures.is_empty():
		print("PASS: exact pose, opening/starter, Tam gift, TM/key one-shots, and controls survived a real Meadows save/load")
		quit(0)
		return
	for message: String in _failures:
		print("FAIL: %s" % message)
	quit(1)
