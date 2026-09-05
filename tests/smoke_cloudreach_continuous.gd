extends SceneTree

## Continuous production chapter, not a checkpoint montage. All route movement
## uses InputEventAction and the actual controller/collision. No position writes.
## Completed-Meadows entitlement/Heart precondition reuses the separately proven
## smoke_meadows_realm_handoff + smoke_cloudreach_transition path. Optional
## clock acceleration preserves the simulation step; enemy defeat has the
## separately declared lethal seam unless --live-combat is supplied. Live
## combat uses the balance lane's controller-input pilot at normal 1x from
## challenge input through the real victory/loss/timeout callback. No
## Cloudreach objective is seeded.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const PILOT := preload("res://tools/combat_pilot.gd")
const BALANCE := preload("res://tools/_probe_cloudreach_combat_balance.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const OUTPUT_ROOT := "res://ralph/reports/CLOUDREACH-CONTINUOUS-0905"
const LIVE_BATTLE_FRAME_LIMIT := 36000
const PERSISTED_MEMBER_FIELDS: Array[String] = [
	"species_id", "display_name", "creature_type", "secondary_type", "nickname",
	"base_hp", "base_attack", "base_defence", "max_hp", "attack", "defence",
	"hp", "energy", "fainted", "resting", "rested", "rest_bed_index", "level",
	"xp", "bond", "battles_fought", "caught_on_day", "levels_gained_with_you",
	"landmarks_visited_together", "distance_m_together", "rest_nights_together",
	"feeds_together", "move_quick", "move_charged", "iv_hp", "iv_attack",
	"iv_defence", "trait_primary", "trait_secondary", "shiny", "boost_hp",
	"boost_attack", "boost_defence", "nourishment", "happiness",
	"rested_seconds_left",
]
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
var live_combat := false
var output_dir := ""
var completed_route := false
var offered: Dictionary = {}
var offer_poll := 0
var initial_party_ids: Array[int] = []
var last_reported_denial := ""
var activity_intervals: Array[Dictionary] = []
var previous_activity: Dictionary = {}
var interaction_activations := 0
var last_activated_path := ""
var combat_pilot: RefCounted = null
var battle_starts: Array[String] = []
var battle_wins: Array[String] = []
var battle_losses: Array[String] = []
var recovery_choices: Array[Dictionary] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1920,1200)
	accelerated = "--accelerated" in OS.get_cmdline_user_args()
	live_combat = "--live-combat" in OS.get_cmdline_user_args()
	output_dir = OUTPUT_ROOT + ("/live" if live_combat else "/mechanics-only")
	if accelerated:
		Engine.time_scale = 8.0
		Engine.physics_ticks_per_second = 480
		Engine.max_physics_steps_per_frame = 32
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	var fixture_dir := "user://cloudreach_continuous_acceptance_live" if live_combat else "user://cloudreach_continuous_acceptance_mechanics"
	game.save_system = SAVE.new(fixture_dir)
	# This exact test-owned slot may have been autosaved by a previous camp
	# night. Remove it before building the declared fresh Meadows-complete
	# fixture; no player save directory is touched.
	var stale_slot := str(game.save_system.call("slot_path", 0))
	if FileAccess.file_exists(stale_slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_slot))
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
	combat_pilot = BALANCE.InputPilot.new(self, manager, director, world.get_node("CameraRig"))
	combat_pilot.pilot = PILOT.Pilot.SPACER
	combat_pilot.switch_input = true
	combat_pilot.use_switching = false
	combat_pilot.listen()
	physics_frame.connect(_record_frame)
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path())
		_log("offer_activated", {"path":last_activated_path}))
	world.get_node("DialoguePanel").finished.connect(func(id: String) -> void: _log("dialogue_finished", {"id":id}))
	director.trainer_started.connect(func(id: String) -> void:
		battle_starts.append(id)
		_log("battle_started", {"id": id}))
	director.trainer_victory.connect(func(id: String) -> void:
		battle_wins.append(id)
		_log("battle_victory", {"id": id}))
	director.trainer_lost.connect(func(id: String) -> void:
		battle_losses.append(id)
		_log("battle_loss", {"id": id}))
	director.trainer_opposition_changed.connect(func(id: String, remaining: int, total: int) -> void: _log("opposition", {"id": id,"remaining": remaining,"total": total}))
	physical.interaction_completed.connect(func(id: String) -> void: _log("physical_interaction", {"id": id}))
	physical.trial_progress.connect(func(passed: int, total: int) -> void: _log("trial_gate", {"passed": passed,"total": total}))
	fly.recovered.connect(func(reason: String) -> void: _fail("Unexpected recovery interrupts continuous route: " + reason))
	fly.landed.connect(func(at: Vector3, carrier: String) -> void:
		_log("flight_landed", {"landing_position":str(at),"carrier":carrier,"on_floor":player.is_on_floor(),"state":fly.state,"stamina":player.vitals.stamina,"shrine_reached":_has("sky_shrine_reached")}))
	fly.denied.connect(func(reason: String) -> void:
		if reason != last_reported_denial:
			last_reported_denial = reason
			_log("flight_denied", {"reason":reason,"state":fly.state,"velocity":str(player.velocity)}))
	await _frames(20)
	_log("precondition", {"description": "Fresh completed-Meadows fixture; five level-25 installed creatures; active Meadows Heart; separate proven handoff reused", "accelerated": accelerated,"combat_mode":"live_input" if live_combat else "mechanics_only_test_lethal", "team":_team_snapshot(),"inventory":_inventory_snapshot()})
	_purpose("Orient in Cloudreach and learn why the routes are broken", "Take the authored arrival road, inspect its landmark, and gather useful preparation instead of beelining")
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
	_purpose("Map the lower storm anchors and reconnect the stranded causeway", "Use the grounded bridge network and accept required encounters; optional trainers remain optional")
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
	_purpose("Repair the aerie and earn Fly without displacing the permanent five", "Use Maela's temporary Galecrest loaner and complete the marked ring trial")
	if not await _trial(): return _finish()
	stage = "mandatory_high_roost_flight"
	if not await _deploy(): return _finish()
	for target: Vector3 in [Vector3(535,760,3170), Vector3(750,935,3030), Vector3(1020,1075,2960)]:
		if not await _fly_to(target): return _finish()
	# The shrine crown can legitimately intercept the final descent before the
	# exact airborne waypoint. Accept only a verified floor inside this landing.
	if not await _fly_to(Vector3(1110,1053,2940),5.0,Vector3(1110,1050,2940)): return _finish()
	if not await _land(Vector3(1110,1050,2940)): return _finish()
	if not _require(_has("sky_shrine_reached"), "Actual Fly-only shrine landing"): return _finish()
	await _capture("high-roost-landing")
	for id: String in ["shrine_vane_west", "shrine_vane_east", "shrine_vane_crown"]:
		if not await _physical_action(id, "cloudreach_" + id + "_aligned", false): return _finish()
	if not await _talk("naturalist_sora", "storm_anchor_engine_truth_learned", false): return _finish()
	if not await _physical_action("shrine_windlass", "cloudreach_upper_route_unlocked", false): return _finish()
	stage = "return_glide_to_grounded_counterweight"
	_purpose("Turn the Fly-only shrine discovery into a grounded road for the upper chapter", "Return by controlled flight, then take the newly unlocked counterweight route")
	if not await _return_to_aerie(): return _finish()
	if not await _navigate(Vector3(-720,700,3680)): return _finish()
	if not _require(_has("cloudreach_act_ii_complete"), "Grounded counterweight route entered"): return _finish()
	if not await _physical_action("upper_anchor_west", "storm_anchor_upper_west_disabled"): return _finish()
	if not await _physical_action("upper_anchor_east", "storm_anchor_upper_east_disabled"): return _finish()
	if not await _battle("officer_voss_summit_approach"): return _finish()
	if not await _physical_action("summit_feed", "cloudreach_upper_anchors_disabled"): return _finish()
	_purpose("Prepare the injured team at the last safe bivouac before the captain", "Use authored creature-bed assignment and trainer sleep; spend no direct healing seam")
	if not await _rest("summit_bivouac"): return _finish()
	if not await _navigate(Vector3(100,1160,5350)): return _finish()
	if not _require(_has("summit_extraction_engine_reached"), "Real summit threshold"): return _finish()
	if not await _battle("captain_veyra_storm_anchor"): return _finish()
	stage = "creature_relay_phase"
	_purpose("Finish the storm-anchor crisis as a creature, not the human", "Pilot the deployed creature inward to all three relays after the captain battle")
	if not _require(runtime.creature_piloted(),"Captain victory handed control to the deployed creature"): return _finish()
	for relay: Dictionary in runtime.finale.config.relays:
		var prompt: Node3D = runtime.finale.get_node("Relay_" + str(relay.id))
		var inward := -Vector3(relay.offset[0],0,relay.offset[2]).normalized()
		if not await _walk(prompt.global_position + Vector3(0,-0.8,0) + inward*2.0, 0.6, runtime.controlled_body()): return _finish()
		if not await _interact(prompt, relay.flag_id, false): return _finish()
	if not _require(_has("storm_anchor_network_disabled"), "Three deployed-creature relay actions"): return _finish()
	stage = "aftermath_overlook"
	_purpose("Witness Cloudreach respond and claim the chapter reward", "Visit the Waterward overlook while preserving the future realm as visible but non-enterable")
	# The authored summit loop begins at the threshold, while the finale leaves
	# control on the circular deck. Exit over the same real central approach used
	# to enter; attaching diagonally to the nearest loop edge cuts outside both
	# the radius-36 arena and its 12m approach despite both supports being valid.
	var finale_origin:=_vec(runtime.finale.config.get("arena_origin",[100.0,1160.0,5450.0]))
	for exit_point: Vector3 in [finale_origin-Vector3(0.0,0.0,30.0), finale_origin-Vector3(0.0,0.0,50.0), Vector3(100.0,1160.0,5350.0)]:
		if not await _walk(exit_point): return _finish()
	if not await _navigate(Vector3(-420,1110,5650)): return _finish()
	await _frames(30)
	if not _require(_has("cloudreach_winds_restored"), "Witness restored winds at overlook"): return _finish()
	var reward_coins_before: int = game.inventory.count("coin")
	if not await _talk("warden_aila", "cloudreach_chapter_complete", false): return _finish()
	_log("chapter_reward_delta", {"coins_before":reward_coins_before,"coins_after":game.inventory.count("coin"),"inventory":_inventory_snapshot(),"team":_team_snapshot()})
	await _capture("waterward-reward")
	var coins: int = game.inventory.count("coin")
	var saved_inventory := _inventory_snapshot()
	var saved_team := _team_snapshot()
	var saved_flags := _flag_snapshot()
	# Nourishment, happiness, and the rested timer are real-time state. Freeze
	# world processing only around this synchronous persistence observation so
	# an ordinary condition tick cannot land between the before/after reads and
	# masquerade as a serialization defect.
	paused=true
	var saved_party_exact := _party_persistence_snapshot()
	var save_ok: bool=game.save_game(0)
	var load_ok: bool=save_ok and game.load_game(0)
	var loaded_party_exact:=_party_persistence_snapshot()
	var party_differences:=_party_persistence_differences(saved_party_exact,loaded_party_exact)
	paused=false
	if not _require(save_ok, "Save completed continuous run"): return _finish()
	if not _require(load_ok, "Reload completed continuous run"): return _finish()
	_log("persistence_party_diff", {"differences":party_differences,
		"before":saved_party_exact,"after":loaded_party_exact})
	_require(party_differences.is_empty(),"Disk reload preserved every persisted field of all five members")
	_require(_flag_snapshot() == saved_flags,"Disk reload preserved the exact progression-flag set")
	await _frames(30)
	for flag: String in ["realm_heart_cloudreach_earned", "realm_key_water", "waterward_route_revealed", "captain_veyra_defeated", "cloudreach_chapter_complete"]:
		_require(_has(flag), "Reload preserved " + flag)
	_require(game.inventory.count("coin") == coins, "Reload did not duplicate payouts")
	_require(_inventory_snapshot() == saved_inventory,"Reload preserved every occupied inventory slot")
	_require(_team_snapshot() == saved_team,"Reload preserved all five species, levels, XP and HP")
	_require(not game.can_enter_realm("water"), "Water realm remains non-enterable")
	_log("persistence_snapshot", {"inventory":_inventory_snapshot(),"team":_team_snapshot(),"party_exact":_party_persistence_snapshot(),"flags":_flag_snapshot(),"day":game.day,"water_enterable":game.can_enter_realm("water")})
	_log("complete", {"optional_trainers": "not attempted", "optional_detours": "opening candy; required fiber and camp preparation", "recovery_choices":recovery_choices, "combat_mode":"live_input" if live_combat else "mechanics_only_test_lethal"})
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
	if is_equal_approx(float(input_values.get(action, -1)), strength) and is_equal_approx(Input.get_action_strength(action), strength): return
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


