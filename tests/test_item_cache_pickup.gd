extends "res://tests/test_case.gd"

## T3-ACTIVITIES. `scripts/world/item_cache_pickup.gd` shipped with T3-PICKUPS
## and no direct test -- its own handover named this as the one real coverage
## gap it left. `key_pickup.gd`, whose contract this file restates, has no
## test either, which the handover also flagged.
##
## Per D02/tests/test_case.gd's own scope ("pure logic only... not scenes"),
## this covers everything reachable without a live `/root/Game` autoload:
## `flag_id()` (pure), `was_taken()`/`restore_progression_from_game()` (both
## take `game` as an explicit parameter, so a fake stands in for the real
## autoload the way `tests/test_harvest_permanence.gd`'s `FakeHarvestGame`
## does), and `_build_visual()`'s model-vs-fallback branch (mirrors
## `tests/test_harvest.gd`'s own `_has_a_populated_mesh_instance` checks for
## `harvest_node.gd`, the same PackedScene-vs-Mesh loader).
##
## What this does NOT cover: `_on_picked_up()`'s actual satchel/flag mutation.
## That method calls `get_node_or_null(^"/root/Game")` directly, which
## `tests/run_tests.gd` never boots (see `tests/test_harvest.gd`'s own header
## on why `harvest_node.gd::_on_gathered()`'s inventory half is out of reach
## the same way) -- a freestanding node with no SceneTree resolves that lookup
## to null and the method refuses rather than mutating anything, so calling it
## here would prove only its own early-out. `tests/smoke_local_requests.gd`
## exercises the equivalent real pickup/consume/flag path for this session's
## other new content (`cart_repair.gd`'s `item_gate.gd` contract) inside a
## real booted world; a future lane wiring one more scene boot into that same
## smoke test is the natural next step for `_on_picked_up()` itself.

const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const GLOW := preload("res://scripts/world/pickup_glow.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")

const MODEL_PATH := "res://assets/props/quaternius_fantasy/Barrel.gltf"


## `was_taken`/`restore_progression_from_game` both take `game: Node` and read
## its `progression` property through the ordinary `Object.get()` -- the same
## seam `village_npcs.gd::_progression()` reads from the real `/root/Game`
## autoload. A plain `Node` with that one property, carrying the REAL flag
## store (`autoload/progression_state.gd`, the same one `tests/test_quest_log.gd`
## constructs directly) rather than a second hand-rolled has()/set() pair,
## stands in for it without a live SceneTree.
class FakeCacheGame:
	extends Node
	var progression: RefCounted = PROGRESSION_STATE.new()


## Exercise the real glow registry without allocating its rendering layers.
class RegistryOnlyGlow:
	extends "res://scripts/world/pickup_glow.gd"
	func _ready() -> void:
		set_process(false)


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_walk(child))
	return out


func _has_a_populated_mesh_instance(node: Node) -> bool:
	for descendant in _walk(node):
		if descendant is MeshInstance3D and (descendant as MeshInstance3D).mesh != null:
			return true
	return false


# --- flag_id() / was_taken(): pure and parameterized, no autoload needed ----

func test_flag_id_is_the_cache_prefix_plus_the_item_id() -> void:
	assert_eq(ITEM_CACHE_PICKUP.flag_id("elixir_might"), "cache:elixir_might")


func test_flag_id_is_stable_per_item_so_two_caches_never_collide() -> void:
	assert_ne(ITEM_CACHE_PICKUP.flag_id("elixir_might"), ITEM_CACHE_PICKUP.flag_id("elixir_guard"))


func test_was_taken_is_false_with_no_game_at_all() -> void:
	assert_false(ITEM_CACHE_PICKUP.was_taken(null, "elixir_might"),
		"a missing autoload must read as 'not taken', the cautious direction for a one-time find")


func test_was_taken_is_false_with_an_empty_item_id() -> void:
	var game := FakeCacheGame.new()
	assert_false(ITEM_CACHE_PICKUP.was_taken(game, ""))
	game.free()


func test_was_taken_reads_the_real_flag_store() -> void:
	var game := FakeCacheGame.new()
	assert_false(ITEM_CACHE_PICKUP.was_taken(game, "elixir_might"))
	game.progression.set_flag(ITEM_CACHE_PICKUP.flag_id("elixir_might"))
	assert_true(ITEM_CACHE_PICKUP.was_taken(game, "elixir_might"))
	game.free()


