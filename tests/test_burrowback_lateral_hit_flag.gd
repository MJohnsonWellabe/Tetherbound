extends "res://tests/test_case.gd"

## F38#2 Burrowback/Nightburrow lateral hit recoil (creature_model_flags.json
## `creatures_ralph_burrowback_lateral_hit`, tools/art_pipeline/lateral_recoil.py
## then hold_clip.py). Judged gain, ships ON. The copy keeps the live mesh's
## textures, so the Nightburrow aspect repaint and coat flags still resolve.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS_PATH := "res://data/config/creature_model_flags.json"
const FLAG := "creatures_ralph_burrowback_lateral_hit"
const DIR := "res://assets/creatures/tetherbound/burrowback/candidate_nat1024/models/"
const LIVE := DIR + "creature_burrowback_nat1024.glb"
const ARM := DIR + "creature_burrowback_nat1024_lateral_hit.glb"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_model_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_arm_ships_on_with_its_score() -> void:
	var entry: Dictionary = _flags().get(FLAG, {})
	assert_true(bool(entry.get("enabled", false)), "%s ships ON (judged gain)" % FLAG)
	assert_true(str(entry.get("_why_on", "")).contains("6.40"), "it records its mapped score")
	assert_true(ResourceLoader.exists(ARM), "the arm's GLB is on disk")
	for id: String in ["burrowback", "nightburrow"]:
		var spec: Dictionary = (entry.get("species", {}) as Dictionary).get(id, {})
		assert_eq(str(spec.get("model", "")), ARM, "%s points at the arm" % id)


func test_on_resolves_the_arm_and_off_keeps_the_live_mesh() -> void:
	for id: String in ["burrowback", "nightburrow"]:
		var look: Dictionary = SPECIES.table()[id]["placeholder"]
		assert_eq(str(look.get("model", "")), ARM, "ON: %s wears the arm" % id)
	var flags := _flags()
	(flags[FLAG] as Dictionary)["enabled"] = false
	var rows := {}
	for id: String in ["burrowback", "nightburrow"]:
		rows[id] = {"placeholder": {"model": LIVE}}
	SPECIES.merge_model_flags(rows, {FLAG: flags[FLAG]})
	for id: String in rows:
		assert_eq(str(rows[id]["placeholder"]["model"]), LIVE, "OFF: %s keeps the live mesh" % id)


func test_the_arm_shares_the_live_textures_and_clips() -> void:
	var live: Node = (load(LIVE) as PackedScene).instantiate()
	var arm: Node = (load(ARM) as PackedScene).instantiate()
	var live_mesh := live.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arm_mesh := arm.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var a := live_mesh.mesh.surface_get_material(0) as BaseMaterial3D
	var b := arm_mesh.mesh.surface_get_material(0) as BaseMaterial3D
	assert_eq(b.albedo_texture.resource_path, a.albedo_texture.resource_path,
		"the arm's albedo is the live extracted texture, so the aspect repaint resolves")
	var live_clips := (live.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation_list()
	var arm_clips := (arm.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation_list()
	assert_eq(arm_clips, live_clips, "the arm keeps every clip")
	live.free()
	arm.free()
