extends SceneTree

## B2 (#229): the Band 2 rootstone at harvest order 16 could not be reached by
## ordinary movement -- Cloudreach's earned chain got no nearer than ~4 m and
## the prompt needs its 2.4 m radius. This probe maps the quarry floor the way
## the player's body sees it: a 0.4 m capsule (the player's own) lifted
## STEP_CLEAR_M off the terrain is tested against every static collider on a
## GRID_M grid, the free cells are flood-filled from the road threshold, and
## each rootstone node reports the nearest reachable cell. `--at=x,z` adds a
## candidate site.
##
##   flock <writer-lock> godot --headless --path . \
##     --script tests/probe_quarry_floor.gd -- [--at=398,1797] [--map]
##
## Inert by default: a standalone SceneTree script, not a test_*.gd. Writes
## nothing.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HARVEST := "res://data/config/bands/band2_stone_and_root/harvest.json"
const SETTLE_FRAMES := 240
const GRID_M := 0.5
const MIN := Vector2(370.0, 1778.0)
const MAX := Vector2(420.0, 1830.0)
const BODY_RADIUS := 0.4
const BODY_HEIGHT := 1.8
const STEP_CLEAR_M := 0.35
# The quarry threshold the road delivers the player to (old_quarry.json
# arrival_scatter_clear), and where Cloudreach's walk actually stood.
const SEEDS := [Vector2(389.0, 1784.0), Vector2(397.5, 1801.4)]

var _world: Node3D
var _terrain_data: Object
var _space: PhysicsDirectSpaceState3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var extra: Array = []
	var draw_map := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var p := a.trim_prefix("--at=").split(",")
			extra.append(Vector2(float(p[0]), float(p[1])))
		elif a == "--map":
			draw_map = true
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _i in SETTLE_FRAMES:
		await physics_frame
	for n in _world.find_children("*", "Terrain3D", true, false):
		_terrain_data = n.get("data")
		break
	var veg := _world.get_node_or_null(^"Vegetation")
	if veg != null:
		veg.set("COLLISION_STREAM_RADIUS", 100000.0)
		veg.call("force_collision_resident", "")
	for _i in 30:
		await physics_frame
	_space = _world.get_world_3d().direct_space_state
	var player := _world.find_child("Player", true, false) as CollisionObject3D
	var exclude: Array[RID] = []
	if player != null:
		exclude.append(player.get_rid())
	var w := int((MAX.x - MIN.x) / GRID_M) + 1
	var h := int((MAX.y - MIN.y) / GRID_M) + 1
	var free := PackedByteArray()
	free.resize(w * h)
	var shape := CapsuleShape3D.new()
	shape.radius = BODY_RADIUS
	shape.height = BODY_HEIGHT
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.exclude = exclude
	q.collide_with_areas = false
	for j in h:
		for i in w:
			var x := MIN.x + i * GRID_M
			var z := MIN.y + j * GRID_M
			var g := _ground(x, z)
			q.transform = Transform3D(Basis(), Vector3(x, g + STEP_CLEAR_M + BODY_HEIGHT * 0.5, z))
			free[j * w + i] = 1 if _space.intersect_shape(q, 1).is_empty() else 0
	var reach := PackedByteArray()
	reach.resize(w * h)
	var queue: Array[int] = []
	for s: Vector2 in SEEDS:
		var si := _cell(s, w)
		if si >= 0 and free[si] == 1:
			reach[si] = 1
			queue.append(si)
		else:
			print("[quarry] seed %s not free" % s)
	while not queue.is_empty():
		var c: int = queue.pop_back()
		var ci := c % w
		var cj := c / w
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni := ci + d.x
			var nj := cj + d.y
			if ni < 0 or nj < 0 or ni >= w or nj >= h:
				continue
			var n := nj * w + ni
			if free[n] == 1 and reach[n] == 0:
				reach[n] = 1
				queue.append(n)
	var targets: Array = []
	var harvest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HARVEST))
	for node: Dictionary in harvest.get("nodes", []):
		if str(node.get("item", "")) == "rootstone":
			targets.append(["order %d" % int(node.get("order", -1)), Vector2(float(node.at[0]), float(node.at[1]))])
	for e: Vector2 in extra:
		targets.append(["candidate", e])
	for t: Array in targets:
		var at: Vector2 = t[1]
		var best := INF
		var best_at := Vector2.ZERO
		for j in h:
			for i in w:
				if reach[j * w + i] == 1:
					var p := Vector2(MIN.x + i * GRID_M, MIN.y + j * GRID_M)
					var d := p.distance_to(at)
					if d < best:
						best = d
						best_at = p
		print("[quarry] %s at %s: nearest reachable cell %s, %.2f m (prompt radius 2.4 m from +0.6 m) -> %s" % [
			t[0], at, best_at, best, "REACHABLE" if best <= 1.8 else "UNREACHABLE"])
	if draw_map:
		# rows run south (+z) to north; '#' blocked, '.' free but cut off, ' ' reachable
		for j in h:
			var row := "%6.1f " % (MIN.y + j * GRID_M)
			for i in w:
				var c := j * w + i
				var mark := " " if reach[c] == 1 else ("." if free[c] == 1 else "#")
				for t: Array in targets:
					if (t[1] as Vector2).distance_to(Vector2(MIN.x + i * GRID_M, MIN.y + j * GRID_M)) < GRID_M * 0.5:
						mark = "R" if t[0] != "candidate" else "C"
				row += mark
			print(row)
		print("x from %.1f step %.1f" % [MIN.x, GRID_M])
	quit(0)


func _cell(p: Vector2, w: int) -> int:
	var i := int(round((p.x - MIN.x) / GRID_M))
	var j := int(round((p.y - MIN.y) / GRID_M))
	return j * w + i


func _ground(x: float, z: float) -> float:
	if _terrain_data == null:
		return 0.0
	var g := float(_terrain_data.call("get_height", Vector3(x, 0.0, z)))
	return 0.0 if is_nan(g) else g
