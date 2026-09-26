extends "res://tests/smoke_cloudreach_continuous.gd"

## Shared base for the Cloudreach-B witnesses: the unchanged continuous
## normal-input route, plus an OPT-IN declared mid-chapter start and an OPT-IN
## declared end.
##
## `--leg=flight` (DECLARED END): the run stops after the route's last flight,
## the controlled return glide that lands back on the aerie deck -- every Fly
## launch, ring, landing and loaner use of the chapter has happened by then.
## Before stopping it performs the same disk save/reload the full route does at
## its end (world paused around the observation) and requires every persisted
## field of every party member, the exact flag set and the Fly unlock to
## survive it. The grounded counterweight/Voss/Veyra remainder is NOT run.
##
## `--start=aerie` (DISCLOSED FIXTURE, not earned play): Act I is treated as
## already done. The Act I completion flags below are set on the progression
## store as the Cloudreach scene enters the tree (before its _ready builds the
## chapter), three Gale Fiber are granted at the first (skipped) arrival
## gather so the route's own ">= 3 gathered" check holds -- the seeded repair
## never spends them, so they stay in the bag -- and the trainer is placed ONCE
## beside the repaired aerie perch. Every route step before the aerie camp rest is then skipped; from the
## real `_rest("windscar_flight_aerie_camp")` onward the base route runs by
## ordinary input exactly as in a full run (trial, Fly, shrine, counterweight,
## Voss, bivouac, Veyra, relays, overlook, save/reload). The skipped span is
## the arrival road, lower anchors, Senn, the causeway signal and Maela's trial
## battle, so XP from those fights is not earned: the party enters the trial at
## the fixture's level 25. Without `--start` behaviour is the full route.
##
## Precedent: smoke_cloudreach_floor_loop_return.gd / aerie_services.gd use the
## same declared flags-before-build plus single placement fixture.
const ACT_ONE_FLAGS: Array[String] = ["cloudreach_chapter_started", "cloudreach_crisis_learned",
	"storm_anchor_lower_west_mapped", "cloudreach_lower_anchors_investigated",
	"defeated_cloudreach_senn", "causeway_survivors_reconnected",
	"completed_cloudreach_maela_trial_battle", "windscar_aerie_prepared",
	"cloudreach_act_i_complete"]
const AERIE_CAMP := "windscar_flight_aerie_camp"

var start_point := ""
var skipping_to_aerie := false
var skipped_steps: Array[String] = []
var start_record: Dictionary = {}
var finish_done := false
var verdict_written := false
var leg_persistence: Dictionary = {}
var sealed_attempt: Dictionary = {}
var sealed_upper_box := AABB()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--start="): start_point = arg.trim_prefix("--start=")
	if start_point == "aerie":
		skipping_to_aerie = true
		node_added.connect(_seed_act_one_on_scene_entry)
	elif not start_point.is_empty():
		push_error("Unknown --start=" + start_point)
	await super._run()


func _seed_act_one_on_scene_entry(node: Node) -> void:
	if node.get_parent() != root or not node.has_node("CloudreachChapter") and node.name != "CloudreachCliffs": return
	node_added.disconnect(_seed_act_one_on_scene_entry)
	for flag: String in ACT_ONE_FLAGS:
		root.get_node("Game").progression.set_flag(flag)


## The first purpose line follows the settled precondition frames: place once.
func _purpose(purpose: String, choice: String) -> void:
	if skipping_to_aerie and start_record.is_empty():
		var repair: Node3D = physical.get_node("aerie_repair/Interactable")
		var at := repair.global_position + Vector3(0, 0.4, 2.0)
		player.global_position = at
		player.velocity = Vector3.ZERO
		last_position = at
		start_record = {"start": "aerie", "placed_at": str(at), "flags_seeded": ACT_ONE_FLAGS,
			"team": _team_snapshot(), "note": "Declared fixture: Act I flags seeded before scene build; single placement beside the aerie repair; route from the aerie camp rest onward is ordinary input"}
		_log("witness_start_state", start_record)
	super._purpose(purpose, choice)


## In an aerie start the base route's fiber lines would read as gathered; say
## what actually happened.
func _log(kind: String, details: Dictionary = {}) -> void:
	if start_point == "aerie" and (kind == "preparation_ready" or (kind == "assertion" and str(details.get("label", "")) == "Gathered 3 Gale Fiber")):
		details = details.duplicate()
		details["fixture_note"] = "Declared --start=aerie grant; not gathered by input in this run"
		if kind == "preparation_ready": details["source"] = "Declared --start=aerie fixture grant"
	super._log(kind, details)


