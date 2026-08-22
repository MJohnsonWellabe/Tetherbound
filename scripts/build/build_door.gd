extends Node3D

## OP21-08. The player-buildable `door` piece, wired to the same door verb
## every authored village building uses (`scripts/world/village_door.gd`),
## instead of the mesh-plus-solid-box every other `buildables.json` entry
## gets from `build_piece.gd`.
##
## Before this: `door` went through `build_piece.gd`'s generic path — one
## glTF (`Door_1_Flat.gltf`) and a combined-AABB collider. No hinge, no
## `Interactable`, no `activated` signal. It looked like a door and blocked
## like a wall; there was no way to open it. Worse, there was no
## wall-with-a-gap buildable at all, so a `door` placed beside a solid `wall`
## never actually cut an opening — the wall's own full-width collider still
## sealed the space.
##
## This assembles the SAME three-module doorway every authored cottage uses
## (`data/config/building_prefabs.json`'s `cottage_a`/`cottage_b` recipes),
## at the same relative offsets, so the buildable kit and the settlement's
## own architecture are one coherent module rather than two:
##   - `Wall_Plaster_Door_Flat` — a wall panel with the doorway already cut in
##     its mesh (replaces solid `wall` for this grid slot; `WALL_IDS` in
##     `build_snap_contract.gd` already treats `door` as a wall-family piece
##     for edge/corner snapping, so this slots into the same perimeter runs).
##   - `DoorFrame_Flat_WoodDark` — the frame lining the cut.
##   - `Door_1_Flat` — the leaf, hung on `village_door.gd`'s hinge.
## All three modules are centred on this node's own origin the same way a
## plain `wall`/`floor` piece is (measured: both `Wall_Plaster_Straight` and
## `Wall_Plaster_Door_Flat` are `x` in [-1, 1]), so a placed door piece
## occupies exactly the wall-edge anchor `build_snap_contract.gd` resolves
## for it — no piece-specific position offset anywhere in the placer.
##
## Collision is three boxes (two jambs, one lintel) rather than one
## combined-AABB box, because an AABB box would re-seal the doorway the mesh
## itself already cut — see `_add_wall_collision`. Their span
## (`DOOR_WIDTH`/`DOOR_HEIGHT` = 1.6m / 2.3m) reproduces the doorway
## `village_door.gd`'s own `DEFAULT_WIDTH`/`DEFAULT_HEIGHT` constants
## describe for every authored building — measured against the actual
## `DoorFrame_Flat_WoodDark` mesh (x in [-0.79, 0.79], y to 2.30), not
## invented.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const VILLAGE_DOOR := preload("res://scripts/world/village_door.gd")
const BUILD_MATERIAL_FINISH := preload("res://scripts/build/build_material_finish.gd")

const DIR := "res://assets/buildings/quaternius_medieval"
const WALL_GAP_MESH := DIR + "/Wall_Plaster_Door_Flat.gltf"
const FRAME_MESH := DIR + "/DoorFrame_Flat_WoodDark.gltf"
const LEAF_MESH := DIR + "/Door_1_Flat.gltf"

## Matches `village_door.gd::DEFAULT_WIDTH`/`DEFAULT_HEIGHT` exactly — the
## authored 1.6m clear / 2.3m tall doorway every cottage uses, reproduced
## here rather than re-derived so a buildable door and an authored door read
## identically to a player walking between them.
const DOOR_WIDTH := VILLAGE_DOOR.DEFAULT_WIDTH
const DOOR_HEIGHT := VILLAGE_DOOR.DEFAULT_HEIGHT
## `village_door.gd::GATE_THICKNESS` — "matching every hand-authored
## `colliders` box in building_prefabs.json," per that file's own comment —
## reused here rather than the raw measured mesh depth (z in [-0.31, 0.09],
## thickness 0.40) so the jamb/lintel boxes are exactly as thick as the
## leaf's own closed-state gate box and seal flush with no seam.
const WALL_DEPTH := VILLAGE_DOOR.GATE_THICKNESS
## Measured `Wall_Plaster_Straight`/`Wall_Plaster_Door_Flat` z-centre (z in
## [-0.31, 0.09]) — where the wall mesh actually sits, not assumed at 0.
const WALL_Z_CENTER := -0.11
## Measured `Wall_Plaster_Straight` height (y to 3.12) — where the lintel
## box's top and the wall-top roof anchor (`build_snap_contract.gd::ROOF_Y`
## adjacent geometry) both sit.
const WALL_HEIGHT := 3.12
## cottage_a/cottage_b's own leaf offset: the door module and its
## `DoorFrame` share one `at`; the leaf sits 0.55m toward -x of that same
## point (`building_prefabs.json`, `Door_1_Flat`'s `at` minus the module's).
## `Door_1_Flat`'s own local origin is its hinge/left edge (mesh x in
## [-0.046, 1.072], not centred) — this offset is what puts that edge inside
## the frame rather than at the module's own centre.
const LEAF_OFFSET := Vector3(-0.55, 0.0, 0.0)

