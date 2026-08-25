extends SceneTree

## WORLD-GRASS. Four ground-plane viewpoints plus a mounted one, day only, so a
## blind critic can answer the one question this lane exists for: is the player
## standing IN grass, or on a picture of it.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_grass_pass.gd -- --out=shots/grass_r0
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (ralph/conventions.md, "Art pipeline traps").
##
## Why a new tool rather than `--only=` against `_probe_corridor_survey.gd`:
## that survey is twelve day eyes plus four night ones at 45 settle frames
## each, and it was budgeted against a 143,630-prop world. The committed bake
## is now 466,922, so every awaited frame costs proportionally more software
## rasterising and the full pass no longer fits in a session. This keeps that
## tool's three hard-won corrections -- pin AND FREEZE the clock, hand Terrain3D
## the capture camera, carry the PLAYER to each viewpoint so the world
## populates around them -- and cuts everything that is not ground cover.
##
## Two cameras per site, from ONE seating, because the ground plane fails in two
## different places and a single framing hides one of them:
##
##   `-eye`  over-the-shoulder at 2.4m, aimed level down the route. This is the
##           MIDDLE DISTANCE frame: it is where `lod_range` shows up as a bald
##           ring, and it is the same framing `_probe_corridor_survey.gd` uses
##           so its sheets remain comparable.
##   `-near` a 1.2m camera pitched into the ground 9m ahead. This is the NEAR
##           FIELD frame, the one that answers whether a standing figure is in
##           cover to the shin. The over-the-shoulder frame cannot answer it:
##           at 2.4m looking level, the metres around the player's own feet are
##           in the bottom eighth of the image.
##
## The mounted frame is last on purpose. It needs a party, a saddle, a summon
## and a live `RidingController`, any of which can fail on a scene change; the
## four on-foot frames are already written by the time it runs, so a failure
## there costs one frame rather than the sheet.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const MOUNT_SPECIES := "meadowhart"

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 45
const ARRIVE_FRAMES := 20
const POSE_FRAMES := 4
const FOV := 70.0

## Over-the-shoulder eye: `_probe_corridor_survey.gd`'s own numbers, unchanged,
## so frames from the two tools sit beside each other honestly.
const BACK := 4.2
const UP := 2.4
## Near-field eye. 1.2m is roughly a walking camera dropped to chest height;
## `NEAR_AHEAD` is how far down the view line it aims, which sets the pitch.
const NEAR_UP := 1.2
const NEAR_BACK := 2.6
const NEAR_AHEAD := 9.0
## Off-route eye: how far to the side of the authored route the player is stood
## for the `-off` frame, and how high that camera sits. 10m clears the path's
## own 3.5m half-width and the grass layer's 0.3-3.0m standoff several times
## over, so what is under the player is meadow rather than verge.
const OFF_ROUTE := 10.0
const OFF_UP := 1.6

## name, eye XZ, look-at XZ. Four regions the prompt names, each on ordinary
## travelled ground rather than on a set piece -- a critic shown only the good
## spots is being asked a different question than the one that matters.
const VIEWPOINTS := [
	["01-band1-open-meadow", Vector2(8.0, 90.0), Vector2(-40.0, 180.0)],
	["02-band2-forest-floor", Vector2(310.0, 1660.0), Vector2(400.0, 1800.0)],
	["03-band3-crossing", Vector2(-152.0, 4170.0), Vector2(-100.0, 4350.0)],
	["04-band4-high-pasture", Vector2(-280.0, 6460.0), Vector2(-70.0, 6720.0)],
]

## Where the mounted frame is taken. Band 1's open meadow, because the
## reference frame it answers to (`docs/reference/moong-01-mounted-in-tall-
## grass.jpg`) is open ground with the mount's legs in the cover.
const MOUNT_VIEW := ["05-band1-mounted", Vector2(-60.0, 220.0), Vector2(-120.0, 330.0)]
## The mounted camera sits lower and further back than the on-foot one: the
## reference's framing puts the animal's legs -- the ruler for "how deep is
## this cover" -- in the lower third, which a 2.4m eye crops out.
const MOUNT_UP := 1.9
const MOUNT_BACK := 5.4

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _out_dir := "res://shots/grass"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = "res://" + arg.substr(6).trim_prefix("res://")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	print("[grass] writing to %s" % _out_dir)

	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[grass] world up, boot settled")

	# The rig drives the player's own camera; left running it fights every
	# `make_current()` below and re-frames the shot between pose and shutter.
	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

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

	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)

	await _pin("day")
	for entry: Variant in VIEWPOINTS:
		var shot: Array = entry as Array
		if only == "" or only in str(shot[0]):
			await _shoot(shot)

	if only == "" or only in str(MOUNT_VIEW[0]):
		await _shoot_mounted()

	print("")
	print("grass pass written to %s" % _out_dir)
	print("Software rendering under the Compatibility renderer: composition,")
	print("density and silhouette are trustworthy; frame times are not a")
	print("performance measurement.")
	quit(0)


