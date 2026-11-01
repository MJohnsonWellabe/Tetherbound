extends SceneTree

const TRAINING_HANDOFF := preload("res://tools/earned_saves/training_handoff.gd")
const LINEAGE := preload("res://tools/earned_saves/checkpoint_lineage.gd")

## F19#5 Cloudreach pieces: the earned Cloudreach chapter cut at its segment
## boundaries, one ordinary-input segment per process, in the new chapter order
## (Meadows -> Tidewake -> Cloudreach -> Stormwood -> Home Key).
##
## WHAT IT IS
##   The earned_chain_runner.gd piece protocol applied to Cloudreach: a fresh
##   process loads the previous checkpoint through the production title
##   (controller focus -> Load Game -> Autosave), runs one piece of the existing
##   earned helper read-only, and on success writes slot 0 through
##   Game.save_game(). No teleport, flag/inventory/party write, HP pin or debug
##   skip occurs. Each piece body is the corresponding slice of
##   tests/helpers/cloudreach_live_segment.gd `_run_route()`, verbatim, run on
##   the F49 portal-arrival helper (tests/helpers/f49_cloudreach_chapter.gd);
##   piece 07 plays the F49 portal leg (tests/helpers/f49_portal_travel.gd).
##
## SEGMENTS (in order)
##   01_arrival_gate        arrival road, ruin, gathers, Aila, lower-cliffs candy
##   02_broken_causeways    lower anchors, Senn, causeway survivors reconnected
##   03_flight_training     Gale Fiber, Maela trial, aerie, rest, Fly ring trial
##   04_high_roost          Fly to the High Roost shrine, vanes, Sora, windlass,
##                          controlled return flight to the aerie
##   05_stronghold          counterweight route, upper anchors, Voss, summit
##                          feed, summit bivouac rest, extraction threshold
##   06_veyra_relay         Captain Veyra, creature relay phase, overlook, reward
##   07_stormward_handoff   new-order handoff: Home Key, hang the Cloudreach relic,
##                          Stormwood arch (the physical Stormward gate is retired)
##   05b_summit_tail        re-proof piece only (not in run_cloudreach_chain.sh):
##                          05's tail from a generated summit-bivouac boundary,
##                          the bivouac rest and the walk to the summit threshold
##
## USAGE
##   godot --headless --path . --script tools/earned_saves/cloudreach_chain_runner.gd -- \
##     --segment=<id> --from=<previous checkpoint dir> --out=<absent checkpoint dir> [--accelerated]
##   <from>/save holds the previous slot 0; <from>/receipt.json (when present) is
##   the previous piece's after-state, compared against the loaded state.
##   --accelerated is the existing continuous-smoke clock (time_scale 8 at
##   480 Hz physics, 1/60 s per tick); input taps drop to 1x as in the helper.
## OUTPUT
##   <out>/save/, <out>/receipt.json and `CLOUDREACH PIECE RESULT {...}`; exit 0 on pass.
const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const CHAPTER := preload("res://tests/helpers/f49_cloudreach_chapter.gd")
const PORTAL := preload("res://tests/helpers/f49_portal_travel.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const SEGMENTS := ["01_arrival_gate", "02_broken_causeways", "03_flight_training", "04_high_roost",
	"05_stronghold", "05b_summit_tail", "06_veyra_relay", "07_stormward_handoff", "06k_return_cliffhold", "06l_return_aerie", "06m_aster_duel", "06n_aster_departure",
	"06m_aster_duel_only", "06o_aster_storage_departure", "06p_aster_chest"]
const SLOT := 0
const LOAD_SETTLE_FRAMES := 300

