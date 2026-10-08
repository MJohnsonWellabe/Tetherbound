extends RefCounted

## F49 ordinary-input composition. No fixtures, grants, pose writes or direct
## transaction calls. Existing helpers retain their disclosed simulation clocks;
## their elapsed time never supplies owner play or hardware performance proof.
const ORDER := preload("res://scripts/data/biome_order.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
# Reuse F20's ordinary dual-clock input, personal lesson reader and authored
# Hall approach. It extends the F49 travel checks; no fixture setup is used.
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const WARDEN := preload("res://tests/helpers/f49_warden_finale.gd")
const CLOUD := preload("res://tests/helpers/f49_cloudreach_chapter.gd")
const STORM_SETTLEMENT := preload("res://tests/helpers/f49_stormheart_settlement.gd")
const REQUIRED_FLAGS := ["redesign_portal_runtime_enabled", "redesign_boss_handoff_runtime_enabled", "redesign_ending_runtime_enabled"]
var driver: SceneTree
var game: Node
var travel: RefCounted
var disk: RefCounted
var visited: Array[String] = []
var resume_source := ""
var stop_boundary := ""
var resumed_boundary := ""
var segmented := false
var meadows_piece_prefix := false
var compatibility_paths: Array[String] = []
var observe_next_goal := false
var observe_lesson_reload := false
var generated_fixture_input := false

func run(owner: SceneTree) -> void:
	driver = owner
	driver.started_ms = Time.get_ticks_msec()
	game = driver.root.get_node("Game")
	# Legacy checkpoint labels embed the old order. Never accept them silently.
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--generated-fixture": generated_fixture_input = true
		if arg == "--observe-next-goal": observe_next_goal = true
		if arg.begins_with("--lesson-reload-witness"):
			if arg != "--lesson-reload-witness" or observe_lesson_reload:
				_fail("Lesson reload witness requires one valueless existing option")
				return
			observe_lesson_reload = true
		if arg.begins_with("--resume-from=") or arg.begins_with("--stop-at=") \
				or arg.begins_with("--checkpoint-dir=") or arg == "--dry-run-water-fixture" or arg == "--m4-finale":
			_fail("F49 refuses legacy resume/setup options; use --legacy-order-diagnostic for isolated debugging")
			return
		if arg.begins_with("--handoff-from="):
			if not resume_source.is_empty() or arg == "--handoff-from=":
				_fail("F49 accepts one nonempty segment source")
				return
			resume_source = arg.trim_prefix("--handoff-from=")
			segmented = true
		if arg == "--meadows-piece-prefix":
			meadows_piece_prefix = true
		if arg.begins_with("--compatibility-manifests="):
			if not compatibility_paths.is_empty() or arg == "--compatibility-manifests=":
				_fail("F49 accepts one nonempty explicit compatibility manifest list")
				return
			for path: String in arg.trim_prefix("--compatibility-manifests=").split(","):
				if path.strip_edges().is_empty():
					_fail("F49 compatibility manifest paths must be nonempty")
					return
				compatibility_paths.append(path)
		if arg.begins_with("--through-boundary="):
			if not stop_boundary.is_empty() or arg == "--through-boundary=":
				_fail("F49 accepts one nonempty segment stop")
				return
			stop_boundary = arg.trim_prefix("--through-boundary=")
			segmented = true
		if arg.begins_with("--world-seed="):
			var seed := arg.trim_prefix("--world-seed=")
			if not seed.is_valid_int():
				_fail("--world-seed must be an integer")
				return
			OS.set_environment("TB_WORLD_SEED", seed)
	if OS.get_cmdline_user_args().has("--capture-next-goal") and not observe_next_goal:
		_fail("Next-goal frames require the existing --observe-next-goal snapshots")
		return
	if observe_lesson_reload:
		var lesson_options := TRAVEL.lesson_witness_options()
		if not lesson_options.failures.is_empty() or not lesson_options.controller or not lesson_options.replay:
			_fail("Lesson reload observation requires naturally observed controller Skip and Settings Help")
			return
	if not compatibility_paths.is_empty() and resume_source.is_empty():
		_fail("F49 reviewed cut compatibility requires an actual imported prefix")
		return
	if generated_fixture_input and (resume_source.is_empty() or not meadows_piece_prefix or not compatibility_paths.is_empty()):
		_fail("Generated F49 chapter input requires an explicit portable fixture source and Meadows constructor")
		return
	if meadows_piece_prefix:
		if resume_source.is_empty():
			_fail("--meadows-piece-prefix requires an actual --handoff-from earned Hall or chapter prefix")
			return
		var requested := ProjectSettings.globalize_path(resume_source).simplify_path().trim_suffix("/").get_file()
		if requested != "hall" and not HANDOFF.BOUNDARIES.has(requested):
			_fail("F49 Meadows-piece continuation starts at Hall or a later chapter boundary")
			return
	if not stop_boundary.is_empty() and not HANDOFF.BOUNDARIES.has(stop_boundary):
		_fail("F49 segment stop must name a new-order chapter boundary")
		return
	if segmented:
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--through-") and not arg.begins_with("--through-boundary="):
				_fail("F49 chapter segments cannot be combined with opening prefix stops")
				return
		if OS.has_environment("TB_WORLD_SEED"):
			_fail("F49 chapter segments preserve the actual fresh population without seed overrides")
			return
	var session: Node = game.get("session")
	var config: Dictionary = session.call("config") if session != null and session.has_method("config") else {}
	for field: String in REQUIRED_FLAGS:
		if config.get(field) != true:
			_fail("F49 missing producer gate: multiplayer.json::session." + field + " remains OFF; ROOT must prove and enable the actual shared runtime")
			return
	if ORDER.runtime_ids() != ["meadows", "water", "cloudreach", "stormwood"]:
		_fail("F49 requires the authored Meadows/Tidewake/Cloudreach/Stormwood order")
		return
	driver.scratch = "user://f49_campaign_%d_%d" % [OS.get_process_id(), driver.started_ms]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(driver.scratch)):
		_fail("F49 scratch already exists; refusing overwrite")
		return
	game.set("save_system", SAVE.new(driver.scratch))
	driver.checkpoint_args = {"no_checkpoints": true}
	driver.coverage = driver.COVERAGE.new()
	if not driver.coverage.start(driver, driver.scratch + "_coverage.jsonl"):
		_fail("F49 road coverage observer could not start")
		return
	driver.route_ledger = driver.ROUTE_LEDGER.new()
	if not driver.route_ledger.start(driver, func() -> String: return driver.reached, driver.scratch + "_ledger.jsonl"):
		_fail("F49 M2 resource/route observer could not start")
		return
	if OS.get_cmdline_user_args().has("--fight-log") or OS.get_cmdline_user_args().has("--aftermath-capture"):
		driver.fight_log = (load("res://tests/helpers/meadows_earned_fight_log_segment.gd") as GDScript).new(
			OS.get_cmdline_user_args().has("--aftermath-capture"))
		driver.root.add_child(driver.fight_log)
	driver.local_chains = driver.LOCAL_CHAINS.new()
	driver.local_chains.earned = true
	travel = TRAVEL.new(driver, game)
	if meadows_piece_prefix:
		disk = HANDOFF.new(driver, game, driver.scratch + "_handoffs",
			HANDOFF.MEADOWS_PIECES + HANDOFF.BOUNDARIES, HANDOFF.MEADOWS_REALMS + HANDOFF.REALMS, HANDOFF.MEADOWS_SLOT)
	else:
		disk = HANDOFF.new(driver, game, driver.scratch + "_handoffs")
	if not disk.configure_compatibility(compatibility_paths):
		_failures(disk.failures)
		return
	var from := -1
	if not resume_source.is_empty():
		resumed_boundary = disk.import_prefix(resume_source, "generated_fixture" if generated_fixture_input else "earned")
		if resumed_boundary.is_empty():
			_failures(disk.failures)
			return
		from = HANDOFF.BOUNDARIES.find(resumed_boundary)
		if not stop_boundary.is_empty() and HANDOFF.BOUNDARIES.find(stop_boundary) <= from:
			_fail("F49 segment must advance beyond its imported boundary")
			return
		if not await disk.reload_boundary(resumed_boundary, travel):
			_failures(disk.failures)
			return
		if not await _goal_witness(resumed_boundary, "after_import_load"): return
		driver.live = {"world": driver.current_scene, "game": game,
			"player": driver.current_scene.get_node_or_null("Player"),
			"rig": driver.current_scene.get_node_or_null("CameraRig")}
		driver.reached = resumed_boundary
		driver.resume_boundary = resumed_boundary
		driver.resume_info = {"source": resume_source, "boundary": resumed_boundary,
			"source_kind": "f49_hash_linked_production_prefix", "journey_id": disk.journey_id}
		if meadows_piece_prefix:
			driver.resume_info.source_kind = "f49_complete_meadows_piece_and_chapter_prefix"
			driver.resume_info.meadows_pieces = (HANDOFF.MEADOWS_PREPARED_PIECES \
				if disk.boundaries.has("relay_prepared") else HANDOFF.MEADOWS_PIECES).duplicate()
		if generated_fixture_input:
			driver.resume_info.source_kind = "generated_fixture"
			driver.resume_info.generated_origin = disk.generated_origin.duplicate(true)
			driver.resume_info.prior_earned_play = false
			driver.resume_info.continuous_fresh_save = false
		for index in from + 1: visited.append(["meadows", "tidewake", "cloudreach", "stormwood"][index])
	if from < 0:
		# A resumed Hall was earned, saved and loaded with its complete prefix.
		# Its real arena stance and unbeaten Warden are still checked by finale.
		if resumed_boundary != "hall" and not await driver._stage_fresh_through_hall(game): return
		visited.append("meadows")
		if not driver._accepted(await WARDEN.new().run_finale(driver, driver.current_scene, game), "passed"): return
		if not await _boundary("meadows_settled"): return
	if from < 1:
		if not await travel.home_key():
			_failures(travel.failures)
			return
		if OS.get_cmdline_user_args().has("--lesson-replay-witness") and not await _first_key_lessons(): return
		if not await travel.hang_relic("meadows") or not await travel.enter("tidewake", "water"):
			_failures(travel.failures)
			return
		visited.append("tidewake")
		if not await _goal_witness("tidewake", "after_portal_arrival"): return
		driver.live["world"] = driver.current_scene
		var tidewake_party_uids := _dock_party_uids()
		if tidewake_party_uids.size() != 5:
			_fail("F49 Tidewake requires the five carried from Meadows")
			return
		await driver._stage_water_to_ending(game, true)
		if driver.finished or not driver.failures.is_empty(): return
		if driver.reached != "tidewake_ending_earned":
			_fail("F49 Tidewake did not settle its real chapter")
			return
		if _dock_party_uids() != tidewake_party_uids:
			_fail("F49 Tidewake replaced or reordered the five carried from Meadows")
			return
		if not await _dock_conclusion_available(): return
		if not await _boundary("tidewake_settled"): return
		if not _dock_saved():
			_fail("F49 Tidewake departure lost its actual world conclusion or owner receipt on disk reload")
			return
	if from < 2:
		if not await travel.home_key() or not await travel.hang_relic("tidewake") or not await travel.enter("cloudreach", "cloudreach"):
			_failures(travel.failures)
			return
		visited.append("cloudreach")
		if not await _goal_witness("cloudreach", "after_portal_arrival"): return
		if not driver._accepted(await CLOUD.new().run(driver, driver.current_scene, game), "ok"): return
		if not await _boundary("cloudreach_settled"): return
	if from < 3:
		if not await travel.home_key() or not await travel.hang_relic("cloudreach") or not await travel.enter("stormwood", "stormwood"):
			_failures(travel.failures)
			return
		visited.append("stormwood")
		if not await _goal_witness("stormwood", "after_portal_arrival"): return
		for helper: GDScript in [driver.STORMWOOD, driver.CROWN, driver.ROOTGATE, driver.DYNAMO, driver.MARROW]:
			var segment: RefCounted = driver.STORMWOOD.Segment.new() if helper == driver.STORMWOOD else helper.new()
			if not driver._accepted(await segment.run(driver, driver.current_scene, game), "passed"): return
		if not driver._accepted(await STORM_SETTLEMENT.new().run(driver, driver.current_scene, game), "passed"): return
		if HOME.journey_context(game).is_empty():
			_fail("F49 missing producer: accepted Stormheart outcome has no Game.regional_ending_context")
			return
		if not await _boundary("stormwood_settled"): return
	if from < 4:
		if not await travel.home_key() or not await travel.hang_relic("stormwood"):
			_failures(travel.failures)
			return
		if not await _goal_witness("homecoming", "after_home_arrival_and_relic"): return
		var grandpa: Node3D
		for node: Node in driver.current_scene.find_children("*", "", true, false):
			if node.has_method("interaction_offer") and node.get_parent().name == "Grandpa":
				grandpa = node as Node3D
		var dialogue: Node = driver.current_scene.get_node_or_null("DialoguePanel")
		if grandpa == null or dialogue == null or dialogue.call("is_open"):
			_fail("F49 homecoming approach requires the actual Grandpa prompt and closed dialogue")
			return
		# The existing approach walks the authored farmhouse doorway without X;
		# inherited homecoming then proves the exact provider's ordinary input.
		if not await travel.approach_grandpa(grandpa):
			_failures(travel.failures)
			return
		if dialogue.call("is_open"):
			_fail("F49 Grandpa dialogue opened before ordinary homecoming input")
			return
		if not await travel.grandpa_and_credits():
			_failures(travel.failures)
			return
		visited.append("homecoming_credits")
		if not await _boundary("completed_world", false): return
	if not await disk.reload_completed(travel):
		_failures(disk.failures)
		return
	if not await _goal_witness("completed_world", "after_completed_reload"): return
	driver.reached = "completed_world_continuation"
	driver.campaign_complete = not segmented
	if segmented: _segment_result("completed_world", true)
	print("F49 JOURNEY " + JSON.stringify({"order": visited, "shortcuts": ["agent emits ordinary actions", "declines pending legendaries to retain the earned five", "production saves copied to immutable handoffs", "credits skipped by controller after their actual opening", "inherited helpers retain their original simulation clocks; wall time is not owner/device timing"], "legacy_cards": {"M2": "same-route ledger/reloads; two-loss/four-character proof queued separately", "M3": "fight/optional activity/visual proof remains separate", "T2": "same-route six chains; island/fight/art/four-character proof remains separate", "S2": "storm/fight/activity/visual proof remains separate"}, "owner_play": "pending", "ally_hardware": "pending", "published_download": "pending"}))
	driver._finish(true)

