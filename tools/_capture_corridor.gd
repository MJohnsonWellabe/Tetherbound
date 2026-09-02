extends SceneTree

## VP4 CORRIDOR PASS. Sixteen player-height frames down the actual walked
## route from the village edge (z~20) through the South Bridge (z~1330),
## Band 2 (z~2470), Band 3's river lock/relay/mill crossing, Band 4's upper
## meadows/ironwood and ridge camp, Band 5's stronghold approach, to the Hall
## gate itself (z~7560), day only -- the eyes VP4 (docs/VISUAL_PARITY_STAGED_
## GOAL_PROMPT_V2.md) judges "player -> empty grass -> sky" against.
##
## Round 4 (stations 09-16): extends the original 8 (village -> Band 2 far,
## authored in earlier rounds of this pass) to cover the rest of the major
## continuous player journey, per the program coordinator's own round-4
## dispatch.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_corridor.gd [-- --out=res://shots/corridor_x --fast]
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (ralph/conventions.md, "Art pipeline traps").
##
## Modelled on `tools/_capture_locations.gd`'s boot/pin/clock-freeze pattern and
## `tools/_probe_corridor_survey.gd`'s single-eye-per-station rig (both read in
## full before writing this): boot the world once, pin+freeze the day clock so
## a multi-station pass does not drift into dusk, hand Terrain3D the capture
## camera so frames show the real streamed LOD, carry the PLAYER to every
## station (not just the camera) since creature/prop spawning is driven off the
## player and the 1.80m body is the rubric's own ruler, and raycast-reseat every
## eye because the analytic heightfield and the streamed collision surface
## disagree by metres near water and slopes.
##
## STATIONS are literal vertices of `data/config/terrain_playground.json`
## `trail.bands[].points` (band1_lower_meadows, band2_stone_and_root) -- never
## hand-picked coordinates -- so the camera stands ON the authored path. `look`
## is the next vertex a station or two ahead along the same polyline, i.e. the
## direction of travel, not a fixed landmark: this pass is judging the
## sightline a walking player actually sees, not a curated view of one prop.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT_DIR := "res://shots/corridor_stations"

const BOOT_FRAMES := 90
const ARRIVE_FRAMES := 20
const SETTLE_FRAMES := 45
const POSE_FRAMES := 4
const FOV := 70.0
## Over-the-shoulder rig, matching `_probe_corridor_survey.gd`'s own corridor
## convention: the player stands in frame as the rubric's 1.80m ruler and the
## camera looks past them along the route, at the height a person actually
## sees the world from.
const BACK := 4.2
const UP := 2.4

