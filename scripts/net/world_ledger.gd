extends RefCounted
const ACTOR_VITALS := preload("res://scripts/net/actor_vitals_delivery.gd")

const STORMWOOD_ARCH_BUILD := preload("res://scripts/world/stormwood_arch_build_rules.gd")
const HOMESTEAD_BUILDING := preload("res://scripts/net/homestead_building_delivery.gd")

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
## Must equal playground_world.gd::RIVER_NEST_AT (F03 moved both; pinned by
## tests/test_world_ledger_races.gd).
const DOSS_AT := Vector3(-22.0, 0.0, 4166.0)
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

func commit_foundation_event(row: Dictionary) -> Dictionary:
	if world == null or not preload("res://scripts/net/foundation_event.gd").valid(row, world.reward_delivery_namespace, world.world_id): return {"ok": false}
	if world.reward_deliveries.has(row.delivery_id):
		return {"ok": world.reward_deliveries[row.delivery_id] == row, "duplicate": true}
	return _commit([{"op": "foundation_event_journal", "scope": "world", "delivery_id": row.delivery_id, "delivery": row.duplicate(true)}], "foundation_event", 1, "")

func commit_alpha_plan(plan: Dictionary) -> Dictionary:
	if world == null or not preload("res://scripts/repeatables/alpha_respawns.gd").valid_plan(plan, world.redesign_world, world.reward_delivery_namespace): return {"ok": false}
	return _commit([{"op": "alpha_cycle", "scope": "world", "world_namespace": world.reward_delivery_namespace,
		"plan": plan.duplicate(true)}], plan.operation, HOST_PEER, "")


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
	# Solmane (owner ruling 2026-09-27, #356 5858140459): Cloudreach's freed
	# legendary reuses stronghold_climax.gd with these receipts.
	"cloudreach:legendary_resolution:accepted:",
	"cloudreach:legendary_resolution:refused:",
]
const MULTIPLAYER_CONFIG := "res://data/config/multiplayer.json"
## Configured prefixes must name a legendary resolution receipt, so a broad
## entry such as "stormwood:" cannot silently lock ordinary world flags.
const OWNED_FLAG_PREFIX_MARK := "legendary_resolution:"
const HOST_PEER := preload("res://scripts/net/peer_registry.gd").HOST_PEER_ID
const DROPPED_FLAG_PREFIX := "dropped:" # dropped_item.gd FLAG_PREFIX
const PICKUP_SPECS := preload("res://scripts/net/pickup_spec_registry.gd")
const GATHER_BATCHES := preload("res://scripts/net/gather_batches.gd")
const FELLED_FLAG_PREFIX := "felled:" # felled_resource.gd flag_id
## `reward_grant` sources only host code may journal. These trainers' delivery
## rows are the Guardian's and the Warden climax's participant journals, and
## since client trainer wins are host-journaled (`trainer_victory`) the host is
## their only honest writer. Deliberately not every `trainer:` source: a
## guest's own local named-wild completion reward is journaled under
## `trainer:<once id>:` too. (A guest can still ASK the host to journal a win
## through `trainer_victory`; that request's own checks are the director's.)
const HOST_ONLY_GRANT_SOURCE_PREFIXES := [
	"trainer:water_trainer_nerissa:",
	"trainer:warden_aldis:",
	# Solmane's participant journal: Captain Veyra's per-participant payout.
	"trainer:captain_veyra_storm_anchor:",
]
## World flags only host code may write or clear. The Tidewake Guardian's
## claim markers, its claimed/settled/freed facts and its settlement flags
## decide who is offered the Guardian (a settlement flag with no offer marker
## makes the world "legacy"); the host writes every one of them
## (`water_guardian_reward.gd`), so a remote write can only be a forgery. The
## legacy `reward:<source>:<n>` receipts of the journals above are included:
## one forged receipt makes every later grant of that source
## `legacy_unresolved`, emptying the journal. Matched as prefixes, so the two
## exact settlement ids also cover any future flag named after them.
const HOST_ONLY_FLAG_PREFIXES := [
	"water_claim:guardian:",
	"water_guardian_",
	"water_currents_restored",
	"realm_relic_water_earned",
	"reward:trainer:water_trainer_nerissa:",
	"reward:trainer:warden_aldis:",
	"reward:trainer:captain_veyra_storm_anchor:",
]

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


