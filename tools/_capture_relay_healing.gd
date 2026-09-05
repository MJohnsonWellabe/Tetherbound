extends SceneTree

## CL-E12 / contract V-5's own evidence: does the ground inside the relay's
## site radius actually CHANGE when the console is pressed?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_relay_healing.gd
##
## NEVER with `--headless` and a rendering driver: that combination hangs
## forever, with no error and no crash.
##
## V-5's *fails if* is written as a picture -- "a before/after frame from the
## 06-relay-standing stand shows no ground change inside the site radius" -- so
## this takes exactly that pair, in ONE boot, with nothing between the two
## frames but the console press and the heal it starts. One world, one camera,
## one set of coordinates: anything that differs between the two images is the
## healing, because nothing else had the chance to move.
##
## WHY NOT JUST RUN `tools/_capture_locations.gd --only=06-relay`. That tool
## photographs the world as it stands and has no way to press anything, so it
## can produce a before or an after but never a pair from one boot -- and a
## pair from two boots is two different scatters, two different light
## accumulations and two different Terrain3D stream states, which is exactly
## the kind of comparison that proves nothing. The two stands below are
## `_capture_locations.gd`'s own `06-relay` `standing` and `approach` shots,
## same local coordinates, same rig numbers, so the frames are comparable with
## that tool's own survey rather than being a private viewpoint.
##
## THE NUMBER IS DECIDED BEFORE THE RENDER, not chosen from the result. What
## the heal puts back is PLANTS, so the measure is green excess --
## mean(G - (R+B)/2) over the frame, in 0..1 units. Regrowth raises it; a
## fading grey drain skin also raises it slightly by uncovering ground colour.
## The prediction is after > before on both stands. Mean luminance is printed
## beside it because the skin fade alone would move that, and separating the
## two is what stops "the picture got brighter" being read as "plants grew".
## The counts printed with each pair are the ground truth the pixels are only
## evidence for: how many drained placements were held inside the relay's own
## stations before, and how many came back.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/relay_healing"
const RELAY_CONFIG := "res://data/config/tether_relay.json"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const BOOT_FRAMES := 240
const SETTLE_FRAMES := 90
const POSE_FRAMES := 8

## `_capture_locations.gd`'s own RIG, for the two modes these stands use.
const RIG := {
	"approach": {"back": 7.0, "up": 3.2},
	"standing": {"back": 3.2, "up": 1.70},
}

## `06-relay`'s own shots, verbatim from `tools/_capture_locations.gd`, in the
## relay's local (s,t) frame. `approach` carries that file's own `back` 4.0
## override -- the fix that stopped the camera standing 29 m into unprobed
## ground and rendering a wall of canopy.
const SHOTS := [
	{"label": "standing", "mode": "standing", "at": Vector2(-8.0, -2.0), "look": Vector2(7.0, -9.0)},
	{"label": "approach", "mode": "approach", "at": Vector2(-20.0, 0.0), "look": Vector2(-14.0, 0.0),
		"back": 4.0},
]

var _world: Node = null
var _relay: Node3D = null
var _player: Node3D = null
var _camera: Camera3D = null
var _field: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[relay-heal] headless has no renderer; run this under xvfb-run")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame

	_relay = _world.get_node_or_null(^"TetherRelay") as Node3D
	_player = _world.get_node_or_null(^"Player") as Node3D
	if _relay == null or _player == null:
		print("[relay-heal] no TetherRelay or no Player in the scene")
		quit(1)
		return
	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.far = 3000.0
	_world.add_child(_camera)
	_camera.make_current()
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	var held_before := _drained_inside()
	print("[relay-heal] drained placements held inside the relay's own stations: %d (%d elsewhere)"
		% [held_before["inside"], held_before["outside"]])

	var before: Dictionary = {}
	for raw: Variant in SHOTS:
		before[str((raw as Dictionary)["label"])] = await _shoot(raw as Dictionary, "before")

	# The console, pressed exactly as the player presses it. `relay_captain_defeated`
	# is the shipped `requires_flag`; granting it here is the fight the player
	# would have won, not a bypass of the healing being tested.
	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		progression.call("set_flag", "relay_captain_defeated")
	if not bool(_relay.call("disable_relay")):
		print("[relay-heal] the console refused; nothing to photograph")
		quit(1)
		return
	print("[relay-heal] console pressed; waiting for the skin fade to finish")
	var started := Time.get_ticks_msec()
	while not bool(_relay.call("healed")) and Time.get_ticks_msec() - started < 60000:
		await process_frame
	for i in SETTLE_FRAMES:
		await physics_frame

	var held_after := _drained_inside()
	print("[relay-heal] after the press: %d held inside, %d elsewhere -> %d plants back inside the site"
		% [held_after["inside"], held_after["outside"], held_before["inside"] - held_after["inside"]])

	print("[relay-heal] ---- measured, on the metric chosen before the render ----")
	for raw: Variant in SHOTS:
		var shot: Dictionary = raw
		var label := str(shot["label"])
		var after: Dictionary = await _shoot(shot, "after")
		var was: Dictionary = before.get(label, {})
		if was.is_empty() or after.is_empty():
			continue
		print("[relay-heal] %-9s green excess %.5f -> %.5f (%+.5f)   luminance %.4f -> %.4f (%+.4f)"
			% [label, was["green"], after["green"], after["green"] - was["green"],
				was["luma"], after["luma"], after["luma"] - was["luma"]])
	print("[relay-heal] frames in %s" % OUT_DIR)
	quit(0)


