extends RefCounted

## Read-only F48 witnesses and ordinary input. Never saves during observation:
## an observation must not repair a missing durable write before asserting it.
## All receipt records below are read from production files, never constructed.
const UIDS := preload("res://scripts/data/redesign_state.gd")
const ATOMIC := preload("res://scripts/save/atomic_save_file.gd")
const DETACHED := preload("res://tools/net/f48_detached_file.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const RECORD_RULES := preload("res://scripts/net/character_record_rules.gd")
const COMMIT_TRACE := preload("res://scripts/net/altar_commit_trace.gd")
const PASSIVE := preload("res://tools/net/f48_passive_witness.gd")
const PORTAL_DELIVERY := preload("res://scripts/net/portal_delivery.gd")
const PROOF_FILES := preload("res://tools/net/proof_steps.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SAVE_DOCUMENT := preload("res://scripts/save/save_document.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")

class ButtonActivationObservation extends RefCounted:
	var count: int = 0
	func note_pressed() -> void:
		count += 1

static func step(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	if action == "f48_diagnostic":
		var diagnostic: Script = load("res://tools/net/f48_diagnostic_steps.gd") as Script
		if diagnostic == null: return _result(false,"Diagnostic tools script unavailable")
		return await diagnostic.call("run",tree,args)
	match action:
		"f48_witness": return await _witness(tree, args)
		"f48_assert": return await _sealed_reply(tree, action, args, _assert(tree, args))
		"f48_assert_snapshot": return await _sealed_reply(tree, action, args, _assert_snapshot(tree))
		"f48_watch_owner_saves":
			tree.set_meta("f48_producer_observation", true)
			return _result(_watch_owner_saves(tree), "Read-only producer actual owner BOOL-save observer")
		"f48_capture_durable": return _capture_durable(tree, args)
		"f48_measure_layout": return _measure_layout(tree, args)
		"f48_fixture_trainer_fight": return await _fixture_trainer_fight(tree, args)
		"f48_fixture_approach": return await _fixture_approach(tree, args)
		"f48_deploy_owned": return await _deploy_owned(tree)
		"f48_dialogue": return await _dialogue(tree, args)
		"f48_fixture_join_boss": return await _fixture_join_boss(tree, args)
		"f48_fixture_capture":
			var captured: Dictionary = await tree.call("_step_f48_fixture_capture", args)
			var data: Dictionary = captured.get("data", {})
			if data.get("owner_training_row") is Dictionary and data.has("owner_projection"):
				data["owner_before_difference"] = _json_difference(data.owner_training_row.get("before"), data.owner_projection)
				data["owner_after_difference"] = _json_difference(data.owner_training_row.get("after"), data.owner_projection)
			if captured.get("verdict") == "PASS" and args.get("role") == "guest":
				var presentation: Dictionary = await _finish_capture_presentation(tree, int(data.get("capture_started_physics_frame", -1)))
				data["presentation_exit"] = presentation.get("data", {})
				captured["data"] = data
				if presentation.get("verdict") != "PASS":
					captured["verdict"] = "FAIL"
					captured["detail"] = str(captured.get("detail", "")) + " " + str(presentation.get("detail", ""))
			return await _sealed_reply(tree, action, args, captured)
		"f48_button": return await _button(tree, args)
		"f48_choice": return await _choice(tree, args)
		"f48_build_cell": return await _build_cell(tree, args)
		"f48_watch_altar_save": return _watch_altar_save(tree)
		"f48_assert_altar_build": return await _sealed_reply(tree, action, args, _assert_altar_build(tree, args))
		"f48_require_configuration": return _require_configuration(args)
		"f48_require": return _require(tree, args)
		"f48_restore_witness": return _restore_witness(tree, args)
		"f48_participants": return await _participants(tree, args)
		"f48_watch_portal": return _watch_portal(tree)
		"f48_arm_boundary": return _arm_boundary(tree, args)
		"f48_start_case": return _start_case(tree, args)
	return _result(false, "Unknown F48 action: " + action)

static func _start_case(tree: SceneTree, args: Dictionary) -> Dictionary:
	PASSIVE.stop(tree)
	var case_id := str(args.get("case", ""))
	if case_id.is_empty() or case_id != case_id.validate_filename(): return _result(false, "Invalid independent matrix case identity")
	var game := tree.root.get_node_or_null(^"Game")
	if game == null or game.session == null or game.session.call("is_active"):
		return _result(false, "Original saved inputs can be restored only outside a session")
	var topup: Node = tree.root.get_node_or_null(^"F48ActorTopup")
	if topup != null:
		if topup.get_script() == null or topup.get_script().resource_path != "res://tools/net/f48_actor_topup.gd" \
			or topup.call("unresolved") != false:
			return _result(false, "The original disclosed topup still requires its actual save/ACK")
		tree.root.remove_child(topup)
		topup.queue_free()
	var observer: Variant = tree.get_meta("f48_boundary_armed", null)
	var writer := tree.root.get_node_or_null(^"Game/Session/LedgerRpc")
	if observer is Callable and writer != null and writer.is_connected("transaction_boundary", observer):
		writer.disconnect("transaction_boundary", observer)
	for key: StringName in tree.get_meta_list():
		if str(key).begins_with("f48_witness_") or str(key) in ["f48_witnesses", "f48_boundary_armed", "f48_boundary_fired", "f48_boss_encounter"]:
			tree.remove_meta(key)
	tree.set_meta("f48_portal_results", [])
	if not tree.has_meta("f48_matrix_output_base"):
		tree.set_meta("f48_matrix_output_base", OS.get_environment("TB_PROOF_OUT"))
	var base := str(tree.get_meta("f48_matrix_output_base"))
	if base.is_empty(): return _result(false, "No independent matrix output root")
	OS.set_environment("TB_PROOF_OUT", base.path_join("cases").path_join(case_id))
	return _result(true, "Fresh detached proof case; only proof observers cleared, original saves load next")

static func _result(ok: bool, detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "PASS" if ok else "FAIL", "detail": detail, "data": data}

# Journal epochs identify the real writer/source record. The authenticated
# transport epoch is independently scoped by Session and is not interchangeable.
static func _boundary_epochs_match(packet: Dictionary, row: Dictionary, journal_epoch: String, transport_epoch: String, current_epoch: String) -> bool:
	if transport_epoch.is_empty() or current_epoch != transport_epoch or journal_epoch.is_empty(): return false
	if row.get("kind") == "portal_unlock": return packet.get("session_id") == transport_epoch
	return row.get("session_id") == journal_epoch and packet.get("session_id") == journal_epoch

static func _owner_transport(game: Node, writer: Node) -> Dictionary:
	if game.get("local") == null or game.get("world") == null or game.get("session") == null: return {}
	var session: Node = game.session
	var transport: Variant = session.get("_peer")
	var epoch := str(session.call("_altar_current_epoch"))
	var peer := int(session.call("local_peer_id"))
	var roster: Variant = session.call("registry")
	if session.call("is_active") != true or not transport is MultiplayerPeer or epoch.is_empty() \
		or transport.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED or roster == null \
		or roster.call("row", peer).get("character_id") != game.local.character_id \
		or writer != session.get_node_or_null(^"LedgerRpc"): return {}
	return {"epoch": epoch, "peer": peer, "game_ref": weakref(game), "local_ref": weakref(game.local),
		"world_ref": weakref(game.world), "session_ref": weakref(session), "writer_ref": weakref(writer), "transport_ref": weakref(transport)}

static func _owner_transport_matches(game: Node, writer: Node, bound: Dictionary) -> bool:
	var current := _owner_transport(game, writer)
	if current.is_empty() or bound.is_empty() or current.epoch != bound.epoch or current.peer != bound.peer: return false
	for field: String in ["game_ref", "local_ref", "world_ref", "session_ref", "writer_ref", "transport_ref"]:
		if current[field].get_ref() != bound[field].get_ref(): return false
	return true

static func _watch_owner_saves(tree: SceneTree) -> bool:
	_watch_fallback_completions(tree)
	_watch_fallback_requests(tree)
	if tree.has_meta("f48_owner_save_watch"): return true
	var game := tree.root.get_node_or_null(^"Game")
	var writer := tree.root.get_node_or_null(^"Game/Session/LedgerRpc")
	if game == null or writer == null or not writer.has_signal("transaction_boundary"): return false
	var session_ref: WeakRef = weakref(game.session)
	var observer := func(packet: Dictionary) -> void:
		var callback_started := COMMIT_TRACE.begin("proof.owner.callback")
		var identity_started := COMMIT_TRACE.begin("proof.owner.identity")
		if packet.get("phase") != "after_owner_write_before_ack" or tree.root.get_node_or_null(^"Game") != game \
			or game.session != session_ref.get_ref() or game.get("local") == null or game.get("world") == null \
			or packet.get("character_id") != game.local.character_id or packet.get("world_namespace") != game.world.reward_delivery_namespace:
			COMMIT_TRACE.end("proof.owner.identity", identity_started, "refused")
			COMMIT_TRACE.end("proof.owner.callback", callback_started, "refused")
			return
		var authority := _owner_transport(game, writer)
		if authority.is_empty():
			COMMIT_TRACE.end("proof.owner.identity", identity_started, "epoch_refused")
			COMMIT_TRACE.end("proof.owner.callback", callback_started, "refused")
			return
		var epoch := str(authority.epoch)
		COMMIT_TRACE.end("proof.owner.identity", identity_started, "passed")
		var row: Variant = game.world.reward_deliveries.get(packet.get("delivery_id"))
		var validation_started := COMMIT_TRACE.begin("proof.owner.row_validation")
		var valid: bool = WORLD_STATE.training_row_valid(row, str(game.world.reward_delivery_namespace), str(game.world.world_id))
		if row is Dictionary and row.get("kind") == "portal_unlock":
			valid = PORTAL_DELIVERY.valid(row, str(game.local.character_id), str(game.world.reward_delivery_namespace)) and row.get("world_id") == game.world.world_id
		var journal_epoch := str(row.get("session_id", "")) if row is Dictionary else ""
		if row is Dictionary and row.get("kind") == "portal_unlock": journal_epoch = epoch
		valid = valid and _boundary_epochs_match(packet, row, journal_epoch, epoch, str(game.session.call("_altar_current_epoch"))) if row is Dictionary else false
		if not valid or row.get("character_id") != packet.get("character_id") or row.get("receipt") != packet.get("receipt"):
			COMMIT_TRACE.end("proof.owner.row_validation", validation_started, "refused")
			COMMIT_TRACE.end("proof.owner.callback", callback_started, "refused")
			return
		COMMIT_TRACE.end("proof.owner.row_validation", validation_started, "passed")
		var observe_started := COMMIT_TRACE.begin("proof.owner.full_observe")
		var data := _observe(tree)
		COMMIT_TRACE.end("proof.owner.full_observe", observe_started)
		var evidence := {"packet": packet.duplicate(true), "row": row.duplicate(true), "files": data,
			"world_ref": weakref(game.world), "session_ref": weakref(game.session), "epoch": epoch, "journal_epoch": journal_epoch, "authority": authority, "identity": str(packet.delivery_id)}
		var receipt := str(row.receipt)
		var sequence: int = int(tree.get_meta("f48_owner_save_sequence", 0)) + 1
		tree.set_meta("f48_owner_save_sequence", sequence)
		var anchor := "owner-%s-%d" % [receipt.sha256_text(), sequence]
		if not PASSIVE.start(tree) or not PASSIVE.anchor(tree, anchor, data):
			COMMIT_TRACE.end("proof.owner.callback", callback_started, "passive_refused")
			return
		evidence.anchor = anchor
		if not _owner_transport_matches(game, writer, authority):
			COMMIT_TRACE.end("proof.owner.callback", callback_started, "transport_changed")
			return
		var disk := {"packet": packet, "row": row, "files": data, "session_epoch": epoch, "journal_epoch": journal_epoch, "passive": PASSIVE.evidence(tree, anchor), "observer_pid": OS.get_process_id()}
		var dir := OS.get_environment("TB_PROOF_OUT").path_join("f48-owner-saves").path_join(str(game.local.character_id))
		DirAccess.make_dir_recursive_absolute(dir)
		var path := dir.path_join(anchor + ".json")
		var publish_started := COMMIT_TRACE.begin("proof.owner.publish")
		if not DETACHED.publish(path, disk):
			COMMIT_TRACE.end("proof.owner.publish", publish_started, "refused")
			COMMIT_TRACE.end("proof.owner.callback", callback_started, "refused")
			return
		COMMIT_TRACE.end("proof.owner.publish", publish_started)
		evidence.path = path
		evidence.sha256 = _digest(path)
		tree.set_meta("f48_latest_owner_save", evidence)
		COMMIT_TRACE.end("proof.owner.callback", callback_started, "published")
	writer.connect("transaction_boundary", observer)
	tree.set_meta("f48_owner_save_watch", observer)
	return true

## A natural fallback can persist later observed care. Its certificate remains
## a descendant of the original transaction, never a replacement ledger edge.
static func _watch_fallback_requests(tree: SceneTree) -> void:
	if tree.has_meta("f48_fallback_request_watch"): return
	var game: Node = tree.root.get_node_or_null(^"Game")
	var saver: RefCounted = game.get("save_system") as RefCounted if game != null else null
	if saver == null or saver.get_script() == null or saver.get_script().resource_path != "res://scripts/save/save_game.gd" \
		or not saver.has_signal("fallback_submitted") or not saver.has_signal("fallback_request_completed"): return
	var bound := {"tree":weakref(tree),"game":weakref(game),"saver":weakref(saver),"jobs":{}}
	var submitted := func(id: String, request: Dictionary) -> void: _fallback_submitted(bound,id,request)
	var completed := func(id: String, request: Dictionary, success: bool, receipt: Dictionary) -> void: _fallback_request_completed(bound,id,request,success,receipt)
	saver.connect("fallback_submitted",submitted)
	saver.connect("fallback_request_completed",completed)
	tree.set_meta("f48_fallback_request_watch",[submitted,completed])

static func _fallback_parent_matches(edge: Dictionary, current: Variant) -> bool:
	if edge.is_empty() or not current is Dictionary or current.get("status") != "accepted" \
		or not edge.get("row") is Dictionary or not _saved_edge_errors(edge).is_empty(): return false
	var accepted: Dictionary = current.duplicate(true)
	accepted["status"] = edge.row.get("status")
	return _json_equal(accepted,edge.row)

static func _fallback_request_carrier_matches(edge: Dictionary, request: Dictionary, replayed_party: Variant) -> bool:
	if not request.get("character_data") is Dictionary or not replayed_party is Array: return false
	var personal: Dictionary = request.character_data.duplicate(true)
	personal["character_id"] = request.get("character_id")
	var expected: Dictionary = RECORD_RULES.portable_projection(edge.get("files",{}).get("disk",{})).duplicate(true)
	expected["party"] = RECORD_RULES.portable_projection({"party": replayed_party}).party
	return _json_equal(RECORD_RULES.portable_projection(personal),expected) \
		and _json_equal(personal.get("party"),replayed_party) \
		and _json_equal(personal.get("satchel_escrow"),edge.get("files",{}).get("disk",{}).get("satchel_escrow"))

static func _fallback_submitted(bound: Dictionary, id: String, request: Dictionary) -> void:
	var tree: SceneTree = bound.tree.get_ref() as SceneTree
	var game: Node = bound.game.get_ref() as Node
	var saver: RefCounted = bound.saver.get_ref() as RefCounted
	if saver == null or not is_instance_valid(tree) or not is_instance_valid(game) or not game.is_inside_tree() \
		or game.is_queued_for_deletion() or tree.root.get_node_or_null(^"Game") != game or game.get("save_system") != saver: return
	var worker: RefCounted = saver.get("_fallback") as RefCounted
	var writer: RefCounted = saver.get("_fallback_writer") as RefCounted
	if worker == null or writer == null or worker.get_script() == null or writer.get_script() == null \
		or worker.get_script().resource_path != "res://scripts/save/fallback_save_worker.gd" \
		or writer.get_script().resource_path != "res://scripts/save/save_game.gd": return
	# Actual mailbox has only active/latest pending jobs; discard superseded
	# submissions without inventing a completion or retaining an unbounded list.
	var active: Dictionary = worker.get("_active_job")
	var pending: Dictionary = worker.get("_pending_job")
	var source: Dictionary = active if active.get("id") == id else pending
	if source.get("id") != id or not is_same(source.get("request"),request): return
	for prior: String in bound.jobs.keys():
		if prior != active.get("id") and prior != id: bound.jobs.erase(prior)
	var session: Node = game.get("session") as Node
	if not is_instance_valid(session) or not session.is_inside_tree() or session.is_queued_for_deletion(): return
	var ledger: Node = session.get_node_or_null(^"LedgerRpc")
	var authority: Dictionary = _owner_transport(game,ledger)
	var edge: Dictionary = tree.get_meta("f48_latest_owner_save",{})
	if authority.is_empty() or edge.is_empty() or not _owner_transport_matches(game,ledger,edge.get("authority",{})) \
		or not request.is_read_only() or id.is_empty() or bound.jobs.has(id) \
		or request.get("character_id") != game.get("local").get("character_id") \
		or request.get("world_id") != game.get("world").get("world_id") \
		or request.get("world_instance_id") != game.get("world").get("reward_delivery_namespace") \
		or request.get("host") != (game.call("world_save_owned") == true) \
		or not _fallback_parent_matches(edge,game.get("world").get("reward_deliveries").get(edge.get("identity"))) \
		or not _fallback_parent_matches(edge,request.get("data",{}).get("reward_deliveries",{}).get(edge.get("identity"))) \
		or _digest(str(edge.get("path",""))) != edge.get("sha256") \
		or not _fallback_request_carrier_matches(edge,request,request.get("character_data",{}).get("party")) \
		or not PASSIVE.matches(tree,str(edge.get("anchor","")),request.character_data.party): return
	bound.jobs[id] = {"request":request,"authority":authority,"edge":edge,"writer_ref":weakref(writer),"saver_ref":weakref(saver),
		"worker_ref":weakref(worker),"submitted_ms":Time.get_ticks_msec(),"passive":PASSIVE.evidence(tree,str(edge.anchor))}

## Validate every frozen payload key plus the store's explicit envelope. Raw
## complete envelopes/bytes remain in the certificate, including timestamps.
static func _fallback_receipt_files(request: Dictionary, receipt: Dictionary, paths: Dictionary, writer_id: int) -> Dictionary:
	if receipt.size() != 6 or receipt.get("version") != 1 or receipt.get("source") != "SaveGame_locked_fallback_write_TRUE_BOOL" \
		or receipt.get("writer_instance_id") != writer_id or receipt.get("writer_script") != "res://scripts/save/save_game.gd" \
		or receipt.get("request_sha256") != SAVE_DOCUMENT.stringify(request).sha256_text() \
		or not receipt.get("files") is Dictionary or receipt.files.size() != paths.size(): return {}
	var decoded := {}
	for kind: String in paths:
		var file: Variant = receipt.files.get(kind)
		if not file is Dictionary or file.size() != 4 or file.get("path") != paths[kind] or not file.get("bytes_base64") is String: return {}
		# Reject malformed untrusted evidence before invoking native decoders.
		var encoded: String = file.bytes_base64
		if encoded.is_empty() or encoded.length() % 4 != 0: return {}
		var base64: RegEx = RegEx.new()
		if base64.compile("^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$") != OK \
			or base64.search(encoded) == null: return {}
		var bytes: PackedByteArray = Marshalls.base64_to_raw(file.bytes_base64)
		if bytes.is_empty() or Marshalls.raw_to_base64(bytes) != encoded: return {}
		var hasher: HashingContext = HashingContext.new()
		hasher.start(HashingContext.HASH_SHA256)
		hasher.update(bytes)
		var payload: Variant = SAVE_DOCUMENT.parse(bytes.get_string_from_utf8())
		if bytes.is_empty() or hasher.finish().hex_encode() != file.get("sha256") \
			or not payload is Dictionary or not _json_equal(payload,file.get("payload")): return {}
		var expected: Dictionary = request.get(kind + "_data",{}).duplicate(true) if kind != "slot" else request.data.duplicate(true)
		var envelope: Array[String] = CHARACTER_SAVE.ENVELOPE_KEYS if kind == "character" else WORLD_SAVE.ENVELOPE_KEYS
		if kind == "slot":
			if request.write_split and request.host: expected["split_locator"]={"world_id":request.world_id,"character_id":request.character_id}
			if not _json_equal(payload,expected): return {}
		else:
			if payload.size() != expected.size() + envelope.size(): return {}
			for field: String in expected:
				if not _json_equal(payload.get(field),expected[field]): return {}
			for field: String in envelope:
				if not payload.has(field) or (field != "version" and not payload[field] is String): return {}
			if payload.version != (CHARACTER_SAVE.VERSION if kind == "character" else WORLD_SAVE.VERSION) \
				or payload.display_name != request.display_name or str(payload.created_at).is_empty() or str(payload.last_played).is_empty(): return {}
			if kind == "character" and (payload.character_id != request.character_id \
				or payload.last_world_id != request.world_id or payload.last_world_instance_id != request.world_instance_id): return {}
			if kind == "world" and payload.world_id != request.world_id: return {}
		decoded[kind]=payload
	return decoded

static func _fallback_request_completed(bound: Dictionary, id: String, request: Dictionary, success: bool, receipt: Dictionary) -> void:
	var job: Dictionary = bound.jobs.get(id,{})
	bound.jobs.erase(id)
	if not success or job.is_empty() or not _json_equal(job.request,request): return
	var tree: SceneTree = bound.tree.get_ref() as SceneTree
	var game: Node = bound.game.get_ref() as Node
	var saver: RefCounted = bound.saver.get_ref() as RefCounted
	var writer: RefCounted = job.writer_ref.get_ref() as RefCounted
	if saver == null or not is_instance_valid(tree) or not is_instance_valid(game) or not game.is_inside_tree() or game.is_queued_for_deletion() \
		or tree.root.get_node_or_null(^"Game") != game or game.get("save_system") != saver or writer == null \
		or saver.get("_fallback_writer") != writer or saver.get("_fallback") != job.worker_ref.get_ref(): return
	var session: Node = game.get("session") as Node
	if not is_instance_valid(session) or not session.is_inside_tree() or session.is_queued_for_deletion(): return
	var ledger: Node = session.get_node_or_null(^"LedgerRpc")
	var edge: Dictionary = tree.get_meta("f48_latest_owner_save",{})
	if not is_same(edge,job.edge) or not _owner_transport_matches(game,ledger,job.authority) \
		or _digest(str(edge.get("path",""))) != edge.get("sha256") \
		or not _fallback_parent_matches(edge,game.get("world").get("reward_deliveries").get(edge.get("identity"))): return
	var characters: RefCounted = saver.get("_characters")
	var worlds: RefCounted = saver.get("_worlds")
	if characters == null or worlds == null: return
	var paths := {"character":characters.call("path_for",str(request.character_id))}
	if not request.character_only:
		paths.slot=saver.call("slot_path",int(request.slot))
		if request.host: paths.world=worlds.call("path_for",str(request.world_id))
	var decoded: Dictionary = _fallback_receipt_files(request,receipt,paths,writer.get_instance_id())
	if decoded.is_empty(): return
	var certificate := {"source":"actual_request_bound_natural_fallback_TRUE_BOOL_descendant","job_id":id,
		"submitted_ms":job.submitted_ms,"completed_ms":Time.get_ticks_msec(),"request":request,"receipt":receipt,
		"original_edge_path":edge.path,"original_edge_sha256":edge.sha256,"original_ledger_row":edge.row,
		"session_epoch":job.authority.epoch,"submission_passive":job.passive}
	var dir: String = OS.get_environment("TB_PROOF_OUT").path_join("f48-fallback-requests").path_join(str(request.character_id))
	if OS.get_environment("TB_PROOF_OUT").is_empty(): return
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = dir.path_join(id + ".json")
	if not DETACHED.publish(path,certificate): return
	tree.set_meta("f48_latest_fallback_descendant",{"job_id":id,"job":job,"receipt":receipt,"files":decoded,"path":path,"sha256":_digest(path)})

static func _fallback_descendant_matches(tree: SceneTree, now: Dictionary, edge: Dictionary) -> bool:
	var descendant: Dictionary = tree.get_meta("f48_latest_fallback_descendant",{})
	var game: Node = tree.root.get_node_or_null(^"Game")
	var session: Node = game.get("session") as Node if game != null else null
	var saver: RefCounted = game.get("save_system") as RefCounted if game != null else null
	if descendant.is_empty() or game == null or session == null or not is_same(descendant.job.edge,edge) \
		or saver == null or saver != descendant.job.saver_ref.get_ref() \
		or saver.get("_fallback_writer") != descendant.job.writer_ref.get_ref() or saver.get("_fallback") != descendant.job.worker_ref.get_ref() \
		or not _owner_transport_matches(game,session.get_node_or_null(^"LedgerRpc"),descendant.job.authority) \
		or _digest(str(descendant.path)) != descendant.sha256: return false
	return now.get("character_path") == descendant.receipt.files.character.path \
		and now.get("character_sha256") == descendant.receipt.files.character.sha256 \
		and _json_equal(now.get("disk"),descendant.files.character)

## Diagnostic only: completed(bool) carries no frozen request identity. Never
## promote this current-file observation into a ledger edge or snapshot source.
static func _watch_fallback_completions(tree: SceneTree) -> void:
	if tree.has_meta("f48_fallback_completion_watch"): return
	var game: Node = tree.root.get_node_or_null(^"Game")
	if game == null or game.get("session") == null: return
	var saver: Variant = game.get("save_system")
	if not saver is RefCounted or not saver.has_signal("fallback_completed"): return
	var saver_script: Script = saver.get_script()
	if saver_script == null or saver_script.resource_path != "res://scripts/save/save_game.gd": return
	var bound := {"tree": weakref(tree), "game": weakref(game),
		"saver": weakref(saver), "session": weakref(game.get("session"))}
	var observer := func(success: bool) -> void: _observe_fallback_completion(bound, success)
	saver.connect("fallback_completed", observer)
	tree.set_meta("f48_fallback_completion_watch", observer)

static func _fallback_source_identity(value: Variant) -> Dictionary:
	if not value is Object or not is_instance_valid(value): return {}
	var script: Script = value.get_script()
	return {"instance_id": value.get_instance_id(), "class": value.get_class(),
		"script": script.resource_path if script != null else ""}

## Read the primary file bytes only. Do not join a worker, repair/select an
## atomic tail, or touch the saver/store caches while another request runs.
static func _fallback_raw_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if file == null: return {"payload":{},"sha256":""}
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var decoded: Variant = preload("res://scripts/save/save_document.gd").parse(bytes.get_string_from_utf8())
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(bytes)
	return {"payload":decoded if decoded is Dictionary else {},"sha256":hasher.finish().hex_encode()}

static func _fallback_current_files(game: Node, saver: RefCounted) -> Dictionary:
	var local: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	# SaveGame.characters()/worlds() call finish_fallback(). Fields are the
	# actual mounted stores, whose path_for methods perform no writes/joins.
	var characters: RefCounted = saver.get("_characters")
	var worlds: RefCounted = saver.get("_worlds")
	if local == null or world == null or characters == null or worlds == null: return {}
	var character_path: String = characters.call("path_for",str(local.get("character_id")))
	var world_path: String = worlds.call("path_for",str(world.get("world_id")))
	var owner_file: Dictionary = _fallback_raw_file(character_path)
	var owns_world: bool = game.call("world_save_owned") == true
	var world_file: Dictionary = _fallback_raw_file(world_path) if owns_world else {"payload":{},"sha256":""}
	return {"character_id":str(local.get("character_id")),"world_id":str(world.get("world_id")),
		"world_namespace":str(world.get("reward_delivery_namespace")),"realm":str(local.get("realm")),
		"memory":local.call("save_data"),"disk":owner_file.payload,"world":world.call("save_data"),
		"disk_world":world_file.payload,"owns_world":owns_world,"character_path":character_path,"world_path":world_path,
		"character_sha256":owner_file.sha256,"world_sha256":world_file.sha256}

static func _observe_fallback_completion(bound: Dictionary, success: bool) -> void:
	if not success: return
	var tree: SceneTree = bound.tree.get_ref() as SceneTree
	var game: Node = bound.game.get_ref() as Node
	var saver: RefCounted = bound.saver.get_ref() as RefCounted
	var session: Node = bound.session.get_ref() as Node
	if not is_instance_valid(tree) or tree.root == null or not is_instance_valid(game) \
		or not game.is_inside_tree() or game.is_queued_for_deletion() or not is_instance_valid(session) \
		or not session.is_inside_tree() or session.is_queued_for_deletion() or saver == null or tree.root.get_node_or_null(^"Game") != game \
		or game.get("save_system") != saver or game.get("session") != session: return
	var writer: Node = session.get_node_or_null(^"LedgerRpc")
	if not is_instance_valid(writer) or writer.is_queued_for_deletion(): return
	var authority: Dictionary = _owner_transport(game, writer)
	if authority.is_empty(): return
	var sequence: int = int(tree.get_meta("f48_fallback_completion_sequence", 0)) + 1
	if sequence > 32: return # Bounded diagnostics; no producer result is changed.
	var characters: RefCounted = saver.get("_characters")
	if characters == null: return
	var owner_path: String = characters.call("path_for",str(game.get("local").get("character_id")))
	var hash_before: String = _digest(owner_path)
	var files: Dictionary = _fallback_current_files(game,saver)
	if files.is_empty() or not _owner_transport_matches(game, writer, authority): return
	var hash_after: String = _digest(owner_path)
	var edge: Dictionary = tree.get_meta("f48_latest_owner_save", {})
	var original: Dictionary = edge.get("row", {}).duplicate(true)
	var current: Variant = files.get("world", {}).get("reward_deliveries", {}).get(edge.get("identity"))
	var same_accepted: bool = false
	if not original.is_empty() and current is Dictionary and current.get("status") == "accepted":
		var compared: Dictionary = current.duplicate(true)
		compared["status"] = original.get("status")
		same_accepted = _json_equal(original, compared)
	var identities := {}
	for field: String in ["game_ref", "local_ref", "world_ref", "session_ref", "writer_ref", "transport_ref"]:
		identities[field] = _fallback_source_identity(authority[field].get_ref())
	var observation := {"source": "actual_SaveGame_fallback_completed_true_current_file_observation",
		"completion_success": true, "request_bound": false,
		"request_limitation": "completed(bool) contains no request identity; current file is observed at callback, not certified as that worker request",
		"observer_pid": OS.get_process_id(), "sampled_ms": Time.get_ticks_msec(),
		"physics_frame": Engine.get_physics_frames(), "session_epoch": authority.epoch,
		"local_peer": authority.peer, "identities": identities, "saver": _fallback_source_identity(saver),
		"worker": _fallback_source_identity(saver.get("_fallback")),
		"worker_writer": _fallback_source_identity(saver.get("_fallback_writer")),
		"files": files, "character_sha256_before_observe": hash_before, "character_sha256_after_observe": hash_after,
		"observed_file_hash_stable": not hash_before.is_empty() and hash_before == hash_after and hash_before == files.character_sha256,
		"original_ledger_row": original,
		"current_ledger_row": current.duplicate(true) if current is Dictionary else {},
		"original_row_accepted_unchanged": same_accepted,
		"original_edge_lifetime_matches": _owner_transport_matches(game, writer, edge.get("authority", {})),
		"original_edge_path": edge.get("path", ""), "original_edge_sha256": edge.get("sha256", ""),
		"original_owner_file_sha256": edge.get("files", {}).get("character_sha256", ""),
		"passive": PASSIVE.evidence(tree, _snapshot_anchor(tree))}
	var output: String = OS.get_environment("TB_PROOF_OUT")
	if output.is_empty(): return
	var dir: String = output.path_join("f48-fallback-completions").path_join(str(files.character_id))
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = dir.path_join("completion-%d-%d.json" % [OS.get_process_id(), sequence])
	if not DETACHED.publish(path, observation): return
	tree.set_meta("f48_fallback_completion_sequence", sequence)
	print("F48_FALLBACK_COMPLETION " + JSON.stringify({"path": path, "sha256": _digest(path),
		"character_sha256": files.character_sha256, "request_bound": false,
		"original_row_accepted_unchanged": same_accepted, "sampled_ms": observation.sampled_ms}))

static func _saved_edge_errors(edge: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not edge.get("row") is Dictionary or not edge.get("files") is Dictionary:
		return ["Actual complete saved edge missing"]
	var row: Dictionary = edge.row
	var data: Dictionary = edge.files
	for scope: String in ["memory", "disk"]:
		if not data.get(scope) is Dictionary:
			errors.append(scope + ": actual complete owner save carrier missing")
			continue
		var carrier: Dictionary = data[scope]
		if row.get("kind") == "portal_unlock":
			var settled: Dictionary = row.duplicate(true)
			settled.status = "settled"
			if not _json_equal(carrier.get("satchel_escrow", {}).get(row.receipt), settled) \
				or carrier.get("redesign_character", {}).get("transaction_receipts", []).count(row.receipt) != 1 \
				or not carrier.get("redesign_character", {}).get("portal_unlocks", []).has(row.biome) \
				or _counts(carrier).get(row.item, 0) != 0:
				errors.append(scope + ": exact portal owner codec/key debit/unlock/receipt not persisted")
		else:
			var full: Dictionary = RECORD_RULES.portable_projection(carrier) if RECORD_RULES.training_version(row) in [2, 3] \
				else preload("res://scripts/creatures/essence.gd").training_projection(carrier)
			if row.get("kind") == "altar_building" and full.get("party") is Array:
				full.party = full.party.map(RECORD_RULES.portable_card)
			if not _json_equal(full, row.get("after")):
				errors.append(scope + ": complete canonical carrier differs from actual immutable row.after at owner BOOL-save edge")
	if row.get("kind") == "portal_unlock":
		for field: String in ["inventory", "party", "redesign_character", "satchel_escrow", "equipment", "realm_hearts"]:
			if not _json_equal(data.get("memory", {}).get(field), data.get("disk", {}).get(field)):
				errors.append("Portal actual owner memory/disk complete carrier mismatch: " + field)
	return errors

static func _snapshot_errors(tree: SceneTree, now: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var edge: Dictionary = tree.get_meta("f48_latest_owner_save", {})
	var original_source: bool = edge.is_empty()
	if original_source: edge = tree.get_meta("f48_admitted_source", {})
	var game := tree.root.get_node_or_null(^"Game")
	if now.is_empty() or edge.is_empty() or game == null:
		return ["Actual latest owner BOOL-save or unchanged original admitted-source edge missing"]
	if not original_source and not _owner_transport_matches(game, game.session.get_node_or_null(^"LedgerRpc"), edge.get("authority", {})):
		errors.append("Actual saved owner transport/admission lifetime changed")
	if game.world != edge.world_ref.get_ref() or game.session != edge.session_ref.get_ref() \
		or game.session.call("_altar_current_epoch") != edge.epoch or now.character_id != edge.files.character_id \
		or now.world_namespace != edge.files.world_namespace or _digest(str(edge.path)) != edge.sha256:
		errors.append("Actual saved owner/world/session/immutable edge changed")
	if (now.character_sha256 != edge.files.character_sha256 or not _json_equal(now.disk, edge.files.disk)) \
		and (original_source or not _fallback_descendant_matches(tree,now,edge)):
		errors.append("Actual complete owner file changed after the latest observed edge")
	for field: String in ["inventory", "redesign_character", "satchel_escrow"]:
		if not _json_equal(now.memory.get(field), now.disk.get(field)):
			errors.append("Snapshot would hide an unsaved owner carrier: " + field)
		if original_source and not _json_equal(now.memory.get(field), edge.files.memory.get(field)):
			errors.append("Original admitted bystander changed owner carrier without an actual newer BOOL-save: " + field)
	if not PASSIVE.matches(tree, str(edge.anchor), now.memory.get("party")):
		errors.append("Full owner party differs outside exact independently replayed passive clocks")
	if original_source:
		var initial_rows: Dictionary = edge.files.world.get("reward_deliveries", {})
		for identity: Variant in now.world.get("reward_deliveries", {}):
			var decision: Variant = now.world.reward_deliveries[identity]
			if decision is Dictionary and decision.get("character_id") == now.character_id \
				and decision.get("kind") in ["creature_training", "portal_unlock", "altar_building"] \
				and not _json_equal(decision, initial_rows.get(identity)):
				errors.append("Original admitted-source baseline cannot stand in for a newer owner decision/receipt")
	else:
		errors.append_array(_saved_edge_errors(edge))
		var current: Variant = now.world.get("reward_deliveries", {}).get(edge.identity)
		if not current is Dictionary or current.get("status") != "accepted":
			errors.append("Latest real owner transaction has not completed its accepted host ACK")
		else:
			var original: Dictionary = edge.row.duplicate(true)
			var accepted: Dictionary = current.duplicate(true)
			original.erase("status")
			accepted.erase("status")
			if not _json_equal(original, accepted): errors.append("Latest authentic full transaction changed after owner save")
	if now.owns_world:
		if now.disk_world.is_empty(): errors.append("Actual durable host world unavailable")
		for field: String in ["reward_deliveries", "placed_buildings", "redesign_world"]:
			if not _json_equal(now.world.get(field), now.disk_world.get(field)):
				errors.append("Snapshot would hide an unsaved full host carrier: " + field)
	return errors

static func _snapshot_anchor(tree: SceneTree) -> String:
	var edge: Dictionary = tree.get_meta("f48_latest_owner_save", {})
	if edge.is_empty(): edge = tree.get_meta("f48_admitted_source", {})
	return str(edge.get("anchor", ""))

static func _assert_snapshot(tree: SceneTree) -> Dictionary:
	var now := _observe(tree)
	var errors := _snapshot_errors(tree, now)
	now.passive_evidence = PASSIVE.evidence(tree, _snapshot_anchor(tree))
	if not errors.is_empty() or not _fallback_descendant_matches(tree,now,tree.get_meta("f48_latest_owner_save",{})):
		now.fallback_descendant = {}
	else:
		var descendant: Dictionary = tree.get_meta("f48_latest_fallback_descendant")
		now.fallback_descendant = {"path":descendant.path,"sha256":descendant.sha256,"job_id":descendant.job_id,"request_bound":true}
	var original_source: bool = not tree.has_meta("f48_latest_owner_save")
	now.snapshot_source = "unchanged_original_admitted_disk_no_initial_memory_disk_convergence_or_saved_live_care_bond_claim" if original_source else "actual_owner_BOOL_edge_full_canonical_after_and_accepted_ACK"
	if not now.fallback_descendant.is_empty(): now.snapshot_source += "_and_separate_request_bound_natural_fallback_descendant"
	return _result(errors.is_empty(), "Read-only explicit input source " + str(now.snapshot_source) + ": " + "; ".join(errors), now)

static func _capture_durable(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Disclosed producer inputs only. Copy actual files; no autosave can repair a
	# missing transaction write, stale roster, receipt, journal or world source.
	var now := _observe(tree)
	var errors := _snapshot_errors(tree, now)
	if not errors.is_empty(): return _result(false, "Refuse invalid actual durable input: " + "; ".join(errors))
	var label := str(args.get("label", ""))
	if label.is_empty() or label != label.validate_filename(): return _result(false, "Exact fresh input capture label required")
	var destination := PROOF_FILES.out_dir(tree).path_join(label)
	if DirAccess.dir_exists_absolute(destination): return _result(false, "Actual input capture already exists")
	var copied := 0
	for directory: String in ["characters", "worlds", "saves"]:
		var count := _copy_exact(OS.get_user_data_dir().path_join(directory), destination.path_join(directory))
		if count < 0: return _result(false, "Exact byte copy failed; partial capture is not accepted")
		copied += count
	var again := _observe(tree)
	if copied <= 0 or again.character_sha256 != now.character_sha256 or again.world_sha256 != now.world_sha256:
		return _result(false, "Actual source files changed during read-only input copying")
	var source_kind := "unchanged original admitted disk; no initial memory/disk convergence or saved live care/bond claim" if not tree.has_meta("f48_latest_owner_save") else "actual newer owner BOOL-save/accepted ACK with full canonical after carriers"
	return _result(true, "Copied exact saved input bytes from " + source_kind + "; no autosave repair",
		{"source_kind": source_kind, "dir": destination, "files": copied, "character_id": now.character_id, "character_sha256": now.character_sha256, "world_sha256": now.world_sha256})

static func _copy_exact(source: String, destination: String) -> int:
	var directory := DirAccess.open(source)
	if directory == null: return 0
	if DirAccess.make_dir_recursive_absolute(destination) != OK: return -1
	var count := 0
	for file: String in directory.get_files():
		var from := source.path_join(file)
		var to := destination.path_join(file)
		if directory.is_link(file) or DirAccess.copy_absolute(from, to) != OK or _digest(from) != _digest(to): return -1
		count += 1
	for sub: String in directory.get_directories():
		if directory.is_link(sub): return -1
		var copied := _copy_exact(source.path_join(sub), destination.path_join(sub))
		if copied < 0: return -1
		count += copied
	return count

static func _measure_layout(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Detached terrain/contact observation only. No position, velocity, save,
	# collider, fixture or production configuration writes.
	var scene := tree.current_scene
	var player := (tree.get("_probe") as Object).call("player") as CharacterBody3D
	var points: Variant = args.get("points")
	if scene == null or not scene.has_method("ground_height_at") or player == null or not points is Dictionary or points.is_empty():
		return _result(false, "Actual initialized world/player and named layout points required")
	var samples := {}
	var errors: Array[String] = []
	for label: String in points:
		var xz: Variant = points[label]
		if not xz is Array or xz.size() != 2 or not (xz[0] is float or xz[0] is int) or not (xz[1] is float or xz[1] is int):
			return _result(false, "Invalid declared XZ point: " + label)
		var x := float(xz[0])
		var z := float(xz[1])
		if not is_finite(x) or not is_finite(z): return _result(false, "Nonfinite declared layout point")
		var y: float = float(scene.call("ground_height_at", x, z))
		samples[label] = {"x": x, "z": z, "finite": is_finite(y), "ground_y": y if is_finite(y) else null}
		if not is_finite(y): errors.append("Actual terrain sample unavailable: " + label)
	var data := {"samples": samples, "scene": str(scene.name), "actor_position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"actor_velocity": [player.velocity.x, player.velocity.y, player.velocity.z], "actor_on_floor": player.is_on_floor(),
		"acceptance_credit": false, "limitation": "Actual terrain-height samples; station contact, physical walk and paid build still require native proof"}
	var output := OS.get_environment("TB_PROOF_OUT")
	if output.is_empty(): return _result(false, "No detached native measurement output", data)
	DirAccess.make_dir_recursive_absolute(output)
	if not DETACHED.publish(output.path_join("f48-layout-measurement.json"), data):
		return _result(false, "Could not retain detached actual layout measurement", data)
	return _result(errors.is_empty(), "Read-only initialized native terrain layout. " + "; ".join(errors), data)

static func _fixture_trainer_fight(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Existing harness-driven fight, explicitly authorized for named mechanics.
	# Never an ordinary survival/balance/earned campaign witness. Every kill,
	# host verdict, retained event, journal, owner save and ACK is still real.
	var trainer := str(args.get("trainer_id", ""))
	var disclosure: Variant = args.get("fixture_disclosure")
	var required := {"scope": "named_mechanics_only", "self_hp_topups": true,
		"ally_placement": true, "enemy_hp_ceiling": 0, "earned_campaign_credit": false}
	var master_definition := preload("res://scripts/creatures/breakthrough.gd").master(trainer)
	if (master_definition.is_empty() and trainer != "warden_aldis") or not _json_equal(disclosure, required):
		return _result(false, "Exact named mechanics fight disclosure required; opponent HP ceiling is disabled")
	var director := tree.current_scene.get_node_or_null(^"EncounterDirector") if tree.current_scene != null else null
	var manager := tree.current_scene.get_node_or_null(^"CombatManager") if tree.current_scene != null else null
	if director == null or manager == null: return _result(false, "Actual production director/manager missing")
	var master: Variant = director.get("_master_duel")
	var guest: bool = not master_definition.is_empty() and master is Dictionary and master.get("guest") == true
	if (not guest and str(director.call("trainer_battle_id")) != trainer) or \
		(guest and (master.get("master_id") != trainer or master.get("encounter_id") != manager.call("encounter_id"))):
		return _result(false, "Fixture fight is not bound to the actual already-started named encounter")
	var budget := int(args.get("budget_frames", 3000))
	# Native 37079967838 reached its second ordinary victory at frame 2760;
	# the generic 3000-frame input budget cannot cover five full-HP opponents.
	# Only this named full-roster mechanics fixture receives a longer bound.
	var maximum := 9000 if trainer == "warden_aldis" else 3000
	if budget < 240 or budget > maximum: return _result(false, "Bounded named mechanics fight budget exceeded")
	var topup: Node = null
	if trainer == "warden_aldis":
		var provider_script: Script = load("res://tools/net/f48_actor_topup.gd")
		topup = provider_script.call("install", tree, required)
		if topup == null: return _result(false, "The disclosed canonical Warden aid requires the actual host PeerRunner")
	var result: Dictionary = await tree.call("_step_win_trainer_battle", {"budget_frames": budget,
		"fixture_guest_master": guest, "retain_fixture_actions": true, "enemy_hp_ceiling": 0,
		"fixture_topup_provider": topup})
	var retained: Variant = tree.get("_trainer_fight_progress")
	var data := {"trainer_id": trainer, "fixture_disclosure": required, "result": result.duplicate(true),
		"actions": retained.get("fixture_actions", []) if retained is Dictionary else [], "acceptance_credit": false}
	data["driver_budget_frames"] = budget
	if topup != null: data["typed_self_topups"] = topup.call("observations")
	data["final_manager"] = {"state": manager.get("state"), "outcome": manager.get("_outcome"),
		"resolve_timer": manager.get("_resolve_timer"), "waiting_shared_trainer_round": manager.get("_waiting_shared_trainer_round")}
	data["trainer_send_delay"] = director.get("_trainer_send_delay")
	data["killing_verdict"] = tree.get("_trainer_fight_killing_verdict")
	var output := OS.get_environment("TB_PROOF_OUT")
	if output.is_empty(): return _result(false, "No retained fixture-fight observation root", data)
	var folder := output.path_join("f48-fixture-fights")
	DirAccess.make_dir_recursive_absolute(folder)
	if not DETACHED.publish(folder.path_join(str(OS.get_process_id()) + "-" + trainer + "-" + str(Time.get_ticks_usec()) + ".json"), data):
		return _result(false, "Could not retain exact fixture fight actions", data)
	result["data"] = data
	return result

static func _dialogue(tree: SceneTree, args: Dictionary) -> Dictionary:
	var panel := tree.get_first_node_in_group(&"dialogue_panel")
	var expected := str(args.get("conversation", ""))
	if panel == null or expected.is_empty() or not panel.call("is_open"):
		return _result(false, "Expected actual open conversation before ordinary dialogue input")
	var runner: RefCounted = panel.get("_runner")
	if runner.call("conversation_id") != expected:
		return _result(false, "Wrong actual conversation", {"expected": expected, "actual": runner.call("conversation_id")})
	var completed := {"value": false}
	var observer := func(id: String) -> void:
		if id == expected: completed.value = true
	panel.connect("completed", observer)
	var presses := 0
	var error := ""
	# The shipping dialogue panel reads interact, not ui_accept. Stop when
	# that exact conversation completes so no extra input reaches combat.
	for _attempt: int in 12:
		if completed.value or not panel.call("is_open"): break
		if runner.call("conversation_id") != expected:
			error = "Conversation changed before completing expected challenge"
			break
		var result: Dictionary = await tree.call("_step_press", {"action": "interact"})
		if result.get("verdict") != "PASS":
			error = str(result.get("detail", "Dialogue input failed"))
			break
		presses += 1
		for _frame: int in 30: await tree.physics_frame
	panel.disconnect("completed", observer)
	return _result(completed.value and error.is_empty(), "Actual named conversation completion by ordinary interact input. " + error,
		{"conversation": expected, "presses": presses, "completed": completed.value})


static func _deploy_owned(tree: SceneTree) -> Dictionary:
	var director := tree.current_scene.get_node_or_null(^"EncounterDirector") if tree.current_scene != null else null
	var game := tree.root.get_node_or_null(^"Game")
	if director == null or game == null: return _result(false, "Actual director and owner required")
	var local: RefCounted = game.get("local")
	var original: Array = UIDS.uids(local.call("save_data").get("party", []))
	if original.is_empty(): return _result(false, "Original owned party required; cannot adopt a substitute")
	if director.call("ally_body") == null:
		var pressed: Dictionary = await tree.call("_step_press", {"action": "creature_recall"})
		if pressed.get("verdict") != "PASS": return pressed
		for _frame: int in 30: await tree.physics_frame
	var creature: Variant = director.call("ally_instance")
	var unchanged := original == UIDS.uids(local.call("save_data").get("party", []))
	var owned := creature != null and original.has(str(creature.get("uid")))
	return _result(unchanged and owned and director.call("ally_body") != null,
		"Ordinary recall input must deploy an original owned companion without changing party UIDs")

static func _capture_input_state(tree: SceneTree) -> Dictionary:
	var owner := INPUT_OWNER.current(tree)
	var probe := tree.get("_probe") as Object
	var game := tree.root.get_node_or_null(^"Game")
	var captures := game.get_node_or_null(^"Session/FoundationComposition/Captures") if game != null else null
	var requests: Variant = captures.get("_requests") if captures != null else null
	return {"context": str(probe.call("input_context")) if probe != null else "missing_probe",
		"owner_path": str(owner.get_path()) if owner != null else "",
		"owner_script": str(owner.get_script().resource_path) if owner != null and owner.get_script() != null else "",
		"tab": str(owner.call("current_tab_id")) if owner != null and owner.has_method("current_tab_id") else "",
		"pending_catch_uid": str(game.pending_catch.get("uid")) if game != null and game.pending_catch != null else "",
		"capture_active": str(captures.get("_active")) if captures != null else "missing_capture_service",
		"capture_requests": requests.size() if requests is Dictionary else -1}

static func _capture_pending_object(value: Variant, expected: Variant = null) -> Dictionary:
	# Object IDs are observations, never deserialized ownership or replacement refs.
	var data := {"variant_type": typeof(value), "valid": is_instance_valid(value)}
	if not is_instance_valid(value): return data
	if value is Object:
		data["instance_id"] = value.get_instance_id()
	if value is WeakRef:
		var target: Variant = value.get_ref()
		data["target_valid"] = is_instance_valid(target)
		if is_instance_valid(target) and target is Object:
			data["target_instance_id"] = target.get_instance_id()
			data["matches_current"] = is_instance_valid(expected) and target == expected
	return data

static func _capture_pending_source(value: Variant) -> Dictionary:
	# These production rows/pending dictionaries contain portable data only.
	# Retain all fields and original Variant numeric types beside readable JSON.
	return {"variant_type": typeof(value), "value": value.duplicate(true) if value is Dictionary or value is Array else value,
		"variant_hex": var_to_bytes(value).hex_encode()}

static func _capture_pending_diagnostic(game: Node) -> Dictionary:
	# One synchronous observation at the refused close boundary. No save, retry,
	# ACK, setter, input or wait; an unknown service never becomes a clear fence.
	var data := {"observed_at_tick_usec": Time.get_ticks_usec(), "game_present": is_instance_valid(game)}
	if not is_instance_valid(game): return data
	var session: Variant = game.get("session")
	var player: Variant = game.get("local")
	var world: Variant = game.get("world")
	data["session"] = _capture_pending_object(session)
	data["player"] = _capture_pending_object(player)
	data["world"] = _capture_pending_object(world)
	if not is_instance_valid(session) or not session is Node: return data
	data["transport_epoch"] = session.call("_altar_current_epoch")
	data["snapshot_ready"] = session.call("snapshot_ready")
	var host: Variant = session.call("is_host")
	data["is_host"] = host
	data["is_host_variant_type"] = typeof(host)
	var transport: Variant = session.get("_peer")
	data["transport"] = _capture_pending_object(transport)
	if is_instance_valid(transport) and transport is MultiplayerPeer:
		data["transport_connection_status"] = transport.get_connection_status()
	if is_instance_valid(player) and player is RefCounted:
		data["character_id"] = player.get("character_id")
		var portal_pending: Variant = session.call("_pending_portal_for", str(player.get("character_id")))
		data["portal_pending"] = portal_pending
		data["portal_pending_variant_type"] = typeof(portal_pending)
		var blocked: Variant = session.call("_owner_training_mutation_blocked", player)
		data["mutation_blocked"] = blocked
		data["mutation_blocked_variant_type"] = typeof(blocked)
	if is_instance_valid(world) and world is RefCounted:
		data["world_id"] = world.get("world_id")
		data["world_namespace"] = world.get("reward_delivery_namespace")
	var retry: Variant = session.get("_owner_training_retry")
	data["retry_variant_type"] = typeof(retry)
	if retry is Dictionary:
		var scalars: Dictionary = retry.duplicate(true)
		var weak_sources := {}
		for field: String in ["player", "world", "release_instance"]:
			if not retry.has(field): continue
			var expected: Variant = player if field == "player" else world if field == "world" else null
			weak_sources[field] = _capture_pending_object(retry[field], expected)
			scalars.erase(field)
		if retry.has("capture_originals") and retry.capture_originals is Array:
			var originals: Array = []
			for original: Variant in retry.capture_originals: originals.append(_capture_pending_object(original))
			weak_sources["capture_originals"] = originals
			scalars.erase("capture_originals")
		data["retry"] = {"keys": retry.keys(), "scalar_source": _capture_pending_source(scalars), "weak_sources": weak_sources}
	data["owner_training_row"] = _capture_pending_source(session.call("_owner_training_row"))
	for field: String in ["_owner_passive", "_groom_passive"]:
		var service: Variant = session.get(field)
		var observation := _capture_pending_object(service)
		if is_instance_valid(service) and service is RefCounted:
			observation["pending"] = _capture_pending_source(service.get("pending"))
			if field == "_owner_passive":
				var local: Variant = service.get("local")
				observation["local_variant_type"] = typeof(local)
				observation["local_error_present"] = local is Dictionary and local.has("error")
				if local is Dictionary and local.has("error"): observation["local_error"] = _capture_pending_source(local.error)
		data[field.trim_prefix("_")] = observation
	return data

static func _finish_capture_presentation(tree: SceneTree, capture_started_frame: int) -> Dictionary:
	# An accepted free-slot catch leaves the real Creatures menu open. Finish
	# that presentation with ordinary input only after all catch work settled.
	var game := tree.root.get_node_or_null(^"Game")
	var captures := game.get_node_or_null(^"Session/FoundationComposition/Captures") if game != null else null
	var before := _capture_input_state(tree)
	var data := {"before": before, "ordinary_cancel": false,
		"capture_started_physics_frame": capture_started_frame, "capture_budget_frames": 600, "modal_release_frames": 15}
	if capture_started_frame < 0:
		return _result(false, "Original catch observation timeline is unavailable", data)
	if game == null or game.session == null or captures == null \
		or captures.get_script() != preload("res://scripts/net/foundation_capture.gd") \
		or game.pending_catch != null or not before.capture_active.is_empty() or before.capture_requests != 0 \
		or game.session.call("_owner_training_mutation_blocked", game.local) == true:
		data["pending_diagnostic"] = _capture_pending_diagnostic(game)
		return _result(false, "Accepted catch presentation still has pending catch/owner/capture work; no close input sent", data)
	var owner := INPUT_OWNER.current(tree)
	if owner == null:
		data["after"] = before.duplicate(true)
		return _result(before.context == "world", "Accepted catch must release actual world input", data)
	if owner != game.call("menu") or owner.get_script() != preload("res://scripts/ui/game_menu.gd") \
		or owner.call("is_open") != true or before.tab != "creatures" or before.context != "menu_creatures":
		return _result(false, "Only the actual settled catch's Creatures menu may receive close input", data)
	var session: Node = game.session
	var epoch := str(session.call("_altar_current_epoch"))
	var local: RefCounted = game.local
	var world: RefCounted = game.world
	var character: String = local.character_id
	var namespace_id: String = world.reward_delivery_namespace
	data["close_started_physics_frame"] = Engine.get_physics_frames()
	var pressed: Dictionary = await tree.call("_step_press", {"action": "menu_cancel"})
	data["ordinary_cancel"] = true
	data["press"] = pressed.duplicate(true)
	if pressed.get("verdict") != "PASS":
		data["pending_diagnostic"] = _capture_pending_diagnostic(game)
		return _result(false, "Ordinary settled-catch menu close input failed", data)
	var modal_frames_left := 15 # The original allowance, distinct from the catch's 600 frames.
	var released := false
	while true:
		# This binding check follows the press await and every frame await.
		# A fresh owner/session/world cannot satisfy the original catch's close.
		var source_live: bool = is_instance_valid(game) and is_instance_valid(session) and is_instance_valid(captures) and is_instance_valid(owner) \
			and tree.root.get_node_or_null(^"Game") == game and game.session == session and game.local == local and game.world == world \
			and session.call("_altar_current_epoch") == epoch and local.character_id == character and world.reward_delivery_namespace == namespace_id \
			and game.get_node_or_null(^"Session/FoundationComposition/Captures") == captures
		if not source_live: break
		if modal_frames_left == 0:
			if Engine.get_physics_frames() - capture_started_frame - 15 > 600: break
			var after := _capture_input_state(tree)
			data["after"] = after
			released = INPUT_OWNER.current(tree) == null and after.context == "world" and owner.call("is_open") == false \
				and game.pending_catch == null and after.capture_active.is_empty() and after.capture_requests == 0 \
				and session.call("_owner_training_mutation_blocked", game.local) != true
			if released or Engine.get_physics_frames() - capture_started_frame - 15 >= 600: break
		else:
			modal_frames_left -= 1
		await tree.physics_frame
	data["observed_physics_frame"] = Engine.get_physics_frames()
	if not released: data["pending_diagnostic"] = _capture_pending_diagnostic(game)
	return _result(released, "Ordinary settled-catch menu close must restore actual world input before onward interaction", data)


static func _fixture_approach(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Explicit mechanics setup at an ACTUAL mounted authored site. The shipping
	# prompt/chooser, actor contact, admission and transaction fences still run.
	if args.get("fixture_disclosure") != "named_mechanics_actor_and_owned_ally_placement_no_earned_credit":
		return _result(false, "Explicit actual actor/owned-ally position fixture disclosure required")
	var scene := tree.current_scene
	var target_name := str(args.get("target", ""))
	var master_id := target_name.trim_suffix("_chest")
	var master_definition := preload("res://scripts/creatures/breakthrough.gd").master(master_id)
	if scene == null or (master_definition.is_empty() and target_name not in ["warden_aldis", "forge", "kitchen", "altar", "home_arch", "tidewake_arch", "meadows_pedestal"]):
		return _result(false, "Unknown authored mechanics approach")
	var world_input_before: Dictionary = {}
	if target_name == "forge":
		world_input_before = _capture_input_state(tree)
		if INPUT_OWNER.current(tree) != null or world_input_before.get("context") != "world":
			return _result(false, "Forge approach requires actual world input after the preceding ordinary panel close; context=%s owner=%s"
				% [str(world_input_before.get("context")), str(world_input_before.get("owner_path"))],
				{"target": target_name, "world_input_before": world_input_before, "acceptance_credit": false})
	var game := tree.root.get_node_or_null(^"Game")
	var target: Node3D
	var altar_interaction: Node3D
	var altar_binding := {}
	for candidate: Node in scene.find_children("*", "Node3D", true, false):
		if not master_definition.is_empty() and candidate.get_script() == preload("res://scripts/masters/master_site.gd") \
			and candidate.get("master_id") == master_id and candidate.get("_mounted") == true:
			if target != null: return _result(false, "Ambiguous actual Master site")
			target = candidate.get_node_or_null(^"RecipeChest" if target_name.ends_with("_chest") else ^"Master") as Node3D
		elif target_name == "warden_aldis" and candidate.get_script() == preload("res://scripts/world/stronghold_climax.gd"):
			if target != null: return _result(false, "Ambiguous actual Warden site")
			target = candidate.call("warden_body") as Node3D
		elif target_name in ["forge", "kitchen"] and candidate.get_script() == preload("res://scripts/build/station_piece.gd") \
			and candidate.get("_id") == target_name and candidate.get("_ghost") == false and candidate.get("_registered") == true:
			if target != null: return _result(false, "Ambiguous actual registered station")
			target = candidate as Node3D
		elif target_name == "altar" and candidate.get_script() == preload("res://scripts/build/build_piece.gd") \
			and candidate.get_meta("building_id", "") == "altar":
			if target != null: return _result(false, "Ambiguous actual paid Altar")
			var placer: Node
			for node: Node in tree.get_nodes_in_group("build_placer"):
				if scene.is_ancestor_of(node) and node.get_script() == preload("res://scripts/build/build_placer.gd"):
					if placer != null: return _result(false, "Ambiguous actual Altar placer")
					placer = node
			if game == null or placer == null: return _result(false, "Actual owning Altar placer unavailable")
			var key := "altar:meadows:" + str(candidate.get_meta("building_uid", ""))
			var resolved: Dictionary = placer.call("resolve_altar_station", game, key, candidate)
			if resolved.get("ok") != true: return _result(false, "Actual paid Altar node does not resolve", resolved)
			var world: RefCounted = game.get("world")
			var paid := WORLD_STATE.altar_paid_provenance(world.get("reward_deliveries"),
				str(world.get("reward_delivery_namespace")), str(world.get("world_id")), resolved.record)
			if paid.is_empty(): return _result(false, "Actual accepted paid Altar provenance unavailable")
			altar_interaction = candidate.get_node_or_null(^"AltarInteraction") as Node3D
			if altar_interaction == null or altar_interaction.get_script() != preload("res://scripts/ui/altar_station_interaction.gd") \
				or altar_interaction.call("_live_binding") != true:
				return _result(false, "Actual paid Altar interaction is not mounted")
			var prompt: Node3D = altar_interaction.get("_prompt") as Node3D
			if not is_instance_valid(prompt) or prompt.get_parent() != altar_interaction \
				or prompt.get_script() != preload("res://scripts/world/interactable.gd") or prompt.get("enabled") != true:
				return _result(false, "Actual mounted Altar prompt unavailable")
			altar_binding = {"building_uid": candidate.get_meta("building_uid"), "station_key": key,
				"record": resolved.record, "paid_delivery_id": paid.delivery_id,
				"interaction_path": str(altar_interaction.get_path()), "prompt_path": str(prompt.get_path())}
			target = candidate as Node3D
		elif target_name in ["home_arch", "tidewake_arch", "meadows_pedestal"] \
			and candidate.get_script() == preload("res://scripts/world/crossing_hall.gd"):
			if target != null: return _result(false, "Ambiguous actual Hall")
			var slot: Node3D
			if target_name == "meadows_pedestal": slot = candidate.get("_pedestals").get("meadows") as Node3D
			else: slot = candidate.call("arch", "home" if target_name == "home_arch" else "tidewake") as Node3D
			target = slot.get_node_or_null(^"Approach") as Node3D if slot != null else null
	var player := (tree.get("_probe") as Object).call("player") as CharacterBody3D
	var director := scene.get_node_or_null(^"EncounterDirector")
	if not is_instance_valid(target) or game == null or player == null or director == null:
		return _result(false, "Actual mounted target/player/director unavailable")
	var ally := director.call("ally_body") as Node3D
	var creature: Variant = director.call("ally_instance")
	if not is_instance_valid(ally) or creature == null: return _result(false, "Original owned companion must already be ordinarily deployed")
	var uid := str(creature.get("uid"))
	var local: RefCounted = game.get("local")
	var owned := false
	for card: Dictionary in local.call("save_data").get("party", []):
		if card.get("uid") == uid: owned = true
	if not owned or uid.is_empty(): return _result(false, "Fixture cannot create or substitute an owned companion")
	var actor_before := player.global_position
	var ally_before := ally.global_position
	var requested := target.global_position + Vector3(2.0, 2.0, 0.0)
	if target_name == "forge":
		# The east side competes with the actual paid Altar prompt. Stand west
		# of the Forge's front prompt, keeping the shipping LOS outside its body.
		var forge_origin: Vector3 = target.call("interaction_origin")
		requested = forge_origin - target.global_basis.x.normalized() * 2.0
		requested.y = target.global_position.y + 2.0
	if target_name in ["home_arch", "tidewake_arch", "meadows_pedestal"]:
		requested = target.global_position + Vector3(0.0, 2.0, 0.0)
	var ally_requested := target.global_position + Vector3(2.0, 0.0, 1.0)
	load("res://scripts/creatures/remote_creature.gd").teleport_body(player, requested)
	player.velocity = Vector3.ZERO
	var ally_placed: bool = ally.has_method("place_on_ground") and ally.call("place_on_ground", ally_requested) == true
	for _frame: int in 90: await tree.physics_frame
	var actual := player.global_position
	var actual_ally := ally.global_position
	var data := {"target": target_name, "source_path": str(target.get_path()), "owned_uid": uid,
		"actor_before": [actor_before.x, actor_before.y, actor_before.z], "actor_requested": [requested.x, requested.y, requested.z],
		"actor_after": [actual.x, actual.y, actual.z], "actor_on_floor": player.is_on_floor(),
		"ally_before": [ally_before.x, ally_before.y, ally_before.z], "ally_requested": [ally_requested.x, ally_requested.y, ally_requested.z],
		"ally_after": [actual_ally.x, actual_ally.y, actual_ally.z], "ally_placement_accepted": ally_placed,
		"fixture_disclosure": args.fixture_disclosure, "acceptance_credit": false}
	var forge_world_input: bool = true
	if target_name == "forge":
		var world_input_after: Dictionary = _capture_input_state(tree)
		data["world_input_before"] = world_input_before
		data["world_input_after"] = world_input_after
		forge_world_input = INPUT_OWNER.current(tree) == null and world_input_after.get("context") == "world"
	if target_name == "altar":
		data["altar_binding"] = altar_binding
		if not is_instance_valid(altar_interaction) or altar_interaction.call("_live_binding") != true:
			return _result(false, "Actual paid Altar interaction changed during approach", data)
	var output := OS.get_environment("TB_PROOF_OUT")
	if output.is_empty(): return _result(false, "No detached fixture approach observation root", data)
	var folder := output.path_join("f48-fixture-approaches")
	DirAccess.make_dir_recursive_absolute(folder)
	if not DETACHED.publish(folder.path_join(str(OS.get_process_id()) + "-" + target_name + "-" + str(Time.get_ticks_usec()) + ".json"), data):
		return _result(false, "Could not retain disclosed actual position fixture", data)
	return _result(ally_placed and player.is_on_floor() and actual.distance_to(target.global_position) <= 3.0 and forge_world_input,
		"Disclosed authored-site placement; actual actor floor/proximity required before ordinary prompt"
			+ ("; actual world input required at Forge" if target_name == "forge" else ""), data)

static func _fixture_join_boss(tree: SceneTree, args: Dictionary) -> Dictionary:
	if args.get("fixture_disclosure") != "named_mechanics_actual_announced_boss_join_no_earned_credit":
		return _result(false, "Explicit authenticated actual boss join fixture required")
	var director := tree.current_scene.get_node_or_null(^"EncounterDirector") if tree.current_scene != null else null
	if director == null: return _result(false, "Actual director unavailable")
	var matches: Array = []
	for row: Dictionary in director.call("joinable_encounters"):
		if row.get("kind") == "boss" and row.get("phase") == "active" \
			and row.get("opponent", {}).get("owner_npc") == "warden_aldis": matches.append(row)
	if matches.size() != 1: return _result(false, "Exactly one actual current Warden announcement required")
	var result: Dictionary = await tree.call("_step_join_encounter", {"encounter_id": matches[0].encounter_id})
	result["data"] = {"announcement": matches[0], "fixture_disclosure": args.fixture_disclosure, "acceptance_credit": false}
	return result

static func _arm_boundary(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var writer := tree.root.get_node_or_null(^"Game/Session/LedgerRpc")
	var actions := {"craft": "station_craft", "release": "trait_release", "feast": "feast_feed",
		"key": "portal_key", "relic": "relic_hang", "essence_spend": "altar_spend"}
	var transaction := str(args.get("transaction", ""))
	var phase := str(args.get("phase", ""))
	var pid := int(args.get("guest_pid", -1))
	var character := str(args.get("character_id", ""))
	var token := str(args.get("token", ""))
	var coordinator_pid := int(args.get("coordinator_pid", -1))
	var process_identity := str(args.get("process_identity", ""))
	if writer == null or game == null or not writer.has_signal("transaction_boundary") or not actions.has(transaction) \
		or phase not in ["after_host_write_before_delivery", "after_owner_write_before_ack"] \
		or pid <= 0 or coordinator_pid <= 0 or coordinator_pid == pid or process_identity.is_empty() \
		or character.is_empty() or token.is_empty() or tree.has_meta("f48_boundary_armed"): return _result(false, "Exact production boundary cannot be armed")
	if (phase == "after_host_write_before_delivery") != bool(game.call("is_host")) \
		or (phase == "after_owner_write_before_ack" and (pid != OS.get_process_id() or character != game.local.character_id)):
		return _result(false, "Boundary observer is not the actual host/owner process")
	var output := OS.get_environment("TB_PROOF_OUT")
	if output.is_empty(): return _result(false, "Detached boundary evidence directory unavailable")
	var path := output.path_join("f48-boundaries").path_join(token.validate_filename() + ".json")
	var ack_path := path + ".ack.json"
	if FileAccess.file_exists(path) or FileAccess.file_exists(ack_path) or FileAccess.file_exists(path + ".resume.json"):
		return _result(false, "Boundary token already exists; fresh output required")
	var world_ref: WeakRef = weakref(game.world)
	var namespace_id := str(game.world.reward_delivery_namespace)
	var epoch := str(game.session.call("_altar_current_epoch"))
	var previous_receipts: Array[String] = []
	for row: Variant in game.world.reward_deliveries.values():
		if row is Dictionary and row.get("character_id") == character and not str(row.get("receipt", "")).is_empty(): previous_receipts.append(str(row.receipt))
	var observer := func(observation: Dictionary) -> void:
		if tree.get_meta("f48_boundary_fired", false) == true or observation.get("phase") != phase \
			or observation.get("action") != actions[transaction] or observation.get("character_id") != character \
			or observation.get("world_namespace") != namespace_id or game.world != world_ref.get_ref() \
			or game.session.call("_altar_current_epoch") != epoch: return
		if str(observation.get("delivery_id", "")).is_empty() or str(observation.get("receipt", "")).is_empty(): return
		if previous_receipts.has(str(observation.receipt)): return
		if transaction == "key" and observation.get("biome") != "tidewake": return
		var evidence := {"token": token, "phase": phase, "transaction": transaction,
			"guest_pid": pid, "observer_pid": OS.get_process_id(), "session_epoch": epoch,
			"coordinator_pid": coordinator_pid, "process_identity": process_identity,
			"observation": observation.duplicate(true), "files": _observe(tree)}
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		if not DETACHED.publish(path, evidence): return
		tree.set_meta("f48_boundary_fired", true)
		# The coordinator owns the child. It reads this immutable exact-cut
		# marker while pumping the pending input step, kills through a kernel
		# process handle/pidfd, waits for real exit, then writes a correlated ACK.
		# Neither Godot OS.kill nor its process-local PID map is an exit witness.
		var marker_sha := FileAccess.get_sha256(path)
		var deadline := Time.get_ticks_msec() + 10000
		while Time.get_ticks_msec() < deadline:
			var ack: Variant = JSON.parse_string(FileAccess.get_file_as_string(ack_path)) if FileAccess.file_exists(ack_path) else null
			if ack is Dictionary and ack.get("token") == token and ack.get("marker_sha256") == marker_sha \
				and ack.get("coordinator_pid") == coordinator_pid and ack.get("guest_pid") == pid \
				and ack.get("process_identity") == process_identity:
				if ack.get("exit", {}).get("ok") == true and ack.get("exit", {}).get("exited") == true \
					and ack.get("exit", {}).get("identity") == process_identity:
					DETACHED.publish(path + ".resume.json", {"token": token, "marker_sha256": marker_sha,
						"ack_sha256": FileAccess.get_sha256(ack_path), "observer_pid": OS.get_process_id()})
				return
			OS.delay_msec(1)
	writer.connect("transaction_boundary", observer)
	tree.set_meta("f48_boundary_armed", observer)
	return _result(true, "Armed real writer boundary for original admitted character; no state mutation")

static func _observe(tree: SceneTree) -> Dictionary:
	var started := Time.get_ticks_msec()
	_phase("current", "observe_begin", started)
	var game := tree.root.get_node_or_null(^"Game")
	if game == null: return {}
	var local: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	if local == null or world == null or saver == null or str(local.character_id).is_empty(): return {}
	var characters: RefCounted = saver.call("characters")
	var worlds: RefCounted = saver.call("worlds")
	var disk: Dictionary = characters.call("read", str(local.character_id))
	_phase(str(local.character_id), "owner_disk_read", started)
	var owns_world := bool(game.call("world_save_owned"))
	var disk_world: Dictionary = worlds.call("read", str(world.world_id)) if owns_world else {}
	var memory: Dictionary = local.call("save_data")
	_phase(str(local.character_id), "owner_memory_read", started)
	var character_path := ATOMIC.readable_path(str(characters.call("path_for", str(local.character_id))))
	var world_path := ATOMIC.readable_path(str(worlds.call("path_for", str(world.world_id))))
	var observed := {"character_id": str(local.character_id), "world_id": str(world.world_id),
		"world_namespace": str(world.reward_delivery_namespace), "realm": str(local.realm),
		"memory": memory, "disk": disk, "world": world.call("save_data"), "disk_world": disk_world,
		"owns_world": owns_world, "character_path": character_path, "world_path": world_path,
		"character_sha256": _digest(character_path), "world_sha256": _digest(world_path),
		"world_files": _files(OS.get_user_data_dir().path_join("worlds"))}
	_phase(str(local.character_id), "observe_complete", started)
	return observed

static func _digest(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

static func _remember(tree: SceneTree, label: String, data: Dictionary, live_anchor: bool = false) -> bool:
	# Labels are exact dictionary keys, never Godot metadata identifiers.
	var witnesses: Dictionary = tree.get_meta("f48_witnesses", {})
	witnesses[label] = data.duplicate(true)
	if live_anchor and not PASSIVE.anchor(tree, label, data): return false
	tree.set_meta("f48_witnesses", witnesses)
	return true

static func _remembered(tree: SceneTree, label: String) -> Dictionary:
	var witnesses: Dictionary = tree.get_meta("f48_witnesses", {})
	return witnesses.get(label, {})

static func _phase(label: String, phase: String, started: int) -> void:
	print("[f48-observation] label=%s phase=%s elapsed_ms=%d" % [label, phase, Time.get_ticks_msec() - started])

static func _summary(data: Dictionary, path: String) -> Dictionary:
	return {"character_id": data.get("character_id", ""), "world_id": data.get("world_id", ""),
		"world_namespace": data.get("world_namespace", ""), "realm": data.get("realm", ""),
		"character_sha256": data.get("character_sha256", ""), "world_sha256": data.get("world_sha256", ""),
		"observation_path": path, "observation_sha256": _digest(path)}

static func _sealed_reply(tree: SceneTree, action: String, args: Dictionary, result: Dictionary) -> Dictionary:
	# Preserve the entire original verdict/args/full observation on PASS and FAIL.
	# Only transport is compact; the complete saved transaction row is required IPC.
	var started := Time.get_ticks_msec()
	_phase(action, "oracle_complete", started)
	await tree.process_frame
	var output := OS.get_environment("TB_PROOF_OUT")
	if output.is_empty(): return _result(false, "Detached oracle output required")
	var dir := output.path_join("f48-observations")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("%s-%d-%d.json" % [action, OS.get_process_id(), Time.get_ticks_usec()])
	if not DETACHED.publish(path, {"action": action, "args": args, "result": result}):
		return _result(false, "Could not seal complete original oracle result")
	_phase(action, "full_result_published", started)
	await tree.process_frame
	var original: Dictionary = result.get("data", {})
	var observed: Dictionary = original.get("observation", original)
	var compact := _summary(observed, path)
	if original.has("saved_transaction_row"):
		compact.saved_transaction_row = original.saved_transaction_row.duplicate(true)
	_phase(action, "compact_reply_ready", started)
	return _result(result.get("verdict") == "PASS", str(result.get("detail", "")), compact)

static func _witness(tree: SceneTree, args: Dictionary) -> Dictionary:
	var label := str(args.get("remember", ""))
	var started := Time.get_ticks_msec()
	_phase(label, "begin", started)
	var producer: bool = tree.get_meta("f48_producer_observation", false) == true
	if producer and not PASSIVE.start(tree): return _result(false, "Actual passive-clock observation unavailable")
	var data := _observe(tree)
	_phase(label, "observed", started)
	if data.is_empty() or data.disk.is_empty():
		return await _sealed_reply(tree, "f48_witness", args, _result(false, "Actual durable character file unavailable", data))
	# The explicit producer's initial guest input predates the finite Home Key
	# runtime. Admission settles that authentic grant before the operation's
	# bystander baseline; never grant, save, ACK or alter the later equalities.
	var admission_game: Node = tree.root.get_node_or_null(^"Game")
	var disk_flags: Array = data.disk.get("flags", {}).get("flags", [])
	if producer and label == "initial-bootstrap" and admission_game != null \
			and admission_game.session.call("is_host") == false \
			and disk_flags.has("opening:beat:walk_out") and not disk_flags.has("home_key_given"):
		var opening: Script = preload("res://scripts/net/opening_home_key.gd")
		var gift_id: String = preload("res://scripts/net/reward_delivery.gd").delivery_id(
			str(data.world_namespace), "home_key:grant:" + str(data.character_id), str(data.character_id))
		var settled: bool = false
		# Same 3000-frame default step allowance; coordinator budgets unchanged.
		for frame: int in 3000:
			var gift: Variant = admission_game.world.reward_deliveries.get(gift_id)
			var edge: Dictionary = tree.get_meta("f48_latest_owner_save", {})
			var row: Dictionary = edge.get("row", {})
			if gift is Dictionary and gift.get("status") == "accepted" \
					and opening.valid_row(gift, admission_game.world, str(data.character_id)) \
					and opening.owner_physically_settled(admission_game.local, gift_id) \
					and row.get("action") == "home_key_deliver" \
					and row.get("intent", {}).get("delivery_id") == gift_id:
				var admitted: Dictionary = _observe(tree)
				if _snapshot_errors(tree, admitted).is_empty():
					data = admitted
					settled = true
					break
			await tree.physics_frame
		if not settled:
			return await _sealed_reply(tree, "f48_witness", args, _result(false,
				"Authentic legacy Home Key admission did not reach owner BOOL-save and accepted journal within original step budget", _observe(tree)))
		_phase(label, "authentic_admission_settled_before_baseline", started)
	if not label.is_empty() and not _remember(tree, label, data, producer):
		return await _sealed_reply(tree, "f48_witness", args, _result(false, "Actual full-card witness anchor refused", data))
	_phase(label, "remembered", started)
	# The coherent full observation is already captured. Yield only afterwards,
	# allowing the existing genuine heartbeat timer to run between costly phases.
	await tree.process_frame
	var output := OS.get_environment("TB_PROOF_OUT")
	if output.is_empty() or label.is_empty() or label != label.validate_filename():
		return await _sealed_reply(tree, "f48_witness", args, _result(false, "Exact detached witness label/output required", data))
	var dir := output.path_join("f48-witnesses").path_join(str(data.character_id))
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(label + ".json")
	if not DETACHED.publish(path, data):
		return await _sealed_reply(tree, "f48_witness", args, _result(false, "Could not preserve immutable detached witness", data))
	if producer and not tree.has_meta("f48_admitted_source"):
		var game := tree.root.get_node_or_null(^"Game")
		tree.set_meta("f48_admitted_source", {"files": data.duplicate(true), "anchor": label, "path": path, "sha256": _digest(path),
			"world_ref": weakref(game.world), "session_ref": weakref(game.session), "epoch": str(game.session.call("_altar_current_epoch"))})
	_phase(label, "full_witness_published", started)
	await tree.process_frame
	var compact := _summary(data, path)
	_phase(label, "compact_reply_ready", started)
	return _result(true, "Read actual files without autosave; full immutable witness retained", compact)

static func _restore_witness(tree: SceneTree, args: Dictionary) -> Dictionary:
	var label := str(args.get("remember", ""))
	var now := _observe(tree)
	if now.is_empty() or label.is_empty(): return _result(false, "No admitted character/label for detached witness")
	var path := OS.get_environment("TB_PROOF_OUT").path_join("f48-witnesses").path_join(now.character_id).path_join(label.validate_filename() + ".json")
	var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not prior is Dictionary or prior.get("character_id") != now.character_id or prior.get("world_namespace") != now.world_namespace:
		return _result(false, "Detached before witness missing or belongs to another character/world")
	_remember(tree, label, prior)
	return _result(true, "Recovered detached observation only; production state unchanged")

static func _participants(tree: SceneTree, args: Dictionary) -> Dictionary:
	var data: Variant = await tree.call("_execute_probe", {"what": "encounter", "args": {}})
	var wanted: Array = args.get("characters", [])
	if not data is Dictionary or data.get("phase") != "active" or wanted.size() < 2:
		return _result(false, "Actual active shared encounter unavailable")
	var members: Variant = data.get("participants", {})
	if not members is Array or members.size() != wanted.size(): return _result(false, "Wrong actual participant count", data)
	# Registry maps changing transport peer ids back to stable character ids.
	var session: Node = tree.root.get_node_or_null(^"Game/Session")
	if session == null: return _result(false, "Actual Session unavailable")
	var registry: Variant = session.call("registry")
	if registry == null: return _result(false, "Actual peer registry unavailable")
	var found: Array = []
	for peer: Variant in members:
		var row: Variant = registry.call("row", int(peer))
		if not row is Dictionary: return _result(false, "Participant has no stable identity")
		found.append(str(row.get("character_id", "")))
	var exact: bool = _unique(found).size() == wanted.size() and found.all(func(id: Variant) -> bool: return wanted.has(id)) \
		and not str(data.get("id", "")).is_empty() and data.get("id") == data.get("bound_id")
	if exact: tree.set_meta("f48_boss_encounter", str(data.id))
	return _result(exact,
		"Actual host participant identities: " + str(found), data)

static func _watch_portal(tree: SceneTree) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	if game == null or not game.has_signal("portal_action_result"):
		return _result(false, "Actual portal result signal unavailable")
	tree.set_meta("f48_portal_results", [])
	if not tree.has_meta("f48_portal_observer"):
		var observer := func(result: Dictionary) -> void:
			var observed: Array = tree.get_meta("f48_portal_results", [])
			observed.append(result.duplicate(true))
			tree.set_meta("f48_portal_results", observed)
		game.connect("portal_action_result", observer)
		tree.set_meta("f48_portal_observer", observer)
	return _result(true, "Watching actual correlated portal replies; no producer mutation")

static func _path(value: Variant, path: String) -> Variant:
	for part: String in path.split("/"):
		if not value is Dictionary or not value.has(part): return null
		value = value[part]
	return value

## JSON IPC parses integral numbers as floats. Compare every field/key/item
## without rounding, coercing booleans/strings or accepting lossy large ints.
static func _json_equal(left: Variant, right: Variant) -> bool:
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _json_equal(left[key], right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for index: int in left.size():
			if not _json_equal(left[index], right[index]): return false
		return true
	if (left is int or left is float) and (right is int or right is float):
		if not is_finite(float(left)) or not is_finite(float(right)): return false
		if typeof(left) != typeof(right) and (abs(float(left)) > 9007199254740991.0 or abs(float(right)) > 9007199254740991.0): return false
		return left == right
	return typeof(left) == typeof(right) and left == right

## Read-only diagnostics: JSON's decimal rendering can conceal the very float
## mismatch under investigation. Preserve primitive Variant bytes as hex text.
## This does not change the exact comparison or its acceptance conditions.
static func _json_difference(left: Variant, right: Variant, path: String = "$") -> Dictionary:
	if _json_equal(left, right): return {}
	if left is Dictionary and right is Dictionary:
		for key: Variant in left:
			if not right.has(key): return {"path": path + "/" + str(key), "reason": "missing right key"}
			var difference := _json_difference(left[key], right[key], path + "/" + str(key))
			if not difference.is_empty(): return difference
		for key: Variant in right:
			if not left.has(key): return {"path": path + "/" + str(key), "reason": "extra right key"}
	if left is Array and right is Array:
		if left.size() != right.size(): return {"path": path, "reason": "array size", "left_size": left.size(), "right_size": right.size()}
		for index: int in left.size():
			var difference := _json_difference(left[index], right[index], path + "/" + str(index))
			if not difference.is_empty(): return difference
	return {"path": path, "left_type": type_string(typeof(left)), "right_type": type_string(typeof(right)),
		"left_variant_hex": var_to_bytes(left).hex_encode(), "right_variant_hex": var_to_bytes(right).hex_encode()}


static func _counts(payload: Dictionary) -> Dictionary:
	var out := {}
	for row: Variant in payload.get("inventory", []):
		if row is Dictionary:
			var id := str(row.get("id", ""))
			out[id] = int(out.get(id, 0)) + int(row.get("n", 0))
	return out

## Assertions added to the existing producer; never starts/resolves a fight.
## Capture identities before unbinding; exited retains the actual terminal result.
static func _check_master_duel(tree: SceneTree, now: Dictionary, wanted: Dictionary, errors: Array[String]) -> void:
	var game := tree.root.get_node_or_null(^"Game")
	var director := tree.current_scene.get_node_or_null(^"EncounterDirector") if tree.current_scene != null else null
	var manager := tree.current_scene.get_node_or_null(^"CombatManager") if tree.current_scene != null else null
	var id := str(wanted.get("master_id", ""))
	var uid := str(wanted.get("creature_uid", ""))
	if game == null or director == null or manager == null or preload("res://scripts/creatures/breakthrough.gd").master(id).is_empty():
		errors.append("Actual canonical Master composition unavailable")
		return
	var key := "f48_master_" + id
	if wanted.get("outcome") == "active":
		var record: Dictionary = director.call("encounter_record")
		var duel: Dictionary = director.get("_master_duel")
		var peer := int(game.session.call("local_peer_id"))
		var active: RefCounted = manager.call("active_creature")
		var participant: Dictionary = record.get("participants", {}).get(peer, {})
		if manager.call("is_fighting") != true or active == null or record.get("kind") != "trainer" \
			or record.get("phase") != "active" or record.get("opponent", {}).get("owner_npc") != id \
			or record.get("participants", {}).size() != 1 or participant.get("character_id") != now.character_id \
			or participant.get("creature_uid") != uid or active.get("uid") != uid or duel.get("creature_uid") != uid \
			or duel.get("character_id") != now.character_id or duel.get("master_id") != id \
			or duel.get("encounter_id") != manager.call("encounter_id") or duel.get("encounter_id") != record.get("encounter_id") \
			or not UIDS.uids(now.memory.get("party", [])).has(str(active.get("uid"))):
			errors.append("Master is not an actual 1v1 with this character's selected owned creature")
			return
		var previous: Dictionary = tree.get_meta(key, {})
		if wanted.get("retry") == true and (previous.get("outcome") != "lost" \
			or previous.get("encounter_id") == duel.encounter_id or previous.get("character_id") != now.character_id \
			or previous.get("world_namespace") != now.world_namespace or previous.get("session_epoch") != game.session.call("_altar_current_epoch")):
			errors.append("Retry lacks this character's actual earlier loss and a new encounter identity")
			return
		var observed := {"master_id": id, "encounter_id": str(duel.encounter_id), "character_id": str(now.character_id),
			"world_namespace": str(now.world_namespace), "session_epoch": str(game.session.call("_altar_current_epoch")),
			"creature_uid": str(active.get("uid")), "outcome": "", "record": record.duplicate(true)}
		tree.set_meta(key, observed)
		var observer := func(outcome: String) -> void: observed.outcome = outcome
		manager.connect("exited", observer, CONNECT_ONE_SHOT)
		now.master_duel = observed.duplicate(true)
	elif wanted.get("outcome") == "lost":
		var observed: Dictionary = tree.get_meta(key, {})
		if observed.get("outcome") != "lost" or observed.get("creature_uid") != uid or observed.get("character_id") != now.character_id \
			or observed.get("world_namespace") != now.world_namespace or observed.get("session_epoch") != game.session.call("_altar_current_epoch") \
			or manager.call("is_fighting") == true or director.call("trainer_battle_active") == true or not (director.get("_master_duel") as Dictionary).is_empty():
			errors.append("Actual original Master loss has not resolved and released its duel")
		now.master_duel = observed.duplicate(true)
	else:
		errors.append("Master assertion requires active or lost")

static func _assert(tree: SceneTree, args: Dictionary) -> Dictionary:
	var now := _observe(tree)
	if now.is_empty() or now.disk.is_empty(): return _result(false, "Actual durable character file unavailable", now)
	var errors: Array[String] = []
	if args.has("master_duel"): _check_master_duel(tree, now, args.master_duel, errors)
	if args.get("portal_enter") == true:
		var entered := false
		for result: Dictionary in tree.get_meta("f48_portal_results", []):
			if result.get("kind") == "portal_enter" and result.get("ok") == true \
					and result.get("character_id") == now.character_id and result.get("world_instance_id") == now.world_namespace \
					and not str(result.get("request_id", "")).is_empty(): entered = true
		if not entered: errors.append("No actual successful correlated portal-enter result")
	var prior: Dictionary = _remembered(tree, str(args.get("since", "")))
	if args.has("since") and prior.is_empty(): errors.append("Missing before witness")
	if not prior.is_empty():
		if now.character_id != prior.character_id or now.world_namespace != prior.world_namespace:
			errors.append("Stable character/world-instance identity changed")
	if args.get("behind_arrival") == true: _check_behind_arrival(tree, now, prior, errors)
	for payload: String in ["memory", "disk"]:
		var state: Dictionary = now[payload]
		var party: Array = UIDS.uids(state.get("party", []))
		if party.size() > 5 or party.size() != _unique(party).size(): errors.append(payload + ": duplicate UID or hidden sixth")
		for row: Variant in state.get("satchel_escrow", {}).values():
			if row is Dictionary and row.has("character_id") and row.character_id != now.character_id:
				errors.append(payload + ": foreign character receipt in portable file")
		for item: String in args.get("item_counts", {}):
			if _counts(state).get(item, 0) != args.item_counts[item]: errors.append(payload + ": wrong inventory count " + item)
		if args.has("creature"):
			var card := {}
			for member: Dictionary in state.get("party", []):
				if member.get("uid") == args.creature.uid: card = member
			if card.is_empty() or card.get("level") != args.creature.level:
				errors.append(payload + ": wrong expected level or missing original owned creature")
			var mirror: Dictionary = state.get("redesign_character", {}).get("creatures", {}).get(args.creature.uid, {})
			if not _json_equal(mirror.get("breakthroughs"), args.creature.breakthroughs):
				errors.append(payload + ": wrong exact breakthrough history")
		if args.has("released_uid"):
			if party.has(args.released_uid): errors.append(payload + ": released UID remains owned")
			if not prior.is_empty():
				var expected_uids := UIDS.uids(prior[payload].get("party", []))
				if not expected_uids.has(args.released_uid): errors.append(payload + ": release target was not owned before")
				expected_uids.erase(args.released_uid)
				if party != expected_uids: errors.append(payload + ": release replaced or lost another companion")
		for path: String in args.get("equals", {}):
			if not _json_equal(_path(state, path), args.equals[path]): errors.append(payload + ": wrong " + path)
		for path: String in args.get("contains", {}):
			var values: Variant = _path(state, path)
			if not values is Array or not values.has(args.contains[path]): errors.append(payload + ": missing " + path)
		for path: String in args.get("contains_all", {}):
			var values: Variant = _path(state, path)
			for wanted: Variant in args.contains_all[path]:
				if not values is Array or not values.has(wanted): errors.append(payload + ": missing " + path + "/" + str(wanted))
		for expected: Dictionary in args.get("receipt_counts", []):
			var receipt := str(expected.get("receipt", ""))
			var receipts: Array = state.get("redesign_character", {}).get("transaction_receipts", [])
			if receipt.is_empty() or receipts.count(receipt) != int(expected.get("count", -1)): errors.append(payload + ": wrong exact receipt count " + receipt)
		for path: String in args.get("lacks", {}):
			var values: Variant = _path(state, path)
			if not values is Array or values.has(args.lacks[path]): errors.append(payload + ": unearned or absent field " + path)
		if not prior.is_empty():
			var before: Dictionary = prior[payload]
			for path: String in args.get("unchanged", []):
				var same: bool = PASSIVE.matches(tree, str(args.get("since", "")), state.get("party")) if path == "party" and payload == "memory" and tree.get_meta("f48_producer_observation", false) == true \
					else _json_equal(_path(state, path), _path(before, path))
				if not same: errors.append(payload + ": replay changed " + path)
			var counts := _counts(state)
			var old_counts := _counts(before)
			for item: String in args.get("item_delta", {}):
				if int(counts.get(item, 0)) - int(old_counts.get(item, 0)) != int(args.item_delta[item]):
					errors.append(payload + ": wrong exact debit/output for " + item)
			for path: String in args.get("append_count", {}):
				var old: Variant = _path(before, path)
				var current: Variant = _path(state, path)
				if not old is Array or not current is Array:
					errors.append(payload + ": receipt carrier unavailable " + path)
				elif current.size() - old.size() != int(args.append_count[path]) or _unique(current).size() != current.size():
					errors.append(payload + ": wrong receipt count " + path)
				else:
					for receipt: Variant in old:
						if not current.has(receipt): errors.append(payload + ": lost receipt " + path)
		# Convergence is checked on transaction-bearing fields, not incidental pose/time.
	for path: String in ["inventory", "redesign_character", "satchel_escrow"]:
		if not _json_equal(_path(now.memory, path), _path(now.disk, path)): errors.append("Memory/disk disagree: " + path)
	if args.get("boss_rewards") == true:
		_check_boss(now, errors)
	if args.has("saved_transaction"):
		_check_saved_transaction(tree, now, prior, args, errors)
		now.saved_transaction_row = _transaction_row(now, str(args.saved_transaction)).duplicate(true)
	if args.has("host_transaction_row"):
		var expected: Dictionary = args.host_transaction_row
		var identity := str(expected.get("delivery_id", expected.get("receipt", "")))
		if not now.owns_world or now.disk_world.is_empty() or identity.is_empty() \
			or expected.get("character_id") == now.character_id or expected.get("status") != "accepted":
			errors.append("Actual guest transaction observation or host-owned file unavailable")
		else:
			for scope: String in ["world", "disk_world"]:
				if not _json_equal(now[scope].get("reward_deliveries", {}).get(identity), expected):
					errors.append(scope + ": host file changed/lost original guest saved transaction row")
	if args.has("participants"):
		_check_host_journal(now, args.participants, str(tree.get_meta("f48_boss_encounter", "")), errors)
	if args.get("guest_world_empty") == true:
		var admitted: Dictionary = _remembered(tree, "admitted")
		if now.owns_world or admitted.is_empty() or now.world_files != admitted.get("world_files"):
			errors.append("Guest wrote a host world file")
	now.passive_evidence = PASSIVE.evidence(tree, str(args.get("since", "")))
	return _result(errors.is_empty(), "Exact durable assertions: " + ("passed" if errors.is_empty() else "; ".join(errors)), now)

static func _unique(values: Array) -> Array:
	var result: Array = []
	for value: Variant in values:
		if not result.has(value): result.append(value)
	return result

static func _check_boss(now: Dictionary, errors: Array[String]) -> void:
	# Independent fixed Meadows hand-off expectations, deliberately not loaded
	# from chapter_rewards.json (a changed producer cannot change its oracle).
	for scope: String in ["memory", "disk"]:
		var state: Dictionary = now[scope]
		if _counts(state).get("tidewake_portal_key", 0) != 1: errors.append(scope + ": participant must own exactly one Tidewake key")
		if state.get("redesign_character", {}).get("relics_held", []).count("meadows") != 1:
			errors.append(scope + ": participant lacks personal Meadows relic")
		var receipt := "defeat:boss_warden_aldis_%s:%s" % [str(now.world_namespace).sha256_text(), str(now.character_id)]
		if state.get("redesign_character", {}).get("transaction_receipts", []).count(receipt) != 1:
			errors.append(scope + ": missing exactly one protected personal boss receipt")

static func _transaction_row(now: Dictionary, transaction: String) -> Dictionary:
	var identity := "portal_unlock:" + ("%s\n%s\n%s" % [now.world_namespace, "tidewake", now.character_id]).sha256_text() \
		if transaction == "key" else "creature_training:" + JSON.stringify([now.world_namespace, now.character_id]).sha256_text()
	var value: Variant = now.get("world", {}).get("reward_deliveries", {}).get(identity)
	return value if value is Dictionary else {}

static func _check_saved_transaction(tree: SceneTree, now: Dictionary, prior: Dictionary, args: Dictionary, errors: Array[String]) -> void:
	var transaction := str(args.saved_transaction)
	var actions := {"craft": "station_craft", "release": "trait_release", "feast": "feast_feed",
		"relic": "relic_hang", "essence_spend": "altar_spend", "master_chest": "master_chest"}
	var row := _transaction_row(now, transaction)
	var receipt := str(row.get("receipt", ""))
	if row.is_empty() or receipt.is_empty() or row.get("character_id") != now.character_id \
		or row.get("world_id") != now.world_id or row.get("status") != "accepted":
		errors.append("Original transaction lacks an accepted actual admitted journal"); return
	if transaction == "key":
		if row.get("kind") != "portal_unlock" or row.get("version") != 2 or row.get("biome") != "tidewake" \
			or row.get("world_instance_id") != now.world_namespace or row.get("item") != "tidewake_portal_key":
			errors.append("Wrong original Tidewake key journal")
	elif not actions.has(transaction) or row.get("kind") != "creature_training" \
		or RECORD_RULES.training_version(row) not in [1, 2, 3] or row.get("action") != actions.get(transaction) \
		or row.get("world_namespace") != now.world_namespace or str(row.get("session_id", "")).is_empty() \
		or row.get("after", {}).get("character_id") != now.character_id \
		or row.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).count(receipt) != 1:
		errors.append("Wrong original accepted personal transaction journal")
	if transaction == "master_chest":
		var master_id := str(args.get("master_id", ""))
		var edge: Dictionary = tree.get_meta("f48_latest_owner_save", {})
		if preload("res://scripts/creatures/breakthrough.gd").master(master_id).is_empty() \
			or receipt != "master_recipe:%s:%s" % [master_id, str(now.character_id)] \
			or row.get("intent") != {"master_id": master_id} or edge.get("identity") != row.get("delivery_id") \
			or edge.get("packet", {}).get("receipt") != receipt or edge.get("row", {}).get("action") != "master_chest":
			errors.append("Master chest lacks its exact actual owner BOOL-save edge and accepted ACK")
		# Existing exact full owner/world/transport/file/passive edge validator.
		# It refuses a pending ACK, another latest row or an unobserved save.
		errors.append_array(_snapshot_errors(tree, now))
	for scope: String in ["memory", "disk"]:
		if now[scope].get("redesign_character", {}).get("transaction_receipts", []).count(receipt) != 1:
			errors.append(scope + ": original saved transaction receipt missing or duplicated")
	if args.has("boundary_receipt") and (receipt != args.boundary_receipt \
		or (row.get("delivery_id", row.get("receipt")) != args.boundary_delivery_id)):
		errors.append("Admission replaced the original native-cut writer receipt/identity")
	if args.has("same_transaction_as"):
		var remembered: Dictionary = _remembered(tree, str(args.same_transaction_as))
		if remembered.is_empty() or not _json_equal(_transaction_row(remembered, transaction), row):
			errors.append("Reconnect changed the original accepted transaction or its full immutable intent")
	elif not prior.is_empty() and _transaction_row(prior, transaction).get("receipt") == receipt:
		errors.append("Expected one new original transaction, but journal already existed before input")

static func _check_host_journal(now: Dictionary, participants: Array, encounter: String, errors: Array[String]) -> void:
	if not now.owns_world or now.disk_world.is_empty():
		errors.append("Actual host world file unavailable")
		return
	if participants.size() < 2 or _unique(participants).size() != participants.size() or encounter.is_empty():
		errors.append("Distinct actual participants and observed live boss encounter required")
	for scope: String in ["world", "disk_world"]:
		var deliveries: Dictionary = now[scope].get("reward_deliveries", {})
		var event_matches := 0
		for raw: Variant in deliveries.values():
			if not raw is Dictionary or raw.get("kind") != "foundation_event" \
				or raw.get("source_id") != "boss:warden_aldis:" + encounter: continue
			if raw.get("version") != 1 or raw.get("status") != "retained" or raw.get("world_namespace") != now.world_namespace \
				or raw.get("world_id") != now.world_id or str(raw.get("session_id", "")).is_empty():
				errors.append(scope + ": malformed retained actual boss event"); continue
			var identity := "foundation_event:" + JSON.stringify([now.world_namespace, raw.session_id, raw.source_id]).sha256_text()
			if raw.get("delivery_id") != identity or not deliveries.has(identity) or deliveries[identity] != raw:
				errors.append(scope + ": retained boss event identity mismatch"); continue
			var duties: Variant = raw.get("duties")
			if not duties is Array or duties.size() != participants.size():
				errors.append(scope + ": retained event does not contain one duty per participant"); continue
			var found: Array = []
			for duty: Variant in duties:
				if not duty is Dictionary or duty.get("action") != "boss_relic" \
					or not participants.has(duty.get("character_id")) \
					or duty.get("intent") != {"trainer_id": "warden_aldis", "biome": "meadows", "encounter_id": encounter} \
					or duty.get("context", {}).get("source_key") != "boss:warden_aldis" \
					or duty.get("context", {}).get("validated_host_outcome") != "win" \
					or duty.get("context", {}).get("realm") != "meadows" \
					or duty.get("context", {}).get("encounter_id") != encounter \
					or not duty.get("context", {}).get("participants") is Array:
					errors.append(scope + ": boss duty is not bound to the observed outcome"); continue
				var bound: Array = duty.context.participants
				if bound.size() != participants.size() or _unique(bound).size() != bound.size() \
					or not bound.all(func(id: Variant) -> bool: return participants.has(id)):
					errors.append(scope + ": boss duty participant identity mismatch")
				found.append(duty.character_id)
			if found.size() != participants.size() or _unique(found).size() != found.size():
				errors.append(scope + ": missing or duplicated stable boss participant duty")
			event_matches += 1
		if event_matches != 1: errors.append(scope + ": exactly one retained observed boss outcome required")
		for character: String in participants:
			var id := "creature_training:" + JSON.stringify([now.world_namespace, character]).sha256_text()
			var row: Variant = deliveries.get(id)
			var receipt := "defeat:boss_warden_aldis_%s:%s" % [str(now.world_namespace).sha256_text(), character]
			# This carrier is overwritten by each later accepted action. Its full
			# portable after-state must preserve the original protected boss receipt.
			if not row is Dictionary or RECORD_RULES.training_version(row) not in [1, 2, 3] or row.get("kind") != "creature_training" or row.get("delivery_id") != id \
				or row.get("character_id") != character or row.get("world_namespace") != now.world_namespace \
				or row.get("world_id") != now.world_id or row.get("status") != "accepted" \
				or row.get("after", {}).get("character_id") != character \
				or row.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).count(receipt) != 1:
				errors.append(scope + ": missing durable accepted personal boss receipt " + character)

static func _check_behind_arrival(tree: SceneTree, now: Dictionary, prior: Dictionary, errors: Array[String]) -> void:
	if prior.is_empty(): errors.append("Behind arrival requires the admitted before witness"); return
	var permits: Array[String] = []
	for result: Dictionary in tree.get_meta("f48_portal_results", []):
		if result.get("kind") == "portal_enter" and result.get("ok") == true and result.get("saved") == true \
			and result.get("durable") == true and result.get("arrival_applied") == true \
			and result.get("character_id") == now.character_id and result.get("world_instance_id") == now.world_namespace \
			and not str(result.get("request_id", "")).is_empty() \
			and not str(result.get("permit_id", "")).is_empty(): permits.append(str(result.permit_id))
	if permits.size() != 1: errors.append("Exactly one real saved arrival permit result required"); return
	var receipt := "craft:portal_arrival_%s:%s" % [permits[0], now.character_id]
	for scope: String in ["memory", "disk"]:
		var before: Array = prior[scope].get("redesign_character", {}).get("transaction_receipts", [])
		var actual: Array = now[scope].get("redesign_character", {}).get("transaction_receipts", [])
		var expected := before.duplicate()
		if expected.has(receipt): errors.append(scope + ": arrival permit was already paid before travel")
		expected.append(receipt)
		if actual != expected: errors.append(scope + ": behind travel must append only its actual bound arrival receipt")

static func _files(path: String) -> Dictionary:
	var found := {}
	var dir := DirAccess.open(path)
	if dir == null: return found
	for file: String in dir.get_files(): found[path.path_join(file)] = _digest(path.path_join(file))
	for sub: String in dir.get_directories():
		found.merge(_files(path.path_join(sub)))
	return found

static func _require(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	if game == null: return _result(false, "Missing Game owner")
	var missing: Array[String] = []
	for request: Dictionary in args.get("nodes", []):
		var node := tree.root.get_node_or_null(NodePath(str(request.path)))
		if node == null:
			missing.append(str(request.path))
			continue
		for method: String in request.get("methods", []):
			if not node.has_method(method): missing.append(str(request.path) + "::" + method)
	for request: Dictionary in args.get("flags", []):
		var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(request.file)))
		if _path(config, str(request.path)) != true: missing.append(str(request.file) + "/" + str(request.path))
	return _result(missing.is_empty(), "Actual producer prerequisite: " + ("present" if missing.is_empty() else ", ".join(missing)))

static func _require_configuration(args: Dictionary) -> Dictionary:
	var files: Variant = args.get("files")
	var expected := ["res://data/config/stations.json", "res://data/config/essence.json"]
	var scope: Variant = args.get("scope", "bootstrap")
	if scope == "full":
		expected.append_array(["res://data/config/traits.json", "res://data/config/multiplayer.json", "res://data/config/hud.json", "res://data/config/alpha_respawns.json"])
	elif scope != "bootstrap": return _result(false, "Unknown disclosed mechanics configuration scope")
	if not files is Array or files.size() != expected.size(): return _result(false, "Pinned disclosed mechanics configuration missing")
	var evidence: Array = []
	for row: Variant in files:
		if not row is Dictionary or not expected.has(row.get("file")): return _result(false, "Unknown or duplicated mechanics configuration file")
		expected.erase(row.file)
		if str(row.get("sha256", "")).length() != 64 or not FileAccess.file_exists(row.file) or FileAccess.get_sha256(row.file) != row.sha256:
			return _result(false, "Effective native configuration differs from the disclosed overlay: " + str(row.file))
		evidence.append({"file": row.file, "sha256": row.sha256})
	return _result(expected.is_empty(), "Exact effective test configuration pinned separately; production defaults unchanged", {"files": evidence})


static func _build_cell(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Read the actual visible catalogue-to-button mapping. Only focus changes;
	# ui_accept reaches the shipping grid callback and ordinary ghost placement.
	var menus := tree.get_nodes_in_group("build_menu")
	if menus.size() != 1: return _result(false, "Need exactly one actual open build menu")
	var menu: Node = menus[0]
	var script: Script = menu.get_script()
	if script == null or script.resource_path != "res://scripts/ui/build_menu.gd" \
		or menu.call("is_open") != true: return _result(false, "Actual open build menu unavailable")
	var pieces: Array = menu.call("_current_pieces")
	var buttons: Variant = menu.get("_cell_buttons")
	if not buttons is Array or buttons.size() != pieces.size(): return _result(false, "Actual displayed build grid mapping unavailable")
	var matches: Array[Button] = []
	for index: int in pieces.size():
		if pieces[index] is Dictionary and pieces[index].get("id") == args.get("id"):
			var button: Variant = buttons[index]
			if button is Button and button.is_visible_in_tree() and not button.disabled: matches.append(button)
	if matches.size() != 1: return _result(false, "Need exactly one actual visible enabled build cell")
	matches[0].grab_focus()
	await tree.process_frame
	return await tree.call("_step_press", {"action": "ui_accept", "tap_frames": 2})


static func _watch_altar_save(tree: SceneTree) -> Dictionary:
	# Producer-only read observer. No save, ACK, party write or fake settlement.
	var game := tree.root.get_node_or_null(^"Game")
	var writer := tree.root.get_node_or_null(^"Game/Session/LedgerRpc")
	if game == null or writer == null or not writer.has_signal("transaction_boundary") \
		or game.call("is_host") != true or tree.has_meta("f48_altar_save_watch"):
		return _result(false, "Actual owning host writer required for paid Altar save observer")
	var world_ref: WeakRef = weakref(game.world)
	var character := str(game.local.character_id)
	var namespace_id := str(game.world.reward_delivery_namespace)
	var epoch := str(game.session.call("_altar_current_epoch"))
	var journal_epoch := str(writer.get("_actor_vitals_session_id"))
	var authority := _owner_transport(game, writer)
	var output := OS.get_environment("TB_PROOF_OUT")
	if character.is_empty() or namespace_id.is_empty() or epoch.is_empty() or journal_epoch.is_empty() or authority.is_empty() or output.is_empty():
		return _result(false, "Actual owner/world/session/output required")
	var prior_receipts: Array = game.local.save_data().redesign_character.transaction_receipts.duplicate()
	tree.set_meta("f48_altar_save_edges", {})
	var observer := func(observation: Dictionary) -> void:
		var callback_started := COMMIT_TRACE.begin("proof.altar.callback")
		var identity_started := COMMIT_TRACE.begin("proof.altar.identity")
		var phase := str(observation.get("phase", ""))
		if phase not in ["after_host_write_before_delivery", "after_owner_write_before_ack"] \
			or observation.get("kind") != "altar_building" or observation.get("action") != "place_building" \
			or observation.get("character_id") != character or observation.get("world_namespace") != namespace_id \
			or observation.get("session_id") != journal_epoch or game.world != world_ref.get_ref() \
			or game.local.character_id != character or not _owner_transport_matches(game, writer, authority) \
			or writer.get("_actor_vitals_session_id") != journal_epoch:
			COMMIT_TRACE.end("proof.altar.identity", identity_started, "refused")
			COMMIT_TRACE.end("proof.altar.callback", callback_started, "refused")
			return
		COMMIT_TRACE.end("proof.altar.identity", identity_started, "passed")
		var row: Variant = game.world.reward_deliveries.get(observation.get("delivery_id"))
		var validation_started := COMMIT_TRACE.begin("proof.altar.row_validation")
		if not WORLD_STATE.altar_build_row_valid(row, namespace_id, str(game.world.world_id)) \
			or row.get("receipt") != observation.get("receipt") or row.get("character_id") != character \
			or not _boundary_epochs_match(observation, row, journal_epoch, epoch, str(game.session.call("_altar_current_epoch"))) \
			or prior_receipts.has(row.get("receipt")):
			COMMIT_TRACE.end("proof.altar.row_validation", validation_started, "refused")
			COMMIT_TRACE.end("proof.altar.callback", callback_started, "refused")
			return
		COMMIT_TRACE.end("proof.altar.row_validation", validation_started, "passed")
		var edges: Dictionary = tree.get_meta("f48_altar_save_edges", {})
		if edges.has(phase):
			COMMIT_TRACE.end("proof.altar.callback", callback_started, "duplicate")
			return
		if edges.has("after_host_write_before_delivery") \
			and edges.after_host_write_before_delivery.row.delivery_id != row.delivery_id:
			COMMIT_TRACE.end("proof.altar.callback", callback_started, "identity_changed")
			return
		var observe_started := COMMIT_TRACE.begin("proof.altar.full_observe")
		var evidence := {"phase": phase, "observation": observation.duplicate(true), "row": row.duplicate(true),
			"files": _observe(tree), "observer_pid": OS.get_process_id(), "session_epoch": epoch, "journal_epoch": journal_epoch}
		COMMIT_TRACE.end("proof.altar.full_observe", observe_started)
		var dir := output.path_join("f48-altar-save-edges").path_join(character)
		DirAccess.make_dir_recursive_absolute(dir)
		var path := dir.path_join(phase + ".json")
		var publish_started := COMMIT_TRACE.begin("proof.altar.publish")
		if not DETACHED.publish(path, evidence):
			COMMIT_TRACE.end("proof.altar.publish", publish_started, "refused")
			COMMIT_TRACE.end("proof.altar.callback", callback_started, "refused")
			return
		COMMIT_TRACE.end("proof.altar.publish", publish_started)
		evidence.path = path
		evidence.sha256 = _digest(path)
		edges[phase] = evidence
		tree.set_meta("f48_altar_save_edges", edges)
		COMMIT_TRACE.end("proof.altar.callback", callback_started, "published")
	writer.connect("transaction_boundary", observer)
	tree.set_meta("f48_altar_save_watch", observer)
	return _result(true, "Read-only exact host/owner save edges armed before original paid build input")


static func _assert_altar_build(tree: SceneTree, args: Dictionary) -> Dictionary:
	var now := _observe(tree)
	var prior: Dictionary = _remembered(tree, str(args.get("since", "")))
	if now.is_empty() or prior.is_empty() or now.get("owns_world") != true \
		or now.get("character_id") != prior.get("character_id") or now.get("world_namespace") != prior.get("world_namespace"):
		return _result(false, "Actual owning host and original admitted witness required")
	var rows: Array[Dictionary] = []
	var previous: Dictionary = prior.world.get("reward_deliveries", {})
	for id: String in now.world.get("reward_deliveries", {}):
		var value: Variant = now.world.reward_deliveries[id]
		if value is Dictionary and value.get("kind") == "altar_building" and not previous.has(id): rows.append(value)
	if rows.size() != 1: return _result(false, "Need exactly one new real paid Altar journal", now)
	var row: Dictionary = rows[0]
	var intent: Variant = row.get("intent")
	if not intent is Dictionary or not intent.get("record") is Dictionary or not intent.get("request") is Dictionary:
		return _result(false, "Real Altar transaction intent unavailable", now)
	if not WORLD_STATE.altar_build_row_valid(row, str(now.world_namespace), str(now.world_id)):
		return _result(false, "Actual complete paid Altar journal schema invalid", {"row": row, "observation": now})
	var record: Dictionary = intent.record
	var txn := str(row.get("action_id", ""))
	var id := "altar_building:" + JSON.stringify([now.world_namespace, now.character_id, txn]).sha256_text()
	var receipt := "craft:%s:altar_build:%s:%s:place_building:%s" % [now.character_id, str(now.world_namespace).sha256_text(), txn, record.get("uid", "")]
	var cost := [{"id": "stone", "n": 10}, {"id": "rootstone", "n": 4}, {"id": "ironwood", "n": 2}]
	var errors: Array[String] = []
	if txn.is_empty() or row.get("version") != 1 or row.get("action") != "place_building" or row.get("status") != "accepted" \
		or row.get("delivery_id") != id or row.get("receipt") != receipt or row.get("character_id") != now.character_id \
		or row.get("world_id") != now.world_id or row.get("world_namespace") != now.world_namespace \
		or intent.request.get("txn_id") != txn or intent.request.get("kind") != "place_building" or intent.request.get("id") != "altar" \
		or intent.request.get("realm") != "meadows" or intent.request.get("paid") != true or not _json_equal(intent.get("cost"), cost):
		errors.append("Wrong original accepted Altar transaction identity/receipt/price")
	if record.size() != 6 or not record.get("paid") is bool or record.get("id") != "altar" or record.get("realm") != "meadows" or record.get("paid") != true \
		or not record.get("uid") is String or not str(record.uid).begins_with("b") or not record.get("position") is Array \
		or not _json_equal(intent.request.get("position"), record.get("position")) or not _json_equal(intent.request.get("yaw_deg"), record.get("yaw_deg")):
		errors.append("Wrong actual paid world-building record")
	var uid := str(record.get("uid", ""))
	var position: Variant = record.get("position")
	if uid.length() < 2 or not uid.substr(1).is_valid_int() or int(uid.substr(1)) < 1 or uid != "b%d" % int(uid.substr(1)):
		errors.append("Missing actual canonical built UID")
	if not position is Array or position.size() != 3:
		errors.append("Missing actual finite build position")
	else:
		for coordinate: Variant in position:
			if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)): errors.append("Nonfinite actual build position")
	var yaw: Variant = record.get("yaw_deg")
	if not (yaw is int or yaw is float) or not is_finite(float(yaw)): errors.append("Nonfinite actual build yaw")
	var edges: Dictionary = tree.get_meta("f48_altar_save_edges", {})
	var host_edge: Dictionary = edges.get("after_host_write_before_delivery", {})
	var owner_edge: Dictionary = edges.get("after_owner_write_before_ack", {})
	if host_edge.is_empty() or owner_edge.is_empty():
		errors.append("Original authenticated before-delivery and owner BOOL-save edges missing")
	else:
		for edge: Dictionary in [host_edge, owner_edge]:
			var pending: Dictionary = edge.row.duplicate(true)
			var accepted: Dictionary = row.duplicate(true)
			# The real ACK changes only status; preserve every other full row field.
			pending.erase("status")
			accepted.erase("status")
			if edge.row.get("status") != "pending" or not _json_equal(pending, accepted) \
				or _digest(str(edge.path)) != edge.sha256:
				errors.append("Exact immutable original saved row/edge artifact changed")
		var host_party: Variant = host_edge.files.memory.get("party")
		if host_party is Array: host_party = host_party.map(RECORD_RULES.portable_card)
		var host_before := {"inventory": host_edge.files.memory.get("inventory"), "party": host_party,
			"redesign_character": host_edge.files.memory.get("redesign_character")}
		if not _json_equal(row.get("before"), host_before):
			errors.append("Full original before carrier differs from actual host writer edge")
		for scope: String in ["memory", "disk"]:
			var saved: Dictionary = owner_edge.files[scope]
			var owner_party: Variant = saved.get("party")
			if owner_party is Array: owner_party = owner_party.map(RECORD_RULES.portable_card)
			var projection := {"inventory": saved.get("inventory"), "party": owner_party, "redesign_character": saved.get("redesign_character")}
			if not _json_equal(row.get("after"), projection):
				errors.append(scope + ": full original after carrier differs at actual owner BOOL-save edge")
	if not row.get("before") is Dictionary or not row.get("after") is Dictionary \
		or not _json_equal(row.before.get("party"), row.after.get("party")):
		errors.append("Paid transaction changed a full original owned party/card field")
	var expected_counts := _counts(prior.memory)
	for need: Dictionary in cost: expected_counts[need.id] = int(expected_counts.get(need.id, 0)) - int(need.n)
	var personal: Dictionary = prior.memory.redesign_character.duplicate(true)
	if personal.transaction_receipts.has(receipt): errors.append("Original build receipt existed before input")
	personal.transaction_receipts.append(receipt)
	for scope: String in ["memory", "disk"]:
		var state: Dictionary = now[scope]
		var counts := _counts(state)
		for item: String in _unique(expected_counts.keys() + counts.keys()):
			if int(counts.get(item, 0)) != int(expected_counts.get(item, 0)): errors.append(scope + ": wrong exact item debit " + item)
		if not _json_equal(state.get("redesign_character"), personal) \
			or not _json_equal(state.get("satchel_escrow"), prior.memory.get("satchel_escrow")):
			errors.append(scope + ": paid build changed progression/escrow or did not persist exactly one receipt")
		# Disk must still hold the original complete saved row. Live care resumes
		# later; its full values remain in now and the sealed owner-edge evidence.
		if scope == "disk":
			var disk_party: Variant = state.get("party")
			if disk_party is Array: disk_party = disk_party.map(RECORD_RULES.portable_card)
			var projection := {"inventory": state.get("inventory"), "party": disk_party, "redesign_character": state.get("redesign_character")}
			if not _json_equal(row.get("after"), projection): errors.append("Latest disk differs from complete authenticated after carrier")
	if not _json_equal(row.before.get("inventory"), prior.memory.get("inventory")) \
		or not _json_equal(row.before.get("redesign_character"), prior.memory.get("redesign_character")):
		errors.append("Original inventory/progression before carrier differs from admitted source")
	for world: String in ["world", "disk_world"]:
		var carrier: Dictionary = now[world]
		if not _json_equal(carrier.get("reward_deliveries", {}).get(id), row): errors.append(world + ": accepted journal absent or changed")
		var found := 0
		for building: Variant in carrier.get("placed_buildings", []):
			if _json_equal(building, record): found += 1
		if found != 1: errors.append(world + ": exact paid Altar record absent or duplicated")
	var differences := {}
	if not errors.is_empty():
		var edge_disk: Dictionary = owner_edge.get("files", {}).get("disk", {})
		for label: String in ["owner_edge_disk", "latest_disk"]:
			var saved: Dictionary = edge_disk if label == "owner_edge_disk" else now.disk
			var diagnostic_party: Variant = saved.get("party")
			if diagnostic_party is Array: diagnostic_party = diagnostic_party.map(RECORD_RULES.portable_card)
			var projection := {"inventory": saved.get("inventory"), "party": diagnostic_party, "redesign_character": saved.get("redesign_character")}
			differences[label] = _json_difference(row.get("after"), projection)
		differences["disk_journal"] = _json_difference(row, now.disk_world.get("reward_deliveries", {}).get(id))
		for building: Variant in now.disk_world.get("placed_buildings", []):
			if building is Dictionary and building.get("uid") == uid:
				differences["disk_building"] = _json_difference(record, building)
	return _result(errors.is_empty(), "Actual paid Altar bootstrap; no earned campaign credit. " + "; ".join(errors),
		{"row": row, "observation": now, "save_edges": edges, "exact_differences": differences})


static func _button(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Focus is harness input setup. Press goes through real InputEvent delivery;
	# no Button.pressed.emit(), no private _cook/_feed/submit adapters.
	var matches: Array[Button] = []
	var text := str(args.get("text", ""))
	var master_uid := str(args.get("master_creature_uid", ""))
	var census_root: Node = tree.root
	if args.has("master_creature_uid"):
		var chooser: Node = INPUT_OWNER.current(tree)
		var game := tree.root.get_node_or_null(^"Game")
		var local: RefCounted = game.get("local") if game != null else null
		if args.has("text") or args.has("feast_recipe") \
				or not preload("res://scripts/creatures/creature_instance.gd").valid_uid(master_uid) \
				or chooser == null or chooser.get_script() != preload("res://scripts/masters/breakthrough_panel.gd") \
				or chooser.get("_mode") != "duel" or local == null:
			return _result(false, "Master UID input requires the actual owned duel chooser")
		var source: Node = chooser.get("_source")
		var service: Node = chooser.get("_service")
		if not is_instance_valid(source) or source.get_script() != preload("res://scripts/masters/master_site.gd") \
				or source.get("_mounted") != true or source.get("master_id") != chooser.get("_master") \
				or not is_instance_valid(service) or service.get_script() != preload("res://scripts/masters/breakthrough_service.gd") \
				or service.get("_panel") != chooser or source.get_meta("breakthrough_service", null) != service:
			return _result(false, "Master UID input requires its actual mounted site and service")
		var view: Dictionary = service.call("view")
		var owned := 0
		for card: Dictionary in view.get("party", []):
			if card.get("uid") == master_uid and card.get("fainted") == false \
					and card.get("resting") == false and float(card.get("hp", 0)) > 0: owned += 1
		if view.get("character_id") != local.get("character_id") or owned != 1:
			return _result(false, "Master UID input requires one conscious companion of the actual character")
		census_root = chooser
	elif args.has("feast_recipe"):
		if args.get("feast_recipe") != "feast_t1_ground" or args.has("text"):
			return _result(false, "Only exact original ground feast recipe label may be resolved")
		var recipes: Dictionary = preload("res://scripts/creatures/breakthrough.gd").feasts().get("recipes", {})
		var recipe: Dictionary = recipes.get("feast_t1_ground", {})
		if recipe.is_empty(): return _result(false, "Actual ground feast recipe missing")
		# Same visible shipping label construction, without assuming a cross-
		# platform Dictionary number rendering; input still presses real button.
		text = str(recipe.name) + " · " + str(recipe.cost)
	_collect_buttons(census_root, text, matches, master_uid)
	if matches.size() != 1:
		var failure: Dictionary = _result(false, "Need exactly one visible enabled button: " + str(args.get("text", "")))
		var snapshot: Dictionary = _button_failure_snapshot(tree, text, matches)
		failure["data"] = snapshot
		var output: String = OS.get_environment("TB_PROOF_OUT")
		if not output.is_empty():
			var folder: String = output.path_join("f48-observations")
			var directory_error: int = DirAccess.make_dir_recursive_absolute(folder)
			var path: String = folder.path_join("f48_button-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
			var published: bool = directory_error == OK and DETACHED.publish(path, {"action": "f48_button", "args": args, "result": failure})
			snapshot["diagnostic_path"] = path if published else ""
			snapshot["diagnostic_published"] = published
		else:
			snapshot["diagnostic_path"] = ""
			snapshot["diagnostic_published"] = false
		return failure
	var owner: Node = INPUT_OWNER.current(tree)
	var forge_refine: bool = owner != null and owner.get_script() == preload("res://scripts/ui/craft_panel.gd") \
		and str(matches[0].get_meta("station_focus_key", "")).begins_with("refine:")
	if not forge_refine:
		matches[0].grab_focus()
		await tree.process_frame
		return await tree.call("_step_press", {"action": "ui_accept", "tap_frames": 2})
	# Let already deferred presentation/focus finish, then select the actual
	# current button immediately before the ordinary physical down event.
	# The same one process-frame wait is retained; no retry or extra budget.
	await tree.process_frame
	matches.clear()
	_collect_buttons(tree.root, text, matches)
	if matches.size() != 1 or INPUT_OWNER.current(tree) != owner \
		or not str(matches[0].get_meta("station_focus_key", "")).begins_with("refine:"):
		return _result(false, "Original Forge button changed before physical confirmation")
	var target: Button = matches[0]
	var target_path: String = str(target.get_path())
	var target_id: int = target.get_instance_id()
	var activated: ButtonActivationObservation = ButtonActivationObservation.new()
	var callback: Callable = activated.note_pressed
	target.pressed.connect(callback)
	target.grab_focus()
	var focus_before: Control = tree.root.get_viewport().gui_get_focus_owner()
	var focused_target: bool = focus_before == target
	var input: Dictionary = await tree.call("_step_press", {"action": "ui_accept", "tap_frames": 2})
	if is_instance_valid(target) and target.is_connected("pressed", callback):
		target.disconnect("pressed", callback)
	var panel_press: Variant = tree.get("_last_panel_press_observation")
	var data: Dictionary = {"requested_text": text, "target_path": target_path,
		"target_instance_id": target_id, "focused_actual_target_before_down": focused_target,
		"actual_pressed_count": activated.count, "input_result": input.duplicate(true),
		"panel_press": panel_press.duplicate(true) if panel_press is Dictionary else {}}
	var ok: bool = input.get("verdict") == "PASS" and focused_target and activated.count == 1
	var result: Dictionary = _result(ok, "Actual Forge button activation count=" + str(activated.count), data)
	var output: String = OS.get_environment("TB_PROOF_OUT")
	if not output.is_empty():
		var folder: String = output.path_join("f48-observations")
		var path: String = folder.path_join("f48_button_activation-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
		if DirAccess.make_dir_recursive_absolute(folder) != OK \
			or not DETACHED.publish(path, {"action": "f48_button", "args": args, "result": result}):
			return _result(false, "Could not preserve actual Forge button activation")
	return result

static func _button_failure_snapshot(tree: SceneTree, text: String, matches: Array[Button]) -> Dictionary:
	# Read existing presentation only. No quote, admission, refresh or input.
	var owner: Node = INPUT_OWNER.current(tree)
	var probe: Object = tree.get("_probe") as Object
	var owner_script: Script = owner.get_script() as Script if owner != null else null
	var data: Dictionary = {"requested_text": text, "exact_enabled_match_count": matches.size(),
		"exact_enabled_match_paths": [], "exact_match_paths_truncated": matches.size() > 32,
		"context": str(probe.call("input_context")) if probe != null else "missing_probe",
		"owner_path": str(owner.get_path()) if owner != null else "",
		"owner_script": owner_script.resource_path if owner_script != null else ""}
	for index: int in mini(matches.size(), 32):
		data.exact_enabled_match_paths.append(str(matches[index].get_path()))
	if owner_script == preload("res://scripts/ui/craft_panel.gd"):
		var station_value: Variant = owner.get("_station")
		var station: Node = station_value as Node if is_instance_valid(station_value) and station_value is Node else null
		var station_script: Script = station.get_script() as Script if is_instance_valid(station) else null
		var cache: Variant = owner.get("_presented_station_view")
		var intent: Variant = owner.get("_station_intent")
		var revision: Variant = cache.get("registry_revision") if cache is Dictionary else null
		data["craft_panel"] = {"open": owner.get("_open"), "station_mode": owner.get("_station_mode"),
			"station_path": str(station.get_path()) if is_instance_valid(station) and station.is_inside_tree() else "",
			"station_inside_tree": is_instance_valid(station) and station.is_inside_tree(),
			"station_script": station_script.resource_path if station_script != null else "",
			"building_id": str(station.get_meta("building_id", "")) if is_instance_valid(station) else "",
			"building_uid": str(station.get_meta("building_uid", "")) if is_instance_valid(station) else "",
			"presented_registry_revision": revision if revision is int or revision is float else null,
			"presented_registry_revision_type": typeof(revision),
			"pending_intent": not intent.is_empty() if intent is Dictionary else null}
	elif owner_script == preload("res://scripts/ui/altar_panel.gd"):
		var quote: Variant = owner.get("_quote")
		var revision: Variant = quote.get("expected_character_revision") if quote is Dictionary else null
		data["altar_panel"] = {"open": owner.get("_open"), "closing": owner.get("_closing"),
			"station_key": str(owner.get("_station_key")), "creature_uid": str(owner.get("_creature_uid")),
			"quote_code": str(owner.get("_quote_code")), "quote_waiting": owner.get("_quote_waiting"),
			"quote_ok": quote.get("ok") == true if quote is Dictionary else false,
			"quoted_revision": revision if revision is int or revision is float else null,
			"pending_id": str(owner.get("_pending_id")), "pending_durable": owner.get("_pending_durable")}
	var census_root: Node = owner if owner != null else tree.root
	var stack: Array[Node] = [census_root]
	var buttons: Array[Dictionary] = []
	var visited: int = 0
	var truncated: bool = false
	while not stack.is_empty() and visited < 4096 and buttons.size() < 128:
		var node: Node = stack.pop_back()
		visited += 1
		if node is Button:
			var button: Button = node as Button
			buttons.append({"path": str(button.get_path()), "text": button.text.substr(0, 512),
				"text_truncated": button.text.length() > 512,
				"visible_in_tree": button.is_visible_in_tree(), "disabled": button.disabled,
				"exact_text": button.text == text})
		for child: Node in node.get_children():
			if stack.size() >= 4096:
				truncated = true
				break
			stack.append(child)
	data["button_census"] = {"root_path": str(census_root.get_path()), "buttons": buttons,
		"button_count": buttons.size(), "nodes_visited": visited, "node_limit": 4096, "button_limit": 128,
		"truncated": truncated or not stack.is_empty()}
	return data

static func _choice(tree: SceneTree, args: Dictionary) -> Dictionary:
	# The actual owned UID is read from a visible shipping OptionButton's item
	# metadata. Selection is delivered through its ordinary popup controller
	# events, never OptionButton.select(), item_selected.emit() or trait submit.
	var uid: Variant = args.get("uid")
	if not uid is String or uid.is_empty(): return _result(false, "Original owned choice UID missing")
	var choices: Array[OptionButton] = []
	_collect_choices(tree.root, uid, choices)
	if choices.size() != 1: return _result(false, "Need exactly one visible enabled actual UID choice: " + uid)
	var choice: OptionButton = choices[0]
	var target := -1
	for index: int in choice.item_count:
		if choice.get_item_metadata(index) == uid:
			if target >= 0 or choice.is_item_disabled(index): return _result(false, "Duplicate or disabled original UID choice")
			target = index
	if target < 0 or choice.item_count > 128: return _result(false, "Missing or unbounded original UID choices")
	choice.grab_focus()
	await tree.process_frame
	var opened: Dictionary = await tree.call("_step_press", {"action": "ui_accept", "tap_frames": 2})
	if opened.get("verdict") != "PASS": return opened
	var popup: PopupMenu = choice.get_popup()
	if not is_instance_valid(popup) or not popup.visible: return _result(false, "Ordinary controller input did not open actual choice popup")
	for _attempt: int in choice.item_count + 1:
		if popup.get_focused_item() == target:
			var selected: Dictionary = await tree.call("_step_press", {"action": "ui_accept", "tap_frames": 2})
			if selected.get("verdict") != "PASS": return selected
			return _result(is_instance_valid(choice) and choice.selected == target and choice.get_item_metadata(choice.selected) == uid,
				"Ordinary popup input selected original owned UID", {"uid": uid, "index": target})
		var moved: Dictionary = await tree.call("_step_press", {"action": "ui_down", "tap_frames": 2})
		if moved.get("verdict") != "PASS": return moved
	return _result(false, "Ordinary popup input did not reach original owned UID")

static func _collect_choices(node: Node, uid: String, choices: Array[OptionButton]) -> void:
	if node is OptionButton and node.is_visible_in_tree() and not node.disabled:
		for index: int in node.item_count:
			if node.get_item_metadata(index) == uid:
				choices.append(node)
				break
	for child: Node in node.get_children(): _collect_choices(child, uid, choices)

static func _collect_buttons(node: Node, text: String, matches: Array[Button], master_uid: String = "") -> void:
	if node is Button and node.is_visible_in_tree() and not node.disabled:
		if (node.get_meta("master_challenger_uid", "") == master_uid if not master_uid.is_empty() else node.text == text):
			matches.append(node)
	for child: Node in node.get_children(): _collect_buttons(child, text, matches, master_uid)
