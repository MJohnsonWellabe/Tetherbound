extends SceneTree

## F03 item 3. Unstaged ordinary-discovery witness for the six Meadows
## activities: load a REAL played Gate F exit save the way the title screen's
## Load does (`Game.load_game(slot)`, then the realm scene), then drive ordinary
## input only -- `move_forward`, `sprint`, the camera rig's yaw (the look
## stick), `creature_recall`, and, if the world starts a fight or a dialogue,
## `combat_run`/the input combat pilot/`interact` -- along the authored road
## graph toward one activity until its lure is first on screen and its prompt is
## offered. It never sets a flag, a position, a party member or the clock.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tests/capture_activity_lures.gd -- \
##     --activity=bram --save=/abs/S04-exit.json --capture-dir=/abs/out
##
## `--activity`    bram | herd | vault | doss | juno | hall
## `--save`        absolute path of a real `S0x-exit.json` (copied, unmodified,
##                 into slot 1 of a scratch save directory, then loaded)
## `--capture-dir` absolute directory for the PNG frames
##
## Receipts: one `[lure-walk] RECEIPT {json}` line at the end with the save and
## its sha256, the loaded pose vs. the pose after load (teleport check), metres
## walked, game seconds, fights, every flag the GAME changed on the way (the
## script writes none) and the frames. Budget: WALK_BUDGET_S of game time; a
## walk that cannot reach the activity inside it is reported as a gap, exit 3.
##
## Inert by default: a standalone SceneTree script, not a test_*.gd.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const COMBAT_PILOT := preload("res://tools/combat_pilot.gd")
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const DEFAULT_SCENE := "res://scenes/world/meadows_playground.tscn"
const SLOT_DIR := "user://f03_lure_walk_slots/"
const SLOT := 1

const SETTLE_FRAMES := 300
## `--budget-s=` overrides (Juno's patrol is 1.6 km and five road fights
## from the real S07 save).
var WALK_BUDGET_S := 360.0
const DENSIFY_M := 8.0
const LOOKAHEAD_M := 4.0
## Metres of cross-country leg are charged this much against road metres when
## choosing where to leave the road for the activity.
## `--off-road-cost=` overrides (a player keeps to the road until the
## activity is close; at 3.0 the herd walk left the road 295 m early).
var OFF_ROAD_COST := 3.0
const LURE_RANGE_M := 160.0
const STUCK_S := 4.0
## Unstick attempts allowed at one blocked spot, and the route progress (m)
## that counts as having left it (more than the 2 x DENSIFY_M an unstick skips).
const UNSTICK_ATTEMPTS := 6
const UNSTICK_RESET_M := 25.0
const APPROACH_FRAME_M := 30.0

var _activity := ""
var _save_path := ""
## What the player looks at (the herd's nearest member for the herd visit).
var _lure_body: Node3D = null
## Minimum on-screen height, in 1280x720 FRAME pixels, for a lure to count as
## readable, not just present.
const READABLE_PX := 24.0
var _capture_dir := ""
## True while the walker has put the companion away to get unstuck.
var _companion_stowed := false

var _world: Node3D = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _game: Node = null
var _manager: Node = null
var _director: Node = null
var _arbiter: Node = null