func _record_frame() -> void:
	# Count every production physics tick, including ticks while input waits for
	# an idle frame. Coroutine-only counting understated those waits.
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
			if not is_instance_valid(candidate) or not candidate is Node: continue
			var prompt: Node = candidate
			if not prompt.has_method("interaction_offer"): continue
			var offer: Dictionary = prompt.call("interaction_offer", runtime.controlled_body().global_position)
			if not offer.is_empty() and bool(offer.get("actionable", true)):
				var key := str(prompt.get_path())
				# Wild engagement is supplied by a non-spatial director. Track
				# each actual nearby body, not just its shared provider once.
				if prompt == director:
					var wild: Node3D = director.call("_engageable")
					if wild != null: key += ":" + str(wild.get_path())
				if offered.has(key): continue
				offered[key] = true
				_log("meaningful_offer", {"path":key,"label":str(offer.label),"distance_m":offer.get("distance",0),"chosen":false})


func _normal_input_clock(reason: String) -> Dictionary:
	var previous := {"time_scale":Engine.time_scale,"physics_hz":Engine.physics_ticks_per_second}
	if Engine.time_scale == 1.0 and Engine.physics_ticks_per_second == 60: return previous
	await process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	_log("clock_mode", {"reason":reason,"time_scale":1.0,"physics_hz":60})
	return previous


