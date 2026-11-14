extends "res://tests/test_case.gd"

## F13#5 `lesson_cue` (LANE-LAND-MT, 13 Nov; ON after G-land-mt-flowstreaks-r2): only the swim
## lesson's lanes lose their chop-cap crescents; every other lane keeps the
## shipped current look (F39#16 / F39#17 no-loss).

const VIEW := preload("res://scripts/world/water_current_flow_view.gd")


func _world() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	return parsed if parsed is Dictionary else {}


func _flow(enabled: bool) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var flow: Dictionary = ((parsed as Dictionary).get("current_flow", {}) as Dictionary).duplicate(true)
	(flow["lesson_cue"] as Dictionary)["enabled"] = enabled
	return flow


func _alphas(view: MeshInstance3D) -> Dictionary:
	var counts := {"lesson": 0, "other": 0}
	var colours: PackedColorArray = view.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	for colour in colours:
		counts["lesson" if colour.a < 0.5 else "other"] += 1
	return counts


func test_lesson_cue_ships_on_and_marks_only_its_lanes() -> void:
	var shipped: Dictionary = _flow(false).get("lesson_cue", {})
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var live: Dictionary = ((parsed as Dictionary).current_flow as Dictionary).lesson_cue
	assert_true(bool(live.enabled), "ships ON (GPU judged)")
	assert_true(str(live.get("_why_on", "")).contains("G-land-mt-flowstreaks-r2"), "_why_on cites the verdict")
	assert_eq(float(live.get("chop_cap_scale", -1.0)), 0.0, "judged chop_cap_scale")
	assert_eq(str(shipped.get("scope", "")), "client_presentation", "the flag declares scope")
	var ids: Array = shipped.get("current_ids", [])
	var known: Array = []
	for current: Dictionary in _world().get("currents", []):
		known.append(str(current.get("id", "")))
	for id: Variant in ids:
		assert_true(known.has(str(id)), "lesson lane %s exists" % str(id))
	var off := VIEW.new()
	off.build(_world(), _flow(false), null)
	assert_eq(int(_alphas(off).lesson), 0, "OFF marks no lane")
	var off_scale: Variant = (off.material_override as ShaderMaterial).get_shader_parameter("lesson_chop_scale")
	assert_true(off_scale == null or is_equal_approx(float(off_scale), 1.0), "OFF keeps the chop caps everywhere")
	off.free()
	var on := VIEW.new()
	on.build(_world(), _flow(true), null)
	var counts := _alphas(on)
	assert_true(int(counts.lesson) > 0 and int(counts.other) > 0, "ON marks the lesson lanes and only them")
	assert_eq(float((on.material_override as ShaderMaterial).get_shader_parameter("lesson_chop_scale")), 0.0,
		"ON drops the lesson lanes' chop caps")
	on.free()
