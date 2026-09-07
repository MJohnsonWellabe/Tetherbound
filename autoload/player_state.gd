extends RefCounted

## D98 / docs/specs/MP_STATE_SEAM.md §1: THIS TRAINER and THIS TEAM.
##
## One per peer. The local one is `Game.local`; from Wave 2 the host also holds
## every connected peer's in `Game.players`. Every `Game.<x>` this file holds --
## `party`, `inventory`, `player_equipment`, `hotbar`, `equipped_tool`,
## `satiety`, `saved_player_pose`, `pending_catch`, `pending_build`,
## `objective_text`/`objective_hint`, `quest_log`, `realm_hearts`, `map`,
## `current_realm`, `pending_realm_entry` -- stays readable and writable under
## its old name as a forwarding property on `Game`. `Game.party` permanently
## means "the local player's party" (D98), not transitionally: every process
## keeps exactly one local player (the execution plan's §2 simplification).
##
## Three things moved here that used to be process-global, and each is the
## point of the move rather than a tidy-up:
##
##   * `map` is now `maps[realm]`, and the map's EXTENT is per instance
##     (`map_state.gd` lost its `static var _grid_x/_grid_z/_origin`), so a
##     Cloudreach map and a Meadows map can describe different worlds at once.
##   * the progression feed is an instance (`feed`), not
##     `progression_feed.gd`'s static log, so two players' XP banners cannot
##     read each other's events.
##   * `realm` replaces `current_realm`: which realm a trainer is standing in
##     is per player from Wave 6.
##
## Pure logic, no `Node`, no transform, testable headlessly
## (`tests/test_player_state.gd`). Anything that needs the scene tree -- the
## live `PlayerVitals` behind `satiety`, the pose capture, the four world-record
## sync seams -- stays in `Game`.

