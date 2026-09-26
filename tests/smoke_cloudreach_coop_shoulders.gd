extends SceneTree

## Owner ruling 2026-09-26: co-op keeps the route shoulders single player has.
## Builds the production Cloudreach world twice in one process -- once solo
## (unsliced, every await resumes in the same frame) and once as a LIVE
## crossing (Game.is_multi_peer() true, so `shell_build_budget.gd` slices the
## build with the crossing budget) -- and requires the live build to finish and
## to stand exactly the same shoulder ridges, each with its walkable collision.
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
	game.set("session", null)
	session.free()
	_expect(bool(live.sliced), "the live build did not slice; the crossing path was not exercised")
	_expect(bool(live.complete), "the live build never completed within %d frames" % LIVE_BUILD_FRAME_LIMIT)
	_expect(int(solo.ridges) > 0, "solo built no shoulder ridges")
	_expect(live.ridges == solo.ridges, "live built %d shoulder ridges, solo %d" % [live.ridges, solo.ridges])
	_expect(live.collisions == solo.collisions,
		"live has %d walkable shoulder collisions, solo %d" % [live.collisions, solo.collisions])
	_expect(live.routes == solo.routes, "shoulder sets differ by route: live %s solo %s" % [live.routes, solo.routes])
	for key in ["solo", "live"]:
		var shown: Dictionary = (solo if key == "solo" else live).duplicate()
		shown.erase("routes")
		print("COOP SHOULDERS %s %s" % [key, JSON.stringify(shown)])
	print("COOP SHOULDERS routes " + JSON.stringify(live.routes))
	for failure in _failures:
		push_error("COOP SHOULDERS: " + failure)
	print("COOP SHOULDERS %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)


func _build(live: bool) -> Dictionary:
	var world := SCENE.instantiate()
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
	var result := {"live": live, "sliced": sliced, "complete": bool(world.call("shell_build_complete")),
		"frames": frames, "ms": Time.get_ticks_msec() - started, "ridges": 0, "collisions": 0, "routes": {}}
	_count(world, result)
	world.queue_free()
	await process_frame
	await process_frame
	return result


func _count(node: Node, result: Dictionary) -> void:
	var parent := node.get_parent()
	if parent != null and str(parent.name).ends_with("CliffShoulders") and str(node.name).begins_with("Ridge"):
		result.ridges += 1
		var routes: Dictionary = result.routes
		routes[str(parent.name)] = int(routes.get(str(parent.name), 0)) + 1
		var body := node.get_node_or_null("Collision")
		if body is StaticBody3D and (body as StaticBody3D).get_child_count() > 0:
			result.collisions += 1
	for child in node.get_children():
		_count(child, result)


func _expect(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)
