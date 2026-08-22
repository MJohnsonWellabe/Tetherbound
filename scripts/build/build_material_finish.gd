extends RefCounted

## BUILD-KIT-2: flattens the Medieval Village MegaKit's build-piece materials
## from "wet/marble/plastic" to matte plaster, weathered tile and dusty
## stone -- the blind critic's #5 defect. Measured post-import
## (`tools/_probe_matvals.gd`, not shipped): every kit material carries a
## `roughness_texture` with the flat `roughness` factor left at glTF's
## default 1.0 (a no-op multiplier, so the TEXTURE alone sets the glossy
## per-pixel value), `metallic_specular` at Godot's default 0.5, and
## `MI_Plaster` specifically at `metallic = 1.0` -- the source glTF has no
## `metallicFactor` on that material at all, so it fell back to glTF's own
## spec default (1.0, fully metal) rather than the `0` every other material
## in the kit sets explicitly. A plastered wall reflecting the environment
## like brushed steel is exactly the "soft grey marbled veining with a wet
## specular sheen" the critic described.
##
## The critic's own read: "the hue choices are correct — only the finish is
## wrong." So this never touches `albedo_color` except on the roof tile,
## whose own defect ("bright glossy salmon reading as plastic") the critic
## paired with an explicit desaturate-toward-terracotta instruction the
## other materials didn't get.
##
## Applied at runtime via `set_surface_override_material` (a duplicate per
## mesh instance, not a mutation of the shared imported resource) rather
## than editing the installed `.gltf` files directly, so this is fully
## reversible and carries no reimport dependency -- `capture_build_kit_house
## .gd`'s own header already leans on staying inside a pre-seeded `.godot/`
## cache without a fresh import pass.

## name -> {roughness, specular, albedo (optional Color multiply)}. Every
## kit material name this file knows about; anything not listed here (only
## `MI_WindowGlass` today) is left exactly as imported, since a window pane
## reading as glass is correct, not a defect.
const FINISH := {
	"MI_Plaster": {"roughness": 0.92, "specular": 0.22},
	"MI_WoodTrim": {"roughness": 0.72, "specular": 0.28},
	"MI_RoundTiles": {"roughness": 0.80, "specular": 0.18, "albedo": Color(0.62, 0.48, 0.42)},
	"MI_UnevenBrick": {"roughness": 0.85, "specular": 0.20},
	"MI_RockTrim": {"roughness": 0.85, "specular": 0.20},
}

## BUILD-KIT-3: the roof mesh's ridge cap is a SECOND surface on the same
## glTF, sharing `MI_WoodTrim` with every wall's exterior timber trim (see
## `tools/diag_roof_wall_bounds.gd`'s sibling, not shipped, which listed
## `Roof_RoundTile_2x1.gltf`'s two surfaces as `MI_RoundTiles`/`MI_WoodTrim`).
## `MI_WoodTrim`'s own entry above stays bright orange on purpose -- that is
## correct on a wall's cross-brace -- so a blanket recolour there would fix
## the ridge cap and break every wall in the same stroke. The blind critic's
## #4 defect ("ridge caps are a different material from the roof they cap...
## flat bright almost-plastic orange against darker saturated terracotta
## tile beneath") is scoped to the roof mesh specifically, so this overrides
## the SAME surface only when the mesh being finished is the roof, by mesh
## path rather than by node name (glTF import can rename nodes on collision,
## the path cannot). Close to `MI_RoundTiles`' own tile tone above rather
## than identical to it -- a ridge cap is still a capping course, not the
## flat field tile, so a little contrast is correct; a different family of
## colour (raw orange) was the actual defect.
const ROOF_RIDGE_TRIM := {"roughness": 0.80, "specular": 0.18, "albedo": Color(0.56, 0.40, 0.34)}
const ROOF_MESH_PATH := "res://assets/buildings/quaternius_medieval/Roof_RoundTile_2x1.gltf"

## BUILD-KIT-3: blind critic's #3 defect -- "horizontal and diagonal timbers
## cross the room at roughly waist height near corners and in front of the
## door... likely the exterior decorative cross-braces rendering on both
## faces of the wall piece." Confirmed by measurement
## (`tools/diag_roof_wall_bounds.gd`'s sibling, not shipped): every wall
## surface, `MI_WoodTrim` included, imports with `cull_mode = CULL_DISABLED`
## (glTF default), so the brace geometry authored to face outward renders
## from the interior too.
##
## `MI_WoodTrim` is NOT one material with one job, though -- `Door_1_Flat`'s
## own door LEAF uses the same material name for its whole visible panel
## (confirmed by the same probe), and that one must stay double-sided: an
## open leaf is seen from both sides in normal play, and `CULL_BACK` on it
## would make the leaf disappear depending which side the camera is on. A
## blanket `MI_WoodTrim` cull change would fix the brace and break the door
## in the same stroke -- the same shape of mistake `ROOF_RIDGE_TRIM` above
## avoids for colour.
##
## So this is scoped to the WALL MESH INSTANCE by name, not to the material:
## only `Wall_Plaster_Straight`/`Wall_Plaster_Door_Flat`'s own combined mesh
## (one `MeshInstance3D`, both its `MI_WoodTrim` surface and no other) gets
## `CULL_BACK`. `DoorFrame_Flat_WoodDark` and `Door_1_Flat` are separate
## `MeshInstance3D` nodes in `build_door.gd`'s assembly and never match this
## set, so the frame and leaf keep their default double-sided render.
const WALL_MESH_NAMES := {
	"Wall_Plaster_Straight": true,
	"Wall_Plaster_Door_Flat": true,
}


static func apply(model: Node3D, mesh_path: String = "") -> void:
	var is_roof := mesh_path == ROOF_MESH_PATH
	for mesh_instance in _mesh_instances(model):
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		var is_wall_mesh: bool = WALL_MESH_NAMES.get(mesh_instance.name, false)
		for i in mesh.get_surface_count():
			var mat := mesh_instance.get_active_material(i)
			if mat == null or not (mat is StandardMaterial3D):
				continue
			var std := mat as StandardMaterial3D
			var is_wood_trim := std.resource_name == "MI_WoodTrim"
			var finish: Variant = FINISH.get(std.resource_name, null)
			if is_roof and is_wood_trim:
				finish = ROOF_RIDGE_TRIM
			if finish == null and not (is_wall_mesh and is_wood_trim):
				continue
			var flat := std.duplicate() as StandardMaterial3D
			if finish != null:
				# The texture, not the factor, was driving the shine (see this
				# file's own header) -- clearing it so the flat `roughness`
				# below is the one number actually in effect, the same reason
				# `metallic`/`metallic_texture` are cleared even though most of
				# the kit's materials were already metallic = 0.
				flat.roughness_texture = null
				flat.roughness = float((finish as Dictionary)["roughness"])
				flat.metallic = 0.0
				flat.metallic_texture = null
				flat.metallic_specular = float((finish as Dictionary)["specular"])
				if (finish as Dictionary).has("albedo"):
					flat.albedo_color = (finish as Dictionary)["albedo"]
			if is_wall_mesh and is_wood_trim:
				flat.cull_mode = BaseMaterial3D.CULL_BACK
			mesh_instance.set_surface_override_material(i, flat)


static func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found
