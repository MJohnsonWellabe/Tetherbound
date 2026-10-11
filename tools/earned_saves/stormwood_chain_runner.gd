extends SceneTree

## F19#5 Stormwood pieces: one ordinary-input segment per process, mirroring
## `earned_chain_runner.gd`'s piece protocol for the fourth chapter.
##
## Each piece copies the previous checkpoint's save/ to a writable scratch,
## loads it through the production title's Load list (Autosave, slot 0), waits
## for ordinary world input, runs one existing earned helper read-only, and on
## success writes the same slot through `Game.save_game()`. No teleport,
## flag/inventory/party write, HP pin or debug skip occurs here. The only
## disclosed setting is the Stormwood smoke's simulation clock (8x scale at
## 480 Hz, the production 1/60 step preserved); helpers that need it switch
## their own fights and walks to 1x.
##
## The loaded state is compared with the previous checkpoint's receipt
## (`after`): the same five UIDs in order, the same world/player flags, items
## and opened portals. A mismatch refuses the piece before play.
##
## PIECES (executable dependency order; see each helper's own preconditions)
##   arrival_prefix  arrival -> Hesk/Tamsin/Break -> Glass Field -> Ondra recipe
##                   (`smoke_stormwood_continuous.gd` Segment)
##   crown_build     Capacitor Alpha, Crown gathering, frames, paid Crown arch
##   rootgate        Crown guardian, Wen, heartstone, Rootgate released
##   named_detour    optional named wilds the route does not fight (F10#2)
##   dynamo          Deepwood, rods, Kestrel, physical core arrival
##   marrow          Marrow five rounds and the four-conduit Break
##   aftermath       Stormheart accepted at five, release ceremony, Waterward view
##   settlement      Stormheart declined (keeps the five), new-order F49 ending
##   home_key        personal Home Key used from Stormwood (f49_portal_travel)
##
## USAGE
##   godot --headless --path . --script tools/earned_saves/stormwood_chain_runner.gd -- \
##     --segment=<id> --from=<checkpoint dir with save/> --out=<absent dir>
const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const SLOT := 0
const LOAD_SETTLE_FRAMES := 300
const PIECES := {
	"arrival_prefix": "res://tests/smoke_stormwood_continuous.gd",
	"crown_build": "res://tests/helpers/stormwood_crown_build_segment.gd",
	"rootgate": "res://tests/helpers/stormwood_earned_rootgate_segment.gd",
	"named_detour": "res://tests/helpers/stormwood_b_named_detour_segment.gd",
	"dynamo": "res://tests/helpers/stormwood_earned_dynamo_segment.gd",
	"marrow": "res://tests/helpers/stormwood_earned_marrow_segment.gd",
	"aftermath": "res://tests/helpers/stormwood_earned_aftermath_segment.gd",
	"settlement": "res://tests/helpers/f49_stormheart_settlement.gd",
	"home_key": "res://tests/helpers/f49_portal_travel.gd",
}
const NAMED_IDS := ["capacitor_alpha", "hollows_alpha", "blackwater_elder",
	"old_rodfolk_hall_guardian", "glass_field_alpha"]

