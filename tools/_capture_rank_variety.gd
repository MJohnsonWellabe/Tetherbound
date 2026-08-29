extends SceneTree

## T1-NPC-CAST evidence render. The owner asked this lane to PROVE, not just
## claim from reading JSON, whether the shipped grunt/officer/captain rank
## ladder gives the three-grunts / two-officers / two-captains VARIETY the
## NPC design board draws, or whether named individuals within one rank
## actually render identically. Built on the same staging pattern as
## `_capture_character_cast.gd` (bare stage, build once, shoot per-slot),
## narrowed to just the rank ladder's NAMED individuals, through the real
## `trainer_npc.gd::model_config()` path the shipped world places them with.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_rank_variety.gd
##
## Scratch/evidence tool, not a shipped asset -- not wired into any test.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const OUT_DIR := "res://shots/rank_variety"

## Every NAMED grunt/officer/captain currently in data/config/bands/*/trainers.json,
## grouped the way the board groups Grunt A/B/C, Officer A/B, Captain A/B.
const CAST := [
	{"slug": "grunt-dorn", "key": "quarry_picket_dorn"},
	{"slug": "grunt-pell", "key": "warrens_watch_pell"},
	{"slug": "grunt-kest", "key": "band2_outrider_kest"},
	{"slug": "officer-dell", "key": "relay_officer_dell"},
	{"slug": "officer-solene", "key": "stronghold_courtyard"},
	{"slug": "officer-ness", "key": "stronghold_checkpoint"},
	{"slug": "captain-vance", "key": "relay_captain"},
	{"slug": "captain-oreth", "key": "captain_riverwatch"},
	{"slug": "captain-halder", "key": "captain_field"},
	{"slug": "captain-vess", "key": "captain_ridge"},
	{"slug": "captain-hald", "key": "stronghold_elite"},
]

const SPACING := 3.0
const WORLD_SETTLE_FRAMES := 15
const GROUP_SETTLE_FRAMES := 35
const TURN_FRAMES := 6
const LINEUP_SETTLE_FRAMES := 15

const FOV := 45.0
const DIST := 3.0
const CAM_HEIGHT := 1.3
const LOOK_HEIGHT := 1.0
const THREE_QUARTER_DEG := 35.0

const LINEUP_SPACING := 1.15
const LINEUP_FOV := 48.0
const LINEUP_DIST := 11.0
const LINEUP_CAM_HEIGHT := 1.15
const LINEUP_LOOK_HEIGHT := 0.92


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world := Node3D.new()
	root.add_child(world)
	_build_environment(world)
	for i in WORLD_SETTLE_FRAMES:
		await process_frame

	var holders: Array[Node3D] = []
	var heights: Array[float] = []
	for i in CAST.size():
		var entry: Dictionary = CAST[i] as Dictionary
		var slug: String = str(entry.get("slug", "?"))
		var cfg := _config_for(str(entry.get("key", "")))
		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		holder.position = Vector3(i * SPACING, 0.0, 0.0)
		world.add_child(holder)
		var built := false
		if not cfg.is_empty():
			built = bool(holder.call("build_from_config", cfg))
		if not built:
			var reason := "no config found" if cfg.is_empty() else "build_from_config() returned false"
			print("FAIL %s: could not stage this character (%s)" % [slug, reason])
			holder.queue_free()
			holders.append(null)
			heights.append(-1.0)
			continue
		if holder.has_method("play"):
			holder.call("play", "idle")
		var box: AABB = RENDER_BOUNDS.measure(holder)
		holder.position.y = -box.position.y * holder.scale.y
		holders.append(holder)
		heights.append(box.size.y)

	for i in GROUP_SETTLE_FRAMES:
		await process_frame

	var camera := Camera3D.new()
	camera.far = 200.0
	world.add_child(camera)
	camera.make_current()

	for i in CAST.size():
		var holder: Node3D = holders[i]
		if holder == null:
			continue
		var entry: Dictionary = CAST[i] as Dictionary
		var slug: String = str(entry.get("slug", "?"))
		var slot_x: float = i * SPACING
		var height_m: float = heights[i]
		var stem := "%02d-%s" % [i + 1, slug]

		for other in holders:
			if other != null:
				(other as Node3D).visible = (other == holder)
		holder.rotation.y = 0.0
		_frame_portrait(camera, slot_x)
		for f in TURN_FRAMES:
			await process_frame
		await _shoot("%s-front" % stem, height_m)

		holder.rotation.y = deg_to_rad(THREE_QUARTER_DEG)
		for f in TURN_FRAMES:
			await process_frame
		await _shoot("%s-threequarter" % stem, height_m)

		holder.rotation.y = 0.0
		for other in holders:
			if other != null:
				(other as Node3D).visible = true

	var live := holders.filter(func(h: Node3D) -> bool: return h != null)
	if live.size() < 2:
		print("FAIL lineup: fewer than two characters staged; skipping")
	else:
		for i in CAST.size():
			if holders[i] != null:
				(holders[i] as Node3D).position.x = i * LINEUP_SPACING
		_frame_lineup(camera)
		for f in LINEUP_SETTLE_FRAMES:
			await process_frame
		await _shoot("%02d-lineup-all" % (CAST.size() + 1), -1.0)

	print("")
	print("rank variety cast written to %s" % OUT_DIR)
	quit(0)


