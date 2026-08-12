extends SceneTree

## Dump every StandardMaterial3D's real imported PBR values from a glTF
## module, so a "why does this read wrong" investigation starts from the
## actual baseline instead of a guess.
##
##   godot --headless --path . --script tools/_probe_material.gd -- <path>
##
## Written for EV6-remainder-well-rocktrim-shadow: the well curb's RockTrim
## stone was reading cold and flat in shadow after two rounds of colour-only
## retinting failed to fix it. This is what found the real cause — MI_RockTrim
## imports with metallic=1.0, a bare-metal value, versus the correctly
## dielectric MI_UnevenBrick (metallic=0.0) on the paving beside it.

const DEFAULT_PATH := "res://assets/buildings/quaternius_medieval/Stairs_Exterior_Platform.gltf"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path := DEFAULT_PATH if args.is_empty() else args[0]
	var scene: PackedScene = load(path)
	if scene == null:
		push_error("could not load %s" % path)
		quit(1)
		return
	_walk(scene.instantiate())
	quit(0)


func _walk(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i)
			if mat is StandardMaterial3D:
				var m := mat as StandardMaterial3D
				print("%s found on %s surface %d" % [m.resource_name, node.name, i])
				print("  albedo_color=%s" % m.albedo_color)
				print("  ao_enabled=%s ao_light_affect=%s ao_texture=%s" % [m.ao_enabled, m.ao_light_affect, m.ao_texture])
				print("  metallic=%s roughness=%s" % [m.metallic, m.roughness])
				print("  normal_enabled=%s normal_scale=%s" % [m.normal_enabled, m.normal_scale])
	for child in node.get_children():
		_walk(child)
