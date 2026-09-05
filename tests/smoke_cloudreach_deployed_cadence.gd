extends "res://tests/smoke_cloudreach_continuous.gd"

## Zero-Cloudreach-seed cadence evidence with the owned companion deployed by
## real recall input. The route only moves forward: arrival road -> Aila ->
## west anchor -> causeway -> east anchor -> Senn approach. Dead-travel clocks
## run only inside those authored travel calls, excluding dialogue, gathering,
## interaction waits, and any diagnostic/backtracking fixture time.

const CADENCE_REVIEW_SECONDS:=60.0
const CADENCE_BAR_SECONDS:=90.0

var cadence_travelling:=false
var cadence_travel_seconds:=0.0
var cadence_distance_m:=0.0
var cadence_last_position:=Vector3.INF
var cadence_last_reset_seconds:=0.0
var cadence_last_reset_distance:=0.0
var cadence_last_reset_position:="route_start"
var cadence_offers: Array[Dictionary]=[]
var cadence_choices: Array[Dictionary]=[]
var dead_travel_intervals: Array[Dictionary]=[]


func _run() -> void:
	start_usec=Time.get_ticks_usec()
	accelerated="--accelerated" in OS.get_cmdline_user_args()
	if accelerated:
		Engine.time_scale=8.0
		Engine.physics_ticks_per_second=480
		Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/deployed-cadence"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.save_system=SAVE.new("user://cloudreach_deployed_cadence")
	# Completed-Meadows handoff only. No Cloudreach chapter/objective flag is seeded.
	for flag: String in ["warden_defeated","realm_key_cloudreach",
			"realm_heart_meadows_earned","realm_heart_meadows_placed",
			"realm_gate_cloudreach_unlocked"]:
		game.progression.set_flag(flag)
	game.realm_hearts.activate("meadows",game.progression)
	for species: String in ["sparkit","mudsnout","bramblebun","terrapup","brooktail"]:
		var member: RefCounted=SPECIES.spawn(species)
		member.set_level(25,PROGRESSION.config())
		game.party.add(member)
	for item: String in ["knife","axe","pickaxe"]:
		game.inventory.add(item,1)
	game.assign_hotbar(0,"knife")
	game.current_realm="cloudreach"
	world=SCENE.instantiate()
	root.add_child(world)
	current_scene=world
	player=world.get_node("Player")
	chapter=world.get_node("CloudreachChapter")
	physical=chapter.physical_runtime()
	runtime=world.get_node("CloudreachRuntime")
	director=runtime.director
	manager=runtime.manager
	fly=player.fly_controller
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations+=1
		last_activated_path=str(provider.get_path())
		_mark_cadence_choice(last_activated_path)
		_log("offer_activated",{"path":last_activated_path}))
	world.get_node("DialoguePanel").finished.connect(func(id: String) -> void:
		_log("dialogue_finished",{"id":id}))
	physical.interaction_completed.connect(func(id: String) -> void:
		_log("physical_interaction",{"id":id}))
	physics_frame.connect(_record_frame)
	await _frames(20)
	stage="deployed_cadence_arrival"
	await _tap("creature_recall")
	await _frames(20)
	_require(director.ally_body()!=null,"Real recall input deployed the active owned companion")
	_log("companion_deployed_input",{"species_id":game.party.active().species_id,
		"body":str(director.ally_body().get_path()) if director.ally_body()!=null else "none",
		"cloudreach_seed_count":0})
	cadence_last_position=player.global_position
	cadence_last_reset_position=str(player.global_position)

	var arrival:=_route("arrival_gate_road")
	var ruin: Node3D=world.find_child("InspectArrivalRuin",true,false)
	if not await _walk_forward(ruin.global_position+Vector3(0,-1,-2)): return _finish_cadence()
	if not await _interact(ruin,"",false): return _finish_cadence()
	if not await _walk_forward(_vec(arrival.polyline[1])): return _finish_cadence()
	if not await _arrival_gather("cr_node_cloudberry_waycamp","cloudberry"): return _finish_cadence()
	if not await _walk_forward(_vec(arrival.polyline[2])): return _finish_cadence()
	if not await _arrival_gather("cr_node_gale_fiber_gate","gale_fiber"): return _finish_cadence()
	if not await _walk_forward(_vec(arrival.polyline[3])): return _finish_cadence()
	if not await _walk_forward(Vector3(-280,180,508)): return _finish_cadence()
	if not await _talk("warden_aila","cloudreach_crisis_learned"): return _finish_cadence()

	stage="deployed_cadence_lower_west"
	if not await _navigate_forward(chapter.get_node("lower_west").global_position): return _finish_cadence()
	if not await _interact(chapter.get_node("lower_west/Interactable"),"storm_anchor_lower_west_mapped"): return _finish_cadence()
	stage="deployed_cadence_causeway"
	var causeway_fiber: Node3D=world.get_node("CloudreachResources/cr_node_gale_fiber_causeway")
	if not await _navigate_forward(causeway_fiber.global_position): return _finish_cadence()
	if not await _arrival_gather("cr_node_gale_fiber_causeway","gale_fiber"): return _finish_cadence()
	stage="deployed_cadence_lower_east"
	if not await _navigate_forward(chapter.get_node("lower_east").global_position): return _finish_cadence()
	if not await _interact(chapter.get_node("lower_east/Interactable"),"cloudreach_lower_anchors_investigated"): return _finish_cadence()
	stage="deployed_cadence_senn_approach"
	var senn_prompt: Node3D=director.trainer_prompts["tether_lieutenant_senn"]
	if not await _navigate_forward(senn_prompt.global_position): return _finish_cadence()
	_finalize_dead_interval("route_end",str(player.global_position))
	for category: String in ["engage","resource","npc","rest"]:
		_require(cadence_offers.any(func(row: Dictionary) -> bool:
			return str(row.get("category",""))==category),
			"Natural deployed route exposed an actual "+category+" offer")
	var violations:=dead_travel_intervals.filter(func(row: Dictionary) -> bool:
		return float(row.get("gap_seconds",0.0))>CADENCE_BAR_SECONDS)
	var review_intervals:=dead_travel_intervals.filter(func(row: Dictionary) -> bool:
		return float(row.get("gap_seconds",0.0))>CADENCE_REVIEW_SECONDS)
	_log("cadence_summary",{"offers":cadence_offers,"dead_travel_intervals":dead_travel_intervals,
		"choices":cadence_choices,
		"review_intervals_over_60s":review_intervals,"violations_over_90s":violations,
		"natural_route_distance_m":cadence_distance_m,
		"natural_travel_seconds":cadence_travel_seconds,
		"excluded_time":"dialogue, interaction waits, gathering, diagnostics, backtracking"})
	_require(violations.is_empty(),"No natural deployed-route dead-travel interval exceeds the 90-second chapter bar")
	_finish_cadence()


