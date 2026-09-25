extends SceneTree

## F06 / C1 (ROADMAP §3, ACCEPTANCE §6.1 F06, card C1): the summit crown has a
## floor, and the roads that climb up inside it keep open sky.
##
## CLOUDREACH-PLAYER-CAMERA found the summit's drawn flat crown uncollidable: a
## trainer at the summit-approach stand (100, 5290) fell through, and a 10 m
## probe grid over x 20-180, z 5140-5410 found drawn ground with no collider
## (SummitSupplyPosition's anchor (100, 1160, 5297) among it). The region's
## `CliffMass` had no collider because the final road climbs up INSIDE that
## crown and a plain crown collider would have roofed it. cloudreach_world.gd
## now carves the crown down to every road under it (`crown_cut` in
## cloudreach_world.json) and draws AND collides that one carved surface as
## the mass's `CarvedCrown`.
##
## Checks, all against the real built scene and its physics space:
##  (a) Drawn == collidable over the report's grid. The expected height at each
##      XZ is read from the `CarvedCrown` render mesh itself (not re-derived).
##      A downward ray from y=2000 must meet a static collider within 1.5 m of
##      it; a collider more than 1.5 m ABOVE it (the aviary, a ledge crown
##      standing on the crown) is passed through and the ray continues. XZ
##      the crown does not draw is skipped and counted. The stand and
##      SummitSupplyPosition get the same probe by name. Then every
##      `CarvedCrown` triangle centroid in that box is probed ground-truth
##      style: a static collider within 0.15 m, or a drawn/road surface above
##      it (the road ribbon and shoulders over the carve floor) -- never
##      nothing and never lower.
##      INFO only: grid XZ where `ground_height_at` differs from the drawn
##      crown by > 1.5 m. That index is a flat ellipse whose rotation does not
##      match the mesa's; it is pre-existing and not changed here.
##  (b) The roads under the crown: every ribbon line of upper_summit_road and
##      summit_overlook_loop, sampled every 2 m at -3.1/0/+3.1 m across (the
##      0.4 m capsule then covers the whole +-3.5 m ribbon), where the crown
##      is drawn above that XZ. At the ribbon's own top (the line
##      height, `_all_route_lines`) a short down ray must find the road; an
##      upward ray from +0.5 m to +2.3 m (trainer 1.8 m + 0.5 m) must not meet
##      the `CarvedCrown` collider (FAIL: a new ceiling) -- any OTHER static
##      collider there is printed as pre-existing; and a 0.4 x 1.8 m capsule
##      lifted 0.25 m off the ribbon must overlap no static collider on the
##      centreline and never the `CarvedCrown` anywhere (another collider at
##      the +-3.1 m road edge is printed, not failed: the east route wing's
##      south block already overhangs the diagonal road's edge near the gate,
##      which this carve neither causes nor changes).
##  (c) The trainer, placed 1 m above the summit-approach stand (100, 5290),
##      must be on the CROWN (is_on_floor, y within 1.5 m of 1160, XZ within
##      2 m of the stand) within 600 physics frames.
##
##  (d) The finale arena keeps its edge and its one entrance (H1). The deck is
##      an island at the crown's north rim; since the crown collides, the
##      plateau round its southern half is walkable, so the perimeter masonry
##      that stands on it has to be solid. A 0.25 m cell grid over r 35.5-48
##      round the arena centre is flood-filled from the deck: a cell is
##      standable when a ray finds ground with normal.y >= cos(45 deg) (the
##      trainer's floor_max_angle) no more than 10 m under the deck and a
##      0.4 x 1.8 m capsule lifted the 0.35 m step height over it meets no
##      static body; a move steps up at most 0.35 m (any drop is allowed).
##      The approach throat -- the southern sector the perimeter leaves open,
##      |sin| < 0.40 -- is not entered. FAIL: any standable cell at r >= 47.5
##      (past every bay and tower) is reached, i.e. a trainer leaves the arena
##      onto walkable ground anywhere but the throat. The same flood at a
##      creature's 55 deg floor angle is printed as INFO.
##  (e) Every visible perimeter bay, watch tower and rear courtyard arcade
##      blocks a capsule: for its drawn near-vertical outward faces that reach
##      the trainer's height band over the ground in front of them, a capsule
##      started 1.2 m out and swept 2 m at the face must stop before it.
##      Faces whose start is still inside the piece's own bounds (a hollow
##      interior, a brick's flank, an arch's open side) are not swept; a piece
##      left with none is printed as INFO.
##  (f) No hidden road collider stands above walkable crown (M1): along every
##      road line over the drawn crown, every 1 m, 3.9 m either side of the
##      centreline (the 7 m collision ribbon + the trainer's radius), the first
##      static surface under the ribbon's height -- the carved crown, a pad's
##      landing crown, a shoulder -- must be within the 0.35 m step of the
##      ribbon or too steep to stand on.
##  (g) The co-op (sliced shell) build, which skips the route shoulders, is
##      built headless after the solo world is freed and gets (d), (e) and (f).
##
## Fixtures, disclosed: the summit route's story flags are set directly
## (as smoke_cloudreach_summit_road does), and (c) makes one position write.
## Nothing here walks: smoke_cloudreach_summit_road and
## smoke_cloudreach_summit_bivouac_join walk both carved roads with real stick
## input and must be run alongside this.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
# The report's x 20-180, z 5140-5410, widened (L2) west over the loop trench
# (x -55), east past the upper road's trench mouth and north to the arena.
const GRID_MIN := Vector2(-60.0, 5140.0)
const GRID_MAX := Vector2(220.0, 5490.0)
const GRID_STEP := 10.0
const GRID_JITTER_M := 0.013
const GRID_TOLERANCE_M := 1.5
const CENTROID_TOLERANCE_M := 0.15
const TRAINER_HEIGHT_M := 1.8
const TRAINER_RADIUS_M := 0.4
const HEADROOM_MARGIN_M := 0.5
# Over the ribbon's own top. The summit ledge's flat cap stands 0.13 m over the
# pad stub ribbons; the controller steps 0.35 m.
const CAPSULE_LIFT_M := 0.25
const CROWN_Y := 1160.0
const STAND := Vector2(100.0, 5290.0)
const SUPPLY := Vector2(100.0, 5297.0)
const SUMMIT_ROUTES: Array[String] = ["upper_summit_road", "summit_overlook_loop"]
const BUCKET_M := 8.0
# (b) samples the ribbon's centre and +-3.1 m, so the 0.4 m capsule covers
# the whole 7 m (+-3.5 m) collision ribbon.
const ROAD_EDGE_OFFSET_M := 3.1
const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const STEP_HEIGHT_M := 0.35
const TRAINER_FLOOR_NORMAL_Y := 0.7071 # cos(45 deg), player.tscn floor_max_angle
const CREATURE_FLOOR_NORMAL_Y := 0.5736 # cos(55 deg), creature.tscn
const RING_CELL_M := 0.25
const RING_INNER_M := 35.5
const RING_OUTER_M := 48.0
const RING_ESCAPE_M := 47.5
const THROAT_SIN := 0.40
const ROAD_BOX_HALF_M := 3.5
const MASONRY_LABELS: Array[String] = ["RetainedMasonry", "PerimeterWatchTower", "RearCourtyardArcade"]

