extends "res://tests/test_case.gd"
const WATER := preload("res://scripts/save/water_traversal_save.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

func _pose() -> Dictionary:
	return {"realm": "water", "position": [66.0, -0.7, 174.0], "model_yaw": 0.0,
		"camera_yaw": 0.0, "camera_pitch": 0.0, "aquatic": {"version": 1, "mode": 1,
		"stamina_fraction": 0.0, "health_fraction": 0.41, "safe_anchor": [57.3, 1.9, 151.5]}}

func test_exhaustion_survives_json_and_pose_sanitisation_without_session_ids() -> void:
	var pose := _pose()
	pose.aquatic.owner_peer_id = 234
	pose.aquatic.revision = 999
	var save := SAVE.new("user://water_traversal_unit")
	var clean: Dictionary = save._sanitise_player_pose(JSON.parse_string(JSON.stringify(pose)))
	assert_eq(clean.position, pose.position)
	assert_eq(clean.aquatic.stamina_fraction, 0.0)
	assert_eq(clean.aquatic.health_fraction, 0.41)
	assert_false(clean.aquatic.has("owner_peer_id"))
	assert_false(clean.aquatic.has("revision"))
	assert_eq(clean.aquatic.safe_anchor, pose.aquatic.safe_anchor)

func test_corrupt_aquatic_data_rejects_the_entire_pose() -> void:
	for key in ["stamina_fraction", "health_fraction"]:
		for value: Variant in [NAN, INF, -0.1, 1.1, "0.4", null]:
			var pose := _pose()
			pose.aquatic[key] = value
			assert_true(SAVE.new()._sanitise_player_pose(pose).is_empty())
	for value: Variant in [null, [1.0], [0.0, NAN, 0.0], [0, "land", 0]]:
		var pose := _pose()
		pose.aquatic.safe_anchor = value
		assert_true(SAVE.new()._sanitise_player_pose(pose).is_empty())

func test_old_pose_is_preserved_and_aquatic_state_cannot_attach_to_another_realm() -> void:
	var pose := _pose()
	pose.erase("aquatic")
	assert_eq(SAVE.new()._sanitise_player_pose(pose), pose)
	pose = _pose()
	pose.realm = "meadows"
	assert_true(SAVE.new()._sanitise_player_pose(pose).is_empty())

func test_pause_and_mount_modes_are_data_without_importing_transport_revision() -> void:
	for mode in [0, 1, 2, 3]:
		var raw: Dictionary = _pose().aquatic
		raw.mode = mode
		assert_eq(WATER.sanitise(raw).mode, mode)
	for mode: Variant in [-1, 4, 1.5, "1", INF]:
		var raw: Dictionary = _pose().aquatic
		raw.mode = mode
		assert_true(WATER.sanitise(raw).is_empty())
