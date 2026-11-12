extends "res://tests/test_case.gd"

## camera.json conversation.twoshot_v2.clearance_1112 (LANE-THINGS, T6): the
## player's head is kept out of the speaker's third. Ships OFF; the scoring
## and the swing choice are pure geometry on a hand-driven rig, as in
## test_conversation_camera.gd.

const RIG := preload("res://scripts/player/camera_rig.gd")
const CONVERSATION := preload("res://scripts/player/conversation_camera.gd")

var _rig: SpringArm3D = null
var _player: Node3D = null


func before_each() -> void:
	_player = Node3D.new()
	_rig = SpringArm3D.new()
	_rig.set_script(RIG)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	_rig.add_child(camera)
	_rig.notification(Node.NOTIFICATION_READY)
	_rig.set_target(_player)
	# Open air: every sweep is clear.
	_rig.set_occlusion_probe_for_tests(func(_pivot: Vector3, _dir: Vector3, limit: float) -> float: return limit)
	_rig.set_mesh_sight_probe_for_tests(func(_from: Vector3, _to: Vector3) -> bool: return false)


func after_each() -> void:
	for node: Node in [_rig, _player]:
		if node != null and is_instance_valid(node):
			node.free()


func _shipped() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/camera.json"))
	return ((parsed.get("conversation", {}) as Dictionary).get("twoshot_v2", {}) as Dictionary).get("clearance_1112", {})


func test_block_lives_in_the_villager_shot_and_names_its_scope() -> void:
	var block := _shipped()
	assert_true(bool(block.get("enabled", false)), "the judged clearance rule ships ON inside twoshot_v2 (G-things-convclear-meadows.md)")
	assert_true(bool((block.get("companion", {}) as Dictionary).get("enabled", false)), "with the companion step")
	assert_eq(str(block.get("scope", "")), "client_presentation")
	assert_false(CONVERSATION.profile_config("aftermath").has("clearance_1112"), "the aftermath profile does not inherit it")


func _shot(lens: Vector3, look_at: Vector3) -> Dictionary:
	var dir := (lens - look_at).normalized()
	return {"pivot": look_at, "dir": dir, "distance": lens.distance_to(look_at), "fov": 40.0}


func test_score_is_negative_with_the_trainer_in_front_of_the_speaker_and_clear_at_the_edge() -> void:
	var cfg := _shipped()
	var speaker := Vector3(0.0, 1.4, -3.0)
	var lens := Vector3(0.0, 1.6, 3.0)
	# Trainer straight between the lens and the speaker.
	var blocked: float = _rig._clearance_score(_shot(lens, speaker), Vector3(0.0, 1.45, 1.2), speaker, cfg)
	assert_true(blocked < 0.0, "a head on the speaker's line is not clear (%.2f)" % blocked)
	# Trainer well off to the side, near the frame edge.
	var clear: float = _rig._clearance_score(_shot(lens, speaker), Vector3(-1.05, 1.45, 1.2), speaker, cfg)
	assert_true(clear >= 0.0, "a shoulder at the frame edge is clear (%.2f)" % clear)
	# Trainer behind the lens is not in the picture at all.
	assert_eq(_rig._clearance_score(_shot(lens, speaker), Vector3(0.0, 1.45, 4.0), speaker, cfg), 1.0)


func test_a_blocked_shot_swings_to_a_clearer_one_and_a_clear_shot_is_untouched() -> void:
	var cfg: Dictionary = CONVERSATION.config().duplicate(true)
	var clear_cfg := _shipped().duplicate(true)
	clear_cfg["enabled"] = true
	var trainer := Vector3(0.0, 1.45, 0.0)
	var speaker := Vector3(0.0, 1.4, -2.4)
	# A shot straight down the pair's axis: the trainer covers the speaker.
	var straight := cfg.duplicate(true)
	straight["shoulder_yaw_deg"] = 0.0
	straight["close_shoulder_extra_deg"] = 0.0
	var shot: Dictionary = CONVERSATION.solve(trainer, speaker, Vector3.FORWARD, straight)
	var before: float = _rig._clearance_score(shot, trainer, speaker, clear_cfg)
	assert_true(before < 0.0, "the straight shot is blocked (%.2f)" % before)
	var swung: Dictionary = _rig._clearance_shot(shot, straight, INF, trainer, speaker, Vector3.FORWARD, clear_cfg)
	var after: float = _rig._clearance_score(swung, trainer, speaker, clear_cfg)
	assert_true(after > before + 0.07, "the swing clears the trainer (%.2f -> %.2f)" % [before, after])
	if after >= 0.0:
		var again: Dictionary = _rig._clearance_shot(swung, straight, INF, trainer, speaker, Vector3.FORWARD, clear_cfg)
		assert_eq(again, swung, "a clear shot is returned untouched")