var world: Node3D
var player: CharacterBody3D
var space: PhysicsDirectSpaceState3D
var failures: Array[String] = []
var crown_body: StaticBody3D
var triangles := PackedVector3Array() # world space, 3 per triangle
var buckets: Dictionary = {} # Vector2i -> PackedInt32Array of triangle indices
var leg := "" # "" for the solo world, "(g) " for the co-op shell
var people_excluded: Dictionary = {}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	var flags: RefCounted = game.get("progression")
	for flag: String in ["realm_key_cloudreach", "cloudreach_upper_route_unlocked",
			"cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled"]:
		flags.call("set_flag", flag)
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node(^"Player") as CharacterBody3D
	for _frame in 3000:
		if bool(world.call("shell_build_complete")):
			break
		await process_frame
	if not bool(world.call("shell_build_complete")):
		_fail("world build did not complete")
		_finish()
		return
	for _frame in 6:
		await physics_frame
	space = world.get_world_3d().direct_space_state
	if not _load_crown():
		_finish()
		return
	_print_build_timing()
	_check_grid()
	_check_centroids()
	_check_roads()
	await _check_stand_landing()
	_check_arena_ring("(d)")
	_check_masonry("(e)")
	_check_road_boxes("(f)")
	await _coop_leg()
	_finish()


## (g) The same world as a co-op shell: `simulation_only` builds sliced, and a
## sliced build skips the route shoulders (cloudreach_world.gd `_build_routes`).
func _coop_leg() -> void:
	world.queue_free()
	for _frame in 4:
		await process_frame
	triangles = PackedVector3Array()
	buckets = {}
	crown_body = null
	world = SCENE.instantiate()
	world.set("simulation_only", true)
	var started := Time.get_ticks_msec()
	root.add_child(world)
	player = world.get_node_or_null(^"Player") as CharacterBody3D
	for _frame in 20000:
		if bool(world.call("shell_build_complete")):
			break
		await process_frame
	if not bool(world.call("shell_build_complete")):
		_fail("(g) co-op shell build did not complete")
		return
	print("SUMMIT CROWN (g): co-op shell built in %d ms" % (Time.get_ticks_msec() - started))
	for _frame in 6:
		await physics_frame
	space = world.get_world_3d().direct_space_state
	if not _load_crown():
		failures[failures.size() - 1] = "(g) " + failures[failures.size() - 1]
		return
	_print_build_timing()
	_check_arena_ring("(g)")
	_check_masonry("(g)")
	_check_road_boxes("(g)")


