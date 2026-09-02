extends SceneTree

## VP9 FIRST SLICE. Every blind judge so far has said "no creature appears in
## any frame" of a creature-bonding game. `tools/_capture_locations.gd` shoots
## the game's PLACES; this shoots the same five evidence stands specifically
## to answer whether the wild population this pass moved/added into them is
## actually visible from where a player stands, day and night where the
## brief asks for both, plus one frame of the player's own starter beside the
## trainer. Modelled directly on `_capture_locations.gd`'s boot/pin/freeze/
## raycast-reseat pattern -- see that file's header for the traps this one
## inherits (headless+opengl3 hangs forever; a clock pin that is not frozen
## wears off; the analytic heightfield and the streamed collision surface
## disagree near water).
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_life.gd
##
## VP_FAST=1 halves the settle budget and renders at whatever resolution the
## caller passed on the command line (960x540 for iteration rounds).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/visual-parity/LIFE/round2"

const BOOT_FRAMES := 90
## ROUND 2: raised from 40/18. The round-1 verdict asked explicitly to "wait
## for the cluster to be streamed in and settled (encounter streaming
## radius) before the shutter" -- these eyes now stand 8-15m from their
## cluster, well inside activation range, but a tighter eye also means less
## margin for a creature still mid-spawn-settle to be caught between frames.
const SETTLE_FRAMES := 70
const ARRIVE_FRAMES := 30
const POSE_FRAMES := 4
const FOV := 70.0
const EYE_UP := 1.70

## Five evidence stands the LIFE brief names by the coordinates of the wild
## cluster this pass sited/confirmed near each, not by eye. `look` is that
## cluster's own authored `centre` (data/config/bands/*/spawns.json), so a
## miss here means the population moved, not that the frame was aimed wrong.
##
## ROUND 2 (program coordinator, round-1 verdict): the placement work landed
## but the evidence did not show it -- village-edge and relay-camp read as
## "tiny figures"/"pale blobs" from the round-1 25-40m eyes, the pond eye
## stood IN the water looking at the mill instead of on the bank looking at
## the water species, and band1-open-meadow's eye landed inside a mesh
## (solid green frame, near clip inside geometry). Every `at` below is now
## 8-15m from its `look` cluster centre -- close enough that a 2-4 creature
## cluster reads at real size -- rather than the 25-40m the brief's PLACEMENT
## instruction asked for (that number sited the wild cluster in the world
## relative to the named stand; it was never a camera-composition distance).
const STANDS := [
	{"id": "01-village-edge", "night": true,
	 "at": [21.0, -32.0], "look": [30.0, -40.0],
	 "_why": "12m from band1 spawns.json order 0's bramblebun cluster centre (30,0,-40) -- the Practice Meadow teaching-fight cluster, ungated so it reads day and night alike. Round 1's eye (14,-25.5) stood 21.6m off and the cluster read as two tiny figures."},
	{"id": "02-mill-pond-banks", "night": true,
	 "at": [-386.0, 520.0], "look": [-378.0, 528.0],
	 "_why": "ON THE BANK, not in the water -- round 1's eye (-368,545) rendered as open water with the mill in the distance and no creature in frame at all. This eye is `_capture_locations.gd`'s own '02-mill-pond standing' point, confirmed there by raycast to sit on the bank (-16.5 against pond level -17.0). Look is order 6's paddlenewt cluster centre (-378,528), 11.3m off, along the shoreline rather than across the water at the mill."},
	{"id": "03-band1-open-meadow", "night": false,
	 "at": [-6.0, 700.0], "look": [-20.0, 700.0],
	 "_why": "round 1's eye (10,685) rendered solid green -- the near clip plane inside a mesh, not the open meadow. This eye stands due east of order 1002's pipwing cluster centre (-20,700) on the same z as the cluster itself (open corridor ground, not the off-axis approach that clipped something), 14m off."},
	{"id": "04-relay-camp", "night": true,
	 "at": [332.0, 932.0], "look": [321.0, 928.5],
	 "_why": "11.3m from a point 8m east of order 1032's bramblebun cluster centre (314,927.5, radius 17 so still inside the disc) -- round 1's eye (344,935) stood 30.9m off and read as 'two pale blobs at 60m'; the corrected-distance round-2 render then read as 'a tan pair in tree shadow' (round-1's own frame showed trees on the west side of this cluster, open trail to the east). Shifted east toward the open trail side rather than re-tuning bramblebun's shared field_emission, which is already owner-set for grass separation everywhere else the species spawns and would risk a glow complaint if pushed further just to fight shade at one stand."},
	{"id": "05-ridge-camp", "night": false,
	 "at": [-250.0, 6458.0], "look": [-260.9, 6451.7],
	 "_why": "12.6m from this pass's own order-4076 burrowback cluster (-260.9,6451.7) -- round 1's eye (-236,6472) stood 32.1m off, off the watchtower spur the same as before."},
]

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _director: Node = null
var _written: int = 0
var _failures: int = 0

static var _fast_mode: bool = false


