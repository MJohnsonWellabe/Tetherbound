extends SceneTree

## F06 #4: a recalled companion appears on the trainer's own level.
##
##   godot --headless --path . --script tests/smoke_cloudreach_recall_level.gd
##
## CLOUDREACH-LANE REPORT, open F06 finding: "On the arrival road near
## (8, 105, -245), the ordinary `creature_recall` press summoned the companion
## about 21 m below the trainer, at y 83.9. The trainer then walked off the
## edge toward it and was recovered to camp."
##
## The base director stands a summoned body 2.4 m behind and 1.2 m right of the
## trainer, then seats it on whatever ground is under that XZ. Beside a narrow
## Cloudreach road that is the valley floor.
##
## Disclosed fixtures: the party is seeded before the scene loads; the trainer
## is teleported to each narrow road and turned to each of 8 headings (the
## body's yaw, set directly while standing still). Every summon and put-away
## is the real `creature_recall` press.
##
## Pins, for every spot x heading:
##   1. the recall press brings the companion out;
##   2. its feet are within LEVEL_TOLERANCE_M of the trainer's floor;
##   3. it is within REACH_M of the trainer;
##   4. every 0.4 m along the straight line between them has floor within
##      LEVEL_TOLERANCE_M of the trainer's floor (no drop between them);
##   5. it is still on that level 45 frames later (it did not slide off).

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")

const TEAM := ["meadowhart", "bramblebun"]
const LEVEL_TOLERANCE_M := 1.5
const REACH_M := 5.0
## Narrow roads with a drop beside them. The first is the reported spot.
const SPOTS := {
	"arrival terrace road (report)": Vector3(8.0, 105.4, -245.0),
	"arrival terrace road edge": Vector3(7.6, 105.41, -245.03),
	"arrival road": Vector3(0.0, 105.3, -250.0),
	"Broken Causeways ledge road": Vector3(-104.0, 401.6, 1664.0),
}

var _failures: Array[String] = []
var _checks := 0
var _world: Node3D
var _player: CharacterBody3D
var _director: Node
var _worst_drop := 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	game.set("pending_realm_entry", "")
	game.set("saved_player_pose", {})
	(game.get("progression") as RefCounted).call("set_flag", "realm_key_cloudreach")
	var party: RefCounted = PARTY.new()
	for species: String in TEAM:
		party.call("add", SPECIES.spawn(species))
	party.call("set_active", 0)
	game.set("party", party)

	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	for frame in 600:
		await physics_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		if _director != null and frame > 240:
			break
	if _director == null:
		_fail("Cloudreach has no EncounterDirector")
		_report()
		return

	for label: String in SPOTS:
		for heading in 8:
			await _recall_at(label, SPOTS[label], heading * TAU / 8.0)
	await _boxed_in_recall()
	print("worst recall drop below the trainer: %.2f m" % _worst_drop)
	_report()


## Last rung: test-only walls 1 m round the trainer leave no verified ring spot,
## so the companion comes out on the trainer's own footprint, on the level (a
## following body is on no physics layer), not beyond a wall or below the road.
func _boxed_in_recall() -> void:
	var at: Vector3 = SPOTS["arrival road"]
	var walls: Array[Node] = []
	for i in 4:
		var angle := i * TAU / 4.0
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 4.0, 0.2)
		shape.shape = box
		wall.add_child(shape)
		_world.add_child(wall)
		var floor_y := _floor_y(at, at.y)
		wall.global_transform = Transform3D(Basis(Vector3.UP, angle), Vector3(at.x, floor_y + 2.0, at.z) + Vector3(sin(angle), 0.0, cos(angle)) * 1.1)
		walls.append(wall)
	await _recall_at("boxed in on the arrival road", at, 0.0)
	var body: Node3D = _director.call("ally_body")
	if body != null:
		var flat := Vector2(body.global_position.x - _player.global_position.x, body.global_position.z - _player.global_position.z).length()
		_check(flat < 1.0, "boxed in: the companion comes out inside the walls, on the trainer's footprint (%.2f m)" % flat)
	for wall in walls:
		wall.queue_free()