func _restore_route_clock(previous: Dictionary) -> void:
	if Engine.time_scale == previous.time_scale and Engine.physics_ticks_per_second == previous.physics_hz: return
	await process_frame
	Engine.time_scale = previous.time_scale
	Engine.physics_ticks_per_second = previous.physics_hz
	_log("clock_mode", {"reason":"resume route diagnosis","time_scale":Engine.time_scale,"physics_hz":Engine.physics_ticks_per_second})


func _tap(action: String, synchronize: bool = true) -> void:
	# Deliver an event between physics batches, as hardware input arrives. An
	# accelerated batch can otherwise contain both synthetic edges and miss the
	# just-pressed window. Do not call the interaction/combat methods directly.
	var previous_clock := await _normal_input_clock("button " + action)
	if synchronize: await process_frame
	_input(action,1)
	await _frames(4)
	await process_frame
	_input(action,0)
	await _frames(8)
	await _restore_route_clock(previous_clock)


func _walk(target: Vector3, radius: float = 0.75, body: CharacterBody3D = null) -> bool:
	if failed: return false
	if body == null: body = player
	var previous := body.global_position
	var segment_start := body.global_position
	var recent_collisions: Array[Dictionary] = []
	var recent_mobile_blocker: CharacterBody3D = null
	var mobile_contact_frame := -10000
	var mobile_detours := 0
	var stalls := 0
	var precision_clock: Dictionary = {}
	var started_seconds := simulated_seconds
	var travel_limit := segment_start.distance_to(target) / 5.0 * 3.0 + 30.0
	_log("travel_start", {"target": str(target),"body_path":str(body.get_path()),"body_position":str(body.global_position)})
	for frame in 36000:
		var offset := target - body.global_position
		if simulated_seconds-started_seconds > travel_limit:
			_log("precision_timeout", {"target":str(target),"body_position":str(body.global_position),"velocity":str(body.velocity),"input_vector":str(Input.get_vector("move_left","move_right","move_forward","move_back")),"recent_wall_contacts":recent_collisions})
			return _fail("Walking exceeded measured-distance time limit toward " + str(target))
		if precision_clock.is_empty() and Vector2(offset.x,offset.z).length() < 8.0:
			precision_clock = await _normal_input_clock("grounded precision approach")
			offset = target-body.global_position
		# A live capsule can occupy the exact authored node while still leaving the
		# player close enough to continue the route or use its interaction. Treat
		# only a recent CharacterBody contact inside practical interaction clearance
		# as arrival. Static geometry, missing support, and distant bodies retain the
		# normal stall/timeout failures below.
		var horizontal_distance := Vector2(offset.x,offset.z).length()
		if horizontal_distance < maxf(radius, 1.25) and \
				is_instance_valid(recent_mobile_blocker) and frame-mobile_contact_frame <= 30:
			_release()
			await _frames(12)
			if absf(body.global_position.y-target.y) > 7:
				return _fail("Wrong elevation at mobile-occupied destination " + str(target))
			_log("travel_arrived_mobile_clearance", {
				"target":str(target), "distance_m":horizontal_distance,
				"blocker":str(recent_mobile_blocker.get_path()),
				"blocker_position":str(recent_mobile_blocker.global_position),
				"method":"real stick arrival within interaction clearance"})
			if not precision_clock.is_empty(): await _restore_route_clock(precision_clock)
			return true
		if Vector2(offset.x,offset.z).length() < radius:
			_release()
			await process_frame
			await _frames(12)
			if absf(body.global_position.y-target.y) > 7:
				return _fail("Wrong elevation at destination " + str(target))
			if Vector2(target.x-body.global_position.x,target.z-body.global_position.z).length() >= radius:
				continue
			_log("travel_arrived", {"target": str(target)})
			if not precision_clock.is_empty(): await _restore_route_clock(precision_clock)
			return true
		_steer(offset, clampf(Vector2(offset.x,offset.z).length()/2,0.22,1))
		await _frames(1)
		if failed: return false
		for index in body.get_slide_collision_count():
			var hit := body.get_slide_collision(index)
			var collider:=hit.get_collider()
			var is_mobile:=collider is CharacterBody3D and collider!=body
			# A player can climb partly onto another capsule, yielding a steep or
			# even floor-like contact normal. Track every live CharacterBody contact
			# before the wall-normal filter so it still receives bounded tangent
			# avoidance instead of being misreported as valid static support.
			if is_mobile:
				recent_mobile_blocker=collider as CharacterBody3D
				mobile_contact_frame=frame
			if is_mobile or absf(hit.get_normal().y) < 0.8:
				recent_collisions.append({"position":str(body.global_position),"body":str(hit.get_collider().get_path()),"normal":str(hit.get_normal())})
				if recent_collisions.size() > 24: recent_collisions.pop_front()
		if frame % 120 == 119:
			stalls = stalls + 1 if body.global_position.distance_to(previous) < 0.4 else 0
			previous = body.global_position
			if stalls >= 3:
				# A wandering creature is a player-facing obstacle, not a broken
				# authored route. Preserve and report the displacement, then respond
				# as a player would: steer around it with the real stick. Static world
				# contacts still fall through to the hard diagnostic/failure below.
				if is_instance_valid(recent_mobile_blocker) and frame-mobile_contact_frame <= 360 and mobile_detours < 3:
					mobile_detours += 1
					if await _sidestep_mobile_blocker(body,target,recent_mobile_blocker,mobile_detours):
						stalls=0
						previous=body.global_position
						recent_mobile_blocker=null
						continue
				var input_owner: Node = INPUT_OWNER.current(self)
				var camera_basis: Basis = world.get_node("CameraRig").planar_basis()
				var hazard: Dictionary = runtime.finale.hazard_at(body.global_position) if runtime != null and runtime.finale != null else {}
				var collisions: Array = []
				for index in body.get_slide_collision_count():
					var hit := body.get_slide_collision(index)
					collisions.append({"body": str(hit.get_collider().get_path()), "normal": str(hit.get_normal())})
				_log("collision_block", {"target": str(target), "body_path":str(body.get_path()),"body_position":str(body.global_position),"collisions": collisions,"recent_wall_contacts":recent_collisions,"velocity":str(body.velocity),"last_motion":str(body.get_last_motion()),"floor_normal":str(body.get_floor_normal()),"locomotion_enabled":player.locomotion_enabled(),"carried":player.is_carried(),"physics_processing":player.is_physics_processing(),"can_process":player.can_process(),"process_mode":player.process_mode,"tree_paused":paused,"dialogue_open":world.get_node("DialoguePanel").is_open(),"input_owner":str(input_owner.get_path()) if input_owner != null else "","input_vector":str(Input.get_vector("move_left","move_right","move_forward","move_back")),"camera_basis":str(camera_basis),"wanted_dir":str(player.get("_wanted_dir")),"deflect_dir":str(player.get("_deflect")),"deflect_left":player.get("_deflect_left"),"walk_speed":player.get("_walk_speed"),"move_speed_scale":player.vitals.move_speed_scale(),"auto_run":game.auto_run,"time_scale":Engine.time_scale,"physics_hz":Engine.physics_ticks_per_second,"manager_state":manager.state if manager != null else -1,"manager_fighting":manager.is_fighting() if manager != null else false,"finale_phase":runtime.finale.phase if runtime != null and runtime.finale != null else "","hazard":hazard,"winner":str(world.get_node("InteractionArbiter").get("_winning_provider"))})
				await _capture("blocked-"+stage)
				return _fail("Walking stalled toward " + str(target))
		var expected := Geometry3D.get_closest_point_to_segment(body.global_position,segment_start,target)
		if body.global_position.y < expected.y-20:
			_log("segment_fall", {"from":str(segment_start),"target":str(target),"expected":str(expected),"recent_wall_contacts":recent_collisions})
			await _capture("fall-"+stage)
			return _fail("Fell below authored segment toward " + str(target))
	return _fail("Travel timeout toward " + str(target))