## The helper's own route, sliced at the piece boundary. Everything else
## (pilot, guards, observers, movement) is the unchanged parent.
class Piece extends "res://tests/helpers/f49_cloudreach_chapter.gd":
	var piece := ""
	## Each piece's terminal results. A script error aborts the coroutine without
	## setting `failed`, so completion is proven by these flags, never assumed.
	const PIECE_RESULTS := {
		"01_arrival_gate": ["cloudreach_crisis_learned"],
		"02_broken_causeways": ["cloudreach_lower_anchors_investigated", "causeway_survivors_reconnected"],
		"03_flight_training": ["windscar_aerie_prepared", "cloudreach_act_i_complete", "fly_traversal_unlocked"],
		"04_high_roost": ["sky_shrine_reached", "storm_anchor_engine_truth_learned", "cloudreach_upper_route_unlocked"],
		"05_stronghold": ["cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled", "summit_extraction_engine_reached"],
		"05b_summit_tail": ["summit_extraction_engine_reached"],
		"06_veyra_relay": ["captain_veyra_defeated", "storm_anchor_network_disabled", "cloudreach_chapter_complete"],
		"07_stormward_handoff": ["cloudreach_chapter_complete", "realm_key_stormwood"],
		"06k_return_cliffhold": ["cloudreach_chapter_complete"],
		"06l_return_aerie": ["cloudreach_chapter_complete"],
		"06m_aster_duel": ["cloudreach_chapter_complete"],
		"06n_aster_departure": ["cloudreach_chapter_complete"],
		"06m_aster_duel_only": ["cloudreach_chapter_complete"],
		"06o_aster_storage_departure": ["cloudreach_chapter_complete"],
		"06p_aster_chest": ["cloudreach_chapter_complete"],
	}
	var body_finished := false

	func _run_route() -> void:
		match piece:
			"01_arrival_gate": await _arrival_gate()
			"02_broken_causeways": await _broken_causeways()
			"03_flight_training": await _flight_training()
			"04_high_roost": await _high_roost()
			"05_stronghold": await _stronghold()
			"05b_summit_tail": await _summit_tail()
			"06_veyra_relay": await _veyra_relay()
			"07_stormward_handoff": _chapter_earned()
			# Via the summit road's plateau fork: the observatory_summit_link
			# climbs into the Old Wind Observatory's LandmarkLedge rim (a 49 deg
			# face, contact normal y 0.66, at (432.5,919.2,4519.7)) and stalls.
			"06k_return_cliffhold": await _aster_approach(Vector3(-340,830,3970), [Vector3(-180,900,4720)])
			"06l_return_aerie": await _aster_approach(Vector3(400,610,3250))
			"06m_aster_duel": await _aster_duel()
			"06m_aster_duel_only": await _aster_duel(false)
			"06p_aster_chest": await _aster_chest()
			"06n_aster_departure": await _aster_departure()
			"06o_aster_storage_departure": await _aster_departure(false)
		if failed or not body_finished:
			_fail("Piece body did not reach its end (stage %s)" % stage)
			return
		for flag: String in PIECE_RESULTS[piece]:
			if not _require(_has(flag), "Piece result " + flag): return
		if piece == "04_high_roost" and not _require(not fly.is_flying() and player.is_on_floor(), "Landed at the aerie"): return
		completed_route = true

	## The established witness recovery (tests/helpers/cloudreach_witness_route.gd
	## `_walk_with_static_sidestep`): a stick walk that stops dead (velocity 0)
	## against STATIC geometry only - the cliff-shoulder ridge colliders, e.g.
	## WindscarCounterweightPassCliffShoulders/Ridge003 - withdraws that stall,
	## pulls the stick back and to the side, and retries the same walk, at most
	## twice per walk. Every use is logged and disclosed; mobile/no-contact
	## stalls keep the base failure. The underlying collider stall stays an open gap.
	const STATIC_SIDESTEP_ATTEMPTS := 2
	var static_sidesteps: Array[Dictionary] = []

	func _walk(target: Vector3, radius: float = 0.75, body: CharacterBody3D = null) -> bool:
		for attempt in STATIC_SIDESTEP_ATTEMPTS + 1:
			var rows_before := rows.size()
			var ok: bool = await super._walk(target, radius, body)
			if ok or attempt == STATIC_SIDESTEP_ATTEMPTS or rows.size() <= rows_before:
				return ok
			var fail_row: Dictionary = rows[rows.size() - 1]
			if str(fail_row.get("kind", "")) != "FAIL" or not str(fail_row.get("message", "")).begins_with("Walking stalled"):
				return false
			var block: Dictionary = {}
			for index in range(rows.size() - 1, rows_before - 1, -1):
				if str(rows[index].get("kind", "")) == "collision_block":
					block = rows[index]
					break
			var collisions: Array = block.get("collisions", [])
			if collisions.is_empty() or collisions.any(func(c: Dictionary) -> bool:
					var node := _tree.root.get_node_or_null(NodePath(str(c.get("body", ""))))
					return node == null or node is CharacterBody3D):
				return false
			# Withdraw the stall just reported.
			failed = false
			failures.remove_at(failures.size() - 1)
			rows.remove_at(rows.size() - 1)
			var mover: Node3D = body if body != null else player
			var ahead := target - mover.global_position
			ahead.y = 0.0
			ahead = ahead.normalized() if ahead.length() > 0.01 else Vector3.FORWARD
			var side := ahead.cross(Vector3.UP) * (1.0 if attempt == 0 else -1.0)
			var record := {"at": str(mover.global_position), "target": str(target), "attempt": attempt + 1,
				"blocker": str(collisions[0].get("body", "")), "normal": str(collisions[0].get("normal", ""))}
			static_sidesteps.append(record)
			_log("witness_static_stall_sidestep", record)
			var previous_clock := await _normal_input_clock("static stall sidestep")
			for vector: Vector3 in [-ahead * 3.0, side * 3.0]:
				for frame in 45:
					_steer(vector, 1.0)
					await _frames(1)
			_release()
			await _frames(10)
			await _restore_route_clock(previous_clock)
		return false

	## The helper's _arrival_gather, except the prompt is re-read from the same
	## resource after the walk: cloudreach_resource_patch.gd rebuilds its
	## DailyHarvest child on every Game.day roll, and the helper's pre-walk
	## reference is then freed (SCRIPT ERROR in _interact). Same input, same checks.
	func _arrival_gather(id: String, item: String) -> bool:
		var resource: Node3D = world.get_node("CloudreachResources/" + id)
		var prompt: Node3D = resource.find_child("Interactable",true,false)
		if prompt == null: return _fail("Missing arrival resource " + id)
		var day_before := int(game.day)
		if not await _walk(prompt.global_position + Vector3(0,-0.8,-1.5),0.35): return false
		prompt = resource.find_child("Interactable",true,false)
		if int(game.day) != day_before:
			_log("resource_prompt_rebuilt", {"id":id,"day_before":day_before,"day_after":int(game.day),"prompt":str(prompt.get_path()) if prompt != null else ""})
		if prompt == null: return _fail("Arrival resource offers no prompt after the day roll " + id)
		var before: int = game.inventory.count(item)
		if str(game.items.gathered_with(item)) == "knife" and str(game.equipped_tool) != "knife":
			var knife_slot: int = game.call("hotbar_slot_of", "knife")
			if knife_slot < 0: return _fail("Earned knife is not assigned to a hotbar slot")
			await _tap("hotbar_%d" % (knife_slot + 1))
			if not _require(str(game.equipped_tool)=="knife","Real hotbar input equipped gathering knife"): return false
		if not await _interact(prompt,"",false): return false
		await _frames(100)
		_log("optional_gather", {"id":id,"item":item,"gained":game.inventory.count(item)-before})
		return _require(game.inventory.count(item)>before,"Optional arrival gather produced " + item)

	## An earned Tidewake Satchel arrives nearly full (F49#0 routes, 1 Nov: 23/24
	## from f49_tw_09; gale_fiber paid nothing). Before a gather that needs a new
	## stack the player makes room through the ordinary Satchel: leftover Tidewake
	## driftwood is dropped (approved Satchel Drop, meadows_earned_team_segment),
	## then carried cloudberries are fed to the hungriest companion (nothing lost,
	## as stormwood_crown_build_segment does with berries); only a stack that
	## still will not go is dropped. Every step is logged and disclosed.
	func _make_arrival_room(item: String) -> bool:
		var inventory: RefCounted = game.inventory
		var maximum := int(game.items.stack_size(item))
		for i in int(inventory.slot_count()):
			var stack: Dictionary = inventory.stack_at(i)
			if str(stack.get("id", "")) == item and int(stack.get("n", 0)) < maximum: return true
			if stack.is_empty(): return true
		var room: RefCounted = load("res://tests/helpers/meadows_earned_team_segment.gd").new()
		room._tree = _tree
		room._world = world
		room._game = game
		room._menu = game.call("menu")
		if int(inventory.count("driftwood")) > 0:
			if not await room._drop_slot(int(inventory.find_slot("driftwood"))):
				return _fail("Satchel Drop of leftover driftwood failed: " + str(room.result().failures))
			_log("satchel_room", {"dropped": "driftwood", "for": item})
			return true
		for _bite in 12:
			if int(inventory.count("cloudberry")) <= 0: break
			var party: RefCounted = game.party
			var hungriest := 0
			for index in int(party.size()):
				if float(party.at(index).get("nourishment")) < float(party.at(hungriest).get("nourishment")): hungriest = index
			var care: Dictionary = await load("res://tests/helpers/meadows_earned_team_segment.gd").new().care_existing(_tree, world, game, "cloudberry", hungriest)
			if not bool(care.get("passed", false)): break
			_log("satchel_room", {"fed": "cloudberry", "party_index": hungriest, "for": item})
		if int(inventory.count("cloudberry")) > 0:
			if not await room._drop_slot(int(inventory.find_slot("cloudberry"))):
				return _fail("Satchel Drop of carried cloudberry failed: " + str(room.result().failures))
			_log("satchel_room", {"dropped": "cloudberry", "for": item})
		for i in int(inventory.slot_count()):
			if (inventory.stack_at(i) as Dictionary).is_empty(): return true
		return _fail("Satchel still has no room for " + item)

	func _arrival_gate() -> void:
		_purpose("Orient in Cloudreach and learn why the routes are broken", "Take the authored arrival road, inspect its landmark, and gather useful preparation instead of beelining")
		stage = "arrival_to_aila"
		var arrival := _route("arrival_gate_road")
		var ruin: Node3D = world.find_child("InspectArrivalRuin",true,false)
		if not await _walk(ruin.global_position + Vector3(0,-1,-2)): return
		if not await _interact(ruin,"",false): return
		if not await _walk(_vec(arrival.polyline[1])): return
		if not await _make_arrival_room("cloudberry"): return
		if not await _arrival_gather("cr_node_cloudberry_waycamp", "cloudberry"): return
		if not await _walk(_vec(arrival.polyline[2])): return
		if not await _make_arrival_room("gale_fiber"): return
		if not await _arrival_gather("cr_node_gale_fiber_gate", "gale_fiber"): return
		if not await _walk(_vec(arrival.polyline[3])): return
		if not await _walk(Vector3(-280,180,508)): return
		if not await _talk("warden_aila", "cloudreach_crisis_learned"): return
		if not await _pickup("cr_pickup_lower_good_candy"): return
		body_finished = true

	func _broken_causeways() -> void:
		stage = "lower_west_anchor"
		_purpose("Map the lower storm anchors and reconnect the stranded causeway", "Use the grounded bridge network and accept required encounters; optional trainers remain optional")
		if not await _navigate(chapter.get_node("lower_west").global_position): return
		if not await _interact(chapter.get_node("lower_west/Interactable"), "storm_anchor_lower_west_mapped"): return
		stage = "lower_east_anchor"
		var causeway_fiber: Node3D = world.get_node("CloudreachResources/cr_node_gale_fiber_causeway")
		if not await _navigate(causeway_fiber.global_position): return
		if not await _arrival_gather("cr_node_gale_fiber_causeway", "gale_fiber"): return
		if not await _navigate(chapter.get_node("lower_east").global_position): return
		if not await _interact(chapter.get_node("lower_east/Interactable"), "cloudreach_lower_anchors_investigated"): return
		if not await _battle("tether_lieutenant_senn"): return
		if not await _physical_action("causeway_signal", "causeway_survivors_reconnected"): return
		body_finished = true

	func _flight_training() -> void:
		stage = "gale_fiber_preparation"
		if game.inventory.count("gale_fiber") < 3:
			var fiber: Node3D = world.get_node("CloudreachResources/cr_node_gale_fiber_bridge")
			if not await _navigate(fiber.global_position): return
			var resource_prompt: Node3D = fiber.find_child("Interactable", true, false)
			var fiber_before: int = game.inventory.count("gale_fiber")
			if resource_prompt == null or not await _interact(resource_prompt): return
			await _frames(100)
			_log("resource_delta", {"id":"cr_node_gale_fiber_bridge","item":"gale_fiber","gained":game.inventory.count("gale_fiber")-fiber_before})
		else:
			_log("preparation_ready", {"gale_fiber":game.inventory.count("gale_fiber"),"source":"Previously gathered through actual arrival input"})
		if not _require(game.inventory.count("gale_fiber") >= 3, "Gathered 3 Gale Fiber"): return
		if not await _battle("keeper_maela_trial"): return
		if not await _physical_action("aerie_repair", "windscar_aerie_prepared"): return
		if not await _talk("keeper_maela", "cloudreach_act_i_complete"): return
		if not await _rest("windscar_flight_aerie_camp"): return
		_purpose("Repair the aerie and earn Fly without displacing the permanent five", "Use the eligible carried creature or Maela's temporary carrier for the marked ring trial")
		if not await _trial(): return
		body_finished = true

	func _high_roost() -> void:
		stage = "mandatory_high_roost_flight"
		if not await _deploy(): return
		for target: Vector3 in [Vector3(535,760,3170), Vector3(750,935,3030), Vector3(1020,1075,2960)]:
			if not await _fly_to(target): return
		if not await _fly_to(Vector3(1110,1053,2940),5.0,Vector3(1110,1050,2940)): return
		if not await _land(Vector3(1110,1050,2940)): return
		if not _require(_has("sky_shrine_reached"), "Actual Fly-only shrine landing"): return
		for id: String in ["shrine_vane_west", "shrine_vane_east", "shrine_vane_crown"]:
			if not await _physical_action(id, "cloudreach_" + id + "_aligned", false): return
		if not await _talk("naturalist_sora", "storm_anchor_engine_truth_learned", false): return
		if not await _physical_action("shrine_windlass", "cloudreach_upper_route_unlocked", false): return
		stage = "return_glide_to_grounded_counterweight"
		_purpose("Turn the Fly-only shrine discovery into a grounded road for the upper chapter", "Return by controlled flight, then take the newly unlocked counterweight route")
		if not await _return_to_aerie(): return
		body_finished = true

	func _stronghold() -> void:
		stage = "return_glide_to_grounded_counterweight"
		if not await _navigate(Vector3(-720,700,3680)): return
		if not _require(_has("cloudreach_act_ii_complete"), "Grounded counterweight route entered"): return
		if not await _physical_action("upper_anchor_west", "storm_anchor_upper_west_disabled"): return
		if not await _physical_action("upper_anchor_east", "storm_anchor_upper_east_disabled"): return
		if not await _battle("officer_voss_summit_approach"): return
		if not await _physical_action("summit_feed", "cloudreach_upper_anchors_disabled"): return
		_purpose("Prepare the injured team at the last safe bivouac before the captain", "Use authored creature-bed assignment and trainer sleep; spend no direct healing seam")
		if not await _rest("summit_bivouac"): return
		if not await _leave_summit_bivouac(): return
		if not _require(_has("summit_extraction_engine_reached"), "Real summit threshold"): return
		body_finished = true

	## The tail of _stronghold, verbatim, after summit_feed.
	func _summit_tail() -> void:
		stage = "summit_tail"
		if not _require(_has("cloudreach_upper_anchors_disabled") and not _has("summit_extraction_engine_reached"),
				"Summit boundary before the threshold"): return
		_purpose("Prepare the injured team at the last safe bivouac before the captain", "Use authored creature-bed assignment and trainer sleep; spend no direct healing seam")
		if not await _rest("summit_bivouac"): return
		if not await _leave_summit_bivouac(): return
		if not _require(_has("summit_extraction_engine_reached"), "Real summit threshold"): return
		body_finished = true

	func _veyra_relay() -> void:
		stage = "captain_veyra"
		if not await _battle("captain_veyra_storm_anchor"): return
		stage = "creature_relay_phase"
		_purpose("Finish the storm-anchor crisis as a creature, not the human", "Pilot the deployed creature inward to all three relays after the captain battle")
		if not _require(runtime.creature_piloted(),"Captain victory handed control to the deployed creature"): return
		for relay: Dictionary in runtime.finale.config.relays:
			var prompt: Node3D = runtime.finale.get_node("Relay_" + str(relay.id))
			var inward := -Vector3(relay.offset[0],0,relay.offset[2]).normalized()
			if not await _walk(prompt.global_position + Vector3(0,-0.8,0) + inward*2.0, 0.6, runtime.controlled_body()): return
			if not await _interact(prompt, relay.flag_id, false): return
		if not _require(_has("storm_anchor_network_disabled"), "Three deployed-creature relay actions"): return
		stage = "aftermath_overlook"
		_purpose("Witness Cloudreach respond and claim the chapter reward", "Visit the Waterward overlook while preserving the future realm as visible but non-enterable")
		var finale_origin:=_vec(runtime.finale.config.get("arena_origin",[100.0,1160.0,5450.0]))
		for exit_point: Vector3 in [finale_origin-Vector3(0.0,0.0,30.0), finale_origin-Vector3(0.0,0.0,50.0), Vector3(100.0,1160.0,5350.0)]:
			if not await _walk(exit_point): return
		if not await _navigate(Vector3(-420,1110,5650)): return
		await _frames(30)
		if not _require(_has("cloudreach_winds_restored"), "Witness restored winds at overlook"): return
		var reward_coins_before: int = game.inventory.count("coin")
		if not await _talk("warden_aila", "cloudreach_chapter_complete", false): return
		_log("chapter_reward_delta", {"coins_before":reward_coins_before,"coins_after":game.inventory.count("coin"),"inventory":_inventory_snapshot(),"team":_team_snapshot()})
		for flag: String in ["realm_heart_cloudreach_earned", "realm_key_stormwood", "stormward_route_revealed", "captain_veyra_defeated", "cloudreach_chapter_complete"]:
			if not _require(_has(flag), "Earned chapter result " + flag): return
		stage = "complete"
		body_finished = true

	## Short saved ground-return pieces avoid the over-budget summit glide.
	const ASTER := "master_t4"
	func _aster_approach(target: Vector3, via: Array = []) -> void:
		stage = "aster_ground_approach"
		for point: Vector3 in via:
			_log("aster_approach_via", {"via": str(point), "reason": "observatory_link_ledge_rim_stall"})
			if not await _navigate(point): return
		if not await _navigate(target): return
		if not _require(player.is_on_floor() and not fly.is_flying(), "Grounded Master approach checkpoint"): return
		stage = "complete"
		body_finished = true

	func _aster_chest() -> void:
		if not _require((game.local.redesign_character.get("master_wins", []) as Array).has(ASTER), "Chest piece retains Aster win"): return
		await _aster_duel()

	func _aster_duel(open_chest: bool = true) -> void:
		stage = "aster_visit"
		if director.ally_body() == null: await _tap("creature_recall")
		var clock := await _normal_input_clock("Master travel, duel and chest through production input")
		var visit: RefCounted = load("res://tools/earned_saves/master_visit.gd").new()
		var outcome: Dictionary = await visit.run(_tree, world, game, {
			"master_id": ASTER,
			"travel": func(site: Node3D) -> bool:
				if player.is_on_floor() and not fly.is_flying() and player.global_position.distance_to(site.global_position) < 30.0: return true
				return await _aster_travel(site),
			"interact": func(prompt: Node3D) -> bool: return await _interact(prompt),
			"tap": func(action: String) -> void: await _tap(action),
			"fight_round": func() -> Dictionary: return await combat_pilot.fight_to_the_end(),
			"chest": open_chest,
		})
		await _restore_route_clock(clock)
		_log("aster_visit", {"chest_requested": open_chest, "result": outcome})
		if not _require(bool(outcome.get("passed", false)), "Aster visit (chest=%s): %s" % [open_chest, str(outcome.get("failures", []))]): return
		stage = "complete"
		body_finished = true

	func _aster_departure(require_recipe: bool = true) -> void:
		stage = "aster_departure"
		if not _require((game.local.redesign_character.get("master_wins", []) as Array).has(ASTER), "Departure retains Aster win"): return
		if require_recipe and not _require((game.local.redesign_character.get("feast_recipes", []) as Array).has("feast_t4"), "Departure retains learned recipe"): return
		var at_perch := false
		for site: Node in _tree.get_nodes_in_group(&"foundation_master_sites"):
			if site is Node3D and site.get("master_id") == ASTER and site.get("_mounted") == true and world.is_ancestor_of(site):
				at_perch = player.global_position.distance_to((site as Node3D).global_position) < 30.0
				break
		if not _require(at_perch and player.is_on_floor() and not fly.is_flying(), "Departure starts at the saved grounded Aster perch"): return
		_log("aster_departure", {"recipe_required": require_recipe, "position": str(player.global_position)})
		if not await _return_to_aerie(): return
		if not _require(player.is_on_floor() and not fly.is_flying(), "Master return landed at the aerie"): return
		stage = "complete"
		body_finished = true

	func _aster_travel(site: Node3D) -> bool:
		_purpose("Raise the team's cap with the Cloudreach Master", "Fly the authored lifts to Aster Windward's perch")
		var pad := site.global_position
		_log("aster_site", {"pad": str(pad), "player": str(player.global_position), "stamina": player.vitals.stamina})
		var legs: Array = [
			{"name": "aerie_lifts", "points": [Vector3(535,760,3170),Vector3(750,935,3030),Vector3(1020,1075,2960)]},
			{"name": "perches", "points": [Vector3(pad.x - 30, pad.y + 25, pad.z + 20)], "land": pad + Vector3(0,0,6)},
		]
		for leg: Dictionary in legs:
			stage = "aster_flight_" + str(leg.name)
			if not fly.is_flying():
				for _wait in 600:
					if player.vitals.stamina >= player.vitals.max_stamina - 0.5: break
					await _frames(1)
				if not await _deploy(): return false
			for point: Vector3 in leg.points:
				if not await _fly_to(point, 6.0):
					_log("aster_flight_short", {"leg": leg.name, "target": str(point), "player": str(player.global_position), "stamina": player.vitals.stamina})
					return false
			_log("aster_leg", {"leg": leg.name, "player": str(player.global_position), "stamina": player.vitals.stamina, "seconds": fly.flight_seconds})
			if leg.has("land") and not await _land_on_perch(leg.land): return false
		return true

	## The perch leg arrives with stamina nearly spent; Fly can end during
	## `_land`'s horizontal hop to its hover point, after the body has already
	## dropped onto the pad. Make that hop with `_fly_to`'s own expected landing,
	## so an ended flight is judged by `_verify_landing` (on the floor, floor
	## ray hit, within 14 m) instead of failing.
	func _land_on_perch(at: Vector3) -> bool:
		if fly.is_flying() and Vector2(at.x-player.global_position.x,at.z-player.global_position.z).length() > 8.0:
			if not await _fly_to(Vector3(at.x,maxf(at.y+12.0,player.global_position.y),at.z),3.0,at): return false
			if not fly.is_flying():
				_log("aster_perch_landing", {"ended_flight_landing": str(player.global_position), "stamina": player.vitals.stamina})
				return true
		return await _land(at)

	## Piece 07 starts from the saved, completed chapter. The Stormward helper
	## requires the route's completion marker; it is set only when the loaded
	## save carries every earned chapter result the helper's final check names.
	func _chapter_earned() -> void:
		for flag: String in ["realm_heart_cloudreach_earned", "realm_key_stormwood", "stormward_route_revealed", "captain_veyra_defeated", "cloudreach_chapter_complete"]:
			if not _require(_has(flag), "Loaded save carries earned chapter result " + flag): return
		body_finished = true
		stage = "complete"