## Eight stations, in the order a player walks them, each `at` a literal
## `trail.bands[]` vertex and `look` the next vertex 1-2 steps ahead along the
## same polyline (the direction of travel). z of `at`: 20, 270, 590, 910, 1300,
## 1660, 2130, 2470 -- roughly even ~370m spacing from the village edge to
## Band 2's far reach, crossing the South Bridge at station 5.
##
## Station 5 is NOT the trail vertex at the bridge's own mid-span (8, 1330):
## `terrain_playground.json` `crossings[0].carve` cuts an 11m gully there, and
## the analytic heightfield returns the gully FLOOR at that point, not the deck
## -- placing the player there put them below the world and triggered
## `severed_spokes`' own fall recovery mid-capture (confirmed the hard way,
## round 1 of this pass: the frame came back as a view up the gully wall with
## no bridge in it). `crossings[0].road`'s own polyline gives an already-tuned
## safe point on solid ground just short of the span (9, 1300), looking at the
## far landing (8, 1338) -- the same crossing, framed from ground the bridge's
## own builder already stands things on.
## Stations 09-16 (round 4), same never-hand-picked contract: every `at` is a
## literal `terrain_playground.json` `trail.bands[]` vertex for
## band3_the_river_lock / band4_upper_meadows_ironwood /
## band5_stronghold_approach, `look` the next vertex along the same polyline.
## Landmark identity checked against each band's own `props.json` cluster
## centroids and `terrain_playground.json`'s own `crossings[]`/site entries
## (never guessed):
##   09 (-30,4060): ROUND-6 ADDENDUM re-site, band3 pt9 (was pt1, -110,3290).
##     JUDGE-b3b5-before.md and JUDGE-round5.md both named the same defect
##     twice: this station is called "river-lock-entry" and showed no water.
##     Checked directly: `data/config/terrain_playground.json`'s `river.course`
##     (the actual carved geometry -- water.json's own `river` block is
##     presentation only, colour/flow/reeds, and carries no course of its
##     own) runs z 4080-4222 across the corridor's FULL x span (-1024 to
##     1021, per the block's own OW5C comment), so any station in that
##     z-band sees water regardless of x; the original pt1 (z=3290) sits
##     ~800m short of it, a gap no anchor can close. Moved to pt9, inside the
##     river's own z-band, looking at pt10 (-152,4170) where the Old Mill
##     Crossing narrows sit -- the water is not just reachable but the actual
##     crossing point.
##     Breaks this pass's own "in walked order" station numbering (09 now
##     sits geographically between what were stations 10/11 and 12) --
##     accepted deliberately, disclosed in the report, because showing the
##     water this station is named for outweighs numbering purity.
##   10 (230,3670): band3 pt5, matching `relay_approach_checkpoint`'s own
##     centroid (240.9,3673.7) to within 13m.
##   11 (350,3760): band3 pt6, exactly `tether_relay.json`'s site centre.
##   12 (-152,4170): `crossings[1]` (old_mill_crossing) road[0] -- NOT the
##     channel centre (-152,4203), which carves a 15m gully (`channel.depth`)
##     the same way South Bridge's own mid-span did to station 05 in round 1;
##     this is the same fix, applied before it could bite twice. Looks at
##     road[2] (-152,4235), the far landing.
##   13 (-300,4990): band4 pt2, a bend just after crossing into Band 4.
##   14 (-280,6460): band4 pt14. ROUND-4 ADDENDUM: `look` re-sited from the
##     next trail vertex to `ridge_patrol_camp`'s own props.json centroid
##     (-235.9,6471.7) -- the trail-vertex look put the camp 51.5 degrees off
##     axis, just past the ~51.3-degree half-FOV, so it never entered frame
##     at all (`JUDGE-b3b5-before.md`'s own finding: "neither ridge nor camp
##     is legible"). Still a documented site coordinate, not eyeballed.
##   15 (80,7370): band5 pt3, a bend on the final approach.
##   16 (20,7480): band5 pt4, looking at pt5 (0,7560) -- `stronghold.json`'s
##     own site centre, i.e. the Hall gate itself.
const STATIONS := [
	["01-village-edge",    Vector2(14.0, 20.0),    Vector2(8.0, 90.0)],
	["02-first-bend",      Vector2(-120.0, 270.0), Vector2(-230.0, 330.0)],
	["03-loop-apex",       Vector2(-330.0, 590.0), Vector2(-190.0, 650.0)],
	["04-eastward-swing",  Vector2(360.0, 910.0),  Vector2(430.0, 1020.0)],
	["05-south-bridge",    Vector2(9.0, 1300.0),   Vector2(8.0, 1338.0)],
	["06-stone-root-entry",Vector2(310.0, 1660.0), Vector2(400.0, 1800.0)],
	["07-band2-mid",       Vector2(20.0, 2130.0),  Vector2(-150.0, 2210.0)],
	["08-band2-far",       Vector2(-420.0, 2470.0),Vector2(-330.0, 2630.0)],
	["09-river-lock-entry",Vector2(-121.5, 4142.5),Vector2(-152.0, 4235.0)],
	["10-relay-approach",  Vector2(230.0, 3670.0), Vector2(350.0, 3760.0)],
	["11-relay",           Vector2(350.0, 3760.0), Vector2(280.0, 3900.0)],
	["12-old-mill-crossing",Vector2(-152.0, 4170.0),Vector2(-152.0, 4235.0)],
	["13-band4-entry-bend",Vector2(-300.0, 4990.0),Vector2(-420.0, 5140.0)],
	["14-ridge-camp-approach",Vector2(-280.0, 6460.0),Vector2(-235.9, 6471.7)],
	["15-stronghold-approach",Vector2(80.0, 7370.0),Vector2(20.0, 7480.0)],
	["16-hall-gate-approach",Vector2(20.0, 7480.0), Vector2(0.0, 7560.0)],
]

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _out_dir := DEFAULT_OUT_DIR

