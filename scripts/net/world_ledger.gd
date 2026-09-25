extends RefCounted

const STORMWOOD_ARCH_BUILD := preload("res://scripts/world/stormwood_arch_build_rules.gd")

## Stage B Wave 3 lane 3.A. THE WORLD LEDGER: one writer for shared world state.
##
## D103. Every consequential world mutation arrives as an INTENT, is validated
## against a `WorldState`, and -- if it survives validation -- is committed as a
## DELTA that every peer applies through `WorldState.apply_delta()`. First
## committed claim wins; the loser is REFUSED with a reason string the caller
## can show the player, never silently dropped.
##
## Pure `RefCounted`: no scene tree, no `multiplayer`, no RPC, no `Game`. That
## is what makes the deterministic interleavings in
## `tests/test_world_ledger_races.gd` provable headlessly, which is where
## race-safety is actually proven -- the net smokes only ever prove "no
## duplication regardless of order". `scripts/net/ledger_rpc.gd` is the thin
## transport that carries intents to the host and deltas back; it owns one of
## these and never reimplements a rule from this file.
##
## ## Realm (D97)
##
## EVERY intent carries an explicit `realm`. Nothing here reads
## `Game.current_realm`: from Wave 6 two peers stand in two realms at once, and
## a record stamped with "whichever realm the local player happens to be in"
## would file a Cloudreach fence in the Meadows. Same rule
## `WorldState.register_building()` already follows.
##
## ## The verdict
##
## `commit()` always returns a Dictionary of this exact shape -- never `null`,
## never a bare `bool`, so no caller has to branch on the type of the answer:
##
##     {
##       "ok":      bool,    # was this committed?
##       "kind":    String,  # the intent kind, echoed
##       "peer":    int,     # who asked
##       "code":    String,  # "" when ok, else a machine tag (see below)
##       "reason":  String,  # "" when ok, else ONE player-facing sentence
##       "pending": false,   # commit() is never pending; ledger_rpc sets true
##       "delta":   Dictionary,  # the committed delta; empty ops when refused
##     }
##
## Refusal codes, all stable enough for a caller to branch on:
##   `already_taken`   another peer's claim landed first
##   `stale_revision`  a storage write raced another and lost
##   `gone`            the thing being dismantled/withdrawn is no longer there
##   `duplicate`       this exact `txn_id` was already committed (a replay)
##   `malformed`       the intent is missing a field it needs
##   `unknown_intent`  no such kind
## A commit that changed nothing because the world already said so (setting an
## already-set world flag) is `ok` with code `noop`, not a refusal.
##
## ## The delta
##
##     {"seq": int, "realm": String, "ops": [op, ...]}
##
## `seq` counts commits on the host, so a peer can spot a gap. Each op carries a
## SCOPE, which says who applies it:
##
##   `world`  a `WorldState` container. `WorldState.apply_delta()` applies these
##            and only these; it is the only way a client's world changes.
##   `player` a per-peer fact, addressed to the peers listed in `peers`.
##            `player_ops_for()` below is the filter; `ledger_rpc.gd` applies
##            the result to the local `PlayerState`.
##   `scene`  a fact whose live mirror lives in a scene node that owns its own
##            format and cannot be written from a pure state object -- today
##            only `veg_deplete`, because `harvested_vegetation` is a base64
##            bitset whose length `vegetation.gd::restore_from_game()` checks
##            against the running layer before it will trust a byte of it.
##            The DURABLE half of that same fact is an ordinary `world` flag op
##            committed alongside it, so a reload does not resurrect the bush.
##            `ledger_rpc.gd` re-emits these for lane 3.B's consumers.
##
## ## What is deliberately NOT here
##
## Player inventories. The host cannot see a client's satchel, so `transfer_item`
## and `drop_item` arbitrate THE MOVE, not the contents: the ledger mints/checks
## a `txn_id` so a retried or duplicated intent can never move the same stack
## twice, and addresses the take/grant to the two peers. Lane 3.E fills in the
## consumer side. Same for `catch_attempt`, which D103 routes through the
## encounter host in Wave 4, not through this file.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const STORMWOOD_ARCHES := preload("res://scripts/world/stormwood_arch_rules.gd")
const STORMWOOD_HARVEST := preload("res://scripts/world/stormwood_harvest_rules.gd")
var _stormwood_harvest_rules: RefCounted
const SATCHEL_RULES := preload("res://scripts/world/death_satchel_rules.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")

const DOSS_FLAG := "river_nest_doss_cleared"
const DOSS_AT := Vector3(72.0, 0.0, 4187.4)
const DOSS_INTERACTION_RADIUS_M := 6.0
const DOSS_COST := {"wood": 1, "fiber": 1}
const DOSS_REWARDS := {"coin": 45, "potion_large": 1}

## The authoritative world this ledger writes. On a client, `ledger_rpc.gd`
## still builds a ledger over the local replica, but only ever calls `apply()`
## on it -- `commit()` is the host's alone.
var world: RefCounted = null

## Commits so far. Rides every delta as `seq`.
var seq: int = 0

## Container key -> revision, for `storage_txn`'s optimistic concurrency.
## SESSION-SCOPED on purpose, not persisted: a stale `expected_revision` only
## means anything against the writes of this session, and a number carried
## across a reload would refuse the first honest write after every load.
var _storage_revisions: Dictionary = {}

## Every `txn_id` this ledger has already committed, so a replayed
## `transfer_item`/`drop_item` is refused rather than duplicating a stack.
var _seen_txns: Dictionary = {}


func _init(world_state: RefCounted = null) -> void:
	world = world_state


## World flags whose id ends in a character id, so a receipt can only be
## written by that character. `legendary_resolution` receipts record each
## participant's own accept/refuse under the per-participant legendary rule.
## Override or extend with `ledger.owned_flag_prefixes` in multiplayer.json.
const OWNED_FLAG_PREFIXES := [
	"legendary_resolution:accepted:",
	"legendary_resolution:refused:",
	"stormwood:legendary_resolution:accepted:",
	"stormwood:legendary_resolution:refused:",
	"tidewake:legendary_resolution:accepted:",
	"tidewake:legendary_resolution:refused:",
]
const MULTIPLAYER_CONFIG := "res://data/config/multiplayer.json"
## Configured prefixes must name a legendary resolution receipt, so a broad
## entry such as "stormwood:" cannot silently lock ordinary world flags.
const OWNED_FLAG_PREFIX_MARK := "legendary_resolution:"
const HOST_PEER := preload("res://scripts/net/peer_registry.gd").HOST_PEER_ID

