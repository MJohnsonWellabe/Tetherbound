extends "res://tests/test_case.gd"

## Owner ruling 2026-09-26, "rejoin returns to exact spot" (MULTIPLAYER
## Return-home placement): a saved pose is resumed only in the host world whose
## snapshot instance equals the character's `last_world_instance_id`.

const REJOIN_POSE := preload("res://scripts/mp/rejoin_pose.gd")
const TITLE := preload("res://scripts/ui/title_screen.gd")
const GAME_STATE := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const TEST_DIR := "user://test_rejoin_pose/"
const HOST_A := "instance-host-a"
const POSE := {"realm": "meadows", "position": [12.5, 3.0, -40.0],
	"model_yaw": 1.2, "camera_yaw": 1.1, "camera_pitch": -0.3}


func _candidate(instance: Variant, pose: Dictionary = POSE) -> Dictionary:
	return {"pose": pose, "world_instance_id": instance}


func test_the_same_host_world_seats_the_saved_pose() -> void:
	var seated: Dictionary = REJOIN_POSE.decide(_candidate(HOST_A), HOST_A, "meadows")
	assert_eq(seated, POSE, "a matching instance returns the exact saved pose")


func test_a_different_or_unknown_world_keeps_the_regional_spawn() -> void:
	assert_true(REJOIN_POSE.decide(_candidate(HOST_A), "instance-host-b", "meadows").is_empty(),
		"another host's world")
	assert_true(REJOIN_POSE.decide(_candidate(""), "", "meadows").is_empty(),
		"an empty instance is never a match, even against an empty host value")
	assert_true(REJOIN_POSE.decide(_candidate(null), HOST_A, "meadows").is_empty(),
		"a character file without provenance")
	assert_true(REJOIN_POSE.decide(_candidate(HOST_A), null, "meadows").is_empty(),
		"a host snapshot without an instance")
	assert_true(REJOIN_POSE.decide({}, HOST_A, "meadows").is_empty(), "a new character")


func test_a_pose_from_another_realm_or_malformed_is_not_seated() -> void:
	assert_true(REJOIN_POSE.decide(_candidate(HOST_A), HOST_A, "stormwood").is_empty(),
		"the guest is standing in another realm")
	var bad := POSE.duplicate(true)
	bad["position"] = [1.0, INF, 2.0]
	assert_true(REJOIN_POSE.decide(_candidate(HOST_A, bad), HOST_A, "meadows").is_empty(), "not finite")
	bad["position"] = [1.0, 2.0]
	assert_true(REJOIN_POSE.decide(_candidate(HOST_A, bad), HOST_A, "meadows").is_empty(), "too short")
	assert_true(REJOIN_POSE.decide(_candidate(HOST_A, {}), HOST_A, "meadows").is_empty(), "no pose")


func test_the_candidate_is_read_from_the_character_file() -> void:
	_wipe()
	var game: Node = GAME_STATE.new()
	var saver: RefCounted = SAVE_GAME.new(TEST_DIR)
	game.save_system = saver
	game.reset_for_new_game()
	game.local.character_id = "rejoin-rin"
	assert_true(TITLE.rejoin_pose_candidate(game).is_empty(), "no file yet")
	game.local.pose = POSE.duplicate(true)
	var characters: RefCounted = saver.characters()
	assert_true(bool(characters.write("rejoin-rin", game.local.save_data(),
		{"last_world_instance_id": HOST_A})), "fixture character must save")
	var candidate: Dictionary = TITLE.rejoin_pose_candidate(game)
	assert_eq(str(candidate.get("world_instance_id")), HOST_A)
	assert_eq(candidate.get("pose"), POSE)
	game.free()
	_wipe()


func _wipe() -> void:
	for dir_path: String in [TEST_DIR, TEST_DIR + "characters/"]:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		for sub: String in dir.get_directories():
			var inner := DirAccess.open(dir_path + sub)
			if inner != null:
				for f: String in inner.get_files():
					inner.remove(f)
			dir.remove(sub)
		for f: String in dir.get_files():
			dir.remove(f)
