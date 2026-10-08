extends RefCounted

## Immutable byte-identical copies of the actual production split save.
## Hashes attest bytes, not earned play. Only the continuous caller can earn a
## boundary. Segments accept only a complete, hash-linked production prefix.
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const COMMITS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const SPAWNS := preload("res://scripts/combat/spawn_tables.gd")
const STATE_DIFF := preload("res://scripts/net/owner_passive_sync.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const BOUNDARIES := ["meadows_settled", "tidewake_settled", "cloudreach_settled", "stormwood_settled", "completed_world"]
const REALMS := ["meadows", "water", "cloudreach", "stormwood", "meadows"]
const MEADOWS_PIECES := ["opening_team", "camp_tournament", "bridge", "warrens", "relay", "hall"]
const MEADOWS_REALMS := ["meadows", "meadows", "meadows", "meadows", "meadows", "meadows"]
const MEADOWS_PREPARED_PIECES := ["opening_team", "camp_tournament", "bridge", "warrens", "relay_prepared", "relay", "hall"]
const MEADOWS_PREPARED_REALMS := ["meadows", "meadows", "meadows", "meadows", "meadows", "meadows", "meadows"]
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
var compatibility_manifests: Dictionary = {}
var compatibility_files: Dictionary = {}
var compatibility_transition: Dictionary = {}

## Evidence only. Each immutable manifest authorizes one exact imported cut;
## supplying these never changes a save, receipt, schema or gameplay predicate.
func configure_compatibility(paths: Array[String]) -> bool:
	for path: String in paths:
		var absolute := ProjectSettings.globalize_path(path).simplify_path()
		var digest := FileAccess.get_sha256(absolute)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(absolute))
		if not parsed is Dictionary or not _hex(digest, 64) or compatibility_manifests.has(digest):
			return _fail("F49 compatibility requires distinct readable immutable manifests")
		var manifest: Dictionary = parsed
		if manifest.get("kind") != "f49_reviewed_cross_cut" or manifest.get("version") != 1 \
			or not _hex(manifest.get("consumer_commit"), 40) or not _hex(manifest.get("producer_commit"), 40) \
			or manifest.consumer_commit == manifest.producer_commit or not manifest.get("prefix") is Array \
			or manifest.prefix.is_empty() or not manifest.prefix[-1] is Dictionary \
			or manifest.get("imported_boundary") != manifest.prefix[-1].get("boundary") \
			or manifest.producer_commit != manifest.prefix[-1].get("producer_commit"):
			return _fail("F49 compatibility has malformed exact cut bindings")
		var review: Variant = manifest.get("review")
		if not review is Dictionary or review.get("verdict") != "compatible" \
			or not review.get("reviewer") is String or review.reviewer.strip_edges().is_empty() \
			or not review.get("record_url") is String or review.record_url.strip_edges().is_empty():
			return _fail("F49 compatibility requires an inline exact-cut reviewer verdict")
		for binding: Variant in manifest.prefix:
			if not binding is Dictionary or not binding.get("boundary") is String or binding.boundary.strip_edges().is_empty() \
				or not binding.get("log_path") is String or binding.log_path.strip_edges().is_empty() \
				or not _hex(binding.get("producer_commit"), 40) \
				or not _hex(binding.get("receipt_sha256"), 64) or not _hex(binding.get("log_sha256"), 64) \
				or not binding.get("files_sha256") is Dictionary or binding.files_sha256.is_empty():
				return _fail("F49 compatibility requires actual producer log/receipt/save bindings")
			var producer_kind: Variant = binding.get("producer_kind", "github_actions")
			if producer_kind == "native_process":
				var native: Variant = binding.get("native_process_receipt")
				if binding.has("run_id") or binding.has("artifact_id") or binding.has("artifact_sha256") \
					or not native is Dictionary or not native.get("path") is String or native.path.strip_edges().is_empty() \
					or not native.get("stderr_path") is String or native.stderr_path.strip_edges().is_empty() \
					or not _hex(native.get("sha256"), 64) or not _hex(native.get("stderr_sha256"), 64):
					return _fail("F49 native compatibility requires disjoint supervisor receipt and stderr byte bindings")
				var process_path := _evidence_path(absolute, str(native.path))
				var stderr_path := _evidence_path(absolute, str(native.stderr_path))
				if FileAccess.get_sha256(process_path) != native.sha256 or FileAccess.get_sha256(stderr_path) != native.stderr_sha256:
					return _fail("F49 native supervisor receipt or stderr digest changed or is missing")
				var process_receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(process_path))
				if not process_receipt is Dictionary or process_receipt.get("source") != binding.producer_commit \
					or typeof(process_receipt.get("exit_code")) not in [TYPE_INT, TYPE_FLOAT] or process_receipt.exit_code != 0 \
					or process_receipt.get("stop_reason") != "" \
					or typeof(process_receipt.get("pid")) not in [TYPE_INT, TYPE_FLOAT]:
					return _fail("F49 native producer did not finish successfully on its bound source")
				var pid: float = float(process_receipt.pid)
				if not is_finite(pid) or pid <= 0.0 or floorf(pid) != pid:
					return _fail("F49 native producer requires a positive integer process id")
				var utc := RegEx.new()
				utc.compile("^([0-9]{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])T(?:[01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9])(?:\\.([0-9]{1,9}))?Z$")
				var seconds: Array[int] = []
				var fractions: Array[int] = []
				for field: String in ["started_utc", "finished_utc"]:
					var stamp: Variant = process_receipt.get(field)
					if not stamp is String: return _fail("F49 native supervisor requires UTC start and finish timestamps")
					var match_utc := utc.search(stamp)
					if match_utc == null or match_utc.get_string(0) != stamp:
						return _fail("F49 native supervisor timestamp is not strict UTC")
					var epoch: int = Time.get_unix_time_from_datetime_string(match_utc.get_string(1))
					if Time.get_datetime_string_from_unix_time(epoch) != match_utc.get_string(1):
						return _fail("F49 native supervisor timestamp is not a valid calendar date")
					seconds.append(epoch)
					fractions.append(int(match_utc.get_string(2).rpad(9, "0")))
				if seconds[1] < seconds[0] or (seconds[1] == seconds[0] and fractions[1] <= fractions[0]):
					return _fail("F49 native supervisor finish must follow its start")
				for line: String in FileAccess.get_file_as_string(stderr_path).split("\n"):
					if line.begins_with("ERROR:") or line.begins_with("SCRIPT ERROR:") or line.begins_with("SCRIPTERROR:"):
						return _fail("F49 native compatibility cannot credit an engine-error producer")
			elif producer_kind == "github_actions":
				if binding.has("native_process_receipt") or not _hex(binding.get("artifact_sha256"), 64) \
					or not _decimal(binding.get("run_id")) or not _decimal(binding.get("artifact_id")):
					return _fail("F49 compatibility requires actual producer run/artifact/log/receipt/save bindings")
			else:
				return _fail("F49 compatibility has an unknown producer kind")
			for hash: Variant in binding.files_sha256.values():
				if not _hex(hash, 64): return _fail("F49 compatibility has an invalid save digest")
			if not _hex(binding.get("save_tree_sha256"), 64) or binding.save_tree_sha256 != _tree_digest(binding.files_sha256):
				return _fail("F49 compatibility complete save-tree digest changed or is missing")
			var log_path := _evidence_path(absolute, binding.log_path)
			if FileAccess.get_sha256(log_path) != binding.log_sha256:
				return _fail("F49 compatibility producer log digest changed or is missing")
			var matches := 0
			var results := 0
			for line: String in FileAccess.get_file_as_string(log_path).split("\n"):
				if line.begins_with("ERROR:") or line.begins_with("SCRIPT ERROR:"):
					return _fail("F49 compatibility cannot credit an engine-error producer")
				if producer_kind == "native_process":
					if line.begins_with("SCRIPTERROR:"): return _fail("F49 native compatibility cannot credit an engine-error producer")
					if line.begins_with("EARNED CHAIN RESULT "):
						var result: Variant = JSON.parse_string(line.trim_prefix("EARNED CHAIN RESULT "))
						if not result is Dictionary or result.get("segment") != binding.boundary \
							or result.get("passed") != true or result.get("failures") != []:
							return _fail("F49 native producer result is malformed, failed or for another boundary")
						results += 1
				if not line.begins_with("F49 DISK HANDOFF "): continue
				var row: Variant = JSON.parse_string(line.trim_prefix("F49 DISK HANDOFF "))
				if not row is Dictionary: return _fail("F49 compatibility has a malformed producer handoff")
				if row.get("boundary") == binding.boundary:
					if row.get("commit") != binding.producer_commit or row.get("files_sha256") != binding.files_sha256:
						return _fail("F49 compatibility producer log does not bind the actual saved cut")
					matches += 1
			if matches != 1: return _fail("F49 compatibility needs one actual producer handoff in its log")
			if producer_kind == "native_process" and results != 1:
				return _fail("F49 native compatibility needs exactly one passed earned-chain result in its stdout")
		compatibility_manifests[digest] = manifest
		compatibility_files[digest] = absolute
	return true

