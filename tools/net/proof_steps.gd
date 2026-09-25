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
##   release_for_catch {release, species, nickname}  SETUP: at a full party, let
##                                         one companion go for a new catch, exactly as
##                                         the release ceremony does (remove_at, then add)
##   rename_member   {from, to}           SETUP: give a companion a distinct name
##   await_probe     {what, path, equals, budget_frames?}  poll one of this peer's
##                                         probes until the value at `path` equals `equals`
##   rider_identity  {character_id}       F12: this peer's picture of ANOTHER player's
##                                         ride, found by character (peer ids change on
##                                         rejoin): registry row, trainer body, mount
##   rider_self      {}                   F12: the rider's own identity and ride
##   guardian_fixture {participants}      HOST, F14 SETUP: the Veilfall prerequisites,
##                                         then Nerissa's defeat by `participants` (peer
##                                         ids) through the director's own session path
##   veilfall_press  {prompt}             press a Veilfall prompt: a control id, `invite`
##                                         or `decline`
##   guardian_answer {release?, until?, screenshot?}  answer THIS peer's Guardian offer
##                                         with controller presses: Accept, or at a full
##                                         belt let `release` go for it
##   guardian_state  {}                   this peer's own Guardian outcome (+ host journal)
##   grandpa_homecoming {screenshot?, must_name?, must_not_name?}  F15: walk up to
##                                         Grandpa, press his real prompt, read the whole
##                                         conversation, report every line and check names
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
const SPECIES_DATA := preload("res://scripts/creatures/creature_species.gd")
const PARTY_SEAM := preload("res://scripts/story/party_seam.gd")
const NET_PROGRESSION := preload("res://scripts/creatures/progression.gd")
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const LEGENDARY_SPECIES := "fulgocobra"

const ACTIONS := ["load_save", "screenshot", "capture_saves", "check_saved", "stormheart_fixture",
	"stormheart_answer", "stormheart_state", "release_for_catch", "rename_member", "grandpa_homecoming", "await_probe",
	"rider_identity", "rider_self", "guardian_fixture", "veilfall_press", "guardian_answer", "guardian_state"]


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
		"release_for_catch":
			return _release_for_catch(tree, args)
		"rename_member":
			return _rename_member(tree, args)
		"grandpa_homecoming":
			return await _grandpa_homecoming(tree, args)
		"await_probe":
			return await _await_probe(tree, args)
		"rider_identity":
			return _rider_identity(tree, args)
		"rider_self":
			return await _rider_self(tree)
		"guardian_fixture":
			return await _guardian_fixture(tree, args)
		"veilfall_press":
			return await _veilfall_press(tree, args)
		"guardian_answer":
			return await _guardian_answer(tree, args)
		"guardian_state":
			return _guardian_state(tree)
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


# --- F15: Grandpa's homecoming ------------------------------------------------------

static func _party_names(game: Node) -> Array:
	var names: Array = []
	var party: RefCounted = game.get("party") if game != null else null
	if party != null:
		for member: Variant in (party.call("members") as Array):
			var m := member as RefCounted
			var nick := str(m.get("nickname"))
			names.append(nick if not nick.is_empty() else str(m.get("display_name")))
	return names