var segment := ""
var from_dir := ""
var out_dir := ""
var failures: Array[String] = []
var disclosures: Array[String] = []
var game: Node
var started_ms := 0
var before := {}
var helper_result := {}
var handoff := {}
var max_steps := 8


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--segment="): segment = arg.trim_prefix("--segment=")
		elif arg.begins_with("--from="): from_dir = arg.trim_prefix("--from=")
		elif arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--max-steps="): max_steps = int(arg.trim_prefix("--max-steps="))
		else: failures.append("Unknown option: " + arg)
	from_dir = ProjectSettings.globalize_path(from_dir).simplify_path().trim_suffix("/")
	out_dir = ProjectSettings.globalize_path(out_dir).simplify_path().trim_suffix("/")
	if not PIECES.has(segment) or from_dir.is_empty() or out_dir.is_empty():
		failures.append("usage: --segment=<%s> --from=<dir> --out=<dir>" % "|".join(PIECES.keys()))
	elif DirAccess.dir_exists_absolute(out_dir) or FileAccess.file_exists(out_dir):
		failures.append("Output exists; refusing overwrite: " + out_dir)
	elif not DirAccess.dir_exists_absolute(from_dir.path_join("save")):
		failures.append("Previous checkpoint has no save/: " + from_dir)
	elif OS.has_environment("TB_WORLD_SEED"):
		failures.append("TB_WORLD_SEED must be unset: the saved population is retained")
	var commit := CHECKPOINTS.commit_sha()
	if commit.length() != 40:
		failures.append("Exact clean source commit required before play: " + commit)
	if not failures.is_empty():
		_finish(commit)
		return
	var working := out_dir + "_working"
	if DirAccess.dir_exists_absolute(working) or not CHECKPOINTS.copy_tree(from_dir.path_join("save"), working):
		failures.append("Could not stage a fresh writable copy at " + working)
		_finish(commit)
		return
	game = root.get_node("Game")
	game.set("save_system", SAVE.new(working))
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = max_steps
	disclosures.append("Simulation clock 8x at 480 Hz, %d physics steps per frame (smoke_stormwood_continuous.gd's scale; the 8-step cap keeps production's per-frame granularity, <= 0.13 s of sim between process frames, so input releases and claim settlement are not starved on a slow host); helpers switch fights/walks to 1x themselves" % max_steps)
	print("STORMWOOD CHAIN segment=%s from=%s out=%s commit=%s" % [segment, from_dir, out_dir, commit])
	if await _load_previous():
		before = _state()
		_handoff_check()
		if failures.is_empty():
			_watch_weather.call_deferred()
			if segment == "arrival_prefix": _watch_seam.call_deferred()
			await _play()
	if failures.is_empty():
		var after := _state()
		if segment != "aftermath" and (after.uids as Array) != (before.uids as Array):
			failures.append("Piece changed the five UIDs: %s -> %s" % [str(before.uids), str(after.uids)])
		if not bool(game.call("save_game", SLOT)):
			failures.append("Game.save_game(%d) refused the checkpoint save" % SLOT)
		elif not CHECKPOINTS.copy_tree(working, out_dir.path_join("save")):
			failures.append("Could not copy the written save into " + out_dir)
	CHECKPOINTS.remove_tree(working)
	_finish(commit)


func _load_previous() -> bool:
	if not bool(game.call("has_save", SLOT)):
		failures.append("Previous save has no autosave slot %d" % SLOT)
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
		failures.append("The title's Load list does not offer the Autosave")
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
	print("STORMWOOD CHAIN loaded realm=%s player=%s" % [game.get("current_realm"),
		(world.get_node("Player") as Node3D).global_position])
	return true


## The previous checkpoint's own after-state is the handoff contract.
func _handoff_check() -> void:
	var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(from_dir.path_join("receipt.json")))
	if not receipt is Dictionary or not (receipt as Dictionary).get("after") is Dictionary:
		handoff = {"checked": false, "reason": "previous checkpoint has no receipt.json after-state (generated input)"}
		return
	var expected: Dictionary = receipt.after
	var mismatched: Array = []
	for key: String in ["uids", "species", "world_flags", "player_flags", "items", "portal_unlocks", "realm"]:
		if JSON.stringify(expected.get(key)) != JSON.stringify(before.get(key)):
			mismatched.append(key)
	handoff = {"checked": true, "previous": from_dir.get_file(), "mismatched": mismatched,
		"passed": mismatched.is_empty()}
	if not mismatched.is_empty():
		for key: String in mismatched:
			failures.append("Handoff mismatch %s: saved %s, loaded %s" % [key,
				JSON.stringify(expected.get(key)), JSON.stringify(before.get(key))])