func _sidestep_mobile_blocker(body: CharacterBody3D, target: Vector3,
		blocker: CharacterBody3D, attempt: int) -> bool:
	var forward:=Vector3(target.x-body.global_position.x,0,target.z-body.global_position.z).normalized()
	if forward.is_zero_approx(): return false
	var right:=Vector3.UP.cross(forward).normalized()
	var to_blocker:=Vector3(blocker.global_position.x-body.global_position.x,0,
		blocker.global_position.z-body.global_position.z)
	var preferred_side := -1.0 if to_blocker.dot(right)>=0.0 else 1.0
	var clearance:=_body_collision_radius(blocker)+_body_collision_radius(body)+0.7
	clearance=maxf(clearance,2.2)
	var home: Variant=blocker.get("home")
	for side_try in 2:
		var side:=preferred_side if side_try==0 else -preferred_side
		var centre:=Vector3(blocker.global_position.x,body.global_position.y,blocker.global_position.z)
		var radial:=Vector3(body.global_position.x-centre.x,0,body.global_position.z-centre.z)
		if radial.length()<0.05: radial=-forward
		radial=radial.normalized()
		var side_dir:=right*side
		# Follow the outside of the live capsule instead of aiming one diagonal
		# point through it. Three points form a small tangent arc: away-and-side,
		# beside, then ahead-and-side. If that side is pinned by a second body,
		# retry the mirrored arc using the same real movement input.
		var arc_dirs: Array[Vector3]=[
			(radial+side_dir*0.8).normalized(),
			side_dir,
			(forward+side_dir*0.8).normalized(),
		]
		var waypoints: Array[Vector3]=[]
		for direction: Vector3 in arc_dirs:
			waypoints.append(centre+direction*clearance)
		_log("mobile_obstacle_detour", {"attempt":attempt,"side_try":side_try+1,
			"blocker":str(blocker.get_path()),"blocker_position":str(blocker.global_position),
			"blocker_home":str(home),
			"blocker_displacement_m":blocker.global_position.distance_to(home) if home is Vector3 else -1.0,
			"blocker_radius_m":_body_collision_radius(blocker),"clearance_m":clearance,
			"waypoints":waypoints.map(func(point: Vector3) -> String: return str(point)),
			"method":"three-point real-stick tangent arc; mirrored retry; no position write"})
		var completed:=true
		for waypoint: Vector3 in waypoints:
			if not await _stick_to_detour_waypoint(body,waypoint):
				completed=false
				break
		if completed:
			var passed_plane:=(body.global_position-centre).dot(forward)
			if passed_plane>_body_collision_radius(blocker)+0.35:
				_log("mobile_obstacle_cleared", {"attempt":attempt,"side_try":side_try+1,
					"blocker":str(blocker.get_path()),"passed_plane_m":passed_plane})
				return true
		_log("mobile_obstacle_detour_retry", {"attempt":attempt,"side_try":side_try+1,
			"blocker":str(blocker.get_path()),"position":str(body.global_position),
			"reason":"arc did not make forward clearance"})
	_release()
	return false


