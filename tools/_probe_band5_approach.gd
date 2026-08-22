extends SceneTree

## BAND5's driven evidence run, and its captures. Prompt 66's "Evidence run"
## asks for time/distance, wild/trainer/resource opportunities, route
## readability, whether the stronghold grows in visual dominance, whether
## faction occupation escalates, and the longest dead-travel interval -- and
## `ralph/lanes/COMMON.md` §10.3 asks for that as a REAL DRIVEN RUN rather than
## a unit test. This walks the authored spine through the live world, so every
## number below comes from the same scene the player gets.
##
## Dead travel is measured the only way that means anything: for each metre of
## the spine, the distance to the NEAREST reason to stop -- a wild cluster's own
## radius, a trainer's challenge range, a gatherable, a prop cluster, a landmark
## or the gate. The longest run of metres with nothing within reach is the
## region's worst empty stretch, reported in metres rather than adjectives.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/band5_approach"
const REACH := 22.0   # how close counts as "there is something here"

func _init() -> void:
	_run()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame

	var stronghold: Node = world.get_node_or_null(^"Stronghold")
	if stronghold != null:
		print("pylons standing: %d" % int(stronghold.call("approach_pylons")))
		var drain: Node = stronghold.call("approach_drain")
		if drain != null:
			print("drained quads on the approach: %d" % int(drain.call("quads")))

	_cadence()
	await _captures(world)
	quit(0)


## --- the walk ---------------------------------------------------------------

func _spine() -> Array[Vector2]:
	var raw := _json("res://data/config/terrain_playground.json")
	var out: Array[Vector2] = []
	for entry: Variant in (raw.get("trail", {}) as Dictionary).get("bands", []):
		var band: Dictionary = entry as Dictionary
		if not str(band.get("id", "")).begins_with("band5"):
			continue
		for point: Variant in band.get("points", []):
			out.append(Vector2(float((point as Array)[0]), float((point as Array)[1])))
	return out


func _interests() -> Array:
	var out: Array = []   # [label, Vector2, reach]
	var dir := "res://data/config/bands/band5_stronghold_approach/"
	for entry: Variant in (_json(dir + "spawns.json").get("spawns", []) as Array):
		var s: Dictionary = entry as Dictionary
		var c: Array = s.get("centre", [])
		if c.size() >= 3:
			out.append(["wild %s x%d" % [s.get("species", "?"), int(s.get("count", 0))],
				Vector2(float(c[0]), float(c[2])), float(s.get("radius", 16.0))])
	for entry: Variant in (_json(dir + "trainers.json").get("trainers", []) as Array):
		var t: Dictionary = entry as Dictionary
		var p: Array = t.get("position", [])
		if p.size() >= 2 and float(p[1]) < 7540.0:   # the doorstep gauntlet is Gate E's
			out.append(["trainer %s" % t.get("id", "?"), Vector2(float(p[0]), float(p[1])), REACH])
	for entry: Variant in (_json(dir + "harvest.json").get("nodes", []) as Array):
		var h: Dictionary = entry as Dictionary
		var a: Array = h.get("at", [])
		if a.size() >= 2:
			out.append(["gather %s" % h.get("item", "?"), Vector2(float(a[0]), float(a[1])), REACH])
	for entry: Variant in (_json(dir + "props.json").get("clusters", []) as Array):
		var c2: Dictionary = entry as Dictionary
		var props: Array = c2.get("props", [])
		if props.is_empty():
			continue
		var a2: Array = (props[0] as Dictionary).get("at", [])
		if a2.size() >= 2:
			out.append(["props %s" % c2.get("name", "?"), Vector2(float(a2[0]), float(a2[1])), REACH])
	out.append(["the three-Sigil gate", Vector2(0.0, 7400.0), REACH])
	return out


func _cadence() -> void:
	var spine := _spine()
	if spine.size() < 2:
		print("no band5 spine; nothing to walk")
		return
	var points := _interests()
	print("=== band5 approach: %d spine waypoints, %d reasons to stop ===" % [spine.size(), points.size()])

	var walked := 0.0
	var dry := 0.0
	var worst_dry := 0.0
	var worst_at := 0.0
	var met := {}
	var order: Array = []
	var step := 1.0
	for i in spine.size() - 1:
		var a: Vector2 = spine[i]
		var b: Vector2 = spine[i + 1]
		var span := a.distance_to(b)
		var n := int(ceil(span / step))
		for s in range(1, n + 1):
			var here: Vector2 = a.lerp(b, float(s) / float(n))
			walked += span / float(n)
			var near := false
			for entry: Variant in points:
				var item: Array = entry as Array
				if here.distance_to(item[1] as Vector2) <= float(item[2]):
					near = true
					if not met.has(item[0]):
						met[item[0]] = walked
						order.append([item[0], walked])
			if near:
				dry = 0.0
			else:
				dry += span / float(n)
				if dry > worst_dry:
					worst_dry = dry
					worst_at = walked
	print("spine length: %.0f m" % walked)
	print("reasons to stop met, in the order the player meets them:")
	for entry: Variant in order:
		print("  %6.0f m  %s" % [float((entry as Array)[1]), (entry as Array)[0]])
	print("met %d of %d; LONGEST DEAD-TRAVEL INTERVAL %.0f m, ending at %.0f m along" % [
		order.size(), points.size(), worst_dry, worst_at])


## --- the captures -----------------------------------------------------------

## Six viewpoints down the route, all at eye height on the spine, each looking
## at the works. What they are FOR: whether the pylon line reads as a bearing,
## and whether the stronghold grows. Judged by an independent critic, never here
## -- `ralph/lanes/COMMON.md` §8.
func _captures(world: Node) -> void:
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var field: RefCounted = HEIGHTFIELD.new()
	var shots := [
		["01-band-mouth", Vector2(0.0, 7000.0)],
		["02-outer-watch", Vector2(-70.0, 7150.0)],
		["03-mid-route", Vector2(-20.0, 7250.0)],
		["04-before-the-gate", Vector2(60.0, 7350.0)],
		["05-past-the-gate", Vector2(20.0, 7440.0)],
		["06-the-waystop", Vector2(-25.0, 7462.0)],
	]
	var target := Vector2(0.0, 7560.0)
	for entry: Variant in shots:
		var shot: Array = entry as Array
		var eye: Vector2 = shot[1]
		var eye_ground: float = field.height_at(eye.x, eye.y)
		var target_ground: float = field.height_at(target.x, target.y)
		camera.global_position = Vector3(eye.x, eye_ground + 1.7, eye.y)
		camera.look_at(Vector3(target.x, target_ground + 6.0, target.y), Vector3.UP)
		for i in 12:
			await physics_frame
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/%s.png" % [OUT_DIR, shot[0]]
		root.get_texture().get_image().save_png(path)
		print("wrote %s" % path)


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
