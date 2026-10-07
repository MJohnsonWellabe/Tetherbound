extends RefCounted

## Immutable byte-identical copies of the actual production split save.
## Hashes attest bytes, not earned play. Only the continuous caller can earn a
## boundary. Segments accept only a complete, hash-linked production prefix.
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const COMMITS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const SPAWNS := preload("res://scripts/combat/spawn_tables.gd")
const BOUNDARIES := ["meadows_settled", "tidewake_settled", "cloudreach_settled", "stormwood_settled", "completed_world"]
const REALMS := ["meadows", "water", "cloudreach", "stormwood", "meadows"]
const MEADOWS_PIECES := ["opening_team", "camp_tournament", "bridge", "warrens", "relay", "hall"]
const MEADOWS_REALMS := ["meadows", "meadows", "meadows", "meadows", "meadows", "meadows"]
const MEADOWS_SLOT := 0
var tree: SceneTree
var game: Node
var base: String
var failures: Array[String] = []
var snapshots: Dictionary = {}
var source_commit := ""
var journey_id := ""
var history: Array = []
var boundaries: Array = BOUNDARIES.duplicate()
var realms: Array = REALMS.duplicate()
var save_slot := 0
var piece_prefix := false

func _init(owner: SceneTree, actual_game: Node, destination: String,
		ordered_boundaries: Array = [], ordered_realms: Array = [], slot: int = 0) -> void:
	tree = owner
	game = actual_game
	base = ProjectSettings.globalize_path(destination).simplify_path().trim_suffix("/")
	save_slot = slot
	if slot < 0 or slot >= SAVE.SLOT_COUNT:
		_fail("Handoff save slot is outside the production SaveSystem range")
	piece_prefix = not ordered_boundaries.is_empty()
	if piece_prefix:
		boundaries = ordered_boundaries.duplicate()
		realms = ordered_realms.duplicate()
		if save_slot != MEADOWS_SLOT or not ((boundaries == MEADOWS_PIECES and realms == MEADOWS_REALMS) \
			or (boundaries == MEADOWS_PIECES + BOUNDARIES and realms == MEADOWS_REALMS + REALMS)):
			_fail("Custom handoffs must preserve the six Meadows pieces, optionally followed by the authored chapters, in autosave slot 0")
	if boundaries.size() != realms.size() or (not piece_prefix and not ordered_realms.is_empty()):
		_fail("Handoff boundary and realm orders must match")
	var seen := {}
	for boundary: Variant in boundaries:
		if not boundary is String or str(boundary).is_empty() or seen.has(boundary) \
			or str(boundary).contains("/") or str(boundary).contains("\\") or boundary in [".", ".."]:
			_fail("Handoff boundary order requires unique directory names")
		seen[boundary] = true

func _fail(message: String) -> bool:
	failures.append(message)
	return false

