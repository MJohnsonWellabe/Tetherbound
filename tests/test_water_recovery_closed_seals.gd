extends "res://tests/test_case.gd"

## F12 "no optional mount opens an uncleared gate", item F12#6. After a forced
## dismount, Water death/fade recovery (`water_player_death.gd::_respawn`)
## places the trainer at `recovery_position()`: newest Water bed, then the
## swim state's `safe_landing`, then First Shore. The safe landing is saved on
## the portable CHARACTER (player_pose.aquatic.safe_anchor), so a character
## who earned Salt Crown in one world must not be recovered onto Salt Crown in
## a world whose dock facts are missing. These checks drive the production
## recovery chooser against the baked heightfield and the production seals.

const DEATH := preload("res://scripts/world/water_player_death.gd")
const SEALS := preload("res://scripts/world/water_gate_seals.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const SWIM := preload("res://scripts/player/swim_controller.gd")

class Flags:
	extends RefCounted
	var ids: Dictionary = {}
	func has(id: String) -> bool:
		return ids.has(id)

class WorldState:
	extends RefCounted
	var flags := Flags.new()

class FakeGame:
	extends Node
	var world := WorldState.new()
	var placed_buildings: Array = []

class WorldFixture:
	extends Node3D
	var field := FIELD.new()
	var config: Dictionary = FIELD.load_config()
	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)

class PlayerFixture:
	extends CharacterBody3D
	var swim_controller: Node

var _world: WorldFixture
var _player: PlayerFixture
var _swim: Node
var _game: FakeGame
var _death: Node
var _home: Vector3
var _seals: Array[Dictionary]
var _rules: Dictionary


func before_each() -> void:
	_world = WorldFixture.new()
	_player = PlayerFixture.new()
	_swim = SWIM.new()
	_player.add_child(_swim)
	_player.swim_controller = _swim
	_game = FakeGame.new()
	_death = DEATH.new()
	# build()'s own world/player binding without the scene-tree downed seam.
	_death.bind_rules(_world)
	_death.set("_world", _world)
	_death.set("_player", _player)
	_home = Vector3(0, _world.ground_height_at(0, 162) + 1.0, 162)
	_death.set("_fallback_home", _home)
	_seals = SEALS.compile(_world.config)
	_rules = SEALS.load_rules()


func after_each() -> void:
	for node: Node in [_death, _player, _world, _game]:
		if is_instance_valid(node):
			node.free()


func _seal(id: String) -> Dictionary:
	for seal: Dictionary in _seals:
		if str(seal.id) == id:
			return seal
	return {}


func _open(seal: Dictionary) -> void:
	for flag: String in seal.required_flags:
		_game.world.flags.ids[flag] = true


func _on_or_behind(seal: Dictionary, at: Vector3) -> bool:
	return Vector2(at.x, at.z).distance_to(seal.centre) < SEALS.outer_radius(seal, _rules)


## A dry, validated recovery spot on this landform (centre or one of its
## authored anchors), or INF when the baked terrain offers none.
func _landing_on(seal: Dictionary) -> Vector3:
	var candidates: Array[Vector3] = [Vector3(seal.centre.x, 0.0, seal.centre.y)]
	for anchor: Dictionary in _world.config.anchors:
		if str(anchor.get("island_id", "")) == str(seal.island_id):
			var raw: Array = anchor.safe_position
			candidates.append(Vector3(float(raw[0]), 0.0, float(raw[2])))
	for at: Vector3 in candidates:
		if not _on_or_behind(seal, at):
			continue
		at.y = _world.ground_height_at(at.x, at.z)
		if _death.call("_safe_ground", at).is_finite():
			return at
	return Vector3.INF


func test_foreign_safe_landing_on_a_sealed_island_is_not_a_recovery_point() -> void:
	var crown := _seal("salt_crown")
	assert_false(crown.is_empty(), "Salt Crown is sealed behind its dock chain")
	var landing := _landing_on(crown)
	assert_true(landing.is_finite(), "Salt Crown offers a validated dry landing")
	# Earned in world A; this world holds every fact before Salt Crown's own.
	for flag: String in crown.required_flags.slice(0, -1):
		_game.world.flags.ids[flag] = true
	assert_true(SEALS.is_sealed(crown, _game.world.flags), "Salt Crown is closed in this world")
	_swim.state.reach_land(landing)
	var at: Vector3 = _death.recovery_position(_game, Vector3(150, 0, 2000))
	assert_false(_on_or_behind(crown, at), "recovery at %s stays off sealed Salt Crown" % at)
	assert_true(SEALS.closed_seal_at(_seals, _rules, at, _game.world.flags).is_empty(), "recovery is behind no closed seal")
	assert_true(at.distance_to(_home) < 0.01, "sealed landing falls through to First Shore")
	assert_true(_swim.state.has_safe_landing and _swim.state.safe_landing.is_equal_approx(landing),
		"the earned anchor is kept, not erased, while its dock is closed here")


