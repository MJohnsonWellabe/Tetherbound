extends SceneTree

## Dialogue portraits, rendered from the installed humanoid rigs.
##
##   xvfb-run -a -s "-screen 0 640x640x24" godot --path . \
##     --rendering-driver opengl3 --resolution 640x640 \
##     --script tools/_capture_portraits.gd [-- <file> ...]
##
## Evidence mode -- one real conversation in the booted world, the panel the
## player sees, at the ROG Ally's own 1280x800 (frames stacked into one
## `_sheet` PNG under ralph/reports/W04-PORTRAITS-0904/):
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_portraits.gd -- --ingame
##
## NEVER `--headless` together with a rendering driver (it hangs).
##
## Why this exists (owner, 2026-09-04, item 8b): every NPC spoke with the
## player's face because `assets/ui/portraits/` held two plates. This writes
## the rest -- one plate per installed humanoid body the dialogue actually
## names -- so `data/dialogue/*.json` can point each speaker at a face that
## is theirs. No new mesh, no generation: every entry below is a
## `data/config/art.json` body, dressed exactly the way the game dresses it
## (`village_npcs.gd::model_config()` is the same call the world makes, so a
## rank palette, a base override and a named villager's hair colour all land
## on the plate the way they land on the body).
##
## Framing matches the two painted plates already on disk (`trainer.png`,
## `grandpa.png`): 256x256, transparent ground, head and shoulders filling
## the frame, the face turned a few degrees off straight-on. Rendered at
## 512 and downscaled for the anti-aliasing the Compatibility renderer does
## not give a SubViewport for free.
##
## `trainer.png` and `grandpa.png` are painted plates and are NOT
## overwritten; ask for them by name on the command line to render a rig
## version alongside for comparison (written under OUT_DIR, never over the
## shipped file).

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const PORTRAIT_DIR := "res://assets/ui/portraits"
const OUT_DIR := "res://shots/portraits"
const SHEET_PATH := "res://ralph/reports/W04-PORTRAITS-0904/_sheet_portraits.png"
const INGAME_SHEET_PATH := "res://ralph/reports/W04-PORTRAITS-0904/_sheet_ingame_conversations.png"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
## Measured by tools/_capture_ui_survey.gd: the world stands up complete
## inside this many physics frames under software GL.
const BOOT_FRAMES := 90
## Villager -> the conversation the world opens when the player greets them
## (data/config/village_npcs.json `greeting`). Halda and Oskar both stand
## outdoors in the square, so no interior has to be entered to reach them.
const INGAME_CONVERSATIONS := [
	{"npc": "Halda", "conversation": "tournament_halda"},
	{"npc": "Oskar", "conversation": "village_oskar"},
]

const RENDER_SIZE := 512
const PLATE_SIZE := 256

## Vertical field of view and the window it frames. The window hangs from the
## measured top of the rig (hair, hat or crown -- `render_bounds.gd`, the same
## measurement `_fit()` stands the body up with) rather than from a head bone,
## because the installed rigs do not agree on where "Head" sits: the villager
## rigs put it at the base of the skull and the Warden's near the crown, and
## round one cropped his face in half for it. WINDOW_HEIGHT is what shows
## below the hair top on a 1.80 m body (down to the collar and shoulder line),
## scaled with the body's height so a 1.50 m body's larger head still fills
## the same share of the plate.
const FOV_DEG := 28.0
const WINDOW_HEIGHT := 0.58
const HEADROOM := 0.025
const REFERENCE_HEIGHT := 1.8
## Turn the body this much so the face reads three-quarter rather than
## passport-flat, the way the two painted plates do.
const BODY_YAW_DEG := -22.0

