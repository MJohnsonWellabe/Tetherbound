extends SceneTree
const TRAINING_HANDOFF := preload("res://tools/earned_saves/training_handoff.gd")
const LINEAGE := preload("res://tools/earned_saves/checkpoint_lineage.gd")

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
##   crown_gather    crown_build through the two crafted frames (saved at Rodline Refuge)
##   crown_arch      from crown_gather: Still Grove and the paid Crown arch
##   crown_wood      crown_gather's first half: rest, Capacitor Alpha, 4 wood/vine sites
##   crown_glass     from crown_wood: room, Crown window, Crown seams, two frames
##   rootgate        Crown guardian, Wen, heartstone, Rootgate released
##   named_detour    optional named wilds the route does not fight (F10#2)
##   dynamo          Deepwood, rods, Kestrel, physical core arrival
##   marrow          Marrow five rounds and the four-conduit Break
##   aftermath       Stormheart accepted at five, release ceremony, Waterward view
##   settlement      Stormheart declined (keeps the five), new-order F49 ending
##   aftermath_reload  aftermath from a reloaded marrow checkpoint: the
##                   durable release/offer must reopen on load
##   marrow_aftermath  marrow then aftermath in ONE process: the Stormheart
##                   release dialogue opens only on the live release event, so
##                   aftermath cannot drain it after a save/load boundary

##   home_key        personal Home Key used from Stormwood (f49_portal_travel)
##   homecoming      Home Key from Stormwood -> hang the Stormwood relic ->
##                   Grandpa's homecoming -> production credits (Skip disclosed)
##                   -> ordinary movement in the completed world, the
##                   f49_campaign_journey.gd order (F49#0's last leg)
##   home_relic      from home_key: hang Stormwood relic, save at home
##   home_credits    from home_relic: Grandpa, credits, ordinary movement
## The split route is marrow_aftermath -> home_key -> home_relic -> home_credits.
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
	# Owner chain rule (13 Oct): crown_build in two pieces, saved between.
	"crown_gather": "res://tests/helpers/stormwood_crown_build_segment.gd",
	"crown_wood": "res://tests/helpers/stormwood_crown_build_segment.gd",
	"crown_glass": "res://tests/helpers/stormwood_crown_build_segment.gd",
	"crown_arch": "res://tests/helpers/stormwood_crown_build_segment.gd",
	# Coordinator progression decision (b): the Stormwood Master by ordinary input.
	"rowan_visit": "res://tools/earned_saves/rowan_visit.gd",
	"rowan_chest": "res://tools/earned_saves/rowan_visit.gd",
	"rootgate": "res://tests/helpers/stormwood_earned_rootgate_segment.gd",
	"named_detour": "res://tests/helpers/stormwood_b_named_detour_segment.gd",
	# One detour per named wild, each its own checkpoint (coordinator fail-fast
	# rule, 2026-10-12): a failure costs one piece, not the chain.
	"named_capacitor_alpha": "res://tests/helpers/stormwood_b_named_detour_segment.gd",
	"named_hollows_alpha": "res://tests/helpers/stormwood_b_named_detour_segment.gd",
	"named_blackwater_elder": "res://tests/helpers/stormwood_b_named_detour_segment.gd",
	"named_old_rodfolk_hall_guardian": "res://tests/helpers/stormwood_b_named_detour_segment.gd",
	"named_glass_field_alpha": "res://tests/helpers/stormwood_b_named_detour_segment.gd",
	"dynamo": "res://tests/helpers/stormwood_earned_dynamo_segment.gd",
	"marrow": "res://tests/helpers/stormwood_earned_marrow_segment.gd",
	"aftermath": "res://tests/helpers/stormwood_earned_aftermath_segment.gd",
	"marrow_aftermath": "res://tests/helpers/stormwood_earned_aftermath_segment.gd",
	"aftermath_reload": "res://tests/helpers/stormwood_aftermath_reload_segment.gd",
	"settlement": "res://tests/helpers/f49_stormheart_settlement.gd",
	"home_key": "res://tests/helpers/f49_portal_travel.gd",
	"homecoming": "res://tests/helpers/f49_portal_travel.gd",
	"home_relic": "res://tests/helpers/f49_portal_travel.gd",
	"home_credits": "res://tests/helpers/f49_portal_travel.gd",
}
const HOME_PREDECESSORS := {"homecoming": "marrow_aftermath", "home_key": "marrow_aftermath",
	"home_relic": "home_key", "home_credits": "home_relic"}
