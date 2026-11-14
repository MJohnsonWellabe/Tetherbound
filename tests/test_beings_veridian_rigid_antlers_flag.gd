extends "res://tests/test_case.gd"

## BEINGS-VERIDIAN-ANTLER (F36#85): creature_model_flags.json
## `beings_veridian_rigid_antlers`, OFF until GPU-judged. The arm is a copy of
## the live faint_headdown GLB whose antler vertices follow the head bone alone
## (tools/art_pipeline/rigid_bind_region.py, then relax_stretched_weights.py).
## Mesh, textures and clips are the live model's.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS_PATH := "res://data/config/creature_model_flags.json"
const FLAG := "beings_veridian_rigid_antlers"
const DIR := "res://assets/creatures/tetherbound/veridian/candidate_nat1024/models/"
const LIVE := DIR + "creature_veridian_nat1024_faint_headdown.glb"
const ARM := DIR + "creature_veridian_nat1024_rigidantler.glb"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_model_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_flag_is_off_and_declares_scope() -> void:
	var entry: Dictionary = _flags().get(FLAG, {})
	assert_false(entry.is_empty(), "%s exists" % FLAG)
	assert_false(bool(entry.get("enabled", true)), "%s is OFF until GPU-judged" % FLAG)
	assert_true(str(entry.get("scope", "")).contains("no state"), "it declares a presentation-only scope")
	assert_eq(str((SPECIES.table()["veridian"]["placeholder"] as Dictionary).get("model", "")), LIVE,
		"OFF: Veridian keeps the live model")


func test_on_swaps_only_veridians_model() -> void:
	var flags := _flags()
	var entry: Dictionary = (flags[FLAG] as Dictionary).duplicate(true)
	entry["enabled"] = true
	var rows := {"veridian": {"placeholder": {"model": LIVE}}, "solmane": {"placeholder": {"model": "x"}}}
	SPECIES.merge_model_flags(rows, {FLAG: entry})
	assert_eq(str(rows["veridian"]["placeholder"]["model"]), ARM, "ON: Veridian wears the rigid-antler copy")
	assert_eq(str(rows["solmane"]["placeholder"]["model"]), "x", "no other species changes")


func test_the_arm_shares_the_live_mesh_textures_and_clips() -> void:
	var live: Node = (load(LIVE) as PackedScene).instantiate()
	var arm: Node = (load(ARM) as PackedScene).instantiate()
	var live_mesh := (live.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var arm_mesh := (arm.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var a := live_mesh.surface_get_material(0) as BaseMaterial3D
	var b := arm_mesh.surface_get_material(0) as BaseMaterial3D
	assert_eq(b.albedo_texture.resource_path, a.albedo_texture.resource_path, "the arm's albedo is the live texture")
	assert_eq((arm_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(),
		(live_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), "same vertex count")
	assert_eq(arm_mesh.get_aabb(), live_mesh.get_aabb(), "same rest bounds")
	var live_clips := (live.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation_list()
	var arm_clips := (arm.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation_list()
	assert_eq(arm_clips, live_clips, "the arm keeps every clip")
	live.free()
	arm.free()


func test_antler_vertices_follow_the_head_alone() -> void:
	var arm: Node = (load(ARM) as PackedScene).instantiate()
	var instance := arm.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := instance.mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var bones := arrays[Mesh.ARRAY_BONES] as PackedInt32Array
	var weights := arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array
	var stride := int(bones.size() / vertices.size())
	var head := -1
	for bind in instance.skin.get_bind_count():
		if str(instance.skin.get_bind_name(bind)) == "head":
			head = bind
	assert_true(head >= 0, "the skin has a head bind")
	var bounds := instance.mesh.get_aabb()
	var cut := bounds.position.y + bounds.size.y * 0.7
	var checked := 0
	var loose := 0
	for i in vertices.size():
		if vertices[i].y < cut:
			continue
		checked += 1
		var on_head := 0.0
		for k in stride:
			if bones[i * stride + k] == head:
				on_head += weights[i * stride + k]
		if on_head < 0.98:
			loose += 1
	assert_true(checked > 1000, "the antlers are sampled (%d vertices)" % checked)
	assert_eq(loose, 0, "every antler vertex above 70% height is bound to the head alone")
	arm.free()
