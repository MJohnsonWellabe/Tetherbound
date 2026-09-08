extends SceneTree

## Work-in-progress genuine fresh-save composition. --through-opening exercises
## its first completed segment and reports prefix evidence only. The default
## cannot report a campaign pass until every earned-state segment is composed.
const SAVE := preload("res://scripts/save/save_game.gd")
const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")
const VILLAGE := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
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
	failures.append("fresh campaign suffix is not composed; opening prefix is not milestone completion")
	_finish(false)


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