const NAMED_IDS := ["capacitor_alpha", "hollows_alpha", "blackwater_elder",
	"old_rodfolk_hall_guardian", "glass_field_alpha"]

var segment := ""
var from_dir := ""
var out_dir := ""
var failures: Array[String] = []
var disclosures: Array[String] = []
var game: Node
var started_ms := 0
## Fail-fast watchdog (coordinator rule, 2026-10-12): the live helper and the
## commit so an abort can report and finish the piece at once.
var _helper: Object = null
var _commit := ""
const WATCHDOG_NO_RECEIPT_MS := 45 * 60 * 1000
const WATCHDOG_SAME_STEP_DEATHS := 2
const WATCHDOG_SATCHEL_DEATHS := 2
var before := {}
var helper_result := {}
var handoff := {}
var saved_owner_receipt := {}
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
	_commit = commit
	if commit.length() != 40:
		failures.append("Exact clean source commit required before play: " + commit)
	if not failures.is_empty():
		_finish(commit)
		return
	# Outside the repository: the game may still write its world file after
	# the piece ends, and a scratch copy is never a checkpoint.
	var working := OS.get_user_data_dir().path_join("stormwood_chain/%s_working_%d" % [out_dir.get_file(), Time.get_ticks_usec()])
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
		if before.is_empty():
			before = _state()
			_handoff_check()
		if failures.is_empty():
			_watch_weather.call_deferred()
			_watchdog.call_deferred()
			_record_frames.call_deferred()
			if segment == "arrival_prefix": _watch_seam.call_deferred()
			await _play()
	if failures.is_empty():
		var after := _state()
		if not segment in ["aftermath", "marrow_aftermath", "aftermath_reload"] and (after.uids as Array) != (before.uids as Array):
			failures.append("Piece changed the five UIDs: %s -> %s" % [str(before.uids), str(after.uids)])
		if HOME_PREDECESSORS.has(segment) and after.creature_progression != before.creature_progression:
			failures.append("Home return changed retained levels, XP, caps or breakthrough history")
		if not bool(game.call("save_game", SLOT)):
			failures.append("Game.save_game(%d) refused the checkpoint save" % SLOT)
		elif not CHECKPOINTS.copy_tree(working, out_dir.path_join("save")):
			failures.append("Could not copy the written save into " + out_dir)
		elif HOME_PREDECESSORS.has(segment) or segment in ["aftermath", "marrow_aftermath", "aftermath_reload"]:
			_verify_saved_owner()
	CHECKPOINTS.remove_tree(working)
	_finish(commit)


