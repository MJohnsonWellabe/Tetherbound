extends "res://tools/capture_cloudreach_architecture.gd"

func _capture_region_row(spec: Dictionary, row: Dictionary, time_name: String) -> void:
	# Windows can clamp the initial client area to its work area during boot.
	# Enforce and verify the native raster after the production world is ready.
	root.borderless = true
	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	if root.size != Vector2i(1920, 1080):
		push_error("Settlement capture requires a native 1920x1080 client area")
		quit(1)
		return
	await super._capture_region_row(spec, row, time_name)

## Grounded settlement approach and court evidence, using the production rig.
func _build_rows(_spec: Dictionary) -> Array:
	var rows: Array = []
	for view: Dictionary in [
		{"id":"place_cliffhold_approach", "at":Vector3(-267,838,4020.3), "target":Vector3(-340,838,3970), "pitch":5.0},
		{"id":"place_cliffhold_court", "at":Vector3(-309.2,830,3991.2), "target":Vector3(-350,841,3980), "pitch":8.0},
		{"id":"place_cliffhold_windwatch", "at":Vector3(-356,830,3962), "target":Vector3(-360,843,3988), "pitch":14.0},
		{"id":"place_galefoot_approach", "at":Vector3(-280,180,480), "target":Vector3(-290,190,528), "pitch":8.0},
		{"id":"place_galefoot_hearth", "at":Vector3(-271,180,522), "target":Vector3(-294,190,528), "pitch":10.0},
	]:
		rows.append({"id":view.id, "label":view.id, "stands":[view.at], "target":view.target,
			"pitch_deg":view.pitch, "times":["day","night"],
			"why":"Settlement identity diagnostic; production camera and physical seating; companion parked behind camera by base place fixture"})
	return rows
