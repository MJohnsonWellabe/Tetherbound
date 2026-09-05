extends "res://tests/smoke_cloudreach_continuous.gd"

## Isolated diagnostic fixture, NOT continuous acceptance. One declared shrine
## start and readiness flags; prints only its own log, never live/events.json.
func _run() -> void:
	start_usec = Time.get_ticks_usec()
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://cloudreach_shrine_services_fixture")
	game.current_realm = "cloudreach"
	for flag: String in ["cloudreach_act_i_complete", "fly_traversal_unlocked", "sky_shrine_reached"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25,PROGRESSION.config())
		game.party.add(member)
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	player.global_position = Vector3(1098.98,1051.31,2938.479)
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path()))
	world.get_node("DialoguePanel").finished.connect(func(id: String) -> void: _log("dialogue_finished",{"id":id}))
	await _frames(30)
	stage = "isolated_shrine_offer_probe"
	var prompt: Node3D = physical.get_node("shrine_vane_west/Interactable")
	_diagnose(prompt,"observed_continuous_approach")
	if not _require(not prompt.interaction_offer(player.global_position).is_empty(),"Original raised-floor approach offers through the viewer capsule"): return _fixture_finish()
	if not await _interact(prompt,"cloudreach_shrine_vane_west_aligned",false): return _fixture_finish()
	for id: String in ["shrine_vane_east","shrine_vane_crown"]:
		if not await _physical_action(id,"cloudreach_"+id+"_aligned",false): return _fixture_finish()
	if not await _talk("naturalist_sora","storm_anchor_engine_truth_learned",false): return _fixture_finish()
	if not await _physical_action("shrine_windlass","cloudreach_upper_route_unlocked",false): return _fixture_finish()
	_fixture_finish()


func _diagnose(prompt: Node3D, label: String) -> void:
	var arbiter: Node = world.get_node("InteractionArbiter")
	arbiter.call("_recompute")
	var eye := player.global_position+Vector3.UP*1.4
	var to_eye := eye-prompt.global_position
	var ray := PhysicsRayQueryParameters3D.create(prompt.global_position+to_eye.normalized()*0.9,eye-to_eye.normalized()*0.55)
	ray.collide_with_areas = false
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	var floor_ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,player.global_position-Vector3.UP*4,1)
	floor_ray.exclude = [player.get_rid()]
	var floor_hit := world.get_world_3d().direct_space_state.intersect_ray(floor_ray)
	_log("offer_diagnostic", {"label":label,"player":str(player.global_position),"on_floor":player.is_on_floor(),"prompt":str(prompt.global_position),"enabled":prompt.enabled,"target_offer":prompt.interaction_offer(player.global_position),"winner":arbiter.winner(),"line_of_sight":prompt.call("_has_line_of_sight",player.global_position),"los_collider":str(hit.collider.get_path()) if not hit.is_empty() else "none","los_hit":str(hit.get("position",Vector3.INF)),"floor_collider":str(floor_hit.collider.get_path()) if not floor_hit.is_empty() else "none","floor_hit":str(floor_hit.get("position",Vector3.INF))})


func _log(kind: String, details: Dictionary = {}) -> void:
	print("CLOUDREACH SHRINE ISOLATED "+JSON.stringify({"kind":kind,"stage":stage,"details":details}))


func _fixture_finish() -> void:
	_release()
	print("CLOUDREACH SHRINE ISOLATED "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
