extends SceneTree

## W05-TREELINE-0904, regression diagnosis. Reproduces `tests/smoke_aggression.gd`'s
## walk toward the aggressor (Galecrest) with the same start, the same held input and
## the same unstick escape, and at the stall NAMES the body that is blocking it --
## `test_move` against the current heading (the direct answer) plus a sphere query
## listing every collider within 4 m and each one's actual shape dimensions.
##
##   godot --headless --path . --script tools/_probe_walk_block_0905.gd
##
## Written because the landing lane attributed a smoke_aggression failure to this
## lane's tree-collider growth, while the test's OWN header records the same walk
## historically stalling at ~40 m against the Terrain3D node and no tree at all.
## Naming the collider decides it rather than assuming.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const WALK_FRAMES := 4000
const UNSTICK_AFTER_FRAMES := 20
const UNSTICK_STEER_RAD := 1.3
const DUMP_AT_STUCK := 120

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _director: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _director == null:
		print("PROBE FAIL: missing Player/CameraRig/EncounterDirector")
		quit(1)
		return

	var start := Vector3(40.0, 0.0, -62.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO

	var wild: Node3D = _director.call("aggressive_creature") as Node3D
	if wild == null:
		print("PROBE FAIL: no aggressive creature spawned")
		quit(1)
		return
	print("PROBE start=%v galecrest=%v straight-line=%.1f m" % [
		start, wild.global_position, start.distance_to(wild.global_position)])

	var stuck := 0
	var last := _player.global_position
	var dumped := 0
	var heading := Vector3.FORWARD
	for i in WALK_FRAMES:
		var to := wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= 10.0:
			print("PROBE reached 10 m at frame %d" % i)
			break
		heading = to.normalized()
		if stuck > UNSTICK_AFTER_FRAMES:
			var phase := int((stuck - UNSTICK_AFTER_FRAMES) / 30.0) % 2
			heading = heading.rotated(Vector3.UP, (1.0 if phase == 0 else -1.0) * UNSTICK_STEER_RAD)
		_rig.set("yaw", atan2(-heading.x, -heading.z))
		Input.action_press("move_forward")
		await physics_frame
		if _player.global_position.distance_to(last) < 0.05:
			stuck += 1
		else:
			stuck = 0
		last = _player.global_position
		if stuck == DUMP_AT_STUCK and dumped < 3:
			dumped += 1
			_dump(wild, heading, "stalled %d frames (dump %d)" % [stuck, dumped])
	Input.action_release("move_forward")
	_dump(wild, heading, "final")
	quit(0)


func _dump(wild: Node3D, heading: Vector3, label: String) -> void:
	var p := _player.global_position
	print("\n=== %s ===" % label)
	print("player=%v  dist_to_galecrest=%.2f m  on_wall=%s  on_floor=%s  vel=%v" % [
		p, p.distance_to(wild.global_position), str(_player.is_on_wall()),
		str(_player.is_on_floor()), _player.velocity])
	if _player.is_on_wall():
		print("wall_normal=%v" % _player.get_wall_normal())
	print("ground slope here = %.1f deg" % _slope_at(p))

	# The direct answer: what does a step along the current heading hit?
	for step in [0.5, 1.0, 2.0]:
		var hit := KinematicCollision3D.new()
		if _player.test_move(_player.global_transform, heading * step, hit):
			var collider: Object = hit.get_collider()
			var node := collider as Node3D
			print("  test_move %.1f m BLOCKED by %s (%s) at %v" % [
				step, ("?" if node == null else str(node.name)),
				("?" if collider == null else collider.get_class()),
				(Vector3.ZERO if node == null else node.global_position)])
		else:
			print("  test_move %.1f m clear" % step)

	# Everything nearby, with its real shape size.
	var space := _player.get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = 4.0
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = sphere
	params.transform = Transform3D(Basis(), p)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.collision_mask = 0xFFFFFFFF
	var hits: Array[Dictionary] = space.intersect_shape(params, 64)
	print("  colliders within 4.0 m: %d" % hits.size())
	for hit_entry: Dictionary in hits:
		var collider: Object = hit_entry.get("collider")
		var node := collider as Node3D
		if node == null:
			continue
		print("    %-38s %-16s dist=%.2f pos=%v" % [
			str(node.name), collider.get_class(), node.global_position.distance_to(p),
			node.global_position])
		for child in node.get_children():
			var cs := child as CollisionShape3D
			if cs == null or cs.shape == null:
				continue
			print("        %s" % _describe(cs))


func _describe(cs: CollisionShape3D) -> String:
	var s: Shape3D = cs.shape
	if s is CylinderShape3D:
		return "Cylinder r=%.2f h=%.2f at %v" % [
			(s as CylinderShape3D).radius, (s as CylinderShape3D).height, cs.global_position]
	if s is CapsuleShape3D:
		return "Capsule r=%.2f h=%.2f at %v" % [
			(s as CapsuleShape3D).radius, (s as CapsuleShape3D).height, cs.global_position]
	if s is SphereShape3D:
		return "Sphere r=%.2f at %v" % [(s as SphereShape3D).radius, cs.global_position]
	if s is BoxShape3D:
		return "Box size=%v at %v" % [(s as BoxShape3D).size, cs.global_position]
	return "%s at %v" % [s.get_class(), cs.global_position]


func _slope_at(p: Vector3) -> float:
	if not _world.has_method("ground_height_at"):
		return -1.0
	var h := float(_world.call("ground_height_at", p.x, p.z))
	var hx := float(_world.call("ground_height_at", p.x + 1.0, p.z))
	var hz := float(_world.call("ground_height_at", p.x, p.z + 1.0))
	return rad_to_deg(atan(Vector2(hx - h, hz - h).length()))
