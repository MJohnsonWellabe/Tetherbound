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
const OUT_DIR := "res://ralph/reports/visual-parity/LIFE/round1"

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 40
const ARRIVE_FRAMES := 18
const POSE_FRAMES := 4
const FOV := 70.0
const EYE_UP := 1.70

## Five evidence stands the LIFE brief names by the coordinates of the wild
## cluster this pass sited/confirmed near each, not by eye. `look` is that
## cluster's own authored `centre` (data/config/bands/*/spawns.json), so a
## miss here means the population moved, not that the frame was aimed wrong.
const STANDS := [
	{"id": "01-village-edge", "night": true,
	 "at": [14.0, -25.5], "look": [30.0, -40.0],
	 "_why": "village.json's own practice-meadow path marker [19.5,-25.5], looking at band1 spawns.json order 0's bramblebun cluster centre (30,0,-40) -- the Practice Meadow teaching-fight cluster, ungated so it reads day and night alike."},
	{"id": "02-mill-pond-banks", "night": true,
	 "at": [-368.0, 545.0], "look": [-374.0, 538.0],
	 "_why": "pond centre (-395,545) per the brief; look point is the midpoint of order 6 (paddlenewt, -378,528) and order 7 (mosshell, -371,563), the two water-edge clusters within 25-30m of the pond centre. Ungated, day and night."},
	{"id": "03-band1-open-meadow", "night": false,
	 "at": [10.0, 685.0], "look": [-20.0, 700.0],
	 "_why": "band1 open meadow (0,700) per the brief, looking at order 1002's pipwing cluster centre (-20,700), the corridor cluster nearest that point."},
	{"id": "04-relay-camp", "night": true,
	 "at": [344.0, 935.0], "look": [314.0, 927.5],
	 "_why": "band1 props.json's relocated trail-camp clearing (344,935), looking at order 1032's bramblebun cluster (314,927.5), 31m off -- and order 1053's night-gated duskhush (337,965) stands within the same frame's depth for the night pass."},
	{"id": "05-ridge-camp", "night": false,
	 "at": [-236.0, 6472.0], "look": [-260.9, 6451.7],
	 "_why": "band4 props.json ridge_patrol_camp centroid (-235.9,6471.7) per the brief, looking at this pass's new order-4076 burrowback cluster (-260.9,6451.7), 32m southwest of the camp and off the watchtower spur."},
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
## in it at all. Staged at Grandpa's yard (`GrandpaHouse.marker("outside")`),
## the opening's own establishing spot, with the player standing in for "the
## trainer" the brief names.
func _shoot_starter() -> void:
	var house: Node = _world.get_node_or_null(^"GrandpaHouse")
	var eye3: Vector3
	var away := Vector2(0.0, -1.0)
	if house != null and house.has_method("marker"):
		eye3 = house.call("marker", "outside")
		var door: Vector3 = house.call("marker", "door")
		var raw := Vector2(eye3.x - door.x, eye3.z - door.z)
		if not raw.is_zero_approx():
			away = raw.normalized()
	else:
		print("  WARN no GrandpaHouse.marker('outside'); falling back to the village well")
		eye3 = Vector3(10.0, 0.0, -15.5)
		eye3.y = _surface(Vector2(eye3.x, eye3.z))

	_player.global_position = eye3 + Vector3(0.0, 0.4, 0.0)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame

	# Creature stands beside the player, ALONG the outward axis from the
	# house rather than at a fixed world offset -- door/outside are a local
	# +x pair, so a hardcoded (+1.6,+1.2) world nudge is only "beside" the
	# player for whichever way the house happens to face.
	var side := Vector2(-away.y, away.x)
	var spot := eye3 + Vector3(side.x * 1.8, 0.0, side.y * 1.8)
	spot.y = _surface(Vector2(spot.x, spot.z))
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

	# Camera stands FURTHER out along the same outward axis than the player
	# does (the house sits on the far side of "outside"), looking back at
	# the player-and-creature pair with the house as backdrop -- not
	# shoulder-to-shoulder with the player staring sideways at a wall.
	var camEye := Vector2(eye3.x, eye3.z) + away * 7.0 + side * 2.0
	var camTarget := Vector2((eye3.x + spot.x) * 0.5, (eye3.z + spot.z) * 0.5)
	_frame(camEye, _surface(camEye), camTarget, _surface(camTarget))
	_hide_huds()
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw
	_save("06-starter-beside-trainer-day")
	print("  06-starter-beside-trainer  day  terrapup at (%.0f,%.0f)" % [spot.x, spot.z])
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
