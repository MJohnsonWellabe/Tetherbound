extends Node3D

## SA7: a simple physical gate on the road out of the village, with an easy
## key nearby. Owner directive, 2026-08-11 — near-field and low-stakes, so the
## player understands early that gated things have keys, well before `SC14`'s
## real combat-gated crossing hours in.
##
## The leaf is the `road_gate_leaf` prefab — the Medieval kit's own fence
## segments, two wide and two courses tall, through the same composer every
## building in the settlement uses (EV6 retired the farm pack this gate's
## Fence2 came from, and D24 wants one family anyway; the same rustic
## fencing the player has already walked past as `fence_run`). Locked/open
## are two static poses of the one leaf — a closed panel across the road vs.
## the same panel swung parallel to it — since no animation rig exists for
## it and grandpa_house.gd already sets the precedent of a gate with no
## animation, its feedback carried by something else (there, the
## conversation; here, the panel's own re-pose plus a line of dialogue).

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const LEAF_PREFAB := "road_gate_leaf"
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
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the road gate cannot build its leaf")
		return
	# building_prefabs.gd caches an un-parented Node3D template tree per
	# prefab name; without a real SceneTree parent it leaks RenderingServer
	# resources at engine shutdown (see building_prefabs.gd's own header on
	# `_holder` — reproduced as a real crash: hundreds of "leaked" GL buffers
	# followed by a heap-corrupting SIGABRT in the exported build, absent
	# once every `BuildingPrefabs` caller parks its templates).
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)
	var leaf: Node3D = prefabs.call("instantiate", LEAF_PREFAB)
	if leaf == null:
		push_error("road gate leaf prefab missing: %s" % LEAF_PREFAB)
		return
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the road gate at %.0f, %.0f" % [at.x, at.y])
		return

	position = Vector3(at.x, ground - 0.05, at.y)
	rotation.y = deg_to_rad(yaw_deg)

	_mesh = leaf
	_mesh.name = "GateMesh"
	add_child(_mesh)

	var aabb: AABB = prefabs.call("combined_aabb", _mesh)

	# A padlock at the panel's own centre. `Fence2` is decorative fencing
	# everywhere else it's placed (village.json) — with no leaf, hinge or
	# hardware of its own, one more length of it read as ordinary property
	# fencing rather than as something deliberately shut, per the blind
	# pass's own finding. Round 1 tried a single near-black box and a
	# second blind round called it out for blending straight into the
	# fence's own dark pickets — same hue, same value, same flat panel
	# plane. This round changes both levers that finding named: a lighter,
	# warmer, shinier material that reads as metal against the fence's
	# flat wood, and a body-plus-shackle silhouette (a box with a ring
	# sunk halfway into it, so only the top loop shows) instead of one
	# more rectangle among the panel's own pickets. A child of `_mesh` so
	# it swings open with the panel rather than needing its own re-pose.
	_lock = MeshInstance3D.new()
	_lock.name = "Lock"
	var lock_body := BoxMesh.new()
	lock_body.size = Vector3(0.16, 0.14, 0.06)
	_lock.mesh = lock_body
	var lock_material := StandardMaterial3D.new()
	lock_material.albedo_color = Color(0.58, 0.45, 0.22)
	lock_material.metallic = 0.85
	lock_material.roughness = 0.2
	_lock.material_override = lock_material
	# Pushed out past the panel's own face (not centred in its thickness,
	# round 1's placement) so the lock's silhouette breaks the fence's
	# outline instead of sitting flush inside it.
	_lock.position = Vector3(
		0.0, aabb.position.y + aabb.size.y * 0.55, aabb.size.z * 0.5 + 0.03)
	_mesh.add_child(_lock)

	var shackle := MeshInstance3D.new()
	shackle.name = "Shackle"
	var shackle_ring := TorusMesh.new()
	shackle_ring.inner_radius = 0.035
	shackle_ring.outer_radius = 0.06
	shackle.mesh = shackle_ring
	shackle.material_override = lock_material
	shackle.rotation.x = deg_to_rad(90.0)
	shackle.position = Vector3(0.0, lock_body.size.y * 0.5, 0.0)
	_lock.add_child(shackle)

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
