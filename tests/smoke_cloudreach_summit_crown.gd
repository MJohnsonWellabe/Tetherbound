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
##      summit_overlook_loop, sampled every 2 m at -2.5/0/+2.5 m across, where
##      the crown is drawn above that XZ. At the ribbon's own top (the line
##      height, `_all_route_lines`) a short down ray must find the road; an
##      upward ray from +0.5 m to +2.3 m (trainer 1.8 m + 0.5 m) must not meet
##      the `CarvedCrown` collider (FAIL: a new ceiling) -- any OTHER static
##      collider there is printed as pre-existing; and a 0.4 x 1.8 m capsule
##      lifted 0.25 m off the ribbon must overlap no static collider on the
##      centreline and never the `CarvedCrown` anywhere (another collider at
##      the +-2.5 m road edge is printed, not failed: the east route wing's
##      south block already overhangs the diagonal road's edge near the gate,
##      which this carve neither causes nor changes).
##  (c) The trainer, placed 1 m above the summit-approach stand (100, 5290),
##      must be on the CROWN (is_on_floor, y within 1.5 m of 1160, XZ within
##      2 m of the stand) within 600 physics frames.
##
## Fixtures, disclosed: the summit route's story flags are set directly
## (as smoke_cloudreach_summit_road does), and (c) makes one position write.
## Nothing here walks: smoke_cloudreach_summit_road and
## smoke_cloudreach_summit_bivouac_join walk both carved roads with real stick
## input and must be run alongside this.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const GRID_MIN := Vector2(20.0, 5140.0)
const GRID_MAX := Vector2(180.0, 5410.0)
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

var world: Node3D
var player: CharacterBody3D
var space: PhysicsDirectSpaceState3D
var failures: Array[String] = []
var crown_body: StaticBody3D
var triangles := PackedVector3Array() # world space, 3 per triangle
var buckets: Dictionary = {} # Vector2i -> PackedInt32Array of triangle indices


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
	_check_grid()
	_check_centroids()
	_check_roads()
	await _check_stand_landing()
	_finish()


func _finish() -> void:
	for line: String in failures:
		printerr("SUMMIT CROWN FAIL: " + line)
	for check: String in ["(a)", "(b)", "(c)"]:
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
	for t in triangles.size() / 3:
		var centroid := (triangles[t * 3] + triangles[t * 3 + 1] + triangles[t * 3 + 2]) / 3.0
		if centroid.x < GRID_MIN.x or centroid.x > GRID_MAX.x \
				or centroid.z < GRID_MIN.y or centroid.z > GRID_MAX.y:
			continue
		probed += 1
		var exclude: Array[RID] = [player.get_rid()]
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
	print("SUMMIT CROWN (a): %d CarvedCrown centroids probed, %d under another surface" % [probed, covered])


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
			for offset: float in [-2.5, 0.0, 2.5]:
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
		if path.contains("/CloudreachPeople/"):
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