var segment := ""
var from_dir := ""
var out_dir := ""
var accelerated := false
var failures: Array[String] = []
var disclosures: Array[String] = []
var started_ms := 0
var game: Node
var before := {}
var previous_after := {}
var handoff := {}
var helper_summary := {}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--segment="): segment = arg.trim_prefix("--segment=")
		elif arg.begins_with("--from="): from_dir = arg.trim_prefix("--from=")
		elif arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
		elif arg == "--accelerated": accelerated = true
		elif arg.begins_with("--release-route="): pass # The exported binary's packaged-route entry (ACCEPTANCE §7 replays).
		else: failures.append("Unknown Cloudreach piece option: " + arg)
	from_dir = ProjectSettings.globalize_path(from_dir).simplify_path().trim_suffix("/")
	out_dir = ProjectSettings.globalize_path(out_dir).simplify_path().trim_suffix("/")
	game = root.get_node("Game")
	if not SEGMENTS.has(segment) or from_dir.is_empty() or out_dir.is_empty():
		failures.append("usage: --segment=<%s> --from=<dir> --out=<absent dir>" % "|".join(SEGMENTS))
	elif not DirAccess.dir_exists_absolute(from_dir.path_join("save")):
		failures.append("Previous checkpoint has no save/: " + from_dir)
	elif DirAccess.dir_exists_absolute(out_dir) or FileAccess.file_exists(out_dir) \
			or DirAccess.dir_exists_absolute(out_dir + "_working"):
		failures.append("Piece output and its scratch must be absent; refusing overwrite")
	if not failures.is_empty():
		_finish(false)
		return
	if FileAccess.file_exists(from_dir.path_join("receipt.json")):
		var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(from_dir.path_join("receipt.json")))
		if not prior is Dictionary or not bool(prior.get("passed", false)) or not prior.get("after") is Dictionary:
			failures.append("Previous checkpoint receipt is malformed or not a PASS")
			_finish(false)
			return
		previous_after = prior.after
	var working := out_dir + "_working"
	if not CHECKPOINTS.copy_tree(from_dir.path_join("save"), working):
		failures.append("Could not copy the previous save to scratch")
		_finish(false)
		return
	if accelerated:
		Engine.time_scale = 8.0
		Engine.physics_ticks_per_second = 480
		Engine.max_physics_steps_per_frame = 32
		disclosures.append("Accelerated clock (existing continuous-smoke mode): time_scale 8 with 480 Hz physics, still 1/60 s per tick; helper input taps drop to 1x")
	game.set("save_system", SAVE.new(working))
	print("CLOUDREACH PIECE segment=%s from=%s out=%s" % [segment, from_dir, out_dir])
	if not await _load_previous():
		_finish(false)
		return
	before = _state()
	_handoff_check()
	if not failures.is_empty():
		_finish(false)
		return
	disclosures.append("Runner Piece overrides the helper's _arrival_gather only to re-read the resource prompt after the walk (cloudreach_resource_patch.gd rebuilds DailyHarvest on each Game.day roll; the helper's pre-walk reference was freed). Input and checks unchanged.")
	var helper := Piece.new()
	helper.piece = segment
	var result: Dictionary = await helper.run(self, current_scene as Node3D, game)
	helper_summary = {"ok": bool(result.get("ok", false)), "stage": str(result.get("stage", "")),
		"distance_m": snappedf(float(result.get("distance_m", 0.0)), 0.1),
		"simulated_seconds": snappedf(helper.simulated_seconds, 0.01),
		"battle_starts": helper.battle_starts, "battle_wins": helper.battle_wins,
		"battle_losses": helper.battle_losses, "recovery_choices": helper.recovery_choices,
		"events": (result.get("events", []) as Array).size(), "static_sidesteps": helper.static_sidesteps}
	for record: Dictionary in helper.static_sidesteps:
		disclosures.append("Static-collider stall withdrawn and retried after a disclosed stick sidestep (witness-route recovery): " + JSON.stringify(record))
	_trainer_stall_diagnostic(helper)
	for line: Variant in result.get("failures", []):
		failures.append("%s: %s" % [segment, str(line)])
	if failures.is_empty() and not bool(result.get("ok", false)):
		failures.append(segment + ": helper returned ok=false at stage " + str(result.get("stage", "")))
	if failures.is_empty() and segment == "07_stormward_handoff":
		# New order (RD-17/F18#2): the physical Stormward gate is a retired
		# crossing (biome_order.legacy_physical_crossings false) and refuses.
		# The handoff is the F49 portal leg tests/helpers/f49_campaign_journey.gd
		# plays: Home Key -> hang the held Cloudreach relic -> Stormwood arch.
		var travel := PORTAL.new(self, game)
		var ok: bool = await _make_handoff_room("cloudreach", "stormwood_portal_key")
		if ok: ok = await travel.home_key()
		if ok: ok = await travel.hang_relic("cloudreach")
		if ok:
			# A successful hang opens the relic-power choice (crossing_hall.gd
			# "Relic hung. Choose the power you carry."). Dismiss it as a player
			# would, with the ordinary menu_cancel press; no power is chosen.
			for _i in 120:
				if INPUT_OWNER.current(self) != null: break
				await process_frame
			var owner: Node = INPUT_OWNER.current(self)
			if owner != null and str(owner.name) == "RelicPowerPanel":
				await travel.tap("menu_cancel")
				for _i in 30: await process_frame
				disclosures.append("Piece 07: the relic-power choice panel that opens after the Cloudreach relic is hung was dismissed with the ordinary menu_cancel press; no power was chosen")
		if ok: ok = await _stormwood_deposit()
		if ok: ok = await travel.enter("stormwood", "stormwood")
		helper_summary["portal_leg"] = {"ok": ok, "failures": travel.failures.duplicate()}
		for line: Variant in travel.failures:
			failures.append("portal: " + str(line))
		if failures.is_empty() and not ok:
			failures.append("portal: Home Key -> Stormwood leg returned false")
		if failures.is_empty():
			for _i in LOAD_SETTLE_FRAMES: await physics_frame
	if failures.is_empty():
		_release_inputs()
		for _i in 30: await physics_frame
		if INPUT_OWNER.current(self) != null:
			failures.append("Piece ended without ordinary world input; refusing to save mid-modal")
	if failures.is_empty() and str(_party_uids()) != str(before.uids):
		failures.append("Piece changed the ordered five creature UIDs")
	_finish(failures.is_empty())


