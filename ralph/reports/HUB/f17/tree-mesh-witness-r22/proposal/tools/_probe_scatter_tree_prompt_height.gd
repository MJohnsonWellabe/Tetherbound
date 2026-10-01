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
const BANK_TURN_FRAMES := 26
const MAX_BANK_TURNS := 3
var _player: CharacterBody3D
var _arbiter: Node
var _prompt: Node3D
var _activated := false
var _geometry_faces := PackedVector3Array()

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
	# One full-precision geometry witness before the unchanged original walk.
	print("TREE_GEOMETRY ", JSON.stringify(_fixture_geometry(world, trunk, placement, layer, order), "", true, true))
	var saw_wall := false
	var terrain := world.get_node("CanonicalLocalTerrain") as StaticBody3D
	var bank_left := 0
	var bank_direction := Vector3.ZERO
	var bank_turns: Array[Dictionary] = []
	var touched := false
	for frame in 180:
		var offset := TARGET - _player.global_position
		offset.y = 0
		offset = offset.normalized()
		var steering := offset
		if bank_left == 0 and bank_turns.size() < MAX_BANK_TURNS:
			var normal := _terrain_bank_normal(offset, terrain)
			var tangent := bank_tangent(offset, normal, bank_direction)
			if tangent != Vector3.ZERO:
				bank_direction = tangent
				bank_left = BANK_TURN_FRAMES
				bank_turns.append({"approach_frame": frame + 1, "player": _player.global_position,
					"cached_normal": normal, "requested_tangent": tangent})
		if bank_left > 0:
			steering = bank_direction
			bank_left -= 1
		_axis(JOY_AXIS_LEFT_X, steering.x)
		_axis(JOY_AXIS_LEFT_Y, steering.z)
		await physics_frame
		if frame == 0 or (frame + 1) % 30 == 0 or (_player.is_on_wall() and not saw_wall):
			approach_trace.append(_approach_sample("approach", frame + 1, steering))
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
	print("TERRAIN stick turns=", bank_turns, " within_original_180_frames=true")
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

func _terrain_bank_normal(wanted: Vector3, terrain: StaticBody3D) -> Vector3:
	if not _player.is_on_floor() or not _player.is_on_wall():
		return Vector3.ZERO
	for index in _player.get_slide_collision_count():
		var hit := _player.get_slide_collision(index)
		if hit.get_collider() != terrain:
			continue
		var normal := hit.get_normal()
		if normal.y > 0.0 and normal.y < cos(_player.floor_max_angle) \
				and Vector3(normal.x, 0.0, normal.z).dot(wanted) < -0.0001:
			return normal
	return Vector3.ZERO


## A provisional horizontal stick request along an observed wall. Collision,
## actual trunk contact and the unchanged success conjunction remain decisive.
static func bank_tangent(wanted: Vector3, normal: Vector3, previous: Vector3 = Vector3.ZERO) -> Vector3:
	for value: float in [wanted.x, wanted.y, wanted.z, normal.x, normal.y, normal.z,
			previous.x, previous.y, previous.z]:
		if not is_finite(value):
			return Vector3.ZERO
	var tangent := Vector3(-normal.z, 0.0, normal.x)
	if tangent.length_squared() < 0.0001 or Vector2(wanted.x, wanted.z).length_squared() < 0.0001:
		return Vector3.ZERO
	tangent = tangent.normalized()
	# Keep the first side through bounded turns; do not oscillate as the bank
	# normal changes. The first turn retains the most requested target heading.
	var reference := previous if previous.length_squared() >= 0.0001 else wanted
	if tangent.dot(reference) < 0.0:
		tangent = -tangent
	return tangent

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
	_geometry_faces = faces.duplicate() # Freeze the actual construction array; never resample.


## Metadata only. Incomplete capture cannot change movement or native success.
func _fixture_geometry(world: Node3D, trunk: StaticBody3D, placement: Dictionary, layer: String, order: int) -> Dictionary:
	var record := {"acceptance": false, "complete": false, "mesh_frozen_at": "fixture_construction",
		"registered_state_at": "settled_before_original_walk", "native_queries_added": 0,
		"expected_vertices": 225, "expected_triangles": 392, "target": _geometry_vector(TARGET),
		"kept_record": {"layer": layer, "order": order, "model": str(placement.model),
			"position": _geometry_vector(placement.position), "yaw": float(placement.yaw), "scale": float(placement.scale),
			"normal": _geometry_vector(placement.normal) if placement.has("normal") else null},
		"physics_frame": Engine.get_physics_frames(),
		"direct_space_state_class": world.get_world_3d().direct_space_state.get_class()}
	if _geometry_faces.size() != 1176:
		record["incomplete"] = "unexpected construction face count"
		return record
	var ids := {}
	var vertices: Array = []
	var indices: Array = []
	for vertex: Vector3 in _geometry_faces:
		if not vertex.is_finite():
			record["incomplete"] = "nonfinite construction vertex"
			return record
		if not ids.has(vertex):
			if vertices.size() == 225:
				record["incomplete"] = "construction vertex bound exceeded"
				return record
			ids[vertex] = vertices.size()
			vertices.append(_geometry_vector(vertex))
		indices.append(int(ids[vertex]))
	if vertices.size() != 225:
		record["incomplete"] = "unexpected distinct construction vertex count"
		return record
	var triangles: Array = []
	for index in 392:
		triangles.append([indices[index * 3], indices[index * 3 + 1], indices[index * 3 + 2]])
	var terrain := world.get_node("CanonicalLocalTerrain") as StaticBody3D
	var terrain_geometry := _registered_geometry(terrain, terrain.get_child(0) as CollisionShape3D, PhysicsServer3D.SHAPE_CONCAVE_POLYGON)
	var trunk_geometry := _registered_geometry(trunk, trunk.get_child(0) as CollisionShape3D, PhysicsServer3D.SHAPE_CYLINDER)
	var player_geometry := _registered_geometry(_player, _player.get_node("Collision") as CollisionShape3D, PhysicsServer3D.SHAPE_CAPSULE)
	record["mesh"] = {"vertices": vertices, "triangle_indices": triangles, "terrain": terrain_geometry,
		"global_transform": terrain_geometry.get("shape_world_pose", {})}
	record["trunk"] = trunk_geometry
	record["settled_start"] = {"player": player_geometry, "position": _geometry_vector(_player.global_position),
		"velocity": _geometry_vector(_player.velocity), "grounded": _player.is_on_floor(), "wall": _player.is_on_wall(),
		"floor_max_angle": _player.floor_max_angle, "safe_margin": _player.safe_margin,
		"floor_snap_length": _player.floor_snap_length, "unsticks": int(_player.get("_unstick_count"))}
	record["prompt"] = {"path": str(_prompt.get_path()), "global_transform": _geometry_transform(_prompt.global_transform),
		"radius": _prompt.radius} # Read height/radius only; no new offer or LOS query.
	record["complete"] = terrain_geometry.get("complete", false) and trunk_geometry.get("complete", false) \
		and player_geometry.get("complete", false) and record.prompt.global_transform.finite \
		and _player.global_position.is_finite() and _player.velocity.is_finite()
	return record


