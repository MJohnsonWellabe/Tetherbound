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
##
## VISUAL-CORRIDOR fix (2026-08-23): `MI_RoundTiles` used to carry
## `"albedo": Color(0.62, 0.48, 0.42)` here -- a BUILD-KIT-2 desaturate-toward-
## terracotta pass answering an even older "bright glossy salmon plastic"
## critique. Multiplied against `T_RoundTiles_BaseColor.png`'s own warm
## orange-brown (measured ~(180,85,48) sRGB, `tools/_probe_roof_mat.gd`-style
## direct pixel sample), that 0.62/0.48/0.42 multiply lands around sRGB
## (144,60,28) -- a dark, saturated red-brown close enough to
## `building_prefabs.json`'s own `"Banner": "#7a2430"` (Team Tether's
## authored oxblood) that a blind critic read the buildable roof as wearing
## the enemy's colour ("23-roof.png ... dark, glazed, oxblood red ... sitting
## in exactly the colour band the project reserves for Team Tether danger").
## `data/config/building_prefabs.json`'s cottage/farmhouse/workshop recipes
## never retint `MI_RoundTiles` at all (only the inn does, deliberately, to
## read as a different building) -- village roofs are this SAME glTF module
## at its native imported colour, confirmed by comparing
## `shots/structures/02-cottage_a.png` (bright, warm, correct orange-red
## terracotta, no override) against the old `23-roof.png` (dark oxblood) from
## the same capture tool and lighting rig. Dropping the `albedo` key here
## restores that native colour -- `apply()` below only sets
## `flat.albedo_color` when a finish entry HAS an `"albedo"` key, so a
## duplicated material with none keeps the imported (1,1,1,1) multiplier,
## i.e. the plain texture, the same "actual value" every cottage roof
## already shows. `roughness`/`specular` stay set (still killing the
## texture-driven shine BUILD-KIT-2's header describes) since that part of
## the earlier fix was never the reported defect -- only the invented colour
## was.
const FINISH := {
	"MI_Plaster": {"roughness": 0.92, "specular": 0.22},
	"MI_WoodTrim": {"roughness": 0.72, "specular": 0.28},
	"MI_RoundTiles": {"roughness": 0.80, "specular": 0.18},
	"MI_UnevenBrick": {"roughness": 0.85, "specular": 0.20},
	"MI_RockTrim": {"roughness": 0.85, "specular": 0.20},
	# THE PROPS KIT, added after scanning all 126 vendored .gltf files for the
	# same gap MI_RockTrim had. 68 materials across that set ship with NO
	# `metallicFactor`, so glTF's spec default of 1.0 applies and they render
	# FULL METAL -- the root cause already blamed for the ice-blue foundations,
	# and it was never confined to the buildings kit.
	#
	# The four below are the props-kit trims that are not metal and were falling
	# straight through `apply()`'s `if finish == null: continue`. That silent
	# skip is the same shape as the one behind the red ironwood canopy
	# (`harvest_node.gd::_material_fixups_for_model()` matching by model path):
	# a fix that lives in a lookup table does not protect the material that is
	# not in the table.
	#
	# The most visible of these is `MI_Trim_Cloth`, which is the bedding on
	# `Bed_Twin1.gltf` -- the player's buildable creature bed. Its blanket and
	# pillow have been rendering as chromed metal, mirroring the sky, in a piece
	# a blind critic already called the worst-looking thing in the game.
	#
	# DELIBERATELY ABSENT: `MI_Trim_Metal` and `MI_MetalOrnaments`. They have the
	# same missing factor, and for them 1.0 is CORRECT -- they are the kit's
	# actual metal. Do not "complete" this table by adding them; that would flatten
	# the anvil and the door furniture into plastic.
	"MI_Trim_Cloth": {"roughness": 0.95, "specular": 0.15},
	"MI_Trim_Furniture": {"roughness": 0.75, "specular": 0.25},
	"MI_Trim_Props": {"roughness": 0.80, "specular": 0.22},
	"MI_Trim_Props_Vertex": {"roughness": 0.78, "specular": 0.25},
}

## VISUAL-CORRIDOR fix: BUILD-KIT-3 used to override the roof mesh's ridge
## cap (`MI_WoodTrim`, shared with every wall's exterior timber trim) to a
## bespoke darker tone "close to `MI_RoundTiles`' own tile tone" -- i.e.
## close to the invented oxblood-adjacent colour this file no longer
## applies. That override existed to fix a contrast mismatch between the
## ridge and a tile that had been artificially darkened; now that the tile
## is back to its native colour (see `FINISH["MI_RoundTiles"]` above), the
## mismatch it was answering no longer exists -- `shots/structures/
## 02-cottage_a.png`'s own ridge cap is plain `MI_WoodTrim` with no
## roof-specific override and reads fine against its native-colour tile. The
## ridge cap on a buildable roof now falls through to `MI_WoodTrim`'s own
## generic entry above (same matte finish every wall's trim gets), so it
## matches the village roofs it sits beside instead of inventing a second
## red.

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
## in the same stroke -- the same shape of mistake the roof's ridge-cap
## comment above avoids for colour (a fix scoped to what actually needs it,
## not a blanket change to every user of the shared material name).
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


static func apply(model: Node3D) -> void:
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
