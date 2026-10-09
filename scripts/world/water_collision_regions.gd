extends Node

## All baked Tidewake regions stay resident. Split only static-body ownership;
## copy the existing native shapes and transforms without re-sampling terrain.
var _bodies: Array[RID] = []
var _shapes: Array[RID] = []
var installed := false
var region_count := 0
var _material: PhysicsMaterial


func install(terrain: Node3D, budget_ms: float) -> bool:
	if int(terrain.get("collision_mode")) != 3:
		return false
	var collision: Object = terrain.get("collision")
	if collision == null:
		return false
	var original: RID = collision.call("get_rid")
	if not await prepare(original, terrain, budget_ms):
		return false
	if not is_instance_valid(terrain) or not terrain.is_inside_tree():
		_release()
		return false
	_material = terrain.get("physics_material") as PhysicsMaterial
	if _material != null:
		_material.changed.connect(_sync_material)
	# Clones have no physics space until this atomic swap. The original floor
	# stays active during preparation and every intervening physics tick.
	terrain.set("collision_mode", 0)
	if int(terrain.get("collision_mode")) != 0:
		_release()
		return false
	activate(terrain.get_world_3d().space)
	return true


func prepare(original: RID, owner: Node3D, budget_ms: float) -> bool:
	if not original.is_valid() or not _bodies.is_empty():
		return false
	var count := PhysicsServer3D.body_get_shape_count(original)
	if count == 0:
		return false
	for index in count:
		var source := PhysicsServer3D.body_get_shape(original, index)
		if PhysicsServer3D.shape_get_type(source) != PhysicsServer3D.SHAPE_HEIGHTMAP:
			return false
	var deadline := Time.get_ticks_usec() + int(maxf(1.0, budget_ms) * 1000.0)
	for index in count:
		var source := PhysicsServer3D.body_get_shape(original, index)
		var shape := PhysicsServer3D.heightmap_shape_create()
		PhysicsServer3D.shape_set_data(shape, PhysicsServer3D.shape_get_data(source))
		_shapes.append(shape)
		var body := PhysicsServer3D.body_create()
		_bodies.append(body)
		PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
		PhysicsServer3D.body_attach_object_instance_id(body, owner.get_instance_id())
		PhysicsServer3D.body_set_collision_layer(body, PhysicsServer3D.body_get_collision_layer(original))
		PhysicsServer3D.body_set_collision_mask(body, PhysicsServer3D.body_get_collision_mask(original))
		PhysicsServer3D.body_set_collision_priority(body, PhysicsServer3D.body_get_collision_priority(original))
		for parameter in [PhysicsServer3D.BODY_PARAM_FRICTION, PhysicsServer3D.BODY_PARAM_BOUNCE]:
			PhysicsServer3D.body_set_param(body, parameter, PhysicsServer3D.body_get_param(original, parameter))
		PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM,
			PhysicsServer3D.body_get_state(original, PhysicsServer3D.BODY_STATE_TRANSFORM))
		PhysicsServer3D.body_add_shape(body, shape, PhysicsServer3D.body_get_shape_transform(original, index))
		if Time.get_ticks_usec() >= deadline:
			await get_tree().process_frame
			if not is_instance_valid(owner) or not owner.is_inside_tree():
				_release()
				return false
			deadline = Time.get_ticks_usec() + int(maxf(1.0, budget_ms) * 1000.0)
	region_count = count
	return true


func activate(space: RID) -> void:
	for body: RID in _bodies:
		PhysicsServer3D.body_set_space(body, space)
	installed = true


func _sync_material() -> void:
	if _material == null:
		return
	for body: RID in _bodies:
		PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_FRICTION,
			_material.friction * (-1.0 if _material.rough else 1.0))
		PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_BOUNCE,
			_material.bounce * (-1.0 if _material.absorbent else 1.0))


func _release() -> void:
	if _material != null and _material.changed.is_connected(_sync_material):
		_material.changed.disconnect(_sync_material)
	_material = null
	for body: RID in _bodies:
		PhysicsServer3D.free_rid(body)
	_bodies.clear()
	for shape: RID in _shapes:
		PhysicsServer3D.free_rid(shape)
	_shapes.clear()
	installed = false
	region_count = 0


func _exit_tree() -> void:
	_release()
