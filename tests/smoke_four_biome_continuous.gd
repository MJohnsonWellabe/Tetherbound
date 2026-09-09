extends SceneTree

## Genuine fresh-save composition. Optional --through-* stops are prefix
## evidence only. Default success requires every earned segment and ending;
## composition itself is not proof that the full runtime path has passed.
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
const DYNAMO := preload("res://tests/helpers/stormwood_earned_dynamo_segment.gd")
const MARROW := preload("res://tests/helpers/stormwood_earned_marrow_segment.gd")
const WATERWARD := preload("res://tests/helpers/stormwood_earned_waterward_handoff.gd")
const WATER_OPENING := preload("res://tests/helpers/water_earned_opening_segment.gd")
const REEDHAVEN := preload("res://tests/helpers/water_reedhaven_segment.gd")
const BRINE := preload("res://tests/helpers/water_brine_segment.gd")
const SHELLWATCH := preload("res://tests/helpers/water_shellwatch_segment.gd")
const TIDAL := preload("res://tests/helpers/water_tidal_segment.gd")
const SWIMMER := preload("res://tests/helpers/water_earned_swimmer_preparation_segment.gd")
const LATE_WATER := preload("res://tests/helpers/water_earned_late_segment.gd")
const WATER_ENDING := preload("res://tests/helpers/water_earned_ending_segment.gd")
const COVERAGE := preload("res://tests/helpers/four_biome_road_coverage_observer.gd")
var coverage: RefCounted
var failures: Array[String] = []
var live: Dictionary = {}
var started_ms := 0
var scratch := ""
var reached := "title"
var campaign_complete := false
var finished := false


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
	coverage = COVERAGE.new()
	if not coverage.start(self, "user://four_biome_coverage_%d_%d.jsonl" % [OS.get_process_id(), started_ms]):
		failures.append_array(coverage.failures)
		_finish(false)
		return
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
		var result: Dictionary
		if segment == camp:
			print("FRESH STAGE ENTRY stage=camp frame=", Engine.get_physics_frames(), " player=", live["player"].global_position)
			result = await camp.run(self, live["world"], game, live["player"], live["rig"], false, false, true)
			print("FRESH STAGE RETURN stage=camp frame=", Engine.get_physics_frames(), " player=", live["player"].global_position, " result=", JSON.stringify(result))
		else:
			print("FRESH STAGE ENTRY stage=materials frame=", Engine.get_physics_frames(), " player=", live["player"].global_position)
			result = await segment.run(self, live["world"], game, live["player"], live["rig"], true)
			print("FRESH STAGE RETURN stage=materials frame=", Engine.get_physics_frames(), " player=", live["player"].global_position, " result=", JSON.stringify(result))
		for line: Variant in result.get("failures", []):
			failures.append(str(line))
		if not bool(result.get("passed", false)) or not failures.is_empty():
			print("FRESH MATERIAL/CAMP DIAGNOSTIC %s" % JSON.stringify(result))
			_finish(false)
			return
	reached = "paid_camp"
	if OS.get_cmdline_user_args().has("--through-camp"):
		_finish(true)
		return
	print("FRESH STAGE ENTRY stage=rest frame=", Engine.get_physics_frames(), " player=", live["player"].global_position)
	var rest_result: Dictionary = await REST.new().run(self,
		live["world"], game, camp._beds, camp._bedroll, true)
	print("FRESH STAGE RETURN stage=rest frame=", Engine.get_physics_frames(), " player=", live["player"].global_position, " result=", JSON.stringify(rest_result))
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
	if not _accepted(await DYNAMO.new().run(self, live["world"], game), "passed"):
		return
	reached = "stormwood_dynamo_core_reached"
	if not _accepted(await MARROW.new().run(self, live["world"], game), "passed"):
		return
	reached = "stormwood_marrow_and_core_released"
	if not _accepted(await WATERWARD.new().run(self, live["world"], game), "passed"):
		return
	live["world"] = current_scene
	reached = "water_arrived"
	var water_opening := WATER_OPENING.new()
	if not _accepted(await water_opening.run(self, live["world"], game), "passed"):
		return
	live["player"] = water_opening.player
	live["rig"] = water_opening.camera
	reached = "water_pell_lesson_earned"
	for entry: Array in [[REEDHAVEN.new(), "water_reedhaven_paid"],
			[BRINE.new(), "water_brine_trial_won"],
			[SHELLWATCH.new(), "water_shellwatch_liberated"],
			[TIDAL.new(), "water_swim_stone_and_recipe_earned"]]:
		var segment: RefCounted = entry[0]
		segment.setup(self, live["world"], live["player"], live["rig"])
		var completed: bool = await segment.run()
		var result: Dictionary = segment.result()
		print("FRESH WATER SEGMENT %s %s" % [entry[1], JSON.stringify(result)])
		if not _accepted(result, "ok"):
			return
		if not completed:
			failures.append("Water segment returned false despite an accepted result: " + str(entry[1]))
			_finish(false)
			return
		reached = str(entry[1])
	var preparation := SWIMMER.new()
	if not _accepted(await preparation.run(self, live["world"], game), "passed"):
		return
	reached = "water_earned_swimmer_and_paid_saddle_mounted"
	var late_water := LATE_WATER.new()
	late_water.setup(self, live["world"], live["player"], live["rig"])
	var late_passed: bool = await late_water.run_from_mount(preparation.swimmer, _abort_late)
	if not _accepted(late_water.result(), "passed"):
		return
	if not late_passed:
		_abort_late("Late Water returned false despite its accepted result")
		return
	reached = "water_nerissa_defeated_and_guardian_freed"
	if not _accepted(await WATER_ENDING.new().run_earned(self, live["world"], game), "ok"):
		return
	reached = "tidewake_ending_earned"
	campaign_complete = true
	_finish(true)


func _abort_late(reason: String) -> void:
	failures.append(reason)
	_finish(false)


func _accepted(result: Dictionary, success_key: String) -> bool:
	for line: Variant in result.get("failures", []):
		failures.append(str(line))
	if not bool(result.get(success_key, false)) or not failures.is_empty():
		_finish(false)
		return false
	return true


func _finish(prefix_passed: bool) -> void:
	if finished:
		return
	finished = true
	if coverage != null:
		var coverage_result: Dictionary = coverage.stop()
		failures.append_array(coverage.failures)
		print("FRESH COVERAGE OBSERVATIONS %s" % JSON.stringify(coverage_result))
	print("FRESH CAMPAIGN RESULT %s" % JSON.stringify({
		"requested_prefix_passed": prefix_passed,
		"reached": reached,
		"campaign_complete": campaign_complete and failures.is_empty(),
		"scratch": scratch,
		"elapsed_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"failures": failures,
	}))
	quit(0 if prefix_passed and failures.is_empty() else 1)
