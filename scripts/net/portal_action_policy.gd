extends RefCounted

## Integration proposal: Session owns this instance and supplies an exclusively
## host-derived context. No RPC may expose evaluate(), authorizations or context.
## This module prepares actions, never writes progression or grants inventory.
var _serial := 0
var _channels: Dictionary = {}
var _permits: Dictionary = {}
var _world := ""

const FIELDS := {
	"home_key_begin": ["kind"], "home_key_finish": ["kind", "use_id"],
	"home_key_cancel": ["kind", "use_id"],
	"portal_unlock": ["kind", "arch_id"], "portal_enter": ["kind", "arch_id"],
	"waystone_touch": ["kind", "waystone_id"],
}


func bind_world(world_instance: String) -> void:
	if world_instance != _world:
		_channels.clear()
		_permits.clear()
		_world = world_instance


static func refusal(context: Dictionary) -> String:
	# All booleans must be assembled from the host encounter/director, actual
	# host trainer body and authoritative traversal states, never a packet.
	for field: String in ["combat", "dialogue", "cutscene", "swimming", "flying", "downed"]:
		if not context.get(field) is bool:
			return "Your travel state is not ready."
	if context.combat: return "Not during a fight."
	if context.dialogue: return "Finish the conversation first."
	if context.cutscene: return "Wait until the scene finishes."
	if context.swimming: return "Reach solid ground first."
	if context.flying: return "Land first."
	if context.downed: return "You can't use it while down."
	return ""


static func valid_payload(payload: Dictionary) -> bool:
	var kind: Variant = payload.get("kind")
	if not kind is String or not FIELDS.has(kind) or payload.size() != FIELDS[kind].size():
		return false
	for field: String in FIELDS[kind]:
		if not payload.get(field) is String or str(payload[field]).is_empty() or str(payload[field]).length() > 192:
			return false
	return true


