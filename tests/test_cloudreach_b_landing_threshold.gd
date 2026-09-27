extends "res://tests/test_case.gd"

## F06#2 (coordinator ruling on #356, Q1): an invalid Fly touchdown cannot be
## reached by ordinary input because the host landing arbiter's slope rule and
## the trainer controller's floor angle are the same 45-degree limit: any
## surface the controller will stand on, the arbiter accepts, and any surface
## the arbiter refuses as "too steep" the controller slides off before a
## landing is claimed. This pins that equality so a later tune of either side
## re-opens the invalid-landing question instead of silently changing it.

const ARBITER := preload("res://scripts/net/fly_anchor_arbiter.gd")
const FLY := preload("res://scripts/player/fly_controller.gd")
const PLAYER_SCENE := "res://scenes/player/player.tscn"
const REMOTE_SCENE := "res://scenes/player/remote_trainer.tscn"


func _configured_min_normal_y() -> float:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FLY.CONFIG_PATH))
	var block: Dictionary = config.get("landing_anchor", {})
	return ARBITER._tunable({"config": block}, "min_normal_y", ARBITER.DEFAULT_MIN_NORMAL_Y)


func _floor_max_angle(scene_path: String) -> float:
	var body := (load(scene_path) as PackedScene).instantiate() as CharacterBody3D
	var angle := body.floor_max_angle
	body.free()
	return angle


func test_arbiter_min_normal_equals_player_floor_angle() -> void:
	var min_normal_y := _configured_min_normal_y()
	var angle := _floor_max_angle(PLAYER_SCENE)
	assert_almost_eq(min_normal_y, cos(angle), 0.001,
		"arbiter min_normal_y %.4f vs cos(player floor_max_angle %.4f) = %.4f" % [min_normal_y, angle, cos(angle)])


func test_arbiter_min_normal_equals_remote_trainer_floor_angle() -> void:
	var min_normal_y := _configured_min_normal_y()
	var angle := _floor_max_angle(REMOTE_SCENE)
	assert_almost_eq(min_normal_y, cos(angle), 0.001,
		"arbiter min_normal_y %.4f vs cos(remote floor_max_angle %.4f) = %.4f" % [min_normal_y, angle, cos(angle)])


func test_default_matches_configured_value() -> void:
	assert_almost_eq(ARBITER.DEFAULT_MIN_NORMAL_Y, _configured_min_normal_y(), 0.0001,
		"the arbiter's fallback and fly_traversal.json agree")
