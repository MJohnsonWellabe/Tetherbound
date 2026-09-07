extends "res://tests/test_case.gd"
## Runs production begin and default staging against lightweight body adapters.
## Terrain, camera rendering, attacks and network transport are outside this test.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

class Fighter extends Node3D:
	signal strike_ready
	signal telegraph_started(seconds: float)
	var instance: RefCounted
	var arena: Node
	var engaged := false
	var target: Node3D
	var placement_calls := 0
	var velocity := Vector3.ZERO
	func face_towards(at: Vector3) -> void:
		rotation.y = atan2(at.x-global_position.x, at.z-global_position.z)
	func place_on_ground(at: Vector3) -> bool:
		placement_calls += 1
		global_position = at
		return true
	func set_engaged(value: bool, other: Node3D = null) -> void:
		engaged = value
		target = other
	func centre() -> Vector3:
		return global_position + Vector3.UP

class ThrowAdapter extends Node:
	var armed_target: Node3D
	func arm(_player: Node3D, enemy: Node3D, _camera: Node) -> void:
		armed_target = enemy
	func disarm() -> void:
		armed_target = null

class Manager extends "res://scripts/combat/combat_manager.gd":
	func _ready() -> void:
		set_physics_process(false)
		_throw = ThrowAdapter.new()
		add_child(_throw)
	func _open_arena() -> void:
		_arena = Node3D.new()
		add_child(_arena)
	func _arena_bounds(_at: Vector3) -> float:
		return -1.0
	func _take_camera() -> void:
		pass
	func _release_camera() -> void:
		pass
	func _stand_the_trainer_aside(_forward: Vector3) -> void:
		pass

var fixture: Node3D
var player: Fighter
var enemy: Fighter
var ally: Fighter
var manager: Manager
var old_arena: Node3D
var old_target: Fighter
var party: Array[RefCounted]

func _setup_fixture() -> void:
	fixture = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	player = Fighter.new()
	enemy = Fighter.new()
	ally = Fighter.new()
	old_target = Fighter.new()
	old_arena = Node3D.new()
	manager = Manager.new()
	for node in [player, enemy, ally, old_target, old_arena, manager]:
		fixture.add_child(node)
	player.position = Vector3(100, 3, 100)
	enemy.position = Vector3(128, 7, 110)
	enemy.rotation = Vector3(0, 1.1, 0)
	ally.position = Vector3(109, 4, 108)
	ally.visible = false
	enemy.instance = SPECIES.spawn("water_aquaryn")
	ally.instance = SPECIES.spawn("terrapup")
	enemy.arena = old_arena
	enemy.set_engaged(true, old_target)
	party = [ally.instance]

func _free_fixture() -> void:
	fixture.free()

func _case_realm_owned_begin_preserves_enemy_and_existing_authority_target() -> void:
	var pose := enemy.global_transform
	var ally_at := ally.global_position
	var player_at := player.global_position
	assert_true(manager.begin(player, enemy, ally, party, null, null, false, true))
	assert_true(manager.is_fighting())
	assert_eq(enemy.global_transform, pose, "Joining must not teleport or turn another participant's enemy")
	assert_eq(enemy.placement_calls, 0)
	assert_eq(enemy.arena, old_arena, "Presentation arena must not replace realm authority's arena")
	assert_eq(enemy.target, old_target, "Joining must not retarget the realm-owned enemy")
	assert_true(enemy.engaged)
	assert_eq(ally.global_position, ally_at)
	assert_eq(player.global_position, player_at)
	assert_true(ally.visible)
	assert_eq(ally.arena, null, "The local presentation ring cannot block the shared surface route")
	assert_eq(manager.throw_aim().armed_target, enemy)
	assert_eq(manager.active_creature(), ally.instance)

func _case_default_begin_still_stages_and_engages_an_ordinary_wild_fight() -> void:
	var before := enemy.global_position
	assert_true(manager.begin(player, enemy, ally, party))
	assert_true(manager.is_fighting())
	assert_eq(enemy.placement_calls, 1, "Default combat still stages its opponent")
	assert_eq(ally.placement_calls, 1)
	assert_ne(enemy.global_position, before)
	assert_eq(enemy.arena, manager._arena)
	assert_eq(ally.arena, manager._arena)
	assert_eq(enemy.target, ally)
	assert_true(enemy.engaged)
	assert_true(ally.visible)
	assert_eq(manager.throw_aim().armed_target, enemy)

func _case_repeated_begin_during_active_fight_cannot_restage_shared_enemy() -> void:
	assert_true(manager.begin(player, enemy, ally, party, null, null, false, true))
	var pose := enemy.global_transform
	var arena := manager._arena
	assert_false(manager.begin(player, enemy, ally, party), "An accidental ordinary begin must not replace an active shared fight")
	assert_eq(enemy.global_transform, pose)
	assert_eq(enemy.placement_calls, 0)
	assert_eq(manager._arena, arena)
	assert_eq(enemy.arena, old_arena)

func test_realm_owned_and_default_begin_in_initialized_tree() -> void:
	# run_tests runs in SceneTree._init before Engine.get_main_loop exists.
	# Use the existing isolated-child convention to exercise real global poses.
	var runner_path := "user://realm-owned-begin-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_combat_realm_owned_begin.gd").new()\n\tfor method in ["_case_realm_owned_begin_preserves_enemy_and_existing_authority_target", "_case_default_begin_still_stages_and_engages_an_ordinary_wild_fight", "_case_repeated_begin_during_active_fight_cannot_restage_shared_enemy"]:\n\t\ttest._setup_fixture()\n\t\ttest.call(method)\n\t\ttest._free_fixture()\n\tprint("REALM_BEGIN_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == 30 else 1)\n')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://realm-owned-begin-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("REALM_BEGIN_RESULT="):
			result = JSON.parse_string(line.trim_prefix("REALM_BEGIN_RESULT="))
	assert_eq(int(result.get("assertions", 0)), 30, "Child must complete all three begin paths")
	assert_eq(result.get("failures", ["missing result"]), [])
