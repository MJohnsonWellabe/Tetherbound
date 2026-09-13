extends SceneTree

## Regression for the OWNER-0912 Meadowhart bare-body crash. A full Meadows
## respawn boot creates ordinary and alpha bodies back-to-back; the original
## adapter retained one large stripped ArrayMesh per transient source instance,
## then apply_size_multiplier destroyed and rebuilt the live skinned model.
## Exercise that exact installed-GLB lifecycle repeatedly without rendering.
##
##   godot --headless --path . --script tests/smoke_meadowhart_alpha_rebuild_0912.gd

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const ALPHA_SCALE := 1.35
const CYCLES := 24

var _failures: Array[String] = []
var _shared_bare_mesh_id := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for cycle in CYCLES:
		var body := CREATURE_SCENE.instantiate() as CharacterBody3D
		body.name = "MeadowhartAlphaRebuild_%02d" % cycle
		body.set_script(CREATURE_BODY)
		root.add_child(body)
		body.call("setup", "meadowhart")
		await process_frame
		_require(bool(body.call("meadowhart_bare_body_present")),
			"cycle %d ordinary body is not the repaired installed GLB" % cycle)
		var ordinary_height := float(body.call("body_height"))
		var ordinary_radius := float(body.call("body_radius"))
		var ordinary_mesh := _skinned_mesh(body)
		_require(ordinary_mesh != null, "cycle %d ordinary skin is missing" % cycle)
		var ordinary_mesh_id := ordinary_mesh.mesh.get_instance_id() if ordinary_mesh != null else 0
		if _shared_bare_mesh_id == 0:
			_shared_bare_mesh_id = ordinary_mesh_id
		_require(ordinary_mesh_id == _shared_bare_mesh_id,
			"cycle %d retained a second stripped ArrayMesh" % cycle)

		body.call("apply_size_multiplier", ALPHA_SCALE)
		await process_frame
		var alpha_mesh := _skinned_mesh(body)
		_require(alpha_mesh != null, "cycle %d alpha skin is missing" % cycle)
		_require(alpha_mesh != null and alpha_mesh.mesh.get_instance_id() == ordinary_mesh_id,
			"cycle %d alpha sizing rebuilt the live skinned ArrayMesh" % cycle)
		_require(is_equal_approx(float(body.call("body_height")), ordinary_height * ALPHA_SCALE),
			"cycle %d alpha height did not scale" % cycle)
		_require(is_equal_approx(float(body.call("body_radius")), ordinary_radius * ALPHA_SCALE),
			"cycle %d alpha radius did not scale" % cycle)
		var collision := body.get_node_or_null(^"Collision") as CollisionShape3D
		_require(collision != null and collision.shape is CapsuleShape3D,
			"cycle %d alpha collider is missing" % cycle)
		body.free()
		await process_frame

	if _failures.is_empty():
		print("meadowhart alpha rebuild: OK -- %d installed-GLB setup/alpha cycles shared one bare mesh and kept collider/art size aligned." % CYCLES)
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _skinned_mesh(body: Node) -> MeshInstance3D:
	var model := body.get_node_or_null(^"Model")
	if model == null:
		return null
	for candidate: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance != null and instance.mesh != null and instance.skin != null:
			return instance
	return null


func _require(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