func _print_build_timing() -> void:
	var total: Variant = world.get("crown_cut_build_usec")
	var carve: Variant = world.get("crown_cut_carve_usec")
	if total == null or carve == null:
		print("SUMMIT CROWN: carved crown build time not recorded by this world")
		return
	print("SUMMIT CROWN: carved crown build %.1f ms (carve %.1f ms, mesh + collider %.1f ms)" % [
		float(total) / 1000.0, float(carve) / 1000.0, float(int(total) - int(carve)) / 1000.0])


func _player_rids() -> Array[RID]:
	var rids: Array[RID] = []
	if player != null:
		rids.append(player.get_rid())
	return rids


## A person is a StaticBody3D (npc_body.gd) but not geometry: printed, skipped.
func _is_person(collider: Object) -> bool:
	var path := str((collider as Node).get_path())
	if not path.contains("/CloudreachPeople/"):
		return false
	if not people_excluded.has(path):
		people_excluded[path] = true
		print("SUMMIT CROWN INFO: excluded person body %s" % path)
	return true


func _finish() -> void:
	for line: String in failures:
		printerr("SUMMIT CROWN FAIL: " + line)
	for check: String in ["(a)", "(b)", "(c)", "(d)", "(e)", "(f)", "(g)"]:
		var count := 0
		for line: String in failures:
			if line.begins_with(check):
				count += 1
		print("SUMMIT CROWN %s %s (%d failures)" % [check, "FAIL" if count > 0 else "PASS", count])
	print("CLOUDREACH SUMMIT CROWN %s (%d failures)" % ["FAIL" if not failures.is_empty() else "PASS",
		failures.size()])
	quit(1 if not failures.is_empty() else 0)


func _fail(line: String) -> void:
	failures.append(line)


## ---- the carved crown's own render triangles --------------------------------

func _load_crown() -> bool:
	var instance := world.find_child("CarvedCrown", true, false) as MeshInstance3D
	if instance == null or instance.mesh == null:
		_fail("no CarvedCrown mesh: the summit crown was not carved/built")
		return false
	for child in instance.get_children():
		if child is StaticBody3D:
			crown_body = child as StaticBody3D
	if crown_body == null:
		_fail("CarvedCrown has no collider")
		return false
	var xform := instance.global_transform
	for surface in instance.mesh.get_surface_count():
		var arrays := instance.mesh.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		if indices is PackedInt32Array and not (indices as PackedInt32Array).is_empty():
			for index: int in indices:
				triangles.append(xform * verts[index])
		else:
			for vertex: Vector3 in verts:
				triangles.append(xform * vertex)
	for t in triangles.size() / 3:
		var a := triangles[t * 3]
		var b := triangles[t * 3 + 1]
		var c := triangles[t * 3 + 2]
		for cx in range(floori(minf(a.x, minf(b.x, c.x)) / BUCKET_M), floori(maxf(a.x, maxf(b.x, c.x)) / BUCKET_M) + 1):
			for cz in range(floori(minf(a.z, minf(b.z, c.z)) / BUCKET_M), floori(maxf(a.z, maxf(b.z, c.z)) / BUCKET_M) + 1):
				var key := Vector2i(cx, cz)
				if not buckets.has(key):
					buckets[key] = PackedInt32Array()
				var list: PackedInt32Array = buckets[key]
				list.append(t)
				buckets[key] = list
	print("SUMMIT CROWN: CarvedCrown %d triangles" % (triangles.size() / 3))
	return true


## The drawn crown height at XZ (highest triangle over it), NAN if undrawn.
func _drawn_height(x: float, z: float) -> float:
	var best := NAN
	for t: int in buckets.get(Vector2i(floori(x / BUCKET_M), floori(z / BUCKET_M)), PackedInt32Array()):
		var a := triangles[t * 3]
		var b := triangles[t * 3 + 1]
		var c := triangles[t * 3 + 2]
		var det := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
		if absf(det) < 0.000001:
			continue
		var l1 := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / det
		var l2 := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / det
		var l3 := 1.0 - l1 - l2
		if l1 < -0.00001 or l2 < -0.00001 or l3 < -0.00001:
			continue
		var h := l1 * a.y + l2 * b.y + l3 * c.y
		if is_nan(best) or h > best:
			best = h
	return best


## ---- (a) drawn == collidable -----------------------------------------------

## First static collider within `tolerance` of `expected` on a ray down from
## `from_y`, passing through anything standing more than `tolerance` above it
## and through non-static bodies. {} when the first thing met at/below the
## band is lower than it (or nothing is).
func _collider_near(x: float, z: float, expected: float, tolerance: float, from_y: float) -> Dictionary:
	var exclude: Array[RID] = [player.get_rid()]
	for _attempt in 12:
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z),
			Vector3(x, expected - 60.0, z))
		query.exclude = exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return {}
		var y := (hit["position"] as Vector3).y
		if not (hit["collider"] is StaticBody3D) or y > expected + tolerance:
			exclude.append(hit["rid"])
			continue
		return hit if y >= expected - tolerance else {}
	return {}