## FAST ITERATION MODE, same contract as the other VP capture tools: `--fast`
## or `VP_FAST=1` halves every settle wait (floor 2 frames) and disables
## MSAA/SSAA. Never used for the evidence frames that ship in a report.
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
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = "res://%s" % arg.substr(6).trim_prefix("res://").trim_suffix("/")
	if _fast_mode:
		print("[fast] iteration mode: settle halved, msaa off")
	print("[corridor] writing to %s" % _out_dir)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in _frames(BOOT_FRAMES):
		await physics_frame
	print("[corridor] world up, boot settled")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false

	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("FAIL no Player node; the frames would have no 1.80m ruler in them")
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
	else:
		print("WARN no Terrain.set_camera(); frames will be of whatever LOD reaches the eye")

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")

	# `--only=` takes a COMMA-SEPARATED list, not one substring -- found the
	# hard way this round: a two-station `--only=02-first-bend,06-stone-
	# root-entry` silently matched NOTHING (the whole joined string was never
	# a substring of either short station name) and the tool still printed
	# its normal "written to" summary, which read as success. Matches
	# `tools/_capture_locations.gd`'s own already-correct parsing.
	var only: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			for piece: String in arg.substr(7).split(",", false):
				var trimmed := piece.strip_edges()
				if trimmed != "":
					only.append(trimmed)
	if not only.is_empty():
		print("[corridor] --only=%s: re-shooting matching stations only" % ", ".join(only))

	await _pin("day")
	for entry: Variant in STATIONS:
		var shot: Array = _resolved_station(entry as Array)
		if only.is_empty() or _selected(only, str(shot[0])):
			await _shoot(shot)

	print("")
	print("corridor stations written to %s" % _out_dir)
	print("Software rendering under the Compatibility renderer: composition,")
	print("density and silhouette are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0)


## Round-4 addendum, station 11-relay only. The relay's yard is authored in
## its own (s,t) frame off a -34.4 degree approach bearing
## (`tether_relay.json`), so a hand-picked WORLD coordinate for "just inside
## the gate looking at the apparatus" would mean re-deriving that rotation --
## exactly the kind of hand math that produced this pass's own left/right
## sign bug twice already. `tools/_capture_locations.gd` solved this once,
## correctly, by asking the site's own `TetherRelay.world_of()` for the
## mapping; its `standing` shot's local `at`=(-8,-2) `look`=(7,-9) (just
## inside the gate, looking at the apparatus pad) is reused verbatim here
## rather than re-derived. The judge's own before-frame verdict for this
## corridor (`JUDGE-b3b5-before.md`) found the apparatus not in frame at all
## with the trail-vertex eye this station used until now; this fixes that
## without touching any relay config.
func _relay_world(local: Vector2) -> Variant:
	var node: Node = _world.get_node_or_null(^"TetherRelay")
	if node == null or not node.has_method("world_of"):
		print("  WARN TetherRelay has no world_of(); station 11 falls back to its trail-vertex eye")
		return null
	return node.call("world_of", local) as Vector2


func _resolved_station(shot: Array) -> Array:
	if str(shot[0]) != "11-relay":
		return shot
	var eye: Variant = _relay_world(Vector2(-8.0, -2.0))
	var look: Variant = _relay_world(Vector2(7.0, -9.0))
	if eye == null or look == null:
		return shot
	return [shot[0], eye, look]


func _selected(only: Array[String], station_id: String) -> bool:
	for want: String in only:
		if want in station_id:
			return true
	return false


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
	print("[corridor] clock pinned to %s and frozen" % time)


func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _shoot(shot: Array) -> void:
	var name: String = str(shot[0])
	var eye: Vector2 = shot[1]
	var target: Vector2 = shot[2]
	var toward := (target - eye).normalized()
	eye = _clear_of_bodies(eye, toward, _field.height_at(eye.x, eye.y))
	var back := eye - toward * BACK

	# Pass one: the analytic seat, so Terrain3D has somewhere to stream to.
	_place(eye, _field.height_at(eye.x, eye.y))
	_frame(back, _field.height_at(back.x, back.y), target, _field.height_at(target.x, target.y))
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame

	# Pass two: reseat on the real streamed surface, then settle so the
	# encounter director populates the region around the player.
	var ground := _surface(eye)
	_place(eye, ground)
	_frame(back, _surface(back), target, _surface(target))
	for i in _frames(SETTLE_FRAMES):
		await physics_frame
	_hide_huds()
	_frame(back, _surface(back), target, _surface(target))
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	var path := "%s/%s-day.png" % [_out_dir, name]
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % name)
		return
	print("  %-22s eye(%.0f, %.1f, %.0f)  %d creatures within 160m" % [
		name, eye.x, ground, eye.y, _creatures_near(Vector3(eye.x, ground, eye.y))])


