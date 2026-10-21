extends SceneTree

## Earned Meadows pieces, one ordinary-input segment per process, through the
## Warden finale and the portal handoff to Tidewake. Obsolete physical Rift
## routes are explicit legacy diagnostics.
##
## WHAT IT IS
##   The same earned helpers the continuous driver
##   (`tests/smoke_four_biome_continuous.gd`) composes, cut at save boundaries.
##   Every segment either starts a FRESH game through the production title
##   (segment `opening_village`) or loads the previous segment's save through the
##   production title's Autosave entry (slot 0), runs one or more earned helpers
##   read-only, and on success writes that same slot through `Game.save_game()`.
##   This retains the actual fresh world's transaction ownership. No teleport,
##   flag/inventory/party write, HP pin or debug skip occurs during earned play.
##   Explicit --generated-fixture constructs a disclosed unearned input first;
##   its own segment then uses the same Load path and unchanged helpers.
##
## SEGMENTS (in order)
##   opening_village  fresh title -> first catch -> road gate -> village
##   opening_team     Load the earned village save -> catch five -> level five
##   camp_tournament  materials -> paid camp -> rest -> tournament (camp beds are
##                    live nodes the rest helper needs, so these share a process)
##   bridge           South Bridge grunt + crossing
##   warrens          Quarry / Burrow Warrens cleared and exited
##   relay            Tether relay disabled, Mill crossed
##   sigils           three Sigil captains, Sigil Gate crossed
##   hall             Hall gauntlet from the sigils save, Warden arena boundary
##   warden           new order: the Warden finale with no Rift
##                    (tests/helpers/f49_warden_finale.gd), declining the freed
##                    legendary so the earned five are retained.
##                    Legacy: Veridian ACCEPTED (warden_accept.gd), Rift -> Cloudreach
##   tidewake_handoff Home Key home, hang the Meadows relic, enter the Tidewake
##                    portal (tests/helpers/f49_portal_travel.gd); saved in Tidewake
##   kell_rift        (resume only) from the warden segment's village_pre_kell
##                    checkpoint: Kell, storm road, Rift -> Cloudreach
##
## USAGE
##   godot --headless --path . \
##     --script tools/earned_saves/earned_chain_runner.gd -- \
##     --segment=<id> --save-dir=<new-root>/<id>/save \
##     --receipt=<new-root>/<id>/receipt.json [--handoff-from=<prior-root>/<previous-id>]
##   Each new root must be absent. Resuming validates/copies the entire exact-
##   source prefix, then production title Load opens a separate writable copy.
##   Do not set TB_WORLD_SEED: the real fresh saved population is retained.
##   Legacy copied-save/run_chain.sh semantics require --legacy-order-diagnostic
##   and their old TB_WORLD_SEED; those outputs never satisfy the piece protocol.
##   --diagnostic: run from a dirty tree / across commits with the clean-tree and
##   lineage gates off. Every receipt, handoff and RESULT line is stamped
##   "DIAGNOSTIC, NOT EVIDENCE"; non-diagnostic imports, promote_f19.mjs and
##   assemble_fixture.py refuse it.
##   --compatibility-manifests=<a.json,...>: cross-commit handoff (WORKFLOW
##   §8.1 rule 9). Either the full reviewed-cut manifest (f49_reviewed_cross_cut)
##   or the light form {"kind":"f49_light_cut","from_sha":<producer>,
##   "to_sha":<this commit>,"piece":<this --segment>,"reviewer":"<name>"}: the
##   runner computes diff_stat and the touched paths from git and accepts the
##   cut only if no save-schema/encounter/route path (f49_disk_handoff
##   LIGHT_CUT_PATHS) changed; the result is recorded in the receipt.
##
## OUTPUT
##   The receipt JSON (flags gained, party, key items, location, wall/game time,
##   helper receipts) and the line `EARNED CHAIN RESULT {...}`. Exit 0 on pass.
const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
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
const WARDEN_FINALE := preload("res://tests/helpers/f49_warden_finale.gd")
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const OFFLOAD := preload("res://tests/helpers/f19_functional_offload.gd")
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const ORDER := preload("res://scripts/data/biome_order.gd")
const GENERATED_PROFILES := "res://tests/fixtures/earned_saves/generated_boundary_profiles.json"
const WARDEN_ACCEPT_PATH := "res://tools/earned_saves/warden_accept.gd"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CHAIN_SLOT := 1  # Historical copied-save slot; legacy-order diagnostics only.
const SEGMENTS := ["opening_village", "opening_team", "camp_tournament", "bridge", "warrens", "relay", "sigils", "hall", "warden", "tidewake_handoff", "kell_rift"]
const MEADOWS_PIECES := HANDOFF.MEADOWS_PIECES
const MEADOWS_REALMS := HANDOFF.MEADOWS_REALMS
const TRAINING := preload("res://tools/earned_saves/training_handoff.gd")
const ALTAR := preload("res://tools/earned_saves/altar_training_piece.gd")
const EARN := preload("res://tools/earned_saves/essence_earning_piece.gd")
const MEADOWS_TRAINING := preload("res://tools/earned_saves/wip_fights/meadows_training_piece.gd")
## Opt-in fixed prefix: --training-profile=meadows_training_v1. Each Altar
## slot raises one retained companion to the tier cap through paid input.
## --feast-choices=<JSON UID:stay/evolve map> applies only to feed pieces.
var training_profile := ""
var piece_order: Array = MEADOWS_PIECES.duplicate()
var piece_realms: Array = MEADOWS_REALMS.duplicate()
var previous_training := {}
var feast_choices := {}
const LOAD_SETTLE_FRAMES := 300
const SETTLE_ROUNDS := 6
const SETTLE_FRAMES := 60

