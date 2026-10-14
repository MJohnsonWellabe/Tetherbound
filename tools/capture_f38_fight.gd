extends "res://tools/art_pipeline/capture_named_fight.gd"

## Pending native fixture: existing prompt/dialogue/production-camera combat
## with real attack/dodge inputs. Inherits fixture party/debug travel, so this
## proves live combat presentation only, never earned opening/progression.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _f38_records: Array[Dictionary] = []
var _f38_graphics: Dictionary = {}


func _init() -> void:
	# Apply the native raster after SceneTree/window initialization, as the
	# inventory capture does; the inherited smoke starts during construction.
	_run.call_deferred()


func _run() -> void:
	_f38_graphics = preload("res://tools/lookdev_capture_bootstrap.gd").prepare(self, "--out=")
	if _f38_graphics.is_empty():
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f38-preset=") and arg.trim_prefix("--f38-preset=") != str(_f38_graphics.preset):
			push_error("F38 legacy preset argument disagrees with required --preset")
			quit(1)
			return
	seed(2042)
	await super._run()


func _save(tag: String) -> void:
	await super._save(tag)
	var path := "%s/%s-%s.png" % [_out, _tid, tag]
	if not FileAccess.file_exists(path):
		return
	var saved := Image.load_from_file(path)
	var expected: Array = _f38_graphics.resolution
	if saved == null or saved.get_size() != Vector2i(int(expected[0]), int(expected[1])):
		push_error("F38 fight saved raster does not match requested preset resolution")
		quit(1)
		return
	_f38_records.append({"file": path, "trainer": _tid, "state": tag,
		"graphics_capture": _f38_graphics,
		"preset": GRAPHICS.selected(), "renderer": RenderingServer.get_current_rendering_method(),
		"candidate": OS.get_cmdline_user_args().has("--f38-candidate"),
		"live_fight": bool(_manager.call("is_fighting")) if _manager != null else false,
		"fixture_limit": "Inherited fixture party/debug travel and automatic input taps; no forced win/keep-alive is requested. Not earned or player-preference evidence."})
	var file := FileAccess.open(_out + "/f38-fight-manifest.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_f38_records, "\t"))
