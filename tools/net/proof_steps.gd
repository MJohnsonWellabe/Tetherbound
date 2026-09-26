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
##   stormheart_answer  {answer, drop_at_ack?}  answer THIS peer's Stormheart offer through
##                                         the real dialogue: interact = Yes, menu_cancel = No
##   stormheart_claim_again {}            send the prompt's ending_claim WITHOUT the acceptance
##                                         hint; the HOST must refuse from its own record
##   stormheart_state {character?}        this peer's view of the F11 outcome (character:
##                                         also the world's receipt of that character's answer)
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
##   guardian_offer_again {}              ask the HOST for this character's offer once more,
##                                         past the hidden prompt: the intent the prompt sends
##   guardian_offer_refused {contains?}   the same intent from a NON-participant: PASS when the
##                                         host's refusal line (default: not_participant's) arrives
##                                         and no claim, marker or Guardian reaches this character
##   nerissa_challenge {}                 F14: Veilfall prerequisites via the ledger, then take up
##                                         Nerissa's challenge at her Veilfall spot (then
##                                         win_trainer_battle); data.multi_peer at the time
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
## Loaded on first use, not preloaded: every proof peer loads this
## file, and only F11 scenarios need the ending.
const ENDING_PATH := "res://scripts/world/stormwood_ending.gd"
const SPECIES_DATA := preload("res://scripts/creatures/creature_species.gd")
const PARTY_SEAM := preload("res://scripts/story/party_seam.gd")
const NET_PROGRESSION := preload("res://scripts/creatures/progression.gd")
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const LEGENDARY_SPECIES := "fulgocobra"

const ACTIONS := ["load_save", "screenshot", "capture_saves", "check_saved", "stormheart_fixture",
	"stormheart_answer", "stormheart_state", "stormheart_claim_again", "release_for_catch", "rename_member", "grandpa_homecoming", "await_probe",
	"rider_identity", "rider_self", "guardian_fixture", "veilfall_press", "guardian_answer", "guardian_state", "guardian_offer_again",
	"homecoming_complete", "credits_continue", "ending_state", "water_dock_act", "water_dock_state",
	"water_dock_resend", "water_dock_cut",
	"water_anchor_fixture", "water_swim_to_wild", "water_local_aquatic", "water_remote_aquatic", "water_win_wild",
	"water_guardian_let_go", "water_guardian_forge_accept",
	"nerissa_challenge", "guardian_offer_refused"]


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
			return _stormheart_state(tree, args)
		"stormheart_claim_again":
			return await _stormheart_claim_again(tree)
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
		"guardian_offer_again":
			return await _guardian_offer_again(tree)
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
	var cut_at_ack := false
	if answer == "accept" and bool(args.get("drop_at_ack", false)):
		# F11 "disconnect at claim acknowledgement". The panel answers Yes in its
		# `_physics_process` and emits `completed`. This one-shot handler closes
		# the transport in that same physics step, before the frame's network
		# poll: whatever the ending then commits (receipt, character save) is
		# local, and the `ending_settled` acknowledgement it sends finds no
		# connected peer. The host-side step that follows proves it never arrived.
		var claim_uid := str(load(ENDING_PATH).call("claim_id", ending.get("_local_claim")))
		var cut := {"done": false, "claim_left": true}
		var on_yes := func(_conversation: String) -> void:
			if is_instance_valid(ending):
				cut.claim_left = not (ending.get("_local_claim") as Dictionary).is_empty()
			(tree.root.multiplayer.multiplayer_peer as MultiplayerPeer).close()
			cut.done = true
		panel.connect("completed", on_yes, CONNECT_ONE_SHOT)
		if not _edge_ok(await tree.call("_press_edge", "interact", true)):
			return {"verdict": "ERROR", "detail": "the answer press did not reach this peer"}
		for f in 240:
			await tree.physics_frame
			if bool(cut.done):
				break
		if is_instance_valid(panel) and panel.is_connected("completed", on_yes):
			panel.disconnect("completed", on_yes)
		await tree.call("_press_edge", "interact", false)
		for f in 60:
			await tree.physics_frame
		# The dropped guest returns to the title; its answer must already be on
		# its saved character (the receipt the rejoin will present).
		var game := tree.root.get_node_or_null(^"Game")
		var character := str((game.get("local") as RefCounted).get("character_id")) if game != null else ""
		var saved: Dictionary = (game.get("save_system") as Object).get("_characters").call("read", character) \
			if game != null and not character.is_empty() else {}
		var saved_flags: Array = ((saved.get("flags", {}) as Dictionary).get("flags", []) as Array) if saved.get("flags") is Dictionary else []
		var receipt_flag := str(load(ENDING_PATH).call("answer_flag", claim_uid, true))
		var receipt_on_disk := not claim_uid.is_empty() and saved_flags.has(receipt_flag)
		cut_at_ack = bool(cut.done) and receipt_on_disk
		var cut_state := _stormheart_state(tree)
		(cut_state.data as Dictionary)["cut_at_ack"] = cut_at_ack
		(cut_state.data as Dictionary)["committed_before_cut"] = not bool(cut.claim_left)
		(cut_state.data as Dictionary)["receipt_on_disk"] = receipt_on_disk
		(cut_state.data as Dictionary)["receipt_flag"] = receipt_flag
		(cut_state.data as Dictionary)["claim_uid"] = claim_uid
		return {"verdict": "PASS" if cut_at_ack else "FAIL",
			"detail": "answered Yes to claim %s; link closed in the answer's own physics step=%s (claim already committed then=%s); '%s' is on the saved character=%s; %s"
				% [claim_uid, str(cut.done), str(not bool(cut.claim_left)), receipt_flag, str(receipt_on_disk), str(cut_state.data)],
			"data": cut_state.data}
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


static func _stormheart_state(tree: SceneTree, args: Dictionary = {}) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game", "data": {}}
	var party: RefCounted = game.get("party")
	var species: Array = []
	var uids: Array = []
	if party != null:
		for member: Variant in (party.call("members") as Array):
			species.append(str((member as RefCounted).get("species_id")))
			uids.append(str((member as RefCounted).get("uid")))
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
		"party_uids": uids,
	}
	# The world's receipt of ANOTHER character's answer (the host reading a guest's).
	var other := str(args.get("character", ""))
	if not other.is_empty():
		data["other_accepted"] = has_flag.call(ending.resolution_flag(true, other))
		data["other_refused"] = has_flag.call(ending.resolution_flag(false, other))
		# The host's own claim entry for that character: one per character.
		var node := _ending(tree)
		if node != null and node.has_method("_saved_state"):
			var claims: Dictionary = (node.call("_saved_state") as Dictionary).get("claims", {})
			var entry: Dictionary = claims.get(other, {})
			data["other_claims"] = claims.keys().filter(func(k: Variant) -> bool: return str(k) == other).size()
			data["other_claim_settled"] = bool(entry.get("settled", false))
			data["other_claim_kept"] = bool(entry.get("kept", false))
			data["other_claim_uid"] = str(ending.claim_id(entry)) if not entry.is_empty() else ""
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
##   water_dock_resend {action_id, budget_frames?}  a stale duplicate copy: re-send this
##                                        character's latest paid escrow txn for the action
##                                        (same txn id, world instance and attempt) straight to
##                                        the ledger, as a client that never saw its verdict
##                                        would; reports the host's answer, the row's status
##                                        and any bag change
##   water_dock_cut    {action_id, report?}  HOST: arm a one-shot cable pull. When the
##                                        ledger commits a REMOTE peer's delta setting the
##                                        action's flag (after its durable world save), that
##                                        requester is disconnected inside delta_applied,
##                                        before `_rpc_delta` is queued: the host committed,
##                                        the delta never reaches the guest. report: what
##                                        the armed cut did (and disarm it). remember_host
##                                        (GUEST): record the host address for a later rejoin

