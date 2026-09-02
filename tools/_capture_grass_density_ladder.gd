extends SceneTree

## OWNER-0902 grass density ladder. The owner approved turning grass ON
## ("grass needs to be on") without separately choosing how dense -- the
## flag flip landed on the ~5x-cheaper config `OWNER-0902-GRASS-RENDER` had
## already staged for a different reason (the ~10 FPS handheld game-breaker),
## and he's now noticed ("our grass has gotten way less dense") and wants to
## SEE the options before picking one.
##
## Renders four density steps -- A (shipped), B, C, D (the pre-cut original)
## -- each as a landscape shot (no creature) and a creature shot (a small
## creature standing in it at normal encounter distance), plus a primitive
## count at the same band1_open site `tools/perf_render_stats.gd` measures,
## so the count is directly comparable to its own already-published numbers
## (grass off 9.2M, step A 13.7M, step D ~31.7M -- the config that produced
## the ~10 FPS game-breaker).
##
## One world boot for all four steps: rebuilding just the GrassField node
## (free + reinstantiate with an overridden static config) is a small
## fraction of the cost of a fresh `meadows_playground.tscn` stand-up, which
## is what makes eight renders tractable in one run instead of eight.
##
## PERF-ROG-GPU still holds -- primitive counts are read from the
## RenderingServer's structural monitors (same numbers a real GPU would be
## handed), not a frame time; this container cannot measure real Ally frame
## time, full stop.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_grass_density_ladder.gd
##
## NEVER `--headless` with a real rendering driver (ralph/conventions.md).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")
const CONFIG_PATH := "res://data/config/grass_field.json"
const OUT := "res://ralph/reports/hud-catch/grass_density_ladder"

const SETTLE_FRAMES := 240
const FIELD_SETTLE_FRAMES := 40
const RESETTLE_FRAMES := 120
const CREATURE_POSE_FRAMES := 30
const SAMPLE_FRAMES := 30

## Same site `perf_render_stats.gd` calls band1_open, and the same site
## `_capture_grass_on_band1_open.gd` used for the OWNER-0902-GRASS-ON
## player-eye-level evidence -- so this ladder's numbers and frames are
## directly comparable to both of those, not a new stand.
const SITE_X := 0.0
const SITE_Z := 700.0
const EYE_HEIGHT := 1.7
const ELEVATED_HEIGHT := 24.0

const CREATURE_SPECIES := "bramblebun"
const CREATURE_RANGE := 6.5

## Anchors: A is the shipped config as of OWNER-0902-GRASS-ON (unchanged
## here). D is the pre-cut original OWNER-0902-GRASS-RENDER measured and
## replaced. B/C interpolate tuft_count/blades_per_tuft/blade_segments per
## the coordinator's own table, and every cover-tier count scales by the same
## fraction of the way from A to D that each step's tuft_count sits at, so
## each step stays a coherent field rather than grass-only.
const STEPS := [
	{"tag": "A-75k", "tuft_count": 75000, "blades_per_tuft": 4, "blade_segments": 3},
	{"tag": "B-150k", "tuft_count": 150000, "blades_per_tuft": 5, "blade_segments": 3},
	{"tag": "C-225k", "tuft_count": 225000, "blades_per_tuft": 6, "blade_segments": 4},
	{"tag": "D-300k", "tuft_count": 300000, "blades_per_tuft": 6, "blade_segments": 4},
]
const TUFT_A := 75000.0
const TUFT_D := 300000.0
## [A, D] anchor counts for stones.count and each cover tier, keyed by name.
const SCALE_ANCHORS := {
	"stones": [25000, 90000],
	"bushes": [6000, 14800],
	"flowers": [6000, 14800],
	"litter": [15000, 49000],
}

