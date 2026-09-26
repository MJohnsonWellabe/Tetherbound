extends "res://tests/smoke_cloudreach_continuous.gd"

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
##   * after the route's save/reload, no loaner species is in the saved party.
##
## START STATE (disclosed): committed completed-Meadows fixture of
## smoke_cloudreach_continuous (the earned c1_arrival save is F06#0 and does not
## exist yet). `--from-save=<dir>` runs it from an earned save.
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
	output_dir = WITNESS_DIR
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
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
	if not initial_party_ids.is_empty() and ids != initial_party_ids and not _has("cloudreach_chapter_complete"):
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
	return await super._trial()


func _wait_on_floor() -> void:
	_release()
	for tick in 600:
		if player.is_on_floor(): return
		await _frames(1)


func _finish() -> void:
	if completed_route and not failed:
		_require(violations.is_empty(), "F06#3 no loaner/gate/identity violation (%d)" % violations.size())
		_require(not launches.is_empty() and launches.all(func(l: Dictionary) -> bool: return bool(l.loaner) and int(l.party_size) == expected_party_size),
			"F06#3 every flight was the loaner carrying the unchanged five (%d launches)" % launches.size())
		_require(owned_carrier_frames == 0, "F06#3 no owned creature was used as the carrier")
		var species: Array = game.party.members().map(func(m: RefCounted) -> String: return str(m.species_id))
		_require(species.size() == expected_party_size and not species.has(loaner_species) and _party_keys() == initial_party_keys, "F06#3 reloaded party is the same members, no loaner: " + str(species))
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
	var file := FileAccess.open(WITNESS_DIR + "/witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"criterion": "F06#3", "passed": completed_route and not failed,
		"start_state": ("earned save " + from_save) if not from_save.is_empty() else "committed completed-Meadows fixture (smoke_cloudreach_continuous default; five non-Fly creatures; earned c1_arrival save not yet available)",
		"combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal", "accelerated": accelerated,
		"stage": stage, "loaner_species": loaner_species, "pre_trial_probe": pre_trial_probe, "launches": launches,
		"flight_frames": flight_frames, "loaner_frames": loaner_frames, "owned_carrier_frames": owned_carrier_frames,
		"initial_party_keys": initial_party_keys, "violations": violations, "final_party": game.party.members().map(func(m: RefCounted) -> String: return str(m.species_id)),
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}, "  "))
	print("F06#3 WITNESS %s launches=%d loaner_frames=%d violations=%d" % ["PASS" if completed_route and not failed else "FAIL", launches.size(), loaner_frames, violations.size()])
	super._finish()