static func host_only_allowed(id: String, peer_id: int, prefixes: Array) -> bool:
	if peer_id == HOST_PEER:
		return true
	for prefix: String in prefixes:
		if id.begins_with(prefix):
			return false
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
		"ripplet_sunken_claim":
			return _ripplet_sunken_claim(intent, peer_id, realm)
		"stormwood_disable_rod":
			return _stormwood_disable_rod(intent, peer_id, realm)
		"stormwood_harvest":
			return _stormwood_harvest(intent, peer_id, realm)
		"stormwood_relight_arch":
			return _stormwood_relight_arch(intent, peer_id, realm)
		"death_satchel_create", "death_satchel_transfer":
			return _death_satchel_intent(intent, peer_id, realm)
		"water_dock_action":
			# The HOST's own world identity, never the request's: an escrowed
			# dock payment for another world (or a hand-made one) is refused.
			var dock_actor: Dictionary = (intent.get("_water_actor", {}) as Dictionary).duplicate() \
				if intent.get("_water_actor", {}) is Dictionary else {}
			var host_instance: Variant = world.get("reward_delivery_namespace")
			dock_actor["world_instance_id"] = host_instance as String \
				if typeof(host_instance) == TYPE_STRING else ""
			var result: Dictionary = preload("res://scripts/world/water_dock_rules.gd").evaluate(intent, dock_actor, world.flags)
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
		"gather_flush":
			return _gather_flush(intent, peer_id, realm)
		"gather_mark":
			return _gather_mark(intent, peer_id, realm)
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
	if flag.begins_with("cache:ripplet:"):
		return _refuse("claim_pickup", peer_id, "typed_claim_required", "Dive to gather this sunken find.")
	if flag.is_empty():
		return _refuse("claim_pickup", peer_id, "malformed", "That find has no identity to record.")
	if _flag_set(flag):
		return _refuse("claim_pickup", peer_id, "already_taken", "Someone else got there first.")
	var ops: Array = [_world_flag(realm, flag)]
	var item := str(intent.get("item", ""))
	var count := maxi(1, int(intent.get("count", 1)))
	if not item.is_empty():
		var character_id := str(intent.get("_actor_character_id", ""))
		# Without an admitted character (no session identity to key the receipt
		# on), or for a find the host's world never stood up (nothing to check
		# the request against), the claim keeps the direct local-only grant, as
		# before; it never reaches the host's character authority.
		if peer_id != HOST_PEER and guest_pickup_routed(flag) and not character_id.is_empty() \
				and not PICKUP_SPECS.lookup(flag).is_empty():
			# A guest's find is a personal grant from a world source: a journaled
			# reward delivery, so the host's character authority gains it exactly
			# once when the guest applies and saves it (owner_passive_sync's
			# reward_delivery_applied). A bare item_grant would reach only the
			# guest's local satchel. The host and solo keep the direct grant.
			# _commit's flag gates decide first, as for any flag writer.
			var gated := _flag_gate(ops, "claim_pickup", peer_id)
			if not gated.is_empty():
				return gated
			if flag.begins_with(FELLED_FLAG_PREFIX) and GATHER_BATCHES.enabled():
				# A felled pile is a frequent gather: it accrues into the guest's
				# open batch instead of journaling one delivery per pile.
				var pile := PICKUP_SPECS.lookup(flag)
				return _guest_gather(ops, "claim_pickup", peer_id, realm, character_id, str(pile.item), int(pile.count))
			# The host's own world says what this find holds; the request's item
			# and count are never trusted on this path (review: a forged claim
			# would otherwise mint into the host's record).
			var spec := PICKUP_SPECS.lookup(flag)
			var delivery := guest_pickup_delivery(world, flag, character_id, str(spec.item), int(spec.count))
			if delivery.is_empty():
				return _refuse("claim_pickup", peer_id, "world_not_ready", "Save this world before gathering.")
			if (world.get("reward_deliveries") as Dictionary).has(str(delivery.delivery_id)):
				return _refuse("claim_pickup", peer_id, "already_taken", "Someone else got there first.")
			ops.append({"op": "reward_delivery_journal", "scope": "world", "realm": realm,
				"delivery_id": delivery.delivery_id, "delivery": delivery})
			ops.append({"op": "reward_delivery", "scope": "player", "realm": realm,
				"peers": [peer_id], "delivery": delivery})
		else:
			ops.append(_item_grant(peer_id, item, count))
	return _commit(ops, "claim_pickup", peer_id, realm)


## Whether a guest's claim of this find pays through a reward delivery. A
## player-dropped stack (dropped_item.gd) is excluded: its drop left only the
## dropper's local satchel, so granting its pickup to the character authority
## would mint an item the authority never lost.
static func guest_pickup_routed(flag: String) -> bool:
	return not flag.is_empty() and not flag.begins_with(DROPPED_FLAG_PREFIX)


## The reward-delivery record for a guest's one-time find: receipt
## (world-instance namespace, "claim_pickup:<flag>", character_id). Empty when
## the world has no saved identity or the guest's character is unknown.
static func guest_pickup_delivery(world_state: RefCounted, flag: String, character_id: String,
		item: String, count: int) -> Dictionary:
	if world_state == null or character_id.is_empty() or flag.is_empty() or item.is_empty():
		return {}
	var namespace_id := str(world_state.get("reward_delivery_namespace"))
	var world_id := str(world_state.get("world_id"))
	if namespace_id.is_empty() or world_id.is_empty():
		return {}
	return REWARD_DELIVERY.make_record(world_id, namespace_id, "claim_pickup:" + flag, character_id, item, count)