func _check_grid() -> void:
	var drawn := 0
	var skipped := 0
	var index_mismatch: Array[String] = []
	var x := GRID_MIN.x
	while x <= GRID_MAX.x + 0.01:
		var z := GRID_MIN.y
		while z <= GRID_MAX.y + 0.01:
			# 13 mm off the round grid, so no probe lands exactly on a mesh
			# vertex/edge (the fan apex sits at a grid point) -- the known
			# watertight-ray edge case smoke_cloudreach_ground_truth avoids.
			var px := x + GRID_JITTER_M
			var pz := z + GRID_JITTER_M
			var expected := _drawn_height(px, pz)
			if is_nan(expected):
				skipped += 1
			else:
				drawn += 1
				if _collider_near(px, pz, expected, GRID_TOLERANCE_M, 2000.0).is_empty():
					_fail("(a) drawn crown at (%.0f, %.2f, %.0f) has no collider within %.1f m" % [
						x, expected, z, GRID_TOLERANCE_M])
				var index := float(world.call("ground_height_at", px, pz))
				if not is_nan(index) and absf(index - expected) > GRID_TOLERANCE_M:
					index_mismatch.append("(%.0f,%.0f) index=%.2f drawn=%.2f" % [x, z, index, expected])
			z += GRID_STEP
		x += GRID_STEP
	for label: String in ["stand", "SummitSupplyPosition"]:
		var at := STAND if label == "stand" else SUPPLY
		var expected := _drawn_height(at.x, at.y)
		if is_nan(expected) or absf(expected - CROWN_Y) > GRID_TOLERANCE_M:
			_fail("(a) %s %s is not on the drawn crown (drawn=%s)" % [label, at, expected])
		elif _collider_near(at.x, at.y, expected, GRID_TOLERANCE_M, 2000.0).is_empty():
			_fail("(a) %s %s has no collider under the drawn crown" % [label, at])
	print("SUMMIT CROWN (a): grid %d drawn XZ probed, %d undrawn skipped" % [drawn, skipped])
	print("SUMMIT CROWN (a) INFO: %d drawn XZ where ground_height_at differs by > %.1f m (pre-existing index shape)%s" % [
		index_mismatch.size(), GRID_TOLERANCE_M,
		"" if index_mismatch.is_empty() else ": " + ", ".join(PackedStringArray(index_mismatch.slice(0, 8)))])


func _check_centroids() -> void:
	var probed := 0
	var covered := 0
	var walls := 0
	for t in triangles.size() / 3:
		var centroid := (triangles[t * 3] + triangles[t * 3 + 1] + triangles[t * 3 + 2]) / 3.0
		if centroid.x < GRID_MIN.x or centroid.x > GRID_MAX.x \
				or centroid.z < GRID_MIN.y or centroid.z > GRID_MAX.y:
			continue
		var face_normal := (triangles[t * 3 + 1] - triangles[t * 3]).cross(triangles[t * 3 + 2] - triangles[t * 3])
		if face_normal.length_squared() > 0.0 and absf(face_normal.normalized().y) < 0.2:
			walls += 1 # a rim strip closing a filled rim: no vertical ray can land on it
			continue
		probed += 1
		var exclude: Array[RID] = _player_rids()
		var hit: Dictionary = {}
		for _attempt in 8:
			var query := PhysicsRayQueryParameters3D.create(centroid + Vector3.UP * 5.0,
				centroid + Vector3.DOWN * 5.0)
			query.exclude = exclude
			hit = space.intersect_ray(query)
			if hit.is_empty() or hit["collider"] is StaticBody3D:
				break
			exclude.append(hit["rid"])
		if hit.is_empty() or not (hit["collider"] is StaticBody3D):
			_fail("(a) CarvedCrown centroid %s: no collider within 5 m" % centroid)
			continue
		var gap := (hit["position"] as Vector3).y - centroid.y
		if gap < -CENTROID_TOLERANCE_M:
			_fail("(a) CarvedCrown centroid %s: collider %.3f m BELOW the drawn crown" % [centroid, -gap])
		elif gap > CENTROID_TOLERANCE_M:
			covered += 1 # road ribbon/shoulder over the carve floor, a ledge crown
	print("SUMMIT CROWN (a): %d CarvedCrown centroids probed, %d under another surface, %d near-vertical rim strips skipped" % [probed, covered, walls])


## ---- (b) the roads that climb inside the crown ------------------------------