## A failure after the verdict was written must not vanish silently.
func _fail(message: String) -> bool:
	if verdict_written:
		# The verdict file and exit code are already written; say so loudly.
		push_error("LATE FAIL after witness verdict: " + message)
		print("CLOUDREACH WITNESS LATE FAIL " + message)
	return super._fail(message)


func _skip(kind: String, id: String) -> bool:
	skipped_steps.append(kind + ":" + id)
	return true


func _walk(target: Vector3, radius: float = 0.75, body: CharacterBody3D = null) -> bool:
	if skipping_to_aerie: return _skip("walk", str(target))
	return await super._walk(target, radius, body)


func _navigate(target: Vector3) -> bool:
	if skipping_to_aerie: return _skip("navigate", str(target))
	return await super._navigate(target)


func _interact(prompt: Node3D, flag: String = "", approach: bool = true) -> bool:
	if skipping_to_aerie: return _skip("interact", flag)
	return await super._interact(prompt, flag, approach)


func _arrival_gather(id: String, item: String) -> bool:
	if skipping_to_aerie:
		# The seeded repair already consumed the fiber; satisfy the route's
		# own ">= 3 gathered" precondition without a second repair.
		if game.inventory.count("gale_fiber") < 3: game.inventory.add("gale_fiber", 3 - game.inventory.count("gale_fiber"))
		return _skip("gather", id)
	return await super._arrival_gather(id, item)


func _talk(id: String, flag: String, navigate: bool = true) -> bool:
	if skipping_to_aerie: return _skip("talk", id)
	return await super._talk(id, flag, navigate)


func _physical_action(id: String, flag: String, navigate: bool = true) -> bool:
	if skipping_to_aerie: return _skip("physical", id)
	return await super._physical_action(id, flag, navigate)


func _pickup(id: String) -> bool:
	if skipping_to_aerie: return _skip("pickup", id)
	return await super._pickup(id)


func _battle(id: String) -> bool:
	if skipping_to_aerie: return _skip("battle", id)
	return await super._battle(id)


## The aerie camp rest is the first real step of an aerie start.
func _rest(id: String) -> bool:
	if skipping_to_aerie and id == AERIE_CAMP:
		skipping_to_aerie = false
		for tick in 60:
			if player.is_on_floor(): break
			await _frames(1)
		_log("witness_start_resume", {"skipped_steps": skipped_steps.size(), "on_floor": player.is_on_floor(), "position": str(player.global_position)})
	elif skipping_to_aerie:
		return _skip("rest", id)
	return await super._rest(id)


## The flight leg ends after the return-glide landing on the aerie deck.
func _return_to_aerie() -> bool:
	var ok: bool = await super._return_to_aerie()
	if not ok or leg != "flight": return ok
	if not _require(not skipping_to_aerie, "Declared start skip mode ended at the aerie camp rest"): return false
	await _frames(30)
	# A witness-owned save directory, so concurrent witnesses never share a slot.
	game.save_system = SAVE.new("user://cloudreach_witness_" + str(get_script().resource_path.get_file().get_basename()))
	paused = true
	var before := _party_persistence_snapshot()
	var flags_before := _flag_snapshot()
	var save_ok: bool = game.save_game(0)
	var load_ok: bool = save_ok and game.load_game(0)
	var after := _party_persistence_snapshot()
	var differences := _party_persistence_differences(before, after)
	paused = false
	leg_persistence = {"save_ok": save_ok, "load_ok": load_ok, "differences": differences,
		"party_size_after": game.party.members().size(), "flags_equal": _flag_snapshot() == flags_before,
		"fly_unlocked_after": _has("fly_traversal_unlocked")}
	_log("witness_leg_persistence", leg_persistence)
	if not _require(save_ok and load_ok, "Flight leg: disk save and reload completed"): return false
	if not _require(differences.is_empty(), "Flight leg: every persisted field of every member survived reload"): return false
	if not _require(_flag_snapshot() == flags_before and _has("fly_traversal_unlocked"), "Flight leg: exact flag set and Fly unlock survived reload"): return false
	_log("leg_complete", {"leg": leg, "team": _team_snapshot(), "inventory": _inventory_snapshot(), "flags": _flag_snapshot().size()})
	completed_route = true
	_finish()
	return false


