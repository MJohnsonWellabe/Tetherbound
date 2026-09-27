extends "res://tests/helpers/cloudreach_witness_route.gd"

## F08#0 witness (ACCEPTANCE §6.1 F08: "Veyra's team and flight-relay exam are
## completed by ordinary input").
##
## Runs the unchanged continuous route and REQUIRES `--live-combat`: every
## trainer fight, Captain Veyra's included, is fought by the balance lane's
## controller-input pilot at the normal 1x clock from challenge input through the
## production victory callback (no lethal seam). After Veyra falls, control must
## pass to the deployed creature, which is piloted by stick input to each of the
## three storm-anchor relays and strikes them with the ordinary interact action.
## The witness checks Veyra's whole team was defeated in live rounds (opposition
## reaches zero), the victory and relay flags commit once, and the network is
## disabled -- then the base route's save/reload/no-double-grant assertions run.
##
## Coordinator re-check additions (BOSSES 4.6), all observed on the production
## finale controller, never written:
##   * stage order: crosswind_command -> anchor_overload -> break_the_eye, with
##     Anchor Overload beginning when exactly one of Veyra's creatures remains;
##   * wind lanes (Stage A) and the relay arc (Stage B) actually push the
##     controlled body: the controller's own drift on it is non-zero;
##   * lee pockets: at the start of Break the Eye the piloted creature walks
##     into the nearest pocket and holds; every frame inside is sheltered with no
##     push and its drift decays to zero; every pocket is sheltered at every
##     arc rotation over one full cycle;
##   * `--fail-exam-first`: the first Veyra attempt is fought by an idle pilot
##     (no input) until the whole party faints; the production loss must return
##     the trainer to Summit Bivouac with the same five, Veyra not defeated and
##     the threshold flag kept. The route then rests there and wins normally.
##
## START STATE: `--from-save=res://tests/fixtures/earned_saves/c1_arrival` runs
## from the earned C1 handoff save. `--start=aerie` runs from the declared aerie
## fixture instead (DRY RUN, does not count; evidence in `aerie-start/`).
const WITNESS_DIR := "res://ralph/reports/CLOUDREACH/b/f08-0-veyra-exam"
const VEYRA := "captain_veyra_storm_anchor"

var veyra_opposition: Array[Dictionary] = []
var relay_strikes: Array[Dictionary] = []
var fail_exam_first := false
var failed_exam: Dictionary = {}
var loss_window := false
var phase_sequence: Array[Dictionary] = []
var hazard_frames: Dictionary = {}
var lee_hold: Dictionary = {}
var lee_cycle_check: Dictionary = {}
var _phase_hooked := false
const LEE_HOLD_FRAMES := 240


## Stand-in for the combat pilot during the planned failed attempt: presses
## nothing and waits for the production round to end.
class IdlePilot extends RefCounted:
	var owner: Object
	var hits_dealt := 0
	var hits_taken := 0
	var damage_dealt := 0.0
	var damage_taken := 0.0
	var quick_thrown := 0
	var charged_thrown := 0
	var voluntary_switches := 0
	func reset_tally() -> void: pass
	func fight_to_the_end() -> Dictionary:
		var frames := 0
		while owner.manager.is_fighting() and frames < 36000:
			owner._release()
			await owner._frames(1)
			frames += 1
		return {"frames": frames, "idle": true}


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--fail-exam-first": fail_exam_first = true
	await super._run()


func _record_frame() -> void:
	super._record_frame()
	if runtime == null or runtime.finale == null or not is_instance_valid(player): return
	var finale: Node = runtime.finale
	if not _phase_hooked:
		_phase_hooked = true
		finale.phase_changed.connect(_on_phase_changed)
	var phase := str(finale.phase)
	if phase not in ["crosswind_command", "anchor_overload", "break_the_eye"]: return
	var body: CharacterBody3D = runtime.controlled_body()
	if body == null: return
	var sample: Dictionary = finale.hazard_at(body.global_position)
	var drift: Vector3 = (finale.get("_hazard_drift") as Dictionary).get(body.get_instance_id(), Vector3.ZERO)
	var row: Dictionary = hazard_frames.get(phase, {"frames": 0, "wind_frames": 0, "arc_frames": 0, "sheltered_frames": 0, "max_drift_mps": 0.0, "pushed_frames": 0})
	row.frames += 1
	if not (sample.wind as Vector3).is_zero_approx(): row.wind_frames += 1
	if not (sample.arc as Vector3).is_zero_approx(): row.arc_frames += 1
	if bool(sample.sheltered): row.sheltered_frames += 1
	if drift.length() > 0.05: row.pushed_frames += 1
	row.max_drift_mps = maxf(float(row.max_drift_mps), drift.length())
	hazard_frames[phase] = row