func evaluate(payload: Dictionary, context: Dictionary, config: Dictionary,
		stones: Dictionary, now_msec: int) -> Dictionary:
	if not valid_payload(payload):
		return _deny("", "That travel request was malformed.")
	var kind: String = payload.kind
	if _world.is_empty() or context.get("world_instance_id") != _world \
			or not context.get("character_id") is String or str(context.character_id).is_empty() \
			or not context.get("peer_id") is int or int(context.peer_id) < 1 \
			or not context.get("realm") is String or str(context.realm).is_empty() \
			or not context.get("position") is Vector3 or not context.get("damage_revision") is int:
		return _deny(kind, "Your character is not admitted to this world.")
	var character: String = context.character_id
	if kind == "home_key_cancel":
		if not _owns_channel(payload.use_id, context):
			return _deny(kind, "That Home Key use has already ended.")
		_channels.erase(character)
		return _ok(kind, payload.use_id, context, {"cancelled": true, "use_id": payload.use_id})
	var reason := refusal(context)
	if not reason.is_empty():
		_channels.erase(character)
		return _deny(kind, reason)
	if kind in ["home_key_begin", "home_key_finish"]:
		if not context.get("home_key_owned") is bool or not bool(context.home_key_owned):
			return _deny(kind, "Grandpa has not given you your Home Key yet.")
		if kind == "home_key_begin":
			if _channels.has(character):
				return _deny(kind, "Your Home Key is already raised.")
			var duration: Variant = (config.get("home_key", {}) as Dictionary).get("raise_seconds")
			var timeout: Variant = (config.get("home_key", {}) as Dictionary).get("response_timeout_seconds")
			if not (duration is float or duration is int) or not is_finite(float(duration)) or float(duration) <= 0 \
					or not (timeout is float or timeout is int) or not is_finite(float(timeout)) or float(timeout) <= float(duration):
				return _deny(kind, "The Home Key is not configured.")
			var id := _mint(character)
			_channels[character] = {"request_id": id, "peer_id": context.peer_id,
				"character_id": character, "world_instance_id": _world, "realm": context.realm,
				"position": context.position, "damage_revision": context.damage_revision,
				"ready_at": now_msec + int(ceil(float(duration) * 1000.0)),
				"expires_at": now_msec + int(ceil(float(timeout) * 1000.0))}
			return _ok(kind, id, context, {"use_id": id, "raise_seconds": float(duration)})
		if not _owns_channel(payload.use_id, context):
			return _deny(kind, "That Home Key use has already ended.")
		var frozen: Dictionary = _channels[character]
		if now_msec >= int(frozen.expires_at):
			_channels.erase(character)
			return _deny(kind, "Your Home Key use timed out. Tap it again.")
		if frozen.realm != context.realm or frozen.damage_revision != context.damage_revision:
			_channels.erase(character)
			return _deny(kind, "Your Home Key use was interrupted.")
		if now_msec < int(frozen.ready_at):
			return _deny(kind, "Your Home Key is still rising.")
		_channels.erase(character)
		return _permit(kind, payload.use_id, context, "meadows", "hall_home")
	if _channels.has(character):
		return _deny(kind, "Lower your Home Key first.")
	if kind == "waystone_touch":
		var stone: Dictionary = _find_stone(stones, payload.waystone_id)
		if stone.is_empty() or stone.get("realm_id") != context.realm:
			return _deny(kind, "That waystone is not in your current biome.")
		# actual mounted target coordinates are host-resolved after ground seating.
		var positions: Dictionary = context.get("waystone_positions", {})
		if not _near(context.position, positions.get(payload.waystone_id), (stones.get("tuning", {}) as Dictionary).get("touch_radius_m")):
			return _deny(kind, "Walk up to the waystone to awaken it.")
		return _ok(kind, _mint(character), context, {"waystone": stone.duplicate(true),
			"requires_owner_save": true})
	var arch := _find_arch(config, payload.arch_id)
	var arch_positions: Dictionary = context.get("arch_positions", {})
	if arch.is_empty() or context.realm != "meadows" or not _near(context.position,
			arch_positions.get(payload.arch_id), (config.get("arch", {}) as Dictionary).get("interaction_radius_m")):
		return _deny(kind, "Stand at the Crossing Hall arch first.")
	var biome: String = arch.biome
	var personal: Variant = context.get("character_unlocks")
	var world: Variant = context.get("world_unlocks")
	if not personal is Array or not world is Array:
		return _deny(kind, "Your portal progress is not ready.")
	var opened: bool = biome == "meadows" or personal.has(biome) or world.has(biome)
	if kind == "portal_unlock":
		if arch.get("key_item", "").is_empty():
			return _deny(kind, "That arch does not take a portal key.")
		if biome == "biome5":
			if not context.get("character_stirred") is bool:
				return _deny(kind, "Your fifth arch progress is not ready.")
			if bool(context.character_stirred):
				return _deny(kind, "The arch is quiet.")
		if world.has(biome) and personal.has(biome):
			return _deny(kind, "This arch is already open for you and this world.")
		if int((context.get("owned_portal_keys", {}) as Dictionary).get(arch.key_item, 0)) != 1:
			return _deny(kind, "Needs the %s Portal Key." % str(arch.get("label", biome.capitalize())))
		return _ok(kind, _mint(character), context, {"arch_id": payload.arch_id,
			"biome": biome, "item": arch.key_item, "requires_world_and_owner_save": true})
	if arch.get("kind") != "live":
		return _deny(kind, "This arch is not ready yet.")
	if not opened:
		return _deny(kind, "Needs the %s Portal Key." % str(arch.get("label", biome)))
	var entry: String = arch.entry_id
	var last: Variant = context.get("last_waystones", {})
	var active: Variant = context.get("waystones_activated", {})
	if not last is Dictionary or not active is Dictionary:
		return _deny(kind, "Your waystone progress is not ready.")
	var selected: String = str(last.get(biome, ""))
	if not selected.is_empty():
		var activated: Variant = active.get(biome, [])
		if not activated is Array or not activated.has(selected):
			return _deny(kind, "Your saved return point is invalid.")
		# v28 schema retains canonical entry markers; they mean the authored
		# entry anchor, never an invented stone or a client-selected coordinate.
		if selected != biome + "_entry":
			var stone := _find_stone(stones, selected)
			if stone.is_empty() or stone.get("biome") != biome:
				return _deny(kind, "Your saved return point is invalid.")
			entry = selected
	return _permit(kind, _mint(character), context, "water" if biome == "tidewake" else biome, entry)


