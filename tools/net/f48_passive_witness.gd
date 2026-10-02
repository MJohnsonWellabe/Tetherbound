extends RefCounted

## Actual passive-clock evidence only. No live creature/save/world mutation.
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const MAX_EVENTS := 1200000
const MAX_BYTES := 335544320
const MAX_ANCHORS := 128

class CardSource extends RefCounted:
	var instance: RefCounted
	func members() -> Array:
		return [instance]

static func start(tree: SceneTree) -> bool:
	if tree.has_meta("f48_passive_state"):
		var retained: Dictionary = tree.get_meta("f48_passive_state")
		return _live(retained) and str(retained.get("error", "")).is_empty()
	var game := tree.root.get_node_or_null(^"Game")
	var output := OS.get_environment("TB_PROOF_OUT")
	if game == null or not game.has_signal("party_passive_tick") or output.is_empty(): return false
	var epoch := str(game.session.call("_altar_current_epoch")) if game.get("session") != null else ""
	if game.get("world") == null or game.get("local") == null or epoch.is_empty() \
		or str(game.local.character_id).is_empty() or str(game.world.reward_delivery_namespace).is_empty(): return false
	var dir := output.path_join("f48-passive")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("actual-%d.jsonl" % OS.get_process_id())
	if FileAccess.file_exists(path): return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	var cfg := CONDITION.config().duplicate(true)
	var state := {"sequence": -1, "events": 0, "error": "", "anchors": {}, "file": file, "path": path,
		"configuration": cfg, "configuration_sha256": FileAccess.get_sha256("res://data/config/creature_condition.json"),
		"chain_sha256": "", "game_ref": weakref(game), "world_ref": weakref(game.world), "session_ref": weakref(game.session),
		"character_id": str(game.local.character_id), "world_namespace": str(game.world.reward_delivery_namespace), "epoch": epoch}
	file.store_line(JSON.stringify({"source": "Game actual tick_buffs then CreatureCondition.tick", "condition_config": cfg,
		"configuration_sha256": state.configuration_sha256, "max_events": MAX_EVENTS, "max_bytes": MAX_BYTES,
		"character_id": state.character_id, "world_namespace": state.world_namespace, "session_epoch": state.epoch}))
	var observer := func(packet: Dictionary) -> void: _tick(state, packet)
	game.connect("party_passive_tick", observer)
	tree.set_meta("f48_passive_watch", observer)
	tree.set_meta("f48_passive_state", state)
	return true

static func stop(tree: SceneTree) -> void:
	var game := tree.root.get_node_or_null(^"Game")
	var observer: Variant = tree.get_meta("f48_passive_watch", null)
	if game != null and observer is Callable and game.is_connected("party_passive_tick", observer):
		game.disconnect("party_passive_tick", observer)
	var state: Dictionary = tree.get_meta("f48_passive_state", {})
	if state.get("file") is FileAccess:
		state.file.flush()
		state.file.close()
	for key: String in ["f48_passive_watch", "f48_passive_state"]:
		if tree.has_meta(key): tree.remove_meta(key)

static func _live(state: Dictionary) -> bool:
	var game: Variant = state.game_ref.get_ref()
	return game != null and game.get("world") != null and game.get("local") != null and game.get("session") != null \
		and game.world == state.world_ref.get_ref() and game.session == state.session_ref.get_ref() \
		and game.local.character_id == state.character_id and game.world.reward_delivery_namespace == state.world_namespace \
		and str(game.session.call("_altar_current_epoch")) == state.epoch

static func _tick(state: Dictionary, packet: Dictionary) -> void:
	if not str(state.error).is_empty(): return
	if not _live(state) or packet.get("character_id") != state.character_id \
		or packet.get("world_namespace") != state.world_namespace or packet.get("session_epoch") != state.epoch:
		state.error = "Actual passive owner/world/session lifetime changed"; return
	var sequence: Variant = packet.get("sequence")
	var delta: Variant = packet.get("delta")
	if not sequence is int or sequence <= 0 or (state.sequence >= 0 and sequence != state.sequence + 1) \
		or not (delta is int or delta is float) or not is_finite(float(delta)) or delta < 0.0 \
		or not packet.get("before") is Dictionary or not packet.get("after") is Dictionary \
		or packet.get("uid") != packet.before.get("uid") or packet.get("uid") != packet.after.get("uid") \
		or not equal(packet.get("condition_config"), state.configuration):
		state.error = "Actual passive sequence/UID/configuration discontinuity"
		return
	if state.events >= MAX_EVENTS or state.file.get_position() >= MAX_BYTES:
		state.error = "Actual passive evidence overflow; no transition dropped"
		return
	var replay := replay_packet(packet, state.configuration)
	if replay.has("error"): state.error = replay.error; return
	var predicted: Dictionary = replay.after
	for anchor: Dictionary in state.anchors.values():
		if not str(anchor.error).is_empty(): continue
		if packet.get("character_id") != anchor.character_id or packet.get("world_namespace") != anchor.world_namespace:
			anchor.error = "Actual passive owner/world identity changed"; continue
		for index: int in anchor.expected.size():
			if anchor.expected[index].get("uid") != packet.uid: continue
			if not equal(anchor.expected[index], packet.before) or not equal(anchor.buffs.get(packet.uid), packet.buffs_before):
				anchor.error = "Full original card changed outside observed passive clocks"
			else:
				anchor.expected[index] = predicted.duplicate(true)
				anchor.buffs[packet.uid] = packet.buffs_after.duplicate(true)
			break
	var line := JSON.stringify({"s": sequence, "u": packet.uid, "d": delta,
		"b": JSON.stringify(packet.before).sha256_text(), "a": JSON.stringify(packet.after).sha256_text()})
	if state.file.get_position() + line.to_utf8_buffer().size() + 1 > MAX_BYTES:
		state.error = "Actual passive evidence overflow; no transition dropped"; return
	state.file.store_line(line)
	if state.file.get_error() != OK:
		state.error = "Actual passive evidence write failed"; return
	state.chain_sha256 = (str(state.chain_sha256) + line).sha256_text()
	state.sequence = sequence
	state.events += 1

