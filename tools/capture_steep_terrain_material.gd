extends "res://tools/capture_visual_audit.gd"
## DRY RUN — does not count toward earned-play or full visual acceptance.
## Production terrain, lighting and CameraRig; inherited stand/clock fixtures.

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		push_error("Native 1920x1080 viewport required")
		quit(1)
		return
	await super._run()

func _build_rows(_spec: Dictionary) -> Array:
	return [
		{"id": "gully_north", "label": "South Bridge north wall", "stands": [Vector3(25, NAN, 1330)], "target": Vector3(25, NAN, 1342), "target_ground": 0.0, "times": ["day", "dusk"]},
		{"id": "gully_south", "label": "South Bridge south wall", "stands": [Vector3(25, NAN, 1330)], "target": Vector3(25, NAN, 1318), "target_ground": 0.0, "times": ["day"]},
		{"id": "bridge_approach", "label": "South Bridge approach and path", "stands": [Vector3(0, NAN, 1295)], "target": Vector3(0, NAN, 1350), "target_ground": 0.0, "times": ["day"]},
		{"id": "quarry", "label": "Old Quarry approach", "stands": [Vector3(380, NAN, 1750)], "target": Vector3(403, NAN, 1794), "target_ground": 3.0, "times": ["day", "night"]}
	]