func _check_roads() -> void:
	var lines: Array = world.get("_all_route_lines")
	var samples := 0
	var pre_existing: Dictionary = {}
	for raw: Variant in lines:
		var line: Dictionary = raw
		if not SUMMIT_ROUTES.has(str(line["route_id"])):
			continue
		var a: Vector3 = line["a"]
		var b: Vector3 = line["b"]
		var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
		if flat.length() < 0.01:
			continue
		var right := Vector3.UP.cross(flat.normalized()).normalized()
		var steps := maxi(1, ceili(flat.length() / 2.0))
		for step in steps + 1:
			var centre := a.lerp(b, float(step) / float(steps))
			for offset: float in [-ROAD_EDGE_OFFSET_M, 0.0, ROAD_EDGE_OFFSET_M]:
				var at := centre + right * offset
				var drawn := _drawn_height(at.x, at.z)
				if is_nan(drawn):
					continue # not under the summit crown
				samples += 1
				_check_road_point(at, offset == 0.0, pre_existing)
	print("SUMMIT CROWN (b): %d road points under the crown checked" % samples)
	for path: String in pre_existing:
		var over := float(pre_existing[path])
		print("SUMMIT CROWN (b) INFO: pre-existing collider %s%s" % [path,
			"" if over < 0.0 else ", lowest %.2f m over the road" % over])


func _check_road_point(at: Vector3, centreline: bool, pre_existing: Dictionary) -> void:
	var exclude: Array[RID] = [player.get_rid()]
	# The road itself is there.
	var down := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.3, at + Vector3.DOWN * 1.0)
	down.exclude = exclude
	var floor_hit := space.intersect_ray(down)
	if not floor_hit.is_empty() and not (floor_hit["collider"] is StaticBody3D):
		var past_body: Array[RID] = [player.get_rid(), floor_hit["rid"]] # a creature on the road
		down.exclude = past_body
		floor_hit = space.intersect_ray(down)
	if floor_hit.is_empty() or (floor_hit["position"] as Vector3).y < at.y - 0.3:
		_fail("(b) no road collider at %s" % at)
	# No ceiling within the trainer's height + margin. Back faces count: a
	# one-sided crown trimesh seen from under the road is still a ceiling.
	var clear_top := at + Vector3.UP * (TRAINER_HEIGHT_M + HEADROOM_MARGIN_M)
	var from := at + Vector3.UP * 0.5
	for _attempt in 8:
		var up := PhysicsRayQueryParameters3D.create(from, clear_top)
		up.exclude = exclude
		up.hit_back_faces = true
		var hit := space.intersect_ray(up)
		if hit.is_empty():
			break
		if not (hit["collider"] is StaticBody3D):
			exclude.append(hit["rid"])
			continue
		var over := (hit["position"] as Vector3).y - at.y
		if hit["collider"] == crown_body:
			_fail("(b) NEW ceiling: the carved crown is %.2f m over the road at %s" % [over, at])
		else:
			var path := str((hit["collider"] as Node).get_path())
			pre_existing[path] = minf(float(pre_existing.get(path, INF)), over)
		exclude.append(hit["rid"])
	# The trainer's capsule fits on the road.
	var capsule := CapsuleShape3D.new()
	capsule.radius = TRAINER_RADIUS_M
	capsule.height = TRAINER_HEIGHT_M
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = capsule
	params.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * (CAPSULE_LIFT_M + TRAINER_HEIGHT_M * 0.5))
	var shape_exclude: Array[RID] = [player.get_rid()]
	params.exclude = shape_exclude
	for overlap: Dictionary in space.intersect_shape(params, 16):
		if not (overlap["collider"] is StaticBody3D):
			continue
		var path := str((overlap["collider"] as Node).get_path())
		# A person standing on the road (Captain Veyra holds the pad at
		# (100, 1160, 5350)) is not road geometry; npc_body.gd bodies are
		# StaticBody3D and the trainer walks around them like anyone else.
		if _is_person(overlap["collider"]):
			continue
		if overlap["collider"] == crown_body or centreline:
			_fail("(b) trainer capsule on the road at %s overlaps %s" % [at, path])
		else:
			# Off the centreline, a collider other than the new crown is the
			# pre-existing stronghold throat (see smoke_cloudreach_summit_road).
			pre_existing[path + " (overlaps the capsule at the road edge)"] = -1.0


## ---- (c) the trainer at the summit-approach stand ---------------------------

func _check_stand_landing() -> void:
	var start := Vector3(STAND.x, CROWN_Y + 1.0, STAND.y)
	player.global_position = start # declared fixture: the one position write
	player.velocity = Vector3.ZERO
	for frame in 600:
		await physics_frame
		var at := player.global_position
		if at.y < CROWN_Y - 40.0:
			break
		if player.is_on_floor() and absf(at.y - CROWN_Y) <= GRID_TOLERANCE_M \
				and Vector2(at.x - STAND.x, at.z - STAND.y).length() <= 2.0:
			print("SUMMIT CROWN (c): trainer on the crown at %s after %d frames" % [at, frame + 1])
			return
	_fail("(c) trainer placed at %s is not standing on the crown after 600 frames: at %s on_floor=%s" % [
		start, player.global_position, player.is_on_floor()])


