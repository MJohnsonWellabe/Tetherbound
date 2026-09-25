extends RefCounted

## Peer-side steps for the two-peer proof command
## (`tools/net/run_two_peer_proof.sh`, runner `tests/smoke_net_proof_two_peer.gd`).
##
## `tools/net/peer_runner.gd` hands any action it does not know to `run()`
## here, so a proof scenario can use every existing peer step plus these:
##
##   load_save       {from, slot?}        a NAMED save (a captured save directory, or a
##                                         slot json) into this home, then the game's own
##                                         `load_game()` and a boot of the realm it names
##   screenshot      {name}               this peer's rendered frame -> PNG
##   capture_saves   {label}              the production autosave, then a copy of this
##                                         peer's saves/, worlds/ and characters/
##   check_saved     {label, dir, path_contains?, contains, lacks}  what a captured
##                                         save says: every `contains` string is in some
##                                         file under <label>/<dir>/ (optionally only
##                                         paths containing `path_contains`), no `lacks`
##                                         string is in any
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

## The title screen's Continue, minus the menu: put a NAMED save in this
## peer's fresh home, `Game.load_game()` it, then boot the realm scene the save
## names, as `_enter_world()` does. Two forms:
##
##  * a DIRECTORY as `capture_saves` writes it (`saves/slot_N.json`, `worlds/`,
##    `characters/`; any file may be `.gz`): copied as-is, locator kept, so it
##    loads through the current split path exactly like a player's Continue.
##    This is the faithful form.
##  * a single slot json (or `.json.gz`): its `split_locator` names files this
##    home does not have, so it is dropped and the save loads through the
##    LEGACY-migration path, split into this home's own pair (the character id
##    becomes `legacy-slot-N`). Use it only where that difference is harmless.
static func _load_save(tree: SceneTree, args: Dictionary) -> Dictionary:
	var from := str(args.get("from", ""))
	if from.is_empty():
		return {"verdict": "ERROR", "detail": "load_save needs args.from (a captured save directory or a slot json)"}
	if not from.begins_with("res://") and not from.begins_with("/"):
		from = ProjectSettings.globalize_path("res://").path_join(from)
	from = ProjectSettings.globalize_path(from)
	var game := tree.root.get_node_or_null(^"Game")
	var saver: Variant = game.get("save_system") if game != null else null
	if saver == null:
		return {"verdict": "ERROR", "detail": "no Game.save_system"}
	var slot := int(args.get("slot", 0))
	var form := ""
	if DirAccess.dir_exists_absolute(from):
		form = "captured directory (split path)"
		var found := -1
		var saves := DirAccess.open(from.path_join("saves"))
		if saves != null:
			for entry: String in saves.get_files():
				var m := RegEx.create_from_string("^slot_(\\d+)\\.json(\\.gz)?$").search(entry)
				if m != null:
					found = int(m.get_string(1)) if found < 0 else -2
		if found < 0:
			return {"verdict": "FAIL", "detail": "%s needs exactly one saves/slot_N.json" % from}
		slot = found
		var user := OS.get_user_data_dir()
		var copied := 0
		for sub: String in SAVE_DIRS:
			copied += _copy_tree(from.path_join(sub), user.path_join(sub), true)
		if copied == 0:
			return {"verdict": "FAIL", "detail": "nothing to copy from %s" % from}
	elif FileAccess.file_exists(from):
		form = "single slot json (legacy-migration path)"
		var dst := str((saver as RefCounted).call("slot_path", slot))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst.get_base_dir()))
		var named: Variant = JSON.parse_string(_read_text(from))
		if not (named is Dictionary):
			return {"verdict": "FAIL", "detail": "named save %s is not a JSON object" % from}
		(named as Dictionary).erase("split_locator")
		var out := FileAccess.open(dst, FileAccess.WRITE)
		if out == null:
			return {"verdict": "ERROR", "detail": "could not write %s" % dst}
		out.store_string(JSON.stringify(named))
		out.close()
	else:
		return {"verdict": "FAIL", "detail": "named save %s does not exist" % from}
	if not bool(game.call("load_game", slot)):
		return {"verdict": "FAIL", "detail": "Game.load_game(%d) refused %s" % [slot, from]}
	var realm := str(game.get("current_realm"))
	if not WORLD_SCENES.has(realm):
		return {"verdict": "FAIL", "detail": "the save names realm '%s', which the peer runner cannot boot" % realm}
	var scene := str(WORLD_SCENES[realm])
	await tree.call("_boot_scene", scene, int(args.get("settle_frames", 120)))
	var party: RefCounted = game.get("party")
	var local: Variant = game.get("local")
	return {"verdict": "PASS", "detail": "loaded %s (%s) as slot %d; realm '%s' booted as '%s'; character '%s'"
		% [from.get_file(), form, slot, realm, scene,
			str((local as RefCounted).get("character_id")) if local != null else ""],
		"data": {"realm": realm, "slot": slot, "form": form,
			"party_size": int(party.call("size")) if party != null else -1,
			"character_id": str((local as RefCounted).get("character_id")) if local != null else "",
			"world_id": str(game.get("world").get("world_id")) if game.get("world") != null else ""}}


