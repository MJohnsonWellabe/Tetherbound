extends "res://tools/capture_stormwood_f09_pockets_roads.gd"

## WO-F09-04: does each pocket lamp's OmniLight3D distance fade actually
## switch the light off by `draw_distance.lights_m` in the Compatibility
## renderer? For one junction lamp, at several camera distances on the
## production camera, render the frame with the lamp's light on and with that
## one light hidden, and report the mean absolute pixel difference. A working
## fade gives a clear difference near the lamp and none past lights_m.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/probe_stormwood_lamp_light_fade.gd -- [--pocket=verge_ash_hollow]

const DISTANCES_M := [20.0, 35.0, 50.0, 58.0, 65.0, 80.0]


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
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pocket="):
			pocket_id = arg.trim_prefix("--pocket=")
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
		var on := await _grab()
		light.visible = false
		var off := await _grab()
		light.visible = true
		var camera_m := _camera.global_position.distance_to(light.global_position)
		print("LIGHT FADE camera_to_light_m=%.1f mean_abs_diff=%.4f changed_pixels=%d" % [camera_m, _mean_diff(on, off), _changed(on, off)])
	quit(0)


func _grab() -> Image:
	for _frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _mean_diff(a: Image, b: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			count += 1
	return total / maxf(1.0, float(count)) * 255.0 / 3.0


func _changed(a: Image, b: Image) -> int:
	var changed := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 3.0 / 255.0:
				changed += 1
	return changed
