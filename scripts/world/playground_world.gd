extends Node3D

## Builds the M1 playground at runtime from baked Terrain3D data.
##
## The Terrain3D node is created in code rather than saved into the scene. A
## GDExtension node stored in a .tscn breaks the whole scene if the extension is
## missing or its version moves, and it turns "did you install the addon?" into
## a corrupt-scene error instead of a clear message. Creating it here means the
## failure is one readable push_error and the rest of the playground still runs.
##
## The terrain itself is authored data, baked once by
## scripts/world/build_playground_terrain.gd. Nothing generates terrain at run
## time and nothing should: per the owner's direction the terrain is authored
## macro geography, not a procedural seed.

const DATA_DIR := "res://data/terrain/playground"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const VEGETATION := preload("res://scripts/world/vegetation.gd")

## Terrain3D.CollisionMode. 3 is FULL_GAME: real collision shapes across the
## loaded regions, which is what the character controller needs to walk on.
const COLLISION_FULL_GAME := 3

## Metres above the sampled ground to drop the player from, so a small mismatch
## between the collision bake and the heightfield does not spawn them inside it.
const SPAWN_CLEARANCE := 2.0

@onready var _player: CharacterBody3D = $Player
@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D

var _terrain: Node3D = null
var _vegetation: Node3D = null


func _ready() -> void:
	_terrain = _build_terrain()
	if _terrain == null:
		return

	# data_directory MUST be set after the node is in the tree and a frame has
	# passed. Terrain3D builds its Terrain3DData on first frame, and assigning
	# the directory before that silently leaves `data` null with nothing but a
	# "Resource file not found: res://" in the log. The terrain then renders
	# nothing, has no collision, and the player stands on empty space at the
	# origin — which looks enough like working that it is worth this comment.
	await get_tree().process_frame
	_terrain.set("data_directory", DATA_DIR)
	await get_tree().process_frame

	# collision_mode is set HERE, after the data is loaded, and then read back.
	#
	# Setting it before the node entered the tree silently reverted to 1
	# (Dynamic/Game), which builds collision only inside a 64m bubble. Everything
	# looked correct: the terrain rendered, the player spawned on the ground, and
	# the smoke test passed — because all of that happens within the bubble. Walk
	# a couple of hundred metres and the ground stops existing and you fall
	# through the world at terminal velocity.
	_terrain.set("collision_mode", COLLISION_FULL_GAME)
	var applied: int = int(_terrain.get("collision_mode"))
	if applied != COLLISION_FULL_GAME:
		push_error("terrain collision_mode is %d, expected %d (Full/Game). " % [applied, COLLISION_FULL_GAME] +
			"The player will fall through the world outside the dynamic collision radius.")

	_apply_ground_materials()

	# Terrain3D needs a camera to decide which regions to keep resident. Without
	# it the extension logs an error every physics frame and stops processing.
	if _terrain.has_method("set_camera"):
		_terrain.call("set_camera", _camera)
	_place_player()
	_dress_the_meadow()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_terrain() -> Node3D:
	if not ClassDB.class_exists("Terrain3D"):
		push_error("Terrain3D addon is not installed or failed to load. " +
			"Check addons/terrain_3d/ and that the extension matches this Godot build.")
		return null
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(DATA_DIR)):
		push_error("No baked terrain at %s. Run: godot --headless --path . " % DATA_DIR +
			"--script scripts/world/build_playground_terrain.gd")
		return null

	var config := _load_terrain_config()
	var terrain: Node3D = ClassDB.instantiate("Terrain3D")
	terrain.name = "Terrain"
	terrain.set("region_size", int(config.get("region_size", 256)))
	terrain.set("vertex_spacing", float(config.get("vertex_spacing", 1.0)))
	# One collision shape per region rather than the 16m default, which over a
	# 512m playground would ask for 1024 shapes instead of four. Set before the
	# node enters the tree: the shape pool is allocated once, so changing this
	# later and calling build() does nothing.
	#
	# This is a cost choice, not a correctness one. The playground is solid at
	# either setting — see ground_height_at() below for the thing that actually
	# was broken.
	terrain.set("collision_shape_size", int(config.get("region_size", 256)))
	# collision_mode is deliberately NOT set here; see _ready() for why.
	add_child(terrain)
	return terrain


