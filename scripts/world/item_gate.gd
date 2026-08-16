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

## SF34: a gate may name MORE THAN ONE item, and then it needs all of them at
## once — spec §3 Band 4's three Sigils are one lock with three keys, not
## three gates. `item_id` stays a plain String for every single-key caller
## (`road_gate.gd` passes one and reads nothing else); `item_ids` is the real
## list every check below runs on, and a one-key gate is just the list of one.
## Deliberately NOT a partial-open state: 2/3 is sealed, exactly like 0/3.
var item_id: String
var item_ids: PackedStringArray = PackedStringArray()
var flag_id: String


## `p_items` is a String (one key) or an Array/PackedStringArray of ids (all
## required). Anything else is a caller bug and is treated as no key at all,
## which fails closed — a gate that cannot be opened beats a gate that opens
## for nothing.
func _init(p_items: Variant, p_flag_id: String) -> void:
	if typeof(p_items) == TYPE_STRING:
		item_ids = PackedStringArray([str(p_items)])
	elif typeof(p_items) == TYPE_ARRAY or typeof(p_items) == TYPE_PACKED_STRING_ARRAY:
		for id: Variant in p_items:
			item_ids.append(str(id))
	else:
		push_error("item_gate.gd: `%s` is not an item id or a list of them" % [p_items])
	item_id = item_ids[0] if item_ids.size() > 0 else ""
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
	if item_ids.is_empty() or held(inventory) < item_ids.size():
		# ALL or nothing: a two-of-three attempt spends nothing. Consuming
		# what the player does have would take the Sigils out of the satchel
		# and leave the gate shut, which is the one failure a physical-key
		# gate must never have.
		return false
	for id: String in item_ids:
		inventory.remove(id, 1)
	progression.set_flag(flag_id)
	return true


## SF34: how many of this gate's items the player is carrying right now, for a
## gate that wants to say "2/3" rather than just "locked". Counts DISTINCT
## required ids held at least once, never a stack size — three of one Sigil is
## still one Sigil as far as the lock is concerned.
func held(inventory: RefCounted) -> int:
	var n := 0
	for id: String in item_ids:
		if int(inventory.count(id)) > 0:
			n += 1
	return n


## How many items this gate needs in total. `held(...) == required()` is the
## same question `try_open` asks, without the side effects — for a HUD line,
## an objective counter or a test.
func required() -> int:
	return item_ids.size()