func _verify_saved_owner() -> void:
	var checkpoint := SAVE.new(out_dir.path_join("save") + "/")
	var flat: Dictionary = checkpoint.call("_read", SLOT)
	if flat.is_empty() or SAVE.version_result(flat.get("version")).get("ok") != true:
		saved_owner_receipt = {"checked": true, "passed": false, "reason": "Copied checkpoint has no readable current-version slot"}
		failures.append(str(saved_owner_receipt.reason))
		return
	var pair: Dictionary = checkpoint.call("_authoritative_split", SLOT, flat)
	var expected: Dictionary = preload("res://scripts/save/character_save.gd").partition(checkpoint.snapshot(game))
	expected["character_id"] = str(game.get("local").get("character_id"))
	var error := preload("res://tests/helpers/stormwood_checkpoint_receipt.gd").saved_owner_error(pair, expected)
	saved_owner_receipt = {"checked": true, "passed": error.is_empty(), "reason": error,
		"character_id": expected.character_id, "path": out_dir.path_join("save"),
		"fields": preload("res://tests/helpers/stormwood_checkpoint_receipt.gd").OWNER_FIELDS}
	if not error.is_empty(): failures.append(error)


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
	# Match the saved boundary before reading any automatically opened dialogue.
	# Dialogue is play: it may advance personal outcome/homecoming receipts.
	if HOME_PREDECESSORS.has(segment):
		before = _state()
		_handoff_check()
		if not failures.is_empty(): return false
	for _i in LOAD_SETTLE_FRAMES: await physics_frame
	for _i in 600:
		if INPUT_OWNER.current(self) == null: break
		await process_frame
	# A dialogue that opens on load is named; for the homecoming piece it is
	# read through with ordinary Interact presses, as a player would (disclosed).
	var opened: Node = INPUT_OWNER.current(self)
	if opened != null and opened.has_method("is_open") and opened.get("_runner") != null:
		var id := str((opened.get("_runner") as RefCounted).call("conversation_id"))
		print("STORMWOOD CHAIN load opened dialogue '%s'" % id)
		if segment in ["home_key", "homecoming"]:
			disclosures.append("On load the save opened dialogue '%s'; read through with ordinary Interact presses" % id)
			for _press in 60:
				if not bool(opened.call("is_open")): break
				for pressed: bool in [true, false]:
					var event := InputEventAction.new()
					event.action = "interact"
					event.pressed = pressed
					event.strength = 1.0 if pressed else 0.0
					Input.parse_input_event(event)
					for _f in 6: await process_frame
			for _i in 600:
				if INPUT_OWNER.current(self) == null: break
				await process_frame
	if INPUT_OWNER.current(self) != null:
		var holder: Node = INPUT_OWNER.current(self)
		failures.append("Loaded piece never returned ordinary world input (owner %s, script %s)" % [
			str(holder.get_path()), str(holder.get_script().resource_path) if holder.get_script() != null else "-"])
		return false
	print("STORMWOOD CHAIN loaded realm=%s player=%s" % [game.get("current_realm"),
		(world.get_node("Player") as Node3D).global_position])
	return true


