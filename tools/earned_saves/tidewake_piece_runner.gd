extends SceneTree

const TRAINING_HANDOFF := preload("res://tools/earned_saves/training_handoff.gd")
const MEADOWS_HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const SAVE_DOCUMENT := preload("res://scripts/save/save_document.gd")
const LINEAGE := preload("res://tools/earned_saves/checkpoint_lineage.gd")
const HOMESTEAD := preload("res://tools/earned_saves/chapter_homestead.gd")

## F19#5 Tidewake pieces: one ordinary-input segment per process, mirroring
## earned_chain_runner.gd's piece protocol (that runner refuses non-Meadows
## pieces by design). Each piece copies the previous checkpoint's save/ into
## its own new checkpoint dir, points Game at that copy, loads slot 0 through
## the production title (Load -> Autosave), checks the handoff against the
## previous receipt (same five UIDs in order, same flags, same items), runs
## the existing earned helper(s) read-only, then writes slot 0 through
## Game.save_game(0). No teleport, flag/inventory/party write or HP pin.
##
## SEGMENTS (in order; the helpers' own preconditions fix Brine before
## Shellwatch: Shellwatch is the "continuation from Tovin's Brine victory")
##   01_opening      Portal arrival -> Pell -> physical swim lesson (f49_tidewake_opening)
##   02_reedhaven    water_reedhaven_segment
##   03_brine        water_brine_segment
##   04_shellwatch   water_shellwatch_segment
##   05_tidal        water_tidal_segment
##   05a_tidal_return / 05b_shellwatch_return / 05c_brine_return / 05d_reedhaven_departure
##                   Reverse authored land/crossing pieces back to Ione's departure
##   05i_ione_approach  Earned Reedhaven departure -> sheltered human swim -> Gull Rest
##   05j_ione_duel   Load Gull Rest approach -> production 1v1 and recipe chest
##   06_swimmer      water_earned_swimmer_preparation_segment (swimmer catch,
##                   paid saddle, mounted)
##   07_late         water_earned_late_segment.run_from_mount (Salt Crown ->
##                   Sluice -> Veilfall -> Nerissa -> tether)
##   07a_salt_bex -> 07b_calder -> 07c_venn -> 07d_nerissa: the human-swim
##                   route in saved pieces; old combined 07 modes now refuse.
##   08_ending       water_earned_ending_segment.run_earned (Guardian invite)
##   09_cloudreach_handoff  Home Key home, hang the Tidewake relic, enter the
##                   Cloudreach arch (f20_portal_travel, as tidewake_handoff)
##
## USAGE
##   godot --headless --path . --script tools/earned_saves/tidewake_piece_runner.gd -- \
##     --segment=<id> --from=<previous checkpoint dir> --out=<new checkpoint dir>
##   <previous checkpoint dir> holds save/ (and receipt.json unless it is the
##   generated arrival). <new checkpoint dir> must be absent.
##   Meadows cross-cut imports additionally take --compatibility-manifests=<path,...>
##   using f49_reviewed_cross_cut manifests with exact producer evidence bindings.
##   Shared homestead pieces: --segment=training_t<3|4|5>_<home|storage|kitchen|feed|return>.
##   Feed accepts --feast-choices=<JSON UID-to-evolve/stay map>; omitted choices use Stay.
##   These pieces require saved training; return stops at the chapter portal arrival.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const SEGMENTS := ["01_opening", "02_reedhaven", "03_brine", "04_shellwatch", "05_tidal",
	"05a_tidal_return", "05b_shellwatch_return", "05c_brine_return", "05d_reedhaven_departure",
	"05i_ione_approach", "05j_ione_duel",
	"05j_ione_duel_only", "05k_ione_chest",
	"05r_first_shore", "05s_reedhaven_ione", "05t_reedhaven_brine", "05u_brine_shellwatch", "05v_shellwatch_tidal",
	"06_swimmer", "07_late", "07_human_late", "07a_salt_bex", "07b_calder", "07c_venn", "07d_nerissa", "08_ending", "09_cloudreach_handoff"]
const LOAD_SETTLE_FRAMES := 300