static func replay_packet(packet: Dictionary, configuration: Dictionary) -> Dictionary:
	var clone: RefCounted = INSTANCE.new()
	var properties := {}
	for property: Dictionary in clone.get_property_list(): properties[str(property.name)] = property
	for key: String in packet.before:
		if not properties.has(key): return {"error": "Unreplayable original full-card field: " + key}
		var value: Variant = packet.before[key]
		if value is Array:
			var target: Array = clone.get(key)
			target.assign(value.duplicate(true))
		elif value is Dictionary: clone.set(key, value.duplicate(true))
		else: clone.set(key, value)
	if not packet.get("buffs_before") is Array or not packet.get("buffs_after") is Array:
		return {"error": "Actual complete buff carrier missing"}
	for buff: Variant in packet.buffs_before:
		if not buff is Dictionary: return {"error": "Malformed complete buff carrier"}
	var typed_buffs: Array = clone.get("active_buffs")
	typed_buffs.assign(packet.buffs_before.duplicate(true))
	var source := CardSource.new()
	source.instance = clone
	var saver: RefCounted = SAVE.new()
	var roundtrip: Dictionary = saver.call("_party_to_array", source)[0]
	if not equal(roundtrip, packet.before): return {"error": "Detached full-card replay did not roundtrip exactly"}
	clone.call("tick_buffs", float(packet.delta))
	CONDITION.tick(clone, configuration, float(packet.delta))
	var predicted: Dictionary = saver.call("_party_to_array", source)[0]
	if not equal(predicted, packet.after) or not equal(clone.get("active_buffs"), packet.buffs_after):
		return {"error": "Actual passive update differs from independently replayed shipping timers"}
	return {"after": predicted, "buffs_after": clone.get("active_buffs").duplicate(true)}

static func anchor(tree: SceneTree, name: String, data: Dictionary) -> bool:
	if not start(tree): return false
	var state: Dictionary = tree.get_meta("f48_passive_state")
	if not _live(state) or state.anchors.has(name) or state.anchors.size() >= MAX_ANCHORS or not data.get("memory", {}).get("party") is Array:
		state.error = "Duplicate/missing/overflow passive anchor"; return false
	state.anchors[name] = {"character_id": data.character_id, "world_namespace": data.world_namespace,
		"initial": data.memory.party.duplicate(true), "expected": data.memory.party.duplicate(true),
		"sequence": state.sequence, "chain_sha256": state.chain_sha256, "error": "", "buffs": {}}
	var game: Variant = state.game_ref.get_ref()
	for member: RefCounted in game.party.call("members"):
		state.anchors[name].buffs[str(member.get("uid"))] = (member.get("active_buffs") as Array).duplicate(true)
	return true

static func matches(tree: SceneTree, name: String, party: Variant) -> bool:
	var state: Dictionary = tree.get_meta("f48_passive_state", {})
	var record: Dictionary = state.get("anchors", {}).get(name, {})
	return not state.is_empty() and _live(state) and str(state.error).is_empty() and not record.is_empty() \
		and str(record.error).is_empty() and equal(record.expected, party)

static func evidence(tree: SceneTree, name: String) -> Dictionary:
	var state: Dictionary = tree.get_meta("f48_passive_state", {})
	if state.is_empty(): return {"error": "Actual passive witness missing"}
	state.file.flush()
	return {"path": state.path, "events": state.events, "sequence": state.sequence,
		"chain_sha256": state.chain_sha256, "configuration_sha256": state.configuration_sha256,
		"error": state.error, "character_id": state.character_id, "world_namespace": state.world_namespace, "session_epoch": state.epoch,
		"anchor": state.anchors.get(name, {}).duplicate(true)}

static func equal(left: Variant, right: Variant) -> bool:
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not equal(left[key], right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for index: int in left.size():
			if not equal(left[index], right[index]): return false
		return true
	if (left is int or left is float) and (right is int or right is float):
		if not is_finite(float(left)) or not is_finite(float(right)): return false
		if typeof(left) != typeof(right) and (abs(float(left)) > 9007199254740991.0 or abs(float(right)) > 9007199254740991.0): return false
		return left == right
	return typeof(left) == typeof(right) and left == right

