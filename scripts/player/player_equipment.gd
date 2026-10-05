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
## damage source in the Meadows is a fall (player_vitals.gd's own fall-damage
## curve). Stormwood lightning separately consumes the two authored insulation
## fields on worn pieces through `storm_mitigation()` below.

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


## F24 pouch occupies the existing backpack slot. HOMESTEAD supplies armor
## definitions with command_pouch_tier 1..4; this reader never equips a new
## slot, creates supplies or changes inventory/save transactions. The host
## freezes this result at encounter admission from the admitted owner record.
func command_pouch_tier() -> int:
	if _items == null:
		return 0
	var id := equipped_in("backpack")
	if id.is_empty() or not bool(_items.call("has", id)):
		return 0
	var row: Dictionary = _items.call("definition", id)
	var tier: Variant = row.get("command_pouch_tier", 0)
	if row.get("kind") != "armor" or row.get("armor_slot") != "backpack" \
			or not (tier is int or tier is float) or not is_finite(float(tier)) \
			or float(tier) != floorf(float(tier)) or float(tier) < 0 or float(tier) > 4:
		return 0
	return int(tier)


func command_pouch_profile() -> Dictionary:
	return preload("res://scripts/combat/tether_commands.gd").tier_profile(command_pouch_tier())


## Bag-facing transaction. Inventory has no callbacks or awaits: removing the
## selected identity and returning the old piece completes before observers poll.
## Preflight on a copy preserves every slot and revision when a swap cannot fit.
func equip_from_inventory(item_id: String, inventory: RefCounted) -> bool:
	if inventory == null or _items == null or int(inventory.call("count", item_id)) < 1:
		return false
	if not bool(_items.call("has", item_id)) or str(_items.call("kind", item_id)) != "armor":
		return false
	var definition: Dictionary = _items.call("definition", item_id)
	var slot := str(definition.get("armor_slot", ""))
	if not is_slot(slot):
		return false
	var displaced := equipped_in(slot)
	var trial: RefCounted = load("res://autoload/inventory.gd").new(_items)
	for index in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", index)
		trial.call("set_slot", index, null if stack.is_empty() else stack)
	trial.call("remove", item_id, 1)
	if not displaced.is_empty() and not bool(trial.call("has_room_for", displaced, 1)):
		return false
	if not bool(inventory.call("remove", item_id, 1)):
		return false
	if not displaced.is_empty():
		inventory.call("add", displaced, 1)
	_equipped[slot] = item_id
	return true


func unequip_to_inventory(slot: String, inventory: RefCounted) -> bool:
	var item_id := equipped_in(slot)
	if item_id.is_empty() or inventory == null or not bool(inventory.call("has_room_for", item_id, 1)):
		return false
	inventory.call("add", item_id, 1)
	_equipped[slot] = ""
	return true


func save_data() -> Dictionary:
	return _equipped.duplicate()


## Missing legacy equipment resets worn slots. Reject unknown items and keys
## whose item belongs to another slot rather than silently moving/duplicating it.
func load_data(raw: Variant) -> void:
	for slot in SLOTS:
		_equipped[slot] = ""
	if not raw is Dictionary or _items == null:
		return
	for slot in SLOTS:
		var value: Variant = raw.get(slot, "")
		if not value is String or not bool(_items.call("has", value)):
			continue
		var definition: Dictionary = _items.call("definition", value)
		if str(definition.get("kind", "")) == "armor" and str(definition.get("armor_slot", "")) == slot:
			_equipped[slot] = value


func is_slot(name: String) -> bool:
	return SLOTS.has(name)


## Sum of every equipped piece's own `defense` field, capped at
## MAX_TOTAL_DEFENSE. 0.0 with nothing equipped or no item database.
func total_defense() -> float:
	if _gear_enabled():
		return hazard_reduction("fall")
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


## Stormwood's worn-gear mitigation. Strike reductions add; duration scales
## multiply, matching their authored meanings. The configured complete-set count
## overrides both to zero. Item ids stay in data: a future insulated piece only
## needs the same two fields and a valid equipped armour slot.
func storm_mitigation(full_set_pieces: int) -> Dictionary:
	var pieces := 0
	var strike_reduction := 0.0
	var static_scale := 1.0
	if _items != null:
		for slot in SLOTS:
			var id := str(_equipped.get(slot, ""))
			if id.is_empty():
				continue
			var definition: Dictionary = _items.call("definition", id)
			if not definition.has("storm_strike_reduction") \
					or not definition.has("static_duration_scale"):
				continue
			pieces += 1
			strike_reduction += clampf(float(definition.storm_strike_reduction), 0.0, 1.0)
			static_scale *= clampf(float(definition.static_duration_scale), 0.0, 1.0)
	var full_set := pieces >= maxi(1, full_set_pieces)
	return {"pieces": pieces, "full_set": full_set,
		"damage_scale": 0.0 if full_set else 1.0 - clampf(strike_reduction, 0.0, 1.0),
		"static_scale": 0.0 if full_set else static_scale}


