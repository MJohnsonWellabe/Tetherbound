extends SceneTree

## F05#7 visual evidence: "the land heals", through the PRODUCTION player
## camera rig with the HUD on. Nothing hidden, nothing touched up.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 12 --script tools/capture_f05_heal.gd -- <out_dir>
##
## `--fixed-fps` makes every frame advance the game clock by exactly 1/fps s,
## so "t = 4.25 s after the freeing" is a frame count and not a guess about
## how fast a software rasteriser happened to run (round 5 sampled the pylon
## fall by frame count at an assumed 60 fps and the fall fell between samples).
## The tool reads the rate back from the frame delta.
##
## Disclosed staging: the earned main chain up to the Warden is set directly
## (as in capture_finale.gd); then `legendary_freed` is set directly while the
## player stands side-on to one approach pylon, instead of pulling the lever
## in the chamber -- so the heal is seen happening where it happens. The player
## is placed at each vantage and the rig's yaw and pitch set behind them.
##
## Round 6 vantages (blind round 5: "the land itself does not change" at the
## quarry and approach; the fall "not captured"; the herd "a lineup"):
##   * before/after pairs that stand over the drained ground and look across it
##     (camera pitched down so the ground fills the frame, not the sky);
##   * the fall seen side-on to the pylon's authored fall azimuth
##     (meadow_healing.json pylons.falls), sampled every 0.25 s from 3 s to 8 s;
##   * the Highfield from inside the herd's open arc, before and after.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CONFIG := "res://data/config/meadow_healing.json"
const SETTLE_S := 8.0
const SHOT_S := 1.2
## Every frame is taken at this one hour: the day clock is pinned, so a
## before and an after differ only by the event. 325 s of the 600 s day = 13:00.
const HOLD_CLOCK_S := 325.0

## [name, stand x, stand z, look x, look z, pitch_deg]. The stands are inside
## the drained discs (terrain_playground.json drains.stations): the quarry
## conduit head (r 24), approach_run_5/6 (r 22/24) and the works (r 42).
const VANTAGES := [
	["quarry", 396.0, 1816.0, 410.0, 1792.0, -22.0],
	["approach", -30.0, 7420.0, -10.0, 7446.0, -20.0],
	["works", -18.0, 7536.0, 4.0, 7556.0, -18.0],
	["highfield", 392.5, 5854.0, 398.0, 5869.0, -10.0],
]
## The fall: which approach pylons may be used, by child index, in order of
## preference (index i creaks at 0.35 i s and is down by 0.35 i + 3.85 s, so
## 5..8 put the whole fall inside the 3-8 s window), and the side-on distances.
const FALL_INDICES := [6, 5, 7, 8, 4, 9]
const FALL_DISTANCES := [22.0, 26.0, 18.0]
const WILD_CLEAR_M := 70.0
const FALL_SAMPLES_S := [1.0, 2.0, 3.0, 3.25, 3.5, 3.75, 4.0, 4.25, 4.5, 4.75, 5.0, 5.25,
	5.5, 5.75, 6.0, 6.25, 6.5, 6.75, 7.0, 7.25, 7.5, 7.75, 8.0, 12.0]

var _out := "user://f05_heal_shots"
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _look: Node = null
var _fps := 60
var _last_delta := 0.0


func _process(delta: float) -> bool:
	_last_delta = delta
	if _look != null and is_instance_valid(_look):
		_look.set("_elapsed_seconds", HOLD_CLOCK_S)
	return false


func _init() -> void:
	_run.call_deferred()


func _frames(seconds: float) -> int:
	return maxi(0, roundi(seconds * float(_fps)))


func _wait(seconds: float) -> void:
	for i in _frames(seconds):
		await process_frame


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	await process_frame
	# The engine consumes `--fixed-fps` itself; its effect is the delta.
	if _last_delta > 0.0:
		_fps = maxi(1, roundi(1.0 / _last_delta))
	print("frames per game second: %d (delta %.4f)" % [_fps, _last_delta])
	RenderingServer.render_loop_enabled = false
	_game = root.get_node(^"Game")
	var party: RefCounted = _game.get("party")
	party.call("clear")
	for species: String in ["terrapup", "mudsnout", "bramblebun", "brooktail"]:
		party.call("add", _game.call("make_creature", species, species.capitalize()))
	var chain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression/objectives.json"))
	for entry: Dictionary in chain.get("main", []):
		var id := str(entry.get("flag_id", ""))
		if id == "legendary_freed":
			break
		_game.get("progression").call("set_flag", id)
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	await _wait(SETTLE_S)
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = get_first_node_in_group("camera_rig") as Node3D
	for node: Node in _world.find_children("*", "", true, false):
		if node.has_method("elapsed_seconds") and "_elapsed_seconds" in node:
			_look = node
			break
	print("day clock held by: %s" % (str(_look.get_path()) if _look != null else "NOTHING"))

	# BEFORE.
	var n := 1
	for v: Array in VANTAGES:
		await _shot("h%02d-%s-a" % [n, v[0]], Vector2(v[1], v[2]), Vector3(v[3], 0.0, v[4]), float(v[5]))
		n += 1

	# THE FALL, side-on.
	var pick := _fall_vantage()
	if pick.is_empty():
		print("no clear side-on pylon vantage; falling back to the round-5 approach vantage")
	else:
		print("fall vantage: %s index %d azimuth %.1f from %s (%.0f m)" % [pick["path"], pick["index"],
			pick["azimuth"], str(pick["stand"]), pick["distance"]])
	var stand: Vector2 = pick.get("stand", Vector2(-24.0, 7478.0))
	var look: Vector3 = pick.get("look", Vector3(-8.0, 0.0, 7505.0))
	# Disclosed staging: wild creatures within WILD_CLEAR_M of the fall stand are
	# hidden for the fall frames (round 6 first pass: a wild Galecrest walked
	# into the lens and hid the pylon for the whole fall).
	_hide_wildlife(Vector3(stand.x, 0.0, stand.y))
	await _shot("f00-t00.00", stand, look, 2.0)
	_game.get("progression").call("set_flag", "legendary_freed")
	print("freed at the pylon vantage")
	var elapsed := 0.0
	for k in FALL_SAMPLES_S.size():
		var t := float(FALL_SAMPLES_S[k])
		await _wait(t - elapsed)
		elapsed = t
		_hide_wildlife(Vector3(stand.x, 0.0, stand.y))
		await _grab("f%02d-t%05.2f" % [k + 1, t])
	await _wait(maxf(16.0 - elapsed, 0.0))
	var healing := _world.get_node_or_null(^"MeadowHealing")
	if healing != null and healing.has_method("report"):
		print("heal report: %s" % str(healing.call("report")))

	# AFTER, same vantages.
	n = 1
	for v: Array in VANTAGES:
		await _shot("h%02d-%s-b" % [n, v[0]], Vector2(v[1], v[2]), Vector3(v[3], 0.0, v[4]), float(v[5]))
		n += 1
	print("done: %s" % ProjectSettings.globalize_path(_out))
	quit(0)


