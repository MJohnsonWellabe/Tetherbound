extends SceneTree

## F01-d. WORLD §3.2's acceptance walk, driven the way a player drives it:
## ordinary exploration camera (the scene's own CameraRig, steered only with
## the look stick) and real movement input (`move_forward`), along the authored
## road polylines in data/config/terrain_playground.json -- the same data
## tests/test_village_road_topology.gd checks.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tests/capture_village_walk.gd -- \
##     --time=day --route=through --capture-dir=/abs/path/to/out
##
## `--time`        day | night   (WorldLook.apply_time with the clock frozen)
## `--route`       through   Grandpa's door -> west street -> South Street ->
##                           TrailGate -> PAST_GATE_M onto the Lower Meadows
##                           spine toward the South Bridge
##                 stoneyard | berry | grove
##                           the through-road to that subarea's junction, then
##                           the lane (or, for the grove, the Pond lane) to the
##                           subarea from paths.village_topology.subareas
##                 visits    ACCEPTANCE F01 "reach every opening NPC, camp and
##                           gate": Grandpa indoors, then, nearest first, every
##                           village villager (village_npcs.json within
##                           VILLAGE_RADIUS_M of the well), the Practice Meadow
##                           camp (objectives.json's beacon) and every boundary
##                           gate. Each leg is the shortest path over the same
##                           road polylines plus a short spur to the target; a
##                           villager counts only when the player stands within
##                           NPC_REACH_M and that villager's own prompt is the
##                           arbiter's winner.
## `--capture-dir` absolute directory for the PNGs (created if missing)
## `--hide-hud`    optional: hide CanvasLayers in the saved frames
## `--plan-only`   print the route and data-derived events, load no world
##
## Starts as a fresh post-opening player: opening flags through `walk_out`
## (Grandpa's door is open because the opening says so, not because this
## script opens it) and one starter. The player is stood 2.5m INSIDE the
## farmhouse and walks out through the real door. For the four road routes
## `road_gate_open` is set before the world loads, standing in for the village
## key hunt -- those walks measure the road, not that puzzle; the leaf still
## has to be physically open for the walk to pass through it. The `visits`
## route sets NO gate flag: it walks to the old key, takes it with interact,
## and opens the first gate it meets with interact, as a player does.
##
## Saves a PNG every CAPTURE_EVERY_S of travel, plus one at every junction,
## signpost, gate and subarea arrival, and prints one receipt line per capture.
## FAILS (exit 1) when the player makes no progress for STUCK_S (a door or gate
## within 6m is named), leaves the painted road band by more than
## OFF_ROAD_LIMIT_M, or a dialogue/menu holds input for longer than STUCK_S.
##
## Inert by default: this is a standalone SceneTree script (not a test_*.gd),
## so nothing runs it unless it is launched explicitly. Under --headless it
## still drives and checks the whole walk but cannot save images; each receipt
## then says `image=headless`.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const BOUNDARY_PATH := "res://data/config/village_boundary.json"
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

const SETTLE_FRAMES := 300
const WIDTH := 1280
const HEIGHT := 720
const CAPTURE_EVERY_S := 1.5
const STUCK_S := 3.0
const STUCK_PROGRESS_M := 0.3
const OFF_ROAD_LIMIT_M := 2.5
const LOOKAHEAD_M := 2.5
const PAST_GATE_M := 10.0
const WALK_BUDGET_S := 300.0
## Steering: look-stick strength reaches full deflection at this error.
const STEER_FULL_DEG := 25.0
const STEER_DEADBAND_DEG := 2.0
## Forward is released while the camera is this far off the road heading, so
## a sharp junction turn is made on the spot rather than cut across the grass.
const TURN_IN_PLACE_DEG := 35.0
const EVENT_NEAR_M := 6.0
## `visits` route. Villagers this close to the well are the village's cast; the
## rest of village_npcs.json stands out on the bands.
const VILLAGE_RADIUS_M := 70.0
const WELL := Vector2(10.0, -10.0)
const CAMP_AT := Vector2(30.0, -40.0)
const CAMP_ARRIVAL_M := 4.0
const GATE_ARRIVAL_M := 3.0
## Where a spur to a person stops: inside every prompt radius in use (Greet
## prompts are 2.4m+, Grandpa's 3.8m) without walking into the body. The walk
## counts arrival up to 0.5m short of a spur's end, so the player ends ~1.2-1.7m
## away. The villager's own prompt winning the arbiter is the reachability
## proof; NPC_REACH_M is only a sanity bound on where the walk stopped.
const NPC_STOP_M := 1.2
const NPC_REACH_M := 3.0
const GRAPH_STEP_M := 1.0
const GRAPH_LINK_M := 1.1
const GRAPH_CLIP_M := 220.0
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
## Villagers who stand indoors are reached through their building's real door,
## never through a wall. Mira's shop is village.json's cottage_a at (18,4), yaw
## -90: shop_interior.gd's doorway lane (local x = DOOR_X 1.0, front wall +z)
## is world z = 5, entered from the doorstep at (13.87,5); she stands behind the
## counter (local z -0.6..-0.1), so the customer spot is local (0,+0.5) = world
## (17.5,4.0), 1.9m from her. Outside doorstep -> just inside the door -> counter.
## The lane is walked at z 4.8, not its 5.0 centre: the Cloudreach relic slot's
## plinth (realm_heart_shrine.gd, 1.41m radius at ~(16.1,6.7)) reaches into the
## doorway to z ~5.3, leaving the lane's southern ~0.9m clear for the body.
const INDOOR_APPROACH := {
	"Mira": [Vector2(13.87, 4.8), Vector2(16.5, 4.8), Vector2(17.5, 4.0)],
}
## A closed door on the way is opened the way a player opens it: when the walk
## stalls and the arbiter's actionable winner is an "Open ..." prompt (or a
## locked boundary leaf's "Try the gate", with the key in the satchel), one
## interact press. Bounded so a door that never opens still fails the walk.
const DOOR_PRESSES_MAX := 3

