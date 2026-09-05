extends SceneTree

## Actual production scene. Checkpoint fixtures are explicit and isolated from
## owner saves; only battle damage/resolution is accelerated. Not route acceptance.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
var failures: Array[String] = []
var world: Node3D
var game: Node
var runtime: Node
var player: CharacterBody3D
var evidence_rows: Array[Dictionary] = []


func _init() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	print("INTEGRATION %s %s" % ["PASS" if ok else "FAIL",label])
	if not ok:
		failures.append(label)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func action(name: String, down: bool) -> void:
	var event:=InputEventAction.new()
	event.action=name
	event.pressed=down
	Input.parse_input_event(event)


func evidence(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():
		return
	var folder := evidence_folder()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var draws:=0.0
	var primitives:=0.0
	var start:=Time.get_ticks_usec()
	for frame in 24:
		await RenderingServer.frame_post_draw
		draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	root.get_texture().get_image().save_png(folder+"/"+label+".png")
	evidence_rows.append({"view":label,"draw_calls":roundi(draws/24.0),"primitives":roundi(primitives/24.0),"measured_frame_ms":float(Time.get_ticks_usec()-start)/24000.0})


func evidence_folder() -> String:
	var folder := "res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/live"
	return folder + ("-full-party" if "--full-party" in OS.get_cmdline_user_args() else "")


func _run() -> void:
	if "--capture" in OS.get_cmdline_user_args():
		root.size=Vector2i(1280,800)
		root.content_scale_size=Vector2i(1920,1200)
	game = root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("save_system",SAVE.new("user://cloudreach_production_integration_smoke"))
	game.set("current_realm","cloudreach")
	var member: RefCounted = SPECIES.spawn("galecrest")
	member.call("set_level",40,preload("res://scripts/creatures/progression.gd").config())
	game.get("party").call("add",member)
	if "--full-party" in OS.get_cmdline_user_args():
		# Explicit near-level full-team checkpoint to stress production reward
		# presentation. Awards still come only from the real three battle rounds.
		var progression_config := preload("res://scripts/creatures/progression.gd").config()
		for species_id: String in ["terrapup", "ripplet", "bramblebun", "mudsnout"]:
			var companion: RefCounted = SPECIES.spawn(species_id)
			companion.call("set_level", 40, progression_config)
			game.get("party").call("add", companion)
		for owned: RefCounted in game.get("party").call("members"):
			owned.set("xp", int(owned.call("xp_to_next", progression_config)) - 1)
		check(game.get("party").call("size") == 5, "explicit full-team reward fixture owns exactly five")
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	await frames(12)
	runtime = world.get_node("CloudreachRuntime")
	player = world.get_node("Player")
	for name in ["CloudreachRuntime","CloudreachChapter","BuildPlacer","PlayerDeath","CombatManager","EncounterDirector","CloudreachFinaleController","CloudreachAtmosphere","CombatHUD","SummitArenaPresentation"]:
		check(world.find_children(name,"",true,false).size()==1,"exactly one "+name)
	check(get_nodes_in_group("progression_feedback_presenter").size()==1,"exactly one shared progression presenter")
	check(get_first_node_in_group("progression_feedback_presenter")==world.get_node("PlaygroundHUD"),"production HUD owns the single progression banner")
	check(world.find_children("MomentBanner","",true,false).size()==1,"exactly one moment banner")
	check(runtime.get("navigation")==game.call("bind_realm_map","cloudreach",player.global_position),"canonical map identity")
	check(world.call("map_terrain_texture")!=null,"production terrain atlas")
	var director: Node = runtime.get("director")
	var manager: Node = runtime.get("manager")
	var chapter: Node = runtime.get("chapter")
	var bodies: Dictionary = chapter.call("npc_bodies")
	check((director.get("trainer_nodes") as Dictionary).size()==8,"seven trainers plus one saved Tavi rematch have physical floors")
	var yards:=world.get_node("CloudreachBattleYards")
	for id: String in yards.get("trainer_positions"):
		var yard:=yards.get_node(id+"_yard") as Node3D
		var trainer: Node3D=director.get("trainer_nodes")[id]
		check(trainer.global_position.distance_to(yard.global_position)<4.0,id+" occupies dedicated yard")
		check(yard.global_position.distance_to(yard.get_meta("road_entry"))>24.0,id+" is outside walking lane")
		for offset in [Vector3(11,0,0),Vector3(-11,0,0),Vector3(0,0,11),Vector3(0,0,-11)]:
			var at: Vector3=yard.global_position+offset
			var floor_hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*1.8,at-Vector3.UP*0.4))
			check(not floor_hit.is_empty() and absf(floor_hit.position.y-at.y)<0.15,id+" clear floor at "+str(offset))
	check(director.get("trainer_nodes")["officer_voss_summit_approach"]==bodies["officer_voss"],"yard reuses the canonical Voss without a duplicate NPC")
	for pair in [["trainer_orrin_bridge_watch","bridgekeeper_orrin"],["keeper_maela_trial","keeper_maela"],["young_trainer_tavi_upper_ring","young_trainer_tavi"],["captain_veyra_storm_anchor","captain_veyra"]]:
		check(director.get("trainer_nodes").get(pair[0])==bodies.get(pair[1]),"canonical body reuse "+pair[1])
	var flags: RefCounted = game.get("progression")
	var finale: Node3D = runtime.get("finale")
	var origin: Vector3 = finale.global_position
	var deck_probe := origin+Vector3(8,0,0)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(deck_probe+Vector3.UP*2,deck_probe-Vector3.UP*3))
	check(not hit.is_empty() and absf(hit.position.y-origin.y-0.15)<0.05,"real summit deck collision")
	check(world.find_children("RelayHousingCollision","StaticBody3D",true,false).size()==3,"every relay housing has actor/camera collision")
	# Explicit saved-state precondition fixture for the final encounter; the
	# Act I and ordered Fly paths have separate real-input production smokes.
	for flag in ["realm_key_cloudreach","cloudreach_chapter_started","cloudreach_crisis_learned","cloudreach_lower_anchors_investigated","causeway_survivors_reconnected","windscar_aerie_prepared","cloudreach_act_i_complete","fly_traversal_unlocked","sky_shrine_reached","storm_anchor_engine_truth_learned","cloudreach_upper_route_unlocked","cloudreach_act_ii_complete","cloudreach_upper_anchors_disabled","summit_extraction_engine_reached"]:
		flags.call("set_flag",flag)
	await frames(8)
	player.global_position = origin+Vector3(0,0.2,-10)
	player.velocity=Vector3.ZERO
	# This bounded checkpoint fixture warps 5km; settle the ordinary camera at
	# the test station rather than recording its temporary pan through terrain.
	world.get_node("CameraRig").global_position=player.global_position+Vector3.UP*1.75
	await frames(6)
	check(await director.call("summon_active_creature"),"real party deployment at summit")
	await frames(5)
	var captain: Node3D = director.get("trainer_nodes").get("captain_veyra_storm_anchor")
	check(captain!=null and captain.global_position.distance_to(origin)<15,"captain staged on real arena")
	check(director.call("begin_trainer_battle",director.get("trainer_specs")["captain_veyra_storm_anchor"],captain),"real captain challenge starts")
	await frames(5)
	check(finale.get("phase")=="crosswind_command","trainer start reaches finale")
	await evidence("captain-crosswind-live")
	var rounds:=0
	for frame in 1800:
		if int(manager.get("state"))==1:
			var enemy: RefCounted = manager.get("_enemy")
			enemy.call("take_damage",float(enemy.get("hp"))+1.0)
			manager.call("_award_victory")
			manager.call("_begin_resolve","won")
			rounds+=1
		if not bool(director.call("trainer_battle_active")):
			break
		await physics_frame
	check(rounds==3,"three real captain rounds resolve")
	if "--full-party" in OS.get_cmdline_user_args():
		for owned: RefCounted in game.get("party").call("members"):
			check(int(owned.get("level")) > 40, "real captain awards level up full-team member " + str(owned.get("species_id")))
	await frames(8)
	check(flags.call("has","captain_veyra_defeated"),"captain victory canonical event")
	check(finale.get("phase")=="break_the_eye","relay phase follows real victory")
	var ally: CharacterBody3D = director.call("ally_body")
	check(runtime.call("controlled_body")==ally,"post-battle creature input/camera handoff")
	var move_start:=ally.global_position
	action("move_right",true)
	await frames(20)
	action("move_right",false)
	check(ally.global_position.distance_to(move_start)>0.5,"real stick input pilots creature after captain")
	for relay: Dictionary in finale.get("config").relays:
		# A relay checkpoint approaches from the arena interior. A constant -Z
		# fixture instead put the crown actor inside its outward machine housing.
		var relay_offset:=Vector3(relay.offset[0],0,relay.offset[2])
		ally.global_position = origin+relay_offset+Vector3.UP*0.15-relay_offset.normalized()*2.0
		ally.velocity=Vector3.ZERO
		await frames(3)
		print("RELAY CHECK %s body=%s controlled=%s phase=%s offer=%s"%[relay.id,ally.global_position,runtime.call("controlled_body")==ally,finale.get("phase"),finale.get_node("Relay_"+relay.id).call("interaction_offer",ally.global_position)])
		# A real device event selects the ordinary controller glyph policy.
		var pad_event:=InputEventJoypadMotion.new()
		pad_event.axis=JOY_AXIS_RIGHT_X
		pad_event.axis_value=0.5
		Input.parse_input_event(pad_event)
		await frames(1)
		var pad_neutral:=InputEventJoypadMotion.new()
		pad_neutral.axis=JOY_AXIS_RIGHT_X
		pad_neutral.axis_value=0.0
		Input.parse_input_event(pad_neutral)
		await frames(2)
		await evidence("relay-"+relay.id+"-live")
		if relay.id == "west" and "--full-party" in OS.get_cmdline_user_args():
			var hud := world.get_node("PlaygroundHUD")
			var banner: Control = hud.get("_moment_banner")
			var strip: Control = hud.get("_party_strip")
			var prompt: Control = hud.get("_prompt_label")
			check(banner.is_visible_in_tree() and strip.is_visible_in_tree(), "full-team reward and party rail remain visible together")
			check(not banner.get_global_rect().intersects(strip.get_global_rect()), "full-team reward does not overlap party rail")
			check(not banner.get_global_rect().intersects(prompt.get_global_rect()), "full-team reward leaves actual relay prompt clear")
			check(banner.get_global_rect().position.x >= banner.get_viewport_rect().size.x * 0.60, "full-team reward leaves central play space clear")
		action("interact",true)
		await frames(3)
		action("interact",false)
		await frames(3)
		check(flags.call("has",relay.flag_id),"real controlled-body input strikes relay "+relay.id)
	check(flags.call("has","storm_anchor_network_disabled"),"three relays restore network")
	player.global_position=Vector3(-420,1110.2,5650)
	player.velocity=Vector3.ZERO
	await frames(6)
	check(flags.call("has","cloudreach_winds_restored"),"real overlook proximity witnesses restoration")
	check(chapter.call("physical_runtime").call("consume_dialogue_effect","cloudreach:cloudreach_aila_final_reward_complete"),"real final dialogue effect grants reward")
	check(flags.call("has","realm_key_water"),"reward grants canonical next-realm key")
	check(game.call("save_game",0),"isolated checkpoint saves")
	var coins_before: int = game.get("inventory").call("count","coin")
	check(game.call("load_game",0),"real save reload reconciles live scene")
	await frames(8)
	check(game.get("progression").call("has","realm_key_water"),"reward entitlement survives disk reload")
	check(runtime.get("navigation")==game.call("bind_realm_map","cloudreach",player.global_position),"live reload retains canonical map identity")
	check(not director.call("can_challenge",director.get("trainer_specs")["captain_veyra_storm_anchor"]),"restored captain cannot pay twice")
	check(game.get("inventory").call("count","coin")==coins_before,"reload preserves exact trainer payout")
	check(director.get("trainer_nodes").get("captain_veyra_storm_anchor")==chapter.call("npc_bodies").get("captain_veyra"),"reload retargets canonical cast without duplicate challenge")
	if not evidence_rows.is_empty():
		var file:=FileAccess.open(evidence_folder()+"/performance.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"video_adapter":RenderingServer.get_video_adapter_name(),"resolution":[root.size.x,root.size.y],"views":evidence_rows},"  "))
	world.queue_free()
	await process_frame
	await process_frame
	print("CLOUDREACH PRODUCTION INTEGRATION %s failures=%d"%["PASS" if failures.is_empty() else "FAIL",failures.size()])
	quit(0 if failures.is_empty() else 1)