const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")
const CLOUDREACH_MAP_STATE := preload("res://scripts/world/cloudreach_map_state.gd")
const REALM_MAP_STATE := preload("res://scripts/world/realm_map_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const REALM_HEART_STATE := preload("res://autoload/realm_heart_state.gd")
const PLAYER_EQUIPMENT := preload("res://scripts/player/player_equipment.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PROGRESSION_FEED := preload("res://scripts/creatures/progression_feed.gd")
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const SPECIES_PATH := "res://data/creatures/species.json"
const MAP_LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const CLOUDREACH_WORLD_PATH := "res://data/config/cloudreach_world.json"
const CLOUDREACH_CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const REALM_HEARTS_PATH := "res://data/config/realm_hearts.json"

## The realms that have an implemented map. Waterward is a distant vista, not
## an enterable place (CLAUDE.md's Biome 2 rule), so it gets no MapState.
const DEFAULT_MAPPED_REALMS: Array[String] = ["meadows", "cloudreach"]

## Item kinds that may occupy an action slot -- an allow-list, not a refusal
## list. Owner board, "UI / SYSTEM FIXES CHECKLIST": "Hotbar: consumables +
## tools only (no wood/stone/etc.)". Moved verbatim from `game_state.gd`, where
## `Game.HOTBAR_KINDS_ALLOWED`/`Game.HOTBAR_SLOTS` remain as aliases onto these.
const HOTBAR_KINDS_ALLOWED := ["tool", "consumable", "food"]
const HOTBAR_SLOTS := 5

## Stable id minted on New Character; from 1.C, the character save's directory
## name. "" until 1.C mints one.
var character_id: String = ""
## The nameplate a remote peer draws over this trainer (Wave 2).
var display_name: String = ""

var party: RefCounted = null
var inventory: RefCounted = null
var equipment: RefCounted = null
var hotbar: Array[String] = ["", "", "", "", ""]
var equipped_tool: String = ""
var satiety: float = 100.0
var pose: Dictionary = {}

## Which realm THIS peer is in. Was `Game.current_realm`, a single global
## answer; per player from now on.
var realm: String = "meadows"
var pending_realm_entry: String = ""

## The PLAYER half of the old flat `Game.progression` store: every id
## `progression_state.scope_of()` answers "player" for.
var flags: RefCounted = null

## realm id -> MapState. Fog, landmarks, dynamic markers, regions and alpha
## pins, per realm, per player.
var maps: Dictionary = {}
var _map_definitions_override: Dictionary = {}

var hearts: RefCounted = null
var feed: RefCounted = null
var quest_log: RefCounted = null

var pending_catch: RefCounted = null
var pending_build: String = ""
var objective_text: String = ""
var objective_hint: String = ""

## The immutable `ItemDB`, handed over by `Game` -- the hotbar rules need to ask
## an item its kind. Not owned here: there is one catalogue per process and it
## is `Game.items`.
var items: RefCounted = null

## What the map and the Realm Hearts read flags THROUGH. `Game` sets this to the
## merged view (`merged_progression.gd`), so a Cloudreach landmark gated on a
## world flag and a hint gated on a personal one both answer correctly from one
## object. Never written through: the two stores above are the only writers.
var flag_reader: RefCounted = null


func _init() -> void:
	flags = PROGRESSION_STATE.new()
	feed = PROGRESSION_FEED.new()
	_build_transients()


## The same empty state a process boot creates, in place. Called by
## `Game.reset_for_new_game()`.
##
## `flags` and `feed` keep their OBJECT IDENTITY across the reset and are
## emptied instead: `merged_progression.gd` holds a reference to `flags`, and
## `progression_feed.gd`'s epoch must keep climbing across a New Game or a
## presenter that cached epoch 3 would see a fresh feed's epoch 0 and read it as
## "no reset happened". `clear()` is the feed's own new-game reset and bumps the
## epoch, exactly as `Game.reset_for_new_game()` has always called it.
func reset() -> void:
	flags.call("load_data", {})
	feed.call("clear_events")
	maps.clear()
	realm = "meadows"
	pending_realm_entry = ""
	pose = {}
	satiety = 100.0
	hotbar = ["", "", "", "", ""]
	equipped_tool = ""
	pending_catch = null
	pending_build = ""
	objective_text = ""
	objective_hint = ""
	_build_transients()


func _build_transients() -> void:
	inventory = INVENTORY.new(items) if items != null else INVENTORY.new(null)
	party = PARTY.new()
	equipment = PLAYER_EQUIPMENT.new()
	equipment.call("configure", items)
	hearts = REALM_HEART_STATE.new()
	quest_log = QUEST_LOG.new()


## `Game` hands over the one catalogue in the process. Called before
## `reset()`/`_build_transients()` does anything that needs it; re-binding it
## afterwards rebuilds the two objects that hold a reference.
func configure(item_db: RefCounted) -> void:
	items = item_db
	if inventory != null:
		inventory = INVENTORY.new(items)
	if equipment != null:
		equipment.call("configure", items)


# --- maps -------------------------------------------------------------------

## The MapState for `realm_id`, built on first ask. null for a realm with no
## implemented map.
##
## The extent is now per instance (`map_state.gd` lost its statics), so the
## Cloudreach map is configured with the Cloudreach bounds and the Meadows map
## with the Meadows ones, and neither can overwrite the other's grid. That is
## the whole reason this lane touched `map_state.gd`.
func map_for(realm_id: String) -> RefCounted:
	var definition := map_definition_for(realm_id)
	if definition.is_empty():
		return null
	if maps.has(realm_id):
		return maps[realm_id]
	var instance: RefCounted
	if realm_id == "cloudreach":
		instance = CLOUDREACH_MAP_STATE.new()
		instance.call("configure_cloudreach", _json(str(definition.get("map_world_path", CLOUDREACH_WORLD_PATH))),
			_json(str(definition.get("map_chapter_path", CLOUDREACH_CHAPTER_PATH))), flag_reader)
	elif realm_id == "meadows":
		instance = MAP_STATE.new()
		instance.call("configure", _json(str(definition.get("map_landmarks_path", MAP_LANDMARKS_PATH))))
	else:
		instance = REALM_MAP_STATE.new()
		instance.call("configure_realm", realm_id, definition,
			_json(str(definition.get("map_world_path", ""))),
			_json(str(definition.get("map_chapter_path", ""))),
			_json(str(definition.get("map_tuning_path", ""))), flag_reader)
	maps[realm_id] = instance
	return instance


## The map for the realm this player is standing in. `Game.map` forwards here.
func map() -> RefCounted:
	return map_for(realm)


## Every realm map's payload, keyed by realm id -- what `save_game.gd` writes
## under `realm_maps`. Builds any map not yet visited so the key set is stable.
func map_payloads() -> Dictionary:
	var payloads: Dictionary = {}
	for realm_id: String in mapped_realm_ids():
		var instance := map_for(realm_id)
		payloads[realm_id] = instance.call("save_data") if instance != null else {}
	return payloads


func load_map_payloads(payloads: Dictionary) -> void:
	for realm_id: String in mapped_realm_ids():
		var instance := map_for(realm_id)
		if instance == null:
			continue
		var payload: Variant = payloads.get(realm_id, {})
		instance.call("load_data", payload if payload is Dictionary else {})


## Test fixtures and future realm catalogues can replace this small registry
## without constructing a world scene. Reconfigure before gameplay begins;
## clearing avoids retaining a MapState with an obsolete grid descriptor.
func configure_map_definitions(definitions: Dictionary) -> void:
	_map_definitions_override = definitions.duplicate(true)
	maps.clear()


func mapped_realm_ids() -> Array[String]:
	var ids: Array[String] = []
	var definitions := _map_definitions()
	for preferred: String in DEFAULT_MAPPED_REALMS:
		if definitions.has(preferred):
			ids.append(preferred)
	var remaining: Array = []
	for realm_id: Variant in definitions.keys():
		var id := str(realm_id)
		if not ids.has(id):
			remaining.append(id)
	remaining.sort()
	for realm_id: Variant in remaining:
		ids.append(str(realm_id))
	return ids


func map_definition_for(realm_id: String) -> Dictionary:
	var raw: Variant = _map_definitions().get(realm_id, {})
	return raw.duplicate(true) if raw is Dictionary else {}


func _map_definitions() -> Dictionary:
	if not _map_definitions_override.is_empty():
		return _map_definitions_override
	var definitions: Dictionary = {
		"meadows": {"display_name": "The Meadows", "map_landmarks_path": MAP_LANDMARKS_PATH},
		"cloudreach": {"display_name": "Cloudreach Cliffs", "map_world_path": CLOUDREACH_WORLD_PATH,
			"map_chapter_path": CLOUDREACH_CHAPTER_PATH},
	}
	var config := _json(REALM_HEARTS_PATH)
	var realms: Variant = config.get("realms", {})
	if not (realms is Dictionary):
		return definitions
	for realm_id: String in (realms as Dictionary):
		var raw: Variant = (realms as Dictionary)[realm_id]
		if not (raw is Dictionary):
			continue
		var authored := raw as Dictionary
		# Existing maps retain their known paths until those optional fields are
		# authored; a new map opts in by declaring any map source path.
		if realm_id not in definitions and not authored.has("map_world_path") \
				and not authored.has("map_landmarks_path"):
			continue
		var merged: Dictionary = definitions.get(realm_id, {}).duplicate(true)
		merged.merge(authored, true)
		definitions[realm_id] = merged
	return definitions


# --- the hotbar -------------------------------------------------------------
##
## Item ids, never satchel indices -- an index is a position in the satchel and
## moving a stack changes it; an id survives sorting, splitting and spending the
## last one. Moved verbatim from `game_state.gd`.

func hotbar_can_hold(item_id: String) -> bool:
	if item_id.is_empty() or items == null:
		return false
	var definition := items.call("definition", item_id) as Dictionary
	if definition.is_empty():
		return false
	return HOTBAR_KINDS_ALLOWED.has(str(items.call("kind", item_id)))


## Put `item_id` on `slot`. "" clears it. Assigning an item that already sits on
## another slot MOVES it: two slots holding one id would both draw the same
## count and spend from the same stack.
func assign_hotbar(slot: int, item_id: String) -> bool:
	if slot < 0 or slot >= HOTBAR_SLOTS:
		return false
	if item_id.is_empty():
		hotbar[slot] = ""
		return true
	if not hotbar_can_hold(item_id):
		return false
	for i in HOTBAR_SLOTS:
		if hotbar[i] == item_id:
			hotbar[i] = ""
	hotbar[slot] = item_id
	return true


func hotbar_slot_of(item_id: String) -> int:
	if item_id.is_empty():
		return -1
	return hotbar.find(item_id)


## Fill any empty slots from what the satchel is actually carrying, in bag
## order, skipping refused kinds and anything already bound.
func autofill_hotbar() -> void:
	if inventory == null:
		return
	for slot in HOTBAR_SLOTS:
		if not hotbar[slot].is_empty():
			continue
		for index in int(inventory.get("SLOT_COUNT")):
			var stack: Dictionary = inventory.call("stack_at", index)
			if stack.is_empty():
				continue
			var id := str(stack.get("id", ""))
			if not hotbar_can_hold(id) or hotbar.has(id):
				continue
			hotbar[slot] = id
			break


# --- creatures --------------------------------------------------------------

## Build a live creature from a species id. Party membership still goes through
## `party.add`, which is the only thing that knows about the five-creature cap.
func make_creature(species_id: String, nickname: String = "") -> RefCounted:
	var definition := _species(species_id)
	if definition.is_empty():
		push_warning("unknown species: %s" % species_id)
		return null
	var creature: RefCounted = CREATURE_INSTANCE.from_species(species_id, definition)
	creature.nickname = nickname
	return creature


# --- save / load ------------------------------------------------------------

## The PLAYER half of today's v22 save dictionary (`MP_STATE_SEAM.md` §4), which
## 1.C writes to `user://characters/<character_id>/character.json`. The v22 key
## names are kept verbatim except the two the partition renames
## (`current_realm` -> `realm`, `progression` -> `flags`, its player half).
##
## `alpha_pins` is NOT a key here: this lane moved the pinned set inside each
## realm map's own `save_data()`, where the fog and the landmarks already live.
## `Game.save_game()` still emits the top-level v22 `alpha_pins` key, read back
## off the active map through `alpha_pin_save_data()`, so `save_game.gd` and 1.C
## see no change until 1.C migrates the key.
##
## The party and satchel serializers are `save_game.gd`'s, called rather than
## re-implemented: there must stay exactly ONE definition of what a saved
## creature looks like, and it is that file's. 1.C re-homes them into
## `character_save.gd` and this call goes with them.
func save_data() -> Dictionary:
	var saver: RefCounted = SAVE_GAME.new()
	return {
		"character_id": character_id,
		"display_name": display_name,
		"party": saver.call("_party_to_array", party),
		"inventory": saver.call("_inventory_to_array", inventory),
		"hotbar": _hotbar_array(),
		"satiety": satiety,
		"player_pose": pose.duplicate(true),
		"realm": realm,
		"pending_realm_entry": pending_realm_entry,
		"realm_hearts": hearts.call("save_data") if hearts != null else {},
		"realm_maps": map_payloads(),
		"flags": flags.save_data() if flags != null else {},
	}


## Tolerant of every missing key -- `load_data({})` is a working fresh state.
func load_data(data: Dictionary) -> void:
	var loader: RefCounted = SAVE_GAME.new()
	character_id = str(data.get("character_id", character_id))
	display_name = str(data.get("display_name", display_name))
	loader.call("_array_to_party", data.get("party", []), party)
	loader.call("_array_to_inventory", data.get("inventory", []), inventory)
	_load_hotbar(data.get("hotbar", []))
	satiety = float(data.get("satiety", 100.0)) if _finite(data.get("satiety")) else 100.0
	var raw_pose: Variant = data.get("player_pose", {})
	pose = (raw_pose as Dictionary).duplicate(true) if typeof(raw_pose) == TYPE_DICTIONARY else {}
	realm = str(data.get("realm", "meadows"))
	pending_realm_entry = str(data.get("pending_realm_entry", ""))
	if flags == null:
		flags = PROGRESSION_STATE.new()
	var raw_flags: Variant = data.get("flags", {})
	flags.call("load_data", raw_flags if typeof(raw_flags) == TYPE_DICTIONARY else {})
	var raw_maps: Variant = data.get("realm_maps", {})
	load_map_payloads(raw_maps as Dictionary if typeof(raw_maps) == TYPE_DICTIONARY else {})
	if hearts != null:
		var raw_hearts: Variant = data.get("realm_hearts", {})
		hearts.call("load_data",
			raw_hearts as Dictionary if typeof(raw_hearts) == TYPE_DICTIONARY else {},
			flag_reader)


func _hotbar_array() -> Array:
	var out: Array = []
	for id: String in hotbar:
		out.append(id)
	return out


func _load_hotbar(raw: Variant) -> void:
	hotbar = ["", "", "", "", ""]
	if typeof(raw) != TYPE_ARRAY:
		return
	var entries := raw as Array
	for slot in mini(HOTBAR_SLOTS, entries.size()):
		var id: Variant = entries[slot]
		hotbar[slot] = str(id) if typeof(id) == TYPE_STRING else ""


func _finite(raw: Variant) -> bool:
	return (typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT) and is_finite(float(raw))


func _species(species_id: String) -> Dictionary:
	var table: Variant = _json(SPECIES_PATH).get("species", {})
	if typeof(table) != TYPE_DICTIONARY:
		return {}
	var entry: Variant = (table as Dictionary).get(species_id, {})
	return entry as Dictionary if typeof(entry) == TYPE_DICTIONARY else {}


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}