var _lure: Node3D = null
var _prompt: Object = null
var _path := PackedVector3Array()  # x, z, and y=1 for road points / 0 off-road
var _receipt := {}
var _frames: Array = []
var _fights: Array = []
var _notes: Array = []
var _walked := 0.0
var _clock := 0.0
var _start_frame := 0
var _last := Vector2.ZERO


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--activity="):
			_activity = a.trim_prefix("--activity=")
		elif a.begins_with("--save="):
			_save_path = a.trim_prefix("--save=")
		elif a.begins_with("--budget-s="):
			WALK_BUDGET_S = float(a.trim_prefix("--budget-s="))
		elif a.begins_with("--off-road-cost="):
			OFF_ROAD_COST = float(a.trim_prefix("--off-road-cost="))
		elif a.begins_with("--capture-dir="):
			_capture_dir = a.trim_prefix("--capture-dir=")
	if not _activity in ["bram", "herd", "vault", "doss", "juno", "hall"] \
			or not _save_path.is_absolute_path() or not FileAccess.file_exists(_save_path) \
			or not _capture_dir.is_absolute_path():
		print("[lure-walk] FAIL usage: --activity=bram|herd|vault|doss|juno|hall --save=/abs/file --capture-dir=/abs/dir")
		quit(2)
		return
	if DisplayServer.get_name() == "headless":
		print("[lure-walk] FAIL needs a rendered run (frames are the evidence)")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	await process_frame
	_game = root.get_node_or_null(^"Game")

	# --- load the real save exactly as the title screen's Load does ----------
	DirAccess.make_dir_recursive_absolute(SLOT_DIR)
	_wipe(SLOT_DIR)
	_game.set("save_system", SAVE_GAME.new(SLOT_DIR))
	var dst := str(_game.get("save_system").call("slot_path", SLOT))
	var out := FileAccess.open(dst, FileAccess.WRITE)
	out.store_buffer(FileAccess.get_file_as_bytes(_save_path))
	out.close()
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_save_path))
	var saved_pose: Array = (raw.get("player_pose", {}) as Dictionary).get("position", [])
	_receipt = {"activity": _activity, "save": _save_path,
		"save_sha256": FileAccess.get_sha256(_save_path), "save_version": raw.get("version"),
		"saved_position": saved_pose, "script_state_writes": "none",
		"budget_s": WALK_BUDGET_S}
	if not bool(_game.call("load_game", SLOT)):
		_finish("FAIL", "Game.load_game refused the real save")
		return
	var scene_path := str(_game.call("current_realm_scene"))
	if scene_path.is_empty():
		scene_path = DEFAULT_SCENE
	_receipt["scene"] = scene_path
	RenderingServer.render_loop_enabled = false
	_world = (load(scene_path) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_arbiter = get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null:
		_finish("FAIL", "no Player/CameraRig")
		return
	var here := _player.global_position
	_receipt["position_after_load"] = [snappedf(here.x, 0.01), snappedf(here.y, 0.01), snappedf(here.z, 0.01)]
	if saved_pose.size() == 3:
		_receipt["load_vs_saved_xz_m"] = snappedf(Vector2(here.x - float(saved_pose[0]),
			here.z - float(saved_pose[2])).length(), 0.01)
	_receipt["flags_before"] = _flags()
	_receipt["clock_hour"] = _hour()
	# A player walks with the active companion out (the herd watch and the
	# Engage prompt both need it). Call it out with the ordinary key, and check
	# the result rather than assuming it: one press toggles.
	# If the active member is fainted in the save, the recall key cannot bring it
	# out; a player cycles to a standing member (Change Creature) first.
	await _ensure_companion_out()
	_receipt["companion_out_at_start"] = _director != null and _director.call("ally_body") != null

	# --- the lure and the route ------------------------------------------------
	await _resolve_lure()
	if _lure == null:
		_finish("FAIL", "activity lure not present in the loaded world")
		return
	_receipt["lure_node"] = str(_lure.get_path())
	var lure_xz := _xz3(_lure.global_position)
	_receipt["lure_position"] = [snappedf(lure_xz.x, 0.1), snappedf(lure_xz.y, 0.1)]
	_receipt["start_distance_to_lure_m"] = snappedf(_xz().distance_to(lure_xz), 0.1)
	var legs: Array = []
	if _activity == "vault":
		var warrens := _world.get_node_or_null(^"BurrowWarrens")
		legs.append(warrens.call("marker", "entrance"))
		for leg: String in ["mouth", "hall", "den", "vault"]:
			legs.append(warrens.call("marker", leg))
	_plan_route(_xz(), _xz3(legs[0]) if not legs.is_empty() else lure_xz)
	for i in range(1, legs.size()):
		var m: Vector3 = legs[i]
		_path.append(Vector3(m.x, 0.0, m.z))
	if legs.is_empty():
		_path.append(Vector3(lure_xz.x, 0.0, lure_xz.y))
	_receipt["route_m"] = snappedf(_path_length(), 0.1)
	_receipt["route_road_points"] = _road_count()
	print("[lure-walk] START activity=%s save=%s pos=%s lure=%s route_m=%.1f hour=%.2f" % [
		_activity, _save_path.get_file(), str(_receipt.position_after_load), str(_receipt.lure_position),
		float(_receipt.route_m), float(_receipt.clock_hour)])
	await _capture("start")
	# Software GL renders this world at well under one frame a second, which
	# starves the fixed 60 Hz physics step. Between captures the render loop is
	# paused; physics, input, AI and the day clock run exactly as in play, and
	# each capture re-enables drawing for the frame it saves.
	RenderingServer.render_loop_enabled = false
	await _walk()


## --- lure resolution ---------------------------------------------------------

func _resolve_lure() -> void:
	match _activity:
		"bram", "juno":
			var trainers := _world.get_node_or_null(^"Trainers")
			# Juno's activity is lured by the Tether patrol holding the stolen
			# Meadowhart (WORLD §11: "follow missing-Meadowhart lead; defeat the
			# named Tether patrol"), not by Juno herself, who only gives the lead.
			var id := "old_champion_bram" if _activity == "bram" else "lost_creature_rue"
			if trainers != null:
				_lure = trainers.call("body_for", id) as Node3D
		"herd":
			_lure = _world.get_node_or_null(^"MeadowhartHerdVisit") as Node3D
			# The visit is a watch point; what a player looks for is the herd
			# itself. Visibility and facing use the nearest herd member.
			_lure_body = _herd_member()
		"doss":
			_lure = _world.get_node_or_null(^"RiverNestClear/Doss") as Node3D
		"vault":
			var warrens := _world.get_node_or_null(^"BurrowWarrens")
			if warrens != null:
				for body: Node3D in warrens.call("population"):
					if str(body.get("display_name")) == "Elder Trailpup":
						_lure = body
		"hall":
			for _frame in 120:
				for candidate: Variant in _director.get("_wild_creatures"):
					var body := candidate as Node3D
					if body != null and str((_director.get("_once_only") as Dictionary).get(body, "")) == "wild_once_5001":
						_lure = body
				if _lure != null:
					break
				await physics_frame
	if _lure != null:
		_prompt = _lure.get_node_or_null(^"Interactable")
	if _lure_body == null:
		_lure_body = _lure


func _herd_member() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	if _director == null:
		return null
	for candidate: Variant in _director.get("_wild_creatures"):
		var b := candidate as Node3D
		if b != null and is_instance_valid(b) and str(b.name).begins_with("Wild_meadowhart_1005_"):
			var d := b.global_position.distance_to(_player.global_position) if _player != null else 0.0
			if d < best_d:
				best_d = d
				best = b
	return best


## True when the arbiter offers this activity's own prompt right now.
func _prompt_offered() -> bool:
	if _arbiter == null:
		return false
	var provider: Variant = _arbiter.call("winning_provider")
	if _prompt != null and provider == _prompt:
		return true
	if provider == _director and _director.call("_engageable") == _lure:
		return true
	return false


## Lure "reads" when its body is inside the live camera's view, within range,
## and a ray from the camera reaches it without hitting world geometry first.
func _lure_visible() -> Dictionary:
	var cam := root.get_viewport().get_camera_3d()
	if _activity == "herd":
		_lure_body = _herd_member()
	var body := _lure_body if _lure_body != null and is_instance_valid(_lure_body) else _lure
	if cam == null or body == null or not is_instance_valid(body):
		return {}
	var target := body.global_position + Vector3(0.0, 1.0, 0.0)
	var dist := cam.global_position.distance_to(target)
	if dist > LURE_RANGE_M or cam.is_position_behind(target) or not cam.is_position_in_frustum(target):
		return {}
	var screen := cam.unproject_position(target)
	var size := root.get_viewport().get_visible_rect().size
	if screen.x < 0 or screen.y < 0 or screen.x > size.x or screen.y > size.y:
		return {}
	# A lure behind a HUD panel (hotbar, quest card, minimap) is not seen, even
	# if the world ray is clear (code-blind judge, discovery-snowball round).
	var hud_panel := _hud_panel_at(screen)
	if hud_panel != "":
		return {}
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, target)
	var exclude: Array[RID] = [_player.get_rid()]
	var ally := _director.call("ally_body") as CollisionObject3D if _director != null else null
	if ally != null:
		exclude.append(ally.get_rid())
	query.exclude = exclude
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Variant = hit.get("collider")
		if not (collider is Node and (collider == body or body.is_ancestor_of(collider as Node))):
			return {}
	# On-screen height of a person-sized (or the body's own) figure: geometric
	# visibility alone counted 10-15 px specks as "seen".
	var h := float(body.call("body_height")) if body.has_method("body_height") else 1.8
	var top := cam.unproject_position(body.global_position + Vector3(0.0, h, 0.0))
	var foot := cam.unproject_position(body.global_position)
	# unproject_position works in the logical canvas (1920x1080 under
	# canvas_items stretch); frames and the readable floor are window pixels.
	var to_frame := float(root.size.y) / size.y
	var px := absf(foot.y - top.y) * to_frame
	return {"distance_m": snappedf(dist, 0.1),
		"screen": [int(screen.x * to_frame), int(screen.y * to_frame)],
		"height_px": int(px), "readable": px >= READABLE_PX}


