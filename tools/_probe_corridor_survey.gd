extends SceneTree

## THE FULL-CORRIDOR BLIND PASS. One survey that walks the whole Meadows
## chapter -- band 1 through band 5, 7.5 km -- so a blind critic can answer the
## question no single-region sheet can: do these frames read as ONE place, and
## as the place `docs/reference/tetherbound-meadows-keyart.png` draws.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_corridor_survey.gd
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (ralph/conventions.md, "Art pipeline traps").
##
## This tool is the union of three earlier tools' hard-won corrections, because
## each of them had exactly one of the three and the other two were still bugs:
##
## 1. `capture_band3_region.gd` pins the day/weather clock AND FREEZES both
##    nodes' processing. Pinning alone wears off: a settle plus a dozen framed
##    shots is minutes of game time, and the later frames come back in a dusk
##    wash under whatever weather rolled. `survey_band2.gd` pins without
##    freezing, which is why its "day" frames were judged as crimson.
## 2. `capture_band3_region.gd` also hands Terrain3D the CAPTURE camera.
##    `playground_world.gd` gives it the player's camera, so a tool that parks
##    the player elsewhere photographs whatever coarse LOD happened to reach
##    the viewpoint. Measured there: 16 of 18 ground raycasts hit nothing.
## 3. `_probe_band5_approach.gd` carries the PLAYER to each viewpoint, because
##    creature spawning is driven off the player. Band 5's round 1 moved only
##    the camera and photographed 22 authored clusters as empty meadow; the
##    critic correctly refused the sheet, since criterion 8 needs the 1.80 m
##    trainer in frame as its ruler.
##
## Holding all three at once needs the player and the capture camera to travel
## TOGETHER -- player on the viewpoint so the world populates around them,
## camera over their shoulder so they are the ruler, and Terrain3D following
## the camera so the ground under both is the real streamed surface.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/corridor"

## MEASURED, not guessed. The first attempt at this survey used the frame
## counts the single-region probes use (240 boot, 40 arrive, 150 settle) and
## did not reach its FIRST shutter in seventeen minutes. The world is not the
## problem -- it stands up complete in under a minute (143,630 props, village,
## relay, warrens and stronghold all logged). The problem is that every awaited
## frame is a full software render of those 143,630 props under llvmpipe, which
## measured ~2.4 s/frame at 1280x800. At that rate the original budget of 3,376
## frames is a hundred and thirty-five minutes and the run dies on its timeout
## having written nothing.
##
## So the counts below are a budget, not a preference: ~1,200 frames, ~48
## minutes. Each is still doing its job -- ARRIVE covers the Terrain3D stream
## after a kilometre jump, SETTLE covers the encounter director populating
## around the player -- and the per-shot creature count printed beside every
## frame is the check that SETTLE is still long enough. A run that reports
## zeroes has been cut too far and the number goes back up.
const BOOT_FRAMES := 90
const SETTLE_FRAMES := 45    # at each viewpoint, so spawning catches up
const ARRIVE_FRAMES := 20    # after the analytic seat, before the ray reseat
const POSE_FRAMES := 4
const FOV := 70.0
const BACK := 4.2            # camera metres behind the player
const UP := 2.4              # camera metres above the ground

## Twelve eyes down the authored spine, in the order a player meets them.
## Weighted toward bands 4 and 5 because those are the two this pass re-judges
## after the density re-bake, and deliberately including each band's ordinary
## travel rather than only its set pieces -- a critic shown only the good spots
## is being asked a different question than the one that matters.
const VIEWPOINTS := [
	["01-band1-opening",     Vector2(8.0, 90.0),      Vector2(-40.0, 180.0)],
	["02-band1-the-loop",    Vector2(-330.0, 590.0),  Vector2(-50.0, 700.0)],
	["03-band2-stone-root",  Vector2(310.0, 1660.0),  Vector2(400.0, 1800.0)],
	["04-band2-warrens",     Vector2(-420.0, 2470.0), Vector2(-330.0, 2630.0)],
	["05-band3-relay",       Vector2(230.0, 3670.0),  Vector2(350.0, 3760.0)],
	["06-band3-crossing",    Vector2(-152.0, 4170.0), Vector2(-100.0, 4350.0)],
	["07-band4-entry",       Vector2(-300.0, 4990.0), Vector2(-420.0, 5140.0)],
	["08-band4-ironwood",    Vector2(170.0, 5590.0),  Vector2(450.0, 5860.0)],
	["09-band4-ridge",       Vector2(-280.0, 6460.0), Vector2(-70.0, 6720.0)],
	["10-band5-mouth",       Vector2(0.0, 7000.0),    Vector2(0.0, 7560.0)],
	["11-band5-mid-route",   Vector2(-20.0, 7250.0),  Vector2(0.0, 7560.0)],
	["12-band5-the-gate",    Vector2(20.0, 7480.0),   Vector2(0.0, 7560.0)],
]

