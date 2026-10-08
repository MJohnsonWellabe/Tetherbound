extends SceneTree

## Earned Meadows pieces, one ordinary-input segment per process. The default
## stops before Warden; obsolete physical Rift routes are explicit diagnostics.
##
## WHAT IT IS
##   The same earned helpers the continuous driver
##   (`tests/smoke_four_biome_continuous.gd`) composes, cut at save boundaries.
##   Every segment either starts a FRESH game through the production title
##   (segment `opening_team`) or loads the previous segment's save through the
##   production title's Autosave entry (slot 0), runs one or more earned helpers
##   read-only, and on success writes that same slot through `Game.save_game()`.
##   This retains the actual fresh world's transaction ownership. No teleport,
##   flag/inventory/party write, HP pin or debug skip occurs during earned play.
##   Explicit --generated-fixture constructs a disclosed unearned input first;
##   its own segment then uses the same Load path and unchanged helpers.
##
## SEGMENTS (in order)
##   opening_team     fresh title -> first catch -> road gate -> village -> team
##   camp_tournament  materials -> paid camp -> rest -> tournament (camp beds are
##                    live nodes the rest helper needs, so these share a process)
##   bridge           South Bridge grunt + crossing
##   warrens          Quarry / Burrow Warrens cleared and exited
##   relay            Tether relay disabled, Mill crossed
##   hall             three Sigils, Hall gauntlet, Warden arena boundary
##   warden           Warden, Veridian offer ACCEPTED (see warden_accept.gd),
##                    acknowledgement, physical Rift crossing -> Cloudreach
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
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const OFFLOAD := preload("res://tests/helpers/f19_functional_offload.gd")
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const ORDER := preload("res://scripts/data/biome_order.gd")
const GENERATED_PROFILES := "res://tests/fixtures/earned_saves/generated_boundary_profiles.json"
const WARDEN_ACCEPT_PATH := "res://tools/earned_saves/warden_accept.gd"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CHAIN_SLOT := 1  # Historical copied-save slot; legacy-order diagnostics only.
const SEGMENTS := ["opening_team", "camp_tournament", "bridge", "warrens", "relay", "hall", "warden", "kell_rift"]
const MEADOWS_PIECES := HANDOFF.MEADOWS_PIECES
const MEADOWS_REALMS := HANDOFF.MEADOWS_REALMS
const LOAD_SETTLE_FRAMES := 300

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
		elif arg == "--legacy-order-diagnostic":
			legacy_order_diagnostic = true
		elif arg == "--functional-offload":
			functional_offload = true
		elif arg == "--generated-fixture":
			generated_fixture = true
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
	if not SEGMENTS.has(segment) or save_dir.is_empty() or receipt_path.is_empty():
		failures.append("usage: --segment=<%s> --save-dir=<dir> --receipt=<json>" % "|".join(SEGMENTS))
		_finish()
		return
	if not failures.is_empty():
		_finish()
		return
	if generated_fixture and (legacy_order_diagnostic or not compatibility_paths.is_empty() or segment not in ["relay", "hall"]):
		failures.append("Generated fixtures are explicit Relay/Hall inputs, never legacy or reviewed earned imports")
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
	game = root.get_node("Game")
	# Installed before any title input, reset, world construction or autosave.
	if legacy_order_diagnostic:
		disclosures.append("Legacy-order diagnostic only: copied input saves and historical wrappers do not prove the new-order retained-five campaign")
		game.set("save_system", SAVE.new(save_dir))
	else:
		if not MEADOWS_PIECES.has(segment) or OS.has_environment("TB_WORLD_SEED"):
			failures.append("New-order pieces stop at Hall and retain the actual saved population; old Warden/Rift routes require --legacy-order-diagnostic")
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
		if not generated_fixture and (segment == "opening_team") != handoff_from.is_empty():
			failures.append("Only opening_team starts fresh; every later piece requires --handoff-from=<previous piece>")
		var working := output_root + "_working_" + segment
		if DirAccess.dir_exists_absolute(working) or FileAccess.file_exists(working):
			failures.append("Piece writable scratch already exists; refusing overwrite")
		if not failures.is_empty():
			_finish()
			return
		disk = HANDOFF.new(self, game, output_root, MEADOWS_PIECES, MEADOWS_REALMS, HANDOFF.MEADOWS_SLOT)
		disk.source_commit = source_commit
		if not disk.configure_compatibility(compatibility_paths):
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
		"opening_team":
			if observe_next_goal: TRAVEL.new(self, game).observe_next_goal(segment, "before_fresh_title")
			await _opening_team()
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
		if actual_uids.size() != 5 or distinct.size() != 5 or actual_uids.has("") \
			or (not retained_uids.is_empty() and actual_uids != retained_uids) \
			or str(game.current_realm) != "meadows" or bool(game.free_build):
			failures.append("Piece must retain its original five distinct UIDs in earned Meadows without free build")
	if failures.is_empty() and legacy_order_diagnostic:
		if not bool(game.call("save_game", CHAIN_SLOT)):
			failures.append("Game.save_game(%d) refused the segment save" % CHAIN_SLOT)
	_finish()


func _opening_team() -> void:
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
	flags_before = []
	_take(await TEAM.new().run(self, current_scene, game), "passed", "team")


func _load_previous() -> bool:
	if not legacy_order_diagnostic:
		var previous: String = MEADOWS_PIECES[MEADOWS_PIECES.find(segment) - 1]
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
	match segment:
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
		"hall":
			var helper: GDScript = load("res://tools/earned_saves/hall_route.gd") if legacy_order_diagnostic else HALL
			_take(await helper.new().run(self, world, game), "passed", "hall")
		"kell_rift":
			# Resume from the warden segment's village_pre_kell checkpoint.
			_take(await (load(WARDEN_ACCEPT_PATH) as GDScript).new().run_from_village(self, world, game), "passed", "kell_rift")
			for _i in 120:
				await physics_frame
		"warden":
			_take(await (load(WARDEN_ACCEPT_PATH) as GDScript).new().run(self, world, game), "passed", "warden_accept")
			# The helper follows the production Rift callback into Cloudreach.
			for _i in 120:
				await physics_frame


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
	print("EARNED CHAIN RESULT %s" % JSON.stringify({"segment": segment, "passed": failures.is_empty(),
		"wall_seconds": receipt.wall_seconds, "location": location, "failures": failures,
		"party": receipt.party_after, "flags_gained": gained.size()}))
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
	for index in 5:
		var creature: RefCounted = game.party.at(index)
		if not levels.is_empty():
			var level := int(levels[index])
			if level < 1 or level > 55:
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
	for field: String in profile.get("character_fields", {}):
		if field not in ["portal_unlocks", "relics_held", "relics_hung"] or not profile.character_fields[field] is Array:
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
		failures.append("Generated scene changed declared progression flags during setup")
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

