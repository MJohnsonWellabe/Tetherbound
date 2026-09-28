extends "res://tests/test_case.gd"
## F14 C3 (#356 grant 5859072534): a trainer round won while that trainer
## still has a creature to send holds the fight camera and the player's
## creature through the send-out beat (`combat_manager.hold_round`), so the HUD
## keeps presenting the fight instead of flashing the exploration layer. A wild
## fight, the trainer's last creature and a lost round release as before.
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

func _case_a_held_trainer_round_keeps_the_fight_presented() -> void:
	manager.hold_round = true
	assert_true(_begin(true), "a trainer's creature fight begins")
	manager._outcome = "won"
	manager._finish()
	assert_eq(str(manager.released_at), "never", "the camera is not handed back to exploration")
	assert_false(manager.is_fighting(), "the round itself is over")
	assert_true(manager.presenting_fight(), "the HUD still presents the fight through the beat")
	assert_true(ally.visible, "the player's creature stays on the field")
	assert_false(manager.hold_round, "the request is consumed by the round it was set for")
	assert_true(_begin(true), "the next creature's round begins")
	assert_eq(manager.presenting_fight(), manager.is_fighting(), "a new round ends the held beat")

func _case_a_held_beat_with_nobody_left_releases() -> void:
	manager.hold_round = true
	assert_true(_begin(true), "a trainer's creature fight begins")
	manager._outcome = "won"
	manager._finish()
	manager.end_round_hold()
	assert_eq(manager.released_at, null, "ending the beat hands the camera back")
	assert_false(manager.presenting_fight(), "the HUD returns to exploration")
	assert_false(ally.visible, "the creature leaves the field as after any fight")

func _case_a_wild_fight_never_holds() -> void:
	manager.hold_round = true
	assert_true(_begin(false), "an ordinary wild fight begins")
	manager._outcome = "won"
	manager._finish()
	assert_eq(manager.released_at, enemy.global_position, "a wild fight releases toward the wild spot")
	assert_false(manager.presenting_fight(), "a wild fight never holds the HUD")

func _case_the_last_creature_releases() -> void:
	assert_true(_begin(true), "a trainer's last creature fight begins")
	manager._outcome = "won"
	manager._finish()
	assert_eq(manager.released_at, enemy.global_position, "the last round releases as before")
	assert_false(manager.presenting_fight(), "and the HUD returns to exploration")

func _case_a_lost_round_releases() -> void:
	manager.hold_round = true
	assert_true(_begin(true), "a trainer's creature fight begins")
	manager._outcome = "lost"
	manager._finish()
	assert_eq(manager.released_at, enemy.global_position, "a lost round releases as before")
	assert_false(manager.presenting_fight(), "a lost round never holds the HUD")

const CASES := ["_case_a_held_trainer_round_keeps_the_fight_presented", "_case_a_held_beat_with_nobody_left_releases",
	"_case_a_wild_fight_never_holds", "_case_the_last_creature_releases", "_case_a_lost_round_releases"]

func test_send_out_hold_in_an_initialized_tree() -> void:
	# Same isolated-child convention as test_combat_aftermath_focus.gd.
	var runner_path := "user://combat-send-out-hold-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_combat_send_out_hold.gd").new()\n\tfor method in test.CASES:\n\t\ttest._setup_fixture()\n\t\ttest.call(method)\n\t\ttest._free_fixture()\n\tprint("SEND_OUT_HOLD_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	runner.close()
	var output: Array = []
	var log_path := ProjectSettings.globalize_path("user://combat-send-out-hold-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", ProjectSettings.globalize_path(runner_path), "--log-file", log_path], output, true)
	var text := "\n".join(output)
	var marker := text.find("SEND_OUT_HOLD_RESULT=")
	assert_true(marker >= 0, "the child run reported a result: %s" % text.right(600))
	if marker < 0:
		return
	var parsed: Variant = JSON.parse_string(text.substr(marker + "SEND_OUT_HOLD_RESULT=".length()).get_slice("\n", 0))
	var result: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	assert_eq(result.get("failures", ["unparsed"]), [], "every send-out hold case passes")
	assert_true(int(result.get("assertions", 0)) >= 20, "the cases asserted (%s)" % str(result.get("assertions")))
	assert_eq(code, 0, "the child exited cleanly")


## The director sets the request only on the trainer send-out path, from the
## queue it just popped, and ends any held beat when the battle ends.
func test_the_director_sets_the_hold_only_for_a_trainer_with_more_to_send() -> void:
	var director := FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	var at := director.find('_manager.set("hold_round", not _trainer_queue.is_empty())')
	assert_true(at >= 0, "the send-out path sets hold_round from the remaining queue")
	var owner_func := director.rfind("\nfunc ", at)
	assert_true(director.substr(owner_func, 40).begins_with("\nfunc _send_out_next_creature("),
		"inside _send_out_next_creature(), after its pop")
	var finish := director.find("\nfunc _finish_trainer_battle(")
	var next := director.find("\nfunc ", finish + 1)
	assert_true(director.substr(finish, next - finish).contains('_manager.call("end_round_hold")'),
		"ending the battle ends any held beat")
