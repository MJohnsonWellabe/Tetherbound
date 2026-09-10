extends SceneTree

## Diagnostic-only continuous suffix from a copied earned post-bridge save.
## The source slot is never opened for writing. Every production autosave lands
## under user://diagnostic_four_biome_tail_copy.

const SAVE := preload("res://scripts/save/save_game.gd")
const WARRENS_TRACE := preload("res://tools/diagnose_retained_warrens_segment.gd")
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

var failures: Array[String] = []
var reached := "copied_post_bridge"
var _stop_after := ""
var _start_after := ""


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var source_slot := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--source-slot="):
			source_slot = arg.trim_prefix("--source-slot=")
		elif arg.begins_with("--stop-after="):
			_stop_after = arg.trim_prefix("--stop-after=")
		elif arg.begins_with("--start-after="):
			_start_after = arg.trim_prefix("--start-after=")
	if source_slot.is_empty() or not FileAccess.file_exists(source_slot):
		push_error("FOUR-BIOME TAIL requires --source-slot=<absolute slot_0.json>")
		quit(2)
		return
	var copied_dir := ProjectSettings.globalize_path("user://diagnostic_four_biome_tail_copy")
	if not _copy_save_tree(source_slot.get_base_dir(), copied_dir):
		push_error("FOUR-BIOME TAIL could not create isolated split-save copy")
		quit(2)
		return
	var game := root.get_node_or_null(^"Game")
	game.set("save_system", SAVE.new(copied_dir))
	if not bool(game.call("load_game", 0)):
		push_error("FOUR-BIOME TAIL could not load copied slot")
		quit(2)
		return
	if str(game.get("current_realm")) != "meadows":
		_fail("Copied checkpoint is not the retained post-bridge Meadows save")
		_finish()
		return
	print("FOUR-BIOME TAIL DIAGNOSTIC ONLY copied earned post-bridge save; no fresh-prefix claim")
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	await scene_changed
	for _frame in 120:
		await physics_frame
	var world := current_scene as Node3D

	if _start_after != "warrens":
		if not _accept(await WARRENS_TRACE.TraceWarrens.new().run(self, world, game), "passed", "warrens"):
			return
	else:
		print("FOUR-BIOME TAIL DIAGNOSTIC RESUME persisted post-Warrens snapshot; no cave replay claim")
	reached = "warrens_cleared_and_exited"
	if _stop("warrens"): return
	if not _accept(await RELAY.new().run(self, world, game), "passed", "relay"):
		return
	reached = "relay_disabled_and_mill_crossed"
	if _stop("relay"): return
	if not _accept(await HALL.new().run(self, world, game), "passed", "hall"):
		return
	reached = "warden_arena_entered"
	if _stop("hall"): return
	if not _accept(await WARDEN.new().run(self, world, game), "passed", "warden"):
		return
	world = current_scene as Node3D
	reached = "cloudreach_arrived"
	if _stop("meadows"): return

	var cloudreach := CLOUDREACH.new()
	if not _accept(await cloudreach.run(self, world, game), "ok", "cloudreach"):
		return
	reached = "cloudreach_completed"
	if _stop("cloudreach"): return
	if not _accept(await STORMWARD.new().run(self, cloudreach), "ok", "stormward"):
		return
	world = current_scene as Node3D
	reached = "stormwood_arrived"

	if not _accept(await STORMWOOD.Segment.new().run(self, world, game), "passed", "stormwood opening"):
		return
	reached = "stormwood_arch_recipe_earned"
	if not _accept(await CROWN.new().run(self, world, game), "passed", "stormwood crown"):
		return
	reached = "stormwood_paid_crown"
	if not _accept(await ROOTGATE.new().run(self, world, game), "passed", "stormwood rootgate"):
		return
	reached = "stormwood_rootgate_released"
	if not _accept(await DYNAMO.new().run(self, world, game), "passed", "stormwood dynamo"):
		return
	reached = "stormwood_dynamo_core_reached"
	if not _accept(await MARROW.new().run(self, world, game), "passed", "stormwood marrow"):
		return
	reached = "stormwood_marrow_and_core_released"
	if _stop("stormwood"): return
	if not _accept(await WATERWARD.new().run(self, world, game), "passed", "waterward"):
		return
	world = current_scene as Node3D
	reached = "water_arrived"

	var water_opening := WATER_OPENING.new()
	if not _accept(await water_opening.run(self, world, game), "passed", "water opening"):
		return
	var player: CharacterBody3D = water_opening.player
	var rig: Node3D = water_opening.camera
	reached = "water_pell_lesson_earned"
	if _stop("water-opening"): return
	for entry: Array in [[REEDHAVEN.new(), "reedhaven", "water_reedhaven_paid"],
			[BRINE.new(), "brine", "water_brine_trial_won"],
			[SHELLWATCH.new(), "shellwatch", "water_shellwatch_liberated"],
			[TIDAL.new(), "tidal", "water_swim_stone_and_recipe_earned"]]:
		var segment: RefCounted = entry[0]
		segment.setup(self, world, player, rig)
		var completed: bool = await segment.run()
		if not _accept(segment.result(), "ok", "water " + str(entry[1])):
			return
		if not completed:
			_fail("Water segment returned false despite accepted result: " + str(entry[1]))
			_finish()
			return
		reached = str(entry[2])
		if _stop(str(entry[1])): return

	var preparation := SWIMMER.new()
	if not _accept(await preparation.run(self, world, game), "passed", "water swimmer"):
		return
	reached = "water_earned_swimmer_and_paid_saddle_mounted"
	var late := LATE_WATER.new()
	late.setup(self, world, player, rig)
	var late_passed: bool = await late.run_from_mount(preparation.swimmer, _abort_late)
	if not _accept(late.result(), "passed", "late water"):
		return
	if not late_passed:
		_abort_late("Late Water returned false despite its accepted result")
		return
	reached = "water_nerissa_defeated_and_guardian_freed"
	if _stop("late-water"): return
	if not _accept(await WATER_ENDING.new().run_earned(self, world, game), "ok", "water ending"):
		return
	reached = "tidewake_ending_earned"
	_finish()


