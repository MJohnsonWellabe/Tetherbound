extends SceneTree

## WORLD-LIFE-0903 diagnostic: where does the new Gate Meadow Trailpup herd
## (order 1075) actually sit, at spawn and after some wander time, relative
## to the road? Investigates probe_route_life.gd's leg-1 (arc 100-200m) zero
## reading -- is it a siting defect or wander-timing luck?

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 420

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: Node3D = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if director == null:
		print("FAIL: no director")
		quit(1)
		return
	print("=== at spawn+settle (%d frames) ===" % SETTLE_FRAMES)
	_report(director)

	# Road point near arc~130 (computed offline): (-2.02, 108.79)
	var road := Vector2(-2.02, 108.79)
	print("\nroad reference point near this herd: %s" % str(road))

	# Let wander run for a while and re-check.
	for w in [10, 30, 60]:
		for i in (w * 60):
			await physics_frame
		print("\n=== after %d more seconds of wander ===" % w)
		_report(director)

	quit(0)


func _report(director: Node) -> void:
	var road := Vector2(-2.02, 108.79)
	for c: Variant in (director.call("wild_creatures") as Array):
		var wild: Node3D = c
		if not is_instance_valid(wild):
			continue
		if not str(wild.name).begins_with("Wild_trailpup_1075"):
			continue
		var home: Vector3 = wild.get("home")
		var pos := wild.global_position
		var d_road_home := road.distance_to(Vector2(home.x, home.z))
		var d_road_pos := road.distance_to(Vector2(pos.x, pos.z))
		print("  %-24s home=%s (road dist %.1fm)  pos=(%.1f,%.1f,%.1f) (road dist %.1fm)" % [
			wild.name, str(home), d_road_home, pos.x, pos.y, pos.z, d_road_pos])
