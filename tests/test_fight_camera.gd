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

func test_manual_orbit_cannot_be_replaced_by_an_appended_side_view() -> void:
	var cfg := FIT.config().duplicate(true)
	cfg["orbit_candidates_deg"] = [0.0]
	cfg["allow_pair_side_views"] = false
	var a := _body(8.0,Vector3.ZERO)
	var b := _body(2.0,Vector3(0,0,-6))
	var fit := FIT.solve(a,b,0.0,deg_to_rad(-30),68.0,16.0/9.0,9.5,cfg,false)
	assert_eq(float(fit.yaw_offset_deg),0.0,"manual look keeps its exact requested yaw even when that composition overlaps")
	assert_true(float(fit.distance)<=float(cfg.max_distance_m),"a separation request never exceeds the configured hard cap")

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
	rig.set_fight_yaw_target(1.2)
	assert_eq(rig.get("_fight_yaw_target"),1.2)
	rig.set_target(null)
	assert_eq(rig.framing_pivot_offset(), Vector3.ZERO, "throw, exploration and new targets cannot inherit fight composition")
	assert_eq(rig.get("_fight_yaw_target"),null,"aim/exit clears solved absolute fight orbit")
	rig.free()

func test_rotated_model_corners_separate_without_world_aabb_inflation_or_false_lens_collapse() -> void:
	var local := AABB(Vector3(-2,0,-0.4),Vector3(4,2,0.8))
	var basis := Basis(Vector3.UP,PI*0.25)
	var pose_a := Transform3D(basis,Vector3.ZERO)
	var pose_b := Transform3D(basis,basis.z*1.4)
	var a: AABB = pose_a*local
	var b: AABB = pose_b*local
	assert_true(a.intersects(b),"axis-aligned enclosing boxes overlap in empty rotated corner volume")
	var points_a := FIT.box_points(local,pose_a)
	var points_b := FIT.box_points(local,pose_b)
	var fit := FIT.solve(a,b,PI*0.75,deg_to_rad(-25),68,16.0/9.0,9.5,FIT.config(),false,points_a,points_b)
	assert_true(bool(fit.get("pass",false)),"actual rotated measured model boxes remain separable: "+str(fit))
	assert_eq(float(fit.get("overlap",1.0)),0.0,"strict zero overlap is retained")
	assert_eq(float(fit.get("yaw_offset_deg",1000)),0.0,"already-clear current orbit does not chase a different neutral heading")
	var camera_basis := Basis.from_euler(Vector3(float(fit.pitch),PI*0.75,0))
	var shot := Transform3D(camera_basis,(fit.pivot as Vector3)+camera_basis.z*float(fit.distance))
	var projected_a := FIT.project_points(points_a,shot,68,16.0/9.0,0.05)
	var projected_b := FIT.project_points(points_b,shot,68,16.0/9.0,0.05)
	assert_true(bool(projected_a.in_frame) and bool(projected_b.in_frame))
	assert_eq(FIT.overlap_ratio(projected_a.rect,projected_b.rect),0.0)
	assert_eq(local.size,Vector3(4,2,0.8),"measurement never changes model/collision size")
	assert_eq(points_a.size(),8)
	for index: int in 8: assert_eq(points_a[index],pose_a*local.get_endpoint(index))
	assert_eq(FIT.oriented_body_limit(Vector3(1.6,3,1.6),Vector3(1.6,-2,1.6),local,pose_a,0.1,0.1),INF,
		"empty enclosing-box corner cannot collapse the lens to its minimum arm")
	var hit := FIT.oriented_body_limit(Vector3(0,3,0),Vector3(0,-2,0),local,pose_a,0.1,0.1)
	assert_true(is_finite(hit) and hit>0.0 and hit<=1.0,"actual model intersection still limits the lens")
	var clipped_probe := func(point: Vector3, probe_basis: Basis, _distance: float) -> Dictionary:
		return {"pivot":point,"distance":0.2,"transform":Transform3D(probe_basis,point+probe_basis.z*0.2)}
	var constrained := FIT.solve(a,b,PI*0.75,deg_to_rad(-25),68,16.0/9.0,9.5,FIT.config(),false,points_a,points_b,clipped_probe)
	assert_false(bool(constrained.get("pass",false)),"requested clear fit cannot bypass an actual clipped lens constraint")

	# Exact measured native9507 giant/giant observed55. Bodies were SAT-
	# disjoint, but coarse yaw neighbours were respectively body-blocked and
	# projected-overlapping. World sweeps remain a separate native obligation.
	var native_ally := PackedVector3Array([
		Vector3(23.6987113952637,1.2938756942749,-40.1333312988281),
		Vector3(24.2533416748047,1.2938756942749,-44.9994659423828),
		Vector3(23.6987113952637,7.09387588500977,-40.1333312988281),
		Vector3(24.2533416748047,7.09387588500977,-44.9994659423828),
		Vector3(18.9748802185059,1.2938756942749,-40.671745300293),
		Vector3(19.5295124053955,1.2938756942749,-45.5378799438477),
		Vector3(18.9748802185059,7.09387588500977,-40.671745300293),
		Vector3(19.5295124053955,7.09387588500977,-45.5378799438477),
	])
	var native_foe := PackedVector3Array([
		Vector3(29.7458400726318,0.621477842330933,-42.5906524658203),
		Vector3(24.9101886749268,0.621477842330933,-43.367301940918),
		Vector3(29.7458400726318,6.42147827148438,-42.5906524658203),
		Vector3(24.9101886749268,6.42147827148438,-43.367301940918),
		Vector3(28.9919033050537,0.621477842330933,-37.8964157104492),
		Vector3(24.1562519073486,0.621477842330933,-38.6730651855469),
		Vector3(28.9919033050537,6.42147827148438,-37.8964157104492),
		Vector3(24.1562519073486,6.42147827148438,-38.6730651855469),
	])
	var ally_box := AABB(native_ally[0],Vector3.ZERO)
	var foe_box := AABB(native_foe[0],Vector3.ZERO)
	for corner: Vector3 in native_ally: ally_box = ally_box.expand(corner)
	for corner: Vector3 in native_foe: foe_box = foe_box.expand(corner)
	var foe_edges := [native_foe[1]-native_foe[0],native_foe[2]-native_foe[0],native_foe[4]-native_foe[0]]
	var foe_size := Vector3(foe_edges[0].length(),foe_edges[1].length(),foe_edges[2].length())
	var actual_foe_box := AABB(-foe_size*.5,foe_size)
	var actual_foe_pose := Transform3D(Basis(foe_edges[0].normalized(),foe_edges[1].normalized(),foe_edges[2].normalized()),foe_box.get_center())
	var model_probe := func(point: Vector3, probe_basis: Basis, requested: float) -> Dictionary:
		var room := FIT.oriented_body_limit(point,point+probe_basis.z*requested,actual_foe_box,actual_foe_pose,.35,2.0)
		var allowed := minf(requested,room)
		return {"pivot":point,"distance":allowed,"transform":Transform3D(probe_basis,point+probe_basis.z*allowed),"model_room":room}
	var native_cfg := FIT.config().duplicate(true)
	native_cfg["max_distance_m"] = 39.5
	native_cfg["orbit_refinement_step_deg"] = 0.0
	var coarse := FIT.solve(ally_box,foe_box,deg_to_rad(-6.502305985662403),deg_to_rad(-30),46,16.0/9.0,9.5,native_cfg,false,native_ally,native_foe,model_probe)
	assert_false(bool(coarse.get("pass",false)),"original actual-body constrained coarse search remains a truthful failure")
	native_cfg["orbit_refinement_step_deg"] = float(FIT.config().orbit_refinement_step_deg)
	var refined := FIT.solve(ally_box,foe_box,deg_to_rad(-6.502305985662403),deg_to_rad(-30),46,16.0/9.0,9.5,native_cfg,false,native_ally,native_foe,model_probe)
	assert_true(bool(refined.get("pass",false)),"bounded intermediate yaw separates the same actual measured bodies: "+str(refined))
	assert_eq(float(refined.get("overlap",1.0)),0.0,"neither body nor zero-overlap requirement is reduced")
	assert_true(float(refined.distance)<=39.5 and int(refined.get("refinement_candidate_count",100))<=12,"same distance cap and bounded extra candidate budget")
	assert_almost_eq(float(refined.pitch),deg_to_rad(-30),.000001,"refinement leaves actual player pitch unchanged")

