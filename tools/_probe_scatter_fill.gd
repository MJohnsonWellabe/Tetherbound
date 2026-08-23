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

	var inventory: RefCounted = game.get("inventory")
	for spec: Array in [["axe", 0], ["pickaxe", 1], ["knife", 2]]:
		inventory.call("add", str(spec[0]), 1)
		game.call("assign_hotbar", int(spec[1]), str(spec[0]))
	print("PROBE granted tools; hotbar=%s" % str(game.get("hotbar")))

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