func test_same_landing_is_used_once_this_world_opens_the_dock() -> void:
	var crown := _seal("salt_crown")
	var landing := _landing_on(crown)
	_open(crown)
	_swim.state.reach_land(landing)
	var at: Vector3 = _death.recovery_position(_game, Vector3.ZERO)
	assert_true(at.distance_to(landing + Vector3.UP) < 0.01, "open Salt Crown landing determines recovery: %s" % at)


func test_every_sealed_landform_landing_is_skipped_until_its_own_fact() -> void:
	var checked := 0
	for seal: Dictionary in _seals:
		var landing := _landing_on(seal)
		if not landing.is_finite():
			continue
		_game.world.flags.ids.clear()
		_swim.state.reach_land(landing)
		var closed: Vector3 = _death.recovery_position(_game, Vector3.ZERO)
		assert_true(SEALS.closed_seal_at(_seals, _rules, closed, _game.world.flags).is_empty(),
			"%s closed: recovery %s crosses no closed seal" % [seal.id, closed])
		assert_true(closed.distance_to(_home) < 0.01, "%s closed: First Shore" % seal.id)
		_open(seal)
		var opened: Vector3 = _death.recovery_position(_game, Vector3.ZERO)
		assert_true(opened.distance_to(landing + Vector3.UP) < 0.01, "%s open: its landing is used" % seal.id)
		checked += 1
	# Every island behind a dock has a dry landing; rest shoals may not.
	assert_true(checked >= 10, "every sealed island was swept (%d)" % checked)


func test_bed_behind_a_closed_seal_is_skipped_for_the_next_candidate() -> void:
	var crown := _seal("salt_crown")
	var landing := _landing_on(crown)
	var reed := _seal("reedhaven")
	var reed_landing := _landing_on(reed)
	assert_true(reed_landing.is_finite(), "Reedhaven offers a validated dry landing")
	_open(reed)
	_swim.state.reach_land(reed_landing)
	_game.placed_buildings.append({"id": "bedroll", "realm": "water",
		"position": [landing.x - 2.0, landing.y, landing.z - 2.0]})
	assert_true(_death.call("_safe_ground", landing).is_finite(), "the bed spot itself is dry, valid ground")
	var at: Vector3 = _death.recovery_position(_game, Vector3.ZERO)
	assert_true(at.distance_to(reed_landing + Vector3.UP) < 0.01, "sealed bed skipped for the open safe landing: %s" % at)
	_open(crown)
	at = _death.recovery_position(_game, Vector3.ZERO)
	assert_true(Vector2(at.x, at.z).distance_to(Vector2(landing.x, landing.z)) < 0.01, "open bed keeps its priority: %s" % at)


func test_closed_seal_at_covers_the_landform_and_its_race_band_only_while_closed() -> void:
	var crown := _seal("salt_crown")
	var flags := Flags.new()
	var centre := Vector3(crown.centre.x, 0, crown.centre.y)
	var rim := SEALS.outer_radius(crown, _rules)
	assert_eq(str(SEALS.closed_seal_at(_seals, _rules, centre, flags).get("id", "")), "salt_crown")
	assert_eq(str(SEALS.closed_seal_at(_seals, _rules, centre + Vector3(rim - 0.1, 0, 0), flags).get("id", "")), "salt_crown")
	assert_true(SEALS.closed_seal_at(_seals, _rules, centre + Vector3(0, 0, -(rim + 0.1)), flags).is_empty(), "outside the race band is open")
	assert_true(SEALS.closed_seal_at(_seals, _rules, Vector3(0, 0, 162), flags).is_empty(), "First Shore is never sealed")
	assert_true(SEALS.closed_seal_at(_seals, _rules, Vector3.INF, flags).is_empty(), "non-finite point is not a seal")
	for flag: String in crown.required_flags:
		flags.ids[flag] = true
	assert_true(SEALS.closed_seal_at(_seals, _rules, centre, flags).is_empty(), "opening the dock clears it")
