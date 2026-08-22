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


static func apply(model: Node3D) -> void:
	for mesh_instance in _mesh_instances(model):
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var mat := mesh_instance.get_active_material(i)
			if mat == null or not (mat is StandardMaterial3D):
				continue
			var std := mat as StandardMaterial3D
			var finish: Variant = FINISH.get(std.resource_name, null)
			if finish == null:
				continue
			var flat := std.duplicate() as StandardMaterial3D
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
			mesh_instance.set_surface_override_material(i, flat)


static func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found
