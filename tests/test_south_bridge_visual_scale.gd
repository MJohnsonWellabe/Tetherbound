extends "res://tests/test_case.gd"

const BRIDGE := preload("res://scripts/world/south_bridge.gd")
const HERO := preload("res://assets/environment/team_tether/south_bridge_gate.glb")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")


## This detached fixture isolates provider capacity with declared radii. It
## has no render models; live admission still requires measurable rendered art.
class ProviderManager extends MANAGER:
	func _admission_render_radius(body: Node3D) -> float:
		return float(body.call("body_radius"))


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
	# The actual earned bridge failure staged a Mudsnout beyond the trench
	# rim. Test the provider's supported footprint, not live placement/physics.
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BRIDGE.TERRAIN_CONFIG))
	var crossing: Dictionary = {}
	for entry: Dictionary in config.get("crossings", []):
		if str(entry.get("id", "")) == "south_bridge":
			crossing = entry
			break
	assert_false(crossing.is_empty())
	var bridge := BRIDGE.new()
	bridge._crossing = crossing
	var carve: Dictionary = crossing.get("carve", {})
	var authored_centre: Array = carve.get("centre", [])
	bridge._centre = Vector2(float(authored_centre[0]), float(authored_centre[1]))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	bridge._across = Vector2(-axis.y, axis.x)
	var footprint := 1.464004
	assert_eq(bridge.combat_arena_bounds_for_fighters_at(2.424889, 1324.017, footprint), -1.0,
		"the original foe spot is in the carved rim, not arena floor")
	var cfg: Dictionary = BRIDGE.COMBAT_MATH.config().get("arena", {})
	var player_at := Vector2(8.006790, 1318.870)
	var forward := (Vector2(2.424889, 1324.017) - player_at).normalized()
	var deploy := float(cfg.get("deploy_offset", 2.6))
	var separation := float(cfg.get("separation", 5.0))
	var ally_at := player_at - forward * deploy
	var foe_at := player_at - forward * (deploy + separation)
	assert_true(bridge.combat_arena_bounds_for_fighters_at(ally_at.x, ally_at.y, footprint) > 0.0)
	assert_true(bridge.combat_arena_bounds_for_fighters_at(foe_at.x, foe_at.y, footprint) > 0.0,
		"the full authored reverse formation fits on the bank without shrinking its capsules")
	var centre := (ally_at + foe_at) * 0.5
	var available := bridge.combat_arena_bounds_for_fighters_at(centre.x, centre.y, footprint)
	var radius := minf(float(cfg.get("radius", 11.0)), available)
	var rim := float(carve.get("half_width", 3.6)) + float(carve.get("rim", 3.4))
	assert_true(radius > 0.0)
	assert_true(absf((centre - bridge._centre).dot(bridge._across))
		>= rim + radius + footprint - 0.001,
		"the offered radius plus the larger capsule stays outside the trench")
	# The manager's spatial query only needs detached parent/child identity;
	# it does not read global transforms, enter a tree or open an actual ring.
	var world := Node3D.new()
	world.add_child(bridge)
	var player := Node3D.new()
	world.add_child(player)
	var foe := CREATURE_BODY.new()
	world.add_child(foe)
	foe.set("_radius", 0.8)
	var ally := CREATURE_BODY.new()
	world.add_child(ally)
	ally.set("_radius", footprint)
	var manager := ProviderManager.new()
	world.add_child(manager)
	manager.set("_player", player)
	manager.set("_wild", foe)
	manager.set("_ally_body", ally)
	assert_almost_eq(float(manager.call("_arena_bounds", Vector3(centre.x, 0.0, centre.y))), available, 0.001,
		"the manager passes the larger actual fighter radius to the provider")
	var bank := bridge._centre - bridge._across * (rim + footprint * 0.5)
	assert_eq(bridge.combat_arena_bounds_for_fighters_at(bank.x, bank.y, footprint), 0.0,
		"a capsule that consumes all clearance must not gain a minimum arena radius")
	assert_eq(float(manager.call("_arena_bounds", Vector3(bank.x, 0.0, bank.y))), 0.0,
		"zero available room remains claimed instead of reopening the meadow")
	var tight := bridge._centre - bridge._across * (rim + footprint + 0.1)
	assert_almost_eq(bridge.combat_arena_bounds_for_fighters_at(tight.x, tight.y, footprint), 0.1, 0.001)
	assert_eq(bridge.combat_arena_bounds_for_fighters_at(8.0, 1330.0, footprint), -1.0)
	assert_eq(bridge.combat_arena_bounds_for_fighters_at(8.0, 7390.0, footprint), -1.0,
		"the bridge cannot claim an unrelated Meadows room")
	# The query uses the crossing's world axis, on either bank, rather than
	# a copied north/south world-Z condition.
	bridge._centre = Vector2(50.0, -80.0)
	bridge._across = Vector2.RIGHT.rotated(deg_to_rad(37.0))
	for side: float in [-1.0, 1.0]:
		var rotated := bridge._centre + bridge._across * side * (rim + footprint + 4.0)
		assert_almost_eq(bridge.combat_arena_bounds_for_fighters_at(rotated.x, rotated.y, footprint), 4.0, 0.001)
		assert_true(bridge.combat_arena_bounds_for_fighters_at(rotated.x, rotated.y, footprint * 2.0) < 4.0,
			"a larger evolved capsule consumes its actual additional room")
	world.free()


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
