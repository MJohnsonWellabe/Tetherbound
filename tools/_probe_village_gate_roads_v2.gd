extends SceneTree

## OWNER-0901-VILLAGE-GATE-ROADS-V2. Answers the two halves of the owner's
## 2026-09-01 report directly, with real numbers rather than a config read:
##
##   "village gate should exist on every road out of the village ... I can
##    still jump it some places and there no gate on at least one of the
##    roads."
##
##   godot --headless --path . --script tools/_probe_village_gate_roads_v2.gd
##
## Three parts:
##  1. ROAD CROSSINGS. Every `paths.routes` polyline in terrain_playground.json
##     that starts at the village square, walked segment by segment against the
##     authored `village_boundary.json` outline (the same polygon
##     village_boundary.gd builds the fence from) to find where -- if anywhere
##     -- it actually crosses the line, and whether a gate sits within
##     `gate_clear_m` of that crossing.
##  2. FENCE HEIGHT. The REAL collision box heights `village_boundary.gd` and
##     `road_gate.gd` built into the running scene, against the player's own
##     configured jump apex (movement.json `jump.height`) -- so "can I jump it"
##     is a measured margin, not a guess from prefab comments.
##  3. JUMP-ASSISTED ESCAPE. At the village's two gates and a spread of fence
##     panels around the whole ring, teleport the player to the inside face,
##     hold forward+jump, and see whether they land outside the polygon
##     (`village_boundary.gd.contains`, not a fixed distance threshold -- the
##     2026-08-30 southeast bulge legitimately puts the fence more than 60m
##     from the square in that corner, which a fixed-radius escape check
##     misreads as an escape).
##
## Diagnostic only. Prints; never asserts.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SQUARE := Vector3(10.0, 0.0, -10.0)
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const BOUNDARY_CONFIG := "res://data/config/village_boundary.json"
const VILLAGE_BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const JUMP_FRAMES := 90

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _outline: PackedVector2Array
var _gate_clear: float = 3.4
var _gate_positions: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D

	var boundary_cfg := _load_json(BOUNDARY_CONFIG)
	_outline = VILLAGE_BOUNDARY.outline(boundary_cfg)
	var wall: Dictionary = boundary_cfg.get("wall", {}) as Dictionary
	_gate_clear = float(wall.get("gate_clear_m", 3.4))
	var gate_entries: Array = (boundary_cfg.get("gates", {}) as Dictionary).get("entries", []) as Array
	for raw: Variant in gate_entries:
		var e := raw as Dictionary
		var at: Array = e.get("at", [])
		if at.size() >= 2:
			_gate_positions.append({"id": str(e.get("id", "?")), "route": str(e.get("route", "?")),
				"at": Vector2(float(at[0]), float(at[1]))})

	print("\n=== PART 1: road crossings against the authored boundary ===")
	_report_road_crossings()

	print("\n=== PART 2: real collision heights vs jump apex ===")
	_report_heights()

	if _player == null or _rig == null:
		print("\nno player/rig; cannot run jump-escape probe")
		quit(1)
		return

	var game := root.get_node_or_null(^"Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	var director := _world.get_node_or_null(^"SequenceDirector")
	if director == null:
		for child: Node in _world.get_children():
			if child.get_script() != null and str(child.get_script().resource_path).ends_with("sequence_director.gd"):
				director = child
				break
	if director != null and progression != null:
		progression.call("set_flag", "opening:beat:free_play")
		director.call("restore_progression_from_game", game)
		for i in 30:
			await physics_frame

	_player.set("_unstick_enabled", false)

	print("\n=== PART 3: fine bearing sweep, polygon-containment ground truth ===")
	await _bearing_sweep()

	print("\n=== PART 4: jump-assisted escape at both gates ===")
	for g: Dictionary in _gate_positions:
		await _try_jump_escape(str(g["id"]), g["at"] as Vector2)

	print("\n=== PART 5: jump-assisted escape at ordinary fence panels (not gates) ===")
	var boundary_node := _world.get_node_or_null(^"VillageBoundary")
	if boundary_node != null:
		var panel_positions := _panel_world_positions(boundary_node)
		# A spread around the ring, not just the panels nearest the gates.
		var picks: Array[int] = []
		var n := panel_positions.size()
		if n > 0:
			for k in 8:
				picks.append((k * n) / 8)
		for idx: int in picks:
			var p: Vector2 = panel_positions[idx]
			await _try_jump_escape("FencePanel[%d]" % idx, p)

	quit(0)


func _panel_world_positions(node: Node) -> Array:
	var out: Array = []
	for child: Node in node.get_children():
		if child is StaticBody3D and str(child.name).begins_with("FencePanelCollision"):
			out.append(Vector2(child.global_position.x, child.global_position.z))
		out.append_array(_panel_world_positions(child))
	return out


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## Segment-vs-closed-polygon crossing point, even-odd style: walk the route's
## own segments and report the first one whose endpoints sit on opposite sides
## of `_outline` (one inside, one outside), then solve the exact intersection
## against whichever outline edge it actually crosses.
func _first_crossing(route_points: Array) -> Variant:
	var prev_in := true
	var prev_pt := Vector2.ZERO
	for i in route_points.size():
		var raw: Array = route_points[i]
		var pt := Vector2(float(raw[0]), float(raw[1]))
		var inside := VILLAGE_BOUNDARY.contains(_outline, pt)
		if i > 0 and inside != prev_in:
			var cross: Variant = _segment_outline_intersection(prev_pt, pt)
			if cross != null:
				return cross
		prev_in = inside
		prev_pt = pt
	return null


func _segment_outline_intersection(a: Vector2, b: Vector2) -> Variant:
	for i in _outline.size():
		var c := _outline[i]
		var d := _outline[(i + 1) % _outline.size()]
		var hit: Variant = Geometry2D.segment_intersects_segment(a, b, c, d)
		if hit != null:
			return hit
	return null


func _report_road_crossings() -> void:
	var terrain_cfg := _load_json(TERRAIN_CONFIG)
	var paths: Dictionary = terrain_cfg.get("paths", {}) as Dictionary
	var routes: Array = paths.get("routes", []) as Array
	print("  outline has %d points; %d gate(s) authored (gate_clear_m=%.1f)" % [
		_outline.size(), _gate_positions.size(), _gate_clear])
	for g: Dictionary in _gate_positions:
		print("    gate %-10s route=%-12s at=%s" % [g["id"], g["route"], str(g["at"])])

	for raw: Variant in routes:
		var route := raw as Dictionary
		var label := str(route.get("label", "?"))
		var pts: Array = route.get("points", [])
		if pts.is_empty():
			continue
		var last_raw: Array = pts[pts.size() - 1]
		var last_pt := Vector2(float(last_raw[0]), float(last_raw[1]))
		var last_inside := VILLAGE_BOUNDARY.contains(_outline, last_pt)
		var cross: Variant = _first_crossing(pts)
		if cross == null:
			print("  route '%-16s' end=%s  NEVER LEAVES the boundary (interior road, no gate needed)" % [
				label, str(last_pt)])
			continue
		var crossing := cross as Vector2
		var nearest_gate := ""
		var nearest_d := 1e9
		for g: Dictionary in _gate_positions:
			var d: float = crossing.distance_to(g["at"] as Vector2)
			if d < nearest_d:
				nearest_d = d
				nearest_gate = str(g["id"])
		var gated := nearest_d <= _gate_clear
		print("  route '%-16s' crosses boundary at %s -- nearest gate %s at %.1fm (clear=%.1fm) -> %s" % [
			label, str(crossing.snapped(Vector2.ONE * 0.1)), nearest_gate, nearest_d, _gate_clear,
			("GATED" if gated else "*** NO GATE ON THIS ROAD ***")])


func _report_heights() -> void:
	var jump_height := 1.35
	var movement_cfg := _load_json("res://data/config/movement.json")
	var jump_block: Dictionary = movement_cfg.get("jump", {}) as Dictionary
	jump_height = float(jump_block.get("height", 1.35))
	print("  configured jump apex (movement.json jump.height): %.2fm above launch ground" % jump_height)

	var boundary_node := _world.get_node_or_null(^"VillageBoundary")
	if boundary_node == null:
		print("  no VillageBoundary node found in the built scene")
		return

	# The metric that actually matters for "can I jump it" is CLEARANCE ABOVE
	# THE GROUND A PLAYER STANDS ON, not the raw collision box height -- both
	# village_boundary.gd's panels (bury_m=1.0 sunk below the lowest sampled
	## ground) and road_gate.gd's leaf box report a box height that includes a
	# metre or more of buried collision no player ever has to clear. Comparing
	# that raw box height to jump apex (as an earlier version of this probe
	# did) understates the real risk: top_world_y minus the REAL ground height
	# at that (x,z) is the number that decides whether a running jump clears it.
	var panel_clearances: Array[float] = []
	var gate_clearances: Dictionary = {}
	_collect_clearances(boundary_node, panel_clearances, gate_clearances)

	if panel_clearances.is_empty():
		print("  no FencePanelCollision bodies found")
	else:
		var lo := panel_clearances[0]
		var hi := panel_clearances[0]
		var sum := 0.0
		for h: float in panel_clearances:
			lo = minf(lo, h)
			hi = maxf(hi, h)
			sum += h
		print("  fence panel clearance ABOVE LOCAL GROUND: min=%.2fm max=%.2fm avg=%.2fm over %d panels" % [
			lo, hi, sum / panel_clearances.size(), panel_clearances.size()])
		print("  clearance vs jump apex (%.2fm): min margin=%.2fm%s" % [
			jump_height, lo - jump_height, "  <-- JUMPABLE where clearance is this short" if lo < jump_height else ""])

	for id: String in gate_clearances.keys():
		var h: float = gate_clearances[id]
		print("  gate '%s' leaf clearance ABOVE LOCAL GROUND=%.2fm  margin vs jump apex=%.2fm%s" % [
			id, h, h - jump_height, "  <-- JUMPABLE" if h < jump_height else ""])


func _collect_clearances(node: Node, panels: Array[float], gates: Dictionary) -> void:
	for child: Node in node.get_children():
		if child is StaticBody3D and str(child.name).begins_with("FencePanelCollision"):
			var c: Variant = _clearance_above_ground(child)
			if c != null:
				panels.append(float(c))
		if child.name == "GateCollision":
			var gate_owner := child.get_parent()
			var gid := str(gate_owner.name) if gate_owner != null else str(child.get_path())
			var c2: Variant = _clearance_above_ground(child)
			if c2 != null:
				gates[gid] = float(c2)
		_collect_clearances(child, panels, gates)


## Top of this body's box, in world Y, minus the REAL ground height sampled
## directly under the body's own (x,z) -- the actual step a jump has to clear.
func _clearance_above_ground(body: Node3D) -> Variant:
	for c: Node in body.get_children():
		if c is CollisionShape3D:
			var shape: Shape3D = (c as CollisionShape3D).shape
			if shape is BoxShape3D:
				var box := shape as BoxShape3D
				var top_world_y: float = body.global_position.y + box.size.y * 0.5
				var ground: float = float(_world.call(
					"ground_height_at", body.global_position.x, body.global_position.z))
				if is_nan(ground):
					return null
				return top_world_y - ground
	return null


## Same 16 bearings and 900-frame walk as tools/_probe_village_gate_escape.gd
## (so this is comparable to that tool's own before/after runs), but judged by
## REAL polygon containment at the point the player actually stops rather than
## a fixed 60m distance threshold -- the 2026-08-30 southeast bulge legitimately
## puts the fence more than 60m from the square in that corner, which a
## fixed-radius escape check misreads as an escape.
const FAN_FRAMES := 900
func _bearing_sweep() -> void:
	var escaped: Array[String] = []
	for step in 16:
		var deg := float(step) * 22.5
		var dir := Vector3(sin(deg_to_rad(deg)), 0.0, cos(deg_to_rad(deg)))
		await _teleport(SQUARE + dir * 5.0)
		var target: Vector3 = SQUARE + dir * 150.0
		await _walk_toward(target, FAN_FRAMES)
		var here := _player.global_position
		var pt := Vector2(here.x, here.z)
		var inside := VILLAGE_BOUNDARY.contains(_outline, pt)
		var out_m := Vector2(here.x - SQUARE.x, here.z - SQUARE.z).length()
		var verdict := "held (inside)" if inside else "ESCAPED (outside polygon)"
		if not inside:
			escaped.append("%.1fdeg @ %s" % [deg, str(pt.snapped(Vector2.ONE * 0.1))])
		print("  bearing %5.1f deg -> %5.1fm from square, stopped at %s  %s" % [
			deg, out_m, str(pt.snapped(Vector2.ONE * 0.1)), verdict])
	print("\n  escaped (outside the authored polygon) on %d of 16 bearings: %s" % [
		escaped.size(), str(escaped)])


## Several separate running-jump attempts per location, each pressing jump at
## a DIFFERENT frame so one of them lands close to the wall's own base --
## a single fixed cadence (an earlier version of this probe) can miss the one
## timing a real player would actually find by feel. Reports the best result.
const JUMP_TIMING_FRAMES: Array[int] = [24, 30, 36, 42, 48, 54, 60]
func _try_jump_escape(label: String, at: Vector2) -> void:
	var out_dir := (at - Vector2(SQUARE.x, SQUARE.z)).normalized()
	var start := Vector3(at.x, 0.0, at.y) - Vector3(out_dir.x, 0.0, out_dir.y) * 4.0
	var target := Vector3(at.x, 0.0, at.y) + Vector3(out_dir.x, 0.0, out_dir.y) * 20.0
	var best_out := false
	var best_pos := start
	for jump_at: int in JUMP_TIMING_FRAMES:
		await _teleport(start)
		for i in 75:
			var to := target - _player.global_position
			to.y = 0.0
			_rig.set("yaw", atan2(-to.x, -to.z))
			Input.action_press("move_forward")
			if i == jump_at:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
			await physics_frame
		Input.action_release("move_forward")
		Input.action_release("jump")
		for i in 10:
			await physics_frame
		var here := _player.global_position
		var inside := VILLAGE_BOUNDARY.contains(_outline, Vector2(here.x, here.z))
		if not inside:
			best_out = true
			best_pos = here
			break
		best_pos = here
	print("  jump attempts at %-14s from %s -> best result %s  %s" % [
		label, str(start.snapped(Vector3.ONE * 0.1)), str(best_pos.snapped(Vector3.ONE * 0.1)),
		("JUMPED OUT (outside polygon)" if best_out else "held (inside) on every timing tried")])


func _teleport(to: Vector3) -> void:
	var ground: float = float(_world.call("ground_height_at", to.x, to.z))
	_player.global_position = Vector3(to.x, (ground if not is_nan(ground) else 0.0) + 1.0, to.z)
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame


func _walk_toward(point: Vector3, frames: int) -> void:
	for i in frames:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= 0.8:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 5:
		await physics_frame
