extends RefCounted

## R7.7. The trainer's five armour slots — GAME_DESIGN.md §18: "Helmet, Upper
## body, Lower body, Boots, Backpack. Trainer armor protects the human, not
## creatures." No more slots and no fewer; adding a sixth (a weapon, a
## shield) is exactly what CLAUDE.md's hard rules forbid — no shields, and
## the human cannot fight — so this module refuses anything that is not one
## of the five.
##
## Kept free of Node/autoload access, the same reasoning player_vitals.gd's
## own header gives for itself: pure state over an item database, testable
## with no scene tree. `autoload/game_state.gd` owns the one live instance
## (`player_equipment`), the same way it owns `inventory` and `party`.
##
## What armour DOES: reduces incoming damage by a flat fraction, summed
## across every equipped piece and capped well under 1.0 (`total_defense()`).
## That is passive mitigation, never a block/parry/counter verb — there is no
## "raise armour" action and nothing here reads player input. The only real
## damage source the Meadows has today is a fall (player_vitals.gd's own
## fall-damage curve); GAME_DESIGN.md §18's "later biomes require gear" line
## is Biome-2 scope and unbuilt here on purpose (CLAUDE.md: no Biome 2 work
## before the Meadows' exit gate).

## GAME_DESIGN.md §18's own list, verbatim order. Anything else is refused.
const SLOTS: Array[String] = ["helmet", "upper_body", "lower_body", "boots", "backpack"]

## A full five-piece set (items.json's own numbers) sums to 0.48; the cap
## sits above that so a future sixth or upgraded piece has room to matter,
## but well below 1.0 -- armour softens a fall, it does not make the player
## unkillable. Tunable.
const MAX_TOTAL_DEFENSE := 0.6

var _equipped: Dictionary = {} # slot name (String) -> item id (String)
var _items: RefCounted = null  # item_db.gd


## `items` is the item database (autoload/item_db.gd or a test double with
## the same has()/kind()/definition() surface) — armour reads its own
## `armor_slot`/`defense` fields from there rather than carrying a second
## copy of either.
func configure(items: RefCounted) -> void:
	_items = items
	_equipped.clear()
	for slot in SLOTS:
		_equipped[slot] = ""


## Puts `item_id` into the slot its own items.json entry names. Refuses (and
## changes nothing) unless the item exists, is `kind: "armor"`, and names one
## of SLOTS — a satchel item with a typo'd or missing `armor_slot` fails
## loudly here rather than silently occupying whatever slot was last tried.
## Returns the item id that PREVIOUSLY held that slot (possibly ""), so the
## caller (an inventory-facing "Equip" verb, not built by this task) can put
## the displaced piece back in the satchel rather than lose it.
func equip(item_id: String) -> Dictionary:
	if _items == null or not bool(_items.call("has", item_id)):
		return {"ok": false, "displaced": ""}
	if str(_items.call("kind", item_id)) != "armor":
		return {"ok": false, "displaced": ""}
	var definition: Dictionary = _items.call("definition", item_id)
	var slot := str(definition.get("armor_slot", ""))
	if not SLOTS.has(slot):
		return {"ok": false, "displaced": ""}
	var displaced := str(_equipped.get(slot, ""))
	_equipped[slot] = item_id
	return {"ok": true, "displaced": displaced}


## Empties `slot`, returning whatever item id was there (possibly "").
func unequip(slot: String) -> String:
	if not SLOTS.has(slot):
		return ""
	var was := str(_equipped.get(slot, ""))
	_equipped[slot] = ""
	return was


func equipped_in(slot: String) -> String:
	return str(_equipped.get(slot, ""))


func is_slot(name: String) -> bool:
	return SLOTS.has(name)


## Sum of every equipped piece's own `defense` field, capped at
## MAX_TOTAL_DEFENSE. 0.0 with nothing equipped or no item database.
func total_defense() -> float:
	if _items == null:
		return 0.0
	var total := 0.0
	for slot in SLOTS:
		var id: String = str(_equipped.get(slot, ""))
		if id == "":
			continue
		var definition: Dictionary = _items.call("definition", id)
		total += float(definition.get("defense", 0.0))
	return clampf(total, 0.0, MAX_TOTAL_DEFENSE)
