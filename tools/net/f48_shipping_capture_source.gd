extends RefCounted

## Read-only source selection, never capture/ownership/save/ACK certification.
## OFF retains the authored once site independently of its ordinary F30 packet.
const SITE := "wild_once_1900"
const BODY_NAME := "Wild_mosshell_1900_1"
const SPAWNS := "res://data/config/bands/band1_lower_meadows/spawns.json"
const FILES := ["stations.json", "essence.json", "traits.json", "multiplayer.json", "hud.json", "alpha_respawns.json", "combat.json"]
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const SCOPE_FIELDS := ["site", "spawn_id", "body_name", "body_uid", "species", "generation", "namespace", "world_id", "epoch", "realm", "body_path", "director_path", "body_instance_id", "creature_instance_id", "director_instance_id", "world_instance_id", "session_instance_id", "game_instance_id", "local_instance_id", "host_character_id", "host_peer"]
const IDS := ["body_instance_id", "creature_instance_id", "director_instance_id", "world_instance_id", "session_instance_id", "game_instance_id", "local_instance_id"]
static var _sources: Dictionary = {}


static func pins_valid(pins: Array) -> bool:
	if pins.size() != FILES.size(): return false
	var seen := {}
	for raw: Variant in pins:
		if not raw is Dictionary or raw.size() != 2 or not raw.get("file") is String \
			or not raw.get("sha256") is String: return false
		var path: String = raw.file
		if not path.begins_with("res://data/config/") or path.get_file() not in FILES \
			or path != "res://data/config/" + path.get_file() or seen.has(path): return false
		var digest: String = raw.sha256
		if digest.length() != 64: return false
		for letter: String in digest:
			if letter not in "0123456789abcdef": return false
		if FileAccess.get_sha256(path) != digest: return false
		seen[path] = true
	return seen.size() == FILES.size()


static func flags_valid(alpha: Dictionary, traits: Dictionary) -> bool:
	return alpha.get("runtime_enabled") is bool and alpha.runtime_enabled == false \
		and traits.get("runtime_enabled") is bool and traits.runtime_enabled == true \
		and TRAITS.runtime_enabled(traits)


static func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}


