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


func _finish() -> void:
	if _failures.is_empty():
		print("WARRENS FIXTURE OK")
		quit(0)
		return
	for f: String in _failures:
		push_error("WARRENS FIXTURE: %s" % f)
	quit(1)
