extends SceneTree

## Continuous production chapter, not a checkpoint montage. All route movement
## uses InputEventAction and the actual controller/collision. No position writes.
## Completed-Meadows entitlement/Heart precondition reuses the separately proven
## smoke_meadows_realm_handoff + smoke_cloudreach_transition path. Only enemy
## damage/result latency is accelerated; no Cloudreach objective is seeded.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const OUTPUT := "res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/live"
var game: Node
var world: Node3D
var player: CharacterBody3D
var chapter: Node
var physical: Node
var runtime: Node
var director: Node
var manager: Node
var fly: Node
var rows: Array[Dictionary] = []
var failed := false
var stage := "boot"
var simulated_seconds := 0.0
var distance_m := 0.0
var last_activity := 0.0
var longest_dead_travel := 0.0
var start_usec := 0
var last_position := Vector3.INF
var checkpoint := 0
var input_values: Dictionary = {}
var accelerated := false
var completed_route := false
var offered: Dictionary = {}
var offer_poll := 0
var initial_party_ids: Array[int] = []
var last_reported_denial := ""
var activity_intervals: Array[Dictionary] = []
var previous_activity: Dictionary = {}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1920,1200)
	accelerated = "--accelerated" in OS.get_cmdline_user_args()
	if accelerated:
		Engine.time_scale = 8.0
		Engine.physics_ticks_per_second = 480
		Engine.max_physics_steps_per_frame = 32
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://cloudreach_continuous_acceptance")
	# Explicit initial save-fixture only: no Cloudreach chapter progress.
	for flag: String in ["warden_defeated", "realm_key_cloudreach", "realm_heart_meadows_earned", "realm_heart_meadows_placed", "realm_gate_cloudreach_unlocked"]:
		game.progression.set_flag(flag)
	game.realm_hearts.activate("meadows", game.progression)
	# Deliberately no owned Fly carrier: a valid full Meadows team must not
	# deadlock the chapter or require a hidden sixth slot.
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
		game.party.add(member)
		initial_party_ids.append(member.get_instance_id())
	for item: String in ["knife", "axe", "pickaxe"]:
		if not game.items.definition(item).is_empty():
			game.inventory.add(item, 1)
	game.assign_hotbar(0, "knife")
	game.current_realm = "cloudreach"
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
	director.trainer_started.connect(func(id: String) -> void: _log("battle_started", {"id": id}))
	director.trainer_victory.connect(func(id: String) -> void: _log("battle_victory", {"id": id}))
	director.trainer_opposition_changed.connect(func(id: String, remaining: int, total: int) -> void: _log("opposition", {"id": id,"remaining": remaining,"total": total}))
	physical.interaction_completed.connect(func(id: String) -> void: _log("physical_interaction", {"id": id}))
	physical.trial_progress.connect(func(passed: int, total: int) -> void: _log("trial_gate", {"passed": passed,"total": total}))
	fly.recovered.connect(func(reason: String) -> void: _fail("Unexpected recovery interrupts continuous route: " + reason))
	fly.denied.connect(func(reason: String) -> void:
		if reason != last_reported_denial:
			last_reported_denial = reason
			_log("flight_denied", {"reason":reason,"state":fly.state,"velocity":str(player.velocity)}))
	await _frames(20)
	_log("precondition", {"description": "Fresh completed-Meadows fixture; five level-25 installed creatures; active Meadows Heart; separate proven handoff reused", "accelerated": accelerated})
	await _capture("arrival")
	stage = "arrival_to_aila"
	var arrival := _route("arrival_gate_road")
	# Optional beats are actually inspected/gathered, as well as offer-logged.
	var ruin: Node3D = world.find_child("InspectArrivalRuin",true,false)
	if not await _walk(ruin.global_position + Vector3(0,-1,-2)): return _finish()
	if not await _interact(ruin,"",false): return _finish()
	if not await _walk(_vec(arrival.polyline[1])): return _finish()
	if not await _arrival_gather("cr_node_cloudberry_waycamp", "cloudberry"): return _finish()
	if not await _walk(_vec(arrival.polyline[2])): return _finish()
	if not await _arrival_gather("cr_node_gale_fiber_gate", "gale_fiber"): return _finish()
	if not await _walk(_vec(arrival.polyline[3])): return _finish()
	if not await _walk(Vector3(-280,180,508)): return _finish()
	if not await _talk("warden_aila", "cloudreach_crisis_learned"): return _finish()
	if not await _pickup("cr_pickup_lower_good_candy"): return _finish()
	stage = "lower_west_anchor"
	if not await _navigate(chapter.get_node("lower_west").global_position): return _finish()
	if not await _interact(chapter.get_node("lower_west/Interactable"), "storm_anchor_lower_west_mapped"): return _finish()
	stage = "lower_east_anchor"
	var causeway_fiber: Node3D = world.get_node("CloudreachResources/cr_node_gale_fiber_causeway")
	if not await _navigate(causeway_fiber.global_position): return _finish()
	if not await _arrival_gather("cr_node_gale_fiber_causeway", "gale_fiber"): return _finish()
	if not await _navigate(chapter.get_node("lower_east").global_position): return _finish()
	if not await _interact(chapter.get_node("lower_east/Interactable"), "cloudreach_lower_anchors_investigated"): return _finish()
	if not await _battle("tether_lieutenant_senn"): return _finish()
	if not await _physical_action("causeway_signal", "causeway_survivors_reconnected"): return _finish()
	# Required preparation is gathered through the shipped tool/interact path.
	stage = "gale_fiber_preparation"
	# Arrival harvesting may already satisfy the repair. Do not manufacture a
	# redundant return journey purely because a fixture named a second crop.
	if game.inventory.count("gale_fiber") < 3:
		var fiber: Node3D = world.get_node("CloudreachResources/cr_node_gale_fiber_bridge")
		if not await _navigate(fiber.global_position): return _finish()
		var resource_prompt: Node3D = fiber.find_child("Interactable", true, false)
		var fiber_before: int = game.inventory.count("gale_fiber")
		if resource_prompt == null or not await _interact(resource_prompt): return _finish()
		await _frames(100)
		_log("resource_delta", {"id":"cr_node_gale_fiber_bridge","item":"gale_fiber","gained":game.inventory.count("gale_fiber")-fiber_before})
	else:
		_log("preparation_ready", {"gale_fiber":game.inventory.count("gale_fiber"),"source":"Previously gathered through actual arrival input"})
	if not _require(game.inventory.count("gale_fiber") >= 3, "Gathered 3 Gale Fiber"): return _finish()
	if not await _battle("keeper_maela_trial"): return _finish()
	if not await _physical_action("aerie_repair", "windscar_aerie_prepared"): return _finish()
	if not await _talk("keeper_maela", "cloudreach_act_i_complete"): return _finish()
	if not await _rest("windscar_flight_aerie_camp"): return _finish()
	if not await _trial(): return _finish()
	stage = "mandatory_high_roost_flight"
	if not await _deploy(): return _finish()
	for target: Vector3 in [Vector3(535,760,3170), Vector3(750,935,3030), Vector3(1020,1075,2960), Vector3(1110,1053,2940)]:
		if not await _fly_to(target): return _finish()
	if not await _land(Vector3(1110,1050,2940)): return _finish()
	if not _require(_has("sky_shrine_reached"), "Actual Fly-only shrine landing"): return _finish()
	await _capture("high-roost-landing")
	for id: String in ["shrine_vane_west", "shrine_vane_east", "shrine_vane_crown"]:
		if not await _physical_action(id, "cloudreach_" + id + "_aligned", false): return _finish()
	if not await _talk("naturalist_sora", "storm_anchor_engine_truth_learned", false): return _finish()
	if not await _physical_action("shrine_windlass", "cloudreach_upper_route_unlocked", false): return _finish()
	stage = "return_glide_to_grounded_counterweight"
	if not await _deploy(): return _finish()
	for target: Vector3 in [Vector3(850,975,3020), Vector3(620,800,3150), Vector3(405,630,3250)]:
		if not await _fly_to(target): return _finish()
	if not await _land(Vector3(400,610,3250)): return _finish()
	if not await _navigate(Vector3(-720,700,3680)): return _finish()
	if not _require(_has("cloudreach_act_ii_complete"), "Grounded counterweight route entered"): return _finish()
	if not await _physical_action("upper_anchor_west", "storm_anchor_upper_west_disabled"): return _finish()
	if not await _physical_action("upper_anchor_east", "storm_anchor_upper_east_disabled"): return _finish()
	if not await _battle("officer_voss_summit_approach"): return _finish()
	if not await _physical_action("summit_feed", "cloudreach_upper_anchors_disabled"): return _finish()
	if not await _rest("summit_bivouac"): return _finish()
	if not await _navigate(Vector3(100,1160,5350)): return _finish()
	if not _require(_has("summit_extraction_engine_reached"), "Real summit threshold"): return _finish()
	if not await _battle("captain_veyra_storm_anchor"): return _finish()
	stage = "creature_relay_phase"
	if not _require(runtime.creature_piloted(),"Captain victory handed control to the deployed creature"): return _finish()
	for relay: Dictionary in runtime.finale.config.relays:
		var prompt: Node3D = runtime.finale.get_node("Relay_" + str(relay.id))
		var inward := -Vector3(relay.offset[0],0,relay.offset[2]).normalized()
		if not await _walk(prompt.global_position + Vector3(0,-0.8,0) + inward*2.0, 0.6, runtime.controlled_body()): return _finish()
		if not await _interact(prompt, relay.flag_id, false): return _finish()
	if not _require(_has("storm_anchor_network_disabled"), "Three deployed-creature relay actions"): return _finish()
	stage = "aftermath_overlook"
	if not await _navigate(Vector3(-420,1110,5650)): return _finish()
	await _frames(30)
	if not _require(_has("cloudreach_winds_restored"), "Witness restored winds at overlook"): return _finish()
	if not await _talk("warden_aila", "cloudreach_chapter_complete", false): return _finish()
	await _capture("waterward-reward")
	var coins: int = game.inventory.count("coin")
	if not _require(game.save_game(0), "Save completed continuous run"): return _finish()
	if not _require(game.load_game(0), "Reload completed continuous run"): return _finish()
	await _frames(30)
	for flag: String in ["realm_heart_cloudreach_earned", "realm_key_water", "waterward_route_revealed", "captain_veyra_defeated", "cloudreach_chapter_complete"]:
		_require(_has(flag), "Reload preserved " + flag)
	_require(game.inventory.count("coin") == coins, "Reload did not duplicate payouts")
	_require(not game.can_enter_realm("water"), "Water realm remains non-enterable")
	_log("complete", {"optional_trainers": "not attempted", "optional_detours": "opening candy; required fiber and camp preparation"})
	completed_route = true
	_finish()


