extends Node3D

## Installed Water cast through production NPC bodies and the shared dialogue
## panel. Speech emits guarded requests only; this component never writes flags,
## awards items, completes objectives, starts combat, or opens a dock. Iona's
## post-victory attunement is likewise only a request to host authority.
signal guarded_event_requested(event_id: String, npc_id: String, peer_id: int)
const NPC := preload("res://scripts/npc/npc_body.gd")
const CHARACTER := preload("res://scripts/characters/character_model.gd")
const RANKS := preload("res://scripts/characters/npc_ranks.gd")
const GREETINGS := preload("res://scripts/world/village_npcs.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const LEDGER := preload("res://scripts/story/story_ledger.gd")
const CHAIN_RULES := preload("res://scripts/world/water_local_chain_rules.gd")
const LOCAL_STEP_EFFECT := "water:local_step:"
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
	if not _panel.line_presented.is_connected(_on_line_presented):
		_panel.line_presented.connect(_on_line_presented)
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

func _on_line_presented(conversation: String, is_last: bool) -> void:
	if not _active_conversation.is_empty() and conversation == _active_conversation:
		_last_line_seen = _last_line_seen or is_last

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
		var personal: RefCounted = game.get("local")
		conversation = choose_conversation(spec, _guards, _conversations, game.get("progression"),
			personal.flags if personal != null else null, LEDGER.world_flags(self), party_species(game))
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
	return speaker_matches(_conversations, conversation, spec)

static func speaker_matches(conversations: Dictionary, conversation: String, spec: Dictionary) -> bool:
	return conversations.has(conversation) and str(conversations[conversation].get("speaker", "")) == str(spec.display_name)

## The greeting a speaker opens with: the first guarded teaching/ceremony/chain
## conversation (in `dialogue_event_guards` order) authored for this speaker
## whose guard holds, else the `greeting_when` branch. Choosing one still offers
## speech only; the chapter validates any request it makes. Static and pure so
## the gating is testable without a scene.
static func choose_conversation(spec: Dictionary, guards: Array, conversations: Dictionary,
		progression: Variant, personal_flags: Variant, world_flags: Variant, party: Array = []) -> String:
	for guard: Variant in guards:
		if not guard is Dictionary:
			continue
		var candidate := str(guard.get("conversation", ""))
		if speaker_matches(conversations, candidate, spec) \
				and guard_holds(guard, personal_flags, world_flags, progression, party):
			return candidate
	return GREETINGS.greeting_for(spec, progression)

## The first local-chain conversation this speaker may open now that is marked
## `outranks_routed_greeting` (a step already under way), or "". Lets a speaker
## whose greeting is routed elsewhere (Edda after the Guardian's freeing) still
## hear a chain report; a chain's lead is not offered through that route.
static func chain_conversation_for(spec: Dictionary, guards: Array, conversations: Dictionary,
		progression: Variant, personal_flags: Variant, world_flags: Variant, party: Array = []) -> String:
	for guard: Variant in guards:
		if not guard is Dictionary or not str(guard.get("effect", "")).begins_with(LOCAL_STEP_EFFECT) \
				or not bool(guard.get("outranks_routed_greeting", false)):
			continue
		var candidate := str(guard.get("conversation", ""))
		if speaker_matches(conversations, candidate, spec) \
				and guard_holds(guard, personal_flags, world_flags, progression, party):
			return candidate
	return ""

func chain_conversation(id: String) -> String:
	var game := get_node_or_null("/root/Game")
	if game == null or not _specs.has(id):
		return ""
	var personal: RefCounted = game.get("local")
	return chain_conversation_for(_specs[id], _guards, _conversations, game.get("progression"),
		personal.flags if personal != null else null, LEDGER.world_flags(self), party_species(game))

## Species ids of this peer's own party: the proof a swimmer-gated guard reads.
static func party_species(game: Object) -> Array:
	var out: Array = []
	var party: Variant = game.get("party") if game != null else null
	if party == null or not (party as Object).has_method("members"):
		return out
	for creature: Variant in party.call("members"):
		if creature != null:
			out.append(str((creature as Object).get("species_id")))
	return out

func _guard_holds(guard: Dictionary) -> bool:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return false
	var personal: RefCounted = game.get("local")
	# Read world truth only for a guard that names world flags, as before.
	var reads_world: bool = not guard.get("requires_world_flags", []).is_empty() \
		or not guard.get("unless_world_flags", []).is_empty()
	reads_world = reads_world or guard.has("requires_swimmer_or_world_flags")
	return guard_holds(guard, personal.flags if personal != null else null,
		LEDGER.world_flags(self) if reads_world else null, game.get("progression"), party_species(game))

## Missing personal or world state fails a requirement and passes an exclusion,
## exactly as the per-node check always did.
static func guard_holds(guard: Dictionary, personal_flags: Variant, world_flags: Variant, progression: Variant,
		party: Array = []) -> bool:
	# The same swimmer-or-flag condition the host rule checks from party proof.
	if guard.has("requires_swimmer_or_world_flags") and not CHAIN_RULES.swimmer_condition_met(
			{"requires_swimmer_or_flags": guard.get("requires_swimmer_or_world_flags", [])}, world_flags, party):
		return false
	for flag: String in guard.get("requires_personal_flags", []):
		if personal_flags == null or not personal_flags.has(flag):
			return false
	for flag: String in guard.get("unless_personal_flags", []):
		if personal_flags != null and personal_flags.has(flag):
			return false
	for flag: String in guard.get("requires_world_flags", []):
		if world_flags == null or not world_flags.has(flag):
			return false
	for flag: String in guard.get("unless_world_flags", []):
		if world_flags != null and world_flags.has(flag):
			return false
	for flag: String in guard.get("requires_flags", []):
		if progression == null or not progression.has(flag):
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
			guarded_event_requested.emit(str(guard.effect), id, game.session.local_peer_id())
