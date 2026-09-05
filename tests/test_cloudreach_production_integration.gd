extends "res://tests/test_case.gd"

const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")


func test_spatial_surface_broadphase_preserves_stack_and_negative_cells() -> void:
	var world := WORLD.new()
	world.call("register_runtime_surface",{"kind":"rect","centre":Vector2(-128,-128),"half":Vector2(4,4),"height":100.0})
	world.call("register_runtime_surface",{"kind":"ellipse","centre":Vector2(-128,-128),"half":Vector2(20,3),"rotation":PI/2,"height":400.0})
	assert_eq(world.call("ground_height_at",-128.0,-128.0),400.0,"map takes highest real stratum")
	assert_eq(world.call("ground_height_near",Vector3(-128,101,-128)),100.0,"actor retains nearby lower stratum")
	assert_eq(world.call("ground_height_at",-128.0,-115.0),400.0,"rotated ellipse extends into adjacent grid cell")
	assert_true(is_nan(world.call("ground_height_at",-115.0,-128.0)),"conservative broad phase does not create ground")
	world.call("register_runtime_surface",{"kind":"segment","a":Vector3(120,20,-10),"b":Vector3(140,40,-10),"half_width":2.0})
	assert_eq(world.call("ground_height_at",130.0,-10.0),30.0,"late arena/path surface invalidates index and interpolates")
	world.free()


func test_counterweight_barrier_is_on_restricted_branch_not_lower_junction() -> void:
	var world:=WORLD.new()
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json"))
	world.set("_config",config)
	var gate: Dictionary={}
	for spec: Dictionary in config.gates:
		if spec.id=="upper_counterweight_gate":
			gate=spec
	var at: Vector3=world.call("_vec3",gate.position)
	var junction:=Vector3(-100,470,2440)
	assert_true(at.distance_to(junction)>40.0,"locked gate leaves the mandatory lower junction open")
	assert_true(Geometry3D.get_closest_point_to_segment(at,junction,Vector3(-360,520,2900)).distance_to(at)<0.1,"gate still belongs to the protected upper route")
	assert_true(absf(float(world.call("_gate_yaw_for",gate.requires_unlock,at))-atan2(-260.0,460.0))<0.001,"offset gate faces across its own slope")
	world.free()


func test_scene_composer_contract_has_no_meadows_story_or_duplicate_feed() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world_runtime.gd")
	assert_false(source.contains("sequence_director.gd"),"Meadows opening cannot mount in Cloudreach")
	assert_false(source.contains("progression_feedback_hud.gd"),"composer reuses PlaygroundHUD feed")
	assert_false(source.contains("resolve_enemy_for_fixture"),"production composition has no test victory path")
	var runtime := RUNTIME.new()
	assert_false(runtime.get("_mounted"),"mount guard begins closed")
	runtime.free()


func test_bridge_cut_does_not_remove_its_neighboring_approach() -> void:
	var world:=WORLD.new()
	world.set("_config",JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json")))
	var approach: Array=world.call("_ground_sections_for_segment","broken_causeway_main",Vector3(-320,300,1040),Vector3(-540,330,1280))
	assert_eq(approach.size(),1,"an endpoint nearby does not carve the approach")
	assert_eq(approach[0].b,Vector3(-540,330,1280),"approach reaches the exact west abutment")
	var span: Array=world.call("_ground_sections_for_segment","broken_causeway_main",Vector3(-540,330,1280),Vector3(-511.2,338.25,1305.6))
	assert_true(span.is_empty(),"real bridge span still has no supporting ground ribbon")
	assert_true(world.call("_bridge_interior_point","broken_causeway_main",Vector3(-511.2,338.25,1305.6)),"internal deck bend cannot acquire a blocking land cap")
	var join: Vector3=world.call("_landing_join",Vector3(-450,342,1360),Vector3(-468,338.25,1344),6.56,0.75)
	assert_true(join.x< -456.0 and is_equal_approx(join.y,342.0),"short bridge ramp reaches cap edge at cap height")
	world.free()