const WATER_ACTIONS := ["homecoming_complete", "credits_continue", "ending_state", "water_dock_act",
	"water_dock_state", "water_dock_resend", "water_dock_cut", "water_anchor_fixture", "water_swim_to_wild",
	"water_local_aquatic", "water_remote_aquatic", "water_win_wild", "water_guardian_let_go",
	"water_guardian_forge_accept",
	"nerissa_challenge", "guardian_offer_refused"]
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
		"water_dock_resend":
			return await _water_dock_resend(tree, args)
		"water_dock_cut":
			return _water_dock_cut(tree, args)
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
		"water_anchor_fixture":
			return await _water_anchor_fixture(tree, args)
		"water_swim_to_wild":
			return await _water_swim_to_wild(tree, args)
		"water_local_aquatic":
			return await _water_local_aquatic(tree, args)
		"water_remote_aquatic":
			return await _water_remote_aquatic(tree, args)
		"water_win_wild":
			return await _water_win_wild(tree, args)
		"water_guardian_let_go":
			return await _water_guardian_let_go(tree, args)
		"water_guardian_forge_accept":
			return await _water_guardian_forge_accept(tree, args)
		"nerissa_challenge":
			return await _nerissa_challenge(tree, args)
		"guardian_offer_refused":
			return await _guardian_offer_refused(tree, args)
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


## HOST, SETUP only: stands in for playing the Nerissa fight. The fight's live
## roster (`_trainer_battle_participants`, normally filled by
## `_note_trainer_participants` during a round) is INJECTED here; the payout
## then goes through the director's own session path --
## `_record_trainer_defeat_for_the_session()` journals one Nerissa reward row
## per participant (the rows that make a character a freeing-fight participant,
## water_guardian_reward.gd) and submits her defeat as a world fact.
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
	# A fight builds the host's encounter record on its first round; no round
	# ran here, so build it the same way.
	director.call("_ensure_encounter_arbiters")
	var handled := bool(director.call("_record_trainer_defeat_for_the_session", spec))
	var budget := 600
	while budget > 0 and not game.world.flags.has(str(spec.get("defeat_flag", ""))):
		await tree.physics_frame
		budget -= 1
	var reward: GDScript = load(GUARDIAN_REWARD_PATH)
	var participants: Array = reward.call("participants", game.world)
	var defeated: bool = game.world.flags.has(str(spec.get("defeat_flag", "")))
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
			% [which, str(prompt.get("label")), str(prompt.get("enabled"))],
			"data": {"enabled": bool(prompt.get("enabled")), "label": str(prompt.get("label"))}}
	# The host judges "beside the mechanism" on ITS copy of this body, which
	# follows a 4 km teleport into the interior a few seconds late (a player
	# walking up gives it that time). Stand still that long before pressing.
	for f in int(args.get("arrive_frames", 240)):
		await tree.physics_frame
	if (prompt.call("interaction_offer", player.global_position) as Dictionary).is_empty():
		return {"verdict": "FAIL", "detail": "the '%s' prompt stopped offering itself while standing" % which,
			"data": {"enabled": bool(prompt.get("enabled"))}}
	var label := str(prompt.get("label"))
	if not await _tap(tree, "interact"):
		return {"verdict": "ERROR", "detail": "the interact press did not reach this peer"}
	# A control's outcome is its world flag (water_veilfall.json); the invite's
	# is the offer guardian_answer waits for.
	var flag := ""
	for control: Dictionary in ((veilfall.get("rules") as Dictionary).get("controls", []) as Array):
		if str(control.get("id", "")) == which:
			flag = str(control.get("flag", ""))
	var game := tree.root.get_node_or_null(^"Game")
	var budget := int(args.get("settle", 60)) if flag.is_empty() else int(args.get("budget_frames", 900))
	for f in budget:
		await tree.physics_frame
		if not flag.is_empty() and game.world.flags.has(flag):
			break
	if not flag.is_empty() and not game.world.flags.has(flag):
		return {"verdict": "FAIL", "detail": "pressed '%s' but '%s' was never set (HUD says '%s')"
			% [label, flag, _label_containing(tree.root, "mechanism")], "data": {"label": label}}
	return {"verdict": "PASS", "detail": "pressed '%s' standing at %s%s" % [label, standing,
		"" if flag.is_empty() else "; '%s' set" % flag], "data": {"label": label}}


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
	for f in 10:
		await tree.physics_frame
	var focus := tree.root.gui_get_focus_owner()
	var presented := {"stage": stage, "pending_species": species, "claim_id": claim_id,
		"party_before": _party_names(game), "tab_visible": (tab as CanvasItem).is_visible_in_tree(),
		"focus": str(tab.get_path_to(focus)) if focus != null and tab.is_ancestor_of(focus) else ("outside: %s" % str(focus.get_path()) if focus != null else "")}
	if not stage in ["guardian", "choose"] or species != GUARDIAN_SPECIES or claim_id.is_empty():
		return {"verdict": "FAIL", "detail": "no Guardian offer on screen (stage '%s', pending '%s', claim '%s')"
			% [stage, species, claim_id], "data": presented}
	if args.has("screenshot"):
		await _screenshot(tree, {"name": str(args.screenshot)})
	if str(args.get("until", "")) == "presented":
		return {"verdict": "PASS", "detail": "offer on screen at stage '%s' for party %s (tab visible=%s, focus '%s')"
			% [stage, str(presented.party_before), str(presented.tab_visible), str(presented.focus)], "data": presented}
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
			var owner := tree.root.gui_get_focus_owner()
			return {"verdict": "FAIL", "detail": "could not bring focus to %s's row (after the presses focus is on %s, menu open=%s, stage '%s'; when presented: tab visible=%s, focus '%s')"
				% [release, str(owner.get_path()) if owner != null else "nothing", str(game.call("menu").call("is_open")),
					str(tab.get("_release_stage")), str(presented.tab_visible), str(presented.focus)], "data": presented}
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
	var ok := guardians == 1 and game.get("pending_catch") == null \
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