## Name of the visible HUD panel covering `point` (logical canvas coordinates),
## or "" when the point is clear of the HUD.
func _hud_panel_at(point: Vector2) -> String:
	var hud := _world.get_node_or_null(^"PlaygroundHUD") if _world != null else null
	if hud == null:
		return ""
	var stack: Array[Node] = [hud]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		var panel := node as Control
		if panel == null or not (panel is PanelContainer or panel is Panel):
			continue
		if not panel.is_visible_in_tree() or panel.size.x < 8.0 or panel.size.y < 8.0:
			continue
		if panel.get_global_rect().has_point(point):
			return str(panel.name)
	return ""


## --- route graph --------------------------------------------------------------

## Dense road graph from every authored band, loop and shortcut. Returns the
## path (road points, then a cross-country leg to `goal`) that minimises road
## metres + OFF_ROAD_COST x off-road metres.
func _plan_route(start: Vector2, goal: Vector2) -> void:
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
	var trail := terrain.get("trail", {}) as Dictionary
	var lines: Array = []
	for key: String in ["bands", "loops", "shortcuts"]:
		for entry: Variant in (trail.get(key, []) as Array):
			var pts: Array = (entry as Dictionary).get("points", [])
			if pts.size() >= 2:
				lines.append(pts)
	_nodes = []
	_adj = []
	_node_key = {}
	for pts: Array in lines:
		var prev := -1
		for j in pts.size():
			var p := Vector2(float(pts[j][0]), float(pts[j][1]))
			if j == 0:
				prev = _node_at(p)
				continue
			var a := Vector2(float(pts[j - 1][0]), float(pts[j - 1][1]))
			var steps := maxi(1, int(ceil(a.distance_to(p) / DENSIFY_M)))
			for s in range(1, steps + 1):
				var k := _node_at(a.lerp(p, float(s) / float(steps)))
				if k != prev:
					_adj[prev].append(k)
					_adj[k].append(prev)
				prev = k
	var nodes := PackedVector2Array(_nodes)
	var adj := _adj
	# Enter the graph at the nearest node to the saved position.
	var src := 0
	for i in nodes.size():
		if nodes[i].distance_to(start) < nodes[src].distance_to(start):
			src = i
	var dist := PackedFloat32Array()
	var prevs := PackedInt32Array()
	dist.resize(nodes.size())
	prevs.resize(nodes.size())
	for i in nodes.size():
		dist[i] = INF
		prevs[i] = -1
	dist[src] = 0.0
	var open := {src: true}
	while not open.is_empty():
		var u := -1
		for k: int in open:
			if u < 0 or dist[k] < dist[u]:
				u = k
		open.erase(u)
		for v: int in adj[u]:
			var nd := dist[u] + nodes[u].distance_to(nodes[v])
			if nd < dist[v]:
				dist[v] = nd
				prevs[v] = u
				open[v] = true
	var best := src
	var best_cost := INF
	for i in nodes.size():
		var c := dist[i] + OFF_ROAD_COST * nodes[i].distance_to(goal)
		if c < best_cost:
			best_cost = c
			best = i
	var chain: Array[int] = []
	var at := best
	while at >= 0:
		chain.push_front(at)
		at = prevs[at]
	for i: int in chain:
		_path.append(Vector3(nodes[i].x, 1.0, nodes[i].y))
	_path.append(Vector3(goal.x, 0.0, goal.y))
	_receipt["entered_road_at"] = [snappedf(nodes[src].x, 0.1), snappedf(nodes[src].y, 0.1)]
	_receipt["left_road_at"] = [snappedf(nodes[best].x, 0.1), snappedf(nodes[best].y, 0.1)]
	_receipt["off_road_leg_m"] = snappedf(nodes[best].distance_to(goal), 0.1)


