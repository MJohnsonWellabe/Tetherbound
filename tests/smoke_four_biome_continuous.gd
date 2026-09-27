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
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const LOCAL_CHAINS := preload("res://tests/helpers/tidewake_b_local_chains.gd")
const WATER_DRY_FIXTURE := preload("res://tests/helpers/tidewake_b_water_arrival_dry_fixture.gd")
## Veilfall interior walk (relative to the interior origin), the same points
## the late segment walked from the entrance to Nerissa's chamber.
const VEILFALL_INTERIOR_PATH := [Vector3(0, 0, 4), Vector3(-5, 0, 18.9), Vector3(0, 0, 34),
	Vector3(9, 0, 45.9), Vector3(0, 0, 56), Vector3(0, 0, 70), Vector3(0, 0, 87)]
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const RESUME_SETTLE_FRAMES := 300
const LOOK_ALIGNMENT_TOLERANCE_DEG := 0.75
const LOOK_ALIGNMENT_STRENGTH := 0.65
var coverage: RefCounted
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
## Checkpoint boundaries (see tests/helpers/four_biome_checkpoints.gd).
var checkpoint_args: Dictionary = {}
var checkpoint_dir := ""
var resume_boundary := ""
var resume_info: Dictionary = {}
## Absolute path of the checkpoint this run resumed from; an export never overwrites it.
var resume_source_abs := ""
var carried_receipts: Dictionary = {}
var prior_elapsed_seconds := 0.0
var checkpoints_written: Array = []
## F13#3 (`--with-local-chains`): the six Tidewake local chains woven into the
## earned Water stage (tests/helpers/tidewake_b_local_chains.gd).
var local_chains: RefCounted = null
var chain_results: Array[String] = []
## `--dry-run-water-fixture`: DRY RUN start at a declared Water arrival.
var dry_run := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	var game := root.get_node("Game")
	checkpoint_args = CHECKPOINTS.parse_args(OS.get_cmdline_user_args())
	for line: Variant in checkpoint_args["errors"]:
		failures.append("CHECKPOINT ARGS: " + str(line))
	if not failures.is_empty():
		_finish(false)
		return
	checkpoint_dir = str(checkpoint_args["checkpoint_dir"])
	if checkpoint_dir.is_empty():
		checkpoint_dir = "user://four_biome_checkpoints_%d_%d" % [OS.get_process_id(), started_ms]
	scratch = "user://four_biome_fresh_%d_%d" % [OS.get_process_id(), started_ms]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(scratch)):
		failures.append("fresh scratch save already exists")
		_finish(false)
		return
	var resuming := not str(checkpoint_args["resume_source"]).is_empty()
	if OS.get_cmdline_user_args().has("--with-local-chains"):
		local_chains = LOCAL_CHAINS.new()
		local_chains.earned = true
	dry_run = OS.get_cmdline_user_args().has("--dry-run-water-fixture")
	if dry_run and resuming:
		failures.append("--dry-run-water-fixture cannot be combined with --resume-from")
		_finish(false)
		return
	# A resumed piece copies the checkpoint's save into its own scratch BEFORE
	# the save system is installed, so the checkpoint itself is never written.
	if resuming and not _stage_resume_files():
		_finish(false)
		return
	# Install before any title input, reset, world construction or autosave.
	game.set("save_system", SAVE.new(scratch))
	coverage = COVERAGE.new()
	if not coverage.start(self, "user://four_biome_coverage_%d_%d.jsonl" % [OS.get_process_id(), started_ms]):
		failures.append_array(coverage.failures)
		_finish(false)
		return
	print("FRESH CAMPAIGN scratch=%s slot=%s checkpoints=%s" % [ProjectSettings.globalize_path(scratch),
		game.get("save_system").call("slot_path", 0), ProjectSettings.globalize_path(checkpoint_dir)])
	var from := -1
	if dry_run:
		print("DRY RUN — does not count: declared Water-arrival fixture (%s), not an earned water_arrived save" %
			"tests/helpers/tidewake_b_water_arrival_dry_fixture.gd")
		live = await WATER_DRY_FIXTURE.new().start(self, game)
		if live.is_empty():
			failures.append("DRY RUN fixture: the Water world never became ready")
			_finish(false)
			return
		reached = "water_arrived (DRY RUN fixture)"
		from = CHECKPOINTS.boundary_index("water_arrived")
	elif resuming:
		if not await _resume_from_checkpoint(game):
			_finish(false)
			return
		from = CHECKPOINTS.boundary_index(resume_boundary)
	if from < 0 and not await _stage_fresh_through_hall(game):
		return
	if from < 1 and not await _stage_warden_to_cloudreach(game):
		return
	if from < 2 and not await _stage_cloudreach_to_stormwood(game):
		return
	if from < 3 and not await _stage_stormwood_to_water(game):
		return
	await _stage_water_to_ending(game)