## file (without .png) -> the spec `village_npcs.gd::model_config()` reads.
## The first eight are the fixed cross-lane contract; the rest are the named
## cast, each keyed to the body and dressing the world gives that speaker.
const PORTRAITS: Array = [
	# --- contract plates ---------------------------------------------------
	{"file": "villager_male", "config_key": "villager_keeper"},
	{"file": "villager_female", "config_key": "villager_farmer", "hair": {"visible": true}},
	{"file": "grunt", "rank": "grunt"},
	{"file": "officer", "rank": "officer"},
	{"file": "captain", "rank": "captain"},
	{"file": "warden", "rank": "warden"},
	# --- villagers on the shared female rig, told apart by hair ------------
	{"file": "mira", "config_key": "villager_farmer"},
	{"file": "tam", "config_key": "villager_smith"},
	{"file": "villager_ranger", "config_key": "villager_ranger"},
	{"file": "halda", "config_key": "villager_ranger", "hair": {"visible": true, "color": "#8f8f96"}},
	{"file": "rae", "config_key": "villager_farmer", "hair": {"visible": true, "color": "#7a4a2c"}},
	{"file": "doss", "config_key": "villager_ranger", "hair": {"visible": true, "color": "#4a5c3d"}},
	# --- named cast with their own installed body ---------------------------
	{"file": "bryn", "config_key": "young_trainer"},
	{"file": "wandering_trainer", "config_key": "wandering_trainer"},
	{"file": "juno", "config_key": "rival_trainer"},
	{"file": "wilhelm", "config_key": "innkeeper"},
	{"file": "nessa", "config_key": "inn_helper"},
	{"file": "corin", "config_key": "trader"},
	{"file": "ada", "config_key": "craftsperson"},
	{"file": "fenn", "config_key": "creature_caretaker"},
	{"file": "garrick", "config_key": "farmer"},
	{"file": "old_perrin", "config_key": "local_historian"},
	{"file": "tobin", "config_key": "lost_traveler"},
	{"file": "maren", "config_key": "field_researcher"},
	{"file": "sorrel", "config_key": "alpha_tracker"},
	{"file": "lark", "config_key": "courier"},
	{"file": "ren", "config_key": "former_tether_member"},
	# --- Team Tether individuals: rank palette over a per-body base --------
	{"file": "grunt_a", "rank": "grunt", "base": "grunt_a"},
	{"file": "grunt_b", "rank": "grunt", "base": "grunt_b"},
	{"file": "grunt_c", "rank": "grunt", "base": "grunt_c"},
	{"file": "officer_a", "rank": "officer", "base": "officer_a"},
	{"file": "officer_b", "rank": "officer", "base": "officer_b"},
	{"file": "captain_a", "rank": "captain", "base": "captain_a"},
	{"file": "captain_b", "rank": "captain", "base": "captain_b"},
]

## Painted plates that already ship. Rendered only on request, and then to
## OUT_DIR rather than over the shipped file.
const PAINTED := {"trainer": {"config_key": "trainer"}, "grandpa": {"config_key": "grandpa"}}

var _viewport: SubViewport = null
var _stage: Node3D = null
var _camera: Camera3D = null
var _plates: Dictionary = {}
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; use xvfb-run")
		quit(1)
		return

	var wanted: Array = []
	for arg in OS.get_cmdline_user_args():
		wanted.append(str(arg))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHEET_PATH.get_base_dir()))

	if wanted.has("--ingame"):
		await _capture_ingame()
		print("")
		print("%d in-game frames, %d failures" % [_plates.size(), _failures.size()])
		for failure in _failures:
			print("  FAIL " + failure)
		quit(0 if _failures.is_empty() else 1)
		return

	# Daylight look: the rank palettes carry an emission floor for night
	# legibility, and a portrait is not a night frame.
	CHARACTER_MODEL.set_emission_floor_scale(0.0)

	_build_stage()
	for i in 10:
		await process_frame

	var specs: Array = []
	if wanted.is_empty():
		specs = PORTRAITS
	else:
		for spec in PORTRAITS:
			if wanted.has(str(spec["file"])):
				specs.append(spec)
		for painted: String in PAINTED:
			if wanted.has(painted):
				var copy: Dictionary = (PAINTED[painted] as Dictionary).duplicate()
				copy["file"] = painted
				copy["scratch_only"] = true
				specs.append(copy)

	for spec in specs:
		await _render_plate(spec)

	_write_sheet()

	print("")
	print("%d plates written, %d failures" % [_plates.size(), _failures.size()])
	for failure in _failures:
		print("  FAIL " + failure)
	quit(0 if _failures.is_empty() else 1)


func _build_stage() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(RENDER_SIZE, RENDER_SIZE)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	_stage = Node3D.new()
	_viewport.add_child(_stage)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.88, 0.92)
	env.ambient_light_energy = 0.18
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env_node.environment = env
	_stage.add_child(env_node)

	# Key: high front-left, warm. Fill: low front-right, cool and soft.
	# Rim: behind and above, to lift the hair and shoulder line off the
	# transparent ground the panel composites this over.
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(-32.0), 0.0)
	key.light_energy = 0.62
	key.light_color = Color(1.0, 0.96, 0.90)
	key.shadow_enabled = true
	_stage.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-12.0), deg_to_rad(40.0), 0.0)
	fill.light_energy = 0.26
	fill.light_color = Color(0.82, 0.88, 1.0)
	_stage.add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-30.0), deg_to_rad(160.0), 0.0)
	rim.light_energy = 0.38
	rim.light_color = Color(1.0, 0.98, 0.94)
	_stage.add_child(rim)

	_camera = Camera3D.new()
	_camera.fov = FOV_DEG
	_camera.near = 0.05
	_camera.far = 50.0
	_stage.add_child(_camera)
	_camera.make_current()


