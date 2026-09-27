extends "res://tools/capture_visual_audit.gd"
## Same live scene/camera, sequential baseline/candidate at each disclosed fixture.
const SELECTED := {
	"meadows": ["env_band1_lower_meadows_0", "env_band2_stone_and_root_0", "env_band4_upper_meadows_ironwood_0"],
	"cloudreach": ["env_gate_lower_cliffs_1", "env_windscar_ravine_0", "env_high_roost_sky_shrine_1"],
	"stormwood": ["env_cinder_verge_0", "env_glowmoss_hollows_0", "env_conductor_run_1"],
	"tidewake": ["env_first_shore_0", "env_brine_steps_1", "env_deep_watch_0"]
}
var _cover_shader: Shader
var _baseline_code: String
var _candidate_code: String

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await super._run()

func _region_spec(region: String) -> Dictionary:
	var spec := super._region_spec(region)
	if region == "cloudreach":
		(spec["flags"] as Array).erase("fly_tutorial_completed")
	return spec

func _build_rows(spec: Dictionary) -> Array:
	var selected: Array = []
	for source: Dictionary in super._build_rows(spec):
		if str(source.id) not in SELECTED.get(_region, []):
			continue
		var row := source.duplicate(true)
		row.id = "place_grass_review_" + str(source.id)
		row.times = ["calm", "break"] if _region == "stormwood" else ["day", "night"]
		selected.append(row)
	return selected

func _boot_region(spec: Dictionary) -> bool:
	var ok := await super._boot_region(spec)
	if not ok:
		return false
	var path := "res://shaders/cloudreach_ground_cover.gdshader" if _region == "cloudreach" else "res://shaders/grass_field.gdshader"
	_cover_shader = load(path) as Shader
	_baseline_code = _cover_shader.code
	var guard := "camera_clearance && " if _region == "cloudreach" else ""
	_candidate_code = _baseline_code.replace("void fragment() {", "void fragment() {\n\tif (" + guard + "!FRONT_FACING) { NORMAL = -NORMAL; }")
	assert(_candidate_code != _baseline_code)
	print("GRASS_NORMAL_PROBE ", path, " baseline=", _baseline_code.sha256_text(), " candidate=", _candidate_code.sha256_text())
	return true

func _shoot(label: String, info: Dictionary) -> void:
	var pivot := _player.global_position + Vector3.UP * float(_rig.get("_height"))
	info["camera_arm_m"] = _rcam.global_position.distance_to(pivot)
	info["fixture"] = "staged location/party/flags/clock; HUD hidden; companion parked; candidate changes loaded grass shader in memory only"
	if float(info.camera_arm_m) < 2.0:
		_skip(label, "camera spring collapsed; invalid grass view")
		return
	for candidate: bool in [false, true]:
		_cover_shader.code = _candidate_code if candidate else _baseline_code
		for i in 24:
			await process_frame
		info["variant"] = "candidate" if candidate else "baseline"
		info["camera"] = _v(_rcam.global_position)
		await super._shoot(label + "_" + str(info.variant), info)
	_cover_shader.code = _baseline_code