## SETUP only: the release is not the clause under proof, Grandpa's reading
## of the team afterwards is. This is `tab_creatures.gd::_do_release()`'s own
## sequence for a new catch at a full party -- the only state in which the game
## lets a companion go: `party.remove_at(slot)`, then `party.add(newcomer)` into
## the freed holder, then the pending catch is cleared.
static func _release_for_catch(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party == null:
		return {"verdict": "ERROR", "detail": "no Game.party"}
	var names := _party_names(game)
	if names.size() < 5:
		return {"verdict": "FAIL", "detail": "the game releases only at a full party; this one is %s" % str(names)}
	var slot := names.find(str(args.get("release", "")))
	if slot < 0:
		return {"verdict": "FAIL", "detail": "no companion called '%s' in %s" % [str(args.get("release", "")), str(names)]}
	var newcomer: RefCounted = SPECIES_DATA.spawn(str(args.get("species", "")))
	if newcomer == null:
		return {"verdict": "ERROR", "detail": "species.json has no '%s'" % str(args.get("species", ""))}
	var cfg: Dictionary = NET_PROGRESSION.config()
	newcomer.call("set_level", int((cfg.get("level", {}) as Dictionary).get("starter_level", 3)), cfg)
	PARTY_SEAM.set_nickname(newcomer, str(args.get("nickname", "")))
	game.set("pending_catch", newcomer)
	var released: Variant = party.call("remove_at", slot)
	var landed := released != null and bool(party.call("add", newcomer))
	game.set("pending_catch", null)
	return {"verdict": "PASS" if landed else "FAIL",
		"detail": "released '%s' for new catch '%s'; party now %s" % [str(args.get("release", "")),
			str(args.get("nickname", "")), str(_party_names(game))],
		"data": {"party": _party_names(game)}}


static func _rename_member(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var party: RefCounted = game.get("party") if game != null else null
	var names := _party_names(game)
	var slot := names.find(str(args.get("from", "")))
	if party == null or slot < 0:
		return {"verdict": "FAIL", "detail": "no companion called '%s' in %s" % [str(args.get("from", "")), str(names)]}
	PARTY_SEAM.set_nickname((party.call("members") as Array)[slot], str(args.get("to", "")))
	return {"verdict": "PASS", "detail": "party now %s" % str(_party_names(game)), "data": {"party": _party_names(game)}}


## The player's own visit: stand where Grandpa's prompt really offers itself,
## read through any conversation already on screen, press `interact` through
## the interaction arbiter, then read the conversation Grandpa starts to its
## natural end with `interact`, recording every line as the panel substitutes
## it. Grandpa's homecoming is local to each peer (sequence_director.gd), so
## this runs on each peer separately.
static func _grandpa_homecoming(tree: SceneTree, args: Dictionary) -> Dictionary:
	var director: Node = tree.call("_sequence_director")
	if director == null:
		return {"verdict": "ERROR", "detail": "no SequenceDirector in this peer's scene"}
	var prompt := director.get("_grandpa_prompt") as Node3D
	var panel: Node = director.get("_dialogue")
	var player := (tree.get("_probe") as Object).call("player") as Node3D
	if prompt == null or panel == null or player == null:
		return {"verdict": "ERROR", "detail": "no Grandpa prompt, dialogue panel or player"}
	var game := tree.root.get_node_or_null(^"Game")
	var party_before := _party_names(game)
	var standing := ""
	for offset: Vector3 in [Vector3(0.9, 0.2, 0), Vector3(-0.9, 0.2, 0), Vector3(0, 0.2, 0.9),
			Vector3(0, 0.2, -0.9), Vector3(1.6, 0.2, 1.6), Vector3(-1.6, 0.2, -1.6)]:
		var at := prompt.global_position + offset
		await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": 60})
		if not (prompt.call("interaction_offer", player.global_position) as Dictionary).is_empty():
			standing = str(offset)
			break
	var cleared := 0
	while cleared < 40 and bool(panel.call("is_open")):
		if not await _tap(tree, "interact"):
			return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
		cleared += 1
	var offer: Dictionary = prompt.call("interaction_offer", player.global_position)
	if not bool(prompt.get("enabled")) or offer.is_empty():
		return {"verdict": "FAIL", "detail": "Grandpa's prompt is not offering itself (enabled=%s, standing %s)"
			% [str(prompt.get("enabled")), standing if not standing.is_empty() else "nowhere in reach"]}
	# Every line the panel presents (substituted), whatever the press timing -- a press buffered through the panel's input guard can
	# advance twice, so polling between presses would miss lines.
	var runner: RefCounted = panel.call("runner")
	var lines: Array = []
	var record := func(_conversation: String, _is_last: bool) -> void:
		# The panel redraws (and re-emits) every frame; keep each line once.
		var line: Dictionary = runner.call("line")
		var row := "%s: %s" % [str(line.get("speaker", "")), str(line.get("text", ""))]
		if lines.is_empty() or lines[-1] != row:
			lines.append(row)
	panel.connect("line_presented", record)
	if not await _tap(tree, "interact"):
		panel.disconnect("line_presented", record)
		return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
	var conversation := str(runner.call("conversation_id")) if runner != null and bool(panel.call("is_open")) else ""
	var shot := {}
	var guard := 0
	while guard < 60 and bool(panel.call("is_open")):
		if args.has("screenshot") and shot.is_empty() and lines.size() >= 3:
			shot = await _screenshot(tree, {"name": str(args.screenshot)})
		if not await _tap(tree, "interact"):
			panel.disconnect("line_presented", record)
			return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
		guard += 1
	panel.disconnect("line_presented", record)
	for f in 30:
		await tree.physics_frame
	var flags: RefCounted = game.call("player_flags") if game != null else null
	var seen := flags != null and bool(flags.call("has", "homecoming_seen"))
	var credits := tree.root.find_child("RegionalCredits", true, false) != null
	var data := {"conversation_id": conversation, "lines": lines, "party": party_before,
		"homecoming_seen": seen, "credits_opened": credits}
	# The acknowledgement itself: one "<name> came home with you." per current
	# companion, in party order, and no other such line.
	var named_lines: Array = lines.filter(func(l: String) -> bool: return l.ends_with(" came home with you."))
	var expected_lines: Array = party_before.map(func(n: String) -> String:
		return "Grandpa Elias: %s came home with you." % n)
	data["named_lines"] = named_lines
	var text := "\n".join(lines)
	var unnamed: Array = []
	for name: Variant in (args.get("must_name", []) as Array):
		if not text.contains(str(name)):
			unnamed.append(str(name))
	var wrongly_named: Array = []
	for name: Variant in (args.get("must_not_name", []) as Array):
		if text.contains(str(name)):
			wrongly_named.append(str(name))
	data["unnamed"] = unnamed
	data["wrongly_named"] = wrongly_named
	# The game's rule (regional_homecoming.gd): the first visit's conversation
	# is chosen by the live party size, so it must match this player's team.
	var expected := "regional_homecoming_%d" % mini(party_before.size(), 5)
	data["expected_conversation"] = expected
	var ok := conversation == expected and not bool(panel.call("is_open")) and seen \
		and named_lines == expected_lines \
		and unnamed.is_empty() and wrongly_named.is_empty()
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "conversation '%s' (expected '%s', %d lines) for party %s; homecoming_seen=%s; missing names %s; wrongly named %s; credits opened=%s%s; lines: %s"
			% [conversation, expected, lines.size(), str(party_before), str(seen), str(unnamed), str(wrongly_named), str(credits),
				"" if shot.is_empty() else "; " + str(shot.get("detail", "")), " | ".join(lines)],
		"data": data}


# --- generic: wait on a probe --------------------------------------------------------

static func _dig(value: Variant, path: Array) -> Variant:
	var at: Variant = value
	for raw: Variant in path:
		# Arguments arrive as JSON, so a peer id in a path is a float here.
		var key := str(int(raw)) if raw is float and float(raw) == floorf(float(raw)) else str(raw)
		if at is Dictionary and (at as Dictionary).has(key):
			at = (at as Dictionary)[key]
		else:
			return null
	return at


static func _await_probe(tree: SceneTree, args: Dictionary) -> Dictionary:
	var what := str(args.get("what", ""))
	var path: Array = args.get("path", []) as Array
	var want: Variant = args.get("equals")
	var budget := int(args.get("budget_frames", 1800))
	var got: Variant = null
	for i in budget:
		got = _dig(await tree.call("_execute_probe", {"what": what, "args": args.get("args", {})}), path)
		var numeric := typeof(got) in [TYPE_INT, TYPE_FLOAT] and typeof(want) in [TYPE_INT, TYPE_FLOAT]
		if (numeric and is_equal_approx(float(got), float(want))) or (not numeric and typeof(got) == typeof(want) and got == want):
			return {"verdict": "PASS", "detail": "%s.%s == %s after %d polls" % [what, ".".join(path), str(want), i],
				"data": {"value": got}}
		await tree.physics_frame
	return {"verdict": "FAIL", "detail": "%s.%s was %s, not %s, after %d polls" % [what, ".".join(path),
		str(got), str(want), budget], "data": {"value": got}}


# --- F12: remote rider identity ----------------------------------------------------

## What THIS peer shows of the player whose character is `character_id`,
## found by character rather than by peer id (a rejoin mints a new peer id):
## the registry row, the trainer body standing for them (its character,
## nameplate and whether it is drawn riding and seated), and the mount carrying
## them (its owner character and peer, authority, species, saddle and swim
## mode). `agree` is true only when every one of those names the same person
## and exactly one body and one mount do, with nothing left over from an
## earlier peer id.
static func _rider_identity(tree: SceneTree, args: Dictionary) -> Dictionary:
	var cid := str(args.get("character_id", ""))
	if cid.is_empty():
		return {"verdict": "ERROR", "detail": "rider_identity needs args.character_id"}
	var sess: Node = tree.call("_session")
	var rows: Array = (sess.call("peers") as Array) if sess != null else []
	var matching_rows: Array = rows.filter(func(r: Variant) -> bool:
		return r is Dictionary and str((r as Dictionary).get("character_id", "")) == cid)
	var pid := int((matching_rows[0] as Dictionary).get("peer_id", 0)) if matching_rows.size() == 1 else 0
	var row_name := str((matching_rows[0] as Dictionary).get("display_name", "")) if matching_rows.size() == 1 else ""
	var live_peers: Array = (tree.call("_session_peer_ids") as Array)
	var bodies: Array = []
	var stale_bodies := 0
	for body: Node in tree.get_nodes_in_group(&"remote_trainer"):
		if not (body is Node3D) or body.is_multiplayer_authority():
			continue
		if not live_peers.has(int(body.get("peer_id"))):
			stale_bodies += 1
		if str(body.get("character_id")) == cid:
			bodies.append(body)
	var mounts: Array = []
	var stale_mounts := 0
	for mount: Node in tree.get_nodes_in_group(&"remote_creature"):
		if not (mount is Node3D) or mount.is_multiplayer_authority():
			continue
		if not live_peers.has(int(mount.get("owner_peer_id"))):
			stale_mounts += 1
		if str(mount.get("owner_character_id")) == cid:
			mounts.append(mount)
	var body: Node3D = bodies[0] if bodies.size() == 1 else null
	var mount: Node3D = mounts[0] if mounts.size() == 1 else null
	var plate := body.get_node_or_null(^"Nameplate") as Label3D if body != null else null
	var model: Node = body.get_node_or_null(^"Model") if body != null else null
	var aquatic: Dictionary = (mount.get("aquatic") as RefCounted).call("snapshot") \
		if mount != null and mount.get("aquatic") != null else {}
	var data := {
		"peer_id": pid, "registry_rows": matching_rows.size(), "registry_display_name": row_name,
		"bodies": bodies.size(), "mounts": mounts.size(),
		"stale_bodies": stale_bodies, "stale_mounts": stale_mounts,
		"body_peer_id": int(body.get("peer_id")) if body != null else 0,
		"nameplate": plate.text if plate != null else "",
		"body_visible_in_scene": body != null and body.visible and tree.current_scene != null
			and tree.current_scene.is_ancestor_of(body),
		"riding": body != null and bool(body.get("net_riding")),
		"seated": model != null and model.has_method("ride_pose_applied") and bool(model.call("ride_pose_applied")),
		"mount_owner_peer_id": int(mount.get("owner_peer_id")) if mount != null else 0,
		"mount_authority": mount.get_multiplayer_authority() if mount != null else 0,
		"mount_species": str(mount.get("species_id")) if mount != null else "",
		"mount_saddle_worn": mount != null and mount.get_node_or_null(^"RideSaddle") != null,
		"mount_swim_mode": int(aquatic.get("mode", -1)),
		"mount_swim_owner": int(aquatic.get("owner_peer_id", 0)),
	}
	var agree: bool = pid > 0 and matching_rows.size() == 1 and bodies.size() == 1 and mounts.size() == 1 \
		and stale_bodies == 0 and stale_mounts == 0 and data.body_peer_id == pid \
		and data.mount_owner_peer_id == pid and data.mount_authority == pid and data.mount_swim_owner == pid \
		and str(data.nameplate) == row_name and bool(data.riding) and bool(data.mount_saddle_worn)
	data["agree"] = agree
	return {"verdict": "PASS" if agree else "FAIL",
		"detail": "character %s: %s" % [cid.left(18), JSON.stringify(data)], "data": data}


## The rider's own side of the same question: who this peer is and what it is
## riding right now.
static func _rider_self(tree: SceneTree) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var local: RefCounted = game.get("local") if game != null else null
	var riding: Dictionary = await tree.call("_execute_probe", {"what": "riding"})
	var swim: Dictionary = await tree.call("_execute_probe", {"what": "water_swimming"})
	var own: Dictionary = riding.get("local", {}) as Dictionary
	var aquatic: Dictionary = ((swim.get("local", {}) as Dictionary).get("aquatic", {}) as Dictionary)
	var sess: Node = tree.call("_session")
	var data := {
		"character_id": str(local.get("character_id")) if local != null else "",
		"peer_id": int(sess.call("local_peer_id")) if sess != null else 0,
		"mounted": bool(own.get("mounted", false)),
		"mount_species": str(own.get("species", "")),
		"saddle_worn": bool(own.get("saddle_worn", false)),
		"swim_mode": int(aquatic.get("mode", -1)),
		"realm": str(game.get("current_realm")) if game != null else "",
	}
	return {"verdict": "PASS", "detail": JSON.stringify(data), "data": data}



# --- F14: the Guardian's per-participant offer ---------------------------------------

const GUARDIAN_SPECIES := "water_abyssal_guardian"
const NERISSA_ID := "water_trainer_nerissa"
## The Veilfall chain up to Nerissa (water_veilfall.json: the two controls'
## and the captain's `requires`), set through the ledger as stand-ins for
## playing the Veilfall.
const VEILFALL_PREREQUISITES := ["water_dock_sluice_isle_both_controls_disabled",
	"water_veilfall_intake_stopped", "water_veilfall_return_opened"]
const GUARDIAN_REWARD_PATH := "res://scripts/world/water_guardian_reward.gd"


static func _veilfall(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null(^"WaterArchipelago/WaterVeilfall")


static func _claims(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null(^"Game/Session/LedgerRpc/WaterCaptureClaims")


## HOST, SETUP only: who fought Nerissa, then her defeat, through the director's
## OWN session path -- `_record_trainer_defeat_for_the_session()` journals one
## Nerissa reward row per participant (the rows that make a character a
## freeing-fight participant, water_guardian_reward.gd) and submits her defeat
## as a world fact. Stands in for playing the fight; nothing is written by hand.
static func _guardian_fixture(tree: SceneTree, args: Dictionary) -> Dictionary:
	var sess: Node = tree.call("_session")
	if sess == null or not bool(sess.call("is_active")) or not bool(sess.call("is_host")):
		return {"verdict": "ERROR", "detail": "guardian_fixture runs on the session host only"}
	var scene := tree.current_scene
	var director := scene.find_child("EncounterDirector", true, false) if scene != null else null
	if director == null or not (director.get("trainer_specs") as Dictionary).has(NERISSA_ID):
		return {"verdict": "ERROR", "detail": "no EncounterDirector holding Nerissa's encounter in the host's scene"}
	var game := tree.root.get_node_or_null(^"Game")
	var written: Array[String] = []
	for flag: String in VEILFALL_PREREQUISITES:
		if game.world.flags.has(flag):
			continue
		var verdict: Dictionary = STORY_LEDGER.set_world_flag(game, flag)
		if not (bool(verdict.get("ok", false)) or bool(verdict.get("pending", false))):
			return {"verdict": "FAIL", "detail": "%s refused: code='%s' reason='%s'"
				% [flag, str(verdict.get("code", "")), str(verdict.get("reason", ""))]}
		written.append(flag)
	var fought: Dictionary = director.get("_trainer_battle_participants")
	fought.clear()
	for raw: Variant in (args.get("participants", []) as Array):
		fought[int(raw)] = true
	var spec: Dictionary = (director.get("trainer_specs") as Dictionary)[NERISSA_ID]
	var handled := bool(director.call("_record_trainer_defeat_for_the_session", spec))
	var budget := 600
	while budget > 0 and not game.world.flags.has(str(spec.get("defeat_flag", ""))):
		await tree.physics_frame
		budget -= 1
	var reward: GDScript = load(GUARDIAN_REWARD_PATH)
	var participants: Array = reward.call("participants", game.world)
	var defeated := game.world.flags.has(str(spec.get("defeat_flag", "")))
	return {"verdict": "PASS" if handled and defeated and participants.size() == fought.size() else "FAIL",
		"detail": "prerequisites committed %s; Nerissa fought by peers %s; session path handled=%s; '%s' set=%s; participant characters %s"
			% [str(written), str(fought.keys()), str(handled), str(spec.get("defeat_flag", "")), str(defeated), str(participants)],
		"data": {"participants": participants, "defeated": defeated}}


## Stand where one of the Veilfall's own prompts offers itself and press
## `interact` through the interaction arbiter. `prompt` is a control id from
## water_veilfall.json (e.g. `guardian_tether`), `invite` or `decline`.
static func _veilfall_press(tree: SceneTree, args: Dictionary) -> Dictionary:
	var veilfall := _veilfall(tree)
	var which := str(args.get("prompt", ""))
	if veilfall == null:
		return {"verdict": "ERROR", "detail": "no WaterVeilfall in this peer's scene"}
	var prompt: Node3D
	match which:
		"invite":
			prompt = veilfall.get("_guardian_prompt")
		"decline":
			prompt = veilfall.get("_decline_prompt")
		_:
			prompt = (veilfall.get("_controls") as Dictionary).get(which)
	var player := (tree.get("_probe") as Object).call("player") as Node3D
	if prompt == null or player == null:
		return {"verdict": "ERROR", "detail": "no Veilfall prompt '%s' (or no player)" % which}
	var standing := ""
	for offset: Vector3 in [Vector3(0, -1.2, -1.6), Vector3(0, -1.2, 1.6), Vector3(1.6, -1.2, 0),
			Vector3(-1.6, -1.2, 0), Vector3(0, -0.4, 0)]:
		var at := prompt.global_position + offset
		await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": 30})
		if bool(prompt.get("enabled")) and not (prompt.call("interaction_offer", player.global_position) as Dictionary).is_empty():
			standing = str(offset)
			break
	if standing.is_empty():
		return {"verdict": "FAIL", "detail": "the '%s' prompt ('%s') does not offer itself (enabled=%s)"
			% [which, str(prompt.get("label")), str(prompt.get("enabled"))]}
	var label := str(prompt.get("label"))
	if not await _tap(tree, "interact"):
		return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
	for f in int(args.get("settle", 60)):
		await tree.physics_frame
	return {"verdict": "PASS", "detail": "pressed '%s' standing at %s" % [label, standing],
		"data": {"label": label}}


static func _creatures_tab(game: Node) -> Node:
	var menu: Node = game.call("menu") if game != null else null
	if menu == null:
		return null
	var tabs: Array = menu.get("_tabs")
	for i in tabs.size():
		if str(tabs[i].id) == "creatures":
			return (menu.get("_bodies") as Array)[i]
	return null


## Tap `dirs` until `target` holds focus (a controller player's own moves).
static func _focus_on(tree: SceneTree, target: Control, dirs: Array) -> bool:
	for dir: String in dirs:
		for i in 7:
			if tree.root.gui_get_focus_owner() == target:
				return true
			await _tap(tree, dir)
	return tree.root.gui_get_focus_owner() == target


## Answer this peer's OWN Guardian offer on the Creatures tab the game opens,
## with controller presses only: with a free holder, Accept (`accept`); at a
## full belt, choose the companion called `release` and "Let them go".
## `until` = `presented` stops once the offer is on screen, unanswered.
static func _guardian_answer(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var tab := _creatures_tab(game)
	var claims := _claims(tree)
	if tab == null or claims == null:
		return {"verdict": "ERROR", "detail": "no Creatures tab or WaterCaptureClaims on this peer"}
	var budget := int(args.get("budget_frames", 1800))
	var stage := ""
	while budget > 0:
		stage = str(tab.get("_release_stage"))
		if stage in ["guardian", "choose"] and game.get("pending_catch") != null:
			break
		await tree.physics_frame
		budget -= 1
	var pending: RefCounted = game.get("pending_catch")
	var species := str(pending.get("species_id")) if pending != null else ""
	var claim_id := str(claims.call("pending_guardian_id"))
	var presented := {"stage": stage, "pending_species": species, "claim_id": claim_id,
		"party_before": _party_names(game)}
	if not stage in ["guardian", "choose"] or species != GUARDIAN_SPECIES or claim_id.is_empty():
		return {"verdict": "FAIL", "detail": "no Guardian offer on screen (stage '%s', pending '%s', claim '%s')"
			% [stage, species, claim_id], "data": presented}
	if args.has("screenshot"):
		await _screenshot(tree, {"name": str(args.screenshot)})
	if str(args.get("until", "")) == "presented":
		return {"verdict": "PASS", "detail": "offer on screen at stage '%s' for party %s"
			% [stage, str(presented.party_before)], "data": presented}
	var release := str(args.get("release", ""))
	if release.is_empty():
		if stage != "guardian":
			return {"verdict": "FAIL", "detail": "asked to accept into a free holder, but the belt is full (stage '%s')" % stage, "data": presented}
		if not await _focus_on(tree, tab.get("_guardian_accept"), ["ui_up", "ui_left"]):
			return {"verdict": "FAIL", "detail": "could not bring focus to Accept", "data": presented}
		await _tap(tree, "ui_accept")
	else:
		if stage != "choose":
			return {"verdict": "FAIL", "detail": "asked to release at a full belt, but stage is '%s'" % stage, "data": presented}
		var slot := (presented.party_before as Array).find(release)
		if slot < 0:
			return {"verdict": "FAIL", "detail": "no companion '%s' to let go" % release, "data": presented}
		if not await _focus_on(tree, (tab.get("_rows") as Array)[slot], ["ui_up", "ui_down"]):
			return {"verdict": "FAIL", "detail": "could not bring focus to %s's row" % release, "data": presented}
		await _tap(tree, "ui_accept")
		if str(tab.get("_release_stage")) != "confirm":
			return {"verdict": "FAIL", "detail": "choosing %s did not ask to confirm (stage '%s')"
				% [release, str(tab.get("_release_stage"))], "data": presented}
		if not await _focus_on(tree, tab.get("_farewell_release"), ["ui_down", "ui_right", "ui_up", "ui_left"]):
			return {"verdict": "FAIL", "detail": "could not bring focus to 'Let them go'", "data": presented}
		await _tap(tree, "ui_accept")
		if args.has("screenshot"):
			await _screenshot(tree, {"name": str(args.screenshot) + "_done"})
		if str(tab.get("_release_stage")) == "done":
			await _focus_on(tree, tab.get("_farewell_done"), ["ui_down", "ui_right"])
			await _tap(tree, "ui_accept")
	# The receipt is saved first, then acknowledged; wait for the host's settlement.
	budget = int(args.get("budget_frames", 1800))
	while budget > 0 and not str(claims.call("pending_guardian_id")).is_empty():
		await tree.physics_frame
		budget -= 1
	var state := _guardian_view(tree)
	var data: Dictionary = presented.merged({"after": state})
	var guardians := int(state.get("guardians_owned", 0))
	var ok := guardians == 1 and int(state.get("party_size", 0)) <= 5 and game.get("pending_catch") == null \
		and bool(state.get("receipt_saved", false)) \
		and (release.is_empty() or not (state.get("party", []) as Array).has(release))
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "answered %s: party %s -> %s; Guardians owned %d; receipt on the saved character=%s"
			% ["Accept" if release.is_empty() else "let %s go" % release, str(presented.party_before),
				str(state.get("party", [])), guardians, str(state.get("receipt_saved", false))],
		"data": data}


## This peer's view of its own Guardian outcome, plus the host's journal when
## this peer is the host.
static func _guardian_view(tree: SceneTree) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var local: RefCounted = game.get("local") if game != null else null
	var character := str(local.get("character_id")) if local != null else ""
	var reward: GDScript = load(GUARDIAN_REWARD_PATH)
	var world: RefCounted = game.get("world") if game != null else null
	var claim_id := str(reward.call("claim_id", reward.call("world_instance", world), character)) \
		if world != null and not character.is_empty() else ""
	var guardians := 0
	var party: RefCounted = game.get("party") if game != null else null
	if party != null:
		for member: Variant in (party.call("members") as Array):
			if str((member as RefCounted).get("species_id")) == GUARDIAN_SPECIES:
				guardians += 1
	var saved := {}
	var store: Object = (game.get("save_system") as Object).get("_characters") if game != null else null
	if store != null and not character.is_empty():
		saved = store.call("read", character)
	var saved_flags: Array = ((saved.get("flags", {}) as Dictionary).get("flags", []) as Array) if saved.get("flags") is Dictionary else []
	var saved_guardians := 0
	for row: Variant in (saved.get("party", []) as Array):
		if row is Dictionary and str((row as Dictionary).get("species_id", "")) == GUARDIAN_SPECIES:
			saved_guardians += 1
	var claims := _claims(tree)
	var view := {"character_id": character, "claim_id": claim_id, "party": _party_names(game),
		"party_size": _party_names(game).size(), "guardians_owned": guardians,
		"saved_guardians": saved_guardians, "saved_party_size": (saved.get("party", []) as Array).size(),
		"receipt_saved": saved_flags.has("water_capture_receipt:" + claim_id),
		"pending_guardian_id": str(claims.call("pending_guardian_id")) if claims != null else "",
		"guardian_freed": world != null and world.flags.has("water_guardian_freed"),
		"offered": world != null and world.flags.has(str(reward.call("offered_flag", character)))}
	var sess: Node = tree.call("_session")
	if sess != null and bool(sess.call("is_active")) and bool(sess.call("is_host")) and world != null:
		view["host_open_claims"] = (world.get("water_capture_claims") as Dictionary).keys()
		view["host_settled"] = world.flags.has("water_guardian_settled")
		view["participants"] = reward.call("participants", world)
	return view


static func _guardian_state(tree: SceneTree) -> Dictionary:
	var view := _guardian_view(tree)
	return {"verdict": "PASS", "detail": JSON.stringify(view), "data": view}
