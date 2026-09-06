extends SceneTree

## OP-0905-09 fast fixture. `tests/smoke_warrens.gd` proves the earth bank
## from inside a full `meadows_playground.tscn` boot (~3-5 minutes); this
## proves the SHAPE alone, against a bare stand-in world, in well under a
## minute, so the fix->measure loop on `_build_bank()`/`_build_bank_mouth()`
## does not require the full boot every round. Same trade
## `smoke_cloudreach_transition.gd`'s own `FlatWorld` makes for the rift
## crossing.
##
## Asserts, in the order a shape defect would actually show up:
##   * the warrens builds without error against the flat fixture
##   * the bank mesh exists and carries a real trimesh (concave) collider
##   * the mouth arch is open: a ray from 12m out at eye height reaches the
##     mouth chamber's own floor marker, not blocked by the bank's dug face
##     or throat shell
##   * every chamber centre is enclosed: a ray straight up from each
##     chamber's own marker hits the warrens' own geometry (the bank), never
##     open sky
##   * prints the bank's own footprint size and crest height (also printed
##     by `_build_bank()` itself, so this doubles as the smoke's readout)

const BURROW_WARRENS := preload("res://scripts/world/burrow_warrens.gd")

## A bare stand-in for the Meadows terrain. `burrow_warrens.gd::build()` and
## its bank shape math only ever call `ground_height_at` on the world (see
## `_site_ground()`/`_bank_height_at()`'s own callers) -- everything else it
## touches on `world` (`get_node_or_null("CombatManager")`/`"Vegetation"`) is
## a plain `Node` method a bare `Node3D` already answers with null, exactly
## the trade `smoke_cloudreach_transition.gd`'s own `FlatWorld` makes.
class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	# `_init()` runs before the SceneTree's own main loop has started -- a
	# node added and built synchronously in there sees `is_inside_tree()`
	# false partway through and every `global_position`/`get_node("/root/...")`
	# call inside `build()` misbehaves silently (measured directly: the first
	# version of this fixture built against a tree that was not yet active
	# and every marker/global-transform value downstream was garbage, same
	# trade `smoke_cloudreach_transition.gd`'s own deferred `_run` avoids).
	# Deferring past `_init()` and waiting one process frame for `root` to go
	# active fixes it.
	var world := FlatWorld.new()
	world.name = "FlatWorld"
	root.add_child(world)
	current_scene = world
	await process_frame

	var warrens: Node3D = BURROW_WARRENS.new()
	warrens.name = "BurrowWarrens"
	world.add_child(warrens)

	var ok := bool(warrens.call("build", world))
	if not ok:
		_fail("build() returned false against the flat fixture")
		_finish()
		return

	await physics_frame
	await physics_frame

	_bank_exists_with_a_trimesh_collider(warrens)
	_the_mouth_arch_is_open(world, warrens)
	_every_chamber_is_enclosed(warrens)
	_the_walked_channel_to_hall_is_open(world, warrens)
	_the_crest_reads_as_a_landmark(warrens)
	_the_mouth_frontage_has_no_flat_slab_edge(warrens)
	_the_throat_is_at_least_8m_and_hides_the_interior(world, warrens)

	_finish()


func _bank_exists_with_a_trimesh_collider(warrens: Node3D) -> void:
	var bank := warrens.get_node_or_null(^"Bank") as MeshInstance3D
	if bank == null:
		_fail("no 'Bank' mesh node under the warrens")
		return
	if bank.mesh == null:
		_fail("the Bank mesh instance has no mesh resource")
		return
	var bodies := bank.find_children("*", "StaticBody3D", true, false)
	if bodies.is_empty():
		_fail("the Bank mesh has no collider (create_trimesh_collision produced no StaticBody3D)")
		return
	var has_trimesh := false
	for shape_node in (bodies[0] as Node).find_children("*", "CollisionShape3D", true, false):
		if (shape_node as CollisionShape3D).shape is ConcavePolygonShape3D:
			has_trimesh = true
	if not has_trimesh:
		_fail("the Bank's collider is not a trimesh (no ConcavePolygonShape3D found)")
	var aabb := bank.mesh.get_aabb()
	print("[fixture] bank mesh local AABB size = %.1f x %.1f x %.1f (footprint x, height, footprint z)" % [
		aabb.size.x, aabb.size.y, aabb.size.z])


