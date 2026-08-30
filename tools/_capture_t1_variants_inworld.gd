extends SceneTree

## T1-VARIANTS-2 2026-08-30. In-world check for the two Aspect variants that
## did not clear JUDGE-4's blind pass (Stormtrail, Riftfrill): base and variant
## side by side, in the real Meadows, on real grass, at encounter distance --
## the gap the JUDGE-4 report named explicitly. `tools/_capture_t1_variants_
## lineup.gd`'s own synthetic stage (plain PlaneMesh, no terrain) was the right
## call for that lane's iteration speed, but it cannot answer whether the
## fixes read correctly against the world's own grass, haze and light, and the
## grass-field capture defect JUDGE-3 section 0 found is now fixed
## (T1-GROUND-3, `grass_field.gd::_follow_camera`) so this render is possible
## where it was not before.
##
## `tools/capture_check.gd` is run and printed, but per the coordinator's own
## warning it has a known hole (a frame shot from BELOW the terrain passed it
## on a previous round) -- eyeballed every frame below, not just the check.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_t1_variants_inworld.gd
##
## NEVER --headless alongside a real rendering driver.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/T1-VARIANTS-2/shots"

## Measured on this box: ~4s/physics_frame under xvfb+llvmpipe with this
## scene's full scatter/grass load (this project's own conventions.md figure
## of ~50s for a full stand-up was on a faster or less-loaded box). 120 is
## comfortably past where grass/scatter settle visually in practice; 300 blew
## well past a 1500s timeout without finishing.
const SETTLE_FRAMES := 120
const POSE_FRAMES := 12
## Encounter range: the same throwing/engagement distance
## tools/_probe_grass_separation.gd measured from real fight logs (7.4-8.1m).
const RANGE := 7.6
const EYE_HEIGHT := 1.6
const GAP := 1.1

const STANDS := [
	{"variant": "stormtrail", "source": "trailpup", "scale": 1.12},
	{"variant": "riftfrill", "source": "paddlenewt", "scale": 1.0},
]

var _world: Node = null
var _camera: Camera3D = null
var _bodies: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var boot_start := Time.get_ticks_msec()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
		if i % 20 == 0:
			print("[t1-variants-inworld] settle frame %d/%d (%.1fs elapsed)" % [
				i, SETTLE_FRAMES, (Time.get_ticks_msec() - boot_start) / 1000.0])
	print("[t1-variants-inworld] Meadows stood up (%.1fs)" % ((Time.get_ticks_msec() - boot_start) / 1000.0))

	# Same open-meadow stand tools/_probe_grass_separation.gd shoots from --
	# real grass field coverage, not a bare corner of the map.
	var stand := Vector3(36.0, 0.0, -50.0)
	stand.y = _ground(stand)

	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.fov = 48.0
	_camera.make_current()

	for time_label in ["day", "night"]:
		_set_time(time_label)
		for stand_def in STANDS:
			await _shoot(stand_def, stand, time_label)

	print("Frames written to %s" % OUT_DIR)
	quit(0)


func _set_time(time_label: String) -> void:
	var look := _world.get_node_or_null(^"WorldLook")
	if look == null:
		print("WARN no WorldLook node; time-of-day cannot be pinned")
		return
	look.call("apply_time", time_label)
	for i in 20:
		await physics_frame


func _shoot(stand_def: Dictionary, at: Vector3, time_label: String) -> void:
	var variant: String = stand_def["variant"]
	var source: String = stand_def["source"]
	var scale: float = float(stand_def["scale"])

	for b in _bodies:
		if is_instance_valid(b):
			b.queue_free()
	_bodies.clear()
	await process_frame

	var look_at := at + Vector3(RANGE, 0.0, 0.0)
	look_at.y = _ground(look_at)
	_camera.global_position = at + Vector3(0.0, EYE_HEIGHT, 0.0)
	_camera.look_at(look_at + Vector3(0.0, 0.5, 0.0), Vector3.UP)

	var base_at := look_at + Vector3(0.0, 0.0, -GAP)
	base_at.y = _ground(base_at)
	var variant_at := look_at + Vector3(0.0, 0.0, GAP)
	variant_at.y = _ground(variant_at)

	var base_body := _spawn(source, 1.0, "")
	base_body.global_position = base_at
	var variant_body := _spawn(source, scale, variant)
	variant_body.global_position = variant_at
	_bodies = [base_body, variant_body]

	for i in POSE_FRAMES:
		await physics_frame

	var problems := CAPTURE_CHECK.warn_only(self, _camera)
	if not problems.is_empty():
		print("[t1-variants-inworld] %s/%s: capture_check flagged %d issue(s) -- see above" % [
			variant, time_label, problems.size()])

	var path := "%s/inworld-%s-vs-%s-%s.png" % [OUT_DIR, variant, source, time_label]
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		print("FAIL %s" % path.get_file())
		return
	print("wrote %s" % path.get_file())


func _spawn(source: String, scale: float, variant: String) -> Node3D:
	var scene: PackedScene = load("res://scenes/creatures/creature.tscn")
	var body: Node3D = scene.instantiate()
	body.set_script(BODY)
	body.name = "T1VariantsInworld_%s_%s" % [source, variant if variant != "" else "base"]
	_world.add_child(body)
	body.set("body_scale", scale)
	body.call("setup", source, false)
	if variant != "":
		body.call("set_aspect_variant", variant, source)
	body.set_physics_process(false)
	return body


func _ground(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return 0.0