var segment := ""
var from_dir := ""
var out_dir := ""
var game: Node
var failures: Array[String] = []
var disclosures: Array[String] = []
var helper_receipts: Array = []
var started_ms := 0
var before := {}
var swimmer_uid := ""
var meadows_prefix: RefCounted
var meadows_origin := {}
var compatibility_paths: Array[String] = []
var training_job := {}
var feast_choices := {}
## Rules v2 #1: disclosed generated input. Raise the same five to this level
## (generator's own level/cap/breakthrough code, full heal) after Load.
var raise_levels := 0
## Rules v2 #1 (coordinator, 2026-10-11, F19#5 07 vs Venn): disclosed generated
## team. `--replace-members=<index>:<species>,...` swaps those party slots for
## freshly spawned Tidewake-catchable species through the live catch's own
## record initializer (breakthrough.initialize_owned_catch), before any
## --raise-levels; then a production save + title reload validates the team.
var replace_members: Array = []
## Rules v2 #1/#2: disclosed generated 08 boundary (late-route flags, heal,
## production save + title reload, teleport into the Veilfall chamber).
var generate_ending := false
const ENDING_WORLD_FLAGS := ["water_dock_salt_crown_landing_charted", "water_sluice_west_disabled",
	"water_sluice_east_disabled", "water_dock_sluice_isle_both_controls_disabled",
	"defeated_water_trainer_bex", "defeated_water_trainer_calder", "defeated_water_trainer_venn",
	"water_veilfall_intake_stopped", "water_veilfall_return_opened", "water_captain_nerissa_defeated",
	"water_tether_disabled", "water_guardian_freed"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--segment="): segment = arg.trim_prefix("--segment=")
		elif arg.begins_with("--from="): from_dir = arg.trim_prefix("--from=").trim_suffix("/")
		elif arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=").trim_suffix("/")
		elif arg.begins_with("--feast-choices="):
			var choices: Variant = JSON.parse_string(arg.trim_prefix("--feast-choices="))
			if not choices is Dictionary: failures.append("Feast choices must be a JSON UID-to-choice dictionary")
			else: feast_choices = choices
		elif arg.begins_with("--compatibility-manifests="):
			if not compatibility_paths.is_empty() or arg == "--compatibility-manifests=":
				failures.append("Supply one nonempty compatibility manifest list")
			for path: String in arg.trim_prefix("--compatibility-manifests=").split(","):
				if path.strip_edges().is_empty(): failures.append("Compatibility manifest path is empty")
				compatibility_paths.append(path)
		elif arg == "--generate-ending": generate_ending = true
		elif arg.begins_with("--release-route="): pass # The exported binary's packaged-route entry (ACCEPTANCE §7 replays).
		elif arg.begins_with("--raise-levels="): raise_levels = int(arg.trim_prefix("--raise-levels="))
		elif arg.begins_with("--replace-members="):
			for pair: String in arg.trim_prefix("--replace-members=").split(",", false):
				replace_members.append([int(pair.get_slice(":", 0)), pair.get_slice(":", 1)])
		else: failures.append("Unknown option: " + arg)
	if segment in ["07_late", "07_human_late", "07b_calder_venn", "07c_nerissa"]:
		failures.append("Combined/old late runs are retired: use 07a_salt_bex -> 07b_calder -> 07c_venn -> 07d_nerissa with saved handoffs")
		_finish()
		return
	training_job = HOMESTEAD.spec(segment)
	if not training_job.is_empty() and (generate_ending or raise_levels > 0 or not replace_members.is_empty()):
		failures.append("Homestead pieces refuse generated ending/level/member options")
	if not failures.is_empty() or (not SEGMENTS.has(segment) and training_job.is_empty()) or from_dir.is_empty() or out_dir.is_empty():
		failures.append("usage: --segment=<%s> --from=<dir> --out=<dir>" % "|".join(SEGMENTS))
		_finish()
		return
	if OS.has_environment("TB_WORLD_SEED"):
		failures.append("Do not set TB_WORLD_SEED: the saved population is retained")
		_finish()
		return
	from_dir = ProjectSettings.globalize_path(from_dir).simplify_path()
	out_dir = ProjectSettings.globalize_path(out_dir).simplify_path()
	if DirAccess.dir_exists_absolute(out_dir) or not DirAccess.dir_exists_absolute(from_dir.path_join("save")):
		failures.append("Output must be absent and the previous checkpoint must hold save/")
		_finish()
		return
	game = root.get_node("Game")
	if not _prepare_meadows_prefix():
		_finish()
		return
	var input_save := from_dir.path_join("save")
	if meadows_prefix != null:
		input_save = str(meadows_prefix.base).path_join("tidewake_handoff/save")
	if not CHECKPOINTS.copy_tree(input_save, out_dir.path_join("save")):
		failures.append("Could not copy the previous save")
		_finish()
		return
	if meadows_prefix != null:
		var hashes: Dictionary = meadows_prefix.snapshots.tidewake_handoff.files_sha256
		if meadows_prefix.call("_hash_tree", input_save) != hashes \
				or meadows_prefix.call("_hash_tree", out_dir.path_join("save")) != hashes:
			failures.append("Meadows writable Load copy changed verified save bytes")
			_finish()
			return
	# Installed before any title input, reset, world construction or autosave.
	game.set("save_system", SAVE.new(out_dir.path_join("save") + "/"))
	if not await _load_through_title():
		_finish()
		return
	before = _snapshot()
	_handoff_check()
	if failures.is_empty() and not replace_members.is_empty():
		_replace_members()
	if failures.is_empty() and raise_levels > 0:
		_raise_levels()
		before = _snapshot()
	if failures.is_empty() and not replace_members.is_empty():
		await _save_and_reload_generated_team()
		before = _snapshot()
	if failures.is_empty() and generate_ending:
		await _generate_ending_boundary()
	if failures.is_empty():
		await _play()
	if failures.is_empty():
		var after_uids: Array = _snapshot().uids
		var end_realm := "cloudreach" if segment == "09_cloudreach_handoff" else "water"
		if not training_job.is_empty(): end_realm = str(training_job.realm) if training_job.phase == "return" else "meadows"
		if after_uids.size() != 5 or str(game.current_realm) != end_realm or bool(game.get("free_build")):
			failures.append("Piece must end with five companions in %s without free build" % end_realm)
	if failures.is_empty() and not bool(game.call("save_game", 0)):
		failures.append("Game.save_game(0) refused the checkpoint save")
	_finish()


func _load_through_title() -> bool:
	if not bool(game.call("has_save", 0)):
		failures.append("No previous save in slot 0")
		return false
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10: await process_frame
	var load_button := title.get("_load_button") as Button
	if load_button == null:
		failures.append("The production title has no Load button")
		return false
	load_button.pressed.emit()
	await process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Autosave") and not (node as Button).disabled:
			chosen = node
	if chosen == null:
		failures.append("The title's Load list does not offer the Autosave slot")
		return false
	chosen.pressed.emit()
	var world: Node = null
	for _frame in 7200:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and is_instance_valid(scene) \
				and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() \
				and bool(game.call("_realm_scene_ready", scene, str(game.get("current_realm")))):
			world = scene
			break
	if world == null:
		failures.append("The loaded save never reached a ready world scene")
		return false
	for _i in LOAD_SETTLE_FRAMES: await physics_frame
	for _i in 600:
		if INPUT_OWNER.current(self) == null: break
		await process_frame
	if INPUT_OWNER.current(self) != null:
		failures.append("Loaded piece never returned ordinary world input")
		return false
	print("TIDEWAKE PIECE loaded realm=%s player=%s" % [game.current_realm, (world.get_node("Player") as Node3D).global_position])
	return true


## The previous receipt's after-state must come back exactly through Load.
func _handoff_check() -> void:
	if meadows_prefix != null:
		if not meadows_prefix.call("_recheck_compatibility"):
			failures.append_array(meadows_prefix.failures)
			return
		if CHECKPOINTS.commit_sha() != str(meadows_prefix.source_commit):
			failures.append("Meadows consumer source changed during Load")
			return
		var saved: Dictionary = meadows_prefix.snapshots.tidewake_handoff.state
		var loaded_state: Dictionary = meadows_prefix.call("_state")
		if saved != loaded_state:
			failures.append("Meadows exported state differs after production Tidewake Load")
		return
	var prior_path := from_dir.path_join("receipt.json")
	if not FileAccess.file_exists(prior_path):
		if segment in ["07b_calder", "07c_venn", "07d_nerissa", "08_ending"]:
			failures.append("Split late-route continuation requires its predecessor PASS receipt")
			return
		if not training_job.is_empty():
			failures.append("Homestead piece requires its matched predecessor receipt")
			return
		disclosures.append("Start save has no receipt (generated arrival); handoff compared only for five distinct UIDs")
		if before.uids.size() != 5 or _distinct(before.uids) != 5:
			failures.append("Start save must hold five distinct companions")
		return
	var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(prior_path))
	if not prior is Dictionary or prior.get("passed") != true or not prior.get("after") is Dictionary:
		failures.append("Previous checkpoint receipt is missing or not a PASS")
		return
	var predecessor := {"07b_calder": "07a_salt_bex", "07c_venn": "07b_calder", "07d_nerissa": "07c_venn", "08_ending": "07d_nerissa"}
	if predecessor.has(segment):
		var receipt_error := CHECKPOINTS.piece_receipt_error(prior, str(predecessor[segment]), ["uids", "flags", "items", "realm"])
		if not receipt_error.is_empty():
			failures.append("Split late-route " + receipt_error)
			return
	if not prior.get("after") is Dictionary:
		failures.append("Previous checkpoint receipt has no after-state")
		return
	for key: String in TRAINING_HANDOFF.missing_route_fields(prior.after, not training_job.is_empty()):
		failures.append("Previous checkpoint after-state lacks " + key)
		return
	swimmer_uid = str(prior.get("swimmer_uid", ""))
	if not prior.get("meadows_origin", {}) is Dictionary:
		failures.append("Previous checkpoint has malformed Meadows provenance")
		return
	meadows_origin = prior.get("meadows_origin", {}).duplicate(true)
	var expected: Dictionary = prior.after
	# Both sides through the same JSON round trip (the receipt's ints read back as floats).
	var loaded: Dictionary = JSON.parse_string(JSON.stringify(before))
	var training := TRAINING_HANDOFF.compare(expected, before)
	if not bool(training.checked):
		disclosures.append("Training handoff not proven: " + str(training.reason))
		if not training_job.is_empty(): failures.append("Homestead piece requires saved training evidence")
	elif not bool(training.matches):
		failures.append("Training handoff: " + str(training.reason))
	loaded["inventory"] = loaded.items
	var differences := TRAINING_HANDOFF.compare_route(expected, loaded)
	var checks := {}
	for key: String in ["uids", "flags", "inventory", "realm"]:
		checks[key] = not differences.has(key)
	print("TIDEWAKE HANDOFF %s" % JSON.stringify(checks))
	for key: String in checks:
		if not checks[key]:
			failures.append("Handoff %s differs after production Load: saved=%s loaded=%s" % [
				key, JSON.stringify(expected.get(key)), JSON.stringify(loaded.get(key))])


