extends SceneTree

## D110 -- what found the storm road carve's real slope. Boots the production
## Meadows scene, forces `legendary_freed` at the world's own progression
## (skipping the boss fight), and walks a body from the storm road's seam
## toward Cloudreach with the same shape `tests/smoke_boss.gd`'s SG44 probe
## uses, printing position every 20 physics frames. This is what found the
## real 5.2m near/far ground difference `rift_crossing.gd::_build_deck`'s own
## `GATE-CROSSING-SLOPE` comment cites -- a flat deck at the higher of the two
## stood the near landing off an unclimbable step. Kept for the next person
## who has to re-measure this seam if the storm road ever moves.
##
##   godot --headless --path . --script tools/_probe_rift_crossing_slope.gd
##
## NOTE: this script's own settle budget (300 + 900 physics frames) is too
## short for Terrain3D's collision to finish generating on a heavily loaded
## machine -- under contention the probe here can fall through the WHOLE
## terrain, not just the crossing, and land nowhere. `tests/smoke_boss.gd`'s
## own probe does not have this problem because thousands of frames of real
## boss-fight play elapse first; treat a "falls forever" result from this
## script as inconclusive and trust that test instead.
const SCENE := "res://scenes/world/meadows_playground.tscn"

var _world: Node = null
var _game: Node = null


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 300:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	var progression: RefCounted = _game.get("progression")
	progression.call("set_flag", "warden_defeated")
	progression.call("set_flag", "realm_key_cloudreach")
	progression.call("set_flag", "legendary_freed")
	# Let the crossing notice the flag (revision poll) and, since it is NOT
	# already set at build, wait out hold+dissipate+appear before it spawns.
	for i in 900:
		await physics_frame

	var crossing := _world.get_node_or_null(^"RiftCrossing")
	var rift := _world.get_node_or_null(^"RiftCollapse")
	print("crossing=", crossing, " span_ready=", crossing.call("span_ready") if crossing else null)
	if crossing == null:
		quit(1)
		return
	print("near_anchor=", crossing.call("near_anchor"), " far_anchor=", crossing.call("far_anchor"))
	var deck_anchor := crossing.find_child("DeckAnchor", true, false) as Node3D
	if deck_anchor:
		print("deck_anchor global=", deck_anchor.global_position, " scale=", deck_anchor.scale)
	var trigger := crossing.find_child("RiftCrossingTrigger", true, false) as Area3D
	if trigger:
		print("trigger global=", trigger.global_position)

	var seam: Vector2 = rift.call("seam")
	var horizon: Dictionary = rift.call("horizon")
	var origin: Vector2 = horizon.get("origin", seam)
	print("seam=", seam, " origin=", origin)
	var seam_ground: float = _world.call("ground_height_at", seam.x, seam.y)
	print("seam ground=", seam_ground)
	var near_a: Vector3 = crossing.call("near_anchor")
	var near_ground2: float = _world.call("ground_height_at", near_a.x, near_a.z)
	print("near anchor ground re-sample=", near_ground2, " (anchor y=", near_a.y, ")")

	var forward := (origin - seam).normalized()
	var probe := CharacterBody3D.new()
	probe.floor_max_angle = deg_to_rad(60.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	probe.add_child(shape)
	_world.add_child(probe)
	probe.global_position = Vector3(seam.x, seam_ground + 1.2, seam.y)
	for i in 10:
		await physics_frame
	var start := Vector2(probe.global_position.x, probe.global_position.z)
	var step := Vector3(forward.x, 0.0, forward.y) * 8.0
	for i in 420:
		probe.velocity.x = step.x
		probe.velocity.z = step.z
		probe.velocity.y = 0.0 if probe.is_on_floor() else probe.velocity.y - 26.0 * (1.0 / 60.0)
		probe.move_and_slide()
		await physics_frame
		if i % 20 == 0:
			var here := Vector2(probe.global_position.x, probe.global_position.z)
			print("i=", i, " pos=", probe.global_position, " along=", (here - start).dot(forward), " on_floor=", probe.is_on_floor())
	print("final pos=", probe.global_position)
	quit(0)
