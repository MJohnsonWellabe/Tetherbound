extends "res://tests/test_case.gd"
## F04#6: a trainer battle names its trainer as the fight's aftermath focus, and
## `_finish()` hands the released camera the trainer's spot instead of the spot
## the trainer's creature fell. A wild fight, or a round nobody named, keeps the
## creature's spot, and a focus never outlives the round it was set for.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

class Fighter extends Node3D:
	signal strike_ready
	signal telegraph_started(seconds: float)
	var instance: RefCounted
	var arena: Node
	var engaged := false
	var target: Node3D
	var velocity := Vector3.ZERO
	func face_towards(at: Vector3) -> void:
		rotation.y = atan2(at.x - global_position.x, at.z - global_position.z)
	func place_on_ground(at: Vector3) -> bool:
		global_position = at
		return true
	func set_engaged(value: bool, other: Node3D = null) -> void:
		engaged = value
		target = other
	func centre() -> Vector3:
		return global_position + Vector3.UP

class ThrowAdapter extends Node:
	var busy := false
	func arm(_player: Node3D, _enemy: Node3D, _camera: Node) -> void:
		pass
	func disarm() -> void:
		pass
	func is_busy() -> bool:
		return busy
	func is_aiming() -> bool:
		return busy

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
	var released_at: Variant = "never"
	func _release_camera(fought_at: Variant = null) -> void:
		released_at = fought_at
	func _stand_the_trainer_aside(_forward: Vector3) -> void:
		pass
	func _update_combat_camera_framing(_delta: float) -> void:
		pass
	func _update_ally_occlusion_fade(_delta: float) -> void:
		pass
	func _drive_player_creature() -> void:
		pass

var fixture: Node3D
var manager: Manager
var player: Fighter
var enemy: Fighter
var ally: Fighter
var trainer: Node3D

func _setup_fixture() -> void:
	fixture = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	player = Fighter.new()
	enemy = Fighter.new()
	ally = Fighter.new()
	trainer = Node3D.new()
	manager = Manager.new()
	for node in [player, enemy, ally, trainer, manager]:
		fixture.add_child(node)
	enemy.position = Vector3(10, 0, 0)
	trainer.position = Vector3(-4, 0, 6)
	enemy.instance = SPECIES.spawn("terrapup")
	ally.instance = SPECIES.spawn("terrapup")

func _free_fixture() -> void:
	fixture.free()

func _begin(owned: bool, realm_owned: bool = false) -> bool:
	var party: Array[RefCounted] = [ally.instance]
	return manager.begin(player, enemy, ally, party, null, null, owned, realm_owned)

func _case_a_trainer_round_releases_toward_the_trainer() -> void:
	manager.aftermath_focus = trainer
	assert_true(_begin(true), "a trainer's creature fight begins")
	manager._finish()
	assert_eq(manager.released_at, trainer.global_position,
		"the aftermath looks at the defeated trainer, not the fallen creature")
	assert_true(manager.aftermath_focus == null, "the focus is consumed by the round it was set for")

func _case_an_unnamed_trainer_round_keeps_the_creature_spot() -> void:
	assert_true(_begin(true), "a trainer's creature fight begins")
	manager._finish()
	assert_eq(manager.released_at, enemy.global_position,
		"with no focus named the aftermath keeps the opponent's spot")

func _case_a_wild_fight_drops_a_stale_focus() -> void:
	manager.aftermath_focus = trainer
	assert_true(_begin(false), "an ordinary wild fight begins")
	assert_true(manager.aftermath_focus == null, "a wild fight clears a focus nobody consumed")
	manager._finish()
	assert_eq(manager.released_at, enemy.global_position, "a wild aftermath looks at the wild spot")

func _case_a_freed_trainer_falls_back_to_the_creature() -> void:
	manager.aftermath_focus = trainer
	assert_true(_begin(true), "a trainer's creature fight begins")
	trainer.free()
	manager._finish()
	assert_eq(manager.released_at, enemy.global_position,
		"a focus that left the tree falls back to the opponent's spot")