## RealmTransition consumes this permit. Bare client-selected destinations
## cannot authorize a transfer. Issuing a permit never moves a body itself.
func consume_permit(request_id: String, peer_id: int, character_id: String,
		world_instance: String, origin_realm: String) -> Dictionary:
	var permit: Variant = _permits.get(request_id)
	if not permit is Dictionary or permit.peer_id != peer_id or permit.character_id != character_id \
			or permit.world_instance_id != world_instance or permit.origin_realm != origin_realm:
		return {}
	_permits.erase(request_id)
	return permit.duplicate(true)


## True while any Home Key channel is frozen. cancel_invalid() is a no-op
## without one, so a per-frame caller can skip building its host context.
func has_open_channels() -> bool:
	return not _channels.is_empty()


## Host tick must cancel immediately on damage/combat/refusal or disconnect.
## Finish also revalidates, so a lost cancellation packet cannot grant travel.
func cancel_invalid(context: Dictionary) -> bool:
	var character := str(context.get("character_id", ""))
	if not _channels.has(character): return false
	var frozen: Dictionary = _channels[character]
	if not refusal(context).is_empty() or frozen.peer_id != context.get("peer_id") \
			or frozen.world_instance_id != context.get("world_instance_id") \
			or frozen.realm != context.get("realm") or frozen.damage_revision != context.get("damage_revision"):
		_channels.erase(character)
		return true
	return false


## A dropped begin-result or finish packet must not retain a channel forever.
## Session calls this with its own monotonic clock and publishes cancellations
## for presentation; expired channels never move or spend anything.
func tick_expired(now_msec: int) -> Array[Dictionary]:
	var cancelled: Array[Dictionary] = []
	for character: String in _channels.keys():
		var row: Dictionary = _channels[character]
		if now_msec >= int(row.expires_at):
			cancelled.append({"kind": "home_key_cancel", "request_id": row.request_id,
				"use_id": row.request_id, "character_id": character, "peer_id": row.peer_id,
				"ok": false, "reason": "Your Home Key use timed out. Tap it again."})
			_channels.erase(character)
	return cancelled


func disconnected(peer_id: int) -> void:
	for character: String in _channels.keys():
		if _channels[character].peer_id == peer_id: _channels.erase(character)
	for token: String in _permits.keys():
		if _permits[token].peer_id == peer_id: _permits.erase(token)


func _owns_channel(id: String, context: Dictionary) -> bool:
	var row: Variant = _channels.get(context.character_id)
	return row is Dictionary and row.request_id == id and row.peer_id == context.peer_id \
		and row.world_instance_id == _world


func _mint(character: String) -> String:
	_serial += 1
	return "travel:%s:%s:%d" % [_world, character, _serial]


func _permit(kind: String, id: String, context: Dictionary, realm: String, entry: String) -> Dictionary:
	_permits[id] = {"request_id": id, "peer_id": context.peer_id, "character_id": context.character_id,
		"world_instance_id": _world, "origin_realm": context.realm, "realm": realm, "entry_id": entry}
	return _ok(kind, id, context, {"travel_permit": id})


static func _near(position: Vector3, raw: Variant, radius: Variant) -> bool:
	if not (radius is float or radius is int) \
			or not is_finite(float(radius)) or float(radius) <= 0: return false
	if raw is Vector3:
		return raw.is_finite() and position.is_finite() and position.distance_to(raw) <= float(radius)
	if not raw is Array or raw.size() != 3: return false
	for axis: Variant in raw:
		if not (axis is float or axis is int) or not is_finite(float(axis)): return false
	return position.distance_to(Vector3(float(raw[0]), float(raw[1]), float(raw[2]))) <= float(radius)


static func _find_arch(config: Dictionary, id: String) -> Dictionary:
	for arch: Variant in config.get("arches", []):
		if arch is Dictionary and arch.get("id") == id: return arch.duplicate(true)
	return {}


static func _find_stone(stones: Dictionary, id: String) -> Dictionary:
	for stone: Variant in stones.get("waystones", []):
		if stone is Dictionary and stone.get("id") == id: return stone.duplicate(true)
	return {}


static func _ok(kind: String, id: String, context: Dictionary, prepared: Dictionary) -> Dictionary:
	return {"ok": true, "kind": kind, "request_id": id, "reason": "",
		"character_id": context.character_id, "prepared": prepared}


static func _deny(kind: String, reason: String) -> Dictionary:
	return {"ok": false, "kind": kind, "request_id": "", "reason": reason, "prepared": {}}