static func _one(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == 1


static func _peer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and value >= 1 and value <= 2147483647 and floorf(float(value)) == value


static func _authored() -> Dictionary:
	var alpha := _json("res://data/config/alpha_respawns.json")
	if not flags_valid(alpha, _json("res://data/config/traits.json")): return {}
	var sites: Variant = alpha.get("sites")
	var site: Variant = sites.get(SITE) if sites is Dictionary else null
	if not site is Dictionary or site.get("id") != SITE or site.get("biome") != "meadows" \
		or site.get("source") != SPAWNS or site.get("original_completion_flag") != SITE \
		or not (site.get("source_order") is int or site.get("source_order") is float) \
		or site.source_order != 1900: return {}
	var rows: Variant = _json(SPAWNS).get("spawns")
	if not rows is Array: return {}
	var matches: Array = []
	for row: Variant in rows:
		if row is Dictionary and (row.get("order") is int or row.get("order") is float) and row.order == 1900:
			matches.append(row)
	if matches.size() != 1: return {}
	var spawn: Dictionary = matches[0]
	if spawn.get("species") != "mosshell" or not _one(spawn.get("count")) \
		or not spawn.get("alpha") is Dictionary or spawn.alpha.is_empty(): return {}
	return {"site": site.duplicate(true), "spawn": spawn.duplicate(true), "file": SPAWNS,
		"sha256": FileAccess.get_sha256(SPAWNS)}


static func _mounted(tree: SceneTree, director: Node) -> Dictionary:
	if tree == null or not is_instance_valid(director) or not director.is_inside_tree() \
		or director.is_queued_for_deletion() or director.get_tree() != tree \
		or director.get_script() != load("res://scripts/combat/encounter_director.gd"): return {}
	var game := tree.root.get_node_or_null(^"Game")
	if game == null or game.is_queued_for_deletion() or game.get_script() != load("res://autoload/game_state.gd"): return {}
	var session: Variant = game.get("session")
	var world: Variant = game.get("world")
	if not session is Node or not is_instance_valid(session) or not session.is_inside_tree() \
		or session.is_queued_for_deletion() or session.get_script() != load("res://scripts/net/session.gd") \
		or game.get_node_or_null(^"Session") != session or session.call("_game") != game \
		or director.get("_session") != session or session.call("is_active") != true \
		or session.call("is_host") != true or director.call("_is_host") != true \
		or not world is RefCounted or world.get_script() != load("res://autoload/world_state.gd"): return {}
	var epoch: Variant = session.call("_altar_current_epoch")
	var local: Variant = game.get("local")
	var peer: Variant = session.call("local_peer_id")
	if not epoch is String or epoch.is_empty() or not world.get("world_id") is String \
		or world.get("world_id").is_empty() or not world.get("reward_delivery_namespace") is String \
		or world.get("reward_delivery_namespace").is_empty() or game.get("current_realm") != "meadows" \
		or director.call("_encounter_realm") != "meadows" or not _peer(peer) \
		or not local is RefCounted or local.get_script() != load("res://autoload/player_state.gd") \
		or not local.get("character_id") is String or local.get("character_id").is_empty(): return {}
	var realm: Variant = session.call("_portal_world_node", "meadows")
	if not realm is Node3D or not is_instance_valid(realm) or not realm.is_inside_tree() \
		or realm.is_queued_for_deletion() or not realm.is_ancestor_of(director): return {}
	return {"tree": tree, "game": game, "session": session, "world": world, "realm": realm, "local": local,
		"director": director, "epoch": epoch, "namespace": world.get("reward_delivery_namespace"),
		"world_id": world.get("world_id"), "host_character_id": local.get("character_id"), "host_peer": peer}


static func _packet_valid(body: Node3D, world: RefCounted) -> bool:
	if not is_instance_valid(body) or body.get_script() != load("res://scripts/creatures/wild_creature.gd") \
		or not is_instance_valid(world) or world.get_script() != load("res://autoload/world_state.gd") \
		or str(body.name) != BODY_NAME or body.has_meta("foundation_alpha_packet") \
		or body.get_meta("foundation_alpha_site", "") != SITE \
		or body.get_meta("ordinary_trait_alpha", null) != true \
		or not body.get_meta("ordinary_trait_alpha", null) is bool \
		or not _one(body.get_meta("foundation_alpha_generation", null)) \
		or not _one(body.get_meta("ordinary_trait_generation", null)): return false
	var creature: Variant = body.get("instance")
	var packet: Variant = body.get_meta("ordinary_trait_packet", null)
	var world_ref: Variant = body.get_meta("ordinary_trait_world", null)
	var alpha_world: Variant = body.get_meta("foundation_alpha_world", null)
	if not creature is RefCounted or creature.get_script() != load("res://scripts/creatures/creature_instance.gd") \
		or not packet is Dictionary or not CODEC.valid_capture_traits(packet) \
		or not world_ref is WeakRef or world_ref.get_ref() != world \
		or not alpha_world is WeakRef or alpha_world.get_ref() != world \
		or creature.get("species_id") != "mosshell" or not creature.get("uid") is String \
		or creature.get("uid").is_empty() or body.get_meta("ordinary_trait_uid", "") != creature.get("uid") \
		or creature.get("traits_initialized") != true \
		or creature.get("rolled_traits") != packet.rolled_traits or creature.get("taught_traits") != packet.taught_traits: return false
	return packet.captured_from.world_namespace == world.get("reward_delivery_namespace") \
		and packet.captured_from.spawn_id == BODY_NAME and _one(packet.captured_from.spawn_generation)


static func _select(wilds: Array, once: Dictionary, world: RefCounted) -> Node3D:
	var matches: Array[Node3D] = []
	for raw: Variant in wilds:
		if not is_instance_valid(raw) or not raw is Node3D or once.get(raw) != SITE: continue
		# Count the exact site's bodies BEFORE packet validation; a malformed
		# second body must not be hidden to make selection appear unambiguous.
		matches.append(raw)
	if matches.size() != 1: return null
	var body: Node3D = matches[0]
	if not body.is_inside_tree() or body.is_queued_for_deletion() or not body.visible \
		or not _packet_valid(body, world) or body.call("is_alive") != true: return null
	return body


static func freeze(tree: SceneTree, director: Node, site: String = SITE, pins: Array = []) -> Dictionary:
	if site != SITE or not pins_valid(pins): return {}
	var mounted := _mounted(tree, director)
	var authored := _authored()
	if mounted.is_empty() or authored.is_empty() or director.call("_once_cleared", SITE) != false: return {}
	var wilds: Variant = director.get("_wild_creatures")
	var once: Variant = director.get("_once_only")
	if not wilds is Array or not once is Dictionary: return {}
	var body := _select(wilds, once, mounted.world)
	if body == null or not mounted.realm.is_ancestor_of(body) or not director.get_parent().is_ancestor_of(body) \
		or body.get_meta("foundation_alpha_epoch", "") != mounted.epoch: return {}
	var creature: RefCounted = body.get("instance")
	var card := CODEC.encode(creature)
	if card.is_empty() or card.get("uid") != creature.get("uid") or card.get("species_id") != "mosshell": return {}
	var scope := {"site": SITE, "spawn_id": BODY_NAME, "body_name": BODY_NAME, "body_uid": creature.get("uid"),
		"species": "mosshell", "generation": 1, "namespace": mounted.namespace, "world_id": mounted.world_id,
		"epoch": mounted.epoch, "realm": "meadows", "body_path": str(body.get_path()),
		"director_path": str(director.get_path()), "body_instance_id": body.get_instance_id(),
		"creature_instance_id": creature.get_instance_id(), "director_instance_id": director.get_instance_id(),
		"world_instance_id": mounted.world.get_instance_id(), "session_instance_id": mounted.session.get_instance_id(),
		"game_instance_id": mounted.game.get_instance_id(), "local_instance_id": mounted.local.get_instance_id(),
		"host_character_id": mounted.host_character_id, "host_peer": mounted.host_peer}
	var source := {"scope": scope, "packet": body.get_meta("ordinary_trait_packet").duplicate(true),
		"card": card.duplicate(true), "authored": authored, "pins": pins.duplicate(true), "refs": {}}
	for key: String in ["tree", "game", "session", "world", "realm", "director", "local"]:
		source.refs[key] = weakref(mounted[key])
	source.refs.body = weakref(body)
	source.refs.creature = weakref(creature)
	if not pins_valid(pins) or _authored() != authored or not _same_objects(source, _mounted(tree, director), body): return {}
	return _remember(source)


static func _remember(source: Dictionary) -> Dictionary:
	for id: Variant in _sources.keys():
		if _sources[id].ticket.get_ref() == null: _sources.erase(id)
	if _sources.size() >= 128: return {}
	var ticket := RefCounted.new()
	_sources[ticket.get_instance_id()] = {"ticket": weakref(ticket), "source": source.duplicate(true)}
	return {"ticket": ticket}


static func _source(binding: Dictionary) -> Dictionary:
	if binding.size() != 1 or not binding.get("ticket") is RefCounted: return {}
	var entry: Dictionary = _sources.get(binding.ticket.get_instance_id(), {})
	return entry.source if not entry.is_empty() and entry.ticket.get_ref() == binding.ticket else {}


static func _same_objects(source: Dictionary, mounted: Dictionary, body: Node3D) -> bool:
	if not source.get("refs") is Dictionary or not source.get("scope") is Dictionary: return false
	for key: String in ["tree", "game", "session", "world", "realm", "director", "local"]:
		var ref: Variant = source.refs.get(key)
		if not ref is WeakRef or ref.get_ref() == null or ref.get_ref() != mounted.get(key): return false
	var body_ref: Variant = source.refs.get("body")
	var creature_ref: Variant = source.refs.get("creature")
	return is_instance_valid(body) and body_ref is WeakRef and body_ref.get_ref() == body \
		and creature_ref is WeakRef and creature_ref.get_ref() != null and creature_ref.get_ref() == body.get("instance") \
		and mounted.get("epoch") == source.scope.get("epoch") and mounted.get("namespace") == source.scope.get("namespace") \
		and mounted.get("world_id") == source.scope.get("world_id") \
		and mounted.get("host_character_id") == source.scope.get("host_character_id") \
		and mounted.get("host_peer") == source.scope.get("host_peer")


static func live(tree: SceneTree, director: Node, binding: Dictionary) -> bool:
	var source := _source(binding)
	if source.is_empty() or not pins_valid(source.pins): return false
	var mounted := _mounted(tree, director)
	if mounted.is_empty() or _authored() != source.authored or director.call("_once_cleared", SITE) != false: return false
	var wilds: Variant = director.get("_wild_creatures")
	var once: Variant = director.get("_once_only")
	if not wilds is Array or not once is Dictionary: return false
	var body := _select(wilds, once, mounted.world)
	return _same_objects(source, mounted, body) and mounted.realm.is_ancestor_of(body) \
		and director.get_parent().is_ancestor_of(body) and str(body.get_path()) == source.scope.body_path \
		and str(director.get_path()) == source.scope.director_path \
		and body.get_meta("foundation_alpha_epoch", "") == source.scope.epoch \
		and body.get("instance").get("uid") == source.scope.body_uid \
		and DOCUMENT.stringify(body.get_meta("ordinary_trait_packet")) == DOCUMENT.stringify(source.packet)


static func report(binding: Dictionary) -> Dictionary:
	var source := _source(binding)
	if source.is_empty(): return {}
	var out: Dictionary = source.scope.duplicate(true)
	# Transport IDs as exact decimal strings. The original native int64 values
	# remain in scope_document; ordinary outer JSON must not round these IDs.
	for field: String in IDS: out[field] = str(source.scope[field])
	out.merge({"mode": "shipping_off_authored_once_ordinary_packet", "read_only": true, "acceptance_credit": false,
		"packet": source.packet.duplicate(true), "shipping_configuration_pins": source.pins.duplicate(true),
		"packet_document": DOCUMENT.stringify(source.packet), "card_document": DOCUMENT.stringify(source.card),
		"scope_document": DOCUMENT.stringify(source.scope), "authored_document": DOCUMENT.stringify(source.authored)})
	out.source_document = DOCUMENT.stringify(out)
	out.source_sha256 = out.source_document.sha256_text()
	return out


static func selected_body(binding: Dictionary) -> Node3D:
	var source := _source(binding)
	var ref: Variant = source.get("refs", {}).get("body")
	return ref.get_ref() as Node3D if ref is WeakRef else null


static func _transport_equal(actual: Variant, original: Variant) -> bool:
	if original is bool: return actual is bool and actual == original
	if original is int or original is float:
		return (actual is int or actual is float) and is_finite(float(actual)) and actual == original
	if original is String: return actual is String and actual == original
	if original is Array:
		if not actual is Array or actual.size() != original.size(): return false
		for index: int in original.size():
			if not _transport_equal(actual[index], original[index]): return false
		return true
	if original is Dictionary:
		if not actual is Dictionary or actual.size() != original.size(): return false
		for key: Variant in original:
			if not actual.has(key) or not _transport_equal(actual[key], original[key]): return false
		return true
	return false


static func _lossless(text: String) -> Variant:
	var envelope: Variant = JSON.parse_string(text)
	if not envelope is Dictionary or envelope.size() != 3 or envelope.get("format") != DOCUMENT.FORMAT \
		or not _one(envelope.get("codec_version")) or not envelope.has("payload"): return null
	return DOCUMENT.parse(text)


## Byte/shape validation only, not independent proof of an actual host freeze.
## The controller must relay the ORIGINAL actual successful host result once;
## runtime encounter/claim/UID and original BOOL/ACK are separate obligations.
static func verified_report(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.get("source_document") is String \
		or not value.get("source_sha256") is String \
		or value.source_document.sha256_text() != value.source_sha256: return {}
	var original: Variant = _lossless(value.source_document)
	if not original is Dictionary: return {}
	var extra: Array = ["mode", "read_only", "acceptance_credit", "packet", "shipping_configuration_pins", "packet_document", "card_document", "scope_document", "authored_document"]
	if original.size() != SCOPE_FIELDS.size() + extra.size(): return {}
	for field: String in SCOPE_FIELDS + extra:
		if not original.has(field) or not value.has(field) or not _transport_equal(value[field], original[field]): return {}
	var expected_size: int = original.size() + 2
	if value.has("encounter_id"):
		if not value.encounter_id is String or value.encounter_id.is_empty(): return {}
		expected_size += 1
	if value.size() != expected_size or original.mode != "shipping_off_authored_once_ordinary_packet" \
		or not original.read_only is bool or original.read_only != true \
		or not original.acceptance_credit is bool or original.acceptance_credit != false \
		or not original.shipping_configuration_pins is Array or not pins_valid(original.shipping_configuration_pins): return {}
	for field: String in ["packet_document", "card_document", "scope_document", "authored_document"]:
		if not original[field] is String: return {}
	var scope: Variant = _lossless(original.scope_document)
	var packet: Variant = _lossless(original.packet_document)
	var card: Variant = _lossless(original.card_document)
	var authored: Variant = _lossless(original.authored_document)
	if not scope is Dictionary or scope.size() != SCOPE_FIELDS.size() \
		or not packet is Dictionary or not card is Dictionary or not authored is Dictionary \
		or authored.is_empty() or authored != _authored() or packet != original.packet \
		or not CODEC.valid_capture_traits(packet) or CODEC.decode(card, packet) == null: return {}
	for field: String in SCOPE_FIELDS:
		if not scope.has(field): return {}
		if field in IDS:
			if not scope[field] is int or scope[field] <= 0 or original[field] != str(scope[field]): return {}
		elif original[field] != scope[field]: return {}
	for field: String in ["body_uid", "namespace", "world_id", "epoch", "body_path", "director_path", "host_character_id"]:
		if not scope[field] is String or scope[field].is_empty(): return {}
	if scope.site != SITE or scope.spawn_id != BODY_NAME or scope.body_name != BODY_NAME \
		or scope.species != "mosshell" or scope.realm != "meadows" or not _one(scope.generation) or not _peer(scope.host_peer) \
		or packet.captured_from.world_namespace != scope.namespace or packet.captured_from.spawn_id != BODY_NAME \
		or not _one(packet.captured_from.spawn_generation) or card.get("uid") != scope.body_uid \
		or card.get("species_id") != "mosshell": return {}
	var out: Dictionary = value.duplicate(true)
	# Typed IDs are available ONLY from this separately checked lossless scope.
	out["scope"] = scope.duplicate(true)
	out["card"] = card.duplicate(true)
	return out
