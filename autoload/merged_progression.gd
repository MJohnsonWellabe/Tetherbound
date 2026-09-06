extends RefCounted

## D98/D99 / docs/specs/MP_STATE_SEAM.md §2: `Game.progression`, as one object
## over two stores.
##
## The flat flag store split in two this lane -- `WorldState.flags` for what
## happened to the world, `PlayerState.flags` for one trainer's tutorial beats,
## readiness and payoffs -- and 49 `set_flag` sites in 27 files plus 505 flag
## READS did not move. This is why: it presents exactly `progression_state.gd`'s
## surface (`has`, `completed`, `set_flag`, `all_set`, `revision`) and routes
## each call to the right store by `progression_state.scope_of()`.
##
## A world flag can never collide with a player flag by construction of the
## scope table (an id resolves to exactly one scope), so "either store has it"
## is exact rather than a guess.
##
## It deliberately does NOT offer `save_data()`/`load_data()`. The two halves go
## to two files from 1.C (D100), and a caller that persisted through the merged
## view would silently write the union into one of them; both are a `push_error`
## so a missed site is loud rather than subtly wrong.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

## The world's store (`Game.world.flags`).
var world_flags: RefCounted = null
## The LOCAL player's store (`Game.local.flags`). From Wave 3 the host writes
## other peers' stores directly through `Game.players[peer].flags`; this view is
## always about the local player, exactly as `Game.party` is.
var player_flags: RefCounted = null


func _init(p_world_flags: RefCounted = null, p_player_flags: RefCounted = null) -> void:
	world_flags = p_world_flags
	player_flags = p_player_flags


## True if EITHER store holds it. Exact, not a guess: the scope table gives an
## id one scope, so only one store can ever have been written.
func has(id: String) -> bool:
	if world_flags != null and bool(world_flags.call("has", id)):
		return true
	return player_flags != null and bool(player_flags.call("has", id))


## Same query as `has()`, spelled for objective/story call sites -- the split
## `progression_state.gd` already keeps.
func completed(id: String) -> bool:
	return has(id)


## Route by scope. An id the table does not name is a `push_error` AND a world
## write: the error is how a missed classification gets found, and the write is
## why the game does not stall on one. `tests/test_flag_scopes.gd` guarantees no
## shipped id takes that path.
func set_flag(id: String, value: bool = true) -> void:
	var store := store_for(id)
	if store == null:
		return
	store.call("set_flag", id, value)


## Which store `id` belongs to, or null when neither exists yet. Public because
## the four writer sites whose ACTOR is not the local player address a store
## explicitly (`MP_STATE_SEAM.md` §3's last paragraph) and this is how they name
## the right one without duplicating the routing rule.
func store_for(id: String) -> RefCounted:
	var scope := PROGRESSION_STATE.scope_of(id)
	if scope == PROGRESSION_STATE.SCOPE_PLAYER:
		return player_flags
	if scope == "":
		push_error("unscoped flag: %s" % id)
	return world_flags


## The union of both stores' set ids.
func all_set() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for store: RefCounted in [world_flags, player_flags]:
		if store == null:
			continue
		for id: Variant in (store.call("all_set") as Array):
			if seen.has(id):
				continue
			seen[id] = true
			out.append(id)
	return out


## The sum of both stores' revisions, so `game_state.gd::_process`'s existing
## "did the rung move" poll redraws the objective line when EITHER store moves.
##
## A sum rather than a max because a max can stand still while one store climbs
## and the other falls back after a load; the sum is monotonic under the only
## thing either store does to its own counter, which is increment it.
##
## Deliberately does NOT include `WorldState.revision`: placing a fence is a
## world mutation and not a reason to recompute the quest log.
var revision: int:
	get:
		var total := 0
		if world_flags != null:
			total += int(world_flags.get("revision"))
		if player_flags != null:
			total += int(player_flags.get("revision"))
		return total


# --- the v22 flat payload, until 1.C splits the file ------------------------
##
## DEVIATION FROM `MP_STATE_SEAM.md` §2, recorded deliberately. The seam says
## these two are "not provided" and that a call is a `push_error`, so a missed
## save site is loud. That is right once 1.C has landed -- but until it does,
## `scripts/save/save_game.gd` (which lane 1.B must leave byte-for-byte alone,
## and which must keep producing exactly today's v22 dictionary) reads the flag
## store through `game.get("progression").call("save_data")`. A `push_error`
## there would not find a missed site; it would stop every save in the game from
## recording a single flag.
##
## So the merged view does exactly what the split has to do anyway, one seam
## earlier than planned: `save_data()` returns the UNION, which is byte-identical
## to the flat store's old payload, and `load_data()` SPLITS the saved list back
## into the two stores by scope. 1.C deletes both when it writes world.json and
## character.json from `world.save_data()` / `local.save_data()`.

## The union, in `progression_state.gd::save_data()`'s exact shape, so the v22
## file this writes is identical to the one the flat store wrote.
func save_data() -> Dictionary:
	return {"flags": all_set()}


## Split a flat v22 flag list back into the two stores by scope. Both stores are
## replaced wholesale (`load_data` on each), never merged into, so loading a
## save can never leave a flag behind from the run before it.
func load_data(data: Dictionary) -> void:
	var world_ids: Array = []
	var player_ids: Array = []
	var raw: Variant = data.get("flags", [])
	if typeof(raw) == TYPE_ARRAY:
		for id: Variant in (raw as Array):
			if typeof(id) != TYPE_STRING or (id as String).is_empty():
				continue
			var scope := PROGRESSION_STATE.scope_of(id as String)
			if scope == PROGRESSION_STATE.SCOPE_PLAYER:
				player_ids.append(id)
			else:
				if scope == "":
					push_error("unscoped flag: %s" % id)
				world_ids.append(id)
	if world_flags != null:
		world_flags.call("load_data", {"flags": world_ids})
	if player_flags != null:
		player_flags.call("load_data", {"flags": player_ids})