## The previous checkpoint's own after-state is the handoff contract.
func _handoff_check() -> void:
	var receipt: Variant = null
	var receipt_path := from_dir.path_join("receipt.json")
	if FileAccess.file_exists(receipt_path): receipt = JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
	if HOME_PREDECESSORS.has(segment):
		var receipt_error := CHECKPOINTS.piece_receipt_error(receipt, str(HOME_PREDECESSORS[segment]),
			["uids", "species", "world_flags", "player_flags", "items", "portal_unlocks", "realm", "training", "ending"])
		if not receipt_error.is_empty():
			handoff = {"checked": true, "passed": false, "reason": receipt_error}
			failures.append("Homecoming " + receipt_error)
			return
	if not receipt is Dictionary or not (receipt as Dictionary).get("after") is Dictionary:
		handoff = {"checked": false, "reason": "previous checkpoint has no receipt.json after-state (generated input)"}
		if HOME_PREDECESSORS.has(segment) or FileAccess.file_exists(from_dir.path_join("receipt.json")):
			failures.append("Homecoming requires a matched predecessor; malformed receipts cannot become generated inputs")
		return
	var expected: Dictionary = receipt.after
	if not bool(receipt.get("passed", false)):
		failures.append("Previous checkpoint receipt is not a PASS")
		return
	var training := TRAINING_HANDOFF.compare(expected, before)
	if not bool(training.checked):
		disclosures.append("Training handoff not proven: " + str(training.reason))
	elif not bool(training.matches):
		failures.append("Training handoff: " + str(training.reason))
	var ending_matches := not HOME_PREDECESSORS.has(segment) or (bool(training.checked) \
		and TRAINING_HANDOFF.compare_ending(expected, before))
	if not ending_matches:
		failures.append("Homecoming requires matched saved training and personal ending receipts")
	var keys: Array = ["uids", "species", "world_flags", "player_flags", "items", "portal_unlocks", "realm"]
	var cross_runner := false
	# A Cloudreach piece receipt (cloudreach_chain_runner.gd, earned_chain_runner
	# shape: party/uids/flags/inventory/realm) hands into Stormwood after piece 07.
	# Compare the ordered five, realm, aggregate inventory and progression flags.
	if not expected.has("species") and expected.get("party") is Array:
		cross_runner = true
		var species: Array = []
		for member: Variant in expected.party:
			if not member is Dictionary:
				failures.append("Previous checkpoint has a malformed party member")
				return
			species.append(str((member as Dictionary).get("species", "")))
		expected = expected.duplicate()
		expected["species"] = species
		# Cloudreach receipts name it `inventory`; Tidewake homestead ones `items`.
		expected["items"] = expected.get("inventory", expected.get("items"))
		expected["world_flags"] = expected.get("flags")
		keys = ["uids", "species", "realm", "items", "world_flags"]
	# Old retained checkpoints predate this receipt field. New checkpoints
	# must prove the same saved progression was loaded, including legacy caps.
	if expected.has("creature_progression"): keys.append("creature_progression")
	var mismatched: Array = []
	for key: String in keys:
		# Both sides through the same JSON round trip: the saved receipt was
		# parsed (numbers are floats), the loaded state was not (ints).
		if not expected.has(key) or expected.get(key) == null \
				or JSON.parse_string(JSON.stringify(expected.get(key))) != JSON.parse_string(JSON.stringify(before.get(key))):
			mismatched.append(key)
	handoff = {"training": training, "ending_required": HOME_PREDECESSORS.has(segment), "ending_matches": ending_matches,
		"checked": true, "previous": from_dir.get_file(), "mismatched": mismatched,
		"passed": ending_matches and mismatched.is_empty() and (not bool(training.checked) or bool(training.matches)), "cross_runner": cross_runner, "keys": keys}
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
		"named_detour", "named_capacitor_alpha", "named_hollows_alpha", "named_blackwater_elder", \
				"named_old_rodfolk_hall_guardian", "named_glass_field_alpha":
			var ids: Array = NAMED_IDS if segment == "named_detour" else [segment.trim_prefix("named_")]
			_helper = script.new()
			helper_result = await _helper.run_named(self, world, game, ids)
			var outcomes: Dictionary = helper_result.get("outcomes", {})
			for id: String in ids:
				if not str(outcomes.get(id, "")) in ["cleared", "already_cleared"]:
					failures.append("named detour %s -> %s" % [id, str(outcomes.get(id, "missing"))])
			helper_result["passed"] = failures.is_empty()
		"marrow_aftermath":
			# Both helpers unchanged and in order; the second runs only if the
			# first passed, and both results are kept.
			var marrow: Dictionary = await (load(PIECES.marrow) as GDScript).new().run(self, world, game)
			for line: Variant in marrow.get("failures", []):
				failures.append("marrow: %s" % str(line))
			if not bool(marrow.get("passed", false)) and failures.is_empty():
				failures.append("marrow helper returned passed=false")
			if not failures.is_empty():
				helper_result = {"passed": false, "failures": [], "marrow": marrow}
				return
			helper_result = await script.new().run(self, world, game)
			helper_result["marrow"] = marrow
		"home_key":
			var travel: RefCounted = script.new(self, game)
			var passed: bool = await travel.call("home_key")
			helper_result = {"passed": passed, "failures": travel.get("failures"),
				"transcript": [], "realm_after": str(game.get("current_realm"))}
		"homecoming":
			var travel: RefCounted = script.new(self, game)
			var passed: bool = await travel.call("home_key")
			if passed: passed = await travel.call("hang_relic", "stormwood")
			if passed: passed = await travel.call("grandpa_and_credits")
			if passed: passed = await travel.call("walk_continuation")
			if passed:
				disclosures.append("Credits closed with the ordinary Skip (menu_cancel) after they opened")
			helper_result = {"passed": passed, "failures": travel.get("failures"),
				"transcript": [], "realm_after": str(game.get("current_realm"))}
		"home_relic", "home_credits":
			var travel: RefCounted = script.new(self, game)
			var passed := str(game.get("current_realm")) == "meadows"
			if not passed: failures.append("Saved home piece must load the actual Meadows return")
			if passed and segment == "home_relic": passed = await travel.call("hang_relic", "stormwood")
			if passed and segment == "home_credits":
				passed = await travel.call("grandpa_and_credits")
				if passed:
					disclosures.append("Credits closed with the ordinary Skip (menu_cancel) after they opened")
					passed = await travel.call("walk_continuation")
			helper_result = {"passed": passed, "failures": travel.get("failures"),
				"transcript": [], "realm_after": str(game.get("current_realm"))}
		_:
			_helper = script.new()
			if segment in ["crown_gather", "crown_wood", "crown_glass", "crown_arch"]:
				_helper.set("stage", segment.trim_prefix("crown_"))
			elif segment == "rowan_chest":
				_helper.set("chest_only", true)
			helper_result = await _helper.run(self, world, game)
	for line: Variant in helper_result.get("failures", []):
		failures.append("%s: %s" % [segment, str(line)])
	if not bool(helper_result.get("passed", false)) and failures.is_empty():
		failures.append("%s helper returned passed=false" % segment)