var _nodes: Array = []
var _adj: Array = []
var _node_key: Dictionary = {}


## Graph node for a point, merging points within ~1m (junctions and band ends).
func _node_at(p: Vector2) -> int:
	var key := Vector2i(roundi(p.x), roundi(p.y))
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var k: Variant = _node_key.get(key + Vector2i(dx, dy))
			if k != null and (_nodes[int(k)] as Vector2).distance_to(p) < 1.0:
				return int(k)
	_nodes.append(p)
	_adj.append([])
	_node_key[key] = _nodes.size() - 1
	return _nodes.size() - 1


func _path_length() -> float:
	var total := 0.0
	for i in range(1, _path.size()):
		total += _xz3(_path[i - 1]).distance_to(_xz3(_path[i]))
	return total


func _road_count() -> int:
	var n := 0
	for p: Vector3 in _path:
		n += 1 if p.y > 0.5 else 0
	return n


## --- the walk -----------------------------------------------------------------

func _walk() -> void:
	_start_frame = Engine.get_physics_frames()
	_last = _xz()
	var cursor := 0
	var seen_on_road := false
	var seen := false
	var readable := false
	var looked := false
	var approach_saved := false
	var best_remaining := INF
	var best_at := 0.0
	var unstick := 0
	var near_checked := false
	## Route distance left when the last unstick fired; the count resets only
	## after real progress past it (best_remaining is reset to INF after an
	## unstick, so it cannot be the reference).
	var unstick_anchor := INF
	var frame := 0
	while _clock < WALK_BUDGET_S:
		await physics_frame
		frame += 1
		_tick()
		var here := _xz()
		if frame % 600 == 0:
			print("[lure-walk] PROGRESS t=%.1fs walked=%.1fm pos=(%.1f,%.1f) cursor=%d/%d" % [
				_clock, _walked, here.x, here.y, cursor, _path.size()])
		# Fights and dialogues the world starts are the player's to handle.
		if _manager != null and bool(_manager.call("is_fighting")):
			_release()
			var foe := _manager.call("enemy_body") as Node
			var foe_name := str(foe.name) if foe != null else "?"
			if foe == _lure or (_activity == "hall" and foe_name.begins_with("Wild_galecrest_5001_")):
				await _capture("engaged")
				_finish("PASS", "the activity's own encounter started on approach")
				return
			await _handle_fight(foe_name)
			best_at = _clock
			continue
		var owner := INPUT_OWNER.current(self)
		if owner != null:
			_release()
			_notes.append("t=%.1fs input owned by %s; pressed interact" % [_clock, str(owner.name)])
			await _capture("dialogue-%s" % str(owner.name).to_lower())
			await _press("interact")
			for i in 30:
				await physics_frame
			best_at = _clock
			continue

		# Lure check (every 10 frames).
		if frame % 10 == 0 and not seen:
			var vis := _lure_visible()
			if not vis.is_empty():
				seen = true
				seen_on_road = cursor < _road_count() - 1
				_receipt["lure_first_seen"] = {"t_s": snappedf(_clock, 0.1), "walked_m": snappedf(_walked, 0.1),
					"camera_to_lure_m": vis.distance_m, "screen_px": vis.screen,
					"while_on_road": seen_on_road, "after_deliberate_look": looked}
				_release()
				await _capture("lure-first-seen")
		if frame % 10 == 0 and seen and not readable:
			var rvis := _lure_visible()
			if not rvis.is_empty() and bool(rvis.get("readable", false)):
				readable = true
				_receipt["lure_first_readable"] = {"t_s": snappedf(_clock, 0.1), "walked_m": snappedf(_walked, 0.1),
					"camera_to_lure_m": rvis.distance_m, "height_px": rvis.height_px,
					"while_on_road": cursor < _road_count() - 1, "after_deliberate_look": looked}
				_release()
				await _capture("lure-first-readable")
		if _prompt_offered():
			_release()
			_receipt["prompt"] = {"t_s": snappedf(_clock, 0.1), "walked_m": snappedf(_walked, 0.1),
				"winner": str(_arbiter.call("winner"))}
			await _face_lure()
			await _capture("prompt-offered")
			_finish("PASS", "lure seen and the activity's prompt was offered")
			return

		# Advance the cursor along the path.
		while cursor < _path.size() - 1 and here.distance_to(_xz3(_path[cursor])) < 3.0:
			cursor += 1
			if cursor == _road_count() and not seen and not looked:
				# At the point the route leaves the road. Glance at the activity,
				# as a player would at a named place, and record that it took a look.
				looked = true
				_release()
				await _capture("left-road-lure-not-yet-on-screen")
				await _face_lure()
				continue
		var lure_d := here.distance_to(_xz3(_lure.global_position))
		if not near_checked and lure_d <= APPROACH_FRAME_M:
			# Whatever happened on the road (stowed to get unstuck, a toggle that
			# did not take), the Engage prompt needs the companion out.
			near_checked = true
			_release()
			_companion_stowed = false
			await _ensure_companion_out("t=%.1fs near the activity; " % _clock)
		if not approach_saved and seen and lure_d <= APPROACH_FRAME_M:
			approach_saved = true
			_release()
			await _face_lure()
			await _capture("approach-30m")
		if cursor >= _path.size() - 1 and lure_d <= 2.0:
			_release()
			await _face_lure()
			_receipt["winner_at_arrival"] = str(_arbiter.call("winner")) if _arbiter != null else ""
			_receipt["companion_out_at_arrival"] = _director != null and _director.call("ally_body") != null
			await _capture("arrival-no-prompt")
			_finish("GAP", "arrived at the lure but its prompt was never offered")
			return

		# Stuck detection on remaining route distance.
		var remaining := here.distance_to(_xz3(_path[cursor]))
		for i in range(cursor + 1, _path.size()):
			remaining += _xz3(_path[i - 1]).distance_to(_xz3(_path[i]))
		if remaining < best_remaining - 0.3:
			# Real progress since the last unstick clears the count: five snags
			# spread over a kilometre are not one blocked spot.
			if unstick > 0 and unstick_anchor - remaining > UNSTICK_RESET_M:
				unstick = 0
				unstick_anchor = INF
				if _companion_stowed:
					_release()
					_companion_stowed = false
					await _ensure_companion_out("t=%.1fs moving again; " % _clock)
			best_remaining = remaining
			best_at = _clock
		elif _clock - best_at > STUCK_S:
			unstick += 1
			_notes.append("t=%.1fs no progress at (%.1f,%.1f); unstick attempt %d (jump + strafe)" % [
				_clock, here.x, here.y, unstick])
			if unstick > UNSTICK_ATTEMPTS:
				_release()
				await _capture("stuck")
				_finish("GAP", "stuck at (%.1f,%.1f), %.1fm of route left" % [here.x, here.y, remaining])
				return
			unstick_anchor = remaining
			await _unstick(unstick)
			# From the second attempt, aim past the blocked waypoint: a boulder
			# or trunk on the road centreline is walked around, not into.
			if unstick >= 2:
				cursor = mini(cursor + 2, _path.size() - 1)
			best_remaining = INF
			best_at = _clock
			continue

		# Steer with the camera rig's yaw toward a point just ahead; walk and sprint.
		var target := _lookahead(here, cursor)
		var to := target - here
		if to.length() > 0.01:
			_rig.set("yaw", atan2(-to.x, -to.y))
		Input.action_press("move_forward", 1.0)
		Input.action_press("sprint")
	_release()
	await _capture("budget-spent")
	_finish("GAP", "walk budget %.0fs of game time spent %.1fm from the lure" % [
		WALK_BUDGET_S, _xz().distance_to(_xz3(_lure.global_position))])


