extends "res://tests/smoke_cloudreach_continuous.gd"

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
## START STATE (disclosed): committed completed-Meadows fixture of
## smoke_cloudreach_continuous (five level-25 installed creatures). The earned
## c1_arrival save is F06#0 and does not exist yet; `--from-save=<dir>` runs it
## from an earned save.
const WITNESS_DIR := "res://ralph/reports/CLOUDREACH/b/f08-0-veyra-exam"
const VEYRA := "captain_veyra_storm_anchor"

var veyra_opposition: Array[Dictionary] = []
var relay_strikes: Array[Dictionary] = []


func _log(kind: String, details: Dictionary = {}) -> void:
	if kind == "opposition" and str(details.get("id", "")) == VEYRA:
		veyra_opposition.append(details.duplicate())
	if kind == "input_interact" or kind == "physical_interaction":
		if stage == "creature_relay_phase": relay_strikes.append(details.duplicate())
	super._log(kind, details)


## This witness's event log lives beside its verdict.
func _write_report() -> void:
	output_dir = WITNESS_DIR
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
	super._write_report()


func _finish() -> void:
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
		_require(battle_wins.count(VEYRA) == 1 and battle_losses.count(VEYRA) == 0, "F08#0 one Veyra victory, no loss")
		_require(relay_state.values().all(func(v: bool) -> bool: return v) and relay_state.size() == 3, "F08#0 three relays struck: " + str(relay_state))
		_require(_has("storm_anchor_network_disabled") and _has("captain_veyra_defeated"), "F08#0 exam outcome flags committed")
	DirAccess.make_dir_recursive_absolute(WITNESS_DIR)
	var file := FileAccess.open(WITNESS_DIR + "/witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"criterion": "F08#0", "passed": completed_route and not failed and live_combat,
		"start_state": ("earned save " + from_save) if not from_save.is_empty() else "committed completed-Meadows fixture (smoke_cloudreach_continuous default; earned c1_arrival save not yet available)",
		"combat_mode": "live_input" if live_combat else "mechanics_only_test_lethal (NOT acceptance)", "accelerated_route_clock": accelerated,
		"stage": stage, "battle_wins": battle_wins, "battle_losses": battle_losses,
		"veyra_battle": veyra_battle, "veyra_opposition": veyra_opposition,
		"relay_state": relay_state, "relay_strikes": relay_strikes,
		"failure": rows.filter(func(r: Dictionary) -> bool: return r.kind == "FAIL")}, "  "))
	print("F08#0 WITNESS %s veyra=%s relays=%s" % ["PASS" if completed_route and not failed and live_combat else "FAIL",
		str(veyra_battle.get("victory_callback", false)), JSON.stringify(relay_state)])
	super._finish()
