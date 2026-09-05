extends SceneTree

## N08-PICKUP-TIERS (2026-09-05). Real in-game frames of the three candy
## tiers for the code-blind judge (docs/AGENT_WORKFLOW.md §7), shot THROUGH
## THE GAMEPLAY CAMERA so the grass ring is dressing the ground in the frame
## (`tools/capture_pickup_glow.gd`'s reason; `capture_check.gd` refuses a
## frame it is not).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_n08_pickup_tiers.gd -- --tag=AFTER [--only=a,b]
##   godot --headless --path . --script tools/contact_sheet.gd -- \
##     --dir=res://shots/n08_pickup_tiers/AFTER --out=res://ralph/reports/N08-PICKUP-TIERS-0905/_sheet-AFTER.png
##
## Never `--headless` with a rendering driver.
##
## Two kinds of stand:
##
##   * the LINE-UP: Good, Great, Rare and a Stamina Shroom stood 1.3 m apart
##     on the same open band-1 ground (the `band1_open` site every grass
##     measurement uses), through `band_pickups.gd::place_one()` -- the
##     loader's own path, so the tier look is exactly what the world builds,
##     and only the placement is staged. Shot at 3 m (arrival), 7 m (the
##     distance a player decides from) and 14 m (the distance a player
##     notices from). The only variable across the four objects is the tier,
##     which is the question; the mushroom is the family round 2 measured as
##     "exactly as something you bend down and pick", in frame as the ruler.
##   * three AUTHORED placements: W18's Highfield trio in band 4, at 7 m,
##     the same three ids and bearing `_capture_w18_pickups.gd` used, so the
##     verdict there and here are on the same ground.
##
## The trainer stands in every frame (it is the rig's own target), so scale
## is judged against the 1.80 m body rather than guessed. The candies' idle
## spin is frozen at a bearing that shows the Rare's wings side-on to the
## lens (the wrapper's long axis, which the wings follow, is its local x;
## a yaw equal to the stand's bearing lays it across the sightline); a still
## cannot show motion, and a frame that happened to catch the wings edge-on
## would be evidence of the phase, not the look.
##
## Frames go to `res://shots/n08_pickup_tiers/<tag>/`; only a contact sheet
## is committed (AGENT_WORKFLOW.md §8). A per-frame log with the grass
## verdict, the glow radius per tier and the stand geometry is written after
## every shot, so a wall-clock kill loses a frame, not the record.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_ROOT := "res://shots/n08_pickup_tiers"
const BAND_PICKUPS := preload("res://scripts/world/band_pickups.gd")
## The same script, held as a plain `GDScript` so its N08 statics can be
## reached by name: the typed constant above is checked at parse time, and
## the BEFORE loader (main before this lane) has no `place_one()`.
var _loader: GDScript = load("res://scripts/world/band_pickups.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")

const SETTLE_PHYSICS_FRAMES := 240
const SETTLE_DRAW_FRAMES := 6
## The SpringArm3D re-extends at 4 m/s after a teleport; 120 physics frames
## clears its 5.2 m boom (`capture_pickup_glow.gd`'s number).
const POSE_PHYSICS_FRAMES := 120
const POSE_DRAW_FRAMES := 10

## The line-up: world x, z of its centre and the spacing along x. The player
## stands south (+z) of it looking north.
const LINEUP_CENTRE := Vector2(0.0, 693.0)
const LINEUP_SPACING_M := 1.3
const LINEUP := [
	{"id": "n08_lineup_good", "item": "good_candy"},
	{"id": "n08_lineup_great", "item": "great_candy"},
	{"id": "n08_lineup_rare", "item": "rare_candy"},
	{"id": "n08_lineup_shroom", "item": "stamina_mushroom"},
]

