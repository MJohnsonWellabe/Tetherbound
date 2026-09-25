extends RefCounted

## Peer-side steps for the two-peer proof command
## (`tools/net/run_two_peer_proof.sh`, runner `tests/smoke_net_proof_two_peer.gd`).
##
## `tools/net/peer_runner.gd` hands any action it does not know to `run()`
## here, so a proof scenario can use every existing peer step plus these:
##
##   load_save       {from, slot?}        a NAMED save (slot json, or .json.gz) -> slot, then the game's own
##                                         `load_game()` and a boot of the realm it names
##   screenshot      {name}               this peer's rendered frame -> PNG
##   capture_saves   {label}              the production autosave, then a copy of this
##                                         peer's saves/, worlds/ and characters/
##   check_saved     {label, dir, contains, lacks}  what a captured save says: every
##                                         `contains` string is in some file under
##                                         <label>/<dir>/, no `lacks` string is in any
##   stormheart_fixture {contributors}    HOST: who fought the Dynamo, then Marrow's
##                                         defeat through the ledger (F11 setup only)
##   stormheart_answer  {answer}          answer THIS peer's Stormheart offer through
##                                         the real dialogue: interact = Yes, menu_cancel = No
##   stormheart_state {}                  this peer's view of the F11 outcome
##
## Output lands under `$TB_PROOF_OUT/peer-<index>/`. Nothing here is a game
## rule: the fixture only stands in for playing the Dynamo fight, and every
## answer, grant and save goes through the game's own code.

const WORLD_SCENES := {"meadows": "world", "cloudreach": "cloudreach", "stormwood": "stormwood",
	"water": "water"}
const SAVE_DIRS := ["saves", "worlds", "characters"]
const MARROW_FLAG := "stormwood:marrow_defeated"
const STORMWOOD_CHAPTER := "res://data/config/stormwood_chapter.json"
## Loaded on first use, not preloaded: every peer of every smoke loads this
## file through peer_runner.gd, and only F11 scenarios need the ending.
const ENDING_PATH := "res://scripts/world/stormwood_ending.gd"
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const LEGENDARY_SPECIES := "fulgocobra"

const ACTIONS := ["load_save", "screenshot", "capture_saves", "check_saved", "stormheart_fixture",
	"stormheart_answer", "stormheart_state"]


static func handles(action: String) -> bool:
	return ACTIONS.has(action)


static func run(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"load_save":
			return await _load_save(tree, args)
		"screenshot":
			return await _screenshot(tree, args)
		"capture_saves":
			return _capture_saves(tree, args)
		"check_saved":
			return _check_saved(tree, args)
		"stormheart_fixture":
			return _stormheart_fixture(tree, args)
		"stormheart_answer":
			return await _stormheart_answer(tree, args)
		"stormheart_state":
			return _stormheart_state(tree)
	return {"verdict": "ERROR", "detail": "proof_steps: unknown action '%s'" % action}


static func out_dir(tree: SceneTree) -> String:
	var base := OS.get_environment("TB_PROOF_OUT")
	if base.is_empty():
		base = OS.get_environment("TB_NET_OUT_DIR").path_join("proof")
	return base.path_join("peer-%d" % int(tree.get("_peer_index")))


# --- named saves -----------------------------------------------------------------

## The title screen's Continue, minus the menu: copy the named save into a
## slot, `Game.load_game()` it, then boot the realm scene the save names so the
## world is built from the loaded state exactly as `_enter_world()` does.
static func _load_save(tree: SceneTree, args: Dictionary) -> Dictionary:
	var from := str(args.get("from", ""))
	if from.is_empty():
		return {"verdict": "ERROR", "detail": "load_save needs args.from (a slot json)"}
	if not from.begins_with("res://") and not from.begins_with("/"):
		from = ProjectSettings.globalize_path("res://").path_join(from)
	from = ProjectSettings.globalize_path(from)
	if not FileAccess.file_exists(from):
		return {"verdict": "FAIL", "detail": "named save %s does not exist" % from}
	var game := tree.root.get_node_or_null(^"Game")
	var saver: Variant = game.get("save_system") if game != null else null
	if saver == null:
		return {"verdict": "ERROR", "detail": "no Game.save_system"}
	var slot := int(args.get("slot", 4))
	var dst := str((saver as RefCounted).call("slot_path", slot))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst.get_base_dir()))
	var out := FileAccess.open(dst, FileAccess.WRITE)
	if out == null:
		return {"verdict": "ERROR", "detail": "could not write %s" % dst}
	# A named save is self-contained: a captured `slot_N.json` names the split
	# world/character pair it was written beside, which does not exist in this
	# peer's fresh home, and `load_slot()` rightly refuses a locator whose
	# halves are missing. Without the locator the same file loads through the
	# ordinary legacy path and is split into this home's own pair.
	var bytes := FileAccess.get_file_as_bytes(from)
	if from.ends_with(".gz"):
		bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var named: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not (named is Dictionary):
		out.close()
		return {"verdict": "FAIL", "detail": "named save %s is not a JSON object" % from}
	(named as Dictionary).erase("split_locator")
	out.store_string(JSON.stringify(named))
	out.close()
	if not bool(game.call("load_game", slot)):
		return {"verdict": "FAIL", "detail": "Game.load_game(%d) refused %s" % [slot, from]}
	var realm := str(game.get("current_realm"))
	var scene := str(WORLD_SCENES.get(realm, "world"))
	await tree.call("_boot_scene", scene, int(args.get("settle_frames", 120)))
	var party: RefCounted = game.get("party")
	return {"verdict": "PASS", "detail": "loaded %s into slot %d; realm '%s' booted as '%s'"
		% [from.get_file(), slot, realm, scene],
		"data": {"realm": realm, "party_size": int(party.call("size")) if party != null else -1,
			"world_id": str(game.get("world").get("world_id")) if game.get("world") != null else ""}}