func _has(flag: String) -> bool:
	return game.progression.has(flag)


func _route(id: String) -> Dictionary:
	for route: Dictionary in world.config_data().routes:
		if route.id == id: return route
	return {}


func _vec(raw: Array) -> Vector3:
	return Vector3(raw[0], raw[1], raw[2])


func _input(action: String, strength: float) -> void:
	if is_equal_approx(float(input_values.get(action, -1)), strength): return
	input_values[action] = strength
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0
	event.strength = strength
	Input.parse_input_event(event)


func _release() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back", "jump", "fly_descend", "interact"]:
		_input(action, 0)


func _steer(offset: Vector3, strength: float = 1.0) -> void:
	offset.y = 0
	var local := (world.get_node("CameraRig").planar_basis() as Basis).inverse() * offset.normalized() * strength
	_input("move_right", maxf(local.x,0)); _input("move_left",maxf(-local.x,0))
	_input("move_back",maxf(local.z,0)); _input("move_forward",maxf(-local.z,0))


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		if game != null and game.party.members().size() != 5:
			_fail("Permanent party must remain exactly the original five; loaner is never owned")
		simulated_seconds += 1.0 / 60.0
		if is_instance_valid(player):
			if last_position != Vector3.INF:
				distance_m += player.global_position.distance_to(last_position)
			last_position = player.global_position
		longest_dead_travel = maxf(longest_dead_travel, simulated_seconds-last_activity)
		offer_poll += 1
		if offer_poll >= 30 and is_instance_valid(world):
			offer_poll = 0
			for candidate: Variant in world.get_node("InteractionArbiter").get("_providers"):
				if not is_instance_valid(candidate) or not candidate is Node3D: continue
				var prompt: Node3D = candidate
				if not prompt.has_method("interaction_offer") or offered.has(str(prompt.get_path())): continue
				var offer: Dictionary = prompt.call("interaction_offer", player.global_position)
				if not offer.is_empty():
					offered[str(prompt.get_path())] = true
					_log("meaningful_offer", {"path":str(prompt.get_path()),"label":str(prompt.get("label")),"chosen":false})