## Stands. Distances are PLAYER distances; the rig's boom puts the lens
## about 5 m further back, and the log records where the lens actually was.
## `lineup` stands look north at the line from `from` metres south of it;
## `pickup` stands look at an authored `BandPickup_<id>` from `from` metres
## along `bearing` (degrees, 0 = camera south of it looking north, the same
## convention as `_capture_w18_pickups.gd`).
##
## The rig looks THROUGH the trainer, so a target on the sightline is a
## target behind his back (the first pass hid the Great candy exactly so).
## Every stand therefore aims `AIM_SIDE_M` to the right of what it is
## photographing: the subject sits left of centre and the body stands beside
## it as the 1.80 m ruler, not over it.
const AIM_SIDE_M := 3.4
const STANDS := [
	{"name": "01-lineup-cam7m", "lineup": true, "from": 2.4, "why": "the four side by side, lens ~7 m: the distance a player decides from; the tier is the only variable"},
	{"name": "02-lineup-cam12m", "lineup": true, "from": 7.0, "why": "the same line, lens ~12 m: does the hierarchy survive where no crest resolves?"},
	{"name": "03-lineup-cam17m", "lineup": true, "from": 12.0, "why": "lens ~17 m, the distance a player notices a find from"},
	{"name": "04-b4-good-south-paddock", "id": "b4_candy_highfield_south_paddock", "from": 2.4, "bearing": 200.0, "why": "W18's Good, authored ground, lens ~7 m"},
	{"name": "05-b4-great-wind-ridge", "id": "b4_candy_wind_ridge_crest", "from": 2.4, "bearing": 200.0, "why": "W18's Great, authored ground, lens ~7 m"},
	{"name": "06-b4-rare-herd-bull", "id": "b4_candy_herd_bull_highfield", "from": 2.4, "bearing": 200.0, "why": "W18's Rare, authored ground, lens ~7 m"},
]

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _tag: String = "AFTER"
var _only: PackedStringArray = PackedStringArray()
var _out: String = ""
var _log: Array[String] = []
var _failures: Array[String] = []
var _staged: Array[Node3D] = []


func _init() -> void:
	for raw: String in OS.get_cmdline_user_args():
		if raw.begins_with("--tag="):
			_tag = raw.substr(6)
		elif raw.begins_with("--only="):
			_only = raw.substr(7).split(",", false)
	_out = "%s/%s" % [OUT_ROOT, _tag]
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_PHYSICS_FRAMES:
		await physics_frame
	for i in SETTLE_DRAW_FRAMES:
		await process_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("[n08-capture] no Player/CameraRig; nothing to shoot")
		quit(1)
		return
	_pin_the_weather()
	var look: Node = _world.get_node_or_null(^"WorldLook")
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	if look != null and look.has_method("apply_time"):
		look.call("apply_time", "day")
	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	_stage_lineup()

	for stand: Dictionary in STANDS:
		if not _only.is_empty() and not _only.has(str(stand["name"])):
			continue
		await _shoot(stand)

	print("")
	print("\n".join(_log))
	for failure: String in _failures:
		print("[n08-capture] FAILURE: %s" % failure)
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	quit(1 if not _failures.is_empty() else 0)


## The four objects, through the loader's own `place_one()`. Nothing about
## the look is staged; only where they stand.
func _stage_lineup() -> void:
	var vegetation: Node3D = _world.get("_vegetation") as Node3D
	var half := float(LINEUP.size() - 1) * 0.5
	for i in LINEUP.size():
		var spec: Dictionary = LINEUP[i]
		var at := LINEUP_CENTRE + Vector2((float(i) - half) * LINEUP_SPACING_M, 0.0)
		var outcome := _place(vegetation, str(spec["id"]), str(spec["item"]), at)
		var node: Node3D = outcome.get("node") as Node3D
		if node == null:
			_failures.append("line-up: %s did not place (%s)" % [str(spec["id"]), str(outcome)])
			continue
		_staged.append(node)
		_freeze_spin(node, 0.0)
		var item := str(spec["item"])
		_log.append("staged %-18s %-16s at %s  glow x%s  parts %s  crest %s%s" % [
			str(spec["id"]), item, str(node.global_position),
			str(_loader.call("glow_scale_for", item)) if _loader_has("glow_scale_for") else "n/a",
			str(_loader.call("parts_for", item)) if _loader_has("parts_for") else "n/a",
			str(_loader.call("crest_for", item)) if _loader_has("crest_for") else "n/a",
			"  (nudged)" if int(outcome.get("nudged", 0)) == 1 else ""])
	_write_log()