## Optional F46 witness begins only after the earned Warden's actual key and
## relic and completed Home Key. Installed Tam teaches both due cards; the
## existing reader retains each card before replaying it through Settings.
func _first_key_lessons() -> bool:
	var rules := preload("res://scripts/onboarding/lesson_rules.gd")
	var options := TRAVEL.lesson_witness_options()
	if not options.failures.is_empty() or not options.controller or not travel._bind():
		_fail("First key lessons require the existing controller/replay options and free world input")
		return false
	var teacher := driver.current_scene.find_child("Tam", true, false) as Node3D
	var cid := str(game.local.character_id)
	var retained: Array[String] = travel._uids()
	for id: String in ["portals", "shrines"]:
		if not rules.available(id, game.local) or game.local.flags.call("has", rules.PREFIX + id):
			_fail("Earned first key/relic must naturally unlock its still-unacknowledged " + id + " lesson")
			return false
	if teacher == null:
		_fail("Earned first key return lacks installed Tam")
		return false
	var player := game.call("find_player") as CharacterBody3D
	var rig := driver.current_scene.get_node_or_null("CameraRig") as Node3D
	var nav := preload("res://tests/helpers/stick_navigator.gd").new(driver, player, rig, Callable(travel, "_stick"))
	var recoveries_before := int(player.get("_unstick_count"))
	var approach := func() -> bool:
		var budget := maxi(1200, int(player.global_position.distance_to(teacher.global_position) * 65.0))
		var arrived: bool = await nav.walk_to(teacher.global_position, budget, 3.5)
		travel.call("_stick", 0.0, 0.0)
		for frame: int in 180:
			if game.local.flags.call("has", rules.PREFIX + "portals") \
					and game.local.flags.call("has", rules.PREFIX + "shrines"): break
			await driver.physics_frame
		return arrived and player.is_on_floor() and int(player.get("_unstick_count")) == recoveries_before \
			and player.global_position.distance_to(teacher.global_position) <= 5.0
	if not await travel._with_navigation_lessons(approach):
		_failures(travel.failures)
		return false
	for id: String in ["portals", "shrines"]:
		if not await travel.replay_observed_lesson(id):
			_failures(travel.failures)
			return false
	if str(game.local.character_id) != cid or travel._uids() != retained or not travel._ready_world("meadows"):
		_fail("First key lesson Skip/Help replay changed the earned character, five or free ready world")
		return false
	print("F46 FIRST KEY LESSONS " + JSON.stringify({"character_id":cid,"party_uids":retained,
		"lessons":["portals","shrines"],"earned_warden_key_and_relic":true,
		"physical_skip_and_help":true,"whole_f46_proven":false}))
	return true