func _body(height: float, feet: Vector3) -> AABB:
	var width := height * 0.7
	return AABB(feet - Vector3(width*0.5,0,width*0.5), Vector3(width,height,width))


func test_foreground_envelopes_cover_feet_but_bodies_behind_do_not_occlude() -> void:
	var box := AABB(Vector3(-1,0,-1),Vector3(2,2,2))
	var pose := Transform3D(Basis.IDENTITY,Vector3(0,0,-8))
	var actor := {"box":box,"pose":pose,"inverse":pose.affine_inverse(),"points":FIT.box_points(box,pose)}
	var cover_box := AABB(Vector3(-0.35,0,-0.3),Vector3(0.7,0.6,0.6))
	var cover_pose := Transform3D(Basis.IDENTITY,Vector3(0,0,-4))
	var cover := {"box":cover_box,"pose":cover_pose,"inverse":cover_pose.affine_inverse(),"points":FIT.box_points(cover_box,cover_pose)}
	assert_true(FIT.bounds_occlude(Transform3D.IDENTITY,actor,cover,68.0,16.0/9.0,0.05),"foreground lower body must count even with clear head and torso")
	cover_pose.origin.z=-12.0
	cover={"box":cover_box,"pose":cover_pose,"inverse":cover_pose.affine_inverse(),"points":FIT.box_points(cover_box,cover_pose)}
	assert_false(FIT.bounds_occlude(Transform3D.IDENTITY,actor,cover,68.0,16.0/9.0,0.05),"a projected overlap behind the actor is not foreground cover")