## Fail-fast watchdog (coordinator rule, 2026-10-12): abort the piece and
## report the step and last receipts on two trainer deaths at one step, two
## death-satchel recovery walks that end in another death, or 45 wall minutes
## with no new receipt (world/player flag). Engage rounds are bounded in the
## detour helper itself (ENGAGE_ROUNDS = 3).
func _watchdog() -> void:
	var receipt_count := -1
	var last_receipt_ms := Time.get_ticks_msec()
	var deaths_seen := 0
	var deaths_by_step := {}
	var satchel_deaths := 0
	var recent: Array = []
	var seen_flags := {}
	var last_fight_hp := -1.0
	var last_items := ""
	var last_surge := -1.0
	while true:
		var wait_until := Time.get_ticks_msec() + 15000
		while Time.get_ticks_msec() < wait_until:
			await process_frame
		if game == null:
			continue
		var flags: Array = (game.get("progression").call("all_set") as Array).duplicate()
		var personal: RefCounted = game.call("player_flags")
		if personal != null and personal.has_method("all_set"):
			flags.append_array(personal.call("all_set") as Array)
		if flags.size() != receipt_count:
			if receipt_count >= 0:
				# Newest receipts by set difference: all_set() is not in grant order.
				for flag: Variant in flags:
					if not seen_flags.has(flag): recent.append(flag)
				recent = recent.slice(maxi(0, recent.size() - 8))
			seen_flags.clear()
			for flag: Variant in flags: seen_flags[flag] = true
			receipt_count = flags.size()
			last_receipt_ms = Time.get_ticks_msec()
		# A live fight whose HP totals still move is progress, not idling: on
		# this host one named fight can outlast 45 wall minutes (run 5 tripped
		# mid-fight). A frozen fight still trips the rule.
		# Carried items are receipts too (gathers record stock, not flags), and
		# a wait the helper declares (the Crown seams' Surge window, up to one
		# 510 s cycle: ~30 wall minutes on this host) is progress while the
		# Surge clock still advances. A frozen wait or walk still trips.
		var items_now := str(_state().get("items", {}))
		if items_now != last_items:
			last_items = items_now
			last_receipt_ms = Time.get_ticks_msec()
		var declared_wait := str(_helper.get("waiting_for")) if _helper != null and "waiting_for" in _helper else ""
		var surge_now := float(((game.get("realm_environment") as Dictionary).get("stormwood", {}) as Dictionary).get("elapsed", 0.0))
		if not declared_wait.is_empty() and surge_now > last_surge + 1.0:
			last_receipt_ms = Time.get_ticks_msec()
		last_surge = surge_now
		var fight_hp := _fight_hp_total()
		if fight_hp >= 0.0 and not is_equal_approx(fight_hp, last_fight_hp):
			last_fight_hp = fight_hp
			last_receipt_ms = Time.get_ticks_msec()
		var safety: Object = _helper.get("_safety") if _helper != null and "_safety" in _helper else null
		if safety != null:
			var counts: Dictionary = safety.get("counts")
			var step := str(safety.get("phase"))
			while int(counts.get("deaths", 0)) > deaths_seen:
				deaths_seen += 1
				deaths_by_step[step] = int(deaths_by_step.get(step, 0)) + 1
				if step.contains("death satchel"):
					satchel_deaths += 1
				if int(deaths_by_step[step]) >= WATCHDOG_SAME_STEP_DEATHS:
					_watchdog_abort("%d trainer deaths at step '%s'" % [deaths_by_step[step], step], step, recent)
					return
				if satchel_deaths >= WATCHDOG_SATCHEL_DEATHS:
					_watchdog_abort("%d death-satchel recovery walks ended in another death" % satchel_deaths, step, recent)
					return
		if Time.get_ticks_msec() - last_receipt_ms > WATCHDOG_NO_RECEIPT_MS:
			var step := str(safety.get("phase")) if safety != null else ""
			_watchdog_abort("no new receipt for %d min" % (WATCHDOG_NO_RECEIPT_MS / 60000), step, recent)
			return