## Read-only: a trainer battle still open after the piece names the gate
## holding its outcome (no call that journals, retries or resolves anything).
func _trainer_stall_diagnostic(helper: RefCounted) -> void:
	var director: Node = helper.get("director")
	if not is_instance_valid(director) or not bool(director.call("trainer_battle_active")): return
	var manager: Node = helper.get("manager")
	var encounter: Dictionary = director.get("_encounter")
	var id := str(encounter.get("encounter_id", ""))
	var spec: Dictionary = director.get("_trainer_spec")
	var row := {"trainer": str(spec.get("id", "")), "encounter_id": id,
		"boss_pending_win": director.get("_boss_pending_win"), "master_pending_win": director.get("_master_pending_win"),
		"ordinary_round_exit": director.get("_ordinary_combat_round_exit"),
		"trainer_send_delay": director.get("_trainer_send_delay"), "queue": (director.get("_trainer_queue") as Array).size() if director.get("_trainer_queue") is Array else -1,
		"battle_sent": director.get("_trainer_battle_sent"),
		"uses_durable_rewards": director.call("uses_durable_trainer_rewards", id) if not id.is_empty() else null,
		"retained_boss_participants": director.call("retained_boss_participants"),
		"manager_outcome": manager.call("outcome") if is_instance_valid(manager) and manager.has_method("outcome") else null,
		"manager_fighting": manager.call("is_fighting") if is_instance_valid(manager) else null,
		"input_owner": str(INPUT_OWNER.current(self)),
		"is_host": game.session.call("is_host") if game.get("session") != null else null,
		"handoff_enabled": game.session.call("config").get("redesign_boss_handoff_runtime_enabled") if game.get("session") != null else null}
	disclosures.append("Trainer battle still open after the piece (read-only diagnostic): " + JSON.stringify(row))
	print("CLOUDREACH TRAINER STALL " + JSON.stringify(row))


