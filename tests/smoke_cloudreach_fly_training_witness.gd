extends "res://tests/smoke_cloudreach_continuous.gd"

## F06#2 witness (ACCEPTANCE §6.1 F06: "training, landing, invalid landing ...
## do not bypass a closed gate or lose an owned creature").
##
## Runs the unchanged continuous normal-input route and, inside Maela's flight
## trial before Fly is earned, steers out of the marked trial volume with
## ordinary stick/jump input (each horizontal side in turn until refused). The
## flyer must be refused ("Stay inside the marked flight trial."), stay inside
## the trial box, and the trial must then complete: rings in order and a
## verified collision landing unlock Fly. Every later landing (High Roost
## shrine, return to the aerie) is recorded and must be a verified floor. The
## whole route asserts zero trial frames outside the marked volume and zero
## frames inside sealed Upper Cloudreach before its unlock.
## DISCLOSED LIMIT: the invalid attempt is a refused one. Refusal zeroes the
## outward velocity, so ordinary input never reaches `recover_to_anchor`; the
## anchor-recovery half of "invalid-landing recovery" is covered separately by
## smoke_cloudreach_fall_recovery and the fly_controller tests, not here.
## A sealed-Upper landing attempt from the aerie was dropped: outside authored
## updrafts Fly only sinks (2 m/s), so from the deck the flyer passes under
## the wind wall rather than testing it.
##
## START STATE (disclosed): committed completed-Meadows fixture of
## smoke_cloudreach_continuous (the earned c1_arrival save is F06#0 and does not
## exist yet). `--from-save=<dir>` runs it from an earned save.
const WITNESS_DIR := "res://ralph/reports/CLOUDREACH/b/f06-2-fly-training"
const TRIAL_ESCAPE_FRAMES := 240

var trial_box := AABB()
var upper_box := AABB()
var denials: Array[Dictionary] = []
var recoveries: Array[Dictionary] = []
var landings: Array[Dictionary] = []
var attempts: Array[Dictionary] = []
var trial_escape_violations := 0
var upper_violations := 0


func _run() -> void:
	var physical_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_physical_runtime.json"))
	var trial: Dictionary = physical_config.trial
	trial_box = AABB(_vec(trial.bounds_position), _vec(trial.bounds_size))
	for spec: Dictionary in physical_config.restrictions:
		if str(spec.id) == "cloudreach_upper": upper_box = AABB(_vec(spec.position), _vec(spec.size))
	await super._run()


func _record_frame() -> void:
	super._record_frame()
	if fly == null or not is_instance_valid(player): return
	if not fly.denied.is_connected(_on_denied):
		fly.denied.connect(_on_denied)
		fly.recovered.connect(_on_recovered)
		fly.landed.connect(_on_landed)
	if physical != null and physical.trial_active and fly.is_flying() and not trial_box.grow(1.0).has_point(player.global_position):
		trial_escape_violations += 1
	if not _has("cloudreach_upper_route_unlocked") and upper_box.has_point(player.global_position):
		upper_violations += 1


func _on_denied(reason: String) -> void:
	if denials.size() < 200:
		denials.append({"reason": reason, "stage": stage, "position": str(player.global_position)})


func _on_recovered(reason: String) -> void:
	recoveries.append({"reason": reason, "stage": stage, "position": str(player.global_position)})


func _on_landed(at: Vector3, carrier: String) -> void:
	landings.append({"position": str(at), "carrier": carrier, "stage": stage, "on_floor": player.is_on_floor(),
		"fly_unlocked": _has("fly_traversal_unlocked")})


func _trial() -> bool:
	stage = "authored_flight_trial"
	if not await _physical_action("flight_trial_start", "", false): return false
	if not _require(physical.trial_active, "Marked trial input started"): return false
	if not await _deploy(): return false
	var gates: Array = physical.config.trial.gates
	for index in gates.size():
		if not await _fly_to(_vec(gates[index].position), 3): return false
		if index == 0 and not await _attempt_trial_escape(): return false
	await _capture("trial-airborne")
	if not await _land(_vec(physical.config.trial.landing_position)): return false
	return _require(_has("fly_traversal_unlocked"), "Ordered airborne rings and landing unlocked Fly")


## Attempt 1: ordinary stick input out of the trial volume. Try each open
## horizontal side in turn until the controller refuses (cliff collision on one
## side must not make the witness vacuous or spuriously fail).
func _attempt_trial_escape() -> bool:
	var denials_before := denials.size()
	var start := player.global_position
	var refused := false
	var tried: Array[String] = []
	for away: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		tried.append(str(away))
		for frame in TRIAL_ESCAPE_FRAMES:
			if not fly.is_flying(): break
			_steer(away * 200.0, 1.0)
			_input("jump", 1)
			await _frames(1)
			if denials.slice(denials_before).any(func(d: Dictionary) -> bool: return str(d.reason).contains("marked flight trial")):
				refused = true
				break
		if refused or not fly.is_flying(): break
	_release()
	attempts.append({"attempt": "trial_escape", "from": str(start), "end": str(player.global_position), "directions_tried": tried,
		"refused": refused, "still_flying": fly.is_flying(), "inside_trial": trial_box.grow(1.0).has_point(player.global_position),
		"trial_active": physical.trial_active})
	_log("witness_attempt", attempts[-1])
	if not _require(refused, "F06#2 leaving the marked trial is refused"): return false
	if not _require(trial_box.grow(1.0).has_point(player.global_position), "F06#2 flyer stays inside the trial volume"): return false
	return _require(fly.is_flying() and physical.trial_active, "F06#2 trial continues after the refusal")


## This witness's event log lives beside its verdict.
func _write_report() -> void:
	output_dir = WITNESS_DIR
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
	super._write_report()


func _finish() -> void:
	if completed_route and not failed:
		_require(trial_escape_violations == 0, "F06#2 no trial frame outside the marked volume (%d)" % trial_escape_violations)
		_require(upper_violations == 0, "F06#2 no frame inside sealed Upper Cloudreach before unlock (%d)" % upper_violations)
		_require(landings.size() >= 3 and landings.all(func(l: Dictionary) -> bool: return bool(l.on_floor)), "F06#2 trial, shrine and aerie-return landings all on verified floor (%d)" % landings.size())
		_require(game.party.members().size() == expected_party_size, "F06#2 party size unchanged after training")
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
	var file := FileAccess.open(WITNESS_DIR + "/witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"criterion": "F06#2", "passed": completed_route and not failed,
		"start_state": ("earned save " + from_save) if not from_save.is_empty() else "committed completed-Meadows fixture (smoke_cloudreach_continuous default; earned c1_arrival save not yet available)",
		"combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal", "accelerated": accelerated,
		"stage": stage, "attempts": attempts, "landings": landings, "recoveries": recoveries,
		"denials": denials.slice(0, 40), "trial_escape_violations": trial_escape_violations,
		"upper_violations": upper_violations,
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}, "  "))
	print("F06#2 WITNESS %s attempts=%s landings=%d" % ["PASS" if completed_route and not failed else "FAIL", JSON.stringify(attempts), landings.size()])
	super._finish()