var segment := ""
var save_dir := ""
var receipt_path := ""
var failures: Array[String] = []
var helper_receipts: Array = []
var started_ms := 0
var game: Node
var flags_before: Array = []
var party_before: Array = []
var disclosures: Array[String] = []
var legacy_order_diagnostic := false
var functional_offload := false
var observe_next_goal := false
var handoff_from := ""
var compatibility_paths: Array[String] = []
var disk: RefCounted
var retained_uids: Array[String] = []
var generated_fixture := false
## --diagnostic: runs from a dirty tree and across commits with the clean-tree
## and lineage gates off; every receipt, handoff and printed proof is stamped
## DIAGNOSTIC, NOT EVIDENCE, and evidence inputs/collectors refuse that stamp.
var diagnostic := false
## F02#4: `--reload-at-sigils` saves and reloads through the production Load
## after each Sigil captain, with the three Sigils before the gate, and at the
## Warden arena. F02#6/#7: `--route-ledger` runs the route-ledger observer
## (tests/helpers/meadows_earned_route_ledger_segment.gd) over the sigils and
## hall pieces, staged at each captain and the Hall.
var reload_at_sigils := false
var route_ledger_enabled := false
var _ledger_stage := ""


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--segment="):
			segment = arg.get_slice("=", 1)
		elif arg.begins_with("--save-dir="):
			save_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--receipt="):
			receipt_path = arg.get_slice("=", 1)
		elif arg.begins_with("--training-profile="):
			if not training_profile.is_empty(): failures.append("Supply one training profile")
			training_profile = arg.trim_prefix("--training-profile=")
			if training_profile != HANDOFF.TRAINING_PROFILE: failures.append("Unknown Meadows training profile")
		elif arg.begins_with("--feast-choices="):
			var choices: Variant = JSON.parse_string(arg.trim_prefix("--feast-choices="))
			if not choices is Dictionary: failures.append("Feast choices must be a JSON UID map")
			else: feast_choices = choices
		elif arg == "--legacy-order-diagnostic":
			legacy_order_diagnostic = true
		elif arg == "--functional-offload":
			functional_offload = true
		elif arg == "--generated-fixture":
			generated_fixture = true
		elif arg == "--diagnostic":
			diagnostic = true
		elif arg == "--reload-at-sigils":
			reload_at_sigils = true
		elif arg == "--route-ledger":
			route_ledger_enabled = true
		elif arg == "--observe-next-goal":
			observe_next_goal = true
		elif arg in ["--lesson-controller-witness", "--lesson-replay-witness", "--capture-lessons"] or arg.begins_with("--lesson-skip-line"):
			pass  # Validated below; only the existing reader can witness an actual lesson.
		elif arg.begins_with("--handoff-from="):
			if not handoff_from.is_empty() or arg == "--handoff-from=":
				failures.append("Supply one nonempty --handoff-from")
			handoff_from = arg.trim_prefix("--handoff-from=")
		elif arg.begins_with("--compatibility-manifests="):
			if not compatibility_paths.is_empty() or arg == "--compatibility-manifests=":
				failures.append("Supply one nonempty explicit compatibility manifest list")
			for path: String in arg.trim_prefix("--compatibility-manifests=").split(","):
				if path.strip_edges().is_empty():
					failures.append("Compatibility manifest paths must be nonempty")
				compatibility_paths.append(path)
		else:
			failures.append("Unknown earned-piece option: " + arg)
	var lesson_options := TRAVEL.lesson_witness_options()
	failures.append_array(lesson_options.failures)
	if training_profile == HANDOFF.TRAINING_PROFILE:
		piece_order = HANDOFF.TRAINED_MEADOWS_PIECES.duplicate()
		piece_realms = HANDOFF.TRAINED_MEADOWS_REALMS.duplicate()
		if legacy_order_diagnostic or generated_fixture: failures.append("Trained Meadows profile requires an earned new-order prefix")
	if not feast_choices.is_empty() and (training_profile != HANDOFF.TRAINING_PROFILE or segment not in ["training_t1_feed", "training_t2_feed"]):
		failures.append("Feast choices apply only to trained Meadows feed pieces")
	if (not SEGMENTS.has(segment) and not piece_order.has(segment)) or save_dir.is_empty() or receipt_path.is_empty():
		failures.append("usage: --segment=<%s> --save-dir=<dir> --receipt=<json>" % "|".join(SEGMENTS))
		_finish()
		return
	if not failures.is_empty():
		_finish()
		return
	# A generated lineage starts only at Relay, Sigils or Hall (Hall added under
	# the owner's chunked-proof rules, 2026-10-11: a piece may start from a
	# disclosed generated boundary); a later piece may continue it from its
	# predecessor's own saved handoff, never start one.
	if generated_fixture and (legacy_order_diagnostic or not compatibility_paths.is_empty() \
			or (segment not in ["relay", "sigils", "hall"] and handoff_from.is_empty())):
		failures.append("Generated fixtures are explicit Relay/Sigils/Hall inputs, never legacy or reviewed earned imports")
		_finish()
		return
	if legacy_order_diagnostic and not handoff_from.is_empty():
		failures.append("Legacy diagnostics cannot import new-order piece provenance")
		_finish()
		return
	if not compatibility_paths.is_empty() and (legacy_order_diagnostic or handoff_from.is_empty()):
		failures.append("Reviewed cut compatibility requires an actual new-order imported prefix")
		_finish()
		return
	if legacy_order_diagnostic and functional_offload:
		failures.append("Functional offload is only for the new-order ordinary-input pieces")
		_finish()
		return
	if legacy_order_diagnostic and OS.get_environment("TB_WORLD_SEED").is_empty():
		failures.append("TB_WORLD_SEED must pin the world for a reproducible chain")
		_finish()
		return
	if diagnostic:
		CHECKPOINTS.diagnostic_mode = true
		disclosures.append(HANDOFF.DIAGNOSTIC_STAMP + ": clean-tree and lineage gates off (--diagnostic)")
		print("EARNED CHAIN " + HANDOFF.DIAGNOSTIC_STAMP)
	game = root.get_node("Game")
	# Installed before any title input, reset, world construction or autosave.
	if legacy_order_diagnostic:
		disclosures.append("Legacy-order diagnostic only: copied input saves and historical wrappers do not prove the new-order retained-five campaign")
		game.set("save_system", SAVE.new(save_dir))
	else:
		if not piece_order.has(segment) or OS.has_environment("TB_WORLD_SEED"):
			failures.append("New-order pieces end at the Tidewake handoff and retain the actual saved population; old Rift routes require --legacy-order-diagnostic")
			_finish()
			return
		var config: Dictionary = game.session.call("config")
		for flag: String in ["redesign_portal_runtime_enabled", "redesign_boss_handoff_runtime_enabled", "redesign_ending_runtime_enabled"]:
			if config.get(flag) != true: failures.append("New-order piece requires the actual producer gate: " + flag)
		if ORDER.runtime_ids() != ["meadows", "water", "cloudreach", "stormwood"]:
			failures.append("New-order piece requires Meadows/Tidewake/Cloudreach/Stormwood")
		var sha := RegEx.new()
		sha.compile("^[0-9a-f]{40}$")
		var source_commit := CHECKPOINTS.commit_sha()
		if sha.search(source_commit) == null:
			failures.append("New-order piece requires an exact clean source commit before play")
		save_dir = ProjectSettings.globalize_path(save_dir).simplify_path().trim_suffix("/")
		receipt_path = ProjectSettings.globalize_path(receipt_path).simplify_path()
		var output_root := save_dir.get_base_dir().get_base_dir()
		if save_dir != output_root.path_join(segment + "/save") \
			or receipt_path != output_root.path_join(segment + "/receipt.json") \
			or DirAccess.dir_exists_absolute(output_root) or FileAccess.file_exists(output_root):
			failures.append("Piece output must be an absent root with <segment>/save and <segment>/receipt.json; refusing overwrite")
		if not generated_fixture and (segment == "opening_village") != handoff_from.is_empty():
			failures.append("Only opening_village starts fresh; every later piece requires --handoff-from=<previous piece>")
		var working := output_root + "_working_" + segment
		if DirAccess.dir_exists_absolute(working) or FileAccess.file_exists(working):
			failures.append("Piece writable scratch already exists; refusing overwrite")
		if not failures.is_empty():
			_finish()
			return
		disk = HANDOFF.new(self, game, output_root, piece_order, piece_realms, HANDOFF.MEADOWS_SLOT)
		disk.source_commit = source_commit
		disk.diagnostic = diagnostic
		if not disk.configure_compatibility(compatibility_paths, segment):
			failures.append_array(disk.failures)
			_finish()
			return
		game.set("save_system", SAVE.new(working))
	# Reuse the existing hosted mechanics mode. It keeps the real display,
	# physics, input and saves; disabled rasterization never supplies visual proof.
	if functional_offload and not OFFLOAD.configure("full_fresh_campaign"):
		failures.append("Existing Compatibility functional offload refused this piece")
		_finish()
		return
	if generated_fixture and handoff_from.is_empty():
		if not await _generate_boundary_fixture():
			_finish()
			return
	print("EARNED CHAIN segment=%s save_dir=%s seed=%s" % [segment, save_dir, OS.get_environment("TB_WORLD_SEED")])
	match segment:
		"opening_village":
			if observe_next_goal: TRAVEL.new(self, game).observe_next_goal(segment, "before_fresh_title")
			await _opening_village()
		_:
			if await _load_previous():
				if observe_next_goal: TRAVEL.new(self, game).observe_next_goal(segment, "after_load_before_piece")
				await _resumed_segment()
	if observe_next_goal:
		TRAVEL.new(self, game).observe_next_goal(segment, "after_piece" if failures.is_empty() else "piece_failed")
	if failures.is_empty() and not legacy_order_diagnostic:
		var actual_uids: Array[String] = []
		var distinct := {}
		for member: Dictionary in _party():
			actual_uids.append(str(member.uid))
			distinct[member.uid] = true
		var required_size := 2 if segment == "opening_village" else 5
		var same_lineage := retained_uids.is_empty() or actual_uids == retained_uids \
			or (segment == "opening_team" and retained_uids.size() == 2 \
				and actual_uids.slice(0, 2) == retained_uids)
		if actual_uids.size() != required_size or distinct.size() != required_size or actual_uids.has("") \
			or not same_lineage \
			or str(game.current_realm) != piece_realms[piece_order.find(segment)] or bool(game.free_build):
			failures.append("Piece must retain its exact earned UIDs in its authored realm without free build")
	if failures.is_empty() and legacy_order_diagnostic:
		if not bool(game.call("save_game", CHAIN_SLOT)):
			failures.append("Game.save_game(%d) refused the segment save" % CHAIN_SLOT)
	if failures.is_empty() and not legacy_order_diagnostic and disk != null:
		await _settle_owner_deliveries()
	_finish()


