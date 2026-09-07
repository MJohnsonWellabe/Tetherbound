extends Node3D

## Same-realm cave residency: the Water shell retains outdoor terrain and this
## interior simultaneously. Controls are authenticated by the persistent host
## transport; only the querying player's entrance/exit moves their own rig.
const INTERACT := preload("res://scripts/world/interactable.gd")
var world: Node3D
var rules: Dictionary
var interior: Node3D
var exterior: Node3D
var entrance: Vector3
var ready_for_intents := false
var _game: Node
var _transport: Node
var _controls: Dictionary = {}
var _gates: Dictionary = {}
var _entry_prompt: Node3D
var _exit_prompt: Node3D
var _last_flags_revision := -1

func build(realm: Node3D) -> void:
	world = realm
	_game = get_node("/root/Game")
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	_transport = _game.ledger.get_node("WaterVeilfallTransport")
	entrance = Vector3(float(rules.entrance_xz[0]), 0, float(rules.entrance_xz[1]))
	entrance.y = world.ground_height_at(entrance.x, entrance.z)
	exterior = Node3D.new()
	exterior.name = "WaterfallPassage"
	add_child(exterior)
	exterior.position = entrance
	_build_waterfall()
	_entry_prompt = _prompt(exterior, "Enter behind the waterfall", Vector3(0, 1.4, 0), _enter)
	interior = Node3D.new()
	interior.name = "VeilfallInterior"
	add_child(interior)
	interior.position = _v(rules.interior_origin)
	_build_rooms()
	_exit_prompt = _prompt(interior, "Return through the waterfall", _v(rules.exit_position), _leave)
	for control: Dictionary in rules.controls:
		var machinery := Node3D.new()
		machinery.name = str(control.id)
		interior.add_child(machinery)
		machinery.position = _v(control.position)
		_box(machinery, Vector3.ZERO, Vector3(2, 2, 1.5), Color(rules.colours.metal), true)
		_box(machinery, Vector3(0, 1.25, 0), Vector3(1.1, 0.3, 1.1), Color(rules.colours.brass), false)
		_controls[str(control.id)] = _prompt(machinery, str(control.label), Vector3(0, 0.4, -1.1), _activate.bind(str(control.id)))
	for gate: Dictionary in rules.gates:
		var barrier := StaticBody3D.new()
		barrier.name = str(gate.id)
		interior.add_child(barrier)
		barrier.position.z = float(gate.z)
		var width := float(gate.width_m)
		var height := float(gate.height_m)
		_collision_box(barrier, Vector3(0, height * 0.5, 0), Vector3(width, height, 0.6))
		for x in range(-int(width * 0.5), int(width * 0.5) + 1, 2):
			_box(barrier, Vector3(x, height * 0.5, 0), Vector3(0.3, height, 0.4), Color(rules.colours.metal), false)
		_gates[str(gate.opens_with)] = barrier
	_build_heart_chamber()
	_place_captain()
	ready_for_intents = true
	_refresh()

func _place_captain() -> void:
	var chapter := world.get_node_or_null("WaterChapter")
	var director := world.get_node_or_null("EncounterDirector")
	if chapter == null or director == null:
		return
	var body: Node3D = chapter.npc_bodies.get(str(rules.captain_npc_id))
	var id := str(rules.captain_encounter_id)
	if body == null or not director.trainer_specs.has(id):
		push_error("Veilfall requires the installed Captain Nerissa encounter")
		return
	# Keep the same authored NPC, four-creature team and production battle.
	# Residency changes where the encounter lives, never creates a second boss.
	body.reparent(interior)
	body.position = _v(rules.captain_position)
	var spec: Dictionary = director.trainer_specs[id]
	spec.position = [body.global_position.x, body.global_position.y, body.global_position.z]
	spec.defeat_flag = str(rules.captain_defeat_flag)
	spec.requires_flags = rules.captain_requires.duplicate()