func _on_phase_changed(phase: String) -> void:
	var remaining := -1
	if not veyra_opposition.is_empty(): remaining = int(veyra_opposition[-1].get("remaining", -1))
	phase_sequence.append({"phase": phase, "opposition_remaining": remaining, "stage": stage,
		"simulated_seconds": snappedf(simulated_seconds, 0.01)})
	_log("witness_finale_phase", phase_sequence[-1])


func _fail(message: String) -> bool:
	if loss_window and message.begins_with("Live input combat lost through the production callback: " + VEYRA):
		_log("witness_expected_exam_loss", {"message": message})
		return false
	return super._fail(message)


func _battle(id: String) -> bool:
	if id != VEYRA or not fail_exam_first or not failed_exam.is_empty():
		return await super._battle(id)
	var uids_before := _party_keys_list()
	var real_pilot: RefCounted = combat_pilot
	var idle := IdlePilot.new()
	idle.owner = self
	combat_pilot = idle
	loss_window = true
	var losses_before := battle_losses.count(VEYRA)
	await super._battle(id)
	combat_pilot = real_pilot
	loss_window = false
	for tick in 240:
		await _frames(1)
	var bivouac: Vector3 = _vec(runtime.finale.config.recovery.safe_position)
	failed_exam = {"loss_callback": battle_losses.count(VEYRA) == losses_before + 1,
		"player": str(player.global_position), "distance_to_bivouac_m": snappedf(player.global_position.distance_to(bivouac), 0.1),
		"party_uids_same": _party_keys_list() == uids_before, "party_size": game.party.members().size(),
		"veyra_defeated": _has("captain_veyra_defeated"), "threshold_kept": _has("summit_extraction_engine_reached"),
		"phase_after": str(runtime.finale.phase), "failed": failed}
	_log("witness_failed_exam_return", failed_exam)
	if not _require(bool(failed_exam.loss_callback), "F08#0 the idle attempt lost through the production callback"): return false
	if not _require(float(failed_exam.distance_to_bivouac_m) < 30.0, "F08#0 the failed exam returned the trainer to Summit Bivouac (%.1f m)" % float(failed_exam.distance_to_bivouac_m)): return false
	if not _require(bool(failed_exam.party_uids_same) and int(failed_exam.party_size) == expected_party_size, "F08#0 the failed exam kept the same five"): return false
	if not _require(not bool(failed_exam.veyra_defeated) and bool(failed_exam.threshold_kept), "F08#0 the failed exam kept the threshold and did not grant Veyra"): return false
	if not await _rest("summit_bivouac"): return false
	if not await _navigate(Vector3(100, 1160, 5350)): return false
	return await super._battle(id)


func _party_keys_list() -> Array[String]:
	var out: Array[String] = []
	for member: RefCounted in game.party.members(): out.append(str(member.get("uid")))
	return out


## Break the Eye: before the first relay, walk the piloted creature into the
## nearest lee pocket and hold there, then continue the unchanged relay route.
func _walk(target: Vector3, radius: float = 0.75, body: CharacterBody3D = null) -> bool:
	if stage == "creature_relay_phase" and lee_hold.is_empty() and runtime != null and runtime.creature_piloted():
		lee_hold = {"started": true}
		if not await _hold_in_lee_pocket(): return false
	return await super._walk(target, radius, body)