func _tap(action: String) -> void:
	_input(action,1)
	await _frames(4)
	_input(action,0)
	await _frames(8)


func _walk(target: Vector3, radius: float = 0.75, body: CharacterBody3D = null) -> bool:
	if failed: return false
	if body == null: body = player
	var previous := body.global_position
	var segment_start := body.global_position
	var recent_collisions: Array[Dictionary] = []
	var stalls := 0
	_log("travel_start", {"target": str(target)})
	for frame in 36000:
		var offset := target - body.global_position
		if Vector2(offset.x,offset.z).length() < radius:
			_release()
			await _frames(8)
			if absf(body.global_position.y-target.y) > 7:
				return _fail("Wrong elevation at destination " + str(target))
			_log("travel_arrived", {"target": str(target)})
			return true
		_steer(offset, clampf(Vector2(offset.x,offset.z).length()/2,0.22,1))
		await _frames(1)
		if failed: return false
		for index in body.get_slide_collision_count():
			var hit := body.get_slide_collision(index)
			if absf(hit.get_normal().y) < 0.8:
				recent_collisions.append({"position":str(body.global_position),"body":str(hit.get_collider().get_path()),"normal":str(hit.get_normal())})
				if recent_collisions.size() > 24: recent_collisions.pop_front()
		if frame % 120 == 119:
			stalls = stalls + 1 if body.global_position.distance_to(previous) < 0.4 else 0
			previous = body.global_position
			if stalls >= 3:
				var collisions: Array = []
				for index in body.get_slide_collision_count():
					var hit := body.get_slide_collision(index)
					collisions.append({"body": str(hit.get_collider().get_path()), "normal": str(hit.get_normal())})
				_log("collision_block", {"target": str(target), "collisions": collisions,"velocity":str(body.velocity),"locomotion_enabled":player.locomotion_enabled(),"dialogue_open":world.get_node("DialoguePanel").is_open(),"input_vector":str(Input.get_vector("move_left","move_right","move_forward","move_back")),"winner":str(world.get_node("InteractionArbiter").get("_winning_provider"))})
				await _capture("blocked-"+stage)
				return _fail("Walking stalled toward " + str(target))
		var expected := Geometry3D.get_closest_point_to_segment(body.global_position,segment_start,target)
		if body.global_position.y < expected.y-20:
			_log("segment_fall", {"from":str(segment_start),"target":str(target),"expected":str(expected),"recent_wall_contacts":recent_collisions})
			await _capture("fall-"+stage)
			return _fail("Fell below authored segment toward " + str(target))
	return _fail("Travel timeout toward " + str(target))


