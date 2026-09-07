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
	flags.call("load_data", {})
	day = 1
	clock_elapsed_seconds = CLOCK_UNSET
	realm_environment = {}
	placed_buildings = []
	farm_plots = []
	death_satchels = []
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
		realm: String = "meadows") -> int:
	death_satchels.append({
		"realm": realm,
		"owner": owner,
		"position": [position.x, position.y, position.z],
		"state": [],
	})
	revision += 1
	return death_satchels.size() - 1


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
		"world_id": world_id,
		"day": day,
		"clock_elapsed_seconds": clock_elapsed_seconds,
		"realm_environment": realm_environment.duplicate(true),
		"world_seed": world_seed,
		"placed_buildings": placed_buildings.duplicate(true),
		"farm_plots": farm_plots.duplicate(true),
		"death_satchels": death_satchels.duplicate(true),
		"harvested_vegetation": harvested_vegetation.duplicate(true),
		"felled_vegetation": felled_vegetation.duplicate(true),
		"flags": flags.save_data() if flags != null else {},
	}


## Tolerant of every missing key -- `load_data({})` is a working fresh state,
## the same contract `map_state.gd` and `progression_state.gd` already give
## `save_game.gd`.
func load_data(data: Dictionary) -> void:
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
		"flag":
			var id := str(op.get("id", ""))
			if id.is_empty() or flags == null:
				return false
			flags.call("set_flag", id, bool(op.get("value", true)))
			revision += 1
			return true
		"building_add":
			# Through `register_building()`, not a hand-built Dictionary: the
			# shape of a placed-building record keeps exactly one construction
			# site, so a delta and a solo placement can never disagree about it.
			register_building(str(op.get("id", "")), _op_position(op.get("position")),
				float(op.get("yaw_deg", 0.0)), bool(op.get("paid", true)),
				str(op.get("realm", "meadows")), str(op.get("uid", "")))
			return true
		"building_remove":
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