## Once only, judged by the authority rather than the prompt: stand beside the
## freed Guardian and send the very intent the invite prompt sends. The host's
## `begin()` must refuse it (`already_resolved`); on a guest the refusal comes
## back as the chamber's world message.
static func _guardian_offer_again(tree: SceneTree) -> Dictionary:
	var veilfall := _veilfall(tree)
	var game := tree.root.get_node_or_null(^"Game")
	if veilfall == null or game == null:
		return {"verdict": "ERROR", "detail": "no WaterVeilfall/Game on this peer"}
	var prompt := veilfall.get("_guardian_prompt") as Node3D
	var at := prompt.global_position + Vector3(0, -1.2, -1.6)
	await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": 240})
	if game.has_method("take_pending_world_message"):
		game.call("take_pending_world_message")
	var claims_before := _guardian_view(tree)
	var result: Dictionary = (veilfall.get("_transport") as Object).call("submit", {"kind": "guardian_offer"})
	# The HUD takes the world message the frame it lands, so read the verdict
	# where it stays: the chamber clears `_invite_unanswered` on a refused
	# offer, and the HUD's line keeps the host's reason.
	var message := ""
	var answered := not bool(result.get("pending", false))
	for f in 600:
		await tree.physics_frame
		if not answered and not bool(veilfall.get("_invite_unanswered")):
			answered = true
		if answered:
			message = _label_containing(tree.root, "already answered")
			if not message.is_empty() or not bool(result.get("pending", false)):
				break
	var after := _guardian_view(tree)
	var refused := (str(result.get("code", "")) == "already_resolved") \
		or (bool(result.get("pending", false)) and message.contains("already answered"))
	var data := {"ok": bool(result.get("ok", false)), "pending": bool(result.get("pending", false)),
		"code": str(result.get("code", "")), "message": message, "refused": refused,
		"pending_guardian_id": str(after.get("pending_guardian_id", "")),
		"guardians_owned": int(after.get("guardians_owned", 0))}
	return {"verdict": "PASS" if refused and str(after.get("pending_guardian_id", "")).is_empty() else "FAIL",
		"detail": "asked the host again: ok=%s pending=%s code='%s' message '%s'; Guardians owned %d -> %d"
			% [str(data.ok), str(data.pending), str(data.code), message,
				int(claims_before.get("guardians_owned", 0)), int(after.get("guardians_owned", 0))],
		"data": data}


## F14 "never an owned sixth", leg 1: at a full belt, answer THIS peer's own
## Guardian offer on the Creatures tab the game opens by letting the GUARDIAN
## itself go (the newcomer row, index 5), with controller presses only. The
## belt must keep exactly the same five, no Guardian, the offer resolved.
static func _water_guardian_let_go(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var tab := _creatures_tab(game)
	var claims := _claims(tree)
	if tab == null or claims == null:
		return {"verdict": "ERROR", "detail": "no Creatures tab or WaterCaptureClaims on this peer"}
	var budget := int(args.get("budget_frames", 1800))
	while budget > 0 and not (str(tab.get("_release_stage")) == "choose" and game.get("pending_catch") != null):
		await tree.physics_frame
		budget -= 1
	for f in 10:
		await tree.physics_frame
	var pending: RefCounted = game.get("pending_catch")
	var before := _guardian_view(tree)
	var presented := {"stage": str(tab.get("_release_stage")),
		"pending_species": str(pending.get("species_id")) if pending != null else "",
		"claim_id": str(claims.call("pending_guardian_id")), "before": before}
	if presented.stage != "choose" or presented.pending_species != GUARDIAN_SPECIES \
			or str(presented.claim_id).is_empty() or int(before.party_size) != 5 or int(before.guardians_owned) != 0:
		return {"verdict": "FAIL", "detail": "no at-capacity Guardian offer on screen (stage '%s', pending '%s', claim '%s', party %s)"
			% [presented.stage, presented.pending_species, presented.claim_id, str(before.party)], "data": presented}
	if args.has("screenshot"):
		await _screenshot(tree, {"name": str(args.screenshot)})
	var newcomer: Button = tab.get("_pending_button")
	if not await _focus_on(tree, newcomer, ["ui_down", "ui_up"]):
		return {"verdict": "FAIL", "detail": "could not bring focus to the Guardian's own (sixth) row", "data": presented}
	await _tap(tree, "ui_accept")
	var target := int(tab.get("_release_target"))
	if str(tab.get("_release_stage")) != "confirm" or target != 5:
		return {"verdict": "FAIL", "detail": "choosing the Guardian's row did not ask to confirm letting it go (stage '%s', target %d)"
			% [str(tab.get("_release_stage")), target], "data": presented}
	if not await _focus_on(tree, tab.get("_farewell_release"), ["ui_down", "ui_right", "ui_up", "ui_left"]):
		return {"verdict": "FAIL", "detail": "could not bring focus to 'Let them go'", "data": presented}
	await _tap(tree, "ui_accept")
	if args.has("screenshot"):
		await _screenshot(tree, {"name": str(args.screenshot) + "_done"})
	if str(tab.get("_release_stage")) == "done":
		await _focus_on(tree, tab.get("_farewell_done"), ["ui_down", "ui_right"])
		await _tap(tree, "ui_accept")
	budget = int(args.get("budget_frames", 1800))
	while budget > 0 and not str(claims.call("pending_guardian_id")).is_empty():
		await tree.physics_frame
		budget -= 1
	var after := _guardian_view(tree)
	var data: Dictionary = presented.merged({"release_target": target, "after": after,
		"party_size": int(after.party_size), "guardians_owned": int(after.guardians_owned),
		"saved_party_size": int(after.saved_party_size), "saved_guardians": int(after.saved_guardians),
		"receipt_saved": bool(after.receipt_saved), "pending_guardian_id": str(after.pending_guardian_id),
		"pending_catch": game.get("pending_catch") != null, "same_five": after.party == before.party})
	var ok: bool = data.same_five and data.party_size == 5 and data.guardians_owned == 0 \
		and data.saved_party_size == 5 and data.saved_guardians == 0 and data.receipt_saved \
		and str(data.pending_guardian_id).is_empty() and not data.pending_catch
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "let the Guardian (row %d) go: party %s -> %s; Guardians owned %d (saved %d, saved party %d); receipt saved=%s; offer still held '%s'; pending_catch=%s"
			% [target, str(before.party), str(after.party), data.guardians_owned, data.saved_guardians,
				data.saved_party_size, str(data.receipt_saved), data.pending_guardian_id, str(data.pending_catch)],
		"data": data}