static var _owned_prefixes: Array = []

var _actor_character := ""


static func owned_flag_prefixes() -> Array:
	if _owned_prefixes.is_empty():
		_owned_prefixes = OWNED_FLAG_PREFIXES.duplicate()
		var file := FileAccess.open(MULTIPLAYER_CONFIG, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				var configured: Variant = ((parsed as Dictionary).get("ledger", {}) as Dictionary) \
					.get("owned_flag_prefixes", []) if (parsed as Dictionary).get("ledger") is Dictionary else []
				if configured is Array:
					for prefix: Variant in configured:
						if prefix is String and (prefix as String).contains(OWNED_FLAG_PREFIX_MARK) \
								and (prefix as String).ends_with(":") and not _owned_prefixes.has(prefix):
							_owned_prefixes.append(prefix)
	return _owned_prefixes


## A remote peer may write an owned receipt only for its own registered
## character. The host's own writes stay trusted: host code records receipts
## for participants it has already validated. `actor_character_id` is filled
## in by the host from the session registry (`ledger_rpc.gd`), never taken
## from the request.
static func owned_flag_allowed(id: String, peer_id: int, actor_character_id: String) -> bool:
	for prefix: String in owned_flag_prefixes():
		if id.begins_with(prefix):
			if peer_id == HOST_PEER:
				return true
			var owner := id.trim_prefix(prefix)
			return not owner.is_empty() and owner == actor_character_id
	return true


# --- the one entry point ------------------------------------------------------

## Validate `intent` and, if it survives, commit it. `peer_id` is who asked --
## the requesting peer on the host, the local peer solo.
func commit(intent: Dictionary, peer_id: int = 1) -> Dictionary:
	# Filled in by the host from the session registry (ledger_rpc.gd), never
	# taken from the request; `_commit` checks owned receipts against it. It
	# lives only for this call, so no later `_commit` caller inherits it.
	_actor_character = str(intent.get("_actor_character_id", ""))
	var verdict := _commit_intent(intent, peer_id)
	_actor_character = ""
	return verdict


func _commit_intent(intent: Dictionary, peer_id: int) -> Dictionary:
	var kind := str(intent.get("kind", ""))
	var realm := str(intent.get("realm", ""))
	if world == null:
		return _refuse(kind, peer_id, "malformed", "The world is not ready yet.")
	if realm.is_empty():
		# D97: never fall back to a global "current realm". An intent that does
		# not say which world it is about is a bug in the caller, not a thing to
		# guess at.
		return _refuse(kind, peer_id, "malformed", "That action did not say which world it belongs to.")

	match kind:
		"stormwood_disable_rod":
			return _stormwood_disable_rod(intent, peer_id, realm)
		"stormwood_harvest":
			return _stormwood_harvest(intent, peer_id, realm)
		"stormwood_relight_arch":
			return _stormwood_relight_arch(intent, peer_id, realm)
		"death_satchel_create", "death_satchel_transfer":
			return _death_satchel_intent(intent, peer_id, realm)
		"water_dock_action":
			var result: Dictionary = preload("res://scripts/world/water_dock_rules.gd").evaluate(intent, intent.get("_water_actor", {}), world.flags)
			if not bool(result.ok):
				return _refuse(kind, peer_id, str(result.code), str(result.reason))
			return _commit(result.ops, kind, peer_id, realm)
		"river_nest_clear":
			return _river_nest_clear(intent, peer_id, realm)
		"water_personal_pickup":
			var result: Dictionary = preload("res://scripts/world/water_personal_pickup.gd").evaluate(intent, intent.get("_water_actor", {}), world.flags)
			if not bool(result.ok):
				return _refuse(kind, peer_id, str(result.code), str(result.reason))
			return _commit(result.ops, kind, peer_id, realm)
		"claim_pickup":
			return _claim_pickup(intent, peer_id, realm)
		"harvest":
			return _harvest(intent, peer_id, realm)
		"deplete_vegetation":
			return _deplete_vegetation(intent, peer_id, realm)
		"place_building":
			return _place_building(intent, peer_id, realm)
		"dismantle":
			return _dismantle(intent, peer_id, realm)
		"storage_txn":
			return _storage_txn(intent, peer_id, realm)
		"set_world_flag":
			return _set_world_flag(intent, peer_id, realm)
		"grant_player_flag":
			return _grant_player_flag(intent, peer_id, realm)
		"transfer_item":
			return _transfer_item(intent, peer_id, realm)
		"drop_item":
			return _drop_item(intent, peer_id, realm)
		"reward_grant":
			return _reward_grant(intent, peer_id, realm)
	return _refuse(kind, peer_id, "unknown_intent", "That action is not something this world knows how to do.")


## Apply a committed delta to this ledger's world and bookkeeping. Called by
## `commit()` itself and, on a client, by `ledger_rpc.gd` when a delta lands --
## so host and client run the SAME apply code and can only disagree if they were
## handed different deltas.
func apply(delta: Dictionary) -> int:
	var ops: Array = delta.get("ops", []) as Array
	for raw: Variant in ops:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("op", "")) in ["storage_set", "satchel_set"]:
			_storage_revisions[str(op.get("container", ""))] = maxi(int(_storage_revisions.get(str(op.get("container", "")), 0)), int(op.get("revision", 0)))
		var txn := str(op.get("txn_id", ""))
		if not txn.is_empty():
			_seen_txns[txn] = true
	seq = maxi(seq, int(delta.get("seq", 0)))
	if world == null:
		return 0
	return int(world.call("apply_delta", delta))


## The revision a caller must quote in the next `storage_txn` for `container`.
func storage_revision(container: String) -> int:
	if container.begins_with("satchel:") and world != null:
		var index: int = world.call("death_satchel_index_of", container.trim_prefix("satchel:"))
		if index >= 0:
			return maxi(int(world.get("death_satchels")[index].get("revision", 0)), int(_storage_revisions.get(container, 0)))
	return int(_storage_revisions.get(container, 0))