func _render_plate(spec: Dictionary) -> void:
	var file := str(spec["file"])
	var cfg: Dictionary = VILLAGE_NPCS.model_config(spec)
	if cfg.is_empty():
		_failures.append("%s: no config resolved from %s" % [file, JSON.stringify(spec)])
		return

	var holder := Node3D.new()
	holder.set_script(CHARACTER_MODEL)
	_stage.add_child(holder)
	if not bool(holder.call("build_from_config", cfg)):
		_failures.append("%s: build_from_config refused %s" % [file, str(cfg.get("model", ""))])
		holder.queue_free()
		return
	holder.rotation.y = deg_to_rad(BODY_YAW_DEG)
	if holder.has_method("play"):
		holder.call("play", "idle")
	# Let the animation settle on its first pose and the skin update.
	for i in 6:
		await process_frame

	var height := float(holder.call("height"))
	var box: AABB = RENDER_BOUNDS.measure(holder)
	var top_y := box.position.y + box.size.y
	var head_y := _head_height(holder, box)
	var scale := clampf(height / REFERENCE_HEIGHT, 0.7, 1.3)
	var window := WINDOW_HEIGHT * scale
	var centre_y := top_y + HEADROOM * scale - window * 0.5
	var distance := (window * 0.5) / tan(deg_to_rad(FOV_DEG * 0.5))
	# Centre on the rig's own midline, not the world origin: `_fit()` recentres
	# the art on x/z but a turned body's head drifts off the axis.
	var centre_x := box.position.x + box.size.x * 0.5
	var centre_z := box.position.z + box.size.z * 0.5
	_camera.position = Vector3(centre_x, centre_y, centre_z + distance)
	_camera.look_at(Vector3(centre_x, centre_y, centre_z), Vector3.UP)

	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = _viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("%s: viewport returned no image" % file)
		holder.queue_free()
		return
	image.convert(Image.FORMAT_RGBA8)
	image.resize(PLATE_SIZE, PLATE_SIZE, Image.INTERPOLATE_LANCZOS)

	var opaque := _opaque_fraction(image)
	var target := "%s/%s.png" % [OUT_DIR, file]
	if not bool(spec.get("scratch_only", false)):
		target = "%s/%s.png" % [PORTRAIT_DIR, file]
	if image.save_png(target) != OK:
		_failures.append("%s: save_png failed for %s" % [file, target])
	else:
		_plates[file] = image
		print("  %-18s body=%-22s h=%.2f top=%.2f head_y=%.2f opaque=%.0f%% -> %s" % [
			file, str(cfg.get("model", "")).get_file().get_basename(), height, top_y, head_y,
			opaque * 100.0, target])
	if opaque < 0.15 or opaque > 0.95:
		_failures.append("%s: %.0f%% opaque pixels -- framing is off (empty or wall-to-wall)" % [
			file, opaque * 100.0])

	holder.queue_free()
	for i in 3:
		await process_frame


## World-space height of the rig's head bone, or a proportional guess from
## the render bounds when a rig has no bone by that name.
func _head_height(holder: Node3D, box: AABB) -> float:
	var skeleton: Skeleton3D = holder.call("skeleton")
	if skeleton != null:
		for bone_name in ["Head", "head", "mixamorig_Head", "DEF-spine.006"]:
			var idx := skeleton.find_bone(bone_name)
			if idx >= 0:
				var pose: Transform3D = skeleton.get_bone_global_pose(idx)
				return (skeleton.global_transform * pose).origin.y
	return box.position.y + box.size.y * 0.86


func _opaque_fraction(image: Image) -> float:
	var count := 0
	var total := image.get_width() * image.get_height()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.5:
				count += 1
	return float(count) / float(maxi(total, 1))


