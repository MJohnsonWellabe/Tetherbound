extends Node3D

## A generic placeable build piece: one glTF module, one box collider, no
## interaction. `camp.gd` stays its own hand-authored script because it
## carries the rest/craft prompts; every other `data/items/buildables.json`
## entry is plain geometry, so this one script places any of them rather
## than each piece needing its own copy of camp.gd's mesh/collision code.
##
## The Medieval Village MegaKit ships each module as a glTF scene (a node
## tree, not a bare `Mesh`), the same shape `building_prefabs.gd` already
## unpacks for `EV6`'s settlement pieces — `load()` on a `.gltf` returns a
## `PackedScene`, so it has to be instantiated rather than dropped straight
## onto a `MeshInstance3D.mesh`.

var _model: Node3D = null


## The see-through preview the placer drags around. No collision.
func build_ghost(mesh_path: String) -> void:
	_spawn(mesh_path, false)


## The real thing: solid and collidable.
func build_real(mesh_path: String) -> void:
	_spawn(mesh_path, true)


func _spawn(mesh_path: String, solid: bool) -> void:
	if not ResourceLoader.exists(mesh_path):
		push_warning("build piece missing: %s" % mesh_path)
		return
	var scene: PackedScene = load(mesh_path)
	_model = scene.instantiate() as Node3D
	add_child(_model)
	if not solid:
		return

	var combined := AABB()
	var first := true
	for mesh_instance in _mesh_instances(_model):
		var local_aabb := mesh_instance.mesh.get_aabb()
		var world_aabb := mesh_instance.transform * local_aabb
		combined = world_aabb if first else combined.merge(world_aabb)
		first = false
	if first:
		return

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = combined.size
	shape.shape = box
	body.add_child(shape)
	body.position = combined.get_center()
	add_child(body)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


## D34/spec 13: three ghost states, each its own colour. `VALID` legal to
## plant, `INVALID` outright blocked (slope, overlap, cost), `UNSUPPORTED`
## the amber middle ground — snapped against a real neighbour but still
## blocked for some other reason, so the player sees "close, but not this"
## rather than the same flat red a piece nowhere near a neighbour gets.
const STATE_VALID := &"valid"
const STATE_INVALID := &"invalid"
const STATE_UNSUPPORTED := &"unsupported"

## One `StandardMaterial3D` per state, built once and reused by every ghost —
## `tint_ghost`/`tint_ghost_state` used to `StandardMaterial3D.new()` on every
## call, which with `_show_ghost` running every `_physics_process` frame was
## an allocation a frame for as long as a piece stayed armed. A `static Dictionary`
## rather than three named statics so a new state is one new match arm, not a
## new var plus a new branch everywhere the var is read.
static var _state_materials: Dictionary = {}


static func _material_for_state(state: StringName) -> StandardMaterial3D:
	if _state_materials.has(state):
		return _state_materials[state]
	var colour: Color
	match state:
		STATE_INVALID:
			colour = Color(UITokens.DANGER, 0.45)
		STATE_UNSUPPORTED:
			colour = Color(UITokens.WARNING, 0.45)
		_:
			# Valid: UITokens.TEAL leaned toward green rather than the raw teal —
			# "valid to place" reads as green in every other part of this HUD
			# language (HP_GREEN, SUCCESS), teal alone would not say "go."
			colour = Color(UITokens.TEAL.lerp(Color(0.35, 0.9, 0.4), 0.6), 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_state_materials[state] = material
	return material


## The three-state ghost tint (see above), applied to every mesh in the
## module since some are more than one part (a door and its handle, a fence
## rail and its posts).
func tint_ghost_state(state: StringName) -> void:
	if _model == null or not is_instance_valid(_model):
		return
	var material := _material_for_state(state)
	for mesh_instance in _mesh_instances(_model):
		mesh_instance.material_override = material


## Wrapper kept for callers that only ever had a legal/not-legal boolean
## (camp.gd, storage_container.gd's own hand-authored ghosts, and any test
## exercising this file directly) — `tint_ghost_state` is the one that knows
## about the amber middle state.
func tint_ghost(ok: bool) -> void:
	tint_ghost_state(STATE_VALID if ok else STATE_INVALID)