## Game seconds since the walk began, and metres actually travelled (every
## physics frame's planar displacement, fights and unsticking included).
func _tick() -> void:
	_clock = float(Engine.get_physics_frames() - _start_frame) / float(Engine.physics_ticks_per_second)
	var now := _xz()
	var step := now.distance_to(_last)
	if step < 5.0:
		_walked += step
	_last = now


func _lookahead(here: Vector2, cursor: int) -> Vector2:
	var budget := LOOKAHEAD_M
	var from := here
	for i in range(cursor, _path.size()):
		var p := _xz3(_path[i])
		var d := from.distance_to(p)
		if d >= budget:
			return from.lerp(p, budget / d)
		budget -= d
		from = p
	return _xz3(_path[_path.size() - 1])


func _handle_fight(foe_name: String) -> void:
	var entry := {"t_s": snappedf(_clock, 0.1), "foe": foe_name}
	await _capture("fight-%s" % foe_name.to_lower())
	await _press("combat_run")
	for i in 60:
		await physics_frame
	if bool(_manager.call("is_fighting")):
		var pilot := COMBAT_PILOT.new(self, _manager, _director, _rig)
		pilot.listen()
		var result: Dictionary = await pilot.fight_to_the_end()
		entry["resolved_by"] = "input combat pilot"
		entry["outcome"] = str(result.get("outcome", ""))
	else:
		entry["resolved_by"] = "combat_run"
	for i in 90:
		await physics_frame
	# Post-fight catch/reward prompts own input briefly; let them settle.
	_fights.append(entry)


