extends Node
## Scene/UI adapter over Foundation's authenticated action doorway. This owns
## no admission map or persistence. Bind only from the actual host/session
## composition; the callback performs identity/proximity/CAS/save/ACK checks.
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")
const PANEL := preload("res://scripts/masters/breakthrough_panel.gd")
var _submit: Callable
var _view: Callable
var _panel: Control

func bind_actions(submit_action: Callable, personal_view: Callable) -> bool:
	if not submit_action.is_valid() or not personal_view.is_valid(): return false
	_submit = submit_action
	_view = personal_view
	return true

func submit(op: String, intent: Dictionary, source: Node) -> Dictionary:
	if not _submit.is_valid():
		return {"ok": false, "code": "breakthrough_producer_not_mounted", "reason": "Master and Kitchen integration is not ready."}
	# Source node stays local. It is not serialized as proof of reachability.
	var verdict: Variant = _submit.call(op, intent.duplicate(true), source)
	return verdict if verdict is Dictionary else {"ok": false, "code": "invalid_producer_verdict"}

func view() -> Dictionary:
	if not _view.is_valid(): return {}
	var state: Variant = _view.call()
	return state if state is Dictionary else {}

func mount_biome(world: Node3D, player: Node3D, runtime_biome: String) -> void:
	for row: Dictionary in BREAKTHROUGH.masters().get("masters", []):
		if BIOMES.runtime_id(str(row.biome)) != runtime_biome: continue
		var scene: Variant = load(str(row.scene))
		if not scene is PackedScene: continue
		var site: Node3D = scene.instantiate()
		world.add_child(site)
		site.set_meta("breakthrough_service", self)
		if not site.call("mount", world, player):
			site.queue_free()
			continue
		site.connect("challenge_requested", _challenge)
		site.connect("chest_requested", _chest)

func _challenge(site: Node3D) -> void:
	_open("duel", site, str(site.get("master_id")))

func _chest(site: Node3D) -> void:
	var verdict := submit("master_chest", {"master_id": str(site.get("master_id"))}, site)
	_message(str(verdict.get("reason", verdict.get("code", ""))))

func open_kitchen(station: Node3D) -> void:
	_open("cook", station, "")

func open_feed() -> void:
	_open("feed", self, "")

func _open(mode: String, source: Node, master_id: String) -> void:
	if _panel == null:
		_panel = PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self, mode, source, master_id)

func _message(message: String) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game != null and not message.is_empty(): game.call("push_world_message", message)

func _exit_tree() -> void:
	if is_instance_valid(_panel): _panel.queue_free()
