extends "res://tools/capture_visual_audit.gd"
const SELECTED := {
	"meadows": ["env_band1_lower_meadows_0", "env_band2_stone_and_root_0", "env_band4_upper_meadows_ironwood_0"],
	"stormwood": ["env_cinder_verge_0", "env_glowmoss_hollows_0", "env_conductor_run_1"],
	"tidewake": ["env_first_shore_0", "env_reedhaven_0", "env_deep_watch_0"]
}
const CANDIDATES := {
	"Cover_flowers": {"placement_seed": 8830145, "drift_offset": Vector2(21.7, 37.3), "patch_start": 0.50, "patch_full": 0.70, "drift_contrast": 1.0, "density_gain": 1.4, "drift_scale": 0.07, "item_size": 0.52, "size_jitter": 0.45},
	"Cover_flowers_gold": {"placement_seed": 4417703, "drift_offset": Vector2(-19.2, 63.1), "patch_start": 0.56, "patch_full": 0.76, "drift_contrast": 1.0, "density_gain": 1.2, "drift_scale": 0.07, "item_size": 0.46, "size_jitter": 0.45},
	"Cover_strand_flowers": {"placement_seed": 202613, "drift_offset": Vector2(57.1, -29.3), "patch_start": 0.58, "patch_full": 0.78, "drift_contrast": 1.0, "density_gain": 0.5, "drift_scale": 0.05, "item_size": 0.48, "size_jitter": 0.38}
}
var _flowers: Array[Dictionary] = []

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await super._run()

func _build_rows(spec: Dictionary) -> Array:
	var selected: Array = []
	for source: Dictionary in super._build_rows(spec):
		if str(source.id) not in SELECTED.get(_region, []):
			continue
		var row := source.duplicate(true)
		row.id = "place_flower_review_" + str(source.id)
		row.times = ["calm", "break"] if _region == "stormwood" else ["day", "night"]
		selected.append(row)
	return selected

func _boot_region(spec: Dictionary) -> bool:
	if not await super._boot_region(spec):
		return false
	for node: Node in _world.find_children("Cover_*", "MultiMeshInstance3D", true, false):
		if not CANDIDATES.has(str(node.name)):
			continue
		var material := (node as MultiMeshInstance3D).material_override as ShaderMaterial
		var before := {}
		var after: Dictionary = CANDIDATES[str(node.name)].duplicate()
		for key: String in after:
			var value: Variant = material.get_shader_parameter(key)
			if value == null:
				value = Vector2.ZERO if key == "drift_offset" else 0
			before[key] = value
		_flowers.append({"name": str(node.name), "material": material, "before": before, "after": after})
		print("FLOWER_PATCH_MATERIAL ", node.get_path(), " before=", before, " after=", after)
	assert(not _flowers.is_empty())
	return true

func _apply_flower_variant(candidate: bool) -> void:
	for tier: Dictionary in _flowers:
		var parameters: Dictionary = tier.after if candidate else tier.before
		for key: String in parameters:
			(tier.material as ShaderMaterial).set_shader_parameter(key, parameters[key])

func _shoot(label: String, info: Dictionary) -> void:
	var pivot := _player.global_position + Vector3.UP * float(_rig.get("_height"))
	info["camera_arm_m"] = _rcam.global_position.distance_to(pivot)
	info["fixture"] = "staged location/party/flags/clock; HUD hidden; companion parked; candidate flower parameters changed in memory"
	if float(info.camera_arm_m) < 2.0:
		_skip(label, "camera spring collapsed")
		return
	for candidate: bool in [false, true]:
		_apply_flower_variant(candidate)
		for i in 24:
			await process_frame
		info["variant"] = "candidate" if candidate else "baseline"
		info["camera"] = _v(_rcam.global_position)
		await super._shoot(label + "_" + str(info.variant), info)
	_apply_flower_variant(false)