static func _hex(value: Variant, length: int) -> bool:
	if not value is String: return false
	var expression := RegEx.new()
	expression.compile("^[0-9a-f]{%d}$" % length)
	return expression.search(value) != null

static func _decimal(value: Variant) -> bool:
	if not value is String: return false
	var expression := RegEx.new()
	expression.compile("^[1-9][0-9]*$")
	return expression.search(value) != null

## Canonical digest of the complete path-to-byte-hash map, independent of JSON
## spacing or key order. Paths containing separators in this format are refused.
static func _tree_digest(files: Dictionary) -> String:
	var keys := files.keys()
	keys.sort()
	var lines := ""
	for key: Variant in keys:
		if not key is String or key.contains("\t") or key.contains("\n") or key.contains("\r"): return ""
		lines += key + "\t" + str(files[key]) + "\n"
	return lines.sha256_text()

static func _evidence_path(manifest_path: String, path: String) -> String:
	return path if path.is_absolute_path() else manifest_path.get_base_dir().path_join(path).simplify_path()

func _reviewed_cut(root: String, prefix: Array, consumer: String, required_digest: String = "") -> String:
	if prefix.is_empty(): return ""
	var last: Dictionary = prefix[-1]
	var last_receipt: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(root.path_join(str(last.boundary) + "/receipt.json")))
	if not last_receipt is Dictionary: return ""
	for digest: String in compatibility_manifests:
		if not required_digest.is_empty() and digest != required_digest: continue
		var manifest: Dictionary = compatibility_manifests[digest]
		if FileAccess.get_sha256(compatibility_files[digest]) != digest \
			or manifest.consumer_commit != consumer or manifest.producer_commit != last_receipt.get("commit") \
			or manifest.imported_boundary != last.boundary or manifest.prefix.size() != prefix.size(): continue
		var valid := true
		for index in prefix.size():
			var original: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(root.path_join(str(prefix[index].boundary) + "/receipt.json")))
			var binding: Dictionary = manifest.prefix[index]
			if not original is Dictionary or binding.boundary != prefix[index].boundary \
				or binding.receipt_sha256 != prefix[index].receipt_sha256 or binding.producer_commit != original.get("commit") \
				or binding.files_sha256 != original.get("files_sha256") \
				or FileAccess.get_sha256(root.path_join(str(binding.boundary) + "/receipt.json")) != binding.receipt_sha256 \
				or _hash_tree(root.path_join(str(binding.boundary) + "/save")) != binding.files_sha256:
				valid = false
		if valid: return digest
	return ""