func export_boundary(label: String, piece_proof: Dictionary = {}) -> bool:
	if not failures.is_empty(): return false
	var commit := COMMITS.commit_sha()
	var sha := RegEx.new()
	sha.compile("^[0-9a-f]{40}$")
	if sha.search(commit) == null: return _fail("F49 handoff requires an exact clean source commit (TB_COMMIT_SHA for exported builds)")
	if not source_commit.is_empty() and source_commit != commit: return _fail("F49 source identity changed between handoffs")
	source_commit = commit
	if boundaries.find(label) != history.size(): return _fail("F49 handoffs must be earned in declared order")
	var meadow_piece := piece_prefix and MEADOWS_PIECES.has(label)
	if meadow_piece and (piece_proof.get("passed") != true or piece_proof.get("segment") != label \
		or piece_proof.get("mode") != "new_order_meadows_piece"):
		return _fail("Meadows piece needs its actual passed helper proof and authored realm")
	if journey_id.is_empty(): journey_id = source_commit + ":" + base
	var destination := base.path_join(label)
	if DirAccess.dir_exists_absolute(destination) or FileAccess.file_exists(destination):
		return _fail("F49 immutable handoff already exists: " + destination)
	if not bool(game.call("save_game", save_slot)): return _fail("F49 production save refused at " + label)
	if not bool(game.save_system.call("finish_fallback")):
		return _fail("F49 production save fallback did not finish at " + label)
	if piece_prefix:
		# The original opening remains the identity anchor after Hall. Never
		# reset its journey/history when a later chapter gains its own receipt.
		# Check after the production save resolves its slot locator, before copy.
		var current := _state()
		var uids: Array = []
		var distinct := {}
		for member: Dictionary in current.party:
			uids.append(str(member.uid))
			distinct[str(member.uid)] = true
		if uids.size() != 5 or distinct.size() != 5 or uids.has("") \
			or current.realm != realms[history.size()] or OS.has_environment(SPAWNS.SEED_ENV_VAR) \
			or SPAWNS.resolve_seed(int(current.world_seed)) != int(current.world_seed):
			return _fail("Meadows-rooted handoff must retain five distinct UIDs, the authored realm and its saved population")
		for field: String in ["character_id", "world_id", "reward_delivery_namespace"]:
			if str(current.get(field, "")).is_empty(): return _fail("Meadows-rooted handoff has no stable " + field)
		if not history.is_empty():
			if not snapshots.has(MEADOWS_PIECES[0]): return _fail("Meadows-rooted handoff lost its original opening receipt")
			var original: Dictionary = snapshots[MEADOWS_PIECES[0]].state
			var original_uids: Array = []
			for member: Dictionary in original.party: original_uids.append(str(member.uid))
			if uids != original_uids: return _fail("Meadows-rooted chapter replaced or reordered the original five")
			for field: String in ["character_id", "world_id", "reward_delivery_namespace", "world_seed"]:
				if current.get(field) != original.get(field): return _fail("Meadows-rooted chapter changed its original " + field)
			if snapshots[MEADOWS_PIECES[0]].journey_id != journey_id:
				return _fail("Meadows-rooted chapter changed its original journey identity")
	# SaveSystem._dir is the actual installed scratch root, never a guessed
	# slot file. Include portable characters/worlds/locator and all other files.
	var source := ProjectSettings.globalize_path(str(game.save_system.get("_dir")))
	if source.is_empty() or not DirAccess.dir_exists_absolute(source):
		return _fail("F49 SaveSystem exposes no readable actual _dir")
	var hashes := _hash_tree(source)
	if hashes.is_empty(): return _fail("F49 actual production save contains no readable bytes")
	if not tree.copy_tree(source, destination.path_join("save")): return _fail("F49 handoff copy failed")
	if hashes != _hash_tree(source) or hashes != _hash_tree(destination.path_join("save")):
		return _fail("F49 save changed during the immutable disk handoff")
	var receipt := {"kind": "f49_ordinary_input_handoff", "boundary": label,
		"commit": source_commit, "realm": str(game.current_realm),
		"journey_id": journey_id, "predecessors": history.duplicate(true),
		"population_provenance": population_provenance(),
		"files_sha256": hashes, "state": _state(), "earned_claim": "continuous caller only; hashes do not prove play"}
	if meadow_piece:
		receipt.kind = "earned_meadows_piece"
		receipt.save_slot = save_slot
		receipt.piece_proof = piece_proof.duplicate(true)
		receipt.earned_claim = "one ordinary-input Meadows piece; production Load joins its complete earned prefix; hashes do not prove play"
	elif piece_prefix or save_slot != 0:
		receipt.save_slot = save_slot
		if piece_prefix:
			receipt.earned_claim = "ordinary-input chapter continuing the complete earned Meadows-piece prefix through production Load; hashes do not prove play"
	var output := FileAccess.open(destination.path_join("receipt.json"), FileAccess.WRITE)
	if output == null: return _fail("F49 immutable receipt write failed")
	# Receipt comparisons must retain the same exact numbers as the copied save.
	var encoded := DOCUMENT.stringify(receipt)
	if encoded.is_empty():
		output.close()
		return _fail("F49 immutable receipt contains unencodable values")
	output.store_string(encoded)
	output.close()
	snapshots[label] = receipt
	history.append({"boundary": label, "receipt_sha256": FileAccess.get_sha256(destination.path_join("receipt.json"))})
	print("F49 DISK HANDOFF " + JSON.stringify({"path": destination, "boundary": label, "commit": source_commit,
		"files_sha256": hashes, "population_provenance": receipt.population_provenance}))
	return true

