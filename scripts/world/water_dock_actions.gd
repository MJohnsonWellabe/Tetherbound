extends Node3D
const RULES := preload("res://scripts/world/water_dock_rules.gd")
const INTERACT := preload("res://scripts/world/interactable.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
var _world: Node3D
var _game: Node
var _data: Dictionary
var _prompts: Dictionary = {}
var _barriers: Dictionary = {}
var _pending: Dictionary = {}
var _last_revision := -1

func build(world: Node3D) -> void:
	add_to_group("progression_restore")
	_world = world
	_game = get_node("/root/Game")
	_data = RULES.load_data()
	for action: Dictionary in _data.actions:
		var equipment := Node3D.new()
		equipment.name = str(action.id)
		add_child(equipment)
		equipment.position = RULES.action_position(action, world.config, world.ground_height_at)
		if not equipment.position.is_finite():
			push_error("Water dock has no terrain: " + str(action.id))
			equipment.queue_free()
			continue
		_build_equipment(equipment, str(action.kind))
		var prompt := INTERACT.new()
		equipment.add_child(prompt)
		prompt.position.y = 1.0
		prompt.configure(str(action.label), float(_data.interaction_distance_m), false)
		prompt.activated.connect(_activate.bind(action))
		_prompts[str(action.flag)] = prompt
	for dock: Dictionary in world.config.docks:
		if str(dock.unlock_flag).is_empty():
			continue
		var anchor: Dictionary = {}
		for candidate: Dictionary in world.config.anchors:
			if str(candidate.id) == str(dock.departure_anchor):
				anchor = candidate
		if anchor.is_empty():
			continue
		var at := Vector3(float(anchor.safe_position[0]), float(anchor.safe_position[1]), float(anchor.safe_position[2]))
		var shore := Vector3(float(anchor.shore_position[0]), 0, float(anchor.shore_position[2]))
		var barrier := StaticBody3D.new()
		barrier.name = str(dock.id) + "Barrier"
		add_child(barrier)
		barrier.position = at + (shore - at).normalized() * 5.0
		barrier.position.y = float(world.ground_height_at(barrier.position.x, barrier.position.z))
		barrier.rotation.y = atan2(shore.x - at.x, shore.z - at.z)
		var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
		var height := float(rules.docks.barrier_height_m)
		var width := float(rules.docks.barrier_width_m)
		_box(barrier, Vector3(0, height * 0.5, 0), Vector3(width, height, 0.35), Color("70583e"))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(width, height, 0.35)
		shape.shape = box
		shape.position.y = height * 0.5
		barrier.add_child(shape)
		_barriers[str(dock.unlock_flag)] = barrier
	CLAIM.listen(self, _on_delta)
	var ledger: Node = _game.ledger
	if ledger != null and not ledger.intent_refused.is_connected(_on_refused):
		ledger.intent_refused.connect(_on_refused)
	_refresh()

func restore_progression_from_game(_loaded_game: Node) -> void:
	# A load can restore a closed gate after this scene already removed it.
	# Rebuild disposable equipment from the newly loaded world flags.
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_prompts.clear()
	_barriers.clear()
	_pending.clear()
	build(_world)

func _activate(action: Dictionary) -> void:
	if _world.simulation_only or _pending.has(str(action.id)):
		return
	var counts: Dictionary = {}
	for item: String in action.cost:
		counts[item] = _game.inventory.count(item)
	_pending[str(action.id)] = true
	var result := CLAIM.submit(self, {"kind":"water_dock_action", "realm":"water", "action_id":str(action.id), "inventory":counts})
	if not CLAIM.in_flight(result):
		_pending.erase(str(action.id))
		_game.push_world_message(str(result.get("reason", "The dock action could not complete.")))

func _on_delta(_delta: Dictionary) -> void:
	_pending.clear()
	_refresh()

func _on_refused(kind: String, _code: String, reason: String, _details: Dictionary) -> void:
	if kind == "water_dock_action":
		_pending.clear()
		_game.push_world_message(reason)

func _process(_delta: float) -> void:
	if _game == null:
		return
	if int(_game.world.flags.revision) != _last_revision:
		_refresh()
	if not _game.is_host():
		return
	for completion: Dictionary in _data.completions:
		if _game.world.flags.has(str(completion.flag)):
			continue
		var ready := true
		for flag: String in completion.requires_flags:
			ready = ready and _game.world.flags.has(flag)
		if ready:
			_game.ledger.submit({"kind":"set_world_flag", "realm":"water", "id":str(completion.flag), "value":true})

func _refresh() -> void:
	_last_revision = int(_game.world.flags.revision)
	for flag: String in _prompts:
		_prompts[flag].enabled = not _world.simulation_only and not _game.world.flags.has(flag)
	for flag: String in _barriers.keys():
		if _game.world.flags.has(flag):
			var barrier: Node = _barriers[flag]
			remove_child(barrier)
			barrier.queue_free()
			_barriers.erase(flag)

func _build_equipment(parent: Node3D, kind: String) -> void:
	_box(parent, Vector3(0, 0.2, 0), Vector3(2.0, 0.4, 1.5), Color("736044"))
	if kind in ["pump", "sluice"]:
		_box(parent, Vector3(0, 0.9, 0), Vector3(1.0, 1.0, 0.8), Color("67736d"))
		_box(parent, Vector3(0.55, 1.7, 0), Vector3(0.15, 0.7, 0.15), Color("986440"))
	elif kind == "chart":
		_box(parent, Vector3(0, 1.0, 0), Vector3(1.8, 0.1, 1.1), Color("c8b887"))
	else:
		_box(parent, Vector3(0, 0.6, 0), Vector3(1.4, 0.35, 1.0), Color("9a8056"))

func _box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	box.material = material
	mesh.mesh = box
	mesh.position = at
	parent.add_child(mesh)
