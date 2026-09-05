extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused real-input traversal of the final Upper Summit Road segment. The
## fixture begins at its authored Voss-side endpoint and performs no later
## position write, allowing locomotion diagnostics to classify any stall.


func _run() -> void:
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/summit-road-regression"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	for flag: String in ["realm_key_cloudreach","cloudreach_upper_route_unlocked","cloudreach_act_ii_complete","cloudreach_upper_anchors_disabled","defeated_cloudreach_officer_voss_summit_approach"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit","mudsnout","bramblebun","terrapup","brooktail"]:
		var member: RefCounted=SPECIES.spawn(species)
		member.set_level(25,PROGRESSION.config())
		game.party.add(member)
	world=SCENE.instantiate()
	root.add_child(world)
	current_scene=world
	player=world.get_node("Player")
	runtime=world.get_node("CloudreachRuntime")
	chapter=world.get_node("CloudreachChapter")
	physical=chapter.get_node("PhysicalRuntime")
	director=runtime.director
	manager=runtime.manager
	await _frames(20)
	var start:=Vector3(300.0,1080.06,5100.0)
	player.global_position=start
	player.velocity=Vector3.ZERO
	last_position=start
	physics_frame.connect(_record_frame)
	stage="summit_road_final_segment"
	await _frames(20)
	var target:=Vector3(100.0,1160.0,5350.0)
	if await _walk(target):
		_require(player.global_position.y>1159.0,"Real stick reached the summit threshold elevation")
	else:
		_probe_blockers(target)
	_release()
	print("CLOUDREACH SUMMIT ROAD %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",start,player.global_position,distance_m])
	quit(1 if failed else 0)


func _probe_blockers(target: Vector3) -> void:
	var space:=world.get_world_3d().direct_space_state
	var direction:=Vector3(target.x-player.global_position.x,0,target.z-player.global_position.z).normalized()
	for height: float in [0.15,0.55,1.0,1.55]:
		var query:=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*height,
			player.global_position+Vector3.UP*height+direction*6.0)
		query.exclude=[player.get_rid()]
		var hit:=space.intersect_ray(query)
		if not hit.is_empty():
			var collider: Object=hit.get("collider")
			print("SUMMIT ROAD BLOCKER height=%.2f collider=%s position=%s normal=%s"%[
				height,str((collider as Node).get_path()) if collider is Node else str(collider),
				str(hit.get("position")),str(hit.get("normal"))])
