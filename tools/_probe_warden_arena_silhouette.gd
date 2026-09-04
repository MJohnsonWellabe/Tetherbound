extends SceneTree

## W-4 (docs/specs/GATE3_ENCOUNTER_CONTRACTS.md sec5.2). Re-measures the
## Warden's own silhouette against the Warden Arena floor at `warden_challenge`
## distance (16m — the two marks are 16m apart in `data/config/stronghold.json`),
## the same Rec.709-luma / fixed-crop-box method `tools/_probe_grass_separation.gd`
## and `_grass_separation_ratio.py` already established for
## CREATURE-LEGIBILITY-0903's 1.5:1 floor.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_warden_arena_silhouette.gd -- --out=ralph/reports/G3-WARDEN-ARENA-0904
##
## NEVER `--headless` with a real rendering driver.
##
## Boots the full Meadows world (the real Stronghold + StrongholdClimax, not a
## bare fallback scene) so the Warden stands where he actually will in play,
## with the real arena dressing (or without it, run before this pass's config
## changes) around him. One frame, one fixed camera pose: `warden_challenge`
## eye height, looking at the Warden's own chest height at `warden_stand`,
## 16m away — the exact two marks the contract names.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 400
const EYE_HEIGHT := 1.6
const CHEST_HEIGHT := 1.1

var _world: Node = null
var _out_dir := "res://ralph/reports/G3-WARDEN-ARENA-0904"
var _tag := "after"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
		elif arg.begins_with("--tag="):
			_tag = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var hold: Node = _world.get_node_or_null(^"Stronghold")
	if hold == null:
		print("FAIL: no Stronghold node in the booted world")
		quit(1)
		return
	var climax: Node = _world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		print("FAIL: no StrongholdClimax node in the booted world")
		quit(1)
		return

	var challenge: Vector3 = hold.call("marker", "warden_challenge")
	var stand: Vector3 = hold.call("marker", "warden_stand")
	var body: Node3D = climax.call("warden_body") as Node3D
	var target := stand
	if body != null:
		target = body.global_position
	print("warden_challenge=%s warden_stand=%s warden_body=%s distance=%.2fm" % [
		str(challenge), str(stand), str(target), challenge.distance_to(target)])

	var camera := Camera3D.new()
	_world.add_child(camera)
	camera.global_position = challenge + Vector3(0.0, EYE_HEIGHT, 0.0)
	camera.look_at(target + Vector3(0.0, CHEST_HEIGHT, 0.0), Vector3.UP)
	camera.fov = 52.0
	camera.make_current()

	for i in 30:
		await physics_frame

	var path := "%s/warden-arena-%s.png" % [_out_dir, _tag]
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("wrote %s" % path)
	quit(0)
