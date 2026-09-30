extends "res://tests/test_case.gd"

const FIT := preload("res://scripts/combat/fight_camera.gd")
const RIG := preload("res://scripts/player/camera_rig.gd")

func test_nine_authored_pairs_project_both_bodies_without_silhouette_overlap() -> void:
	var cfg := FIT.config()
	assert_eq((cfg.get("size_matrix", {}) as Dictionary).size(), 9)
	var heights := {"small": 2.0, "normal": 4.0, "giant": 8.0}
	for ally_class: String in heights:
		for foe_class: String in heights:
			var a := _body(float(heights[ally_class]), Vector3.ZERO)
			var gap := (a.size.x + float(heights[foe_class]) * 0.7) * 0.5 + 0.6
			var b := _body(float(heights[foe_class]), Vector3(0.0, 0.0, -gap))
			for aspect: float in [16.0 / 9.0, 16.0 / 10.0]:
				var fit := FIT.solve(a, b, deg_to_rad(35.0), deg_to_rad(-25.0), 68.0, aspect, 9.5, cfg)
				var pair := ally_class + "/" + foe_class
				assert_eq(str(fit.get("pair", "")), pair)
				assert_true(bool(fit.get("pass", false)), pair + " fully framed without projected-box overlap: " + str(fit))
				assert_true(float(fit.get("overlap", 1.0)) <= 0.0, pair)
				assert_eq(a.size.y, float(heights[ally_class]), "fit never shrinks the actual actor")
				assert_eq(b.size.y, float(heights[foe_class]))

func test_pivot_uses_actual_body_midpoint_and_class_boundaries() -> void:
	var cfg := FIT.config()
	assert_eq(FIT.size_class(2.5, cfg), "small")
	assert_eq(FIT.size_class(2.501, cfg), "normal")
	assert_eq(FIT.size_class(5.0, cfg), "normal")
	assert_eq(FIT.size_class(5.001, cfg), "giant")
	var a := _body(2.0, Vector3(100.0, 12.0, 400.0))
	var b := _body(4.0, Vector3(104.0, 16.0, 392.0))
	var profile := FIT.pair_profile(a, b, cfg)
	var expected := a.get_center().lerp(b.get_center(), float(cfg.midpoint_bias)) + Vector3.UP * float(profile.height_offset_m)
	assert_eq(FIT.pivot(a, b, cfg, profile), expected, "composition follows the two rendered bounds, never arena origin")

func test_impossible_and_near_plane_frames_never_report_a_pass() -> void:
	var cfg := FIT.config().duplicate(true)
	cfg["max_distance_m"] = 0.2
	var body := _body(8.0, Vector3.ZERO)
	var fit := FIT.solve(body, body, 0.0, 0.0, 68.0, 16.0 / 9.0, 9.5, cfg)
	assert_false(bool(fit.get("pass", false)), "distance cap cannot turn a clipped/coincident pair into accepted framing")
	assert_false(bool(FIT.project_box(body, Transform3D.IDENTITY, 68.0, 16.0/9.0, 0.05).get("valid", false)))
	assert_almost_eq(FIT.overlap_ratio(Rect2(0,0,2,2), Rect2(1,0,1,2)), 1.0, 0.0001, "overlap denominator is the smaller actor")
	assert_eq(FIT.overlap_ratio(Rect2(0,0,1,1), Rect2(2,0,1,1)), 0.0)

func test_rig_takeover_clears_midpoint_offset_and_runtime_pitch_is_not_accumulated() -> void:
	var cfg := FIT.config()
	var a := _body(8.0, Vector3.ZERO)
	var b := _body(2.0, Vector3(0,0,-6))
	var fit := FIT.solve(a,b,deg_to_rad(35),deg_to_rad(-30),68,16.0/9.0,9.5,cfg,false)
	assert_almost_eq(float(fit.pitch), deg_to_rad(-30), 0.0001, "takeover applies profile pitch once; live frames preserve it")
	var rig := RIG.new()
	rig.set_framing_pivot_offset(Vector3(2,1,3))
	assert_eq(rig.framing_pivot_offset(), Vector3(2,1,3))
	rig.set_framing_pivot_offset(Vector3.INF)
	assert_eq(rig.framing_pivot_offset(), Vector3.ZERO)
	rig.set_framing_pivot_offset(Vector3(2,1,3))
	rig.set_target(null)
	assert_eq(rig.framing_pivot_offset(), Vector3.ZERO, "throw, exploration and new targets cannot inherit fight composition")
	rig.free()

func _body(height: float, feet: Vector3) -> AABB:
	var width := height * 0.7
	return AABB(feet - Vector3(width*0.5,0,width*0.5), Vector3(width,height,width))