## Reuse the complete Meadows verifier before any Load or writable save copy.
## Changed source cuts use the existing exact producer/log/save review contract.
## Light cuts are not accepted here: their Meadows path filter does not cover
## this consumer's Tidewake runner and route helpers.
func _prepare_meadows_prefix() -> bool:
	var path := from_dir.path_join("receipt.json")
	if not FileAccess.file_exists(path):
		if not compatibility_paths.is_empty():
			failures.append("Compatibility manifests require a Meadows prefix receipt")
			return false
		return true
	var receipt: Variant = SAVE_DOCUMENT.parse(FileAccess.get_file_as_string(path))
	if not receipt is Dictionary:
		failures.append("Previous checkpoint receipt cannot be decoded")
		return false
	if receipt.get("kind", "") not in ["earned_meadows_piece", "f49_ordinary_input_handoff", "f49_generated_fixture_handoff"]:
		if not compatibility_paths.is_empty():
			failures.append("Compatibility manifests require the Meadows prefix import")
			return false
		return true
	if segment != "01_opening" or receipt.get("boundary") != "tidewake_handoff" \
			or raise_levels > 0 or not replace_members.is_empty() or generate_ending:
		failures.append("Meadows prefix may only enter the unmodified Tidewake opening")
		return false
	var profile: String = str(receipt.get("profile", ""))
	if not profile.is_empty() and profile != MEADOWS_HANDOFF.TRAINING_PROFILE:
		failures.append("Unknown Meadows predecessor profile")
		return false
	var order: Array = MEADOWS_HANDOFF.TRAINED_MEADOWS_PIECES if profile == MEADOWS_HANDOFF.TRAINING_PROFILE else MEADOWS_HANDOFF.MEADOWS_PIECES
	var realms: Array = MEADOWS_HANDOFF.TRAINED_MEADOWS_REALMS if profile == MEADOWS_HANDOFF.TRAINING_PROFILE else MEADOWS_HANDOFF.MEADOWS_REALMS
	meadows_prefix = MEADOWS_HANDOFF.new(self, game, out_dir + "_meadows_prefix", order, realms, MEADOWS_HANDOFF.MEADOWS_SLOT)
	for manifest_path: String in compatibility_paths:
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if not manifest is Dictionary or manifest.get("kind") != "f49_reviewed_cross_cut":
			failures.append("Tidewake import requires a full reviewed cross-cut manifest")
			return false
	if not meadows_prefix.call("configure_compatibility", compatibility_paths, "tidewake_01_opening"):
		failures.append_array(meadows_prefix.failures)
		return false
	if meadows_prefix.call("import_prefix", from_dir, "earned") != "tidewake_handoff":
		failures.append_array(meadows_prefix.failures)
		return false
	meadows_origin = {"commit": meadows_prefix.source_commit,
		"profile": profile,
		"journey_id": meadows_prefix.journey_id, "prefix": meadows_prefix.base,
		"predecessors": meadows_prefix.history.duplicate(true),
		"compatibility_transition": meadows_prefix.compatibility_transition.duplicate(true),
		"compatibility_manifests": meadows_prefix.compatibility_files.duplicate(true)}
	return true