## ---- (d) the finale arena's edge and single entrance -----------------------

func _check_arena_ring(label: String) -> void:
	var config := FINALE.read_config()
	var origin := FINALE.vec(config["arena_origin"])
	var deck_radius := float(config["arena_radius_m"])
	var deck_top := origin.y + 0.15
	var started := Time.get_ticks_msec()
	var cells := ceili(RING_OUTER_M / RING_CELL_M)
	var side := cells * 2 + 1
	# Per cell: ground y (NAN: no ground / a fall), ground normal.y, and whether
	# a stepped-up capsule there is clear of every static body.
	var ground := PackedFloat32Array()
	var normal_y := PackedFloat32Array()
	var clear := PackedByteArray()
	ground.resize(side * side)
	normal_y.resize(side * side)
	clear.resize(side * side)
	ground.fill(NAN)
	var capsule := CapsuleShape3D.new()
	capsule.radius = TRAINER_RADIUS_M
	capsule.height = TRAINER_HEIGHT_M
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = capsule
	params.exclude = _player_rids()
	var probed := 0
	for iz in side:
		for ix in side:
			var local := Vector2(float(ix - cells), float(iz - cells)) * RING_CELL_M
			var r := local.length()
			if r < RING_INNER_M or r > RING_OUTER_M:
				continue
			var at := Vector3(origin.x + local.x, 0.0, origin.z + local.y)
			var hit := _static_ray(Vector3(at.x, deck_top + STEP_HEIGHT_M + 1.9, at.z),
				Vector3(at.x, deck_top - 10.0, at.z), false)
			if hit.is_empty():
				continue
			probed += 1
			var index := iz * side + ix
			var y := (hit["position"] as Vector3).y
			ground[index] = y
			normal_y[index] = (hit["normal"] as Vector3).y
			params.transform = Transform3D(Basis.IDENTITY,
				Vector3(at.x, y + STEP_HEIGHT_M + 0.01 + TRAINER_HEIGHT_M * 0.5, at.z))
			var blocked := false
			for overlap: Dictionary in space.intersect_shape(params, 8):
				if overlap["collider"] is StaticBody3D and not _is_person(overlap["collider"]):
					blocked = true
					break
			clear[index] = 0 if blocked else 1
	var trainer_escapes := _flood_ring(ground, normal_y, clear, cells, side, deck_radius,
		TRAINER_FLOOR_NORMAL_Y)
	var creature_escapes := _flood_ring(ground, normal_y, clear, cells, side, deck_radius,
		CREATURE_FLOOR_NORMAL_Y)
	print("%s arena ring: %d cells with ground probed round (%.0f, %.0f) r %.1f-%.1f in %d ms" % [
		"SUMMIT CROWN " + label, probed, origin.x, origin.z, RING_INNER_M, RING_OUTER_M,
		Time.get_ticks_msec() - started])
	for line: String in _describe_escapes(trainer_escapes, origin, ground, cells, side):
		_fail("%s trainer leaves the arena off the deck onto walkable ground: %s" % [label, line])
	print("SUMMIT CROWN %s arena ring: trainer (45 deg) escape routes %d" % [label, trainer_escapes.size()])
	var creature_lines := _describe_escapes(creature_escapes, origin, ground, cells, side)
	print("SUMMIT CROWN %s INFO: arena ring at a creature's 55 deg floor angle: %d escape routes%s" % [
		label, creature_lines.size(), "" if creature_lines.is_empty() else ": " + "; ".join(PackedStringArray(creature_lines))])


## Flood from the deck edge. Returns {escape cell index: parent chain end} as
## an Array of escape paths (each a PackedInt32Array, escape cell first).
func _flood_ring(ground: PackedFloat32Array, normal_y: PackedFloat32Array, clear: PackedByteArray,
		cells: int, side: int, deck_radius: float, floor_normal_y: float) -> Array:
	var parent := PackedInt32Array()
	parent.resize(side * side)
	parent.fill(-2)
	var queue := PackedInt32Array()
	for index in side * side:
		if _standable(index, ground, normal_y, clear, floor_normal_y) \
				and _cell_radius(index, cells, side) < deck_radius:
			parent[index] = -1
			queue.append(index)
	var escapes: Array = []
	var escaped_buckets: Dictionary = {}
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var ix := index % side
		var iz := index / side
		for dz in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dz == 0:
					continue
				var nx: int = ix + dx
				var nz: int = iz + dz
				if nx < 0 or nz < 0 or nx >= side or nz >= side:
					continue
				var next := nz * side + nx
				if parent[next] != -2 or not _standable(next, ground, normal_y, clear, floor_normal_y):
					continue
				if ground[next] > ground[index] + STEP_HEIGHT_M:
					continue
				var local := Vector2(float(nx - cells), float(nz - cells)) * RING_CELL_M
				var r := local.length()
				# The approach throat: the southern sector the perimeter leaves open.
				if r > deck_radius and local.y < 0.0 and absf(local.x) < THROAT_SIN * r:
					continue
				parent[next] = index
				if r >= RING_ESCAPE_M:
					# One reported route per 5 degrees of exit bearing.
					var bucket := int(floor(fposmod(rad_to_deg(atan2(local.x, local.y)), 360.0) / 5.0))
					if not escaped_buckets.has(bucket):
						escaped_buckets[bucket] = true
						var path := PackedInt32Array()
						var cursor := next
						while cursor >= 0:
							path.append(cursor)
							cursor = parent[cursor]
						escapes.append(path)
					continue
				queue.append(next)
	return escapes