## Grandpa's farmhouse: HOUSE_AT (-22,-16) in playground_world.gd, door on the
## east wall at x = -17 (grandpa_house.gd EXT_HALF_W 5.0). The start is 2.5m
## inside that doorway; the west street begins 0.5m outside it.
const INSIDE_START := Vector2(-19.5, -16.0)
const DOORWAY := Vector2(-17.0, -16.0)

const OPENING_FLAGS := [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:name", "opening:beat:return_starter",
	"opening:beat:walk_out",
]

var _time := "day"
var _route_name := "through"
var _capture_dir := ""
var _hide_hud := false
var _plan_only := false
var _headless := false

var _world: Node3D = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _game: Node = null
var _manager: Node = null

var _terrain: Dictionary = {}
var _roads: Dictionary = {}
var _path := PackedVector2Array()
var _arcs := PackedFloat32Array()
var _road_from_arc := 0.0
var _road_until_arc := INF
var _subarea: Dictionary = {}
var _events: Array = []
var _painted_half := 1.8

var _captures := 0
var _max_off_road := 0.0
var _failed := ""
var _visited: Array[String] = []


func _init() -> void:
	# Deferred: autoloads (Game) are not under root yet while _init runs.
	call_deferred("_run")


func _parse_args() -> bool:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--time="):
			_time = a.substr("--time=".length())
		elif a.begins_with("--route="):
			_route_name = a.substr("--route=".length())
		elif a.begins_with("--capture-dir="):
			_capture_dir = a.substr("--capture-dir=".length())
		elif a == "--hide-hud":
			_hide_hud = true
		elif a == "--plan-only":
			_plan_only = true
	if not _time in ["day", "night"]:
		print("[village-walk] FAIL bad --time=%s (day|night)" % _time)
		return false
	if not _route_name in ["through", "stoneyard", "berry", "grove", "visits"]:
		print("[village-walk] FAIL bad --route=%s (through|stoneyard|berry|grove|visits)" % _route_name)
		return false
	if _capture_dir.is_empty() or not _capture_dir.is_absolute_path():
		print("[village-walk] FAIL --capture-dir must be an absolute path")
		return false
	return true


