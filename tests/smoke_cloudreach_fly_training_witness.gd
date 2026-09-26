extends "res://tests/smoke_cloudreach_continuous.gd"

## F06#2 witness (ACCEPTANCE §6.1 F06: "training, landing, invalid landing ...
## do not bypass a closed gate or lose an owned creature").
##
## Runs the unchanged continuous normal-input route and, inside Maela's flight
## trial, adds two deliberate wrong-way attempts with ordinary stick/jump input:
##   1. mid-trial, before Fly is earned: steer out of the marked trial volume.
##      The flyer must be refused ("Stay inside the marked flight trial.") and
##      stay inside the trial box; the trial then completes normally.
##   2. after the trial lands and unlocks Fly, before the shrine windlass opens
##      the upper route: fly north at the sealed Upper Cloudreach wind wall and
##      try to set down there. The flyer must be refused/recovered, never enter
##      the sealed box, then land back on the aerie deck by ordinary descent.
## Every landing the route makes is recorded (position, floor, carrier). The
## base harness treats any Fly recovery as a failure; inside attempt 2 a
## recovery to the verified anchor is the expected invalid-landing outcome and
## is recorded instead.
##
## START STATE (disclosed): committed completed-Meadows fixture of
## smoke_cloudreach_continuous (the earned c1_arrival save is F06#0 and does not
## exist yet). `--from-save=<dir>` runs it from an earned save.
const WITNESS_DIR := "res://ralph/reports/CLOUDREACH/b/f06-2-fly-training"
const TRIAL_ESCAPE_FRAMES := 240
const SEALED_PUSH_FRAMES := 600

var trial_box := AABB()
var upper_box := AABB()
var denials: Array[Dictionary] = []
var recoveries: Array[Dictionary] = []
var landings: Array[Dictionary] = []
var attempts: Array[Dictionary] = []
var invalid_window := false
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
		denials.append({"reason": reason, "stage": stage, "position": str(player.global_position), "window": invalid_window})


func _on_recovered(reason: String) -> void:
	recoveries.append({"reason": reason, "stage": stage, "position": str(player.global_position), "window": invalid_window})


func _on_landed(at: Vector3, carrier: String) -> void:
	landings.append({"position": str(at), "carrier": carrier, "stage": stage, "on_floor": player.is_on_floor(),
		"fly_unlocked": _has("fly_traversal_unlocked"), "window": invalid_window})


## Inside the declared invalid-landing window a recovery is the expected answer.
func _fail(message: String) -> bool:
	if invalid_window and message.begins_with("Unexpected recovery interrupts"):
		_log("witness_expected_recovery", {"message": message})
		return false
	return super._fail(message)


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
	if not _require(_has("fly_traversal_unlocked"), "Ordered airborne rings and landing unlocked Fly"): return false
	return await _attempt_sealed_landing()


## Attempt 1: ordinary stick input straight out of the trial volume.
func _attempt_trial_escape() -> bool:
	var denials_before := denials.size()
	var start := player.global_position
	var away := Vector3(trial_box.get_center().x - start.x, 0, trial_box.get_center().z - start.z)
	away = (-away.normalized() if away.length() > 0.1 else Vector3.BACK) * 200.0
	for frame in TRIAL_ESCAPE_FRAMES:
		if not fly.is_flying(): break
		_steer(away, 1.0)
		_input("jump", 1)
		await _frames(1)
	_release()
	var refused := denials.slice(denials_before).any(func(d: Dictionary) -> bool: return str(d.reason).contains("marked flight trial"))
	attempts.append({"attempt": "trial_escape", "from": str(start), "end": str(player.global_position),
		"refused": refused, "still_flying": fly.is_flying(), "inside_trial": trial_box.grow(1.0).has_point(player.global_position),
		"trial_active": physical.trial_active})
	_log("witness_attempt", attempts[-1])
	if not _require(refused, "F06#2 leaving the marked trial is refused"): return false
	if not _require(trial_box.grow(1.0).has_point(player.global_position), "F06#2 flyer stays inside the trial volume"): return false
	return _require(fly.is_flying() and physical.trial_active, "F06#2 trial continues after the refusal")


## Attempt 2: after Fly unlock, try to fly into and set down in sealed Upper
## Cloudreach before the shrine windlass. Then descend back onto the aerie deck.
func _attempt_sealed_landing() -> bool:
	stage = "witness_sealed_upper_landing"
	var landing := _vec(physical.config.trial.landing_position)
	if not _require(not _has("cloudreach_upper_route_unlocked"), "Upper route is still sealed for the attempt"): return false
	if not await _deploy(): return false
	invalid_window = true
	var denials_before := denials.size()
	var recoveries_before := recoveries.size()
	var target := Vector3(landing.x, landing.y + 30.0, upper_box.position.z + 150.0)
	var closest := INF
	for frame in SEALED_PUSH_FRAMES:
		if not fly.is_flying(): break
		var offset := target - player.global_position
		_steer(offset, 1.0)
		_input("jump", 1 if offset.y > 2 else 0)
		_input("fly_descend", 1 if offset.y < -8 or frame > SEALED_PUSH_FRAMES / 2 else 0)
		closest = minf(closest, upper_box.position.z - player.global_position.z)
		await _frames(1)
	_release()
	var refused := denials.slice(denials_before).any(func(d: Dictionary) -> bool: return str(d.reason).contains("cloudreach_upper"))
	var recovered := recoveries.size() > recoveries_before
	attempts.append({"attempt": "sealed_upper_landing", "target": str(target), "end": str(player.global_position),
		"closest_gap_to_wall_m": closest, "refused": refused, "recovered": recovered,
		"still_flying": fly.is_flying(), "on_floor": player.is_on_floor(), "inside_sealed": upper_box.has_point(player.global_position)})
	_log("witness_attempt", attempts[-1])
	if not _require(refused or recovered, "F06#2 sealed Upper Cloudreach refuses the flyer"): return false
	if not _require(not upper_box.has_point(player.global_position), "F06#2 flyer never sets down inside the sealed region"): return false
	invalid_window = false
	if not fly.is_flying() and player.global_position.distance_to(landing) > 14.0:
		# Refused and grounded elsewhere on the aerie shelf: walk back normally.
		if not await _navigate(landing): return false
		return true
	if not await _land(landing): return false
	return _require(_has("fly_traversal_unlocked"), "Fly remains unlocked after the refused landing")


func _finish() -> void:
	if completed_route and not failed:
		_require(trial_escape_violations == 0, "F06#2 no trial frame outside the marked volume (%d)" % trial_escape_violations)
		_require(upper_violations == 0, "F06#2 no frame inside sealed Upper Cloudreach before unlock (%d)" % upper_violations)
		_require(landings.size() >= 3, "F06#2 trial, refused-attempt and shrine landings recorded (%d)" % landings.size())
		_require(game.party.members().size() == 5, "F06#2 same five after training")
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