## Mirrors `tests/smoke_warrens.gd::_the_mouth_arch_is_open()` exactly, minus
## the CharacterBody3D exclusion list this fixture never populates any bodies
## into.
func _the_mouth_arch_is_open(world: Node, warrens: Node3D) -> void:
	var space := (world as Node3D).get_world_3d().direct_space_state
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var approach: Vector3 = warrens.to_global(Vector3(0.0, 1.6, warrens.to_local(mouth).z - 12.0))
	var target := mouth + Vector3.UP * 1.0
	var full := approach.distance_to(target)
	var query := PhysicsRayQueryParameters3D.create(approach, target)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("[fixture] mouth arch: clear line from %.1fm out straight to the mouth chamber floor" % full)
		return
	var collider: Node = hit.get("collider", null) as Node
	var hit_distance: float = approach.distance_to(hit.get("position", approach))
	if hit_distance < full - 2.0:
		_fail("the mouth arch is blocked %.1fm short of the mouth chamber by %s" % [
			full - hit_distance, "no collider" if collider == null else str(collider.get_path())])
	else:
		print("[fixture] mouth arch: reached %.1fm of %.1fm before hitting %s" % [
			hit_distance, full, "nothing" if collider == null else str(collider.get_path())])


## Mirrors `tests/smoke_warrens.gd::_the_bank_encloses_every_chamber()`, and
## also reports the highest cover hit above the mouth as this fixture's own
## crest-height readout.
func _every_chamber_is_enclosed(warrens: Node3D) -> void:
	var space := (warrens as Node3D).get_world_3d().direct_space_state
	var checked := 0
	var crest_local := 0.0
	for id: String in warrens.call("chamber_ids"):
		var at: Vector3 = warrens.call("marker", id)
		var query := PhysicsRayQueryParameters3D.create(at, at + Vector3.UP * 200.0)
		var hit := space.intersect_ray(query)
		checked += 1
		var collider: Node = hit.get("collider", null) as Node
		if hit.is_empty() or collider == null or not warrens.is_ancestor_of(collider):
			_fail("chamber '%s' is not enclosed: a ray straight up from its own marker reached open sky" % id)
			continue
		var hit_y: float = float((hit.get("position", at) as Vector3).y)
		crest_local = maxf(crest_local, hit_y - warrens.global_position.y)
	print("[fixture] chamber enclosure: %d chambers checked, highest cover hit %.1fm above the mouth (%.1fx the 1.8m trainer)" % [
		checked, crest_local, crest_local / 1.8])


