extends "res://tests/test_case.gd"

## Resource publication regression, not a floor-contact or ENet smoke.
## Inject dry-land resource recovery, then call the actual driver and receiver.
const DRIVER := preload("res://scripts/world/water_mounted_swim.gd")
const STATE := preload("res://scripts/player/swim_state.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")

class HumanState extends Node:
	var state = STATE.new()

class Player extends CharacterBody3D:
	var swim_controller: Node

class DryWorld extends Node3D:
	var player: CharacterBody3D
	func local_rig() -> CharacterBody3D:
		return player
	func water_depth_at(_position: Vector3) -> float:
		return 0.0
	func ground_height_at(_x: float, _z: float) -> float:
		return 2.0

class Riding extends Node:
	func is_mounted() -> bool:
		return false

class Director extends Node:
	func trainer_battle_active() -> bool:
		return false

class Combat extends Node:
	func is_fighting() -> bool:
		return false

var fixture: Node
var driver: Node
var actor: CharacterBody3D
var creature: RefCounted
var remote: RefCounted

func _setup_fixture() -> void:
	fixture = Node.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	var world := DryWorld.new()
	fixture.add_child(world)
	var combat := Combat.new()
	combat.name = "CombatManager"
	world.add_child(combat)
	var player := Player.new()
	world.add_child(player)
	player.swim_controller = HumanState.new()
	player.add_child(player.swim_controller)
	world.player = player
	var riding := Riding.new()
	fixture.add_child(riding)
	var director := Director.new()
	fixture.add_child(director)
	actor = CharacterBody3D.new()
	fixture.add_child(actor)
	creature = INSTANCE.new()
	creature.swim_stamina_fraction = 0.2
	driver = DRIVER.new()
	fixture.add_child(driver)
	driver.set_physics_process(false)
	driver.setup(world, riding, director)
	driver._instance = creature
	driver._species = {"stamina_capacity": 200.0}
	driver.state.owner_peer_id = driver.multiplayer.get_unique_id()
	driver.state.enter_water(true, 0.0)
	remote = STATE.new()
	remote.owner_peer_id = driver.multiplayer.get_unique_id()

func _free_fixture() -> void:
	fixture.free()

func _receive() -> bool:
	return remote.apply_remote_snapshot(actor.get_meta("water_aquatic"), remote.owner_peer_id)

func _case_dry_recovery_publishes_each_new_fraction_after_landing() -> void:
	driver._apply_buoyancy(actor, 0.1)
	assert_true(_receive(), "initial landing snapshot")
	assert_eq(remote.mode, STATE.Mode.LAND)
	assert_almost_eq(remote.stamina_fraction, 0.2)
	var previous_revision: int = remote.revision
	for recovered: float in [0.26, 0.32, 0.5, 1.0]:
		# The recovery integrator owns this resource. This fixture isolates its
		# handoff to the dry-branch publisher from actual physics floor contact.
		creature.swim_stamina_fraction = recovered
		driver._apply_buoyancy(actor, 0.1)
		assert_true(driver.state.revision > previous_revision, "resource change is a new packet")
		assert_true(_receive(), "remote accepts recovery after its landing packet")
		assert_almost_eq(remote.stamina_fraction, recovered)
		assert_eq(remote.mode, STATE.Mode.LAND)
		previous_revision = remote.revision

func _case_unchanged_dry_resource_does_not_churn_revision_or_replay_old_resource() -> void:
	driver._apply_buoyancy(actor, 0.1)
	assert_true(_receive())
	var landing: Dictionary = actor.get_meta("water_aquatic").duplicate(true)
	creature.swim_stamina_fraction = 0.8
	driver._apply_buoyancy(actor, 0.1)
	assert_true(_receive())
	var recovered_revision: int = remote.revision
	driver._apply_buoyancy(actor, 0.1)
	assert_eq(driver.state.revision, recovered_revision)
	assert_false(_receive(), "duplicate revision stays rejected")
	assert_false(remote.apply_remote_snapshot(landing, remote.owner_peer_id), "late landing cannot rewind recovery")
	assert_almost_eq(remote.stamina_fraction, 0.8)



func test_actual_driver_recovery_packets_reach_remote_state() -> void:
	# run_tests invokes cases during SceneTree._init, before any node can
	# acquire multiplayer. A tiny initialized child tree supplies that native
	# API; it creates only the fixture nodes above, never a game-world scene.
	var runner_path := "user://water_mounted_replication_runner.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_water_mounted_replication.gd").new()\n\tfor method in ["_case_dry_recovery_publishes_each_new_fraction_after_landing", "_case_unchanged_dry_resource_does_not_churn_revision_or_replay_old_resource"]:\n\t\ttest._setup_fixture()\n\t\ttest.call(method)\n\t\ttest._free_fixture()\n\tprint("WATER_MOUNT_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == 25 else 1)\n')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://water-mounted-replication-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("WATER_MOUNT_RESULT="):
			result = JSON.parse_string(line.trim_prefix("WATER_MOUNT_RESULT="))
	assert_eq(int(result.get("assertions", 0)), 25, "child must finish all actual-driver assertions")
	assert_eq(result.get("failures", ["missing result"]), [])