## One contact sheet of every plate written this run, on a mid grey so the
## alpha edge is visible; cells run in file-name order, left to right.
func _write_sheet() -> void:
	if _plates.is_empty():
		return
	var names: Array = _plates.keys()
	names.sort()
	var columns := 6
	var rows := int(ceil(float(names.size()) / float(columns)))
	var cell := PLATE_SIZE
	var sheet := Image.create(columns * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.42, 0.44, 0.47, 1.0))
	for i in names.size():
		var plate: Image = _plates[names[i]]
		var at := Vector2i((i % columns) * cell, (i / columns) * cell)
		sheet.blend_rect(plate, Rect2i(0, 0, cell, cell), at)
	var path := ProjectSettings.globalize_path(SHEET_PATH)
	if sheet.save_png(path) == OK:
		print("sheet -> %s (%s)" % [SHEET_PATH, ", ".join(PackedStringArray(names))])
	else:
		_failures.append("sheet: save_png failed for %s" % path)


## --- evidence: the panel over the real world ---------------------------------

## Boot the Meadows, walk the player up to a villager, open the conversation
## the world would open on a greet, and photograph the screen. The camera is
## our own (the rig is stood down, as every survey tool here does) so the
## speaker's body is in frame beside their plate; the panel, the HUD and the
## world are the real ones.
func _capture_ingame() -> void:
	var packed: PackedScene = load(WORLD_SCENE)
	if packed == null:
		_failures.append("ingame: could not load %s" % WORLD_SCENE)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	current_scene = world
	for i in BOOT_FRAMES:
		await physics_frame
	print("[ingame] world booted")

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var rig: Node = world.get_node_or_null(^"CameraRig")
	var panel: Node = get_first_node_in_group("dialogue_panel")
	var villagers: Node = world.get_node_or_null(^"VillageNPCs")
	if player == null or rig == null or panel == null or villagers == null:
		_failures.append("ingame: missing Player/CameraRig/dialogue_panel/VillageNPCs")
		return
	rig.set_process(false)
	rig.set_physics_process(false)

	var field: RefCounted = HEIGHTFIELD.new()
	var camera := Camera3D.new()
	camera.fov = 55.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var frames: Array[Image] = []
	for entry in INGAME_CONVERSATIONS:
		var npc_name := str(entry["npc"])
		var conversation := str(entry["conversation"])
		var npc: Node3D = villagers.get_node_or_null(NodePath(npc_name)) as Node3D
		if npc == null:
			_failures.append("ingame: no villager named %s in VillageNPCs" % npc_name)
			continue
		var at: Vector3 = npc.global_position
		# The villagers face the square's well; stand the player on that side.
		var toward_well := Vector3(-at.x, 0.0, -at.z).normalized()
		var stand := at + toward_well * 2.2
		stand.y = field.height_at(stand.x, stand.z) + 0.4
		player.global_position = stand
		player.velocity = Vector3.ZERO
		player.look_at(Vector3(at.x, stand.y, at.z), Vector3.UP)
		# Over the player's shoulder, but wide enough that the SPEAKER holds
		# the frame: the player is a shoulder at the edge, the villager sits
		# centre-left above the box (round-one judge: the player model
		# dominated both frames and the speaker was the hardest thing to see).
		var right := toward_well.cross(Vector3.UP).normalized()
		var eye := stand + toward_well * 0.9 + right * 2.1 + Vector3.UP * 1.45
		camera.global_position = eye
		camera.look_at(at + Vector3.UP * 1.25 - right * 0.35, Vector3.UP)
		for i in 12:
			await physics_frame

		if not bool(panel.call("start", conversation)):
			_failures.append("ingame: panel refused start('%s')" % conversation)
			continue
		for i in 12:
			await physics_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		if image == null or image.is_empty():
			_failures.append("ingame: no image for %s" % conversation)
		else:
			image.convert(Image.FORMAT_RGBA8)
			frames.append(image)
			_plates[conversation] = image
			print("  %-20s %s at %s -> frame %dx%d" % [
				conversation, npc_name, str(at), image.get_width(), image.get_height()])
		panel.call("close")
		for i in 6:
			await physics_frame

	if frames.is_empty():
		return
	var width := frames[0].get_width()
	var height := 0
	for frame in frames:
		height += frame.get_height()
	var sheet := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var y := 0
	for frame in frames:
		sheet.blit_rect(frame, Rect2i(0, 0, frame.get_width(), frame.get_height()), Vector2i(0, y))
		y += frame.get_height()
	if sheet.save_png(ProjectSettings.globalize_path(INGAME_SHEET_PATH)) == OK:
		print("sheet -> %s" % INGAME_SHEET_PATH)
	else:
		_failures.append("ingame: save_png failed for %s" % INGAME_SHEET_PATH)