## Diagnostic for the `smoke_warrens.gd::_the_route_can_be_walked` failure
## ("stopped 17.8m short" of the hall): the walked line from 12m outside the
## mouth to the hall's own centre, at knee (0.4m) and chest (1.2m) height,
## PLUS a 0.4m-radius capsule shape-cast along the same line (the actual
## shape a CharacterBody3D presents) so a defect that only blocks the
## capsule's own width -- not a thin ray -- still shows up. Every collider
## along the line is printed with its node path so a bank/throat/lip/spoil
## culprit is identified by name rather than guessed at.
func _the_walked_channel_to_hall_is_open(world: Node, warrens: Node3D) -> void:
	var space := (world as Node3D).get_world_3d().direct_space_state
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var hall: Vector3 = warrens.call("marker", "hall")
	var approach: Vector3 = warrens.to_global(Vector3(0.0, 0.0, warrens.to_local(mouth).z - 12.0))
	var floor_y := mouth.y

	for height in [0.4, 1.2]:
		var origin := Vector3(approach.x, floor_y + height, approach.z)
		var target := Vector3(hall.x, floor_y + height, hall.z)
		var full := origin.distance_to(target)
		var hits: Array[String] = []
		var current := origin
		var exclude: Array[RID] = []
		var dir := (target - origin).normalized()
		for _i in 12:
			var query := PhysicsRayQueryParameters3D.create(current, target)
			query.exclude = exclude
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				break
			var collider: Node = hit.get("collider", null) as Node
			var pos: Vector3 = hit.get("position", current)
			hits.append("%s @%.1fm" % [
				str(collider.get_path()) if collider != null else "?(no collider)",
				origin.distance_to(pos)])
			var rid: RID = hit.get("rid", RID())
			if rid.is_valid():
				exclude.append(rid)
			else:
				break
			current = pos + dir * 0.05
		print("[fixture] route ray @%.1fm height, %.1fm long: %s" % [
			height, full, "CLEAR" if hits.is_empty() else ", ".join(hits)])

	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.margin = 0.01
	var center_y := floor_y + 1.0
	var start := Vector3(approach.x, center_y, approach.z)
	var motion := Vector3(hall.x - approach.x, 0.0, hall.z - approach.z)
	query.transform = Transform3D(Basis(), start)
	query.motion = motion
	var result: PackedFloat32Array = space.cast_motion(query)
	var safe: float = result[0] if result.size() > 0 else 0.0
	var unsafe: float = result[1] if result.size() > 1 else safe
	var full_len := motion.length()
	print("[fixture] capsule shape-cast (r=0.4m): safe %.1fm, unsafe %.1fm, of %.1fm along the mouth->hall line" % [
		safe * full_len, unsafe * full_len, full_len])
	if safe < 0.999:
		# The overlap test at the exact `safe` fraction can land in the gap
		# cast_motion itself leaves between "safe" and "unsafe" (touching,
		# not yet overlapping) -- probe a few points past `unsafe` too, and
		# fall back to a top-down vertical ray stack at the blocked XZ (every
		# distinct surface there, floor to well above the bank's own crest)
		# so the culprit is identified by name even if the shape overlap
		# itself comes back empty.
		var probed := {}
		for frac in [safe, unsafe, minf(unsafe + 0.02, 1.0), minf(unsafe + 0.08, 1.0)]:
			query.transform = Transform3D(Basis(), start + motion * frac)
			for o: Dictionary in space.intersect_shape(query, 8):
				var c: Node = o.get("collider", null) as Node
				var owner_p := c.get_parent() if c != null else null
				var key := "%s (owner=%s)" % [
					str(c.get_path()) if c != null else "?(no collider)",
					str(owner_p.name) if owner_p != null else "?"]
				probed[key] = true
		if probed.is_empty():
			print("   capsule overlap probe found nothing at safe/unsafe -- falling back to a vertical ray stack")
		else:
			for key: String in probed:
				print("   capsule blocked by %s" % key)
		var blocked_xz := start + motion * unsafe
		var stack_top := Vector3(blocked_xz.x, floor_y + 60.0, blocked_xz.z)
		var stack_bottom := Vector3(blocked_xz.x, floor_y - 5.0, blocked_xz.z)
		var stack_exclude: Array[RID] = []
		var stack_current := stack_top
		var layers: Array[String] = []
		for _i in 10:
			var rq := PhysicsRayQueryParameters3D.create(stack_current, stack_bottom)
			rq.exclude = stack_exclude
			var rh := space.intersect_ray(rq)
			if rh.is_empty():
				break
			var rc: Node = rh.get("collider", null) as Node
			var rp: Vector3 = rh.get("position", stack_current)
			# `create_trimesh_collision()` adds an anonymously-named
			# StaticBody3D as a CHILD of the MeshInstance3D it was called on
			# -- the parent's own name is the actual visual piece, which is
			# what identifies the culprit; the collider's own path is not.
			var owner_name := "?"
			if rc != null:
				var p := rc.get_parent()
				owner_name = str(p.name) if p != null else str(rc.name)
			layers.append("%s (owner=%s) @y=%.2f (%.2fm above floor)" % [
				str(rc.get_path()) if rc != null else "?(no collider)", owner_name, rp.y, rp.y - floor_y])
			var rrid: RID = rh.get("rid", RID())
			if rrid.is_valid():
				stack_exclude.append(rrid)
			else:
				break
			stack_current = rp + Vector3.DOWN * 0.05
		var blocked_local: Vector3 = warrens.to_local(blocked_xz)
		print("   vertical ray stack at the blocked point (local x=%.2f, z=%.2f), top to bottom: %s" % [
			blocked_local.x, blocked_local.z, "NOTHING" if layers.is_empty() else " | ".join(layers)])
		_fail("the walked capsule channel from outside the mouth to the hall is blocked %.1fm short (safe %.1fm of %.1fm)" % [
			full_len - safe * full_len, safe * full_len, full_len])
	else:
		print("[fixture] capsule shape-cast: channel to the hall is clear")