## Production title -> controller focus Load Game -> Autosave (slot 0).
func _load_previous() -> bool:
	if not bool(game.call("has_save", SLOT)):
		failures.append("No slot %d in the copied previous save" % SLOT)
		return false
	if change_scene_to_file(TITLE_SCENE) != OK:
		failures.append("Could not open the production title")
		return false
	for _i in 10: await process_frame
	var title := current_scene
	var travel := PORTAL.new(self, game)
	var load_button := title.get("_load_button") as Button
	for _step in 8:
		if root.gui_get_focus_owner() == load_button: break
		await travel.tap("ui_down")
	if load_button == null or root.gui_get_focus_owner() != load_button:
		failures.append("Title controller focus did not reach Load Game")
		return false
	await travel.tap("ui_accept")
	var first := root.gui_get_focus_owner() as Button
	if first == null or not first.text.begins_with("Autosave —") or first.disabled:
		failures.append("The title Load list did not offer the copied Autosave: " + (first.text if first != null else "<none>"))
		return false
	await travel.tap("ui_accept")
	for _frame in 7200:
		await process_frame
		if current_scene != title and travel._ready_world("cloudreach"):
			for _i in LOAD_SETTLE_FRAMES: await physics_frame
			for _i in 600:
				if INPUT_OWNER.current(self) == null: break
				await process_frame
			if INPUT_OWNER.current(self) != null:
				failures.append("Loaded piece never returned ordinary world input")
				return false
			return true
	failures.append("The production Load did not reach a ready Cloudreach world")
	return false