func _copy_save_tree(source_dir: String, destination_dir: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(destination_dir) != OK:
		return false
	var source := DirAccess.open(source_dir)
	if source == null:
		return false
	source.list_dir_begin()
	while true:
		var name := source.get_next()
		if name.is_empty():
			break
		if name in [".", ".."]:
			continue
		var from := source_dir.path_join(name)
		var to := destination_dir.path_join(name)
		if source.current_is_dir():
			if not _copy_save_tree(from, to):
				source.list_dir_end()
				return false
		else:
			var output := FileAccess.open(to, FileAccess.WRITE)
			if output == null:
				source.list_dir_end()
				return false
			output.store_buffer(FileAccess.get_file_as_bytes(from))
			output.close()
	source.list_dir_end()
	return true


func _accept(result: Dictionary, key: String, label: String) -> bool:
	for line: Variant in result.get("failures", []):
		failures.append("%s: %s" % [label, str(line)])
	if not bool(result.get(key, false)) and failures.is_empty():
		failures.append("%s returned %s=false" % [label, key])
	if not failures.is_empty():
		_finish()
		return false
	print("FOUR-BIOME TAIL SEGMENT PASS %s reached=%s" % [label, reached])
	return true


func _stop(label: String) -> bool:
	if _stop_after != label:
		return false
	_finish()
	return true


func _abort_late(reason: String) -> void:
	_fail(reason)


func _fail(reason: String) -> void:
	if not failures.has(reason):
		failures.append(reason)


func _finish() -> void:
	print("FOUR-BIOME TAIL RESULT ", JSON.stringify({
		"passed": failures.is_empty(),
		"reached": reached,
		"failures": failures,
	}))
	quit(0 if failures.is_empty() else 1)
