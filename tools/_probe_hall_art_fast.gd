extends SceneTree

## T1-HALL-ART — fast single-boot look rig for the Hall's ASSET layer.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_hall_art_fast.gd
##
## WHY THIS EXISTS AND WHAT IT IS NOT EVIDENCE FOR.
##
## `tools/_judge_capture_hall.gd` instantiates the whole Meadows playground --
## Terrain3D, ~130k scattered props, the village, the NPC cast -- and that boot
## is 5-8 minutes before a single shutter opens, plus two 60-frame settle passes
## per stand waiting for the grass ring and the terrain bubble to stream in. That
## cost is correct for the judge's stands, because the thing being judged there is
## the fortress AGAINST its landscape: figure/ground separation, the bald
## mid-distance, the treeline. None of that means anything without the landscape.
##
## This rig answers a different and much narrower question -- **is the asset layer
## itself right?** Are the props where the config says, facing out of the wall
## rather than into it, at human scale, and does the stone read as weathered ruin
## with vegetation on it? For that the terrain is irrelevant, so this builds ONLY
## `stronghold.gd` under `art.json`'s own sun and environment, and boots in
## seconds instead of minutes.
##
## **These frames are therefore NOT valid evidence for the JUDGE-6 silhouette
## measurement**, and must never be substituted for it: there is no hill, no
## ground and no scatter in them, so `tools/_t1hall4_measure.py`'s fortress/hill
## boxes have nothing to compare against. Luminance numbers from these images
## would be meaningless. The full capture stays the source of truth for that;
## this is the iteration loop that stops a lane spending 8 minutes to discover a
## banner is facing into a wall.
##
## Sun, sky and tonemap are read from `data/config/art.json` rather than invented,
## so a surface that looks wrong here looks wrong in the game for the same reason.

const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const OUT_DIR := "res://shots/_hall_art_fast"
const ART := "res://data/config/art.json"
const POSE_FRAMES := 6
const SETTLE := 30

## Local-frame camera stands around the complex. `eye` and `look` are in the
## stronghold's OWN local frame (x lateral, z depth, origin `site.at`), the same
## frame `stronghold.json`'s `hall_occupation` block uses, so a stand here can be
## read straight against a placement there.
const STANDS := [
	# the causeway approach: the south elevation, scaffolds and gate banners
	{"name": "F-01-south-elevation", "eye": [0.0, -70.0, 16.0], "look": [0.0, -6.0, 8.0]},
	# three-quarter from the south-east, the read a player gets walking up
	{"name": "F-02-south-east-3q", "eye": [46.0, -52.0, 14.0], "look": [0.0, 4.0, 8.0]},
	# the east flank: courtyard wall ivy, flank scaffold and banner
	{"name": "F-03-east-flank", "eye": [58.0, 32.0, 12.0], "look": [0.0, 32.0, 7.0]},
	# close on the courtyard's west wall from inside: siphon, boiler, pipes, ivy
	{"name": "F-04-courtyard-interior", "eye": [6.0, 40.0, 3.0], "look": [-10.0, 26.0, 3.0]},
	# the west flank at range, for the whole silhouette
	{"name": "F-05-west-flank", "eye": [-64.0, 30.0, 20.0], "look": [0.0, 34.0, 9.0]},
]


func _init() -> void:
	_run()


