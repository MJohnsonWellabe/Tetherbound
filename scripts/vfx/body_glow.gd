extends Node

## W09-VFX (CL-A2). A glow on a creature's OWN body: the brief white flash of
## being struck, and the slower gold rim of a level-up. Both are this node with
## a different `mode`.
##
## Mechanism: `GeometryInstance3D.material_overlay` on every MeshInstance3D
## the body draws (its loaded model under `model_pivot()`, or the Body/Head
## capsule fallback), carrying shaders/vfx_body_glow.gdshader. An overlay is
## drawn as an extra pass over the mesh's own materials and is PER INSTANCE,
## which is the whole reason it is used instead of touching the materials:
## creature_body.gd shares one material per species/colourway across every
## live body (`_shared_variant_material`, `_swapped_material`), so brightening
## a material would flash every bramblebun in the cluster when one is hit.
##
## Nothing in creature_body.gd is edited or called beyond reading
## `model_pivot()`. The overlay slot was free on every creature (no other
## system sets it; build_placer.gd uses it on buildings), and an existing
## overlay on a mesh is left alone rather than replaced.
##
## Physics-clocked with a public `advance()`, like vfx_burst.gd, for the same
## reasons. Finishing clears every overlay it set and frees the node; if the
## body is freed first this dies with it, and a mesh that vanished mid-flash is
## skipped rather than reached for.

const SHADER := preload("res://shaders/vfx_body_glow.gdshader")

enum Mode { FLASH, PULSE }

var _mode: int = Mode.FLASH
var _duration: float = 0.16
var _strength: float = 0.85
var _life: float = 0.0
var _finished: bool = false
var _material: ShaderMaterial = null
## The MeshInstance3D nodes this glow set an overlay on. Only those are restored.
var _meshes: Array = []


## `body` is a creature body (or any Node3D with MeshInstance3D descendants).
## Returns null when the body has nothing to draw over.
static func attach(body: Node3D, mode: int, spec: Dictionary, strength: float) -> Node:
	if body == null or not is_instance_valid(body):
		return null
	var glow := new()
	glow.name = "BodyGlow"
	glow._mode = mode
	glow._duration = maxf(float(spec.get("duration", 0.16)), 0.02)
	glow._strength = strength
	glow._material = ShaderMaterial.new()
	glow._material.shader = SHADER
	glow._material.set_shader_parameter("colour", Color(str(spec.get("colour", "#fff1d6"))))
	glow._material.set_shader_parameter("rim_power", float(spec.get("rim_power", 2.0)))
	glow._material.set_shader_parameter("flat_mix", float(spec.get("flat_mix", 0.5)))
	glow._material.set_shader_parameter("strength", 0.0)
	glow._collect_meshes(body)
	if glow._meshes.is_empty():
		glow.free()
		return null
	for mesh: MeshInstance3D in glow._meshes:
		mesh.material_overlay = glow._material
	body.add_child(glow)
	glow._apply(0.0)
	return glow


func finished() -> bool:
	return _finished


func mesh_count() -> int:
	return _meshes.size()


## For the perf probe only: lift the overlay off every mesh (or put it back)
## without ending the glow, so one paused frame can be counted with and
## without this effect and nothing else different.
func suspend(off: bool) -> void:
	for mesh: Variant in _meshes:
		if is_instance_valid(mesh) and mesh is MeshInstance3D:
			(mesh as MeshInstance3D).material_overlay = null if off else _material


## Every drawable MeshInstance3D of the body: the loaded model under the pivot,
## or the capsule fallback nodes directly under the body. A mesh that already
## carries someone else's overlay is left to them.
func _collect_meshes(body: Node3D) -> void:
	var roots: Array = []
	if body.has_method("model_pivot"):
		var pivot: Variant = body.call("model_pivot")
		if pivot is Node:
			roots.append(pivot)
	roots.append(body)
	for root: Node in roots:
		_walk(root, root != body)


func _walk(node: Node, deep: bool) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh != null and mesh.material_overlay == null and not _meshes.has(mesh):
			_meshes.append(mesh)
	if not deep:
		# Directly under the body itself only the capsule fallback nodes count;
		# the model pivot was walked in full already, and anything else hung
		# off the body (auras, shadows, this node's siblings) is not the body.
		for child in node.get_children():
			if child is MeshInstance3D and (child.name == "Body" or child.name == "Head"):
				_walk(child, false)
		return
	for child in node.get_children():
		_walk(child, true)


func _physics_process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if _finished:
		return
	_life += delta
	if _life >= _duration:
		_finish()
		return
	_apply(_life / _duration)


func _apply(u: float) -> void:
	var envelope: float
	match _mode:
		Mode.PULSE:
			# In and out, peaking mid-life: a glow that swells and settles.
			envelope = sin(clampf(u, 0.0, 1.0) * PI)
		_:
			# Full on at contact, gone fast: a flash.
			envelope = pow(1.0 - clampf(u, 0.0, 1.0), 1.5)
	_material.set_shader_parameter("strength", _strength * envelope)


func _finish() -> void:
	_finished = true
	for mesh: Variant in _meshes:
		# A model rebuild can free a mesh while its glow still lives on the body.
		# Validate before even querying its type: `is` on a freed object errors.
		if is_instance_valid(mesh) and mesh is MeshInstance3D and (mesh as MeshInstance3D).material_overlay == _material:
			(mesh as MeshInstance3D).material_overlay = null
	_meshes.clear()
	queue_free()
