extends RefCounted

## Immutable byte-identical copies of the actual production split save.
## Hashes attest bytes, not earned play. Only the continuous caller can earn a
## boundary. No supplied fixture/resume is accepted by F49's campaign driver.
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const COMMITS := preload("res://tests/helpers/four_biome_checkpoints.gd")
var tree: SceneTree
var game: Node
var base: String
var failures: Array[String] = []
var snapshots: Dictionary = {}
var source_commit := ""

func _init(owner: SceneTree, actual_game: Node, destination: String) -> void:
	tree = owner
	game = actual_game
	base = ProjectSettings.globalize_path(destination)

func _fail(message: String) -> bool:
	failures.append(message)
	return false

func export_boundary(label: String) -> bool:
	var commit := COMMITS.commit_sha()
	var sha := RegEx.new()
	sha.compile("^[0-9a-f]{40}$")
	if sha.search(commit) == null: return _fail("F49 handoff requires an exact clean source commit (TB_COMMIT_SHA for exported builds)")
	if not source_commit.is_empty() and source_commit != commit: return _fail("F49 source identity changed between handoffs")
	source_commit = commit
	var destination := base.path_join(label)
	if DirAccess.dir_exists_absolute(destination): return _fail("F49 immutable handoff already exists: " + destination)
	if not bool(game.call("save_game", 0)): return _fail("F49 production save refused at " + label)
	if not bool(game.save_system.call("finish_fallback")):
		return _fail("F49 production save fallback did not finish at " + label)
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
		"files_sha256": hashes, "state": _state(), "earned_claim": "continuous caller only; hashes do not prove play"}
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
	print("F49 DISK HANDOFF " + JSON.stringify({"path": destination, "boundary": label, "commit": source_commit, "files_sha256": hashes}))
	return true

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
		"redesign_character": game.local.get("redesign_character").duplicate(true),
		"realm": str(game.current_realm), "character_id": HOME.character_id(game),
		"ending": {"outcome_id": context.get("outcome_id"), "home_return_receipt": context.get("home_return_receipt"),
			"homecoming_seen": context.get("homecoming_seen"), "regional_credits_seen": context.get("regional_credits_seen"),
			"starter_uid": context.get("starter_uid"), "chapter_choices": context.get("chapter_choices")}}

func reload_completed(travel: RefCounted) -> bool:
	return await reload_boundary("completed_world", travel, true)

func reload_boundary(label: String, travel: RefCounted, completed: bool = false) -> bool:
	if not snapshots.has(label): return _fail("F49 has no earned " + label + " handoff")
	var receipt: Dictionary = snapshots[label]
	var source := base.path_join(label + "/save")
	if _hash_tree(source) != receipt.files_sha256: return _fail("F49 completed-world handoff digest changed")
	var destination := base + "_reload_" + label
	if DirAccess.dir_exists_absolute(destination): return _fail("F49 reload scratch already exists")
	if not tree.copy_tree(source, destination): return _fail("F49 completed-world reload copy failed")
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
	if first == null or not first.text.begins_with("Save 0") or first.disabled:
		return _fail("F49 copied completed save was refused by the actual title Load list")
	await travel.tap("ui_accept")
	for frame in 7200:
		await tree.process_frame
		if tree.current_scene != title and travel._ready_world(str(receipt.realm)):
			if _state() != receipt.state: return _fail("F49 party/rewards/ending changed when loading actual disk bytes")
			if _hash_tree(source) != receipt.files_sha256: return _fail("F49 reload modified its immutable input")
			return await travel.walk_continuation() if completed else true
	return _fail("F49 completed-world production Load did not become ready")