func _death_satchel_intent(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var kind := str(intent.kind)
	var actor: Dictionary = intent.get("_satchel_actor", {})
	var txn := str(intent.get("txn_id", ""))
	var requested_instance: Variant = intent.get("world_instance_id", null)
	var host_instance: Variant = world.get("reward_delivery_namespace")
	if typeof(requested_instance) != TYPE_STRING or (requested_instance as String).is_empty() \
			or typeof(host_instance) != TYPE_STRING or (host_instance as String).is_empty() \
			or requested_instance != host_instance:
		return _refuse(kind, peer_id, "wrong_world",
			"That pending satchel move belongs to a different world.")
	if txn.is_empty() or _seen_txns.has(txn):
		return _refuse(kind, peer_id, "duplicate", "That satchel move was already recorded.")
	var at: Variant = actor.get("position")
	if str(actor.get("realm", "")) != realm or int(actor.get("peer", 0)) != peer_id or not at is Vector3 or not at.is_finite():
		return _refuse(kind, peer_id, "wrong_actor", "Your trainer is not ready in this realm.")
	var character := str(actor.get("character_id", ""))
	if kind == "death_satchel_create":
		if not SATCHEL_RULES.valid_slots(intent.get("state")):
			return _refuse(kind, peer_id, "malformed", "The dropped stacks could not be checked.")
		var uid := "death_" + txn
		if world.call("death_satchel_index_of", uid) >= 0:
			return _refuse(kind, peer_id, "duplicate", "That death satchel already exists.")
		# The requested drop point may lift a drowned bag to the surface, but
		# cannot move it to a different island from the host's trainer proxy.
		var raw: Variant = intent.get("position")
		if raw is Array and raw.size() == 3:
			for value: Variant in raw:
				if not (value is float or value is int) or not is_finite(float(value)):
					return _refuse(kind, peer_id, "malformed", "The dropped position could not be checked.")
			var requested := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
			if requested.is_finite() and requested.distance_to(at) <= 5.0:
				at = requested
		return _commit([{"op": "satchel_add", "scope": "world", "realm": realm,
			"uid": uid, "owner": character, "position": [at.x, at.y, at.z],
			"state": intent.state.duplicate(true), "txn_id": txn}], kind, peer_id, realm)
	var uid := str(intent.get("uid", ""))
	var index: int = world.call("death_satchel_index_of", uid)
	if index < 0:
		return _refuse(kind, peer_id, "unknown_satchel", "That satchel has not reached this world yet.")
	var record: Dictionary = world.get("death_satchels")[index]
	if (record.get("transactions", []) as Array).has(txn):
		return _refuse(kind, peer_id, "duplicate", "That satchel move was already recorded.")
	if str(record.get("realm", "meadows")) != realm or (not str(record.get("owner", "")).is_empty() and str(record.owner) != character):
		return _refuse(kind, peer_id, "not_owner", "Only this satchel's owner can move its contents.")
	var raw: Array = record.position
	if at.distance_to(Vector3(float(raw[0]), float(raw[1]), float(raw[2]))) > 3.6:
		return _refuse(kind, peer_id, "too_far", "Move closer to your satchel.")
	var container := "satchel:" + uid
	var current := storage_revision(container)
	for key: String in ["expected_revision", "count"]:
		var value: Variant = intent.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) != floorf(float(value)) or float(value) < 0 or float(value) > 2147483647:
			return _refuse(kind, peer_id, "malformed", "That satchel move could not be checked.")
	if int(intent.get("expected_revision", -1)) != current:
		var refusal := _refuse(kind, peer_id, "stale_revision", "The satchel changed; try again.")
		refusal.container = container
		refusal.revision = current
		return refusal
	if not SATCHEL_RULES.valid_slots(intent.get("personal")):
		return _refuse(kind, peer_id, "malformed", "Your carried stacks could not be checked.")
	var preview := SATCHEL_RULES.preview(record.get("state", []), intent.personal, str(intent.get("direction", "")), str(intent.get("item", "")), int(intent.get("count", 0)))
	if preview.is_empty():
		return _refuse(kind, peer_id, "no_room", "Those items will not fit, or are no longer there.")
	return _commit([{"op": "satchel_set", "scope": "world", "realm": realm,
		"uid": uid, "container": container, "state": preview.state,
		"revision": current + 1, "txn_id": txn}], kind, peer_id, realm)


## Take the host's word for a container's revision, from a `stale_revision`
## refusal. A client's `_storage_revisions` is otherwise only ever advanced by
## `apply()` seeing a committed `storage_set`, so a peer that joined after a
## chest was written has no other way to learn a number it never saw. Host-side
## this is never called: the host IS the number.
func adopt_storage_revision(container: String, revision: int) -> void:
	if container.is_empty():
		return
	_storage_revisions[container] = maxi(int(_storage_revisions.get(container, 0)), revision)