func _ripplet_sunken_claim(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	var actor: Dictionary = intent.get("_ripplet_actor", {})
	if realm != "water" or actor.get("peer") != peer_id:
		return _refuse("ripplet_sunken_claim", peer_id, "wrong_actor", "Reach the sunken find first.")
	var result: Dictionary = preload("res://scripts/world/ripplet_sunken_rules.gd").evaluate(intent, actor, world.flags, world.day)
	if not result.get("ok", false): return _refuse("ripplet_sunken_claim", peer_id, "refused", str(result.reason))
	var namespace_id := str(world.reward_delivery_namespace)
	if namespace_id.is_empty() or str(world.world_id).is_empty(): return _refuse("ripplet_sunken_claim", peer_id, "world_not_ready", "Save this world before gathering.")
	var ops: Array = [_world_flag("water", str(result.key))]
	if not str(result.previous).is_empty(): ops.append(_world_flag("water", str(result.previous), false))
	for item: String in result.outputs:
		var source := str(result.key) + ":" + item if result.outputs.size() > 1 else str(result.key)
		var delivery := REWARD_DELIVERY.make_record(str(world.world_id), namespace_id, source, str(result.character_id), item, int(result.outputs[item]))
		if delivery.is_empty() or world.reward_deliveries.has(str(delivery.delivery_id)):
			return _refuse("ripplet_sunken_claim", peer_id, "already_taken", "Someone already gathered this find.")
		ops.append({"op":"reward_delivery_journal", "scope":"world", "realm":"water", "delivery_id":delivery.delivery_id, "delivery":delivery})
		ops.append({"op":"reward_delivery", "scope":"player", "realm":"water", "peers":[peer_id], "delivery":delivery})
	return _commit(ops, "ripplet_sunken_claim", peer_id, "water")


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
	var character_id := str(intent.get("_actor_character_id", ""))
	var node_spec := PICKUP_SPECS.lookup(flag)
	if not item.is_empty() and amount > 0 and guest_batches(peer_id, character_id) and not node_spec.is_empty():
		# A guest's harvest of a node the host's world stood up: the host's item
		# and one of its legal yields, accrued into the guest's open batch.
		return _guest_gather(ops, "harvest", peer_id, realm, character_id, str(node_spec.item), PICKUP_SPECS.legal_amount(node_spec, amount))
	if not item.is_empty() and amount > 0:
		ops.append(_item_grant(peer_id, item, amount))
	return _commit(ops, "harvest", peer_id, realm)


## Coordinator ruling (b): whether a gather by this peer accrues into a batch.
## Only a guest with an admitted character; the host and solo keep the
## immediate grant.
static func guest_batches(peer_id: int, character_id: String) -> bool:
	return peer_id != HOST_PEER and not character_id.is_empty() and GATHER_BATCHES.enabled()


## A guest's frequent gather: the world flag(s) plus one gather_accrue into its
## open batch (gather_batches.gd). The host flushes the batch as one reward
## delivery (gather_flush); nothing reaches a satchel here.
func _guest_gather(ops: Array, kind: String, peer_id: int, realm: String, character_id: String, item: String, count: int) -> Dictionary:
	var gated := _flag_gate(ops, kind, peer_id)
	if not gated.is_empty():
		return gated
	if str(world.get("reward_delivery_namespace")).is_empty() or str(world.get("world_id")).is_empty():
		return _refuse(kind, peer_id, "world_not_ready", "Save this world before gathering.")
	if GATHER_BATCHES.accrued(GATHER_BATCHES.batch(world.redesign_world, character_id), item, count).is_empty():
		return _refuse(kind, peer_id, "batch_full", "Your gathering is still arriving; try again in a moment.")
	ops.append({"op": "gather_accrue", "scope": "world", "realm": realm,
		"character_id": character_id, "item": item, "count": count})
	return _commit(ops, kind, peer_id, realm)


## Host only: journal a character's open batch as one reward delivery to
## `target_peer` (the character's connected peer).
func _gather_flush(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	if peer_id != HOST_PEER:
		return _refuse("gather_flush", peer_id, "host_only", "Only the host can record that.")
	var character := str(intent.get("character_id", ""))
	var target := int(intent.get("target_peer", 0))
	var row := GATHER_BATCHES.batch(world.redesign_world, character)
	var delivery := GATHER_BATCHES.flush_delivery(row, str(world.get("world_id")),
		str(world.get("reward_delivery_namespace")), character)
	if character.is_empty() or delivery.is_empty():
		return _refuse("gather_flush", peer_id, "nothing_open", "There is nothing to deliver.")
	# A departed guest has no peer to address: the pending row waits in the
	# world and its rejoin's reward reconciliation applies it.
	# (An empty `peers` list means everyone, so a departed guest gets no player op.)
	var flush_ops: Array = [{"op": "gather_flush", "scope": "world", "realm": realm, "character_id": character,
		"seq": int(row.next_seq), "delivery_id": delivery.delivery_id, "delivery": delivery}]
	if target > 0:
		flush_ops.append({"op": "reward_delivery", "scope": "player", "realm": realm, "peers": [target], "delivery": delivery})
	return _commit(flush_ops, "gather_flush", peer_id, realm)


## Host only: advance a character's acked or replayed batch mark (pruning rows
## at or below both).
func _gather_mark(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
	if peer_id != HOST_PEER:
		return _refuse("gather_mark", peer_id, "host_only", "Only the host can record that.")
	var character := str(intent.get("character_id", ""))
	var mark := str(intent.get("mark", ""))
	var seq_mark := int(intent.get("seq", -1))
	if GATHER_BATCHES.marked(GATHER_BATCHES.batch(world.redesign_world, character), mark, seq_mark).is_empty():
		return _refuse("gather_mark", peer_id, "invalid_mark", "That batch mark is invalid.")
	return _commit([{"op": "gather_mark", "scope": "world", "realm": realm,
		"character_id": character, "mark": mark, "seq": seq_mark}], "gather_mark", peer_id, realm)


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
	var character_id := str(intent.get("_actor_character_id", ""))
	if guest_batches(peer_id, character_id):
		return _guest_gather([_world_flag(realm, flag)], kind, peer_id, realm, character_id, str(site.item), int(site.amount))
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
	if id == "forward_camp": return _refuse("place_building",peer_id,"camp_transaction_required","Forward camps need the host's paid kit transaction.")
	if id == "altar": return _refuse("place_building", peer_id, "altar_transaction_required", "The Altar needs its paid transaction.")
	if HOMESTEAD_BUILDING.requires_journal(id): return _refuse("place_building", peer_id, "station_transaction_required", "Homestead stations need their paid transaction.")
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
	if record.get("id") == "forward_camp": return _refuse("dismantle",peer_id,"camp_transaction_required","Pack up the camp through its host kit transaction.")
	if record.get("id") == "altar": return _refuse("dismantle", peer_id, "altar_transaction_required", "The Altar needs its paid transaction.")
	# F31: no legacy refund or free removal of a gated homestead record; a
	# journaled one leaves only through its own paid-provenance refund row.
	if HOMESTEAD_BUILDING.requires_journal(record.get("id")) or HOMESTEAD_BUILDING.record_valid(record):
		return _refuse("dismantle", peer_id, "station_transaction_required", "Homestead stations need their paid transaction.")
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
	# Ceremony markers release retained personal boss drops. Only the host's
	# validated settlement controllers may publish them; an admitted guest's
	# generic flag RPC must not skip the ceremony or clear a saved settlement.
	if peer_id != HOST_PEER and load("res://scripts/net/encounter_rewards.gd").call("is_chapter_settlement_flag", id):
		return _refuse("set_world_flag", peer_id, "host_boss_settlement_required", "The host must save the ceremony's outcome first.")
	if id.begins_with("cache:ripplet:"):
		return _refuse("set_world_flag", peer_id, "typed_claim_required", "Sunken finds use their own claim receipt.")
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
	if SATCHEL_RULES.protected_key(str(intent.get("item", ""))):
		return _refuse("transfer_item", peer_id, "protected_key", "Keys stay with their owner.")
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
	if SATCHEL_RULES.protected_key(str(intent.get("item", ""))):
		return _refuse("drop_item", peer_id, "protected_key", "Keys stay with their owner.")
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
	if not host_only_allowed(source, peer_id, HOST_ONLY_GRANT_SOURCE_PREFIXES):
		return _refuse("reward_grant", peer_id, "host_only", "Only the host can record that reward.")
	if peer_id != HOST_PEER:
		var refusal := client_grant_refusal(intent, world.get("flags"))
		if not refusal.is_empty():
			return _refuse("reward_grant", peer_id, str(refusal.code), str(refusal.reason))
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


## --- A GUEST's own reward_grant ------------------------------------------------
##
## A client may ask the host to journal only the rewards the game really pays a
## guest on its own machine, and only what the game authored for them. Every
## other grant is the host's to make (trainer wins arrive as `trainer_victory`,
## shared fights are host-run). For each source a guest may send:
##   * the item, count and personal flag must equal the authored payout, so a
##     changed `source`, `item` or `count` mints nothing (the delivery id folds
##     item/count/flag in, so any other value would otherwise be a NEW delivery);
##   * the activity must already be complete in the HOST's world;
##   * where the payout has a fixed place, the host's own copy of the guest's
##     body must be there (`_reward_actor`, built by ledger_rpc.gd, never read
##     from the request).
## The recipient is always the sender alone (ledger_rpc.gd `_reward_recipients`).
## Named-wild once-only rewards (`trainer:<once id>:...`) are a guest's own local
## fight: `<once id>` must be a real once id and the component must be exactly
## that id's authored `completion_reward` (`once_reward_components`).
const CLIENT_GRANT_SOURCES := {
	# scripts/world/cart_repair.gd REWARD_SOURCE / REWARD_COINS; paid after the
	# host's delta sets the repaired flag.
	"broken_cart_coll:repair": {"item": "coin", "count": 25, "flag": "",
		"requires_any": ["band1_broken_cart_repaired"]},
	# scripts/world/stormwood_pims_parcels.gd REWARD_*; claim_reward() pays on
	# the complete flag or the second step.
	"stormwood_pims_parcels": {"item": "potion_small", "count": 2, "flag": "",
		"requires_any": ["stormwood:side_pims_parcels_complete", "stormwood:side_pims_parcels_2"]},
	# scripts/world/stormwood_rook_circuit_reward.gd REWARD_*; claim_reward() pays on
	# the complete flag or the second step (owner ruling 2026-09-26: Thunder Break).
	"stormwood_deepwood_circuit": {"item": "tm_thunder_break", "count": 1, "flag": "",
		"requires_any": ["stormwood:side_deepwood_circuit_complete", "stormwood:side_deepwood_circuit_2"]},
}
const CLOUDREACH_RUNTIME := "res://data/config/cloudreach_physical_runtime.json"
## scripts/world/meadowhart_herd_visit.gd REVEAL_FLAG / COMPLETE_FLAG.
const MEADOWHART_REVEAL_FLAG := "band1_meadowhart_herd_met"
const MEADOWHART_FOUND_FLAG := "band1_meadowhart_herd_found"
const OBJECTIVES := "res://data/progression/objectives.json"
## The claim bag's prompt reach plus a margin for the proxy's lag.
const CLIENT_GRANT_REACH_M := 8.0
const ONCE_REWARD_BAND_DIR := "res://data/config/bands"
const STORMWOOD_NAMED := "res://scripts/combat/stormwood_encounter_catalogue.gd"
const WARRENS_CONFIG := "res://data/config/burrow_warrens.json"
static var _client_grant_table: Dictionary = {}
static var _once_reward_table: Dictionary = {}


## Every source a guest may send, with its authored payout and conditions.
static func client_grant_sources() -> Dictionary:
	if not _client_grant_table.is_empty():
		return _client_grant_table
	var table: Dictionary = CLIENT_GRANT_SOURCES.duplicate(true)
	var cloudreach: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLOUDREACH_RUNTIME))
	if cloudreach is Dictionary:
		for raw: Variant in ((cloudreach as Dictionary).get("activity_rewards", []) as Array):
			if not raw is Dictionary:
				continue
			var row := raw as Dictionary
			var at: Array = row.get("position", []) as Array
			table[str(row.get("source", ""))] = {"item": str(row.get("item_id", "")),
				"count": int(row.get("count", 0)), "flag": str(row.get("claimed_flag", "")),
				"requires_any": [str(row.get("requires_unlock", ""))] if not str(row.get("requires_unlock", "")).is_empty() else [],
				"realm": "cloudreach",
				"at": Vector3(float(at[0]), float(at[1]), float(at[2])) if at.size() == 3 else Vector3.INF}
	var objectives: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES))
	if objectives is Dictionary:
		for raw: Variant in ((objectives as Dictionary).get("local", []) as Array):
			if not raw is Dictionary or not (raw as Dictionary).get("visit") is Dictionary:
				continue
			var visit: Dictionary = (raw as Dictionary).get("visit")
			if str(visit.get("reward_source", "")).is_empty():
				continue
			# scripts/world/meadowhart_herd_visit.gd: the grant sets the personal
			# COMPLETE_FLAG, and the world REVEAL_FLAG is written just before it
			# on the same reliable channel. The landmark reach is client-checked.
			# The visit pays one grant per part (its `reward_parts`): a lone part
			# under the bare source, several as "<source>:<item>", with the
			# completion flag only on the last part. Mirrored here, not preloaded,
			# so this ledger does not depend on a world script.
			var parts: Array = []
			var listed: Variant = visit.get("rewards", [])
			if listed is Array and not (listed as Array).is_empty():
				for part: Variant in listed:
					if part is Dictionary and int((part as Dictionary).get("count", 0)) > 0:
						parts.append({"item": str((part as Dictionary).get("item", "")),
							"count": int((part as Dictionary).get("count", 0))})
			else:
				parts.append({"item": str(visit.get("reward_item", "orb_basic")),
					"count": int(visit.get("reward_count", 3))})
			var base := str(visit.reward_source)
			for index in parts.size():
				var part_row: Dictionary = parts[index]
				var key := base if parts.size() == 1 else "%s:%s" % [base, part_row.item]
				table[key] = {"item": part_row.item, "count": part_row.count,
					"flag": MEADOWHART_FOUND_FLAG if index == parts.size() - 1 else "",
					"requires_any": [MEADOWHART_REVEAL_FLAG]}
	table.erase("")
	_client_grant_table = table
	return table


