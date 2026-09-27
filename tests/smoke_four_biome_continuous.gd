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
const ROUTE_LEDGER := preload("res://tests/helpers/meadows_earned_route_ledger_segment.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const LOOK_ALIGNMENT_TOLERANCE_DEG := 0.75
const LOOK_ALIGNMENT_STRENGTH := 0.65
var coverage: RefCounted
var route_ledger: RefCounted
var failures: Array[String] = []
var live: Dictionary = {}
var started_ms := 0
var scratch := ""
var reached := "title"
var campaign_complete := false
var finished := false
var _measurement_camera_alignment := false
var _measurement_previous := Vector3.INF
var _measurement_look_action := StringName()


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	# `--world-seed=N` pins the rolled world for this process, the same override
	# `TB_WORLD_SEED` gives, for runners that cannot set the environment.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--world-seed="):
			var raw := arg.trim_prefix("--world-seed=")
			if not raw.is_valid_int():
				failures.append("--world-seed must be an integer: %s" % raw)
				_finish(false)
				return
			OS.set_environment("TB_WORLD_SEED", raw)
			print("FRESH CAMPAIGN world_seed override=", raw)
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
	# F02#5/#7: `--route-ledger` measures supplies, beat spacing and A7 on this
	# same walk. Observer only; without the flag the run is unchanged.
	if OS.get_cmdline_user_args().has("--route-ledger"):
		route_ledger = ROUTE_LEDGER.new()
		if not route_ledger.start(self, func() -> String: return reached,
				"user://route_ledger_%d_%d.jsonl" % [OS.get_process_id(), started_ms]):
			failures.append("route ledger could not create its evidence file")
			_finish(false)
			return
	var resume := _arg_value("--resume-from=")
	if not resume.is_empty():
		if not await _resume_checkpoint(game, resume):
			_finish(false)
			return
		_start_meadows_road_camera_alignment()
		if await _meadows_after_bridge(game):
			failures.append("--resume-from stops after the Hall; the Warden onward runs only from a new game")
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
			result = await camp.run(self, live["world"], game, live["player"], live["rig"], false, false, false)
			print("FRESH STAGE RETURN stage=camp frame=", Engine.get_physics_frames(), " player=", live["player"].global_position, " result=", JSON.stringify(result))
		else:
			print("FRESH STAGE ENTRY stage=materials frame=", Engine.get_physics_frames(), " player=", live["player"].global_position)
			result = await segment.run(self, live["world"], game, live["player"], live["rig"], false)
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
		live["world"], game, camp._beds, camp._bedroll, false)
	print("FRESH STAGE RETURN stage=rest frame=", Engine.get_physics_frames(), " player=", live["player"].global_position, " result=", JSON.stringify(rest_result))
	for line: Variant in rest_result.get("failures", []):
		failures.append(str(line))
	if not bool(rest_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return
	reached = "rested_team"
	# F02#4 "recovery survives reload": the camp rest's restored HP, rested
	# and fed state must come back from a production save before the bracket.
	var bed_marks: Array = []
	for bed: Node3D in camp._beds:
		bed_marks.append(int(bed.get_meta("placed_index", -1)))
	var roll_mark := int(camp._bedroll.get_meta("placed_index", -1))
	if not await _reload_transition(game, "rested_team"):
		_finish(false)
		return
	# The rebuilt world stood the placed camp back up from the save; re-find
	# its beds and bedroll by their saved placement index for the bracket's
	# recovery (the pre-reload nodes are gone).
	if OS.get_cmdline_user_args().has("--reload-at-transitions") and not _refind_camp(camp, bed_marks, roll_mark):
		_finish(false)
		return
	if OS.get_cmdline_user_args().has("--through-rest"):
		_finish(true)
		return
	var tournament := TOURNAMENT.new()
	tournament.recover = func() -> Dictionary:
		return await REST.new().recover(self, live["world"], game, camp._beds, camp._bedroll)
	var tournament_result: Dictionary = await tournament.run(self,
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
	_start_meadows_road_camera_alignment()
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
	if not await _meadows_after_bridge(game):
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


## Bridge -> Warrens -> Relay/Mill -> Hall, each followed by the production
## save/reload. A `--resume-from` run skips the stages its earned checkpoint is
## already past. Returns false when the run has finished (pass or fail).
func _meadows_after_bridge(game: Node) -> bool:
	if not _resumed_past("south_bridge_crossed") \
			and not await _reload_transition(game, "south_bridge_crossed"):
		_finish(false)
		return false
	var stages := [
		[WARRENS, "warrens_cleared_and_exited", "--through-warrens"],
		[RELAY, "relay_disabled_and_mill_crossed", "--through-relay"],
		[HALL, "warden_arena_entered", "--through-hall"],
	]
	for stage: Array in stages:
		var label := str(stage[1])
		if _resumed_past(label):
			continue
		var result: Dictionary = await (stage[0] as GDScript).new().run(self, live["world"], game)
		for line: Variant in result.get("failures", []):
			failures.append(str(line))
		if not bool(result.get("passed", false)) or not failures.is_empty():
			_finish(false)
			return false
		reached = label
		# F02#4: the stage's own save/reload happens before a `--through-*`
		# stop, so the last transition of a prefix run is reload-checked too.
		if not await _reload_transition(game, label):
			_finish(false)
			return false
		if OS.get_cmdline_user_args().has(str(stage[2])):
			_finish(true)
			return false
	return true


## Earned checkpoints (coordinator speed rule, 2026-09-27). Every reload
## transition copies the production save it just wrote to
## `user://four_biome_checkpoints/<label>_<pid>/`; `--resume-from=<that dir>`
## continues from it for debugging. A resumed run is never `closes` proof: that
## stays one uninterrupted run from a new game, which is why its result says so.
const CHECKPOINT_ROOT := "user://four_biome_checkpoints"
const STAGE_ORDER := ["south_bridge_crossed", "warrens_cleared_and_exited",
	"relay_disabled_and_mill_crossed", "warden_arena_entered"]
var resumed_from := ""


func _resumed_past(label: String) -> bool:
	if resumed_from.is_empty():
		return false
	return STAGE_ORDER.find(label) <= STAGE_ORDER.find(resumed_from)


func _arg_value(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


static func copy_tree(from: String, to: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(to) != OK:
		return false
	var dir := DirAccess.open(from)
	if dir == null:
		return false
	for file: String in dir.get_files():
		if dir.copy(from.path_join(file), to.path_join(file)) != OK:
			return false
	for sub: String in dir.get_directories():
		if not copy_tree(from.path_join(sub), to.path_join(sub)):
			return false
	return true


func _write_checkpoint(label: String, scene_path: String) -> void:
	var to := ProjectSettings.globalize_path("%s/%s_%d" % [CHECKPOINT_ROOT, label, OS.get_process_id()])
	if not copy_tree(ProjectSettings.globalize_path(scratch), to.path_join("save")):
		print("CHECKPOINT %s: copy failed" % label)
		return
	var meta := FileAccess.open(to.path_join("checkpoint.json"), FileAccess.WRITE)
	if meta == null:
		print("CHECKPOINT %s: checkpoint.json could not be written" % label)
		return
	meta.store_string(JSON.stringify({"label": label, "scene": scene_path,
		"world_seed": OS.get_environment("TB_WORLD_SEED"), "elapsed_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0}))
	meta.close()
	print("CHECKPOINT %s -> %s" % [label, to])


func _resume_checkpoint(game: Node, from: String) -> bool:
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(from.path_join("checkpoint.json")))
	if not meta is Dictionary or not STAGE_ORDER.has(str((meta as Dictionary).get("label", ""))):
		failures.append("--resume-from has no readable earned checkpoint: " + from)
		return false
	# The checkpoint's rolled world, unless the command line pinned the same one.
	var seed := str((meta as Dictionary).get("world_seed", ""))
	if not seed.is_empty():
		if OS.has_environment("TB_WORLD_SEED") and OS.get_environment("TB_WORLD_SEED") != seed:
			failures.append("--world-seed %s conflicts with the checkpoint's seed %s" % [OS.get_environment("TB_WORLD_SEED"), seed])
			return false
		OS.set_environment("TB_WORLD_SEED", seed)
	if not copy_tree(from.path_join("save"), ProjectSettings.globalize_path(scratch)):
		failures.append("could not copy the checkpoint save into this run's scratch")
		return false
	if not bool(game.call("load_game", 0)):
		failures.append("load_game(0) refused the earned checkpoint")
		return false
	var packed := load(str(meta.get("scene", ""))) as PackedScene if not str(meta.get("scene", "")).is_empty() else null
	if packed == null:
		failures.append("the earned checkpoint names no loadable scene")
		return false
	var world: Node = packed.instantiate()
	root.add_child(world)
	current_scene = world
	for i in 240:
		await physics_frame
	live["world"] = world
	live["player"] = world.get_node_or_null(^"Player")
	live["rig"] = get_first_node_in_group("camera_rig")
	resumed_from = str(meta["label"])
	reached = resumed_from
	print("RESUMED FROM EARNED CHECKPOINT %s (%s) — debug only, not closes proof" % [resumed_from, from])
	return live["player"] != null

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


## F02 (ACCEPTANCE §6.1): "each transition, reward and recovery survives
## reload". With `--reload-at-transitions`, after the bridge, the Warrens, the
## relay/Mill and the Hall: a production save (the installed scratch save
## system), the live Meadows freed, the flag store and party emptied, a
## production load and a fresh Meadows scene; the next segment continues in the
## rebuilt world. Every flag and the party's UIDs must come back exactly.
## Without the flag this is a no-op, so the CI path is unchanged.
func _reload_transition(game: Node, label: String) -> bool:
	if not OS.get_cmdline_user_args().has("--reload-at-transitions"):
		return true
	var progression: RefCounted = game.get("progression")
	var party: RefCounted = game.get("party")
	var flags_before: Array = (progression.call("all_set") as Array).duplicate()
	flags_before.sort()
	var uids_before := _party_uids(party)
	var inventory: RefCounted = game.get("inventory")
	var items_before := _inventory_totals(inventory)
	var members_before := _party_condition(party)
	var scene_path := str(current_scene.scene_file_path)
	if not bool(game.call("save_game", 0)):
		failures.append("RELOAD %s: save_game(0) refused" % label)
		return false
	_write_checkpoint(label, scene_path)
	var old := current_scene
	old.queue_free()
	for i in 4:
		await process_frame
	progression.call("load_data", {})
	party.call("clear")
	# F02#4: rewards must come back from the save, not survive in memory.
	for i in int(inventory.call("slot_count")):
		inventory.call("set_slot", i, null)
	if not bool(game.call("load_game", 0)):
		failures.append("RELOAD %s: load_game(0) failed" % label)
		return false
	# Read what the save restored at once: nourishment drains in real time,
	# so reading after the world rebuild's settle frames drifts by a tick
	# (0.1 over 240 frames, local 7a0634a3 validation) without any defect.
	var members_after := _party_condition(party)
	var world: Node = (load(scene_path) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in 240:
		await physics_frame
	live["world"] = world
	live["player"] = world.get_node_or_null(^"Player")
	live["rig"] = get_first_node_in_group("camera_rig")
	var flags_after: Array = (progression.call("all_set") as Array).duplicate()
	flags_after.sort()
	var uids_after := _party_uids(party)
	var items_after := _inventory_totals(inventory)
	var lost: Array = []
	for flag: Variant in flags_before:
		if not flags_after.has(flag):
			lost.append(flag)
	var gained: Array = []
	for flag: Variant in flags_after:
		if not flags_before.has(flag):
			gained.append(flag)
	var player := live["player"] as Node3D
	print("RELOAD %s: flags %d -> %d (lost %s, gained %s); party %s -> %s; player at %s" % [label,
		flags_before.size(), flags_after.size(), str(lost), str(gained), str(uids_before), str(uids_after),
		str(player.global_position) if player != null else "NONE"])
	if not lost.is_empty():
		failures.append("RELOAD %s: flags lost across the reload: %s" % [label, str(lost)])
	print("RELOAD %s: inventory %s -> %s" % [label, JSON.stringify(items_before), JSON.stringify(items_after)])
	print("RELOAD %s: party condition %s -> %s" % [label, JSON.stringify(members_before), JSON.stringify(members_after)])
	if members_after != members_before:
		failures.append("RELOAD %s: party HP/fainted/level/XP/rest changed across the reload (%s -> %s)" % [label,
			JSON.stringify(members_before), JSON.stringify(members_after)])
	if items_after != items_before:
		failures.append("RELOAD %s: the carried inventory changed across the reload (%s -> %s)" % [label,
			JSON.stringify(items_before), JSON.stringify(items_after)])
	if uids_after != uids_before:
		failures.append("RELOAD %s: the party changed across the reload (%s -> %s)" % [label, str(uids_before), str(uids_after)])
	if player == null:
		failures.append("RELOAD %s: the rebuilt world has no Player" % label)
	return failures.is_empty()


## Recovery state per member, keyed by UID: HP (0.1 precision, as saved),
## max HP, fainted, level, XP, and the rest/feeding condition a camp night
## restores. F02#4's "recovery survives reload" compares this exactly.
func _refind_camp(camp: RefCounted, bed_marks: Array, roll_mark: int) -> bool:
	var by_mark := {}
	for node: Node in (current_scene as Node).find_children("*", "", true, false):
		if node is Node3D and node.has_meta("placed_index"):
			by_mark[int(node.get_meta("placed_index"))] = node
	var beds: Array[Node3D] = []
	for mark: int in bed_marks:
		var bed := by_mark.get(mark) as Node3D
		if bed == null or not bed.has_method("build_index"):
			failures.append("RELOAD rested_team: placed creature bed %d did not come back from the save" % mark)
			return false
		beds.append(bed)
	var roll := by_mark.get(roll_mark) as Node3D
	if roll == null:
		failures.append("RELOAD rested_team: the placed bedroll did not come back from the save")
		return false
	camp.set("_beds", beds)
	camp.set("_bedroll", roll)
	print("RELOAD rested_team: camp re-found from the save (beds %s, bedroll %d)" % [str(bed_marks), roll_mark])
	return true


func _party_condition(party: RefCounted) -> Dictionary:
	var out := {}
	for i in int(party.call("size")):
		var member: RefCounted = party.call("at", i)
		if member == null:
			continue
		out[str(member.get("uid"))] = {"hp": snappedf(float(member.get("hp")), 0.1),
			"max_hp": snappedf(float(member.get("max_hp")), 0.1), "fainted": bool(member.get("fainted")),
			"level": int(member.get("level")), "xp": int(member.get("xp")),
			"rested": bool(member.get("rested")), "nourishment": snappedf(float(member.get("nourishment")), 0.1)}
	return out


func _inventory_totals(inventory: RefCounted) -> Dictionary:
	var totals := {}
	for i in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if not stack.is_empty():
			var id := str(stack.get("id", ""))
			totals[id] = int(totals.get(id, 0)) + int(stack.get("n", 0))
	return totals


func _party_uids(party: RefCounted) -> Array:
	var out: Array = []
	for i in int(party.call("size")):
		var member: Variant = party.call("at", i)
		if member != null:
			out.append(str((member as RefCounted).get("uid")))
	return out


func _finish(prefix_passed: bool) -> void:
	if finished:
		return
	finished = true
	if coverage != null:
		var coverage_result: Dictionary = coverage.stop()
		failures.append_array(coverage.failures)
		print("FRESH COVERAGE OBSERVATIONS %s" % JSON.stringify(coverage_result))
	if route_ledger != null:
		print("ROUTE LEDGER SUMMARY %s" % JSON.stringify(route_ledger.stop()))
	_stop_meadows_road_camera_alignment()
	print("FRESH CAMPAIGN RESULT %s" % JSON.stringify({
		"requested_prefix_passed": prefix_passed,
		"reached": reached,
		"campaign_complete": campaign_complete and failures.is_empty(),
		"resumed_from": resumed_from,
		"counts_as_proof": resumed_from.is_empty(),
		"scratch": scratch,
		"elapsed_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"failures": failures,
	}))
	quit(0 if prefix_passed and failures.is_empty() else 1)


## ROAD measurement-only camera alignment. The gameplay camera remains freely
## orbiting in production; this canonical continuous driver uses the ordinary
## look actions after the earned tournament so a road sample can honestly
## compare camera-forward with measured travel. No camera transform is assigned.
func _start_meadows_road_camera_alignment() -> void:
	if _measurement_camera_alignment:
		return
	_measurement_camera_alignment = true
	_measurement_previous = Vector3.INF
	if not physics_frame.is_connected(_align_meadows_camera_to_travel):
		physics_frame.connect(_align_meadows_camera_to_travel)


func _stop_meadows_road_camera_alignment() -> void:
	_measurement_camera_alignment = false
	_measurement_previous = Vector3.INF
	_release_measurement_look()
	if physics_frame.is_connected(_align_meadows_camera_to_travel):
		physics_frame.disconnect(_align_meadows_camera_to_travel)


func _align_meadows_camera_to_travel() -> void:
	if not _measurement_camera_alignment:
		return
	var scene := current_scene as Node3D
	var game := root.get_node_or_null("Game")
	if scene == null or game == null or str(game.get("current_realm")) != "meadows":
		_measurement_previous = Vector3.INF
		_release_measurement_look()
		return
	var player := scene.get_node_or_null("Player") as CharacterBody3D
	var rig := scene.get_node_or_null("CameraRig")
	var manager := scene.get_node_or_null("CombatManager")
	var director := scene.get_node_or_null("EncounterDirector")
	if player == null or rig == null or paused or INPUT_OWNER.current(self) != null \
			or (manager != null and manager.has_method("is_fighting") and manager.is_fighting()) \
			or (director != null and director.has_method("trainer_battle_active") \
				and director.trainer_battle_active()):
		_measurement_previous = Vector3.INF
		_release_measurement_look()
		return
	var at := player.global_position
	if not at.is_finite():
		_measurement_previous = Vector3.INF
		_release_measurement_look()
		return
	if not _measurement_previous.is_finite():
		_measurement_previous = at
		return
	var motion := at - _measurement_previous
	_measurement_previous = at
	motion.y = 0.0
	if motion.length_squared() < 0.0001:
		_release_measurement_look()
		return
	var heading := motion.normalized()
	var wanted_yaw := atan2(-heading.x, -heading.z)
	var yaw_error := angle_difference(float(rig.get("yaw")), wanted_yaw)
	if absf(rad_to_deg(yaw_error)) <= LOOK_ALIGNMENT_TOLERANCE_DEG:
		_release_measurement_look()
		return
	var action := &"look_left" if yaw_error > 0.0 else &"look_right"
	if _measurement_look_action != action:
		_release_measurement_look()
	_measurement_look_action = action
	Input.action_press(action, LOOK_ALIGNMENT_STRENGTH)


func _release_measurement_look() -> void:
	if not _measurement_look_action.is_empty():
		Input.action_release(_measurement_look_action)
		_measurement_look_action = StringName()