## Validate the entire prefix before copying or installing a writable save.
## Exact source identity is conservative: a changed cut needs a fresh chain.
func import_prefix(source_boundary: String) -> String:
	if not failures.is_empty(): return ""
	if OS.has_environment(SPAWNS.SEED_ENV_VAR):
		_fail("F49 receiving process must retain the saved population without an environment seed override")
		return ""
	var source := ProjectSettings.globalize_path(source_boundary).simplify_path().trim_suffix("/")
	var label := source.get_file()
	var index := boundaries.find(label)
	if index < 0 or label == "completed_world":
		_fail("F49 resume requires an unfinished new-order chapter boundary")
		return ""
	var source_root := source.get_base_dir()
	if source_root == base or source_root.begins_with(base + "/") or base.begins_with(source_root + "/") \
		or DirAccess.dir_exists_absolute(base) or FileAccess.file_exists(base):
		_fail("F49 imported and writable handoff roots must be separate and output must be absent")
		return ""
	var commit := COMMITS.commit_sha()
	var sha := RegEx.new()
	sha.compile("^[0-9a-f]{40}$")
	if sha.search(commit) == null:
		_fail("F49 resume requires an exact clean source commit")
		return ""
	if not source_commit.is_empty() and source_commit != commit:
		_fail("F49 source identity changed before importing the earned prefix")
		return ""
	var identity: Array = []
	var retained: Dictionary = {}
	var chain: Array = []
	for step in index + 1:
		var boundary: String = boundaries[step]
		var meadow_piece := piece_prefix and MEADOWS_PIECES.has(boundary)
		var directory := source_root.path_join(boundary)
		var receipt_hash := FileAccess.get_sha256(directory.path_join("receipt.json"))
		var parsed: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(directory.path_join("receipt.json")))
		if not parsed is Dictionary or receipt_hash.is_empty() \
			or FileAccess.get_sha256(directory.path_join("receipt.json")) != receipt_hash:
			_fail("F49 resume has no readable exact receipt for " + boundary)
			return ""
		var receipt: Dictionary = parsed
		if not receipt.get("state") is Dictionary or not receipt.get("population_provenance") is Dictionary \
			or not receipt.get("files_sha256") is Dictionary or not receipt.get("predecessors") is Array \
			or not receipt.state.get("party") is Array:
			_fail("F49 resume receipt has malformed state, population, hashes or lineage at " + boundary)
			return ""
		var state: Dictionary = receipt.get("state", {})
		var uids: Array = []
		var distinct_uids := {}
		for member: Variant in state.party:
			if not member is Dictionary or str(member.get("uid", "")).is_empty():
				_fail("F49 resume receipt has no stable party identity at " + boundary)
				return ""
			uids.append(member.uid)
			distinct_uids[member.uid] = true
		var current_identity := [receipt.get("commit"), receipt.get("journey_id"), state.get("character_id"),
			state.get("world_id"), state.get("reward_delivery_namespace"), state.get("world_seed"), uids]
		if step == 0: identity = current_identity
		if receipt.get("kind") != ("earned_meadows_piece" if meadow_piece else "f49_ordinary_input_handoff") \
			or receipt.get("boundary") != boundary or receipt.get("save_slot", -1 if piece_prefix else 0) != save_slot \
			or receipt.get("commit") != commit or str(receipt.get("journey_id", "")).is_empty() \
			or receipt.get("realm") != realms[step] or state.get("realm") != realms[step] \
			or str(state.get("character_id", "")).is_empty() or str(state.get("world_id", "")).is_empty() \
			or str(state.get("reward_delivery_namespace", "")).is_empty() or current_identity != identity \
			or receipt.get("predecessors") != chain or state.get("party", []).is_empty() or state.get("party", []).size() > 5 \
			or receipt.get("files_sha256", {}).is_empty() \
			or _hash_tree(directory.path_join("save")) != receipt.get("files_sha256"):
			_fail("F49 resume rejected mismatched source, identity, order, lineage or save hashes at " + boundary)
			return ""
		if piece_prefix:
			if uids.size() != 5 or distinct_uids.size() != 5:
				_fail("Meadows-rooted prefix requires the original five distinct UIDs through every chapter")
				return ""
		if meadow_piece:
			var proof: Variant = receipt.get("piece_proof")
			if not proof is Dictionary or proof.get("passed") != true or proof.get("segment") != boundary \
				or proof.get("mode") != "new_order_meadows_piece":
				_fail("Meadows prefix requires passed pieces and the original five distinct UIDs")
				return ""
		var population: Dictionary = receipt.get("population_provenance", {})
		if population.get("saved_world_seed") != state.get("world_seed") \
			or population.get("effective_encounter_seed") != state.get("world_seed") \
			or population.get("has_environment_override") != false:
			_fail("F49 segmented prefix requires its original reproducible population without seed overrides")
			return ""
		# Read through the same slot/locator/split validators as production Load.
		# These APIs only read detached data; never load it onto Game to inspect it.
		var reader := SAVE.new(directory.path_join("save"))
		var flat: Dictionary = reader._read(save_slot)
		if not bool(SAVE.version_result(flat.get("version")).get("ok", false)):
			_fail("F49 prefix has an unreadable or incompatible production slot at " + boundary)
			return ""
		var split: Dictionary = reader._authoritative_split(save_slot, flat)
		if split.get("state") != "split" or split.get("world_id") != state.get("world_id") \
			or split.get("character_id") != state.get("character_id"):
			_fail("F49 prefix has invalid production split versions, schema or identity at " + boundary)
			return ""
		var validation_data := flat.duplicate()
		validation_data["world_id"] = str(split.world_id)
		if not SAVE._redesign_errors(validation_data, str(split.character_id)).is_empty():
			_fail("F49 prefix has invalid production slot schema at " + boundary)
			return ""
		retained[boundary] = receipt
		chain.append({"boundary": boundary, "receipt_sha256": receipt_hash})
	for step in index + 1:
		var boundary: String = boundaries[step]
		if not tree.copy_tree(source_root.path_join(boundary), base.path_join(boundary)):
			_fail("F49 resume immutable prefix copy failed at " + boundary)
			return ""
	# Recheck both complete trees after copying, including the original receipts.
	for step in index + 1:
		var boundary: String = boundaries[step]
		if _hash_tree(base.path_join(boundary + "/save")) != retained[boundary].files_sha256 \
			or _hash_tree(source_root.path_join(boundary + "/save")) != retained[boundary].files_sha256 \
			or FileAccess.get_sha256(base.path_join(boundary + "/receipt.json")) != chain[step].receipt_sha256 \
			or FileAccess.get_sha256(source_root.path_join(boundary + "/receipt.json")) != chain[step].receipt_sha256:
			_fail("F49 resume immutable prefix copy changed bytes at " + boundary)
			return ""
	snapshots = retained
	history = chain
	source_commit = commit
	journey_id = str(identity[1])
	print("F49 SEGMENT INPUT " + JSON.stringify({"path": source, "boundary": label,
		"commit": commit, "journey_id": journey_id, "predecessors": history}))
	return label