func copy_tree(from: String, to: String) -> bool:
	return CHECKPOINTS.copy_tree(from, to)


func _generate_ending_boundary() -> void:
	if segment != "08_ending":
		failures.append("--generate-ending is only for 08_ending")
		return
	for flag: String in ENDING_WORLD_FLAGS:
		game.world.flags.set_flag(flag)
	for creature: RefCounted in game.party.members():
		creature.heal_fully()
	if not bool(game.call("save_game", 0)):
		failures.append("Generated ending boundary: production save refused")
		return
	current_scene.queue_free()
	for _i in 4: await process_frame
	if not await _load_through_title():
		return
	var world := current_scene as Node3D
	var cave := world.get_node_or_null("WaterVeilfall") as Node3D
	var player := world.get_node("Player") as CharacterBody3D
	if cave == null:
		failures.append("Generated ending boundary: no WaterVeilfall")
		return
	var chamber: Vector3 = (cave.get("interior") as Node3D).global_position + Vector3(0, 1.0, 87)
	player.global_position = chamber
	player.velocity = Vector3.ZERO
	for _i in 120: await physics_frame
	if not bool(cave.call("contains_interior", player.global_position)) or not player.is_on_floor():
		failures.append("Generated ending boundary: teleport did not settle inside the Veilfall chamber (%s)" % player.global_position)
		return
	var ally_director := world.get_node_or_null("EncounterDirector")
	if ally_director != null and ally_director.call("ally_body") == null:
		Input.action_press(&"creature_recall")
		await physics_frame
		Input.action_release(&"creature_recall")
		for _i in 60: await physics_frame
	disclosures.append("GENERATED INPUT (Rules v2 #1/#2): 08 boundary from the 05 checkpoint: world flags %s set, the same five healed, production save + title reload, player teleported into the Veilfall chamber at %s; the late route itself (07) is not credited" % [str(ENDING_WORLD_FLAGS), player.global_position])
	before = _snapshot()