## Calls the active companion out with the ordinary key and checks the result
## rather than assuming it: one press toggles, so a press when it is already
## out would put it away. If the active member is fainted, the recall key
## cannot bring it out; a player cycles to a standing member first.
func _ensure_companion_out(prefix: String = "") -> void:
	for attempt in 4:
		if _director == null or _director.call("ally_body") != null:
			return
		var active: RefCounted = (_game.get("party") as RefCounted).call("active")
		if attempt >= 1 and active != null and float(active.get("hp")) <= 0.0:
			await _press("party_cycle")
			_notes.append("%sactive member %s is fainted; pressed party_cycle" % [prefix, str(active.get("nickname"))])
		await _press("creature_recall")
		for i in 60:
			await physics_frame
		_notes.append("%spressed creature_recall (attempt %d); companion out afterwards: %s" % [
			prefix, attempt + 1, str(_director.call("ally_body") != null)])


func _unstick(attempt: int) -> void:
	_release()
	# A companion walking at the player's shoulder can wedge them on a narrow
	# road shoulder (herd r3: pinned between a boulder and the Terrapup). From
	# the third attempt, put it away with the ordinary key; the walk calls it
	# back out once it is moving again.
	if attempt == 3 and _director != null and _director.call("ally_body") != null:
		await _press("creature_recall")
		_companion_stowed = true
		_notes.append("t=%.1fs put the companion away to get unstuck" % _clock)
	var side := "move_left" if attempt % 2 == 1 else "move_right"
	# Back off first so the strafe is not pressed flat against the obstacle.
	Input.action_press("move_back")
	for i in 24:
		await physics_frame
	Input.action_release("move_back")
	Input.action_press("jump")
	Input.action_press(side)
	Input.action_press("move_forward")
	for i in 30:
		await physics_frame
	Input.action_release("jump")
	for i in 30 + 15 * attempt:
		await physics_frame
	Input.action_release(side)
	Input.action_release("move_forward")


