extends "res://scripts/player/human_water_contact_view.gd"

## P2-108 (F39#8, tb/vis-tidewake-1104, flag-off): the mounted swimmer's
## waterline foam ring and trailing wake, reusing the judged P2-072 swimmer
## ring. GPU judges, 28 Oct: "no splash or wake ... reads as walking on glass".
## Attached by water_mounted_swim.gd only when water_mount_presentation.json is
## on and the mount's row has a `wake` map. Reads the mount's own aquatic
## snapshot meta; local presentation only, no state, network or save change.


func _process(delta: float) -> void:
	if not is_instance_valid(_body):
		_clear()
		queue_free()
		return
	var snap: Variant = _body.get_meta("water_aquatic", {})
	var swimming := snap is Dictionary and int(snap.get("mode", SWIM.Mode.LAND)) == SWIM.Mode.MOUNTED
	var packet := {"mode": SWIM.Mode.HUMAN if swimming else SWIM.Mode.LAND,
		"surface_y": float(snap.get("surface_y", NAN)) if snap is Dictionary else NAN}
	step_visual(delta, packet, _body.global_position)


## Shadows stay with water_mount_presentation.set_shadows; the wake never
## touches the mount's meshes.
func _set_body_shadow(_casting: bool) -> void:
	pass