func _goal_witness(gate: String, phase: String) -> bool:
	if not observe_next_goal: return true
	travel.observe_next_goal(gate, phase)
	if not await travel.capture_next_goal(gate, phase):
		_failures(travel.failures)
		return false
	return true

func _boundary(label: String, reload_disk: bool = true) -> bool:
	driver.reached = label
	if observe_next_goal: travel.observe_next_goal(label, "before_export")
	if not disk.export_boundary(label):
		_failures(disk.failures)
		return false
	if observe_next_goal: travel.observe_next_goal(label, "after_export")
	if reload_disk:
		var observed: Dictionary = travel.observed_lesson_history() if observe_lesson_reload else {}
		var reopened: Array[String] = []
		var watch := func() -> void:
			var service := game.get_node_or_null("OnboardingLessons")
			var panel: Node = service.get("_panel") if service != null else null
			if is_instance_valid(panel) and panel.call("is_open") and service.get("_replaying") == false:
				var id := str(panel.get("_row").get("id", ""))
				if observed.has(id) and not reopened.has(id): reopened.append(id)
		if not observed.is_empty(): driver.process_frame.connect(watch)
		var loaded: bool = await disk.reload_boundary(label, travel)
		if loaded and not observed.is_empty():
			# Same observation window as the existing Home Key disk witness.
			# No dismissals, input or service/flag writes can conceal a reopen.
			for frame: int in 300: await driver.process_frame
		if not observed.is_empty(): driver.process_frame.disconnect(watch)
		if not loaded:
			_failures(disk.failures)
			return false
		if not observed.is_empty():
			var retained := reopened.is_empty()
			for id: String in observed:
				retained = retained and str(game.local.character_id) == observed[id].character_id \
					and travel._uids() == observed[id].party_uids \
					and game.local.flags.call("has", "opening:lesson:" + id) == true
			var service := game.get_node_or_null("OnboardingLessons")
			retained = retained and service != null and service.get("_identity") == str(game.local.character_id) \
				and (service.get("_pending") as Dictionary).is_empty() and not driver.paused \
				and travel._ready_world(str(game.current_realm))
			print("F46 EARNED LESSON RELOAD " + JSON.stringify({"boundary":label,"observed":observed,
				"reopened":reopened,"settle_frames":300,"passed":retained,
				"scope":"Actual existing disk Load retains only naturally observed personal acknowledgements; teacher return and whole F46 remain open"}))
			if not retained:
				_fail("Existing earned boundary Load lost or naturally reopened this character's observed lesson")
				return false
	if reload_disk and not await _goal_witness(label, "after_boundary_reload"): return false
	if label == "tidewake_settled" and not _dock_saved():
		_fail("F49 Tidewake segment lost its saved conclusion on production reload")
		return false
	if segmented and label == stop_boundary and label != "completed_world":
		_segment_result(label, false)
		driver._finish(true)
		return false
	return true

