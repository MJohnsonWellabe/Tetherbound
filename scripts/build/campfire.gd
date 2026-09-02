extends Node3D

## OWNER-0902-CAMP-SPLIT: the campfire, split out of camp.gd's bundled camp
## into its own independently placeable buildable (`data/items/buildables.json`'s
## `campfire`) -- the stone ring, the lit log pile, and the "Craft" prompt that
## used to sit beside camp.gd's fire. Everything below (mesh paths, scales,
## the flame-mesh cast fix, the halo fraction) is carried over unchanged from
## camp.gd's own history; only the placement is now standalone rather than one
## piece of a three-part composed node. See that file's git history (and
## `data/items/buildables.json`'s `_comment_camp`) for why the split happened.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")
const CAMPFIRE_GLOW := preload("res://scripts/world/campfire_glow.gd")
const BONFIRE := "res://assets/props/quaternius_survival/Bonfire_Fire.obj"

## T1-CAMP, carried over from camp.gd: every AUTHORED camp in the game pairs
## `Bonfire_Fire` with this same Meshy-generated ring; the player-built fire
## now does too.
const STONE_RING := "res://assets/props/generated_camp/campfire_stone_ring.glb"
const STONE_RING_SCALE := 0.8
const FIRE_SCALE := 0.55

## T1-CAST-FIX: the visible flame is the Meshy-generated flame sculpt, lit
## through `ignite_mesh()` rather than the bonfire's own faceted `Fire` cone
## (hidden via `hide_fire_surface()`) -- see camp.gd's own history for the
## full account of why.
const CAMP_FLAME := "res://assets/props/generated_camp/camp_flame.glb"
const CAMP_FLAME_SCALE := 0.85
const CAMP_FLAME_POSITION := Vector3(0.0, 0.18, 0.0)
const CAMP_FLAME_ENERGY := 3.5
const HALO_FRACTION := 0.3

var _ghost_ring: Node3D = null
var _ghost_fire: MeshInstance3D = null
## R2.4, carried over: instantiated once, on the first "Craft" activation.
var _craft_panel: CanvasLayer = null


func build_ghost() -> void:
	_spawn(false)


func build_real() -> void:
	_spawn(true)
	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "CraftInteractable"
	prompt.position = Vector3(0.0, 0.5, 1.6)
	prompt.call("configure", "Craft", 2.6, true)
	prompt.connect("activated", _on_craft)
	add_child(prompt)


func _spawn(solid: bool) -> void:
	_ghost_ring = null
	_ghost_fire = null
	var ring := BUILD_PIECE.new()
	add_child(ring)
	if solid:
		ring.call("build_real", STONE_RING, {}, Vector3.ONE * STONE_RING_SCALE)
	else:
		ring.call("build_ghost", STONE_RING, Vector3.ONE * STONE_RING_SCALE)
		_ghost_ring = ring

	var fire := _mesh(BONFIRE, Vector3.ZERO, FIRE_SCALE)
	# Lit only on the real thing -- a drag-around ghost is a preview, not an
	# already-burning fire. See camp.gd's own history for the full account of
	# the flame-mesh cast fix and the halo-fraction tuning below.
	if fire != null and solid:
		CAMPFIRE_GLOW.hide_fire_surface(fire)
		CAMPFIRE_GLOW.texture_logs(fire)
		var flame_scene := load(CAMP_FLAME) as PackedScene
		if flame_scene != null:
			var flame := flame_scene.instantiate() as Node3D
			flame.name = "CampFlame"
			flame.position = CAMP_FLAME_POSITION
			flame.scale = Vector3.ONE * CAMP_FLAME_SCALE
			add_child(flame)
			CAMPFIRE_GLOW.ignite_mesh(flame, CAMP_FLAME_ENERGY, true)
		var overlay: Node3D = CAMPFIRE_GLOW.new(true, HALO_FRACTION)
		overlay.scale = Vector3.ONE / FIRE_SCALE
		fire.add_child(overlay)

	if not solid:
		_ghost_fire = fire
		return

	if fire == null:
		return
	var aabb: AABB = (fire.mesh as Mesh).get_aabb()
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * fire.scale.x
	shape.shape = box
	body.add_child(shape)
	body.position = fire.position + Vector3(0.0, aabb.size.y * 0.5 * fire.scale.x, 0.0)
	body.rotation.y = fire.rotation.y
	add_child(body)


func _mesh(path: String, at: Vector3, scale_factor: float) -> MeshInstance3D:
	if not ResourceLoader.exists(path):
		push_warning("campfire piece missing: %s" % path)
		return null
	var mesh := MeshInstance3D.new()
	mesh.mesh = load(path)
	mesh.position = at
	mesh.scale = Vector3.ONE * scale_factor
	add_child(mesh)
	return mesh


## Legal (green) or not (red), at ghost alpha either way.
func tint_ghost(ok: bool) -> void:
	var colour := Color(0.5, 1.0, 0.5, 0.45) if ok else Color(1.0, 0.4, 0.4, 0.45)
	if _ghost_fire != null and is_instance_valid(_ghost_fire):
		var material := StandardMaterial3D.new()
		material.albedo_color = colour
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ghost_fire.material_override = material
	if _ghost_ring != null and is_instance_valid(_ghost_ring):
		_ghost_ring.call("tint_ghost", ok)


## R2.4, carried over: the craft screen -- data/recipes/recipes.json's base
## tier, spent and granted through GameState.craft().
func _on_craft() -> void:
	if _craft_panel == null:
		_craft_panel = CRAFT_PANEL.new()
		get_tree().root.add_child(_craft_panel)
	_craft_panel.call("open")
