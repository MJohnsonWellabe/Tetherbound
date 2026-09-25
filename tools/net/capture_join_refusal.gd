extends SceneTree

## Capture the title's Join screen after a REAL host refusal (X05). Nothing
## is staged: the title parses `--mp-join` exactly as a player's launch would,
## builds the world, dials the host, receives the host's admission verdict and
## returns to the title, which shows the reason. This script only waits for
## that and saves the frame.
##
##   godot --headless --path . -- --mp-host 27150          # the host, elsewhere
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/net/capture_join_refusal.gd -- \
##     --mp-join 127.0.0.1:27150 --out=/abs/path/refusal.png [--net-content-fingerprint=...]
##
## Exits 0 once a refusal reason is on screen and saved, 1 on timeout.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const TIMEOUT_MS := 600_000

var _out := ""
var _started_ms := 0
var _seen_join := false


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
	if _out.is_empty() or DisplayServer.get_name() == "headless":
		print("capture_join_refusal: needs --out=<png> and a renderer")
		quit(1)
		return
	_started_ms = Time.get_ticks_msec()
	change_scene_to_file(TITLE_SCENE)
	_watch()


func _watch() -> void:
	while Time.get_ticks_msec() - _started_ms < TIMEOUT_MS:
		await process_frame
		var scene := current_scene
		if scene == null:
			continue
		if scene.scene_file_path != TITLE_SCENE:
			_seen_join = true
			continue
		if not _seen_join:
			continue
		var status: Variant = scene.get("_status")
		if status is Label and not (status as Label).text.strip_edges().is_empty():
			for i in 20:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			DirAccess.make_dir_recursive_absolute(_out.get_base_dir())
			var err := image.save_png(_out)
			print("capture_join_refusal: status='%s' saved=%s err=%d"
				% [(status as Label).text, _out, err])
			quit(0 if err == OK else 1)
			return
	print("capture_join_refusal: timed out without a refusal on the title")
	quit(1)