## Every named wild's authored once-only payout, keyed by the once id the
## encounter director pays it under (`_award_once_completion_reward`), as
## {once_id: {"coins": n, "items": {item_id: count}, "xp": bool}}:
## - band alpha/elder spawns: `wild_once_<order>`;
## - Stormwood named encounters: `wild_once_<named order>`;
## - Burrow Warrens named residents: `warrens_once_<nickname>`, and the
##   guardian's clear payout under its clear flag.
static func once_reward_components() -> Dictionary:
	if not _once_reward_table.is_empty():
		return _once_reward_table
	var table: Dictionary = {}
	var add := func(once_id: String, reward: Variant) -> void:
		if once_id.is_empty() or not reward is Dictionary:
			return
		var items: Dictionary = {}
		for entry: Variant in ((reward as Dictionary).get("items", []) as Array):
			if entry is Dictionary:
				items[str((entry as Dictionary).get("id", ""))] = maxi(1, int((entry as Dictionary).get("count", 1)))
		table[once_id] = {"coins": maxi(0, int((reward as Dictionary).get("coins", 0))), "items": items,
			"xp": int((reward as Dictionary).get("xp_bonus", 0)) > 0}
	var bands := DirAccess.open(ONCE_REWARD_BAND_DIR)
	if bands != null:
		for band: String in bands.get_directories():
			var band_spawns := "%s/%s/spawns.json" % [ONCE_REWARD_BAND_DIR, band]
			if not FileAccess.file_exists(band_spawns):
				continue
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(band_spawns))
			for raw: Variant in ((parsed as Dictionary).get("spawns", []) as Array if parsed is Dictionary else []):
				if not raw is Dictionary:
					continue
				# Alpha only, as the director pays it (`_configure_once_completion_reward`
				# is given the alpha block; an elder's reward is never paid).
				var named: Variant = (raw as Dictionary).get("alpha")
				if named is Dictionary and (named as Dictionary).has("completion_reward"):
					add.call("wild_once_%d" % int((raw as Dictionary).get("order", -1)),
						(named as Dictionary).get("completion_reward"))
	var stormwood: Script = load(STORMWOOD_NAMED)
	for raw: Variant in (stormwood.call("encounter_catalogue") as Dictionary).get("named_encounters", []):
		if raw is Dictionary and (raw as Dictionary).has("completion_reward"):
			add.call("wild_once_%d" % int(stormwood.call("named_order", str((raw as Dictionary).get("id", "")))),
				(raw as Dictionary).get("completion_reward"))
	var warrens: Variant = JSON.parse_string(FileAccess.get_file_as_string(WARRENS_CONFIG))
	if warrens is Dictionary:
		for raw: Variant in ((warrens as Dictionary).get("spawns", []) as Array):
			if raw is Dictionary and not str((raw as Dictionary).get("nickname", "")).is_empty():
				add.call("warrens_once_%s" % str((raw as Dictionary).nickname).to_lower().replace(" ", "_"),
					(raw as Dictionary).get("completion_reward"))
		var clear: Dictionary = (warrens as Dictionary).get("clear", {}) as Dictionary
		add.call(str(clear.get("flag", "warrens_cleared")), clear.get("reward"))
	_once_reward_table = table
	return table


