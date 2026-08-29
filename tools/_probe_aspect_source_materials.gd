extends SceneTree

## T1-CREATURE-ART: introspect the live imported materials for the four
## base creatures (Burrowback, Trailpup, Paddlenewt, Tuskroot) before
## designing the Aspect-variant recolor/emissive pipeline. Prints, per
## surface: albedo texture path + size, emission_enabled, emission_texture
## path + size, emission_energy_multiplier. Scratch/dev-only, not shipped.

const MODELS := {
	"burrowback": "res://assets/creatures/tetherbound/burrowback/models/creature_burrowback_lod0.glb",
	"trailpup": "res://assets/creatures/tetherbound/trailpup/models/creature_trailpup_lod0.glb",
	"paddlenewt": "res://assets/creatures/tetherbound/paddlenewt/models/creature_paddlenewt_lod0.glb",
	"tuskroot": "res://assets/creatures/tetherbound/tuskroot/models/creature_tuskroot_lod0.glb",
}


func _initialize() -> void:
	for species in MODELS:
		print("=== %s ===" % species)
		var packed: PackedScene = load(MODELS[species]) as PackedScene
		var art: Node3D = packed.instantiate() as Node3D
		_walk(art, species)
	quit()


func _walk(node: Node, species: String) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var mat: Material = instance.get_active_material(surface)
			if mat is BaseMaterial3D:
				var b := mat as BaseMaterial3D
				var albedo_tex := b.albedo_texture
				var em_tex := b.emission_texture
				print("  [%s] surface %d name=%s" % [node.name, surface, mat.resource_name])
				print("    albedo: %s size=%s" % [
					(albedo_tex.resource_path if albedo_tex else "null"),
					(str(albedo_tex.get_size()) if albedo_tex else "-"),
				])
				print("    metallic=%s roughness=%s" % [b.metallic, b.roughness])
				print("    emission_enabled=%s energy=%s" % [b.emission_enabled, b.emission_energy_multiplier])
				print("    emission_tex: %s size=%s same_as_albedo=%s" % [
					(em_tex.resource_path if em_tex else "null"),
					(str(em_tex.get_size()) if em_tex else "-"),
					(em_tex == albedo_tex),
				])
				print("    emission colour: %s" % [b.emission])
	for child in node.get_children():
		_walk(child, species)
