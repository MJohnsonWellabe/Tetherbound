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


func _init(db: RefCounted) -> void:
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