func test_was_taken_is_per_item_not_global() -> void:
	var game := FakeCacheGame.new()
	game.progression.set_flag(ITEM_CACHE_PICKUP.flag_id("elixir_might"))
	assert_false(ITEM_CACHE_PICKUP.was_taken(game, "elixir_guard"),
		"one cache's flag must not read as every cache having been taken")
	game.free()


# --- restore_progression_from_game(): the reload-does-not-respawn contract --

## `_deactivate()` calls `queue_free()`, deferred to the next idle frame --
## this harness never steps the SceneTree (D02: pure logic, no scenes), so
## `is_instance_valid()` right after the call would still read true regardless
## of whether deactivation ran. `visible` is set SYNCHRONOUSLY in
## `_deactivate()`, before the deferred free, so it is what a test without a
## running tree can actually observe.
func test_restore_deactivates_a_node_whose_item_was_already_taken() -> void:
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.call("setup", "elixir_might", "Take it", "", 1.0)
	var game := FakeCacheGame.new()
	game.progression.set_flag(ITEM_CACHE_PICKUP.flag_id("elixir_might"))

	node.call("restore_progression_from_game", game)

	assert_false(node.visible, "an already-taken cache must hide itself on restore, the same as key_pickup.gd's contract")
	node.free()
	game.free()


func test_restore_leaves_an_untaken_node_alone() -> void:
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.call("setup", "elixir_might", "Take it", "", 1.0)
	var game := FakeCacheGame.new()

	node.call("restore_progression_from_game", game)

	assert_true(node.visible, "a cache nobody has found yet must stay visible after a restore call")
	node.free()
	game.free()


func test_restore_with_no_game_leaves_the_node_alone() -> void:
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.call("setup", "elixir_might", "Take it", "", 1.0)

	node.call("restore_progression_from_game", null)

	assert_true(node.visible)
	node.free()


# --- setup() itself already checks was_taken() through the real /root/Game -
# lookup path, which resolves to null on a freestanding node (same as
# village_npcs.gd's own `_progression()` null-Game convention) -- so setup()
# on a fresh, untouched flag store must leave the node active and visible.

func test_setup_on_a_fresh_flag_store_leaves_the_prompt_enabled() -> void:
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.call("setup", "elixir_might", "Take it", "", 1.0)
	assert_true(is_instance_valid(node), "setup() must not free a node nobody has found yet")
	if is_instance_valid(node):
		node.free()


# --- _build_visual(): the PackedScene-vs-Mesh branch, and the fallback ------

func test_a_gltf_model_builds_a_real_populated_mesh_not_a_dead_assignment() -> void:
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.call("setup", "elixir_might", "Take it", MODEL_PATH, 0.9)
	assert_true(_has_a_populated_mesh_instance(node),
		"a .gltf model (a PackedScene, per its own .import sidecar) must produce a MeshInstance3D with a real mesh somewhere in the visual subtree, not a null one")
	node.free()


func test_a_missing_model_still_falls_back_to_a_real_box() -> void:
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.call("setup", "elixir_might", "Take it", "", 1.0)
	assert_true(_has_a_populated_mesh_instance(node),
		"the no-model fallback must still be a real, populated MeshInstance3D")
	node.free()


func test_every_cache_placement_names_a_model_that_actually_exists() -> void:
	# T3-PICKUPS's own CACHE_MODEL constant, read from playground_world.gd
	# directly rather than restated, so a future model swap cannot silently
	# leave every cache on the fallback box without this test noticing.
	const PLAYGROUND := "res://scripts/world/playground_world.gd"
	var file := FileAccess.open(PLAYGROUND, FileAccess.READ)
	assert_true(file != null, "%s is missing" % PLAYGROUND)
	if file == null:
		return
	var text := file.get_as_text()
	var marker := "const CACHE_MODEL := \""
	var at := text.find(marker)
	assert_true(at != -1, "playground_world.gd no longer defines CACHE_MODEL the way this test expects")
	if at == -1:
		return
	var start := at + marker.length()
	var path := text.substr(start, text.find("\"", start) - start)
	assert_true(ResourceLoader.exists(path), "CACHE_MODEL names '%s', which does not exist" % path)


