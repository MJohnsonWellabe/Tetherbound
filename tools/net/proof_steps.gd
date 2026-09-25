extends RefCounted

## Peer-side steps for the two-peer proof command
## (`tools/net/run_two_peer_proof.sh`, runner `tests/smoke_net_proof_two_peer.gd`).
##
## `tools/net/proof_peer_runner.gd` (the proof command's peer process) hands these actions to `run()`
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
## Loaded on first use, not preloaded: every proof peer loads this
## file, and only F11 scenarios need the ending.
const ENDING_PATH := "res://scripts/world/stormwood_ending.gd"
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const LEGENDARY_SPECIES := "fulgocobra"

const ACTIONS := ["load_save", "screenshot", "capture_saves", "check_saved", "stormheart_fixture",
	"stormheart_answer", "stormheart_state",
	"homecoming_complete", "credits_continue", "ending_state", "water_dock_act", "water_dock_state"]


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
	if WATER_ACTIONS.has(action):
		return await _water_run(tree, action, args)
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
	# Rendered peers run with the render loop off (the proof runner's _spawn_peer); draw this
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


# --- F15 (Tidewake / Water lane): the homecoming, the credits, the dock ------------
#
##   homecoming_complete {screenshot?}   walk up to THIS peer's Grandpa, press his real
##                                        prompt, read the conversation the director
##                                        chose through with `interact`; report the
##                                        conversation id and whether the credits opened
##   credits_continue  {screenshot?, second_press?}  wait out the roll's input guard,
##                                        press `interact` (the roll's Continue), then
##                                        a second press; count `acknowledged`
##   ending_state      {disk_reload?}     this peer's F15 ending facts: receipts, pending,
##                                        Grandpa's next conversation, realm keys, Local
##                                        Requests, tracked objective. disk_reload: FIRST
##                                        the production save for this peer, then its
##                                        character is emptied in memory, then read back
##                                        from disk (host: `load_slot`; guest: its
##                                        character file); the process restart stand-in
##   water_dock_act    {action_id, drop?, force?}  walk up to the dock equipment and
##                                        press it. drop = "after_send": flush the intent
##                                        and pull the cable in the same frame, then read
##                                        the character back from disk (crash); drop =
##                                        "after_delta": wait for the commit to reach this
##                                        peer, then pull the cable and read back from
##                                        disk without a save (crash after the in-memory
##                                        debit). force: press even when the prompt is
##                                        dark (a stale client's resend)
##   water_dock_state  {action_id?, grant?, rejoin?}  dock flags, bag counts in memory
##                                        and on disk. grant {item: n}: SETUP first, put the
##                                        materials in this peer's bag and save the character
##                                        (stands in for gathering them). rejoin: first,
##                                        after a water_dock_act crash, the title's returning
##                                        Join (peer_runner `production_join`) back to the
##                                        host this peer was connected to, as this character

const WATER_ACTIONS := ["homecoming_complete", "credits_continue", "ending_state", "water_dock_act",
	"water_dock_state"]
const HOMECOMING_PATH := "res://scripts/story/regional_homecoming.gd"
const QUEST_LOG_PATH := "res://scripts/world/quest_log.gd"
const DOCK_RULES_PATH := "res://scripts/world/water_dock_rules.gd"
const WORLD_LEDGER_PATH := "res://scripts/net/world_ledger.gd"
const CREDITS_CONFIG := "res://data/config/regional_credits.json"