func _play() -> void:
	var world := current_scene as Node3D
	var script: GDScript = load(PIECES[segment])
	match segment:
		"arrival_prefix":
			helper_result = await script.Segment.new().run(self, world, game)
		"named_detour":
			helper_result = await script.new().run_named(self, world, game, NAMED_IDS)
			var outcomes: Dictionary = helper_result.get("outcomes", {})
			for id: String in NAMED_IDS:
				if not str(outcomes.get(id, "")) in ["cleared", "already_cleared"]:
					failures.append("named detour %s -> %s" % [id, str(outcomes.get(id, "missing"))])
			helper_result["passed"] = failures.is_empty()
		"home_key":
			var travel: RefCounted = script.new(self, game)
			var passed: bool = await travel.call("home_key")
			helper_result = {"passed": passed, "failures": travel.get("failures"),
				"transcript": [], "realm_after": str(game.get("current_realm"))}
		_:
			helper_result = await script.new().run(self, world, game)
	for line: Variant in helper_result.get("failures", []):
		failures.append("%s: %s" % [segment, str(line)])
	if not bool(helper_result.get("passed", false)) and failures.is_empty():
		failures.append("%s helper returned passed=false" % segment)


## Diagnostic only: the host's achieved simulation rate and the Surge phase.
func _watch_weather() -> void:
	var last_ms := Time.get_ticks_msec()
	var last_sim := -1.0
	while true:
		while Time.get_ticks_msec() - last_ms < 15000:
			await process_frame
		var surge := current_scene.get_node_or_null("StormwoodSurge") if current_scene != null else null
		var env: Variant = (game.get("realm_environment") as Dictionary).get("stormwood", {})
		var sim := float((env as Dictionary).get("elapsed", 0.0)) if env is Dictionary else 0.0
		var player := current_scene.get_node_or_null("Player") as Node3D if current_scene != null else null
		print("STORMWOOD CHAIN clock sim=%.1f sim/wall=%.2f phase=%s sheltered=%s at=%s" % [sim,
			(sim - last_sim) / (float(Time.get_ticks_msec() - last_ms) / 1000.0) if last_sim >= 0.0 else 0.0,
			str(surge.get("phase")) if surge != null else "-", str(surge.get("sheltered")) if surge != null else "-",
			str(player.global_position) if player != null else "-"])
		last_sim = sim
		last_ms = Time.get_ticks_msec()


## Diagnostic only: the first charged seam's prompt and what moves the player
## near it, a few times a second while within 8 m.
func _watch_seam() -> void:
	var last_ms := 0
	while true:
		await physics_frame
		if current_scene == null or Time.get_ticks_msec() - last_ms < 250: continue
		var seam := current_scene.get_node_or_null("StormwoodHarvests/stormwood_harvest_cinder_verge_018") as Node3D
		var player := current_scene.get_node_or_null("Player") as CharacterBody3D
		if player == null: continue
		var at := Vector3(-762.0, 27.3, 893.0) if seam == null else seam.global_position
		if player.global_position.distance_to(at) > 8.0: continue
		last_ms = Time.get_ticks_msec()
		var prompt := seam.get_node_or_null("Interactable") if seam != null else null
		var near: Array = []
		for body: Node3D in current_scene.find_children("*", "CharacterBody3D", true, false):
			if body != player and body.global_position.distance_to(player.global_position) < 3.0:
				near.append("%s@%.2f" % [body.get_path(), body.global_position.distance_to(player.global_position)])
		var surge := current_scene.get_node_or_null("StormwoodSurge")
		print("STORMWOOD CHAIN seam valid=%s visible=%s taken=%s enabled=%s offer=%s phase=%s player=%s vel=%s floor=%s near=%s fighting=%s" % [
			seam != null, seam.visible if seam != null else false, str(seam.get("_taken")) if seam != null else "-",
			str(prompt.get("enabled")) if prompt != null else "-",
			str(prompt.call("interaction_offer", player.global_position)) if prompt != null else "-",
			str(surge.get("phase")) if surge != null else "-", str(player.global_position), str(player.velocity),
			player.is_on_floor(), str(near), str(current_scene.get_node("CombatManager").call("is_fighting")) if current_scene.has_node("CombatManager") else "-"])


