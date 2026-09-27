extends "res://tests/helpers/cloudreach_witness_route.gd"

## F06#3 witness (ACCEPTANCE §6.1 F06: "loaner paths ... do not bypass a closed
## gate or lose an owned creature"; CLAUDE.md: the loaner cannot create a sixth
## slot).
##
## Runs the unchanged continuous normal-input route with the fixture's five
## non-Fly creatures, so every flight in the chapter is carried by Maela's
## transient Galecrest loaner. On top of the route it adds:
##   * a pre-trial negative: at the aerie, before the trial starts, the ordinary
##     double-jump must NOT deploy Fly and no loaner is offered;
##   * a per-frame ledger of every loaner flight: party size and instance IDs
##     are the same five, the loaner is never a Party member, and the flyer is
##     never inside a sealed restriction box (High Roost before Fly unlock,
##     Upper/Summit before the counterweight route) or outside the trial box
##     while the trial is the only authorization;
##   * full route only (coordinator Q2): after the windlass lifts every Fly
##     restriction and before Officer Voss is beaten, an active overfly: launch
##     the loaner by double-jump where the route stands after the two upper
##     anchors and fly straight at the
##     summit threshold: first climb the observatory updraft to its ceiling, then
##     glide at Voss's road point and on toward the threshold, sampling the
##     trajectory every second. The flyer must never stand on a floor more than
##     VOSS_PLANE_MARGIN_M past Voss's road point toward the summit, may be
##     recovered at most once (back to the overfly start), and no Voss-gated
##     progression flag may be set before Voss falls;
##   * after the route's save/reload, no loaner species is in the saved party;
##   * full route only: after the chapter completes and the disk reload runs,
##     the ordinary double-jump deploys no flight and no carrier is eligible
##     (the loaner ends at `mentor_loaner.ends_at_flag`).
##
## START STATE: `--from-save=res://tests/fixtures/earned_saves/c1_arrival` runs
## from the earned C1 handoff save. `--start=aerie` runs from the declared aerie
## fixture instead (DRY RUN, does not count; evidence in `aerie-start/`).
const WITNESS_DIR := "res://ralph/reports/CLOUDREACH/b/f06-3-loaner"

var sealed_boxes: Array[Dictionary] = []
var trial_box := AABB()
var loaner_species := ""
var flight_frames := 0
var loaner_frames := 0
var owned_carrier_frames := 0
var launches: Array[Dictionary] = []
var violations: Array[Dictionary] = []
var pre_trial_probe: Dictionary = {}
var was_flying := false
var initial_party_keys: Array[String] = []
const SUMMIT_THRESHOLD := Vector3(100, 1160, 5350)
const SUMMIT_ARENA := Vector3(100, 1160, 5450)
const VOSS_ROAD := Vector3(300, 1080, 5100)  # cloudreach_scene_runtime.json battle_yards officer_voss_summit_approach.road_position
const VOSS_PLANE_MARGIN_M := 20.0
const OVERFLY_CLIMB_FRAMES := 1200
const OVERFLY_FRAMES := 3600
const VOSS_GATED_FLAGS: Array[String] = ["cloudreach_upper_anchors_disabled", "summit_extraction_engine_reached", "captain_veyra_defeated"]
var pre_voss_overfly: Dictionary = {}
var start_had_loaner_species := false
var trial_escape: Dictionary = {}
var post_chapter_probe: Dictionary = {}
var _post_chapter_running := false
var _start_species_checked := false


## Stable across save/reload: the persisted uid when present, otherwise the
## persisted species/IV/trait tuple.
func _party_keys() -> Array[String]:
	var keys: Array[String] = []
	for member: RefCounted in game.party.members():
		var uid := str(member.get("uid"))
		keys.append(uid if not uid.is_empty() else "%s:%s:%s:%s:%s" % [member.species_id, member.iv_hp, member.iv_attack, member.iv_defence, member.trait_primary])
	return keys


## This witness's event log lives beside its verdict.
func _write_report() -> void:
	output_dir = _witness_dir(WITNESS_DIR)
	DirAccess.make_dir_recursive_absolute(_witness_dir(WITNESS_DIR))
	super._write_report()