## Wall time of every process frame during play (coordinator, 12 Oct: report
## median/p95/max frame with the piece result).
var _frame_usec := PackedInt32Array()

func _record_frames() -> void:
	var last := Time.get_ticks_usec()
	while true:
		await process_frame
		var now := Time.get_ticks_usec()
		_frame_usec.append(mini(now - last, 2147483647))
		last = now

func _frame_stats() -> Dictionary:
	if _frame_usec.is_empty(): return {}
	var sorted := _frame_usec.duplicate()
	sorted.sort()
	var n := sorted.size()
	return {"frames": n, "median_ms": snappedf(sorted[n / 2] / 1000.0, 0.1),
		"p95_ms": snappedf(sorted[mini(n - 1, int(n * 0.95))] / 1000.0, 0.1),
		"p99_ms": snappedf(sorted[mini(n - 1, int(n * 0.99))] / 1000.0, 0.1),
		"max_ms": snappedf(sorted[n - 1] / 1000.0, 0.1)}

## Sum of the live fight's two combatants' HP, or -1 outside a fight.
func _fight_hp_total() -> float:
	var manager := current_scene.get_node_or_null(^"CombatManager") if current_scene != null else null
	if manager == null or not bool(manager.call("is_fighting")):
		return -1.0
	var total := 0.0
	for getter: String in ["enemy", "active_creature"]:
		if manager.has_method(getter):
			var creature: Variant = manager.call(getter)
			if creature is Object and creature != null:
				total += float((creature as Object).get("hp"))
	return total


func _watchdog_abort(reason: String, step: String, recent: Array) -> void:
	var outcomes: Variant = _helper.get("outcomes") if _helper != null and "outcomes" in _helper else {}
	var line := "WATCHDOG abort: %s (step=%s, outcomes=%s, last receipts=%s)" % [reason, step, str(outcomes), str(recent)]
	print("STORMWOOD CHAIN " + line)
	failures.append(line)
	_finish(_commit)


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
		_monitor_growth()