func _build_rooms() -> void:
	var wall_height := float(rules.wall_height_m)
	var wall_thickness := float(rules.wall_thickness_m)
	for room: Dictionary in rules.rooms:
		var center := Vector3(float(room.center_xz[0]), 0, float(room.center_xz[1]))
		var width := float(room.size_xz[0])
		var length := float(room.size_xz[1])
		var floor_width := float(room.get("bridge_width_m", width))
		_box(interior, center - Vector3.UP * float(rules.floor_thickness_m) * 0.5,
			Vector3(floor_width, float(rules.floor_thickness_m), length), Color(rules.colours.floor), true)
		for side in [-1, 1]:
			_box(interior, center + Vector3(side * width * 0.5, wall_height * 0.5, 0),
				Vector3(wall_thickness, wall_height, length), Color(rules.colours.stone), true)
			# Pump channels are contained by a lower trough floor. Falling from
			# the bridge leads to reachable ramps, never an unbounded void.
			if room.has("bridge_width_m"):
				var trough_width := (width - floor_width) * 0.5
				_box(interior, center + Vector3(side * (floor_width + trough_width) * 0.5, -1.5, 0),
					Vector3(trough_width, 1.0, length), Color(rules.colours.stone), true)
				_box(interior, center + Vector3(side * (floor_width + trough_width) * 0.5, -0.4, 0),
					Vector3(trough_width, 0.08, length), Color(rules.colours.channel), false)
		_box(interior, center + Vector3.UP * wall_height,
			Vector3(width + wall_thickness, wall_thickness, length), Color(rules.colours.stone), true)
		var light := OmniLight3D.new()
		interior.add_child(light)
		light.position = center + Vector3.UP * 7
		light.light_color = Color("c8dbc9")
		light.light_energy = 2.0
		light.omni_range = maxf(width, length)
	# Entrance/back walls make the cave enclosed, while consecutive rooms share
	# unobstructed thresholds except for their authored mechanical grilles.
	_box(interior, Vector3(0, wall_height * 0.5, 0), Vector3(18, wall_height, wall_thickness), Color(rules.colours.stone), true)
	_box(interior, Vector3(0, wall_height * 0.5, 124), Vector3(42, wall_height, wall_thickness), Color(rules.colours.stone), true)
	# Close the shoulders where galleries widen. The central connection stays
	# open, but neither width change exposes a walkable exit into empty space.
	for joint in [[30.0, 18.0, 30.0], [80.0, 30.0, 42.0]]:
		var shoulder: float = (float(joint[2]) - float(joint[1])) * 0.5
		for side in [-1, 1]:
			_box(interior, Vector3(side * (float(joint[1]) + shoulder) * 0.5, wall_height * 0.5, float(joint[0])),
				Vector3(shoulder, wall_height, wall_thickness), Color(rules.colours.stone), true)
	# Shallow steps recover both sides of the channel crossing to the gallery.
	for side in [-1, 1]:
		for step in 4:
			_box(interior, Vector3(side * 5, -1.0 + step * 0.25, 59 + step),
				Vector3(4, 0.5, 1.2), Color(rules.colours.floor), true)

func _build_waterfall() -> void:
	var fall: Dictionary = rules.waterfall
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(fall.width_m), float(fall.height_m))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(fall.colour)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.83
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	plane.material = material
	mesh.mesh = plane
	mesh.rotation.x = PI * 0.5
	mesh.position = Vector3(0, float(fall.height_m) * 0.5 - 2, -2)
	exterior.add_child(mesh)

func _build_heart_chamber() -> void:
	var crystal := MeshInstance3D.new()
	crystal.name = "CaptiveHeartChamberCrystal"
	var prism := PrismMesh.new()
	prism.size = Vector3(5, 10, 5)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(rules.colours.crystal)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.3
	prism.material = material
	crystal.mesh = prism
	interior.add_child(crystal)
	crystal.position = _v(rules.crystal_position)
	for side in [-1, 1]:
		_box(interior, Vector3(side * 18, 7, 105), Vector3(0.12, 6, 3), Color(rules.colours.banner), false)
		_box(interior, Vector3(side * 7, 1, 113), Vector3(2, 2, 3), Color(rules.colours.metal), true)

func _prompt(parent: Node3D, label: String, at: Vector3, action: Callable) -> Node3D:
	var prompt := INTERACT.new()
	parent.add_child(prompt)
	prompt.position = at
	prompt.configure(label, float(rules.interact_radius_m), not world.simulation_only)
	prompt.activated.connect(action)
	return prompt

func _enter() -> void:
	if world.simulation_only:
		return
	var player: Node3D = world.local_rig()
	if player.global_position.distance_to(_entry_prompt.global_position) > float(rules.interact_radius_m):
		return
	_transfer_local(interior.position + _v(rules.entry_position))

