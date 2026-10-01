extends RefCounted

## Passive witness for an ordinary admitted fight. It never launches a move,
## changes a receipt, grants a move/item, presses input or owns damage timing.
## Caller attaches after the real HUD and before the witnessed input segment.
var _manager: Node
var _hud: Node
var _rows: Dictionary = {}
var _order: Array[String] = []
var _label_ids: Dictionary = {}
var _attached := false
var _overflow := false
const MAX_ACTIONS := 128

func attach(manager: Node, hud: Node) -> bool:
	if _attached or not is_instance_valid(manager) or not is_instance_valid(hud): return false
	if not manager.has_signal("attack_launched") or not manager.has_signal("impact_confirmed"): return false
	var labels: Variant = hud.get("_damage_numbers")
	if not labels is Array: return false
	_manager = manager
	_hud = hud
	for label: Label in labels:
		if is_instance_valid(label): _label_ids[label.get_instance_id()] = true
	_manager.connect("attack_launched", _on_launch)
	_manager.connect("impact_confirmed", _on_impact)
	_attached = true
	return true

func _on_launch(on_enemy: bool, launch: Dictionary, presentation: Node3D) -> void:
	if not _attached: return
	var id := str(launch.get("action_id", ""))
	if id.is_empty() or _rows.has(id): return
	if _rows.size() >= MAX_ACTIONS:
		_overflow = true
		return
	var script_path := ""
	if is_instance_valid(presentation) and presentation.get_script() is Script:
		script_path = (presentation.get_script() as Script).resource_path
	_rows[id] = {"action_id": id, "move_id": str(launch.get("move_id", "")),
		"encounter_id": str(launch.get("encounter_id", "")), "on_enemy": on_enemy,
		"mastery_rank": int(launch.get("mastery_rank", -1)),
		"launch_frame": Engine.get_process_frames(), "launch_ticks_usec": Time.get_ticks_usec(),
		"travel_seconds": float(launch.get("travel_seconds", -1.0)),
		"presentation_script": script_path, "contact_frame": -1, "contact_ticks_usec": -1,
		"impact_receipt_frame": -1, "number_birth_frame": -1, "number_draw_frame": -1,
		"duplicate_contact": false, "duplicate_impact": false,
		"contact_geometry_nodes_visible": false, "number_node_visible_after_draw": false}
	_order.append(id)
	if is_instance_valid(presentation) and presentation.has_signal("presentation_arrived"):
		presentation.connect("presentation_arrived", _on_contact.bind(id, weakref(presentation)))
	else:
		_rows[id]["contact_observation_missing"] = true

func _on_contact(_context: Dictionary, id: String, effect_ref: WeakRef) -> void:
	if not _attached or not _rows.has(id): return
	var row: Dictionary = _rows[id]
	if int(row.contact_frame) >= 0:
		row.duplicate_contact = true
		return
	row.contact_frame = Engine.get_process_frames()
	row.contact_ticks_usec = Time.get_ticks_usec()
	var effect := effect_ref.get_ref() as Node3D
	if not is_instance_valid(effect): return
	var impact: Variant = effect.get("_impact")
	if impact is Node3D and is_instance_valid(impact):
		for child: Node in impact.get_children():
			if child is GeometryInstance3D and child.is_visible_in_tree():
				row.contact_geometry_nodes_visible = true

func _on_impact(_on_enemy: bool, receipt: Dictionary, _position: Vector3) -> void:
	if not _attached or not is_instance_valid(_hud): return
	var id := str(receipt.get("action_id", ""))
	if not _rows.has(id): return
	var row: Dictionary = _rows[id]
	if int(row.impact_receipt_frame) >= 0:
		row.duplicate_impact = true
		return
	row.impact_receipt_frame = Engine.get_process_frames()
	row.impact_ticks_usec = Time.get_ticks_usec()
	row.applied_damage = float(receipt.get("applied_damage", receipt.get("damage", -1.0)))
	# Labels are identified from the actual HUD's existing array after its
	# normal receipt listener. No label metadata or parent is modified here.
	var labels: Variant = _hud.get("_damage_numbers")
	if not labels is Array: return
	var current_ids: Dictionary = {}
	var new_labels: Array[WeakRef] = []
	for label: Label in labels:
		if not is_instance_valid(label): continue
		var label_id := label.get_instance_id()
		current_ids[label_id] = true
		if not _label_ids.has(label_id): new_labels.append(weakref(label))
	_label_ids = current_ids
	if new_labels.size() != 1:
		row.number_association_ambiguous = true
		row.new_label_count = new_labels.size()
		return
	row.number_birth_frame = Engine.get_process_frames()
	await RenderingServer.frame_post_draw
	if not _attached: return
	var number := new_labels[0].get_ref() as Label
	if not is_instance_valid(number): return
	row.number_draw_frame = Engine.get_process_frames()
	var bounds := number.get_global_rect()
	var in_view := number.get_viewport_rect().intersects(bounds)
	var inherited_alpha := number.self_modulate.a
	var ancestor: Node = number
	while is_instance_valid(ancestor):
		if ancestor is CanvasItem: inherited_alpha *= (ancestor as CanvasItem).modulate.a
		ancestor = ancestor.get_parent()
	row.number_node_visible_after_draw = number.is_visible_in_tree() and inherited_alpha > 0.0 and in_view and not number.text.is_empty() and number.size.x > 0.0 and number.size.y > 0.0
	row.number_rect = [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y]
	row.number_inherited_alpha = inherited_alpha
	row.number_text = number.text
	row.number_contact_order_observed = int(row.contact_frame) >= 0 and int(row.number_draw_frame) >= int(row.contact_frame)

func detach() -> void:
	_attached = false
	if is_instance_valid(_manager):
		if _manager.is_connected("attack_launched", _on_launch): _manager.disconnect("attack_launched", _on_launch)
		if _manager.is_connected("impact_confirmed", _on_impact): _manager.disconnect("impact_confirmed", _on_impact)
	_manager = null
	_hud = null

func snapshot() -> Dictionary:
	var rows: Array[Dictionary] = []
	for id: String in _order: rows.append((_rows[id] as Dictionary).duplicate(true))
	return {"scope": "Passive actual callback/HUD-node observation; no gameplay mutation or independent acceptance",
		"overflow": _overflow, "renderer": RenderingServer.get_current_rendering_method(),
		"actions": rows, "limits": ["Visible nodes are not a pixel/hit-locus proof",
		"Needs actual input/earned-route and source/scene/audio provenance from caller",
		"Must attach after HUD; ambiguous/missing labels stay unproved",
		"Contact-only/legacy paths without library signals remain unproved",
		"No independent craft, co-op, HP-authority or performance verdict"]}