## Build a graph from production grounded polylines; attach current/target to
## nearest edges. This routes back through real junctions, never a straight-line
## shortcut across a ravine. Final off-road approach is still collision-tested.
func _navigate(target: Vector3) -> bool:
	var points: Array[Vector3] = []
	var edges: Array = []
	for route: Dictionary in world.config_data().routes:
		if route.traversal_mode != "ground" or (not str(route.requires_unlock).is_empty() and not _has(route.requires_unlock)): continue
		var previous := -1
		for raw: Array in route.polyline:
			var at := _vec(raw)
			var index := points.find(at)
			if index < 0: index = points.size(); points.append(at)
			if previous >= 0: edges.append([previous,index])
			previous = index
	var endpoints: Array[int] = []
	for at: Vector3 in [player.global_position,target]:
		var best := INF
		var chosen: Array = []
		var projected := Vector3.ZERO
		for edge: Array in edges:
			var closest := Geometry3D.get_closest_point_to_segment(at,points[edge[0]],points[edge[1]])
			var distance := at.distance_to(closest)
			if distance < best: best=distance; chosen=edge; projected=closest
		var index := points.size()
		points.append(projected)
		endpoints.append(index)
		edges.append([index,chosen[0]]); edges.append([index,chosen[1]])
	var distances: Dictionary = {endpoints[0]:0.0}
	var previous: Dictionary = {}
	var open: Array[int] = [endpoints[0]]
	while not open.is_empty():
		open.sort_custom(func(a:int,b:int)->bool:return float(distances[a])<float(distances[b]))
		var current: int = open.pop_front()
		if current == endpoints[1]: break
		for edge: Array in edges:
			var next: int = edge[1] if edge[0]==current else (edge[0] if edge[1]==current else -1)
			if next < 0: continue
			var cost := float(distances[current])+points[current].distance_to(points[next])
			if cost < float(distances.get(next,INF)):
				distances[next]=cost; previous[next]=current
				if next not in open: open.append(next)
	if not distances.has(endpoints[1]): return _fail("No unlocked authored ground route to " + str(target))
	var path: Array[Vector3] = [target]
	var cursor := endpoints[1]
	while true:
		path.push_front(points[cursor])
		if cursor == endpoints[0]: break
		cursor=previous[cursor]
	for at: Vector3 in path:
		if not await _walk(at): return false
	return true