func _run() -> void:
	if not _parse_args():
		quit(2)
		return
	_headless = DisplayServer.get_name() == "headless"
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	_terrain = _json(TERRAIN_PATH)
	var paths := _terrain.get("paths", {}) as Dictionary
	_painted_half = float(paths.get("width", 1.4)) * 0.5 + float(paths.get("shoulder", 1.1))
	_roads = _load_roads()
	if not _build_route():
		quit(1)
		return
	if _plan_only:
		# Data only, no world: print the path and the data-derived events.
		print("[village-walk] PLAN route=%s path=%s" % [_route_name, str(_path)])
		for e: Dictionary in _events:
			print("[village-walk] PLAN event arc=%.1f %s" % [float(e.arc), str(e.label)])
		quit(0)
		return

	await process_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("[village-walk] FAIL no Game autoload")
		quit(1)
		return
	var progression: RefCounted = _game.get("progression")
	for flag: String in OPENING_FLAGS:
		progression.call("set_flag", flag)
	if _route_name != "visits":
		progression.call("set_flag", "road_gate_open")
	var party: RefCounted = _game.get("party")
	if party != null and (party.call("members") as Array).is_empty():
		var starter: RefCounted = _game.call("make_creature", "terrapup")
		if starter != null:
			party.call("add", starter)

	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	if _player == null or _rig == null:
		print("[village-walk] FAIL no Player/CameraRig in %s" % SCENE)
		quit(1)
		return

	var look := _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("set_clock_frozen", true)
		look.call("apply_time", _time)
	var weather := _world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
	if _hide_hud:
		for child in _world.get_children():
			if child is CanvasLayer:
				(child as CanvasLayer).visible = false
	_add_world_events()
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.arc) < float(b.arc))

	# Stand inside the farmhouse, facing the door. Everything after this is input.
	var ground := _ground_at(INSIDE_START)
	_player.global_position = Vector3(INSIDE_START.x, ground + 1.0, INSIDE_START.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", _yaw_toward(INSIDE_START, DOORWAY))
	for i in 30:
		await physics_frame

	print("[village-walk] START route=%s time=%s capture_dir=%s headless=%s path_m=%.1f road_arcs=[%.1f,%.1f] events=%d" % [
		_route_name, _time, _capture_dir, str(_headless), _arcs[_arcs.size() - 1],
		_road_from_arc, minf(_road_until_arc, _arcs[_arcs.size() - 1]), _events.size()])
	await _capture("start-inside-house")
	if _route_name == "visits":
		await _visit_all()
	else:
		await _walk()
	_release_all()
	if _failed.is_empty():
		print("[village-walk] PASS route=%s time=%s captures=%d max_off_road_m=%.2f%s" % [
			_route_name, _time, _captures, _max_off_road,
			(" visited=%d" % _visited.size()) if _route_name == "visits" else ""])
		quit(0)
	else:
		await _capture("failure")
		print("[village-walk] FAIL route=%s time=%s: %s (captures=%d)" % [_route_name, _time, _failed, _captures])
		quit(1)


## --- route data --------------------------------------------------------------

func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _v(raw: Variant) -> Vector2:
	var a := raw as Array
	return Vector2(float(a[0]), float(a[1]))


func _line(raw: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Variant in (raw as Array):
		out.append(_v(p))
	return out


func _load_roads() -> Dictionary:
	var out := {}
	var paths := _terrain.get("paths", {}) as Dictionary
	for raw: Variant in (paths.get("routes", []) as Array) + (paths.get("approaches", []) as Array):
		var entry := raw as Dictionary
		out[str(entry.get("id", entry.get("label", "")))] = _line(entry.get("points", []))
	for raw: Variant in ((_terrain.get("trail", {}) as Dictionary).get("bands", []) as Array):
		if str((raw as Dictionary).get("id", "")) == "band1_lower_meadows":
			out["band1_lower_meadows"] = _line((raw as Dictionary).get("points", []))
	return out


func _dist_to_line(p: Vector2, line: PackedVector2Array) -> float:
	var best := INF
	for i in line.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])))
	return best