func population_provenance() -> Dictionary:
	# The capture override belongs to the encounter director, not save data.
	# Observe both identities; never rewrite Game/world seed to reconcile them.
	var saved := int(game.get("world_seed"))
	return {"saved_world_seed": saved, "effective_encounter_seed": SPAWNS.resolve_seed(saved),
		"has_environment_override": OS.has_environment(SPAWNS.SEED_ENV_VAR),
		"environment_override": OS.get_environment(SPAWNS.SEED_ENV_VAR)}

func _hash_tree(path: String, prefix: String = "") -> Dictionary:
	var out := {}
	var directory := DirAccess.open(path)
	if directory == null: return {}
	for filename: String in directory.get_files():
		var digest := FileAccess.get_sha256(path.path_join(filename))
		if digest.is_empty(): return {}
		out[prefix + filename] = digest
	for child: String in directory.get_directories():
		var child_hashes := _hash_tree(path.path_join(child), prefix + child + "/")
		if child_hashes.is_empty(): return {}
		out.merge(child_hashes)
	return out

func _state() -> Dictionary:
	var party := []
	for member: RefCounted in game.party.members():
		party.append({"uid": str(member.get("uid")), "species": str(member.get("species_id")),
			"nickname": str(member.get("nickname")), "level": int(member.get("level")), "xp": int(member.get("xp")),
			"hp": snappedf(float(member.get("hp")), 0.1), "fainted": bool(member.get("fainted"))})
	var flags: Array = game.progression.call("all_set").duplicate()
	flags.sort()
	var inventory := {}
	for slot: int in int(game.inventory.call("slot_count")):
		var stack: Dictionary = game.inventory.call("stack_at", slot)
		if not stack.is_empty(): inventory[str(slot)] = stack.duplicate(true)
	var context := HOME.journey_context(game)
	return {"party": party, "flags": flags, "inventory": inventory,
		"world_id": str(game.world.world_id), "reward_delivery_namespace": str(game.world.reward_delivery_namespace),
		"world_seed": int(game.get("world_seed")),
		"redesign_character": game.local.get("redesign_character").duplicate(true),
		"realm": str(game.current_realm), "character_id": HOME.character_id(game),
		"ending": {"outcome_id": context.get("outcome_id"), "home_return_receipt": context.get("home_return_receipt"),
			"homecoming_seen": context.get("homecoming_seen"), "regional_credits_seen": context.get("regional_credits_seen"),
			"starter_uid": context.get("starter_uid"), "chapter_choices": context.get("chapter_choices")}}

