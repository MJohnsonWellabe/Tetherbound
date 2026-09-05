extends Node

## CL-W1 — alphas pin to the map at 300 m and stay pinned until caught or beaten.
##
## Owner directive D-0904B-1: *"Within 300 m an alpha appears on the map, and
## does not disappear until caught."* Amendment A-3 settles the open question
## that directive itself flagged (a player whose five slots are full cannot
## catch anything, so a catch-only clear would leave a permanent pin they can
## do nothing about): **caught OR beaten**. Both outcomes already fire the same
## flag, so both clear the pin for free — see `_once_flag_for` below.
##
## Sixteen `alpha`/`elder` clusters are authored across
## `data/config/bands/*/spawns.json` and were, until this file existed, entirely
## unadvertised: the player could walk the whole corridor past every one of them
## and never learn they were there.
##
## ## Why the pin comes from the DATA, not from a body
##
## The obvious implementation — watch the live wild creatures, pin the ones
## flagged alpha — does not work at this range and would have been discovered
## only in play. `encounter_director.gd` streams wild bodies in around the
## player; at 300 m an alpha's body very often does not exist yet, so a
## body-driven pin would appear only once the player could already SEE the
## creature, which advertises nothing. This file reads the authored cluster
## centres out of the spawn config once, at `_ready()`, and never looks at a
## body at all. That also keeps `map_state.gd`'s "never a radar" rule honest:
## the pin is a fixed authored place, and it does not move when the creature
## does.
##
## ## Why this is its own node
##
## The brief's own boundary, and a good one: `encounter_director.gd` is already
## 2,000 lines and owns the live population. This owns a proximity test and two
## `MapState` calls, shares no state with the director, and is dropped into the
## world by one `add_child` line in `playground_world.gd`. It is a plain `Node`
## with no transform because it has no place in the world — it reads the
## player's.
##
## ## Persistence
##
## Not here. `MapState` holds the pinned set (`pin_alpha`/`unpin_alpha`) and
## `scripts/save/save_game.gd` VERSION 17 writes it at the save's top level, so
## a loaded save already has its pins and their markers back before this node
## has ticked once. What this node does on load is the other half: prune any pin
## whose alpha was already beaten (`_prune_cleared()`), which covers the case
## where the flag fired in a session whose save happened before the pin logic
## existed, and re-arm the proximity test for everything else.

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const SPAWNS_CONFIG := "res://data/config/spawns.json"
const MAP_CONFIG := "res://data/config/map.json"

## The one-shot intro line is remembered as a progression flag rather than a
## field on this node: it must survive a save, a reload and walking out of the
## world scene and back in, and `progression` is the store that already does
## all three. See `data/config/map.json`'s own comment for why it fires once
## and not sixteen times.
const INTRO_FLAG := "alpha_pin_intro_seen"

## Fallbacks, used only if `data/config/map.json` is missing or malformed.
## Every one of them is the same value that file authors, so a build with a
## broken config still behaves rather than silently pinning nothing.
const DEFAULT_RADIUS_M := 300.0
const DEFAULT_INTERVAL_S := 0.5
const DEFAULT_ICON := "alpha"
const DEFAULT_MESSAGE := "An alpha is near — marked on your map."

@export var player_path: NodePath = ^"../Player"

var _player: Node3D = null
var _radius_m := DEFAULT_RADIUS_M
var _radius_sq := DEFAULT_RADIUS_M * DEFAULT_RADIUS_M
var _interval_s := DEFAULT_INTERVAL_S
var _icon := DEFAULT_ICON
var _message := DEFAULT_MESSAGE
var _elapsed := 0.0

## One entry per authored alpha/elder cluster: {order, species, display_name,
## position: Vector2, once_id}. Built once in `_ready()` — the spawn config
## does not change at runtime, and re-parsing five JSON files twice a second
## would be the whole cost of this feature.
var _clusters: Array[Dictionary] = []


func _ready() -> void:
	_read_config()
	_clusters = build_clusters()
	_player = get_node_or_null(player_path) as Node3D
	# A world with no player (a headless boot, a menu-only scene) has nobody to
	# measure a distance from. Everything else about this node still works, so
	# the load-time prune below still runs; only the proximity tick idles.
	_prune_cleared()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _interval_s:
		return
	_elapsed = 0.0
	tick()


## The whole per-tick job, split out from `_process` so a test or a probe can
## drive it directly without a SceneTree clock. Safe to call at any cadence.
func tick() -> void:
	var map: RefCounted = _map()
	if map == null:
		return
	_prune_cleared()
	if _player == null or not is_instance_valid(_player):
		return
	var here := Vector2(_player.global_position.x, _player.global_position.z)
	for cluster: Dictionary in _clusters:
		var order := int(cluster.get("order", 0))
		if map.call("is_alpha_pinned", order):
			continue
		if _once_cleared(str(cluster.get("once_id", ""))):
			continue
		var position: Vector2 = cluster.get("position", Vector2.ZERO)
		# XZ only, deliberately: the corridor climbs, and a 3D distance would
		# pin a ridge alpha later than a flat-ground one at the same map
		# distance. "Within 300 m" on a map means map distance.
		if here.distance_squared_to(position) > _radius_sq:
			continue
		if map.call(
				"pin_alpha",
				order,
				str(cluster.get("species", "")),
				str(cluster.get("display_name", "")),
				Vector3(position.x, 0.0, position.y),
				_icon):
			_announce_first_pin()


