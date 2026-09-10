extends SceneTree

## Real MapState lifecycle regression for the minimap fog texture. Meadows and
## Cloudreach use distinct production extents, so switching between them proves
## the GPU texture allocation follows the bound map rather than merely checking
## a synthetic width.

const MINIMAP := preload("res://scripts/ui/minimap.gd")
const MEADOWS_MAP := preload("res://autoload/map_state.gd")
const CLOUDREACH_MAP := preload("res://scripts/world/cloudreach_map_state.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var meadows := MEADOWS_MAP.new()
	meadows.call("configure", _read_json("res://data/config/map_landmarks.json"))
	var cloudreach := CLOUDREACH_MAP.new()
	cloudreach.call("configure_cloudreach",
		_read_json("res://data/config/cloudreach_world.json"),
		_read_json("res://data/config/cloudreach_chapter.json"), PROGRESSION.new())
	var meadows_size := Vector2i(
		int(meadows.call("cell_grid_x")), int(meadows.call("cell_grid_z")))
	var cloudreach_size := Vector2i(
		int(cloudreach.call("cell_grid_x")), int(cloudreach.call("cell_grid_z")))
	_check(meadows_size != cloudreach_size,
		"production Meadows and Cloudreach fixtures must exercise different fog dimensions")

	var minimap := MINIMAP.new()
	root.add_child(minimap)
	minimap.call("configure", meadows, null, 90.0)
	minimap.call("_rebuild_fog")
	var meadows_texture := minimap.get("_fog_texture") as ImageTexture
	_check(_texture_size(meadows_texture) == meadows_size,
		"first Meadows fog texture does not match its real MapState grid")
	var meadows_texture_id := meadows_texture.get_instance_id() \
		if meadows_texture != null else 0

	minimap.call("configure", cloudreach, null, 90.0)
	minimap.call("_rebuild_fog")
	var cloudreach_texture := minimap.get("_fog_texture") as ImageTexture
	_check(minimap.get("_map_state") == cloudreach,
		"minimap did not retain the explicitly bound Cloudreach MapState")
	_check(_texture_size(cloudreach_texture) == cloudreach_size,
		"Cloudreach fog texture retained the prior Meadows allocation")
	_check(cloudreach_texture != null \
			and cloudreach_texture.get_instance_id() != meadows_texture_id,
		"different real fog dimensions did not recreate the ImageTexture")

	var cloudreach_texture_id := cloudreach_texture.get_instance_id() \
		if cloudreach_texture != null else 0
	_check(bool(cloudreach.call("mark_visited", Vector3(0.0, 160.0, 300.0))),
		"Cloudreach fixture did not advance real fog discovery")
	minimap.call("_rebuild_fog")
	var updated_texture := minimap.get("_fog_texture") as ImageTexture
	_check(updated_texture != null \
			and updated_texture.get_instance_id() == cloudreach_texture_id,
		"same-grid dirty fog update churned the compatible texture object")

	minimap.call("configure", meadows, null, 90.0)
	minimap.call("_rebuild_fog")
	var returned_texture := minimap.get("_fog_texture") as ImageTexture
	_check(minimap.get("_map_state") == meadows,
		"minimap did not restore the explicitly rebound Meadows MapState")
	_check(_texture_size(returned_texture) == meadows_size,
		"return to Meadows did not restore the Meadows fog dimensions")

	minimap.queue_free()
	await process_frame
	await process_frame
	for failure: String in _failures:
		push_error(failure)
	print("MINIMAP FOG TEXTURE LIFECYCLE: meadows=", meadows_size,
		" cloudreach=", cloudreach_size, " failures=", _failures.size())
	quit(0 if _failures.is_empty() else 1)


func _texture_size(texture: ImageTexture) -> Vector2i:
	return Vector2i(texture.get_width(), texture.get_height()) \
		if texture != null else Vector2i.ZERO


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _check(value: bool, message: String) -> void:
	if not value:
		_failures.append(message)
