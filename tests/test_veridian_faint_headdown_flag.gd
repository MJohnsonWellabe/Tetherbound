extends "res://tests/test_case.gd"

## F39#6 Veridian faint head-down (creature_model_flags.json
## `creatures_ralph_veridian_faint_headdown`, tools/art_pipeline/lateral_recoil.py
## on the faint clip). Judged gain, ships ON. The copy keeps the live nat1024 mesh's
## textures and every clip.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS_PATH := "res://data/config/creature_model_flags.json"
const FLAG := "creatures_ralph_veridian_faint_headdown"
const DIR := "res://assets/creatures/tetherbound/veridian/candidate_nat1024/models/"
const LIVE := DIR + "creature_veridian_nat1024.glb"
const ARM := DIR + "creature_veridian_nat1024_faint_headdown.glb"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_model_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_arm_ships_on_with_its_score_and_resolves() -> void:
	var entry: Dictionary = _flags().get(FLAG, {})
	assert_true(bool(entry.get("enabled", false)), "%s ships ON (judged gain)" % FLAG)
	assert_true(str(entry.get("_why_on", "")).contains("6.30"), "it records its mapped score")
	assert_true(ResourceLoader.exists(ARM), "the arm's GLB is on disk")
	assert_eq(str((SPECIES.table()["veridian"]["placeholder"] as Dictionary).get("model", "")), ARM,
		"ON: Veridian wears the arm")


func test_off_keeps_the_live_mesh() -> void:
	var flags := _flags()
	(flags[FLAG] as Dictionary)["enabled"] = false
	var rows := {"veridian": {"placeholder": {"model": LIVE}}}
	SPECIES.merge_model_flags(rows, {FLAG: flags[FLAG]})
	assert_eq(str(rows["veridian"]["placeholder"]["model"]), LIVE, "OFF: Veridian keeps the live nat1024 mesh")


func test_the_arm_shares_the_live_textures_and_clips() -> void:
	var live: Node = (load(LIVE) as PackedScene).instantiate()
	var arm: Node = (load(ARM) as PackedScene).instantiate()
	var a := (live.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.surface_get_material(0) as BaseMaterial3D
	var b := (arm.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.surface_get_material(0) as BaseMaterial3D
	assert_eq(b.albedo_texture.resource_path, a.albedo_texture.resource_path, "the arm's albedo is the live extracted texture")
	var live_clips := (live.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation_list()
	var arm_clips := (arm.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation_list()
	assert_eq(arm_clips, live_clips, "the arm keeps every clip")
	live.free()
	arm.free()