static func _read_text(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"):
		bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return bytes.get_string_from_utf8()


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
	var names: Array[String] = []
	var only := str(args.get("path_contains", ""))
	for file: String in _json_files(root_dir):
		if only.is_empty() or file.contains(only):
			texts.append(FileAccess.get_file_as_string(file))
			names.append(file.trim_prefix(root_dir + "/"))
	if texts.is_empty():
		return {"verdict": "FAIL", "detail": "no captured save files under %s%s"
			% [root_dir, "" if only.is_empty() else " matching '%s'" % only]}
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
		"detail": "missing %s; unexpectedly present %s; read %s under %s"
			% [str(missing), str(present), str(names), root_dir.trim_prefix(out_dir(tree) + "/")],
		"data": {"files": names, "missing": missing, "present": present}}


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


## `gunzip`: a `.gz` file lands under its name without the suffix, decompressed.
static func _copy_tree(src: String, dst: String, gunzip := false) -> int:
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
				copied += _copy_tree(src.path_join(entry), dst.path_join(entry), gunzip)
			elif gunzip and entry.ends_with(".gz"):
				var out := FileAccess.open(dst.path_join(entry.trim_suffix(".gz")), FileAccess.WRITE)
				if out != null:
					out.store_string(_read_text(src.path_join(entry)))
					out.close()
					copied += 1
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
	# The walk-up: stand beside the offer prompt where it really offers itself
	# to this player (enabled, in radius, line of sight) -- the host's own
	# proximity check (OFFER_RADIUS_M) then reads this player's body there.
	var prompt := ending.get("_offer_prompt") as Node3D
	if prompt == null:
		return {"verdict": "ERROR", "detail": "the Stormheart has no offer prompt in this peer's scene"}
	var player := (tree.get("_probe") as Object).call("player") as Node3D
	if player == null:
		return {"verdict": "ERROR", "detail": "no live player to walk up"}
	var standing := ""
	for offset: Vector3 in [Vector3(2, 0.5, 0), Vector3(-2, 0.5, 0), Vector3(0, 0.5, 2), Vector3(0, 0.5, -2),
			Vector3(3, 1, 3), Vector3(-3, 1, -3)]:
		var at := prompt.global_position + offset
		await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": int(args.get("walk_settle", 90))})
		if not (prompt.call("interaction_offer", player.global_position) as Dictionary).is_empty():
			standing = str(offset)
			break
	var waited := 0
	var skipped := 0
	var presses_on_prompt := 0
	var next_ask := 0
	var seen_label := ""
	while waited < budget and not _offer_open(ending, panel):
		# The release conversation plays first and the offer waits for the
		# panel; read any other open conversation through, as a player would.
		if bool(panel.call("is_open")):
			if not await _tap(tree, "interact"):
				return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
			waited += 10
			skipped += 1
			continue
		# The player's own press on the prompt, through the interaction arbiter.
		# It must be enabled and offering itself to this player right now: after
		# the host has answered, only a participant still owed their Stormheart
		# keeps it (the rule under proof), so a dark prompt fails here.
		if (ending.get("_local_claim") as Dictionary).is_empty() and waited >= next_ask:
			var offer: Dictionary = prompt.call("interaction_offer", player.global_position)
			if not bool(prompt.get("enabled")) or offer.is_empty():
				return {"verdict": "FAIL", "detail": "the offer prompt is not offering itself to this player (enabled=%s, standing %s, label '%s')"
					% [str(prompt.get("enabled")), standing if not standing.is_empty() else "nowhere in reach", str(prompt.get("label"))]}
			seen_label = str(prompt.get("label"))
			if not await _tap(tree, "interact"):
				return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
			presses_on_prompt += 1
			next_ask = waited + 300
		await tree.physics_frame
		waited += 1
	if not _offer_open(ending, panel):
		return {"verdict": "FAIL", "detail": "no Stormheart offer reached this peer in %d frames (pressed the prompt %d times)"
			% [budget, presses_on_prompt]}
	var presses := 0
	while presses < 40 and bool(panel.call("is_open")) and not _on_confirmation(panel):
		if not await _tap(tree, "interact"):
			return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
		presses += 1
	if not _on_confirmation(panel):
		return {"verdict": "FAIL", "detail": "the offer closed before its Yes/No line (%d presses)" % presses}
	var shot := {}
	if args.has("screenshot"):
		shot = await _screenshot(tree, {"name": str(args.screenshot)})
	if not await _tap(tree, "interact" if answer == "accept" else "menu_cancel"):
		return {"verdict": "ERROR", "detail": "the answer press did not reach this peer"}
	var settle := 0
	while settle < budget and not (ending.get("_local_claim") as Dictionary).is_empty():
		await tree.physics_frame
		settle += 1
	var state := _stormheart_state(tree)
	var settled := (ending.get("_local_claim") as Dictionary).is_empty()
	return {"verdict": "PASS" if settled else "FAIL",
		"detail": "party holds the Stormheart=%s; claim settled=%s; answered %s by pressing the enabled prompt '%s' %d time(s) (standing %s), after %d earlier line(s) and %d offer line(s)%s"
			% [str((state.data as Dictionary).get("has_stormheart")), str(settled), answer, seen_label,
				presses_on_prompt, standing, skipped, presses,
				"" if shot.is_empty() else "; " + str(shot.get("detail", ""))],
		"data": state.data}


static func _offer_open(ending: Node, panel: Node) -> bool:
	var runner: RefCounted = panel.call("runner")
	return runner != null and not (ending.get("_local_claim") as Dictionary).is_empty() \
		and bool(panel.call("is_open")) \
		and str(runner.call("conversation_id")) == load(ENDING_PATH).OFFER_CONVERSATION


static func _on_confirmation(panel: Node) -> bool:
	var runner: RefCounted = panel.call("runner")
	return runner != null and bool(runner.call("is_active")) \
		and bool((runner.call("line") as Dictionary).get("confirmation", false))


## One press and release of `action` through peer_runner's own input edge
## (the physical event plus the polled state). False if either edge failed.
static func _tap(tree: SceneTree, action: String) -> bool:
	var down: Variant = await tree.call("_press_edge", action, true)
	for f in 2:
		await tree.physics_frame
	var up: Variant = await tree.call("_press_edge", action, false)
	for f in 8:
		await tree.physics_frame
	return _edge_ok(down) and _edge_ok(up)


static func _edge_ok(result: Variant) -> bool:
	return not (result is Dictionary) or bool((result as Dictionary).get("ok", true))


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