func _handoff_check() -> void:
	if previous_after.is_empty():
		handoff = {"checked": false, "reason": "no previous piece receipt (start save)"}
		return
	var training := TRAINING_HANDOFF.compare(previous_after, before)
	if not bool(training.checked):
		disclosures.append("Training handoff not proven: " + str(training.reason))
	elif not bool(training.matches):
		failures.append("Training handoff: " + str(training.reason))
	var problems := TRAINING_HANDOFF.compare_route(previous_after, before)
	handoff = {"training": training, "checked": true, "matches": problems.is_empty() and (not bool(training.checked) or bool(training.matches)), "differs": problems}
	if not problems.is_empty():
		failures.append("Handoff: loaded %s differ from the previous piece's saved state" % ", ".join(problems))


func _release_inputs() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back", "jump", "fly_descend", "interact"]:
		Input.action_release(action)


func _party_uids() -> Array:
	var out: Array = []
	for member: RefCounted in game.party.members():
		out.append(str(member.get("uid")))
	return out


func _state() -> Dictionary:
	var party: Array = []
	for member: RefCounted in game.party.members():
		party.append({"uid": str(member.get("uid")), "species": str(member.get("species_id")),
			"level": int(member.get("level")), "xp": int(member.get("xp")),
			"hp": snappedf(float(member.get("hp")), 0.1), "max_hp": int(member.get("max_hp")),
			"fainted": bool(member.get("fainted"))})
	var flags: Array = (game.progression.call("all_set") as Array).duplicate()
	flags.sort()
	var inventory := {}
	for index in int(game.inventory.call("slot_count")):
		var stack: Dictionary = game.inventory.call("stack_at", index)
		if stack.is_empty(): continue
		var id := str(stack.get("id", ""))
		inventory[id] = int(inventory.get(id, 0)) + int(stack.get("n", 0))
	var keys := inventory.keys()
	keys.sort()
	var sorted_inventory := {}
	for id: String in keys: sorted_inventory[id] = inventory[id]
	var player := current_scene.get_node_or_null("Player") as Node3D if current_scene != null else null
	return {"realm": str(game.get("current_realm")), "scene": str(current_scene.name) if current_scene != null else "",
		"position": [snappedf(player.global_position.x, 0.01), snappedf(player.global_position.y, 0.01),
			snappedf(player.global_position.z, 0.01)] if player != null else [],
		"training": TRAINING_HANDOFF.snapshot(game), "uids": _party_uids(), "party": party, "flags": flags, "inventory": sorted_inventory,
		"day": int(game.get("day")), "clock_seconds": snappedf(float(game.get("clock_elapsed_seconds")), 0.01)}