## The loader's own `place_one()` where it has one. The BEFORE frames are
## shot against the loader as it stood on `main` before this lane, which has
## no `place_one`; that path is the same lines `place_all()` ran then, so
## the before and after differ only in `dress()`.
func _place(vegetation: Node3D, id: String, item: String, at: Vector2) -> Dictionary:
	if _loader_has("place_one"):
		# `call`, not a direct call: the static checker refuses a script that
		# names a static method its base lacks, and the BEFORE loader lacks it.
		return _loader.call("place_one", _world, vegetation, {"id": id, "item": item, "pos": at, "y": NAN})
	var out := {"placed": 0, "nudged": 0, "unclear": 0, "no_ground": 0, "node": null}
	var spot: Dictionary = BAND_PICKUPS._clear_spot(_world, vegetation, at)
	if spot.is_empty():
		out["no_ground"] = 1
		return out
	if bool(spot["nudged"]):
		out["nudged"] = 1
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.name = "BandPickup_%s" % id
	node.position = spot["at"]
	_world.add_child(node)
	var model_and_scale: Array = _world.call("_item_cache_model", item)
	node.call("setup", item, BAND_PICKUPS.label_for(item), str(model_and_scale[0]), float(model_and_scale[1]), id)
	var game := _world.get_node_or_null(^"/root/Game")
	BAND_PICKUPS.dress(node, item, BAND_PICKUPS._badge_colour(game, item))
	out["placed"] = 1
	out["node"] = node
	return out


func _loader_has(method: String) -> bool:
	for entry: Dictionary in _loader.get_script_method_list():
		if str(entry.get("name", "")) == method:
			return true
	return false


## A still cannot show the idle spin, and a frame that caught the wings
## end-on would be evidence of the phase, not the look. Freeze every candy at
## `yaw`: the wrapper's long axis is its local x, so a yaw equal to the
## stand's bearing lays the wings across the sightline, side-on to the lens.
func _freeze_spin(node: Node3D, yaw: float) -> void:
	if node.has_meta("tier_spin"):
		var tween: Tween = node.get_meta("tier_spin") as Tween
		if tween != null and tween.is_valid():
			tween.kill()
	if node.has_meta("tier_spinner"):
		var spinner := node.get_node_or_null(NodePath(str(node.get_meta("tier_spinner")))) as Node3D
		if spinner != null:
			spinner.rotation.y = yaw