## Why the host must refuse this GUEST's reward_grant, or {} when it may pay.
## Pure: `intent` carries the host-built `_reward_actor`; `flags` is the host
## world's flag store (anything with `has(id)`).
static func client_grant_refusal(intent: Dictionary, flags: Variant) -> Dictionary:
	var source := str(intent.get("source", ""))
	var item := str(intent.get("item", ""))
	var count := int(intent.get("count", 0)) if not item.is_empty() else 0
	var flag := str(intent.get("flag", ""))
	if source.begins_with("trainer:"):
		var parts := source.split(":")
		var once: Dictionary = once_reward_components().get(parts[1] if parts.size() >= 2 else "", {})
		var tail := parts[2] if parts.size() >= 3 else ""
		if not once.is_empty() and flag.is_empty():
			if parts.size() == 3 and tail == "xp" and item.is_empty() and bool(once.xp):
				return {}
			if parts.size() == 4 and tail == "item" and parts[3] == item \
					and int((once.items as Dictionary).get(item, 0)) == count and count > 0:
				return {}
			if parts.size() == 3 and tail == "coins" and item == "coin" and count > 0 \
					and int(once.coins) == count:
				return {}
		return {"code": "not_authored", "reason": "That reward was never offered to you."}
	var entry: Dictionary = client_grant_sources().get(source, {})
	if entry.is_empty():
		return {"code": "unknown_source", "reason": "Only the host can record that reward."}
	if item != str(entry.get("item", "")) or count != int(entry.get("count", 0)) or flag != str(entry.get("flag", "")):
		return {"code": "not_authored", "reason": "That reward was never offered like this."}
	var needs: Array = entry.get("requires_any", []) as Array
	if not needs.is_empty():
		var earned := false
		for id: Variant in needs:
			earned = earned or (flags != null and bool((flags as Object).call("has", str(id))))
		if not earned:
			return {"code": "not_earned", "reason": "That reward is not yours yet."}
	if entry.has("at") and (entry.at as Vector3) != Vector3.INF:
		var actor: Dictionary = intent.get("_reward_actor", {}) if intent.get("_reward_actor", {}) is Dictionary else {}
		var where: Variant = actor.get("position", null)
		if str(actor.get("realm", "")) != str(entry.get("realm", "")) or not where is Vector3 \
				or Vector2((where as Vector3).x, (where as Vector3).z).distance_to(
					Vector2((entry.at as Vector3).x, (entry.at as Vector3).z)) > CLIENT_GRANT_REACH_M:
			return {"code": "too_far", "reason": "Stand by the reward to claim it."}
	return {}


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
	# A guest's receipt is its own: never a `peers` list it wrote, which could
	# spend another player's XP receipt before the host pays them.
	for raw: Variant in (_peers(intent, peer_id) if peer_id == HOST_PEER else [peer_id]):
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