## A stand-in for follower_creature.gd: the methods and the `leader` property
## the companion step reads.
class Follower extends Node3D:
	var leader: Node3D = null
	var following := true
	var placed := Vector3.INF
	func is_following() -> bool: return following
	func set_following(value: bool) -> void: following = value
	func height() -> float: return 2.6
	func place_on_ground(target: Vector3) -> bool:
		placed = target
		position = target
		return true


func test_the_trainers_own_follower_in_the_frame_steps_behind_the_lens_and_follows_again() -> void:
	var speaker := Node3D.new()
	speaker.position = Vector3(0.0, 0.0, -3.0)
	_rig._talk_speaker = speaker
	_rig._talk_cfg = {"clearance_1112": {"enabled": true, "companion": {"enabled": true, "behind_lens_m": 2.4, "margin_deg": 8.0}}}
	var lens := Vector3(0.6, 1.7, 2.6)
	_rig._talk_shot = _shot(lens, Vector3(0.0, 1.4, -2.0))
	var companion: Dictionary = _rig._companion_clear_config()
	assert_false(companion.is_empty())

	var mine := Follower.new()
	mine.leader = _player
	mine.position = Vector3(1.2, 0.0, -1.5)
	assert_true(_rig._step_companion_clear(mine, companion), "a follower beside the speaker is stepped away")
	assert_false(mine.following, "it holds its place while the shot is up")
	var look := (Vector3(0.0, 1.4, -2.0) - lens).normalized()
	assert_true((mine.placed - lens).dot(look) < 0.0, "it stands behind the lens")

	var theirs := Follower.new()
	theirs.leader = speaker
	theirs.position = Vector3(-1.2, 0.0, -1.5)
	assert_false(_rig._step_companion_clear(theirs, companion), "another trainer's creature is never moved")
	assert_true(theirs.following)

	var behind := Follower.new()
	behind.leader = _player
	behind.position = Vector3(0.6, 0.0, 6.0)
	assert_false(_rig._step_companion_clear(behind, companion), "a follower already behind the lens is left alone")

	_rig._release_companions()
	assert_true(mine.following, "it follows again when the conversation ends")
	for node: Node in [mine, theirs, behind, speaker]:
		node.free()


func test_companion_step_is_inert_with_the_flag_off() -> void:
	_rig._talk_cfg = {"clearance_1112": {"enabled": false}}
	assert_true(_rig._companion_clear_config().is_empty())
	_rig._talk_cfg = {}
	assert_true(_rig._companion_clear_config().is_empty())


## G-things-convclear-other-biomes.md: the rule is off in Stormwood.
func test_rule_is_scoped_off_stormwood_and_on_elsewhere() -> void:
	var block := _shipped()
	assert_eq(block.get("exclude_realms", []), ["stormwood"])
	var talk := {"clearance_1112": block}
	assert_true(RIG.clearance_for_realm(talk, "stormwood").is_empty(), "no clearance swing or companion step in Stormwood")
	for realm: String in ["meadows", "water", "cloudreach", ""]:
		assert_false(RIG.clearance_for_realm(talk, realm).is_empty(), "the rule runs in '%s'" % realm)
	var off := block.duplicate(true)
	off["enabled"] = false
	assert_true(RIG.clearance_for_realm({"clearance_1112": off}, "meadows").is_empty())