## Give the ground real PBR materials.
##
## Until now this switched on `show_colormap`, a Terrain3D DEBUG VIEW, and used
## it as the ground treatment. It was flagged as a placeholder when it went in
## and it survived three milestones. The blind critic measured what it cost:
## 78–91% of the lower half of every exploration frame was featureless flat
## fill, against 3–13% for the references — because a vertex colour map has no
## albedo detail at any distance.
##
## Terrain3D's auto shader picks between the textures by slope, so the same
## grass/soil/rock intent the bake already encodes is expressed with real
## materials instead of flat colour.
func _apply_ground_materials() -> void:
	if _terrain == null:
		return
	var material: Object = _terrain.get("material")
	if material == null:
		push_warning("terrain has no material; ground will render as the default checker")
		return

	var textures := _build_texture_list()
	if textures == null:
		# The colour map is still better than a grey checkerboard, so a missing
		# texture is a downgrade rather than a broken world.
		push_warning("no terrain textures; falling back to the flat colour map")
		material.set("show_checkered", false)
		material.set("show_colormap", true)
		return

	_terrain.set("assets", textures)
	material.set("show_checkered", false)
	material.set("show_colormap", false)
	# The auto shader blends the second texture onto slopes, which is what makes
	# the rocky rises read as stone rather than as grass at an angle.
	material.set("auto_shader", true)
	_apply_ground_shader(material)


## Push data/config/terrain_playground.json's `shader` block at the material.
##
## Split from the texture list because these are two different kinds of thing:
## which textures exist is a content question, and how they are drawn is a
## presentation one. The distinction matters because the presentation half is
## what answers two of the blind critic's measured complaints — the world edge
## and the tiling — and both were invisible from the config until now.
##
## Named properties go through `set`; everything else is a shader uniform. The
## split is by name because Terrain3D exposes some of the shader's uniforms as
## real properties and leaves the rest reachable only through
## `set_shader_param`, and setting one the wrong way fails silently.
func _apply_ground_shader(material: Object) -> void:
	# Terrain3DMaterial exposes exactly TWO of these as real properties. The rest
	# — auto_slope, blend_sharpness, dual_scale_*, mipmap_bias and the macro
	# variation colours — are shader uniforms, reachable only through
	# set_shader_param.
	#
	# This list was longer, and `material.set()` on a name that is not a property
	# returns quietly having done nothing. So five settings were written to the
	# config, read back from the config, and never reached the shader: two
	# consecutive surveys came back byte-identical after retuning dual scaling,
	# which is the only reason it was noticed at all. If a value here appears to
	# do nothing, check which side of this line it is on before tuning it further.
	const PROPERTIES := ["world_background", "texture_filtering"]
	const COLOURS := ["macro_variation1", "macro_variation2"]

	var cfg: Dictionary = _load_terrain_config().get("shader", {})
	if cfg.is_empty():
		# FLAT rather than NOISE, matching the shader's own default, so a missing
		# config is the old look rather than an unlit void.
		material.set("world_background", 1)
		return

	var ignored: Array[String] = []
	for key: String in cfg.keys():
		if key.begins_with("_"):
			continue
		var value: Variant = cfg[key]
		if COLOURS.has(key):
			value = Color(str(value))
		if PROPERTIES.has(key):
			material.set(key, value)
			continue
		if not material.has_method("set_shader_param"):
			ignored.append(key)
			continue
		material.call("set_shader_param", key, value)
		# Read back. A uniform that does not exist under this name accepts the
		# write and returns null, which is indistinguishable from working right
		# up until a survey comes back unchanged.
		if material.call("get_shader_param", key) == null:
			ignored.append(key)
	if not ignored.is_empty():
		push_warning("terrain shader ignored %d setting(s), which will look exactly like tuning them did nothing: %s" % [
			ignored.size(), ", ".join(ignored)
		])

	var background: int = int(material.get("world_background"))
	if background != int(cfg.get("world_background", 1)):
		push_warning("terrain world_background is %d, not the %d the config asked for; " % [
			background, int(cfg.get("world_background", 1))
		] + "the world will have a visible edge at the end of the baked regions.")