## Internal typed host arm; not recognized by _commit_intent/client packets.
func commit_actor_vitals_delivery(delivery: Dictionary, peer_id: int) -> Dictionary:
	var op := {"op": "actor_vitals_journal", "scope": "world",
		"delivery_id": str(delivery.get("delivery_id", "")), "delivery": delivery.duplicate(true)}
	if world == null or not ACTOR_VITALS.valid_world_op(op, world.get("reward_deliveries"),
		str(world.get("reward_delivery_namespace"))):
		return _refuse("actor_vitals", peer_id, "invalid_vitals", "That accepted vitality record is not ready.")
	return _commit([op, {"op": "actor_vitals_settle", "scope": "player", "peers": [peer_id],
		"delivery": delivery.duplicate(true)}], "actor_vitals", peer_id, "")


func accept_actor_vitals_delivery(id: String, character: String, journal_revision: int,
		receipt: Dictionary, peer_id: int) -> Dictionary:
	if character.is_empty():
		return _refuse("actor_vitals_accept", peer_id, "not_admitted", "This character has not been admitted.")
	var op := {"op": "actor_vitals_accept", "scope": "world", "delivery_id": id,
		"character_id": character, "journal_revision": journal_revision, "receipt": receipt.duplicate(true)}
	if world == null or not ACTOR_VITALS.valid_world_op(op, world.get("reward_deliveries"),
		str(world.get("reward_delivery_namespace"))):
		return _refuse("actor_vitals_accept", peer_id, "stale_vitals_ack", "That vitality receipt is no longer current.")
	return _commit([op], "actor_vitals_accept", peer_id, "")


