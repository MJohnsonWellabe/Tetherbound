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

	_apply_placeholder_material()

	# Terrain3D needs a camera to decide which regions to keep resident. Without
	# it the extension logs an error every physics frame and stops processing.
	if _terrain.has_method("set_camera"):
		_terrain.call("set_camera", _camera)
	_place_player()
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
	terrain.set("collision_mode", COLLISION_FULL_GAME)
	add_child(terrain)
	return terrain


## Show the baked colour map instead of Terrain3D's "no textures assigned"
## checkerboard.
##
## This is only visible on a rendered frame, which is how it was missed: every
## check up to this point read terrain DATA — heights, region counts, collision
## — and all of them passed while the ground rendered as a grey checker. The
## first screenshot ever taken of this scene found it immediately.
##
## `show_colormap` is nominally a debug view, and using it as the ground
## treatment is deliberate for M1: it renders the slope-driven grass/soil/rock
## map from data/config/terrain_playground.json with zero texture assets. It is
## a placeholder and is replaced by real splatmapped Terrain3DAssets at the art
## pass, not kept.
func _apply_placeholder_material() -> void:
	if _terrain == null:
		return
	var material: Object = _terrain.get("material")
	if material == null:
		push_warning("terrain has no material; ground will render as the default checker")
		return
	material.set("show_checkered", false)
	material.set("show_colormap", true)


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