func _recheck_compatibility() -> bool:
	var paths: Array[String] = []
	for digest: String in compatibility_files:
		if FileAccess.get_sha256(compatibility_files[digest]) != digest:
			return _fail("F49 compatibility manifest changed after validation")
		paths.append(compatibility_files[digest])
	compatibility_manifests.clear()
	compatibility_files.clear()
	if not configure_compatibility(paths): return false
	for index in history.size():
		var row: Dictionary = history[index]
		var original: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(base.path_join(str(row.boundary) + "/receipt.json")))
		if not original is Dictionary or FileAccess.get_sha256(base.path_join(str(row.boundary) + "/receipt.json")) != row.receipt_sha256 \
			or _hash_tree(base.path_join(str(row.boundary) + "/save")) != original.get("files_sha256"):
			return _fail("F49 retained prefix bytes changed before reviewed continuation")
		if index == 0: continue
		var previous: Dictionary = snapshots[history[index - 1].boundary]
		if previous.commit != original.commit:
			var transition: Variant = original.get("compatibility_transition")
			if not transition is Dictionary or not _hex(transition.get("manifest_sha256"), 64) \
				or transition.get("consumer_commit") != original.commit or transition.get("producer_commit") != previous.commit \
				or transition.get("imported_boundary") != history[index - 1].boundary \
				or _reviewed_cut(base, history.slice(0, index), str(original.commit), transition.manifest_sha256).is_empty():
				return _fail("F49 retained cut no longer matches its reviewed prefix")
	return true

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
			or (boundaries == MEADOWS_PIECES + BOUNDARIES and realms == MEADOWS_REALMS + REALMS) \
			or (boundaries == MEADOWS_PREPARED_PIECES and realms == MEADOWS_PREPARED_REALMS) \
			or (boundaries == MEADOWS_PREPARED_PIECES + BOUNDARIES and realms == MEADOWS_PREPARED_REALMS + REALMS)):
			_fail("Custom handoffs must preserve the Meadows pieces with only the optional pre-Captain preparation cut, then authored chapters, in autosave slot 0")
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
	if not _recheck_compatibility(): return false
	if not compatibility_transition.is_empty() and _reviewed_cut(base, history, commit, compatibility_transition.manifest_sha256).is_empty():
		return _fail("F49 reviewed imported cut changed before export")
	source_commit = commit
	if boundaries.find(label) != history.size(): return _fail("F49 handoffs must be earned in declared order")
	var meadow_piece := piece_prefix and MEADOWS_PREPARED_PIECES.has(label)
	if meadow_piece and (piece_proof.get("passed") != true or piece_proof.get("segment") != label \
		or piece_proof.get("mode") != "new_order_meadows_piece"):
		return _fail("Meadows piece needs its actual passed helper proof and authored realm")
	if label == "relay_prepared" and not _relay_preparation_proof(piece_proof):
		return _fail("Relay preparation requires its completed real Riverwatch recovery and safe-join receipts")
	if journey_id.is_empty(): journey_id = source_commit + ":" + base
	var destination := base.path_join(label)
	if DirAccess.dir_exists_absolute(destination) or FileAccess.file_exists(destination):
		return _fail("F49 immutable handoff already exists: " + destination)
	if not bool(game.call("save_game", save_slot)): return _fail("F49 production save refused at " + label)
	if not bool(game.save_system.call("finish_fallback")):
		return _fail("F49 production save fallback did not finish at " + label)
	if piece_prefix or not compatibility_manifests.is_empty():
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
			if not snapshots.has(boundaries[0]): return _fail("Reviewed handoff lost its original identity receipt")
			var original: Dictionary = snapshots[boundaries[0]].state
			var original_uids: Array = []
			for member: Dictionary in original.party: original_uids.append(str(member.uid))
			if uids != original_uids: return _fail("Meadows-rooted chapter replaced or reordered the original five")
			for field: String in ["character_id", "world_id", "reward_delivery_namespace", "world_seed"]:
				if current.get(field) != original.get(field): return _fail("Meadows-rooted chapter changed its original " + field)
			if snapshots[boundaries[0]].journey_id != journey_id:
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
	if not compatibility_transition.is_empty(): receipt.compatibility_transition = compatibility_transition.duplicate(true)
	if meadow_piece:
		receipt.kind = "earned_meadows_piece"
		receipt.save_slot = save_slot
		receipt.piece_proof = piece_proof.duplicate(true)
		receipt.earned_claim = "one ordinary-input Meadows piece; production Load joins its complete earned prefix; hashes do not prove play"
	elif piece_prefix or save_slot != 0:
		receipt.save_slot = save_slot
		if piece_prefix:
			receipt.earned_claim = "ordinary-input chapter continuing the complete earned Meadows-piece prefix through production Load; hashes do not prove play"
	if not piece_prefix and not compatibility_manifests.is_empty():
		receipt.earned_claim = "ordinary-input chapter continuing its complete reviewed earned prefix through production Load; hashes do not prove play"
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
	compatibility_transition.clear()
	history.append({"boundary": label, "receipt_sha256": FileAccess.get_sha256(destination.path_join("receipt.json"))})
	print("F49 DISK HANDOFF " + JSON.stringify({"path": destination, "boundary": label, "commit": source_commit,
		"files_sha256": hashes, "population_provenance": receipt.population_provenance}))
	return true

