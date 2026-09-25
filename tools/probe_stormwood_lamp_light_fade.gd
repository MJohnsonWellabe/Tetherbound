extends "res://tools/capture_stormwood_f09_pockets_roads.gd"

## WO-F09-04: do the pocket draw-distance fades work in the Compatibility
## renderer, on the production camera?
##
## 1. Lamp light: each lamp's OmniLight3D uses Light3D distance fade ending at
##    `draw_distance.lights_m`. At several camera distances from one junction
##    lamp (night preset, so the light is what shows), render the frame with
##    the light on and with that one light hidden, and report the mean
##    absolute pixel difference. A working fade leaves no difference past
##    lights_m.
## 2. Palisade: trunks use visibility_range_end `draw_distance.models_m` with
##    a `models_fade_m` self fade. Standing down the pocket's spur, render with
##    the pocket's palisade shown and hidden and report the same difference.
##
## Every difference is measured in a 400 x 300 px box around the subject's
## projected position, with rain/particles hidden, and reported beside a
## noise floor (two grabs with nothing changed; grass wind still moves). The
## lamp light is raised to `PROBE_LIGHT_ENERGY` during the probe so a light
## that is still drawing cannot hide in that noise.
##
## Frames at the near/far pair of each (lamp 40/70 m, palisade 230/270 m)
## are written to --out.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/probe_stormwood_lamp_light_fade.gd -- [--pocket=verge_ash_hollow] [--out=res://...]