func _interact(prompt: Node3D, flag: String = "", approach: bool = true) -> bool:
	if not is_instance_valid(prompt): return _fail("Missing physical interaction")
	var arbiter: Node = world.get_node("InteractionArbiter")
	# Do not move away from a real winning offer merely to satisfy a canned
	# offset. In particular, reused trainer NPCs also offer separate dialogue.
	if approach and arbiter.get("_winning_provider") != prompt:
		if not await _walk(prompt.global_position+Vector3(0,-0.8,-1.5),0.35): return false
	_release()
	await _frames(2)
	if arbiter.get("_winning_provider") != prompt:
		return _fail("Expected offer %s, actual %s" % [prompt.get_path(),arbiter.get("_winning_provider")])
	var prompt_path := str(prompt.get_path())
	_log("interaction_context", {"prompt":prompt_path,"prompt_position":str(prompt.global_position),"root_position":str(prompt.get_parent().global_position),"on_floor":player.is_on_floor(),"locomotion_enabled":player.locomotion_enabled(),"root_distance":player.global_position.distance_to(prompt.get_parent().global_position),"manager_state":manager.state,"senn_defeated":_has("defeated_cloudreach_senn")})
	await _tap("interact")
	_log("input_interact", {"prompt": prompt_path})
	if not flag.is_empty() and not _require(_has(flag),"Input completed "+flag): return false
	return true


func _arrival_gather(id: String, item: String) -> bool:
	var resource: Node3D = world.get_node("CloudreachResources/" + id)
	var prompt: Node3D = resource.find_child("Interactable",true,false)
	if prompt == null: return _fail("Missing arrival resource " + id)
	if not await _walk(prompt.global_position + Vector3(0,-0.8,-1.5),0.35): return false
	var before: int = game.inventory.count(item)
	if str(game.items.gathered_with(item)) == "knife" and str(game.equipped_tool) != "knife":
		await _tap("hotbar_1")
		if not _require(str(game.equipped_tool)=="knife","Real hotbar input equipped gathering knife"): return false
	if not await _interact(prompt,"",false): return false
	await _frames(100)
	_log("optional_gather", {"id":id,"item":item,"gained":game.inventory.count(item)-before})
	return _require(game.inventory.count(item)>before,"Optional arrival gather produced " + item)


func _talk(id: String, flag: String, navigate: bool = true) -> bool:
	stage="talk_"+id
	var body: Node3D = chapter.npc_bodies().get(id)
	if body == null: return _fail("Missing NPC "+id)
	if navigate and not await _navigate(body.global_position+Vector3(0,0,-2)): return false
	if not await _interact(body.get_node("Interactable")): return false
	var panel: Node = world.get_node("DialoguePanel")
	for line in 45:
		if not panel.is_open(): break
		await _frames(20)
		await _tap("interact")
	await _frames(15)
	if not _require(_has(flag),"Dialogue completed "+flag): return false
	await _capture(stage)
	return true


