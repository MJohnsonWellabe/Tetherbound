extends Node

## Host observes the lesson; the existing world ledger publishes its result.
## This node's path also exists in a Water simulation shell for remote visitors.
const LESSON := preload("res://scripts/world/water_lesson.gd")
const LEDGER_RPC := preload("res://scripts/net/ledger_rpc.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
var world: Node3D
var npc_bodies: Dictionary = {}
var _game: Node
var _lesson: RefCounted
var _ledger: Node


func build(owner_world: Node3D) -> void:
	world = owner_world
	_game = get_node("/root/Game")
	_lesson = LESSON.new(world.config.swim_lesson)
	_ledger = LEDGER_RPC.attach(_game)
	var cast := NPCS.new()
	cast.name = "WaterNPCs"
	world.add_child(cast)
	npc_bodies = cast.build(world)
	cast.guarded_event_requested.connect(_on_dialogue_request)
	if world.simulation_only:
		cast.visible = false
		for body: Node3D in npc_bodies.values():
			body.prompt_node().enabled = false
	elif str(_game.current_realm) == "water":
		apply_personal_event(_game.local.flags, "arrival", str(_game.current_realm))


static func apply_personal_event(flags: RefCounted, event: String, realm: String) -> bool:
	if flags == null or realm != "water":
		return false
	if event == "arrival":
		flags.set_flag("water_chapter_started", true)
		return true
	if event == "saddle_taught" and flags.has("water_swim_stone_earned"):
		flags.set_flag("water_swim_saddle_recipe_learned", true)
		return true
	return false


func _on_dialogue_request(event: String, npc_id: String, peer: int) -> void:
	if peer != int(_game.session.local_peer_id()) or world.simulation_only or str(_game.current_realm) != "water":
		return
	var body: Node3D = npc_bodies.get(npc_id)
	var player := world.local_rig() as Node3D
	if body == null or player == null or body.global_position.distance_to(player.global_position) > 5.0:
		return
	match event:
		"water:water_swim_lesson_briefed":
			_game.local.flags.set_flag("water_swim_lesson_briefed", true)
		"water:water_swim_saddle_recipe_taught":
			if apply_personal_event(_game.local.flags, "saddle_taught", "water"):
				_game.push_world_message("Swim Saddle recipe learned. Craft it at a workbench.")


func _physics_process(_delta: float) -> void:
	if _game == null or not bool(_game.call("is_host")) or not world.shell_build_complete():
		return
	var flag := str(world.config.swim_lesson.completion_flag)
	if _game.world.flags.has(flag):
		return
	var completed := false
	if not world.simulation_only and str(_game.current_realm) == "water":
		var player := world.local_rig() as CharacterBody3D
		if player != null and player.swim_controller != null:
			completed = _lesson.observe(int(_game.session.local_peer_id()), player.global_position,
				int(player.swim_controller.state.mode))
	for proxy: Node in get_tree().get_nodes_in_group("remote_trainer"):
		if str(proxy.get("net_realm")) != "water" or proxy.is_multiplayer_authority():
			continue
		var packet: Dictionary = proxy.get("net_aquatic")
		if not packet.is_empty():
			completed = _lesson.observe(proxy.get_multiplayer_authority(), proxy.global_position,
				int(packet.get("mode", -1))) or completed
	if completed:
		_ledger.submit({"kind": "set_world_flag", "realm": "water", "id": flag, "value": true})
		_game.push_world_message("Swim lesson complete. The First Shore channel is open.")