func _case_a_hosted_realm_fight_drops_a_stale_focus() -> void:
	# The shared-host path (encounter_director.gd::_begin_shared_host_local)
	# begins realm-owned and not opponent-owned: never a trainer's aftermath.
	manager.aftermath_focus = trainer
	assert_true(_begin(false, true), "a hosted-realm fight begins")
	assert_true(manager.aftermath_focus == null, "a hosted-realm fight clears a focus nobody consumed")
	manager._finish()
	assert_eq(manager.released_at, enemy.global_position, "a hosted-realm aftermath looks at the opponent")

const CASES := ["_case_a_hosted_realm_fight_drops_a_stale_focus", "_case_a_trainer_round_releases_toward_the_trainer",
	"_case_an_unnamed_trainer_round_keeps_the_creature_spot",
	"_case_a_wild_fight_drops_a_stale_focus", "_case_a_freed_trainer_falls_back_to_the_creature"]

func test_aftermath_focus_in_an_initialized_tree() -> void:
	# Same isolated-child convention as test_combat_flee_buffer.gd: the fight
	# needs a live tree, which run_tests' SceneTree._init does not have yet.
	var runner_path := "user://combat-aftermath-focus-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_combat_aftermath_focus.gd").new()\n\tfor method in test.CASES:\n\t\ttest._setup_fixture()\n\t\ttest.call(method)\n\t\ttest._free_fixture()\n\tprint("AFTERMATH_FOCUS_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	runner.close()
	var output: Array = []
	var log_path := ProjectSettings.globalize_path("user://combat-aftermath-focus-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", ProjectSettings.globalize_path(runner_path), "--log-file", log_path], output, true)
	var text := "\n".join(output)
	var marker := text.find("AFTERMATH_FOCUS_RESULT=")
	assert_true(marker >= 0, "the child run reported a result: %s" % text.right(600))
	if marker < 0:
		return
	var parsed: Variant = JSON.parse_string(text.substr(marker + "AFTERMATH_FOCUS_RESULT=".length()).get_slice("\n", 0))
	var result: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	assert_eq(result.get("failures", ["unparsed"]), [], "every aftermath-focus case passes")
	assert_true(int(result.get("assertions", 0)) >= 12, "the cases asserted (%s)" % str(result.get("assertions")))
	assert_eq(code, 0, "the child exited cleanly")


## Only a Meadows trainer battle names a focus: the one write is the director's
## `_send_out_next_creature()`. Wild spawns, the shared-host realm path and the
## Stormwood/Tidewake directors and hosted trainer never set it, so their
## aftermath keeps the opponent's spot.
func test_only_the_meadows_trainer_round_names_an_aftermath_focus() -> void:
	var writers: Array[String] = []
	var dirs: Array[String] = ["res://scripts"]
	while not dirs.is_empty():
		var dir := dirs.pop_back() as String
		for sub in DirAccess.get_directories_at(dir):
			dirs.append(dir.path_join(sub))
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd") or file == "combat_manager.gd":
				continue
			var path := dir.path_join(file)
			var text := FileAccess.get_file_as_string(path)
			if text.contains("aftermath_focus"):
				writers.append(path)
	assert_eq(writers, ["res://scripts/combat/encounter_director.gd"],
		"only the Meadows encounter director names an aftermath focus")
	var director := FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	assert_eq(director.count('set("aftermath_focus"'), 1, "the director sets it in exactly one place")
	var at := director.find('set("aftermath_focus"')
	var owner_func := director.rfind("\nfunc ", at)
	assert_true(director.substr(owner_func, 40).begins_with("\nfunc _send_out_next_creature("),
		"the one write is inside _send_out_next_creature(), right before its fight starts")
	for other in ["res://scripts/combat/stormwood_encounter_director.gd",
			"res://scripts/combat/water_encounter_director.gd",
			"res://scripts/combat/stormwood_hosted_trainer.gd"]:
		assert_true(FileAccess.file_exists(other), "%s still exists to check" % other)
		assert_false(FileAccess.get_file_as_string(other).contains("aftermath_focus"),
			"%s never names an aftermath focus" % other)
