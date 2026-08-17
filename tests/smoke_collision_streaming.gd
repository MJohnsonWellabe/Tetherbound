extends SceneTree

## COLL1 / §8.3: does scatter collision actually stream, or is every prop's
## `CollisionShape3D` resident all the time regardless of the player?
##
##   godot --headless --path . --script tests/smoke_collision_streaming.gd
##
## Why this exists as its own file rather than trusting the traversal walk:
## the prior attempt at terrain collision streaming (`ralph/OW5-stream`)
## shipped a test that "passed on reverted code — the collision bubble
## follows the camera, which follows the player, so the test could not tell
## the difference" (coordinator's own words, `ralph/NOTES.md`). Any check
## that only walks the player around and asserts "collision exists near the
## player" passes identically whether streaming is real or whether
## everything is just eagerly resident all the time — the player is always
## near SOME collision either way. To actually distinguish the two, this
## test asserts something that is TRUE under streaming and FALSE under
## eager/whole-world collision:
##
##   1. Immediately after boot, fewer collidable placements are resident
##      than exist in the world total. (Eager: resident == total, always.)
##   2. Moving the streaming centre away from a spot that was resident, and
##      NOT re-visiting it, makes it stop being resident. (Eager: nothing
##      is ever freed, so this is never true.)
##   3. Moving the streaming centre TO a spot that was not resident makes it
##      become resident. (Eager: it was already resident, so this proves
##      nothing on its own — check 1 is what rules eager out; this one
##      proves the mechanism is bidirectional, not a one-way leak.)
##
## Deliberately does not reuse `update_collision_streaming`'s normal
## COLLISION_STREAM_RADIUS-driven call path in a way that could be satisfied
## by "everything is always within radius on this small world" — it checks
## two points far enough apart (world corners) that COLLISION_STREAM_RADIUS
## (100m) cannot cover both from either one.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
## Opposite corners of the current ±256m playground -- far enough apart that
## COLLISION_STREAM_RADIUS (100m, vegetation.gd) cannot reach from one to the
## other, so a placement resident at one is provably not "coincidentally
## still in range" from the other.
const CORNER_A := Vector3(-200.0, 0.0, -200.0)
const CORNER_B := Vector3(200.0, 0.0, 200.0)


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var vegetation: Node = world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		print("collision-streaming FAIL: no Vegetation node in the scene")
		quit(1)
		return
	if not vegetation.has_method("update_collision_streaming"):
		print("collision-streaming FAIL: vegetation.gd has no update_collision_streaming -- streaming is not implemented")
		quit(1)
		return

	var failures: Array[String] = []

	# --- check 1: not everything is resident at boot. ---
	var total: int = int(vegetation.call("collidable_count"))
	var resident_at_boot: int = int(vegetation.call("collision_resident_count"))
	print("collidable placements: %d total, %d resident at boot" % [total, resident_at_boot])
	if total == 0:
		failures.append("no collidable placements at all -- the rocks/trees layers may not have scattered")
	elif resident_at_boot >= total:
		failures.append(
			"%d of %d collidable placements are resident at boot -- every collider is loaded regardless of the player, collision is not streaming" % [
				resident_at_boot, total])

	# --- check 2/3: streaming a far corner in frees the OTHER corner and
	# loads this one. ---
	vegetation.call("update_collision_streaming", CORNER_A)
	for i in 5:
		await physics_frame
	var resident_at_a: int = int(vegetation.call("collision_resident_count"))
	print("resident after centring on corner A %s: %d" % [CORNER_A, resident_at_a])

	vegetation.call("update_collision_streaming", CORNER_B)
	for i in 5:
		await physics_frame
	var resident_at_b: int = int(vegetation.call("collision_resident_count"))
	print("resident after centring on corner B %s: %d" % [CORNER_B, resident_at_b])

	# Both corners are inside the ±256m world and the scatter is dense enough
	# (thousands of instances, §8.3) that SOME collidable prop sits within
	# COLLISION_STREAM_RADIUS of any given point unless the world is nearly
	# empty -- so a genuinely streaming implementation loads something at
	# each corner, and an eager implementation still shows the same resident
	# count at both corners (== total) because nothing was ever freed.
	if resident_at_a <= 0:
		failures.append("nothing streamed in at corner A %s -- either the corner has no props nearby or streaming is broken" % CORNER_A)
	if resident_at_b <= 0:
		failures.append("nothing streamed in at corner B %s -- either the corner has no props nearby or streaming is broken" % CORNER_B)
	if total > 0 and resident_at_a >= total and resident_at_b >= total:
		failures.append("resident count never dropped below the world total when the streaming centre moved -- nothing is ever being freed")

	print("")
	if failures.is_empty():
		print("collision-streaming: OK — %d/%d resident at boot, and the resident set actually changes (%d at corner A, %d at corner B) as the streaming centre moves." % [
			resident_at_boot, total, resident_at_a, resident_at_b])
		quit(0)
	else:
		for line in failures:
			print("collision-streaming FAIL: %s" % line)
		quit(1)
