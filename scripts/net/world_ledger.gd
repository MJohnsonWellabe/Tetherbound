extends RefCounted

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


# --- the one entry point ------------------------------------------------------

## Validate `intent` and, if it survives, commit it. `peer_id` is who asked --
## the requesting peer on the host, the local peer solo.
func commit(intent: Dictionary, peer_id: int = 1) -> Dictionary:
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
		if str(op.get("op", "")) == "storage_set":
			_storage_revisions[str(op.get("container", ""))] = int(op.get("revision", 0))
		var txn := str(op.get("txn_id", ""))
		if not txn.is_empty():
			_seen_txns[txn] = true
	seq = maxi(seq, int(delta.get("seq", 0)))
	if world == null:
		return 0
	return int(world.call("apply_delta", delta))


## The revision a caller must quote in the next `storage_txn` for `container`.
func storage_revision(container: String) -> int:
	return int(_storage_revisions.get(container, 0))


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
	var op := {
		"op": "building_add",
		"scope": "world",
		"realm": realm,
		"id": id,
		"position": _position(intent.get("position")),
		"yaw_deg": float(intent.get("yaw_deg", 0.0)),
		"paid": bool(intent.get("paid", true)),
	}
	return _commit([op], "place_building", peer_id, realm)


## Removal by index into `placed_buildings`, which is the address
## `build_placer.gd` already stashes as node metadata and already removes by.
## Ordered delta application keeps every peer's indices in step; a stable id per
## record is lane 3.C's call to make, and would be a save-format change.
func _dismantle(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var index := int(intent.get("index", -1))
	var buildings: Array = world.get("placed_buildings") as Array
	if index < 0 or index >= buildings.size():
		return _refuse("dismantle", peer_id, "gone", "That structure is already gone.")
	var record: Dictionary = buildings[index] as Dictionary
	if str(record.get("realm", "meadows")) != realm:
		# Two peers in two realms, both holding index 4. Refusing is the only
		# safe answer: the record at that index is not the one being pointed at.
		return _refuse("dismantle", peer_id, "gone", "That structure is already gone.")
	return _commit([{"op": "building_remove", "scope": "world", "realm": realm, "index": index}],
		"dismantle", peer_id, realm)


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


## D106: a shared victory pays EVERY participant, once each. The world remembers
## who has been paid (`reward:<source>:<peer>`), so a peer who reconnects and
## re-reports the same win is refused while the peers who have not been paid
## still are.
func _reward_grant(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var source := str(intent.get("source", ""))
	if source.is_empty():
		return _refuse("reward_grant", peer_id, "malformed", "That reward has no source to record.")
	var peers := _peers(intent, peer_id)
	if peers.is_empty():
		return _refuse("reward_grant", peer_id, "malformed", "There is nobody to reward.")
	var item := str(intent.get("item", ""))
	var count := maxi(1, int(intent.get("count", 1)))
	var flag_id := str(intent.get("flag", ""))
	var ops: Array = []
	var paid: Array = []
	for raw: Variant in peers:
		var target := int(raw)
		var receipt := reward_flag(source, target)
		if _flag_set(receipt):
			continue
		paid.append(target)
		ops.append(_world_flag(realm, receipt))
		if not item.is_empty():
			ops.append(_item_grant(target, item, count))
		if not flag_id.is_empty():
			ops.append({"op": "flag", "scope": "player", "realm": realm, "id": flag_id,
				"value": true, "peers": [target]})
	if paid.is_empty():
		return _refuse("reward_grant", peer_id, "already_taken", "That reward has already been claimed.")
	var verdict := _commit(ops, "reward_grant", peer_id, realm)
	verdict["paid"] = paid
	return verdict


# --- flag ids, shared with the consumers ---------------------------------------

## The world fact "this scattered placement is gone". Realm-qualified so two
## stacked worlds cannot share a bush.
static func vegetation_flag(realm: String, layer: String, index: int) -> String:
	return "vegetation:%s:%s#%d" % [realm, layer, index]


## The world fact "this participant has been paid for this victory" (D106).
static func reward_flag(source: String, peer_id: int) -> String:
	return "reward:%s:%d" % [source, peer_id]


# --- internals ------------------------------------------------------------------

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
