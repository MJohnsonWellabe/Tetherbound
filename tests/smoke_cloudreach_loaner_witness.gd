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
##     summit threshold. The flyer must never stand on a floor within
##     OVERFLY_GATE_RADIUS_M of the threshold or arena, and no Voss-gated
##     progression flag may be set before Voss falls;
##   * after the route's save/reload, no loaner species is in the saved party.
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
const OVERFLY_GATE_RADIUS_M := 40.0
const OVERFLY_FRAMES := 3600
const VOSS_GATED_FLAGS: Array[String] = ["cloudreach_upper_anchors_disabled", "summit_extraction_engine_reached", "captain_veyra_defeated"]
var pre_voss_overfly: Dictionary = {}


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
	var ids: Array[int] = []
	for member: RefCounted in game.party.members():
		ids.append(member.get_instance_id())
		if not loaner_species.is_empty() and str(member.species_id) == loaner_species and from_save.is_empty():
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
	if not await super._trial(): return false
	# The loaner itself must be refused by a closed gate, not just never tested.
	return await _sealed_upper_attempt()


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
	var previous_clock := await _normal_input_clock("pre-Voss loaner overfly launch")
	await _tap("jump")
	await _tap("jump")
	await _frames(5)
	await _restore_route_clock(previous_clock)
	var launched: bool = fly.is_flying()
	var loaner: bool = launched and fly.last_flight_used_mentor_loaner()
	var closest := INF
	var grounded_near := 0
	var frames := 0
	overfly_window = true
	if launched:
		for frame in OVERFLY_FRAMES:
			if not fly.is_flying(): break
			var offset := SUMMIT_THRESHOLD - player.global_position
			_steer(offset, 1.0)
			_input("jump", 1 if offset.y > 2 else 0)
			await _frames(1)
			frames += 1
			closest = minf(closest, minf(player.global_position.distance_to(SUMMIT_THRESHOLD), player.global_position.distance_to(SUMMIT_ARENA)))
		_release()
		for frame in 2400:
			if not fly.is_flying(): break
			_input("fly_descend", 1)
			await _frames(1)
		_release()
	await _wait_on_floor()
	overfly_window = false
	for tick in 60:
		var near := minf(player.global_position.distance_to(SUMMIT_THRESHOLD), player.global_position.distance_to(SUMMIT_ARENA))
		closest = minf(closest, near)
		if player.is_on_floor() and near < OVERFLY_GATE_RADIUS_M: grounded_near += 1
		await _frames(1)
	var flags_after := VOSS_GATED_FLAGS.filter(func(f: String) -> bool: return _has(f))
	pre_voss_overfly = {"start": str(start), "launched": launched, "loaner": loaner, "flight_frames": frames,
		"end": str(player.global_position), "closest_to_summit_m": snappedf(closest, 0.1), "grounded_frames_within_gate_radius": grounded_near,
		"voss_defeated": _has("defeated_cloudreach_voss"), "recoveries_to_last_safe_landing": overfly_recoveries, "gated_flags_before": flags_before, "gated_flags_after": flags_after,
		"party_size": game.party.members().size()}
	_log("witness_pre_voss_overfly", pre_voss_overfly)
	if not _require(grounded_near == 0, "F06#3 the pre-Voss loaner overfly never stands within %.0f m of the summit threshold/arena" % OVERFLY_GATE_RADIUS_M): return false
	if not _require(flags_after == flags_before, "F06#3 the pre-Voss overfly set no Voss-gated progression flag"): return false
	return _require(game.party.members().size() == expected_party_size, "F06#3 party unchanged after the pre-Voss overfly")


func _wait_on_floor() -> void:
	_release()
	for tick in 600:
		if player.is_on_floor(): return
		await _frames(1)


func _finish() -> void:
	if _finish_already_done(): return
	if completed_route and not failed:
		_require(violations.is_empty(), "F06#3 no loaner/gate/identity violation (%d)" % violations.size())
		_require(not launches.is_empty() and launches.all(func(l: Dictionary) -> bool: return bool(l.loaner) and int(l.party_size) == expected_party_size),
			"F06#3 every flight was the loaner carrying the unchanged five (%d launches)" % launches.size())
		_require(owned_carrier_frames == 0, "F06#3 no owned creature was used as the carrier")
		_require(not sealed_attempt.is_empty() and int(sealed_attempt.refused_after_frames) >= 0, "F06#3 the loaner flight was refused by the sealed Upper wind wall")
		if leg.is_empty():
			_require(not pre_voss_overfly.is_empty(), "F06#3 the full route ran the pre-Voss loaner overfly")
		var species: Array = game.party.members().map(func(m: RefCounted) -> String: return str(m.species_id))
		_require(species.size() == expected_party_size and not species.has(loaner_species) and _party_keys() == initial_party_keys, "F06#3 reloaded party is the same members, no loaner: " + str(species))
	DirAccess.make_dir_recursive_absolute(_witness_dir(WITNESS_DIR))
	var file := FileAccess.open(_witness_dir(WITNESS_DIR) + "/witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"criterion": "F06#3", "passed": completed_route and not failed,
		"start_state": _start_state_label(), "leg": leg, "leg_persistence": leg_persistence, "skipped_steps": skipped_steps.size(),
		"combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal", "accelerated": accelerated,
		"stage": stage, "sealed_attempt": sealed_attempt, "pre_voss_overfly": pre_voss_overfly, "loaner_species": loaner_species, "pre_trial_probe": pre_trial_probe, "launches": launches,
		"flight_frames": flight_frames, "loaner_frames": loaner_frames, "owned_carrier_frames": owned_carrier_frames,
		"initial_party_keys": initial_party_keys, "violations": violations, "final_party": game.party.members().map(func(m: RefCounted) -> String: return str(m.species_id)),
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}, "  "))
	file.close()
	verdict_written = true
	print("F06#3 WITNESS %s launches=%d loaner_frames=%d violations=%d" % ["PASS" if completed_route and not failed else "FAIL", launches.size(), loaner_frames, violations.size()])
	super._finish()