var _base_config: Dictionary = {}
var _terrain: Node = null
var _camera: Camera3D = null
var _rig: Node = null
var _player: Node3D = null
var _world: Node = null
var _field: Node = null
var _creature: Node3D = null
var _report_lines: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return

	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		print("FAIL: could not read %s" % CONFIG_PATH)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		print("FAIL: grass_field.json did not parse as a Dictionary")
		quit(1)
		return
	_base_config = parsed

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_rig = _world.get_node_or_null(^"CameraRig")
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_player = _world.get_node_or_null(^"Player") as Node3D
	if _camera == null:
		print("FAIL: no CameraRig/Camera3D")
		quit(1)
		return
	if _rig != null:
		_rig.set_process(false)
		_rig.set_physics_process(false)

	var initial_field := _find_grass_field(_world)
	if initial_field == null:
		print("FAIL: no GrassField in the scene at boot -- is grass_field.enabled true?")
		quit(1)
		return
	_terrain = initial_field.get("_terrain") as Node
	initial_field.queue_free()
	await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_report_lines.append("# Grass density ladder -- render evidence")
	_report_lines.append("")
	_report_lines.append("Same site (%.0f, %.0f), same camera, same seed, same time of day, player" % [SITE_X, SITE_Z])
	_report_lines.append("eye level, 1280x800. Landscape and creature shots per step, plus a")
	_report_lines.append("primitive count at the elevated band1_open view `tools/perf_render_stats.gd`")
	_report_lines.append("uses, so the numbers are directly comparable to its own published series")
	_report_lines.append("(grass off 9.2M, step A 13.7M, step D's own config ~31.7M -- the load that")
	_report_lines.append("produced the owner's ~10 FPS game-breaker). Primitive counts are a proxy for")
	_report_lines.append("GPU cost, not a frame-time promise -- no container in this project can")
	_report_lines.append("measure real Ally/handheld frame time (`PERF-ROG-GPU`).")
	_report_lines.append("")
	_report_lines.append("| step | tuft_count | blades/tuft | segments | stones | bushes | flowers | litter | draw calls | primitives | objects |")
	_report_lines.append("|---|---|---|---|---|---|---|---|---|---|---|")

	for step: Dictionary in STEPS:
		await _run_step(step)

	var report_path := "%s/GRASS-DENSITY-LADDER.md" % OUT
	var out_file := FileAccess.open(ProjectSettings.globalize_path(report_path), FileAccess.WRITE)
	if out_file != null:
		out_file.store_string("\n".join(_report_lines) + "\n")
		out_file.close()
		print("wrote %s" % report_path)
	else:
		print("FAIL: could not write %s" % report_path)

	quit(0)