func _run() -> void:
	var physical_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_physical_runtime.json"))
	trial_box = AABB(_vec(physical_config.trial.bounds_position), _vec(physical_config.trial.bounds_size))
	for spec: Dictionary in physical_config.restrictions:
		sealed_boxes.append({"id": str(spec.id), "flag": str(spec.requires_flag), "box": AABB(_vec(spec.position), _vec(spec.size))})
	var fly_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/fly_traversal.json")) if FileAccess.file_exists("res://data/config/fly_traversal.json") else {}
	loaner_species = str(fly_config.get("mentor_loaner", {}).get("species_id", ""))
	await super._run()


func _violation(kind: String, details: Dictionary = {}) -> void:
	if violations.size() >= 50: return
	var row := {"kind": kind, "stage": stage, "position": str(player.global_position)}
	row.merge(details)
	violations.append(row)


func _record_frame() -> void:
	super._record_frame()
	if fly == null or not is_instance_valid(player): return
	if loaner_species.is_empty() and fly.get("config") is Dictionary:
		loaner_species = str(fly.config.get("mentor_loaner", {}).get("species_id", ""))
	if not _start_species_checked and not loaner_species.is_empty() and game.party.members().size() == expected_party_size:
		_start_species_checked = true
		start_had_loaner_species = game.party.members().any(func(m: RefCounted) -> bool: return str(m.species_id) == loaner_species)
	var ids: Array[int] = []
	for member: RefCounted in game.party.members():
		ids.append(member.get_instance_id())
		if not loaner_species.is_empty() and str(member.species_id) == loaner_species and not start_had_loaner_species:
			_violation("loaner_in_party", {"species": loaner_species})
	# Live instance IDs are only stable until the route's own disk reload, which
	# rebuilds every member; after that the stable identity key is compared.
	if not initial_party_ids.is_empty() and ids != initial_party_ids and leg_persistence.is_empty() and not _has("cloudreach_chapter_complete"):
		_violation("party_identity_changed", {"ids": ids})
	if initial_party_keys.is_empty() and ids.size() == expected_party_size: initial_party_keys = _party_keys()
	elif not initial_party_keys.is_empty() and not paused and _party_keys() != initial_party_keys:
		_violation("party_stable_identity_changed", {"keys": _party_keys()})
	var flying: bool = fly.is_flying()
	if flying:
		flight_frames += 1
		if fly.last_flight_used_mentor_loaner(): loaner_frames += 1
		else: owned_carrier_frames += 1
		if not was_flying:
			launches.append({"stage": stage, "position": str(player.global_position), "loaner": fly.last_flight_used_mentor_loaner(),
				"party_size": ids.size(), "fly_unlocked": _has("fly_traversal_unlocked"), "trial_active": physical.trial_active})
		for sealed: Dictionary in sealed_boxes:
			if not _has(sealed.flag) and (sealed.box as AABB).has_point(player.global_position):
				_violation("loaner_in_sealed_region", {"restriction": sealed.id})
		if not _has("fly_traversal_unlocked") and not trial_box.grow(1.0).has_point(player.global_position):
			_violation("loaner_outside_trial_before_unlock")
	was_flying = flying


## Before Maela starts the trial, the ordinary double-jump must not produce a
## loaner flight. Then run the base trial unchanged.
func _trial() -> bool:
	await _wait_on_floor()
	var previous_clock := await _normal_input_clock("pre-trial double-jump probe")
	await _tap("jump")
	await _tap("jump")
	await _frames(10)
	await _restore_route_clock(previous_clock)
	pre_trial_probe = {"flying_after_double_jump": fly.is_flying(), "eligible_carrier": fly.eligible_creature() != null,
		"fly_unlocked": _has("fly_traversal_unlocked"), "trial_active": physical.trial_active, "position": str(player.global_position)}
	_log("witness_pre_trial_probe", pre_trial_probe)
	await _wait_on_floor()
	if not _require(not pre_trial_probe.flying_after_double_jump, "F06#3 no loaner flight before the trial starts"): return false
	if not _require(not pre_trial_probe.eligible_carrier, "F06#3 no loaner offered before the trial starts"): return false
	if not await _trial_with_escape(): return false
	# The loaner itself must be refused by a closed gate, not just never tested.
	return await _sealed_upper_attempt()