## F19#5 r8: a combat_mastery duty journaled as pending_owner_save applies on
## the frames after a production save, so a receipt read on the save frame
## missed one mastery use that production Load then replayed. Save, let those
## deliveries apply, and repeat until the observed state is stable (bounded).
## Nothing is written but ordinary production saves; export then saves again.
func _settle_owner_deliveries() -> void:
	var before: Dictionary = disk.call("_state")
	for round in SETTLE_ROUNDS:
		if not bool(game.call("save_game", HANDOFF.MEADOWS_SLOT)):
			failures.append("Settling save refused before export")
			return
		for _i in SETTLE_FRAMES:
			await physics_frame
		var after: Dictionary = disk.call("_state")
		if after == before:
			disclosures.append("Pending owner deliveries settled after %d save(s) before export" % (round + 1))
			return
		before = after
	disclosures.append("Owner deliveries still changing after %d settling saves; exported the last state" % SETTLE_ROUNDS)


func _opening_village() -> void:
	if bool(game.call("has_save", CHAIN_SLOT)) or bool(game.call("has_save", 0)):
		failures.append("the fresh segment's save dir already holds a save")
		return
	var opening := OPENING.new()
	var live: Dictionary = await opening.run(self)
	if not _take(live, "passed", "opening"):
		return
	live = await opening.open_road_gate()
	if not _take(live, "passed", "road_gate"):
		return
	var village := VILLAGE.new()
	if not legacy_order_diagnostic: village.care_basket_purchases = 5
	var village_failures: Array[String] = await village.run(self,
		live["world"], live["game"], live["player"], live["rig"])
	if not village_failures.is_empty():
		failures.append_array(village_failures)
		return
	helper_receipts.append({"segment": "village", "passed": true})