# --- captures --------------------------------------------------------------------

static func _screenshot(tree: SceneTree, args: Dictionary) -> Dictionary:
	var name := str(args.get("name", "frame"))
	if DisplayServer.get_name() == "headless":
		return {"verdict": "PASS", "detail": "headless peer: no frame to capture (run with --render)",
			"data": {"captured": false}}
	# Rendered peers run with the render loop off (net_harness.gd); draw this
	# frame on demand. Two draws, so post-processing reads a settled frame.
	for i in maxi(1, int(args.get("draws", 2))):
		RenderingServer.force_draw(true, 0.0)
	var image := tree.root.get_texture().get_image()
	if image == null or image.is_empty():
		return {"verdict": "FAIL", "detail": "the root viewport returned no image"}
	var dir := out_dir(tree)
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("%s.png" % name)
	if image.save_png(path) != OK:
		return {"verdict": "FAIL", "detail": "could not write %s" % path}
	return {"verdict": "PASS", "detail": "captured %dx%d -> %s" % [image.get_width(), image.get_height(), path],
		"data": {"captured": true, "path": path}}


## The production save this peer would make right now (`Game.autosave_here()`:
## a host writes its world and character, a client only its character), then a
## copy of what is on disk, so a proof can show each peer's saved world.
static func _capture_saves(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var wrote := bool(game.call("autosave_here"))
	var label := str(args.get("label", "saves"))
	var dst := out_dir(tree).path_join(label)
	var copied := 0
	var user := OS.get_user_data_dir()
	for sub: String in SAVE_DIRS:
		copied += _copy_tree(user.path_join(sub), dst.path_join(sub))
	# `autosave_here()` answers for the WORLD write, which a client never
	# makes (D100); what every peer must have on disk is its character.
	var local: Variant = game.get("local")
	var character := str((local as RefCounted).get("character_id")) if local != null else ""
	var saver: Variant = game.get("save_system")
	var characters: Variant = (saver as RefCounted).call("characters") if saver != null else null
	var character_on_disk := characters != null and not character.is_empty() \
		and bool((characters as RefCounted).call("has", character))
	var owns_world := bool(game.call("world_save_owned")) if game.has_method("world_save_owned") else true
	var ok := character_on_disk and (wrote or not owns_world)
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "%s: autosave_here()=%s, character '%s' on disk=%s; copied %d files to %s" % [
			"host (world + character)" if owns_world else "client (character only)",
			str(wrote), character, str(character_on_disk), copied, dst],
		"data": {"world_written": wrote, "owns_world": owns_world, "character_on_disk": character_on_disk,
			"files": copied, "dir": dst, "character_id": character,
			"world_id": str(game.get("world").get("world_id")) if game.get("world") != null else ""}}


## Read back what `capture_saves` copied: the proof is what reached disk, not
## what the live process believes.
static func _check_saved(tree: SceneTree, args: Dictionary) -> Dictionary:
	var root_dir := out_dir(tree).path_join(str(args.get("label", "saves"))).path_join(str(args.get("dir", "")))
	var texts: Array[String] = []
	for file: String in _json_files(root_dir):
		texts.append(FileAccess.get_file_as_string(file))
	if texts.is_empty():
		return {"verdict": "FAIL", "detail": "no captured save files under %s" % root_dir}
	var missing: Array[String] = []
	for want: Variant in (args.get("contains", []) as Array):
		if not texts.any(func(t: String) -> bool: return t.contains(str(want))):
			missing.append(str(want))
	var present: Array[String] = []
	for bad: Variant in (args.get("lacks", []) as Array):
		if texts.any(func(t: String) -> bool: return t.contains(str(bad))):
			present.append(str(bad))
	var ok := missing.is_empty() and present.is_empty()
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "%d file(s) under %s; missing %s; unexpectedly present %s"
			% [texts.size(), root_dir.trim_prefix(out_dir(tree) + "/"), str(missing), str(present)],
		"data": {"files": texts.size(), "missing": missing, "present": present}}


