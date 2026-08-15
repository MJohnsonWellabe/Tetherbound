extends Node3D

## GAME_DESIGN.md §22, Player Death: on death, everything carried drops into
## a satchel at the death location, the player respawns healed at home, and
## nothing else is lost — no XP, no level (there is no XP/level system yet,
## Phase 4, so there is nothing to lose there), and the party is never
## touched. Old death satchels never move once dropped and several can
## coexist — see death_satchel.gd, which this spawns fresh, once per death.
##
## Wired the same way camp.gd/world_perimeter.gd are: a small component
## `playground_world.gd` builds and hands the player node to, rather than
## logic living inside the world script itself.

const DEATH_SATCHEL := preload("res://scripts/world/death_satchel.gd")

const FADE_SECONDS := 1.2
const MAP_ICON := "death_satchel"

var _world: Node3D = null
var _player: CharacterBody3D = null
var _fallback_home: Vector3 = Vector3.ZERO
var _satchel_count: int = 0


## `world` is where satchels get parented — the same level everything else
## `_build_settlement()` builds into. `spawn_position` is the opening's own
## drop point (`playground_world.gd::_place_player()`), the respawn point
## until the player has built a camp.
func build(world: Node3D, player: CharacterBody3D, spawn_position: Vector3) -> void:
	_world = world
	_player = player
	_fallback_home = spawn_position
	if player.has_signal("died"):
		player.connect("died", _on_died)


func _on_died() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return

	var carried: Array = []
	var bag: RefCounted = game.get("inventory")
	if bag != null:
		carried = bag.call("drain")
	if not carried.is_empty():
		_drop_satchel(carried, _player.global_position, game)

	var respawn_at: Vector3 = resolve_home(game.get("placed_buildings"), _fallback_home)
	_fade_and_respawn(respawn_at)


func _drop_satchel(carried: Array, at: Vector3, game: Node) -> void:
	var satchel: Node3D = DEATH_SATCHEL.new()
	_satchel_count += 1
	satchel.name = "DeathSatchel_%d" % _satchel_count
	satchel.position = at
	_world.add_child(satchel)
	satchel.call("build", carried, game.get("items"))

	var map: RefCounted = game.get("map")
	if map != null:
		map.call("add_dynamic_marker", "death_satchel_%d" % _satchel_count, MAP_ICON, at)


## The last-placed camp's bed, or the world's own opening spawn point if none
## has been built yet — the camp/bed is already this project's one placed
## rest point (camp.gd), and §22 does not name a different "home." A static,
## dependency-free function so this is testable headless, no node required.
static func resolve_home(buildings: Variant, fallback: Vector3) -> Vector3:
	if not buildings is Array:
		return fallback
	var list: Array = buildings
	for i in range(list.size() - 1, -1, -1):
		if not list[i] is Dictionary:
			continue
		var entry: Dictionary = list[i]
		if str(entry.get("id", "")) != "camp":
			continue
		var pos: Array = entry.get("position", [])
		if pos.size() >= 3:
			return Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	return fallback


## The same fade-out/act/fade-in shape camp.gd's own rest uses, built here
## rather than shared: camp's version also advances the day and autosaves,
## neither of which belongs to a death.
func _fade_and_respawn(at: Vector3) -> void:
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", false)

	var layer := CanvasLayer.new()
	layer.layer = 15
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	_world.add_child(layer)

	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, FADE_SECONDS * 0.5)
	tween.tween_callback(func() -> void: _respawn(at))
	tween.tween_interval(0.4)
	tween.tween_property(rect, "color:a", 0.0, FADE_SECONDS * 0.5)
	tween.tween_callback(layer.queue_free)


func _respawn(at: Vector3) -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = at
	var vitals: RefCounted = _player.get("vitals")
	if vitals != null and vitals.has_method("rest"):
		vitals.call("rest")
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", true)