func _envelope(box: AABB, pose: Transform3D, owner: Node3D = null) -> Dictionary:
	var out := {"box":box,"pose":pose,"inverse":pose.affine_inverse(),"points":FIT.box_points(box,pose)}
	if owner != null:
		out["body_id"] = owner.get_instance_id()
		out["model_id"] = owner.get_instance_id()
	return out


## F21#4 strict judge: a covering non-combatant is dithered at the chosen lens
## instead of failing every near view (the over-wide pull-back), and the fade
## hands its material back once clear or when the camera is released.
func test_foreground_cover_is_faded_not_escaped_and_restores_when_clear() -> void:
	var manager: Node = preload("res://scripts/combat/combat_manager.gd").new()
	var model := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var original := StandardMaterial3D.new()
	mesh.set_surface_override_material(0,original)
	model.add_child(mesh)
	var actor := _envelope(AABB(Vector3(-1,0,-1),Vector3(2,2,2)),Transform3D(Basis.IDENTITY,Vector3(0,0,-8)))
	var cover_box := AABB(Vector3(-0.35,0,-0.3),Vector3(0.7,0.6,0.6))
	var cover := _envelope(cover_box,Transform3D(Basis.IDENTITY,Vector3(0,0,-4)),model)
	var context := {"hud_rects":[] as Array[Rect2],"occluders":[cover],"subjects":[actor],"overflow":false,
		"hud_available":true,"geometry_valid":true,"invalid_hud_paths":[],"viewport":Vector2(1920,1080),
		"fov":68.0,"near":0.05,"fade_foreground":false}
	var hard: Dictionary = manager.call("_fight_visibility_score",Transform3D.IDENTITY,Rect2(),Rect2(),context)
	assert_false(bool(hard.pass),"without the fade, foreground cover still fails the view")
	context.fade_foreground = true
	var soft: Dictionary = manager.call("_fight_visibility_score",Transform3D.IDENTITY,Rect2(),Rect2(),context)
	assert_true(bool(soft.pass) and bool(soft.cover_faded),"with the fade, cover is faded rather than escaped")
	assert_true(float(soft.penalty) > 0.0,"cover still ranks a view below a clear one")
	var cfg := {"fade_foreground":true,"foreground_fade":0.75,"foreground_fade_speed":100.0,"foreground_fade_inset":0.0}
	var fading := int(manager.call("_update_foreground_fades",Transform3D.IDENTITY,context,cfg,0.1))
	assert_eq(fading,1,"the covering body fades")
	var faded := mesh.get_surface_override_material(0) as BaseMaterial3D
	assert_true(faded != original and faded.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_OBJECT_DITHER,
		"screen-door dither, opaque pass")
	# Clear: the body moves behind the actor, the fade eases out and restores.
	context.occluders = [_envelope(cover_box,Transform3D(Basis.IDENTITY,Vector3(0,0,-12)),model)]
	assert_eq(int(manager.call("_update_foreground_fades",Transform3D.IDENTITY,context,cfg,0.1)),0)
	assert_eq(mesh.get_surface_override_material(0),original,"original material handed back once clear")
	# Release mid-fade restores too.
	context.occluders = [cover]
	manager.call("_update_foreground_fades",Transform3D.IDENTITY,context,cfg,0.1)
	manager.call("_clear_foreground_fades")
	assert_eq(mesh.get_surface_override_material(0),original,"camera release restores every faded body")
	model.free()
	manager.free()