func _face_lure() -> void:
	var body := _lure_body if _lure_body != null and is_instance_valid(_lure_body) else _lure
	var to := _xz3(body.global_position) - _xz()
	if to.length() > 0.01:
		_rig.set("yaw", atan2(-to.x, -to.y))
	for i in 30:
		await physics_frame


func _press(action: String) -> void:
	Input.action_press(action)
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 2:
		await physics_frame
	Input.action_release(action)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 10:
		await physics_frame


func _release() -> void:
	for a: String in ["move_forward", "sprint", "move_left", "move_right", "move_back", "jump"]:
		Input.action_release(a)


## --- receipts -------------------------------------------------------------------

func _capture(label: String) -> void:
	if _start_frame > 0:
		_tick()
	var was_paused := not RenderingServer.render_loop_enabled
	RenderingServer.render_loop_enabled = true
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var file := "%s_%02d_%s.png" % [_activity, _frames.size() + 1, label]
	var saved := "no-image"
	if image != null and not image.is_empty():
		saved = file if image.save_png(_capture_dir.path_join(file)) == OK else "save-error"
	var here := _player.global_position
	var lure_d := _xz().distance_to(_xz3(_lure.global_position)) if _lure != null and is_instance_valid(_lure) else -1.0
	_frames.append({"file": saved, "label": label, "t_s": snappedf(_clock, 0.1),
		"walked_m": snappedf(_walked, 0.1), "pos": [snappedf(here.x, 0.1), snappedf(here.z, 0.1)],
		"lure_m": snappedf(lure_d, 0.1)})
	if was_paused:
		RenderingServer.render_loop_enabled = false
	print("[lure-walk] CAPTURE %s t=%.1fs walked=%.1fm pos=(%.1f,%.1f) lure_m=%.1f" % [
		saved, _clock, _walked, here.x, here.z, lure_d])


