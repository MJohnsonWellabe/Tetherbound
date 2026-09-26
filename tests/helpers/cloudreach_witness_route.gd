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
var want_exhausted_fall := false
var exhausted_attempted := false
var exhausted_window := false
var exhausted_fall: Dictionary = {}
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
	if exhausted_window and message.begins_with("Unexpected recovery interrupts"):
		_log("witness_expected_recovery", {"message": message})
		return false
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
	# An opted-in witness runs its exhausted fall from the exact shrine stand
	# the base route launches its own return glide from (after the windlass),
	# which the production launch check accepts on every recorded run.
	if want_exhausted_fall and not exhausted_attempted and not failed:
		exhausted_attempted = true
		if not await _exhausted_fall_attempt(): return false
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




## Production exhausted-fall recovery, reached by ordinary input only. From the
## shrine stand the route launches its return glide from (the flyer's safe
## anchor is the shrine floor it last stood on), deploy, hold Jump in the
## authored `cloudreach_shrine_lift` until the flight clock or stamina runs out
## (`state == "exhausted"`), then steer off the pinnacle over the open ravine.
## An exhausted flyer sinks; once it is `recovery_drop_m` below the anchor the
## production `recover_to_anchor` must put it back on the verified shrine floor.
## No position write, no stamina edit and no call into the fly controller.
func _exhausted_fall_attempt() -> bool:
	var previous_stage := stage
	stage = "witness_exhausted_fall"
	var anchor := player.global_position
	var fly_config: Dictionary = fly.config
	var drop_m := float(fly_config.get("recovery_drop_m", 100.0))
	var flags_before := _flag_snapshot()
	# The production launch check refuses where the companion's flight shape
	# would overlap something overhead. Record what overlaps here, then walk
	# by ordinary input to the nearest point on the same floor where the same
	# query is clear -- as a player would step out from under an overhang.
	var launch_probe := _launch_clearance(player.global_position)
	exhausted_fall["launch_blocker_at_landing"] = launch_probe
	if not bool(launch_probe.clear):
		var spot := _nearest_clear_launch(player.global_position)
		exhausted_fall["launch_spot"] = str(spot)
		if spot == Vector3.INF: return _fail("No clear launch point on the shrine within 22 m")
		if not await _walk(spot, 0.6): return false
		await _frames(10)
		anchor = player.global_position
	if not await _deploy(): return false
	exhausted_window = true
	var reasons: Array[String] = []
	var on_recovered := func(reason: String) -> void: reasons.append(reason)
	fly.recovered.connect(on_recovered)
	var lift_centre := Vector3(972, 0, 2975)
	var exhausted_frame := -1
	var hover_frames := 0
	for frame in 60 * 240:
		if not fly.is_flying() or failed: break
		if fly.state == "exhausted":
			exhausted_frame = frame
			break
		_steer(Vector3(lift_centre.x - player.global_position.x, 0, lift_centre.z - player.global_position.z), 0.25)
		_input("jump", 1)
		hover_frames += 1
		await _frames(1)
	var exhausted_at := player.global_position
	var lowest_y := player.global_position.y
	var recovered_frame := -1
	var landed_elsewhere := false
	for frame in 60 * 60:
		if reasons.size() > 0:
			recovered_frame = frame
			break
		if not fly.is_flying():
			landed_elsewhere = true
			break
		_input("jump", 0)
		_steer(Vector3(850 - player.global_position.x, 0, 2975 - player.global_position.z), 1.0)
		lowest_y = minf(lowest_y, player.global_position.y)
		await _frames(1)
	_release()
	fly.recovered.disconnect(on_recovered)
	await _frames(20)
	exhausted_window = false
	var floor_query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, player.global_position - Vector3.UP * 3, 1)
	floor_query.exclude = [player.get_rid()]
	var floor_hit := player.get_world_3d().direct_space_state.intersect_ray(floor_query)
	exhausted_fall.merge({"anchor": str(anchor), "hover_frames": hover_frames, "exhausted_after_frames": exhausted_frame,
		"exhausted_at": str(exhausted_at), "stamina_at_exhaustion_logged": true, "lowest_y_before_recovery": lowest_y,
		"drop_below_anchor_m": anchor.y - lowest_y, "recovery_drop_m": drop_m, "recovered_after_frames": recovered_frame,
		"recovery_reasons": reasons, "landed_elsewhere": landed_elsewhere, "end": str(player.global_position),
		"end_distance_to_anchor_m": player.global_position.distance_to(anchor), "on_floor": player.is_on_floor(),
		"floor_path": str(floor_hit.collider.get_path()) if not floor_hit.is_empty() else "none",
		"flying_after": fly.is_flying(), "party_size": game.party.members().size()}, true)
	_log("witness_exhausted_fall", exhausted_fall)
	if not _require(exhausted_frame >= 0, "Holding Jump in the shrine lift ran the flight to exhaustion"): return false
	if not _require(not landed_elsewhere and recovered_frame >= 0, "The exhausted flyer was recovered by production recover_to_anchor, not landed elsewhere"): return false
	if not _require(anchor.y - lowest_y >= drop_m - 1.0, "Recovery fired only after falling the configured drop below the anchor"): return false
	if not _require(player.global_position.distance_to(anchor) < 3.0 and player.is_on_floor() and not floor_hit.is_empty() and not fly.is_flying(), "Recovered onto the verified shrine anchor floor"): return false
	if not _require(_flag_snapshot() == flags_before and game.party.members().size() == expected_party_size, "Exhausted fall changed no flag and lost no creature"): return false
	# Ordinary standing rest before the route's next flight (as the base _deploy does).
	for tick in 60 * 120:
		if player.vitals.stamina >= player.vitals.max_stamina * 0.98: break
		await _frames(1)
	stage = previous_stage
	return true