## The base trial with one active attempt, on the loaner, to leave the marked
## trial volume after the first ring: ordinary stick input on each horizontal
## side in turn until the controller refuses ("Stay inside the marked flight
## trial."). The flyer must stay inside and keep flying; the trial then
## completes unchanged.
func _trial_with_escape() -> bool:
	if _resume_skip("trial", "fly_traversal_unlocked"): return true
	stage = "authored_flight_trial"
	if not await _physical_action("flight_trial_start", "", false): return false
	if not _require(physical.trial_active, "Marked trial input started"): return false
	if not await _deploy(): return false
	var gates: Array = physical.config.trial.gates
	for index in gates.size():
		if not await _fly_to(_vec(gates[index].position), 3): return false
		if index == 0 and not await _loaner_trial_escape(): return false
	if not await _land(_vec(physical.config.trial.landing_position)): return false
	return _require(_has("fly_traversal_unlocked"), "Ordered airborne rings and landing unlocked Fly")


func _loaner_trial_escape() -> bool:
	var refusals: Array[String] = []
	var on_denied := func(reason: String) -> void: refusals.append(reason)
	fly.denied.connect(on_denied)
	var start := player.global_position
	var refused := false
	var tried: Array[String] = []
	for away: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		tried.append(str(away))
		for frame in 240:
			if not fly.is_flying(): break
			_steer(away * 200.0, 1.0)
			_input("jump", 1)
			await _frames(1)
			if refusals.any(func(r: String) -> bool: return r.contains("marked flight trial")):
				refused = true
				break
		if refused or not fly.is_flying(): break
	_release()
	fly.denied.disconnect(on_denied)
	trial_escape = {"from": str(start), "end": str(player.global_position), "directions_tried": tried, "refused": refused,
		"loaner": fly.last_flight_used_mentor_loaner(), "still_flying": fly.is_flying(),
		"inside_trial": trial_box.grow(1.0).has_point(player.global_position), "trial_active": physical.trial_active}
	_log("witness_loaner_trial_escape", trial_escape)
	if not _require(refused and bool(trial_escape.loaner), "F06#3 the loaner leaving the marked trial is refused"): return false
	if not _require(bool(trial_escape.inside_trial), "F06#3 the loaner stays inside the trial volume"): return false
	return _require(fly.is_flying() and physical.trial_active, "F06#3 the trial continues after the refusal")


func _battle(id: String) -> bool:
	if id == "officer_voss_summit_approach" and pre_voss_overfly.is_empty() and leg.is_empty():
		if not await _pre_voss_overfly(): return false
	return await super._battle(id)