var _last_histogram := {}


## Diagnostic only: engine node/object counts and frame cost, and the node
## kinds (class + script, scene-root child) that grew since the last sample.
func _monitor_growth() -> void:
	var histogram := {}
	var walk := func(node: Node, recurse: Callable) -> void:
		var script: Script = node.get_script()
		var key := "%s:%s" % [node.get_class(), script.resource_path.get_file() if script != null else ""]
		histogram[key] = int(histogram.get(key, 0)) + 1
		for child: Node in node.get_children():
			recurse.call(child, recurse)
	walk.call(root, walk)
	var growth: Array = []
	for key: String in histogram:
		var delta := int(histogram[key]) - int(_last_histogram.get(key, 0))
		if delta != 0 and not _last_histogram.is_empty():
			growth.append([delta, key, int(histogram[key])])
	growth.sort_custom(func(a: Array, b: Array) -> bool: return absi(int(a[0])) > absi(int(b[0])))
	_last_histogram = histogram
	print("STORMWOOD CHAIN perf nodes=%d objects=%d orphans=%d process_ms=%.1f physics_ms=%.1f fps=%.1f growth=%s" % [
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_FPS), str(growth.slice(0, 8))])


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
	var creature_progression: Dictionary = {}
	var personal_progression: Dictionary = game.get("local").get("redesign_character")
	for member: RefCounted in game.get("party").call("members"):
		uids.append(str(member.get("uid")))
		species.append(str(member.get("species_id")))
		condition.append({"level": int(member.get("level")), "hp": snappedf(float(member.get("hp")), 0.1),
			"max_hp": int(member.get("max_hp")), "fainted": bool(member.get("fainted"))})
		var uid := str(member.get("uid"))
		var record: Dictionary = personal_progression.get("creatures", {}).get(uid, {})
		creature_progression[uid] = {"level": int(member.get("level")), "xp": int(member.get("xp")),
			"cap_level": record.get("cap_level", -1), "breakthroughs": record.get("breakthroughs", []).duplicate(true)}
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
	return {"training": TRAINING_HANDOFF.snapshot(game), "ending": TRAINING_HANDOFF.ending_snapshot(game),
		"uids": uids, "species": species, "condition": condition, "creature_progression": creature_progression, "items": items,
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
	var lineage := LINEAGE.from_directory(from_dir)
	var receipt := {"kind": "stormwood_earned_piece", "segment": segment, "passed": passed,
		"input_mode": LINEAGE.input_mode(lineage), "lineage": lineage,
		"commit": commit, "from": from_dir, "handoff": handoff, "before": before, "after": after,
		"flags_gained": gained, "failures": failures, "disclosures": disclosures,
		"helper": PIECES.get(segment, ""), "helper_outcomes": helper_result.get("outcomes", {}),
		"stormheart_progression": helper_result.get("stormheart_progression", {}),
		"saved_owner": saved_owner_receipt,
		"wall_seconds": snappedf(float(Time.get_ticks_msec() - started_ms) / 1000.0, 0.1),
		"frame_wall": _frame_stats(), "transcript": transcript}
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
		# Provenance first: a PASS receipt must never advertise a checkpoint
		# whose required lineage artifact could not be written.
		if not CHECKPOINTS.write_json(out_dir.path_join("PROVENANCE.json"), provenance):
			failures.append("Could not write checkpoint PROVENANCE.json")
			passed = false
		receipt.passed = passed
		if not CHECKPOINTS.write_json(out_dir.path_join("receipt.json"), receipt):
			failures.append("Could not write checkpoint receipt.json")
			passed = false
	print("STORMWOOD CHAIN RESULT " + JSON.stringify({"segment": segment, "passed": passed,
		"failures": failures, "handoff": handoff, "flags_gained": gained,
		"wall_seconds": receipt.wall_seconds, "frame_wall": receipt.frame_wall}))
	quit(0 if passed else 1)
