extends RefCounted

## A Crown-only visual substitution. The existing piece continues to own lit
## materials, including the rear details. The runtime keeps all physics/state.
const CONFIG := "res://assets/environment/stormwood/crown_arch/candidate.json"
const FRAME := "res://assets/environment/stormwood/crown_arch/crown_arch_frame.obj"
const PAVING := "res://assets/environment/stormwood/crown_arch/crown_arch_paving.obj"
const INSTALLED_KIT := preload("res://assets/environment/stormwood/crown_arch/crown_arch_installed_kit_candidate.gd")


static func apply(piece: Node3D, slab: MeshInstance3D, clearance: Node3D) -> bool:
	# Private installed-kit experiment is separate and defaults OFF.
	if INSTALLED_KIT.has_opt_in():
		return INSTALLED_KIT.apply(piece, slab, clearance)
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not value is Dictionary or value.get("enabled", false) != true:
		return false
	var frame := piece.get_node_or_null("StormglassFrame") as MeshInstance3D
	var rear := piece.get_node_or_null("RearStormglassDetails") as MeshInstance3D
	var frame_mesh := load(FRAME) as ArrayMesh
	var paving_mesh := load(PAVING) as ArrayMesh
	var tones: Array = value.get("paving_tone_multipliers", [])
	if frame == null or rear == null or frame_mesh == null or paving_mesh == null:
		push_warning("Crown candidate unavailable; retaining installed presentation")
		return false
	if frame_mesh.get_surface_count() != 2 or paving_mesh.get_surface_count() != 4 or tones.size() != 4:
		push_warning("Crown candidate surface contract differs; retaining installed presentation")
		return false
	var masonry := slab.material_override as StandardMaterial3D
	if masonry == null:
		return false
	var rear_mesh := ArrayMesh.new()
	rear_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, frame_mesh.surface_get_arrays(1))
	var stone_material := frame.get_surface_override_material(0)
	var glass_material := frame.get_surface_override_material(1)
	var rear_material := rear.get_surface_override_material(0)
	# The derivative retains the installed OBJ's original coordinate frame and
	# all surfaces below 2.65m. Keep the existing normalization/rear transform.
	frame.mesh = frame_mesh
	frame.set_surface_override_material(0, stone_material)
	frame.set_surface_override_material(1, glass_material)
	rear.mesh = rear_mesh
	rear.set_surface_override_material(0, rear_material)
	slab.mesh = paving_mesh
	slab.material_override = null
	for surface: int in range(4):
		var material := masonry.duplicate() as StandardMaterial3D
		var tint := masonry.albedo_color
		var tone := float(tones[surface])
		material.albedo_color = Color(tint.r * tone, tint.g * tone, tint.b * tone, tint.a)
		slab.set_surface_override_material(surface, material)
	var clear_radius := float(value.get("paving_clear_radius_m", 6.4))
	if clearance != null and clear_radius > 0.0:
		clearance.set_meta("grass_clear_radius", clear_radius)
	return true