func _replace_members() -> void:
	var party: RefCounted = game.party
	var level := int(party.call("members")[0].get("level"))
	var lines: Array = []
	# Highest index first, so earlier indices still name their original slot.
	var ordered := replace_members.duplicate()
	ordered.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	for pair: Array in ordered:
		var index := int(pair[0])
		var species := str(pair[1])
		var members: Array = party.call("members")
		if index < 1 or index >= members.size() or str(members[index].get("uid")) == swimmer_uid:
			failures.append("--replace-members: slot %d is the lead, out of range or the swimmer" % index)
			return
		var old: RefCounted = party.call("remove_at", index)
		if old == null:
			failures.append("--replace-members: the party refused to release slot %d" % index)
			return
		game.local.redesign_character.creatures.erase(str(old.get("uid")))
		var fresh: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn(species)
		if fresh == null:
			failures.append("--replace-members: unknown species " + species)
			return
		fresh.call("set_level", level, preload("res://scripts/creatures/progression.gd").config())
		if not bool(party.call("add", fresh)):
			failures.append("--replace-members: the party refused " + species)
			return
		var record := preload("res://scripts/creatures/breakthrough.gd").initialize_owned_catch(party, game.local.redesign_character, fresh)
		if record.is_empty():
			failures.append("--replace-members: the live catch initializer refused " + species)
			return
		game.local.redesign_character = record
		fresh.call("heal_fully")
		lines.append("slot %d %s L%d -> %s L%d (%s)" % [index, str(old.get("species_id")), int(old.get("level")), species, level, str(fresh.get("uid"))])
	disclosures.append("GENERATED TEAM (Rules v2 #1, coordinator 2026-10-11): " + "; ".join(lines) + " via breakthrough.initialize_owned_catch, then production save + title reload")