func _load_previous() -> bool:
	if not legacy_order_diagnostic:
		var previous: String = piece_order[piece_order.find(segment) - 1]
		if ProjectSettings.globalize_path(handoff_from).simplify_path().trim_suffix("/").get_file() != previous:
			failures.append("Piece must load its immediate predecessor: " + previous)
			return false
		if disk.import_prefix(handoff_from, "generated_fixture" if generated_fixture else "earned") != previous:
			failures.append_array(disk.failures)
			return false
		var travel := TRAVEL.new(self, game)
		if not await disk.reload_boundary(previous, travel):
			failures.append_array(disk.failures)
			return false
		for member: Dictionary in disk.snapshots[previous].state.party:
			retained_uids.append(str(member.uid))
		for _i in LOAD_SETTLE_FRAMES: await physics_frame
		for _i in 600:
			if INPUT_OWNER.current(self) == null: break
			await process_frame
		if INPUT_OWNER.current(self) != null:
			failures.append("Loaded piece never returned ordinary world input")
			return false
		if training_profile == HANDOFF.TRAINING_PROFILE:
			# For an unstamped common bridge prefix, project its actual persisted
			# character only after full hash-linked import and production Load.
			previous_training = HANDOFF.training_snapshot(disk.snapshots[previous].state)
			if previous_training.is_empty() or not TRAINING.compare({"training": previous_training}, {"training": TRAINING.snapshot(game)}).matches:
				failures.append("Loaded trained prefix differs from saved creature/cap/recipe history")
				return false
		flags_before = (game.get("progression").call("all_set") as Array).duplicate()
		party_before = _party()
		return true
	if not bool(game.call("has_save", CHAIN_SLOT)):
		failures.append("no previous-segment save in slot %d of %s" % [CHAIN_SLOT, save_dir])
		return false
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10:
		await process_frame
	# The production Load list, then the chain slot's own button.
	var load_button := title.get("_load_button") as Button
	if load_button == null:
		failures.append("the production title has no Load button")
		return false
	load_button.pressed.emit()
	await process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Save %d" % CHAIN_SLOT) \
				and not (node as Button).disabled:
			chosen = node
	if chosen == null:
		failures.append("the title's Load list does not offer Save %d" % CHAIN_SLOT)
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
		failures.append("the loaded save never reached a ready world scene")
		return false
	for _i in LOAD_SETTLE_FRAMES:
		await physics_frame
	for _i in 600:
		if INPUT_OWNER.current(self) == null:
			break
		await process_frame
	flags_before = (game.get("progression").call("all_set") as Array).duplicate()
	party_before = _party()
	print("EARNED CHAIN loaded realm=%s player=%s flags=%d party=%s" % [
		game.get("current_realm"), world.get_node("Player").global_position, flags_before.size(), JSON.stringify(party_before)])
	return true


func _resumed_segment() -> void:
	var world := current_scene as Node3D
	if segment.begins_with("training_"):
		if training_profile != HANDOFF.TRAINING_PROFILE or not piece_order.has(segment):
			failures.append("Training piece requires the fixed earned training prefix")
			return
		if segment == "training_t2_return":
			_take(await ALTAR.new().return_to_bridge(self, world, game, previous_training), "passed", segment)
			return
		var fields := segment.split("_")
		var tier := int(fields[1].trim_prefix("t"))
		if fields[2] == "earn":
			_take(await EARN.new().run_earning(self, world, game, {"tier": tier, "previous_training": previous_training}), "passed", segment)
			return
		if fields[2] == "altar":
			_take(await ALTAR.new().run_training(self, world, game, {"tier": tier,
				"party_index": int(fields[3]) - 1, "previous_training": previous_training}), "passed", segment)
		else:
			_take(await MEADOWS_TRAINING.new().run(self, world, game, {"tier": tier,
				"phase": fields[2], "choices": feast_choices, "previous_training": previous_training}), "passed", segment)
		return
	match segment:
		"opening_team":
			_take(await TEAM.new().run(self, world, game), "passed", "team")
		"camp_tournament":
			var player := world.get_node("Player") as CharacterBody3D
			var rig := world.get_node("CameraRig") as Node3D
			if not _take(await MATERIALS.new().run(self, world, game, player, rig, false), "passed", "materials"):
				return
			var camp := CAMP.new()
			if not _take(await camp.run(self, world, game, player, rig, false, false, false), "passed", "camp"):
				return
			if not _take(await REST.new().run(self, world, game, camp._beds, camp._bedroll, false), "passed", "rest"):
				return
			var tournament := TOURNAMENT.new()
			if not legacy_order_diagnostic:
				tournament.recover = func() -> Dictionary:
					return await REST.new().recover(self, world, game, camp._beds, camp._bedroll)
			_take(await tournament.run(self, world, game, player, rig), "passed", "tournament")
		"bridge":
			var helper: GDScript = load("res://tools/earned_saves/bridge_crossing.gd") if legacy_order_diagnostic else BRIDGE
			_take(await helper.new().run(self, world, game), "passed", "bridge")
		"warrens":
			var helper: GDScript = load("res://tools/earned_saves/warrens_route.gd") if legacy_order_diagnostic else WARRENS
			_take(await helper.new().run(self, world, game), "passed", "warrens")
		"relay":
			var helper: GDScript = load("res://tools/earned_saves/relay_route.gd") if legacy_order_diagnostic else RELAY
			_take(await helper.new().run(self, world, game), "passed", "relay")
		"sigils":
			var sigils := HALL.new()
			sigils.run_stage = HALL.STAGE_SIGILS
			_stage_hooks(sigils)
			var ledger := _start_ledger()
			_take(await sigils.run(self, world, game), "passed", "sigils")
			_stop_ledger(ledger)
		"hall":
			if legacy_order_diagnostic:
				_take(await (load("res://tools/earned_saves/hall_route.gd") as GDScript).new().run(self, world, game), "passed", "hall")
			else:
				var hall := HALL.new()
				hall.run_stage = HALL.STAGE_HALL
				_stage_hooks(hall)
				var ledger := _start_ledger()
				_take(await hall.run(self, world, game), "passed", "hall")
				_stop_ledger(ledger)
		"kell_rift":
			# Resume from the warden segment's village_pre_kell checkpoint.
			_take(await (load(WARDEN_ACCEPT_PATH) as GDScript).new().run_from_village(self, world, game), "passed", "kell_rift")
			for _i in 120:
				await physics_frame
		"warden":
			if not legacy_order_diagnostic:
				_take(await WARDEN_FINALE.new().run_finale(self, world, game), "passed", "warden_finale")
				return
			_take(await (load(WARDEN_ACCEPT_PATH) as GDScript).new().run(self, world, game), "passed", "warden_accept")
			# The helper follows the production Rift callback into Cloudreach.
			for _i in 120:
				await physics_frame
		"tidewake_handoff":
			var travel := TRAVEL.new(self, game)
			if await travel.home_key() and await travel.hang_relic("meadows") and await travel.enter("tidewake", "water"):
				helper_receipts.append({"segment": "tidewake_handoff", "passed": true})
				for _i in LOAD_SETTLE_FRAMES:
					await physics_frame
			else:
				failures.append_array(travel.failures)
				if travel.failures.is_empty(): failures.append("tidewake_handoff: portal travel failed without a receipt")


func _stage_hooks(helper: RefCounted) -> void:
	if not reload_at_sigils and not route_ledger_enabled:
		return
	_ledger_stage = segment + "_start"
	helper.set("after_captain", _stage)
	helper.set("after_hall", _stage)
	helper.set("before_gate", func() -> bool: return await _stage("sigils_carried"))