func _hold_in_lee_pocket() -> bool:
	var finale: Node = runtime.finale
	var body: CharacterBody3D = runtime.controlled_body()
	var origin: Vector3 = finale.global_position
	var best: Dictionary = {}
	for lee: Dictionary in finale.config.lee_pockets:
		var at: Vector3 = origin + _vec(lee.offset)
		if best.is_empty() or body.global_position.distance_to(at) < float(best.distance):
			best = {"id": str(lee.id), "at": at, "radius": float(lee.radius_m), "distance": body.global_position.distance_to(at)}
	if not await super._walk(best.at + Vector3(0, -0.8, 0), 1.0, body): return false
	var inside := 0
	var pushed_inside := 0
	var drift_start := -1.0
	var drift_end := 0.0
	for tick in LEE_HOLD_FRAMES:
		_release()
		await _frames(1)
		var sample: Dictionary = finale.hazard_at(body.global_position)
		var drift: Vector3 = (finale.get("_hazard_drift") as Dictionary).get(body.get_instance_id(), Vector3.ZERO)
		if bool(sample.sheltered):
			inside += 1
			if drift_start < 0.0: drift_start = drift.length()
			drift_end = drift.length()
			if not (sample.wind as Vector3).is_zero_approx() or not (sample.arc as Vector3).is_zero_approx(): pushed_inside += 1
	# Every pocket is sheltered at every arc rotation over one full cycle.
	var cycle := float(finale.config.relay_arc.cycle_seconds) * 360.0 / absf(float(finale.config.relay_arc.rotation_degrees_per_second))
	var unsheltered := 0
	var samples := 0
	for lee: Dictionary in finale.config.lee_pockets:
		var t := 0.0
		while t < cycle:
			samples += 1
			if not bool(finale.hazard_at(origin + _vec(lee.offset), finale.elapsed + t).sheltered): unsheltered += 1
			t += 0.25
	lee_hold = {"pocket": best.id, "frames_held": LEE_HOLD_FRAMES, "frames_sheltered": inside, "pushed_frames_inside": pushed_inside,
		"drift_on_entry_mps": snappedf(drift_start, 0.01), "drift_after_hold_mps": snappedf(drift_end, 0.01), "phase": str(finale.phase)}
	lee_cycle_check = {"cycle_seconds": snappedf(cycle, 0.01), "samples": samples, "unsheltered_samples": unsheltered}
	_log("witness_lee_pocket_hold", {"hold": lee_hold, "cycle_check": lee_cycle_check})
	if not _require(inside >= LEE_HOLD_FRAMES / 2 and pushed_inside == 0, "F08#0 the piloted creature sheltered in a lee pocket with no push (%d frames)" % inside): return false
	if not _require(drift_end < 0.05, "F08#0 drift decays to zero inside the lee pocket (%.2f m/s)" % drift_end): return false
	return _require(unsheltered == 0, "F08#0 every lee pocket is sheltered at every arc rotation")


func _log(kind: String, details: Dictionary = {}) -> void:
	if kind == "opposition" and str(details.get("id", "")) == VEYRA:
		veyra_opposition.append(details.duplicate())
	if kind == "input_interact" or kind == "physical_interaction":
		if stage == "creature_relay_phase": relay_strikes.append(details.duplicate())
	super._log(kind, details)


## This witness's event log lives beside its verdict.
func _write_report() -> void:
	output_dir = _witness_dir(WITNESS_DIR)
	DirAccess.make_dir_recursive_absolute(_witness_dir(WITNESS_DIR))
	super._write_report()


