extends SceneTree

## Coordinator ask (ralph/NOTES.md, CI-AGGRESSION + OF15): does the REAL
## physical collision surface (queried directly, not the analytic
## heightfield) actually sit where ground_height_at() says at the three
## reported wedge coordinates? Casts straight down from well above, at each
## point and at four 0.5m offsets around it, and reports the gap.
##
##   godot --headless --path . --script tools/_probe_wedge_height_check.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const POINTS := [
	{"label": "CI-AGGRESSION creature freeze", "x": 52.9728, "z": -122.276},
	{"label": "OF15 point A", "x": 60.0, "z": -106.0},
	{"label": "OF15 point B", "x": 65.0, "z": -108.0},
]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var field := HEIGHTFIELD.new()
	var space := get_root().get_world_3d().direct_space_state

	for entry: Dictionary in POINTS:
		var x: float = entry["x"]
		var z: float = entry["z"]
		var label: String = entry["label"]
		var analytic: float = float(field.call("height_at", x, z))

		var params := PhysicsRayQueryParameters3D.create(
			Vector3(x, 200.0, z), Vector3(x, -200.0, z))
		params.collide_with_bodies = true
		params.collide_with_areas = false
		var hit := space.intersect_ray(params)

		print("")
		print("--- %s at (%.4f, %.4f) ---" % [label, x, z])
		print("  ground_height_at (analytic): %.3f" % analytic)
		if hit.is_empty():
			print("  raycast from y=200 straight down: NO HIT AT ALL -- no collision surface anywhere on this vertical line")
		else:
			var real_y: float = (hit["position"] as Vector3).y
			var normal: Vector3 = hit["normal"]
			var collider: Object = hit.get("collider")
			print("  raycast real surface y: %.3f  (gap vs analytic: %.3fm)" % [real_y, real_y - analytic])
			print("  raycast normal: %s (%.2f deg from up)" % [normal, rad_to_deg(normal.angle_to(Vector3.UP))])
			print("  collider: %s" % collider)

			# A second ray offset 0.5m in +x and +z, to see if the surface is
			# smooth or has a step/crack right at this point specifically --
			# a seam between two independent HeightMapShape3D tiles would show
			# up as a discontinuity here that isn't in the analytic field.
			for offset: Vector2 in [Vector2(0.5, 0.0), Vector2(-0.5, 0.0), Vector2(0.0, 0.5), Vector2(0.0, -0.5)]:
				var ox := x + offset.x
				var oz := z + offset.y
				var oparams := PhysicsRayQueryParameters3D.create(
					Vector3(ox, 200.0, oz), Vector3(ox, -200.0, oz))
				var ohit := space.intersect_ray(oparams)
				var oanalytic: float = float(field.call("height_at", ox, oz))
				if ohit.is_empty():
					print("    +0.5m offset (%.1f,%.1f): NO HIT (analytic %.3f)" % [offset.x, offset.y, oanalytic])
				else:
					var oy: float = (ohit["position"] as Vector3).y
					print("    +0.5m offset (%.1f,%.1f): real y=%.3f analytic=%.3f gap=%.3f" % [
						offset.x, offset.y, oy, oanalytic, oy - oanalytic])

	quit(0)