func _save_and_reload_generated_team() -> void:
	if not bool(game.call("save_game", 0)):
		failures.append("Generated team: production save refused")
		return
	current_scene.queue_free()
	for _i in 4: await process_frame
	await _load_through_title()


func _raise_levels() -> void:
	if raise_levels < 1 or raise_levels > 55:
		failures.append("--raise-levels outside the authored 1..55 range")
		return
	var levels_before: Array = []
	for creature: RefCounted in game.party.members():
		levels_before.append(int(creature.level))
		creature.level = raise_levels
		creature.xp = 0
		creature.recompute_stats_from_base(preload("res://scripts/creatures/progression.gd").config())
		var tiers: Variant = preload("res://scripts/creatures/breakthrough.gd").caught_tiers(raise_levels)
		var record: Dictionary = game.local.redesign_character.creatures[creature.uid]
		record.breakthroughs = tiers
		record.cap_level = preload("res://scripts/creatures/breakthrough.gd").level_cap(tiers)
		creature.heal_fully()
	disclosures.append("GENERATED INPUT (Rules v2 #1): after production Load, the same five (uids unchanged) were raised from %s to L%d with the generator's level/cap/breakthrough code and fully healed; no other state changed" % [str(levels_before), raise_levels])


func _play() -> void:
	var world := current_scene as Node3D
	if not training_job.is_empty():
		_take(await HOMESTEAD.new().run(self, world, game, {"segment": segment,
			"previous_training": before.get("training", {}), "choices": feast_choices}), "passed", segment)
		return
	var player := world.get_node("Player") as CharacterBody3D
	var rig := world.get_node("CameraRig") as Node3D
	match segment:
		"01_opening":
			var opening: RefCounted = load("res://tests/helpers/f49_tidewake_opening.gd").new()
			_take(await opening.run(self, world, game), "passed", "opening")
		"02_reedhaven":
			await _setup_run(load("res://tests/helpers/water_reedhaven_segment.gd").new(), world, player, rig, "reedhaven")
		"03_brine":
			await _setup_run(load("res://tests/helpers/water_brine_segment.gd").new(), world, player, rig, "brine")
		"04_shellwatch":
			await _setup_run(load("res://tests/helpers/water_shellwatch_segment.gd").new(), world, player, rig, "shellwatch")
		"05_tidal":
			await _setup_run(load("res://tests/helpers/water_tidal_segment.gd").new(), world, player, rig, "tidal")
		"05a_tidal_return", "05b_shellwatch_return", "05c_brine_return", "05d_reedhaven_departure":
			var phase := segment.substr(4)
			await _setup_run(load("res://tools/earned_saves/ione_visit.gd").new(phase), world, player, rig, segment)
		"05r_first_shore", "05s_reedhaven_ione", "05t_reedhaven_brine", "05u_brine_shellwatch", "05v_shellwatch_tidal":
			await _setup_run(load("res://tools/earned_saves/ione_visit.gd").new(segment.substr(4)), world, player, rig, segment)
		"05i_ione_approach", "05j_ione_duel":
			var phase := "approach" if segment == "05i_ione_approach" else "duel"
			await _setup_run(load("res://tools/earned_saves/ione_visit.gd").new(phase), world, player, rig, segment)
		"05j_ione_duel_only", "05k_ione_chest":
			var phase := "duel_only" if segment == "05j_ione_duel_only" else "chest"
			await _setup_run(load("res://tools/earned_saves/ione_visit.gd").new(phase), world, player, rig, segment)
		"06_swimmer":
			var prep: RefCounted = load("res://tests/helpers/water_earned_swimmer_preparation_segment.gd").new()
			_take(await prep.run(self, world, game), "passed", "swimmer_preparation")
			var caught: RefCounted = prep.get("swimmer")
			swimmer_uid = str(caught.get("uid")) if caught != null else ""
			for _i in 60: await physics_frame
		"07_late":
			var late: RefCounted = load("res://tests/helpers/water_earned_late_segment.gd").new()
			late.setup(self, world, player, rig)
			var riding: Node = world.get_node_or_null("RidingController")
			var swimmer: RefCounted = null
			for member: RefCounted in game.get("party").call("members"):
				if str(member.get("uid")) == swimmer_uid: swimmer = member
			if riding == null or swimmer == null:
				failures.append("07_late: no RidingController or the 06 receipt's swimmer uid %s is not in the loaded five" % swimmer_uid)
				return
			if not bool(riding.call("is_mounted")):
				# A mount is live-only state (not saved). Remount the retained
				# swimmer by the late helper's own ordinary input step.
				disclosures.append("07_late: mount is not persisted by save; remounted the 06 swimmer through the late helper's own _mount_existing (deploy, walk, riding press) before run_from_mount")
				late.set("_swimmer", swimmer)
				late.set("_riding", riding)
				late.set("_deadline", Time.get_ticks_msec() + int(late.get("watchdog_ms")))
				if not await late.call("_mount_existing", "post-load remount"):
					_take(late.result(), "passed", "late_remount")
					return
			var ok: bool = await late.run_from_mount(swimmer, func(reason: String) -> void: failures.append("late abort: " + reason))
			_take(late.result(), "passed", "late")
			if not ok and failures.is_empty(): failures.append("late returned false")
		"07a_salt_bex", "07b_calder", "07c_venn", "07d_nerissa":
			# Critical path with the same five (WORLD §6 retained-team override):
			# the player's own swimming over the sheltered late crossings.
			var human: RefCounted = load("res://tests/helpers/water_human_late_segment.gd").new()
			human.setup(self, world, player, rig)
			var pieces := {"07a_salt_bex": "salt_bex", "07b_calder": "calder", "07c_venn": "venn", "07d_nerissa": "nerissa"}
			var ok: bool = await human.run_human(str(pieces.get(segment, "all")))
			_take(human.result(), "passed", "human_late")
			if not ok and failures.is_empty(): failures.append("human late returned false")
		"08_ending":
			_take(await load("res://tests/helpers/water_earned_ending_segment.gd").new().run_earned(self, world, game), "ok", "ending")
		"09_cloudreach_handoff":
			# As earned_chain_runner's tidewake_handoff, one chapter on: Home Key
			# home, hang the earned Tidewake relic, Use/Enter the Cloudreach arch.
			var travel: RefCounted = load("res://tests/helpers/f20_portal_travel.gd").new(self, game)
			var passed: bool = await travel.home_key() and await travel.hang_relic("tidewake") \
				and await travel.enter("cloudreach", "cloudreach")
			if passed:
				for _i in 300:
					await physics_frame
			helper_receipts.append({"segment": "cloudreach_handoff", "passed": passed})
			if not passed:
				failures.append_array(travel.failures)
				if travel.failures.is_empty(): failures.append("cloudreach_handoff: portal travel failed without a receipt")