func _run_step(step: Dictionary) -> void:
	var tag: String = step["tag"]
	var tuft_count: int = step["tuft_count"]
	var frac: float = clampf((float(tuft_count) - TUFT_A) / (TUFT_D - TUFT_A), 0.0, 1.0)

	var cfg: Dictionary = _base_config.duplicate(true)
	cfg["tuft_count"] = tuft_count
	cfg["blades_per_tuft"] = step["blades_per_tuft"]
	cfg["blade_segments"] = step["blade_segments"]

	var stones_a: float = SCALE_ANCHORS["stones"][0]
	var stones_d: float = SCALE_ANCHORS["stones"][1]
	var stones_count := int(round(lerpf(stones_a, stones_d, frac)))
	if cfg.has("stones"):
		(cfg["stones"] as Dictionary)["count"] = stones_count

	var cover_tiers: Array = cfg.get("cover_tiers", [])
	for entry: Variant in cover_tiers:
		var tier: Dictionary = entry
		var name: String = str(tier.get("name", ""))
		if SCALE_ANCHORS.has(name):
			var a: float = SCALE_ANCHORS[name][0]
			var d: float = SCALE_ANCHORS[name][1]
			tier["count"] = int(round(lerpf(a, d, frac)))

	GRASS_FIELD._config = cfg

	if _field != null and is_instance_valid(_field):
		_field.queue_free()
		await process_frame
	_field = MultiMeshInstance3D.new()
	_field.set_script(GRASS_FIELD)
	_field.name = "GrassField_%s" % tag
	_world.add_child(_field)
	_field.call("bind", _terrain, _camera)
	for i in FIELD_SETTLE_FRAMES:
		await physics_frame
	print("[%s] tuft_count=%d blades=%d segments=%d stones=%d cover_frac=%.2f" % [
		tag, tuft_count, step["blades_per_tuft"], step["blade_segments"], stones_count, frac])

	var ground := 0.0
	if _world.has_method("ground_height_at"):
		ground = float(_world.call("ground_height_at", SITE_X, SITE_Z))
	if is_nan(ground):
		ground = 0.0

	# 1. Landscape shot -- no creature, player eye level.
	var eye := Vector3(SITE_X, ground + EYE_HEIGHT, SITE_Z)
	if _player != null:
		_player.global_position = Vector3(SITE_X, ground + 1.5, SITE_Z)
	_camera.global_position = eye
	_camera.global_rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
	if _terrain != null and _terrain.has_method("set_camera"):
		_terrain.call("set_camera", _camera)
	for i in RESETTLE_FRAMES:
		await physics_frame
	await RenderingServer.frame_post_draw
	_save("%s-landscape" % tag)

	# 2. Creature shot -- same site, a small creature standing at normal
	# encounter distance, camera looking at it.
	var stand := Vector3(SITE_X, ground, SITE_Z)
	var look_at := stand + Vector3(CREATURE_RANGE, 0.0, 0.0)
	look_at.y = ground
	if _world.has_method("ground_height_at"):
		look_at.y = float(_world.call("ground_height_at", look_at.x, look_at.z))
	if is_nan(look_at.y):
		look_at.y = ground
	_camera.global_position = stand + Vector3(0.0, EYE_HEIGHT, 0.0)
	_camera.look_at(look_at + Vector3(0.0, 0.45, 0.0), Vector3.UP)
	if _player != null:
		_player.global_position = stand + Vector3(0.0, 1.5, 0.0)
	for i in 20:
		await physics_frame
	if _creature != null and is_instance_valid(_creature):
		_creature.queue_free()
		await process_frame
	_creature = _spawn_creature(look_at)
	for i in CREATURE_POSE_FRAMES:
		await physics_frame
	await RenderingServer.frame_post_draw
	_save("%s-creature" % tag)
	if _creature != null and is_instance_valid(_creature):
		_creature.queue_free()
		await process_frame
	_creature = null

	# 3. Primitive count at the elevated band1_open view.
	var elevated := Vector3(SITE_X, ground + ELEVATED_HEIGHT, SITE_Z)
	_camera.global_position = elevated
	_camera.global_rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
	if _player != null:
		_player.global_position = Vector3(SITE_X, ground + 1.5, SITE_Z)
	for i in RESETTLE_FRAMES:
		await physics_frame

	var draws := 0.0
	var prims := 0.0
	var objs := 0.0
	for i in SAMPLE_FRAMES:
		await RenderingServer.frame_post_draw
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var n := float(SAMPLE_FRAMES)
	draws /= n
	prims /= n
	objs /= n
	print("[%s] band1_open: draw_calls=%.0f primitives=%.0f objects=%.0f" % [tag, draws, prims, objs])

	var cover_note := "%d/%d/%d" % [
		int((cover_tiers[0] as Dictionary).get("count", 0)) if cover_tiers.size() > 0 else 0,
		int((cover_tiers[1] as Dictionary).get("count", 0)) if cover_tiers.size() > 1 else 0,
		int((cover_tiers[2] as Dictionary).get("count", 0)) if cover_tiers.size() > 2 else 0,
	]
	_report_lines.append("| %s | %d | %d | %d | %d | %s | | %.0f | %.0f | %.0f |" % [
		tag, tuft_count, step["blades_per_tuft"], step["blade_segments"], stones_count, cover_note,
		draws, prims, objs])


func _save(tag: String) -> void:
	var path := "%s/%s.png" % [OUT, tag]
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("  wrote %s" % path)


func _spawn_creature(at: Vector3) -> Node3D:
	var scene: PackedScene = load("res://scenes/creatures/creature.tscn")
	if scene == null:
		return null
	var body: Node3D = scene.instantiate()
	body.set_script(load("res://scripts/creatures/wild_creature.gd"))
	body.name = "DensityLadderCreature"
	_world.add_child(body)
	body.global_position = at
	body.call("populate", CREATURE_SPECIES, null)
	body.global_position = at
	return body


func _find_grass_field(node: Node) -> Node:
	if node.get_script() != null \
			and String(node.get_script().resource_path).ends_with("grass_field.gd"):
		return node
	for child in node.get_children():
		var found := _find_grass_field(child)
		if found != null:
			return found
	return null