const DISTANCES_M := [20.0, 35.0, 40.0, 50.0, 58.0, 65.0, 70.0, 80.0]
const SAVE_LIGHT_M := [40.0, 70.0]
const PALISADE_M := [200.0, 230.0, 245.0, 255.0, 270.0, 290.0]
const SAVE_PALISADE_M := [230.0, 270.0]
const PROBE_LIGHT_ENERGY := 40.0
const BOX := Vector2i(200, 150)


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		push_error("light fade probe requires a rendering display")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_hud_off = true
	var pocket_id := "verge_ash_hollow"
	_output_dir = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pocket="):
			pocket_id = arg.trim_prefix("--pocket=")
		elif arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
	if not _output_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not await _mount_production_world() or not _prepare_capture_shell():
		quit(1)
		return
	_game = root.get_node(^"Game")
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_time_name = "night"
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POCKETS_PATH))
	var holder := _world.get_node_or_null(NodePath("StormwoodPockets/Pocket_%s/SpurLamp" % pocket_id)) as Node3D
	if holder == null:
		push_error("no SpurLamp for %s" % pocket_id)
		quit(1)
		return
	var light := holder.get_node("WarmMouthLight") as OmniLight3D
	var lamp := Vector2(holder.global_position.x, holder.global_position.z)
	var facing := Vector2(0.0, 1.0).rotated(-holder.rotation.y)
	print("LIGHT FADE lamp=%s fade_enabled=%s begin=%.1f length=%.1f lights_m=%.1f renderer=%s" % [
		str(lamp), str(light.distance_fade_enabled), light.distance_fade_begin, light.distance_fade_length,
		float(cfg.draw_distance.lights_m), str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))])
	for distance: float in DISTANCES_M:
		# The trainer stands in front of the lantern; the rig sits ~5.6 m
		# behind, so the camera distance is measured, not assumed.
		var stand := lamp + facing * maxf(distance - 5.6, 2.0)
		await _stand(stand, Vector3(lamp.x, _ground(lamp.x, lamp.y) + 1.0, lamp.y), -10.0)
		for layer: Node in _world.find_children("*", "CanvasLayer", true, false) + root.find_children("*", "CanvasLayer", true, false):
			(layer as CanvasLayer).visible = false
		_hide_particles()
		var saved_energy := light.light_energy
		light.light_energy = PROBE_LIGHT_ENERGY
		var on := await _grab()
		var on_again := await _grab()
		light.visible = false
		var off := await _grab()
		light.visible = true
		light.light_energy = saved_energy
		var focus := _camera.unproject_position(Vector3(lamp.x, _ground(lamp.x, lamp.y), lamp.y))
		var camera_m := _camera.global_position.distance_to(light.global_position)
		print("LIGHT FADE stand_m=%.0f camera_to_light_m=%.1f on_vs_hidden changed_px=%d mean=%.3f | noise floor changed_px=%d mean=%.3f" % [
			distance, camera_m, _changed(on, off, focus), _mean_diff(on, off, focus), _changed(on, on_again, focus), _mean_diff(on, on_again, focus)])
		if SAVE_LIGHT_M.has(distance):
			_save(on, "fade_lamp_%dm_light_on" % int(distance))
			_save(off, "fade_lamp_%dm_light_hidden" % int(distance))
	# Palisade: day preset, standing down the spur from the pocket centre.
	_time_name = "day"
	var pocket: Dictionary = {}
	for row: Dictionary in cfg.pockets:
		if str(row.id) == pocket_id:
			pocket = row
	var frame: Dictionary = POCKET_FRAME.frame(pocket)
	var centre: Vector2 = frame.centre
	var out_dir: Vector2 = frame.forward
	var body := _world.get_node(NodePath("StormwoodPockets/Pocket_%s" % pocket_id)) as Node3D
	var trunks: Array[Node3D] = []
	for child: Node in body.get_children():
		if child is Node3D and not child is CollisionShape3D and not str(child.name).contains("Lamp"):
			trunks.append(child as Node3D)
	print("PALISADE FADE pocket=%s trunks=%d models_m=%.0f models_fade_m=%.0f" % [pocket_id, trunks.size(),
		float(cfg.draw_distance.models_m), float(cfg.draw_distance.models_fade_m)])
	for distance: float in PALISADE_M:
		var stand := centre + out_dir * distance
		await _stand(stand, Vector3(centre.x, _ground(centre.x, centre.y) + 2.5, centre.y), 0.0)
		for layer: Node in _world.find_children("*", "CanvasLayer", true, false) + root.find_children("*", "CanvasLayer", true, false):
			(layer as CanvasLayer).visible = false
		_hide_particles()
		var shown := await _grab()
		var shown_again := await _grab()
		for trunk in trunks:
			trunk.visible = false
		var hidden := await _grab()
		for trunk in trunks:
			trunk.visible = true
		var focus := _camera.unproject_position(Vector3(centre.x, _ground(centre.x, centre.y) + 2.5, centre.y))
		var camera_m := Vector2(_camera.global_position.x, _camera.global_position.z).distance_to(centre)
		print("PALISADE FADE stand_m=%.0f camera_to_centre_m=%.1f shown_vs_hidden changed_px=%d mean=%.3f | noise floor changed_px=%d mean=%.3f" % [
			distance, camera_m, _changed(shown, hidden, focus), _mean_diff(shown, hidden, focus), _changed(shown, shown_again, focus), _mean_diff(shown, shown_again, focus)])
		if SAVE_PALISADE_M.has(distance):
			_save(shown, "fade_palisade_%dm" % int(distance))
	quit(0)


func _save(image: Image, name: String) -> void:
	if _output_dir.is_empty():
		return
	image.save_jpg(ProjectSettings.globalize_path("%s/%s.jpg" % [_output_dir, name]), 0.85)


func _grab() -> Image:
	for _frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _hide_particles() -> void:
	for node: Node in _world.find_children("*", "GPUParticles3D", true, false) + _world.find_children("*", "CPUParticles3D", true, false):
		(node as Node3D).visible = false


func _box(image: Image, focus: Vector2) -> Rect2i:
	var centre := Vector2i(int(focus.x), int(focus.y))
	return Rect2i(centre - BOX, BOX * 2).intersection(Rect2i(Vector2i.ZERO, image.get_size()))


func _mean_diff(a: Image, b: Image, focus: Vector2) -> float:
	var rect := _box(a, focus)
	var total := 0.0
	var count := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			count += 1
	return total / maxf(1.0, float(count)) * 255.0 / 3.0


func _changed(a: Image, b: Image, focus: Vector2) -> int:
	var rect := _box(a, focus)
	var changed := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 8.0 / 255.0:
				changed += 1
	return changed