## The first preferred approach pylon with a clear line of sight from a stand
## at right angles to its authored fall azimuth, so the fall crosses the frame.
func _fall_vantage() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var falls: Dictionary = ((parsed as Dictionary).get("pylons", {}) as Dictionary).get("falls", {})
	var holder := _world.find_child("ApproachConduits", true, false)
	if holder == null:
		return {}
	var pylons: Array[Node3D] = []
	for child: Node in holder.get_children():
		if child is MeshInstance3D and str(child.name).begins_with("Pylon_"):
			pylons.append(child as Node3D)
	var space := _world.get_world_3d().direct_space_state
	for index: int in FALL_INDICES:
		if index >= pylons.size():
			continue
		var pylon := pylons[index]
		var key := "ApproachConduits/%s" % pylon.name
		if not falls.has(key) or falls[key] == null:
			continue
		var az := deg_to_rad(float(falls[key]))
		var dir := Vector2(sin(az), cos(az))
		var base := pylon.global_position
		var mid_fallen := Vector3(base.x + dir.x * 6.0, base.y + 1.5, base.z + dir.y * 6.0)
		for distance: float in FALL_DISTANCES:
			for side: float in [1.0, -1.0]:
				var perp := Vector2(-dir.y, dir.x) * side
				# Stand opposite the fall's midpoint so the whole arc is in frame.
				var spot := Vector2(base.x, base.z) + dir * 5.0 + perp * distance
				var y := float(_world.call("ground_height_at", spot.x, spot.y))
				if is_nan(y):
					continue
				var eye := Vector3(spot.x, y + 1.7, spot.y)
				var clear := true
				for target: Vector3 in [base + Vector3(0.0, 6.0, 0.0), mid_fallen]:
					var query := PhysicsRayQueryParameters3D.create(eye, target)
					query.exclude = [_player.get_rid()]
					var hit := space.intersect_ray(query)
					if not hit.is_empty() and (hit["position"] as Vector3).distance_to(target) > 2.5:
						clear = false
						break
				if clear:
					return {"path": str(pylon.get_path()), "index": index, "azimuth": rad_to_deg(az),
						"stand": spot, "distance": distance,
						"look": Vector3(base.x + dir.x * 5.0, base.y + 4.0, base.z + dir.y * 5.0)}
	return {}


func _hide_wildlife(near: Vector3) -> void:
	var healing := _world.get_node_or_null(^"MeadowHealing")
	for node: Node in _world.find_children("*", "CharacterBody3D", true, false):
		var body := node as Node3D
		if body == _player or not ("species_id" in body) or body.is_in_group(&"deployed_creature"):
			continue
		if healing != null and healing.is_ancestor_of(body):
			continue
		var flat := Vector2(body.global_position.x - near.x, body.global_position.z - near.z)
		if flat.length() <= WILD_CLEAR_M and body.visible:
			body.visible = false
			body.process_mode = Node.PROCESS_MODE_DISABLED
			print("staging: hid wild %s at %.0f m" % [str(body.get("species_id")), flat.length()])


func _shot(name: String, flat: Vector2, target: Vector3, pitch_deg: float) -> void:
	var y := float(_world.call("ground_height_at", flat.x, flat.y))
	var t := target
	if t.y == 0.0:
		t.y = float(_world.call("ground_height_at", t.x, t.z))
	var at := Vector3(flat.x, y, flat.y)
	_player.global_position = at + Vector3(0.0, 0.3, 0.0)
	_player.velocity = Vector3.ZERO
	var dir := t - at
	dir.y = 0.0
	if dir.length() > 0.01:
		_player.rotation.y = atan2(dir.x, dir.z)
		if _rig != null:
			_rig.set("yaw", wrapf(atan2(-dir.x, -dir.z), -PI, PI))
			_rig.set("pitch", deg_to_rad(pitch_deg))
	await _wait(SHOT_S)
	await _grab(name)


func _grab(name: String) -> void:
	var path := "%s/%s.png" % [_out, name]
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	print("shot -> %s" % path)