func _standable(index: int, ground: PackedFloat32Array, normal_y: PackedFloat32Array,
		clear: PackedByteArray, floor_normal_y: float) -> bool:
	return not is_nan(ground[index]) and normal_y[index] >= floor_normal_y and clear[index] == 1


func _cell_radius(index: int, cells: int, side: int) -> float:
	return Vector2(float(index % side - cells), float(index / side - cells)).length() * RING_CELL_M


func _describe_escapes(escapes: Array, origin: Vector3, ground: PackedFloat32Array,
		cells: int, side: int) -> Array[String]:
	var lines: Array[String] = []
	for raw: Variant in escapes:
		var path: PackedInt32Array = raw
		var points: Array[String] = []
		# The deck-edge cell it left from, the cell where it crossed r 40 (the
		# masonry line), and the escape cell.
		var marks := {path[path.size() - 1]: true, path[0]: true}
		for cursor in path:
			if absf(_cell_radius(cursor, cells, side) - 40.0) < RING_CELL_M * 0.75:
				marks[cursor] = true
				break
		for i in range(path.size() - 1, -1, -1):
			var cursor := path[i]
			if not marks.has(cursor):
				continue
			var local := Vector2(float(cursor % side - cells), float(cursor / side - cells)) * RING_CELL_M
			points.append("(%.1f, %.2f, %.1f) r%.1f %.0fdeg" % [origin.x + local.x, ground[cursor],
				origin.z + local.y, local.length(), fposmod(rad_to_deg(atan2(local.x, local.y)), 360.0)])
		lines.append(" -> ".join(PackedStringArray(points)))
	return lines


## First StaticBody3D on the segment (people and non-static bodies passed).
func _static_ray(from: Vector3, to: Vector3, back_faces: bool) -> Dictionary:
	var exclude := _player_rids()
	for _attempt in 12:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = exclude
		query.hit_back_faces = back_faces
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return {}
		if hit["collider"] is StaticBody3D and not _is_person(hit["collider"]):
			return hit
		exclude.append(hit["rid"])
	return {}


## ---- (e) the perimeter masonry is solid ------------------------------------