## The night set is a subset, not a repeat: four eyes, one per lighting question
## the ledger has open (forest interior, open upland, the approach, the gate).
## Same eyes as their day twins, so day and night differ in exactly one
## variable and the critic can attribute what it sees.
const NIGHT := ["03-band2-stone-root", "08-band4-ironwood",
	"10-band5-mouth", "12-band5-the-gate"]

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[corridor] world up, boot settled; starting the day pass")

	# The rig drives the player's own camera; left running it fights every
	# `make_current()` below and re-frames the shot between the pose frames and
	# the shutter.
	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	# Once, deep: catch every CanvasLayer the world built during `_ready`.
	# Band 5's round 1 burned the HUD, an open rest menu and a "TEAM 0/5" card
	# into all twelve frames and the critic spent a numbered defect on it.
	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false

	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("no Player node; the frames would have no 1.80m ruler in them")
		quit(1)
		return

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	else:
		print("WARN no Terrain.set_camera(); frames will be of whatever LOD reaches the eye")

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")

	await _pin("day")
	for entry: Variant in VIEWPOINTS:
		await _shoot(entry as Array, "day")

	await _pin("night")
	for entry: Variant in VIEWPOINTS:
		var shot: Array = entry as Array
		if str(shot[0]) in NIGHT:
			await _shoot(shot, "night")

	print("")
	print("corridor survey written to %s" % OUT_DIR)
	print("Software rendering under the Compatibility renderer: composition,")
	print("density and silhouette are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0)


## Pin the clock to `time`, then STOP both clocks. Order matters and freezing
## matters: a pin that is not frozen wears off across a twelve-viewpoint pass.
func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	if _look != null:
		_look.set_process(true)
		_look.set_physics_process(true)
		_look.call("apply_time", time)
	for i in 30:
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null:
		_look.set_process(false)
		_look.set_physics_process(false)


## A HUD that did not exist at boot -- a combat HUD, a prompt, an interaction
## card raised by standing next to something -- is still a HUD in the frame.
## Re-hidden before every shutter, shallowly: the deep walk is 143,630 nodes
## and CanvasLayers are never buried inside the scatter.
func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _shoot(shot: Array, suffix: String) -> void:
	var name: String = str(shot[0])
	var eye: Vector2 = shot[1]
	var target: Vector2 = shot[2]
	var toward := (target - eye).normalized()
	eye = _clear_of_bodies(eye, toward, _surface(eye))
	var back := eye - toward * BACK

	# Pass one: the analytic seat, so Terrain3D has somewhere to stream to.
	# There is no collision to raycast against until the camera is already
	# standing there, so the real seat cannot be asked for yet.
	_place(eye, _field.height_at(eye.x, eye.y))
	_frame(back, _field.height_at(back.x, back.y), target, _field.height_at(target.x, target.y))
	for i in ARRIVE_FRAMES:
		await physics_frame

	# Pass two: reseat both the body and the eye on the surface that actually
	# arrived, then stand still long enough for the encounter director to
	# populate the region around the player.
	var ground := _surface(eye)
	_place(eye, ground)
	_frame(back, _surface(back), target, _surface(target))
	for i in SETTLE_FRAMES:
		await physics_frame
	_hide_huds()
	_frame(back, _surface(back), target, _surface(target))
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s-%s: viewport returned no image" % [name, suffix])
		return
	var path := "%s/%s-%s.png" % [OUT_DIR, name, suffix]
	if image.save_png(path) != OK:
		print("FAIL %s-%s: save_png" % [name, suffix])
		return
	print("  %-22s %-5s eye(%.0f, %.1f, %.0f)  %d creatures within 160m" % [
		name, suffix, eye.x, ground, eye.y, _creatures_near(Vector3(eye.x, ground, eye.y))])


## Trainer and villager bodies (`npc_body.gd`) are STATIC capsule colliders
## parked dead-centre on their own authored `position` -- and two of this
## survey's own viewpoints turn out to equal that exact coordinate: band4's
## ironwood and ridge captains sit at (170,5590) and (-280,6460)
## (`data/config/bands/band4_upper_meadows_ironwood/trainers.json`), the same
## points `VIEWPOINTS` above names for "08-band4-ironwood" and "09-band4-
## ridge". A player capsule spawned centred on another capsule has no lateral
## escape vector, so Godot's depenetration shoves it straight UP the shared
## axis instead of sideways -- which is exactly the "trainer standing on the
## NPC's head" a blind critic flagged in three frames. No walking player ever
## produces that: nobody centres themselves ON the person they are about to
## fight (`trainer_npc.gd`'s PROMPT_RADIUS keeps the challenge prompt ~4m off,
## and the fastest way to a trainer's exact tile is a straight walk-in, which
## the collider itself blocks well before the centres coincide). This is the
## harness choosing an occupied seat, not the game misbehaving -- so step the
## seat aside before framing rather than photograph the harness's own mistake.
func _clear_of_bodies(eye: Vector2, toward: Vector2, ground: float) -> Vector2:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return eye
	# Perpendicular to the view line, so a step aside barely changes the shot.
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
				print("  NOTE (%.0f,%.0f) was occupied by an NPC body; landing moved %.1fm aside" % [
					eye.x, eye.y, (candidate - eye).length()])
			return candidate
	return eye


## Terrain3D's own collision is a StaticBody3D too, and the occupancy
## capsule's lower edge can graze a slope. Only a body OUTSIDE the Terrain
## node counts as something worth stepping around.
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


## The analytic heightfield and the streamed collision surface disagree -- by
## nearly 3 m on ordinary ground and up to 22 m near the river channel. Seating
## an eye on the analytic value buries the camera inside the terrain wherever
## the real ground is higher, and what comes back is the UNDERSIDE of the
## ground: a flat dead-coloured plane with the world ending in mid-air above
## it, which a critic reported as a water plane because there was no way to
## know better. Raycast, and say so out loud when the ray misses.
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


## How populated the frame's neighbourhood actually is, printed beside every
## shot, and the check that SETTLE_FRAMES is still long enough.
##
## Asked the director rather than walked from the scene tree, for two reasons.
## `is_in_group("creatures")` returns zero -- `encounter_director.gd` puts
## spawned bodies in no group at all, and Band 5's round 2 nearly reported "the
## region's 75 creatures do not spawn" on the strength of that check. A name
## walk works but is the wrong instrument here: this world carries 143,630
## props, so rebuilding an Array of every node in it once per shot costs more
## than the shot does. `wild_creatures()` is the director's own registry.
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
