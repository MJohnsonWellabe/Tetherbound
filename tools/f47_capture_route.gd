extends SceneTree

## Starts the REAL title scene, never a fixture, teleport or automatic pilot.
## ROOT queue: godot --path . --script tools/f47_capture_route.gd --
##   --out=<new-absolute-jsonl-path> --run-id=<unique-route-id>
## Production inputs and menu/new-game flow are unchanged.
const OBSERVER := preload("res://scripts/economy/route_observer.gd")
var _out := ""
var _run_id := ""


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		elif arg.begins_with("--run-id="): _run_id = arg.trim_prefix("--run-id=")
	_begin.call_deferred()


func _begin() -> void:
	var observer := OBSERVER.new()
	observer.name = "F47RouteObserver"
	root.add_child(observer)
	if not observer.start(_out, _run_id):
		push_error("F47 capture requires a new writable --out path and unique --run-id")
		quit(2)
		return
	var main_path := str(ProjectSettings.get_setting("application/run/main_scene"))
	var error := change_scene_to_file(main_path)
	if error != OK:
		observer.stop("main_scene_failed")
		quit(2)