## Same depenetration-avoidance as `_probe_corridor_survey.gd`: an authored
## path vertex can coincide closely enough with a static NPC/creature body that
## a player capsule spawned there has no lateral escape vector and gets shoved
## straight up by Godot's own depenetration. Step aside, perpendicular to the
## view line, before framing.
func _clear_of_bodies(eye: Vector2, toward: Vector2, ground: float) -> Vector2:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return eye
	var aside := Vector2(-toward.y, toward.x).normalized()
	for attempt in 4:
		var candidate := eye if attempt == 0 else eye + aside * 2.0 * float(attempt)
		var query := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.6
		capsule.height = 2.6
		query.shape = capsule
		query.transform = Transform3D(Basis(), Vector3(candidate.x, ground + 1.3, candidate.y))
		query.collide_with_bodies = true
		query.collide_with_areas = false
		if _player != null:
			query.exclude = [_player.get_rid()]
		var blocker := ""
		for hit: Dictionary in space.intersect_shape(query, 4):
			var body: Node = hit.get("collider") as Node
			if body == null or _under_terrain(body):
				continue
			blocker = body.name
			break
		if blocker == "":
			if attempt > 0:
				print("  NOTE (%.0f,%.0f) was occupied; landing moved %.1fm aside" % [
					eye.x, eye.y, (candidate - eye).length()])
			return candidate
	return eye


func _under_terrain(body: Node) -> bool:
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain == null:
		return false
	var node: Node = body
	while node != null:
		if node == terrain:
			return true
		node = node.get_parent()
	return false


func _place(at: Vector2, ground: float) -> void:
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


func _frame(eye: Vector2, eye_ground: float, target: Vector2, target_ground: float) -> void:
	_camera.global_position = Vector3(eye.x, eye_ground + UP, eye.y)
	_camera.look_at(Vector3(target.x, target_ground + 2.0, target.y), Vector3.UP)


## The analytic heightfield and the streamed collision surface disagree, by up
## to 22m near water. Raycast, and say so when the ray misses.
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
		print("  WARN no collision under (%.0f, %.0f); analytic %.2f may be under the surface" % [
			at.x, at.y, analytic])
		return analytic
	return float((hit["position"] as Vector3).y)


func _creatures_near(at: Vector3) -> int:
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	if director == null or not director.has_method("wild_creatures"):
		return -1
	var n := 0
	for wild: Variant in director.call("wild_creatures"):
		var body: Node3D = wild as Node3D
		if body != null and is_instance_valid(body):
			if body.global_position.distance_to(at) <= 160.0:
				n += 1
	return n


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