func accept_reward_delivery(delivery_id: String, character_id: String, peer_id: int) -> Dictionary:
	if delivery_id.begins_with("portal_unlock:"):
		return _refuse("reward_delivery_accept", peer_id, "typed_receipt_required", "That portal receipt requires its exact sender and generation.")
	if delivery_id.begins_with("actor_vitals:") or delivery_id.begins_with("creature_training:") or delivery_id.begins_with("altar_building:"):
		return _refuse("reward_delivery_accept", peer_id, "typed_receipt_required", "That vitality receipt requires its exact revision.")
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
	var accept_ops: Array = [{"op": "reward_delivery_accept", "scope": "world",
		"delivery_id": delivery_id, "character_id": character_id}]
	var batch_seq := GATHER_BATCHES.seq_of(str((raw as Dictionary).get("source", "")))
	if batch_seq >= 1:
		# The guest saved this batch: close redelivery (gather_batches.gd marks).
		accept_ops.append({"op": "gather_mark", "scope": "world", "realm": "",
			"character_id": character_id, "mark": "acked", "seq": batch_seq})
	return _commit(accept_ops, "reward_delivery_accept", peer_id, str((raw as Dictionary).get("realm", "")))


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
	var gated := _flag_gate(ops, kind, peer_id)
	if not gated.is_empty():
		return gated
	seq += 1
	var delta := {"seq": seq, "realm": realm, "ops": ops}
	apply(delta)
	return {
		"ok": true, "kind": kind, "peer": peer_id, "code": "", "reason": "",
		"pending": false, "delta": delta,
	}


## One gate for every intent kind that writes a world flag: an owned receipt
## can only be written (or cleared) by the character it names. Empty when the
## ops pass; otherwise the refusal.
func _flag_gate(ops: Array, kind: String, peer_id: int) -> Dictionary:
	for op: Variant in ops:
		if op is Dictionary and str(op.get("op", "")) == "flag" \
				and str(op.get("scope", "")) == "world" \
				and str(op.get("id", "")).begins_with("cache:ripplet:") and kind != "ripplet_sunken_claim":
			return _refuse(kind, peer_id, "typed_ripplet_claim", "Reach that find with your diving Ripplet.")
		if op is Dictionary and str((op as Dictionary).get("op", "")) == "flag" \
				and str((op as Dictionary).get("scope", "")) == "world" \
				and not owned_flag_allowed(str((op as Dictionary).get("id", "")), peer_id, _actor_character):
			return _refuse(kind, peer_id, "not_your_character",
				"Only that character can record their own choice.")
		if op is Dictionary and str((op as Dictionary).get("op", "")) == "flag" \
				and str((op as Dictionary).get("scope", "")) == "world" \
				and not host_only_allowed(str((op as Dictionary).get("id", "")), peer_id, HOST_ONLY_FLAG_PREFIXES):
			return _refuse(kind, peer_id, "host_only", "Only the host can record that.")
	return {}


func _refuse(kind: String, peer_id: int, code: String, reason: String) -> Dictionary:
	return {
		"ok": false, "kind": kind, "peer": peer_id, "code": code, "reason": reason,
		"pending": false, "delta": {"seq": seq, "realm": "", "ops": []},
	}


## Internal host typed door; _commit_intent never accepts these op names.
func commit_creature_training_delivery(row: Dictionary, peer_id: int) -> Dictionary:
	if row.get("version") == 3 and row.get("action") == "camp_build": return _commit_foundation_camp(row, peer_id)
	if row.get("version") == 3 and row.get("action") == "resource": return _commit_foundation_resource(row, peer_id)
	var op := {"op": "creature_training_journal", "scope": "world", "delivery_id": row.get("delivery_id"), "delivery": row.duplicate(true)}
	if world == null or not preload("res://autoload/world_state.gd").training_world_op_valid(op,
		world.reward_deliveries, world.reward_delivery_namespace, world.world_id):
		return _refuse("creature_training", peer_id, "invalid_training", "That training decision is invalid.")
	var ops: Array = [op]
	if row.get("action") == "relic_hang": ops.append({"op": "foundation_shrine_display", "scope": "world", "delivery_id": row.delivery_id, "receipt": row.receipt, "biome": row.intent.biome})
	if row.get("action") == "dock_conclusion": ops.append({"op": "foundation_dock_departure", "scope": "world", "delivery_id": row.delivery_id, "receipt": row.receipt})
	ops.append({"op": "creature_training_settle", "scope": "player", "peers": [peer_id], "delivery": row.duplicate(true)})
	return _commit(ops, "creature_training", peer_id, "meadows")

func _commit_foundation_resource(row: Dictionary, peer: int) -> Dictionary:
	var journal := {"op": "creature_training_journal", "scope": "world", "delivery_id": row.get("delivery_id"), "delivery": row.duplicate(true)}
	if world == null or not preload("res://autoload/world_state.gd").training_world_op_valid(journal,
		world.reward_deliveries, world.reward_delivery_namespace, world.world_id):
		return _refuse("resource", peer, "invalid_resource_journal", "That resource decision changed.")
	var stock_op: Dictionary = world.call("resource_world_op", row)
	if stock_op.is_empty(): return _refuse("resource", peer, "resource_stock_changed", "That resource has changed. Try again.")
	return _commit([journal, stock_op,
		{"op": "creature_training_settle", "scope": "player", "peers": [peer], "delivery": row.duplicate(true)}],
		"resource", peer, stock_op.realm)

