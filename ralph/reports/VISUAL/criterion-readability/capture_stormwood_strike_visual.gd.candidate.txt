extends "res://tools/capture_stormwood_surge_phases.gd"
## Native production-camera presentation fixtures; no earned or damage proof.
const STRIKE_MOTION = preload("res://scripts/ui/motion_prefs.gd")
var _receipt: FileAccess
var _serial := 8000
var _timed := false

func _run() -> void:
	_t0 = Time.get_ticks_msec()
	_biome_id = "stormwood"
	_character_id = "trainer"
	_output_dir = "res://shots/storm-strike-baseline"
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--timed":
			_timed = true
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
	root.size = Vector2i(1920,1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	_receipt = FileAccess.open(_output_dir.path_join("manifest.jsonl"), FileAccess.WRITE)
	if not await _mount_production_world() or not _prepare_capture_shell():
		_done()
		return
	_game = root.get_node(^"Game")
	_surge = _world.get_node(^"StormwoodSurge")
	_lightning = _world.get_node(^"StormwoodLightning")
	_lightning.set_process(false)
	_pin_day()
	if _timed:
		await _timed_views()
		STRIKE_MOTION.set_reduced_motion(false)
		print("STRIKE_CAPTURE_COMPLETE failures=", _failures)
		quit(0 if _failures.is_empty() else 1)
		return
	for place: Dictionary in [
		{"id":"clearing", "at":Vector2(-610,755)},
		{"id":"verge", "at":Vector2(-598,753)}]:
		var xz: Vector2 = place.at
		var target := Vector3(xz.x, float(_world.call("ground_height_at",xz.x,xz.y)) + 0.08, xz.y)
		await _stand(xz - Vector2(0,10), target, -12.0)
		await _enter_phase("break", false)
		_surge.set("_flash_next", 100000.0)
		_surge.set("_sky_next", 100000.0)
		_surge.set("_flash_echo", -1.0)
		for _frame in 45:
			await process_frame
		for reduced: bool in [false,true]:
			STRIKE_MOTION.set_reduced_motion(reduced)
			var prefix := str(place.id) + ("_reduced" if reduced else "_normal")
			await _frame(prefix + "_00_clear", target, -1.0)
			var ring: MeshInstance3D = _lightning.call("_build_telegraph", target)
			_lightning.add_child(ring)
			ring.global_position = target
			_serial += 1
			_lightning.get("_visuals")[_serial] = ring
			var material := ring.material_override as ShaderMaterial
			for index in 3:
				var progress: float = [0.1,0.5,0.9][index]
				material.set_shader_parameter("progress", progress)
				await _frame(prefix + "_0%d_warning" % (index+1), target, progress)
			_lightning.call("_receive", {"id":_serial,"kind":"impact","at":target,"hits":{}})
			await _frame(prefix + "_04_impact", target, 1.0)
			for _frame in 5:
				await process_frame
			await _frame(prefix + "_05_decay", target, 1.0)
			for _frame in 45:
				await process_frame
	STRIKE_MOTION.set_reduced_motion(false)
	print("STRIKE_CAPTURE_COMPLETE failures=", _failures)
	quit(0 if _failures.is_empty() else 1)

func _frame(id: String, target: Vector3, progress: float) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(1920,1080):
		_failures.append(id + ": native image missing")
		return
	if image.save_png(_output_dir.path_join(id + ".png")) != OK:
		_failures.append(id + ": write failed")
	var record := {"file":id + ".png", "proof":"DRY RUN — does not count", "target":_vec(target),
		"feet":_vec(_player.global_position), "camera":_vec(_camera.global_position),
		"rotation":_vec(_camera.global_rotation_degrees), "fov":_camera.fov,
		"warning_progress":progress,"phase":_surge.get("phase"),"flash":_surge.call("flash_level"),
		"reduced_motion":STRIKE_MOTION.reduced_motion()}
	_receipt.store_line(JSON.stringify(record))
	_receipt.flush()
	print("STRIKE_FRAME ", JSON.stringify(record))

func _vec(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

## Real production warning tween, sampled without saving PNGs in the timed
## loop. Fixed-FPS frames are simulation-time evidence, not a performance run.
func _timed_views() -> void:
	for view: Dictionary in [
		{"id":"outside", "at":Vector2(-598,753), "distance":10.0},
		{"id":"inside", "at":Vector2(-598,753), "distance":0.0},
		{"id":"brush_inside", "at":Vector2(-610,755), "distance":0.0}]:
		var xz: Vector2 = view.at
		var target := Vector3(xz.x, float(_world.call("ground_height_at",xz.x,xz.y)) + 0.08, xz.y)
		await _stand(xz - Vector2(0,float(view.distance)), target + Vector3(0,0,10), -12.0)
		await _enter_phase("break", false)
		_surge.set("_flash_next", 100000.0)
		_surge.set("_sky_next", 100000.0)
		_surge.set("_flash_echo", -1.0)
		for reduced: bool in [false,true]:
			STRIKE_MOTION.set_reduced_motion(reduced)
			for _settle in 45:
				await process_frame
			_serial += 1
			_lightning.call("_receive", {"id":_serial,"kind":"warning","at":target})
			var ring: MeshInstance3D = _lightning.get("_visuals")[_serial]
			var mat := ring.material_override as ShaderMaterial
			var images: Array[Image] = []
			var records: Array[Dictionary] = []
			var impact := false
			var end_frames := 0
			for frame in 110:
				await process_frame
				await RenderingServer.frame_post_draw
				var progress := float(mat.get_shader_parameter("progress"))
				if frame % 6 == 0 or progress >= 0.999 and not impact or impact and end_frames < 3:
					var shot := root.get_texture().get_image()
					images.append(shot)
					var id := "%s_%s_%03d" % [str(view.id), "reduced" if reduced else "normal",frame]
					records.append({"file":id+".png","proof":"DRY RUN — does not count", "frame":frame,
						"warning_progress":progress,"impact":impact,"flash":_surge.call("flash_level"),
						"reduced_motion":reduced,"target":_vec(target),"feet":_vec(_player.global_position),
						"camera":_vec(_camera.global_position),"rotation":_vec(_camera.global_rotation_degrees),"fov":_camera.fov})
				if impact:
					end_frames += 1
					if end_frames >= 24:
						break
				elif progress >= 0.999:
					impact = true
					_lightning.call("_receive", {"id":_serial,"kind":"impact","at":target,"hits":{}})
			if not impact:
				_failures.append(str(view.id)+": warning never reached impact")
			for i in images.size():
				if images[i].get_size() != Vector2i(1920,1080) or images[i].save_png(_output_dir.path_join(records[i].file)) != OK:
					_failures.append(str(records[i].file)+": image write/size failed")
				_receipt.store_line(JSON.stringify(records[i]))
			_receipt.flush()
			print("TIMED_STRIKE ", view.id, " reduced=", reduced, " frames=", images.size(), " impact=", impact)