func _segment_result(label: String, completed: bool) -> void:
	print("F49 SEGMENT RESULT " + JSON.stringify({"kind": "f49_generated_fixture_segment" if generated_fixture_input else "f49_earned_segment",
		"input_mode":"generated_fixture" if generated_fixture_input else "earned",
		"generated_origin":disk.generated_origin,"prior_earned_play":false if generated_fixture_input else null,
		"journey_id": disk.journey_id, "commit": disk.source_commit,
		"from_boundary": resumed_boundary, "through_boundary": label,
		"predecessors": disk.history, "visited": visited,
		"completed_world_reloaded": completed, "counts_as_uninterrupted_proof": false}))

func _fail(message: String) -> void:
	driver.failures.append(message)
	driver._finish(false)

func _failures(lines: Array) -> void:
	for line: Variant in lines: driver.failures.append(str(line))
	if lines.is_empty(): driver.failures.append("F49 continuation failed without a producer receipt")
	driver._finish(false)

func _dock_conclusion_available() -> bool:
	var chains: RefCounted = driver.local_chains
	var world := driver.current_scene as Node3D
	var cave := world.get_node_or_null("WaterVeilfall")
	if chains == null or cave == null or not chains.continuous \
		or not chains.earned or not cave.call("contains_interior", chains.player.global_position):
		_fail("F49 dock continuation requires earned continuous travel and the actual Veilfall chamber")
		return false
	var party_before := _dock_party_uids()
	var origin: Vector3 = cave.get("interior").global_position
	var interior: Array = driver.VEILFALL_INTERIOR_PATH.duplicate()
	interior.reverse()
	for point: Vector3 in interior:
		if not await chains.navigator.walk_to(origin + point, 2400, 1.5):
			_fail("F49 ordinary Veilfall exit walk stalled")
			return false
	var exit_prompt: Node3D = cave.get("_exit_prompt")
	if not await chains._approach_prompt(exit_prompt, exit_prompt.global_position):
		_fail("F49 actual Veilfall exit provider did not own Interact")
		return false
	await chains._press_interact()
	await chains._frames(30)
	if cave.call("contains_interior", chains.player.global_position):
		_fail("F49 ordinary exit input did not leave Veilfall")
		return false
	chains.last_island = "veilfall"
	# _talk uses the existing continuous human-swim island path, ground
	# navigator, exact NPC provider and Interact-driven natural completion.
	var heard: Array = await chains._talk("water_mara")
	if heard.is_empty() or heard[0] != "water_mara_post" or not chains.failures.is_empty():
		_failures(chains.failures)
		return false
	var chapter := world.get_node_or_null("WaterChapter")
	var prompt: Node3D = chapter.get("_dock_prompt") if chapter != null else null
	if prompt == null or not await chains._approach_prompt(prompt, prompt.global_position):
		_fail("F49 civilian departure provider did not own ordinary Interact after Mara's afterword")
		return false
	await chains._press_interact()
	for frame in 600:
		if _dock_saved():
			if _dock_party_uids() != party_before:
				_fail("F49 dock continuation replaced the earned party")
				return false
			return true
		await driver.physics_frame
	_fail("F49 actual dock handoff did not settle its saved world and owner receipt")
	return false

func _dock_party_uids() -> Array[String]:
	var uids: Array[String] = []
	for member: RefCounted in game.party.members(): uids.append(str(member.get("uid")))
	return uids

func _dock_saved() -> bool:
	var receipt: String = "craft:water_dock_departure:" + str(game.local.character_id)
	var row: Dictionary = game.session.call("_owner_training_row")
	var decision: Dictionary = game.session.call("_training_decision", game.session.call("local_peer_id"), row)
	return decision.get("ok") == true and decision.get("saved") == true \
		and row.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).has(receipt) \
		and game.world.flags.has("water_civilian_departure_complete") \
		and game.local.redesign_character.transaction_receipts.has(receipt)