func _leave() -> void:
	if world.simulation_only:
		return
	var player: Node3D = world.local_rig()
	if player.global_position.distance_to(_exit_prompt.global_position) > float(rules.interact_radius_m):
		return
	_transfer_local(entrance + Vector3(0, 0.2, -3))

func _transfer_local(destination: Vector3) -> void:
	var manager := world.get_node("CombatManager")
	if manager.is_fighting():
		return
	var riding := world.get_node_or_null("RidingController")
	if riding != null and riding.is_mounted():
		_game.push_world_message("Dismount before entering the narrow passage.")
		return
	var director := world.get_node("EncounterDirector")
	if director.ally_body() != null:
		director.dismiss_active_creature()
	world.local_rig().global_position = destination
	world.local_rig().velocity = Vector3.ZERO
	_refresh()

func _activate(id: String) -> void:
	var verdict: Dictionary = _transport.submit({"kind": "veilfall_control", "control_id": id})
	if not verdict.get("ok", false) and not verdict.get("pending", false):
		_game.push_world_message(str(verdict.get("reason", "The mechanism is not ready.")))

func host_commit(intent: Dictionary, _peer: int, actor: Dictionary) -> Dictionary:
	if not _game.is_host() or str(intent.get("kind", "")) != "veilfall_control":
		return {"ok": false, "reason": "The realm authority cannot perform that action."}
	var id := str(intent.get("control_id", ""))
	if not _controls.has(id):
		return {"ok": false, "reason": "That mechanism does not exist."}
	var position: Vector3 = actor.get("position", Vector3.INF)
	if str(actor.get("realm", "")) != "water" or position.distance_to(_controls[id].global_position) > float(rules.interact_radius_m):
		return {"ok": false, "reason": "Stand beside the mechanism."}
	for control: Dictionary in rules.controls:
		if str(control.id) != id:
			continue
		for flag: String in control.requires:
			if not _game.world.flags.has(flag):
				return {"ok": false, "reason": "The upstream tether is still holding this mechanism."}
		return _game.ledger.submit({"kind": "set_world_flag", "realm": "water", "id": str(control.flag), "value": true})
	return {"ok": false}

func receive_authority(kind: String, payload: Dictionary) -> void:
	if kind == "verdict" and not payload.get("ok", false):
		_game.push_world_message(str(payload.get("reason", "The mechanism is not ready.")))

func contains_interior(at: Vector3) -> bool:
	if interior == null:
		return false
	var local := at - interior.position
	return absf(local.x) <= 24 and local.z >= -2 and local.z <= 126 and absf(local.y) < 20

func built_floor_height_at(x: float, z: float) -> float:
	if interior == null:
		return NAN
	var local := Vector2(x - interior.position.x, z - interior.position.z)
	for room: Dictionary in rules.rooms:
		var center := Vector2(float(room.center_xz[0]), float(room.center_xz[1]))
		var half := Vector2(float(room.size_xz[0]), float(room.size_xz[1])) * 0.5
		if absf(local.x - center.x) <= half.x and absf(local.y - center.y) <= half.y:
			if room.has("bridge_width_m") and absf(local.x - center.x) > float(room.bridge_width_m) * 0.5:
				return interior.position.y - 1
			return interior.position.y
	return NAN

func _process(_delta: float) -> void:
	if not ready_for_intents:
		return
	_refresh()

func _refresh() -> void:
	if interior == null:
		return
	var inside: bool = not world.simulation_only and contains_interior(world.local_rig().global_position)
	interior.visible = inside
	_entry_prompt.enabled = not world.simulation_only and not inside
	_exit_prompt.enabled = inside
	for control: Dictionary in rules.controls:
		_controls[str(control.id)].enabled = inside and not _game.world.flags.has(str(control.flag))
	if _last_flags_revision == int(_game.world.flags.revision):
		return
	_last_flags_revision = int(_game.world.flags.revision)
	for flag: String in _gates:
		var gate: StaticBody3D = _gates[flag]
		var opened: bool = _game.world.flags.has(flag)
		gate.visible = not opened
		gate.collision_layer = 0 if opened else 1

func _box(parent: Node3D, at: Vector3, size: Vector3, colour: Color, collision: bool) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.72
	box.material = material
	mesh.mesh = box
	parent.add_child(mesh)
	mesh.position = at
	if collision:
		var body := StaticBody3D.new()
		parent.add_child(body)
		_collision_box(body, at, size)

func _collision_box(parent: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	parent.add_child(collider)
	collider.position = at

func _v(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
