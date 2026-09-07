extends Node3D

## Installed Water cast through production NPC bodies and the shared dialogue
## panel. Speech emits guarded requests only; this component never writes flags,
## awards items, completes objectives, starts combat, or opens a dock.
signal guarded_event_requested(event_id: String, npc_id: String, peer_id: int)
const NPC := preload("res://scripts/npc/npc_body.gd")
const CHARACTER := preload("res://scripts/characters/character_model.gd")
const RANKS := preload("res://scripts/characters/npc_ranks.gd")
const GREETINGS := preload("res://scripts/world/village_npcs.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const LEDGER := preload("res://scripts/story/story_ledger.gd")
const CAST_PATH := "res://data/config/water_characters.json"
const DIALOGUE_PATH := "res://data/dialogue/water.json"
var _world: Node3D
var _player: Node3D
var _panel: Node
var _specs: Dictionary = {}
var _bodies: Dictionary = {}
var _guards: Array = []
var _conversations: Dictionary = {}
var _active_npc := ""
var _active_conversation := ""
var _last_line_seen := false

func build(world: Node3D) -> Dictionary:
	if not _bodies.is_empty():
		return _bodies.duplicate()
	_world = world
	if get_parent() == null:
		_world.add_child(self)
	_player = world.call("local_rig") if world.has_method("local_rig") else world.get_node_or_null("Player")
	_panel = world.get_node_or_null("DialoguePanel")
	if _panel == null:
		push_error("Water NPCs require their realm's production DialoguePanel")
		return {}
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CAST_PATH))
	var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_PATH))
	_conversations = dialogue.get("conversations", {})
	_guards = cast.get("dialogue_event_guards", [])
	# Extend the production runner's dictionary without changing shared source.
	# Strip declarative effects from these copies: guarded requests below are
	# the only Water speech-action channel, so a generic flag drainer cannot
	# accidentally turn a conversation into a physical chapter completion.
	var table: Dictionary = RUNNER.table()
	for id: String in _conversations:
		var entry: Dictionary = _conversations[id].duplicate(true)
		for line: Variant in entry.get("lines", []):
			if line is Dictionary:
				line.erase("effect")
				line.erase("effects")
		table[id] = entry
	if not _panel.finished.is_connected(_on_finished):
		_panel.finished.connect(_on_finished)
	var centres: Dictionary = {}
	var config: Dictionary = world.get("config")
	for island: Dictionary in config.get("islands", []):
		centres[str(island.id)] = island.center_xz_m
	for spec: Dictionary in cast.get("npcs", []):
		var id := str(spec.id)
		if not centres.has(str(spec.island_id)):
			push_error("Water NPC has unknown island: " + id)
			continue
		var centre: Array = centres[str(spec.island_id)]
		var offset: Array = spec.island_local_offset
		var position := Vector3(float(centre[0]) + float(offset[0]), 0, float(centre[1]) + float(offset[2]))
		position.y = world.call("ground_height_at", position.x, position.z)
		if not is_finite(position.y) or position.y < 0.0:
			push_error("Water NPC has no dry terrain: " + id)
			continue
		var profile := str(spec.body_profile)
		var model: Dictionary = CHARACTER.config_for(profile).duplicate(true)
		if profile.begins_with("officer_"):
			model = RANKS.config_for("officer", profile)
		elif profile.begins_with("captain_"):
			model = RANKS.config_for("captain", profile)
		if model.is_empty() or str(model.get("model", "")) != str(spec.model):
			push_error("Water NPC installed profile/model mismatch: " + id)
			continue
		var body: Node3D = NPC.new()
		body.name = id
		body.set_meta("water_npc_id", id)
		body.set_meta("water_island_id", str(spec.island_id))
		add_child(body)
		if not body.call("setup_from_config", model, _player):
			body.queue_free()
			continue
		body.global_position = position
		body.rotation.y = deg_to_rad(float(spec.get("facing_deg", 0.0)))
		var prompt: Node3D = body.call("add_prompt", "Greet " + str(spec.display_name))
		prompt.activated.connect(_on_greeted.bind(id))
		_specs[id] = spec
		_bodies[id] = body
	return _bodies.duplicate()

func _process(_delta: float) -> void:
	if _active_conversation.is_empty() or _panel == null or not _panel.call("is_open"):
		return
	var runner: RefCounted = _panel.call("runner")
	if str(runner.call("conversation_id")) == _active_conversation:
		_last_line_seen = _last_line_seen or bool(runner.call("line").get("is_last", false))

func _on_greeted(id: String) -> void:
	start_conversation(id)

## Allows the chapter to request an authored conversation, still enforcing the
## speaking body, local realm/proximity, speaker identity and action guards.
func start_conversation(id: String, requested: String = "") -> bool:
	if not _specs.has(id) or _panel == null or _panel.call("is_open"):
		return false
	var game := get_node_or_null("/root/Game")
	if game == null or str(game.get("current_realm")) != "water" or _player == null:
		return false
	if _player.global_position.distance_to((_bodies[id] as Node3D).global_position) > 5.0:
		return false
	var spec: Dictionary = _specs[id]
	var conversation := requested
	if conversation.is_empty():
		conversation = GREETINGS.greeting_for(spec, game.get("progression"))
		# Guarded teaching/ceremony conversations are authored for these speakers.
		# Choosing one still offers speech only; the chapter validates its request.
		for guard: Dictionary in _guards:
			var candidate := str(guard.get("conversation", ""))
			if _speaker_matches(candidate, spec) and _guard_holds(guard):
				conversation = candidate
				break
	if not _speaker_matches(conversation, spec):
		return false
	for guard: Dictionary in _guards:
		if str(guard.get("conversation", "")) == conversation and not _guard_holds(guard):
			return false
	_active_npc = id
	_active_conversation = conversation
	_last_line_seen = false
	if not _panel.call("start", conversation, {"speaker": spec.display_name, "portrait": spec.portrait}):
		_active_npc = ""
		_active_conversation = ""
		return false
	_last_line_seen = bool(_panel.call("runner").call("line").get("is_last", false))
	return true

func _speaker_matches(conversation: String, spec: Dictionary) -> bool:
	return _conversations.has(conversation) and str(_conversations[conversation].get("speaker", "")) == str(spec.display_name)

func _guard_holds(guard: Dictionary) -> bool:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return false
	var personal: RefCounted = game.get("local")
	for flag: String in guard.get("requires_personal_flags", []):
		if personal == null or not personal.flags.has(flag):
			return false
	for flag: String in guard.get("requires_world_flags", []):
		if not LEDGER.world_flag(self, flag):
			return false
	for flag: String in guard.get("requires_flags", []):
		if not game.get("progression").has(flag):
			return false
	return true

func _on_finished(conversation: String) -> void:
	if conversation != _active_conversation:
		return
	var id := _active_npc
	var delivered := _last_line_seen
	_active_npc = ""
	_active_conversation = ""
	_last_line_seen = false
	var game := get_node_or_null("/root/Game")
	if not delivered or game == null or str(game.get("current_realm")) != "water":
		return
	for guard: Dictionary in _guards:
		if str(guard.get("conversation", "")) == conversation and _guard_holds(guard):
			guarded_event_requested.emit(str(guard.effect), id, multiplayer.get_unique_id())

