extends SceneTree

## GATHER-ROUTE-0903, part 2.
##
##   godot --headless --path . --script tools/_probe_gather_route_reach_0903b.gd
##
## `tools/_probe_gather_route_reach_0903.gd` teleported straight to the
## RoadGate and walked the 24m leg to the wood node at (16,-28) cleanly in
## 12.9 real-time-equivalent seconds -- no fence, no slope, nothing in the
## way. That rules out an unreachable authored node (option (a) in the
## GATHER-ROUTE-0903 brief) and rules out the walker being unable to route
## around static geometry over that distance (most of option (b)).
##
## But the real smoke run's own failing leg took several MINUTES of wall
## clock to report "stopped 22.9m short" -- barely any of the 24m gap
## closed -- which a 1680-frame travel budget (28 simulated seconds) cannot
## explain by itself. `stick_navigator.gd::walk_to()` has a second budget
## that CAN explain it: `HELD_FRAMES` (36000 -- ten minutes), spent whenever
## `can_walk()` is false and not counted against the travel budget at all.
## `can_walk()` reads `player.locomotion_enabled()`, and
## `encounter_director.gd::_on_wild_wants_to_engage()` is a real, undisguised
## production mechanic: an AGGRESSIVE wild creature can close on the player
## and start a fight on its own, with no interact press, which
## `_set_exploration_active(false)` freezes locomotion for -- and nothing in
## `gate_a_material_route.gd`'s travel code (unlike its own harvest-press
## path, which does clear an interact-arbiter STATEMENT) does anything about
## a live fight, because winning, fleeing or catching one is not a travel
## concern.
##
## This runs the SAME leg through the REAL `gate_a_material_route.gd`
## methods (`_unlock_road_gate()` for the key+gate, then
## `_harvest_authored_stop()` for the wood node) rather than a bare
## teleport-and-walk, starting from the real post-opening position so the
## player is genuinely exposed to whatever roams that stretch of the
## Meadows, and polls `locomotion_enabled()`, whether a fight is running,
## and the nearest wild creature every second throughout -- so an
## encounter, if one is what happens, is caught in the act rather than
## inferred from a stopped-short number.
##
## Cheaper than the full continuous smoke: tools are granted directly
## (`_probe_scatter_fill.gd`'s own convention -- "a probe, not evidence",
## the village visit is already proven elsewhere) rather than played
## through Mira/Tam/the Foreman.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
## The real run's own checkpoint: "opening played; player stands where the
## game left them, at (21.0, 1.0, -39.0)".
const POST_OPENING_AT := Vector3(21.0, 1.0, -39.0)
const REPORT_EVERY_FRAMES := 60

var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _route
var _route_done := false
var _elapsed_frames := 0


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _i in 300:
		await physics_frame

	_game = root.get_node_or_null(^"/root/Game")
	_player = _find(_world, "locomotion_enabled") as CharacterBody3D
	_rig = _find(_world, "planar_basis") as Node3D
	if _game == null or _player == null or _rig == null:
		print("PROBE: missing game/player/rig")
		quit(1)
		return

	var inventory: RefCounted = _game.get("inventory")
	for spec: Array in [["axe", 0], ["pickaxe", 1], ["knife", 2]]:
		inventory.call("add", str(spec[0]), 1)
		_game.call("assign_hotbar", int(spec[1]), str(spec[0]))
	print("PROBE granted tools; hotbar=%s" % str(_game.get("hotbar")))

	_player.global_position = POST_OPENING_AT
	_player.velocity = Vector3.ZERO
	for _i in 60:
		await physics_frame
	print("PROBE standing at the real post-opening position: %s" % str(_player.global_position.round()))

	_route = MATERIAL_ROUTE.new()
	_route.set("_tree", self)
	_route.set("_world", _world)
	_route.set("_game", _game)
	_route.set("_player", _player)
	_route.set("_rig", _rig)
	_route.set("_arbiter", get_first_node_in_group(&"interaction_arbiter"))
	if not _route.call("_resolve_move_bindings"):
		print("PROBE: no left-stick bindings")
		quit(1)
		return
	_route.set("_nav", NAVIGATOR.new(self, _player, _rig, Callable(_route, "_send_stick")))

	# Fire-and-forget: GDScript resumes an un-awaited coroutine on its own
	# awaited signals (here, physics_frame), so this keeps running while the
	# loop below polls state every second -- the loop below is what actually
	# holds the SceneTree alive.
	_drive_route()

	var seconds := 0
	while not _route_done:
		for _i in REPORT_EVERY_FRAMES:
			await physics_frame
			_elapsed_frames += 1
		seconds += 1
		_report(seconds)
		if seconds > 900:
			print("PROBE: giving up after 900s wall-equivalent; route never finished")
			break

	print("")
	print("PROBE VERDICT: route failures=%s" % str(_route.get("failures")))
	print("PROBE transcript:")
	for line: Variant in (_route.get("transcript") as Array):
		print("  | %s" % str(line))
	quit(0)


func _drive_route() -> void:
	if not await _route.call("_unlock_road_gate"):
		print("PROBE: _unlock_road_gate failed: %s" % str(_route.get("failures")))
		_route_done = true
		return
	print("PROBE: gate unlocked; player at %s" % str(_player.global_position.round()))
	var stop: Dictionary = MATERIAL_ROUTE.AUTHORED_ROUTE[0]
	var ok: bool = await _route.call("_harvest_authored_stop", stop)
	print("PROBE: _harvest_authored_stop(node0) returned %s" % str(ok))
	_route_done = true


func _report(second: int) -> void:
	var locomotion := bool(_player.call("locomotion_enabled"))
	var manager := _world.get_node_or_null(^"CombatManager")
	var fighting := manager != null and manager.has_method("is_fighting") and bool(manager.call("is_fighting"))
	var nearest_name := "<none>"
	var nearest_dist := INF
	var nearest_aggressive := "?"
	var director := _world.get_node_or_null(^"EncounterDirector")
	var wild_list: Array = (director.get("_wild_creatures") as Array) if director != null else []
	for node: Variant in wild_list:
		if not node is Node3D or not is_instance_valid(node as Object):
			continue
		var d := _player.global_position.distance_to((node as Node3D).global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_name = str((node as Node3D).name)
			nearest_aggressive = str((node as Node3D).get("aggressive")) if (node as Node3D).get("aggressive") != null else "?"
	var arbiter := get_first_node_in_group(&"interaction_arbiter")
	var winner: Variant = arbiter.call("winning_provider") if arbiter != null else null
	print(("t=%4ds pos %-24s locomotion=%s fighting=%s | nearest wild '%s' aggressive=%s at %.1fm | "
		+ "arbiter winner=%s | vel %.2f floor %s") % [
		second, str(_player.global_position.round()), str(locomotion), str(fighting),
		nearest_name, nearest_aggressive, nearest_dist,
		str((winner as Node).name) if winner is Node else "<none>",
		Vector2(_player.velocity.x, _player.velocity.z).length(), str(_player.is_on_floor())])


func _find(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child: Node in node.get_children():
		var found := _find(child, method)
		if found != null:
			return found
	return null
