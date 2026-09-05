extends SceneTree

## A bounded live fixture using the production player, interaction arbiter,
## Warden payout, shrine, gate and disk save. It does not claim to play the
## Warden combat or walk the Meadows. The production world crossing/return is
## covered separately by smoke_cloudreach_transition.gd.
const SHRINE := preload("res://scripts/world/realm_heart_shrine.gd")
const GATE := preload("res://scripts/world/realm_gate.gd")
const PLAYER := preload("res://scripts/player/player_controller.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const SAVE_DIR := "user://meadows_realm_handoff_smoke/"

class RewardDirector extends "res://scripts/combat/encounter_director.gd":
	# Suppress unrelated wild-world construction, retaining production reward
	# and progression methods intact.
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("save_system", SAVE.new(SAVE_DIR))
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var floor_body := StaticBody3D.new()
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(50, 1, 12)
	floor_collision.shape = floor_shape
	floor_body.position = Vector3(10, -0.5, 0)
	floor_body.add_child(floor_collision)
	world.add_child(floor_body)
	var player: CharacterBody3D = PLAYER.new()
	player.name = "Player"
	var body_collision := CollisionShape3D.new()
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = 0.4
	body_shape.height = 1.8
	body_collision.shape = body_shape
	body_collision.position.y = 0.9
	player.add_child(body_collision)
	var model := Node3D.new()
	model.name = "Model"
	player.add_child(model)
	world.add_child(player)
	var arbiter: Node = ARBITER.new()
	world.add_child(arbiter)
	arbiter.call("set_player", player)
	var shrine: Node3D = SHRINE.new()
	world.add_child(shrine)
	var gate: Node3D = GATE.new()
	gate.position.x = 20.0
	world.add_child(gate)
	var director := RewardDirector.new()
	world.add_child(director)
	await _settle()
	var progression: RefCounted = game.get("progression")
	var hearts: RefCounted = game.get("realm_hearts")
	var vitals: RefCounted = player.get("vitals")
	var baseline: float = vitals.get("max_stamina")
	player.position = Vector3(20, 0, 2)
	await _press_interact()
	_expect(not gate.call("try_unlock", game), "no-key gate accepted unlock")
	_expect(not game.call("can_enter_realm", "cloudreach"), "router accepted a missing key")
	_expect(not gate.call("try_enter", game), "locked gate accepted entry")
	_expect(not progression.call("has", "realm_gate_cloudreach_unlocked"), "input opened the no-key gate")

	var warden: Dictionary = TRAINERS.trainer("warden_aldis")
	director.call("_record_trainer_defeat", warden)
	var revision: int = progression.get("revision")
	var inventory: RefCounted = game.get("inventory")
	var coins: int = inventory.call("count", "coin")
	director.call("_record_trainer_defeat", warden)
	_expect(int(progression.get("revision")) == revision, "Warden entitlement grant repeated")
	_expect(int(inventory.call("count", "coin")) == coins, "Warden payout repeated")
	await _settle()
	_expect(bool(shrine.get_node(^"Interactable").get("actionable")), "earned shrine stayed unresponsive without reload")
	var shrine_copy: String = shrine.get_node(^"Interactable").get("label")
	_expect(shrine_copy.contains("maximum stamina") and shrine_copy.contains("Only one Heart power"), "persistent shrine prompt omitted the power or one-active rule")
	_expect(bool(gate.get_node(^"Interactable").get("actionable")), "rewarded gate stayed unresponsive without reload")
	_expect(bool(hearts.call("is_earned", "meadows", progression)), "production Warden did not grant Heart")
	_expect(bool(game.call("can_enter_realm", "cloudreach")), "production Warden did not grant realm key")
	await _press_interact()
	_expect(bool(progression.call("has", "realm_gate_cloudreach_unlocked")), "rewarded gate input failed without reload")
	await _settle()
	_expect(bool((gate.get("_barrier_shape") as CollisionShape3D).disabled), "unlocked gate collider stayed closed")

	player.position = Vector3(0, 0, 2)
	await _press_interact()
	_expect(bool(hearts.call("is_placed", "meadows", progression)), "shrine input did not place Heart")
	_expect(str(hearts.call("active_id")) == "", "placement silently equipped power")
	var message: String = game.call("take_pending_world_message")
	_expect(message.contains("maximum stamina") and message.contains("Only one Heart power"), "shrine omitted power/selection explanation")
	await _press_interact()
	_expect(str(hearts.call("active_id")) == "meadows", "shrine input did not equip Heart")
	_expect(is_equal_approx(float(vitals.get("max_stamina")), baseline * 2.0), "live player capacity did not double")
	_expect(bool(game.call("save_game", 1)), "active Heart save failed")
	await _press_interact()
	_expect(str(hearts.call("active_id")) == "", "shrine input did not release power")
	_expect(is_equal_approx(float(vitals.get("max_stamina")), baseline), "live player capacity did not return to baseline")
	_expect(bool(game.call("load_game", 1)), "active Heart reload failed")
	await _settle()
	_expect(str(hearts.call("active_id")) == "meadows", "saved Heart choice was lost")
	_expect(is_equal_approx(float(vitals.get("max_stamina")), baseline * 2.0), "loaded power did not update live stamina")
	# Exercise a shared selection change originating outside this shrine.
	hearts.call("clear_active")
	await _settle()
	_expect(str(shrine.get_node(^"Interactable").get("label")).begins_with("Activate"), "shrine ignored external Heart revision")
	_cleanup()
	if failures.is_empty():
		print("MEADOWS REALM HANDOFF OK: production reward idempotency, live input, stamina, no-reload gate and disk persistence")
	else:
		for failure: String in failures:
			push_error("MEADOWS REALM HANDOFF: " + failure)
	quit(0 if failures.is_empty() else 1)


func _settle() -> void:
	await process_frame
	await process_frame
	await physics_frame
	await process_frame


func _press_interact() -> void:
	await _settle()
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	await physics_frame
	await process_frame
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	await _settle()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _cleanup() -> void:
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	for slot in SAVE.SLOT_COUNT:
		var file := "slot_%d.json" % slot
		if dir.file_exists(file):
			dir.remove(file)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_DIR))