## F14 "never an owned sixth", leg 2: a MODIFIED client at a full belt, the
## Guardian's offer on screen, bypassing the Creatures tab. In order: (a) the
## settle the tab's Accept calls, with no release (-1); (b) the same with an
## out-of-range release (6); (c) a direct `party.add` of the pending Guardian;
## then (d) the raw accept intent the host acts on -- `_acknowledge(id)`, the
## `_ack` RPC a settled capture sends -- WITHOUT settling or releasing anyone.
## Waits for the host's settlement to reach this peer. PASS only if every local
## attempt refused, the belt stayed the same five (live and saved), no
## Guardian is owned or saved, and the host settled the forged accept.
static func _water_guardian_forge_accept(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var claims := _claims(tree)
	if game == null or claims == null:
		return {"verdict": "ERROR", "detail": "no Game or WaterCaptureClaims on this peer"}
	var budget := int(args.get("budget_frames", 1800))
	while budget > 0 and not (game.get("pending_catch") != null and not str(claims.call("pending_guardian_id")).is_empty()):
		await tree.physics_frame
		budget -= 1
	var pending: RefCounted = game.get("pending_catch")
	var id := str(claims.call("pending_guardian_id"))
	var before := _guardian_view(tree)
	var data := {"claim_id": id, "pending_species": str(pending.get("species_id")) if pending != null else "",
		"before": before, "settled_before": game.world.flags.has("water_guardian_settled")}
	if pending == null or data.pending_species != GUARDIAN_SPECIES or id.is_empty() \
			or int(before.party_size) != 5 or int(before.guardians_owned) != 0 or bool(data.settled_before):
		return {"verdict": "FAIL", "detail": "no unsettled at-capacity Guardian offer to forge against (pending '%s', claim '%s', party %s, settled %s)"
			% [data.pending_species, id, str(before.party), str(data.settled_before)], "data": data}
	var attempts := {}
	var r: Dictionary = claims.call("complete_pending_capture", -1)
	attempts["settle_no_release"] = {"ok": bool(r.get("ok", false)), "reason": str(r.get("reason", "")),
		"party_size": _party_names(game).size()}
	r = claims.call("complete_pending_capture", 6)
	attempts["settle_release_6"] = {"ok": bool(r.get("ok", false)), "reason": str(r.get("reason", "")),
		"party_size": _party_names(game).size()}
	var added := bool((game.get("party") as RefCounted).call("add", pending))
	attempts["party_add"] = {"ok": added, "party_size": _party_names(game).size()}
	var local_refused: bool = not attempts.settle_no_release.ok and not attempts.settle_release_6.ok and not added
	claims.call("_acknowledge", id)
	budget = int(args.get("budget_frames", 1800))
	while budget > 0 and not game.world.flags.has("water_guardian_settled"):
		await tree.physics_frame
		budget -= 1
	for f in 60:
		await tree.physics_frame
	var after := _guardian_view(tree)
	data.merge({"attempts": attempts, "local_refused": local_refused, "raw_ack_sent": id,
		"host_settled_seen": game.world.flags.has("water_guardian_settled"), "after": after,
		"party_size": int(after.party_size), "guardians_owned": int(after.guardians_owned),
		"saved_party_size": int(after.saved_party_size), "saved_guardians": int(after.saved_guardians),
		"receipt_saved": bool(after.receipt_saved), "same_five": after.party == before.party,
		"offer_still_on_screen": game.get("pending_catch") != null and str(claims.call("pending_guardian_id")) == id})
	var ok: bool = local_refused and data.host_settled_seen and data.same_five and data.party_size == 5 \
		and data.guardians_owned == 0 and data.saved_party_size == 5 and data.saved_guardians == 0 \
		and not data.receipt_saved
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "forged at a full belt: settle(-1) ok=%s ('%s'); settle(6) ok=%s ('%s'); party.add ok=%s; raw accept ack for '%s' -> host settled seen=%s; party %s -> %s; Guardians owned %d (saved %d, saved party %d); receipt saved=%s; offer still on screen=%s"
			% [str(attempts.settle_no_release.ok), attempts.settle_no_release.reason, str(attempts.settle_release_6.ok),
				attempts.settle_release_6.reason, str(added), id, str(data.host_settled_seen), str(before.party),
				str(after.party), data.guardians_owned, data.saved_guardians, data.saved_party_size,
				str(data.receipt_saved), str(data.offer_still_on_screen)],
		"data": data}


static func _label_containing(node: Node, needle: String) -> String:
	if node is Label and (node as Label).text.contains(needle):
		return (node as Label).text
	if node is RichTextLabel and (node as RichTextLabel).text.contains(needle):
		return (node as RichTextLabel).text
	for child: Node in node.get_children():
		var found := _label_containing(child, needle)
		if not found.is_empty():
			return found
	return ""


# --- F15: paid dock debit, duplicate txn copy (appended) ---------------------------

