extends SceneTree

## Per-phase timing for the meadows_playground scene load/instantiate/render
## path shared by every visual capture tool (survey.gd, capture_paths.gd,
## capture_menu_panels.gd, capture_hillside.gd, etc). RENDER-PERF-DIAG:
## written after two independent firings (EV4-textures-lighting-remainder,
## R9.4-remainder-6) each burned 12-100+ minutes against a real capture tool
## with zero frames produced and no idea which phase was slow.
##
## Root cause, found by timing each phase separately: NOT scene loading,
## instantiation, or vegetation scatter (all under ~1s combined) and NOT a
## genuine per-frame rendering wall either. It was `--headless`. Godot
## silently uses its no-op "Dummy" rendering driver under `--headless`,
## REGARDLESS of a `--rendering-driver` flag also being passed -- so a
## capture tool run with `--headless` either hangs forever on
## `RenderingServer.frame_post_draw` (a signal tied to a real render pass
## completing, which structurally cannot fire under Dummy) or, if that
## await is skipped, fails immediately with "Parameter "t" is null" from
## `get_image()` (the Dummy driver never populates a real texture). Both
## look exactly like "stuck", and CPU staying busy while it happens (as the
## two prior attempts both recorded) is consistent with the main loop
## spinning through frame after frame while genuinely waiting on that dead
## signal, not with the scene being too expensive to render.
##
## Every capture tool's own header already documents the correct invocation
## WITHOUT `--headless` -- xvfb-run supplies a virtual X display so
## `--rendering-driver opengl3` gets a real (if slow, llvmpipe-software)
## rendering context instead. Follow it exactly. Verified end to end:
## capture_paths.gd, run this way, produced real PNGs for all 4 viewpoints
## in 4m34s -- slow because llvmpipe software-rendering the scene's ~24k
## MultiMesh-instanced props genuinely costs real time (roughly 0.2-1.2s per
## frame depending on what's happening that frame, timed below), but nowhere
## near "100+ minutes, mystery".
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/diag_scene_perf.gd
##
## Do NOT add --headless to this or any other capture tool's invocation.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 20  # deliberately short -- this measures cost/frame, not a real capture
const FOV := 70.0


func _init() -> void:
	_run()


func _run() -> void:
	var t0 := Time.get_ticks_msec()

	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)

	var prev := t0
	for i in SETTLE_FRAMES:
		await physics_frame
		var now := Time.get_ticks_msec()
		if now - prev > 20 or i == 0:
			print("settle physics_frame %2d      %6d ms" % [i, now - prev])
		prev = now
	var t_settle := Time.get_ticks_msec()
	print("settle (%d physics frames) TOTAL %6d ms" % [SETTLE_FRAMES, t_settle - t0])

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var field: RefCounted = HEIGHTFIELD.new()
	var eye := Vector3(2.0, field.height_at(2.0, -4.0) + 1.8, -4.0)
	var target := Vector3(10.0, field.height_at(10.0, -10.0) + 0.3, -10.0)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	var t_camera := Time.get_ticks_msec()
	print("camera setup                 %6d ms" % (t_camera - t_settle))

	for i in 20:
		await physics_frame
	var t_pose_physics := Time.get_ticks_msec()
	print("20 pose physics_frames       %6d ms  (%.0f ms/frame)" % [t_pose_physics - t_camera, (t_pose_physics - t_camera) / 20.0])

	for i in 4:
		await process_frame
	var t_pose_process := Time.get_ticks_msec()
	print("4 pose process_frames        %6d ms  (%.0f ms/frame)" % [t_pose_process - t_pose_physics, (t_pose_process - t_pose_physics) / 4.0])

	await RenderingServer.frame_post_draw
	var t_post_draw := Time.get_ticks_msec()
	print("frame_post_draw               %6d ms" % (t_post_draw - t_pose_process))

	var tex := root.get_texture()
	var image := tex.get_image() if tex != null else null
	var t_capture := Time.get_ticks_msec()
	print("get_texture()+get_image()    %6d ms" % (t_capture - t_post_draw))

	if image == null:
		print("image is NULL -- likely running under --headless (Dummy driver). Remove --headless and retry.")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots/_diag"))
	var err := image.save_png("res://shots/_diag/diag-probe.png")
	var t_save := Time.get_ticks_msec()
	print("save_png() [err=%d]           %6d ms" % [err, t_save - t_capture])

	print("")
	print("TOTAL wall time for one viewpoint's worth of work: %6d ms" % (t_save - t0))
	quit(0)