## Removes the pin of every alpha whose once-flag has already fired. Runs on
## `_ready()` (so a load lands correct even if the save predates this feature or
## the flag fired between the pin and the save) and at the top of every tick (so
## a pin clears within half a second of the fight ending, without this file
## having to know anything about how a fight ends).
func _prune_cleared() -> void:
	var map: RefCounted = _map()
	if map == null:
		return
	for cluster: Dictionary in _clusters:
		var order := int(cluster.get("order", 0))
		if not map.call("is_alpha_pinned", order):
			continue
		if _once_cleared(str(cluster.get("once_id", ""))):
			map.call("unpin_alpha", order)


## Every authored alpha/elder cluster, from the merged band spawn config.
##
## Static and public because `tests/test_alpha_pins.gd` asserts against the real
## authored content — that all sixteen are found, that each mints the once-id
## `encounter_director.gd` actually fires, and that none of them lands on a
## position of (0, 0) — and a test that built its own copy of this loop would be
## pinning its own arithmetic rather than the game's.
static func build_clusters() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var config: Dictionary = BAND_CONTENT.load_config(SPAWNS_CONFIG, "spawns")
	var spawns: Array = config.get("spawns", [])
	for index in spawns.size():
		var raw: Variant = spawns[index]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var spawn := raw as Dictionary
		var alpha: Dictionary = spawn.get("alpha", {}) if spawn.get("alpha", {}) is Dictionary else {}
		var elder: Dictionary = spawn.get("elder", {}) if spawn.get("elder", {}) is Dictionary else {}
		if alpha.is_empty() and elder.is_empty():
			continue
		var centre_raw: Variant = spawn.get("centre", [])
		var centre: Array = centre_raw as Array if typeof(centre_raw) == TYPE_ARRAY else []
		if centre.size() < 3:
			continue
		var species := str(spawn.get("species", ""))
		# `order` is the entry's own stable, globally-unique identity (the band
		# files' own header) and is what `encounter_director.gd` already builds
		# the once-flag from, so the pin needs no new authored field either.
		var order := int(spawn.get("order", index))
		out.append({
			"order": order,
			"species": species,
			"display_name": _label_for(species, alpha, elder),
			"position": Vector2(float(centre[0]), float(centre[2])),
			"once_id": _once_flag_for(order),
		})
	return out


## The exact id `encounter_director.gd::_spawn_creatures()` mints for a band
## alpha or elder ("wild_once_%d" % order), and the same one it fires in
## `_on_combat_exited()` on both `won` and `CAUGHT`. Pinned by
## `tests/test_alpha_pins.gd` against that file, because two independent
## spellings of one id is a pin that never clears and no error anywhere.
static func _once_flag_for(order: int) -> String:
	return "wild_once_%d" % order


## What the full map calls this pin.
##
## Mirrors what the player will actually read on the creature's own nameplate
## when they get there, so the map and the world agree: `_apply_elder()` prefixes
## the elder's authored `title` ("Elder Mosshell"), and `_make_alpha()` marks its
## individual as an alpha, which the game says as "Alpha <species>". A species
## with no `display_name` in `species.json` falls back to its id capitalised
## rather than printing an empty label.
static func _label_for(species: String, alpha: Dictionary, elder: Dictionary) -> String:
	var definition: Dictionary = SPECIES.definition(species)
	var shown := str(definition.get("display_name", ""))
	if shown.is_empty():
		shown = species.capitalize()
	if not elder.is_empty():
		var title := str(elder.get("title", "Elder"))
		return "%s %s" % [title, shown] if not title.is_empty() else shown
	if not alpha.is_empty():
		return "Alpha %s" % shown
	return shown


func _announce_first_pin() -> void:
	if _message.is_empty():
		return
	var progression: RefCounted = _progression()
	if progression == null:
		return
	if bool(progression.call("has", INTRO_FLAG)):
		return
	progression.call("set_flag", INTRO_FLAG)
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", _message)


func _read_config() -> void:
	var parsed: Variant = null
	if FileAccess.file_exists(MAP_CONFIG):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(MAP_CONFIG))
	var config: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	var pin: Dictionary = config.get("alpha_pin", {}) if config.get("alpha_pin", {}) is Dictionary else {}
	_radius_m = maxf(0.0, float(pin.get("radius_m", DEFAULT_RADIUS_M)))
	_radius_sq = _radius_m * _radius_m
	_interval_s = maxf(0.0, float(pin.get("check_interval_s", DEFAULT_INTERVAL_S)))
	_icon = str(pin.get("icon", DEFAULT_ICON))
	_message = str(pin.get("first_pin_message", DEFAULT_MESSAGE))


func _map() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("map") if game != null else null


func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


func _once_cleared(id: String) -> bool:
	if id.is_empty():
		return false
	var progression: RefCounted = _progression()
	return progression != null and bool(progression.call("has", id))