func _finish() -> void:
	if _finish_already_done(): return
	var veyra_battle: Dictionary = {}
	for row: Dictionary in rows:
		if row.kind == "battle_resolved" and str(row.get("id", "")) == VEYRA: veyra_battle = row
	var relay_flags: Array[String] = []
	var relay_state: Dictionary = {}
	if runtime != null and runtime.finale != null:
		for relay: Dictionary in runtime.finale.config.relays:
			relay_flags.append(str(relay.flag_id))
			relay_state[str(relay.flag_id)] = _has(str(relay.flag_id))
	if completed_route and not failed:
		_require(live_combat, "F08#0 requires --live-combat (ordinary-input fights, no lethal seam)")
		_require(str(veyra_battle.get("mode", "")) == "live_input_spacer_switch" and bool(veyra_battle.get("victory_callback", false)) and not veyra_battle.get("rounds", []).is_empty(),
			"F08#0 Veyra defeated by live controller input through the production callback")
		_require(not veyra_opposition.is_empty() and int(veyra_opposition[-1].get("remaining", -1)) == 0,
			"F08#0 Veyra's whole team was defeated (opposition reached 0)")
		_require(battle_wins.count(VEYRA) == 1 and battle_losses.count(VEYRA) == (1 if fail_exam_first else 0), "F08#0 one Veyra victory; losses only the planned failed attempt")
		_require(relay_state.values().all(func(v: bool) -> bool: return v) and relay_state.size() == 3, "F08#0 three relays struck: " + str(relay_state))
		_require(_has("storm_anchor_network_disabled") and _has("captain_veyra_defeated"), "F08#0 exam outcome flags committed")
		var order: Array = phase_sequence.map(func(r: Dictionary) -> String: return str(r.phase))
		var a := order.rfind("crosswind_command")
		var b := order.rfind("anchor_overload")
		var c := order.rfind("break_the_eye")
		_require(a >= 0 and b > a and c > b, "F08#0 stages ran Crosswind Command -> Anchor Overload -> Break the Eye: " + str(order))
		# The finale reacts to the director's opposition signal before the
		# harness logs it, so read the count logged on the same frame.
		var overload: Array = phase_sequence.filter(func(r: Dictionary) -> bool: return str(r.phase) == "anchor_overload")
		var at_overload := -1
		if not overload.is_empty():
			var t := float(overload[-1].simulated_seconds)
			for row: Dictionary in rows:
				if row.kind == "opposition" and str(row.get("id", "")) == VEYRA and absf(float(row.get("simulated_seconds", -99.0)) - t) <= 0.05:
					at_overload = int(row.get("remaining", -1))
		_require(at_overload == 1, "F08#0 Anchor Overload began with one Veyra creature left (same-frame count %d): %s" % [at_overload, str(overload)])
		var cw: Dictionary = hazard_frames.get("crosswind_command", {})
		var ov: Dictionary = hazard_frames.get("anchor_overload", {})
		_require(int(cw.get("wind_frames", 0)) > 0 and int(cw.get("pushed_frames", 0)) > 0, "F08#0 Stage A wind lanes pushed the controlled body: " + str(cw))
		_require(int(ov.get("arc_frames", 0)) > 0 and int(ov.get("pushed_frames", 0)) > 0, "F08#0 Stage B relay arc pushed the controlled body: " + str(ov))
		_require(not lee_hold.is_empty() and lee_hold.has("frames_sheltered"), "F08#0 lee pocket hold ran")
		if fail_exam_first:
			_require(not failed_exam.is_empty() and battle_losses.count(VEYRA) == 1, "F08#0 the planned failed exam ran and returned to Summit Bivouac")
	DirAccess.make_dir_recursive_absolute(_witness_dir(WITNESS_DIR))
	var file := FileAccess.open(_witness_dir(WITNESS_DIR) + "/witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"criterion": "F08#0", "passed": completed_route and not failed and live_combat,
		"start_state": _start_state_label(), "leg": leg, "leg_persistence": leg_persistence, "skipped_steps": skipped_steps.size(),
		"combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal (NOT acceptance)", "accelerated_route_clock": accelerated,
		"stage": stage, "battle_wins": battle_wins, "battle_losses": battle_losses,
		"veyra_battle": veyra_battle, "veyra_opposition": veyra_opposition,
		"relay_state": relay_state, "relay_strikes": relay_strikes, "phase_sequence": phase_sequence,
		"hazard_frames": hazard_frames, "lee_hold": lee_hold, "lee_cycle_check": lee_cycle_check,
		"fail_exam_first": fail_exam_first, "failed_exam": failed_exam,
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}, "  "))
	print("F08#0 WITNESS %s veyra=%s relays=%s" % ["PASS" if completed_route and not failed and live_combat else "FAIL",
		str(veyra_battle.get("victory_callback", false)), JSON.stringify(relay_state)])
	super._finish()