func _physical_action(id: String, flag: String, navigate: bool = true) -> bool:
	stage=id
	var prompt: Node3D=physical.get_node(id+"/Interactable")
	if navigate and not await _navigate(prompt.global_position-Vector3.UP*0.8): return false
	return await _interact(prompt,flag)


func _pickup(id: String) -> bool:
	stage="pickup_"+id
	var pickup: Node3D=physical.get_node_or_null(id)
	if pickup==null: return _fail("Missing authored pickup "+id)
	var prompt: Node3D=pickup.find_child("Interactable",true,false)
	return await _interact(prompt)


func _rest(id: String) -> bool:
	stage="rest_"+id
	var camp: Node3D=physical.get_node_or_null(id)
	if camp==null: return _fail("Missing unlocked camp "+id)
	if not await _navigate(camp.global_position): return false
	var day_before:int=game.day
	var team_before := _team_snapshot()
	if not await _interact(camp.get_node("Interactable")): return false
	await _frames(60)
	_log("rest_delta", {"id":id,"day_before":day_before,"day_after":game.day,"team_before":team_before,"team_after":_team_snapshot()})
	return _require(game.day>day_before,"Actual camp rest advanced day")


func _battle(id: String) -> bool:
	stage="battle_"+id
	var body: Node3D=director.trainer_nodes.get(id)
	if body==null: return _fail("Missing trainer "+id)
	if not await _navigate(body.global_position+Vector3(3,0,0)): return false
	if director.ally_body()==null: await _tap("creature_recall")
	await _frames(30)
	var prompt: Node3D=director.trainer_prompts[id]
	if not await _interact(prompt): return false
	await _frames(20)
	if not _require(director.trainer_battle_active(),"Real input started "+id): return false
	await _capture(stage)
	var team_before := _team_snapshot()
	var coin_before: int = game.inventory.count("coin")
	var rounds:=0
	var resolved_enemies: Dictionary = {}
	for frame in 2400:
		if int(manager.state) == 1 and manager._enemy != null and not resolved_enemies.has(manager._enemy.get_instance_id()):
			# Explicit TEST-ONLY lethal seam after real trigger/body/manager start.
			# ACTIVE only: is_fighting() includes RESOLVING, which would repeat XP.
			# Each actual enemy receives exactly one reward/resolve invocation.
			resolved_enemies[manager._enemy.get_instance_id()] = true
			manager._enemy.take_damage(float(manager._enemy.hp)+1)
			manager._award_victory()
			manager._begin_resolve("won")
			rounds+=1
		if not director.trainer_battle_active(): break
		await _frames(1)
	await _frames(20)
	_log("battle_resolved", {"id":id,"rounds":rounds,"damage_seam":"test-only lethal after actual production start","coins_gained":game.inventory.count("coin")-coin_before,"team_before":team_before,"team_after":_team_snapshot()})
	return _require(not director.trainer_battle_active() and rounds>0,"Production round callbacks finished "+id)


func _team_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member: RefCounted in game.party.members():
		result.append({"label":member.label(),"level":member.level,"xp":member.xp,"hp":member.hp})
	return result


func _deploy() -> bool:
	_release()
	var stamina_before: float = player.vitals.stamina
	for tick in 600:
		if not player.is_on_floor() or player.vitals.stamina >= player.vitals.max_stamina * 0.98: break
		await _frames(1)
	if player.vitals.stamina > stamina_before + 1:
		_log("flight_preparation_recovery", {"stamina_before":stamina_before,"stamina_after":player.vitals.stamina,"method":"Standing on verified floor; ordinary stamina regeneration"})
	await _tap("jump")
	await _tap("jump")
	if not _require(fly.is_flying(),"Double-jump input deployed Fly"): return false
	var roster_ids: Array[int] = []
	for member: RefCounted in game.party.members(): roster_ids.append(member.get_instance_id())
	if not _require(roster_ids == initial_party_ids and fly.last_flight_used_mentor_loaner(),"Maela loaner carries the unchanged five-non-Fly team without a sixth slot"): return false
	_log("flight_launch", {"carrier":fly.eligible_creature().species_id,"loaner":true,"stamina":player.vitals.stamina,"party_size":roster_ids.size()})
	return true


