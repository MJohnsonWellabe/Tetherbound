extends SceneTree

## Fast (no world-load) search for a station-14 eye/look pair that puts
## `ridge_patrol_camp`'s own fire/tent inside the frame, using the EXACT
## same camera maths `tools/_capture_corridor.gd::_frame`/`_shoot` use
## (fov, BACK offset, look_at, 1280x720 viewport) so the numbers this prints
## are the numbers a real render would show, without paying a full render's
## cost per candidate. Height is flattened to 0 for every point (this is a
## horizontal-FOV search only; the real render still settles on the true
## ground height, which the earlier full render already proved does not
## change the fire/tent from being pinned to a wide-open field).
##
##   godot --headless --path . --script tools/_probe_station14_candidates.gd

const FOV := 70.0
const BACK := 4.2
const UP := 2.4
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)

const FIRE := Vector2(-233.9, 6473.7)
const TENT := Vector2(-238.3, 6473.6)

# band4_upper_meadows_ironwood trail points 10-16 (terrain_playground.json).
const TRAIL := {
	10: Vector2(390, 6040), 11: Vector2(230, 6140), 12: Vector2(60, 6230),
	13: Vector2(-110, 6340), 14: Vector2(-280, 6460), 15: Vector2(-210, 6620),
	16: Vector2(-70, 6720),
}


func _init() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(VIEWPORT_SIZE.x), int(VIEWPORT_SIZE.y))
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.fov = FOV
	viewport.add_child(camera)
	camera.make_current()
	await process_frame
	await process_frame

	# Try every ordered pair of nearby trail points as (eye, look), same
	# convention as every other station: eye is a vertex, look is another
	# vertex (not necessarily adjacent -- station 14's own round-4 addendum
	# already established that "next vertex" is not sacred when it puts the
	# landmark out of frame).
	var indices: Array = TRAIL.keys()
	for eye_i: int in indices:
		for look_i: int in indices:
			if eye_i == look_i:
				continue
			var eye: Vector2 = TRAIL[eye_i]
			var look: Vector2 = TRAIL[look_i]
			var toward := (look - eye).normalized()
			var back := eye - toward * BACK
			camera.global_position = Vector3(back.x, UP, back.y)
			camera.look_at(Vector3(look.x, 2.0, look.y), Vector3.UP)

			var results: Array[String] = []
			var all_inside := true
			for probe: Array in [["fire", FIRE], ["tent", TENT]]:
				var label: String = str(probe[0])
				var spot: Vector2 = probe[1]
				var world_pos := Vector3(spot.x, 1.0, spot.y)
				var behind := camera.is_position_behind(world_pos)
				var screen := camera.unproject_position(world_pos)
				var inside := not behind and screen.x >= 40.0 and screen.x <= VIEWPORT_SIZE.x - 40.0 \
					and screen.y >= 40.0 and screen.y <= VIEWPORT_SIZE.y - 40.0
				all_inside = all_inside and inside
				results.append("%s(%.0f,%.0f,%s)" % [label, screen.x, screen.y, "IN" if inside else "out"])
			if all_inside:
				print("CANDIDATE eye=pt%d%s look=pt%d%s -> %s" % [
					eye_i, eye, look_i, look, ", ".join(results)])
	print("done")
	quit(0)
