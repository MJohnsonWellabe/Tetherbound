extends SceneTree

## The capture smoke test: can this process write a PNG at all?
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_diag_minimal.gd
##
## `docs/AGENT_WORKFLOW.md` has named this file since 2026-08-22 as "a 120-second
## smoke test for exactly this", and `docs/acceptance/GATE_F_MASTER_PROTOCOL.md` §A.4 and
## §I.8 both gate the Gate F capture lane on it. It did not exist. This is that
## file, written to the description the two documents already give it.
##
## ## What it is for
##
## `--headless` together with `--rendering-driver opengl3` **hangs forever** —
## no error, no crash, no partial output, exit 124 from `timeout`. It is the
## single most expensive trap in this repo: one afternoon lost four LOD capture
## attempts (one running 43 minutes), several map captures and two HUD
## captures, every one of them written off as "contention" or "the world is too
## slow to build". Neither was true. The world builds fine; the hang is always
## in the render step and is unrelated to scene weight.
##
## The cost of that misdiagnosis is what this file removes. It loads **no
## project scene and no world** — one `ColorRect` on a plain `Control`, which is
## the exact shape the trap was verified against. So:
##
##   * it writes a PNG in about a second on a correct invocation, and
##   * if it does NOT, the invocation is wrong, and no amount of blaming the
##     capture script, the scene or the box will fix it.
##
## A capture lane that runs this first can tell those two failures apart before
## spending forty minutes on the wrong one.
##
## ## Reading the result
##
## Exit 0 and a PNG on disk: the invocation renders, go take the real capture.
## Exit 1: it reached the render step and got nothing back — a real renderer
## problem worth investigating.
## No exit at all, killed by `timeout`: the invocation is the `--headless` +
## driver combination. Drop `--headless`, keep `xvfb-run`.
##
## Writes to `--gatef-out=<dir>/capture_smoke.png` when given one, otherwise to
## `user://capture_diag_minimal.png`, and prints the absolute path either way.

const SIZE := Vector2i(160, 120)
## Frames rendered before the grab. One is not enough: the first frame of a
## fresh viewport is routinely the clear colour with nothing composited over it,
## which would make this smoke test pass on a renderer that draws nothing.
const WARMUP_FRAMES := 6


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var out_path := _out_path()
	print("capture smoke: display_server=%s adapter=%s viewport=%s"
		% [DisplayServer.get_name(), RenderingServer.get_video_adapter_name(),
			str(root.get_viewport().get_visible_rect().size)])

	if DisplayServer.get_name() == "headless":
		# Not a failure of the renderer — a statement about the invocation.
		# Distinguished from exit 1 so a caller can tell "you asked for a
		# capture from a headless process" apart from "the GPU path is broken".
		print("capture smoke: SKIP — headless display server, this process cannot render.")
		print("capture smoke: use xvfb-run WITHOUT --headless. Never --headless with a rendering driver.")
		quit(2)
		return

	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(page)
	# Two rects, not one: a solid fill would also be produced by a viewport that
	# rendered nothing and kept its clear colour. Two colours in known corners
	# means something was actually composited.
	var back := ColorRect.new()
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.color = Color(0.10, 0.12, 0.16)
	page.add_child(back)
	var patch := ColorRect.new()
	patch.position = Vector2.ZERO
	patch.size = Vector2(SIZE)
	patch.color = Color(0.85, 0.45, 0.15)
	page.add_child(patch)

	for i in WARMUP_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		print("capture smoke: FAIL — the viewport returned no image.")
		quit(1)
		return
	var error := image.save_png(out_path)
	if error != OK:
		print("capture smoke: FAIL — save_png returned %d for %s" % [error, out_path])
		quit(1)
		return
	print("capture smoke: OK — wrote %dx%d to %s" % [image.get_width(), image.get_height(), out_path])
	quit(0)


## `--gatef-out=<dir>` puts the frame beside the run it is gating, which is what
## makes the smoke result part of the run record rather than a thing somebody
## remembers having done.
func _out_path() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--gatef-out="):
			var dir := arg.substr("--gatef-out=".length())
			DirAccess.make_dir_recursive_absolute(dir)
			return dir.path_join("capture_smoke.png")
	return ProjectSettings.globalize_path("user://capture_diag_minimal.png")
