extends Node

## Host observes the lesson; the existing world ledger publishes its result.
## This node's path also exists in a Water simulation shell for remote visitors.
const LESSON := preload("res://scripts/world/water_lesson.gd")
const LEDGER_RPC := preload("res://scripts/net/ledger_rpc.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const NAMED := preload("res://scripts/world/water_named_resolution.gd")
const RECIPE_MIGRATION := preload("res://scripts/save/water_recipe_migration.gd")
## F13 local chains: a guarded conversation's `water:local_step:<step id>`
## asks WaterLocalChains to submit that host-validated step.
const LOCAL_STEP_EVENT := "water:local_step:"
var world: Node3D
var npc_bodies: Dictionary = {}
var _game: Node
var _lesson: RefCounted
var _ledger: Node
var _named: RefCounted
var _dock_prompt: Node3D
var _dock_pending: Dictionary = {}
var _dock_retry_seconds := 0.0
var _dock_afterword: Dictionary = {}


func build(owner_world: Node3D) -> void:
	world = owner_world
	_game = get_node("/root/Game")
	_lesson = LESSON.new(world.config.swim_lesson)
	_ledger = LEDGER_RPC.attach(_game)
	_named = NAMED.new()
	_named.baseline(_game.world.flags)
	if _ledger != null and not _ledger.delta_applied.is_connected(_named.note_delta):
		_ledger.delta_applied.connect(_named.note_delta)
	var cast := NPCS.new()
	cast.name = "WaterNPCs"
	world.add_child(cast)
	npc_bodies = cast.build(world)
	cast.guarded_event_requested.connect(_on_dialogue_request)
	cast.authored_conversation_finished.connect(_on_dock_afterword)
	var mara: Node3D = npc_bodies.get("water_mara")
	if mara != null and not world.simulation_only:
		_dock_prompt = preload("res://scripts/world/interactable.gd").new()
		_dock_prompt.name = "CivilianDeparture"
		mara.add_child(_dock_prompt)
		_dock_prompt.position = Vector3(1.5, 0.0, 0.0)
		# This is a dock action beside Mara, not a point on her turning body.
		# Keep its authored placement while she faces the approaching player.
		var dock_anchor := _dock_prompt.global_transform
		_dock_prompt.set_as_top_level(true)
		_dock_prompt.global_transform = dock_anchor
		_dock_prompt.call("configure", "Confirm civilian departures", float(mara.prompt_node().radius), false)
		_dock_prompt.connect("activated", request_dock_conclusion)
	# Edda's Guardian offer only for a character that may still answer.
	preload("res://scripts/world/water_guardian_reward.gd").gate_edda_offer(cast, npc_bodies, _game)
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
		# F13#2: a character that started the chapter before the reed hollow
		# taught cordage keeps it; every arrival then stamps the gate marker.
		RECIPE_MIGRATION.repair(flags)
		flags.set_flag("water_chapter_started", true)
		flags.set_flag(RECIPE_MIGRATION.GATE_MARKER, true)
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
		"water:water_swim_stone_attune":
			var alpha := world.get_node_or_null("WaterAlpha")
			if alpha != null and alpha.has_method("request_attunement"):
				alpha.call("request_attunement")
		"water:water_swim_saddle_recipe_taught":
			if apply_personal_event(_game.local.flags, "saddle_taught", "water"):
				_game.push_world_message("Swim Saddle recipe learned. Craft it at a workbench.")
		"water:water_guardian_offer_requested":
			var veilfall := world.get_node_or_null("WaterVeilfall")
			if veilfall != null:
				veilfall.request_guardian_offer()
		_:
			if event.begins_with(LOCAL_STEP_EVENT):
				var chains := world.get_node_or_null("WaterLocalChains")
				if chains != null:
					chains.call("request_step", event.trim_prefix(LOCAL_STEP_EVENT))


## Named catch/defeat flags written locally by the shared director reach the
## host world (client) or every peer (host). See water_named_resolution.gd.
## Deliberately not a `progression_restore` member: that sweep runs on every
## client delta and would swallow a local write not yet forwarded. A flag that
## arrives by load/snapshot after build is at worst forwarded once as a no-op.
func _on_dock_afterword(conversation: String, npc: String, peer: int) -> void:
	if conversation != "water_mara_post" or npc != "water_mara" or peer != _game.session.local_peer_id() \
		or not _game.world.flags.has("water_currents_restored"): return
	_dock_afterword = {"character_id": _game.local.character_id, "world_namespace": _game.world.reward_delivery_namespace}

func dock_departure_ready() -> bool:
	if _game == null or world == null or world.simulation_only or not is_instance_valid(_dock_prompt) \
		or _game.current_realm != "water" or not bool(_game.call("is_host")) \
		or _game.session.config().get("redesign_ending_runtime_enabled") != true \
		or not _game.world.flags.has("water_currents_restored") \
		or _dock_afterword != {"character_id": _game.local.character_id, "world_namespace": _game.world.reward_delivery_namespace}: return false
	var actor: Node3D = world.local_rig()
	return actor != null and actor.global_position.distance_to(_dock_prompt.global_position) <= float(_dock_prompt.get("radius"))

func request_dock_conclusion() -> void:
	if not dock_departure_ready(): return
	if _dock_pending.is_empty():
		_dock_pending = {"character_id": _game.local.character_id, "world_namespace": _game.world.reward_delivery_namespace,
			"dock_id": "first_shore_to_reedhaven_dock"}
	_retry_dock_conclusion()

func _retry_dock_conclusion() -> void:
	if _dock_pending.is_empty(): return
	var result: Dictionary = _game.session.call("foundation_dock_conclusion", self, _dock_pending.duplicate(true))
	if result.get("ok") == true and result.get("saved") == true:
		_dock_pending.clear()
		_game.push_world_message("Civilian departures recorded. The shared crossings are open; your Home Key can take you back to the Crossing Hall.")

func _process(_delta: float) -> void:
	if _game != null and is_instance_valid(_dock_prompt):
		_dock_prompt.call("set_enabled", dock_departure_ready() and not _game.world.flags.has("water_civilian_departure_complete"))
		_dock_retry_seconds -= _delta
		if _dock_retry_seconds <= 0.0:
			_dock_retry_seconds = 1.0
			_retry_dock_conclusion()
	if _named == null or _game == null:
		return
	var fresh: Array[String] = _named.pending(_game.world.flags)
	if fresh.is_empty() or not bool(_game.call("is_multi_peer")):
		return
	for flag: String in fresh:
		if bool(_game.call("is_host")):
			var world_ledger: RefCounted = _ledger.get("ledger")
			_ledger.publish_journaled_delta({"seq": int(world_ledger.get("seq")) if world_ledger != null else 0,
				"realm": "water", "ops": [NAMED.flag_op(flag)]})
		else:
			_ledger.submit({"kind": "set_world_flag", "realm": "water", "id": flag, "value": true})


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