func _stage(label: String) -> bool:
	_ledger_stage = label
	if not reload_at_sigils:
		return true
	return await _reload_transition(label)


func _start_ledger() -> RefCounted:
	if not route_ledger_enabled:
		return null
	var ledger: RefCounted = preload("res://tests/helpers/meadows_earned_route_ledger_segment.gd").new()
	var path := "user://route_ledger_%s_%d_%d.jsonl" % [segment, OS.get_process_id(), Time.get_ticks_msec()]
	if not ledger.call("start", self, func() -> String: return _ledger_stage, path):
		failures.append("Route ledger could not start at " + path)
		return null
	disclosures.append("Route ledger observer (read-only) over the %s piece: %s" % [segment, ProjectSettings.globalize_path(path)])
	return ledger


func _stop_ledger(ledger: RefCounted) -> void:
	if ledger != null:
		_ledger_stage = segment + "_end"
		print("ROUTE LEDGER SUMMARY %s" % JSON.stringify(ledger.call("stop")))


## F02#4, as smoke_four_biome_continuous.gd `_reload_transition`: a production
## save, the live Meadows freed, flags, party and satchel emptied, a production
## load and a fresh Meadows scene. Every flag, the party UIDs and condition and
## the carried items must come back exactly.
func _reload_transition(label: String) -> bool:
	var progression: RefCounted = game.get("progression")
	var party: RefCounted = game.get("party")
	var inventory: RefCounted = game.get("inventory")
	var flags_before: Array = (progression.call("all_set") as Array).duplicate()
	flags_before.sort()
	var uids_before := _party_uids()
	var items_before := _inventory_totals()
	var condition_before := _party_condition()
	var scene_path := str(current_scene.scene_file_path)
	if not bool(game.call("save_game", 0)):
		failures.append("RELOAD %s: save_game(0) refused" % label)
		return false
	current_scene.queue_free()
	for i in 4:
		await process_frame
	progression.call("load_data", {})
	party.call("clear")
	for i in int(inventory.call("slot_count")):
		inventory.call("set_slot", i, null)
	if not bool(game.call("load_game", 0)):
		failures.append("RELOAD %s: load_game(0) failed" % label)
		return false
	var condition_after := _party_condition()
	var world: Node = (load(scene_path) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in 240:
		await physics_frame
	var flags_after: Array = (progression.call("all_set") as Array).duplicate()
	flags_after.sort()
	var lost: Array = flags_before.filter(func(f: Variant) -> bool: return not flags_after.has(f))
	print("RELOAD %s: flags %d -> %d (lost %s); party %s -> %s; items %s -> %s" % [label, flags_before.size(),
		flags_after.size(), str(lost), str(uids_before), str(_party_uids()), JSON.stringify(items_before),
		JSON.stringify(_inventory_totals())])
	if not lost.is_empty():
		failures.append("RELOAD %s: flags lost across the reload: %s" % [label, str(lost)])
	if _party_uids() != uids_before:
		failures.append("RELOAD %s: the party changed across the reload" % label)
	if _inventory_totals() != items_before:
		failures.append("RELOAD %s: the carried inventory changed across the reload" % label)
	if condition_after != condition_before:
		failures.append("RELOAD %s: party HP/fainted/level/XP changed across the reload (%s -> %s)" % [label,
			JSON.stringify(condition_before), JSON.stringify(condition_after)])
	if world.get_node_or_null(^"Player") == null:
		failures.append("RELOAD %s: the rebuilt world has no Player" % label)
	return failures.is_empty()


func _party_uids() -> Array:
	var out: Array = []
	for member: RefCounted in game.get("party").call("members"):
		out.append(str(member.get("uid")))
	return out


func _party_condition() -> Dictionary:
	var out := {}
	for member: RefCounted in game.get("party").call("members"):
		out[str(member.get("uid"))] = [snappedf(float(member.get("hp")), 0.1), int(member.get("max_hp")),
			bool(member.get("fainted")), int(member.get("level")), int(member.get("xp"))]
	return out


func _inventory_totals() -> Dictionary:
	var out := {}
	var inventory: RefCounted = game.get("inventory")
	for i in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if not stack.is_empty():
			out[str(stack.get("id", ""))] = int(out.get(str(stack.get("id", "")), 0)) + int(stack.get("n", 0))
	return out


func _take(result: Dictionary, key: String, label: String) -> bool:
	var receipts: Variant = result.get("receipts", result.get("transcript", []))
	helper_receipts.append({"segment": label, "passed": bool(result.get(key, false)),
		"receipts": JSON.parse_string(JSON.stringify(receipts))})
	for line: Variant in result.get("failures", []):
		failures.append("%s: %s" % [label, str(line)])
	for row: Variant in (receipts if receipts is Array else []):
		var beat := str((row as Dictionary).get("beat", "")) if row is Dictionary else ""
		if beat == "gate_prompt_assertion_bypassed":
			disclosures.append("bridge: the Meadows helper's 'gate must own the interact prompt' assertion was bypassed because ordinary play had already opened the South Bridge (south_bridge_open set, key spent); the stale '%s' battle offer ('offered a battle that could not start') remains an open Meadows defect" % "south_bridge_grunt")
		elif beat == "unreachable_node_skipped":
			disclosures.append("warrens: harvest order 16 rootstone (393,1802) skipped as physically unreachable (BLOCKERS.md B2, open Meadows defect); nothing later consumes rootstone, so no replacement gathering was needed")
		elif beat == "undertrail_mound_detour":
			disclosures.append("warrens: added an ordinary controller-walk detour west of the Warrens mound on the undertrail approach (BLOCKERS.md B3)")
		elif beat == "prompt_press_delayed_dialogue":
			disclosures.append(segment + ": the exact Interact press opened its dialogue without the arbiter's activated signal; accepted on the real panel opening, the helper still verified the exact conversation: %s" % JSON.stringify(row))
		elif beat == "prompt_press_retry":
			disclosures.append(segment + ": an Interact press did not activate the exact offered provider and was retried with no side effect: %s" % JSON.stringify(row))
		elif beat == "pre_sigil_camp_night":
			disclosures.append("hall: earned rest at the authored riverwatch_rest before the Sigil loop (walked back over the Mill; production bed panel + Rest until morning): %s" % JSON.stringify(row))
		elif beat == "between_fight_care":
			disclosures.append(segment + ": ordinary Satchel care (helper's own _prepare) run before a road leg with a drained active creature (BLOCKERS.md B5)")
		elif beat == "quarry_east_detour":
			disclosures.append("warrens: added an ordinary controller-walk detour east of the quarry pylon before the fourth rootstone (helper's direct leg stalls; BLOCKERS.md B2)")
		elif beat == "veridian_accepted":
			disclosures.append("warden: Veridian offer ACCEPTED with a full belt through the production farewell ceremony; released lowest-level earned member %s" % JSON.stringify((row as Dictionary).get("released", {})))
	if not bool(result.get(key, false)) and failures.is_empty():
		failures.append("%s returned %s=false" % [label, key])
	return failures.is_empty()


func _party() -> Array:
	var out: Array = []
	var party: RefCounted = game.get("party")
	if party == null:
		return out
	for member: Variant in (party.call("members") as Array):
		var c := member as RefCounted
		if c == null:
			continue
		out.append({"uid": str(c.get("uid")), "species": str(c.get("species_id")),
			"nickname": str(c.get("nickname")), "level": int(c.get("level")),
			"hp": int(c.get("hp")) if c.get("hp") != null else -1})
	return out


func _inventory() -> Dictionary:
	var stacks := {}
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return stacks
	for index in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", index)
		if stack.is_empty():
			continue
		var id := str(stack.get("id", ""))
		stacks[id] = int(stacks.get(id, 0)) + int(stack.get("n", 0))
	return stacks


func _finish() -> void:
	var flags_after: Array = []
	var location := {}
	if game != null:
		flags_after = (game.get("progression").call("all_set") as Array).duplicate()
		var scene := current_scene
		var player := scene.get_node_or_null("Player") as Node3D if scene != null else null
		location = {"realm": str(game.get("current_realm")), "scene": str(scene.name) if scene != null else "",
			"player": [player.global_position.x, player.global_position.y, player.global_position.z] if player != null else []}
	var gained: Array = []
	for flag: Variant in flags_after:
		if not flags_before.has(flag):
			gained.append(flag)
	gained.sort()
	var inventory := _inventory() if game != null else {}
	var key_items := {}
	for id: String in inventory:
		if id.contains("key") or id.contains("sigil") or id.contains("recipe") or id.contains("gear"):
			key_items[id] = inventory[id]
	var receipt := {
		"segment": segment,
		"training_profile": training_profile,
		"mode": "legacy_order_diagnostic" if legacy_order_diagnostic else "new_order_meadows_piece",
		"functional_offload": functional_offload,
		"input_mode": "generated_fixture" if generated_fixture else "earned",
		"prior_earned_play": false if generated_fixture else null,
		"continuous_fresh_save": false,
		"handoff_from": handoff_from,
		"passed": failures.is_empty(),
		"failures": failures,
		"world_seed_env": OS.get_environment("TB_WORLD_SEED"),
		"saved_world_seed": int(game.get("world_seed")) if game != null else 0,
		"wall_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"game_day": int(game.get("day")) if game != null else 0,
		"game_clock_seconds": float(game.get("clock_elapsed_seconds")) if game != null else -1.0,
		"location": location,
		"flags_gained": gained,
		"flags_total": flags_after.size(),
		"party_before": party_before,
		"party_after": _party() if game != null else [],
		"inventory": inventory,
		"key_items": key_items,
		"free_build": bool(game.get("free_build")) if game != null else false,
		"disclosures": disclosures,
		"helper_receipts": helper_receipts,
	}
	if diagnostic: receipt.evidence_status = HANDOFF.DIAGNOSTIC_STAMP
	if not legacy_order_diagnostic:
		if observe_next_goal and failures.is_empty() and disk != null:
			TRAVEL.new(self, game).observe_next_goal(segment, "before_export")
		if failures.is_empty() and disk != null and not disk.export_boundary(segment, receipt):
			failures.append_array(disk.failures)
		if observe_next_goal and failures.is_empty() and disk != null:
			TRAVEL.new(self, game).observe_next_goal(segment, "after_export")
		receipt.passed = failures.is_empty()
		# The immutable handoff owns receipt.json. Failed runs only print their
		# evidence; they must never create a success-shaped resumable boundary.
		print("EARNED PIECE PROOF " + JSON.stringify(receipt))
	else:
		var file := FileAccess.open(receipt_path, FileAccess.WRITE)
		if file == null:
			failures.append("Legacy diagnostic receipt could not be written")
		else:
			file.store_string(JSON.stringify(receipt, "  "))
			file.close()
	print("EARNED CHAIN RESULT %s%s" % ["[%s] " % HANDOFF.DIAGNOSTIC_STAMP if diagnostic else "", JSON.stringify({"segment": segment, "passed": failures.is_empty(),
		"wall_seconds": receipt.wall_seconds, "location": location, "failures": failures,
		"party": receipt.party_after, "flags_gained": gained.size()})])
	quit(0 if failures.is_empty() else 1)


func copy_tree(from: String, to: String) -> bool:
	return CHECKPOINTS.copy_tree(from, to)


## Owner #5726060136810: setup only. After export, the original helpers receive
## the immutable production save through their unchanged title Load path.
func _generate_boundary_fixture() -> bool:
	var generated_root := save_dir.get_base_dir().get_base_dir() + "_generated_input"
	if DirAccess.dir_exists_absolute(generated_root) or FileAccess.file_exists(generated_root):
		failures.append("Generated fixture output root already exists; refusing overwrite")
		return false
	var table: Variant = JSON.parse_string(FileAccess.get_file_as_string(GENERATED_PROFILES))
	if not table is Dictionary or table.get("owner_policy") != "#5726060136810" \
			or not table.get("profiles", {}).has(segment):
		failures.append("Generated segment requires its committed complete boundary profile")
		return false
	var profile: Dictionary = table.profiles[segment]
	var source := ProjectSettings.globalize_path(str(table.base_save))
	var working := ProjectSettings.globalize_path(str(game.save_system.get("_dir")))
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(source.get_base_dir().path_join("PROVENANCE.json")))
	if not manifest is Dictionary or manifest.get("kind") != "generated_fixture_template":
		failures.append("Generated fixture template requires its portable byte provenance")
		return false
	for file: String in manifest.files_sha256:
		if FileAccess.get_sha256(source.path_join(file)) != manifest.files_sha256[file]:
			failures.append("Generated fixture template bytes changed: " + file)
			return false
	if not copy_tree(source, working) or not game.load_game(0):
		failures.append("Generated fixture template failed production Load validation")
		return false
	var original_party := _party()
	var original_ids: Array[String] = []
	for member: Dictionary in original_party: original_ids.append(str(member.uid))
	var distinct := {}
	for uid: String in original_ids: distinct[uid] = true
	if original_ids.size() != 5 or original_ids.has("") or distinct.size() != 5:
		failures.append("Generated fixture must start with five actual distinct template identities")
		return false
	var levels: Array = profile.party_levels
	if not levels.is_empty() and levels.size() != 5:
		failures.append("Generated level profile must declare all five companions")
		return false
	# The four chapters end near L55. A post-credits profile (regional_credits_seen)
	# may reach the Masters' cap ceiling, as an ordinary post-credits player can.
	var level_max := 55
	if (profile.personal_flags as Array).has("regional_credits_seen"):
		level_max = int(preload("res://scripts/creatures/breakthrough.gd").masters().get("ceiling", 60))
	for index in 5:
		var creature: RefCounted = game.party.at(index)
		if not levels.is_empty():
			var level := int(levels[index])
			if level < 1 or level > level_max:
				failures.append("Generated four-chapter level is outside its authored range")
				return false
			creature.level = level
			creature.xp = 0
			creature.recompute_stats_from_base(preload("res://scripts/creatures/progression.gd").config())
			var tiers := preload("res://scripts/creatures/breakthrough.gd").caught_tiers(level)
			var record: Dictionary = game.local.redesign_character.creatures[creature.uid]
			record.breakthroughs = tiers
			record.cap_level = preload("res://scripts/creatures/breakthrough.gd").level_cap(tiers)
		if profile.heal_party: creature.heal_fully()
	for flag: String in profile.world_flags: game.world.flags.set_flag(flag)
	for flag: String in profile.personal_flags: game.local.flags.set_flag(flag)
	# Only declared progress carriers; never fabricate transaction/delivery
	# receipts or previous PASS evidence for a generated chapter input.
	# Independent Master boundaries: tier -> exactly the prior tiers' wins/recipes.
	var prior_tier: int = {"tidewake_t3_ione_independent": 3, "cloudreach_t4_aster_independent": 4}.get(segment, 0)
	var prior_t3_setup := prior_tier > 0
	var prior_wins: Array = []
	var prior_recipes: Array = []
	for tier in range(1, prior_tier):
		prior_wins.append("master_t%d" % tier)
		prior_recipes.append("feast_t%d" % tier)
	if prior_t3_setup and (profile.get("character_fields", {}).get("master_wins") != prior_wins \
			or profile.get("character_fields", {}).get("feast_recipes") != prior_recipes):
		failures.append("Independent T%d boundary may declare only prior Master wins and recipes %s" % [prior_tier, str(prior_wins)])
		return false
	var allowed_carriers := ["portal_unlocks", "relics_held", "relics_hung"]
	if prior_t3_setup: allowed_carriers.append_array(["master_wins", "feast_recipes"])
	for field: String in profile.get("character_fields", {}):
		if field not in allowed_carriers or not profile.character_fields[field] is Array:
			failures.append("Generated profile tried to replace an undeclared protected carrier")
			return false
		game.local.redesign_character[field] = profile.character_fields[field].duplicate()
	if profile.has("world_portal_unlocks"):
		game.world.redesign_world.portal_unlocks = profile.world_portal_unlocks.duplicate()
	for item: String in profile.inventory_add:
		if game.inventory.add(item, int(profile.inventory_add[item])) != 0:
			failures.append("Generated inventory could not fit declared item: " + item)
			return false
	game.day = int(profile.day)
	game.clock_elapsed_seconds = float(profile.clock_elapsed_seconds)
	game.current_realm = str(profile.realm)
	game.local.realm = str(profile.realm)
	game.pending_realm_entry = ""
	var pose: Dictionary = game.saved_player_pose.duplicate(true)
	pose.realm = str(profile.realm)
	if pose.get("traversal") is Dictionary:
		pose.traversal.realm = str(profile.realm)
		pose.traversal.mode = "grounded"
		pose.traversal.velocity = [0.0, 0.0, 0.0]
	game.saved_player_pose = pose
	var expected_inventory: Array = game.save_system.snapshot(game).inventory.duplicate(true)
	var expected_flags: Array = game.progression.all_set().duplicate()
	var scenes := {"meadows":"res://scenes/world/meadows_playground.tscn", "water":"res://scenes/world/water_archipelago.tscn",
		"cloudreach":"res://scenes/world/cloudreach_cliffs.tscn", "stormwood":"res://scenes/world/stormwood.tscn"}
	if not scenes.has(profile.realm) or change_scene_to_file(scenes[profile.realm]) != OK:
		failures.append("Generated fixture could not mount its authored realm")
		return false
	var ready := false
	for frame in 7200:
		await process_frame
		if current_scene != null and game._realm_scene_ready(current_scene, str(profile.realm)):
			ready = true
			break
	var player: CharacterBody3D = game.find_player()
	if not ready or player == null:
		failures.append("Generated fixture realm did not become ready")
		return false
	var requested := player.global_position
	if profile.position is Dictionary:
		if profile.position.has("ground_xz"):
			var xz: Array = profile.position.ground_xz
			requested = Vector3(float(xz[0]), float(current_scene.ground_height_at(float(xz[0]), float(xz[1]))) + 0.15, float(xz[1]))
		elif profile.position.has("stronghold_marker"):
			requested = current_scene.get_node("Stronghold").marker(str(profile.position.stronghold_marker)) + Vector3.UP * 0.15
		elif profile.position.get("water_dock") == true:
			var prompt: Node3D = current_scene.get_node("WaterChapter").get("_dock_prompt")
			requested = prompt.global_position + Vector3(0.0, 0.15, 2.5)
		elif profile.position.get("cloudreach_reward") == true:
			var npc: Node3D = current_scene.get_node("CloudreachChapter").npc_bodies().get("warden_aila")
			requested = npc.global_position + Vector3(0.0, 0.15, 2.5)
		elif profile.position.get("stormheart_south_ring") == true:
			requested = current_scene.get_node("StormheartTree").to_global(Vector3(0.0, 150.0, 26.0)) + Vector3.UP * 0.15
		else:
			failures.append("Generated pose requires an authored ground or Hall marker")
			return false
		player.global_position = requested
		player.velocity = Vector3.ZERO
	# Disclosed opt-in (coordinator, 2026-10-11): one paid Crown-arch record on
	# the authored Still Grove footing, written exactly as the real build does
	# (world_ledger.gd place_building: register_building + building_arch_link
	# twin e_crown / footing still_grove), for pieces that start past Rootgate.
	if profile.get("stormwood_paid_crown_arch") == true:
		if str(profile.realm) != "stormwood" or not (game.progression.call("has", "stormwood:crown_arch_built") as bool):
			failures.append("Generated Crown arch requires a Stormwood profile that declares stormwood:crown_arch_built")
			return false
		var footing: Dictionary = {}
		var arches: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_arches.json"))
		for socket: Dictionary in (arches as Dictionary).get("footings", []):
			if str(socket.get("id", "")) == "still_grove": footing = socket
		if footing.is_empty():
			failures.append("Generated Crown arch found no authored still_grove footing")
			return false
		var at := Vector3(float(footing.at[0]), 0.0, float(footing.at[1]))
		at.y = float(current_scene.ground_height_at(at.x, at.z))
		var uid: String = game.world.call("register_building", "stormglass_arch", at, float(footing.get("yaw_deg", 90.0)), true, "stormwood", "")
		var index: int = game.world.call("building_index_of", uid)
		game.world.placed_buildings[index]["arch_twin"] = "e_crown"
		game.world.placed_buildings[index]["arch_footing"] = "still_grove"
		disclosures.append("Generated paid Crown-arch placed_buildings record %s at %s on footing still_grove (twin e_crown); no materials were spent" % [uid, str(at)])
	for frame in 60: await physics_frame
	if not player.is_on_floor() or Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(requested.x, requested.z)) > 0.6 \
			or game.day != int(profile.day) or bool(game.free_build):
		failures.append("Generated fixture failed its declared ordinary ground pose/day/free-build guard")
		return false
	var actual_ids: Array[String] = []
	for member: Dictionary in _party(): actual_ids.append(str(member.uid))
	if actual_ids != original_ids:
		failures.append("Generated setup replaced or reordered its declared five")
		return false
	# Validate the actual production save before publishing any importable
	# boundary. A refused setup may leave scratch bytes, never a handoff.
	if not game.save_game(0) or not game.save_system.finish_fallback():
		failures.append("Generated profile failed its production save before publication")
		return false
	var saved: Dictionary = game.save_system._read(0)
	if saved.get("day") != int(profile.day) or saved.get("current_realm") != profile.realm \
			or saved.get("inventory") != expected_inventory or saved.get("party", []).size() != 5 \
			or saved.get("player_pose", {}).get("realm") != profile.realm:
		failures.append("Generated production bytes differ from declared day/realm/inventory/five/pose")
		return false
	var saved_position: Array = saved.player_pose.get("position", [])
	if saved_position.size() != 3 or Vector3(float(saved_position[0]),float(saved_position[1]),float(saved_position[2])).distance_to(player.global_position) > 0.01:
		failures.append("Generated saved pose differs from the actual settled body")
		return false
	var actual_flags: Array = game.progression.all_set()
	expected_flags.sort()
	actual_flags.sort()
	if actual_flags != expected_flags:
		var added: Array = actual_flags.filter(func(flag: Variant) -> bool: return not expected_flags.has(flag))
		var removed: Array = expected_flags.filter(func(flag: Variant) -> bool: return not actual_flags.has(flag))
		failures.append("Generated scene changed declared progression flags during setup (added %s, removed %s)" % [str(added), str(removed)])
		return false
	for field: String in profile.get("character_fields", {}):
		if saved.redesign_character.get(field) != profile.character_fields[field]:
			failures.append("Generated saved progress differs from its declared carrier: " + field)
			return false
	if profile.has("world_portal_unlocks") and saved.redesign_world.portal_unlocks != profile.world_portal_unlocks:
		failures.append("Generated saved world portal progress differs from declaration")
		return false
	for index in 5:
		var member: Dictionary = saved.party[index]
		var expected_level := int(original_party[index].level) if levels.is_empty() else int(levels[index])
		var record: Dictionary = saved.redesign_character.creatures[original_ids[index]]
		if member.get("uid") != original_ids[index] or member.get("species_id") != original_party[index].species \
				or int(member.get("level", 0)) != expected_level or int(record.cap_level) < expected_level:
			failures.append("Generated production companion identity/species/level/cap differs from declaration")
			return false
	var observation := {"kind":"generated_fixture","owner_policy":"#5726060136810","profile":profile,
		"profile_sha256":FileAccess.get_sha256(GENERATED_PROFILES),"template_files_sha256":manifest.files_sha256,
		"prior_earned_play":false,"continuous_fresh_save":false,"input":generated_root.path_join(str(profile.boundary)),
		"saved_day":saved.day,"saved_pose":saved.player_pose,"party":saved.party,
		"creature_records":saved.redesign_character.creatures,"inventory":saved.inventory,
		"declared_character_fields":profile.get("character_fields", {}),
		"saved_character_progress":{"portal_unlocks":saved.redesign_character.portal_unlocks,
			"relics_held":saved.redesign_character.relics_held,"relics_hung":saved.redesign_character.relics_hung},
		"flags":game.progression.all_set(),"source":CHECKPOINTS.commit_sha()}
	var encoded := preload("res://scripts/save/save_document.gd").stringify(observation)
	if encoded.is_empty() or DirAccess.make_dir_recursive_absolute(generated_root) != OK:
		failures.append("Generated setup observation could not be encoded before publication")
		return false
	var file := FileAccess.open(generated_root.path_join("GENERATED_SETUP.json"), FileAccess.WRITE)
	if file == null:
		failures.append("Generated setup could not retain its actual declared carriers")
		return false
	file.store_string(encoded)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or FileAccess.get_file_as_string(generated_root.path_join("GENERATED_SETUP.json")) != encoded:
		failures.append("Generated setup observation was not retained before publication")
		return false
	var generator := HANDOFF.new(self, game, generated_root, MEADOWS_PIECES + HANDOFF.BOUNDARIES,
		MEADOWS_REALMS + HANDOFF.REALMS, HANDOFF.MEADOWS_SLOT)
	var provenance := {"generator":"tools/earned_saves/earned_chain_runner.gd:%s:%s" % [FileAccess.get_sha256(GENERATED_PROFILES),segment],
		"owner_policy":"#5726060136810","prior_earned_play":false,"continuous_fresh_save":false}
	if not generator.export_boundary(str(profile.boundary), {}, "generated_fixture", provenance):
		failures.append_array(generator.failures)
		return false
	handoff_from = generated_root.path_join(str(profile.boundary))
	disclosures.append(str(profile.disclosure))
	print("GENERATED FIXTURE INPUT " + JSON.stringify(observation))
	return true
