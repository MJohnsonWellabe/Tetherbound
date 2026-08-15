extends RefCounted

## SB10: the generic mechanism behind every physical gate the spec names —
## the South Bridge Key, the Mill Bridge Gear, the three Sigils (§3 Gate 1,
## §15, §19). A gate is a carried item operating the world; never a level
## check, never a UI lock.
##
## Pure logic, no Node, no transform — same split `progression_state.gd`
## itself draws, testable headlessly. A scene-tree caller (`road_gate.gd`)
## owns the mesh/collision/prompt; this owns only "does the player have what
## it takes, and has this gate already been opened."
##
## Persistence rides on `progression_state.gd` rather than a bespoke save
## slot: opening a gate just sets `flag_id`, and `is_open()` is a read of
## that same flag — a gate opened before a save survives reload for free.
## `road_gate.gd`'s own `_open` was a plain in-memory bool before this and
## relocked on every scene rebuild (a fresh game, a reload, even walking far
## enough to unload/reload the world); that is the real bug this class fixes,
## not just the "make it reusable" ask.

var item_id: String
var flag_id: String


func _init(p_item_id: String, p_flag_id: String) -> void:
	item_id = p_item_id
	flag_id = p_flag_id


## Whether this gate has already been opened, per `progression`'s flag store.
func is_open(progression: RefCounted) -> bool:
	return progression.has(flag_id)


## The one thing a caller does on interaction. Already open: a no-op that
## reports open. Otherwise, consumes one `item_id` from `inventory` and sets
## `flag_id` if the player is carrying it. Returns whether the gate is open
## after the call — true means "just opened" or "already was", false means
## still locked (the caller still has whatever it started with).
func try_open(inventory: RefCounted, progression: RefCounted) -> bool:
	if is_open(progression):
		return true
	if inventory.count(item_id) <= 0:
		return false
	inventory.remove(item_id, 1)
	progression.set_flag(flag_id)
	return true
