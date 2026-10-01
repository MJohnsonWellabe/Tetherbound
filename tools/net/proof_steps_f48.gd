extends RefCounted

## Read-only F48 witnesses and ordinary input. Never saves during observation:
## an observation must not repair a missing durable write before asserting it.
## All receipt records below are read from production files, never constructed.
const DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const UIDS := preload("res://scripts/data/redesign_state.gd")
const ATOMIC := preload("res://scripts/save/atomic_save_file.gd")
const DETACHED := preload("res://tools/net/f48_detached_file.gd")

static func step(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"f48_witness": return _witness(tree, args)
		"f48_assert": return _assert(tree, args)
		"f48_button": return await _button(tree, args)
		"f48_require": return _require(tree, args)
		"f48_restore_witness": return _restore_witness(tree, args)
		"f48_participants": return await _participants(tree, args)
		"f48_watch_portal": return _watch_portal(tree)
		"f48_arm_boundary": return _arm_boundary(tree, args)
	return _result(false, "Unknown F48 action: " + action)

static func _result(ok: bool, detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "PASS" if ok else "FAIL", "detail": detail, "data": data}

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
	var world_ref := weakref(game.world)
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
	return _result(_unique(found).size() == wanted.size() and found.all(func(id: Variant) -> bool: return wanted.has(id)),
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
				errors.append(payload + ": feast changed level or lost owned creature")
			var mirror: Dictionary = state.get("redesign_character", {}).get("creatures", {}).get(args.creature.uid, {})
			if mirror.get("breakthroughs") != args.creature.breakthroughs:
				errors.append(payload + ": feast did not clear exactly the requested tier")
		if args.has("released_uid"):
			if party.has(args.released_uid): errors.append(payload + ": released UID remains owned")
			if not prior.is_empty():
				var expected_uids := UIDS.uids(prior[payload].get("party", []))
				if not expected_uids.has(args.released_uid): errors.append(payload + ": release target was not owned before")
				expected_uids.erase(args.released_uid)
				if party != expected_uids: errors.append(payload + ": release replaced or lost another companion")
		for path: String in args.get("equals", {}):
			if _path(state, path) != args.equals[path]: errors.append(payload + ": wrong " + path)
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
				if _path(state, path) != _path(before, path): errors.append(payload + ": replay changed " + path)
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
		if _path(now.memory, path) != _path(now.disk, path): errors.append("Memory/disk disagree: " + path)
	if args.get("boss_rewards") == true:
		_check_boss(now, errors)
	if args.has("participants"):
		_check_host_journal(now, args.participants, errors)
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
		if not state.get("redesign_character", {}).get("relics_held", []).has("meadows"):
			errors.append(scope + ": participant lacks personal Meadows relic")
		var escrow: Dictionary = state.get("satchel_escrow", {})
		for source: String in ["trainer:warden_aldis:item:tidewake_portal_key", "trainer:warden_aldis:relic:meadows"]:
			var id := DELIVERY.delivery_id(now.world_namespace, source, now.character_id)
			var row: Variant = escrow.get(id)
			if not row is Dictionary or row.get("character_id") != now.character_id or row.get("source") != source \
					or row.get("world_namespace") != now.world_namespace or row.get("status") != "settled":
				errors.append(scope + ": missing exact settled personal delivery " + source)

static func _check_host_journal(now: Dictionary, participants: Array, errors: Array[String]) -> void:
	if not now.owns_world or now.disk_world.is_empty():
		errors.append("Actual host world file unavailable")
		return
	if participants.size() < 2 or _unique(participants).size() != participants.size(): errors.append("Distinct participant identities required")
	for scope: String in ["world", "disk_world"]:
		var deliveries: Dictionary = now[scope].get("reward_deliveries", {})
		for character: String in participants:
			for source: String in ["trainer:warden_aldis:item:tidewake_portal_key", "trainer:warden_aldis:relic:meadows"]:
				var id := DELIVERY.delivery_id(now.world_namespace, source, character)
				var row: Variant = deliveries.get(id)
				if not row is Dictionary or row.get("character_id") != character or row.get("source") != source \
						or row.get("world_namespace") != now.world_namespace or row.get("status") != "accepted":
					errors.append(scope + ": missing exact accepted participant delivery " + character + "/" + source)

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

static func _button(tree: SceneTree, args: Dictionary) -> Dictionary:
	# Focus is harness input setup. Press goes through real InputEvent delivery;
	# no Button.pressed.emit(), no private _cook/_feed/submit adapters.
	var matches: Array[Button] = []
	_collect_buttons(tree.root, str(args.get("text", "")), matches)
	if matches.size() != 1: return _result(false, "Need exactly one visible enabled button: " + str(args.get("text", "")))
	matches[0].grab_focus()
	await tree.process_frame
	return await tree.call("_step_press", {"action": "ui_accept", "tap_frames": 2})

static func _collect_buttons(node: Node, text: String, matches: Array[Button]) -> void:
	if node is Button and node.is_visible_in_tree() and not node.disabled and node.text == text:
		matches.append(node)
	for child: Node in node.get_children(): _collect_buttons(child, text, matches)