## F33 hazard arithmetic reads actual worn ItemDB rows. Trainer gear never
## supplies creature stats or a damage action. Consumer hooks below are used
## only when the shared source owner connects the real traversal/hazard path.
const HAZARD_FIELDS := {
	"fall": "fall_damage_reduction", "storm": "storm_strike_reduction",
	"drowning": "drowning_damage_reduction", "swim_stamina": "swim_stamina_reduction",
	"currents": "current_push_reduction", "cold": "cold_penalty_reduction",
	"terrain": "terrain_damage_reduction"
}
static var _gear_rules: Dictionary = {}

func hazard_reduction(hazard: String) -> float:
	if not HAZARD_FIELDS.has(hazard) or _items == null or not _gear_enabled():
		return 0.0
	var total := 0.0
	for slot: String in SLOTS:
		var id := equipped_in(slot)
		if id.is_empty():
			continue
		var row: Dictionary = _items.call("definition", id)
		# Existing travel/hide armour retains its fall protection after activation.
		var raw: Variant = row.get(HAZARD_FIELDS[hazard], row.get("defense", 0.0) if hazard == "fall" else 0.0)
		if (raw is int or raw is float) and is_finite(float(raw)):
			total += clampf(float(raw), 0.0, 1.0)
	var cfg := _gear_config()
	var cap := float(cfg.get("mitigation_cap", MAX_TOTAL_DEFENSE))
	return clampf(total, 0.0, clampf(cap, 0.0, MAX_TOTAL_DEFENSE))

func hazard_scale(hazard: String) -> float:
	return 1.0 - hazard_reduction(hazard)

func mitigate_hazard_damage(damage: float, hazard: String) -> float:
	if not is_finite(damage) or damage <= 0.0:
		return 0.0
	return damage * hazard_scale(hazard)

func current_push(flow: Vector3) -> Vector3:
	return flow * hazard_scale("currents")

func cold_regen_scale(zone_penalty: float) -> float:
	# Called only while inside an authored local cold zone. No cold meter.
	return 1.0 - clampf(zone_penalty, 0.0, 1.0) * hazard_scale("cold")

func local_cold_regen_scale(realm: String, position: Vector3) -> float:
	if not _gear_enabled():
		return 1.0
	var penalty := 0.0
	for zone: Dictionary in _gear_config().get("cold_zones", []):
		if zone.get("realm_id") != realm:
			continue
		var low: Array = zone.get("min", [])
		var high: Array = zone.get("max", [])
		if low.size() != 3 or high.size() != 3:
			continue
		if position.x >= float(low[0]) and position.x <= float(high[0]) \
				and position.y >= float(low[1]) and position.y <= float(high[1]) \
				and position.z >= float(low[2]) and position.z <= float(high[2]):
			penalty = maxf(penalty, float(zone.get("stamina_regen_penalty", 0.0)))
	if penalty <= 0.0:
		return 1.0 # Outside every zone: no worn-gear lookup on this per-frame path.
	return cold_regen_scale(penalty)

func static_duration_scale() -> float:
	if _items == null or not _gear_enabled():
		return 1.0
	var result := 1.0
	for slot: String in SLOTS:
		var row: Dictionary = _items.call("definition", equipped_in(slot))
		var raw: Variant = row.get("static_duration_scale", 1.0)
		if (raw is int or raw is float) and is_finite(float(raw)):
			result *= clampf(float(raw), 0.0, 1.0)
	return clampf(result, 1.0 - float(_gear_config().get("mitigation_cap", MAX_TOTAL_DEFENSE)), 1.0)

static func _gear_config() -> Dictionary:
	if not _gear_rules.is_empty():
		return _gear_rules
	var raw: Variant = preload("res://scripts/data/redesign_data.gd").json("res://data/config/gear.json")
	_gear_rules = raw if raw is Dictionary else {}
	return _gear_rules

## F33#3: the trainer-gear hazard consumers (swim drowning and current, pond
## submersion, Cloudreach cold, Stormwood Dynamo static, hazard terrain) are
## gated together until each has its production-caller test.
static func hazards_live() -> bool:
	return _gear_enabled() and bool(_gear_config().get("feature_flags", {}).get("hazards_enabled", false))

static func _gear_enabled() -> bool:
	return bool(_gear_config().get("feature_flags", {}).get("runtime_enabled", false))