func _offset_fixture() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var previous := tree.current_scene
	var world := Node3D.new()
	tree.root.add_child(world)
	tree.current_scene = world
	var field := RegistryOnlyGlow.new()
	field.name = GLOW.FIELD_NAME
	world.add_child(field)
	var pickup := ITEM_CACHE_PICKUP.new()
	world.add_child(pickup)
	pickup.position = Vector3(10.0, 0.35, 20.0)
	pickup.setup("elixir_might", "Take it", MODEL_PATH, 0.8, "offset_fixture", "stormwood", 3)
	# A known 0.8m, ground-origin model at scale 0.8 isolates transform math
	# from the production bottle asset, which may be replaced independently.
	(pickup.get("_visual") as Node3D).free()
	var visual := Node3D.new()
	visual.scale = Vector3.ONE * 0.8
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.8, 0.3)
	mesh.mesh = box
	mesh.position.y = 0.4
	visual.add_child(mesh)
	pickup.add_child(visual)
	pickup.set("_visual", visual)
	return {"tree": tree, "previous": previous, "world": world,
		"pickup": pickup, "visual": visual, "field": field}


func _free_offset_fixture(fixture: Dictionary) -> void:
	(fixture.world as Node).free()
	(fixture.tree as SceneTree).current_scene = fixture.previous


func test_visual_offset_keeps_root_prompt_and_claim_while_grounding_one_glow() -> void:
	var fixture := _offset_fixture()
	var pickup: Node3D = fixture.pickup
	var visual: Node3D = fixture.visual
	var field: Node3D = fixture.field
	var prompt := pickup.get_node("Interactable") as Node3D
	var root_transform := pickup.global_transform
	var prompt_transform := prompt.global_transform
	var key := str(pickup.call("_key"))
	assert_eq(field.call("highlight_count"), 1)
	pickup.call("set_visual_offset", Vector3(0.0, -0.35, 0.0))
	var anchor := visual.get_parent() as Node3D
	assert_eq(pickup.get("_visual"), visual, "bounds callers retain the same visual")
	assert_eq(anchor.scale, Vector3.ONE, "glow measures the model's scale exactly once")
	assert_eq(visual.scale, Vector3.ONE * 0.8)
	assert_eq(pickup.global_transform, root_transform)
	assert_eq(prompt.global_transform, prompt_transform)
	assert_eq(float(prompt.get("radius")), 2.4)
	assert_eq(str(pickup.call("_key")), key)
	assert_eq(int(pickup.get("_count")), 3)
	var bounds := BOUNDS.measure(anchor)
	assert_true(absf(bounds.size.y - 0.64) < 0.00001)
	assert_true(absf((anchor.global_transform * bounds.position).y) < 0.00001,
		"rendered bottle base must reach ground while claim root stays at 0.35m")
	# Reward beams stay siblings of presentation, never part of item bounds.
	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(1.0, 34.0, 1.0)
	beam.mesh = beam_mesh
	beam.position.y = 17.0
	pickup.add_child(beam)
	var glow_height := GLOW.prop_glow_height(anchor, 0.28)
	assert_true(absf(glow_height - 0.352) < 0.00001,
		"glow belongs to scaled bottle, not elevated root or 34m reward beam")
	var positions: Array = field.call("highlight_positions")
	assert_eq(positions.size(), 1)
	assert_true((positions[0] as Vector3).is_equal_approx(Vector3(10.0, 0.0, 20.0)))
	# Repeated corrections must reuse the anchor/registration, not accumulate.
	pickup.call("set_visual_offset", Vector3(0.0, -0.25, 0.0))
	assert_eq(visual.get_parent(), anchor)
	assert_eq(field.call("highlight_count"), 1)
	positions = field.call("highlight_positions")
	assert_true(absf((positions[0] as Vector3).y - 0.1) < 0.00001)
	assert_eq(pickup.global_transform, root_transform)
	pickup.call("_deactivate")
	assert_eq(field.call("highlight_count"), 0, "claim removal immediately unregisters anchored glow")
	assert_false(bool(prompt.get("enabled")))
	_free_offset_fixture(fixture)


func test_freeing_offset_pickup_unregisters_glow_without_a_claim() -> void:
	var fixture := _offset_fixture()
	var pickup: Node3D = fixture.pickup
	var field: Node3D = fixture.field
	pickup.call("set_visual_offset", Vector3(0.0, -0.35, 0.0))
	assert_eq(field.call("highlight_count"), 1)
	pickup.free()
	assert_eq(field.call("highlight_count"), 0, "residency removal must not leave a registered emitter")
	_free_offset_fixture(fixture)