static func _frames(n: int) -> int:
	return maxi(2, n / 2) if _fast_mode else n


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	_fast_mode = "--fast" in OS.get_cmdline_user_args() or OS.get_environment("VP_FAST") == "1"
	if _fast_mode:
		print("[fast] iteration mode: settle halved, msaa off")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in _frames(BOOT_FRAMES):
		await physics_frame
	print("[life] world up, boot settled")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("FAIL no Player node")
		quit(1)
		return

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()
	if _fast_mode:
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _director == null:
		print("FATAL: no EncounterDirector")
		quit(1)
		return

	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7).strip_edges()

	if only == "" or only == "stands":
		await _pin("day")
		for entry: Variant in STANDS:
			await _shoot_stand(entry as Dictionary, "day")

		await _pin("night")
		for entry: Variant in STANDS:
			var stand: Dictionary = entry as Dictionary
			if bool(stand.get("night", false)):
				await _shoot_stand(stand, "night")

	if only == "" or only == "starter":
		await _pin("day")
		await _shoot_starter()

	print("")
	print("life survey: %d frames written, %d failed, into %s" % [_written, _failures, OUT_DIR])
	quit(0 if _failures == 0 else 1)


func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	if _look != null:
		_look.set_process(true)
		_look.set_physics_process(true)
		_look.call("apply_time", time)
	for i in _frames(30):
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null:
		_look.set_process(false)
		_look.set_physics_process(false)
	print("[life] clock pinned to %s and frozen" % time)


func _shoot_stand(stand: Dictionary, suffix: String) -> void:
	var id: String = str(stand["id"])
	var at: Array = stand["at"] as Array
	var look: Array = stand["look"] as Array
	var eye := Vector2(float(at[0]), float(at[1]))
	var target := Vector2(float(look[0]), float(look[1]))

	var ground := _surface(eye)
	_place(eye, ground)
	_frame(eye, ground, target, _surface(target))
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame
	ground = _surface(eye)
	_place(eye, ground)
	_frame(eye, ground, target, _surface(target))
	for i in _frames(SETTLE_FRAMES):
		await physics_frame

	_hide_huds()
	_frame(eye, ground, target, _surface(target))
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw

	var here := Vector3(eye.x, ground, eye.y)
	var n := _creatures_near(here)
	_save("%s-%s" % [id, suffix])
	print("  %-24s %-5s eye(%.0f,%.1f,%.0f)  %d wild creatures within 60m" % [
		id, suffix, eye.x, ground, eye.y, n])
	if n <= 0:
		print("  WARN %s: no wild creature registered within 60m of this stand" % id)


## The player's own starter, standing beside the trainer body -- the same
## `EncounterDirector.spawn_wild()` mechanism `_capture_creature_animation_
## world.gd` uses to put a creature in the world, not the party/save-state
## `summon_active_creature()` path, which needs a live save to have a party
## in it at all.
##
## ROUND 2 (program coordinator): round 1 staged this at Grandpa's yard and
## burned three re-renders fighting the house's own roof/wall colliders
## (`_capture_locations.gd`'s own header calls this exact trap out -- a
## raycast near a building routinely hits ITS collider, not the ground), and
## the surviving frame showed only the creature's own back with no trainer
## in shot. Moved to the open Practice Meadow instead -- the same ground
## `01-village-edge` already renders clean, confirmed clear of geometry by
## that very frame -- and reframed as the coordinator's "website hero" ask:
## trainer and starter side by side, three-quarter view from behind and to
## the side, both fully in frame, facing out over the meadow toward the
## grass knoll `01-village-edge-day` shows on the horizon.
func _shoot_starter() -> void:
	var base := Vector2(21.0, -32.0)
	var landmark := Vector2(60.0, -60.0)
	var facing := (landmark - base).normalized()
	var side := Vector2(-facing.y, facing.x)

	var player_ground := _surface(base)
	_player.global_position = Vector3(base.x, player_ground + 0.4, base.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame

	var spot2 := base + side * 2.2
	var spot := Vector3(spot2.x, _surface(spot2), spot2.y)
	var wild: Node3D = _director.call("spawn_wild", "terrapup", spot, {
		"name": "Shot_starter_terrapup",
		"wander_radius": 0.0,
	}) as Node3D
	if wild == null:
		print("  FAIL starter-beside-trainer: spawn_wild returned null")
		_failures += 1
		return
	for i in _frames(SETTLE_FRAMES):
		await physics_frame

	var mid := (base + spot2) * 0.5
	var camEye := mid - facing * 5.5 + side * -3.0
	var camTarget := mid + facing * 10.0
	_frame(camEye, _surface(camEye), camTarget, _surface(camTarget))
	_hide_huds()
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw
	_save("06-starter-beside-trainer-day")
	print("  06-starter-beside-trainer  day  player(%.0f,%.0f) terrapup(%.0f,%.0f)" % [
		base.x, base.y, spot2.x, spot2.y])
	wild.queue_free()
	await process_frame


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		print("  FAIL %s: viewport returned no image" % name)
		_failures += 1
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		print("  FAIL %s: save_png" % name)
		_failures += 1
		return
	_written += 1
	print("wrote %s" % path)


func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _place(at: Vector2, ground: float) -> void:
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


func _frame(eye: Vector2, eye_ground: float, target: Vector2, target_ground: float) -> void:
	_camera.global_position = Vector3(eye.x, eye_ground + EYE_UP, eye.y)
	_camera.look_at(Vector3(target.x, target_ground + EYE_UP, target.y), Vector3.UP)


## Same raycast-over-analytic reseat `_capture_locations.gd::_surface()` uses:
## the streamed collision surface and the analytic heightfield disagree by
## metres near water and slopes, and seating on the analytic value alone can
## bury the camera underground.
func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return analytic
	return float((hit["position"] as Vector3).y)


func _creatures_near(at: Vector3) -> int:
	if _director == null or not _director.has_method("wild_creatures"):
		return -1
	var n := 0
	for wild: Variant in _director.call("wild_creatures"):
		var body: Node3D = wild as Node3D
		if body != null and is_instance_valid(body):
			if body.global_position.distance_to(at) <= 60.0:
				n += 1
	return n
