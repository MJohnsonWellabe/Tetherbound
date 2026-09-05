extends SceneTree

## Production-scene checkpoint fixture. Quest facts are explicitly seeded;
## rewards use actual rematch rounds, with test-only lethal resolution.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
var failures: Array[String] = []
var checks := 0
var game: Node
var world: Node3D
var payoffs: Node3D
var director: Node
var player: CharacterBody3D


func _init() -> void:
	_run.call_deferred()


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error("PAYOFF FAIL " + label)
	else:
		print("PAYOFF PASS " + label)


func frames(count: int) -> void:
	for frame in count:
		await physics_frame


func _run() -> void:
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://cloudreach_world_payoffs_smoke")
	game.current_realm = "cloudreach"
	var member: RefCounted = SPECIES.spawn("terrapup")
	member.set_level(40,preload("res://scripts/creatures/progression.gd").config())
	game.party.add(member)
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	var runtime: Node = world.get_node("CloudreachRuntime")
	payoffs = runtime.payoffs
	director = runtime.director
	await frames(12)
	check(payoffs.people.is_empty(),"no premature travelers")
	check(payoffs.anchors.size()==8,"both lower, three upper/feed, three summit anchors bound")
	check(payoffs.markers.size()==3,"all surveyed perches have real floors")
	check(not payoffs.board.visible,"circuit board is earned")
	check(not payoffs.signal_audio.playing,"bell route is initially silent")
	check(game.save_game(0),"save pre-payoff checkpoint")
	for flag in ["realm_key_cloudreach","cloudreach_chapter_started","cloudreach_crisis_learned","causeway_survivors_reconnected","side_three_bells_complete"]:
		game.progression.set_flag(flag)
	player.global_position=Vector3(-495,338.5,1310)
	await frames(12)
	check(payoffs.people.size()==4,"two bell travelers and stranded pair appear")
	check(payoffs.signal_audio.stream!=null and payoffs.signal_count>0,"installed audible route signal played near real bridge")
	var walker: Node3D=payoffs.people.bell_traveler.body
	var walk_start:=walker.global_position
	await frames(90)
	check(walker.global_position.distance_to(walk_start)>0.5,"traveler actually walks along supported bridge deck")
	var first_pair: Node3D=payoffs.people.shelter_traveler.body
	var second_pair: Node3D=payoffs.people.shelter_courier.body
	check(absf(first_pair.global_position.y-460)<1 and absf(second_pair.global_position.y-460)<1,"stranded pair begins at ravine shelter")
	game.progression.set_flag("side_stranded_couriers_complete")
	await frames(8)
	check(payoffs.people.shelter_traveler.body==first_pair and payoffs.people.shelter_courier.body==second_pair,"same pair relocates without duplicate bodies")
	check(absf(first_pair.global_position.y-180)<1 and absf(second_pair.global_position.y-180)<1,"both travelers visibly return to Galefoot")
	for spec: Dictionary in payoffs.config.survey_markers:
		game.progression.set_flag(spec.flag)
		await frames(3)
		var marker: Node3D=payoffs.markers[spec.id]
		check(marker.visible,"survey reveals "+str(spec.id))
		var prompt: Node3D=marker.get_node("SurveyRest/Interactable")
		check(prompt.global_position.distance_to(marker.global_position)<1.0,"rest prompt remains on "+str(spec.id)+" landing")
		check(not prompt.interaction_offer(marker.global_position+Vector3(0,0,1.5)).is_empty(),"survey creates usable rest at "+str(spec.id))
	game.progression.set_flag("cloudreach_upper_route_unlocked")
	game.progression.set_flag("side_cliff_circuit_complete")
	game.progression.set_flag("defeated_cloudreach_tavi")
	game.progression.set_flag("cloudreach_winds_restored")
	await frames(12)
	check(payoffs.people.size()==6,"restoration fills reopened lower and upper roads")
	check(payoffs.board.visible and not payoffs.board.get_node("MasterySeal").visible,"five-place circuit mark precedes mastery reward")
	for id: String in payoffs.anchors:
		check(payoffs.anchors[id].wind.visible and not payoffs.anchors[id].bottled.visible,"natural wind replaces bottled anchor "+id)
	check(not game.can_enter_realm("water"),"payoffs do not enter Waterward")
	check(not game.progression.has("realm_key_water"),"payoffs do not manufacture final chapter rewards")
	var tavi: Node3D=director.trainer_nodes.young_trainer_tavi_rematch
	check(tavi==director.trainer_nodes.young_trainer_tavi_upper_ring,"rematch reuses canonical Tavi")
	player.global_position=tavi.global_position+Vector3(0,0.2,-5)
	player.velocity=Vector3.ZERO
	await frames(8)
	check(await director.summon_active_creature(),"real creature deployment at Tavi")
	await frames(5)
	var spec: Dictionary=director.trainer_specs.young_trainer_tavi_rematch
	var coins: int=game.inventory.count("coin")
	var candy: int=game.inventory.count("great_candy")
	check(director.begin_trainer_battle(spec,tavi),"earned rematch starts real encounter")
	var rounds:=0
	for frame in 1200:
		var manager: Node=runtime.manager
		if int(manager.state)==1:
			manager._enemy.take_damage(manager._enemy.hp+1)
			manager._award_victory()
			manager._begin_resolve("won")
			rounds+=1
		if not director.trainer_battle_active():
			break
		await physics_frame
	await frames(8)
	check(rounds==3,"three rematch rounds use production callbacks")
	check(game.progression.has(spec.defeat_flag),"rematch defeat is canonical save state")
	check(game.inventory.count("coin")==coins+90 and game.inventory.count("great_candy")==candy+1,"exact one-time ace reward")
	check(payoffs.board.get_node("MasterySeal").visible,"victory adds mastery seal")
	check(game.save_game(1),"save all earned payoffs and rematch")
	director._record_trainer_defeat(spec)
	check(game.inventory.count("coin")==coins+90,"duplicate victory cannot pay again")
	check(game.load_game(1),"reload all payoffs from disk")
	await frames(12)
	check(payoffs.people.size()==6 and payoffs.board.get_node("MasterySeal").visible,"payoffs rebuild after reload without duplicates")
	check(not director.can_challenge(spec),"saved rematch cannot be farmed")
	check(game.inventory.count("coin")==coins+90 and game.inventory.count("great_candy")==candy+1,"reload preserves exact reward")
	check(game.load_game(0),"load earlier save")
	await frames(12)
	check(payoffs.people.is_empty() and not payoffs.board.visible,"earlier save removes unearned population/board")
	check(not payoffs.signal_audio.playing,"earlier save silences route signal")
	for id: String in payoffs.anchors:
		check(payoffs.anchors[id].bottled.visible and not payoffs.anchors[id].wind.visible,"earlier save restores bottled anchor "+id)
	if "--capture" in OS.get_cmdline_user_args():
		game.load_game(1)
		await frames(15)
		await _captures()
	print("CLOUDREACH WORLD PAYOFFS %s checks=%d failures=%d"%["PASS" if failures.is_empty() else "FAIL",checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _captures() -> void:
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i(1920,1200)
	var folder:="res://ralph/reports/CLOUDREACH-WORLD-PAYOFFS-0905/shots"
	DirAccess.make_dir_recursive_absolute(folder)
	var shots: Array=[
		["bell-road",Vector3(-499,338.25,1317),Vector3(-506,340,1310)],
		["returned-pair",Vector3(-293,180,529),Vector3(-293.5,181.5,536)],
		["surveyed-perch",Vector3(900,1021,2712),Vector3(900,1022,2700)],
		["circuit-mark",Vector3(-181,851,4094),Vector3(-183,852,4101)],
		["freed-anchor",Vector3(436,921,4513),Vector3(436,922,4503)]
	]
	var camera: Camera3D=world.get_viewport().get_camera_3d()
	var rig:=world.get_node("CameraRig") as SpringArm3D
	rig.set_process(false)
	rig.set_physics_process(false)
	rig.spring_length=5.8
	camera.fov=70.0
	player.set_physics_process(false)
	for shot: Array in shots:
		var at: Vector3=shot[1]
		var height:=float(world.call("ground_height_near",at))
		check(not is_nan(height) and absf(height-at.y)<4.0,str(shot[0])+" capture stand has authored floor")
		if is_nan(height) or absf(height-at.y)>=4.0:
			continue
		at.y=height+0.2
		player.global_position=at
		player.velocity=Vector3.ZERO
		var sightline: Vector3=shot[2]-at
		# The real SpringArm owns its Camera3D child's transform. Pose the rig,
		# not the child (the latter is overwritten by the engine before draw).
		rig.global_position=at+Vector3.UP*1.55
		rig.rotation=Vector3(deg_to_rad(-10.0),atan2(-sightline.x,-sightline.z),0)
		rig.reset_physics_interpolation()
		player.reset_physics_interpolation()
		await frames(30)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/"+str(shot[0])+".png")