func _check_masonry(label: String) -> void:
	var pieces: Array[MeshInstance3D] = []
	for node: Node in world.find_children("*", "MeshInstance3D", true, false):
		for prefix: String in MASONRY_LABELS:
			if str(node.name).begins_with(prefix):
				pieces.append(node as MeshInstance3D)
	var counts := {}
	var capsule := CapsuleShape3D.new()
	capsule.radius = TRAINER_RADIUS_M
	capsule.height = TRAINER_HEIGHT_M
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = capsule
	params.exclude = _player_rids()
	for piece in pieces:
		var kind := ""
		for prefix: String in MASONRY_LABELS:
			if str(piece.name).begins_with(prefix):
				kind = prefix
		counts[kind] = int(counts.get(kind, 0)) + 1
		var xform := piece.global_transform
		var faces := piece.mesh.get_faces()
		var tried := 0
		var passed := 0
		var sample_failures: Array[String] = []
		var stride := maxi(1, faces.size() / 3 / 24)
		for t in range(0, faces.size() / 3, stride):
			var a := xform * faces[t * 3]
			var b := xform * faces[t * 3 + 1]
			var c := xform * faces[t * 3 + 2]
			# Godot front faces wind clockwise, so the drawn outward normal is
			# (c - a) x (b - a).
			var normal := (c - a).cross(b - a)
			if normal.length_squared() < 0.0001:
				continue
			normal = normal.normalized()
			var outward := Vector3(normal.x, 0.0, normal.z)
			if outward.length() < 0.95:
				continue # not a near-vertical face
			outward = outward.normalized()
			var centroid := (a + b + c) / 3.0
			var start := centroid + outward * 1.2
			# A face whose 1.2 m-out start is still inside the piece's own
			# footprint faces its hollow interior, a brick's flank along the
			# wall or an arch's opening: not a face a trainer walks into.
			var start_local := xform.affine_inverse() * start
			var local_box := piece.get_aabb()
			if start_local.x > local_box.position.x and start_local.x < local_box.end.x \
					and start_local.z > local_box.position.z and start_local.z < local_box.end.z:
				continue
			var floor_hit := _static_ray(Vector3(start.x, CROWN_Y + 3.0, start.z),
				Vector3(start.x, CROWN_Y - 12.0, start.z), false)
			var ground_y := (floor_hit["position"] as Vector3).y if not floor_hit.is_empty() \
				else (xform * piece.get_aabb().position).y
			var band_low := ground_y + STEP_HEIGHT_M + 0.01
			var band_high := band_low + TRAINER_HEIGHT_M
			if maxf(a.y, maxf(b.y, c.y)) < band_low or minf(a.y, minf(b.y, c.y)) > band_high:
				continue # the face does not reach a trainer's body there
			start.y = band_low + TRAINER_HEIGHT_M * 0.5
			params.transform = Transform3D(Basis.IDENTITY, start)
			params.motion = -outward * 2.0
			var motion := space.cast_motion(params)
			tried += 1
			# Contact is at 1.2 - 0.4 = 0.8 m of the 2 m sweep; nothing stopping
			# it leaves the capsule centre past the face.
			if not motion.is_empty() and float(motion[0]) <= 0.5:
				passed += 1
			elif sample_failures.size() < 2:
				sample_failures.append("face at (%.1f, %.1f, %.1f) swept %.2f of 2 m" % [
					centroid.x, centroid.y, centroid.z, 1.0 if motion.is_empty() else float(motion[0])])
		var where := xform * piece.get_aabb().get_center()
		var name := "%s/%s" % [piece.get_parent().name, piece.name]
		if tried == 0:
			print("SUMMIT CROWN %s INFO: %s at (%.1f, %.1f) has no exterior face in a trainer's band (its top overhangs its base)" % [
				label, name, where.x, where.z])
		elif passed < tried:
			_fail("%s %s at (%.1f, %.1f): a capsule passes %d of %d visible masonry faces (%s)" % [
				label, name, where.x, where.z, tried - passed, tried, "; ".join(PackedStringArray(sample_failures))])
	print("SUMMIT CROWN %s masonry: %s pieces swept" % [label, counts])
	if int(counts.get("RetainedMasonry", 0)) == 0 or int(counts.get("PerimeterWatchTower", 0)) == 0:
		_fail("%s the arena perimeter masonry was not found (%s)" % [label, counts])


## ---- (f) no hidden road collider over walkable crown ------------------------

func _check_road_boxes(label: String) -> void:
	var lines: Array = world.get("_all_route_lines")
	var samples := 0
	var walls := 0
	for raw: Variant in lines:
		var line: Dictionary = raw
		var route := str(line["route_id"])
		if route.begins_with("crown:"):
			continue
		var a: Vector3 = line["a"]
		var b: Vector3 = line["b"]
		var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
		if flat.length() < 0.01:
			continue
		var right := Vector3.UP.cross(flat.normalized()).normalized()
		var steps := maxi(1, ceili(flat.length()))
		for offset: float in [-(ROAD_BOX_HALF_M + TRAINER_RADIUS_M), ROAD_BOX_HALF_M + TRAINER_RADIUS_M]:
			var run_from := Vector3.INF
			var run_to := Vector3.ZERO
			var worst := 0.0
			var worst_at := Vector3.ZERO
			for step in steps + 1:
				var centre := a.lerp(b, float(step) / float(steps))
				var at := centre + right * offset
				var is_wall := false
				if not is_nan(_drawn_height(at.x, at.z)):
					samples += 1
					var hit := _static_ray(Vector3(at.x, centre.y + 0.3, at.z),
						Vector3(at.x, centre.y - 12.0, at.z), false)
					# Any walkable static ground there counts (the crown, a pad's
					# landing crown, a shoulder), not only the carved crown.
					if not hit.is_empty() and (hit["normal"] as Vector3).y >= TRAINER_FLOOR_NORMAL_Y:
						var rise := centre.y - (hit["position"] as Vector3).y
						if rise > STEP_HEIGHT_M:
							is_wall = true
							if rise > worst:
								worst = rise
								worst_at = hit["position"]
				if is_wall:
					if run_from == Vector3.INF:
						run_from = at
					run_to = at
				if (not is_wall or step == steps) and run_from != Vector3.INF:
					walls += 1
					_fail("%s %s: the hidden %.0f m road box stands up to %.2f m over walkable crown from (%.1f, %.1f) to (%.1f, %.1f), worst at %s" % [
						label, route, ROAD_BOX_HALF_M * 2.0, worst, run_from.x, run_from.z, run_to.x, run_to.z, worst_at])
					run_from = Vector3.INF
					worst = 0.0
	print("SUMMIT CROWN %s road boxes: %d samples beside ribbons over the crown, %d wall runs" % [
		label, samples, walls])