## Coordinator Q2: the windlass has lifted every Fly restriction box; Voss's
## approach is now the only thing between the trainer and the summit. Launch
## the loaner by ordinary double-jump and fly straight at the summit threshold
## for up to OVERFLY_FRAMES, then descend and land wherever the glide ends. The
## base route then walks on to Voss from there.
func _pre_voss_overfly() -> bool:
	stage = "witness_pre_voss_overfly"
	await _wait_on_floor()
	var start := player.global_position
	var flags_before := VOSS_GATED_FLAGS.filter(func(f: String) -> bool: return _has(f))
	var toward_summit := Vector3(SUMMIT_THRESHOLD.x - VOSS_ROAD.x, 0, SUMMIT_THRESHOLD.z - VOSS_ROAD.z).normalized()
	var previous_clock := await _normal_input_clock("pre-Voss loaner overfly launch")
	await _tap("jump")
	await _tap("jump")
	await _frames(5)
	await _restore_route_clock(previous_clock)
	var launched: bool = fly.is_flying()
	var loaner: bool = launched and fly.last_flight_used_mentor_loaner()
	var closest := INF
	var furthest_past_voss := -INF
	var grounded_past_voss := 0
	var frames := 0
	var climb_frames := 0
	var peak_y := start.y
	var trajectory: Array[Dictionary] = []
	overfly_window = true
	overfly_recoveries = 0
	if launched:
		# 1) Climb in the observatory updraft with no stick until it tops out.
		var stalled := 0
		for frame in OVERFLY_CLIMB_FRAMES:
			if not fly.is_flying(): break
			_steer(Vector3.ZERO, 0.0)
			_climb_input(true)
			await _frames(1)
			frames += 1
			climb_frames += 1
			peak_y = maxf(peak_y, player.global_position.y)
			stalled = stalled + 1 if str(fly.state) != "climb" else 0
			if stalled > 60: break
			if frames % 60 == 0: trajectory.append(_overfly_sample(toward_summit))
		_climb_input(false)
		# 2) Glide at Voss's road point, then on past it toward the summit.
		for target: Vector3 in [VOSS_ROAD, SUMMIT_THRESHOLD]:
			for frame in OVERFLY_FRAMES:
				if not fly.is_flying(): break
				var offset := target - player.global_position
				if Vector2(offset.x, offset.z).length() < 8.0: break
				_steer(offset, 1.0)
				_climb_input(offset.y > 2)
				await _frames(1)
				frames += 1
				peak_y = maxf(peak_y, player.global_position.y)
				closest = minf(closest, minf(player.global_position.distance_to(SUMMIT_THRESHOLD), player.global_position.distance_to(SUMMIT_ARENA)))
				furthest_past_voss = maxf(furthest_past_voss, (player.global_position - VOSS_ROAD).dot(toward_summit))
				if player.is_on_floor() and (player.global_position - VOSS_ROAD).dot(toward_summit) > VOSS_PLANE_MARGIN_M: grounded_past_voss += 1
				if frames % 60 == 0: trajectory.append(_overfly_sample(toward_summit))
		_release()
		for frame in 2400:
			if not fly.is_flying(): break
			_input("fly_descend", 1)
			await _frames(1)
		_release()
	await _wait_on_floor()
	overfly_window = false
	for tick in 60:
		closest = minf(closest, minf(player.global_position.distance_to(SUMMIT_THRESHOLD), player.global_position.distance_to(SUMMIT_ARENA)))
		if player.is_on_floor() and (player.global_position - VOSS_ROAD).dot(toward_summit) > VOSS_PLANE_MARGIN_M: grounded_past_voss += 1
		await _frames(1)
	trajectory.append(_overfly_sample(toward_summit))
	var flags_after := VOSS_GATED_FLAGS.filter(func(f: String) -> bool: return _has(f))
	pre_voss_overfly = {"start": str(start), "launched": launched, "loaner": loaner, "flight_frames": frames, "climb_frames": climb_frames,
		"peak_y": snappedf(peak_y, 0.1), "end": str(player.global_position), "end_distance_to_start_m": snappedf(player.global_position.distance_to(start), 0.1),
		"closest_to_summit_m": snappedf(closest, 0.1), "furthest_past_voss_plane_m": snappedf(furthest_past_voss, 0.1),
		"grounded_frames_past_voss_plane": grounded_past_voss, "voss_plane_margin_m": VOSS_PLANE_MARGIN_M,
		"voss_defeated": _has("defeated_cloudreach_voss"), "recoveries_to_last_safe_landing": overfly_recoveries,
		"gated_flags_before": flags_before, "gated_flags_after": flags_after, "party_size": game.party.members().size(),
		"trajectory_1s": trajectory}
	_log("witness_pre_voss_overfly", pre_voss_overfly)
	if not _require(launched and loaner, "F06#3 the pre-Voss overfly launched the loaner by double-jump"): return false
	if not _require(grounded_past_voss == 0, "F06#3 the pre-Voss loaner overfly never stands past Voss's road point toward the summit"): return false
	if not _require(overfly_recoveries <= 1 and (overfly_recoveries == 0 or player.global_position.distance_to(start) < 3.0),
		"F06#3 at most one exhausted recovery, back to the overfly start (%d, %.1f m)" % [overfly_recoveries, player.global_position.distance_to(start)]): return false
	if not _require(flags_after == flags_before, "F06#3 the pre-Voss overfly set no Voss-gated progression flag"): return false
	return _require(game.party.members().size() == expected_party_size, "F06#3 party unchanged after the pre-Voss overfly")


func _overfly_sample(toward_summit: Vector3) -> Dictionary:
	return {"t": snappedf(simulated_seconds, 0.1), "at": str(player.global_position.snapped(Vector3.ONE * 0.1)),
		"region": MAP_STATE_SCRIPT.region_at(checkpoint_world, player.global_position), "state": str(fly.state),
		"flying": fly.is_flying(), "grounded": player.is_on_floor(),
		"past_voss_m": snappedf((player.global_position - VOSS_ROAD).dot(toward_summit), 0.1)}


## Climb input for the overfly. Production Fly currently climbs while Jump is
## held inside an updraft (the #356 held-button conflict); when the SYSTEMS tap
## pulse lands this becomes a fresh tap every pulse.
func _climb_input(on: bool) -> void:
	_input("jump", 1 if on else 0)


func _wait_on_floor() -> void:
	_release()
	for tick in 600:
		if player.is_on_floor(): return
		await _frames(1)


