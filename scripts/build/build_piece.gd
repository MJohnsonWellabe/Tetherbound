extends Node3D

## A generic placeable build piece: one glTF module, one box collider, no
## interaction. `campfire.gd`/`player_bed.gd`/`camp_tent.gd` stay their own
## hand-authored scripts because they carry the rest/craft prompts or sink
## compensation; every other `data/items/buildables.json` entry is plain
## geometry, so this one script places any of them rather than each piece
## needing its own copy of that mesh/collision code.
##
## The Medieval Village MegaKit ships each module as a glTF scene (a node
## tree, not a bare `Mesh`), the same shape `building_prefabs.gd` already
## unpacks for `EV6`'s settlement pieces — `load()` on a `.gltf` returns a
## `PackedScene`, so it has to be instantiated rather than dropped straight
## onto a `MeshInstance3D.mesh`.

const BUILD_MATERIAL_FINISH := preload("res://scripts/build/build_material_finish.gd")

var _model: Node3D = null

## OF24: a data-driven point light for any buildable that wants one -- see
## `_build_light()`. Only the torch uses this today, but nothing here is
## torch-specific: a second lit buildable is a `light` block in
## data/items/buildables.json, not new code.
var _light: OmniLight3D = null
var _light_base_energy := 0.0
var _light_flicker := 0.0
var _flicker_time := 0.0


## The see-through preview the placer drags around. No collision, no light --
## a glowing ghost would read as already-placed.
func build_ghost(mesh_path: String, model_scale: Vector3 = Vector3.ONE) -> void:
	_spawn(mesh_path, false, {}, model_scale)


## The real thing: solid, collidable, and lit if `light` (the buildable's own
## `data/items/buildables.json` `light` block) is non-empty.
##
## OP21-09: `model_scale` is `buildables.json`'s own optional `scale` field —
## a per-axis correction for a kit mesh that does not tile onto
## `build_snap_contract.gd`'s module at its authored size (the roof panel:
## measured 3.30w x 1.95d against the 2m module it is placed one-per-floor-
## tile on). Defaults to no-op `Vector3.ONE` for every piece that already
## fits its module, which is every piece but the roof today.
func build_real(mesh_path: String, light: Dictionary = {}, model_scale: Vector3 = Vector3.ONE) -> void:
	_spawn(mesh_path, true, light, model_scale)


func _spawn(mesh_path: String, solid: bool, light: Dictionary, model_scale: Vector3 = Vector3.ONE) -> void:
	if not ResourceLoader.exists(mesh_path):
		push_warning("build piece missing: %s" % mesh_path)
		return
	var scene: PackedScene = load(mesh_path)
	_model = scene.instantiate() as Node3D
	_model.scale = model_scale
	add_child(_model)
	BUILD_MATERIAL_FINISH.apply(_model)
	if not light.is_empty():
		_build_light(light)
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

	# `combined` is in `_model`'s own local space (every `mesh_instance`
	# transform above is relative to `_model`, not to this node) — the
	# collision body is a sibling of `_model`, not a child of it, so its
	# position/size need `model_scale` applied explicitly rather than
	# inheriting it the way a child node would.
	var center := combined.get_center() * model_scale
	var size := combined.size * model_scale

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	add_child(body)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


## T1-CAST (§17). Read-only access to the placed module's own mesh
## instances, for a caller that needs to apply an override beyond the
## generic legal/illegal ghost tint above -- e.g. `creature_bed.gd`
## differentiating its own placement from another caller of the SAME mesh
## path. Returns an empty array before the piece is built. No new behaviour;
## `_spawn` already builds this list internally for the collision AABB pass,
## this just exposes it.
func mesh_instances() -> Array[MeshInstance3D]:
	if _model == null or not is_instance_valid(_model):
		return []
	return _mesh_instances(_model)


## OF24: `{color, energy, range, flicker}` off the buildable's own JSON entry
## -- the torch's `light` block first, but generic on purpose (see this
## file's own top-of-class comment). Sits at the placed model's
## `flame_local_position()` if it exposes one (torch_prop.gd does, the SAME
## point the carried torch's own OmniLight in scripts/player/torch.gd reads,
## so the ground and handheld versions glow from the same spot on the shared
## mesh) or the model's local origin otherwise. `flicker` is a 0-1 fraction
## of `energy` the light wobbles by; 0 (or the field absent) is a steady
## light with no per-frame cost.
func _build_light(light: Dictionary) -> void:
	_light = OmniLight3D.new()
	_light.name = "PieceLight"
	_light.light_color = Color(str(light.get("color", "#ffb366")))
	_light_base_energy = float(light.get("energy", 1.6))
	_light.light_energy = _light_base_energy
	_light.omni_range = float(light.get("range", 6.0))
	_light.shadow_enabled = false
	_light_flicker = clampf(float(light.get("flicker", 0.0)), 0.0, 1.0)
	if _model != null and _model.has_method("flame_local_position"):
		_light.position = _model.call("flame_local_position")
	add_child(_light)


func _process(delta: float) -> void:
	if _light == null or _light_flicker <= 0.0:
		return
	# Same two-out-of-phase-sines shape scripts/player/torch.gd's own OmniLight
	# flicker uses, not shared code -- this and that light have different
	# owners (a placed piece here, the carried torch there) and no third
	# caller yet to justify factoring the six-line shape out.
	_flicker_time += delta
	var noise := sin(_flicker_time * 9.0) * 0.6 + sin(_flicker_time * 24.3 + 1.3) * 0.4
	_light.light_energy = _light_base_energy * (1.0 + noise * _light_flicker)


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
## (camp_tent.gd/campfire.gd/player_bed.gd, storage_container.gd's own
## hand-authored ghosts, and any test exercising this file directly) —
## `tint_ghost_state` is the one that knows
## about the amber middle state.
func tint_ghost(ok: bool) -> void:
	tint_ghost_state(STATE_VALID if ok else STATE_INVALID)
