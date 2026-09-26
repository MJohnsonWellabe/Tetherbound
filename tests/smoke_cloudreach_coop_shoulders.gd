extends SceneTree

## Owner ruling 2026-09-26: co-op keeps the route shoulders single player has.
## Builds the production Cloudreach world twice in one process -- once solo
## (unsliced, every await resumes in the same frame) and once as a LIVE
## crossing (Game.is_multi_peer() true, so `shell_build_budget.gd` slices the
## build with the crossing budget) -- and requires the live build to finish and
## to stand exactly the same shoulder ridges, each with its walkable collision:
## the same nodes per route and the same collision faces (a sha256 over every
## ridge's name, transform and trimesh faces). A third build as a host SHELL
## (simulation_only) must defer the shoulders, as it did before the ruling.
##
##   godot --headless --path . --script tests/smoke_cloudreach_coop_shoulders.gd
##
## Prints `COOP SHOULDERS {...}` and `COOP SHOULDERS PASS` / `FAIL`.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const LIVE_BUILD_FRAME_LIMIT := 60000

## Stands in for the network session of the host of a two-peer game: the
## build asks whether more than one peer is present, the world whether this
## peer is the host.
class LiveSession extends Node:
	func is_multi_peer() -> bool:
		return true

	func is_host() -> bool:
		return true

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	var solo := await _build(false)
	var session := LiveSession.new()
	game.set("session", session)
	_expect(bool(game.call("is_multi_peer")), "the stand-in session did not make the game multi-peer")
	var live := await _build(true)
	var shell := await _build(true, true)
	game.set("session", null)
	session.free()
	_expect(bool(live.sliced), "the live build did not slice; the crossing path was not exercised")
	_expect(bool(live.complete), "the live build never completed within %d frames" % LIVE_BUILD_FRAME_LIMIT)
	_expect(int(solo.ridges) > 0, "solo built no shoulder ridges")
	_expect(live.ridges == solo.ridges, "live built %d shoulder ridges, solo %d" % [live.ridges, solo.ridges])
	_expect(live.collisions == solo.collisions,
		"live has %d walkable shoulder collisions, solo %d" % [live.collisions, solo.collisions])
	_expect(live.routes == solo.routes, "shoulder sets differ by route: live %s solo %s" % [live.routes, solo.routes])
	_expect(str(live.faces_sha256) == str(solo.faces_sha256),
		"live shoulder collision faces differ from solo")
	_expect(bool(shell.complete) and int(shell.ridges) == 0,
		"a host shell built %d shoulder ridges; shells defer them" % int(shell.ridges))
	var builds := {"solo": solo, "live": live, "shell": shell}
	for key in ["solo", "live", "shell"]:
		var shown: Dictionary = (builds[key] as Dictionary).duplicate()
		shown.erase("routes")
		print("COOP SHOULDERS %s %s" % [key, JSON.stringify(shown)])
	print("COOP SHOULDERS routes " + JSON.stringify(live.routes))
	for failure in _failures:
		push_error("COOP SHOULDERS: " + failure)
	print("COOP SHOULDERS %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)


func _build(live: bool, shell: bool = false) -> Dictionary:
	var world := SCENE.instantiate()
	world.set("simulation_only", shell)
	root.add_child(world)
	current_scene = world
	var started := Time.get_ticks_msec()
	var frames := 0
	var budget: RefCounted = world.get("_shell_build")
	var sliced := budget != null and bool(budget.call("is_slicing"))
	while not bool(world.call("shell_build_complete")) and frames < LIVE_BUILD_FRAME_LIMIT:
		await physics_frame
		frames += 1
	for _frame in 4:
		await physics_frame
	var result := {"live": live, "shell": shell, "sliced": sliced, "complete": bool(world.call("shell_build_complete")),
		"frames": frames, "ms": Time.get_ticks_msec() - started, "ridges": 0, "collisions": 0, "routes": {}}
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	_count(world, result, ctx)
	result["faces_sha256"] = ctx.finish().hex_encode()
	var budget_summary := "" if budget == null else str(budget.call("summary"))
	result["build_summary"] = budget_summary.get_slice(";", 0)
	world.queue_free()
	await process_frame
	await process_frame
	return result


func _count(node: Node, result: Dictionary, ctx: HashingContext) -> void:
	var parent := node.get_parent()
	if parent != null and str(parent.name).ends_with("CliffShoulders") and str(node.name).begins_with("Ridge"):
		result.ridges += 1
		var routes: Dictionary = result.routes
		routes[str(parent.name)] = int(routes.get(str(parent.name), 0)) + 1
		var body := node.get_node_or_null("Collision")
		if body is StaticBody3D and (body as StaticBody3D).get_child_count() > 0:
			result.collisions += 1
		ctx.update(("%s/%s %s\n" % [parent.name, node.name, (node as Node3D).global_transform]).to_utf8_buffer())
		if body != null:
			for shape_node in body.get_children():
				if shape_node is CollisionShape3D and (shape_node as CollisionShape3D).shape is ConcavePolygonShape3D:
					var faces: PackedVector3Array = ((shape_node as CollisionShape3D).shape as ConcavePolygonShape3D).get_faces()
					ctx.update(faces.to_byte_array())
	for child in node.get_children():
		_count(child, result, ctx)


func _expect(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)
