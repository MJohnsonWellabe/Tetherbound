extends SceneTree

## N10-HARNESS-TESTS-0905 / CL-H14's neighbour. Why does `S08-27`'s
## `press interact` never start a fight with the Ironwood Grove's pipwing?
##
##   godot --headless --path . --script tools/gate_f/probe_grove_pipwing_engage.gd
##
## Two lanes converged on this exact site by two different methods and neither
## could say why. W03-S08-FREEZE-0904 ran S08 twelve steps past S08-22 and
## found `input_context` reading `world` for 768 of 773 sampled rows with no
## combat event of any kind in the telemetry. W21-HARNESS-FIGHTS-0904, driving
## the same site by predicate instead of by press count, got
## `S08-29 FAIL chip_to_floor: no live enemy to chip` and
## `S08-31 input_context=world (wanted combat_aim)`. Both concluded the same
## thing: the encounter never staged.
##
## This probe does not run the segment. It stands the player exactly where
## `S08-26` leaves them and reads, off the live world:
##
##   * where the grove's pipwings actually are, individually, and how far each
##     one is from the waypoint the segment walks to;
##   * `encounter_director.gd`'s own `engage_range` (data/config/combat.json
##     `flow.engage_range`), the radius `_engageable()` searches;
##   * whether `_engageable()` returns anything from the waypoint, with a
##     creature deployed -- which is what `interaction_activate()` needs before
##     `press interact` can start a fight at all;
##   * what the interaction arbiter is actually offering there.
##
## The spawn scatter is DETERMINISTIC (`encounter_director.gd` seeds each
## cluster's RNG from `hash("wild_spawn_%d" % order)`), so these positions are
## the positions every run gets, not a sample.

const SCENE := "res://scenes/world/meadows_playground.tscn"
## `S08-26`'s own `at:`, which is also spawn order 4020's authored `centre`.
const WAYPOINT := Vector2(-334.2, 5055.3)
## `S08-26`'s own `close_enough`, i.e. how far short of the waypoint the walk
## is allowed to stop and still PASS.
const CLOSE_ENOUGH := 4.0
const SETTLE_FRAMES := 300

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _find(_world, "CharacterBody3D") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	var director := _find_script(_world, "encounter_director.gd")
	if _player == null or director == null:
		print("PROBE FAIL: player=%s director=%s" % [str(_player), str(director)])
		quit(1)
		return

	var ground := _player.global_position.y
	var stand := Vector3(WAYPOINT.x, ground + 1.0, WAYPOINT.y)
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	if _rig != null:
		_rig.global_position = stand
	for i in 180:
		await physics_frame
	stand = _player.global_position

	print("=== grove pipwing engage probe ===")
	print("standing at (%.2f, %.2f, %.2f); S08-26's waypoint is (%.1f, %.1f), close_enough %.1f m"
		% [stand.x, stand.y, stand.z, WAYPOINT.x, WAYPOINT.y, CLOSE_ENOUGH])

	var range_m := float(director.get("_engage_range"))
	print("encounter_director engage_range = %.2f m (data/config/combat.json flow.engage_range)" % range_m)

	var wilds: Array = director.call("wild_creatures")
	var rows: Array = []
	for w: Variant in wilds:
		var node := w as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var d := stand.distance_to(node.global_position)
		if d > 60.0:
			continue
		rows.append({"d": d, "name": str(node.name), "species": str(node.get("species_id")),
			"pos": node.global_position, "alive": bool(node.call("is_alive")),
			"visible": bool(node.visible)})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	print("live wild bodies within 60 m of the waypoint: %d" % rows.size())
	for r: Dictionary in rows:
		var p: Vector3 = r["pos"]
		print("  %7.2f m  %-28s %-12s at (%.1f, %.1f)  alive=%s visible=%s%s"
			% [r["d"], r["name"], r["species"], p.x, p.z, str(r["alive"]), str(r["visible"]),
				"   <-- INSIDE engage_range" if float(r["d"]) <= range_m else ""])

	var pips: Array = rows.filter(func(r: Dictionary) -> bool: return str(r["species"]) == "pipwing")
	if pips.is_empty():
		print("VERDICT: NO pipwing body exists within 60 m of the waypoint at all.")
	else:
		var nearest: float = float((pips[0] as Dictionary)["d"])
		print("nearest pipwing: %.2f m; engage_range %.2f m; %d pipwing(s) within 60 m"
			% [nearest, range_m, pips.size()])
		print("worst case for a walk that stops `close_enough` short: %.2f m"
			% (nearest + CLOSE_ENOUGH))

	# The other half: is the engage path even open? `_engageable()` returns null
	# with no creature deployed, whatever is standing nearby.
	print("ally deployed before summon: %s" % str(director.get("_ally") != null))
	var party := _party()
	if party == null or (party.call("members") as Array).is_empty():
		print("NOTE: this boot has an empty party, so `summon_active_creature()` has nothing to "
			+ "call out. The distances above are the measurement that does not depend on it.")
	else:
		var summoned: bool = await director.call("summon_active_creature")
		for i in 120:
			await physics_frame
		print("summon_active_creature -> %s; ally now %s"
			% [str(summoned), str(director.get("_ally") != null)])

	var engageable: Node3D = director.call("_engageable")
	print("_engageable() from the waypoint: %s"
		% ("null -- `interaction_activate()` returns without starting anything, so `press interact` does nothing"
			if engageable == null else "%s at %.2f m" % [str(engageable.name),
				stand.distance_to(engageable.global_position)]))

	var arbiter := _find_script(_world, "interaction_arbiter.gd")
	if arbiter != null:
		print("arbiter prompt here: \"%s\"" % str(arbiter.call("prompt")))

	quit(0)


func _party() -> RefCounted:
	var game := root.get_node_or_null(^"/root/Game")
	return game.get("party") as RefCounted if game != null else null


func _find(node: Node, klass: String) -> Node:
	if node.is_class(klass) and node.name == "Player":
		return node
	for child in node.get_children():
		var hit := _find(child, klass)
		if hit != null:
			return hit
	return null


func _find_script(node: Node, tail: String) -> Node:
	var script := node.get_script() as GDScript
	if script != null and script.resource_path.ends_with(tail):
		return node
	for child in node.get_children():
		var hit := _find_script(child, tail)
		if hit != null:
			return hit
	return null
