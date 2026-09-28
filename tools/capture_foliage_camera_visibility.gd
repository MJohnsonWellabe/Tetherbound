extends "res://tools/capture_stormwood_surge_phases.gd"
## DRY RUN — paired material-only controls in the production world/camera.
const VISIBILITY := preload("res://scripts/world/foliage_camera_visibility.gd")
var _materials: Array[Dictionary] = []
var _receipt: FileAccess
var _moving := false

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Foliage capture needs the real Compatibility renderer")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_output_dir = "res://shots/foliage-camera-stormwood"
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--motion": _moving = true
		if arg.begins_with("--biome="): _biome_id = arg.trim_prefix("--biome=")
		if arg.begins_with("--out="): _output_dir = arg.trim_prefix("--out=")
	root.size = Vector2i(1920,1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	_receipt = FileAccess.open(_output_dir.path_join("manifest.jsonl"),FileAccess.WRITE)
	if not await _mount_production_world() or not _prepare_capture_shell():
		quit(1)
		return
	_game = root.get_node(^"Game")
	_pin_day()
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_lightning = _world.get_node_or_null(^"StormwoodLightning")
	if _lightning != null: _lightning.set_process(false)
	var veg := _world.get_node(^"Vegetation")
	var assets: Object = _world.get_node(^"Terrain").call("get_assets")
	for model: String in VISIBILITY.config().models:
		if not veg.get("_mesh_ids").has(model): continue
		var asset: Object = assets.call("get_mesh_asset",int(veg.get("_mesh_ids")[model]))
		var mesh: Mesh = asset.call("get_mesh",0)
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as ShaderMaterial
			if material != null and material.has_meta("foliage_unfaded_material"):
				_materials.append({"mesh":mesh,"surface":surface,"fade":material,"source":material.get_meta("foliage_unfaded_material")})
	if _materials.is_empty():
		push_error("No production faded bush materials registered")
		quit(1)
		return
	var sites: Array[Vector2] = [Vector2(-610,755)]
	if _biome_id == "meadows":
		sites.clear()
		var bush_id := int(veg.get("_mesh_ids")[str(VISIBILITY.config().models[0])])
		var positions: PackedVector3Array = veg.get("_instance_positions")[bush_id]
		for wanted: Vector2 in [Vector2(0,450),Vector2(-100,3500)]:
			var nearest := Vector2.ZERO
			var distance := INF
			for pos in positions:
				var xz := Vector2(pos.x,pos.z)
				if xz.distance_squared_to(wanted) < distance:
					distance = xz.distance_squared_to(wanted)
					nearest = xz
			sites.append(nearest)
	for site_index in sites.size():
		var site := sites[site_index]
		if _moving:
			# The second Meadows stand faces a solid boulder; retain it for still
			# comparisons, not a forced traversal through unchanged collision.
			if site_index == 0: await _capture_motion(site,site_index,veg)
			continue
		for offset: float in [-6.0,-3.0,0.0,3.0,6.0]:
			var xz := site + Vector2(0,offset)
			await _place(xz)
			if _surge != null:
				await _enter_phase("break",false)
				_surge.set("_flash_next",100000.0)
				_surge.set("_sky_next",100000.0)
				_surge.set("_flash_echo",-1.0)
			var ring: MeshInstance3D
			if _lightning != null:
				ring = _lightning.call("_build_telegraph", _player.global_position)
				_lightning.add_child(ring)
				ring.global_position = _player.global_position
				(ring.material_override as ShaderMaterial).set_shader_parameter("progress",0.5)
			for enabled: bool in [false,true]:
				_toggle_visibility(enabled)
				for frame in 8: await process_frame
				await RenderingServer.frame_post_draw
				var picture := root.get_texture().get_image()
				var id := "site%d_offset%s_%s" % [site_index,str(int(offset)),"fade" if enabled else "control"]
				if picture.get_size() != Vector2i(1920,1080) or picture.save_png(_output_dir.path_join(id+".png")) != OK:
					_failures.append(id+": native save failed")
				var record := {"file":id+".png","proof":"DRY RUN — does not count","biome":_biome_id,"enabled":enabled,
					"site":[site.x,site.y],"offset":offset,"feet":_v3(_player.global_position),"camera":_v3(_camera.global_position),
					"rotation":_v3(_camera.global_rotation_degrees),"fov":_camera.fov,"materials":_materials.size(),
					"vegetation_instances":veg.get("_placed"),"harvest_points":veg.get("_harvest_points")}
				_receipt.store_line(JSON.stringify(record)); _receipt.flush()
				print("FOLIAGE_FRAME ",JSON.stringify(record))
			if ring != null: ring.queue_free()
		await _capture_angles(site,site_index)
	print("FOLIAGE_CAPTURE_COMPLETE failures=",_failures)
	quit(0 if _failures.is_empty() else 1)

func _capture_angles(site: Vector2, site_index: int) -> void:
	await _place(site)
	for pitch_degrees: float in [-45.0,25.0]:
		_rig.set("pitch",deg_to_rad(pitch_degrees))
		_rig.rotation = Vector3(deg_to_rad(pitch_degrees),PI,0)
		for frame in 75: await physics_frame
		for enabled: bool in [false,true]:
			_toggle_visibility(enabled)
			for frame in 8: await process_frame
			await RenderingServer.frame_post_draw
			var id := "site%d_pitch%d_%s" % [site_index,int(pitch_degrees),"fade" if enabled else "control"]
			var picture := root.get_texture().get_image()
			if picture.get_size() != Vector2i(1920,1080) or picture.save_png(_output_dir.path_join(id+".png")) != OK:
				_failures.append(id+": native save failed")
			_receipt.store_line(JSON.stringify({"file":id+".png","proof":"DRY RUN — staged camera pitch",
				"biome":_biome_id,"enabled":enabled,"feet":_v3(_player.global_position),
				"camera":_v3(_camera.global_position),"rotation":_v3(_camera.global_rotation_degrees),"fov":_camera.fov}))
			_receipt.flush()

func _capture_motion(site: Vector2, site_index: int, veg: Node) -> void:
	# Scripted input after a staged arrival, not earned-route/performance proof.
	# Production locomotion, grounding, animation and camera run for two seconds.
	for enabled: bool in [false,true]:
		_toggle_visibility(enabled)
		await _place(site + Vector2(0,-6))
		if _surge != null:
			await _enter_phase("break",false)
			_surge.set("_flash_next",100000.0)
			_surge.set("_sky_next",100000.0)
			_surge.set("_flash_echo",-1.0)
		var start := _player.global_position
		_player.call("set_locomotion_enabled",true)
		Input.action_press("move_forward")
		for frame in 121:
			await physics_frame
			await RenderingServer.frame_post_draw
			var id := "site%d_%s_%03d" % [site_index,"fade" if enabled else "control",frame]
			var picture := root.get_texture().get_image()
			if picture.get_size() != Vector2i(1920,1080) or picture.save_png(_output_dir.path_join(id+".png")) != OK:
				_failures.append(id+": native save failed")
			_receipt.store_line(JSON.stringify({"file":id+".png","proof":"DRY RUN — staged arrival plus scripted move_forward input",
				"biome":_biome_id,"enabled":enabled,"frame":frame,"nominal_seconds":frame/60.0,
				"feet":_v3(_player.global_position),"camera":_v3(_camera.global_position),"fov":_camera.fov,
				"vegetation_instances":veg.get("_placed"),"harvest_points":veg.get("_harvest_points")}))
			_receipt.flush()
		Input.action_release("move_forward")
		if _player.global_position.distance_to(start) < 4.0:
			_failures.append("motion traversal covered under four metres")
		print("FOLIAGE_MOTION_COMPLETE site=",site_index," enabled=",enabled)

func _place(xz: Vector2) -> void:
	if not bool(_game.call("debug_teleport_to",xz.x,xz.y,_biome_id,"")):
		_failures.append("teleport refused")
	for frame in 10: await physics_frame
	var ground := _floor_at(xz.x,xz.y,4.0)
	_player.global_position = Vector3(xz.x,ground+TRAINER_CLEARANCE,xz.y)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = 0.0
	_rig.call("set_target",_player)
	_rig.set("yaw",PI); _rig.set("pitch",deg_to_rad(-12.0))
	_rig.rotation = Vector3(deg_to_rad(-12.0),PI,0)
	_rig.global_position = _player.global_position
	_player.reset_physics_interpolation(); _rig.reset_physics_interpolation(); _camera.reset_physics_interpolation()
	for frame in 75: await physics_frame
	_hud_visible(false)

func _v3(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

func _toggle_visibility(enabled: bool) -> void:
	for entry in _materials:
		(entry.mesh as Mesh).surface_set_material(entry.surface,entry.fade if enabled else entry.source)

func _hud_visible(on: bool) -> void:
	# Meadows has no StormwoodSurge node. The world walk already includes any
	# surge CanvasLayers, so the inherited second walk is unnecessary here.
	for layer: Node in _world.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = on