## F21#4 strict judge: a contact-range failure must not drift to the distance
## cap for a marginally smaller box overlap.
func test_failed_fit_takes_the_nearest_lens_within_overlap_tolerance() -> void:
	var near := {"framed":true,"overlap":0.03,"distance":12.0,"visibility":{"hud_clear":true}}
	var far := {"framed":true,"overlap":0.016,"distance":39.5,"visibility":{"hud_clear":true}}
	var hud_covered := {"framed":true,"overlap":0.02,"distance":9.0,"visibility":{"hud_clear":false}}
	var unframed := {"framed":false,"overlap":0.0,"distance":6.0,"visibility":{"hud_clear":true}}
	var failed: Array[Dictionary] = [far, near, hud_covered, unframed]
	var chosen := FIT.nearest_fallback(far, failed, {"fallback_overlap_tolerance":0.05})
	assert_eq(float(chosen.distance), 12.0, "nearest framed, HUD-clear lens within tolerance")
	assert_eq(float(FIT.nearest_fallback(far, failed, {}).distance), 39.5, "tolerance 0 keeps the least-overlap rule")
	var tight := FIT.nearest_fallback(far, failed, {"fallback_overlap_tolerance":0.01})
	assert_eq(float(tight.distance), 39.5, "a materially larger overlap is never taken for distance")


## Judge r3: a body beside a combatant whose whole box only grazes the actor's
## empty box corner is not dithered; one squarely in front still is.
func test_fade_inset_ignores_corner_grazes_but_keeps_real_cover() -> void:
	var actor := _envelope(AABB(Vector3(-1,0,-1),Vector3(2,2,2)),Transform3D(Basis.IDENTITY,Vector3(0,0,-8)))
	var cover_box := AABB(Vector3(-0.35,0,-0.3),Vector3(0.7,1.8,0.6))
	var graze := _envelope(cover_box,Transform3D(Basis.IDENTITY,Vector3(0.8,0,-4)))
	var front := _envelope(cover_box,Transform3D(Basis.IDENTITY,Vector3(0,0,-4)))
	var hit := func(subject: Dictionary, cover: Dictionary, inset: float) -> bool:
		return FIT.bounds_occlude(Transform3D.IDENTITY,FIT.inset_envelope(subject,inset),FIT.inset_envelope(cover,inset),68.0,16.0/9.0,0.05)
	assert_true(bool(hit.call(actor,graze,0.0)),"the whole boxes graze")
	assert_false(bool(hit.call(actor,graze,0.15)),"the inset envelopes do not")
	assert_true(bool(hit.call(actor,front,0.15)),"real foreground cover still fades")
	var narrowed := FIT.inset_envelope(actor,0.15)
	assert_almost_eq((narrowed.box as AABB).size.y,2.0,0.0001,"full height kept, so feet still count")