## The polyline from its start up to (and ending exactly on) `point`.
func _prefix(line: PackedVector2Array, point: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array([line[0]])
	for i in line.size() - 1:
		var c := Geometry2D.get_closest_point_to_segment(point, line[i], line[i + 1])
		if c.distance_to(point) <= 0.75:
			out.append(point)
			return out
		out.append(line[i + 1])
	return out


## The polyline from `point` (on it) to its end.
func _suffix(line: PackedVector2Array, point: Vector2) -> PackedVector2Array:
	for i in line.size() - 1:
		var c := Geometry2D.get_closest_point_to_segment(point, line[i], line[i + 1])
		if c.distance_to(point) <= 0.75:
			var out := PackedVector2Array([point])
			for j in range(i + 1, line.size()):
				if line[j].distance_to(point) > 0.05:
					out.append(line[j])
			return out
	return PackedVector2Array()


func _append(out: PackedVector2Array, more: PackedVector2Array) -> void:
	for p: Vector2 in more:
		if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.05:
			out.append(p)


func _topology() -> Dictionary:
	return (_terrain.get("paths", {}) as Dictionary).get("village_topology", {}) as Dictionary


func _subarea_by(key: String, value: String) -> Dictionary:
	for raw: Variant in (_topology().get("subareas", []) as Array):
		if str((raw as Dictionary).get(key, "")) == value:
			return raw as Dictionary
	return {}


func _build_route() -> bool:
	var west: PackedVector2Array = _roads.get("Grandpa's House", PackedVector2Array())
	var south: PackedVector2Array = _roads.get("village_south_street", PackedVector2Array())
	var spine: PackedVector2Array = _roads.get("band1_lower_meadows", PackedVector2Array())
	if west.size() < 2 or south.size() < 2 or spine.size() < 2:
		print("[village-walk] FAIL terrain_playground.json lacks the through-road pieces")
		return false
	west.reverse()  # Grandpa's door -> the civic bend
	var road := PackedVector2Array()
	match _route_name:
		"visits":
			# Legs are planned live, one target at a time (_visit_all); this
			# placeholder only feeds the START line.
			_set_leg(PackedVector2Array([INSIDE_START, DOORWAY]), -1, -1)
			return true
		"through":
			_append(road, west)
			_append(road, _suffix(south, west[west.size() - 1]))
			_append(road, _suffix(spine, south[south.size() - 1]))
		"stoneyard", "berry":
			var kind := "stone_work" if _route_name == "stoneyard" else "berry_field"
			_subarea = _subarea_by("kind", kind)
			var lane_id := ""
			for raw: Variant in (_topology().get("side_lanes", []) as Array):
				if str((raw as Dictionary).get("subarea", "")) == str(_subarea.get("id", "?")):
					lane_id = str((raw as Dictionary).get("road", ""))
			var lane: PackedVector2Array = _roads.get(lane_id, PackedVector2Array())
			if _subarea.is_empty() or lane.size() < 2:
				print("[village-walk] FAIL no %s subarea with a side lane in village_topology" % kind)
				return false
			_append(road, _prefix(west, lane[0]))
			_append(road, lane)
		"grove":
			_subarea = _subarea_by("kind", "grove")
			var served: PackedVector2Array = _roads.get(str(_subarea.get("road", "")), PackedVector2Array())
			if _subarea.is_empty() or served.size() < 2:
				print("[village-walk] FAIL no grove subarea with a serving road in village_topology")
				return false
			# Where the serving road leaves the through-road: its last vertex
			# still on the west street before it turns off it.
			var branch := Vector2.INF
			for i in served.size() - 1:
				if _dist_to_line(served[i], west) <= 0.75 and _dist_to_line(served[i + 1], west) > 0.75:
					branch = served[i]
			var centre := _v(_subarea.get("centre", []))
			var from_branch := _suffix(served, branch)
			var nearest := Vector2.INF
			for i in from_branch.size() - 1:
				var c := Geometry2D.get_closest_point_to_segment(centre, from_branch[i], from_branch[i + 1])
				if nearest == Vector2.INF or c.distance_to(centre) < nearest.distance_to(centre):
					nearest = c
			_append(road, _prefix(west, branch))
			_append(road, _prefix(from_branch, nearest))
	_path = PackedVector2Array([INSIDE_START, DOORWAY])
	var road_start := _path.size()
	_append(_path, road)
	if not _subarea.is_empty():
		_path.append(_v(_subarea.get("centre", [])))
	_arcs = PackedFloat32Array([0.0])
	for i in range(1, _path.size()):
		_arcs.append(_arcs[i - 1] + _path[i - 1].distance_to(_path[i]))
	_road_from_arc = _arcs[road_start]
	if not _subarea.is_empty():
		_road_until_arc = _arcs[_path.size() - 2]
	# Road-graph junctions and the gate, from the data.
	for j: Vector2 in _junctions():
		_add_event(j, "junction (%.1f,%.1f)" % [j.x, j.y], 1.0)
	var boundary := _json(BOUNDARY_PATH)
	for raw: Variant in ((boundary.get("gates", {}) as Dictionary).get("entries", []) as Array):
		var gate := raw as Dictionary
		_add_event(_v(gate.get("at", [])), "gate %s" % str(gate.get("id", "")), 4.0)
	if _route_name == "through":
		var gate_arc := INF
		for e: Dictionary in _events:
			if str(e.label) == "gate TrailGate":
				gate_arc = float(e.arc)
		if gate_arc == INF:
			print("[village-walk] FAIL the through-road never reaches TrailGate")
			return false
		_truncate(gate_arc + PAST_GATE_M)
	if not _subarea.is_empty():
		_events.append({"arc": _arcs[_arcs.size() - 1] - _arrival_radius(),
			"label": "arrive %s" % str(_subarea.get("name", ""))})
	return true


func _arrival_radius() -> float:
	return minf(4.0, float(_subarea.get("radius", 8.0)) * 0.5)


func _truncate(arc: float) -> void:
	var out := PackedVector2Array([_path[0]])
	for i in range(1, _path.size()):
		if _arcs[i] < arc:
			out.append(_path[i])
			continue
		var t := (arc - _arcs[i - 1]) / maxf(_arcs[i] - _arcs[i - 1], 0.001)
		out.append(_path[i - 1].lerp(_path[i], t))
		break
	_path = out
	_arcs = PackedFloat32Array([0.0])
	for i in range(1, _path.size()):
		_arcs.append(_arcs[i - 1] + _path[i - 1].distance_to(_path[i]))


## A junction is a vertex where one road leaves another in the middle of it
## (not at either end, where one road simply continues as the next).
func _junctions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for rid: String in _roads:
		var r: PackedVector2Array = _roads[rid]
		for qid: String in _roads:
			if qid == rid:
				continue
			var q: PackedVector2Array = _roads[qid]
			for i in r.size() - 1:
				if _dist_to_line(r[i], q) > 0.75 or _dist_to_line(r[i + 1], q) <= 0.75:
					continue
				if r[i].distance_to(q[0]) <= 0.75 or r[i].distance_to(q[q.size() - 1]) <= 0.75:
					continue
				var fresh := true
				for o: Vector2 in out:
					if o.distance_to(r[i]) <= 1.0:
						fresh = false
				if fresh:
					out.append(r[i])
	return out


## Arc length of the point on the path nearest `p`, and the distance to it.
func _project(p: Vector2, from_arc: float = 0.0, to_arc: float = INF) -> Vector2:
	var best_d := INF
	var best_arc := 0.0
	for i in _path.size() - 1:
		if _arcs[i + 1] < from_arc or _arcs[i] > to_arc:
			continue
		var c := Geometry2D.get_closest_point_to_segment(p, _path[i], _path[i + 1])
		var d := c.distance_to(p)
		if d < best_d:
			best_d = d
			best_arc = _arcs[i] + _path[i].distance_to(c)
	return Vector2(best_arc, best_d)


func _point_at(arc: float) -> Vector2:
	for i in range(1, _path.size()):
		if _arcs[i] >= arc:
			var t := (arc - _arcs[i - 1]) / maxf(_arcs[i] - _arcs[i - 1], 0.001)
			return _path[i - 1].lerp(_path[i], t)
	return _path[_path.size() - 1]


func _add_event(at: Vector2, label: String, near: float) -> void:
	var hit := _project(at)
	if hit.y <= near:
		_events.append({"arc": hit.x, "label": label})


## Signposts are read off the built world (the square's fingerpost and every
## one-arm trailhead post), not transcribed.
func _add_world_events() -> void:
	for node: Node in _world.get_children():
		if not node is Node3D:
			continue
		var node_name := String(node.name)
		if node_name == "Signpost" or node_name.begins_with("TrailheadSignpost_"):
			var p := (node as Node3D).global_position
			_add_event(Vector2(p.x, p.z), "signpost %s" % node_name, EVENT_NEAR_M)


## --- the walk ----------------------------------------------------------------

func _ground_at(p: Vector2) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		var h: float = float(_world.call("ground_height_at", p.x, p.y))
		if not is_nan(h):
			return h
	return 1.0


func _yaw_toward(from: Vector2, to: Vector2) -> float:
	var d := to - from
	return atan2(-d.x, -d.y)


func _xz() -> Vector2:
	return Vector2(_player.global_position.x, _player.global_position.z)


func _release_all() -> void:
	for action: String in ["move_forward", "look_left", "look_right"]:
		Input.action_release(action)


func _walk() -> void:
	var total := _arcs[_arcs.size() - 1]
	var progress := 0.0
	var best_progress := 0.0
	var best_at_s := 0.0
	var clock := 0.0
	var travel_since_capture := 0.0
	var owned_s := 0.0
	var next_event := 0
	var door_presses := 0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	while clock < WALK_BUDGET_S:
		await physics_frame
		clock += dt
		var here := _xz()
		var hit := _project(here, maxf(0.0, progress - 3.0), progress + 6.0)
		progress = maxf(progress, hit.x)

		# Fights are a player's to walk away from: flee with the real verb
		# and do not count the fight as being stuck.
		if _manager != null and bool(_manager.call("is_fighting")):
			_release_all()
			print("[village-walk] NOTE a wild fight started at (%.1f,%.1f); fleeing with combat_run" % [here.x, here.y])
			await _press("combat_run")
			best_at_s = clock
			continue
		if _input_owned():
			owned_s += dt
			if owned_s > STUCK_S:
				_failed = "input held by %s for %.1fs at (%.1f,%.1f)" % [
					str(_owner_name()), owned_s, here.x, here.y]
				return
			continue
		owned_s = 0.0

		# Off the painted band, only while on a road leg.
		if progress >= _road_from_arc and progress <= _road_until_arc:
			var off := maxf(0.0, hit.y - _painted_half)
			_max_off_road = maxf(_max_off_road, off)
			if off > OFF_ROAD_LIMIT_M:
				_failed = "left the painted road band by %.2fm at (%.1f,%.1f), arc %.1f" % [off, here.x, here.y, progress]
				return

		if progress > best_progress + STUCK_PROGRESS_M:
			best_progress = progress
			best_at_s = clock
		elif clock - best_at_s > STUCK_S * 0.5 and door_presses < DOOR_PRESSES_MAX and _door_prompt_wins():
			_release_all()
			door_presses += 1
			print("[village-walk] NOTE pressed interact on \"%s\" at (%.1f,%.1f)" % [
				_winner_label(), here.x, here.y])
			await _press("interact")
			best_at_s = clock
			continue
		elif clock - best_at_s > STUCK_S:
			_failed = "no progress for %.1fs at (%.1f,%.1f), arc %.1f/%.1f%s" % [
				STUCK_S, here.x, here.y, progress, total, _blocker_near(here)]
			return

		while next_event < _events.size() and progress >= float(_events[next_event].arc):
			await _capture(str(_events[next_event].label))
			next_event += 1
		var arrived := progress >= total - 0.5
		if not _subarea.is_empty():
			arrived = arrived or here.distance_to(_v(_subarea.get("centre", []))) <= _arrival_radius()
		if arrived:
			_release_all()
			while next_event < _events.size():
				await _capture(str(_events[next_event].label))
				next_event += 1
			await _capture("end")
			return

		# Steer the camera with the look stick toward a point just ahead on
		# the road; walk only while roughly facing it.
		var target := _point_at(progress + LOOKAHEAD_M)
		var wanted := _yaw_toward(here, target)
		var diff := rad_to_deg(angle_difference(float(_rig.get("yaw")), wanted))
		Input.action_release("look_left")
		Input.action_release("look_right")
		if absf(diff) > STEER_DEADBAND_DEG:
			var strength := clampf(absf(diff) / STEER_FULL_DEG, 0.25, 1.0)
			Input.action_press("look_left" if diff > 0.0 else "look_right", strength)
		if absf(diff) < TURN_IN_PLACE_DEG:
			Input.action_press("move_forward", 1.0)
			travel_since_capture += dt
		else:
			Input.action_release("move_forward")
		if travel_since_capture >= CAPTURE_EVERY_S:
			travel_since_capture = 0.0
			await _capture("travel")
	_failed = "walk budget %.0fs spent at arc %.1f/%.1f" % [WALK_BUDGET_S, progress, total]


func _press(action: String) -> void:
	Input.action_press(action)
	for i in 2:
		await physics_frame
	Input.action_release(action)
	for i in 30:
		await physics_frame


func _input_owned() -> bool:
	return _owner_name() != ""


func _owner_name() -> String:
	var node: Node = INPUT_OWNER.current(self)
	return String((node as Node).name) if node is Node else ""


func _blocker_near(here: Vector2) -> String:
	var names: Array[String] = []
	var boundary := _json(BOUNDARY_PATH)
	for raw: Variant in ((boundary.get("gates", {}) as Dictionary).get("entries", []) as Array):
		var gate := raw as Dictionary
		if _v(gate.get("at", [])).distance_to(here) <= 6.0:
			names.append("gate %s" % str(gate.get("id", "")))
	if DOORWAY.distance_to(here) <= 6.0:
		names.append("Grandpa's door")
	return "" if names.is_empty() else " -- blocked near %s" % ", ".join(names)


func _capture(label: String) -> void:
	_captures += 1
	var here := _player.global_position
	var heading := fposmod(rad_to_deg(-float(_rig.get("yaw"))), 360.0)
	var slug := label.to_lower().replace(" ", "-").replace("(", "").replace(")", "").replace(",", "_").replace("'", "")
	var file := "%s_%s_%03d_%s.png" % [_route_name, _time, _captures, slug]
	var saved := "headless"
	if not _headless:
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		if image == null or image.is_empty():
			saved = "no-image"
		else:
			if image.get_width() != WIDTH or image.get_height() != HEIGHT:
				image.resize(WIDTH, HEIGHT, Image.INTERPOLATE_LANCZOS)
			var err := image.save_png(_capture_dir.path_join(file))
			saved = file if err == OK else "save-error-%d" % err
	print("[village-walk] CAPTURE %03d label=\"%s\" pos=(%.2f,%.2f,%.2f) heading_deg=%.1f image=%s" % [
		_captures, label, here.x, here.y, here.z, heading, saved])


## --- visits (ACCEPTANCE F01: every opening NPC, camp and gate) ----------------

func _visit_all() -> void:
	var targets := _visit_targets()
	if targets.is_empty():
		_failed = "no visit targets found"
		return
	print("[village-walk] VISITS %s" % ", ".join(targets.map(func(t: Dictionary) -> String: return str(t.label))))
	var graph := _road_graph()
	# Grandpa first, from the start pose inside the house: no road indoors.
	for t: Dictionary in targets:
		if str(t.kind) == "grandpa":
			await _visit(t, PackedVector2Array())
			targets.erase(t)
			break
		if not _failed.is_empty():
			return
	if not _failed.is_empty():
		return
	# Out through the real door before the first road leg.
	_set_leg(PackedVector2Array([_xz(), DOORWAY]), -1, -1)
	await _walk()
	if not _failed.is_empty():
		return
	while not targets.is_empty():
		var here := _xz()
		# Nearest first, but nothing past the boundary before the key is in the
		# satchel: until then only villagers and the key itself are eligible.
		var have_key := _has_key()
		var next: Dictionary = {}
		for t: Dictionary in targets:
			if not have_key and not str(t.kind) in ["villager", "key"]:
				continue
			if next.is_empty() or here.distance_to(t.at) < here.distance_to(next.at):
				next = t
		if next.is_empty():
			_failed = "no reachable target left before the key: %s" % str(targets.map(func(t: Dictionary) -> String: return str(t.label)))
			return
		targets.erase(next)
		await _visit(next, _graph_path(graph, here, next.at))
		if not _failed.is_empty():
			return


func _visit_targets() -> Array:
	var out: Array = []
	var grandpa := _world.find_child("Grandpa", true, false) as Node3D
	if grandpa != null:
		out.append({"kind": "grandpa", "label": "Grandpa", "node": grandpa,
			"at": Vector2(grandpa.global_position.x, grandpa.global_position.z)})
	for raw: Variant in (_json(VILLAGERS_PATH).get("villagers", []) as Array):
		var spec := raw as Dictionary
		var at := _v(spec.get("position", [0, 0]))
		if at.distance_to(WELL) > VILLAGE_RADIUS_M:
			continue
		var npc_name := str(spec.get("name", ""))
		var node := _world.find_child(npc_name, true, false) as Node3D
		if node == null:
			print("[village-walk] FAIL villager %s is authored but not in the world" % npc_name)
			_failed = "villager %s missing" % npc_name
			return []
		out.append({"kind": "villager", "label": npc_name, "node": node,
			"at": Vector2(node.global_position.x, node.global_position.z)})
	var key := _world.get_node_or_null(^"GateKey") as Node3D
	if key == null:
		_failed = "the old gate key is not lying in the world"
		return []
	out.append({"kind": "key", "label": "the old key", "node": key,
		"at": Vector2(key.global_position.x, key.global_position.z)})
	out.append({"kind": "camp", "label": "Practice Meadow camp", "at": CAMP_AT})
	for raw: Variant in ((_json(BOUNDARY_PATH).get("gates", {}) as Dictionary).get("entries", []) as Array):
		var gate := raw as Dictionary
		out.append({"kind": "gate", "label": "gate %s" % str(gate.get("id", "")), "at": _v(gate.get("at", []))})
	return out


## One leg: (optional) road path, then a spur to the target's stopping point.
func _visit(t: Dictionary, road: PackedVector2Array) -> void:
	var at: Vector2 = t.at
	var kind := str(t.kind)
	var here := _xz()
	var leg := PackedVector2Array([here])
	_append(leg, road)
	var from_road := 1 if road.size() > 0 else -1
	var until_road := leg.size() - 1 if road.size() > 0 else -1
	var stop := at
	if INDOOR_APPROACH.has(str(t.label)):
		var through: Array = INDOOR_APPROACH[str(t.label)]
		for i in through.size() - 1:
			leg.append(through[i] as Vector2)
		stop = through[through.size() - 1] as Vector2
	elif kind in ["grandpa", "villager", "key"]:
		var back := leg[leg.size() - 1] - at
		stop = at + (back.normalized() * NPC_STOP_M if back.length() > NPC_STOP_M else back)
	if leg[leg.size() - 1].distance_to(stop) > 0.05:
		leg.append(stop)
	_set_leg(leg, from_road, until_road)
	await _walk()
	if not _failed.is_empty():
		_failed = "visiting %s: %s" % [t.label, _failed]
		return
	var d := _xz().distance_to(at)
	var reach := {"grandpa": NPC_REACH_M, "villager": NPC_REACH_M, "key": NPC_REACH_M,
		"camp": CAMP_ARRIVAL_M, "gate": GATE_ARRIVAL_M}[kind] as float
	if d > reach:
		_failed = "ended %.2fm from %s (needs %.1fm)" % [d, t.label, reach]
		return
	var prompt := "-"
	if kind == "key":
		prompt = await _prompt_winner(t.node as Node)
		if prompt == "":
			_failed = "stood %.2fm from the old key but its prompt never won" % d
			return
		await _press("interact")
		if not _has_key():
			_failed = "pressed interact on \"%s\" but the key is not in the satchel" % prompt
			return
	elif kind in ["grandpa", "villager"]:
		prompt = await _prompt_winner(t.node as Node)
		if kind == "villager" and prompt == "":
			_failed = "stood %.2fm from %s but its prompt never won the arbiter" % [d, t.label]
			return
	_visited.append(str(t.label))
	await _capture("reached %s" % t.label)
	print("[village-walk] VISIT %s kind=%s dist_m=%.2f prompt=\"%s\"" % [t.label, kind, d, prompt])


## The arbiter's winning label when the winner belongs to `owner`, else "".
func _prompt_winner(owner: Node) -> String:
	var arbiter := get_first_node_in_group("interaction_arbiter")
	if arbiter == null or owner == null:
		return ""
	for _i in 30:
		await physics_frame
		var provider := arbiter.call("winning_provider") as Node
		if provider != null and (provider == owner or owner.is_ancestor_of(provider)):
			return str((arbiter.call("winner") as Dictionary).get("label", "?"))
	return ""


func _set_leg(leg: PackedVector2Array, from_road: int, until_road: int) -> void:
	_path = leg
	_arcs = PackedFloat32Array([0.0])
	for i in range(1, _path.size()):
		_arcs.append(_arcs[i - 1] + _path[i - 1].distance_to(_path[i]))
	_road_from_arc = _arcs[from_road] if from_road >= 0 else INF
	_road_until_arc = _arcs[until_road] if until_road >= 0 else -INF
	_events = []
	_subarea = {}


## Every village road (routes, approaches, the band-1 spine) sampled every
## GRAPH_STEP_M within GRAPH_CLIP_M of the well; consecutive samples link, and
## samples of different roads within GRAPH_LINK_M link (junctions/crossings).
func _road_graph() -> Dictionary:
	var pts := PackedVector2Array()
	var edges: Array = []  # per node: Array of [other, cost]
	var owner := PackedInt32Array()
	var road_index := 0
	for key: Variant in _roads.keys():
		var line: PackedVector2Array = _roads[key]
		var prev := -1
		for i in line.size() - 1:
			var a := line[i]
			var b := line[i + 1]
			var n := maxi(1, int(ceil(a.distance_to(b) / GRAPH_STEP_M)))
			for k in n + (1 if i == line.size() - 2 else 0):
				var p := a.lerp(b, float(k) / float(n))
				if p.distance_to(WELL) > GRAPH_CLIP_M:
					prev = -1
					continue
				pts.append(p)
				owner.append(road_index)
				edges.append([])
				var idx := pts.size() - 1
				if prev >= 0:
					var c := pts[prev].distance_to(p)
					(edges[prev] as Array).append([idx, c])
					(edges[idx] as Array).append([prev, c])
				prev = idx
		road_index += 1
	var cell := {}
	for i in pts.size():
		var key := Vector2i(floori(pts[i].x / GRAPH_LINK_M), floori(pts[i].y / GRAPH_LINK_M))
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for j: int in (cell.get(key + Vector2i(dx, dy), []) as Array):
					if owner[j] != owner[i] and pts[i].distance_to(pts[j]) <= GRAPH_LINK_M:
						var c := pts[i].distance_to(pts[j])
						(edges[i] as Array).append([j, c])
						(edges[j] as Array).append([i, c])
		if not cell.has(key):
			cell[key] = []
		(cell[key] as Array).append(i)
	return {"pts": pts, "edges": edges}


func _nearest_node(graph: Dictionary, p: Vector2) -> int:
	var pts: PackedVector2Array = graph.pts
	var best := -1
	for i in pts.size():
		if best < 0 or pts[i].distance_squared_to(p) < pts[best].distance_squared_to(p):
			best = i
	return best


## Dijkstra (linear scan; a few thousand nodes) from the road point nearest
## `from` to the road point nearest `to`.
func _graph_path(graph: Dictionary, from: Vector2, to: Vector2) -> PackedVector2Array:
	var pts: PackedVector2Array = graph.pts
	var edges: Array = graph.edges
	var s := _nearest_node(graph, from)
	var g := _nearest_node(graph, to)
	var dist := PackedFloat32Array()
	dist.resize(pts.size())
	dist.fill(INF)
	var prev := PackedInt32Array()
	prev.resize(pts.size())
	prev.fill(-1)
	var done := PackedByteArray()
	done.resize(pts.size())
	var frontier := {s: true}
	dist[s] = 0.0
	while not frontier.is_empty():
		var u := -1
		for k: int in frontier.keys():
			if u < 0 or dist[k] < dist[u]:
				u = k
		frontier.erase(u)
		if u == g:
			break
		done[u] = 1
		for e: Array in (edges[u] as Array):
			var v: int = e[0]
			if done[v] == 1:
				continue
			var nd := dist[u] + float(e[1])
			if nd < dist[v]:
				dist[v] = nd
				prev[v] = u
				frontier[v] = true
	var out := PackedVector2Array()
	if dist[g] == INF:
		return out
	var at := g
	while at >= 0:
		out.append(pts[at])
		at = prev[at]
	out.reverse()
	return out


func _winner_label() -> String:
	var arbiter := get_first_node_in_group("interaction_arbiter")
	if arbiter == null:
		return ""
	return str((arbiter.call("winner") as Dictionary).get("label", ""))


func _door_prompt_wins() -> bool:
	var arbiter := get_first_node_in_group("interaction_arbiter")
	if arbiter == null:
		return false
	var winner := arbiter.call("winner") as Dictionary
	var label := str(winner.get("label", ""))
	return bool(winner.get("actionable", false)) and (label.begins_with("Open ") or label == "Try the gate")


func _has_key() -> bool:
	var inventory: RefCounted = _game.get("inventory")
	return inventory != null and int(inventory.call("count", "castle_gate_key")) > 0