var _leaf: Node3D = null
var _door: Node3D = null


## The see-through preview the placer drags around: all three modules in
## their closed rest pose, no collision, no interaction — matching
## `build_piece.gd::build_ghost`'s contract for every other catalogue entry.
func build_ghost() -> void:
	_spawn(false)


## The real thing: wall-with-gap + frame + leaf, jamb/lintel collision, and
## `village_door.gd`'s hinge/prompt wired to the leaf.
func build_real() -> void:
	_spawn(true)


func _spawn(solid: bool) -> void:
	_add_module(WALL_GAP_MESH, "WallGap")
	_add_module(FRAME_MESH, "Frame")
	_leaf = _add_module(LEAF_MESH, "Leaf")
	if _leaf != null:
		_leaf.position = LEAF_OFFSET
	if not solid:
		return

	_add_wall_collision()

	_door = VILLAGE_DOOR.new()
	_door.name = "Door"
	add_child(_door)
	if _leaf != null:
		_door.call("setup", _leaf, Vector3.ZERO, "Door", DOOR_WIDTH, DOOR_HEIGHT)


## Passthrough to `village_door.gd::force_open` -- same test/story hook that
## script's own header describes, exposed here since the hinge node itself
## (`_door`) is private to this piece.
func force_open(open: bool) -> void:
	if _door != null:
		_door.call("force_open", open)


## Passthrough to `village_door.gd::is_open`.
func is_door_open() -> bool:
	return _door != null and bool(_door.call("is_open"))


func _add_module(mesh_path: String, node_name: String) -> Node3D:
	if not ResourceLoader.exists(mesh_path):
		push_warning("build door missing module: %s" % mesh_path)
		return null
	var scene: PackedScene = load(mesh_path)
	var node := scene.instantiate() as Node3D
	node.name = node_name
	add_child(node)
	BUILD_MATERIAL_FINISH.apply(node)
	return node


## Two jambs and a lintel, leaving `DOOR_WIDTH` x `DOOR_HEIGHT` open at the
## piece's own centre — an AABB box across the whole module would re-seal
## exactly the gap `Wall_Plaster_Door_Flat`'s mesh already cuts, sealing the
## doorway regardless of what `village_door.gd`'s own gate collider does.
func _add_wall_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "WallCollision"
	var half_width := 1.0  # matches the wall module's own x in [-1, 1]
	var jamb_width := half_width - DOOR_WIDTH * 0.5
	_add_box(body, Vector3((half_width - jamb_width * 0.5), WALL_HEIGHT * 0.5, WALL_Z_CENTER),
		Vector3(jamb_width, WALL_HEIGHT, WALL_DEPTH))
	_add_box(body, Vector3(-(half_width - jamb_width * 0.5), WALL_HEIGHT * 0.5, WALL_Z_CENTER),
		Vector3(jamb_width, WALL_HEIGHT, WALL_DEPTH))
	var lintel_height := WALL_HEIGHT - DOOR_HEIGHT
	_add_box(body, Vector3(0.0, DOOR_HEIGHT + lintel_height * 0.5, WALL_Z_CENTER),
		Vector3(DOOR_WIDTH, lintel_height, WALL_DEPTH))
	add_child(body)


func _add_box(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


## Same three-state ghost tint `build_piece.gd` uses (VALID/INVALID/
## UNSUPPORTED), applied across all three modules — kept here rather than
## imported from build_piece.gd because that file's `_material_for_state` is
## a private static, and a door ghost has no `_model` single root to hand it.
const STATE_VALID := &"valid"
const STATE_INVALID := &"invalid"
const STATE_UNSUPPORTED := &"unsupported"
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
			colour = Color(UITokens.TEAL.lerp(Color(0.35, 0.9, 0.4), 0.6), 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_state_materials[state] = material
	return material


func tint_ghost_state(state: StringName) -> void:
	var material := _material_for_state(state)
	for mesh_instance in _mesh_instances(self):
		mesh_instance.material_override = material


func tint_ghost(ok: bool) -> void:
	tint_ghost_state(STATE_VALID if ok else STATE_INVALID)
