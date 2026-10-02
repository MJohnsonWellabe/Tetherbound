extends RefCounted

## Read-only F48 witnesses and ordinary input. Never saves during observation:
## an observation must not repair a missing durable write before asserting it.
## All receipt records below are read from production files, never constructed.
const UIDS := preload("res://scripts/data/redesign_state.gd")
const ATOMIC := preload("res://scripts/save/atomic_save_file.gd")
const DETACHED := preload("res://tools/net/f48_detached_file.gd")

static func step(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"f48_witness": return _witness(tree, args)
		"f48_assert": return _assert(tree, args)
		"f48_assert_snapshot": return _assert_snapshot(tree)
		"f48_button": return await _button(tree, args)
		"f48_choice": return await _choice(tree, args)
		"f48_build_cell": return await _build_cell(tree, args)
		"f48_assert_altar_build": return _assert_altar_build(tree, args)
		"f48_require_configuration": return _require_configuration(args)
		"f48_require": return _require(tree, args)
		"f48_restore_witness": return _restore_witness(tree, args)
		"f48_participants": return await _participants(tree, args)
		"f48_watch_portal": return _watch_portal(tree)
		"f48_arm_boundary": return _arm_boundary(tree, args)
		"f48_start_case": return _start_case(tree, args)
	return _result(false, "Unknown F48 action: " + action)

static func _start_case(tree: SceneTree, args: Dictionary) -> Dictionary:
	var case_id := str(args.get("case", ""))
	if case_id.is_empty() or case_id != case_id.validate_filename(): return _result(false, "Invalid independent matrix case identity")
	var game := tree.root.get_node_or_null(^"Game")
	if game == null or game.session == null or game.session.call("is_active"):
		return _result(false, "Original saved inputs can be restored only outside a session")
	var observer: Variant = tree.get_meta("f48_boundary_armed", null)
	var writer := tree.root.get_node_or_null(^"Game/Session/LedgerRpc")
	if observer is Callable and writer != null and writer.is_connected("transaction_boundary", observer):
		writer.disconnect("transaction_boundary", observer)
	for key: StringName in tree.get_meta_list():
		if str(key).begins_with("f48_witness_") or str(key) in ["f48_boundary_armed", "f48_boundary_fired", "f48_boss_encounter"]:
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

static func _assert_snapshot(tree: SceneTree) -> Dictionary:
	# capture_saves performs a disclosed autosave. Establish the existing
	# durable transaction carriers FIRST so it cannot repair a failed proof.
	var now := _observe(tree)
	if now.is_empty() or now.disk.is_empty(): return _result(false, "Actual prior durable owner file unavailable")
	for field: String in ["inventory", "party", "redesign_character", "satchel_escrow"]:
		if not _json_equal(now.memory.get(field), now.disk.get(field)):
			return _result(false, "Snapshot would repair unsaved owner carrier: " + field, now)
	if now.owns_world:
		if now.disk_world.is_empty(): return _result(false, "Actual prior durable host world unavailable", now)
		for field: String in ["reward_deliveries", "placed_buildings", "redesign_world"]:
			if not _json_equal(now.world.get(field), now.disk_world.get(field)):
				return _result(false, "Snapshot would repair unsaved host carrier: " + field, now)
	return _result(true, "Original complete transaction carriers already durable before disclosed capture", now)

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
	var game := tree.root.get_node_or_null(^"Game")
	if game == null: return {}
	var local: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	if local == null or world == null or saver == null or str(local.character_id).is_empty(): return {}
	var characters: RefCounted = saver.call("characters")
	var worlds: RefCounted = saver.call("worlds")
	var disk: Dictionary = characters.call("read", str(local.character_id))
	var owns_world := bool(game.call("world_save_owned"))
	var disk_world: Dictionary = worlds.call("read", str(world.world_id)) if owns_world else {}
	var memory: Dictionary = local.call("save_data")
	var character_path := ATOMIC.readable_path(str(characters.call("path_for", str(local.character_id))))
	var world_path := ATOMIC.readable_path(str(worlds.call("path_for", str(world.world_id))))
	return {"character_id": str(local.character_id), "world_id": str(world.world_id),
		"world_namespace": str(world.reward_delivery_namespace), "realm": str(local.realm),
		"memory": memory, "disk": disk, "world": world.call("save_data"), "disk_world": disk_world,
		"owns_world": owns_world, "character_path": character_path, "world_path": world_path,
		"character_sha256": _digest(character_path), "world_sha256": _digest(world_path),
		"world_files": _files(OS.get_user_data_dir().path_join("worlds"))}

static func _digest(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

static func _witness(tree: SceneTree, args: Dictionary) -> Dictionary:
	var data := _observe(tree)
	if data.is_empty() or data.disk.is_empty(): return _result(false, "Actual durable character file unavailable", data)
	var label := str(args.get("remember", ""))
	if not label.is_empty(): tree.set_meta("f48_witness_" + label, data.duplicate(true))
	# Write detached observations only to the proof output, never user saves.
	var output := OS.get_environment("TB_PROOF_OUT")
	if not output.is_empty():
		var dir := output.path_join("f48-witnesses").path_join(str(data.character_id))
		DirAccess.make_dir_recursive_absolute(dir)
		var file := FileAccess.open(dir.path_join(label.validate_filename() + ".json"), FileAccess.WRITE)
		if file == null: return _result(false, "Could not preserve detached witness", data)
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	return _result(true, "Read actual files without autosave; identities and file digests preserved", data)

static func _restore_witness(tree: SceneTree, args: Dictionary) -> Dictionary:
	var label := str(args.get("remember", ""))
	var now := _observe(tree)
	if now.is_empty() or label.is_empty(): return _result(false, "No admitted character/label for detached witness")
	var path := OS.get_environment("TB_PROOF_OUT").path_join("f48-witnesses").path_join(now.character_id).path_join(label.validate_filename() + ".json")
	var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not prior is Dictionary or prior.get("character_id") != now.character_id or prior.get("world_namespace") != now.world_namespace:
		return _result(false, "Detached before witness missing or belongs to another character/world")
	tree.set_meta("f48_witness_" + label, prior)
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

static func _counts(payload: Dictionary) -> Dictionary:
	var out := {}
	for row: Variant in payload.get("inventory", []):
		if row is Dictionary:
			var id := str(row.get("id", ""))
			out[id] = int(out.get(id, 0)) + int(row.get("n", 0))
	return out

static func _assert(tree: SceneTree, args: Dictionary) -> Dictionary:
	var now := _observe(tree)
	if now.is_empty() or now.disk.is_empty(): return _result(false, "Actual durable character file unavailable", now)
	var errors: Array[String] = []
	if args.get("portal_enter") == true:
		var entered := false
		for result: Dictionary in tree.get_meta("f48_portal_results", []):
			if result.get("kind") == "portal_enter" and result.get("ok") == true \
					and result.get("character_id") == now.character_id and result.get("world_instance_id") == now.world_namespace \
					and not str(result.get("request_id", "")).is_empty(): entered = true
		if not entered: errors.append("No actual successful correlated portal-enter result")
	var prior: Dictionary = tree.get_meta("f48_witness_" + str(args.get("since", "")), {})
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
		for path: String in args.get("lacks", {}):
			var values: Variant = _path(state, path)
			if not values is Array or values.has(args.lacks[path]): errors.append(payload + ": unearned or absent field " + path)
		if not prior.is_empty():
			var before: Dictionary = prior[payload]
			for path: String in args.get("unchanged", []):
				if not _json_equal(_path(state, path), _path(before, path)): errors.append(payload + ": replay changed " + path)
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
		var admitted: Dictionary = tree.get_meta("f48_witness_admitted", {})
		if now.owns_world or admitted.is_empty() or now.world_files != admitted.get("world_files"):
			errors.append("Guest wrote a host world file")
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
		var receipt := "defeat:boss_warden_aldis:" + str(now.character_id)
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
		"relic": "relic_hang", "essence_spend": "altar_spend"}
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
		or row.get("version") not in [1, 2, 3] or row.get("action") != actions.get(transaction) \
		or row.get("world_namespace") != now.world_namespace or str(row.get("session_id", "")).is_empty() \
		or row.get("after", {}).get("character_id") != now.character_id \
		or row.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).count(receipt) != 1:
		errors.append("Wrong original accepted personal transaction journal")
	for scope: String in ["memory", "disk"]:
		if now[scope].get("redesign_character", {}).get("transaction_receipts", []).count(receipt) != 1:
			errors.append(scope + ": original saved transaction receipt missing or duplicated")
	if args.has("boundary_receipt") and (receipt != args.boundary_receipt \
		or (row.get("delivery_id", row.get("receipt")) != args.boundary_delivery_id)):
		errors.append("Admission replaced the original native-cut writer receipt/identity")
	if args.has("same_transaction_as"):
		var remembered: Dictionary = tree.get_meta("f48_witness_" + str(args.same_transaction_as), {})
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
			var receipt := "defeat:boss_warden_aldis:" + character
			# This carrier is overwritten by each later accepted action. Its full
			# portable after-state must preserve the original protected boss receipt.
			if not row is Dictionary or row.get("version") not in [1, 2, 3] or row.get("kind") != "creature_training" or row.get("delivery_id") != id \
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