func _setup_run(helper: RefCounted, world: Node3D, player: CharacterBody3D, rig: Node3D, label: String) -> void:
	helper.setup(self, world, player, rig)
	var completed: bool = await helper.run()
	_take(helper.result(), "ok", label)
	if not completed and failures.is_empty():
		failures.append(label + " returned false despite an accepted result")


func _take(result: Dictionary, key: String, label: String) -> bool:
	var receipts: Variant = result.get("receipts", result.get("transcript", []))
	helper_receipts.append({"segment": label, "passed": bool(result.get(key, false)),
		"receipts": JSON.parse_string(JSON.stringify(receipts))})
	for line: Variant in result.get("failures", result.get("errors", [])):
		failures.append("%s: %s" % [label, str(line)])
	if not bool(result.get(key, false)) and failures.is_empty():
		failures.append("%s returned %s=false: %s" % [label, key, JSON.stringify(result).left(2000)])
	return failures.is_empty()


func _snapshot() -> Dictionary:
	var uids: Array = []
	var party: Array = []
	for member: RefCounted in game.get("party").call("members"):
		uids.append(str(member.get("uid")))
		party.append({"uid": str(member.get("uid")), "species": str(member.get("species_id")),
			"level": int(member.get("level")), "hp": int(member.get("hp")), "fainted": bool(member.get("fainted"))})
	var flags: Array = (game.get("progression").call("all_set") as Array).duplicate()
	flags.sort()
	var items := {}
	var inventory: RefCounted = game.get("inventory")
	for i in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if not stack.is_empty():
			items[str(stack.get("id", ""))] = int(items.get(str(stack.get("id", "")), 0)) + int(stack.get("n", 0))
	var player := current_scene.get_node_or_null("Player") as Node3D if current_scene != null else null
	return {"training": TRAINING_HANDOFF.snapshot(game), "ending": TRAINING_HANDOFF.ending_snapshot(game),
		"uids": uids, "party": party, "flags": flags, "items": items, "realm": str(game.get("current_realm")),
		"day": int(game.get("day")), "player": [player.global_position.x, player.global_position.y,
			player.global_position.z] if player != null else []}