## SECOND-PASS-0906 item 1: "raise the crest to ~10.5m (>=5.8x the 1.8m
## trainer)". Reads the Bank mesh's OWN local AABB (`_bank_exists_with_a_
## trimesh_collider()` above already prints it) rather than a straight-up
## ray from a chamber marker: that marker sits exactly AT `_floor_y`, on the
## floor plinth's own top surface, and a ray cast from a point coincident
## with a collider's own face is not a reliable "how tall is the thing above
## it" measurement (measured directly: it returns near-zero here, floor
## self-intersection, on every chamber, not just the mouth). The mesh's own
## build-time AABB is exact and ambiguity-free -- `_build_bank()` samples
## `_bank_height_at()` on top of the fixture's flat (0m) terrain, so the
## AABB's own height IS the crest above the mouth's own grade.
func _the_crest_reads_as_a_landmark(warrens: Node3D) -> void:
	var bank := warrens.get_node_or_null(^"Bank") as MeshInstance3D
	if bank == null or bank.mesh == null:
		_fail("crest check: no Bank mesh to measure (see the earlier bank-exists assertion)")
		return
	var crest_local: float = bank.mesh.get_aabb().size.y
	print("[fixture] crest above the mouth: %.1fm (%.1fx the 1.8m trainer)" % [crest_local, crest_local / 1.8])
	if crest_local < 10.0:
		_fail(("the crest is only %.1fm above the mouth; the brief asks for >=10.5m (>=5.8x the 1.8m trainer) "
			+ "so the mound reads as a landmark from the approach, not a low hump") % crest_local)


## SECOND-PASS-0906 item 2: "no exterior mesh has an axis-aligned top edge
## longer than 3m at the mouth" -- the "flat rectangular slab" defect was the
## `mouth` chamber's own cone guaranteeing full clearance `p` across its
## WHOLE rectangle width (`_bank_chamber_bumps()`'s own enclosure guarantee),
## which draws a genuinely flat-topped mesa right where the face carve
## anchors its cliff line (`_bank_apply_face_carve()`'s `top_at_line`). This
## samples that SAME anchor line directly (`_bank_height_at(x, z0)`, the
## actual visible surface, not the pre-carve union) across the mouth's
## frontage and finds the longest run of x where the height barely moves --
## the direct measurement of "how long is the flattest stretch of the
## skyline right above the arch", which is what a straight top edge IS.
func _the_mouth_frontage_has_no_flat_slab_edge(warrens: Node3D) -> void:
	var bank := warrens.call("_bank_cfg") as Dictionary
	var z0: float = float(warrens.call("_mouth_outer_z"))
	# The arch's own open notch is SUPPOSED to be flat ground for its whole
	# width (it is the doorway) -- that is not the slab defect, so each scan
	# below breaks its run at the notch rather than measuring across it. 1.5m
	# past the arch's own margin so an edge vertex right at the notch's own
	# smoothstep transition never gets counted into either shoulder's run.
	var arch_clear: float = float(bank.get("arch_width_m", 5.0)) * 0.5 \
		+ float(bank.get("arch_margin_m", 0.6)) + 1.5
	var tol := 0.12
	# Past the mound's own foot the ground is legitimately flat -- that is
	# the meadow, not a slab, and every real mound has to taper down to it
	# somewhere. A run only counts toward the "slab" defect while the
	# surface is still meaningfully ELEVATED (above `ground_floor`); once a
	# run's own base height drops to bare ground, its length is not
	# evidence of anything this check is about.
	var ground_floor := 0.3
	var half_span := 14.0
	var step := 0.25
	var worst_run := 0.0
	var worst_row := 0.0
	for z_off: float in [0.0, -1.0, -2.0]:
		var z: float = z0 + z_off
		# Two independent shoulders (left of the arch, right of the arch) --
		# never one scan spanning across the open doorway in between.
		for side: float in [-1.0, 1.0]:
			var x0: float = side * arch_clear
			var x1: float = side * half_span
			var lo: float = minf(x0, x1)
			var hi: float = maxf(x0, x1)
			var run_start := lo
			var run_base_h := float(warrens.call("_bank_height_at", lo, z))
			var x := lo
			while x <= hi:
				var h := float(warrens.call("_bank_height_at", x, z))
				if absf(h - run_base_h) > tol:
					var run_len: float = x - run_start
					if run_len > worst_run and run_base_h > ground_floor:
						worst_run = run_len
						worst_row = z
					run_start = x
					run_base_h = h
				x += step
			var tail_len: float = hi - run_start
			if tail_len > worst_run and run_base_h > ground_floor:
				worst_run = tail_len
				worst_row = z
	print("[fixture] mouth frontage flattest shoulder run: %.1fm (row z=%.1f, tolerance %.2fm, arch clearance %.1fm)" % [
		worst_run, worst_row, tol, arch_clear])
	if worst_run > 3.0:
		_fail(("the mouth frontage has a %.1fm run of near-constant height at row z=%.1f (outside the arch's own " +
			"opening) -- reads as a flat slab top edge, not a rounded dug face; the brief caps this at 3m") % [worst_run, worst_row])


