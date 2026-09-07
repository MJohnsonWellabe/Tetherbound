extends Node

## The same creature-control ownership handoff used by Cloudreach's finale.
## This adapter sends attacks to the Dynamo host; it never breaks a conduit
## locally or turns the trainer into a combatant.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var world: Node3D
var dynamo: Node3D
var director: Node
var manager: Node
var player: Node3D
var _body: CharacterBody3D

func mount(owner_world: Node3D, owner_dynamo: Node3D) -> void:
	world = owner_world
	dynamo = owner_dynamo
	director = world.get_node("EncounterDirector")
	manager = world.get_node("CombatManager")
	player = world.get_node("Player")
	set_process(not bool(world.get("simulation_only")))
	set_physics_process(not bool(world.get("simulation_only")))
	set_process_unhandled_input(not bool(world.get("simulation_only")))

func _process(_delta: float) -> void:
	if not is_instance_valid(world) or not is_instance_valid(dynamo):
		_release()
		return
	var ally: CharacterBody3D = director.call("ally_body")
	var creature: RefCounted = ally.get("instance") if is_instance_valid(ally) else null
	var pilot := str(dynamo.get("phase")) == "break_core" \
		and not bool(manager.call("is_fighting")) \
		and not bool(director.call("trainer_battle_active")) \
		and is_instance_valid(ally) and ally.visible \
		and creature != null and not bool(creature.get("fainted")) \
		and ally.global_position.distance_to(dynamo.global_position) <= 48.0
	if pilot and ally != _body:
		_release()
		_body = ally
		_body.call("set_following", false)
		player.call("set_locomotion_enabled", false)
		world.get_node("CameraRig").call("set_target", _body, {"distance":5.8, "height":1.4})
		world.get_node("InteractionArbiter").call("set_player", _body)
	elif not pilot and is_instance_valid(_body):
		_release()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_body) or INPUT_OWNER.current(get_tree()) != null:
		return
	if not bool(world.get_node("InteractionArbiter").call("enabled")):
		return
	var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis: Basis = world.get_node("CameraRig").call("planar_basis")
	_body.call("request_move", basis * Vector3(axis.x, 0, axis.y))

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_body) or INPUT_OWNER.current(get_tree()) != null:
		return
	var slot := "quick" if event.is_action_pressed("combat_quick") else ("charged" if event.is_action_pressed("combat_charged") else "")
	if slot.is_empty():
		return
	# Selecting the nearest conduit is an input convenience. Its identity,
	# reach, facing, timing and piloted body are revalidated on the host.
	var rules: RefCounted = dynamo.get("rules")
	var local := dynamo.to_local(_body.global_position)
	var closest := -1
	var distance := INF
	for i in int(rules.config.bank_count):
		var candidate: float = Vector2(local.x, local.z).distance_squared_to(rules.bank_position(i))
		if candidate < distance:
			distance = candidate
			closest = i
	if closest >= 0:
		dynamo.call("request_conduit_strike", closest, slot)
	get_viewport().set_input_as_handled()

func _release() -> void:
	if is_instance_valid(_body):
		_body.call("set_following", true)
	_body = null
	if is_instance_valid(world) and is_instance_valid(player):
		var arbiter := world.get_node_or_null("InteractionArbiter")
		var camera := world.get_node_or_null("CameraRig")
		if arbiter != null:
			arbiter.call("set_player", player)
		if camera != null:
			camera.call("set_target", player, {})
		player.call("set_locomotion_enabled", true)

func _exit_tree() -> void:
	_release()
