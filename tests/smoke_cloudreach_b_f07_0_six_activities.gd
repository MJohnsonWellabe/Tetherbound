extends "res://tests/smoke_cloudreach_continuous.gd"

## F07#0 (Cloudreach-B, owner direction #356 13:07): the six WORLD §11
## Cloudreach activities, each witnessed in the production world as
## lure -> action -> payoff -> acknowledgement -> saved state, then one disk
## save + reload that must keep every completion.
##
## Activities follow `ralph/reports/CLOUDREACH/f07-0-six-activities/README.md`
## (tb/cloudreach): Waycamp shelter, Three Bells, Windscar couriers, Aeries
## (High Perches survey), the Cliff Circuit and the Observatory latch.
##
## Shortcuts (disclosed, owner ruling 06:55): fixture start (chapter flags up to
## Act II written before load; the lower/Windscar circuit pair defeats and
## Sora's engine-truth flag are fixture flags; level-30 retained five, none a
## flier, so every flight is Maela's loaner); teleports to each prompt's pad;
## 4 Gale Fiber granted for the shelter; Tavi fought through the harness's
## mechanics-mode lethal seam; accelerated clock (physics stays 1/60 s).
## Every prompt, bed assignment, dialogue, pickup and flight uses real input.
##
##   godot --headless --path . --script tests/smoke_cloudreach_b_f07_0_six_activities.gd
##   ... -- --with-air --only=cliff_circuit   (a disclosed air-type fifth member;
##   the three circuit TMs are air-only, so the default all-ground/water five
##   is refused every prize)

const WITNESS_DIR := "res://ralph/reports/CLOUDREACH/b/f07-0-six-activities-witness"
const START_FLAGS: Array[String] = ["realm_key_cloudreach", "warden_defeated", "realm_heart_meadows_earned",
	"realm_heart_meadows_placed", "realm_gate_cloudreach_unlocked", "cloudreach_chapter_started",
	"cloudreach_aila_arrival_complete", "cloudreach_crisis_learned", "causeway_survivors_reconnected",
	"cloudreach_lower_anchors_investigated", "windscar_aerie_prepared", "fly_traversal_unlocked",
	"sky_shrine_reached", "cloudreach_act_i_complete", "cloudreach_upper_route_unlocked",
	"cloudreach_act_ii_complete", "storm_anchor_upper_west_disabled", "storm_anchor_upper_east_disabled",
	"cloudreach_upper_anchors_disabled", "storm_anchor_engine_truth_learned",
	"defeated_cloudreach_ila", "defeated_cloudreach_orrin", "defeated_cloudreach_senn",
	"completed_cloudreach_maela_trial_battle"]
const MID_STAIR := Vector3(-435.0, 1035.0, 5155.0)

