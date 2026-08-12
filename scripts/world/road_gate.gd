extends Node3D

## SA7: a simple physical gate on the road out of the village, with an easy
## key nearby. Owner directive, 2026-08-11 — near-field and low-stakes, so the
## player understands early that gated things have keys, well before `SC14`'s
## real combat-gated crossing hours in.
##
## Reuses the exact fence model and collider-from-AABB approach village.gd
## already established for every other structure in the settlement, so this
## reads as the same rustic fencing the player has already seen rather than a
## new prop family (D24). Locked/open are two static poses of the one mesh —
## a closed panel across the road vs. the same panel swung parallel to it —
## since no animation rig exists for it and grandpa_house.gd already sets the
## precedent of a gate with no animation, its feedback carried by something
## else (there, the conversation; here, the panel's own re-pose plus a line
## of dialogue).
##
## EV6 moved the settlement's whole fence family from the farm pack's loose
## `.obj` meshes to the Medieval Village MegaKit's `.gltf` modules (see
## `building_prefabs.json`'s `fence_run`, which replaced the same
## `Fence`/`Fence2` models this file used to load) but missed this file,
## leaving it pointing at a model EV6 deleted. `Prop_WoodenFence_Single` is
## the same segment `fence_run`'s own middle panel uses. A `.gltf` module is a
## scene, not a bare mesh, so this now instantiates and measures its AABB the
## way `props.gd::_place` does for every other kit-sourced scene, rather than
## assigning a `Mesh` resource straight onto a `MeshInstance3D`.

const BUILDINGS_DIR := "res://assets/buildings/quaternius_medieval"
const MODEL := "Prop_WoodenFence_Single"
const INTERACTABLE := preload("res://scripts/world/interactable.gd")

const KEY_ITEM_ID := "castle_gate_key"
const LOCKED_CONVERSATION := "road_gate_locked"
const UNLOCKED_CONVERSATION := "road_gate_unlocked"

var _mesh: Node3D = null
var _shape: CollisionShape3D = null
var _prompt: Node3D = null
var _lock: MeshInstance3D = null
var _open := false


## `world` only for `ground_height_at` — the same duck-typed climb
## village.gd's own `_ground_height` uses, so this does not need a direct
## reference to playground_world.gd.
func build(world: Node3D, at: Vector2, yaw_deg: float) -> void:
	var path := "%s/%s.gltf" % [BUILDINGS_DIR, MODEL]
	if not ResourceLoader.exists(path):
		push_error("road gate model missing: %s" % path)
		return
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the road gate at %.0f, %.0f" % [at.x, at.y])
		return

	position = Vector3(at.x, ground - 0.05, at.y)
	rotation.y = deg_to_rad(yaw_deg)

	var packed: PackedScene = load(path) as PackedScene
	_mesh = packed.instantiate()
	_mesh.name = "GateMesh"
	add_child(_mesh)

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(_mesh, meshes)
	if meshes.is_empty():
		push_error("road gate model has no mesh: %s" % path)
		return
	# Same root-local AABB derivation as props.gd::_place — the module may sit
	# under an importer-added transform node, so this reads each mesh's
	# GLOBAL transform (valid now that `_mesh` is parented into the tree) and
	# un-does `_mesh`'s own transform, leaving bounds in `_mesh`'s local space.
	var to_root_local: Transform3D = _mesh.global_transform.affine_inverse()
	var aabb: AABB = to_root_local * (meshes[0].global_transform * meshes[0].get_aabb())
	for i in range(1, meshes.size()):
		aabb = aabb.merge(to_root_local * (meshes[i].global_transform * meshes[i].get_aabb()))

	# A dark latch box at the panel's own centre. `Prop_WoodenFence_Single` is
	# decorative fencing everywhere else it's placed (`fence_run`) — with no
	# leaf, hinge or hardware of its own, one more length of it read as
	# ordinary property fencing rather than as something deliberately shut,
	# per the blind pass's own finding. A child of `_mesh` so it swings open
	# with the panel rather than needing its own re-pose.
	_lock = MeshInstance3D.new()
	_lock.name = "Lock"
	var lock_box := BoxMesh.new()
	lock_box.size = Vector3(0.16, 0.16, 0.24)
	_lock.mesh = lock_box
	var lock_material := StandardMaterial3D.new()
	lock_material.albedo_color = Color(0.1, 0.09, 0.08)
	lock_material.metallic = 0.7
	lock_material.roughness = 0.35
	_lock.material_override = lock_material
	_lock.position = Vector3(0.0, aabb.position.y + aabb.size.y * 0.55, 0.0)
	_mesh.add_child(_lock)

	var body := StaticBody3D.new()
	body.name = "GateCollision"
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size
	_shape.shape = box
	body.add_child(_shape)
	body.position = Vector3(0.0, aabb.size.y * 0.5, 0.0)
	add_child(body)

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3(0.0, 1.2, 0.0)
	# Wider than the fence's own thin collision box: at full scale (no
	# `scale` factor is applied here, unlike `village.json`'s fences, since
	# a road gate wants to read as a real obstacle rather than a knee-high
	# rail) an approach from an angle can be stopped by the panel's face
	# well outside a tighter radius, and the interaction should not demand a
	# more perpendicular approach than a locked gate reasonably does.
	_prompt.call("configure", "Try the gate", 4.0, true)
	_prompt.connect("activated", _on_tried)
	add_child(_prompt)


func is_open() -> bool:
	return _open


func _on_tried() -> void:
	if _open:
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var has_key: bool = inventory != null and int(inventory.call("count", KEY_ITEM_ID)) > 0

	if has_key:
		inventory.call("remove", KEY_ITEM_ID, 1)
		_unlock()
		_say(UNLOCKED_CONVERSATION)
	else:
		_say(LOCKED_CONVERSATION)


func _unlock() -> void:
	_open = true
	_shape.disabled = true
	_lock.visible = false
	# Swing the same panel parallel to the road it was blocking — an instant
	# re-pose rather than an animation, this file's own header explains why.
	_mesh.rotation.y += deg_to_rad(90.0)
	_prompt.call("set_enabled", false)


func _collect_meshes(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, into)


## Same lookup village_npcs.gd's `_on_greeted` uses: the "dialogue_panel"
## group rather than an exported path, so this does not need to know where
## sequence_director.gd hung the panel.
func _say(conversation_id: String) -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; the gate has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)