## A genuine sealed-airspace landing attempt after Fly unlock and before the
## shrine windlass opens Upper Cloudreach, by ordinary input only: from the
## aerie deck, deploy, climb the authored `cloudreach_aerie_lift` by holding
## Jump, glide north at the sealed `cloudreach_upper` wind wall (the lift's
## ceiling keeps the glide above the wall's floor), keep pressing and then try
## to descend onto the sealed shelf. The wall must refuse the flyer and it must
## never be inside the sealed box; it then glides back and lands on the deck.
func _sealed_upper_attempt() -> bool:
	var physical_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_physical_runtime.json"))
	for spec: Dictionary in physical_config.restrictions:
		if str(spec.id) == "cloudreach_upper": sealed_upper_box = AABB(_vec(spec.position), _vec(spec.size))
	var landing := _vec(physical.config.trial.landing_position)
	var previous_stage := stage
	stage = "witness_sealed_upper_attempt"
	if not _require(_has("fly_traversal_unlocked") and not _has("cloudreach_upper_route_unlocked"), "Sealed attempt runs after Fly unlock and before the windlass"): return false
	var flags_before_attempt := _flag_snapshot()
	if not await _deploy(): return false
	var denial_reasons: Array[String] = []
	var on_denied := func(reason: String) -> void: denial_reasons.append(reason)
	fly.denied.connect(on_denied)
	var climb_end_y := -INF
	for frame in 1500:
		if not fly.is_flying() or player.global_position.y >= 770.0: break
		_steer(Vector3(450, 0, 3200) - Vector3(player.global_position.x, 0, player.global_position.z), 0.3)
		_input("jump", 1)
		await _frames(1)
		if failed: break
	climb_end_y = player.global_position.y
	var target := Vector3(450, 700, sealed_upper_box.position.z + 150.0)
	var refused_frame := -1
	var inside_frames := 0
	var closest_gap := INF
	for frame in 3600:
		if not fly.is_flying() or failed: break
		_steer(target - player.global_position, 1.0)
		_input("jump", 0)
		# After the first refusal keep pressing for 1 s, then try to set down there.
		_input("fly_descend", 1 if refused_frame >= 0 and frame > refused_frame + 60 else 0)
		await _frames(1)
		closest_gap = minf(closest_gap, sealed_upper_box.position.z - player.global_position.z)
		if sealed_upper_box.has_point(player.global_position): inside_frames += 1
		if refused_frame < 0 and denial_reasons.any(func(r: String) -> bool: return r.contains("cloudreach_upper")): refused_frame = frame
		if refused_frame >= 0 and frame > refused_frame + 180: break
	_release()
	fly.denied.disconnect(on_denied)
	sealed_attempt = {"climb_end_y": climb_end_y, "target": str(target), "refused_after_frames": refused_frame,
		"denials": denial_reasons.slice(0, 5), "closest_gap_to_box_m": closest_gap, "frames_inside_sealed_box": inside_frames,
		"end": str(player.global_position), "still_flying": fly.is_flying(), "on_floor": player.is_on_floor()}
	_log("witness_sealed_attempt", sealed_attempt)
	if not _require(refused_frame >= 0, "Sealed Upper Cloudreach wind wall refuses the flyer"): return false
	if not _require(inside_frames == 0 and not sealed_upper_box.has_point(player.global_position), "Flyer is never inside sealed Upper Cloudreach"): return false
	# Glide home by ordinary input and land on the aerie deck.
	if not fly.is_flying():
		if not await _deploy(): return false
	if not await _fly_to(Vector3(landing.x + 30, maxf(landing.y + 25.0, minf(player.global_position.y, 760.0)), landing.z), 8.0): return false
	if not await _land(landing): return false
	var flags_unchanged: bool = _flag_snapshot() == flags_before_attempt
	var ok := _require(flags_unchanged and not _has("cloudreach_upper_route_unlocked"), "Refused attempt changed no progression flag")
	stage = previous_stage
	return ok


## `_finish` can be reached twice when a declared leg ends inside a route step
## (the step returns and the base route calls `_finish` again). Report once.
func _finish_already_done() -> bool:
	if finish_done: return true
	finish_done = true
	return false


func _start_state_label() -> String:
	if start_point == "aerie":
		return "DECLARED aerie fixture (--start=aerie): committed completed-Meadows fixture party, Act I flags seeded before scene build, single placement beside the aerie repair; ordinary input from the aerie camp rest onward"
	if not from_save.is_empty():
		return "earned save " + from_save
	return "committed completed-Meadows fixture (smoke_cloudreach_continuous default; earned c1_arrival save not yet available)"


## Aerie-start evidence never overwrites a full-route run's evidence.
func _witness_dir(base: String) -> String:
	return base + ("/aerie-start" if start_point == "aerie" else "")