var dialogues: Array[String] = []
var activities: Dictionary = {}
var messages: Array[String] = []
var with_air := false
var only := ""


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	accelerated = true
	with_air = "--with-air" in OS.get_cmdline_user_args()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="): only = arg.trim_prefix("--only=")
	var variant := ("with-air" if with_air else "default-five") + ("" if only.is_empty() else "-" + only)
	output_dir = WITNESS_DIR + "/" + variant + "/latest-run"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://cloudreach_b_f07_0_six_activities")
	for flag: String in START_FLAGS:
		game.progression.set_flag(flag)
	game.realm_hearts.activate("meadows", game.progression)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "pipwing" if with_air else "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(30, PROGRESSION.config())
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
	physics_frame.connect(_record_frame)
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path()))
	world.get_node("DialoguePanel").finished.connect(func(id: String) -> void:
		dialogues.append(id)
		_log("dialogue_finished", {"id": id}))
	director.trainer_started.connect(func(id: String) -> void: battle_starts.append(id))
	director.trainer_victory.connect(func(id: String) -> void: battle_wins.append(id))
	director.trainer_lost.connect(func(id: String) -> void: battle_losses.append(id))
	physical.interaction_completed.connect(func(id: String) -> void: _log("physical_interaction", {"id": id}))
	fly.recovered.connect(func(reason: String) -> void: _log("flight_recovered", {"reason": reason}))
	fly.landed.connect(func(at: Vector3, carrier: String) -> void:
		_log("flight_landed", {"landing_position": str(at), "carrier": carrier}))
	# The HUD drains Game's one-line world message; sample it every physics frame.
	physics_frame.connect(func() -> void:
		var text := str(game.get("_pending_world_message"))
		if not text.is_empty() and (messages.is_empty() or messages[-1] != text):
			messages.append(text))
	await _frames(30)
	_log("precondition", {"description": "Fixture start (disclosed): chapter flags through Act II, level-30 retained five, no owned flier",
		"flags": _flag_snapshot().size(), "team": _team_snapshot()})
	for step: Callable in [_waycamp_shelter, _windscar_couriers, _aeries, _three_bells, _cliff_circuit, _observatory_latch]:
		if not only.is_empty() and step.get_method() != "_" + only:
			continue
		failed = false
		await step.call()
		_release()
		await _frames(10)
	var persistence := await _save_and_reload()
	var passed := persistence.get("ok", false) as bool
	for id: String in activities:
		passed = passed and bool(activities[id].get("pass", false))
	var verdict := {"criterion": "F07#0", "passed": passed, "team": _team_snapshot(), "with_air": with_air, "only": only, "activities": activities, "persistence": persistence,
		"dialogues": dialogues, "shortcuts": ["fixture flags through Act II (+ lower/Windscar circuit pair defeats, engine truth)",
		"teleport to each prompt pad", "4 Gale Fiber granted", "Tavi mechanics-mode lethal seam",
		"accelerated clock, physics 1/60 s", "Maela's loaner carries every flight (no owned flier)"]}
	var file := FileAccess.open(output_dir + "/verdict.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(verdict, "  "))
	file.close()
	_write_report()
	print("F07#0 SIX ACTIVITIES " + JSON.stringify(verdict))
	print("F07#0 SIX ACTIVITIES %s" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)


# --- the six activities ------------------------------------------------------

func _waycamp_shelter() -> void:
	var row := {"region": "gate_lower_cliffs"}
	stage = "waycamp_shelter"
	row["lure"] = _available("waycamp_canvas_bundle")
	row["bundle"] = await _act("waycamp_canvas_bundle", "side_waycamp_bundle_found")
	game.inventory.add("gale_fiber", 4) # disclosed grant; gathering is witnessed on the route
	var fiber_before: int = game.inventory.count("gale_fiber")
	row["supply"] = await _act("waycamp_shelter_supply", "side_waycamp_shelter_supplied")
	row["fiber_spent"] = fiber_before - int(game.inventory.count("gale_fiber"))
	await _frames(10)
	var decor := physical.get_node_or_null("waycamp_shelter_supply/CompletionDecor") as Node3D
	row["payoff_rain_cover"] = decor != null and decor.is_visible_in_tree()
	row["bed_assigned"] = await _assign_bed(-21)
	row["rest"] = await _act("waycamp_shelter_rest", "side_waycamp_shelter_complete")
	# Payoff (ruling (a), #356 14:00): a completed night in the sheltered bed
	# pays that companion the bed's rest XP once more. A real camp-rest press.
	row["payoff_night"] = await _sheltered_night(-21)
	row["ack"] = await _talk_to("healer_iven")
	row["ack_expected"] = "cloudreach_iven_waycamp_shelter"
	row["saved_flags"] = ["side_waycamp_bundle_found", "side_waycamp_shelter_supplied", "side_waycamp_shelter_complete"]
	row["pass"] = row.lure and row.bundle and row.supply and int(row.fiber_spent) == 4 and row.payoff_rain_cover \
		and row.bed_assigned and row.rest and bool(row.payoff_night.get("ok", false)) and row.ack == row.ack_expected
	_record("waycamp_shelter", row)


func _three_bells() -> void:
	var row := {"region": "broken_causeways -> windscar_ravine -> high_roost_sky_shrine"}
	stage = "three_bells"
	row["lure"] = _available("side_lower_bell")
	row["lower_bell"] = await _act("side_lower_bell", "side_bell_lower_found")
	row["windscar_bell"] = await _act("side_windscar_bell", "side_bell_windscar_rung")
	# The High Perches bell is flown to: the loaner lifts off the perch pad the
	# survey already proved, climbs out over the drop and lands at the bell.
	row["high_bell_flight"] = await _fly_between(Vector3(909.0, 1020.0, 2700.0), Vector3(906.0, 1020.0, 2700.0),
		Vector3(935.0, 1040.0, 2735.0))
	row["high_bell"] = await _act("side_high_bell", "side_three_bells_complete", false)
	await _frames(30)
	var travelers: Array[String] = []
	for label: String in ["Bridge Courier", "Bridge Traveler"]:
		var node := world.find_child("*" + label.replace(" ", "*") + "*", true, false) as Node3D
		if node != null and node.is_visible_in_tree():
			travelers.append(str(node.get_path()))
	row["payoff_travelers"] = travelers
	row["ack"] = await _talk_to("bridgekeeper_orrin")
	row["ack_expected"] = "cloudreach_orrin_bells_complete"
	row["saved_flags"] = ["side_bell_lower_found", "side_bell_windscar_rung", "side_three_bells_complete"]
	row["pass"] = row.lure and row.lower_bell and row.windscar_bell and row.high_bell_flight and row.high_bell \
		and travelers.size() == 2 and row.ack == row.ack_expected
	_record("three_bells", row)


func _windscar_couriers() -> void:
	var row := {"region": "windscar_ravine (from broken_causeways)"}
	stage = "windscar_couriers"
	row["lure"] = _available("courier_pack")
	row["pack"] = await _act("courier_pack", "side_courier_pack_recovered")
	row["delivery"] = await _act("courier_delivery", "side_courier_medicine_delivered")
	await _frames(20)
	# Neri has moved home to Galefoot; the report to her completes the chain.
	row["report"] = await _talk_to("courier_neri")
	row["report_expected"] = "cloudreach_neri_delivery_report"
	row["chain_complete"] = _has("side_stranded_couriers_complete")
	var potions_before: int = game.inventory.count("potion_small")
	var reward := physical.get_node_or_null("cr_reward_couriers_potions") as Node3D
	var reward_prompt: Node3D = reward.find_child("Interactable", true, false) if reward != null else null
	row["payoff_reward_present"] = reward_prompt != null
	if reward_prompt != null:
		row["payoff_reward_taken"] = await _act_prompt(reward_prompt)
	await _frames(20)
	row["payoff_potions"] = int(game.inventory.count("potion_small")) - potions_before
	row["ack"] = await _talk_to("courier_neri")
	row["ack_expected"] = "cloudreach_neri_home"
	row["saved_flags"] = ["side_courier_pack_recovered", "side_courier_medicine_delivered",
		"side_stranded_couriers_complete", "cloudreach_payout:couriers_thanks"]
	row["pass"] = row.lure and row.pack and row.delivery and row.report == row.report_expected \
		and row.chain_complete and int(row.payoff_potions) == 2 and row.ack == row.ack_expected
	_record("windscar_couriers", row)


func _aeries() -> void:
	var row := {"region": "high_roost_sky_shrine (+ upper_cloudreach, summit_final_stronghold)"}
	stage = "aeries"
	var surveys := {}
	for survey: Dictionary in physical.config.get("landing_objectives", []):
		if not str(survey.id).begins_with("survey_"):
			continue
		failed = false
		var pad := _vec(survey.position)
		var approach := _vec(survey.approach_position)
		var flag := str(survey.completion_flag)
		var before := _has(flag)
		var flown := await _fly_between(pad + Vector3(float(survey.radius_m) * 0.5, 0.0, 0.0), pad, approach)
		await _frames(30)
		surveys[str(survey.id)] = {"lure_available": not before, "flown_and_landed": flown, "flag": flag, "set": _has(flag)}
	row["surveys"] = surveys
	row["lure"] = bool(surveys.get("survey_high_perches", {}).get("lure_available", false))
	row["payoff_messages"] = messages.filter(func(text: String) -> bool: return text.begins_with("Landing recorded"))
	row["ack"] = await _talk_to("naturalist_sora")
	row["ack_expected"] = "cloudreach_sora_aeries_complete"
	row["saved_flags"] = ["side_aerie_high_perches_surveyed", "side_aerie_observatory_surveyed", "side_aeries_complete"]
	var all_set := true
	for id: String in surveys:
		all_set = all_set and bool(surveys[id].flown_and_landed) and bool(surveys[id].set)
	row["pass"] = row.lure and surveys.size() == 3 and all_set and row.ack == row.ack_expected
	_record("aeries", row)


func _cliff_circuit() -> void:
	var row := {"region": "upper_cloudreach"}
	stage = "cliff_circuit"
	row["pairs_from_fixture"] = _has("side_cliff_circuit_lower") and _has("side_cliff_circuit_windscar")
	var tavi_id := ""
	row["trainer_ids"] = director.trainer_nodes.keys().filter(func(id: String) -> bool: return "tavi" in id)
	if director.trainer_nodes.has("young_trainer_tavi_upper_ring"):
		tavi_id = "young_trainer_tavi_upper_ring"
	row["trainer_id"] = tavi_id
	row["lure"] = not tavi_id.is_empty() and not _has("side_cliff_circuit_complete")
	if not tavi_id.is_empty():
		var body: Node3D = director.trainer_nodes[tavi_id]
		await _place_near(body.global_position + Vector3(3.0, 0.0, 0.0))
		row["battle"] = await _battle(tavi_id)
	row["chain_complete"] = _has("side_cliff_circuit_complete")
	failed = false
	await _frames(30)
	# One TM of the three; a TM none of the retained five can learn is refused.
	var prizes := {}
	var chosen := ""
	for id: String in ["circuit_prize_wind_blade", "circuit_prize_heavenfall", "circuit_prize_aerial_flash"]:
		var spec: Dictionary = {}
		for entry: Dictionary in physical.config.interactions:
			if entry.id == id: spec = entry
		prizes[id] = {"item": str(spec.get("item_id", "")), "available": _available(id), "refusal": physical.tm_prize_refusal(spec)}
		if chosen.is_empty() and bool(prizes[id].available):
			chosen = id
	row["prizes_before"] = prizes
	row["prize_id"] = chosen
	var tm_item := str(prizes.get(chosen, {}).get("item", ""))
	var tm_before: int = game.inventory.count(tm_item) if not tm_item.is_empty() else 0
	row["prize"] = not chosen.is_empty() and await _act(chosen, "side_cliff_circuit_tm_chosen")
	await _frames(20)
	row["payoff_tm_item"] = tm_item
	row["payoff_tm"] = (int(game.inventory.count(tm_item)) - tm_before) if not tm_item.is_empty() else 0
	var others_refused := true
	for id: String in prizes:
		if id != chosen: others_refused = others_refused and not _available(id)
	row["other_prizes_refused"] = others_refused
	row["ack"] = await _talk_to("young_trainer_tavi")
	row["ack_expected"] = "cloudreach_tavi_defeated"
	row["saved_flags"] = ["side_cliff_circuit_lower", "side_cliff_circuit_windscar", "side_cliff_circuit_complete",
		"side_cliff_circuit_tm_chosen"]
	row["pass"] = row.pairs_from_fixture and row.lure and bool(row.get("battle", false)) and row.chain_complete \
		and row.prize and int(row.payoff_tm) == 1 and row.other_prizes_refused and row.ack == row.ack_expected
	_record("cliff_circuit", row)


func _observatory_latch() -> void:
	var row := {"region": "summit_final_stronghold"}
	stage = "observatory_latch"
	var stair := world.get_node_or_null(^"SuspendedBridges/ObservatoryLatchStairUpper") as Node3D
	row["lure"] = _available("observatory_latch_sighting")
	row["stair_absent_before"] = stair != null and not (stair.get_node(^"DeckSection1") as Node3D).visible \
		and is_nan(float(world.call("ground_height_near", MID_STAIR)))
	row["sighting"] = await _act("observatory_latch_sighting", "side_observatory_latch_sighted")
	row["latch"] = await _act("observatory_return_latch", "side_observatory_latch_complete")
	await _frames(20)
	row["payoff_stair"] = stair != null and (stair.get_node(^"DeckSection1") as Node3D).visible \
		and is_finite(float(world.call("ground_height_near", MID_STAIR)))
	row["ack"] = await _talk_to("defector_rusk")
	row["ack_expected"] = "cloudreach_rusk_observatory_latch"
	row["saved_flags"] = ["side_observatory_latch_sighted", "side_observatory_latch_complete"]
	row["pass"] = row.lure and row.stair_absent_before and row.sighting and row.latch and row.payoff_stair \
		and row.ack == row.ack_expected
	_record("observatory_latch", row)


# --- persistence --------------------------------------------------------------

func _save_and_reload() -> Dictionary:
	stage = "save_reload"
	_release()
	await _frames(30)
	var inventory_before := _reward_counts()
	var flags_before := _flag_snapshot()
	var set_before: Array[String] = []
	for id: String in activities:
		for flag: String in activities[id].get("saved_flags", []):
			if _has(flag): set_before.append(flag)
	var save_ok: bool = game.save_game(0)
	# Scrub the live flags, so only the disk slot can bring them back.
	for id: String in activities:
		for flag: String in activities[id].get("saved_flags", []):
			game.progression.set_flag(flag, false)
	var load_ok: bool = save_ok and game.load_game(0)
	await _frames(30)
	var missing: Array[String] = []
	for id: String in activities:
		var kept := true
		for flag: String in activities[id].get("saved_flags", []):
			if flag in set_before and not _has(flag):
				missing.append(flag)
				kept = false
		activities[id]["saved_after_reload"] = kept
	var inventory_after := _reward_counts()
	var result := {"save_ok": save_ok, "load_ok": load_ok, "flags_set_before_save": set_before, "missing_flags": missing,
		"flags_equal": _flag_snapshot() == flags_before, "inventory_before": inventory_before, "inventory_after": inventory_after,
		"party_size": game.party.members().size()}
	result["ok"] = save_ok and load_ok and missing.is_empty() and inventory_after == inventory_before \
		and game.party.members().size() == 5
	_log("persistence", result)
	return result


# --- helpers ------------------------------------------------------------------

func _reward_counts() -> Dictionary:
	var counts := {}
	for item: String in ["potion_small", "tm_wind_blade", "tm_heavenfall", "tm_aerial_flash"]:
		counts[item] = int(game.inventory.count(item))
	return counts


func _record(id: String, row: Dictionary) -> void:
	activities[id] = row
	_log("activity", {"id": id, "row": row})
	print("F07#0 ACTIVITY %s %s" % [id, "PASS" if bool(row.get("pass", false)) else "FAIL"])


func _available(id: String) -> bool:
	var prompt := physical.get_node_or_null(id + "/Interactable")
	return prompt != null and bool(prompt.get("enabled"))


## Teleport (disclosed) to the prompt's pad, then real Interactable + interact.
func _act(id: String, flag: String, place: bool = true) -> bool:
	failed = false
	var prompt := physical.get_node_or_null(id + "/Interactable") as Node3D
	if prompt == null:
		return _fail("Missing interaction " + id)
	if place and not await _stand_where_offer_wins(prompt):
		return _fail("No approach where %s is the winning offer" % id)
	return await _physical_action(id, flag, false)


func _act_prompt(prompt: Node3D) -> bool:
	failed = false
	if not await _stand_where_offer_wins(prompt):
		return _fail("No approach where %s is the winning offer" % prompt.get_path())
	return await _interact(prompt, "", false)


## Teleport (disclosed) beside the prompt, trying the four sides, until the
## production arbiter offers this prompt; the press itself stays real input.
func _stand_where_offer_wins(prompt: Node3D) -> bool:
	var arbiter: Node = world.get_node("InteractionArbiter")
	for side: Vector3 in [Vector3(0, 0, -1.5), Vector3(0, 0, 1.5), Vector3(1.5, 0, 0), Vector3(-1.5, 0, 0), Vector3.ZERO]:
		await _place_near(prompt.global_position + side)
		await process_frame
		arbiter.call("_recompute")
		if arbiter.get("_winning_provider") == prompt:
			return true
		_log("offer_side_rejected", {"prompt": str(prompt.get_path()), "side": str(side),
			"winner": str(arbiter.get("_winning_provider")), "winner_offer": arbiter.call("winner"),
			"prompt_enabled": prompt.get("enabled"), "prompt_offer": prompt.call("interaction_offer", player.global_position)})
	return false


## Real dialogue input with a named NPC; returns the first conversation opened.
func _talk_to(npc_id: String) -> String:
	failed = false
	var body: Node3D = chapter.npc_bodies().get(npc_id)
	if body == null:
		_fail("Missing NPC " + npc_id)
		return ""
	await _place_near(body.global_position + Vector3(0.0, 0.0, -2.5))
	var first := dialogues.size()
	var previous_clock := await _normal_input_clock("dialogue " + npc_id)
	if await _interact(body.get_node("Interactable")):
		var panel: Node = world.get_node("DialoguePanel")
		for line in 45:
			if not panel.is_open(): break
			await _frames(20)
			await _tap("interact")
	await _frames(15)
	await _restore_route_clock(previous_clock)
	return dialogues[first] if dialogues.size() > first else ""


## Real camp-bed controller input: assign the first companion to the bed whose
## build index is `index` (Galefoot's creature bed is -21).
func _assign_bed(index: int) -> bool:
	failed = false
	var bed: Node3D = null
	for node: Node in world.find_children("CampCreatureBed", "", true, false):
		if node.has_method("build_index") and int(node.call("build_index")) == index:
			bed = node
	if bed == null:
		return _fail("No creature bed with build index %d" % index)
	var prompt := bed.get_node_or_null("Interactable") as Node3D
	if director.ally_body() != null:
		await _tap("creature_recall")
		await _frames(12)
	await _place_near(prompt.global_position)
	var previous_clock := await _normal_input_clock("creature bed assignment")
	var ok := await _interact(prompt)
	if ok:
		await _tap("ui_accept")
		await _frames(8)
		var member: RefCounted = game.party.at(0)
		ok = _require(bool(member.get("resting")) and int(member.get("rest_bed_index")) == index,
			"Controller input assigned a companion to creature bed %d" % index)
		await _tap("menu_cancel")
		await _frames(8)
	await _restore_route_clock(previous_clock)
	return ok


## One ordinary night at the camp that owns bed `index`: press its rest prompt
## and require the bedded companion to gain twice the configured rest XP.
func _sheltered_night(index: int) -> Dictionary:
	failed = false
	var bed: Node3D = null
	for node: Node in world.find_children("CampCreatureBed", "", true, false):
		if node.has_method("build_index") and int(node.call("build_index")) == index:
			bed = node
	var camp: Node3D = bed.get_parent() if bed != null else null
	var prompt: Node3D = camp.get_node_or_null("Interactable") if camp != null else null
	var member: RefCounted = game.party.at(0)
	var result := {"camp": str(camp.get_path()) if camp != null else "", "bedded": bool(member.get("resting")) and int(member.get("rest_bed_index")) == index}
	if prompt == null:
		result["ok"] = false
		return result
	var rest_xp: int = PROGRESSION.rest_xp(PROGRESSION.config())
	var before := int(member.get("level")) * 100000 + int(member.get("xp"))
	var day_before := int(game.day)
	var pressed := await _act_prompt(prompt)
	var previous_clock := await _normal_input_clock("camp rest night")
	await _frames(160)
	await _restore_route_clock(previous_clock)
	var gained := int(member.get("level")) * 100000 + int(member.get("xp")) - before
	result.merge({"pressed": pressed, "day_before": day_before, "day_after": int(game.day), "rest_xp": rest_xp, "xp_gained": gained})
	result["ok"] = pressed and bool(result.bedded) and int(game.day) == day_before + 1 and gained == rest_xp * 2
	return result


## Stand on `from`, deploy Fly by double jump, pass `via` (if any) and land on
## `to` with held Jump / fly_descend input (lawful held Fly input).
func _fly_between(from: Vector3, to: Vector3, via: Vector3 = Vector3.INF) -> bool:
	failed = false
	await _place_near(from)
	await _frames(30)
	if not await _deploy():
		return false
	if via != Vector3.INF and not await _fly_to(via, 6.0):
		return false
	return await _land(to)


## Teleport (disclosed). A drop of more than 100 m below Fly's safe anchor is
## read by the production fall rule as a fall, so the teleport moves the anchor
## with the trainer (part of the same disclosed shortcut) and re-places if a
## recovery still pulls the trainer back.
func _place_near(at: Vector3) -> void:
	_release()
	for attempt in 4:
		for wait in 120:
			if fly == null or not fly.is_flying(): break
			await _frames(1)
		var ground := float(world.call("ground_height_near", at))
		var spot := Vector3(at.x, (ground if is_finite(ground) else at.y) + 1.2, at.z)
		if fly != null:
			fly.set("safe_anchor", spot - Vector3.UP * 1.2)
		player.global_position = spot
		player.velocity = Vector3.ZERO
		await _frames(30)
		if Vector2(player.global_position.x - spot.x, player.global_position.z - spot.z).length() < 3.0 \
				and absf(player.global_position.y - spot.y) < 4.0:
			return
		_log("placement_reverted", {"wanted": str(spot), "attempt": attempt})