func _finish(passed: bool) -> void:
	var after := _state() if game != null and current_scene != null and game.get("party") != null else {}
	var gained: Array = []
	for flag: Variant in after.get("flags", []):
		if not (before.get("flags", []) as Array).has(flag): gained.append(flag)
	var inventory_delta := {}
	for id: Variant in (after.get("inventory", {}) as Dictionary).keys() + (before.get("inventory", {}) as Dictionary).keys():
		var delta := int(after.get("inventory", {}).get(id, 0)) - int(before.get("inventory", {}).get(id, 0))
		if delta != 0: inventory_delta[id] = delta
	if passed:
		# The game's own save into the piece output; the scratch Load copy is discarded.
		game.set("save_system", SAVE.new(out_dir.path_join("save")))
		if not bool(game.call("save_game", SLOT)):
			failures.append("Game.save_game(%d) refused the piece save" % SLOT)
			passed = false
	var lineage := LINEAGE.from_directory(from_dir)
	var receipt := {"input_mode": LINEAGE.input_mode(lineage), "lineage": lineage,
		"criterion": "F19#5", "chapter": "cloudreach", "segment": segment,
		"commit": CHECKPOINTS.commit_sha(), "from": from_dir, "passed": passed and failures.is_empty(),
		"failures": failures, "accelerated": accelerated,
		"injections": "none: production title Load, unchanged helper movement/combat/interaction by ordinary input, Game.save_game",
		"disclosures": disclosures, "handoff_check": handoff, "helper": helper_summary,
		"wall_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"before": before, "after": after, "flags_gained": gained, "inventory_delta": inventory_delta,
	}
	if not out_dir.is_empty() and not FileAccess.file_exists(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)
		var file := FileAccess.open(out_dir.path_join("receipt.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(receipt, "  "))
			file.close()
	print("CLOUDREACH PIECE RESULT " + JSON.stringify({"segment": segment, "passed": receipt.passed,
		"failures": failures, "flags_gained": gained, "position": after.get("position", []),
		"realm": after.get("realm", ""), "helper": helper_summary}))
	quit(0 if receipt.passed else 1)


## A carried-full Satchel holds the chapter boss's coin payout and hand-off
## (portal key + relic) as boss_handoff_make_satchel_room (Tidewake 09, 1 Nov:
## the first freed slot goes to the coin payout). The player makes two slots
## first: carried cloudberries are fed to the hungriest companion (nothing
## lost), then leftover gathered materials go by the approved Satchel Drop.
## Every step is disclosed; the held duty then delivers.
func _make_handoff_room(biome: String, key_item: String) -> bool:
	var world := current_scene as Node3D
	var inventory: RefCounted = game.get("inventory")
	var delivered := func() -> bool:
		var now: Dictionary = game.local.get("redesign_character")
		return ((now.get("relics_held", []) as Array).has(biome) or (now.get("relics_hung", []) as Array).has(biome)) \
			and int(inventory.call("count", key_item)) > 0
	if delivered.call(): return true
	var team := load("res://tests/helpers/meadows_earned_team_segment.gd")
	var free := func() -> int:
		var n := 0
		for i in int(inventory.call("slot_count")):
			if (inventory.call("stack_at", i) as Dictionary).is_empty(): n += 1
		return n
	for _bite in 12:
		if free.call() >= 2 or int(inventory.call("count", "cloudberry")) <= 0: break
		# Food can only target a standing companion: a fainted row is disabled in
		# the Satchel's care picker (attempt 2 picked fainted row 0 and the refusal
		# left the picker open, so the following Drop could not focus a slot).
		var party: RefCounted = game.get("party")
		var hungriest := -1
		for index in int(party.call("size")):
			var member: RefCounted = party.call("at", index)
			if bool(member.get("fainted")) or float(member.get("hp")) <= 0.0: continue
			if hungriest < 0 or float(member.get("nourishment")) < float(party.call("at", hungriest).get("nourishment")): hungriest = index
		if hungriest < 0: break
		var care: Dictionary = await team.new().care_existing(self, world, game, "cloudberry", hungriest)
		await _release_world_input()
		if not bool(care.get("passed", false)): break
		disclosures.append("Piece 07: fed a carried cloudberry to party row %d through the Satchel to make room for the held %s hand-off" % [hungriest, biome])
	for id: String in ["gale_fiber", "cloudberry", "driftwood", "fiber", "wood", "rootstone", "berries"]:
		while free.call() < 2 and int(inventory.call("count", id)) > 0:
			await _release_world_input()
			var room: RefCounted = team.new()
			room._tree = self
			room._world = world
			room._game = game
			room._menu = game.call("menu")
			var slot := int(inventory.call("find_slot", id))
			var n := int((inventory.call("stack_at", slot) as Dictionary).get("n", 0))
			if not await room._drop_slot(slot):
				failures.append("Piece 07: Satchel Drop of %s failed: %s" % [id, str(room.result().failures)])
				return false
			disclosures.append("Piece 07: DROPPED %s x%d through the Satchel to make room for the held %s hand-off" % [id, n, biome])
	for _frame in 1800:
		if delivered.call(): return true
		await physics_frame
	failures.append("Piece 07: held %s hand-off did not deliver after making Satchel room (free=%d)" % [biome, int(free.call())])
	return false


## Closes whatever menu or picker a care/drop step left open, with ordinary
## menu_cancel presses, and waits until world input is free again.
func _release_world_input() -> void:
	var portal := PORTAL.new(self, game)
	for _press in 6:
		if INPUT_OWNER.current(self) == null: break
		await portal.tap("menu_cancel")
		for _i in 20: await process_frame
	for _i in 30: await process_frame


## Coordinator decision (a), 1 Nov: a four-chapter Satchel reaches Stormwood
## full (arrival_prefix failed twice: Stormglass, then glowmoss). While home
## for the relic, the player stores surplus in the homestead Storage Chest
## through the production panel (homestead_common.storage_trip: builds/funds
## the chest if absent, stores every stack not kept). Kept: tools, Home Key and
## keys (the helper forces those), the large-potion healing stack, revives,
## coin, the worn hide vest and the torch. Nothing is dropped. Disclosed.
const STORMWOOD_KEEP := ["potion_large", "revive", "coin", "hide_vest", "torch"]

func _stormwood_deposit() -> bool:
	var world := current_scene as Node3D
	# Coordinator-approved (b) then (a), 1 Nov: the chest that frees room costs
	# wood x8 + fiber x4 (two new stacks) and the Satchel is full, so first drop
	# the smaller duplicate potion_small and revive stacks (approved Satchel Drop).
	for id: String in ["potion_small", "revive"]:
		if not await _drop_smaller_duplicate(world, id):
			return false
	var result: Dictionary = await load("res://tools/earned_saves/wip_fights/storage_trip.gd").new().run(
		self, world, game, {"keep": STORMWOOD_KEEP, "return": false})
	for row: Variant in result.get("receipts", result.get("transcript", [])):
		if row is Dictionary and str((row as Dictionary).get("beat", "")) == "storage_trip":
			disclosures.append("Piece 07: Storage Chest deposit before Stormwood (stored %s; kept %s; free slots %s)" % [
				str(row.get("stored")), str(row.get("kept")), str(row.get("free_slots"))])
	if not bool(result.get("passed", false)):
		failures.append("Piece 07: Storage Chest deposit failed: " + str(result.get("failures", [])))
		return false
	return true


func _drop_smaller_duplicate(world: Node3D, id: String) -> bool:
	var inventory: RefCounted = game.get("inventory")
	var slots: Array[int] = []
	for i in int(inventory.call("slot_count")):
		if str((inventory.call("stack_at", i) as Dictionary).get("id", "")) == id: slots.append(i)
	if slots.size() < 2:
		return true
	var smallest := slots[0]
	for i: int in slots:
		if int((inventory.call("stack_at", i) as Dictionary).get("n", 0)) <= int((inventory.call("stack_at", smallest) as Dictionary).get("n", 0)):
			smallest = i
	var n := int((inventory.call("stack_at", smallest) as Dictionary).get("n", 0))
	await _release_world_input()
	var room: RefCounted = load("res://tests/helpers/meadows_earned_team_segment.gd").new()
	room._tree = self
	room._world = world
	room._game = game
	room._menu = game.call("menu")
	if not await room._drop_slot(smallest):
		failures.append("Piece 07: Satchel Drop of the smaller %s stack failed: %s" % [id, str(room.result().failures)])
		return false
	disclosures.append("Piece 07: DROPPED the smaller duplicate %s stack (x%d, slot %d) through the Satchel to make room to build the Storage Chest" % [id, n, smallest])
	return true
