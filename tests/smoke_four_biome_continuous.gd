extends SceneTree

## Work-in-progress genuine fresh-save composition. --through-opening exercises
## its first completed segment and reports prefix evidence only. The default
## cannot report a campaign pass until every earned-state segment is composed.
const SAVE := preload("res://scripts/save/save_game.gd")
const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")
const VILLAGE := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const TEAM := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const MATERIALS := preload("res://tests/helpers/meadows_earned_material_segment.gd")
const CAMP := preload("res://tests/helpers/meadows_earned_camp_segment.gd")
const REST := preload("res://tests/helpers/meadows_earned_rest_segment.gd")
const TOURNAMENT := preload("res://tests/helpers/meadows_earned_tournament_segment.gd")
const BRIDGE := preload("res://tests/helpers/meadows_earned_bridge_segment.gd")
const WARRENS := preload("res://tests/helpers/meadows_earned_warrens_segment.gd")
const RELAY := preload("res://tests/helpers/meadows_earned_relay_segment.gd")
const HALL := preload("res://tests/helpers/meadows_earned_hall_segment.gd")
const WARDEN := preload("res://tests/helpers/meadows_earned_warden_segment.gd")
const CLOUDREACH := preload("res://tests/helpers/cloudreach_live_segment.gd")
const STORMWARD := preload("res://tests/helpers/earned_stormward_handoff.gd")
const STORMWOOD := preload("res://tests/smoke_stormwood_continuous.gd")
const CROWN := preload("res://tests/helpers/stormwood_crown_build_segment.gd")
const ROOTGATE := preload("res://tests/helpers/stormwood_earned_rootgate_segment.gd")
var failures: Array[String] = []
var live: Dictionary = {}
var started_ms := 0
var scratch := ""
var reached := "title"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	var game := root.get_node("Game")
	scratch = "user://four_biome_fresh_%d_%d" % [OS.get_process_id(), started_ms]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(scratch)):
		failures.append("fresh scratch save already exists")
		_finish(false)
		return
	# Install before any title input, reset, world construction or autosave.
	game.set("save_system", SAVE.new(scratch))
	print("FRESH CAMPAIGN scratch=%s slot=%s" % [ProjectSettings.globalize_path(scratch),
		game.get("save_system").call("slot_path", 0)])
	var opening := OPENING.new()
	live = await opening.run(self)
	for line: Variant in live.get("failures", []):
		failures.append(str(line))
	if not bool(live.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	print("FRESH PREFIX: title through first live catch; no seeded progress, HP pinning or reload")
	reached = "opening"
	if OS.get_cmdline_user_args().has("--through-opening"):
		_finish(true)
		return
	live = await opening.open_road_gate()
	for line: Variant in live.get("failures", []):
		failures.append(str(line))
	if not failures.is_empty():
		_finish(false)
		return
	reached = "road_gate"
	var village_failures: Array[String] = await VILLAGE.new().run(self,
		live["world"], live["game"], live["player"], live["rig"])
	failures.append_array(village_failures)
	if not failures.is_empty():
		_finish(false)
		return
	reached = "village"
	if OS.get_cmdline_user_args().has("--through-village"):
		_finish(true)
		return
	var team_result: Dictionary = await TEAM.new().run(self, live["world"], game)
	for line: Variant in team_result.get("failures", []):
		failures.append(str(line))
	if not bool(team_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "earned_team"
	if OS.get_cmdline_user_args().has("--through-team"):
		_finish(true)
		return
	var camp := CAMP.new()
	for segment: RefCounted in [MATERIALS.new(), camp]:
		var result: Dictionary = await segment.run(self,
			live["world"], game, live["player"], live["rig"])
		for line: Variant in result.get("failures", []):
			failures.append(str(line))
		if not bool(result.get("passed", false)) or not failures.is_empty():
			_finish(false)
			return
	reached = "paid_camp"
	if OS.get_cmdline_user_args().has("--through-camp"):
		_finish(true)
		return
	var rest_result: Dictionary = await REST.new().run(self,
		live["world"], game, camp._beds, camp._bedroll)
	for line: Variant in rest_result.get("failures", []):
		failures.append(str(line))
	if not bool(rest_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "rested_team"
	if OS.get_cmdline_user_args().has("--through-rest"):
		_finish(true)
		return
	var tournament_result: Dictionary = await TOURNAMENT.new().run(self,
		live["world"], game, live["player"], live["rig"])
	for line: Variant in tournament_result.get("failures", []):
		failures.append(str(line))
	if not bool(tournament_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "tournament_won"
	if OS.get_cmdline_user_args().has("--through-tournament"):
		_finish(true)
		return
	var bridge_result: Dictionary = await BRIDGE.new().run(self, live["world"], game)
	for line: Variant in bridge_result.get("failures", []):
		failures.append(str(line))
	if not bool(bridge_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "south_bridge_crossed"
	if OS.get_cmdline_user_args().has("--through-bridge"):
		_finish(true)
		return
	var warrens_result: Dictionary = await WARRENS.new().run(self, live["world"], game)
	for line: Variant in warrens_result.get("failures", []):
		failures.append(str(line))
	if not bool(warrens_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "warrens_cleared_and_exited"
	if OS.get_cmdline_user_args().has("--through-warrens"):
		_finish(true)
		return
	var relay_result: Dictionary = await RELAY.new().run(self, live["world"], game)
	for line: Variant in relay_result.get("failures", []):
		failures.append(str(line))
	if not bool(relay_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "relay_disabled_and_mill_crossed"
	if OS.get_cmdline_user_args().has("--through-relay"):
		_finish(true)
		return
	var hall_result: Dictionary = await HALL.new().run(self, live["world"], game)
	for line: Variant in hall_result.get("failures", []):
		failures.append(str(line))
	if not bool(hall_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "warden_arena_entered"
	if OS.get_cmdline_user_args().has("--through-hall"):
		_finish(true)
		return
	if not _accepted(await WARDEN.new().run(self, live["world"], game), "passed"):
		return
	live["world"] = current_scene
	reached = "cloudreach_arrived"
	if OS.get_cmdline_user_args().has("--through-meadows"):
		_finish(true)
		return
	var cloudreach := CLOUDREACH.new()
	if not _accepted(await cloudreach.run(self, live["world"], game), "ok"):
		return
	reached = "cloudreach_completed"
	if OS.get_cmdline_user_args().has("--through-cloudreach"):
		_finish(true)
		return
	if not _accepted(await STORMWARD.new().run(self, cloudreach), "ok"):
		return
	live["world"] = current_scene
	reached = "stormwood_arrived"
	var stormwood := STORMWOOD.Segment.new()
	if not _accepted(await stormwood.run(self, live["world"], game), "passed"):
		return
	reached = "stormwood_arch_recipe_earned"
	if not _accepted(await CROWN.new().run(self, live["world"], game), "passed"):
		return
	reached = "stormwood_paid_crown"
	if not _accepted(await ROOTGATE.new().run(self, live["world"], game), "passed"):
		return
	reached = "stormwood_rootgate_released"
	failures.append("fresh campaign suffix is not composed; reached prefix is not milestone completion")
	_finish(false)


func _accepted(result: Dictionary, success_key: String) -> bool:
	for line: Variant in result.get("failures", []):
		failures.append(str(line))
	if not bool(result.get(success_key, false)) or not failures.is_empty():
		_finish(false)
		return false
	return true


func _finish(prefix_passed: bool) -> void:
	print("FRESH CAMPAIGN RESULT %s" % JSON.stringify({
		"requested_prefix_passed": prefix_passed,
		"reached": reached,
		"campaign_complete": false,
		"scratch": scratch,
		"elapsed_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"failures": failures,
	}))
	quit(0 if prefix_passed and failures.is_empty() else 1)