func _state() -> Dictionary:
	var uids: Array = []
	var species: Array = []
	var condition: Array = []
	for member: RefCounted in game.get("party").call("members"):
		uids.append(str(member.get("uid")))
		species.append(str(member.get("species_id")))
		condition.append({"level": int(member.get("level")), "hp": snappedf(float(member.get("hp")), 0.1),
			"max_hp": int(member.get("max_hp")), "fainted": bool(member.get("fainted"))})
	var items := {}
	var inventory: RefCounted = game.get("inventory")
	for i in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if not stack.is_empty():
			items[str(stack.id)] = int(items.get(str(stack.id), 0)) + int(stack.get("n", 0))
	var world_flags: Array = (game.get("progression").call("all_set") as Array).duplicate()
	world_flags.sort()
	var player_flags: Array = []
	var personal: RefCounted = game.call("player_flags")
	if personal != null and personal.has_method("all_set"):
		player_flags = (personal.call("all_set") as Array).duplicate()
		player_flags.sort()
	var route: Dictionary = game.get("world").get("redesign_world")
	var player := current_scene.get_node_or_null("Player") as Node3D if current_scene != null else null
	return {"uids": uids, "species": species, "condition": condition, "items": items,
		"world_flags": world_flags, "player_flags": player_flags,
		"portal_unlocks": route.get("portal_unlocks", []), "realm": str(game.get("current_realm")),
		"position": [snappedf(player.global_position.x, 0.1), snappedf(player.global_position.y, 0.1),
			snappedf(player.global_position.z, 0.1)] if player != null else []}


func _finish(commit: String) -> void:
	var passed := failures.is_empty()
	var transcript: Variant = JSON.parse_string(JSON.stringify(helper_result.get("transcript", [])))
	for line: Variant in (transcript if transcript is Array else []):
		print("STORMWOOD CHAIN — %s" % str(line))
	var after := _state() if game != null and current_scene != null and passed else {}
	var gained: Array = []
	if passed:
		for flag: String in after.world_flags + after.player_flags:
			if not (before.world_flags as Array).has(flag) and not (before.player_flags as Array).has(flag):
				gained.append(flag)
	var receipt := {"kind": "stormwood_earned_piece", "segment": segment, "passed": passed,
		"commit": commit, "from": from_dir, "handoff": handoff, "before": before, "after": after,
		"flags_gained": gained, "failures": failures, "disclosures": disclosures,
		"helper": PIECES.get(segment, ""), "helper_outcomes": helper_result.get("outcomes", {}),
		"wall_seconds": snappedf(float(Time.get_ticks_msec() - started_ms) / 1000.0, 0.1),
		"transcript": transcript}
	if passed:
		var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(from_dir.path_join("PROVENANCE.json")))
		var injections: Array = []
		if source is Dictionary and (source as Dictionary).get("prior_earned_play") == false:
			injections.append("Lineage starts from a disclosed generated arrival: " + from_dir.get_file())
		elif source is Dictionary:
			injections.append_array((source as Dictionary).get("injections", []))
		var provenance := {"kind": "stormwood_earned_checkpoint", "segment": segment, "commit": commit,
			"command": "godot --headless --path . --script tools/earned_saves/stormwood_chain_runner.gd -- --segment=%s --from=%s --out=%s" % [
				segment, ProjectSettings.localize_path(from_dir), ProjectSettings.localize_path(out_dir)],
			"start_save": ProjectSettings.localize_path(from_dir), "load_path": "production title Load -> Autosave (slot 0)",
			"save_path": "Game.save_game(0)", "helper": PIECES[segment],
			"injections": injections, "shortcuts": disclosures,
			"no_fixture_statement": "No teleport, flag/inventory/party write, HP pin or debug skip during play."}
		CHECKPOINTS.write_json(out_dir.path_join("receipt.json"), receipt)
		CHECKPOINTS.write_json(out_dir.path_join("PROVENANCE.json"), provenance)
	print("STORMWOOD CHAIN RESULT " + JSON.stringify({"segment": segment, "passed": passed,
		"failures": failures, "handoff": handoff, "flags_gained": gained,
		"wall_seconds": receipt.wall_seconds}))
	quit(0 if passed else 1)