static func _json_files(dir: String) -> Array[String]:
	var found: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return found
	d.list_dir_begin()
	var entry := d.get_next()
	while entry != "":
		if not entry.begins_with("."):
			if d.current_is_dir():
				found.append_array(_json_files(dir.path_join(entry)))
			elif entry.ends_with(".json"):
				found.append(dir.path_join(entry))
		entry = d.get_next()
	d.list_dir_end()
	return found


static func _copy_tree(src: String, dst: String) -> int:
	var dir := DirAccess.open(src)
	if dir == null:
		return 0
	DirAccess.make_dir_recursive_absolute(dst)
	var copied := 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			if dir.current_is_dir():
				copied += _copy_tree(src.path_join(entry), dst.path_join(entry))
			elif DirAccess.copy_absolute(src.path_join(entry), dst.path_join(entry)) == OK:
				copied += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return copied


# --- F11: the Stormheart offer ---------------------------------------------------

static func _ending(tree: SceneTree) -> Node:
	var scene := tree.current_scene
	return scene.find_child("StormwoodEnding", true, false) if scene != null else null


## SETUP, host only: stands in for PLAYING the Dynamo fight, nothing after it.
## The Dynamo's contributor list is what `stormwood_ending.gd` records as the
## fight's participants, and Marrow's defeat flag is what the fight commits;
## from there the host's own ending controller frees the Stormheart and sends
## each participant their offer.
static func _stormheart_fixture(tree: SceneTree, args: Dictionary) -> Dictionary:
	var sess: Node = tree.call("_session")
	if sess == null or not bool(sess.call("is_active")) or not bool(sess.call("is_host")):
		return {"verdict": "ERROR", "detail": "stormheart_fixture runs on the session host only"}
	var scene := tree.current_scene
	var dynamo := scene.find_child("StormwoodDynamo", true, false) if scene != null else null
	if dynamo == null:
		return {"verdict": "ERROR", "detail": "no StormwoodDynamo in the host's current scene"}
	var ids: Array[int] = []
	for raw: Variant in (args.get("contributors", []) as Array):
		ids.append(int(raw))
	(dynamo.get("contributors") as Array).assign(ids)
	var game := tree.root.get_node_or_null(^"Game")
	# "Reached the Dynamo and beat Marrow", read off the chapter itself: the
	# entry flags of the act that owns `dynamo:release` and that objective's own
	# prerequisites (Marrow's defeat), so the fixture follows the authored chain.
	var written: Array[String] = []
	for flag: String in _release_prerequisites():
		if bool((game.get("progression") as RefCounted).call("has", flag)):
			continue
		var verdict: Dictionary = STORY_LEDGER.set_world_flag(game, flag)
		if not (bool(verdict.get("ok", false)) or bool(verdict.get("pending", false))):
			return {"verdict": "FAIL", "detail": "%s refused: code='%s' reason='%s'"
				% [flag, str(verdict.get("code", "")), str(verdict.get("reason", ""))]}
		written.append(flag)
	return {"verdict": "PASS" if written.has(MARROW_FLAG) or bool((game.get("progression") as RefCounted).call("has", MARROW_FLAG)) else "FAIL",
		"detail": "Dynamo contributors %s; committed %s" % [str(ids), str(written)]}


static func _release_prerequisites() -> Array[String]:
	var out: Array[String] = []
	var chapter: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORMWOOD_CHAPTER))
	if not (chapter is Dictionary):
		out.append(MARROW_FLAG)
		return out
	for act: Dictionary in (chapter as Dictionary).get("acts", []):
		for objective: Dictionary in act.get("objectives", []):
			if str(objective.get("completion_event", "")) != "dynamo:release":
				continue
			for flag: Variant in act.get("entry_flags", []) + objective.get("requires_flags", []):
				if not out.has(str(flag)):
					out.append(str(flag))
	if not out.has(MARROW_FLAG):
		out.append(MARROW_FLAG)
	return out


