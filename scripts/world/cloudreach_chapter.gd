extends Node3D

## Cloudreach's single dialogue/event adapter. Owns arrival/lower inspections;
## the physical runtime owns the complete cast, camps, caches and later acts.
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const RUNTIME_PATH := "res://data/config/cloudreach_act_one_runtime.json"
const CHAPTER_LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const PHYSICAL := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const PHYSICAL_RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const PYLON := preload("res://assets/environment/team_tether/tether_pylon.glb")
const PYLON_ALBEDO := preload("res://assets/environment/team_tether/tether_pylon_albedo.png")

var _chapter: Dictionary = {}
var _runtime: Dictionary = {}
var _world: Node3D
var _player: CharacterBody3D
var _panel: Node
var _anchor_prompts: Dictionary = {}
var _arrival_position := Vector3.ZERO
var _revision := -1
var _dialogue_was_open := false
var _events: Node = null
var _physical: Node3D = null
var _pylon_material: StandardMaterial3D = null


static func read_data(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw: Variant = JSON.parse_string(file.get_as_text())
	return raw if raw is Dictionary else {}


static func find_entry(entries: Array, id: String) -> Dictionary:
	for spec: Dictionary in entries:
		if str(spec.get("id", "")) == id:
			return spec
	return {}


static func flags_hold(progression: RefCounted, flags: Array) -> bool:
	for flag: String in flags:
		if not bool(progression.call("has", flag)):
			return false
	return true


## Authored completion events are the public contract. Reject events arriving
## before their prerequisites instead of manufacturing later chapter progress.
static func apply_event(progression: RefCounted, chapter: Dictionary, event: String) -> bool:
	return bool(CHAPTER_LOGIC.dispatch(progression, chapter, event).get("changed", false))


static func npc_specs(chapter: Dictionary, runtime: Dictionary, progression: RefCounted = null) -> Array:
	return PHYSICAL_RULES.npc_specs(chapter, runtime, progression,
		read_data(PHYSICAL.DATA_PATH).get("npc_position_overrides", {}))


func _ready() -> void:
	_world = get_parent() as Node3D
	_player = _world.get_node(^"Player") as CharacterBody3D
	_panel = _world.get_node(^"DialoguePanel")
	_chapter = read_data(CHAPTER_PATH)
	_runtime = read_data(RUNTIME_PATH)
	_events = CHAPTER_EVENTS.new()
	_events.name = "Events"
	_events.set("realm_id", "cloudreach")
	_events.set("chapter", _chapter)
	add_child(_events)
	add_to_group("progression_restore")
	var camp := find_entry(_chapter.get("camping_contract", {}).get("camps", []),
		str(_runtime.get("arrival", {}).get("camp_id", "")))
	_arrival_position = _vec3(camp.get("position", []))
	_build_anchors()
	_physical = PHYSICAL.new()
	_physical.name = "PhysicalRuntime"
	add_child(_physical)
	_physical.call("configure", _player, _player.get("fly_controller"),
		Callable(_events, "emit_event"), Callable(self, "_physical_ground"))
	_sync_prompts()


func _process(_delta: float) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var progression: RefCounted = game.get("progression")
	var arrival: Dictionary = _runtime.get("arrival", {})
	var offset := _player.global_position - _arrival_position
	if not bool(progression.call("has", "cloudreach_chapter_started")) \
			and Vector2(offset.x, offset.z).length() <= float(arrival.get("radius_m", 18.0)) \
			and absf(offset.y) <= float(arrival.get("height_tolerance_m", 4.0)):
		_emit_event("arrival_anchor_reached")
	for effect: String in _panel.call("drain_effects"):
		var parts := RUNNER.parse_effect(effect)
		if parts[0] == "cloudreach":
			# Guards include physical shrine vanes and distinguish Neri's side
			# report from main dialogue events. Never fall back after rejection.
			if not bool(_physical.call("consume_dialogue_effect", effect)):
				push_warning("Cloudreach dialogue effect rejected by chapter prerequisites: %s" % effect)
		else:
			push_warning("Unhandled Cloudreach dialogue effect: %s" % effect)
	# Recover a partially written old save with both individual mappings but
	# no aggregate flag. The aggregate is always durable, never UI-derived.
	if _revision != int(progression.get("revision")):
		CHAPTER_LOGIC.reconcile(progression, _chapter)
		_sync_prompts()
	var modal := bool(_panel.call("is_open"))
	if modal != _dialogue_was_open:
		_dialogue_was_open = modal
		_player.call("set_locomotion_enabled", not modal)
		_world.get_node(^"CameraRig").set_process(not modal)


func restore_progression_from_game(_game: Node) -> void:
	_revision = -1
	CHAPTER_LOGIC.reconcile(_game.get("progression"), _chapter)
	_sync_prompts()


## Public physical-event seam for later Cloudreach acts. Interactions call
## this only after their concrete action succeeds; the shared adapter rejects
## wrong-realm, wrong-order and duplicate events.
func emit_event(event: String) -> Dictionary:
	return _emit_event(event)


func physical_runtime() -> Node3D:
	return _physical


func events_adapter() -> Node:
	return _events


## Canonical NPC id -> current installed body. Call again after relocation;
## callers must not retain freed pre-restoration bodies across save reloads.
func npc_bodies() -> Dictionary:
	var result: Dictionary = {}
	if not is_instance_valid(_physical):
		return result
	var people := _physical.get_node_or_null(^"CloudreachPeople")
	if people == null:
		return result
	for spec: Dictionary in _chapter.get("npcs", []):
		var body := people.get_node_or_null(NodePath(str(spec["name"])))
		if body != null and not body.is_queued_for_deletion():
			result[str(spec["id"])] = body
	return result


func _physical_ground(at: Vector3) -> Vector3:
	var height := float(_world.call("ground_height_near", at))
	return Vector3.INF if is_nan(height) or absf(height - at.y) > 8.0 else Vector3(at.x, height, at.z)


func _emit_event(event: String) -> Dictionary:
	if _events == null:
		return {"accepted": false, "changed": false, "completed_ids": [], "granted_flags": []}
	return _events.call("emit_event", event)


func _build_anchors() -> void:
	for spec: Dictionary in _runtime.get("anchors", []):
		var anchor := Node3D.new()
		anchor.name = str(spec["id"])
		anchor.position = _grounded(_vec3(spec["position"]))
		add_child(anchor)
		var model := PYLON.instantiate() as Node3D
		model.scale = Vector3.ONE * float(spec.get("model_scale", 1.0))
		_apply_pylon_material(model)
		anchor.add_child(model)
		var prompt := INTERACTABLE.new()
		prompt.name = "Interactable"
		prompt.position = Vector3(0, 1.0, -1.4)
		prompt.call("configure", spec["label"], 3.8, true)
		prompt.connect("activated", _inspect_anchor.bind(spec))
		anchor.add_child(prompt)
		_anchor_prompts[str(spec["flag_id"])] = prompt


func _apply_pylon_material(node: Node) -> void:
	if _pylon_material == null:
		_pylon_material = StandardMaterial3D.new()
		_pylon_material.albedo_texture = PYLON_ALBEDO
		_pylon_material.roughness = 0.82
	for child: Node in node.get_children():
		_apply_pylon_material(child)
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = _pylon_material


func _inspect_anchor(spec: Dictionary) -> void:
	var game := get_node(^"/root/Game")
	var progression: RefCounted = game.get("progression")
	if not bool(progression.call("has", "cloudreach_crisis_learned")):
		return
	var flag := str(spec["flag_id"])
	if bool(progression.call("has", flag)):
		return
	var result: Dictionary = _emit_event("count:" + flag)
	var complete := bool(progression.call("has", "cloudreach_lower_anchors_investigated"))
	if not bool(result.get("accepted", false)):
		return
	game.call("push_world_message", "Storm Anchors inspected: 2/2. Both feed lines lead uphill."
		if complete else "Storm Anchors inspected: 1/2. A feed line leads uphill.")
	_sync_prompts()


func _sync_prompts() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var progression: RefCounted = game.get("progression")
	_revision = int(progression.get("revision"))
	for flag: String in _anchor_prompts:
		var prompt: Node = _anchor_prompts[flag]
		prompt.call("set_enabled", bool(progression.call("has", "cloudreach_crisis_learned"))
			and not bool(progression.call("has", flag)))


func _grounded(at: Vector3) -> Vector3:
	var height: float = float(_world.call("ground_height_near", at))
	if is_nan(height) or absf(height - at.y) > 8.0:
		push_error("Cloudreach authored placement has no intended surface at %s" % at)
		return at
	return Vector3(at.x, height, at.z)


static func _vec3(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2])) if raw.size() >= 3 else Vector3.ZERO