## Through the REAL placement path -- rank config, then that trainer's own
## site overrides layered over it -- exactly as `trainer_npc.gd` builds the
## body the player actually meets. Not `npc_ranks.config_for()` alone, which
## would hide any per-site override that DOES exist (three of five captains
## have one; every grunt and officer has none -- see the id list above).
func _config_for(trainer_id: String) -> Dictionary:
	var spec: Dictionary = TRAINER_NPC.trainer(trainer_id)
	if spec.is_empty():
		print("FAIL %s: no trainer entry with that id" % trainer_id)
		return {}
	return TRAINER_NPC.model_config(spec)


func _build_environment(world: Node3D) -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.28, 0.30, 0.33)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.90)
	env.ambient_light_energy = 0.28
	env_node.environment = env
	world.add_child(env_node)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400.0, 400.0)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.34, 0.35, 0.37)
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(-18.0), 0.0)
	key.light_energy = 0.34
	key.shadow_enabled = true
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(170.0), 0.0)
	fill.light_energy = 0.19
	fill.light_color = Color(0.80, 0.85, 0.95)
	world.add_child(fill)


func _frame_portrait(camera: Camera3D, slot_x: float) -> void:
	camera.fov = FOV
	camera.global_position = Vector3(slot_x, CAM_HEIGHT, DIST)
	camera.look_at(Vector3(slot_x, LOOK_HEIGHT, 0.0), Vector3.UP)


func _frame_lineup(camera: Camera3D) -> void:
	var centre_x: float = (CAST.size() - 1) * 0.5 * LINEUP_SPACING
	camera.fov = LINEUP_FOV
	camera.global_position = Vector3(centre_x, LINEUP_CAM_HEIGHT, LINEUP_DIST)
	camera.look_at(Vector3(centre_x, LINEUP_LOOK_HEIGHT, 0.0), Vector3.UP)


func _label(text: String) -> void:
	if _caption == null:
		var layer := CanvasLayer.new()
		root.add_child(layer)
		_caption = Label.new()
		_caption.position = Vector2(24, 20)
		_caption.add_theme_font_size_override("font_size", 22)
		_caption.add_theme_color_override("font_color", Color(1, 1, 1))
		_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_caption.add_theme_constant_override("outline_size", 6)
		layer.add_child(_caption)
	_caption.text = text


var _caption: Label = null


func _shoot(name: String, height_m: float) -> void:
	_label(name if height_m < 0.0 else "%s  -  %.2f m" % [name, height_m])
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % name)
		return
	print("  %-28s -> %s" % [name, path])