func _stick_to_detour_waypoint(body: CharacterBody3D, waypoint: Vector3) -> bool:
	var checkpoint:=body.global_position
	for frame in 960:
		var offset:=waypoint-body.global_position
		if Vector2(offset.x,offset.z).length()<0.6:
			_release()
			await _frames(4)
			return true
		_steer(offset,0.9)
		await _frames(1)
		if frame%240==239:
			if Vector2(body.global_position.x-checkpoint.x,
					body.global_position.z-checkpoint.z).length()<0.18:
				_release()
				return false
			checkpoint=body.global_position
	_release()
	return false


func _body_collision_radius(body: Node3D) -> float:
	var result:=0.0
	for raw: Node in body.find_children("*","CollisionShape3D",true,false):
		var collision:=raw as CollisionShape3D
		if collision==null or collision.disabled or collision.shape==null: continue
		var shape:=collision.shape
		var radius:=0.0
		if shape is CapsuleShape3D: radius=(shape as CapsuleShape3D).radius
		elif shape is SphereShape3D: radius=(shape as SphereShape3D).radius
		elif shape is CylinderShape3D: radius=(shape as CylinderShape3D).radius
		elif shape is BoxShape3D:
			var size: Vector3=(shape as BoxShape3D).size
			radius=maxf(size.x,size.z)*0.5
		var horizontal_scale:=maxf(collision.global_basis.x.length(),collision.global_basis.z.length())
		result=maxf(result,radius*horizontal_scale)
	return maxf(result,0.35)


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
	var previous_clock := await _normal_input_clock("physical interaction")
	var succeeded := await _interact_normal(prompt,flag,approach)
	await _restore_route_clock(previous_clock)
	return succeeded


func _interact_normal(prompt: Node3D, flag: String, approach: bool) -> bool:
	if not is_instance_valid(prompt): return _fail("Missing physical interaction")
	var arbiter: Node = world.get_node("InteractionArbiter")
	# Do not move away from a real winning offer merely to satisfy a canned
	# offset. In particular, reused trainer NPCs also offer separate dialogue.
	if approach and arbiter.get("_winning_provider") != prompt:
		if not await _walk(prompt.global_position+Vector3(0,-0.8,-1.5),0.35): return false
	_release()
	await _frames(2)
	await process_frame
	# Match the arbiter's production press-time scan at the actual event boundary.
	# The idle-frame wait can contain many accelerated movement ticks.
	arbiter.call("_recompute")
	if arbiter.get("_winning_provider") != prompt:
		var controlled: CharacterBody3D = runtime.controlled_body()
		_log("offer_conflict", {"wanted":str(prompt.get_path()),"prompt_position":str(prompt.global_position),"prompt_enabled":prompt.get("enabled"),"target_offer":prompt.call("interaction_offer",controlled.global_position),"winner_offer":arbiter.call("winner"),"actor":str(controlled.get_path()),"actor_position":str(controlled.global_position)})
		return _fail("Expected offer %s, actual %s" % [prompt.get_path(),arbiter.get("_winning_provider")])
	var prompt_path := str(prompt.get_path())
	var activations_before := interaction_activations
	_log("interaction_context", {"prompt":prompt_path,"prompt_position":str(prompt.global_position),"root_position":str(prompt.get_parent().global_position),"on_floor":player.is_on_floor(),"locomotion_enabled":player.locomotion_enabled(),"root_distance":player.global_position.distance_to(prompt.get_parent().global_position),"manager_state":manager.state,"senn_defeated":_has("defeated_cloudreach_senn"),"input_vector":str(Input.get_vector("move_left","move_right","move_forward","move_back")),"velocity":str(player.velocity)})
	await _tap("interact",false)
	_log("input_interact", {"prompt": prompt_path})
	if not _require(interaction_activations == activations_before + 1 and last_activated_path == prompt_path,"Real input activated expected offer " + prompt_path): return false
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
	var previous_clock := await _normal_input_clock("dialogue " + id)
	if not await _interact(body.get_node("Interactable")):
		await _restore_route_clock(previous_clock)
		return false
	var panel: Node = world.get_node("DialoguePanel")
	for line in 45:
		if not panel.is_open(): break
		await _frames(20)
		await _tap("interact")
	await _frames(15)
	await _restore_route_clock(previous_clock)
	if not _require(_has(flag),"Dialogue completed "+flag): return false
	await _capture(stage)
	return true