## Build a Terrain3DAssets from data/config/terrain_playground.json.
##
## Returns null rather than half a texture list, so the caller can fall back
## cleanly instead of rendering one texture and a checkerboard.
func _build_texture_list() -> Object:
	if not ClassDB.class_exists("Terrain3DAssets") or not ClassDB.class_exists("Terrain3DTextureAsset"):
		return null
	var entries: Array = _load_terrain_config().get("textures", [])
	if entries.is_empty():
		return null

	var assets: Object = ClassDB.instantiate("Terrain3DAssets")
	var index := 0
	# Every texture in the array must be the same size. Terrain3D builds one
	# Texture2DArray, and a single odd resolution makes the whole array fail —
	# silently, leaving a terrain drawn from the colour map alone.
	#
	# That cost two rounds. A 2K grass dropped into a set of 1K textures turned
	# the ground into a flat pale field with no albedo at all, and because it
	# still LOOKED like ground, the next hour went into tuning sun energy and
	# ambient against a surface that had no texture on it to tune.
	var uniform_size := Vector2i.ZERO
	for entry: Variant in entries:
		var path: String = str((entry as Dictionary).get("albedo", ""))
		if not ResourceLoader.exists(path):
			continue
		var size: Vector2i = (load(path) as Texture2D).get_size()
		if uniform_size == Vector2i.ZERO:
			uniform_size = size
		elif size != uniform_size:
			push_error("terrain texture %s is %dx%d but the set is %dx%d. " % [
				path.get_file(), size.x, size.y, uniform_size.x, uniform_size.y
			] + "Terrain3D needs one size for the whole array; the ground will draw " +
				"from the colour map with no albedo detail at all.")
			return null

	for entry: Variant in entries:
		var spec: Dictionary = entry
		var albedo: String = str(spec.get("albedo", ""))
		if not ResourceLoader.exists(albedo):
			push_error("terrain texture missing: %s" % albedo)
			return null
		var texture: Object = ClassDB.instantiate("Terrain3DTextureAsset")
		texture.set("name", str(spec.get("name", "texture%d" % index)))
		texture.set("id", index)
		texture.set("albedo_texture", load(albedo))
		var normal: String = str(spec.get("normal", ""))
		if ResourceLoader.exists(normal):
			texture.set("normal_texture", load(normal))
		# Normal depth well under 1.0, and this is the single most consequential
		# number in the file.
		#
		# At full strength a photographic grass normal map turns most of its
		# texels away from a 52-degree sun, and the ground within about thirty
		# metres of the camera goes black — measured luminance 0.071 against
		# 0.27-0.60 across the references, with the mottled high-contrast fizz the
		# critic called "high-frequency mottled noise, not grass". It flattens
		# with distance because the mip average cancels the perturbation, which is
		# why the far hills looked fine and the foreground did not, and why three
		# confident explanations for it were all wrong.
		texture.set("normal_depth", float(spec.get("normal_depth", 0.35)))
		texture.set("ao_strength", float(spec.get("ao_strength", 0.3)))
		texture.set("roughness_mod", float(spec.get("roughness_mod", 0.0)))
		# Detiling rotates and shifts the tile per region so a 2K texture stops
		# announcing its own repeat period.
		texture.set("detiling_rotation", float(spec.get("detiling_rotation", 0.25)))
		texture.set("detiling_shift", float(spec.get("detiling_shift", 0.3)))
		texture.set("uv_scale", float(spec.get("uv_scale", 0.1)))
		texture.set("albedo_color", Color(str(spec.get("tint", "#ffffff"))))
		assets.call("set_texture", index, texture)
		index += 1
	return assets


## Scatter grass, bushes, trees and rocks across the playground.
##
## Built at runtime from a seeded rule rather than saved into the scene, for the
## same reason the terrain is: a scene full of ten thousand placed nodes is
## unreadable, unmergeable, and impossible to retune. The seed makes it
## identical every run, so a survey frame taken today is comparable with one
## taken after a change.
func _dress_the_meadow() -> void:
	var config := _load_terrain_config()
	_vegetation = VEGETATION.new()
	_vegetation.name = "Vegetation"
	add_child(_vegetation)
	_vegetation.call("build", float(config.get("world_size", 512)))
	var stats: Dictionary = _vegetation.call("stats")
	print("[playground] scattered %d props in %d batches" % [stats["instances"], stats["batches"]])


## Ground height at a world x/z, or NAN where there is no terrain.
##
## Anything that needs to stand something on the ground should ask this rather
## than casting a ray downwards.
##
## Raycasts against Terrain3D's heightmap collision are unreliable: measured
## across the playground, roughly a quarter of downward rays return no hit at
## points where the ground is unquestionably present — a sphere query at the
## same spot collides, the character walks over it without falling, and
## `data.get_height` returns a sane value. `move_and_slide` uses shape casts, so
## the world has always been solid to walk on; only rays lie about it.
##
## That cost an entire creature. The M3 wild pal was placed by raycast, the ray
## silently missed, and the creature was never spawned at all — no error, no
## body, just an encounter that could not happen.
func ground_height_at(x: float, z: float) -> float:
	if _terrain == null:
		return NAN
	var data: Object = _terrain.get("data")
	if data == null:
		return NAN
	return float(data.call("get_height", Vector3(x, 0.0, z)))


func _load_terrain_config() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Drop the player onto the baked ground rather than trusting a hand-placed Y in
## the scene, which silently rots every time the terrain is re-baked.
func _place_player() -> void:
	if _player == null or _terrain == null:
		return
	var data: Object = _terrain.get("data")
	if data == null:
		push_warning("terrain data not ready; leaving the player at its scene position")
		return

	var spawn := Vector3(_player.global_position.x, 0.0, _player.global_position.z)
	var ground: float = data.call("get_height", spawn)
	if is_nan(ground):
		push_warning("no terrain height at spawn; leaving the player where it is")
		return

	_player.global_position = Vector3(spawn.x, ground + SPAWN_CLEARANCE, spawn.z)
	if _camera_rig != null and _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", _player)
	print("[playground] spawned at %.1f, %.1f, %.1f" % [
		_player.global_position.x, _player.global_position.y, _player.global_position.z
	])
