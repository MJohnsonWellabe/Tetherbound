extends SceneTree

## Synthetic native reachability diagnostic, not earned campaign evidence.
## Reads the exact shipped scatter placement; actual Player, arbiter, prompt
## and production tree collider, on a local canonical heightfield mesh.
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const VEG := preload("res://scripts/world/vegetation.gd")
const FIELD := preload("res://scripts/world/playground_heightfield.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
# bf0f38b203 removed trees#320. Pin kept trees#886, the closest non-smaller
# CommonTree_2 in this region by scale (1.598110499382019 -> 1.6529272198677063).
const TARGET := Vector3(98.15209197998047, 5.79111909866333, -35.932098388671875)
var _player: CharacterBody3D
var _arbiter: Node
var _prompt: Node3D
var _activated := false

class CameraBasis extends Node3D:
	func planar_basis() -> Basis: return Basis.IDENTITY

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var data := {}
	var file := FileAccess.open("res://data/scatter/playground/region_0_-1.bin", FileAccess.READ)
	BAKE._read_region(file, data, {})
	var placement := {}
	var layer := ""
	var order := -1
	for key: String in data:
		for record: Dictionary in data[key]:
			if record.placement.position.distance_to(TARGET) < 0.01:
				placement = record.placement.duplicate(true)
				layer = key
				order = int(record.order)
	if placement.is_empty():
		print("FAIL exact shipped placement absent")
		quit(1)
		return
	var veg := VEG.new()
	var field := FIELD.new()
	var config: Dictionary = veg._layer_for(str(placement.model))
	print("EXACT BAKED placement=", placement, " layer=", layer, " order=", order,
		" layer_collision=", config.get("collision_radius"), " collides=", config.get("collides"),
		" canonical_ground=", field.height_at(TARGET.x, TARGET.z),
		" old_prompt_height=", 1.0 + float(placement.scale))
	for offset in [-4.0,-1.0,0.0,1.0,4.0]:
		print("GROUND sample z_offset=",offset," y=",field.height_at(TARGET.x,TARGET.z+offset))
	if OS.get_cmdline_user_args().has("--metadata-only"):
		veg.free()
		quit(0)
		return
	# Fixture construction only; the active sample below uses ordinary stick.
	var world := Node3D.new()
	world.name = "ExactTreeNativeFixture"
	root.add_child(world)
	current_scene = world
	var camera := CameraBasis.new()
	camera.name = "CameraRig"
	world.add_child(camera)
	_build_floor(world, field)
	_player = PLAYER.instantiate()
	_player.name = "Player"
	_player.camera_rig_path = NodePath("../CameraRig")
	_player.position = TARGET + Vector3(0, 1, 4)
	_player.position.y = field.height_at(_player.position.x, _player.position.z) + 0.2
	world.add_child(_player)
	_arbiter = ARBITER.new()
	_arbiter.name = "InteractionArbiter"
	_arbiter.player_path = NodePath("../Player")
	world.add_child(_arbiter)
	_arbiter.activated.connect(func(provider: Object): _activated = provider == _prompt)
	world.add_child(veg)
	veg._field = field
	# Avoid renderer instancer setup; only the production spawn method's id
	# lookup needs this read-only fixture dictionary entry.
	veg._mesh_ids[str(placement.model)] = 0
	placement.harvest_item = "wood"
	placement.harvest_amount = 2
	placement.harvest_layer = layer
	placement.harvest_index = order
	veg._spawn_harvest_point(placement)
	var point: Node3D = veg._harvest_nodes["%s#%d" % [layer, order]]
	_prompt = point.get_node("Interactable")
	# Probe input observes admission without submitting a synthetic ledger claim.
	_prompt.activated.disconnect(point._on_gathered)
	var trunk := StaticBody3D.new()
	trunk.name = "ExactProductionTreeCollider"
	world.add_child(trunk)
	trunk.add_child(veg._make_collision_shape(placement, float(config.collision_radius)))
	for frame in 30: await physics_frame
	# At most nine cached observations; no additional physics query or frame.
	var approach_trace := [_approach_sample("settled", 0, Vector3.ZERO)]
	var saw_wall := false
	var touched := false
	for frame in 180:
		var offset := TARGET - _player.global_position
		offset.y = 0
		offset = offset.normalized()
		_axis(JOY_AXIS_LEFT_X, offset.x)
		_axis(JOY_AXIS_LEFT_Y, offset.z)
		await physics_frame
		if frame == 0 or (frame + 1) % 30 == 0 or (_player.is_on_wall() and not saw_wall):
			approach_trace.append(_approach_sample("approach", frame + 1, offset))
			saw_wall = saw_wall or _player.is_on_wall()
		for index in _player.get_slide_collision_count():
			if _player.get_slide_collision(index).get_collider() == trunk:
				touched = true
		if touched:
			break
	_axis(JOY_AXIS_LEFT_X, 0)
	_axis(JOY_AXIS_LEFT_Y, 0)
	for frame in 8: await physics_frame
	var offer: Dictionary = _prompt.interaction_offer(_player.global_position)
	print("PHYSICAL tree-contact player=", _player.global_position, " grounded=", _player.is_on_floor(),
		" touched_actual_trunk=",touched,
		" prompt=", _prompt.global_position, " distance=", _player.global_position.distance_to(_prompt.global_position),
		" radius=", _prompt.radius, " own_offer=", offer, " winner=", _arbiter.winner(),
		" contacts=", _contacts(), " unsticks=", _player.get("_unstick_count"))
	# Flush outside the moving sample; these observations cannot admit success.
	for sample: Dictionary in approach_trace:
		print("APPROACH cached sample=", sample)
	await process_frame
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	for frame in 3: await physics_frame
	await process_frame
	press = InputEventAction.new()
	press.action = "interact"
	Input.parse_input_event(press)
	for frame in 5: await physics_frame
	var success: bool = _activated and _arbiter.winning_provider() == _prompt and _player.is_on_floor() \
		and touched and int(_player.get("_unstick_count")) == 0
	print("RESULT exact physical prompt activated=", _activated, " success=", success,
		" mode=", "current production", " no campaign receipt claimed")
	world.queue_free()
	await process_frame
	quit(0 if success else 1)

func _approach_sample(stage: String, frame: int, requested_stick: Vector3) -> Dictionary:
	# physics_frame resumes before the next player step; contact/wanted fields
	# describe the latest completed controller step, not the new stick request.
	var contacts := []
	for index in _player.get_slide_collision_count():
		var hit := _player.get_slide_collision(index)
		contacts.append({"body": str(hit.get_collider().name),
			"position": hit.get_position(), "normal": hit.get_normal(), "depth": hit.get_depth()})
	var owner: Node = INPUT_OWNER.current(self)
	return {"stage": stage, "approach_frame": frame, "physics_frame": Engine.get_physics_frames(),
		"position": _player.global_position, "velocity": _player.velocity,
		"requested_stick": requested_stick,
		"resolved_stick": Input.get_vector("move_left", "move_right", "move_forward", "move_back"),
		"last_controller_wanted": _player.get("_wanted_dir"),
		"deflect_left": _player.get("_deflect_left"), "deflect": _player.get("_deflect"),
		"locomotion_enabled": _player.get("_locomotion_enabled"), "carried": _player.get("_carried"),
		"input_owner": str(owner.name) if owner != null else "",
		"grounded": _player.is_on_floor(), "wall": _player.is_on_wall(),
		"floor_stop_on_slope": _player.floor_stop_on_slope,
		"floor_constant_speed": _player.floor_constant_speed,
		"contacts": contacts, "unsticks": _player.get("_unstick_count")}

func _build_floor(world: Node3D, field: RefCounted) -> void:
	var faces := PackedVector3Array()
	for x in range(-7, 7):
		for z in range(-7, 7):
			var points: Array[Vector3] = []
			for offset in [Vector2(x,z), Vector2(x+1,z), Vector2(x,z+1), Vector2(x+1,z+1)]:
				var at := Vector3(TARGET.x+offset.x, 0, TARGET.z+offset.y)
				at.y = field.height_at(at.x, at.z)
				points.append(at)
			for index in [0, 1, 2, 1, 3, 2]: faces.append(points[index])
	var body := StaticBody3D.new()
	body.name = "CanonicalLocalTerrain"
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)

func _axis(axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)

func _contacts() -> Array:
	var rows := []
	for index in _player.get_slide_collision_count():
		var hit := _player.get_slide_collision(index)
		rows.append({"body": str(hit.get_collider().name), "normal": hit.get_normal()})
	return rows
