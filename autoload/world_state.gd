extends RefCounted

## D98 / docs/specs/MP_STATE_SEAM.md §1: what has happened to THIS WORLD.
##
## One per hosted world. The host's is authoritative; from Wave 3 every peer
## holds a replica that only `apply_delta()` may mutate. `Game.world` is the
## live one, and every `Game.<x>` this file holds -- `day`,
## `clock_elapsed_seconds`, `world_seed`, `placed_buildings`, `farm_plots`,
## `death_satchels`, `harvested_vegetation`, `felled_vegetation` -- stays
## readable and writable under its old name as a forwarding property on `Game`,
## so none of the 390 `Game.<field>` sites the assumption inventory counts had
## to move.
##
## Same shape as `party.gd`/`inventory.gd`/`progression_state.gd`: pure logic,
## no `Node`, no transform, testable headlessly (`tests/test_world_state.gd`).
## The scene-tree side of a world record -- reading a chest's live contents,
## reading the day/night clock off `world_look.gd` -- stays in `Game`'s four
## sync seams, which write INTO this object. This file never touches a tree.
##
## What is NOT here, deliberately: `current_realm`. Which realm a trainer is
## standing in is per player from now on (`PlayerState.realm`), so a method
## that needs to stamp a record with a realm takes it as an argument rather
## than reading one global answer -- see `register_building()` and
## `register_death_satchel()` below.

