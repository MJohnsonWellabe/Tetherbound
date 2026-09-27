extends "res://tests/test_case.gd"

## F14#2 (V-TW-1, V-VIS-12): the Tidewake current foam look follows
## `water_currents_restored` as a whole parameter set, not only calm_scale.
## The before (live) and after (restored) sets must differ materially in each
## named parameter, and the applied material uniforms must follow the flag
## (set, clear, and a rebuilt view reading an already-restored store).
const VIEW := preload("res://scripts/world/water_current_flow_view.gd")
const FLAG := "water_currents_restored"
## Each named parameter, and the minimum live:restored ratio that makes the
## change read at a glance (VIS fix list: >= 60 % less foam, >= 3x speed).
const MATERIAL_RATIOS := {
	"opacity": 2.0,
	"lane_opacity": 3.0,
	"streak_density": 2.5,
	"dash_fill": 2.5,
	"fleck_amount": 5.0,
	"speed_scale": 3.0,
	"brightness": 1.2,
}

class Flags:
	extends RefCounted
	var ids: Dictionary = {}
	func has(id: String) -> bool:
		return ids.has(id)
	func set_flag(id: String, value: bool = true) -> void:
		if value:
			ids[id] = true
		else:
			ids.erase(id)


func _config() -> Dictionary:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	return all.get("current_flow", {})


func _world() -> Dictionary:
	return {"terrain": {"sea_level_m": 0.0}, "currents": [{
		"id": "probe", "polyline": [[0, 0, 0], [0, 0, 100]], "width_m": 20.0,
		"flow_direction_xz": [0, -1], "strength_m_s": 1.3}]}


func _view(flags: Flags) -> MeshInstance3D:
	var view: MeshInstance3D = VIEW.new()
	view.build(_world(), _config(), flags)
	return view


func _uniform(view: MeshInstance3D, key: String) -> float:
	return float((view.material_override as ShaderMaterial).get_shader_parameter(key))


func test_live_and_restored_sets_differ_materially_in_every_named_parameter() -> void:
	var view := _view(Flags.new())
	var live: Dictionary = view.state_parameters(false)
	var restored: Dictionary = view.state_parameters(true)
	for key: String in MATERIAL_RATIOS:
		assert_true(live.has(key) and restored.has(key), "both states declare " + key)
		var before := float(live.get(key, 0.0))
		var after := float(restored.get(key, 0.0))
		assert_true(after > 0.0 and before >= after * float(MATERIAL_RATIOS[key]),
			"%s live %.3f vs restored %.3f differs by >= %.1fx" % [key, before, after, MATERIAL_RATIOS[key]])
	assert_true(float(restored.calm_scale) < float(live.calm_scale), "calm_scale drops when restored")
	# Effective streak scroll at an authored 1.3 m/s current (full 1.8 m/s).
	var strength := 1.3 / float(_config().get("full_strength_m_s", 1.8))
	var scroll_live := maxf(float(live.min_speed_m_s), strength * float(live.speed_scale)) * float(live.calm_scale)
	var scroll_calm := maxf(float(restored.min_speed_m_s), strength * float(restored.speed_scale)) * float(restored.calm_scale)
	assert_true(scroll_live >= scroll_calm * 3.0, "streak drift %.2f vs %.2f m/s is >= 3x" % [scroll_live, scroll_calm])
	view.free()


func test_applied_uniforms_follow_the_flag_both_ways() -> void:
	var flags := Flags.new()
	var view := _view(flags)
	var live: Dictionary = view.state_parameters(false)
	var restored: Dictionary = view.state_parameters(true)
	for key: String in MATERIAL_RATIOS:
		assert_almost_eq(_uniform(view, key), float(live[key]), 0.0001, "unrestored build applies live " + key)
	flags.set_flag(FLAG)
	view.call("_refresh", false)
	assert_true(view.is_restored_look(), "view switches to the restored look")
	for key: String in MATERIAL_RATIOS:
		assert_almost_eq(_uniform(view, key), float(restored[key]), 0.0001, "flag set applies restored " + key)
	assert_almost_eq(_uniform(view, "calm_scale"), float(_config().restored_calm_scale), 0.0001, "calm_scale follows")
	flags.set_flag(FLAG, false)
	view.call("_refresh", false)
	for key: String in MATERIAL_RATIOS:
		assert_almost_eq(_uniform(view, key), float(live[key]), 0.0001, "flag cleared restores live " + key)
	assert_almost_eq(_uniform(view, "calm_scale"), 1.0, 0.0001, "calm_scale back to 1.0")
	view.free()


func test_rebuilt_view_over_restored_store_starts_restored() -> void:
	var flags := Flags.new()
	flags.set_flag(FLAG)
	var view := _view(flags)
	var restored: Dictionary = view.state_parameters(true)
	assert_true(view.is_restored_look(), "reload/rebuild reads the restored state at build")
	for key: String in MATERIAL_RATIOS:
		assert_almost_eq(_uniform(view, key), float(restored[key]), 0.0001, "rebuilt view applies restored " + key)
	view.free()


func test_shader_declares_every_state_uniform() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/water_current_flow.gdshader")
	for key: String in MATERIAL_RATIOS.keys() + ["calm_scale", "min_speed_m_s"]:
		assert_true(code.contains("uniform float " + key), "shader declares " + key)
