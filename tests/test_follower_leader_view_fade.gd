extends "res://tests/test_case.gd"

## F38 P2-062 (22 Oct): after a won fight the large ally parked beside the
## trainer near the lens and filled half the gameplay view. With the
## `follow_candidate` enabled, the follower also fades when the lens is close
## to its body or when it covers the trainer while following; never when it
## stands clear, and never for a fight's pilot covering its trainer.

const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const RUNS_IN_INITIALIZED_TREE := true

var _root: Node3D = null


class FightingManager extends Node:
	var _ally_body: Node = null
	func _enter_tree() -> void:
		add_to_group(&"foundation_combat_managers")
	func is_fighting() -> bool:
		return true


func after_each() -> void:
	FOLLOWER._follow_fade_cfg = null
	if is_instance_valid(_root):
		_root.free()
	_root = null


func _setup(ally_at: Vector3) -> Array:
	_root = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_root)
	var trainer := Node3D.new()
	_root.add_child(trainer)
	var follower: Node3D = FOLLOWER.new()
	_root.add_child(follower)
	follower.global_position = ally_at
	follower.leader = trainer
	# A 3 m wide, 3.8 m tall body standing on its origin.
	follower._camera_fade_bounds = AABB(Vector3(-1.5, 0.0, -1.5), Vector3(3.0, 3.8, 3.0))
	return [follower, trainer]


func test_disabled_candidate_never_fades() -> void:
	FOLLOWER._follow_fade_cfg = {"enabled": false, "near_margin_m": 1.5}
	var parts := _setup(Vector3(0, 0, 3))
	assert_false(parts[0]._blocks_leader_view(parts[0], Vector3(0, 1.5, 6.0)), "OFF keeps shipping behaviour")


func test_ally_between_lens_and_trainer_fades() -> void:
	FOLLOWER._follow_fade_cfg = {"enabled": true, "near_margin_m": 0.1, "leader_heights_m": [0.5, 1.0, 1.6]}
	var parts := _setup(Vector3(0, 0, 4))
	parts[0].set_following(true)
	assert_true(parts[0]._blocks_leader_view(parts[0], Vector3(0, 1.5, 9.0)), "a body on the camera-to-trainer line fades")


## Fights close-1025: in a fight the trainer stands behind its piloted
## creature; covering the trainer there must not ghost the pilot.
func test_piloted_body_in_a_fight_stays_solid() -> void:
	FOLLOWER._follow_fade_cfg = {"enabled": true, "near_margin_m": 0.1, "leader_heights_m": [0.5, 1.0, 1.6]}
	var parts := _setup(Vector3(0, 0, 4))
	parts[0].set_following(false)
	assert_false(parts[0]._blocks_leader_view(parts[0], Vector3(0, 1.5, 9.0)), "the fight's pilot covering its trainer stays solid")


func test_lens_close_to_the_body_fades() -> void:
	FOLLOWER._follow_fade_cfg = {"enabled": true, "near_margin_m": 1.5, "leader_heights_m": []}
	var parts := _setup(Vector3(3, 0, 4))
	assert_true(parts[0]._blocks_leader_view(parts[0], Vector3(3, 1.5, 6.2)), "a lens within the margin fades")


func test_ally_standing_clear_does_not_fade() -> void:
	FOLLOWER._follow_fade_cfg = {"enabled": true, "near_margin_m": 1.5, "leader_heights_m": [0.5, 1.0, 1.6]}
	var parts := _setup(Vector3(5, 0, -2))
	assert_false(parts[0]._blocks_leader_view(parts[0], Vector3(0, 1.5, 6.0)), "a body beside and ahead of the trainer stays solid")


## GPU J pass: a fight whose pilot was left in its following state still
## ghosted it. A running fight that pilots the body keeps it solid.
func test_following_body_piloted_by_a_running_fight_stays_solid() -> void:
	FOLLOWER._follow_fade_cfg = {"enabled": true, "near_margin_m": 0.1, "leader_heights_m": [0.5, 1.0, 1.6]}
	var parts := _setup(Vector3(0, 0, 4))
	parts[0].set_following(true)
	var manager := FightingManager.new()
	manager._ally_body = parts[0]
	_root.add_child(manager)
	assert_false(parts[0]._blocks_leader_view(parts[0], Vector3(0, 1.5, 9.0)), "a fight's pilot stays solid even while following")