## After the chapter completes and the route's disk reload has run, the
## ordinary double-jump must no longer produce a loaner flight (fly_traversal.json
## `mentor_loaner.ends_at_flag`). Runs once, then finishes normally.
func _post_chapter_loaner_probe() -> void:
	stage = "witness_post_chapter_loaner_probe"
	await _wait_on_floor()
	var previous_clock := await _normal_input_clock("post-chapter loaner probe")
	await _tap("jump")
	await _tap("jump")
	await _frames(10)
	await _restore_route_clock(previous_clock)
	var mentor: Dictionary = fly.config.get("mentor_loaner", {}) if fly.get("config") is Dictionary else {}
	post_chapter_probe = {"flying_after_double_jump": fly.is_flying(), "eligible_carrier": fly.eligible_creature() != null,
		"loaner_used": fly.is_flying() and fly.last_flight_used_mentor_loaner(), "chapter_complete": _has("cloudreach_chapter_complete"),
		"ends_at_flag": str(mentor.get("ends_at_flag", "")), "after_disk_reload": true, "party_size": game.party.members().size(),
		"position": str(player.global_position)}
	_log("witness_post_chapter_loaner_probe", post_chapter_probe)
	if fly.is_flying():
		for frame in 2400:
			if not fly.is_flying(): break
			_input("fly_descend", 1)
			await _frames(1)
		_release()
	_require(bool(post_chapter_probe.chapter_complete) and not bool(post_chapter_probe.flying_after_double_jump) and not bool(post_chapter_probe.eligible_carrier),
		"F06#3 after the chapter and a disk reload the loaner is no longer offered: " + str(post_chapter_probe))
	_finish()


func _finish() -> void:
	if completed_route and not failed and leg.is_empty() and post_chapter_probe.is_empty():
		if not _post_chapter_running:
			_post_chapter_running = true
			_post_chapter_loaner_probe()
		return
	if _finish_already_done(): return
	if completed_route and not failed:
		_require(violations.is_empty(), "F06#3 no loaner/gate/identity violation (%d)" % violations.size())
		_require(not launches.is_empty() and launches.all(func(l: Dictionary) -> bool: return bool(l.loaner) and int(l.party_size) == expected_party_size),
			"F06#3 every flight was the loaner carrying the unchanged five (%d launches)" % launches.size())
		_require(owned_carrier_frames == 0, "F06#3 no owned creature was used as the carrier")
		_require(not sealed_attempt.is_empty() and int(sealed_attempt.refused_after_frames) >= 0, "F06#3 the loaner flight was refused by the sealed Upper wind wall")
		_require(not trial_escape.is_empty() and bool(trial_escape.refused), "F06#3 the loaner's trial-escape attempt was refused")
		if leg.is_empty():
			_require(not pre_voss_overfly.is_empty(), "F06#3 the full route ran the pre-Voss loaner overfly")
		var species: Array = game.party.members().map(func(m: RefCounted) -> String: return str(m.species_id))
		_require(species.size() == expected_party_size and not species.has(loaner_species) and _party_keys() == initial_party_keys, "F06#3 reloaded party is the same members, no loaner: " + str(species))
	DirAccess.make_dir_recursive_absolute(_witness_dir(WITNESS_DIR))
	var file := FileAccess.open(_witness_dir(WITNESS_DIR) + "/witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"criterion": "F06#3", "passed": completed_route and not failed,
		"start_state": _start_state_label(), "leg": leg, "leg_persistence": leg_persistence, "skipped_steps": skipped_steps.size(),
		"combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal", "accelerated": accelerated,
		"stage": stage, "sealed_attempt": sealed_attempt, "pre_voss_overfly": pre_voss_overfly, "trial_escape": trial_escape, "post_chapter_probe": post_chapter_probe,
		"counterweight_crown_seal": "active coverage: tests/test_cloudreach_counterweight_seal.gd (crown and stair boxes); watched per frame here", "loaner_species": loaner_species, "pre_trial_probe": pre_trial_probe, "launches": launches,
		"flight_frames": flight_frames, "loaner_frames": loaner_frames, "owned_carrier_frames": owned_carrier_frames,
		"initial_party_keys": initial_party_keys, "violations": violations, "final_party": game.party.members().map(func(m: RefCounted) -> String: return str(m.species_id)),
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}, "  "))
	file.close()
	verdict_written = true
	print("F06#3 WITNESS %s launches=%d loaner_frames=%d violations=%d" % ["PASS" if completed_route and not failed else "FAIL", launches.size(), loaner_frames, violations.size()])
	super._finish()
