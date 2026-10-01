extends RefCounted

## Read-only presentation of actual owned F16 fields. No quoted cost,
## default cap/history, effect application or pending sixth-creature admission.
const DATA := preload("res://scripts/data/redesign_data.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const PARTY := preload("res://autoload/party.gd")
static var _catalog_loaded := false
static var _traits: Dictionary = {}
static var _names: Dictionary = {}
static var _caps: Array = []
static var _essence_items: Dictionary = {}


static func _load_presentation() -> void:
	if _catalog_loaded: return
	_catalog_loaded = true
	var catalog: Dictionary = DATA.load_catalog("traits")
	if catalog.get("ok") == true and catalog.get("data") is Array:
		for row: Dictionary in catalog.data: _traits[row.id] = row.duplicate(true)
	var cfg: Variant = DATA.json("res://data/config/traits.json")
	if cfg is Dictionary and cfg.get("presentation") is Dictionary:
		_names = cfg.presentation.duplicate(true)
	var essences: Variant = DATA.json("res://data/schema/essences.json")
	if essences is Array:
		for row: Variant in essences:
			if row is Dictionary and row.get("type") is String and row.get("id") is String:
				_essence_items[row.type] = row.id
	var caps: Variant = DATA.json("res://data/schema/level_caps.json")
	if caps is Array:
		for row: Variant in caps:
			if row is Dictionary and row.get("status") == "live" and ESSENCE._integer(row.get("level"), 1, 60):
				_caps.append(int(row.level))


static func _trait_name(id: String) -> String:
	var presentation: Variant = _names.get(id)
	var name: Variant = presentation.get("display_name") if presentation is Dictionary else null
	return name if name is String and not name.is_empty() else id.replace("_", " ").capitalize()


static func inspect_owned(player: RefCounted, creature: RefCounted) -> Dictionary:
	var result := {"owned": false, "cap": -1, "level": 0, "at_cap": false,
		"cap_text": "Training details unavailable", "essence_text": "", "trait_text": ""}
	if player == null or creature == null: return result
	var party: Variant = player.get("party")
	var inventory: Variant = player.get("inventory")
	var personal: Variant = player.get("redesign_character")
	if not party is RefCounted or not party.has_method("members") \
			or not inventory is RefCounted or not inventory.has_method("count") \
			or not personal is Dictionary: return result
	var members: Variant = party.call("members")
	if not members is Array or members.size() > PARTY.MAX_CREATURES or not members.has(creature):
		result.cap_text = "Not on your team yet"
		return result
	result.owned = true
	var uid: Variant = creature.get("uid")
	var records: Variant = personal.get("creatures")
	if not ESSENCE._component(uid) or not records is Dictionary: return result
	var record: Variant = records.get(uid)
	if not record is Dictionary: return result # Never invent a default cap.
	_load_presentation()
	var cap: Variant = record.get("cap_level")
	var level: Variant = creature.get("level")
	if ESSENCE._integer(cap, 1, 60) and _caps.has(int(cap)) and ESSENCE._integer(level, 1, 100):
		result.level = int(level)
		if int(level) <= int(cap):
			result.cap = int(cap)
			result.at_cap = int(level) == int(cap)
			result.cap_text = "Level %d / Cap %d" % [int(level), int(cap)]
			if result.at_cap:
				result.cap_text += " · Current ceiling" if int(cap) == 60 else " · Breakthrough needed"
		else:
			result.cap_text = "Level %d · Training needs to sync" % int(level)
	var balances: Array[String] = []
	var seen_types := {}
	for raw: Variant in [creature.get("creature_type"), creature.get("secondary_type")]:
		if not raw is String or raw.is_empty() or seen_types.has(raw): continue
		seen_types[raw] = true
		var item := str(_essence_items.get(raw, ""))
		if not item.is_empty() and RULES.db().has(item):
			balances.append("%s %d" % [RULES.db().item_name(item), int(inventory.call("count", item))])
	if RULES.db().has("tether_candy"):
		balances.append("Tether Candy %d" % int(inventory.call("count", "tether_candy")))
	result.essence_text = "Have: " + " · ".join(balances) if not balances.is_empty() else ""
	var rolled: Variant = record.get("rolled_traits")
	var taught: Variant = record.get("taught_traits")
	var tiers: Variant = record.get("breakthroughs")
	if not rolled is Array or rolled.size() > 3 or not taught is Dictionary \
			or taught.size() > 3 or not tiers is Array:
		result.trait_text = "Trait information unavailable"
		return result
	var seen := {}
	var rolled_names: Array[String] = []
	for id: Variant in rolled:
		if not id is String or not _traits.has(id) or seen.has(id):
			result.trait_text = "Trait information unavailable"
			return result
		seen[id] = true
		rolled_names.append("%s (%s)" % [_trait_name(id), str(_traits[id].rarity).capitalize()])
	for slot: Variant in taught:
		var id: Variant = taught[slot]
		if not slot is String or not slot in ["1", "2", "3"] or not id is String \
				or not _traits.has(id) or seen.has(id) or not tiers.has([1, 3, 5][int(slot) - 1]):
			result.trait_text = "Trait information unavailable"
			return result
		seen[id] = true
	var lines: Array[String] = ["Rolled traits: " + (", ".join(rolled_names) if not rolled_names.is_empty() else "None")]
	for slot: int in 3:
		var key := str(slot + 1)
		if taught.has(key):
			lines.append("Taught %d: %s (%s)" % [slot + 1, _trait_name(taught[key]), str(_traits[taught[key]].rarity).capitalize()])
		elif tiers.has([1, 3, 5][slot]):
			lines.append("Taught %d: Empty" % (slot + 1))
		else:
			lines.append("Taught %d: Locked · L%d breakthrough" % [slot + 1, [10, 30, 50][slot]])
	result.trait_text = "\n".join(lines)
	return result