static func _water_dock_resend(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	if game == null:
		return {"verdict": "ERROR", "detail": "no /root/Game"}
	var action_id := str(args.get("action_id", ""))
	var action := _dock_action(action_id)
	if action.is_empty():
		return {"verdict": "ERROR", "detail": "no dock action '%s'" % action_id}
	var escrow: Dictionary = game.get("local").get("satchel_escrow")
	var row: Dictionary = {}
	for raw: Variant in escrow.values():
		if raw is Dictionary and str(raw.get("kind", "")) == "water_dock_debit" \
				and str(raw.get("action_id", "")) == action_id \
				and (row.is_empty() or int(raw.get("attempt", 0)) > int(row.get("attempt", 0))):
			row = raw
	if row.is_empty():
		return {"verdict": "FAIL", "detail": "this character has no escrow row for '%s'" % action_id,
			"data": {"found": false}}
	var cost: Array = (action.cost as Dictionary).keys()
	var counts := {}
	for item: String in cost:
		counts[item] = int(action.cost[item])
	var txn := str(row.txn_id)
	var status_before := str(row.status)
	var ledger: Node = game.get("ledger")
	var refusals: Array = []
	var on_refused := func(kind: String, code: String, _reason: String, _d: Dictionary) -> void:
		if kind == "water_dock_action":
			refusals.append(code)
	ledger.connect("intent_refused", on_refused)
	var seq_before := int((ledger.get("ledger") as RefCounted).get("seq"))
	var bag_before := _bag(game, cost)
	var disk_before := _bag_on_disk(game, cost)
	var verdict: Dictionary = ledger.call("submit", {"kind": "water_dock_action", "realm": "water",
		"action_id": action_id, "inventory": counts, "txn_id": txn,
		"world_instance_id": str(row.get("world_instance_id", "")), "attempt": int(row.get("attempt", 1))})
	if not bool(verdict.get("pending", false)) and not bool(verdict.get("ok", false)):
		refusals.append(str(verdict.get("code", "")))
	var waited := 0
	while refusals.is_empty() and waited < int(args.get("budget_frames", 600)):
		await tree.physics_frame
		waited += 1
	for f in 30:
		await tree.physics_frame
	ledger.disconnect("intent_refused", on_refused)
	var bag_after := _bag(game, cost)
	var taken := {}
	for item: String in bag_before:
		taken[item] = int(bag_before[item]) - int(bag_after[item])
	var current: Variant = escrow.get(txn)
	var data := {"found": true, "txn": txn, "attempt": int(row.get("attempt", 1)),
		"status_before": status_before,
		"status_after": str((current as Dictionary).get("status", "")) if current is Dictionary else "",
		"refusals": refusals, "committed": bool(verdict.get("ok", false)),
		"seq_before": seq_before, "seq_after": int((ledger.get("ledger") as RefCounted).get("seq")),
		"taken": taken, "bag_before": bag_before, "bag_after": bag_after,
		"disk_before": disk_before, "disk_after": _bag_on_disk(game, cost)}
	return {"verdict": "PASS",
		"detail": "re-sent txn %s (attempt %d, row %s -> %s); host answer %s after %d frames; bag %s -> %s (disk %s -> %s)"
			% [txn.left(12), int(data.attempt), status_before, str(data.status_after), str(refusals), waited,
				str(bag_before), str(bag_after), str(disk_before), str(data.disk_after)],
		"data": data}


static func _water_dock_cut(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(tree)
	if bool(args.get("remember_host", false)):
		# GUEST, before its press: keep the host address for the later rejoin
		# (water_dock_act only records it after its press, which the cut can beat).
		var link: Variant = tree.root.multiplayer.multiplayer_peer
		var server: ENetPacketPeer = (link as ENetMultiplayerPeer).get_peer(1) if link is ENetMultiplayerPeer else null
		if server == null:
			return {"verdict": "ERROR", "detail": "not connected to a host"}
		tree.set_meta(&"f15_host_address", [server.get_remote_address(), server.get_remote_port()])
		return {"verdict": "PASS", "detail": "remembered host %s:%d" % [server.get_remote_address(), server.get_remote_port()]}
	if game == null or not bool(game.call("is_host")):
		return {"verdict": "ERROR", "detail": "water_dock_cut runs on the host"}
	var ledger: Node = game.get("ledger")
	if bool(args.get("report", false)):
		if not tree.has_meta(&"f15_dock_cut"):
			return {"verdict": "ERROR", "detail": "no armed water_dock_cut"}
		var armed: Dictionary = tree.get_meta(&"f15_dock_cut")
		if ledger.is_connected("delta_applied", armed.handler):
			ledger.disconnect("delta_applied", armed.handler)
		tree.remove_meta(&"f15_dock_cut")
		var data := {"cut": bool(armed.state.cut), "peer": int(armed.state.peer),
			"seq": int(armed.state.seq), "flag_on_host": bool(game.get("world").get("flags").call("has", str(armed.flag)))}
		return {"verdict": "PASS", "detail": "armed cut %s: peer %d disconnected at commit seq %d; host flag %s"
			% ["FIRED" if data.cut else "never fired", data.peer, data.seq, str(data.flag_on_host)], "data": data}
	var action := _dock_action(str(args.get("action_id", "")))
	if action.is_empty():
		return {"verdict": "ERROR", "detail": "no dock action '%s'" % str(args.get("action_id", ""))}
	var flag := str(action.flag)
	var state := {"cut": false, "peer": 0, "seq": 0}
	var mp := tree.root.multiplayer
	var handler := func(delta: Dictionary) -> void:
		if bool(state.cut):
			return
		var sender := mp.get_remote_sender_id()
		if sender <= 1:
			return
		for op: Variant in delta.get("ops", []):
			if op is Dictionary and str(op.get("op", "")) == "flag" and str(op.get("id", "")) == flag \
					and bool(op.get("value", false)):
				# Graceful ENet disconnect resets the peer's unsent queue; the
				# `_rpc_delta` that follows this signal is refused for it.
				(mp.multiplayer_peer as MultiplayerPeer).disconnect_peer(sender)
				state.cut = true
				state.peer = sender
				state.seq = int(delta.get("seq", 0))
				return
	ledger.connect("delta_applied", handler)
	tree.set_meta(&"f15_dock_cut", {"handler": handler, "state": state, "flag": flag})
	return {"verdict": "PASS", "detail": "armed: the next remote commit of '%s' disconnects its requester before the delta is sent" % flag,
		"data": {"armed": true}}


## Once only, judged by the HOST's own record: stand beside the Stormheart and
## send the same `ending_claim` intent the offer prompt sends, but WITHOUT this
## character's portable acceptance hint (`already_accepted: false`), so the
## host can only refuse from its own claims and resolution flags. It must answer
## exactly "You have already answered the Stormheart." -- the reason it gives
## only when it owes this character nothing -- read the moment it arrives
## (after the frame's network poll, before the HUD takes it), never a stale line.
static func _stormheart_claim_again(tree: SceneTree) -> Dictionary:
	var ending := _ending(tree)
	var game := tree.root.get_node_or_null(^"Game")
	var session: Node = game.get("session") if game != null else null
	if ending == null or game == null or session == null:
		return {"verdict": "ERROR", "detail": "no StormwoodEnding/Game/Session on this peer"}
	var prompt := ending.get("_offer_prompt") as Node3D
	if prompt != null:
		var at := prompt.global_position + Vector3(2, 0.5, 0)
		await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": 120})
	var before := _stormheart_state(tree).data as Dictionary
	game.set("_pending_world_message", "")
	session.call("request_stormwood_encounter", {"kind": "ending_claim", "already_accepted": false})
	var reason := ""
	for f in 600:
		await tree.process_frame
		var waiting := str(game.get("_pending_world_message"))
		if not waiting.is_empty():
			reason = waiting
			break
	var after := _stormheart_state(tree).data as Dictionary
	var data := {"refusal": reason, "party_before": before.get("party_uids", []),
		"party_after": after.get("party_uids", [])}
	var ok: bool = reason == "You have already answered the Stormheart." and data.party_before == data.party_after
	return {"verdict": "PASS" if ok else "FAIL",
		"detail": "sent ending_claim without the acceptance hint: host answered '%s'; party %s -> %s"
			% [reason, str(data.party_before), str(data.party_after)], "data": data}


# --- F12 Tidewake: a swimmer's combat pause, seen from both peers -------------
#
##   water_anchor_fixture {anchor_id}      SETUP: stand this peer's trainer on an
##                                        authored Water anchor's dry safe landing (the
##                                        only position write), settle, and require it
##                                        dry with a safe landing earned
##   water_swim_to_wild {site_id, budget_frames?}  real camera-relative stick input
##                                        from where the trainer stands toward the
##                                        site's first live member, until the director
##                                        offers THAT wild through the InteractionArbiter
##                                        (the Engage press itself is the scenario's
##                                        `press interact`)
##   water_local_aquatic {record?, baseline?, min_frames_since?, wait_for_mode?, budget_frames?}
##                                        this peer's own swim state and resources (mode,
##                                        drowning, stamina, health, the fight and active
##                                        creature), top level. `record` keeps a baseline
##                                        under a label; `baseline` reports the change
##                                        since that label and FAILS if it is missing
##   water_remote_aquatic {peer_id, record?, baseline?, min_frames_since?, sample_frames?, wait_for_mode?, budget_frames?}
##                                        this peer's picture of ANOTHER trainer's swim
##                                        state: the snapshot its remote trainer received
##                                        (net_*) and the one it applied (mode, drowning,
##                                        stamina_fraction, revision), plus position.
##                                        `sample_frames` watches every frame of a window
##                                        and reports whether the mode held (mode_steady)
##   water_win_wild  {enemy_hp_ceiling, budget_frames?}  finish the current WILD fight
##                                        through the production combat path: the enemy's
##                                        hp is capped at the ceiling (the allowance
##                                        win_trainer_battle and smoke_water_combat_pause
##                                        use), the creature is steered with the stick and
##                                        `combat_quick` is pressed until the wild faints

const SWIM_HUMAN := 1
const SWIM_PAUSED := 3
const AQUATIC_BASELINES_META := &"proof_water_aquatic_baselines"
const SWIM_CONFIG := "res://data/config/water_swimming.json"


static func _water_scene(tree: SceneTree) -> Node3D:
	var scene := tree.current_scene as Node3D
	if scene == null or not scene.has_method("world_realm") or str(scene.call("world_realm")) != "water":
		return null
	return scene


static func _aquatic_baselines(tree: SceneTree) -> Dictionary:
	if not tree.has_meta(AQUATIC_BASELINES_META):
		tree.set_meta(AQUATIC_BASELINES_META, {})
	return tree.get_meta(AQUATIC_BASELINES_META) as Dictionary


static func _water_anchor_fixture(tree: SceneTree, args: Dictionary) -> Dictionary:
	var world := _water_scene(tree)
	var player := (tree.get("_probe") as Object).call("player") as CharacterBody3D
	if world == null or player == null or player.get("swim_controller") == null:
		return {"verdict": "ERROR", "detail": "water_anchor_fixture needs the real Water scene, Player and SwimController"}
	var id := str(args.get("anchor_id", ""))
	var at := Vector3.INF
	for anchor: Dictionary in (world.get("config") as Dictionary).get("anchors", []):
		if str(anchor.get("id", "")) == id:
			var raw: Array = anchor.safe_position
			at = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	if not at.is_finite():
		return {"verdict": "ERROR", "detail": "no authored Water anchor '%s'" % id}
	at.y = float(world.call("ground_height_at", at.x, at.z)) + 0.15
	tree.call("_drive_left", 0.0, 0.0)
	# A teleport, not a kinematic sweep (see peer_runner `_step_teleport`).
	load("res://scripts/creatures/remote_creature.gd").teleport_body(player, at)
	player.velocity = Vector3.ZERO
	for f in int(args.get("settle", 45)):
		await tree.physics_frame
	var swimming: Node = player.get("swim_controller")
	var data := {"anchor_id": id, "on_floor": player.is_on_floor(), "swimming": bool(swimming.call("is_swimming")),
		"has_safe_landing": bool(swimming.get("state").has_safe_landing), "mode": int(swimming.get("state").mode)}
	var ok: bool = data.on_floor and not data.swimming and data.has_safe_landing
	return {"verdict": "PASS" if ok else "FAIL", "data": data,
		"detail": "SETUP: trainer stood on %s's dry landing at %s: %s" % [id, player.global_position, JSON.stringify(data)]}


static func _water_swim_to_wild(tree: SceneTree, args: Dictionary) -> Dictionary:
	var world := _water_scene(tree)
	var player := (tree.get("_probe") as Object).call("player") as CharacterBody3D
	var camera := (tree.get("_probe") as Object).call("camera_rig") as Node3D
	if world == null or player == null or camera == null:
		return {"verdict": "ERROR", "detail": "water_swim_to_wild needs the real Water scene, Player and camera"}
	var director := world.get_node_or_null(^"EncounterDirector")
	var arbiter := world.get_node_or_null(^"InteractionArbiter")
	var swimming: Node = player.get("swim_controller")
	var vitals: RefCounted = player.get("vitals")
	var site := str(args.get("site_id", ""))
	var wild: Node3D = null
	for f in 240:
		for member: Variant in (director.get("_site_members") as Dictionary).get(site, []):
			if member is Node3D and is_instance_valid(member) and bool((member as Node3D).call("is_alive")):
				wild = member
				break
		if wild != null:
			break
		await tree.physics_frame
	if wild == null:
		return {"verdict": "FAIL", "detail": "the production site loop spawned no live member of %s" % site}
	var start_stamina := -1.0
	var swim_frames := 0
	for frame in int(args.get("budget_frames", 2400)):
		if not is_instance_valid(wild):
			break
		var offset := wild.global_position - player.global_position
		offset.y = 0.0
		if bool(swimming.call("is_swimming")):
			if start_stamina < 0.0:
				start_stamina = float(vitals.stamina)
			swim_frames += 1
		if bool(swimming.call("is_swimming")) and swim_frames > 90 and director.call("_engageable") == wild \
				and arbiter.call("winning_provider") == director:
			tree.call("_drive_left", 0.0, 0.0)
			for f in 2:
				await tree.physics_frame
			var data := {"site_id": site, "species": str(wild.get("species_id")), "offered": true,
				"swim_frames": swim_frames, "stamina_start": start_stamina, "stamina": float(vitals.stamina),
				"stamina_spent": start_stamina - float(vitals.stamina), "mode": int(swimming.get("state").mode)}
			var ok: bool = data.mode == SWIM_HUMAN and float(data.stamina_spent) > 0.5
			return {"verdict": "PASS" if ok else "FAIL", "data": data,
				"detail": "swam by stick to %s's %s: %s" % [site, data.species, JSON.stringify(data)]}
		var direction := offset.normalized() if offset.length() > 2.0 else Vector3.ZERO
		var local: Vector3 = (camera.call("planar_basis") as Basis).inverse() * direction
		tree.call("_drive_left", local.x, local.z)
		await tree.physics_frame
	tree.call("_drive_left", 0.0, 0.0)
	return {"verdict": "FAIL", "detail": "never reached an Engage offer for %s: player=%s wild=%s swimming=%s" % [
		site, player.global_position, wild.global_position if is_instance_valid(wild) else Vector3.INF,
		str(swimming.call("is_swimming"))]}


## Baseline bookkeeping shared by the two aquatic views. `key` is the resource
## compared (stamina for the owner, stamina_fraction for a remote view).
static func _aquatic_compare(tree: SceneTree, scope: String, data: Dictionary, key: String,
		args: Dictionary) -> String:
	var store := _aquatic_baselines(tree)
	data["frame"] = Engine.get_physics_frames()
	if args.has("baseline"):
		var label := scope + ":" + str(args.baseline)
		if not store.has(label):
			return "no baseline '%s' recorded on this peer" % str(args.baseline)
		var base: Dictionary = store[label]
		var frames := int(data.frame) - int(base.frame)
		var delta := float(data[key]) - float(base[key])
		data["baseline"] = str(args.baseline)
		data["baseline_mode"] = int(base.mode)
		data["baseline_" + key] = float(base[key])
		data["frames_since"] = frames
		data[key + "_delta"] = delta
		data["stamina_unchanged"] = is_equal_approx(float(data[key]), float(base[key]))
		data["stamina_decreased"] = delta < -0.0001
		data["drain_per_s"] = -delta / (float(frames) / float(Engine.physics_ticks_per_second)) if frames > 0 else 0.0
		if data.has("health") and base.has("health"):
			data["health_unchanged"] = is_equal_approx(float(data.health), float(base.health))
		if frames < int(args.get("min_frames_since", 0)):
			return "only %d frames since baseline '%s' (need %d)" % [frames, str(args.baseline), int(args.min_frames_since)]
	if args.has("record"):
		store[scope + ":" + str(args.record)] = data.duplicate(true)
	return ""


static func _water_local_aquatic(tree: SceneTree, args: Dictionary) -> Dictionary:
	var world := _water_scene(tree)
	var player := (tree.get("_probe") as Object).call("player") as CharacterBody3D
	if world == null or player == null or player.get("swim_controller") == null:
		return {"verdict": "ERROR", "detail": "water_local_aquatic needs the real Water scene, Player and SwimController"}
	var state: RefCounted = (player.get("swim_controller") as Node).get("state")
	if args.has("wait_for_mode"):
		for f in int(args.get("budget_frames", 300)):
			if int(state.mode) == int(args.wait_for_mode):
				break
			await tree.physics_frame
	var vitals: RefCounted = player.get("vitals")
	var manager := world.get_node_or_null(^"CombatManager")
	var fighting := manager != null and bool(manager.call("is_fighting"))
	var active: Variant = manager.call("active_creature") if manager != null else null
	var enemy: Variant = manager.call("enemy") if fighting else null
	var data := {"mode": int(state.mode), "drowning": bool(state.drowning), "revision": int(state.revision),
		"stamina": float(vitals.stamina), "max_stamina": float(vitals.max_stamina),
		"stamina_fraction": float(state.stamina_fraction), "health": float(vitals.health),
		"fighting": fighting, "active_species": str((active as RefCounted).get("species_id")) if active != null else "",
		"enemy_species": str((enemy as RefCounted).get("species_id")) if enemy != null else "",
		"position": [player.global_position.x, player.global_position.y, player.global_position.z]}
	var problem := _aquatic_compare(tree, "local", data, "stamina", args)
	if data.has("drain_per_s"):
		var configured := float((JSON.parse_string(FileAccess.get_file_as_string(SWIM_CONFIG)) as Dictionary).human.stamina_drain_per_s)
		data["configured_drain_per_s"] = configured
		data["drain_matches_config"] = absf(float(data.drain_per_s) - configured) <= configured * 0.1
	return {"verdict": "FAIL" if not problem.is_empty() else "PASS", "data": data,
		"detail": (problem + "; " if not problem.is_empty() else "") + JSON.stringify(data)}


static func _remote_trainer_for(tree: SceneTree, pid: int) -> Node3D:
	for node: Node in tree.get_nodes_in_group("remote_trainer"):
		if node is Node3D and not node.is_multiplayer_authority() and int(node.get("peer_id")) == pid:
			return node as Node3D
	return null


## Read in one frame with no await: the snapshot the remote trainer received
## (`net_aquatic`) and the state it applied. `applied_matches_received` holds
## only when the applied revision IS the received one and every field agrees;
## a snapshot that arrived this frame and is applied on the next `_follow` is
## reported as `applied_revision` < `revision`, never as agreement. While the
## owner drains, a new revision arrives every owner frame, so the applied state
## trails by `applied_lag_revisions` (one or more: unrendered and rendered peers
## are not frame-locked); `applied_mode_matches_received` is the part of that
## agreement that does not depend on frame timing.
static func _remote_aquatic_view(body: Node3D, pid: int) -> Dictionary:
	var aquatic: RefCounted = body.get("aquatic")
	var applied: Dictionary = aquatic.call("snapshot")
	var received: Dictionary = body.get("net_aquatic")
	var applied_revision := int(aquatic.get("_received_revision"))
	return {"peer_id": pid, "found": true, "mode": int(applied.get("mode", -1)),
		"applied_revision": applied_revision,
		"resume_mode": int(applied.get("resume_mode", -1)), "drowning": bool(applied.get("drowning", false)),
		"stamina_fraction": float(applied.get("stamina_fraction", -1.0)),
		"owner_peer_id": int(applied.get("owner_peer_id", 0)),
		"revision": int(received.get("revision", -1)), "net_mode": int(received.get("mode", -1)),
		"net_stamina_fraction": float(received.get("stamina_fraction", -1.0)),
		"applied_matches_received": not received.is_empty() and applied_revision == int(received.get("revision", -2))
			and int(received.get("mode", -1)) == int(applied.get("mode", -2))
			and bool(received.get("drowning", false)) == bool(applied.get("drowning", true))
			and is_equal_approx(float(received.get("stamina_fraction", -1.0)), float(applied.get("stamina_fraction", -2.0))),
		"applied_mode_matches_received": not received.is_empty() and int(received.get("mode", -1)) == int(applied.get("mode", -2)),
		"applied_lag_revisions": int(received.get("revision", -1)) - applied_revision,
		"visible": body.visible,
		"position": [body.global_position.x, body.global_position.y, body.global_position.z]}


static func _water_remote_aquatic(tree: SceneTree, args: Dictionary) -> Dictionary:
	var pid := int(args.get("peer_id", 0))
	if pid <= 0:
		return {"verdict": "ERROR", "detail": "water_remote_aquatic needs args.peer_id (e.g. \"$peer1\")"}
	var body := _remote_trainer_for(tree, pid)
	if body == null:
		return {"verdict": "FAIL", "data": {"peer_id": pid, "found": false},
			"detail": "no remote trainer for peer %d on this peer" % pid}
	if args.has("wait_for_mode"):
		for f in int(args.get("budget_frames", 300)):
			if int((body.get("aquatic") as RefCounted).get("mode")) == int(args.wait_for_mode):
				break
			await tree.physics_frame
	var modes := {}
	var low := INF
	var high := -INF
	for f in int(args.get("sample_frames", 0)):
		await tree.physics_frame
		if not is_instance_valid(body):
			return {"verdict": "FAIL", "detail": "peer %d's remote trainer left mid-sample" % pid}
		var aquatic: RefCounted = body.get("aquatic")
		modes[int(aquatic.get("mode"))] = true
		low = minf(low, float(aquatic.get("stamina_fraction")))
		high = maxf(high, float(aquatic.get("stamina_fraction")))
	# Let the newest received snapshot be applied (the remote trainer applies
	# on its next `_follow`) before reading both sides in the same frame.
	for f in 10:
		if int((body.get("aquatic") as RefCounted).get("_received_revision")) \
				== int((body.get("net_aquatic") as Dictionary).get("revision", -2)):
			break
		await tree.physics_frame
	var data := _remote_aquatic_view(body, pid)
	if not modes.is_empty():
		var seen: Array = modes.keys()
		seen.sort()
		data["sample_frames"] = int(args.sample_frames)
		data["modes_seen"] = ",".join(seen.map(func(m: Variant) -> String: return str(m)))
		data["mode_steady"] = seen.size() == 1 and int(seen[0]) == int(data.mode)
		data["sample_stamina_range"] = high - low
	var problem := _aquatic_compare(tree, "remote%d" % pid, data, "stamina_fraction", args)
	return {"verdict": "FAIL" if not problem.is_empty() else "PASS", "data": data,
		"detail": (problem + "; " if not problem.is_empty() else "") + JSON.stringify(data)}


static func _water_win_wild(tree: SceneTree, args: Dictionary) -> Dictionary:
	var world := _water_scene(tree)
	var player := (tree.get("_probe") as Object).call("player") as CharacterBody3D
	var camera := (tree.get("_probe") as Object).call("camera_rig") as Node3D
	var manager := world.get_node_or_null(^"CombatManager") if world != null else null
	var director := world.get_node_or_null(^"EncounterDirector") if world != null else null
	if manager == null or director == null or player == null:
		return {"verdict": "ERROR", "detail": "water_win_wild needs the Water scene's CombatManager/EncounterDirector"}
	if not bool(manager.call("is_fighting")) or bool(director.call("trainer_battle_active")):
		return {"verdict": "FAIL", "detail": "no wild fight is running (fighting=%s trainer=%s)"
			% [str(manager.call("is_fighting")), str(director.call("trainer_battle_active"))]}
	var ceiling := float(args.get("enemy_hp_ceiling", 0.0))
	if ceiling <= 0.0:
		return {"verdict": "ERROR", "detail": "water_win_wild needs args.enemy_hp_ceiling > 0"}
	var state: RefCounted = (player.get("swim_controller") as Node).get("state")
	var foe: Node3D = manager.call("enemy_body")
	var foe_species := str(foe.get("species_id")) if foe != null else ""
	var budget := int(args.get("budget_frames", 3600))
	var frames := 0
	var swings := 0
	var capped := 0
	var paused_throughout := true
	while bool(manager.call("is_fighting")) and frames < budget:
		var enemy: Variant = manager.call("enemy")
		if enemy != null and float((enemy as RefCounted).get("hp")) > ceiling:
			(enemy as RefCounted).set("hp", ceiling) # disclosed hp ceiling allowance
			capped += 1
		var target: Node3D = manager.call("enemy_body")
		var ally: Node3D = director.call("ally_body")
		if is_instance_valid(target) and is_instance_valid(ally):
			var offset := target.global_position - ally.global_position
			offset.y = 0.0
			if offset.length() > float(manager.call("combat_move_reach", "quick")) * 0.8:
				var local: Vector3 = (camera.call("planar_basis") as Basis).inverse() * offset.normalized()
				tree.call("_drive_left", local.x, local.z)
			else:
				tree.call("_drive_left", 0.0, 0.0)
		if frames % 20 == 0:
			tree.call("_press_edge", "combat_quick", true)
			swings += 1
		elif frames % 20 == 2:
			tree.call("_press_edge", "combat_quick", false)
		if int(state.mode) != SWIM_PAUSED:
			paused_throughout = false
		frames += 1
		await tree.physics_frame
	tree.call("_press_edge", "combat_quick", false)
	tree.call("_drive_left", 0.0, 0.0)
	await tree.physics_frame
	var fainted := foe != null and is_instance_valid(foe) and not bool(foe.call("is_alive"))
	var data := {"enemy_species": foe_species, "fighting": bool(manager.call("is_fighting")), "enemy_fainted": fainted,
		"frames": frames, "swings": swings, "hp_capped_frames": capped, "enemy_hp_ceiling": ceiling,
		"paused_throughout": paused_throughout, "mode_after": int(state.mode)}
	var ok: bool = not data.fighting and fainted and paused_throughout
	return {"verdict": "PASS" if ok else "FAIL", "data": data,
		"detail": "wild %s: %s" % ["won" if ok else "NOT won", JSON.stringify(data)]}


## F14, peer that fights: take up Captain Nerissa's challenge at her real
## Veilfall spot through `begin_trainer_battle()` (what her prompt calls), with
## the Water director's own spec (Veilfall's defeat flag and requirements). The
## Veilfall chain up to her (VEILFALL_PREREQUISITES) is committed through the
## ledger first, as a stand-in for playing it. Win it with `win_trainer_battle`.
## `data.multi_peer` says whether anybody else was in the session at the time.
static func _nerissa_challenge(tree: SceneTree, args: Dictionary) -> Dictionary:
	var scene := tree.current_scene
	var director := scene.find_child("EncounterDirector", true, false) if scene != null else null
	var game := _game(tree)
	if director == null or game == null or not (director.get("trainer_specs") as Dictionary).has(NERISSA_ID):
		return {"verdict": "ERROR", "detail": "no EncounterDirector holding Nerissa's encounter in this scene"}
	var written: Array[String] = []
	for flag: String in VEILFALL_PREREQUISITES:
		if game.world.flags.has(flag):
			continue
		var verdict: Dictionary = STORY_LEDGER.set_world_flag(game, flag)
		if not (bool(verdict.get("ok", false)) or bool(verdict.get("pending", false))):
			return {"verdict": "FAIL", "detail": "%s refused: code='%s' reason='%s'"
				% [flag, str(verdict.get("code", "")), str(verdict.get("reason", ""))]}
		written.append(flag)
	for f in 30:
		await tree.physics_frame
	var spec: Dictionary = (director.get("trainer_specs") as Dictionary)[NERISSA_ID]
	var chapter := scene.find_child("WaterChapter", true, false)
	var veilfall := _veilfall(tree)
	var body: Node3D = null
	if chapter != null and veilfall != null:
		body = (chapter.get("npc_bodies") as Dictionary).get(
			str((veilfall.get("rules") as Dictionary).get("captain_npc_id", ""))) as Node3D
	if body == null:
		return {"verdict": "ERROR", "detail": "Nerissa's body is not placed in the Veilfall"}
	var at := body.global_position + Vector3(2.0, 0.0, 2.0)
	await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": int(args.get("settle", 120))})
	var multi := bool(game.call("is_multi_peer"))
	if not bool(director.call("can_challenge", spec)):
		return {"verdict": "FAIL", "detail": "Nerissa will not take the challenge (no usable ally: %s, too low: %s)"
			% [str(director.call("no_usable_ally")), str(director.call("too_low_to_challenge", spec))],
			"data": {"multi_peer": multi}}
	if not bool(director.call("begin_trainer_battle", spec, body)):
		return {"verdict": "FAIL", "detail": "begin_trainer_battle('%s') refused" % NERISSA_ID}
	for f in 45:
		await tree.physics_frame
	return {"verdict": "PASS", "detail": "prerequisites committed %s; challenged Nerissa (defeat flag '%s') with multi_peer=%s; %d creatures to come"
		% [str(written), str(spec.get("defeat_flag", "")), str(multi), int(director.call("trainer_creatures_left"))],
		"data": {"multi_peer": multi, "defeat_flag": str(spec.get("defeat_flag", ""))}}


## F14: stand beside the freed Guardian and send the very intent its invite
## prompt sends (past a hidden prompt), then wait for the HOST's refusal line.
## PASS only when the line contains `contains` (default: `begin()`'s
## `not_participant` reason) and this character got no claim, no offered
## marker and no Guardian.
static func _guardian_offer_refused(tree: SceneTree, args: Dictionary) -> Dictionary:
	var veilfall := _veilfall(tree)
	var game := _game(tree)
	if veilfall == null or game == null:
		return {"verdict": "ERROR", "detail": "no WaterVeilfall/Game on this peer"}
	var needle := str(args.get("contains", "Only those who fought Captain Nerissa"))
	var prompt := veilfall.get("_guardian_prompt") as Node3D
	var at := prompt.global_position + Vector3(0, -1.2, -1.6)
	await tree.call("_step_teleport", {"at": [at.x, at.y, at.z], "settle": 240})
	if game.has_method("take_pending_world_message"):
		game.call("take_pending_world_message")
	var result: Dictionary = (veilfall.get("_transport") as Object).call("submit", {"kind": "guardian_offer"})
	var message := str(result.get("reason", "")) if not bool(result.get("pending", false)) else ""
	for f in int(args.get("budget_frames", 600)):
		if message.contains(needle):
			break
		await tree.physics_frame
		var queued := str(game.get("_pending_world_message"))
		if queued.contains(needle):
			message = queued
		else:
			var shown := _label_containing(tree.root, needle)
			if not shown.is_empty():
				message = shown
	for f in 60:
		await tree.physics_frame
	var after := _guardian_view(tree)
	var data := {"ok": bool(result.get("ok", false)), "pending": bool(result.get("pending", false)),
		"code": str(result.get("code", "")), "message": message, "refused": message.contains(needle),
		"offered": bool(after.get("offered", false)),
		"pending_guardian_id": str(after.get("pending_guardian_id", "")),
		"guardians_owned": int(after.get("guardians_owned", 0))}
	var clean := not bool(data.offered) and str(data.pending_guardian_id).is_empty() and int(data.guardians_owned) == 0
	return {"verdict": "PASS" if bool(data.refused) and not bool(data.ok) and clean else "FAIL",
		"detail": "asked the host for an offer: ok=%s pending=%s code='%s' message '%s'; offered=%s claim='%s' Guardians %d"
			% [str(data.ok), str(data.pending), str(data.code), message, str(data.offered),
				str(data.pending_guardian_id), int(data.guardians_owned)],
		"data": data}
