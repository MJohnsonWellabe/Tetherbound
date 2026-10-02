extends Node
## Scene/UI adapter over Foundation's authenticated action doorway. This owns
## no admission map or persistence. Bind only from the actual host/session
## composition; the callback performs identity/proximity/CAS/save/ACK checks.
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")
const PANEL := preload("res://scripts/masters/breakthrough_panel.gd")
const SITE := preload("res://scripts/masters/master_site.gd")
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

func retained_transaction(actions: Array) -> Dictionary:
	var producer: Object = _submit.get_object() if _submit.is_valid() else null
	return producer.call("retained_training_transaction", actions) \
		if producer != null and producer.has_method("retained_training_transaction") else {}

func mount_biome(world: Node3D, player: Node3D, runtime_biome: String) -> void:
	if not is_instance_valid(world) or not is_instance_valid(player) or not world.is_inside_tree() \
		or not player.is_inside_tree() or not world.is_ancestor_of(player): return
	for row: Dictionary in BREAKTHROUGH.masters().get("masters", []):
		if BIOMES.runtime_id(str(row.biome)) != runtime_biome: continue
		var retained := retained_site(world, str(row.id))
		if retained.status != "absent":
			if retained.status == "owned":
				var npc: Node = retained.site.get_node_or_null(^"Master")
				if npc != null and npc.has_method("set_player"): npc.call("set_player", player)
			continue # Never duplicate or adopt a foreign/ambiguous authored site.
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

## Read-only ownership lookup. It is also usable by detached source controls;
## mount_biome supplies the separate live world/occupant readiness fence.
func retained_site(world: Node3D, master_id: String) -> Dictionary:
	if not is_instance_valid(world): return {"status": "unavailable"}
	var found: Node3D
	var candidates: Array[Node] = []
	if world.is_inside_tree():
		for node: Node in world.get_tree().get_nodes_in_group(SITE.FOUNDATION_GROUP):
			if world.is_ancestor_of(node): candidates.append(node)
	else:
		candidates = world.find_children("*", "Node3D", true, false)
	for candidate: Node in candidates:
		if candidate.get_script() != SITE or candidate.get("master_id") != master_id: continue
		if found != null: return {"status": "ambiguous"}
		found = candidate as Node3D
	if found == null: return {"status": "absent"}
	if not found.has_meta("breakthrough_service") or found.get_meta("breakthrough_service") != self or found.get("_mounted") != true \
		or found.is_queued_for_deletion(): return {"status": "foreign_or_unready"}
	return {"status": "owned", "site": found}

func _challenge(site: Node3D) -> void:
	_open("duel", site, str(site.get("master_id")))

func _chest(site: Node3D) -> void:
	var verdict := submit("master_chest", {"master_id": str(site.get("master_id"))}, site)
	_message(str(verdict.get("reason", verdict.get("code", ""))))

func open_kitchen(station: Node3D) -> void:
	_open("cook", station, "")

func open_feed() -> void:
	_open("feed", self, "")

## Only Session's fenced reply for this still-open ordinary chooser reaches
## this path. The selected actual local creature must still be the same UID.
func accept_duel_offer(intent: Dictionary, result: Dictionary) -> bool:
	if not is_instance_valid(_panel) or _panel.call("is_open") != true or _panel.get("_mode") != "duel" \
		or _panel.get("_service") != self or _panel.get("_master") != intent.get("master_id"):
		return false
	var site := _panel.get("_source") as Node3D
	var producer: Object = _submit.get_object() if _submit.is_valid() else null
	if not is_instance_valid(site) or producer == null or not producer.has_method("_foundation_master_director"): return false
	var director: Node = producer.call("_foundation_master_director", site)
	if director == null or director.call("accept_guest_master_offer", site, intent, result) != true: return false
	_panel.call("close")
	return true

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
