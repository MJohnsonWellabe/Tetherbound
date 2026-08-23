extends SceneTree

## GATEB-PATH diagnostic. The material route's LIVE SCATTER fill on its own.
##
##   godot --headless --path . --script tools/_probe_scatter_fill.gd
##
## `gate_a_material_route.gd` closes its wood/stone shortfall by chopping real
## scatter stands and picking up the pile each one leaves. That is the longest
## and least-exercised part of the Gate B continuous run, and reaching it for
## real costs four minutes of opening and village first.
##
## So this GRANTS the tools and the quick slots -- which the village segment has
## already proven it hands over for real -- and drives only the fill. It is a
## probe, not evidence: nothing here belongs in a smoke test.
##
## GATEB-COORD: it also has to STAND the player where the fill really begins.
## As first written it drove the fill from the default spawn, and the default
## spawn is inside GrandpaHouse -- `tools/_probe_stuck_point.gd` names the
## collider on every side of it. So the "stopped 46.9m short" this probe
## reported was the player failing to get OUT OF THE BEDROOM, not the failure
## the continuous run hits; the run has been outdoors for twenty minutes by
## then. `ralph/DONE.md`'s GATEB-PATH entry reads that number as evidence about
## hill climbing, and it is not evidence about hills at all.
##
## `AUTHORED_ROUTE`'s last stop is (-168, 312), so that is where the fill
## starts for real, and that is where this now puts the player.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for _i in 300:
		await physics_frame

	var game := root.get_node_or_null(^"/root/Game")
	var player := _find_player(world)
	var rig := _find_rig(world)
	if game == null or player == null or rig == null:
		print("PROBE: missing game/player/rig")
		quit(1)
		return

	# Where the authored route leaves the player. Dropped in from above rather
	# than placed at the terrain height: `ground_height_at()` answers for the
	# TERRAIN, and a body spawned at terrain+1 inside a prop is wedged.
	var end_of_route := MATERIAL_ROUTE.AUTHORED_ROUTE.back()["at"] as Vector2
	player.global_position = Vector3(end_of_route.x, _ground(end_of_route) + 6.0,
		end_of_route.y)
	for _i in 180:
		await physics_frame
	print("PROBE standing where the authored route ends: %s" % str(player.global_position))

	var inventory: RefCounted = game.get("inventory")
	for spec: Array in [["axe", 0], ["pickaxe", 1], ["knife", 2]]:
		inventory.call("add", str(spec[0]), 1)
		game.call("assign_hotbar", int(spec[1]), str(spec[0]))
	# The authored stops are not replayed here, so without this the fill would
	# have the WHOLE 57-wood target to close instead of the 41 it closes in the
	# real run. Granted, because the authored stops are already proven and the
	# question this probe asks is about the fill's travel.
	for spec: Array in [["wood", 16], ["stone", 9], ["fiber", 24]]:
		inventory.call("add", str(spec[0]), int(spec[1]))
	print("PROBE granted tools + the authored route's yield; hotbar=%s; %s" % [
		str(game.get("hotbar")),
		"wood %d / stone %d / fiber %d" % [int(inventory.call("count", "wood")),
			int(inventory.call("count", "stone")), int(inventory.call("count", "fiber"))]])

	var route := MATERIAL_ROUTE.new()
	route.set("_tree", self)
	route.set("_world", world)
	route.set("_game", game)
	route.set("_player", player)
	route.set("_rig", rig)
	route.set("_arbiter", get_first_node_in_group(&"interaction_arbiter"))
	if not route.call("_resolve_move_bindings"):
		print("PROBE: no left-stick bindings")
		quit(1)
		return
	route.set("_nav", NAVIGATOR.new(self, player, rig, Callable(route, "_send_stick")))

	# Every activation the arbiter actually fires, so a press that credited
	# nothing can be told apart from a press that never arrived.
	var arbiter := get_first_node_in_group(&"interaction_arbiter")
	arbiter.connect("activated", func(provider: Object) -> void:
		var where := ""
		if provider is Node3D:
			var at: Vector3 = (provider as Node3D).global_position
			where = " @(%.1f, %.1f)" % [at.x, at.z]
		print("PROBE   arbiter ACTIVATED %s#%d%s" % [
			(provider as Node).name, (provider as Object).get_instance_id(), where]))

	var started := Time.get_ticks_msec()
	var ok: bool = await route._fill_with_live_scatter("wood")
	print("PROBE wood fill %s in %.1fs; satchel wood=%d" % [
		"OK" if ok else "FAILED", (Time.get_ticks_msec() - started) / 1000.0,
		int(inventory.call("count", "wood"))])
	for line: Variant in (route.get("transcript") as Array):
		print("PROBE | %s" % str(line))
	for line: Variant in (route.get("failures") as Array):
		print("PROBE FAIL | %s" % str(line))
	quit(0 if ok else 1)


func _ground(at: Vector2) -> float:
	var terrain := get_first_node_in_group(&"terrain")
	if terrain != null and terrain.has_method("ground_height_at"):
		return float(terrain.call("ground_height_at", at.x, at.y))
	return 5.0


func _find_player(node: Node) -> CharacterBody3D:
	if node is CharacterBody3D and node.has_method("locomotion_enabled"):
		return node as CharacterBody3D
	for child: Node in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _find_rig(node: Node) -> Node3D:
	if node is Node3D and node.has_method("planar_basis"):
		return node as Node3D
	for child: Node in node.get_children():
		var found := _find_rig(child)
		if found != null:
			return found
	return null
