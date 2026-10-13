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
const FIGHTS := ["relay_officer_dell", "relay_captain", "captain_riverwatch", "captain_field", "captain_ridge"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	var ids: Array = FIGHTS.duplicate()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--trainers="):
			ids = Array(a.trim_prefix("--trainers=").split(",", false))
	DirAccess.make_dir_recursive_absolute(out)
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for i in 300:
		await physics_frame
	var look := get_first_node_in_group(&"day_cycle")
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
	for id: String in ids:
		var body: Node3D = trainers.call("body_for", id) as Node3D if trainers != null else null
		if body == null:
			print("PROBE %s: no body" % id)
			continue
		var points: Array[Vector3] = []
		for key: String in [AFTERMATH.SITE_BEFORE_META, AFTERMATH.STONE_META]:
			var node := AFTERMATH._meta_node(body, key)
			if node != null:
				var box := RENDER_BOUNDS.measure(node)
				if box.size != Vector3.ZERO:
					points.append(box.get_center())
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
		cam.current = true
		for f in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(out.path_join("%s-before.png" % id))
		AFTERMATH.settle(body, id)
		for f in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(out.path_join("%s-after.png" % id))
		print("PROBE %s: framed at %s" % [id, str(centre)])
		var basis_euler := cam.global_transform.basis.get_euler()
		poses.append({"id": id, "pos": [cam.global_position.x, cam.global_position.y, cam.global_position.z],
			"yaw": rad_to_deg(basis_euler.y), "pitch": rad_to_deg(basis_euler.x), "fov": cam.fov,
			"look_at": [centre.x, centre.y + 0.7, centre.z]})
	# The fixed camera set (WORKFLOW 8.1 rule 10) is written from these poses.
	var file := FileAccess.open(out.path_join("cameras.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(poses, "\t") + "\n")
	quit(0)
