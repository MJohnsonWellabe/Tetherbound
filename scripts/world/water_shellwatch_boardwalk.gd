extends Node3D

## Weathered timber sleepers in the sand passage behind Shellwatch's rescue
## landing. The boards follow the baked ground and stay flush with the route.
const BOARD := preload("res://assets/buildings/quaternius_medieval/Floor_WoodDark.gltf")
const START := Vector2(268.0, 1008.0)
const END := Vector2(291.0, 1041.0)
const COUNT := 38


func build(world: Node3D) -> void:
	var forward := (END - START).normalized()
	var across := Vector2(forward.y, -forward.x)
	for i in COUNT:
		if i == 10 or i == 26:
			continue
		var fraction := clampf((float(i) + sin(float(i) * 1.61) * 0.12) / float(COUNT - 1), 0.0, 1.0)
		var lateral := sin(PI * fraction) * 0.9 + sin(float(i) * 1.83) * 0.14
		var at := START.lerp(END, fraction) + across * lateral
		var tangent := (forward + across * (cos(PI * fraction) * 0.9 * PI / START.distance_to(END))).normalized()
		var transverse := Vector2(tangent.y, -tangent.x)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if not is_finite(ground) or ground <= 0.0:
			continue
		var left := float(world.call("ground_height_at", at.x - transverse.x * 1.2, at.y - transverse.y * 1.2))
		var right_height := float(world.call("ground_height_at", at.x + transverse.x * 1.2, at.y + transverse.y * 1.2))
		var behind := float(world.call("ground_height_at", at.x - tangent.x * 0.24, at.y - tangent.y * 0.24))
		var ahead := float(world.call("ground_height_at", at.x + tangent.x * 0.24, at.y + tangent.y * 0.24))
		if not is_finite(left) or not is_finite(right_height) or not is_finite(behind) or not is_finite(ahead):
			continue
		var x_axis := Vector3(transverse.x * 2.4, right_height - left, transverse.y * 2.4).normalized()
		var z_axis := Vector3(tangent.x * 0.48, ahead - behind, tangent.y * 0.48).normalized()
		var y_axis := z_axis.cross(x_axis).normalized()
		z_axis = x_axis.cross(y_axis).normalized()
		var sleeper := BOARD.instantiate() as Node3D
		sleeper.name = "SandSleeper%02d" % i
		for child in sleeper.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			var source := mesh.get_active_material(0)
			if source is BaseMaterial3D:
				var weathered := source.duplicate() as BaseMaterial3D
				weathered.albedo_color = Color(0.52, 0.55, 0.54)
				weathered.roughness = 1.0
				mesh.set_surface_override_material(0, weathered)
		var width := 1.43 + sin(float(i) * 2.17) * 0.09
		var depth := 0.23 + sin(float(i) * 1.27) * 0.018
		sleeper.transform = Transform3D(Basis(x_axis * width, y_axis, z_axis * depth),
			Vector3(at.x, ground + 0.035, at.y))
		add_child(sleeper)