## Validate the entire prefix before copying or installing a writable save.
## Default source identity is strict. Explicit reviewed manifests authorize only
## the exact transition and preserve every original receipt and predecessor hash.
func import_prefix(source_boundary: String) -> String:
	if not failures.is_empty(): return ""
	if OS.has_environment(SPAWNS.SEED_ENV_VAR):
		_fail("F49 receiving process must retain the saved population without an environment seed override")
		return ""
	var source := ProjectSettings.globalize_path(source_boundary).simplify_path().trim_suffix("/")
	var label := source.get_file()
	# Detect only the explicit optional cut in the requested receipt's lineage.
	# The unchanged strict loop below still validates every ordered receipt,
	# original identity and byte hash; presence alone never accepts a boundary.
	if piece_prefix and not boundaries.has("relay_prepared"):
		var terminal: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(source.path_join("receipt.json")))
		var prepared := label == "relay_prepared"
		if terminal is Dictionary and terminal.get("predecessors") is Array:
			for predecessor: Variant in terminal.predecessors:
				if predecessor is Dictionary and predecessor.get("boundary") == "relay_prepared": prepared = true
		if prepared:
			boundaries.insert(4, "relay_prepared")
			realms.insert(4, "meadows")
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
	if not _recheck_compatibility(): return ""
	var identity: Array = []
	var retained: Dictionary = {}
	var chain: Array = []
	for step in index + 1:
		var boundary: String = boundaries[step]
		var meadow_piece := piece_prefix and MEADOWS_PREPARED_PIECES.has(boundary)
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
			if not member is Dictionary or not member.get("uid") is String or member.uid.is_empty():
				_fail("F49 resume receipt has no stable party identity at " + boundary)
				return ""
			uids.append(member.uid)
			distinct_uids[member.uid] = true
		var current_identity := [receipt.get("journey_id"), state.get("character_id"),
			state.get("world_id"), state.get("reward_delivery_namespace"), state.get("world_seed"), uids]
		if step == 0: identity = current_identity
		if receipt.get("kind") != ("earned_meadows_piece" if meadow_piece else "f49_ordinary_input_handoff") \
			or receipt.get("boundary") != boundary or receipt.get("save_slot", -1 if piece_prefix else 0) != save_slot \
			or not _hex(receipt.get("commit"), 40) or (compatibility_manifests.is_empty() and receipt.get("commit") != commit) \
			or not receipt.get("journey_id") is String or receipt.journey_id.is_empty() \
			or receipt.get("realm") != realms[step] or state.get("realm") != realms[step] \
			or not state.get("character_id") is String or state.character_id.is_empty() \
			or not state.get("world_id") is String or state.world_id.is_empty() \
			or not state.get("reward_delivery_namespace") is String or state.reward_delivery_namespace.is_empty() \
			or current_identity != identity \
			or receipt.get("predecessors") != chain or state.get("party", []).is_empty() or state.get("party", []).size() > 5 \
			or receipt.get("files_sha256", {}).is_empty() \
			or _hash_tree(directory.path_join("save")) != receipt.get("files_sha256"):
			_fail("F49 resume rejected mismatched source, identity, order, lineage or save hashes at " + boundary)
			return ""
		var transition: Variant = receipt.get("compatibility_transition", {})
		var changed_cut: bool = step > 0 and retained[boundaries[step - 1]].commit != receipt.commit
		if changed_cut or not transition is Dictionary or not transition.is_empty():
			if not changed_cut or not transition is Dictionary \
				or transition.get("consumer_commit") != receipt.commit \
				or transition.get("producer_commit") != retained[boundaries[step - 1]].commit \
				or transition.get("imported_boundary") != boundaries[step - 1] \
				or not _hex(transition.get("manifest_sha256"), 64) \
				or _reviewed_cut(source_root, chain, str(receipt.commit), str(transition.manifest_sha256)).is_empty():
				_fail("F49 prefix cut transition lacks its exact reviewed manifest")
				return ""
		if piece_prefix or not compatibility_manifests.is_empty():
			if uids.size() != 5 or distinct_uids.size() != 5:
				_fail("Reviewed or Meadows-rooted prefix requires the original five distinct UIDs through every chapter")
				return ""
		if meadow_piece:
			var proof: Variant = receipt.get("piece_proof")
			if not proof is Dictionary or proof.get("passed") != true or proof.get("segment") != boundary \
				or proof.get("mode") != "new_order_meadows_piece":
				_fail("Meadows prefix requires passed pieces and the original five distinct UIDs")
				return ""
			if boundary == "relay_prepared" and not _relay_preparation_proof(proof):
				_fail("Relay preparation prefix lacks its actual recovery and safe-join witness")
				return ""
		var population: Dictionary = receipt.get("population_provenance", {})
		if population.get("saved_world_seed") != state.get("world_seed") \
			or population.get("effective_encounter_seed") != state.get("world_seed") \
			or population.get("has_environment_override") != false \
			or (not compatibility_manifests.is_empty() and population.get("environment_override") != ""):
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
	if retained[label].commit != commit:
		var digest := _reviewed_cut(source_root, chain, commit)
		if digest.is_empty():
			_fail("F49 imported producer cut has no exact reviewed consumer binding")
			return ""
		compatibility_transition = {"manifest_sha256": digest, "imported_boundary": label,
			"producer_commit": retained[label].commit, "consumer_commit": commit}
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
	journey_id = str(identity[0])
	print("F49 SEGMENT INPUT " + JSON.stringify({"path": source, "boundary": label,
		"commit": commit, "journey_id": journey_id, "predecessors": history,
		"compatibility_transition": compatibility_transition}))
	return label