static func _water_run(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"homecoming_complete":
			return await _homecoming_complete(tree, args)
		"credits_continue":
			return await _credits_continue(tree, args)
		"ending_state":
			if bool(args.get("disk_reload", false)):
				var reload := await _disk_reload(tree, args)
				var after := _ending_state(tree)
				after.data["disk_reload"] = reload.data
				after.detail = "%s; then %s" % [str(reload.detail), str(after.detail)]
				after.verdict = reload.verdict
				return after
			return _ending_state(tree)
		"water_dock_act":
			return await _water_dock_act(tree, args)
		"water_dock_state":
			var before := ""
			if args.has("grant"):
				var granted := _water_dock_fixture(tree, {"items": args.grant})
				if str(granted.verdict) != "PASS":
					return granted
				before = str(granted.detail) + "; then "
			if bool(args.get("rejoin", false)):
				var joined: Dictionary = await _relaunch_join(tree, args)
				if str(joined.verdict) != "PASS":
					return joined
				before = "REJOIN: " + str(joined.detail) + "; then "
			var state := _water_dock_state(tree, args)
			state.detail = before + str(state.detail)
			return state
	return {"verdict": "ERROR", "detail": "proof_steps: unknown Water action '%s'" % action}


static func _game(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null(^"Game")


static func _is_host_owned(game: Node) -> bool:
	var session: Variant = game.get("session")
	return session == null or not (session as Node).has_method("is_active") \
		or not bool((session as Node).call("is_active")) or bool((session as Node).call("is_host"))


static func _character_id(game: Node) -> String:
	var local: Variant = game.get("local")
	return str((local as RefCounted).get("character_id")) if local != null else ""


## Stand where `prompt` offers itself to this player, trying a ring around `centre`.
static func _walk_up(tree: SceneTree, prompt: Node3D, centre: Vector3, settle: int) -> String:
	var player := (tree.get("_probe") as Object).call("player") as Node3D
	if player == null or prompt == null:
		return ""
	for offset: Vector3 in [Vector3(1.4, 0.3, 0), Vector3(-1.4, 0.3, 0), Vector3(0, 0.3, 1.4),
			Vector3(0, 0.3, -1.4), Vector3(2.2, 0.6, 1.0), Vector3(-2.2, 0.6, -1.0), Vector3(1.0, 1.0, 2.2)]:
		var at := centre + offset
		await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": settle})
		if not (prompt.call("interaction_offer", player.global_position) as Dictionary).is_empty():
			return str(offset)
	return ""


static func _homecoming_complete(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	var director: Node = tree.call("_sequence_director")
	if game == null or director == null:
		return {"verdict": "ERROR", "detail": "no Game or SequenceDirector in this peer's scene"}
	var homecoming: Variant = load(HOMECOMING_PATH)
	var prompt := director.get("_grandpa_prompt") as Node3D
	var grandpa := director.get("_grandpa") as Node3D
	var panel := director.get("_dialogue") as Node
	if prompt == null or grandpa == null or panel == null:
		return {"verdict": "ERROR", "detail": "the director has no Grandpa/prompt/dialogue panel"}
	var expected := str(homecoming.conversation_id(game))
	var budget := int(args.get("budget_frames", 1800))
	var standing := await _walk_up(tree, prompt, grandpa.global_position, int(args.get("walk_settle", 45)))
	if standing.is_empty():
		return {"verdict": "FAIL", "detail": "Grandpa's prompt never offered itself to this player (enabled=%s, label '%s', expected conversation '%s')"
			% [str(prompt.get("enabled")), str(prompt.get("label")), expected]}
	var waited := 0
	var presses := 0
	while waited < budget and not bool(panel.call("is_open")):
		if presses * 120 <= waited:
			if not await _tap(tree, "interact"):
				return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
			presses += 1
			waited += 10
		await tree.physics_frame
		waited += 1
	if not bool(panel.call("is_open")):
		return {"verdict": "FAIL", "detail": "pressing Grandpa's prompt %d time(s) opened no conversation (expected '%s')" % [presses, expected]}
	var runner: RefCounted = panel.call("runner")
	var conversation := str(runner.call("conversation_id")) if runner != null else ""
	var lines: Array[String] = []
	var shot := {}
	var guard := 0
	while bool(panel.call("is_open")) and guard < 80:
		runner = panel.call("runner")
		if runner != null and bool(runner.call("is_active")):
			var text := str((runner.call("line") as Dictionary).get("text", ""))
			if lines.is_empty() or lines[-1] != text:
				lines.append(text)
		if shot.is_empty() and args.has("screenshot") and lines.size() >= 2:
			shot = await _screenshot(tree, {"name": str(args.screenshot)})
		if not await _tap(tree, "interact"):
			return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
		guard += 1
	var credits_open := false
	for f in int(args.get("credits_wait_frames", 120)):
		var roll: Variant = director.get("_regional_credits")
		if roll != null and is_instance_valid(roll) and bool((roll as Node).call("is_open")):
			credits_open = true
			break
		await tree.physics_frame
	var flags: RefCounted = game.get("local").get("flags")
	var data := {"conversation": conversation, "expected": expected, "lines": lines.size(),
		"initial": bool(homecoming.is_initial(conversation)), "repeat": conversation == str(homecoming.REPEAT_ID),
		"homecoming_seen": bool(flags.call("has", homecoming.SEEN_FLAG)),
		"credits_seen": bool(flags.call("has", homecoming.CREDITS_SEEN_FLAG)),
		"credits_open": credits_open, "credits_pending": bool(homecoming.credits_pending(game)),
		"character_id": _character_id(game), "closed": not bool(panel.call("is_open"))}
	return {"verdict": "PASS" if bool(data.closed) and conversation == expected else "FAIL",
		"detail": "Grandpa: '%s' (expected '%s'), %d line(s), %d press(es) on the prompt standing %s; homecoming_seen=%s credits_open=%s%s"
			% [conversation, expected, lines.size(), presses, standing, str(data.homecoming_seen), str(credits_open),
				"" if shot.is_empty() else "; " + str(shot.get("detail", ""))],
		"data": data}


static func _credits_continue(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	var director: Node = tree.call("_sequence_director")
	if game == null or director == null:
		return {"verdict": "ERROR", "detail": "no Game or SequenceDirector"}
	var roll := director.get("_regional_credits") as Node
	if roll == null or not is_instance_valid(roll) or not bool(roll.call("is_open")):
		return {"verdict": "FAIL", "detail": "the credits roll is not open on this peer"}
	var homecoming: Variant = load(HOMECOMING_PATH)
	var acks: Array = []
	var counter := func(id: String) -> void: acks.append(id)
	roll.connect("acknowledged", counter)
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CREDITS_CONFIG))
	var guard := float(((config as Dictionary).get("motion", {}) as Dictionary).get("input_guard_seconds", 0.25)) \
		if config is Dictionary else 0.25
	var hold := maxf(guard, float(args.get("watch_seconds", guard)))
	var frames := 0
	while float(roll.get("_elapsed")) < hold and frames < 3000:
		await tree.process_frame
		frames += 1
	var shot := {}
	if args.has("screenshot"):
		shot = await _screenshot(tree, {"name": str(args.screenshot)})
	var pending_before := bool(homecoming.credits_pending(game))
	if not await _tap(tree, "interact"):
		return {"verdict": "ERROR", "detail": "the Continue press did not reach this peer"}
	for f in 10:
		await tree.physics_frame
	var after_first := acks.size()
	var open_after := bool(roll.call("is_open"))
	# The second press lands on the world again: standing beside Grandpa it
	# opens his next conversation (the repeat greeting). Read it through, so it
	# neither stays open into the next step nor goes unreported, and show that
	# finishing it does not bring the roll back.
	var second_conversation := ""
	var reopened := false
	if bool(args.get("second_press", true)):
		await _tap(tree, "interact")
		for f in 10:
			await tree.physics_frame
		var panel := director.get("_dialogue") as Node
		if panel != null and bool(panel.call("is_open")):
			var runner: RefCounted = panel.call("runner")
			second_conversation = str(runner.call("conversation_id")) if runner != null else "?"
			var guard_presses := 0
			while bool(panel.call("is_open")) and guard_presses < 40:
				await _tap(tree, "interact")
				guard_presses += 1
			for f in 60:
				await tree.physics_frame
		reopened = bool(roll.call("is_open"))
	if roll.is_connected("acknowledged", counter):
		roll.disconnect("acknowledged", counter)
	var flags: RefCounted = game.get("local").get("flags")
	var saver: Variant = game.get("save_system")
	var characters: Variant = (saver as RefCounted).call("characters") if saver != null else null
	var on_disk: Dictionary = (characters as RefCounted).call("state", _character_id(game)) if characters != null else {}
	var disk_flags := JSON.stringify(on_disk.get("flags", {}))
	var data := {"acknowledged": acks.size(), "acknowledged_after_first_press": after_first,
		"open_after_continue": open_after, "pending_before": pending_before,
		"credits_seen": bool(flags.call("has", homecoming.CREDITS_SEEN_FLAG)),
		"credits_pending": bool(homecoming.credits_pending(game)),
		"credits_seen_on_disk": disk_flags.contains(str(homecoming.CREDITS_SEEN_FLAG)),
		"watched_seconds": snappedf(float(roll.get("_elapsed")), 0.01),
		"second_press_conversation": second_conversation, "credits_reopened": reopened}
	var ok: bool = acks.size() == 1 and after_first == 1 and not open_after and not reopened and bool(data.credits_seen) \
		and not bool(data.credits_pending) and bool(data.credits_seen_on_disk)
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "credits watched %.2fs, Continue pressed; acknowledged %d time(s) (after the first press %d), open after=%s, receipt in memory=%s on disk=%s, pending=%s; second press opened '%s', roll reopened=%s%s"
			% [data.watched_seconds, acks.size(), after_first, str(open_after), str(data.credits_seen),
				str(data.credits_seen_on_disk), str(data.credits_pending), second_conversation, str(reopened),
				"" if shot.is_empty() else "; " + str(shot.get("detail", ""))],
		"data": data}


static func _realm_keys(game: Node) -> Array[String]:
	var out: Array[String] = []
	for store: Variant in [game.get("world").get("flags"), game.get("local").get("flags")]:
		if store == null:
			continue
		for id: Variant in ((store as RefCounted).call("save_data") as Dictionary).get("flags", []):
			if str(id).begins_with("realm_key_") and not out.has(str(id)):
				out.append(str(id))
	out.sort()
	return out


static func _ending_state(tree: SceneTree) -> Dictionary:
	var game := _game(tree)
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game", "data": {}}
	var homecoming: Variant = load(HOMECOMING_PATH)
	var flags: RefCounted = game.get("local").get("flags")
	var reader: RefCounted = load(QUEST_LOG_PATH).new()
	reader.call("set_realm", "meadows")
	var progression: RefCounted = game.get("progression")
	var local_rows: Array = reader.call("local_entries", progression)
	var shown: Array[String] = [str(reader.call("tracked_text", progression)), str(reader.call("tracked_hint", progression))]
	for row: Variant in local_rows:
		shown.append(JSON.stringify(row))
	var sequel := false
	for text: String in shown:
		sequel = sequel or text.to_lower().contains("sequel") or text.to_lower().contains("chapter")
	var keys := _realm_keys(game)
	var director: Node = tree.call("_sequence_director")
	var roll: Variant = director.get("_regional_credits") if director != null else null
	var data := {"character_id": _character_id(game), "host_owned": _is_host_owned(game),
		"currents_restored": bool(game.get("world").get("flags").call("has", homecoming.WORLD_FLAG)),
		"homecoming_seen": bool(flags.call("has", homecoming.SEEN_FLAG)),
		"credits_seen": bool(flags.call("has", homecoming.CREDITS_SEEN_FLAG)),
		"credits_pending": bool(homecoming.credits_pending(game)),
		"credits_open": roll != null and is_instance_valid(roll) and bool((roll as Node).call("is_open")),
		"grandpa_next": str(homecoming.conversation_id(game)),
		"realm_keys": keys, "realm_key_count": keys.size(),
		"local_requests": local_rows.size(), "local_requests_offered": not local_rows.is_empty(), "tracked_id": str(reader.call("tracked_id", progression)),
		"sequel_or_chapter_prompt": sequel}
	return {"verdict": "PASS", "detail": str(data), "data": data}


static func _disk_reload(tree: SceneTree, _args: Dictionary) -> Dictionary:
	var game := _game(tree)
	var saver: Variant = game.get("save_system") if game != null else null
	if saver == null:
		return {"verdict": "ERROR", "detail": "no Game.save_system"}
	var host_owned := _is_host_owned(game)
	var character_id := _character_id(game)
	var characters: RefCounted = (saver as RefCounted).call("characters")
	if host_owned:
		if not bool(game.call("autosave_here")):
			return {"verdict": "FAIL", "detail": "host autosave_here() refused"}
	else:
		game.call("autosave_here")
	if character_id.is_empty() or not bool(characters.call("has", character_id)):
		return {"verdict": "FAIL", "detail": "no character file on disk for '%s'" % character_id}
	var homecoming: Variant = load(HOMECOMING_PATH)
	var local: RefCounted = game.get("local")
	local.call("load_data", {})
	var emptied := not bool(local.get("flags").call("has", homecoming.SEEN_FLAG)) \
		and _character_id(game) == character_id
	var ok := false
	if host_owned:
		ok = bool((saver as RefCounted).call("load_slot", game, int(game.call("autosave_slot"))))
	else:
		ok = bool(characters.call("apply", game, character_id))
	for f in 30:
		await tree.physics_frame
	var back := _character_id(game) == character_id
	return {"verdict": "PASS" if ok and emptied and back else "FAIL",
		"detail": "%s: saved, memory emptied (homecoming receipt gone=%s), read back from disk=%s, same character=%s"
			% ["host slot (world + character)" if host_owned else "guest character file", str(emptied), str(ok), str(back)],
		"data": {"host_owned": host_owned, "emptied": emptied, "reloaded": ok, "character_id": character_id}}


# --- dock ------------------------------------------------------------------------

static func _docks(tree: SceneTree) -> Node:
	var scene := tree.current_scene
	return scene.find_child("WaterDocks", true, false) if scene != null else null


static func _dock_action(action_id: String) -> Dictionary:
	for row: Dictionary in (load(DOCK_RULES_PATH).load_data() as Dictionary).actions:
		if str(row.id) == action_id:
			return row
	return {}


static func _bag(game: Node, items: Array) -> Dictionary:
	var out := {}
	var inventory: RefCounted = game.get("local").get("inventory")
	for item: Variant in items:
		out[str(item)] = int(inventory.call("count", str(item)))
	return out


static func _bag_on_disk(game: Node, items: Array) -> Dictionary:
	var out := {}
	var saver: Variant = game.get("save_system")
	var state: Dictionary = ((saver as RefCounted).call("characters") as RefCounted).call("state", _character_id(game)) \
		if saver != null else {}
	for item: Variant in items:
		out[str(item)] = 0
	for stack: Variant in (state.get("inventory", []) as Array):
		if stack is Dictionary and out.has(str((stack as Dictionary).get("id", ""))):
			out[str(stack.id)] = int(out[str(stack.id)]) + int((stack as Dictionary).get("n", 0))
	return out


static func _save_character(game: Node) -> bool:
	game.call("autosave_here")
	var saver: Variant = game.get("save_system")
	var id := _character_id(game)
	return saver != null and not id.is_empty() \
		and bool(((saver as RefCounted).call("characters") as RefCounted).call("has", id))


static func _water_dock_fixture(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var items: Dictionary = args.get("items", {}) as Dictionary
	var inventory: RefCounted = game.get("local").get("inventory")
	for item: Variant in items:
		var left := int(inventory.call("add", str(item), int(items[item])))
		if left != 0:
			return {"verdict": "FAIL", "detail": "bag had no room for %d %s" % [left, str(item)]}
	var saved := _save_character(game)
	var bag := _bag(game, items.keys())
	var disk := _bag_on_disk(game, items.keys())
	return {"verdict": "PASS" if saved and bag == disk else "FAIL",
		"detail": "SETUP (stands in for gathering): bag %s, on disk %s, saved=%s" % [str(bag), str(disk), str(saved)],
		"data": {"bag": bag, "disk": disk}}


static func _water_dock_act(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	var docks := _docks(tree)
	if game == null or docks == null:
		return {"verdict": "ERROR", "detail": "no Game or WaterDocks (is this peer in Water?)"}
	var action_id := str(args.get("action_id", ""))
	var action := _dock_action(action_id)
	if action.is_empty():
		return {"verdict": "ERROR", "detail": "no dock action '%s'" % action_id}
	var flag := str(action.flag)
	var cost: Array = (action.cost as Dictionary).keys()
	var prompt := (docks.get("_prompts") as Dictionary).get(flag) as Node3D
	if prompt == null:
		return {"verdict": "ERROR", "detail": "the dock has no prompt for '%s'" % flag}
	var drop := str(args.get("drop", "none"))
	var host_owned := _is_host_owned(game)
	var local_peer := tree.root.multiplayer.get_unique_id()
	var takes: Array = []
	var refusals: Array = []
	var ledger: Node = game.get("ledger")
	var world_ledger: Variant = load(WORLD_LEDGER_PATH)
	var on_delta := func(delta: Dictionary) -> void:
		for op: Variant in world_ledger.player_ops_for(delta, local_peer):
			if str((op as Dictionary).get("op", "")) == "item_take":
				takes.append("%s x%d" % [str(op.item), int(op.count)])
	var on_refused := func(kind: String, code: String, _reason: String, _d: Dictionary) -> void:
		if kind == "water_dock_action":
			refusals.append(code)
	ledger.connect("delta_applied", on_delta)
	ledger.connect("intent_refused", on_refused)
	var bag_before := _bag(game, cost)
	var disk_before := _bag_on_disk(game, cost)
	var flag_before := bool(game.get("world").get("flags").call("has", flag))
	var standing := await _walk_up(tree, prompt, prompt.global_position - Vector3(0, 1.0, 0), int(args.get("walk_settle", 60)))
	var offered := not standing.is_empty()
	var shot := {}
	if args.has("screenshot"):
		shot = await _screenshot(tree, {"name": str(args.screenshot)})
	var pressed := ""
	if offered and drop == "none":
		if not await _tap(tree, "interact"):
			return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
		pressed = "interact on the offered prompt"
	elif offered or bool(args.get("force", false)):
		# Same signal the arbiter fires on an interact press, emitted in THIS
		# frame so the cable can be pulled right behind the intent.
		prompt.emit_signal("activated")
		pressed = "prompt activated (%s)" % ("offered" if offered else "FORCED: prompt dark, stale-client resend")
	else:
		ledger.disconnect("delta_applied", on_delta)
		ledger.disconnect("intent_refused", on_refused)
		return {"verdict": "FAIL", "detail": "the '%s' prompt is not offering itself (enabled=%s, flag already set=%s)"
			% [str(action.label), str(prompt.get("enabled")), str(flag_before)],
			"data": {"offered": false, "prompt_enabled": bool(prompt.get("enabled")), "flag_before": flag_before,
				"bag_before": bag_before, "bag_after": bag_before, "item_takes": [], "refusals": []}}
	var crash := ""
	var session: Node = game.get("session")
	var link: Variant = tree.root.multiplayer.multiplayer_peer
	if not host_owned and link is ENetMultiplayerPeer:
		var server: ENetPacketPeer = (link as ENetMultiplayerPeer).get_peer(1)
		if server != null:
			tree.set_meta(&"f15_host_address", [server.get_remote_address(), server.get_remote_port()])
	if drop == "after_send" and not host_owned:
		var peer: Variant = tree.root.multiplayer.multiplayer_peer
		if peer is ENetMultiplayerPeer and (peer as ENetMultiplayerPeer).host != null:
			(peer as ENetMultiplayerPeer).host.flush()
		(peer as MultiplayerPeer).close()
		crash = _crash_reload(game)
	var budget := int(args.get("budget_frames", 600))
	var waited := 0
	while waited < budget:
		# A fresh action settles on its flag; a press of a finished one waits for
		# its refusal (or the whole budget), so a late second debit is still seen.
		if crash.is_empty() and ((not flag_before and bool(game.get("world").get("flags").call("has", flag)))
				or not refusals.is_empty() or (flag_before and waited >= int(args.get("settle_frames", 240)))):
			break
		if not crash.is_empty() and waited >= 120:
			break
		await tree.physics_frame
		waited += 1
	if drop == "after_delta" and not host_owned and crash.is_empty():
		(tree.root.multiplayer.multiplayer_peer as MultiplayerPeer).close()
		crash = _crash_reload(game)
		for f in 120:
			await tree.physics_frame
	if ledger.is_connected("delta_applied", on_delta):
		ledger.disconnect("delta_applied", on_delta)
	if ledger.is_connected("intent_refused", on_refused):
		ledger.disconnect("intent_refused", on_refused)
	var bag_after := _bag(game, cost)
	var disk_after := _bag_on_disk(game, cost)
	var taken := {}
	for item: String in bag_before:
		taken[item] = int(bag_before[item]) - int(bag_after[item])
	var data := {"action_id": action_id, "offered": offered, "pressed": pressed, "drop": drop,
		"flag_before": flag_before, "flag_after": bool(game.get("world").get("flags").call("has", flag)),
		"bag_before": bag_before, "bag_after": bag_after, "taken": taken,
		"disk_before": disk_before, "disk_after": disk_after,
		"item_takes": takes, "refusals": refusals, "crash": crash,
		"session_active": session != null and bool(session.call("is_active"))}
	return {"verdict": "PASS",
		"detail": "%s standing %s; flag %s -> %s; bag %s -> %s (disk %s -> %s); item_take ops seen %s; refusals %s%s%s"
			% [pressed, standing if offered else "(not offered)", str(flag_before), str(data.flag_after),
				str(bag_before), str(bag_after), str(disk_before), str(disk_after), str(takes), str(refusals),
				"" if crash.is_empty() else "; CRASH stand-in: " + crash,
				"" if shot.is_empty() else "; " + str(shot.get("detail", ""))],
		"data": data}


## The process-restart stand-in for a crash: in the frame the cable is pulled,
## drop what this process holds and read its character back from disk. No save
## runs first (a crash makes none).
static func _crash_reload(game: Node) -> String:
	var id := _character_id(game)
	var characters: RefCounted = (game.get("save_system") as RefCounted).call("characters")
	var ok := bool(characters.call("apply", game, id))
	return "transport closed; character '%s' read back from disk=%s (no save)" % [id, str(ok)]


static func _water_dock_state(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game", "data": {}}
	var rules: Dictionary = load(DOCK_RULES_PATH).load_data()
	var done := {}
	var items: Array = []
	for row: Dictionary in rules.actions:
		done[str(row.id)] = bool(game.get("world").get("flags").call("has", str(row.flag)))
		for item: Variant in (row.cost as Dictionary):
			if not items.has(item):
				items.append(item)
	var docks := _docks(tree)
	var action_id := str(args.get("action_id", ""))
	var prompt_enabled: Variant = null
	if docks != null and not action_id.is_empty():
		var p: Variant = (docks.get("_prompts") as Dictionary).get(str(_dock_action(action_id).get("flag", "")))
		prompt_enabled = bool((p as Node).get("enabled")) if p != null else null
	var session: Node = game.get("session")
	var data := {"character_id": _character_id(game), "done": done, "bag": _bag(game, items),
		"disk": _bag_on_disk(game, items), "prompt_enabled": prompt_enabled,
		"session_active": session != null and bool(session.call("is_active")),
		"realm": str(game.get("current_realm"))}
	return {"verdict": "PASS", "detail": str(data), "data": data}


static func _relaunch_join(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	if game == null or not tree.has_meta(&"f15_host_address"):
		return {"verdict": "ERROR", "detail": "no remembered host address (relaunch_join follows a water_dock_act crash)"}
	var address: Array = tree.get_meta(&"f15_host_address")
	var result: Dictionary = await tree.call("_step_production_join", {"host": str(address[0]),
		"port": int(address[1]), "character": {"character_id": _character_id(game)},
		"budget_frames": int(args.get("budget_frames", 3000))})
	result["data"] = {"character_id": _character_id(game), "realm": str(game.get("current_realm"))}
	return result