## Pin the clock, then STOP both clocks. A pin that is not frozen wears off
## across a multi-viewpoint pass and the later frames come back in a dusk wash.
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


## A HUD that did not exist at boot is still a HUD in the frame. Re-hidden
## shallowly before every shutter; CanvasLayers are never inside the scatter.
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
	eye = _clear_of_bodies(eye, toward, _surface(eye))
	var back := eye - toward * BACK

	# Pass one: the analytic seat, so Terrain3D has somewhere to stream to.
	_place(eye, _field.height_at(eye.x, eye.y))
	_frame(back, _field.height_at(back.x, back.y), UP, target, _field.height_at(target.x, target.y), 2.0)
	for i in ARRIVE_FRAMES:
		await physics_frame

	# Pass two: reseat on the surface that actually arrived, then stand still
	# long enough for the encounter director to populate around the player.
	var ground := _surface(eye)
	_place(eye, ground)
	_frame(back, _surface(back), UP, target, _surface(target), 2.0)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _expose("%s-eye" % name, back, UP, target, 2.0)

	# Near field, same seating: a lower eye pitched into the ground just ahead
	# of the player, which is where "am I standing in it" is actually visible.
	var near_eye := eye - toward * NEAR_BACK
	var near_at := eye + toward * NEAR_AHEAD
	await _expose("%s-near" % name, near_eye, NEAR_UP, near_at, 0.0)

	# And the same near question asked OFF the route, which the two frames above
	# cannot answer however they are tuned. Both of them stand on the trail and
	# aim down it, so the bottom of the image is the worn band -- and at a 1.2m
	# eye the bottom of the image is only two or three metres ahead, where a
	# path 7m wide (terrain_playground.json `paths`: width 2.0, shoulder 2.5 a
	# side, so path_factor reaches zero 3.5m off the centreline) subtends the
	# whole frame width. Two blind passes in a row read that as the defect,
	# measured the lower frame's colour, and reported the meadow as rendering in
	# the trail's palette -- which is what the lower frame IS, and says nothing
	# about the meadow. Sampled off-route in the same world the ground measures
	# hue 72.6 at value 0.435 against the reference's own 68.4/0.529, so the
	# grass palette was never the thing those measurements found. This frame
	# stands the player ten metres off the route in open ground so ground cover
	# is judged on ground the player actually crosses rather than on road.
	var off_dir := Vector2(-toward.y, toward.x)
	var off := _clear_of_bodies(eye + off_dir * OFF_ROUTE, toward, _surface(eye))
	_place(off, _surface(off))
	for i in 20:
		await physics_frame
	await _expose("%s-off" % name, off - toward * NEAR_BACK, OFF_UP,
		off + toward * NEAR_AHEAD, 0.0)
	# Put the player back where the site is, so the next viewpoint's own
	# streaming starts from the seat this one reported.
	_place(eye, ground)

	print("  %-24s eye(%.0f, %.1f, %.0f)  %d creatures within 160m" % [
		name, eye.x, ground, eye.y, _creatures_near(Vector3(eye.x, ground, eye.y))])


## Frame, settle, hide HUDs, shutter. Split out of `_shoot` because the near
## and eye cameras share one seating and one settle -- re-settling for the
## second camera would double the cost of the pass for no new information.
func _expose(name: String, eye: Vector2, up: float, target: Vector2, target_up: float) -> void:
	_hide_huds()
	_frame(eye, _surface(eye), up, target, _surface(target), target_up)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	if image.save_png("%s/%s.png" % [_out_dir, name]) != OK:
		print("FAIL %s: save_png" % name)