func _record_frame() -> void:
	var row_start:=rows.size()
	if cadence_travelling and is_instance_valid(player):
		cadence_travel_seconds+=1.0/60.0
		if cadence_last_position!=Vector3.INF:
			cadence_distance_m+=player.global_position.distance_to(cadence_last_position)
		cadence_last_position=player.global_position
	super._record_frame()
	for index in range(row_start,rows.size()):
		var row: Dictionary=rows[index]
		if str(row.get("kind",""))!="meaningful_offer": continue
		var offer:=row.duplicate(true)
		offer["category"]=_offer_category(offer)
		offer["natural_travel_seconds"]=snappedf(cadence_travel_seconds,0.01)
		offer["natural_route_distance_m"]=snappedf(cadence_distance_m,0.01)
		cadence_offers.append(offer)
		_finalize_dead_interval(str(offer.get("label","offer")),str(offer.get("position","")))


func _offer_category(row: Dictionary) -> String:
	var label:=str(row.get("label","")).to_lower()
	var path:=str(row.get("path","")).to_lower()
	if label.begins_with("engage "): return "engage"
	if label.begins_with("gather ") or label.begins_with("take ") \
			or path.contains("cloudreachresources"): return "resource"
	if label.begins_with("greet ") or label.begins_with("challenge ") or path.contains("cloudreachpeople"): return "npc"
	if label.begins_with("rest ") or path.contains("campcreaturebed"): return "rest"
	return "other"


func _mark_cadence_choice(path: String) -> void:
	var choice:={"path":path,"natural_travel_seconds":snappedf(cadence_travel_seconds,0.01),
		"natural_route_distance_m":snappedf(cadence_distance_m,0.01),"matched_offer":false}
	for index in range(cadence_offers.size()-1,-1,-1):
		var offer: Dictionary=cadence_offers[index]
		if str(offer.get("path","")).begins_with(path):
			offer["chosen"]=true
			offer["chosen_at_natural_travel_seconds"]=snappedf(cadence_travel_seconds,0.01)
			choice.matched_offer=true
			break
	cadence_choices.append(choice)


func _finalize_dead_interval(to_label: String,to_position: String) -> void:
	var gap:=cadence_travel_seconds-cadence_last_reset_seconds
	var gap_distance:=cadence_distance_m-cadence_last_reset_distance
	dead_travel_intervals.append({"from":cadence_last_reset_position,"to":to_position,
		"to_label":to_label,"gap_seconds":snappedf(gap,0.01),
		"gap_distance_m":snappedf(gap_distance,0.01)})
	cadence_last_reset_seconds=cadence_travel_seconds
	cadence_last_reset_distance=cadence_distance_m
	cadence_last_reset_position=to_position


func _walk_forward(target: Vector3) -> bool:
	cadence_travelling=true
	cadence_last_position=player.global_position
	var result:=await _walk(target)
	cadence_travelling=false
	return result


func _navigate_forward(target: Vector3) -> bool:
	cadence_travelling=true
	cadence_last_position=player.global_position
	var result:=await _navigate(target)
	cadence_travelling=false
	return result


func _finish_cadence() -> void:
	_release()
	var report:=FileAccess.open(output_dir+"/cadence.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed":not failed,"zero_cloudreach_seeds":true,
		"companion_deployed_by_input":director!=null and director.ally_body()!=null,
		"distance_m":cadence_distance_m,"travel_seconds":cadence_travel_seconds,
		"offers":cadence_offers,"choices":cadence_choices,
		"dead_travel_intervals":dead_travel_intervals,"events":rows},"  "))
	report.close()
	print("CLOUDREACH DEPLOYED CADENCE %s distance_m=%.1f travel_s=%.1f offers=%d dead_max_s=%.1f"%[
		"FAIL" if failed else "PASS",cadence_distance_m,cadence_travel_seconds,
		cadence_offers.size(),_longest_dead_gap()])
	quit(1 if failed else 0)


func _longest_dead_gap() -> float:
	var longest:=0.0
	for interval: Dictionary in dead_travel_intervals:
		longest=maxf(longest,float(interval.get("gap_seconds",0.0)))
	return longest