func _colour(raw: Variant, fallback: String) -> Color:
	return Color(str(raw if raw != null else fallback))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var art: Dictionary = {}
	var f := FileAccess.open(ART, FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			art = parsed as Dictionary
	var sun_cfg: Dictionary = art.get("sun", {}) as Dictionary
	var sky_cfg: Dictionary = art.get("sky", {}) as Dictionary
	var env_cfg: Dictionary = art.get("environment", {}) as Dictionary

	var holder := Node3D.new()
	root.add_child(holder)

	# --- the Hall itself, and nothing else --------------------------------
	var hold: Node3D = STRONGHOLD.new()
	holder.add_child(hold)
	if not hold.call("build", holder, null, null):
		push_error("the Hall did not build")
		quit(1)
		return

	# --- art.json's own light and sky -------------------------------------
	var sun := DirectionalLight3D.new()
	sun.light_color = _colour(sun_cfg.get("colour"), "#fff6e6")
	sun.light_energy = float(sun_cfg.get("energy", 1.35))
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = float(sun_cfg.get("shadow_max_distance", 420.0))
	sun.shadow_normal_bias = float(sun_cfg.get("shadow_normal_bias", 2.0))
	sun.rotation_degrees = Vector3(
		float(sun_cfg.get("pitch_deg", -44.0)), float(sun_cfg.get("yaw_deg", 140.0)), 0.0)
	holder.add_child(sun)

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = _colour(sky_cfg.get("top_colour"), "#3b6f93")
	mat.sky_horizon_color = _colour(sky_cfg.get("horizon_colour"), "#d3cebd")
	mat.ground_horizon_color = _colour(sky_cfg.get("ground_horizon_colour"), "#b9c8cf")
	mat.ground_bottom_color = _colour(sky_cfg.get("ground_bottom_colour"), "#4a5648")
	sky.sky_material = mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _colour(env_cfg.get("ambient_colour"), "#a8bccc")
	env.ambient_light_energy = float(env_cfg.get("ambient_energy", 2.1))
	env.ambient_light_sky_contribution = float(env_cfg.get("ambient_sky_contribution", 0.1))
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = float(env_cfg.get("exposure", 0.6))
	env.tonemap_white = float(env_cfg.get("white", 6.0))
	world_env.environment = env
	holder.add_child(world_env)

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 3000.0
	holder.add_child(camera)
	camera.make_current()

	for i in SETTLE:
		await physics_frame

	# Report what actually got built, so a blank frame cannot be mistaken for a
	# correctly-built Hall that merely rendered badly.
	_report(hold)

	for entry: Variant in STANDS:
		var s: Dictionary = entry as Dictionary
		var eye: Array = s["eye"]
		var look: Array = s["look"]
		camera.global_position = hold.to_global(
			Vector3(float(eye[0]), float(eye[2]), float(eye[1])))
		camera.look_at(hold.to_global(
			Vector3(float(look[0]), float(look[2]), float(look[1]))), Vector3.UP)
		for i in 10:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/%s.png" % [OUT_DIR, str(s["name"])]
		image.save_png(path)
		print("[hall-art-fast] %s" % path)
	quit(0)


func _report(hold: Node3D) -> void:
	var reclaim: Node = hold.get_node_or_null(^"RuinReclaim")
	var retrofit: Node = hold.get_node_or_null(^"TetherRetrofit")
	var pipes: Node = hold.get_node_or_null(^"TetherPipes")
	var instances := 0
	var batches := 0
	if reclaim != null:
		for c in reclaim.get_children():
			if c is MultiMeshInstance3D:
				batches += 1
				instances += (c as MultiMeshInstance3D).multimesh.instance_count
	var props := 0
	var surfaces := 0
	var cores := 0
	var lights := 0
	if retrofit != null:
		for c in retrofit.get_children():
			props += 1
			surfaces += _surfaces(c)
			if c.find_child("TT_RiftCore", true, false) != null:
				cores += 1
			for sub in c.get_children():
				if sub is OmniLight3D:
					lights += 1
	var pieces := 0
	var pipe_surfaces := 0
	if pipes != null:
		for c in pipes.get_children():
			pieces += 1
			pipe_surfaces += _surfaces(c)
	print("[hall-art-fast] reclaim: %d instances / %d batches" % [instances, batches])
	print("[hall-art-fast] retrofit: %d props, %d surfaces, %d siphon cores, %d lights"
		% [props, surfaces, cores, lights])
	print("[hall-art-fast] pipes: %d pieces, %d surfaces" % [pieces, pipe_surfaces])
	print("[hall-art-fast] DRAW CALLS ADDED: %d" % [batches + surfaces + pipe_surfaces])


func _surfaces(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D:
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh != null:
			total += mesh.get_surface_count()
	for child in node.get_children():
		total += _surfaces(child)
	return total