func _recall_at(label: String, at: Vector3, yaw: float) -> void:
	var context := "%s, heading %d deg" % [label, roundi(rad_to_deg(yaw))]
	if _director.call("ally_body") != null:
		await _press("creature_recall")
		for i in 4:
			await physics_frame
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(at.x, _floor_y(at, at.y) + 0.05, at.z)
	_player.rotation = Vector3(0.0, yaw, 0.0)
	for i in 10:
		_player.velocity = Vector3.ZERO
		await physics_frame
	var trainer_floor := _floor_y(_player.global_position, _player.global_position.y)
	_player.rotation = Vector3(0.0, yaw, 0.0)
	await _press("creature_recall")
	var body: Node3D
	for i in 90:
		body = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible:
			break
		await physics_frame
	if body == null or not is_instance_valid(body) or not body.visible:
		_fail("%s: the recall press brought no companion out" % context)
		return
	var at_body := body.global_position
	var drop := trainer_floor - at_body.y
	_worst_drop = maxf(_worst_drop, drop)
	_check(absf(at_body.y - trainer_floor) <= LEVEL_TOLERANCE_M,
		"%s: companion feet y %.2f vs trainer floor %.2f (|dy| %.2f <= %.1f)" % [context, at_body.y, trainer_floor, absf(at_body.y - trainer_floor), LEVEL_TOLERANCE_M])
	var flat := Vector2(at_body.x - _player.global_position.x, at_body.z - _player.global_position.z).length()
	_check(flat <= REACH_M, "%s: companion %.2f m from the trainer (<= %.1f)" % [context, flat, REACH_M])
	var gap := _first_gap(_player.global_position, at_body, trainer_floor, body)
	_check(gap < 0.0, "%s: floor on the trainer's level all the way to the companion (gap at %.2f m)" % [context, gap])
	for i in 45:
		await physics_frame
	if is_instance_valid(body):
		_check(absf(body.global_position.y - trainer_floor) <= LEVEL_TOLERANCE_M,
			"%s: 45 frames later the companion is still on the level (y %.2f)" % [context, body.global_position.y])


## Distance along the trainer->companion line of the first sample with no floor
## within the tolerance of the trainer's floor, or -1 when there is none.
func _first_gap(from: Vector3, to: Vector3, level: float, body: Node3D) -> float:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var steps := maxi(1, ceili(flat.length() / 0.4))
	var exclude: Array[RID] = [_player.get_rid()]
	if body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	var space := _player.get_world_3d().direct_space_state
	for i in steps + 1:
		# The trainer's own contact can be a road's bevelled lip (the reported
		# spot is one); the line starts past the trainer's capsule.
		if flat.length() * float(i) / steps < 0.5:
			continue
		var p := from + flat * (float(i) / steps)
		var ray := PhysicsRayQueryParameters3D.create(Vector3(p.x, level + LEVEL_TOLERANCE_M + 0.5, p.z),
			Vector3(p.x, level - LEVEL_TOLERANCE_M, p.z), _player.collision_mask, exclude)
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or (hit["normal"] as Vector3).y < 0.6:
			print("  gap sample %s: %s" % [p, "no hit" if hit.is_empty() else "hit %s normal %s collider %s" % [hit["position"], hit["normal"], hit["collider"]]])
			return flat.length() * float(i) / steps
	return -1.0


func _floor_y(at: Vector3, level: float) -> float:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, level + 3.0, at.z), Vector3(at.x, level - 6.0, at.z), _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(ray)
	return (hit["position"] as Vector3).y if not hit.is_empty() else level


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL %s" % message)


func _report() -> void:
	print("CLOUDREACH RECALL LEVEL %s checks=%d failures=%d" % ["OK" if _failures.is_empty() else "FAIL", _checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