## The mounted frame. Follows `tests/smoke_riding.gd`'s setup exactly rather
## than reaching into the controller: party, saddle, summon, then the real
## `mount()`. Anything that fails here prints and returns -- the on-foot sheet
## is already on disk.
func _shoot_mounted() -> void:
	var name: String = str(MOUNT_VIEW[0])
	var riding: Node = _world.get_node_or_null(^"RidingController")
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	var game: Node = root.get_node_or_null(^"/root/Game")
	if riding == null or director == null or game == null:
		print("FAIL %s: no RidingController/EncounterDirector/Game" % name)
		return
	var party: RefCounted = game.get("party")
	var bag: RefCounted = game.get("inventory")
	if party == null or bag == null:
		print("FAIL %s: Game has no party/inventory" % name)
		return

	var eye: Vector2 = MOUNT_VIEW[1]
	var target: Vector2 = MOUNT_VIEW[2]
	var toward := (target - eye).normalized()
	eye = _clear_of_bodies(eye, toward, _surface(eye))

	# Seat the player first: the director spawns and streams around them, so a
	# summon issued 6km from where the shot is taken arrives in the wrong place.
	_place(eye, _field.height_at(eye.x, eye.y))
	_frame(eye - toward * MOUNT_BACK, _field.height_at(eye.x, eye.y), MOUNT_UP,
		target, _field.height_at(target.x, target.y), 1.2)
	for i in ARRIVE_FRAMES:
		await physics_frame
	_place(eye, _surface(eye))
	for i in 20:
		await physics_frame

	if director.call("ally_body") != null:
		director.call("dismiss_active_creature")
		for i in 20:
			await physics_frame
	var mount: RefCounted = SPECIES.spawn(MOUNT_SPECIES)
	if mount == null or not bool(party.call("add", mount)):
		print("FAIL %s: could not put a %s in the party" % [name, MOUNT_SPECIES])
		return
	for i in int(party.call("size")):
		if party.call("at", i) == mount:
			party.call("set_active", i)
			break
	bag.call("add", "saddle", 1)
	await director.call("summon_active_creature")
	for i in 90:
		await physics_frame
		var b: Node3D = director.call("ally_body")
		if b != null and is_instance_valid(b) and b.visible:
			break
	var body: Node3D = director.call("ally_body")
	if body == null or not is_instance_valid(body):
		print("FAIL %s: the %s never appeared" % [name, MOUNT_SPECIES])
		return
	if not bool(riding.call("mount")):
		print("FAIL %s: mount() refused (distance %.1fm)" % [
			name, _player.global_position.distance_to(body.global_position)])
		return
	for i in SETTLE_FRAMES:
		await physics_frame

	# The mount is what the camera frames now, not the trainer inside it.
	var at := Vector2(body.global_position.x, body.global_position.z)
	var mount_back := at - toward * MOUNT_BACK
	var mount_at := at + toward * 10.0
	await _expose(name, mount_back, MOUNT_UP, mount_at, 0.6)
	print("  %-24s mounted at (%.0f, %.0f)" % [name, at.x, at.y])

	# Then get off, and shoot the pair. The mounted frame CANNOT answer the
	# rubric's scale criterion on its own, because riding hides the trainer's
	# model: `player_controller.gd::set_carrier` does it deliberately -- the
	# trainer rig has no seated clip (idle/walk/sprint/throw only), so a visible
	# rider would stand bolt upright on the creature's back, and hidden is the
	# honest placeholder until a sit clip exists. The consequence for a critic is
	# real and was paid for once: shown only the mounted frame, a blind pass
	# reported "no rider on the mount" as a defect and then, having no 1.80m
	# ruler beside the animal, concluded from the grass around it that the mount
	# was fawn-sized and could not carry a person. This second frame puts the
	# trainer on the ground next to the creature so that question is answerable
	# from the picture instead of guessed.
	riding.call("dismount")
	for i in 30:
		await physics_frame
	var beside := at - Vector2(-toward.y, toward.x) * 2.2
	_place(beside, _surface(beside))
	for i in 20:
		await physics_frame
	await _expose("%s-beside" % name, mount_back, MOUNT_UP, mount_at, 0.6)


## Step the seat aside when it lands inside a static NPC capsule: a player
## capsule centred on another capsule has no lateral escape vector, so
## depenetration shoves it straight up and the frame shows the trainer standing
## on the NPC's head. The harness choosing an occupied seat, not the game
## misbehaving -- see `_probe_corridor_survey.gd`'s own note.
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


func _frame(eye: Vector2, eye_ground: float, up: float,
		target: Vector2, target_ground: float, target_up: float) -> void:
	_camera.global_position = Vector3(eye.x, eye_ground + up, eye.y)
	_camera.look_at(Vector3(target.x, target_ground + target_up, target.y), Vector3.UP)


## The analytic heightfield and the streamed collision surface disagree by
## metres. Seating an eye on the analytic value buries the camera inside the
## terrain wherever the real ground is higher, and what comes back is the
## UNDERSIDE of the ground. Raycast, and say so out loud when the ray misses.
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
