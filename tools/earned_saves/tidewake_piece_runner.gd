extends SceneTree

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
##   06_swimmer      water_earned_swimmer_preparation_segment (swimmer catch,
##                   paid saddle, mounted)
##   07_late         water_earned_late_segment.run_from_mount (Salt Crown ->
##                   Sluice -> Veilfall -> Nerissa -> tether)
##   07_human_late   water_human_late_segment.run_human: the same late route by the
##                   player's own swimming with the same five (no swimmer/saddle)
##   08_ending       water_earned_ending_segment.run_earned (Guardian invite)
##
## USAGE
##   godot --headless --path . --script tools/earned_saves/tidewake_piece_runner.gd -- \
##     --segment=<id> --from=<previous checkpoint dir> --out=<new checkpoint dir>
##   <previous checkpoint dir> holds save/ (and receipt.json unless it is the
##   generated arrival). <new checkpoint dir> must be absent.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const SEGMENTS := ["01_opening", "02_reedhaven", "03_brine", "04_shellwatch", "05_tidal",
	"06_swimmer", "07_late", "07_human_late", "08_ending"]
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
## Rules v2 #1: disclosed generated input. Raise the same five to this level
## (generator's own level/cap/breakthrough code, full heal) after Load.
var raise_levels := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--segment="): segment = arg.trim_prefix("--segment=")
		elif arg.begins_with("--from="): from_dir = arg.trim_prefix("--from=").trim_suffix("/")
		elif arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=").trim_suffix("/")
		elif arg.begins_with("--raise-levels="): raise_levels = int(arg.trim_prefix("--raise-levels="))
		else: failures.append("Unknown option: " + arg)
	if not SEGMENTS.has(segment) or from_dir.is_empty() or out_dir.is_empty():
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
	if not CHECKPOINTS.copy_tree(from_dir.path_join("save"), out_dir.path_join("save")):
		failures.append("Could not copy the previous save")
		_finish()
		return
	game = root.get_node("Game")
	# Installed before any title input, reset, world construction or autosave.
	game.set("save_system", SAVE.new(out_dir.path_join("save") + "/"))
	if not await _load_through_title():
		_finish()
		return
	before = _snapshot()
	_handoff_check()
	if failures.is_empty() and raise_levels > 0:
		_raise_levels()
		before = _snapshot()
	if failures.is_empty():
		await _play()
	if failures.is_empty():
		var after_uids: Array = _snapshot().uids
		if after_uids.size() != 5 or str(game.current_realm) != "water" or bool(game.get("free_build")):
			failures.append("Piece must end with five companions in Water without free build")
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
	var prior_path := from_dir.path_join("receipt.json")
	if not FileAccess.file_exists(prior_path):
		disclosures.append("Start save has no receipt (generated arrival); handoff compared only for five distinct UIDs")
		if before.uids.size() != 5 or _distinct(before.uids) != 5:
			failures.append("Start save must hold five distinct companions")
		return
	var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(prior_path))
	if not prior is Dictionary or not prior.get("passed", false):
		failures.append("Previous checkpoint receipt is missing or not a PASS")
		return
	swimmer_uid = str(prior.get("swimmer_uid", ""))
	var expected: Dictionary = prior.after
	# Both sides through the same JSON round trip (the receipt's ints read back as floats).
	var loaded: Dictionary = JSON.parse_string(JSON.stringify(before))
	var checks := {}
	for key: String in ["uids", "flags", "items", "realm"]:
		checks[key] = loaded[key] == expected[key]
	print("TIDEWAKE HANDOFF %s" % JSON.stringify(checks))
	for key: String in checks:
		if not checks[key]:
			failures.append("Handoff %s differs after production Load: saved=%s loaded=%s" % [
				key, JSON.stringify(expected[key]), JSON.stringify(before[key])])


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
		"07_human_late":
			# Critical path with the same five (WORLD §6 retained-team override):
			# the player's own swimming over the sheltered late crossings.
			var human: RefCounted = load("res://tests/helpers/water_human_late_segment.gd").new()
			human.setup(self, world, player, rig)
			var ok: bool = await human.run_human()
			_take(human.result(), "passed", "human_late")
			if not ok and failures.is_empty(): failures.append("human late returned false")
		"08_ending":
			_take(await load("res://tests/helpers/water_earned_ending_segment.gd").new().run_earned(self, world, game), "ok", "ending")


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
	return {"uids": uids, "party": party, "flags": flags, "items": items, "realm": str(game.get("current_realm")),
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
	var receipt := {"segment": segment, "passed": failures.is_empty(), "failures": failures,
		"from": from_dir, "out": out_dir, "input_mode": "generated_levels" if raise_levels > 0 else "earned", "commit": CHECKPOINTS.commit_sha(),
		"wall_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"before": before, "after": after, "flags_gained": gained,
		"swimmer_uid": swimmer_uid, "disclosures": disclosures, "helper_receipts": helper_receipts}
	if not out_dir.is_empty() and DirAccess.dir_exists_absolute(out_dir):
		var file := FileAccess.open(out_dir.path_join("receipt.json" if failures.is_empty() else "receipt.FAILED.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(receipt, "  "))
			file.close()
	print("TIDEWAKE PIECE RESULT %s" % JSON.stringify({"segment": segment, "passed": failures.is_empty(),
		"wall_seconds": receipt.wall_seconds, "failures": failures, "flags_gained": gained.size(),
		"uids": after.get("uids", [])}))
	quit(0 if failures.is_empty() else 1)
