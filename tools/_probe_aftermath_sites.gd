extends SceneTree

## Diagnostic only (never evidence): boots the Meadows, frames each outdoor
## named fight's aftermath site object from the capture tool's site camera,
## then settles the trainer (trainer_aftermath.gd::settle, the after state the
## defeat flag restores) and frames it again. Checks a site_object layout in
## one boot instead of six full fights.
##
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/_probe_aftermath_sites.gd -- --out=/abs/dir [--trainers=a,b]

const SCENE := "res://scenes/world/meadows_playground.tscn"
const AFTERMATH := preload("res://scripts/world/trainer_aftermath.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const FIGHTS := ["relay_officer_dell", "relay_captain", "captain_riverwatch", "captain_field", "captain_ridge"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	var fixed := {}
	var fixed_requested := false
	var expected_preset := ""
	var saved := 0
	var candidate := false
	var ids: Array = FIGHTS.duplicate()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--cameras="):
			fixed_requested = true
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(a.trim_prefix("--cameras=")))
			if parsed is Dictionary:
				for view: Dictionary in (parsed as Dictionary).get("views", []):
					fixed[str(view.get("id", ""))] = view
		elif a.begins_with("--trainers="):
			ids = Array(a.trim_prefix("--trainers=").split(",", false))
		elif a.begins_with("--preset="):
			expected_preset = a.trim_prefix("--preset=")
		elif a == "--candidate":
			candidate = true
	if out.is_empty() or ids.is_empty() or DirAccess.make_dir_recursive_absolute(out) != OK:
		push_error("PROBE: valid --out and nonempty trainer selection required")
		quit(2)
		return
	if not expected_preset.is_empty() and (GRAPHICS.selected() != expected_preset or GRAPHICS.restart_required()):
		push_error("PROBE: actual preset/renderer does not match --preset=" + expected_preset)
		quit(2)
		return
	print("PROBE graphics: %s / %s" % [GRAPHICS.selected(), RenderingServer.get_current_rendering_method()])
	if fixed_requested:
		for id: String in ids:
			if not fixed.has(id):
				push_error("PROBE: requested fixed set lacks trainer " + id)
				quit(2)
				return
	# Diagnostic opt-in is process-local, never written to shipped config.
	AFTERMATH.config()["visual_candidate_enabled"] = candidate
	print("PROBE visual candidate: %s" % candidate)
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for i in 300:
		await physics_frame
	var look := get_first_node_in_group(&"day_cycle")
	var weather := world.get_node_or_null(^"WorldWeather")
	if look != null:
		look.call("reset_to_morning")
		look.call("set_clock_frozen", true)
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	if hud != null:
		hud.set("visible", false)
	var trainers := world.get_node_or_null(^"Trainers")
	var poses: Array = []
	var cam := Camera3D.new()
	cam.fov = 60.0
	root.add_child(cam)
	GRAPHICS.apply_camera(cam)
	for id: String in ids:
		var body: Node3D = trainers.call("body_for", id) as Node3D if trainers != null else null
		if body == null:
			print("PROBE %s: no body" % id)
			continue
		var before_site := AFTERMATH._meta_node(body, AFTERMATH.SITE_BEFORE_META)
		var after_site := AFTERMATH._meta_node(body, AFTERMATH.SITE_AFTER_META)
		if before_site == null or after_site == null or not before_site.visible or after_site.visible:
			push_error("PROBE: fresh undefeated site required for " + id)
			quit(2)
			return
		var points: Array[Vector3] = []
		for key: String in [AFTERMATH.SITE_BEFORE_META, AFTERMATH.STONE_META]:
			var node := AFTERMATH._meta_node(body, key)
			if node != null:
				var box := RENDER_BOUNDS.measure(node)
				if box.size != Vector3.ZERO:
					points.append(node.global_transform * box.get_center())
		if points.is_empty():
			print("PROBE %s: no site object" % id)
			continue
		var centre := Vector3.ZERO
		for p: Vector3 in points:
			centre += p
		centre /= float(points.size())
		var home: Transform3D = body.get_meta(AFTERMATH.HOME_META) if body.has_meta(AFTERMATH.HOME_META) else body.global_transform
		var yaw := home.basis.get_euler().y
		var forward := Vector3(sin(yaw), 0.0, cos(yaw))
		var right := Vector3(-cos(yaw), 0.0, sin(yaw))
		cam.global_transform = Transform3D(Basis(), centre + forward * 6.5 - right * 1.5 + Vector3.UP * 3.0) \
			.looking_at(centre + Vector3.UP * 0.7, Vector3.UP)
		if fixed.has(id):
			# Fixed camera set: the committed pose, not this round's framing.
			var view: Dictionary = fixed[id]
			var p: Array = view["pos"]
			var t: Array = view["look_at"]
			cam.fov = float(view.get("fov", 60.0))
			cam.global_transform = Transform3D(Basis(), Vector3(float(p[0]), float(p[1]), float(p[2]))) \
				.looking_at(Vector3(float(t[0]), float(t[1]), float(t[2])), Vector3.UP)
			if look == null or weather == null:
				push_error("PROBE: fixed set requires WorldLook and WorldWeather")
				quit(2)
				return
			weather.call("set_weather", str(view.get("weather", "clear")))
			look.call("apply_time", str(view.get("time_name", "morning")))
		cam.current = true
		for f in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		if _save_frame(out.path_join("%s-before.png" % id)):
			saved += 1
		AFTERMATH.settle(body, id)
		for f in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		if _save_frame(out.path_join("%s-after.png" % id)):
			saved += 1
		print("PROBE %s: framed at %s" % [id, str(centre)])
		var basis_euler := cam.global_transform.basis.get_euler()
		poses.append({"id": id, "pos": [cam.global_position.x, cam.global_position.y, cam.global_position.z],
			"yaw": rad_to_deg(basis_euler.y), "pitch": rad_to_deg(basis_euler.x), "fov": cam.fov,
			"look_at": fixed[id]["look_at"] if fixed.has(id) else [centre.x, centre.y + 0.7, centre.z]})
	# The fixed camera set (WORKFLOW 8.1 rule 10) is written from these poses.
	var file := FileAccess.open(out.path_join("cameras.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(poses, "\t") + "\n")
	print("PROBE done: %d/%d images (diagnostic only)" % [saved, ids.size() * 2])
	quit(0 if saved == ids.size() * 2 and file != null else 2)


func _save_frame(path: String) -> bool:
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(path) != OK:
		push_error("PROBE: image save failed: " + path)
		return false
	return true