const FARM_LOGIC := preload("res://scripts/world/farm_logic.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const REDESIGN_STATE := preload("res://scripts/data/redesign_state.gd")
var redesign_world: Dictionary = REDESIGN_STATE.defaults("world")

## `game_state.gd::CLOCK_UNSET`, repeated here rather than imported: this file
## is the one that owns the field now, and `game_state.gd` keeps its own const
## as the name every existing caller already reads.
const CLOCK_UNSET := -1.0

## Stable id minted on New World; from 1.C, the world save's directory name.
## "" until 1.C mints one -- nothing reads it yet, and inventing a scheme this
## lane does not need would be inventing 1.C's format.
var world_id: String = ""

var world_seed: int = 0
var day: int = 1
var clock_elapsed_seconds: float = CLOCK_UNSET
## Realm-local weather clocks and durable environmental state. These belong
## to the hosted world, independently of the day clock and visiting players.
var realm_environment: Dictionary = {}

## The WORLD half of the old flat `Game.progression` store: every id
## `progression_state.scope_of()` answers "world" for. `Game.progression` is a
## merged view over this and the local player's (`merged_progression.gd`).
var flags: RefCounted = null

var placed_buildings: Array = []

## Mints `uid` for the next placed building. Monotonic WITHIN a session, so an
## id is never reused while an intent naming it could still be in flight --
## reuse is the whole class of bug the uid exists to close. Not saved: it is
## rebuilt from the records on load (see `load_data`), which keeps the world
## file's key set exactly what D100 partitions it into.
##
## Only a host ever mints; a client receives the uid on the committed
## `building_add` op.
var next_building_uid: int = 1
var farm_plots: Array = []
var death_satchels: Array = []
## Durable host journal for per-character authored reward delivery.
var reward_deliveries: Dictionary = {}
## Random per-world-instance namespace for portable reward identities. Unlike
## the save locator (`slot-0`), this cannot collide between two hosts.
var reward_delivery_namespace: String = ""
## Host journal for unfinished Aquaryn handovers. These records are not owned
## creatures or a usable reserve; only the named catcher's five-slot ceremony
## can consume one. Personal receipts make replay after a lost ack idempotent.
var water_capture_claims: Dictionary = {}
var harvested_vegetation: Dictionary = {}
var felled_vegetation: Dictionary = {}

## Bumped on every world-record mutation, for Wave 3's delta detection.
##
## Deliberately NOT part of `merged_progression.revision`: that one sums the two
## FLAG stores, because `game_state.gd::_process` polls it to decide whether the
## objective line moved, and placing a fence is not a reason to recompute the
## quest log. See merged_progression.gd's own `revision()`.
var revision: int = 0


func _init() -> void:
	flags = PROGRESSION_STATE.new()


## The same empty state a process boot creates, in place. Called by
## `Game.reset_for_new_game()`; the object identity is kept so anything holding
## a `Game.world` reference across a New Game keeps holding the live one.
## `flags` keeps its OBJECT IDENTITY across the reset and is emptied instead:
## `merged_progression.gd` holds a reference to it, and re-pointing that on
## every New Game is one more thing to get wrong. `load_data({})` is the flag
## store's own "working fresh state" contract.
func reset() -> void:
	redesign_world = REDESIGN_STATE.defaults("world")
	flags.call("load_data", {})
	day = 1
	clock_elapsed_seconds = CLOCK_UNSET
	realm_environment = {}
	placed_buildings = []
	farm_plots = []
	death_satchels = []
	reward_deliveries = {}
	reward_delivery_namespace = ""
	water_capture_claims = {}
	harvested_vegetation = {}
	felled_vegetation = {}
	revision += 1


func advance_day() -> int:
	day += 1
	revision += 1
	return day


## Record a real placement (moved verbatim from `game_state.gd`, plus the
## explicit `realm`). `build_placer.gd` calls this through `Game` once, right
## after the piece is spent and planted -- the registry, not the scene node, is
## what a save actually persists.
##
## `realm` is an argument rather than a read of a global: two peers can stand in
## two realms at once from Wave 6, and a record stamped with "whichever realm
## the local player happens to be in" would file a Cloudreach fence in the
## Meadows. `Game.register_building()` passes `local.realm`, which is exactly
## what `current_realm` meant before.
## `uid` is the record's STABLE address, and the reason it exists is a race
## lanes 3.C and 3.D each hit from opposite directions. Addressing a structure
## by its index into this array is correct only until somebody dismantles a
## structure below it: a `dismantle` intent already in flight then names a
## VALID index that is no longer the right record, and the host takes down the
## neighbour. The same renumber moves a chest's storage key onto another
## chest's revision counter. An index is a position; a uid is an identity, and
## only an identity survives the array changing under it.
##
## Empty `uid` mints the next one, which is what a host and a solo player do.
## A client passes the uid that arrived on the committed op, so every peer's
## record carries the same identity.
func register_building(id: String, position: Vector3, yaw_deg: float = 0.0,
		paid: bool = true, realm: String = "meadows", uid: String = "") -> String:
	var assigned := uid
	if assigned.is_empty():
		assigned = "b%d" % next_building_uid
		next_building_uid += 1
	else:
		# Keep the counter ahead of anything applied from a delta or a load, so
		# this peer can never mint an id that is already in use.
		var n := int(assigned.substr(1)) if assigned.begins_with("b") else 0
		next_building_uid = maxi(next_building_uid, n + 1)
	placed_buildings.append({
		"realm": realm,
		"uid": assigned,
		"id": id,
		"position": [position.x, position.y, position.z],
		"yaw_deg": yaw_deg,
		# BUILD-REMOVE: Free Build placements must not become a material faucet.
		# Missing on legacy saves means paid (the only pre-Free-Build economy).
		"paid": paid,
	})
	revision += 1
	return assigned


## The index of the record with `uid`, or -1. The one place an identity becomes
## a position, so nothing else has to know that `placed_buildings` is an array.
func building_index_of(uid: String) -> int:
	if uid.is_empty():
		return -1
	for i in placed_buildings.size():
		var record: Variant = placed_buildings[i]
		if record is Dictionary and str((record as Dictionary).get("uid", "")) == uid:
			return i
	return -1


## Give every legacy record a uid, in array order, and put the counter past the
## highest. Runs identically on every peer over identical data -- a joiner gets
## the host's already-migrated snapshot, so the two cannot disagree.
func _migrate_building_uids() -> void:
	var highest := 0
	for record: Variant in placed_buildings:
		if record is Dictionary:
			var uid := str((record as Dictionary).get("uid", ""))
			if uid.begins_with("b"):
				highest = maxi(highest, int(uid.substr(1)))
	for record: Variant in placed_buildings:
		if record is Dictionary and str((record as Dictionary).get("uid", "")).is_empty():
			highest += 1
			(record as Dictionary)["uid"] = "b%d" % highest
	next_building_uid = maxi(next_building_uid, highest + 1)


## D104/D-MP10: a death satchel is a world entity with an OWNER. Only the owner
## may open it; everyone else sees it labelled. `owner` is a character id and
## defaults to "" -- exactly what `realm_world_records.normalized()` stamps on a
## legacy record, so solo behaviour is unchanged until 1.C mints character ids.
##
## Returns the new entry's index, which the caller stashes as node metadata so
## `sync_state_to_game`/`restore_from_game` can find their way back to it.
func register_death_satchel(position: Vector3, owner: String = "",
		realm: String = "meadows", uid: String = "") -> int:
	if uid.is_empty():
		uid = "legacy_satchel_%d" % death_satchels.size()
	death_satchels.append({
		"uid": uid,
		"realm": realm,
		"owner": owner,
		"position": [position.x, position.y, position.z],
		"state": [],
	})
	revision += 1
	return death_satchels.size() - 1


func death_satchel_index_of(uid: String) -> int:
	for index in death_satchels.size():
		if death_satchels[index] is Dictionary:
			var record: Dictionary = death_satchels[index]
			if str(record.get("uid", "legacy_satchel_%d" % index)) == uid:
				return index
	return -1


## R7.6. The state of farm bed `index`, or a fresh fallow one. Grows
## `farm_plots` on demand rather than requiring anyone to size it up front: a
## save written when farm.json listed four beds is loaded by a build that lists
## six, and the two new beds should read as unworked ground.
func farm_plot_at(index: int) -> Dictionary:
	if index < 0:
		return FARM_LOGIC.fresh()
	if index >= farm_plots.size():
		return FARM_LOGIC.fresh()
	return FARM_LOGIC.sanitised(farm_plots[index])


func set_farm_plot(index: int, plot: Dictionary) -> void:
	if index < 0:
		return
	while farm_plots.size() <= index:
		farm_plots.append(FARM_LOGIC.fresh())
	farm_plots[index] = FARM_LOGIC.sanitised(plot)
	revision += 1


## The WORLD half of today's v22 save dictionary (`MP_STATE_SEAM.md` §4), which
## 1.C writes to `user://worlds/<world_id>/world.json` and the net harness
## hashes for its desync detector (`MP_NET_HARNESS_CONTRACT.md` §7). The v22
## key names are kept verbatim so 1.C's key-coverage test can compare sets
## rather than a rename map; `progression` is the one key that splits, and its
## world half is `flags` here.
##
## `scripts/save/save_game.gd` does NOT go through this yet: it still assembles
## the v22 dictionary from `Game`'s own properties, which now forward here, so
## the file it writes is byte-identical to the one it wrote before this lane.
## 1.C replaces that path; this is the shape it replaces it with.
func save_data() -> Dictionary:
	return {
		"redesign_world": redesign_world.duplicate(true),
		"world_id": world_id,
		"day": day,
		"clock_elapsed_seconds": clock_elapsed_seconds,
		"realm_environment": realm_environment.duplicate(true),
		"world_seed": world_seed,
		"placed_buildings": placed_buildings.duplicate(true),
		"farm_plots": farm_plots.duplicate(true),
		"death_satchels": death_satchels.duplicate(true),
		"reward_deliveries": reward_deliveries.duplicate(true),
		"reward_delivery_namespace": reward_delivery_namespace,
		"water_capture_claims": water_capture_claims.duplicate(true),
		"harvested_vegetation": harvested_vegetation.duplicate(true),
		"felled_vegetation": felled_vegetation.duplicate(true),
		"flags": flags.save_data() if flags != null else {},
	}


## Tolerant of every missing key -- `load_data({})` is a working fresh state,
## the same contract `map_state.gd` and `progression_state.gd` already give
## `save_game.gd`.
func load_data(data: Dictionary) -> void:
	var portal_failures := portal_world_errors(data.get("reward_deliveries", {}), str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", "")))
	if not portal_failures.is_empty():
		push_error("World portal journal refused: %s" % "; ".join(portal_failures))
		return
	var training_failures := training_world_errors(data.get("reward_deliveries", {}),
		str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", "")), data.get("placed_buildings", []))
	if not training_failures.is_empty():
		push_error("World training refused: %s" % "; ".join(training_failures))
		return
	var vitals_errors := preload("res://scripts/net/actor_vitals_delivery.gd").world_errors(
		data.get("reward_deliveries", {}), str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", "")))
	if not vitals_errors.is_empty():
		push_error("World actor vitals refused: %s" % "; ".join(vitals_errors))
		return
	var redesign: Variant = data.get("redesign_world", REDESIGN_STATE.defaults("world"))
	var redesign_errors := REDESIGN_STATE.validate("world", redesign)
	if not redesign_errors.is_empty():
		push_error("World schema refused: %s" % "; ".join(redesign_errors))
		return
	redesign_world = redesign.duplicate(true)
	world_id = str(data.get("world_id", world_id))
	day = _int(data.get("day"), 1)
	clock_elapsed_seconds = _finite_clock(data.get("clock_elapsed_seconds"))
	realm_environment = _dictionary(data.get("realm_environment", {}))
	world_seed = _int(data.get("world_seed"), 0)
	placed_buildings = _array(data.get("placed_buildings", []))
	# The counter is DERIVED from the records rather than saved, so the world
	# file keeps exactly the ten keys D100 partitions it into -- adding an
	# eleventh would break the contract that the world and character key sets
	# together equal the v22 set, which `test_world_state.gd` enforces. Deriving
	# is sufficient because a uid only has to be unique among LIVE records and
	# against intents in flight, and no intent survives a reload. This also
	# repairs a world saved before uids existed.
	next_building_uid = 1
	_migrate_building_uids()
	farm_plots = _array(data.get("farm_plots", []))
	death_satchels = _array(data.get("death_satchels", []))
	reward_deliveries = _dictionary(data.get("reward_deliveries", {}))
	reward_delivery_namespace = str(data.get("reward_delivery_namespace", ""))
	water_capture_claims = _dictionary(data.get("water_capture_claims", {}))
	for index in death_satchels.size():
		if death_satchels[index] is Dictionary and str(death_satchels[index].get("uid", "")).is_empty():
			death_satchels[index]["uid"] = "legacy_satchel_%d" % index
	harvested_vegetation = _dictionary(data.get("harvested_vegetation", {}))
	felled_vegetation = _dictionary(data.get("felled_vegetation", {}))
	if flags == null:
		flags = PROGRESSION_STATE.new()
	var raw_flags: Variant = data.get("flags", {})
	flags.call("load_data", raw_flags if typeof(raw_flags) == TYPE_DICTIONARY else {})
	revision += 1


## A saved number, or the default. Deliberately strict about the TYPE rather
## than calling `int()` on whatever arrived: `int([])` is not a conversion, it
## is a "Nonexistent 'int' constructor" error that aborts the whole load
## halfway through and leaves a half-restored world -- which is exactly the
## failure "never fatal on load" exists to prevent.
func _int(raw: Variant, fallback: int) -> int:
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return int(raw)
	return fallback


func _array(raw: Variant) -> Array:
	return (raw as Array).duplicate(true) if typeof(raw) == TYPE_ARRAY else []


func _dictionary(raw: Variant) -> Dictionary:
	return (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {}


## Anything that is not a finite number becomes the "no carried clock"
## sentinel, the same rule `save_game.gd::_finite_clock` already applies.
func _finite_clock(raw: Variant) -> float:
	if not (typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT) or not is_finite(float(raw)):
		return CLOCK_UNSET
	var seconds := float(raw)
	return seconds if seconds >= 0.0 else CLOCK_UNSET


# --- Wave 3 / D103: the one way a world changes -------------------------------

## Apply a delta the `WorldLedger` committed. Returns how many WORLD-scope ops
## actually landed.
##
## From Wave 3 this is the ONLY way a client's world state changes: a client
## never validates, never decides, and never writes a world container of its own
## accord -- it receives ops the host already committed and replays them. The
## host runs this same function on its own commit (`world_ledger.gd::_commit()`
## calls `apply()`, which calls this), so host and client cannot drift by
## running different code over the same ops.
##
## Ops whose `scope` is not `world` are skipped, deliberately and silently:
## `player` ops are addressed to a peer and applied by `ledger_rpc.gd` against
## `PlayerState`, and `scene` ops belong to a live node that owns its own mirror
## format (lane 3.B's vegetation bitset). This file has no opinion about either,
## which is the same line `MP_STATE_SEAM.md` §1 already draws.
##
## Never fatal on a malformed op: a delta from a peer running a different build
## should cost that one op, not the whole world.
func apply_delta(delta: Dictionary) -> int:
	var raw_ops: Variant = delta.get("ops", [])
	if typeof(raw_ops) != TYPE_ARRAY:
		return 0
	var applied := 0
	for raw: Variant in (raw_ops as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var op := raw as Dictionary
		if str(op.get("scope", "")) != "world":
			continue
		if _apply_op(op):
			applied += 1
	return applied


func _apply_op(op: Dictionary) -> bool:
	match str(op.get("op", "")):
		"portal_delivery_journal", "portal_delivery_accept":
			if not portal_op_valid(op, reward_deliveries, reward_delivery_namespace, world_id): return false
			reward_deliveries[op.receipt] = op.delivery.duplicate(true)
			if op.delivery.biome == "biome5":
				redesign_world.fifth_arch_stirred = true
			elif not redesign_world.portal_unlocks.has(op.delivery.biome):
				redesign_world.portal_unlocks.append(op.delivery.biome)
			return true
		"creature_training_journal", "creature_training_accept":
			if not training_world_op_valid(op, reward_deliveries, reward_delivery_namespace, world_id):
				return false
			if op.op == "creature_training_journal":
				reward_deliveries[op.delivery_id] = op.delivery.duplicate(true)
			else:
				reward_deliveries[op.delivery_id].status = "accepted"
			revision += 1
			return true
		"actor_vitals_journal", "actor_vitals_accept":
			if not preload("res://scripts/net/actor_vitals_delivery.gd").valid_world_op(op, reward_deliveries, reward_delivery_namespace):
				return false
			if op.op == "actor_vitals_journal":
				reward_deliveries[op.delivery_id] = op.delivery.duplicate(true)
			else:
				reward_deliveries[op.delivery_id].status = "accepted"
			revision += 1
			return true
		"reward_delivery_accept":
			var accept_id := str(op.get("delivery_id", ""))
			var accept_character := str(op.get("character_id", ""))
			if accept_id.begins_with("actor_vitals:") or accept_id.begins_with("creature_training:") or accept_id.begins_with("altar_building:"):
				return false
			var accepted: Variant = reward_deliveries.get(accept_id)
			if not accepted is Dictionary or str((accepted as Dictionary).get("status", "")) != "pending" \
					or str((accepted as Dictionary).get("character_id", "")) != accept_character:
				return false
			(accepted as Dictionary)["status"] = "accepted"
			revision += 1
			return true
		"reward_delivery_journal":
			var delivery: Variant = op.get("delivery", {})
			var id := str(op.get("delivery_id", ""))
			if id.begins_with("actor_vitals:") or id.begins_with("creature_training:") or id.begins_with("altar_building:") or (delivery is Dictionary and delivery.get("kind") in ["actor_vitals", "creature_training", "altar_building"]):
				return false
			if id.is_empty() or not delivery is Dictionary:
				return false
			var delivery_namespace := str((delivery as Dictionary).get("world_namespace", ""))
			if delivery_namespace.is_empty() \
					or (not reward_delivery_namespace.is_empty() \
						and reward_delivery_namespace != delivery_namespace):
				return false
			if reward_deliveries.has(id):
				return false
			if reward_delivery_namespace.is_empty():
				reward_delivery_namespace = delivery_namespace
			reward_deliveries[id] = (delivery as Dictionary).duplicate(true)
			revision += 1
			return true
		"satchel_add":
			var uid := str(op.get("uid", ""))
			if uid.is_empty() or death_satchel_index_of(uid) >= 0:
				return false
			var index := register_death_satchel(_op_position(op.get("position")), str(op.get("owner", "")), str(op.get("realm", "meadows")), uid)
			death_satchels[index]["state"] = (op.get("state", []) as Array).duplicate(true)
			return true
		"satchel_set":
			var index := death_satchel_index_of(str(op.get("uid", "")))
			if index < 0:
				return false
			if int(op.get("revision", 0)) <= int(death_satchels[index].get("revision", 0)):
				return false
			death_satchels[index]["state"] = (op.get("state", []) as Array).duplicate(true)
			death_satchels[index]["revision"] = int(op.get("revision", 0))
			var transactions: Array = death_satchels[index].get("transactions", [])
			var txn := str(op.get("txn_id", ""))
			if not txn.is_empty() and not transactions.has(txn):
				transactions.append(txn)
			death_satchels[index]["transactions"] = transactions
			revision += 1
			return true
		"flag":
			var id := str(op.get("id", ""))
			if id.is_empty() or flags == null:
				return false
			flags.call("set_flag", id, bool(op.get("value", true)))
			revision += 1
			return true
		"building_add":
			if op.get("id") == "altar" and not _altar_building_op_bound(op, false): return false
			# Through `register_building()`, not a hand-built Dictionary: the
			# shape of a placed-building record keeps exactly one construction
			# site, so a delta and a solo placement can never disagree about it.
			register_building(str(op.get("id", "")), _op_position(op.get("position")),
				float(op.get("yaw_deg", 0.0)), bool(op.get("paid", true)),
				str(op.get("realm", "meadows")), str(op.get("uid", "")))
			return true
		"building_arch_link":
			var index := building_index_of(str(op.get("uid", "")))
			if index < 0:
				return false
			var row: Dictionary = placed_buildings[index]
			if str(row.get("id", "")) != "stormglass_arch" or str(row.get("realm", "")) != "stormwood":
				return false
			row["arch_twin"] = str(op.get("twin", ""))
			if op.has("footing"):
				row["arch_footing"] = str(op.footing)
			revision += 1
			return true
		"building_remove":
			var altar_index := building_index_of(str(op.get("uid", "")))
			if altar_index < 0 and op.get("index") is int: altar_index = int(op.index)
			if altar_index >= 0 and altar_index < placed_buildings.size() and placed_buildings[altar_index].get("id") == "altar" and not _altar_building_op_bound(op, true): return false
			# By uid when the op carries one, which is every op the ledger mints
			# now. The index fallback is only for a delta minted before uids
			# existed; it is not a path any live code takes.
			var index := building_index_of(str(op.get("uid", "")))
			if index < 0:
				if op.has("uid"):
					return false
				index = int(op.get("index", -1))
			if index < 0 or index >= placed_buildings.size():
				return false
			placed_buildings.remove_at(index)
			revision += 1
			return true
		"storage_set":
			# Same rule as building_remove: identity first, position only as a
			# fallback for a delta minted before uids existed. A chest addressed
			# by index inherits its neighbour's contents after a dismantle.
			var slot := building_index_of(str(op.get("uid", "")))
			if slot < 0:
				if op.has("uid"):
					return false
				slot = int(op.get("index", -1))
			if slot < 0 or slot >= placed_buildings.size():
				return false
			var record: Dictionary = placed_buildings[slot] as Dictionary
			var state: Variant = op.get("state", [])
			record["state"] = (state as Array).duplicate(true) if typeof(state) == TYPE_ARRAY else []
			revision += 1
			return true
	return false


func _op_position(raw: Variant) -> Vector3:
	if typeof(raw) == TYPE_VECTOR3:
		return raw as Vector3
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() == 3:
		var a := raw as Array
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


## Canonical validation for the discriminated EXISTING world carrier; the
## same guard runs for split/flat reads, snapshots, typed ops and both saves.
static func training_row_valid(row: Variant, world_namespace: String, expected_world: String = "") -> bool:
	if row is Dictionary and row.get("kind") == "creature_training" and row.get("version") == 2:
		return not world_namespace.is_empty() and preload("res://scripts/net/character_action_delivery.gd").valid(row, preload("res://scripts/net/character_record_rules.gd").errors, "", world_namespace, expected_world)
	if row is Dictionary and row.get("kind") == "altar_building": return altar_build_row_valid(row, world_namespace, expected_world)
	const ESSENCE = preload("res://scripts/creatures/essence.gd")
	const TEACHING = preload("res://scripts/creatures/teaching.gd")
	const PROGRESSION = preload("res://scripts/creatures/progression.gd")
	return not world_namespace.is_empty() and ESSENCE.training_row_valid(row, "", world_namespace) \
		and row.action in ["altar_spend", "wild_defeat"] and (expected_world.is_empty() or row.world_id == expected_world) \
		and ESSENCE.training_transition_valid(row, ESSENCE.config(), PROGRESSION.config(),
			TEACHING.available_moves, TEACHING.character_loadout_mirror)


static func training_world_errors(raw: Variant, world_namespace: String, expected_world: String = "", buildings: Variant = null) -> Array[String]:
	if not raw is Dictionary: return ["world reward deliveries must be an object"]
	for key: Variant in raw:
		var row: Variant = raw[key]
		if str(key).begins_with("creature_training:") or str(key).begins_with("altar_building:") or (row is Dictionary and row.get("kind") in ["creature_training", "altar_building"]):
			if not training_row_valid(row, world_namespace, expected_world) or key != row.delivery_id:
				return ["invalid typed creature training journal"]

	var pending: Dictionary = {}
	var has_building_rows := false
	for row: Variant in raw.values():
		if not row is Dictionary or not row.get("kind") in ["creature_training", "altar_building"]: continue
		if row.status == "pending":
			if pending.has(row.character_id): return ["multiple pending personal mutations"]
			pending[row.character_id] = row.receipt
		if row.kind == "altar_building": has_building_rows = true
		if row.kind == "altar_building" and row.action == "dismantle":
			var place := 0
			var removals := 0
			for prior: Variant in raw.values():
				if not prior is Dictionary or prior.get("kind") != "altar_building" or prior.get("intent", {}).get("record", {}).get("uid") != row.intent.record.uid: continue
				if prior.action == "dismantle": removals += 1
				elif prior.status == "accepted" and prior.character_id == row.character_id and int(prior.character_revision) < int(row.character_revision) and preload("res://scripts/creatures/essence.gd")._equivalent(prior.intent.record, row.intent.record): place += 1
			if place != 1 or removals != 1: return ["refund lacks unique paid placement provenance"]
	if (has_building_rows or buildings is Array) and not altar_buildings_bound(raw, buildings): return ["Altar building UID journal binding failed"]
	return []


static func training_world_op_valid(op: Dictionary, records: Dictionary, world_namespace: String, expected_world: String) -> bool:
	if op.get("scope") != "world" or not op.get("delivery_id") is String: return false
	var old: Variant = records.get(op.delivery_id)
	if op.get("op") == "creature_training_journal":
		if op.size() != 4 or not training_row_valid(op.get("delivery"), world_namespace, expected_world): return false
		var row: Dictionary = op.delivery
		if row.delivery_id != op.delivery_id or row.status != "pending": return false
		if old == null: return int(row.journal_revision) == 1
		if row.kind == "altar_building": return false # Immutable per-action ID; only exact acceptance may change it.
		return training_row_valid(old, world_namespace, expected_world) and old.character_id == row.character_id \
			and old.status == "accepted" and int(row.journal_revision) == int(old.journal_revision) + 1 \
			and int(row.character_revision) > int(old.character_revision) \
			and row.before.redesign_character.transaction_receipts.has(old.receipt)
	if op.get("op") == "creature_training_accept":
		return op.size() == 6 and training_row_valid(old, world_namespace, expected_world) \
			and old.status == "pending" and not str(op.get("character_id", "")).is_empty() \
			and old.character_id == op.character_id and old.journal_revision == op.get("journal_revision") \
			and old.receipt == op.get("receipt")
	return false


## Altar-only discriminator in the existing reward journal. A paid bit alone
## is not refundable provenance; original placement and removal rows survive.
static func altar_build_id(world_namespace: String, character: String, txn: String) -> String:
	const E = preload("res://scripts/creatures/essence.gd")
	return "altar_building:" + JSON.stringify([world_namespace, character, txn]).sha256_text() \
		if E._opaque_id(world_namespace) and E._component(character) and E._opaque_id(txn) else ""


static func altar_recipe() -> Array:
	var data: Variant = preload("res://scripts/data/redesign_data.gd").json("res://data/items/buildables.json")
	if not data is Dictionary or not data.get("buildables") is Array: return []
	var found: Array = []
	for raw: Variant in data.buildables:
		if raw is Dictionary and raw.get("id") == "altar":
			if not found.is_empty() or not raw.get("cost") is Array: return []
			found = raw.cost.duplicate(true)
	# Binding to the settled recipe, not a request price or Free Build setting.
	return found if preload("res://scripts/creatures/essence.gd")._equivalent(found, [{"id": "stone", "n": 10}, {"id": "rootstone", "n": 4}, {"id": "ironwood", "n": 2}]) else []


static func altar_build_transition(full: Dictionary, character: String, revision: int,
		action: String, txn: String, record: Dictionary, world_namespace: String) -> Dictionary:

	const E = preload("res://scripts/creatures/essence.gd")
	const RULES = preload("res://scripts/world/death_satchel_rules.gd")
	if not altar_txn_id_valid(txn) or not action in ["place_building", "dismantle"] or revision < 0 or revision >= 2147483647 \
		or not E._baseline_errors(full, character).is_empty() or altar_build_id(world_namespace, character, txn).is_empty(): return {}
	if record.size() != 6 or record.get("id") != "altar" or record.get("realm") != "meadows" \
		or not record.get("paid") is bool or record.paid != true or not record.get("uid") is String \
		or not record.uid.begins_with("b") or not record.uid.substr(1).is_valid_int() \
		or int(record.uid.substr(1)) < 1 or int(record.uid.substr(1)) > 2147483646 or not record.get("position") is Array \
		or record.position.size() != 3 or not (record.get("yaw_deg") is int or record.get("yaw_deg") is float) \
		or not is_finite(float(record.yaw_deg)): return {}
	for cell: Variant in record.position:
		if not (cell is int or cell is float) or not is_finite(float(cell)): return {}
	if not preload("res://scripts/creatures/teaching.gd").admitted_party_errors(full.party, full.redesign_character).is_empty(): return {}
	if record.uid != "b%d" % int(record.uid.substr(1)): return {}
	var cost := altar_recipe()
	if cost.is_empty(): return {}
	var receipt := "craft:%s:altar_build:%s:%s:%s:%s" % [character, world_namespace.sha256_text(), txn, action, record.uid]
	var cfg: Dictionary = E.config()
	if not E._integer(cfg.get("maximum_transaction_receipts"), 1, 65536) \
		or full.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts) \
		or full.redesign_character.transaction_receipts.has(receipt): return {}
	var inv := RULES.inventory_from(full.inventory)
	for need: Dictionary in cost:
		if action == "place_building":
			if inv.count(need.id) < int(need.n) or not inv.remove(need.id, int(need.n)): return {}
		elif inv.add(need.id, int(need.n)) != 0: return {}
	var next := full.duplicate(true)
	next.inventory = RULES.slots(inv)
	next.redesign_character.transaction_receipts.append(receipt)
	if not E._baseline_errors(next, character).is_empty(): return {}
	return {"ok": true, "character_id": character, "action": action, "action_id": txn,
		"character_revision": revision + 1, "receipt": receipt, "before": full.duplicate(true),
		"state": next, "record": record.duplicate(true), "cost": cost}


static func altar_build_row_valid(raw: Variant, world_namespace: String, world_id: String = "") -> bool:
	const E = preload("res://scripts/creatures/essence.gd")

	if not raw is Dictionary or raw.size() != E.TRAINING_ROW_FIELDS.size(): return false
	for field: String in E.TRAINING_ROW_FIELDS:
		if not raw.has(field): return false
	if raw.kind != "altar_building" or not E._integer(raw.version, 1, 1) \
		or not E._integer(raw.journal_revision, 1, 1) or not E._integer(raw.character_revision, 1, 2147483647) \
		or not raw.status in ["pending", "accepted"] or not raw.action in ["place_building", "dismantle"] \
		or raw.world_namespace != world_namespace or not E._opaque_id(raw.world_id) \
		or not E._opaque_id(raw.session_id) or (not world_id.is_empty() and raw.world_id != world_id) \
		or raw.delivery_id != altar_build_id(world_namespace, str(raw.character_id), str(raw.action_id)) \
		or not raw.intent is Dictionary or raw.intent.size() != 3 \
		or not raw.intent.get("request") is Dictionary or not raw.intent.get("record") is Dictionary \
		or not raw.intent.get("cost") is Array or not raw.before is Dictionary or not raw.after is Dictionary \
		or raw.before.size() != 3 or raw.after.size() != 3: return false
	var request: Dictionary = raw.intent.request
	if request.get("txn_id") != raw.action_id or request.get("kind") != raw.action or request.get("realm") != "meadows": return false
	if raw.action == "place_building":
		if request.size() != 7 or request.get("id") != "altar" or request.get("paid") != true \
			or not E._equivalent(request.get("position"), raw.intent.record.get("position")) \
			or not E._equivalent(request.get("yaw_deg"), raw.intent.record.get("yaw_deg")): return false
	else:
		if request.size() != 4 or request.get("uid") != raw.intent.record.get("uid"): return false
	# Canonical projection preserves the unchanged party and every personal field;
	# recompute only the unchanged party/inventory/personal projection. No missing gear/portal carrier is invented here.
	var full := raw.before.duplicate(true)
	full.character_id = raw.character_id
	var proposal := altar_build_transition(full, raw.character_id, int(raw.character_revision) - 1,
		raw.action, raw.action_id, raw.intent.record, world_namespace)
	return proposal.get("ok") == true and proposal.receipt == raw.receipt \
		and E._equivalent(proposal.cost, raw.intent.cost) \
		and E._equivalent(E.training_projection(proposal.state), raw.after)


## Exactly one pending personal mutation across training/building actions.
## Old accepted history is retained for replay/provenance, never replayed as XP.
static func training_owner_row(deliveries: Dictionary, world_namespace: String, world_id: String,
		character: String) -> Dictionary:
	var latest: Dictionary = {}
	var pending := 0
	for raw: Variant in deliveries.values():
		if not raw is Dictionary or raw.get("character_id") != character \
			or not raw.get("kind") in ["creature_training", "altar_building"]: continue
		if not training_row_valid(raw, world_namespace, world_id): return {}
		if raw.status == "pending": pending += 1
		if latest.is_empty() or int(raw.character_revision) > int(latest.character_revision): latest = raw
		elif int(raw.character_revision) == int(latest.character_revision) and raw.receipt != latest.receipt: return {}
	if pending > 1 or (pending == 1 and latest.get("status") != "pending"): return {}
	return latest.duplicate(true)


static func altar_paid_provenance(deliveries: Dictionary, world_namespace: String, world_id: String,
		record: Dictionary, character: String = "", require_accepted: bool = true) -> Dictionary:
	var placed: Dictionary = {}
	for raw: Variant in deliveries.values():
		if not raw is Dictionary or raw.get("kind") != "altar_building" \
			or not raw.get("intent", {}).get("record") is Dictionary \
			or raw.intent.record.get("uid") != record.get("uid"): continue
		if not altar_build_row_valid(raw, world_namespace, world_id): return {}
		if raw.action == "dismantle": return {}
		if not placed.is_empty() or (require_accepted and raw.status != "accepted") \
			or (not character.is_empty() and raw.character_id != character) \
			or not preload("res://scripts/creatures/essence.gd")._equivalent(raw.intent.record, record): return {}
		placed = raw
	return placed.duplicate(true)


## Callers supply the actual existing building array at every world boundary.
## The journal is not useful if its UID was dropped, duplicated or reused.
static func altar_buildings_bound(deliveries: Dictionary, buildings: Variant) -> bool:
	if not buildings is Array: return false
	const E = preload("res://scripts/creatures/essence.gd")
	var places: Dictionary = {}
	var removals: Dictionary = {}
	for row: Variant in deliveries.values():
		if not row is Dictionary or row.get("kind") != "altar_building": continue
		var uid: String = row.intent.record.uid
		var selected: Dictionary = places if row.action == "place_building" else removals
		if selected.has(uid): return false
		selected[uid] = row
	var actual: Dictionary = {}
	for record: Variant in buildings:
		if not record is Dictionary or record.get("id") != "altar": continue
		if not record.get("uid") is String or actual.has(record.uid): return false
		actual[record.uid] = record
	for uid: String in places:
		if removals.has(uid):
			if actual.has(uid): return false
		elif not actual.has(uid) or not E._equivalent(actual[uid], places[uid].intent.record): return false
	for uid: String in removals:
		if not places.has(uid): return false
	for uid: String in actual:
		if not places.has(uid): return false
	return true


static func altar_txn_id_valid(raw: Variant) -> bool:
	if not raw is String or raw.length() != 32: return false
	for code: int in raw.to_utf8_buffer():
		if not (code >= 48 and code <= 57) and not (code >= 97 and code <= 102): return false
	return true


func _altar_building_op_bound(op: Dictionary, removing: bool) -> bool:
	var found := 0
	for row: Variant in reward_deliveries.values():
		if not row is Dictionary or row.get("kind") != "altar_building" or row.get("status") != "pending": continue
		if row.get("action_id") != op.get("txn_id") or row.get("intent", {}).get("record", {}).get("uid") != op.get("uid"): continue
		if not altar_build_row_valid(row, reward_delivery_namespace, world_id): return false
		if removing:
			if row.action != "dismantle": return false
			var index := building_index_of(str(op.get("uid", "")))
			if index < 0 or not preload("res://scripts/creatures/essence.gd")._equivalent(placed_buildings[index], row.intent.record): return false
		else:
			if row.action != "place_building" or building_index_of(row.intent.record.uid) >= 0: return false
			for field: String in ["id", "realm", "uid", "position", "yaw_deg", "paid"]:
				if not preload("res://scripts/creatures/essence.gd")._equivalent(op.get(field), row.intent.record[field]): return false
		found += 1
	return found == 1


## Typed portal facts use the existing reward journal. Validate both saved
## rows and deltas; unrelated item/vitals/training discriminators stay intact.
static func portal_world_errors(raw: Variant, world_namespace: String, world_id: String) -> Array[String]:
	return preload("res://scripts/net/portal_delivery.gd").world_errors(raw, world_namespace, world_id)


static func portal_op_valid(op: Dictionary, deliveries: Dictionary, world_namespace: String, world_id: String) -> bool:
	const DELIVERY = preload("res://scripts/net/portal_delivery.gd")
	var row: Variant = op.get("delivery")
	if not DELIVERY.valid(row, "", world_namespace) or row.world_id != world_id or op.get("receipt") != row.receipt: return false
	var prior: Variant = deliveries.get(row.receipt)
	if op.get("op") == "portal_delivery_journal":
		return row.status == "pending" and (prior == null or DELIVERY.equivalent(prior, row))
	if op.get("op") == "portal_delivery_accept":
		if not DELIVERY.valid(prior, row.character_id, world_namespace): return false
		var expected: Dictionary = prior.duplicate(true)
		expected.status = "accepted"
		return row.status == "accepted" and DELIVERY.equivalent(expected, row)
	return false