const LAUNCH_PROBE_LIFT_M := 1.9


## The production launch overhead query (fly_controller.launch_blockers), read
## only: which colliders the companion's flight shape would overlap at `at`.
func _launch_clearance(at: Vector3) -> Dictionary:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = fly._flight_shape()
	# Production evaluates this after the first Jump, airborne; the recorded
	# launches sit ~1.9 m above the floor they left. Probing at the feet would
	# overlap the floor itself.
	query.transform = Transform3D(player.global_transform.basis, at + Vector3.UP * (LAUNCH_PROBE_LIFT_M + float(fly.config.get("collision_height_m", 4.5)) * 0.5))
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	var hits: Array[String] = []
	for hit: Dictionary in player.get_world_3d().direct_space_state.intersect_shape(query, 8):
		var collider: Object = hit.get("collider")
		hits.append(str(collider.get_path()) if collider is Node else str(collider))
	return {"at": str(at), "clear": hits.is_empty(), "overlapping": hits}


## The shrine's own authored stands first (the base route later launches from
## beside the windlass), then rings on walkable ground at a similar height.
func _nearest_clear_launch(origin: Vector3) -> Vector3:
	var space := player.get_world_3d().direct_space_state
	var probes: Array[Vector3] = []
	for id: String in ["shrine_windlass", "shrine_vane_west", "shrine_vane_east", "shrine_vane_crown"]:
		var prompt: Node3D = physical.get_node_or_null(id + "/Interactable")
		if prompt != null: probes.append(prompt.global_position)
	for radius: float in [3.0, 5.0, 7.0, 9.0, 12.0, 15.0, 18.0, 22.0]:
		for step in 16:
			var angle := TAU * float(step) / 16.0
			probes.append(origin + Vector3(cos(angle), 0, sin(angle)) * radius)
	for probe: Vector3 in probes:
		var ray := PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 4.0, probe - Vector3.UP * 4.0, 1)
		ray.exclude = [player.get_rid()]
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or (hit.normal as Vector3).y < 0.8 or absf((hit.position as Vector3).y - origin.y) > 3.0: continue
		var ground: Vector3 = hit.position
		if bool(_launch_clearance(ground).clear): return ground
	return Vector3.INF


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