func _finish(verdict: String, why: String) -> void:
	_release()
	if _start_frame > 0:
		_tick()
	_receipt["verdict"] = verdict
	_receipt["why"] = why
	_receipt["walked_m"] = snappedf(_walked, 0.1)
	_receipt["game_seconds"] = snappedf(_clock, 0.1)
	_receipt["fights"] = _fights
	_receipt["notes"] = _notes
	_receipt["frames"] = _frames
	if _game != null:
		var after := _flags()
		var before: Array = _receipt.get("flags_before", [])
		var changed: Array = []
		for f: String in after:
			if not f in before:
				changed.append(f)
		_receipt["flags_set_by_game_during_walk"] = changed
		_receipt.erase("flags_before")
	if _player != null:
		_receipt["final_position"] = [snappedf(_player.global_position.x, 0.1), snappedf(_player.global_position.z, 0.1)]
	print("[lure-walk] RECEIPT %s" % JSON.stringify(_receipt))
	print("[lure-walk] %s activity=%s: %s" % [verdict, _activity, why])
	_wipe(SLOT_DIR)
	quit(0 if verdict == "PASS" else (3 if verdict == "GAP" else 1))


func _flags() -> Array:
	var progression: RefCounted = _game.get("progression")
	return (progression.call("all_set") as Array).duplicate() if progression != null else []


func _hour() -> float:
	for node in get_nodes_in_group("day_cycle"):
		if node.has_method("hour"):
			return float(node.call("hour"))
	return -1.0


func _wipe(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_wipe(dir_path.path_join(sub))
		DirAccess.remove_absolute(dir_path.path_join(sub))
	for f: String in dir.get_files():
		dir.remove(f)


func _xz() -> Vector2:
	return Vector2(_player.global_position.x, _player.global_position.z)


func _xz3(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
