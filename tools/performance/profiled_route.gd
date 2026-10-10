extends "res://tools/capture_lookdev_route.gd"

## Evidence-only wrapper. Run with a DEBUG_ENABLED Godot engine and a remote
## collector. The underlying fixed route and production callbacks stay intact.
var _profile_first_frame := -1
var _profile_last_frame := -1


func _record_frame() -> void:
	if _measuring:
		_profile_last_frame = Engine.get_process_frames()
		if _profile_first_frame < 0:
			_profile_first_frame = _profile_last_frame
			EngineDebugger.send_message("owner_profile:start", [
				_profile_first_frame, OS.is_debug_build(), _biome_id, _preset,
				_source_commit, _manifest.get("route_config_sha256", ""),
			int(ProjectSettings.get_setting("network/limits/debugger/max_queued_messages", 2048)),
			])
	super._record_frame()


func _write_route_receipt(complete: bool) -> void:
	if _profile_first_frame >= 0:
		EngineDebugger.send_message("owner_profile:end", [
			_profile_first_frame, _profile_last_frame, complete,
			_waypoints_reached, _route.get("waypoints", []).size(),
		])
	super._write_route_receipt(complete)