func reload_completed(travel: RefCounted) -> bool:
	return await reload_boundary("completed_world", travel, true)

func reload_boundary(label: String, travel: RefCounted, completed: bool = false) -> bool:
	if not failures.is_empty(): return false
	if not snapshots.has(label): return _fail("F49 has no earned " + label + " handoff")
	var receipt: Dictionary = snapshots[label]
	if receipt.get("save_slot", -1 if piece_prefix else 0) != save_slot: return _fail("F49 handoff save slot changed before Load")
	var source := base.path_join(label + "/save")
	if _hash_tree(source) != receipt.files_sha256: return _fail("F49 completed-world handoff digest changed")
	var destination := base + "_reload_" + label
	if DirAccess.dir_exists_absolute(destination) or FileAccess.file_exists(destination):
		return _fail("F49 reload scratch already exists")
	if not tree.copy_tree(source, destination): return _fail("F49 completed-world reload copy failed")
	if _hash_tree(destination) != receipt.files_sha256 or _hash_tree(source) != receipt.files_sha256:
		return _fail("F49 writable Load copy changed immutable save bytes")
	# Load the copy through production title controller navigation. This destroys
	# the outgoing world; the immutable handoff itself is never installed writable.
	game.set("save_system", SAVE.new(destination))
	if tree.change_scene_to_file("res://scenes/ui/title_screen.tscn") != OK:
		return _fail("F49 could not open production Load screen")
	for frame in 10: await tree.process_frame
	var title := tree.current_scene
	var load_button := title.get("_load_button") as Button
	for step in 8:
		if tree.root.gui_get_focus_owner() == load_button: break
		await travel.tap("ui_down")
	if tree.root.gui_get_focus_owner() != load_button: return _fail("F49 title controller focus did not reach Load Game")
	await travel.tap("ui_accept")
	var first := tree.root.gui_get_focus_owner() as Button
	if save_slot != 0:
		for step in SAVE.SLOT_COUNT + 2:
			if first != null and first.text.begins_with("Save %d —" % save_slot) and not first.disabled: break
			await travel.tap("ui_down")
			first = tree.root.gui_get_focus_owner() as Button
	var expected_label := "Save %d —" % save_slot if save_slot != 0 else "Autosave —"
	if first == null or not first.text.begins_with(expected_label) or first.disabled:
		return _fail("F49 copied completed save was refused by the actual title Load list")
	await travel.tap("ui_accept")
	for frame in 7200:
		await tree.process_frame
		if tree.current_scene != title and travel._ready_world(str(receipt.realm)):
			if _state() != receipt.state: return _fail("F49 party/rewards/ending changed when loading actual disk bytes")
			if _hash_tree(source) != receipt.files_sha256: return _fail("F49 reload modified its immutable input")
			return await travel.walk_continuation() if completed else true
	return _fail("F49 completed-world production Load did not become ready")