static func _assert_altar_build(tree: SceneTree, args: Dictionary) -> Dictionary:
	var now := _observe(tree)
	var prior: Dictionary = tree.get_meta("f48_witness_" + str(args.get("since", "")), {})
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
		if not _json_equal(state.get("party"), prior.memory.get("party")) or not _json_equal(state.get("redesign_character"), personal) \
			or not _json_equal(state.get("satchel_escrow"), prior.memory.get("satchel_escrow")):
			errors.append(scope + ": paid build changed an owned card/progression or did not persist exactly one receipt")
		var projection := {"inventory": state.get("inventory"), "party": state.get("party"), "redesign_character": state.get("redesign_character")}
		if not _json_equal(row.get("after"), projection): errors.append(scope + ": accepted full after carrier differs from real owner")
	var before := {"inventory": prior.memory.get("inventory"), "party": prior.memory.get("party"), "redesign_character": prior.memory.get("redesign_character")}
	if not _json_equal(row.get("before"), before): errors.append("Accepted original before carrier differs from admitted source")
	for world: String in ["world", "disk_world"]:
		var carrier: Dictionary = now[world]
		if not _json_equal(carrier.get("reward_deliveries", {}).get(id), row): errors.append(world + ": accepted journal absent or changed")
		var found := 0
		for building: Variant in carrier.get("placed_buildings", []):
			if _json_equal(building, record): found += 1
		if found != 1: errors.append(world + ": exact paid Altar record absent or duplicated")
	return _result(errors.is_empty(), "Actual paid Altar bootstrap; no earned campaign credit. " + "; ".join(errors), {"row": row, "observation": now})


static func _button(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Focus is harness input setup. Press goes through real InputEvent delivery;
	# no Button.pressed.emit(), no private _cook/_feed/submit adapters.
	var matches: Array[Button] = []
	_collect_buttons(tree.root, str(args.get("text", "")), matches)
	if matches.size() != 1: return _result(false, "Need exactly one visible enabled button: " + str(args.get("text", "")))
	matches[0].grab_focus()
	await tree.process_frame
	return await tree.call("_step_press", {"action": "ui_accept", "tap_frames": 2})

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

static func _collect_buttons(node: Node, text: String, matches: Array[Button]) -> void:
	if node is Button and node.is_visible_in_tree() and not node.disabled and node.text == text:
		matches.append(node)
	for child: Node in node.get_children(): _collect_buttons(child, text, matches)