func _relay_preparation_proof(proof: Dictionary) -> bool:
	var recovery := false
	var joined := false
	var helpers: Variant = proof.get("helper_receipts", [])
	if not helpers is Array: return false
	for helper: Variant in helpers:
		if not helper is Dictionary or helper.get("segment") != "relay_prepared" or helper.get("passed") != true: continue
		var beats: Variant = helper.get("receipts", [])
		if not beats is Array: return false
		for beat: Variant in beats:
			if not beat is Dictionary: continue
			if beat.get("beat") == "pre_relay_riverwatch_recovery" \
					and beat.get("inventory_unchanged") == true and beat.get("xp_caps_unchanged") == true:
				recovery = true
			if recovery and beat.get("beat") == "relay_prepared" and beat.get("safe_join") == true:
				joined = true
	return recovery and joined


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
	# Observe the same detached serialization boundary as the production save.
	# The live party owns move knowledge; the redesign record is its saved mirror.
	var serialized: Array = SAVE.new()._party_to_array(game.party)
	var redesign: Dictionary = game.local.get("redesign_character").duplicate(true)
	if TEACHING.party_loadout_errors(serialized, redesign).is_empty():
		redesign = TEACHING.character_loadout_mirror(serialized, redesign)
	var party := []
	for member: Dictionary in serialized:
		var observed := {"uid": member.uid, "species": member.species_id,
			"nickname": member.nickname, "level": member.level, "xp": member.xp,
			"hp": snappedf(float(member.hp), 0.1), "fainted": member.fainted}
		# Retain the raw carriers too: projection must not hide lost knowledge,
		# equipped moves, mastery uses/receipts, or the edit revision and identity.
		for field: String in ["known_moves", "move_quick", "move_charged", "move_utility", "move_ultimate",
			"move_mastery_uses", "move_mastery_receipts", "loadout_revision", "loadout_last_edit"]:
			if member.has(field): observed[field] = member[field]
		party.append(observed)
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
		"redesign_character": redesign,
		"realm": str(game.current_realm), "character_id": HOME.character_id(game),
		"ending": {"outcome_id": context.get("outcome_id"), "home_return_receipt": context.get("home_return_receipt"),
			"homecoming_seen": context.get("homecoming_seen"), "regional_credits_seen": context.get("regional_credits_seen"),
			"starter_uid": context.get("starter_uid"), "chapter_choices": context.get("chapter_choices")}}