func _fly_to(target: Vector3, radius: float = 5.0) -> bool:
	for frame in 10800:
		var offset:=target-player.global_position
		if offset.length()<radius:
			_release()
			_log("flight_waypoint", {"target":str(target),"state":fly.state,"flight_seconds":fly.flight_seconds,"stamina":player.vitals.stamina})
			return true
		if not fly.is_flying(): return _fail("Flight ended before "+str(target))
		var horizontal:=Vector2(offset.x,offset.z).length()
		_steer(offset,clampf(horizontal/12,0,1))
		_input("jump",1 if offset.y>2 else 0)
		_input("fly_descend",1 if offset.y < -8 else 0)
		await _frames(1)
		if failed:return false
	return _fail("Flight timeout toward "+str(target))


func _land(at: Vector3) -> bool:
	for frame in 2400:
		if not fly.is_flying():
			_release(); await _frames(12)
			return _require(player.is_on_floor() and player.global_position.distance_to(at)<14,"Collision landing at "+str(at))
		_steer(at-player.global_position,clampf(Vector2(at.x-player.global_position.x,at.z-player.global_position.z).length()/8,0,1))
		_input("jump",0); _input("fly_descend",1)
		await _frames(1)
		if failed:return false
	return _fail("Landing timed out "+str(at))


func _trial() -> bool:
	stage="authored_flight_trial"
	if not await _physical_action("flight_trial_start", "",false):return false
	if not _require(physical.trial_active,"Marked trial input started"):return false
	if not await _deploy():return false
	for gate: Dictionary in physical.config.trial.gates:
		if not await _fly_to(_vec(gate.position),3):return false
	await _capture("trial-airborne")
	if not await _land(_vec(physical.config.trial.landing_position)):return false
	return _require(_has("fly_traversal_unlocked"),"Ordered airborne rings and landing unlocked Fly")


func _require(condition: bool, label: String) -> bool:
	if not condition:return _fail(label)
	_log("assertion", {"label":label})
	return true


func _fail(message: String) -> bool:
	if not failed:
		failed=true
		_release()
		_log("FAIL", {"message":message})
	return false


func _log(kind: String, details: Dictionary = {}) -> void:
	var row: Dictionary={"kind":kind,"stage":stage,"simulated_seconds":snappedf(simulated_seconds,0.01),"wall_seconds":(Time.get_ticks_usec()-start_usec)/1000000.0,"position":str(player.global_position) if is_instance_valid(player) else "boot"}
	row.merge(details)
	rows.append(row)
	if kind in ["meaningful_offer","input_interact","physical_interaction","battle_started","battle_victory","trial_gate","optional_gather","resource_delta","flight_launch","flight_waypoint"]:
		if not previous_activity.is_empty():
			activity_intervals.append({"from":previous_activity.kind,"to":kind,"from_stage":previous_activity.stage,"to_stage":stage,"start_seconds":previous_activity.simulated_seconds,"end_seconds":snappedf(simulated_seconds,0.01),"gap_seconds":snappedf(simulated_seconds-float(previous_activity.simulated_seconds),0.01)})
		previous_activity = row
	if kind not in ["travel_start","travel_arrived"]: last_activity=simulated_seconds
	print("CLOUDREACH CONTINUOUS "+JSON.stringify(row))
	_write_report()


func _write_report() -> void:
	var file:=FileAccess.open(OUTPUT+"/events.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed and stage=="complete","stage":stage,"distance_m":distance_m,"longest_dead_travel_seconds":longest_dead_travel,"accelerated":accelerated,"activity_intervals":activity_intervals,"events":rows},"  "))


func _capture(label: String) -> void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	checkpoint+=1
	root.get_texture().get_image().save_png(OUTPUT+"/%02d-%s.png"%[checkpoint,label])
	_log("capture",{"label":label,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"fps":Performance.get_monitor(Performance.TIME_FPS),"performance_valid":not accelerated})


func _finish() -> void:
	_release()
	if not completed_route and not failed:
		_fail("Harness returned before reaching the final persistence/non-entry assertions")
	if completed_route and not failed:stage="complete"
	_write_report()
	print("CLOUDREACH CONTINUOUS %s stage=%s distance_m=%.1f dead_travel_max_s=%.1f"%["FAIL" if failed else "PASS",stage,distance_m,longest_dead_travel])
	quit(1 if failed else 0)