func _commit_foundation_camp(row: Dictionary, peer: int) -> Dictionary:
	if world == null or not preload("res://autoload/world_state.gd").training_row_valid(row, world.reward_delivery_namespace, world.world_id) \
		or row.status != "pending" or not preload("res://scripts/creatures/essence.gd")._equivalent(world.placed_buildings, row.host_context.world_before) \
		or int(world.next_building_uid) != row.host_context.next_building_uid: return {"ok": false, "code": "camp_world_changed"}
	var plan := preload("res://scripts/net/foundation_actions.gd").camp_plan(row.before, int(row.character_revision) - 1, row.intent, row.host_context)
	if plan.get("ok") != true: return plan
	var building_op: Dictionary = plan.record.duplicate(true) if row.intent.action == "place" else {"uid": plan.record.uid, "realm": plan.record.realm}
	building_op.op = "building_add" if row.intent.action == "place" else "building_remove"
	building_op.scope = "world"
	building_op.character_id = row.character_id
	building_op.txn_id = row.intent.action_id
	return _commit([{"op": "creature_training_journal", "scope": "world", "delivery_id": row.delivery_id, "delivery": row},
		building_op, {"op": "creature_training_settle", "scope": "player", "peers": [peer], "delivery": row}], "camp_build", peer, plan.record.realm)


func accept_creature_training_delivery(id: String, character: String, journal_revision: int,
		receipt: String, peer_id: int) -> Dictionary:
	var op := {"op": "creature_training_accept", "scope": "world", "delivery_id": id,
		"character_id": character, "journal_revision": journal_revision, "receipt": receipt}
	if world == null or not preload("res://autoload/world_state.gd").training_world_op_valid(op,
		world.reward_deliveries, world.reward_delivery_namespace, world.world_id):
		return _refuse("creature_training_accept", peer_id, "stale_training_ack", "That training decision is no longer current.")
	return _commit([op], "creature_training_accept", peer_id, "meadows")


## Internal only: the public building intent cannot call this typed door.
## One delta applies the journal and the ordinary building UID operation.
func commit_altar_building(row: Dictionary, peer: int) -> Dictionary:
	const W = preload("res://autoload/world_state.gd")
	if world == null or not W.altar_build_row_valid(row, world.reward_delivery_namespace, world.world_id) \
		or world.reward_deliveries.has(row.delivery_id) or row.status != "pending":
		return _refuse(str(row.get("action", "")), peer, "invalid_building_journal", "That Altar decision is invalid.")
	var record: Dictionary = row.intent.record
	var building_op: Dictionary
	if row.action == "place_building":
		if record.uid != "b%d" % int(world.next_building_uid) or world.building_index_of(record.uid) >= 0:
			return _refuse(row.action, peer, "stale_building_uid", "That placement changed.")
		building_op = record.duplicate(true)
		building_op.op = "building_add"
	else:
		var index := int(world.building_index_of(record.uid))
		if index < 0 or not preload("res://scripts/creatures/essence.gd")._equivalent(world.placed_buildings[index], record) \
			or W.altar_paid_provenance(world.reward_deliveries, world.reward_delivery_namespace, world.world_id, record, row.character_id).is_empty():
			return _refuse(row.action, peer, "unproved_paid_altar", "That Altar has no matching paid placement.")
		building_op = {"op": "building_remove", "realm": "meadows", "uid": record.uid, "index": index}
	building_op.scope = "world"
	building_op.txn_id = row.action_id
	var verdict := _commit([{"op": "creature_training_journal", "scope": "world", "delivery_id": row.delivery_id, "delivery": row.duplicate(true)},
		building_op, {"op": "creature_training_settle", "scope": "player", "peers": [peer], "delivery": row.duplicate(true)}], row.action, peer, "meadows")
	verdict.uid = record.uid
	verdict.txn_id = row.action_id
	return verdict


## Internal prepared portal journal, never a packet-supplied grant intent.
func commit_portal_delivery(row: Dictionary, peer: int) -> Dictionary:
	if world == null or not preload("res://autoload/world_state.gd").portal_op_valid(
		{"op": "portal_delivery_journal", "receipt": row.get("receipt"), "delivery": row},
		world.reward_deliveries, world.reward_delivery_namespace, world.world_id):
		return _refuse("portal_unlock", peer, "invalid_portal_journal", "The portal receipt could not be prepared.")
	return _commit([{"op": "portal_delivery_journal", "scope": "world", "realm": "meadows", "receipt": row.receipt, "delivery": row.duplicate(true)}], "portal_unlock", peer, "meadows")


func accept_portal_delivery(row: Dictionary, peer: int) -> Dictionary:
	if world == null or not preload("res://autoload/world_state.gd").portal_op_valid(
		{"op": "portal_delivery_accept", "receipt": row.get("receipt"), "delivery": row},
		world.reward_deliveries, world.reward_delivery_namespace, world.world_id):
		return _refuse("portal_unlock", peer, "invalid_portal_ack", "That portal acknowledgement is no longer current.")
	return _commit([{"op": "portal_delivery_accept", "scope": "world", "realm": "meadows", "receipt": row.receipt, "delivery": row.duplicate(true)}], "portal_unlock", peer, "meadows")
