extends "res://tools/phase2_capture_routes.gd"

## P2-049 probe: after each selected route frame, list every visible mesh near
## the player whose material reads near-black, so the owner of the detached
## dark strips can be named. Diagnostic only; prints, changes nothing.

const RADIUS_M := 70.0
const DARK_LUMA := 0.14


func _capture_row(row: Dictionary) -> void:
	await super._capture_row(row)
	if _player == null or _world == null:
		return
	var origin := _player.global_position
	print("P2049 PROBE frame=%s player=%s" % [str(row.get("frame_id", "")), origin])
	var stack: Array[Node] = [_world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		if not node is GeometryInstance3D or not (node as GeometryInstance3D).is_visible_in_tree():
			continue
		var geo := node as GeometryInstance3D
		var box := geo.global_transform * geo.get_aabb()
		var centre := box.get_center()
		if centre.distance_to(origin) > RADIUS_M + box.size.length() * 0.5:
			continue
		var colour := _albedo(geo)
		if colour.a < 0.0:
			continue
		var luma := colour.r * 0.2126 + colour.g * 0.7152 + colour.b * 0.0722
		if luma > DARK_LUMA:
			continue
		print("P2049 DARK %s class=%s luma=%.3f colour=%s aabb_pos=%s aabb_size=%s" % [
			geo.get_path(), geo.get_class(), luma, colour.to_html(false), box.position, box.size])


func _albedo(geo: GeometryInstance3D) -> Color:
	var material: Material = geo.material_override
	if material == null and geo is MeshInstance3D:
		var mesh := (geo as MeshInstance3D).mesh
		if mesh != null and mesh.get_surface_count() > 0:
			material = (geo as MeshInstance3D).get_active_material(0)
	if material == null and geo is MultiMeshInstance3D:
		var multi := (geo as MultiMeshInstance3D).multimesh
		if multi != null and multi.mesh != null and multi.mesh.get_surface_count() > 0:
			material = multi.mesh.surface_get_material(0)
	if material is BaseMaterial3D:
		return (material as BaseMaterial3D).albedo_color
	if material is ShaderMaterial:
		for key: String in ["albedo", "albedo_color", "base_colour", "colour", "color"]:
			var value: Variant = (material as ShaderMaterial).get_shader_parameter(key)
			if value is Color:
				return value
	return Color(0, 0, 0, -1)
