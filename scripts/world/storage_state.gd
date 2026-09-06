extends RefCounted

## R2.7. A placed storage chest's own satchel — items only, never creatures.
##
## Wraps a second `autoload/inventory.gd` instance rather than inventing a new
## grid format: a chest is "another slot+stack container", the exact shape
## Inventory already is, so the transfer panel can reuse the same read API
## (`stack_at`, `count`, `slot_count`) it would use for the player's own
## satchel. CLAUDE.md: player can own only five creatures, ever, and storage is
## never how that limit gets worked around — this class only ever moves
## `{id, n}` item stacks, the same contract Inventory enforces everywhere
## else, so there is no path into it for a creature instance to take.
##
## Pure logic, no nodes, so tests/test_storage.gd can exercise it headlessly —
## the same split test_inventory.gd already draws for the player's satchel.

const INVENTORY := preload("res://autoload/inventory.gd")

var inventory: RefCounted

## Kept so `preview_deposit`/`preview_withdraw` below can build throwaway
## copies of this chest and of the player's satchel out of the same catalogue,
## rather than asking a caller to hand the item database back in.
var _db: RefCounted = null


func _init(db: RefCounted) -> void:
	_db = db
	inventory = INVENTORY.new(db)


## Move up to `n` of `id` from the player's satchel into this chest. Returns
## how many did NOT move — zero on a full success, `n` if the player did not
## have `n` to give, and something in between if the chest had less room
## than the player had items.
##
## Checked against the source count FIRST, all-or-nothing on the "do we even
## attempt this" question, the same way Inventory.remove refuses a partial
## removal — a deposit either has enough to try or does nothing at all.
func deposit(player_inventory: RefCounted, id: String, n: int) -> int:
	if n <= 0 or id.is_empty() or player_inventory == null:
		return maxi(0, n)
	if int(player_inventory.count(id)) < n:
		return n

	var leftover := int(inventory.add(id, n))
	var moved := n - leftover
	if moved > 0:
		player_inventory.remove(id, moved)
	return leftover


## The reverse of `deposit`: move up to `n` of `id` from this chest back into
## the player's satchel. Same partial-fit contract.
func withdraw(player_inventory: RefCounted, id: String, n: int) -> int:
	if n <= 0 or id.is_empty() or player_inventory == null:
		return maxi(0, n)
	if int(inventory.count(id)) < n:
		return n

	var leftover := int(player_inventory.add(id, n))
	var moved := n - leftover
	if moved > 0:
		inventory.remove(id, moved)
	return leftover


## D103, lane 3.D. What this chest WOULD hold if `n` of `id` moved in from
## `player_inventory`, and how many would actually move — computed on
## throwaway copies, changing nothing on either side.
##
## Two players can share one chest, so a deposit is no longer a write this
## object is allowed to make on its own: `storage_container.gd` quotes the
## result here in a `storage_txn` intent, and the ledger decides. Until it
## does, the satchel and the chest are exactly as the player left them —
## which is the whole point of previewing rather than doing.
##
##     {"state": Array, "moved": int, "leftover": int}
##
## `state` is `save_data()`'s array shape, ready to ride the intent; `moved` is
## what the caller must take out of the satchel once the write commits;
## `leftover` keeps `deposit()`'s own contract (`n` when the player did not
## have `n` to give, the remainder when the chest ran out of room).
func preview_deposit(player_inventory: RefCounted, id: String, n: int) -> Dictionary:
	if n <= 0 or id.is_empty() or player_inventory == null:
		return _no_move(n)
	# The same source-count-first, all-or-nothing gate `deposit()` applies.
	if int(player_inventory.count(id)) < n:
		return _no_move(n)
	var scratch := _clone(inventory)
	var leftover := int(scratch.add(id, n))
	return {"state": _slots_of(scratch), "moved": n - leftover, "leftover": leftover}


## The reverse of `preview_deposit`: what this chest would hold if `n` of `id`
## moved out into `player_inventory`. `moved` is what the caller must ADD to
## the satchel once the write commits.
func preview_withdraw(player_inventory: RefCounted, id: String, n: int) -> Dictionary:
	if n <= 0 or id.is_empty() or player_inventory == null:
		return _no_move(n)
	if int(inventory.count(id)) < n:
		return _no_move(n)
	# The player's satchel decides how much can actually leave the chest, so
	# the fit is measured on a copy of it — never on the real one, which must
	# not change until the ledger says the write landed.
	var scratch_player := _clone(player_inventory)
	var leftover := int(scratch_player.add(id, n))
	var moved := n - leftover
	var scratch_chest := _clone(inventory)
	if moved > 0:
		scratch_chest.remove(id, moved)
	return {"state": _slots_of(scratch_chest), "moved": moved, "leftover": leftover}


## A preview that moves nothing: this chest exactly as it stands.
func _no_move(n: int) -> Dictionary:
	return {"state": save_data(), "moved": 0, "leftover": maxi(0, n)}


## A detached copy of `source`, slot for slot. `set_slot` rather than `add`
## because slot POSITION is player-visible state (`inventory.gd`'s own class
## comment) — a copy that repacked the satchel would preview a layout the
## player never asked for.
func _clone(source: RefCounted) -> RefCounted:
	var out: RefCounted = INVENTORY.new(_db)
	for i in int(source.call("slot_count")):
		var stack: Dictionary = source.call("stack_at", i)
		out.set_slot(i, null if stack.is_empty() else stack)
	return out


## `[stack, ...]` for any inventory, `null` for an empty slot — `save_data()`'s
## array shape, shared so a preview and a save cannot drift apart.
func _slots_of(source: RefCounted) -> Array:
	var out: Array = []
	for i in int(source.call("slot_count")):
		var stack: Dictionary = source.call("stack_at", i)
		out.append(null if stack.is_empty() else stack)
	return out


## R3.1-remainder. `[stack, ...]`, one entry per slot, `null` for an empty
## one — the exact array shape `save_game.gd`'s own `_inventory_to_array`
## uses for the player's satchel, so a chest's contents ride the same JSON
## convention rather than inventing a second one.
func save_data() -> Array:
	return _slots_of(inventory)


## The reverse of `save_data`. `data` is whatever a save file's `state` key
## holds — trusted no further than `save_game.gd` trusts its own inventory
## array. A round trip through `JSON.stringify`/`parse_string` turns every
## `n` into a float (JSON has no integer type), so this re-coerces exactly
## the way `save_game.gd::_stack_from_json` does for the player's own
## satchel; without it a reloaded chest's stacks would carry `"n": 5.0`.
func load_data(data: Variant) -> void:
	if typeof(data) != TYPE_ARRAY:
		return
	var array := data as Array
	for i in inventory.slot_count():
		inventory.set_slot(i, _stack_from_json(array[i] if i < array.size() else null))


func _stack_from_json(stack: Variant) -> Variant:
	if typeof(stack) != TYPE_DICTIONARY:
		return null
	var dict := stack as Dictionary
	var fixed := {"id": str(dict.get("id", "")), "n": int(dict.get("n", 0))}
	if dict.has("durability"):
		fixed["durability"] = int(dict.get("durability"))
	if dict.has("durability_bonus"):
		# SD18: same JSON-float round-trip fix as `durability` above, so a
		# reinforced tool stashed in a chest doesn't lose its raised ceiling.
		fixed["durability_bonus"] = int(dict.get("durability_bonus"))
	return fixed