func _distinct(values: Array) -> int:
	var seen := {}
	for v: Variant in values: seen[v] = true
	return seen.size()


func _finish() -> void:
	if not failures.is_empty() and current_scene != null and current_scene.get_node_or_null("Player") != null:
		var at := (current_scene.get_node("Player") as Node3D).global_position
		var arbiter := current_scene.get_node_or_null("InteractionArbiter")
		var winner: Variant = arbiter.call("winning_provider") if arbiter != null else null
		print("TIDEWAKE FAIL DIAG player=%s winner=%s" % [at, (winner as Node).get_path() if winner is Node else "none"])
		var director := current_scene.get_node_or_null("EncounterDirector")
		if director != null:
			var ally: Variant = director.call("ally_body") if director.has_method("ally_body") else null
			print("TIDEWAKE FAIL DIAG ally=%s pos=%s visible=%s" % [ally, (ally as Node3D).global_position if is_instance_valid(ally) else "-",
				(ally as Node3D).visible if is_instance_valid(ally) else "-"])
		var alpha := current_scene.get_node_or_null("WaterAlpha")
		if alpha != null:
			var abody: Variant = alpha.get("body")
			print("TIDEWAKE FAIL DIAG alpha ready=%s body_valid=%s species=%s level=%s pos=%s" % [alpha.get("ready_for_intents"),
				is_instance_valid(abody), abody.instance.species_id if is_instance_valid(abody) and abody.get("instance") != null else "-",
				abody.instance.level if is_instance_valid(abody) and abody.get("instance") != null else "-",
				(abody as Node3D).global_position if is_instance_valid(abody) else "-"])
		for n: Node in current_scene.find_children("*", "Node3D", true, false):
			if n.name.begins_with("Interactable") and (n as Node3D).global_position.distance_to(at) < 8.0:
				print("TIDEWAKE FAIL DIAG near %s d=%.2f parent_pos=%s" % [n.get_path(), (n as Node3D).global_position.distance_to(at), (n.get_parent() as Node3D).global_position if n.get_parent() is Node3D else "-"])
	var after := _snapshot() if game != null and current_scene != null else {}
	var gained: Array = []
	if not before.is_empty() and not after.is_empty():
		gained = after.flags.filter(func(f: Variant) -> bool: return not before.flags.has(f))
	var generated: Array = []
	if generate_ending: generated.append("generated ending flags, healing and position")
	if raise_levels > 0: generated.append("generated levels to %d" % raise_levels)
	if not replace_members.is_empty(): generated.append("generated party replacements " + JSON.stringify(replace_members))
	var lineage := LINEAGE.from_directory(from_dir, generated, meadows_prefix != null and not meadows_origin.is_empty())
	var receipt := {"segment": segment, "passed": failures.is_empty(), "failures": failures,
		"from": from_dir, "out": out_dir, "input_mode": LINEAGE.input_mode(lineage), "lineage": lineage,
		"commit": CHECKPOINTS.commit_sha(),
		"wall_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"before": before, "after": after, "flags_gained": gained,
		"swimmer_uid": swimmer_uid, "meadows_origin": meadows_origin,
		"disclosures": disclosures, "helper_receipts": helper_receipts}
	if not out_dir.is_empty() and DirAccess.dir_exists_absolute(out_dir):
		var file := FileAccess.open(out_dir.path_join("receipt.json" if failures.is_empty() else "receipt.FAILED.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(receipt, "  "))
			file.close()
	print("TIDEWAKE PIECE RESULT %s" % JSON.stringify({"segment": segment, "passed": failures.is_empty(),
		"wall_seconds": receipt.wall_seconds, "failures": failures, "flags_gained": gained.size(),
		"uids": after.get("uids", [])}))
	quit(0 if failures.is_empty() else 1)