func _physical_action(id: String, flag: String, navigate: bool = true) -> bool:
	stage=id
	var prompt: Node3D=physical.get_node(id+"/Interactable")
	if navigate and not await _navigate(prompt.global_position-Vector3.UP*0.8): return false
	var fiber_before: int = game.inventory.count("gale_fiber")
	if not await _interact(prompt,flag): return false
	if id == "aerie_repair":
		var spent: int = fiber_before-game.inventory.count("gale_fiber")
		_log("resource_delta", {"id":id,"item":"gale_fiber","before":fiber_before,"after":game.inventory.count("gale_fiber"),"spent":spent})
		return _require(spent == 3,"Actual perch repair spent exactly 3 gathered Gale Fiber")
	return true


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
	if live_combat:
		return await _recover_party_through_camp_input(camp, id)
	var previous_clock := await _normal_input_clock("camp rest and fade")
	var day_before:int=game.day
	var team_before := _team_snapshot()
	if not await _interact(camp.get_node("Interactable")):
		await _restore_route_clock(previous_clock)
		return false
	await _frames(120)
	_log("rest_delta", {"id":id,"day_before":day_before,"day_after":game.day,"team_before":team_before,"team_after":_team_snapshot()})
	await _capture(stage)
	await _restore_route_clock(previous_clock)
	return _require(game.day>day_before,"Actual camp rest advanced day")


func _recover_party_through_camp_input(camp: Node3D, id: String) -> bool:
	var bed: Node3D = camp.get_node_or_null("CampCreatureBed")
	var bed_prompt: Node3D = bed.get_node_or_null("Interactable") if bed != null else null
	var rest_prompt: Node3D = camp.get_node_or_null("Interactable")
	if bed == null or bed_prompt == null or rest_prompt == null:
		return _fail("Missing authored creature-bed/rest input at " + id)
	var previous_clock := await _normal_input_clock("live-combat camp recovery")
	var pending := _injured_party_indices()
	# Even a clean team uses the real bed once. This pins the authored service
	# to the continuous route without assigning HP or invoking recovery code.
	if pending.is_empty():
		pending.append(0)
	for index: int in pending:
		var member: RefCounted = game.party.at(index)
		var before_team := _team_snapshot()
		if director.ally_body() != null:
			await _tap("creature_recall")
			await _frames(12)
		if not await _walk(bed_prompt.global_position + Vector3(0.0, -0.8, -1.2), 0.4):
			await _restore_route_clock(previous_clock)
			return false
		if not await _interact(bed_prompt, "", false):
			await _restore_route_clock(previous_clock)
			return false
		for step in index:
			await _tap("ui_down")
		await _tap("ui_accept")
		await _frames(8)
		if not _require(bool(member.get("resting")) and int(member.get("rest_bed_index")) == int(bed.call("build_index")),
				"Controller input assigned party member %d to %s creature bed" % [index, id]):
			await _restore_route_clock(previous_clock)
			return false
		await _tap("menu_cancel")
		await _frames(8)
		if not await _walk(rest_prompt.global_position + Vector3(0.0, -0.8, 0.8), 0.8):
			await _restore_route_clock(previous_clock)
			return false
		var day_before := int(game.day)
		if not await _interact(rest_prompt, "", false):
			await _restore_route_clock(previous_clock)
			return false
		await _frames(140)
		var choice := {"camp":id,"party_index":index,"species_id":str(member.get("species_id")),
			"day_before":day_before,"day_after":int(game.day),"team_before":before_team,"team_after":_team_snapshot()}
		recovery_choices.append(choice)
		_log("camp_creature_recovery", choice)
		if not _require(int(game.day) == day_before + 1, "Ordinary camp input passed one night at " + id):
			await _restore_route_clock(previous_clock)
			return false
		if not _require(not bool(member.get("fainted")) and float(member.get("hp")) >= float(member.get("max_hp")) - 0.01,
				"Physically bedded party member recovered overnight at " + id):
			await _restore_route_clock(previous_clock)
			return false
	await _capture(stage)
	await _restore_route_clock(previous_clock)
	return _require(_injured_party_indices().is_empty(), "Camp-bed input recovered every injured party member at " + id)


func _injured_party_indices() -> Array[int]:
	var result: Array[int] = []
	for index in game.party.size():
		var member: RefCounted = game.party.at(index)
		if bool(member.get("fainted")) or float(member.get("hp")) < float(member.get("max_hp")) - 0.01:
			result.append(index)
	return result