## Wait for this peer's own offer, read the whole conversation with `interact`
## as a player does, and answer its Yes/No line: `interact` is Yes,
## `menu_cancel` is No (`dialogue_panel.gd`). Then wait for the answer to settle
## (the character save and the host's acknowledgement).
static func _stormheart_answer(tree: SceneTree, args: Dictionary) -> Dictionary:
	var answer := str(args.get("answer", ""))
	if not answer in ["accept", "refuse"]:
		return {"verdict": "ERROR", "detail": "stormheart_answer needs args.answer = accept|refuse"}
	var ending := _ending(tree)
	var panel: Node = tree.current_scene.find_child("DialoguePanel", true, false) \
		if tree.current_scene != null else null
	if ending == null or panel == null:
		return {"verdict": "ERROR", "detail": "no StormwoodEnding/DialoguePanel in this peer's scene"}
	var budget := int(args.get("budget_frames", 1800))
	# The walk-up: stand beside the offer prompt, where the host's proximity
	# check (OFFER_RADIUS_M) reads this player's replicated body.
	var prompt := ending.get("_offer_prompt") as Node3D
	if prompt != null:
		var at := prompt.global_position + Vector3(2.0, 0.5, 0.0)
		await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": int(args.get("walk_settle", 90))})
	var waited := 0
	var skipped := 0
	var asked := 0
	var next_ask := 0
	while waited < budget and not _offer_open(ending, panel):
		# The player's walk-up: the offer prompt's `activated` handler asks the
		# host for this character's claim (`_on_offer`, the prompt's only
		# action), as `veridian_answer` calls its prompts' handlers. Asked again
		# only if no claim arrived, the way a player would press it again.
		if (ending.get("_local_claim") as Dictionary).is_empty() and waited >= next_ask:
			ending.call("_on_offer")
			asked += 1
			next_ask = waited + 300
		# The release conversation plays first and the offer waits for the
		# panel; read any other open conversation through, as a player would.
		if bool(panel.call("is_open")) and not _offer_open(ending, panel):
			await _tap(tree, "interact")
			waited += 10
			skipped += 1
			continue
		await tree.physics_frame
		waited += 1
	if not _offer_open(ending, panel):
		return {"verdict": "FAIL", "detail": "no Stormheart offer reached this peer in %d frames (asked %d times)"
			% [budget, asked]}
	var presses := 0
	while presses < 40 and bool(panel.call("is_open")) and not _on_confirmation(panel):
		await _tap(tree, "interact")
		presses += 1
	if not _on_confirmation(panel):
		return {"verdict": "FAIL", "detail": "the offer closed before its Yes/No line (%d presses)" % presses}
	var shot := {}
	if args.has("screenshot"):
		shot = await _screenshot(tree, {"name": str(args.screenshot)})
	await _tap(tree, "interact" if answer == "accept" else "menu_cancel")
	var settle := 0
	while settle < budget and not (ending.get("_local_claim") as Dictionary).is_empty():
		await tree.physics_frame
		settle += 1
	var state := _stormheart_state(tree)
	var settled := (ending.get("_local_claim") as Dictionary).is_empty()
	return {"verdict": "PASS" if settled else "FAIL",
		"detail": "answered %s after reading %d earlier line(s) and %d offer line(s)%s; claim settled=%s; party holds the Stormheart=%s"
			% [answer, skipped, presses, "" if shot.is_empty() else "; " + str(shot.get("detail", "")),
				str(settled), str((state.data as Dictionary).get("has_stormheart"))],
		"data": state.data}


static func _offer_open(ending: Node, panel: Node) -> bool:
	return not (ending.get("_local_claim") as Dictionary).is_empty() and bool(panel.call("is_open")) \
		and str((panel.call("runner") as RefCounted).call("conversation_id")) == load(ENDING_PATH).OFFER_CONVERSATION


static func _on_confirmation(panel: Node) -> bool:
	var runner: RefCounted = panel.call("runner")
	return runner != null and bool(runner.call("is_active")) \
		and bool((runner.call("line") as Dictionary).get("confirmation", false))


static func _tap(tree: SceneTree, action: String) -> void:
	await tree.call("_press_edge", action, true)
	for f in 2:
		await tree.physics_frame
	await tree.call("_press_edge", action, false)
	for f in 8:
		await tree.physics_frame


static func _stormheart_state(tree: SceneTree) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game", "data": {}}
	var party: RefCounted = game.get("party")
	var species: Array = []
	if party != null:
		for member: Variant in (party.call("members") as Array):
			species.append(str((member as RefCounted).get("species_id")))
	var local: RefCounted = game.get("local")
	var character := str(local.get("character_id")) if local != null else ""
	var ending: Variant = load(ENDING_PATH)
	var world_flags: RefCounted = game.get("world").get("flags") if game.get("world") != null else null
	var has_flag := func(id: String) -> bool:
		return world_flags != null and bool(world_flags.call("has", id))
	var data := {
		"character_id": character,
		"party": species,
		"has_stormheart": species.has(LEGENDARY_SPECIES),
		"freed": has_flag.call(ending.FREED_FLAG),
		"world_accepted": has_flag.call(ending.resolution_flag(true, character)),
		"world_refused": has_flag.call(ending.resolution_flag(false, character)),
		"accepted_anywhere": ending.accepted_anywhere(game.call("player_flags")),
	}
	return {"verdict": "PASS", "detail": str(data), "data": data}