func _shoot(stand: Dictionary) -> void:
	var name := str(stand["name"])
	var subject := Vector3.ZERO
	var distance := float(stand["from"])
	var bearing := 0.0
	if bool(stand.get("lineup", false)):
		var ground := float(_world.call("ground_height_at", LINEUP_CENTRE.x, LINEUP_CENTRE.y))
		subject = Vector3(LINEUP_CENTRE.x, ground, LINEUP_CENTRE.y)
	else:
		var node := _world.get_node_or_null(NodePath("BandPickup_%s" % str(stand["id"]))) as Node3D
		if node == null:
			_failures.append("%s: no BandPickup_%s in the world" % [name, str(stand["id"])])
			return
		bearing = deg_to_rad(float(stand.get("bearing", 0.0)))
		_freeze_spin(node, bearing)
		subject = node.global_position
	# The sightline runs from the stand toward the subject; the aim point is
	# `AIM_SIDE_M` to the right of the subject along that line's perpendicular,
	# and the player stands `distance` back from the AIM point, so the body
	# is beside the subject in frame rather than in front of it.
	var toward := Vector3(-sin(bearing), 0.0, -cos(bearing))
	var right := Vector3(-toward.z, 0.0, toward.x)
	var target := subject + right * AIM_SIDE_M
	var stand_at := target - toward * distance
	stand_at.y = float(_world.call("ground_height_at", stand_at.x, stand_at.z)) + 0.1
	_player.global_position = stand_at
	_player.velocity = Vector3.ZERO
	var to := target - stand_at
	_rig.set("yaw", atan2(-to.x, -to.z))
	var pitch := -atan2(maxf(stand_at.y + 1.4 - target.y, 0.0), maxf(distance, 0.01)) * 0.5
	var camera: Camera3D = null
	# On a ridge the boom can put the lens under the slope behind the player
	# (the first BEFORE pass lost the wind-ridge stand to exactly that, a
	# 26 cm burial). A steeper pitch lifts the lens; step it until the camera
	# clears its own ground, and record the pitch used.
	for attempt in 4:
		_rig.set("pitch", pitch)
		for i in POSE_PHYSICS_FRAMES:
			await physics_frame
		for i in POSE_DRAW_FRAMES:
			await process_frame
		camera = root.get_camera_3d()
		if camera == null:
			break
		var under := float(_world.call("ground_height_at", camera.global_position.x, camera.global_position.z))
		if is_nan(under) or camera.global_position.y > under + 0.3:
			break
		pitch -= 0.14
	if camera == null:
		_failures.append("%s: no current camera" % name)
		return
	# `warn_only`, not `require`: a refused frame here would end the whole
	# run (it quits the tree), and the log carries the problem either way; a
	# stand with a problem is still counted as a failure in the exit code.
	var problems: Array[String] = CAPTURE_CHECK.warn_only(self, camera)
	for problem: String in problems:
		_failures.append("%s: %s" % [name, problem])
	var grass := _grass_verdict(camera)
	if grass.begins_with("NO GRASS"):
		_failures.append("%s: %s" % [name, grass])
	if not problems.is_empty():
		grass += "  CAPTURE CHECK: " + "; ".join(problems)
	grass += "  (rig pitch %.2f)" % pitch

	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_out, name]
	if image == null or image.save_png(path) != OK:
		_failures.append("%s: no image / save_png failed" % name)
		return
	_log.append("%-30s %-6s dist=%4.1fm  eye %s -> %s\n%-30s %s\n%-30s %s\n%-30s %s" % [
		name, _tag, distance, str(camera.global_position), str(target), "", grass, "", str(stand["why"]), "", path])
	_write_log()
	print("[n08-capture] %s -> %s | %s" % [name, path, grass])


func _write_log() -> void:
	var file := FileAccess.open("%s/tiers-%s.log" % [_out, _tag], FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_log) + "\n")


func _pin_the_weather() -> void:
	var weather: Node = _world.get_node_or_null(^"WorldWeather")
	if weather == null:
		return
	if weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
	weather.set_process(false)


## `capture_pickup_glow.gd::_grass_verdict()`, verbatim in substance: the
## tuft ring has to carry instances AND be near this camera.
func _grass_verdict(camera: Camera3D) -> String:
	var field := _world.get_node_or_null(^"GrassField")
	if field == null:
		return "NO GRASS: no GrassField node in this world"
	var best_count := 0
	var layers: Array[Node] = [field]
	layers.append_array(field.find_children("*", "MultiMeshInstance3D", true, false))
	for layer: Node in layers:
		var mmi := layer as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		best_count = maxi(best_count, mmi.multimesh.instance_count)
	if best_count <= 0:
		return "NO GRASS: the grass field carries zero instances"
	var drift := (field as Node3D).global_position.distance_to(camera.global_position)
	if drift > 40.0:
		return "NO GRASS: the ring is %.0fm from this camera (following another one)" % drift
	return "grass ok: %d tufts, ring %.1fm from the lens" % [best_count, drift]
