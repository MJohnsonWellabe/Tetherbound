extends MeshInstance3D
## Godot 4.7 can query a released material RID while destroying several GLB
## instances with copied shutdown surface overrides. Release those bindings
## before MeshInstance3D destruction, while the mesh's source materials exist.
## PREDELETE leaves temporary removal/reparenting and live appearance untouched.

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and mesh != null:
		for surface in mesh.get_surface_count():
			set_surface_override_material(surface, null)