## The player-scope ops in `delta` addressed to `peer_id`. Pure and static so
## `ledger_rpc.gd` and `tests/test_world_ledger_races.gd` ask the same question
## of the same code -- "did this grant actually reach both peers" is then a
## claim about shipping behaviour, not about a test's own re-implementation.
static func player_ops_for(delta: Dictionary, peer_id: int) -> Array:
	var out: Array = []
	for raw: Variant in (delta.get("ops", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("scope", "")) != "player":
			continue
		var peers: Array = op.get("peers", []) as Array
		if peers.is_empty() or peers.has(peer_id):
			out.append(op)
	return out


## The scene-scope ops in `delta`, for the live mirrors that own their own
## format (lane 3.B's vegetation bitset).
static func scene_ops(delta: Dictionary) -> Array:
	var out: Array = []
	for raw: Variant in (delta.get("ops", []) as Array):
		if typeof(raw) == TYPE_DICTIONARY and str((raw as Dictionary).get("scope", "")) == "scene":
			out.append(raw)
	return out


# --- intents ------------------------------------------------------------------

func _stormwood_disable_rod(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var kind := "stormwood_disable_rod"
	if realm != "stormwood":
		return _refuse(kind, peer_id, "malformed", "That station belongs to the Stormwood.")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_rod_stations.json"))
	for station: Dictionary in data.get("stations", []):
		if str(station.id) != str(intent.get("id", "")):
			continue
		if _flag_set(str(station.disabled_flag)):
			return _refuse(kind, peer_id, "already_taken", "This rod line is already quiet.")
		for gate: String in station.get("requires_flags", []):
			if not _flag_set(gate):
				return _refuse(kind, peer_id, "locked", "Follow the rod line before opening this switch.")
		if not _flag_set(str(station.guard_defeat_flag)):
			return _refuse(kind, peer_id, "guarded", "Defeat the station's picket before opening its switch.")
		return _commit([_world_flag(realm, str(station.disabled_flag))], kind, peer_id, realm)
	return _refuse(kind, peer_id, "malformed", "That rod station could not be found.")

## A one-time world find (`item_cache_pickup.gd`, `key_pickup.gd`,
## `tm_pickup.gd`). `flag` is the value of that consumer's own static
## `flag_id()`, so the ledger never has to learn three id schemes -- and the
## flag store is already where "collected" lives, which is D103's point: it was
## the right shape, it just had no single writer.
func _claim_pickup(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var flag := str(intent.get("flag", ""))
	if flag.is_empty():
		return _refuse("claim_pickup", peer_id, "malformed", "That find has no identity to record.")
	if _flag_set(flag):
		return _refuse("claim_pickup", peer_id, "already_taken", "Someone else got there first.")
	var ops: Array = [_world_flag(realm, flag)]
	var item := str(intent.get("item", ""))
	var count := maxi(1, int(intent.get("count", 1)))
	if not item.is_empty():
		ops.append(_item_grant(peer_id, item, count))
	return _commit(ops, "claim_pickup", peer_id, realm)


## A hand-authored harvest node (`harvest_node.gd`). Gone, not resting: the same
## `harvest_node:<id>` flag D72 already writes, now written once by the host.
func _harvest(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var flag := str(intent.get("flag", ""))
	if flag.begins_with("harvest_node:order:stormwood_harvest_"):
		return _refuse("harvest", peer_id, "malformed", "That resource needs the forest's harvest rules.")
	if flag.is_empty():
		return _refuse("harvest", peer_id, "malformed", "That resource has no identity to record.")
	if _flag_set(flag):
		return _refuse("harvest", peer_id, "already_taken", "Someone else already gathered that.")
	var ops: Array = [_world_flag(realm, flag)]
	var item := str(intent.get("item", ""))
	var amount := maxi(0, int(intent.get("amount", 0)))
	if not item.is_empty() and amount > 0:
		ops.append(_item_grant(peer_id, item, amount))
	return _commit(ops, "harvest", peer_id, realm)


func _stormwood_harvest(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var kind := "stormwood_harvest"
	if realm != "stormwood":
		return _refuse(kind, peer_id, "malformed", "That resource belongs to the Stormwood.")
	if _stormwood_harvest_rules == null:
		_stormwood_harvest_rules = STORMWOOD_HARVEST.new()
	var id := str(intent.get("site_id", ""))
	var reason: String = _stormwood_harvest_rules.refusal(id, world)
	if not reason.is_empty():
		return _refuse(kind, peer_id, "unavailable", reason)
	var flag := STORMWOOD_HARVEST.flag(id)
	if _flag_set(flag):
		return _refuse(kind, peer_id, "already_taken", "Someone else already gathered that.")
	var site: Dictionary = _stormwood_harvest_rules.sites[id]
	# Identity, yield and availability come from host data, never the request.
	return _commit([_world_flag(realm, flag), _item_grant(peer_id, str(site.item), int(site.amount))], kind, peer_id, realm)


## One scattered bush/tree/rock, addressed the way `vegetation.gd` addresses it:
## a layer name and an index into that layer's placements. The durable half is
## an ordinary world flag; the live bitset is a `scene` op, because its length
## has to line up with the running layer and only that node knows the length.
func _deplete_vegetation(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var layer := str(intent.get("layer", ""))
	var index := int(intent.get("index", -1))
	if layer.is_empty() or index < 0:
		return _refuse("deplete_vegetation", peer_id, "malformed", "That growth has no identity to record.")
	var flag := vegetation_flag(realm, layer, index)
	if _flag_set(flag):
		return _refuse("deplete_vegetation", peer_id, "already_taken", "Someone else already gathered that.")
	var ops: Array = [
		_world_flag(realm, flag),
		{"op": "veg_deplete", "scope": "scene", "realm": realm, "layer": layer, "index": index},
	]
	var item := str(intent.get("item", ""))
	var amount := maxi(0, int(intent.get("amount", 0)))
	if not item.is_empty() and amount > 0:
		ops.append(_item_grant(peer_id, item, amount))
	return _commit(ops, "deplete_vegetation", peer_id, realm)


## The record `build_placer.gd` plants. The op carries exactly the arguments
## `WorldState.register_building()` takes, and `apply_delta()` calls that
## function rather than appending a hand-built Dictionary, so the shape of a
## placed-building record has one construction site and cannot drift.
func _place_building(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var id := str(intent.get("id", ""))
	if id.is_empty():
		return _refuse("place_building", peer_id, "malformed", "That structure has no identity to record.")
	var txn := str(intent.get("txn_id", ""))
	if not txn.is_empty() and _seen_txns.has(txn):
		return _refuse("place_building", peer_id, "duplicate",
			"That structure was already placed.")
	# The HOST mints the uid, here, once, and every peer applies the one that
	# arrives on the op. A client minting its own would produce two identities
	# for one structure the moment two peers placed in the same tick.
	var uid := "b%d" % int(world.get("next_building_uid"))
	var arch_plan: Dictionary = {}
	var request_position := _position(intent.get("position"))
	var arch_at := Vector3(float(request_position[0]), float(request_position[1]), float(request_position[2]))
	if realm == "stormwood" and id != "stormglass_arch" and not STORMWOOD_ARCH_BUILD.footing_at(arch_at).is_empty():
		return _refuse("place_building", peer_id, "arch_footing", "This old footing accepts only a Stormglass Arch.")
	var committed_position: Variant = intent.get("position")
	var committed_yaw := float(intent.get("yaw_deg", 0.0))
	if id == "stormglass_arch":
		# Snap first, then judge: the footing centre and facing the client
		# preview snaps to (build_placer.gd) are what gets committed, so the
		# placement rules, occupancy and cost are evaluated there too, not at
		# wherever inside the 5 m footing radius the request landed. Height
		# stays the request's ground-clamped y.
		var socket := STORMWOOD_ARCH_BUILD.footing_at(arch_at)
		if not socket.is_empty():
			var centre := Vector3(float(socket.at[0]), arch_at.y, float(socket.at[1]))
			for row: Dictionary in STORMWOOD_ARCH_BUILD.records(world.get("placed_buildings")):
				var raw: Array = row.get("position", [])
				var here := Vector2(float(raw[0]), float(raw[2])) if raw.size() == 3 else Vector2.INF
				if str(row.get("arch_footing", "")) == str(socket.get("id", "")) \
						or here.distance_to(Vector2(centre.x, centre.z)) < 5.0:
					return _refuse("place_building", peer_id, "arch_occupied",
						"Another arch already occupies this footing.")
			arch_at = centre
			committed_position = centre
			committed_yaw = float(socket.get("yaw_deg", committed_yaw))
		arch_plan = STORMWOOD_ARCH_BUILD.placement(arch_at, realm, world.get("flags"), world.get("placed_buildings"))
		if not bool(arch_plan.ok):
			return _refuse("place_building", peer_id, "arch_locked", str(arch_plan.reason))
		if bool(intent.get("paid", true)):
			var available: Dictionary = intent.get("available_materials", {})
			for need: Dictionary in STORMWOOD_ARCH_BUILD.cost(arch_at):
				if int(available.get(str(need.id), 0)) < int(need.n):
					return _refuse("place_building", peer_id, "arch_materials", "This footing needs the correct Stormglass grade and arch materials.")
	var op := {
		"op": "building_add",
		"scope": "world",
		"realm": realm,
		"uid": uid,
		"id": id,
		"position": _position(committed_position),
		"yaw_deg": committed_yaw,
		"paid": bool(intent.get("paid", true)),
	}
	if not txn.is_empty():
		op["txn_id"] = txn
	var ops: Array = [op]
	if not arch_plan.is_empty():
		ops.append({"op": "building_arch_link", "scope": "world", "realm": realm,
			"uid": uid, "twin": str(arch_plan.twin), "footing": str(arch_plan.footing)})
		if not str(arch_plan.twin).is_empty() and str(arch_plan.twin) != "e_crown":
			ops.append({"op": "building_arch_link", "scope": "world", "realm": realm,
				"uid": str(arch_plan.twin), "twin": uid})
	var verdict := _commit(ops, "place_building", peer_id, realm)
	# Echoed so the presser can match THIS answer to the ticket it raised. Two
	# placements in flight inside one round trip otherwise pop the wrong ticket
	# and charge the wrong press (lane 3.C, F3).
	verdict["uid"] = uid
	if not txn.is_empty():
		verdict["txn_id"] = txn
	return verdict


## By `uid`, not by index. Lane 3.C measured why: a client submits `dismantle`
## for index N, another peer's removal below N commits while that intent is in
## flight, and the host applies it against a renumbered array -- taking down the
## NEIGHBOUR. The realm guard cannot catch it, because after the renumber the
## index is perfectly valid, just wrong. An identity does not move when the
## array does.
func _dismantle(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var txn := str(intent.get("txn_id", ""))
	if not txn.is_empty() and _seen_txns.has(txn):
		return _refuse("dismantle", peer_id, "duplicate", "That structure was already taken down.")
	var buildings: Array = world.get("placed_buildings") as Array
	var uid := str(intent.get("uid", ""))
	var index := -1
	if not uid.is_empty():
		index = int(world.call("building_index_of", uid))
	else:
		# Only for a caller not yet taught uids. No shipping code takes it.
		index = int(intent.get("index", -1))
	if index < 0 or index >= buildings.size():
		return _refuse("dismantle", peer_id, "gone", "That structure is already gone.")
	var record: Dictionary = buildings[index] as Dictionary
	if str(record.get("realm", "meadows")) != realm:
		return _refuse("dismantle", peer_id, "gone", "That structure is already gone.")
	var op := {"op": "building_remove", "scope": "world", "realm": realm,
		"uid": str(record.get("uid", "")), "index": index}
	if not txn.is_empty():
		op["txn_id"] = txn
	var ops: Array = [op]
	var twin := str(record.get("arch_twin", ""))
	if not twin.is_empty() and twin != "e_crown":
		ops.append({"op": "building_arch_link", "scope": "world", "realm": realm,
			"uid": twin, "twin": ""})
	var verdict := _commit(ops, "dismantle", peer_id, realm)
	verdict["uid"] = str(record.get("uid", ""))
	if not txn.is_empty():
		verdict["txn_id"] = txn
	return verdict


## Optimistic concurrency for a chest (D103, lane 3.D). The caller quotes the
## revision it read; a write against a revision that has since moved is refused
## with a sentence a player can act on rather than silently overwriting whatever
## their friend just deposited.
func _storage_txn(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var container := str(intent.get("container", ""))
	if container.is_empty():
		return _refuse("storage_txn", peer_id, "malformed", "That container has no identity to record.")
	if not intent.has("expected_revision"):
		return _refuse("storage_txn", peer_id, "malformed", "That container write did not say what it was based on.")
	var expected := int(intent.get("expected_revision"))
	var current := storage_revision(container)
	if expected != current:
		# The refusal CARRIES the current revision, and that is not a nicety.
		# Lane 3.D found the failure it prevents: `_storage_revisions` is
		# session-scoped and is not in the join snapshot, so a peer that joins
		# a session where the host has already written a chest reads 0 while
		# the host holds N. Its write is refused, a refusal commits nothing, so
		# its local number never moves -- and it is refused again, forever, on a
		# chest that tells it "someone else changed that container" for the rest
		# of the session. Telling the loser the number turns both that lockout
		# and every ordinary lost race into one silent retry.
		var verdict := _refuse("storage_txn", peer_id, "stale_revision",
			"Someone else changed that container -- close it and look again.")
		verdict["container"] = container
		verdict["revision"] = current
		return verdict
	var state: Variant = intent.get("state", [])
	var op := {
		"op": "storage_set",
		"scope": "world",
		"realm": realm,
		"container": container,
		"index": int(intent.get("index", -1)),
		"state": (state as Array).duplicate(true) if typeof(state) == TYPE_ARRAY else [],
		"revision": current + 1,
	}
	# The submitter's own id rides on the op, so a client can tell "MY write
	# committed" from "an identical write committed". Without it the only
	# positive signal a client has is the arriving delta, matched by revision
	# and contents -- exact unless two peers deposit the same item and count
	# from the same revision, when the two states are byte-identical and the
	# loser settles as though it had won, quietly destroying its own items.
	# `apply()` already records op-level `txn_id`s in `_seen_txns`, so this
	# also buys `storage_txn` the replay guard the item moves have.
	var txn := str(intent.get("txn_id", ""))
	if not txn.is_empty():
		if _seen_txns.has(txn):
			return _refuse("storage_txn", peer_id, "duplicate",
				"That container write was already made.")
		op["txn_id"] = txn
	return _commit([op], "storage_txn", peer_id, realm)


func _set_world_flag(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var id := str(intent.get("id", ""))
	if id.is_empty():
		return _refuse("set_world_flag", peer_id, "malformed", "That world change has no identity to record.")
	var value := bool(intent.get("value", true))
	if _flag_set(id) == value:
		# Not a refusal: the world already says what the caller asked it to say,
		# and a story trigger that fires twice should be harmless, not an error
		# the player is shown.
		var verdict := _commit([], "set_world_flag", peer_id, realm)
		verdict["code"] = "noop"
		return verdict
	return _commit([_world_flag(realm, id, value)], "set_world_flag", peer_id, realm)


## D99: a per-player flag, granted to the peers named in the intent -- one peer
## for a personal beat, everyone in the session for a home flag. The host cannot
## read a client's flag store, so this never refuses as "already granted"; the
## op is idempotent where it lands (`progression_state.set_flag`).
func _grant_player_flag(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var id := str(intent.get("id", ""))
	if id.is_empty():
		return _refuse("grant_player_flag", peer_id, "malformed", "That progress has no identity to record.")
	var peers := _peers(intent, peer_id)
	if peers.is_empty():
		return _refuse("grant_player_flag", peer_id, "malformed", "There is nobody to give that to.")
	var op := {"op": "flag", "scope": "player", "realm": realm, "id": id, "value": true, "peers": peers}
	return _commit([op], "grant_player_flag", peer_id, realm)


## D107, lane 3.E. The ledger arbitrates THE MOVE, not the satchels: a `txn_id`
## committed once can never be committed again, so a retried or duplicated
## intent cannot mint a second stack no matter which order the two halves land.
func _transfer_item(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var txn := str(intent.get("txn_id", ""))
	var item := str(intent.get("item", ""))
	var count := int(intent.get("count", 0))
	var from_peer := int(intent.get("from", peer_id))
	var to_peer := int(intent.get("to", 0))
	if txn.is_empty() or item.is_empty() or count <= 0 or to_peer == 0:
		return _refuse("transfer_item", peer_id, "malformed", "That trade was missing something.")
	if from_peer == to_peer:
		return _refuse("transfer_item", peer_id, "malformed", "That trade had only one side.")
	if _seen_txns.has(txn):
		return _refuse("transfer_item", peer_id, "duplicate", "That trade already went through.")
	var ops: Array = [
		_item_take(from_peer, item, count, txn),
		_item_grant(to_peer, item, count, txn),
	]
	return _commit(ops, "transfer_item", peer_id, realm)


## Dropping is a transfer with the world on the receiving end: the same replay
## guard, plus a `scene` op so lane 3.E's dropped-stack prop is spawned once for
## everyone rather than once per peer that heard about it.
func _drop_item(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var txn := str(intent.get("txn_id", ""))
	var item := str(intent.get("item", ""))
	var count := int(intent.get("count", 0))
	if txn.is_empty() or item.is_empty() or count <= 0:
		return _refuse("drop_item", peer_id, "malformed", "That drop was missing something.")
	if _seen_txns.has(txn):
		return _refuse("drop_item", peer_id, "duplicate", "That was already dropped.")
	var ops: Array = [
		_item_take(peer_id, item, count, txn),
		{
			"op": "item_dropped", "scope": "scene", "realm": realm, "txn_id": txn,
			"item": item, "count": count, "position": _position(intent.get("position")),
			"from": peer_id,
		},
	]
	return _commit(ops, "drop_item", peer_id, realm)


## A shared victory journals one stable delivery per participating character.
## `_reward_recipients` is host-only metadata supplied by LedgerRpc; peer ids
## remain routing addresses, while the receipt identity survives reconnects.
func _reward_grant(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var source := str(intent.get("source", ""))
	if source.is_empty():
		return _refuse("reward_grant", peer_id, "malformed", "That reward has no source to record.")
	var world_id := str(intent.get("world_id", world.get("world_id")))
	var recipients: Variant = intent.get("_reward_recipients", [])
	if not recipients is Array or recipients.is_empty():
		return _refuse("reward_grant", peer_id, "malformed", "There is nobody to reward.")
	var item := str(intent.get("item", ""))
	var count := int(intent.get("count", 1))
	var flag_id := str(intent.get("flag", ""))
	if not item.is_empty() and count <= 0:
		return _refuse("reward_grant", peer_id, "malformed", "That reward has no items to deliver.")
	# XP announcements still use reward_grant only as their historical receipt;
	# this slice changes durable item/flag delivery, not XP ownership.
	if item.is_empty() and flag_id.is_empty():
		return _legacy_receipt_only_reward(intent, peer_id, realm, source)
	if _has_legacy_reward_receipt(source):
		return _refuse("reward_grant", peer_id, "legacy_unresolved",
			"This older reward receipt cannot identify its recipient. Manual recovery may be needed.")
	var ops: Array = []
	var paid: Array = []
	var valid_recipients: Array = []
	var seen_characters: Dictionary = {}
	for raw: Variant in recipients:
		if not raw is Dictionary:
			continue
		var target := int((raw as Dictionary).get("peer", 0))
		var character_id := str((raw as Dictionary).get("character_id", ""))
		if target <= 0 or character_id.is_empty() or seen_characters.has(character_id):
			continue
		seen_characters[character_id] = true
		valid_recipients.append({"peer": target, "character_id": character_id})
	if valid_recipients.is_empty():
		return _refuse("reward_grant", peer_id, "malformed", "There is nobody to reward.")
	var world_namespace := str(world.get("reward_delivery_namespace"))
	if world_namespace.is_empty():
		world_namespace = Crypto.new().generate_random_bytes(16).hex_encode()
	var provenance_world_id := world_id if not world_id.is_empty() else "instance:" + world_namespace
	for raw: Variant in valid_recipients:
		var target := int((raw as Dictionary).get("peer", 0))
		var character_id := str((raw as Dictionary).get("character_id", ""))
		var delivery := REWARD_DELIVERY.make_record(provenance_world_id, world_namespace, source, character_id,
			item, count, flag_id)
		if delivery.is_empty():
			return _refuse("reward_grant", peer_id, "malformed", "That reward cannot be delivered safely.")
		var delivery_id := str(delivery.get("delivery_id", ""))
		var existing: Variant = (world.get("reward_deliveries") as Dictionary).get(delivery_id)
		if existing is Dictionary:
			continue
		paid.append(target)
		ops.append({"op": "reward_delivery_journal", "scope": "world", "realm": realm,
			"delivery_id": delivery_id, "delivery": delivery})
		ops.append({"op": "reward_delivery", "scope": "player", "realm": realm,
			"peers": [target], "delivery": delivery})
	if paid.is_empty():
		return _refuse("reward_grant", peer_id, "already_taken", "That reward has already been claimed.")
	var verdict := _commit(ops, "reward_grant", peer_id, realm)
	verdict["paid"] = paid
	return verdict


## Doss's Meadows repair is one host-arbitrated exchange: the first valid
## claimant pays, repairs the shared perch and receives both personal rewards.
## Every operation is in the same delta, so a losing race changes nothing.
func _river_nest_clear(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var kind := "river_nest_clear"
	var actor: Variant = intent.get("_doss_actor", {})
	if realm != "meadows" or not actor is Dictionary \
			or str((actor as Dictionary).get("realm", "")) != "meadows":
		return _refuse(kind, peer_id, "wrong_realm", "Reach Doss's river perch first.")
	if int((actor as Dictionary).get("peer", 0)) != peer_id \
			or str((actor as Dictionary).get("character_id", "")).is_empty():
		return _refuse(kind, peer_id, "unknown_character", "Your character is not connected.")
	var position: Variant = (actor as Dictionary).get("position")
	if not position is Vector3 or not (position as Vector3).is_finite() \
			or Vector2((position as Vector3).x, (position as Vector3).z).distance_to(Vector2(DOSS_AT.x, DOSS_AT.z)) > DOSS_INTERACTION_RADIUS_M:
		return _refuse(kind, peer_id, "too_far", "Move closer to Doss's bank perch.")
	if _flag_set(DOSS_FLAG):
		return _refuse(kind, peer_id, "already_taken", "The bank perch is already repaired.")
	var slots: Variant = (actor as Dictionary).get("inventory_slots", [])
	if not SATCHEL_RULES.valid_slots(slots):
		return _refuse(kind, peer_id, "malformed", "Your satchel could not be checked.")
	var trial := SATCHEL_RULES.inventory_from(slots as Array)
	for item: String in DOSS_COST:
		if int(trial.call("count", item)) < int(DOSS_COST[item]):
			return _refuse(kind, peer_id, "materials", "Bring one wood and one fiber for the repair.")
		trial.call("remove", item, int(DOSS_COST[item]))
	for item: String in DOSS_REWARDS:
		if int(trial.call("add", item, int(DOSS_REWARDS[item]))) != 0:
			return _refuse(kind, peer_id, "no_room", "Make room for Doss's full reward first.")
	var character_id := str((actor as Dictionary).get("character_id", ""))
	var world_namespace := str(world.get("reward_delivery_namespace"))
	if world_namespace.is_empty():
		world_namespace = Crypto.new().generate_random_bytes(16).hex_encode()
	var world_id := str(world.get("world_id"))
	var provenance_world_id := world_id if not world_id.is_empty() else "instance:" + world_namespace
	var ops: Array = [_world_flag(realm, DOSS_FLAG)]
	for item: String in DOSS_COST:
		ops.append(_item_take(peer_id, item, int(DOSS_COST[item])))
	for item: String in DOSS_REWARDS:
		var source := "river_nest_doss:%s" % item
		var delivery := REWARD_DELIVERY.make_record(provenance_world_id, world_namespace,
			source, character_id, item, int(DOSS_REWARDS[item]))
		if delivery.is_empty():
			return _refuse(kind, peer_id, "malformed", "Doss's reward could not be recorded.")
		var delivery_id := str(delivery.get("delivery_id", ""))
		if (world.get("reward_deliveries") as Dictionary).has(delivery_id):
			return _refuse(kind, peer_id, "already_taken", "Doss's reward was already claimed.")
		ops.append({"op": "reward_delivery_journal", "scope": "world", "realm": realm,
			"delivery_id": delivery_id, "delivery": delivery})
		ops.append({"op": "reward_delivery", "scope": "player", "realm": realm,
			"peers": [peer_id], "delivery": delivery})
	return _commit(ops, kind, peer_id, realm)


func _legacy_receipt_only_reward(intent: Dictionary, peer_id: int, realm: String,
		source: String) -> Dictionary:
	var ops: Array = []
	var paid: Array = []
	for raw: Variant in _peers(intent, peer_id):
		var target := int(raw)
		var receipt := reward_flag(source, target)
		if _flag_set(receipt):
			continue
		paid.append(target)
		ops.append(_world_flag(realm, receipt))
	if paid.is_empty():
		return _refuse("reward_grant", peer_id, "already_taken", "That reward has already been claimed.")
	var verdict := _commit(ops, "reward_grant", peer_id, realm)
	verdict["paid"] = paid
	return verdict


func accept_reward_delivery(delivery_id: String, character_id: String, peer_id: int) -> Dictionary:
	var raw: Variant = (world.get("reward_deliveries") as Dictionary).get(delivery_id)
	if delivery_id.is_empty() or character_id.is_empty() or not raw is Dictionary \
			or str((raw as Dictionary).get("character_id", "")) != character_id:
		return _refuse("reward_delivery_accept", peer_id, "invalid_recipient",
			"That reward acknowledgement does not belong to this character.")
	if str((raw as Dictionary).get("status", "")) == "accepted":
		return {"ok": true, "kind": "reward_delivery_accept", "peer": peer_id,
			"code": "noop", "reason": "", "pending": false,
			"delta": {"seq": seq, "realm": "", "ops": []}}
	if str((raw as Dictionary).get("status", "")) != "pending":
		return _refuse("reward_delivery_accept", peer_id, "invalid_receipt",
			"That reward acknowledgement is not pending.")
	return _commit([{"op": "reward_delivery_accept", "scope": "world",
		"delivery_id": delivery_id, "character_id": character_id}],
		"reward_delivery_accept", peer_id, str((raw as Dictionary).get("realm", "")))


func _has_legacy_reward_receipt(source: String) -> bool:
	var flags: Variant = world.get("flags")
	if flags == null:
		return false
	var saved: Variant = (flags as RefCounted).call("save_data")
	if not saved is Dictionary:
		return false
	var prefix := "reward:%s:" % source
	for raw: Variant in (saved as Dictionary).get("flags", []):
		if not raw is String or not (raw as String).begins_with(prefix):
			continue
		var suffix := (raw as String).substr(prefix.length())
		if suffix.is_valid_int() and int(suffix) > 0 and str(int(suffix)) == suffix:
			return true
	return false


# --- flag ids, shared with the consumers ---------------------------------------

## The world fact "this scattered placement is gone". Realm-qualified so two
## stacked worlds cannot share a bush.
static func vegetation_flag(realm: String, layer: String, index: int) -> String:
	return "vegetation:%s:%s#%d" % [realm, layer, index]


## The world fact "this participant has been paid for this victory" (D106).
static func reward_flag(source: String, peer_id: int) -> String:
	return "reward:%s:%d" % [source, peer_id]


# --- internals ------------------------------------------------------------------

func _stormwood_relight_arch(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var kind := "stormwood_relight_arch"
	var id := str(intent.get("id", ""))
	var arch := STORMWOOD_ARCHES.definition(id)
	if realm != "stormwood" or arch.is_empty():
		return _refuse(kind, peer_id, "invalid_arch", "That arch does not belong to this road.")
	if not STORMWOOD_ARCHES.is_available(arch, world.get("flags")):
		return _refuse(kind, peer_id, "gated", "The Rootgate must open before this road can be relit.")
	if STORMWOOD_ARCHES.is_lit(arch, world.get("flags")):
		return _refuse(kind, peer_id, "already_lit", "That arch is already alight.")
	var cost := int(STORMWOOD_ARCHES.config().relight_cost)
	if int(intent.get("available_stormglass", 0)) < cost:
		return _refuse(kind, peer_id, "materials", "Relighting this arch needs %d Stormglass." % cost)
	# The character inventory uses the established per-peer delta path. The
	# flag and cost are a single winning commit; a competing claimant pays none.
	return _commit([_world_flag(realm, STORMWOOD_ARCHES.lit_flag(id)), _item_take(peer_id, "stormglass", cost)], kind, peer_id, realm)


func _flag_set(id: String) -> bool:
	var flags: Variant = world.get("flags")
	return flags != null and bool((flags as RefCounted).call("has", id))


func _world_flag(realm: String, id: String, value: bool = true) -> Dictionary:
	return {"op": "flag", "scope": "world", "realm": realm, "id": id, "value": value}


func _item_grant(peer_id: int, item: String, count: int, txn: String = "") -> Dictionary:
	var op := {"op": "item_grant", "scope": "player", "peers": [peer_id], "item": item, "count": count}
	if not txn.is_empty():
		op["txn_id"] = txn
	return op


func _item_take(peer_id: int, item: String, count: int, txn: String = "") -> Dictionary:
	var op := {"op": "item_take", "scope": "player", "peers": [peer_id], "item": item, "count": count}
	if not txn.is_empty():
		op["txn_id"] = txn
	return op


## The peers an intent addresses: an explicit `peers` array, a single `peer`,
## or -- for the ordinary single-player case -- whoever asked.
func _peers(intent: Dictionary, peer_id: int) -> Array:
	var raw: Variant = intent.get("peers")
	if typeof(raw) == TYPE_ARRAY:
		var out: Array = []
		for entry: Variant in (raw as Array):
			var id := int(entry)
			if not out.has(id):
				out.append(id)
		return out
	if intent.has("peer"):
		return [int(intent.get("peer"))]
	return [peer_id]


## `[x, y, z]` whatever the caller had: `WorldState` stores positions as plain
## arrays so they survive JSON, and an intent that crossed the wire arrives as
## one already.
func _position(raw: Variant) -> Array:
	if typeof(raw) == TYPE_VECTOR3:
		var v := raw as Vector3
		return [v.x, v.y, v.z]
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() == 3:
		var a := raw as Array
		return [float(a[0]), float(a[1]), float(a[2])]
	return [0.0, 0.0, 0.0]


## Build the delta, apply it, and answer. Applying through `apply()` rather than
## mutating here is deliberate: the host and every client then run the exact
## same apply code over the exact same ops.
func _commit(ops: Array, kind: String, peer_id: int, realm: String) -> Dictionary:
	# One gate for every intent kind that writes a world flag: an owned receipt
	# can only be written (or cleared) by the character it names.
	for op: Variant in ops:
		if op is Dictionary and str((op as Dictionary).get("op", "")) == "flag" \
				and str((op as Dictionary).get("scope", "")) == "world" \
				and not owned_flag_allowed(str((op as Dictionary).get("id", "")), peer_id, _actor_character):
			return _refuse(kind, peer_id, "not_your_character",
				"Only that character can record their own choice.")
	seq += 1
	var delta := {"seq": seq, "realm": realm, "ops": ops}
	apply(delta)
	return {
		"ok": true, "kind": kind, "peer": peer_id, "code": "", "reason": "",
		"pending": false, "delta": delta,
	}


func _refuse(kind: String, peer_id: int, code: String, reason: String) -> Dictionary:
	return {
		"ok": false, "kind": kind, "peer": peer_id, "code": code, "reason": reason,
		"pending": false, "delta": {"seq": seq, "realm": "", "ops": []},
	}
