extends RefCounted

## Versioned save/load for the state that has to survive a quit: the party,
## the satchel, the day counter and placed buildings (R3.1). `docs/HANDOFF.md`
## §4 has said "still not one write to user:// outside settings" since the
## settings screen shipped; this is the first one.
##
## Same shape `docs/decisions/D15` set for `user://settings.json`: JSON, a
## `version` field from the first write, and never fatal on load — a missing,
## corrupt, or newer-than-this-build slot just means "nothing to load", the
## same three "carry on, do not brick the player" cases D15 named for
## settings. There is no migration path yet because there is only one version.
##
## Pure logic, no nodes, so `tests/test_save_format.gd` can exercise it
## headlessly — the same split `autoload/party.gd`, `autoload/inventory.gd`
## and `scripts/ui/key_bindings.gd` all already draw. `game` below is
## whatever object holds `day`, `party`, `inventory` and `placed_buildings` as
## properties — the `Game` autoload in the real build, a small fake in tests.

const PAL_INSTANCE := preload("res://scripts/pals/pal_instance.gd")

const VERSION := 1
const SLOT_COUNT := 5
## Written automatically whenever the player rests (`scripts/build/camp.gd`).
## Slots 1-4 are the player's own manual saves. Nothing enforces the split
## beyond this comment — any slot reads and writes the same way.
const AUTOSAVE_SLOT := 0

var _dir: String


func _init(dir: String = "user://saves/") -> void:
	_dir = dir if dir.ends_with("/") else dir + "/"


func slot_path(slot: int) -> String:
	return "%sslot_%d.json" % [_dir, slot]


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## What a slot list screen needs without loading it onto live state — empty
## for no save, an unreadable file, or a version this build cannot read.
func slot_info(slot: int) -> Dictionary:
	var data := _read(slot)
	if data.is_empty():
		return {}
	return {
		"day": int(data.get("day", 1)),
		"party_size": (data.get("party", []) as Array).size(),
	}


## Serialize `game` into `slot`. Returns whether the write succeeded.
func save(game: Object, slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	DirAccess.make_dir_recursive_absolute(_dir)

	var data := {
		"version": VERSION,
		"day": int(game.get("day")),
		"party": _party_to_array(game.get("party")),
		"inventory": _inventory_to_array(game.get("inventory")),
		"placed_buildings": (game.get("placed_buildings") as Array).duplicate(true),
	}

	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


## Rehydrate `game` from `slot`. Returns whether a save was actually applied —
## false, with `game` left untouched, for a missing, corrupt, or
## newer-than-this-build file.
func load_slot(game: Object, slot: int) -> bool:
	var data := _read(slot)
	if data.is_empty():
		return false
	var version := int(data.get("version", 0))
	if version != VERSION:
		push_warning("save slot %d is version %d, this build reads %d -- not loading" % [
			slot, version, VERSION
		])
		return false

	game.set("day", int(data.get("day", 1)))
	_array_to_party(data.get("party", []), game.get("party"))
	_array_to_inventory(data.get("inventory", []), game.get("inventory"))
	game.set("placed_buildings", (data.get("placed_buildings", []) as Array).duplicate(true))
	return true


func _read(slot: int) -> Dictionary:
	if slot < 0 or slot >= SLOT_COUNT:
		return {}
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _party_to_array(party: Variant) -> Array:
	var out: Array = []
	if party == null:
		return out
	for pal: Variant in ((party as RefCounted).call("members") as Array):
		var instance := pal as RefCounted
		out.append({
			"species_id": str(instance.get("species_id")),
			"display_name": str(instance.get("display_name")),
			"pal_type": str(instance.get("pal_type")),
			"nickname": str(instance.get("nickname")),
			"max_hp": float(instance.get("max_hp")),
			"attack": float(instance.get("attack")),
			"defence": float(instance.get("defence")),
			"hp": float(instance.get("hp")),
			"energy": float(instance.get("energy")),
			"fainted": bool(instance.get("fainted")),
		})
	return out


## Fields are set directly rather than going through `PalInstance.from_species`
## so a load never depends on `species.json` still defining the species —
## an instance's saved stats are trusted as-is, the same "carry on with what
## the file says" spirit as the rest of this class.
func _array_to_party(entries: Variant, party: Variant) -> void:
	if party == null or typeof(entries) != TYPE_ARRAY:
		return
	var party_ref := party as RefCounted
	party_ref.call("clear")
	for raw: Variant in (entries as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var d := raw as Dictionary
		var pal: RefCounted = PAL_INSTANCE.new()
		pal.species_id = str(d.get("species_id", ""))
		pal.display_name = str(d.get("display_name", pal.species_id))
		pal.pal_type = str(d.get("pal_type", "ground"))
		pal.nickname = str(d.get("nickname", ""))
		pal.max_hp = float(d.get("max_hp", 1.0))
		pal.attack = float(d.get("attack", 1.0))
		pal.defence = float(d.get("defence", 1.0))
		pal.hp = float(d.get("hp", pal.max_hp))
		pal.energy = float(d.get("energy", 0.0))
		pal.fainted = bool(d.get("fainted", false))
		party_ref.call("add", pal)


func _inventory_to_array(inventory: Variant) -> Array:
	var out: Array = []
	if inventory == null:
		return out
	var inventory_ref := inventory as RefCounted
	var count: int = int(inventory_ref.call("slot_count"))
	for i in count:
		var stack: Dictionary = inventory_ref.call("stack_at", i)
		out.append(null if stack.is_empty() else stack)
	return out


func _array_to_inventory(entries: Variant, inventory: Variant) -> void:
	if inventory == null or typeof(entries) != TYPE_ARRAY:
		return
	var inventory_ref := inventory as RefCounted
	var array := entries as Array
	var count: int = int(inventory_ref.call("slot_count"))
	for i in count:
		var stack: Variant = array[i] if i < array.size() else null
		inventory_ref.call("set_slot", i, _stack_from_json(stack))


## JSON has no integer type — every number round-trips as a float
## (`JSON.parse_string`), so a stack read back from a save would otherwise
## carry `"n": 12.0` instead of `12`. `id`/`n` are Inventory's own stack
## contract (see `autoload/inventory.gd`); `durability` is optional and only
## present on tools.
func _stack_from_json(stack: Variant) -> Variant:
	if typeof(stack) != TYPE_DICTIONARY:
		return null
	var dict := stack as Dictionary
	var fixed := {"id": str(dict.get("id", "")), "n": int(dict.get("n", 0))}
	if dict.has("durability"):
		fixed["durability"] = int(dict.get("durability"))
	return fixed
