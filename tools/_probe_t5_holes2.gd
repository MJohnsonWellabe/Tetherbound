extends SceneTree

## T5-CARE probe, second pass: WHAT are the floorless columns near the village?
##
##   godot --headless --path . --script tools/_probe_t5_holes2.gd
##
## `tools/_probe_t5_holes.gd` found 87 columns with no collider at all in the
## village corridor, identical from two different player positions (so not
## collision streaming). This asks what the world THINKS is there -- its own
## `ground_height_at`, the nearest terrain body, and how far the hole is from
## the walked route -- so the finding can be written up as either a real
## fall-through or a harmless void outside the playable area.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SAMPLES: Array = [
	Vector2(-6.0, -20.0),
	Vector2(-2.0, -20.0),
	Vector2(-2.0, -2.0),
	Vector2(-10.0, -10.0),
	Vector2(0.0, -20.0),
	Vector2(2.0, -20.0),
	Vector2(14.0, -18.0),
	Vector2(14.0, -20.0),
	Vector2(10.0, -13.0),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var space := world.get_world_3d().direct_space_state

	print("")
	print("=== T5 hole characterisation ===")
	for s: Variant in SAMPLES:
		var xz := s as Vector2
		var reported := float(world.call("ground_height_at", xz.x, xz.y))
		var params := PhysicsRayQueryParameters3D.create(
			Vector3(xz.x, 400.0, xz.y), Vector3(xz.x, -400.0, xz.y))
		params.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(params)
		var what := "NOTHING"
		if not hit.is_empty():
			var node := hit["collider"] as Node
			what = "%.2f on %s (%s)" % [
				float((hit["position"] as Vector3).y), node.name, node.get_class()]
		# What does a body actually do if you drop it here?
		var landed := _drop_test(world, xz)
		print("  (%6.1f,%6.1f)  ground_height_at=%7.2f  ray=%-34s  dropped body -> %s" % [
			xz.x, xz.y, reported, what, landed])

	# Where IS the terrain collider, and how big is it?
	print("")
	print("=== terrain bodies in the scene ===")
	var seen := {}
	for node in world.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		for child in body.get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.shape == null:
				continue
			var kind := shape.shape.get_class()
			var key := "%s/%s" % [body.name, kind]
			if seen.has(key):
				continue
			seen[key] = true
			var extra := ""
			var height_map := shape.shape as HeightMapShape3D
			if height_map != null:
				extra = " %dx%d samples, scale %s, at %s" % [
					height_map.map_width, height_map.map_depth,
					str(shape.global_scale), str(shape.global_position)]
			print("  %-40s %s%s" % [body.name, kind, extra])
	quit(0)


## Drop a real body down the column and report where it comes to rest, or that
## it never did.
func _drop_test(world: Node3D, xz: Vector2) -> String:
	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	body.add_child(shape)
	world.add_child(body)
	body.global_position = Vector3(xz.x, 20.0, xz.y)
	var frames := 0
	while frames < 240:
		body.velocity.y -= 20.0 * (1.0 / 60.0)
		body.move_and_slide()
		frames += 1
		if body.is_on_floor():
			var rest := body.global_position.y
			body.queue_free()
			return "rested at y=%.2f" % rest
		if body.global_position.y < -200.0:
			body.queue_free()
			return "FELL THROUGH (past y=-200)"
	var last := body.global_position.y
	body.queue_free()
	return "still falling at y=%.2f" % last
