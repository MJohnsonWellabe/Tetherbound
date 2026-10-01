extends RefCounted

## Layer the existing drum/interior with installed-family planting and warm
## entry light. No new floor, collider, route, character or persistent state.
const PARTS := preload("res://scripts/world/cloudreach_aviary.gd")
const BUSH := preload("res://assets/environment/stylized_nature/Bush_Common.gltf")
const FLOWERS := preload("res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf")


static func build(root: Node3D, spec: Dictionary, arches: Array, materials: Dictionary,
		palette_owner: Node = null) -> void:
	if not bool(spec.get("enabled", false)):
		return
	if bool(root.get_meta("f40_sanctuary_built", false)):
		return
	root.set_meta("f40_sanctuary_built", true)
	var interior := root.get_node("AviaryInterior") as Node3D
	for index in arches.size():
		var arch: Dictionary = arches[index]
		var node := arch["node"] as Node3D
		var light := OmniLight3D.new()
		light.name = "SanctuaryEntryLight%d" % index
		var arch_mesh := node.get_node("AviaryStoneArch") as MeshInstance3D
		light.position = Vector3(arch_mesh.position.x,
			float(spec.get("entry_light_height_m", 5.8)), arch_mesh.position.z)
		light.light_color = Color(str(spec.get("entry_light_colour", "#ffc18b")))
		light.light_energy = float(spec.get("entry_light_energy", 2.0))
		light.omni_range = float(spec.get("entry_light_radius_m", 18.0))
		light.shadow_enabled = false
		root.add_child(light)
		for side_name: String in ["AviaryJambLeft", "AviaryJambRight"]:
			var jamb := node.get_node(side_name) as Node3D
			var mount := Vector3(jamb.position.x,
				float(spec.get("entry_light_height_m", 5.8)), jamb.position.z)
			var outward := Vector3(mount.x, 0.0, mount.z).normalized()
			mount += outward * float(spec.get("entry_lantern_outset_m", 0.7))
			PARTS._install_prop(root, PARTS.WALL_LANTERN, "SanctuaryEntryLantern",
				mount, float(spec.get("entry_lantern_height_m", 1.1)),
				deg_to_rad(float(arch.angle_deg)), false)
	# Leave the east/west through-routes and north/south entries clear. Each
	# planter is a separate direct interior child so the existing summit carve
	# seating pass can remove it if its full drawn footprint lacks support.
	var radius := float(spec.get("plant_radius_m", 21.5))
	var planter_height := float(spec.get("planter_height_m", 0.65))
	var planter_width := float(spec.get("planter_width_m", 3.6))
	for raw: Variant in spec.get("plant_angles_deg", []):
		var angle := deg_to_rad(float(raw))
		var planter := Node3D.new()
		planter.name = "SanctuaryPlanter%d" % int(raw)
		planter.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		interior.add_child(planter)
		PARTS._box(planter, "StoneTrough", Vector3.UP * planter_height * 0.5,
			Vector3(planter_width, planter_height, planter_width), materials["masonry"], false)
		var garden := PARTS._install_prop(planter, BUSH, "WindGarden", Vector3.UP * planter_height,
			float(spec.get("plant_height_m", 2.4)), angle, false)
		var flowers := PARTS._install_prop(planter, FLOWERS, "AlpineFlowers", Vector3(planter_width * 0.25, planter_height, 0),
			float(spec.get("plant_height_m", 2.4)) * 0.4, angle, false)
		if palette_owner != null and palette_owner.has_method("_apply_tree_palette"):
			palette_owner.call("_apply_tree_palette", garden, int(raw))
			palette_owner.call("_apply_tree_palette", flowers, int(raw) + 1)
	var glow := OmniLight3D.new()
	glow.name = "SanctuaryClerestoryLight"
	glow.position.y = float(spec.get("clerestory_light_height_m", 10.5))
	glow.light_color = Color(str(spec.get("entry_light_colour", "#ffc18b")))
	glow.light_energy = float(spec.get("clerestory_light_energy", 1.4))
	glow.omni_range = float(spec.get("clerestory_light_range_m", 22.0))
	glow.shadow_enabled = false
	root.add_child(glow)