## Each stage returns false once the run has finished (a failure, a requested
## --through-* prefix, or --stop-at), true to continue with the next stage.
func _stage_fresh_through_hall(game: Node) -> bool:
	var opening := OPENING.new()
	live = await opening.run(self)
	for line: Variant in live.get("failures", []):
		failures.append(str(line))
	if not bool(live.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	print("FRESH PREFIX: title through first live catch; no seeded progress, HP pinning or reload")
	reached = "opening"
	if OS.get_cmdline_user_args().has("--through-opening"):
		_finish(true)
		return false
	live = await opening.open_road_gate()
	for line: Variant in live.get("failures", []):
		failures.append(str(line))
	if not failures.is_empty():
		_finish(false)
		return false
	reached = "road_gate"
	var village_failures: Array[String] = await VILLAGE.new().run(self,
		live["world"], live["game"], live["player"], live["rig"])
	failures.append_array(village_failures)
	if not failures.is_empty():
		_finish(false)
		return false
	reached = "village"
	if OS.get_cmdline_user_args().has("--through-village"):
		_finish(true)
		return false
	var team_result: Dictionary = await TEAM.new().run(self, live["world"], game)
	for line: Variant in team_result.get("failures", []):
		failures.append(str(line))
	if not bool(team_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	reached = "earned_team"
	if OS.get_cmdline_user_args().has("--through-team"):
		_finish(true)
		return false
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
			return false
	reached = "paid_camp"
	if OS.get_cmdline_user_args().has("--through-camp"):
		_finish(true)
		return false
	print("FRESH STAGE ENTRY stage=rest frame=", Engine.get_physics_frames(), " player=", live["player"].global_position)
	var rest_result: Dictionary = await REST.new().run(self,
		live["world"], game, camp._beds, camp._bedroll, false)
	print("FRESH STAGE RETURN stage=rest frame=", Engine.get_physics_frames(), " player=", live["player"].global_position, " result=", JSON.stringify(rest_result))
	for line: Variant in rest_result.get("failures", []):
		failures.append(str(line))
	if not bool(rest_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	reached = "rested_team"
	if OS.get_cmdline_user_args().has("--through-rest"):
		_finish(true)
		return false
	var tournament_result: Dictionary = await TOURNAMENT.new().run(self,
		live["world"], game, live["player"], live["rig"])
	for line: Variant in tournament_result.get("failures", []):
		failures.append(str(line))
	if not bool(tournament_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	reached = "tournament_won"
	if OS.get_cmdline_user_args().has("--through-tournament"):
		_finish(true)
		return false
	_start_meadows_road_camera_alignment()
	var bridge_result: Dictionary = await BRIDGE.new().run(self, live["world"], game)
	for line: Variant in bridge_result.get("failures", []):
		failures.append(str(line))
	if not bool(bridge_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	reached = "south_bridge_crossed"
	if OS.get_cmdline_user_args().has("--through-bridge"):
		_finish(true)
		return false
	if not await _reload_transition(game, "south_bridge_crossed"):
		_finish(false)
		return false
	var warrens_result: Dictionary = await WARRENS.new().run(self, live["world"], game)
	for line: Variant in warrens_result.get("failures", []):
		failures.append(str(line))
	if not bool(warrens_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	reached = "warrens_cleared_and_exited"
	if OS.get_cmdline_user_args().has("--through-warrens"):
		_finish(true)
		return false
	if not await _reload_transition(game, "warrens_cleared_and_exited"):
		_finish(false)
		return false
	var relay_result: Dictionary = await RELAY.new().run(self, live["world"], game)
	for line: Variant in relay_result.get("failures", []):
		failures.append(str(line))
	if not bool(relay_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	reached = "relay_disabled_and_mill_crossed"
	if OS.get_cmdline_user_args().has("--through-relay"):
		_finish(true)
		return false
	if not await _reload_transition(game, "relay_disabled_and_mill_crossed"):
		_finish(false)
		return false
	var hall_result: Dictionary = await HALL.new().run(self, live["world"], game)
	for line: Variant in hall_result.get("failures", []):
		failures.append(str(line))
	if not bool(hall_result.get("passed", false)) or not failures.is_empty():
		_finish(false)
		return false
	reached = "warden_arena_entered"
	if not await _checkpoint_boundary(game, "hall"):
		return false
	if OS.get_cmdline_user_args().has("--through-hall"):
		_finish(true)
		return false
	if not await _reload_transition(game, "warden_arena_entered"):
		_finish(false)
		return false
	return true


func _stage_warden_to_cloudreach(game: Node) -> bool:
	if not _accepted(await WARDEN.new().run(self, live["world"], game), "passed"):
		return false
	live["world"] = current_scene
	reached = "cloudreach_arrived"
	if not await _checkpoint_boundary(game, "c1_arrival"):
		return false
	if OS.get_cmdline_user_args().has("--through-meadows"):
		_finish(true)
		return false
	return true


func _stage_cloudreach_to_stormwood(game: Node) -> bool:
	var cloudreach := CLOUDREACH.new()
	if not _accepted(await cloudreach.run(self, live["world"], game), "ok"):
		return false
	reached = "cloudreach_completed"
	if OS.get_cmdline_user_args().has("--through-cloudreach"):
		_finish(true)
		return false
	if not _accepted(await STORMWARD.new().run(self, cloudreach), "ok"):
		return false
	live["world"] = current_scene
	reached = "stormwood_arrived"
	return await _checkpoint_boundary(game, "stormwood_arrived")


func _stage_stormwood_to_water(game: Node) -> bool:
	var stormwood := STORMWOOD.Segment.new()
	if not _accepted(await stormwood.run(self, live["world"], game), "passed"):
		return false
	reached = "stormwood_arch_recipe_earned"
	if not _accepted(await CROWN.new().run(self, live["world"], game), "passed"):
		return false
	reached = "stormwood_paid_crown"
	if not _accepted(await ROOTGATE.new().run(self, live["world"], game), "passed"):
		return false
	reached = "stormwood_rootgate_released"
	if not _accepted(await DYNAMO.new().run(self, live["world"], game), "passed"):
		return false
	reached = "stormwood_dynamo_core_reached"
	if not _accepted(await MARROW.new().run(self, live["world"], game), "passed"):
		return false
	reached = "stormwood_marrow_and_core_released"
	if not _accepted(await WATERWARD.new().run(self, live["world"], game), "passed"):
		return false
	live["world"] = current_scene
	reached = "water_arrived"
	return await _checkpoint_boundary(game, "water_arrived")


func _stage_water_to_ending(game: Node) -> void:
	var water_opening := WATER_OPENING.new()
	if not _accepted(await water_opening.run(self, live["world"], game), "passed"):
		return
	live["player"] = water_opening.player
	live["rig"] = water_opening.camera
	reached = "water_pell_lesson_earned"
	# F13#3: Lantern (Pell, First Shore) right after the earned lesson.
	if not await _visit_local_chains(game, ["lantern"]):
		return
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
		# F13#3: Gull (Adair, Brine Steps) after the Brine trial; Cradle (Otto,
		# Tidal Cradle) after Tidal, before the swimmer preparation.
		if reached == "water_brine_trial_won" and not await _visit_local_chains(game, ["gull"]):
			return
		if reached == "water_swim_stone_and_recipe_earned" and not await _visit_local_chains(game, ["cradle"]):
			return
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
	# F13#3: Deep Watch (Orsen, Sluice; Tidecoil), Garden (Edda, Salt Crown)
	# and Lastlight (Halen, Veilfall) after Nerissa and the tether, before the
	# Guardian invitation (Edda/Orsen/Halen stop offering leads once the
	# ending restores the currents): leave the Veilfall interior by its own
	# prompt, ride the earned saddled swimmer between islands, walk back in.
	if local_chains != null and not await _veilfall_out_and_back(game, preparation.swimmer):
		return
	if not _accepted(await WATER_ENDING.new().run_earned(self, live["world"], game), "ok"):
		return
	reached = "tidewake_ending_earned"
	if local_chains != null and not await _saved_chain_completion(game):
		return
	# A DRY RUN (declared Water fixture) never counts as a completed campaign.
	campaign_complete = not dry_run
	_finish(true)


## F13#3 hook: plays `names` from wherever the earned segment left the
## trainer, then (return_home) walks/swims/rides back by input to that island
## and position so the next earned segment's own entry conditions are
## unchanged. A no-op without `--with-local-chains`.
func _visit_local_chains(game: Node, names: Array, return_home: bool = true) -> bool:
	if local_chains == null:
		return true
	var world := live["world"] as Node3D
	if local_chains.world != world and not local_chains.bind(self, world, true):
		return _chain_failed()
	var player := local_chains.player as Node3D
	var home: Vector3 = player.global_position
	var home_island: String = local_chains._here()
	print("F13#3 VISIT %s from %s on %s (party=%s)" % [names, home, home_island, JSON.stringify(_party_rows(game.get("party")))])
	for chain: String in names:
		var line: String = await local_chains.run_chain(chain)
		chain_results.append(line)
		print("F13#3 " + line)
		if not LOCAL_CHAINS.passed(line):
			return _chain_failed()
	if return_home:
		if not await local_chains._go(home, 1.5, "return after " + ",".join(names)):
			return _chain_failed()
		if local_chains._here() != home_island:
			local_chains._check(false, "returned to island %s, not %s" % [local_chains._here(), home_island])
			return _chain_failed()
		print("F13#3 returned to %s on %s after %s" % [player.global_position, home_island, names])
	local_chains._stick(0.0, 0.0)
	await local_chains._frames(30)
	return true


func _chain_failed() -> bool:
	for line: String in local_chains.failures:
		failures.append("F13#3 " + line)
	if local_chains.failures.is_empty():
		failures.append("F13#3 chain visit failed")
	for line: String in chain_results:
		print("F13#3 " + line)
	local_chains.print_travel_log()
	_finish(false)
	return false


## After the late segment: the same five, the swimmer deployed, inside the
## Veilfall interior. Walk the interior back to its exit prompt, Interact, play
## the three late chains riding the earned swimmer, walk to the entrance
## prompt, Interact, and walk the interior to Nerissa's chamber again.
func _veilfall_out_and_back(game: Node, swimmer: RefCounted) -> bool:
	var world := live["world"] as Node3D
	if local_chains.world != world and not local_chains.bind(self, world, true):
		return _chain_failed()
	local_chains.mount = swimmer
	local_chains.last_island = "veilfall"
	var cave := world.get_node_or_null("WaterVeilfall")
	var player := local_chains.player as CharacterBody3D
	if cave == null or not bool(cave.call("contains_interior", player.global_position)):
		local_chains._check(false, "late Water did not end inside the Veilfall interior")
		return _chain_failed()
	var origin: Vector3 = (cave.get("interior") as Node3D).global_position
	var inside: Array = VEILFALL_INTERIOR_PATH.duplicate()
	inside.reverse()
	for point: Vector3 in inside:
		if not await local_chains.navigator.walk_to(origin + point, 2400, 1.5):
			local_chains._check(false, "Veilfall interior walk out stalled at %s toward %s" % [player.global_position, origin + point])
			return _chain_failed()
	var exit_prompt: Node3D = cave.get("_exit_prompt")
	if not local_chains._check(await local_chains._approach_prompt(exit_prompt, exit_prompt.global_position),
			"Veilfall exit prompt offered (winner=%s)" % local_chains.arbiter.call("prompt")):
		return _chain_failed()
	await local_chains._press_interact()
	await local_chains._frames(30)
	if not local_chains._check(not bool(cave.call("contains_interior", player.global_position)),
			"Interact on the exit prompt left the Veilfall interior"):
		return _chain_failed()
	print("F13#3 left the Veilfall interior at %s island=%s" % [player.global_position, local_chains._here()])
	if not await _visit_local_chains(game, ["deep", "garden", "lastlight"], false):
		return false
	var entry_prompt: Node3D = cave.get("_entry_prompt")
	if not await local_chains._go(entry_prompt.global_position, 2.5, "Veilfall entrance"):
		return _chain_failed()
	if not local_chains._check(await local_chains._approach_prompt(entry_prompt, entry_prompt.global_position),
			"Veilfall entrance prompt offered (winner=%s)" % local_chains.arbiter.call("prompt")):
		return _chain_failed()
	await local_chains._press_interact()
	await local_chains._frames(30)
	if not local_chains._check(bool(cave.call("contains_interior", player.global_position)),
			"Interact on the entrance prompt entered the Veilfall interior"):
		return _chain_failed()
	for point: Vector3 in VEILFALL_INTERIOR_PATH:
		if not await local_chains.navigator.walk_to(origin + point, 2400, 1.5):
			local_chains._check(false, "Veilfall interior walk in stalled at %s toward %s" % [player.global_position, origin + point])
			return _chain_failed()
	local_chains._stick(0.0, 0.0)
	await local_chains._frames(30)
	return true


## F13#3 saved completion: after the ending, one production save -> reset ->
## load -> rebuilt Water world (tests/helpers/water_chain_reload.gd); every
## chain's records, receipts, quest-log `done` and carried rewards are
## re-asserted and each requester greeted again by walk + Interact.
func _saved_chain_completion(game: Node) -> bool:
	var reload: GDScript = load("res://tests/helpers/water_chain_reload.gd")
	var items := {}
	for item: String in ["skill_candy_i", "skill_candy_ii", "skill_candy_iii", "berries", "reef_stone"]:
		items[item] = game.inventory.count(item)
	var reloaded: Dictionary = await reload.save_and_reload(self, game, live["world"],
		"water_claim:local:lantern_return:complete", "")
	for pair: Array in reloaded.checks:
		local_chains._check(pair[0], "Reload: " + str(pair[1]))
	if reloaded.world == null:
		return _chain_failed()
	live["world"] = reloaded.world
	if not local_chains.bind(self, reloaded.world, true):
		return _chain_failed()
	live["player"] = local_chains.player
	live["rig"] = local_chains.camera
	await local_chains._frames(60)
	chain_results.append_array(await local_chains.verify_saved(PackedStringArray(LOCAL_CHAINS.CHAINS), items))
	for line: String in chain_results:
		print("F13#3 " + line)
	local_chains.print_travel_log()
	print("F13#3 %s: %d checks, %d failures" % ["DRY RUN — does not count" if dry_run else "local chains",
		local_chains.checks, local_chains.failures.size()])
	if not local_chains.failures.is_empty():
		return _chain_failed()
	return true


## Checkpoint boundary: a production save (`Game.save_game`, the menu Save
## call) into the chain slot, exported in the earned_saves layout with a
## receipt. Explicitly requested checkpoints (--checkpoint-dir/--stop-at/
## --resume-from) fail the run when the save or export is refused; a default
## run only warns, so its pass/fail meaning is unchanged. Returns false when
## the run finished here (failure or --stop-at).
func _checkpoint_boundary(game: Node, boundary: String) -> bool:
	if bool(checkpoint_args.get("no_checkpoints", false)):
		return true
	var strict := bool(checkpoint_args.get("requested", false))
	var problem := ""
	var out := ""
	var receipt := {}
	if not bool(game.call("save_game", CHECKPOINTS.CHECKPOINT_SLOT)):
		problem = "Game.save_game(%d) refused at boundary %s" % [CHECKPOINTS.CHECKPOINT_SLOT, boundary]
	else:
		var elapsed := (Time.get_ticks_msec() - started_ms) / 1000.0
		var player := current_scene.get_node_or_null("Player") as Node3D if current_scene != null else null
		receipt = CHECKPOINTS.build_receipt(boundary, {
			"commit": CHECKPOINTS.commit_sha(),
			"world_seed": int(game.get("world_seed")),
			"world_seed_env": OS.get_environment("TB_WORLD_SEED"),
			"elapsed_seconds": elapsed,
			"cumulative_elapsed_seconds": prior_elapsed_seconds + elapsed,
			"realm": str(game.get("current_realm")),
			"player": [player.global_position.x, player.global_position.y, player.global_position.z] if player != null else [],
			"game_day": int(game.get("day")) if game.get("day") != null else 0,
			"party": _party_rows(game.get("party")),
			"flags": (game.get("progression").call("all_set") as Array).duplicate(),
			"resumed_from": resume_info,
		})
		var target_abs := ProjectSettings.globalize_path(checkpoint_dir.path_join(boundary)).simplify_path()
		if not resume_source_abs.is_empty() and (target_abs == resume_source_abs or resume_source_abs.begins_with(target_abs + "/")):
			out = ""
			problem = "checkpoint export refused: target %s would overwrite the resume source %s (use a different --checkpoint-dir)" % [target_abs, resume_source_abs]
		else:
			out = CHECKPOINTS.export_checkpoint(scratch, checkpoint_dir, boundary, boundary, receipt, carried_receipts)
		if not problem.is_empty():
			pass  # refused above: never overwrite the checkpoint this run resumed from
		elif out.is_empty():
			problem = "checkpoint export to %s failed at boundary %s" % [checkpoint_dir, boundary]
		else:
			carried_receipts[boundary] = receipt
			checkpoints_written.append(ProjectSettings.globalize_path(out))
			print("FOUR BIOME CHECKPOINT %s" % JSON.stringify({"boundary": boundary, "dir": ProjectSettings.globalize_path(out),
				"commit": receipt["commit"], "world_seed": receipt["world_seed"], "elapsed_seconds": receipt["elapsed_seconds"],
				"party": receipt["party"], "flags_total": receipt["flags_total"]}))
	if not problem.is_empty():
		if strict:
			failures.append("CHECKPOINT " + problem)
			_finish(false)
			return false
		print("FOUR BIOME CHECKPOINT WARNING " + problem)
	if str(checkpoint_args.get("stop_at", "")) == boundary:
		print("FOUR BIOME CHECKPOINT stop-at %s reached" % boundary)
		_finish(true)
		return false
	return true


## Resolves --resume-from and copies its save into this run's fresh scratch.
func _stage_resume_files() -> bool:
	var source := CHECKPOINTS.resolve_source(str(checkpoint_args["resume_source"]), checkpoint_dir)
	if source.is_empty():
		failures.append("RESUME: no checkpoint with a save/ at '%s' (as a dir, under %s, or under %s)" % [
			checkpoint_args["resume_source"], checkpoint_dir, CHECKPOINTS.FIXTURE_ROOT])
		return false
	resume_source_abs = ProjectSettings.globalize_path(source).simplify_path()
	resume_boundary = CHECKPOINTS.pick_boundary(source, str(checkpoint_args["resume_boundary"]))
	if resume_boundary.is_empty():
		failures.append("RESUME: %s has no receipt for boundary '%s' (known: %s)" % [source,
			checkpoint_args["resume_boundary"], ", ".join(CHECKPOINTS.boundary_names())])
		return false
	var stop_at := str(checkpoint_args["stop_at"])
	if not stop_at.is_empty() and CHECKPOINTS.boundary_index(stop_at) < CHECKPOINTS.boundary_index(resume_boundary):
		failures.append("RESUME: --stop-at=%s is before the resumed boundary %s" % [stop_at, resume_boundary])
		return false
	carried_receipts = CHECKPOINTS.read_all_receipts(source)
	var receipt: Dictionary = carried_receipts.get(resume_boundary, {})
	if receipt.has("cumulative_elapsed_seconds"):
		prior_elapsed_seconds = float(receipt["cumulative_elapsed_seconds"])
	else:
		for other: Variant in carried_receipts.values():
			prior_elapsed_seconds += float((other as Dictionary).get("wall_seconds", 0.0))
	resume_info = {"source": source, "boundary": resume_boundary,
		"source_commit": str(receipt.get("commit", "")), "source_kind": str(receipt.get("kind", "earned_chain_runner"))}
	if not CHECKPOINTS.copy_tree(source.path_join("save"), scratch):
		failures.append("RESUME: could not copy %s/save into %s" % [source, scratch])
		return false
	print("RESUME staged %s at boundary %s (next segment %s) into %s" % [source, resume_boundary,
		CHECKPOINTS.next_segment(resume_boundary), ProjectSettings.globalize_path(scratch)])
	return true


## Loads the staged checkpoint through the production title's Load list (the
## same path as tools/earned_saves/earned_chain_runner.gd), then refuses the
## resume unless the loaded party and flags match the receipt.
func _resume_from_checkpoint(game: Node) -> bool:
	if not bool(game.call("has_save", CHECKPOINTS.CHECKPOINT_SLOT)):
		failures.append("RESUME: the staged checkpoint has no slot %d save" % CHECKPOINTS.CHECKPOINT_SLOT)
		return false
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10:
		await process_frame
	var load_button := title.get("_load_button") as Button
	if load_button == null:
		failures.append("RESUME: the production title has no Load button")
		return false
	load_button.pressed.emit()
	await process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Save %d" % CHECKPOINTS.CHECKPOINT_SLOT) \
				and not (node as Button).disabled:
			chosen = node
	if chosen == null:
		failures.append("RESUME: the title's Load list does not offer Save %d" % CHECKPOINTS.CHECKPOINT_SLOT)
		return false
	chosen.pressed.emit()
	var world: Node = null
	for _frame in 3600:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and is_instance_valid(scene) \
				and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() \
				and bool(game.call("_realm_scene_ready", scene, str(game.get("current_realm")))):
			world = scene
			break
	if world == null:
		failures.append("RESUME: the loaded checkpoint never reached a ready world scene")
		return false
	for _i in RESUME_SETTLE_FRAMES:
		await physics_frame
	for _i in 600:
		if INPUT_OWNER.current(self) == null:
			break
		await process_frame
	var receipt: Dictionary = carried_receipts.get(resume_boundary, {})
	var loaded_flags: Array = (game.get("progression").call("all_set") as Array).duplicate()
	var problems := CHECKPOINTS.validate(receipt, resume_boundary, _party_uids(game.get("party")), loaded_flags)
	var want_seed := int(receipt.get("world_seed", receipt.get("saved_world_seed", 0)))
	if want_seed != 0 and want_seed != int(game.get("world_seed")):
		problems.append("loaded world seed %d does not match the receipt's %d" % [int(game.get("world_seed")), want_seed])
	if not problems.is_empty():
		for line: Variant in problems:
			failures.append("RESUME REFUSED: " + str(line))
		return false
	live = {"world": world, "game": game, "player": world.get_node_or_null(^"Player"),
		"rig": get_first_node_in_group("camera_rig")}
	reached = CHECKPOINTS.reached_label(resume_boundary)
	print("RESUME VERIFIED boundary=%s realm=%s player=%s party=%s flags=%d seed=%d" % [resume_boundary,
		game.get("current_realm"), (live["player"] as Node3D).global_position, JSON.stringify(_party_rows(game.get("party"))),
		loaded_flags.size(), int(game.get("world_seed"))])
	# The fresh run's ROAD camera alignment is on from the tournament onward
	# while in the Meadows; keep a Meadows-resumed piece measuring the same way.
	if CHECKPOINTS.boundary_index(resume_boundary) == 0:
		_start_meadows_road_camera_alignment()
	# `--stop-at` the resumed boundary itself: re-export this verified load
	# through a fresh production save (write/resume round trip) and stop.
	if str(checkpoint_args["stop_at"]) == resume_boundary:
		await _checkpoint_boundary(game, resume_boundary)
		return false
	return true


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
	var scene_path := str(current_scene.scene_file_path)
	if not bool(game.call("save_game", 0)):
		failures.append("RELOAD %s: save_game(0) refused" % label)
		return false
	var old := current_scene
	old.queue_free()
	for i in 4:
		await process_frame
	progression.call("load_data", {})
	party.call("clear")
	if not bool(game.call("load_game", 0)):
		failures.append("RELOAD %s: load_game(0) failed" % label)
		return false
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
	if uids_after != uids_before:
		failures.append("RELOAD %s: the party changed across the reload (%s -> %s)" % [label, str(uids_before), str(uids_after)])
	if player == null:
		failures.append("RELOAD %s: the rebuilt world has no Player" % label)
	return failures.is_empty()


func _party_uids(party: RefCounted) -> Array:
	var out: Array = []
	for i in int(party.call("size")):
		var member: Variant = party.call("at", i)
		if member != null:
			out.append(str((member as RefCounted).get("uid")))
	return out


func _party_rows(party: RefCounted) -> Array:
	var out: Array = []
	if party == null:
		return out
	for i in int(party.call("size")):
		var member := party.call("at", i) as RefCounted
		if member != null:
			out.append({"uid": str(member.get("uid")), "species": str(member.get("species_id")),
				"level": int(member.get("level")), "nickname": str(member.get("nickname"))})
	return out


func _finish(prefix_passed: bool) -> void:
	if finished:
		return
	finished = true
	if coverage != null:
		var coverage_result: Dictionary = coverage.stop()
		failures.append_array(coverage.failures)
		print("FRESH COVERAGE OBSERVATIONS %s" % JSON.stringify(coverage_result))
	_stop_meadows_road_camera_alignment()
	print("FRESH CAMPAIGN RESULT %s" % JSON.stringify({
		"requested_prefix_passed": prefix_passed,
		"reached": reached,
		"campaign_complete": campaign_complete and failures.is_empty(),
		"scratch": scratch,
		"elapsed_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"cumulative_elapsed_seconds": prior_elapsed_seconds + (Time.get_ticks_msec() - started_ms) / 1000.0,
		"resumed_from": resume_info,
		"dry_run": dry_run,
		"local_chains": chain_results,
		"checkpoints": checkpoints_written,
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