func _registered_geometry(body: PhysicsBody3D, collision: CollisionShape3D, expected_type: int) -> Dictionary:
	var record := {"complete": false, "server_disabled_state_observed": false,
		"disabled_state_source": "CollisionShape3D.disabled; no public server getter"}
	if body == null or collision == null or collision.shape == null:
		return record
	var rid := body.get_rid()
	if not rid.is_valid() or PhysicsServer3D.body_get_shape_count(rid) != 1:
		return record
	var shape := PhysicsServer3D.body_get_shape(rid, 0)
	if shape != collision.shape.get_rid() or PhysicsServer3D.shape_get_type(shape) != expected_type:
		return record
	var raw: Variant = PhysicsServer3D.shape_get_data(shape)
	if not raw is Dictionary:
		return record
	var data: Dictionary = raw
	if expected_type == PhysicsServer3D.SHAPE_CONCAVE_POLYGON:
		if not data.get("faces") is PackedVector3Array or data.faces.size() != 1176:
			return record
		record["shape_data"] = {"face_vertices": 1176, "backface_collision": data.get("backface_collision"),
			"faces_match_construction": data.faces == _geometry_faces}
		if data.faces != _geometry_faces:
			return record
	else:
		if not data.has("height") or not data.has("radius"):
			return record
		var height := float(data.height)
		var radius := float(data.radius)
		if not is_finite(height) or not is_finite(radius) or height <= 0.0 or radius <= 0.0:
			return record
		if expected_type == PhysicsServer3D.SHAPE_CAPSULE and height < 2.0 * radius:
			return record
		record["shape_data"] = {"height": height, "radius": radius,
			"resource_height": float(collision.shape.get("height")), "resource_radius": float(collision.shape.get("radius"))}
		if height != record.shape_data.resource_height or radius != record.shape_data.resource_radius:
			return record
	var body_pose: Transform3D = PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)
	var local_pose := PhysicsServer3D.body_get_shape_transform(rid, 0)
	record.merge({"path": str(body.get_path()), "body_rid": str(rid), "shape_rid": str(shape), "shape_index": 0,
		"shape_type": expected_type, "shape_node_disabled": collision.disabled,
		"body_pose": _geometry_transform(body_pose), "shape_local_pose": _geometry_transform(local_pose),
		"shape_world_pose": _geometry_transform(body_pose * local_pose), "shape_node_world_pose": _geometry_transform(collision.global_transform),
		"collision_layer": PhysicsServer3D.body_get_collision_layer(rid), "collision_mask": PhysicsServer3D.body_get_collision_mask(rid),
		"space_rid": str(PhysicsServer3D.body_get_space(rid))})
	record["complete"] = record.body_pose.finite and record.shape_local_pose.finite and record.shape_world_pose.finite \
		and body_pose == body.global_transform and local_pose == collision.transform and not collision.disabled \
		and PhysicsServer3D.body_get_space(rid) == body.get_world_3d().space \
		and PhysicsServer3D.body_get_shape_count(rid) == 1 and PhysicsServer3D.body_get_shape(rid, 0) == shape
	return record


func _geometry_vector(value: Vector3) -> Array:
	if not value.is_finite():
		return []
	return [value.x, value.y, value.z]


func _geometry_transform(value: Transform3D) -> Dictionary:
	if not value.origin.is_finite() or not value.basis.x.is_finite() or not value.basis.y.is_finite() or not value.basis.z.is_finite():
		return {"finite": false}
	return {"finite": true, "origin": _geometry_vector(value.origin), "basis_x": _geometry_vector(value.basis.x),
		"basis_y": _geometry_vector(value.basis.y), "basis_z": _geometry_vector(value.basis.z),
		"basis_scale": [value.basis.x.length(), value.basis.y.length(), value.basis.z.length()], "basis_determinant": value.basis.determinant()}

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
