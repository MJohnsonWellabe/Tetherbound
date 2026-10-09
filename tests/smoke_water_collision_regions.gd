extends SceneTree

## Real native floor comparisons after executing the production install path.
## Original full body vs cloned region bodies occupy identical coordinates;
## collision layers isolate queries without changing transforms.
const REGIONS := preload("res://scripts/world/water_collision_regions.gd")
var _checks := 0
var _failures := 0
var _rays := 0
var _reference: RID
var _reference_shapes: Array[RID] = []

class CollisionRef extends RefCounted:
	var body: RID
	func get_rid() -> RID:
		return body

class TerrainFixture extends Node3D:
	var collision := CollisionRef.new()
	var shapes: Array[RID] = []
	var physics_material: PhysicsMaterial
	var collision_mode := 3:
		set(value):
			collision_mode = value
			if value == 0 and collision.body.is_valid():
				PhysicsServer3D.free_rid(collision.body)
				collision.body = RID()
				for shape: RID in shapes:
					PhysicsServer3D.free_rid(shape)
				shapes.clear()

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		if _failures <= 10:
			print("FAIL: " + label)

func _run() -> void:
	var terrain := TerrainFixture.new()
	root.add_child(terrain)
	terrain.physics_material = PhysicsMaterial.new()
	terrain.physics_material.friction = 0.6
	terrain.physics_material.rough = true
	terrain.physics_material.bounce = 0.2
	terrain.physics_material.absorbent = true
	_reference = _body(terrain, 1)
	terrain.collision.body = _body(terrain, 2)
	for rz in range(-1, 2):
		for rx in range(-1, 2):
			var values := PackedFloat32Array()
			values.resize(17 * 17)
			for z in 17:
				for x in 17:
					var gx := rx * 16 + x
					var gz := rz * 16 + z
					values[16 - z + x * 17] = 0.01 * gx * gz + 0.17 * gx - 0.23 * gz
			var shape_data := {"width": 17, "depth": 17, "heights": values,
				"min_height": -30.0, "max_height": 30.0}
			var transform := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(rx * 16 + 8, 0, rz * 16 + 8))
			for original: bool in [true, false]:
				var shape := PhysicsServer3D.heightmap_shape_create()
				PhysicsServer3D.shape_set_data(shape, shape_data)
				if original:
					_reference_shapes.append(shape)
				else:
					terrain.shapes.append(shape)
				PhysicsServer3D.body_add_shape(_reference if original else terrain.collision.body, shape, transform)
	var regions := REGIONS.new()
	terrain.add_child(regions)
	_check(await regions.install(terrain, 1.0), "production install succeeds")
	_check(terrain.collision_mode == 0 and not terrain.collision.body.is_valid(), "original RIDs destroyed before activating clones")
	_check(regions.installed and regions.region_count == 9, "all nine distant signed-coordinate regions remain resident")
	var bodies: Array[RID] = regions.get("_bodies")
	_check(bodies.size() == 9, "one body per unchanged original region")
	for index in bodies.size():
		var body := bodies[index]
		_check(PhysicsServer3D.body_get_shape_count(body) == 1, "single original shape per body")
		var shape := PhysicsServer3D.body_get_shape(body, 0)
		var data: Dictionary = PhysicsServer3D.shape_get_data(shape)
		var expected: Dictionary = PhysicsServer3D.shape_get_data(_reference_shapes[index])
		_check(data == expected, "exact native shape data including dimensions/heights/bounds")
		_check(PhysicsServer3D.body_get_shape_transform(body, 0) == PhysicsServer3D.body_get_shape_transform(_reference, index), "exact native shape transform")
		_check(PhysicsServer3D.body_get_collision_layer(body) == 2 and PhysicsServer3D.body_get_collision_mask(body) == 5, "layer/mask preserved")
		_check(PhysicsServer3D.body_get_collision_priority(body) == PhysicsServer3D.body_get_collision_priority(_reference), "priority preserved")
		_check(is_equal_approx(PhysicsServer3D.body_get_param(body, PhysicsServer3D.BODY_PARAM_FRICTION), -0.6), "rough friction preserved")
		_check(is_equal_approx(PhysicsServer3D.body_get_param(body, PhysicsServer3D.BODY_PARAM_BOUNCE), -0.2), "absorbing bounce preserved")
	await physics_frame
	await physics_frame
	var state := terrain.get_world_3d().direct_space_state
	for z in range(-16, 32):
		for x in range(-16, 32):
			for fraction: Vector2 in [Vector2.ZERO, Vector2(0.25, 0.63), Vector2(0.75, 0.33)]:
				var point := Vector3(x + fraction.x, 30, z + fraction.y)
				var a := state.intersect_ray(PhysicsRayQueryParameters3D.create(point, point - Vector3(0, 60, 0), 1))
				var b := state.intersect_ray(PhysicsRayQueryParameters3D.create(point, point - Vector3(0, 60, 0), 2))
				_rays += 1
				_check(a.is_empty() == b.is_empty(), "ray presence %s" % point)
				if not a.is_empty() and not b.is_empty():
					_check(a.position == b.position, "exact floor position %s" % point)
					_check(a.normal == b.normal, "exact floor normal %s" % point)
					_check(a.collider_id == b.collider_id, "collider identity %s" % point)
	terrain.physics_material.friction = 0.9
	for body: RID in bodies:
		_check(is_equal_approx(PhysicsServer3D.body_get_param(body, PhysicsServer3D.BODY_PARAM_FRICTION), -0.9), "live material changes preserved")
	regions.queue_free()
	await process_frame
	PhysicsServer3D.free_rid(_reference)
	for shape: RID in _reference_shapes:
		PhysicsServer3D.free_rid(shape)
	terrain.queue_free()
	await process_frame
	print("Water regional collider clone: %d checks, %d native ray pairs, %d failures" % [_checks, _rays, _failures])
	quit(0 if _failures == 0 and _rays == 6912 else 1)

func _body(terrain: Node3D, layer: int) -> RID:
	var body := PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_attach_object_instance_id(body, terrain.get_instance_id())
	PhysicsServer3D.body_set_collision_layer(body, layer)
	PhysicsServer3D.body_set_collision_mask(body, 5)
	PhysicsServer3D.body_set_collision_priority(body, 1.7)
	PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_FRICTION, -0.6)
	PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_BOUNCE, -0.2)
	PhysicsServer3D.body_set_space(body, terrain.get_world_3d().space)
	return body
