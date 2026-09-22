extends "res://tests/test_case.gd"

const BRIDGE := preload("res://scripts/world/south_bridge.gd")
const HERO := preload("res://assets/environment/team_tether/south_bridge_gate.glb")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")


class FakeProgression extends RefCounted:
	var revision := 0
	var defeated := false
	func has(id: String) -> bool:
		return defeated and id == "defeated_south_bridge_grunt"


class FakeInventory extends RefCounted:
	var revision := 0
	var keys := 0
	func count(id: String) -> int:
		return keys if id == "south_bridge_key" else 0


class AutoOpenBridge extends BRIDGE:
	var attempts := 0
	var nearby := true
	var test_inventory: FakeInventory = null
	func _on_tried() -> void:
		attempts += 1
		if test_inventory != null and test_inventory.keys > 0:
			test_inventory.keys -= 1
			test_inventory.revision += 1
	func _auto_open_player_in_range() -> bool:
		return nearby


func test_checkpoint_gate_is_a_fortified_chapter_threshold_at_trainer_scale() -> void:
	var model := HERO.instantiate() as Node3D
	assert_true(model != null, "the approved South Bridge hero gate must load")
	if model == null:
		return
	var raw := BOUNDS.measure(model)
	assert_true(raw.size.y > 0.0, "the approved gate has measurable geometry")
	var fitted_width := raw.size.x * BRIDGE.HERO_GATE_HEIGHT / raw.size.y
	assert_almost_eq(BRIDGE.HERO_GATE_HEIGHT, 4.4, 0.001)
	assert_true(BRIDGE.HERO_GATE_HEIGHT / 1.8 >= 2.4,
		"the chapter gate must stand at least 2.4 trainer-heights")
	assert_true(fitted_width >= 9.0,
		"the fortified gate must span the bridge and its gully shoulders")
	model.free()


func test_auto_open_retries_when_the_delayed_key_arrives() -> void:
	var fixture := _auto_open_fixture(true)
	var bridge := fixture.bridge as AutoOpenBridge
	var progression := fixture.progression as FakeProgression
	var inventory := fixture.inventory as FakeInventory
	progression.defeated = true
	progression.revision += 1
	bridge._process(0.0)
	assert_eq(bridge.attempts, 0, "defeat without its delayed reward key stays shut")
	inventory.keys = 2
	inventory.revision += 1
	bridge._process(0.0)
	assert_eq(bridge.attempts, 1, "key delivery retries through the normal gate interaction")
	bridge._process(0.0)
	assert_eq(bridge.attempts, 1, "unchanged state does not duplicate the request")
	inventory.revision += 1
	bridge._process(0.0)
	assert_eq(bridge.attempts, 1, "another inventory change cannot spend a second key while pending")
	assert_eq(inventory.keys, 1, "only one key was spent")
	bridge.free()


func test_auto_open_retries_when_the_qualified_player_approaches() -> void:
	var fixture := _auto_open_fixture(false)
	var bridge := fixture.bridge as AutoOpenBridge
	var progression := fixture.progression as FakeProgression
	var inventory := fixture.inventory as FakeInventory
	progression.defeated = true
	progression.revision += 1
	inventory.keys = 1
	inventory.revision += 1
	bridge._process(0.0)
	assert_eq(bridge.attempts, 0, "earned key does not open a distant bridge")
	bridge.nearby = true
	bridge._process(0.0)
	assert_eq(bridge.attempts, 1, "entering range uses the inherited interaction path")
	bridge.free()


func _auto_open_fixture(nearby: bool) -> Dictionary:
	var bridge := AutoOpenBridge.new()
	bridge.nearby = nearby
	var progression := FakeProgression.new()
	var inventory := FakeInventory.new()
	bridge.test_inventory = inventory
	bridge._progression_cache = progression
	bridge._inventory_cache = inventory
	return {"bridge": bridge,
		"progression": progression, "inventory": inventory}