func reload_completed(travel: RefCounted) -> bool:
	return await reload_boundary("completed_world", travel, true)

func reload_boundary(label: String, travel: RefCounted, completed: bool = false) -> bool:
	if not failures.is_empty(): return false
	if source_commit.is_empty() or COMMITS.commit_sha() != source_commit:
		return _fail("F49 clean consumer source changed before installing the actual prefix")
	if not _recheck_compatibility(): return false
	if not snapshots.has(label): return _fail("F49 has no earned " + label + " handoff")
	var receipt: Dictionary = snapshots[label]
	if receipt.commit != source_commit and (compatibility_transition.get("imported_boundary") != label \
		or compatibility_transition.get("producer_commit") != receipt.commit \
		or compatibility_transition.get("consumer_commit") != source_commit \
		or not _hex(compatibility_transition.get("manifest_sha256"), 64) \
		or _reviewed_cut(base, history, source_commit, compatibility_transition.manifest_sha256).is_empty()):
		return _fail("F49 actual Load no longer binds its reviewed producer and consumer cuts")
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
			var observed := _state()
			if observed != receipt.state:
				var paths: Array = STATE_DIFF._differing_paths("", receipt.state, observed, 0, [])
				if paths.is_empty(): paths.append("") # Retain exact values if only Variant types differ.
				var differences: Array = []
				for path: String in paths:
					var pair: Array = [receipt.state, observed]
					for side: int in 2:
						for key: String in path.replace("[", "/").replace("]", "").split("/", false):
							if pair[side] is Dictionary: pair[side] = pair[side].get(key)
							elif pair[side] is Array and key.is_valid_int() and int(key) >= 0 and int(key) < pair[side].size():
								pair[side] = pair[side][int(key)]
							else: pair[side] = null
					differences.append({"path": path, "expected": pair[0], "actual": pair[1],
						"expected_type": typeof(pair[0]), "actual_type": typeof(pair[1])})
				# One failure-only record; the production codec preserves exact floats.
				print("F49 LOAD STATE MISMATCH " + DOCUMENT.stringify({"boundary": label, "frame": frame,
					"differences": differences, "path_limit": 16}))
				return _fail("F49 party/rewards/ending changed when loading actual disk bytes")
			if _hash_tree(source) != receipt.files_sha256: return _fail("F49 reload modified its immutable input")
			return await travel.walk_continuation() if completed else true
	return _fail("F49 completed-world production Load did not become ready")