## How many drained placements the vegetation is still holding inside the
## relay's own authored discs, and how many outside them. Same two sources the
## heal itself reads, so this is the mechanism's own ground truth.
func _drained_inside() -> Dictionary:
	var out := {"inside": 0, "outside": 0}
	var vegetation := _world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		return out
	var discs := _relay_discs()
	var held: Dictionary = vegetation.get("_drained")
	for layer_name: String in held.keys():
		for entry: Variant in (held[layer_name] as Array):
			var at: Vector3 = (entry as Dictionary).get("position", Vector3.ZERO)
			var spot := Vector2(at.x, at.z)
			var inside := false
			for raw: Variant in discs:
				var disc: Dictionary = raw
				if spot.distance_to(disc["centre"] as Vector2) <= float(disc["radius"]):
					inside = true
					break
			if inside:
				out["inside"] = int(out["inside"]) + 1
			else:
				out["outside"] = int(out["outside"]) + 1
	return out


func _relay_discs() -> Array:
	var relay_config := _json(RELAY_CONFIG)
	var wanted: Dictionary = {}
	for raw: Variant in ((relay_config.get("dead_ground", {}) as Dictionary).get("heal_stations", []) as Array):
		wanted[str(raw)] = true
	var discs: Array = []
	for raw: Variant in ((_json(TERRAIN_CONFIG).get("drains", {}) as Dictionary).get("stations", []) as Array):
		var station: Dictionary = raw
		if not wanted.has(str(station.get("id", ""))):
			continue
		var centre: Array = station.get("centre", [])
		if centre.size() < 2:
			continue
		discs.append({"centre": Vector2(float(centre[0]), float(centre[1])),
			"radius": float(station.get("radius", 0.0))})
	return discs


func _shoot(shot: Dictionary, suffix: String) -> Dictionary:
	var eye: Vector2 = _relay.call("world_of", shot["at"] as Vector2)
	var target: Vector2 = _relay.call("world_of", shot["look"] as Vector2)
	var default_rig: Dictionary = RIG.get(str(shot["mode"]), RIG["standing"])
	var back_m := float(shot.get("back", default_rig["back"]))
	var up_m := float(shot.get("up", default_rig["up"]))
	var toward := (target - eye).normalized()
	var back := eye - toward * back_m
	var eye_ground := float(_field.call("height_at", eye.x, eye.y))
	var back_ground := float(_field.call("height_at", back.x, back.y))
	var look_ground := float(_field.call("height_at", target.x, target.y))
	if is_nan(back_ground):
		back_ground = eye_ground
	# The ruler goes first and gets frames to stand, so whatever the world
	# populates around a player at that spot is in the picture.
	_player.global_position = Vector3(eye.x, eye_ground + 0.4, eye.y)
	_camera.global_position = Vector3(back.x, back_ground + up_m, back.y)
	_camera.look_at(Vector3(target.x, look_ground + 1.6, target.y), Vector3.UP)
	for i in SETTLE_FRAMES:
		await physics_frame
	for layer: Node in _all(_world):
		if layer is CanvasLayer:
			(layer as CanvasLayer).visible = false
	_camera.global_position = Vector3(back.x, back_ground + up_m, back.y)
	_camera.look_at(Vector3(target.x, look_ground + 1.6, target.y), Vector3.UP)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("[relay-heal] FAIL %s-%s: the viewport returned no image" % [str(shot["label"]), suffix])
		return {}
	var path := "%s/06-relay-%s-%s.png" % [OUT_DIR, str(shot["label"]), suffix]
	image.save_png(path)
	print("[relay-heal] wrote %s" % path)
	return _measure(image)


## The metric, fixed before the first render: mean green excess and mean
## luminance over the whole frame, both in 0..1.
func _measure(image: Image) -> Dictionary:
	var green := 0.0
	var luma := 0.0
	var n := 0
	var step := 2
	var x := 0
	while x < image.get_width():
		var y := 0
		while y < image.get_height():
			var c := image.get_pixel(x, y)
			green += c.g - (c.r + c.b) * 0.5
			luma += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
			y += step
		x += step
	if n == 0:
		return {"green": 0.0, "luma": 0.0}
	return {"green": green / float(n), "luma": luma / float(n)}


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