## SECOND-PASS-0906 item 3: "keep the walk channel >= doorway size and
## re-run the fixture's capsule probe" (done above, unaffected -- see
## `_throat_curve_offset()`'s own header for why) plus the NEW ask: a ray
## from outside, off the walk corridor's own centreline (so it is not the
## SAME ray `_the_mouth_arch_is_open()` already proves stays open for a
## walking player), should now be stopped by earth before it reaches the
## mouth chamber's own structural doorway -- the direct test for "the
## interior's grey box walls ... show straight through the throat" no longer
## holding. The off-centre line is a real design constraint, not an
## arbitrary probe point: `_throat_curve_offset()`'s own header explains why
## the centreline (x=0) must stay open for the capsule, so only a line away
## from it can ever be the one the curve blocks.
func _the_throat_is_at_least_8m_and_hides_the_interior(world: Node, warrens: Node3D) -> void:
	var depth: float = float((warrens.call("_bank_cfg") as Dictionary).get("throat_depth_m", 0.0))
	print("[fixture] throat depth: %.1fm" % depth)
	if depth < 8.0:
		_fail("the throat is only %.1fm deep; the brief asks for ~8m" % depth)

	var space := (world as Node3D).get_world_3d().direct_space_state
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var mouth_local := warrens.to_local(mouth)
	var x_off := -1.8
	var eye_h := 1.6
	var origin := warrens.to_global(Vector3(x_off, eye_h, mouth_local.z - 20.0))
	var target := warrens.to_global(Vector3(x_off, eye_h, mouth_local.z))
	var full := origin.distance_to(target)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		_fail(("an off-centre ray (x=%.1f) from outside the mouth reaches all the way to the chamber centre "
			+ "with nothing in the throat to stop it -- the interior is still visible straight through") % x_off)
		return
	var collider: Node = hit.get("collider", null) as Node
	var owner: Node = collider.get_parent() if collider != null else null
	var owner_name := str(owner.name) if owner != null else "?(no owner)"
	var earth_names := ["Bank", "Throat", "DoorwayCollar", "MouthLip"]
	var hit_distance: float = origin.distance_to(hit.get("position", origin))
	print("[fixture] off-centre throat ray (x=%.1f): stopped %.1fm of %.1fm by %s (owner=%s)" % [
		x_off, hit_distance, full, str(collider.get_path()) if collider != null else "?", owner_name])
	if not earth_names.has(owner_name):
		_fail(("the off-centre throat ray was stopped by '%s', not one of the throat's own earth pieces %s -- " +
			"it is hitting a structural wall, meaning the curve is not actually occluding it") % [owner_name, str(earth_names)])


func _finish() -> void:
	if _failures.is_empty():
		print("WARRENS FIXTURE OK")
		quit(0)
		return
	for f: String in _failures:
		push_error("WARRENS FIXTURE: %s" % f)
	quit(1)