func _battle(id: String) -> bool:
	stage="battle_"+id
	var body: Node3D=director.trainer_nodes.get(id)
	if body==null: return _fail("Missing trainer "+id)
	var prompt: Node3D=director.trainer_prompts[id]
	if id == "captain_veyra_storm_anchor":
		# Reused Veyra moves from her gatehouse presentation pose to the finale
		# origin when the summit threshold event rebuilds the canonical cast. Do
		# not retain that pre-threshold body position as a navigation target: the
		# diagonal from it to her relocated prompt misses the shipped 12m-wide
		# SummitArenaApproach. Enter through that real central deck with stick
		# input, then approach the current prompt on the overlapping arena floor.
		var arena_origin:=_vec(runtime.finale.config.get("arena_origin",[100.0,1160.0,5450.0]))
		if not await _walk(arena_origin-Vector3(0.0,0.0,50.0)): return false
		await _frames(20)
		if not await _walk(arena_origin+Vector3(3.0,0.0,0.0)): return false
	else:
		if not await _navigate(body.global_position+Vector3(3,0,0)): return false
	if director.ally_body()==null: await _tap("creature_recall")
	await _frames(30)
	var battle_clock: Dictionary = {}
	if live_combat:
		# The normal clock starts before the challenge input and remains in force
		# until the production director emits victory/loss or the live timeout.
		battle_clock = await _normal_input_clock("live combat from challenge input through outcome: " + id)
	var team_before := _team_snapshot()
	var coin_before: int = game.inventory.count("coin")
	var starts_before := battle_starts.count(id)
	var wins_before := battle_wins.count(id)
	var losses_before := battle_losses.count(id)
	if not await _interact(prompt):
		if live_combat: await _restore_route_clock(battle_clock)
		return false
	await _frames(20)
	if not _require(director.trainer_battle_active(),"Real input started "+id):
		if live_combat: await _restore_route_clock(battle_clock)
		return false
	await _capture(stage)
	if live_combat:
		combat_pilot.reset_tally()
		combat_pilot.voluntary_switches = 0
		var round_results: Array[Dictionary] = []
		var battle_start_frame := Engine.get_physics_frames()
		while director.trainer_battle_active() and Engine.get_physics_frames() - battle_start_frame < LIVE_BATTLE_FRAME_LIMIT:
			if manager.is_fighting():
				var opponent: RefCounted = manager.enemy()
				var ally: RefCounted = manager.active_creature()
				var round_result: Dictionary = await combat_pilot.fight_to_the_end()
				round_result["opponent"] = str(opponent.get("species_id")) if opponent != null else ""
				round_result["ally_at_start"] = str(ally.get("species_id")) if ally != null else ""
				round_result["seconds"] = float(round_result.get("frames", 0)) / 60.0
				round_results.append(round_result)
				if bool(round_result.get("timed_out", false)):
					break
			else:
				await _frames(1)
		await _frames(20)
		var timed_out: bool = director.trainer_battle_active()
		var won_callback: bool = battle_wins.count(id) == wins_before + 1
		var loss_callback: bool = battle_losses.count(id) == losses_before + 1
		var result := {"id":id,"mode":"live_input_spacer_switch","rounds":round_results,
			"timed_out":timed_out,"started_callback":battle_starts.count(id)==starts_before+1,
			"victory_callback":won_callback,"loss_callback":loss_callback,
			"coins_gained":game.inventory.count("coin")-coin_before,"team_before":team_before,
			"team_after":_team_snapshot(),"hits_dealt":combat_pilot.hits_dealt,
			"hits_taken":combat_pilot.hits_taken,"damage_dealt":combat_pilot.damage_dealt,
			"damage_taken":combat_pilot.damage_taken,"quick_inputs":combat_pilot.quick_thrown,
			"charged_inputs":combat_pilot.charged_thrown,"switches":combat_pilot.voluntary_switches}
		_log("battle_resolved", result)
		await _restore_route_clock(battle_clock)
		if timed_out:
			return _fail("Live input combat timed out without a production outcome: " + id)
		if loss_callback:
			return _fail("Live input combat lost through the production callback: " + id)
		return _require(won_callback and bool(result.started_callback) and int(result.coins_gained) > 0 and not round_results.is_empty(),
			"Live controller combat earned production victory/reward callbacks for " + id)
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
	_log("battle_resolved", {"id":id,"rounds":rounds,"evidence_scope":"mechanics_only",
		"damage_seam":"test-only lethal after actual production start","coins_gained":game.inventory.count("coin")-coin_before,"team_before":team_before,"team_after":_team_snapshot()})
	return _require(not director.trainer_battle_active() and rounds>0,"Production round callbacks finished "+id)


func _team_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member: RefCounted in game.party.members():
		result.append({"species_id":member.species_id,"label":member.label(),"level":member.level,"xp":member.xp,"hp":member.hp})
	return result


func _party_persistence_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member: RefCounted in game.party.members():
		var row: Dictionary = {}
		for field: String in PERSISTED_MEMBER_FIELDS:
			row[field] = member.get(field)
		result.append(row)
	return result


