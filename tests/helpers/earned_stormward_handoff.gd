extends RefCounted

## Continue a completed live Cloudreach segment through its physical realm gate.
## No scene/router invocation, prerequisite write, pose assignment or save load.
const ENTRY := preload("res://tests/smoke_stormwood_continuous.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var failures: Array[String] = []
var _activated := 0
var _wanted: Object
var _travel_watches: Array[Dictionary] = []

func run(tree: SceneTree, route: RefCounted) -> Dictionary:
	var outcome := await _run(tree, route)
	_stop_travel_watches()
	return outcome

func _run(tree: SceneTree, route: RefCounted) -> Dictionary:
	if tree == null or route == null or not bool(route.get("completed_route")):
		return _fail("Stormward requires the completed earned Cloudreach segment")
	var world: Node3D = route.get("world")
	var game: Node = route.get("game")
	if not is_instance_valid(world) or not is_instance_valid(game) or tree.current_scene != world \
			or str(game.get("current_realm")) != "cloudreach" or INPUT_OWNER.current(tree) != null:
		return _fail("Stormward requires the retained Cloudreach scene and ordinary world input")
	var ids: Array[int] = route.call("_party_ids")
	var source_world_id := world.get_instance_id()
	if ids.size() != 5 or ids != route.get("initial_party_ids"):
		return _fail("Stormward requires the same five earned creatures")
	var passage := world.get_node_or_null("StormwardPassage")
	var gate := world.get_node_or_null("StormwardPassage/StormwardRealmGate")
	if gate == null or passage == null or str(gate.get("destination_realm")) != "stormwood" \
			or str(gate.get("destination_entry_id")) != "stormwood_arrival_from_cloudreach" \
			or not bool(gate.call("has_key", game)) or bool(gate.call("is_unlocked", game)):
		return _fail("The earned Stormwood key must meet the actual still-locked Stormward gate")
	var stairs: Array[Node3D] = []
	for child: Node in passage.get_children():
		if child is StaticBody3D and str(child.name).begins_with("ScarredStep"):
			stairs.append(child)
	stairs.sort_custom(func(a: Node3D, b: Node3D) -> bool: return str(a.name) < str(b.name))
	if stairs.is_empty():
		return _fail("Stormward's actual supported stair route is missing")
	# The completed chapter disconnected its observers. Its movement helpers
	# still require the measured physics clock and reject recovery during travel.
	var fly: Object = route.get("fly")
	if not is_instance_valid(fly) or not (route.get("failures") as Array).is_empty():
		return _fail("Stormward requires the completed route's healthy travel context")
	_watch_travel(tree.physics_frame, Callable(route, "_record_frame"))
	_watch_travel(Signal(fly, "recovered"), func(reason: String) -> void:
		route.call("_fail", "Unexpected recovery interrupts Stormward handoff: " + reason))
	# Reach the authored overlook through the existing route graph, then follow
	# actual stair bodies; the raised surfaces are not terrain projected points.
	if not await route.call("_navigate", Vector3(-420, 1110, 5650)) or not (route.get("failures") as Array).is_empty():
		return _fail("Could not walk back to the Stormward overlook")
	for stair: Node3D in stairs:
		if stair.global_position.distance_to(gate.global_position) < 1.0:
			break
		var shape := stair.get_child(stair.get_child_count() - 1) as CollisionShape3D
		if shape == null or not shape.shape is BoxShape3D:
			return _fail("Stormward stair lacks its actual box support")
		var top := stair.global_position + Vector3(0, (shape.shape as BoxShape3D).size.y / 2.0, 0)
		if not await route.call("_walk", top, 0.35) or not (route.get("failures") as Array).is_empty():
			return _fail("Could not walk the actual Stormward stair " + str(stair.name))
	var prompt := gate.get_node_or_null("Interactable")
	var arbiter := world.get_node_or_null("InteractionArbiter")
	if prompt == null or arbiter == null:
		return _fail("Stormward gate lacks its actual interaction provider")
	# Unlock and travel are two deliberate inputs. Observe activation independently
	# of the completed chapter helper, whose signal subscriptions have ended.
	_wanted = prompt
	arbiter.connect("activated", _on_activated)
	for press in 2:
		await tree.process_frame
		var offer: Dictionary = arbiter.call("winner")
		if not bool(arbiter.call("enabled")) or arbiter.call("winning_provider") != prompt \
				or not bool(offer.get("actionable", false)) or INPUT_OWNER.current(tree) != null \
				or not (route.get("failures") as Array).is_empty():
			arbiter.disconnect("activated", _on_activated)
			return _fail("The actual Stormward gate does not own an actionable offer")
		var before := _activated
		if press == 1:
			# Production travel may destroy the old world during this input.
			_stop_travel_watches()
		await route.call("_tap", "interact")
		if _activated != before + 1:
			if is_instance_valid(arbiter): arbiter.disconnect("activated", _on_activated)
			return _fail("Physical Interact did not activate the exact Stormward gate")
		if press == 0 and (not bool(gate.call("is_unlocked", game)) or not bool(gate.call("has_key", game))):
			arbiter.disconnect("activated", _on_activated)
			return _fail("First input did not earn the durable unlock while retaining the chapter key")
	if is_instance_valid(arbiter) and arbiter.is_connected("activated", _on_activated):
		arbiter.disconnect("activated", _on_activated)
	for _frame in ENTRY.SCENE_WAIT_FRAMES:
		var arrived := tree.current_scene
		if is_instance_valid(arrived) and arrived.get_instance_id() != source_world_id and arrived.name == "Stormwood" \
				and str(game.get("current_realm")) == "stormwood" \
				and str(game.get("pending_realm_entry")).is_empty() and arrived.has_method("shell_build_complete") \
				and bool(arrived.call("shell_build_complete")) and INPUT_OWNER.current(tree) == null \
				and arrived.get_node_or_null("EncounterDirector") != null \
				and bool(arrived.get_node("EncounterDirector").get("population_ready")):
			if ids != route.call("_party_ids"):
				return _fail("Ordinary realm travel changed the retained five creature identities")
			return {"ok": true, "world": arrived, "game": game, "failures": [],
				"source": "earned physical Stormward gate", "campaign_complete": false}
		await tree.physics_frame
	return _fail("Ordinary Stormward travel did not settle within the existing scene wait bound")

func _watch_travel(source: Signal, callback: Callable) -> void:
	source.connect(callback)
	_travel_watches.append({"source": source, "callback": callback})

func _stop_travel_watches() -> void:
	for watch: Dictionary in _travel_watches:
		var source: Signal = watch.source
		if is_instance_valid(source.get_object()) and source.is_connected(watch.callback):
			source.disconnect(watch.callback)
	_travel_watches.clear()

func _on_activated(provider: Object) -> void:
	if provider == _wanted:
		_activated += 1

func _fail(message: String) -> Dictionary:
	failures.append(message)
	return {"ok": false, "failures": failures.duplicate(), "campaign_complete": false}