func _party_persistence_differences(before: Array[Dictionary],after: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if before.size()!=after.size():
		result.append({"field":"party_size","before":before.size(),"after":after.size()})
	for index in mini(before.size(),after.size()):
		for field: String in PERSISTED_MEMBER_FIELDS:
			var before_value: Variant=before[index].get(field)
			var after_value: Variant=after[index].get(field)
			# JSON is the production disk representation. A derived float can have
			# different insignificant binary tail bits before encoding and after
			# decoding while both sides serialize to the exact same JSON number.
			var same_json_float:=typeof(before_value)==TYPE_FLOAT and \
				typeof(after_value)==TYPE_FLOAT and \
				JSON.stringify(before_value)==JSON.stringify(after_value)
			if before_value!=after_value and not same_json_float:
				result.append({"party_index":index,"species_id":str(before[index].get("species_id","")),
					"field":field,"before":before_value,"after":after_value})
	return result


func _flag_snapshot() -> Array:
	var result: Array = game.progression.all_set()
	result.sort()
	return result


func _inventory_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in game.inventory.slot_count():
		var stack: Dictionary = game.inventory.stack_at(index)
		if not stack.is_empty(): result.append({"slot":index,"stack":stack})
	return result


func _deploy() -> bool:
	_release()
	var stamina_before: float = player.vitals.stamina
	for tick in 600:
		if not player.is_on_floor() or player.vitals.stamina >= player.vitals.max_stamina * 0.98: break
		await _frames(1)
	if player.vitals.stamina > stamina_before + 1:
		_log("flight_preparation_recovery", {"stamina_before":stamina_before,"stamina_after":player.vitals.stamina,"method":"Standing on verified floor; ordinary stamina regeneration"})
	# A single accelerated idle-frame batch can consume the entire ordinary
	# jump window. Drive the two physical presses at normal simulation speed,
	# then resume route acceleration; physics remains 1/60 in both modes.
	var previous_clock := await _normal_input_clock("double-jump Fly deployment")
	await _tap("jump")
	await _tap("jump")
	await _restore_route_clock(previous_clock)
	if not _require(fly.is_flying(),"Double-jump input deployed Fly"): return false
	var roster_ids: Array[int] = []
	for member: RefCounted in game.party.members(): roster_ids.append(member.get_instance_id())
	if not _require(roster_ids == initial_party_ids and fly.last_flight_used_mentor_loaner(),"Maela loaner carries the unchanged five-non-Fly team without a sixth slot"): return false
	_log("flight_launch", {"carrier":fly.eligible_creature().species_id,"loaner":true,"stamina":player.vitals.stamina,"party_size":roster_ids.size()})
	return true


func _return_to_aerie() -> bool:
	if not await _deploy(): return false
	# Deployment begins only ~2m above the platform. Gain clearance in the real
	# shrine updraft before descending away, or the capsule simply lands again.
	for target: Vector3 in [Vector3(1020,1075,3000),Vector3(850,975,3020),Vector3(620,800,3150),Vector3(405,630,3250)]:
		if not await _fly_to(target): return false
	return await _land(Vector3(400,610,3250))


func _fly_to(target: Vector3, radius: float = 5.0, expected_landing: Vector3 = Vector3.INF) -> bool:
	for frame in 10800:
		var offset:=target-player.global_position
		if offset.length()<radius:
			_release()
			_log("flight_waypoint", {"target":str(target),"state":fly.state,"flight_seconds":fly.flight_seconds,"stamina":player.vitals.stamina})
			return true
		if not fly.is_flying():
			if expected_landing != Vector3.INF:
				return await _verify_landing(expected_landing)
			return _fail("Flight ended before "+str(target))
		var horizontal:=Vector2(offset.x,offset.z).length()
		_steer(offset,clampf(horizontal/12,0,1))
		_input("jump",1 if offset.y>2 else 0)
		_input("fly_descend",1 if offset.y < -8 else 0)
		await _frames(1)
		if failed:return false
	return _fail("Flight timeout toward "+str(target))


func _land(at: Vector3) -> bool:
	if not fly.is_flying(): return await _verify_landing(at)
	# Ring 3 is roughly 44m from the perch but only 14m above it. Starting an
	# 8m/s descent there reaches the cliff skirt before the landing surface.
	# Fly horizontally over the intended landing first, using the same input
	# controller and authored lift; this is no ground/position/recovery seam.
	if Vector2(at.x-player.global_position.x,at.z-player.global_position.z).length() > 8.0:
		var approach := Vector3(at.x,maxf(at.y+12.0,player.global_position.y),at.z)
		if not await _fly_to(approach,3.0): return false
	for frame in 2400:
		if not fly.is_flying():
			return await _verify_landing(at)
		_steer(at-player.global_position,clampf(Vector2(at.x-player.global_position.x,at.z-player.global_position.z).length()/8,0,1))
		_input("jump",0); _input("fly_descend",1)
		await _frames(1)
		if failed:return false
	return _fail("Landing timed out "+str(at))


func _verify_landing(at: Vector3) -> bool:
	_release()
	await _frames(12)
	var query := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,player.global_position-Vector3.UP*4,1)
	query.exclude = [player.get_rid()]
	var floor_hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	_log("landing_floor", {"target":str(at),"on_floor":player.is_on_floor(),"state":fly.state,"floor_path":str(floor_hit.collider.get_path()) if not floor_hit.is_empty() else "none","floor_position":str(floor_hit.get("position",Vector3.INF)),"shrine_reached":_has("sky_shrine_reached")})
	return _require(player.is_on_floor() and not floor_hit.is_empty() and player.global_position.distance_to(at)<14,"Collision landing at "+str(at))


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


func _purpose(purpose: String, choice: String) -> void:
	_log("player_purpose", {"purpose":purpose,"choice":choice})


func _log(kind: String, details: Dictionary = {}) -> void:
	var row: Dictionary={"kind":kind,"stage":stage,"simulated_seconds":snappedf(simulated_seconds,0.01),"wall_seconds":(Time.get_ticks_usec()-start_usec)/1000000.0,"position":str(player.global_position) if is_instance_valid(player) else "boot"}
	row.merge(details)
	rows.append(row)
	if kind in ["meaningful_offer","input_interact","physical_interaction","battle_started","battle_victory","trial_gate","optional_gather","resource_delta","flight_launch","flight_waypoint"]:
		if not previous_activity.is_empty():
			activity_intervals.append({"from":previous_activity.kind,"to":kind,"from_stage":previous_activity.stage,"to_stage":stage,"start_seconds":previous_activity.simulated_seconds,"end_seconds":snappedf(simulated_seconds,0.01),"gap_seconds":snappedf(simulated_seconds-float(previous_activity.simulated_seconds),0.01)})
		previous_activity = row
		last_activity=simulated_seconds
	print("CLOUDREACH CONTINUOUS "+JSON.stringify(row))
	_write_report()


func _write_report() -> void:
	var file:=FileAccess.open(output_dir+"/events.json",FileAccess.WRITE)
	var route_complete := not failed and stage=="complete"
	file.store_string(JSON.stringify({"passed":route_complete and live_combat,
		"mechanics_route_completed":route_complete,"evidence_scope":"live_combat_acceptance" if live_combat else "mechanics_only_test_lethal",
		"combat_mode":"live_input_spacer_switch" if live_combat else "test_only_lethal",
		"stage":stage,"distance_m":distance_m,"longest_dead_travel_seconds":longest_dead_travel,
		"accelerated":accelerated,"activity_intervals":activity_intervals,"recovery_choices":recovery_choices,"events":rows},"  "))


func _capture(label: String) -> void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	checkpoint+=1
	root.get_texture().get_image().save_png(output_dir+"/%02d-%s.png"%[checkpoint,label])
	_log("capture",{"label":label,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"fps":Performance.get_monitor(Performance.TIME_FPS),"performance_valid":not accelerated})


func _finish() -> void:
	_release()
	if not completed_route and not failed:
		_fail("Harness returned before reaching the final persistence/non-entry assertions")
	if completed_route and not failed:stage="complete"
	_write_report()
	var verdict := "FAIL" if failed else ("PASS" if live_combat else "MECHANICS-ONLY PASS")
	print("CLOUDREACH CONTINUOUS %s stage=%s distance_m=%.1f dead_travel_max_s=%.1f"%[verdict,stage,distance_m,longest_dead_travel])
	quit(1 if failed else 0)
