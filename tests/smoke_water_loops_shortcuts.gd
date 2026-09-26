extends SceneTree

## ACCEPTANCE §6.1 F13 #1 (Tidewake lane): "four land loops and three
## shortcuts, walked in engine". Production `water_archipelago.tscn`, a real
## player body and real stick input: the LEFT stick carries the body, the RIGHT
## stick turns the camera yaw toward the next waypoint, and the left stick is
## always read through the live camera's `planar_basis()` exactly as a player's
## would be. No actor is moved during a measured leg.
##
## LAND LOOPS (`water_world.json::land_loops`, 4 rows). Each loop is walked
## vertex to vertex along its authored polyline (straight chords -- the data
## has no other path) and back to its first vertex. Every leg must stay on
## real ground: on floor at every waypoint, never swimming, never below the
## terrain, no stall against a step or slope (`STALL_WINDOW_FRAMES` without
## `STALL_PROGRESS_M` of progress), no per-frame jump larger than
## `TELEPORT_M` (a recovery/teleport correction), no drop larger than
## `MAX_DROP_M` in one airborne span, no health loss. The first blocking fault
## ends that loop's walk (recorded as a DEFECT with waypoint index and
## position); the other loops still run. Distance is the body's own summed
## horizontal travel; time is simulated physics time (frames / 60).
##
## SHORTCUTS (`water_world.json::return_shortcuts`, 3 rows).
## * `reedhaven_maintenance_ramp` (kind physical_ramp, unlock
##   `water_dock_reedhaven_repaired`). Closed: before the repair the ramp's
##   authored `path` (Woven Hall -> ramp top -> ramp foot -> departure; the
##   deck bridges a terrace scarp) must NOT be walkable, the scene must hold
##   a runtime node for the ramp, and that node must hold no walk-surface
##   collision (the gate itself). Unlock through the production Reedhaven
##   repair prompt; the deck collision must appear on that live flag change.
##   Open: walk the same path end to end. Shorter: walked length
##   must beat the "repeat the marsh loop" return (hall -> nearest
##   reed_root_circuit vertex -> shorter arc -> vertex nearest the departure ->
##   departure, measured on the authored polyline).
## * `shellwatch_pump_return_channel` and `deep_watch_current_cut` (kind
##   current_reduction). WORLD/data define these as a channel that is always
##   physically swimmable whose unlock swaps an exposed flow for a gentle one
##   ("never a new hidden teleport"). Closed therefore means: before the flag
##   the live field over the direct channel carries its full authored strength
##   (0.35 / 2.2 m/s). Open: after the flag it carries `strength_after_unlock`
##   (0.08 / 0.10), and the direct return is swum end to end with real input.
##   Shorter: the walked direct return is shorter than the walked sheltered
##   (normal) crossing of the same edge. Both swims are measured over the same
##   span, first shore vertex -> far safe anchor; the approach from the start
##   stance to that vertex is swum/walked but printed separately.
##
## DISCLOSED FIXTURES (all written before the leg they serve; none during it):
##  F0  Every placement below also refills player health and stamina, so fall
##      damage from one element's recorded defect cannot kill the player and
##      trigger death recovery inside the next element.
##  F1  One placement at polyline[0] of each land loop (4 placements).
##  F2  Reedhaven: world flag `water_swim_lesson_complete` (the repair's
##      prerequisite) and 6 reed_fiber + 4 driftwood in the bag (its cost);
##      placement at the Woven Hall (twice: closed attempt, open walk) and one
##      placement beside the repair prompt.
##  F3  Shellwatch: world flag `water_dock_brine_steps_trial_won` (story
##      prerequisite; lifts Brine/Shellwatch tide-race seals), and trainer
##      flags `defeated_water_trainer_solm` / `defeated_water_trainer_irva`
##      (prerequisites of the two production prompts that earn the unlock);
##      placement at the Brine departure, one beside the pump prompt, and one
##      back at the Shellwatch arrival before the open return swim.
##  F4  Deep Watch: world flags `water_aquaryn_resolved`,
##      `water_dock_salt_crown_landing_charted` (story prerequisites; lift the
##      Sluice/Deep Watch seals), `water_named_deep_watch_tidecoil_resolved`
##      (chart prompt prerequisite); personal `water_swim_stone_earned` +
##      `water_swim_saddle_recipe_learned`, one swim_saddle and a level-60
##      Aquaryn (the route requires a compatible swim mount); placement at the
##      Sluice departure; production summon + `riding.mount()` as in
##      smoke_water_continuous.gd.
## Unlock flags are never set directly: each is published by its production
## dock prompt (interaction_activate after the body physically reaches it).
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

const PHYSICS_HZ := 60.0
const WAYPOINT_TOLERANCE_M := 1.2
const STALL_WINDOW_FRAMES := 90
const STALL_PROGRESS_M := 0.5
const TELEPORT_M := 2.5
const BELOW_TERRAIN_M := 0.6
const MAX_DROP_M := 1.5
const WATCHDOG_S := 40 * 60

var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var riding: Node
var director: Node
var navigator: RefCounted
var checks := 0
var failures: Array[String] = []
var defects: Array[String] = []
var table: Array[String] = []
var finished := false
var started_ms := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	_watchdog.call_deferred()
	await process_frame
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "water-loops-shortcuts"
	game.world.world_id = "water-loops-shortcuts-world"
	game.save_system = SAVE.new("user://water_loops_shortcuts_%d/" % Time.get_ticks_usec())
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 120000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _check(world.shell_build_complete(), "Production Tidewake world finishes building"):
		_finish()
		return
	player = world.local_rig()
	camera = world.local_camera_rig()
	riding = world.get_node("RidingController")
	director = world.get_node("EncounterDirector")
	navigator = NAVIGATOR.new(self, player, camera, _send_stick)
	await _frames(30)
	_check(world.config.land_loops.size() == 4, "water_world.json authors four land loops")
	_check(world.config.return_shortcuts.size() == 3, "water_world.json authors three return shortcuts")

	for loop: Dictionary in world.config.land_loops:
		await _walk_loop(loop)
	await _reedhaven_ramp(_shortcut("reedhaven_maintenance_ramp"))
	await _shellwatch_channel(_shortcut("shellwatch_pump_return_channel"))
	await _deep_watch_cut(_shortcut("deep_watch_current_cut"))
	_finish()


# ---------------------------------------------------------------- land loops

func _walk_loop(loop: Dictionary) -> void:
	var id := str(loop.id)
	var points: Array[Vector3] = []
	for raw: Array in loop.polyline:
		points.append(_v(raw))
	_check(points.size() >= 4 and _flat(points[0]).distance_to(_flat(points[-1])) < 0.01,
		"%s is authored as a closed polyline" % id)
	await _place(points[0], "F1 %s start" % id)
	if not _check(player.is_on_floor(), "%s start placement settles on floor" % id):
		_row("loop %s | walked NO | start not on floor" % id)
		return
	var stats := _new_stats()
	for index in range(1, points.size()):
		var leg: Dictionary = await _walk_leg(points[index], stats, "%s waypoint %d" % [id, index])
		if not bool(leg.ok):
			_defect("%s: waypoint %d %s not reached on foot -- %s" % [
				id, index, _fmt(points[index]), str(leg.reason)])
			_fail("%s is walkable end to end (blocked before waypoint %d)" % [id, index])
			_report_remaining_chords(id, points, index)
			_row("loop %s | walked NO (reached %d/%d waypoints) | %.1f m | %.1f s | authored %.1f m" % [
				id, index - 1, points.size() - 1, stats.distance, stats.frames / PHYSICS_HZ,
				float(loop.get("measured_polyline_m", 0.0))])
			return
		_stop_stick()
		await _frames(3)
		_check(player.is_on_floor() and not _swimming(),
			"%s waypoint %d reached on foot, on floor, not swimming" % [id, index])
	var closes := _flat(player.global_position).distance_to(_flat(points[0])) <= WAYPOINT_TOLERANCE_M + 0.1
	_check(closes, "%s closes back at its start" % id)
	_check(stats.max_drop <= MAX_DROP_M and not stats.teleported and stats.health_lost <= 0.0,
		"%s walk had no drop/teleport/health loss" % id)
	_row("loop %s | walked YES | %.1f m | %.1f s | authored %.1f m | max drop %.2f m" % [
		id, stats.distance, stats.frames / PHYSICS_HZ, float(loop.get("measured_polyline_m", 0.0)), stats.max_drop])


## Analytic follow-up only (no walking): after the first block, list the
## remaining authored chords whose baked terrain exceeds the loop's own target
## grade, so a defect report names every cliff rather than only the first.
func _report_remaining_chords(id: String, points: Array[Vector3], from_index: int) -> void:
	var loop := {}
	for row: Dictionary in world.config.land_loops:
		if str(row.id) == id:
			loop = row
	var target := float(loop.get("maximum_target_grade_deg", 24.0))
	for index in range(from_index, points.size()):
		var a := _flat(points[index - 1])
		var b := _flat(points[index])
		var steps := maxi(1, int(a.distance_to(b)))
		var worst := 0.0
		var worst_at := Vector3.ZERO
		var over := 0
		var previous := NAN
		for step in steps + 1:
			var p := a.lerp(b, float(step) / steps)
			var h: float = world.ground_height_at(p.x, p.y)
			if is_finite(previous):
				var grade := rad_to_deg(atan(absf(h - previous) / (a.distance_to(b) / steps)))
				if grade > target:
					over += 1
				if grade > worst:
					worst = grade
					worst_at = Vector3(p.x, h, p.y)
			previous = h
		if over > 0:
			print("ANALYTIC %s chord %d->%d: %d x 1m samples over %.0f deg target, worst %.1f deg at %s" % [
				id, index - 1, index, over, target, worst, _fmt(worst_at)])


# ---------------------------------------------------------------- shortcuts

func _reedhaven_ramp(shortcut: Dictionary) -> void:
	var flag := str(shortcut.unlock_flag)
	var hall := _landmark(str(shortcut.from_landmark))
	var departure := _anchor(str(shortcut.to_anchor))
	var ramp_nodes := _nodes_named(world, "maintenance_ramp")
	_check(not ramp_nodes.is_empty(),
		"reedhaven_maintenance_ramp has a runtime node in the production scene (found %s)" % str(ramp_nodes))
	if ramp_nodes.is_empty():
		_defect("reedhaven_maintenance_ramp: kind physical_ramp has no runtime geometry, gate or seal in the scene; " +
			"no script under scripts/ reads return_shortcuts rows of kind physical_ramp")
	# F2 fixtures.
	game.world.flags.set_flag("water_swim_lesson_complete")
	game.inventory.add("reed_fiber", 6)
	game.inventory.add("driftwood", 4)

	# Closed.
	_check(not game.world.flags.has(flag), "Reedhaven ramp starts with %s unset" % flag)
	await _place(hall, "F2 Woven Hall (closed attempt)")
	var closed_stats := _new_stats()
	var closed: Dictionary = await _walk_path(_ramp_path(shortcut, departure), closed_stats, "Reedhaven ramp closed attempt")
	_stop_stick()
	# The gate itself, not just a failed walk: before the flag the ramp node
	# holds no walk-surface collision (no deck) at all.
	var closed_shapes := _ramp_collision_shapes(ramp_nodes)
	_check(not ramp_nodes.is_empty() and closed_shapes == 0,
		"Reedhaven ramp node has no deck collision before %s (%d collision shapes)" % [flag, closed_shapes])
	var closed_ok := not bool(closed.ok) and not ramp_nodes.is_empty() and closed_shapes == 0
	_check(not bool(closed.ok), "Reedhaven ramp line is not walkable before %s (%s)" % [
		flag, "blocked: " + str(closed.reason) if closed_ok else "walked %.1f m in %.1f s with nothing in the way" % [
			closed_stats.distance, closed_stats.frames / PHYSICS_HZ]])
	if bool(closed.ok):
		_defect("reedhaven_maintenance_ramp: hall %s -> departure %s is already walkable before the repair (no gate/seal)" % [
			_fmt(hall), _fmt(departure)])

	# Unlock through the production repair prompt.
	var equipment := world.get_node("WaterDocks").get_node_or_null("reedhaven_repair") as Node3D
	if not _check(equipment != null, "Production Reedhaven repair equipment exists"):
		_row("shortcut reedhaven_maintenance_ramp | closed %s | unlock FAILED" % str(closed_ok))
		return
	await _place(equipment.global_position + Vector3(3.0, 0.0, 0.0), "F2 beside Reedhaven repair prompt")
	var unlocked := await _activate_prompt(_prompt_of(equipment), "Reedhaven repair") and await _wait_flag(flag, 600)
	_check(unlocked, "Production Reedhaven repair publishes %s" % flag)
	await _frames(5)
	var open_shapes := _ramp_collision_shapes(ramp_nodes)
	_check(open_shapes > 0, "Reedhaven ramp deck collision appears on the live %s change, no reload (%d collision shapes)" % [
		flag, open_shapes])

	# Open.
	await _place(hall, "F2 Woven Hall (open walk)")
	var open_stats := _new_stats()
	var open: Dictionary = await _walk_path(_ramp_path(shortcut, departure), open_stats, "Reedhaven ramp open walk")
	_stop_stick()
	var open_ok := unlocked and open_shapes > 0 and bool(open.ok)
	_check(open_ok, "Reedhaven ramp walked end to end after %s (%s)" % [flag, str(open.get("reason", "arrived"))])
	if not bool(open.ok):
		_defect("reedhaven_maintenance_ramp: after unlock the hall -> departure line is still blocked -- %s" % str(open.reason))

	# Shorter than repeating the marsh loop.
	var normal := _marsh_loop_return(hall, departure)
	var shorter: bool = open_ok and open_stats.distance < normal
	_check(shorter, "Reedhaven ramp walk (%.1f m) is shorter than the marsh-loop return (%.1f m authored)" % [
		open_stats.distance, normal])
	_row("shortcut reedhaven_maintenance_ramp | closed %s | open/walked %s | %.1f m | %.1f s | shorter %s (normal %.1f m authored loop return)" % [
		_yn(closed_ok), _yn(open_ok), open_stats.distance, open_stats.frames / PHYSICS_HZ, _yn(shorter), normal])


func _shellwatch_channel(shortcut: Dictionary) -> void:
	var flag := str(shortcut.unlock_flag)
	var route_id := str(shortcut.route_id)
	var direct := _route(route_id)
	var sheltered := _route(route_id.replace("_direct", "_sheltered"))
	var exposed := float(_current(str(direct.current_id)).strength_m_s)
	var gentle := float(shortcut.strength_after_unlock_m_s)
	# F3 fixtures.
	game.world.flags.set_flag("water_dock_brine_steps_trial_won")
	game.world.flags.set_flag("defeated_water_trainer_solm")
	game.world.flags.set_flag("defeated_water_trainer_irva")
	await _frames(4)

	# Closed: the live field over the direct channel carries its exposed flow.
	_check(not game.world.flags.has(flag), "Shellwatch channel starts with %s unset" % flag)
	var closed_flow := _channel_flow(direct)
	var closed_ok := absf(closed_flow - exposed) < 0.01
	_check(closed_ok, "Before %s the direct channel flows at its exposed %.2f m/s (live %.3f)" % [flag, exposed, closed_flow])

	# Normal crossing: human swim over the sheltered route, with real input.
	await _place(_anchor(str(sheltered.from_anchor)), "F3 Brine Steps departure")
	var normal_stats := _new_stats()
	var normal_ok := await _swim_route(sheltered, false, false, normal_stats, "Shellwatch sheltered crossing")
	_check(normal_ok, "Sheltered Brine -> Shellwatch crossing swum end to end (%.1f m, %.1f s)" % [
		normal_stats.distance, normal_stats.frames / PHYSICS_HZ])

	# Unlock through the two production prompts; the dock completion publishes the flag.
	var docks := world.get_node("WaterDocks")
	var release := docks.get_node_or_null("shellwatch_release") as Node3D
	var pump := docks.get_node_or_null("shellwatch_pump") as Node3D
	var unlocked := release != null and pump != null
	if unlocked:
		unlocked = await _activate_prompt(_prompt_of(release), "Shellwatch resident release") \
			and await _wait_flag("water_shellwatch_residents_freed", 600)
	if unlocked:
		await _place(pump.global_position + Vector3(3.0, 0.0, 0.0), "F3 beside Shellwatch pump prompt")
		unlocked = await _activate_prompt(_prompt_of(pump), "Shellwatch dock pump") \
			and await _wait_flag("water_shellwatch_pump_disabled", 600) and await _wait_flag(flag, 600)
	_check(unlocked, "Production Shellwatch release + pump prompts publish %s" % flag)

	# Open: gentle flow, and the direct return swum end to end.
	var open_flow := _channel_flow(direct)
	var flow_ok := unlocked and absf(open_flow - gentle) < 0.01
	_check(flow_ok, "After %s the direct channel flows at %.2f m/s (live %.3f)" % [flag, gentle, open_flow])
	await _place(_anchor(str(direct.to_anchor)), "F3 Shellwatch arrival (open return)")
	var open_stats := _new_stats()
	var swum := await _swim_route(direct, true, false, open_stats, "Shellwatch direct return")
	var open_ok := flow_ok and swum
	_check(swum, "Direct Shellwatch -> Brine return swum end to end (%.1f m, %.1f s)" % [
		open_stats.distance, open_stats.frames / PHYSICS_HZ])
	var shorter: bool = open_ok and normal_ok and open_stats.distance < normal_stats.distance
	_check(shorter, "Direct return (%.1f m) is shorter than the sheltered crossing (%.1f m swum)" % [
		open_stats.distance, normal_stats.distance])
	_row("shortcut shellwatch_pump_return_channel | closed %s (%.2f m/s exposed) | open/swum %s (%.2f m/s) | %.1f m | %.1f s | shorter %s (normal sheltered %.1f m / %.1f s)" % [
		_yn(closed_ok), closed_flow, _yn(open_ok), open_flow, open_stats.distance, open_stats.frames / PHYSICS_HZ,
		_yn(shorter), normal_stats.distance, normal_stats.frames / PHYSICS_HZ])


func _deep_watch_cut(shortcut: Dictionary) -> void:
	var flag := str(shortcut.unlock_flag)
	var route_id := str(shortcut.route_id)
	var direct := _route(route_id)
	var sheltered := _route(route_id.replace("_direct", "_sheltered"))
	var exposed := float(_current(str(direct.current_id)).strength_m_s)
	var gentle := float(shortcut.strength_after_unlock_m_s)
	# F4 fixtures.
	var merged: Dictionary = CATALOG.merge_catalogue(SPECIES.table())
	if not _check(bool(merged.ok), "Water species catalogue accepts the Aquaryn fixture"):
		_row("shortcut deep_watch_current_cut | fixture FAILED")
		return
	SPECIES.table().merge(merged.catalogue, true)
	for world_flag: String in ["water_aquaryn_resolved", "water_dock_salt_crown_landing_charted",
			"water_named_deep_watch_tidecoil_resolved"]:
		game.world.flags.set_flag(world_flag)
	game.local.flags.set_flag("water_swim_stone_earned")
	game.local.flags.set_flag("water_swim_saddle_recipe_learned")
	game.inventory.add("swim_saddle", 1)
	var aquaryn: RefCounted = SPECIES.spawn("water_aquaryn")
	aquaryn.set_level(60, PROGRESSION.config())
	if not _check(game.local.party.add(aquaryn), "F4 level-60 Aquaryn fixture joins the party"):
		_row("shortcut deep_watch_current_cut | fixture FAILED")
		return
	await _frames(4)

	_check(not game.world.flags.has(flag), "Deep Watch cut starts with %s unset" % flag)
	var closed_flow := _channel_flow(direct)
	var closed_ok := absf(closed_flow - exposed) < 0.01
	_check(closed_ok, "Before %s the direct channel flows at its exposed %.2f m/s (live %.3f)" % [flag, exposed, closed_flow])

	await _place(_anchor(str(sheltered.from_anchor)), "F4 Sluice Isle departure")
	var mounted: bool = await director.summon_active_creature()
	await _frames(24)
	mounted = mounted and riding.mount()
	await _frames(8)
	if not _check(mounted and riding.is_mounted(), "F4 production summon + mount of the Aquaryn at Sluice Isle"):
		_row("shortcut deep_watch_current_cut | mount fixture FAILED")
		return
	var normal_stats := _new_stats()
	var normal_ok := await _swim_route(sheltered, false, true, normal_stats, "Deep Watch sheltered crossing")
	_check(normal_ok, "Sheltered Sluice -> Deep Watch crossing swum mounted end to end (%.1f m, %.1f s)" % [
		normal_stats.distance, normal_stats.frames / PHYSICS_HZ])

	var unlocked := false
	var chart := world.get_node("WaterDocks").get_node_or_null("deep_watch_chart") as Node3D
	if normal_ok and chart != null and riding.dismount():
		await _frames(12)
		unlocked = await _activate_prompt(_prompt_of(chart), "Deep Watch chart") and await _wait_flag(flag, 600)
	_check(unlocked, "Production Deep Watch chart prompt publishes %s" % flag)
	var open_flow := _channel_flow(direct)
	var flow_ok := unlocked and absf(open_flow - gentle) < 0.01
	_check(flow_ok, "After %s the direct channel flows at %.2f m/s (live %.3f)" % [flag, gentle, open_flow])

	var open_stats := _new_stats()
	var swum := false
	if unlocked and await _remount("Deep Watch"):
		swum = await _swim_route(direct, true, true, open_stats, "Deep Watch direct return")
	var open_ok := flow_ok and swum
	_check(swum, "Direct Deep Watch -> Sluice return swum mounted end to end (%.1f m, %.1f s)" % [
		open_stats.distance, open_stats.frames / PHYSICS_HZ])
	var shorter: bool = open_ok and normal_ok and open_stats.distance < normal_stats.distance
	_check(shorter, "Direct return (%.1f m) is shorter than the sheltered crossing (%.1f m swum)" % [
		open_stats.distance, normal_stats.distance])
	_row("shortcut deep_watch_current_cut | closed %s (%.2f m/s exposed) | open/swum %s (%.2f m/s) | %.1f m | %.1f s | shorter %s (normal sheltered %.1f m / %.1f s)" % [
		_yn(closed_ok), closed_flow, _yn(open_ok), open_flow, open_stats.distance, open_stats.frames / PHYSICS_HZ,
		_yn(shorter), normal_stats.distance, normal_stats.frames / PHYSICS_HZ])


## Strongest flow the live field assigns to this route's own current over its
## straight chord (sampled every 2 m). Endpoints where a higher-priority
## sibling owns the water are skipped by the id filter.
func _channel_flow(route: Dictionary) -> float:
	var restored: bool = game.world.flags.has("water_currents_restored")
	var id := str(route.current_id)
	var points: Array = route.polyline
	var best := 0.0
	for index in range(1, points.size()):
		var a := _v(points[index - 1])
		var b := _v(points[index])
		var steps := maxi(1, int(a.distance_to(b) / 2.0))
		for step in steps + 1:
			var p := a.lerp(b, float(step) / steps)
			p.y = 0.0
			var sample: Dictionary = world.currents.sample(p, restored)
			if str(sample.id) == id:
				best = maxf(best, (sample.velocity as Vector3).length())
	return best


func _swim_route(route: Dictionary, reverse: bool, mounted: bool, stats: Dictionary, label: String) -> bool:
	var polyline: Array = route.polyline.duplicate()
	if reverse:
		polyline.reverse()
	var targets: Array[Vector3] = []
	for raw: Array in polyline:
		targets.append(_v(raw))
	targets.append(_anchor(str(route.from_anchor if reverse else route.to_anchor)))
	# The approach from wherever the body stands to the route's first shore
	# vertex is travelled for real but not counted, so the direct and the
	# sheltered crossings are measured over the same span: shore vertex ->
	# ... -> far safe anchor.
	var approach := _new_stats()
	var entered_water := false
	for index in targets.size():
		var leg_stats: Dictionary = approach if index == 0 else stats
		var leg: Dictionary = await _travel_leg(targets[index], leg_stats, "%s point %d" % [label, index], mounted)
		if index == 0:
			print("%s: uncounted approach to shore vertex %.1f m" % [label, float(approach.distance)])
		entered_water = entered_water or bool(stats.swam) or bool(approach.swam)
		if not bool(leg.ok):
			_defect("%s: point %d %s not reached -- %s" % [label, index, _fmt(targets[index]), str(leg.reason)])
			return false
	_stop_stick()
	await _frames(6)
	return _check(entered_water, "%s actually crossed water" % label)


func _remount(label: String) -> bool:
	if director.ally_body() == null and not await director.summon_active_creature():
		return _fail(label + ": Aquaryn could not be summoned for the return")
	await _frames(20)
	var body: Node3D = director.ally_body()
	if body == null:
		return _fail(label + ": Aquaryn has no body for the return")
	if not await _walk_to(body.global_position, label + " mount approach", 2.5):
		return false
	var offer: Dictionary = riding.interaction_offer(player.global_position)
	if offer.is_empty() or not bool(offer.get("actionable", true)):
		return _fail(label + ": production Ride offer refused " + str(offer))
	riding.interaction_activate()
	await _frames(12)
	return _check(riding.is_mounted(), label + ": production Ride offer remounts the Aquaryn")


## Walk-surface collision under the ramp node(s): the physical gate.
func _ramp_collision_shapes(paths: Array[String]) -> int:
	var count := 0
	for path: String in paths:
		var node := root.get_node_or_null(NodePath(path))
		if node != null:
			count += node.find_children("*", "CollisionShape3D", true, false).size()
	return count


## The ramp row's authored walk, after its first vertex (the hall, where the
## walker is placed); the final vertex is the grounded departure anchor itself.
func _ramp_path(shortcut: Dictionary, departure: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var raw_path: Array = shortcut.get("path", [])
	for index in range(1, raw_path.size() - 1):
		points.append(_v(raw_path[index]))
	points.append(departure)
	return points


## Land legs through `points` in order; the first failing leg ends the walk.
func _walk_path(points: Array[Vector3], stats: Dictionary, label: String) -> Dictionary:
	for index in points.size():
		var leg: Dictionary = await _walk_leg(points[index], stats, "%s leg %d" % [label, index + 1])
		if not bool(leg.ok):
			return leg
	return {"ok": true}


func _marsh_loop_return(hall: Vector3, departure: Vector3) -> float:
	var loop: Array[Vector3] = []
	for row: Dictionary in world.config.land_loops:
		if str(row.id) == "reed_root_circuit":
			for raw: Array in row.polyline:
				loop.append(_v(raw))
	loop.pop_back()  # closing duplicate
	var from := _nearest(loop, hall)
	var to := _nearest(loop, departure)
	var forward := 0.0
	var index := from
	while index != to:
		forward += _flat(loop[index]).distance_to(_flat(loop[(index + 1) % loop.size()]))
		index = (index + 1) % loop.size()
	var perimeter := 0.0
	for i in loop.size():
		perimeter += _flat(loop[i]).distance_to(_flat(loop[(i + 1) % loop.size()]))
	var arc := minf(forward, perimeter - forward)
	return _flat(hall).distance_to(_flat(loop[from])) + arc + _flat(loop[to]).distance_to(_flat(departure))


func _nearest(points: Array[Vector3], to: Vector3) -> int:
	var best := 0
	for index in points.size():
		if _flat(points[index]).distance_to(_flat(to)) < _flat(points[best]).distance_to(_flat(to)):
			best = index
	return best


# ---------------------------------------------------------------- walking

func _new_stats() -> Dictionary:
	return {"distance": 0.0, "frames": 0, "held": 0, "max_drop": 0.0, "teleported": false,
		"health_lost": 0.0, "swam": false}


## Land leg: straight at `target` with real sticks. Returns {ok, reason}.
func _walk_leg(target: Vector3, stats: Dictionary, label: String) -> Dictionary:
	return await _travel_leg(target, stats, label, false, true)


## One leg of travel. `on_foot` enforces the land rules; otherwise the leg is a
## swim (human, or mounted when `mounted`).
func _travel_leg(target: Vector3, stats: Dictionary, label: String, mounted: bool,
		on_foot: bool = false) -> Dictionary:
	var body: Node3D = riding.mount_body() if mounted else player
	var start_distance := _flat(body.global_position).distance_to(_flat(target))
	var speed := 4.2 if on_foot else (8.0 if mounted else 3.0)
	var budget := int((start_distance / speed * 2.5 + 20.0) * PHYSICS_HZ)
	var history: Array[float] = []
	var previous := body.global_position
	var health := float(player.get("vitals").health)
	var airborne_from := NAN
	var walked := 0
	while walked < budget:
		if mounted and (not riding.is_mounted() or not is_instance_valid(riding.mount_body())):
			return {"ok": false, "reason": "mount lost at %s" % _fmt(previous)}
		var offset := target - body.global_position
		offset.y = 0.0
		if offset.length() <= WAYPOINT_TOLERANCE_M:
			return {"ok": true}
		if not player.locomotion_enabled() and not mounted:
			# A fight or other hold is not walking; it does not count.
			_stop_stick()
			stats.held += 1
			if stats.held > 60 * 600:
				return {"ok": false, "reason": "locomotion held for over ten minutes at %s" % _fmt(previous)}
			history.clear()
			await physics_frame
			previous = body.global_position
			continue
		_steer(offset)
		await physics_frame
		walked += 1
		stats.frames += 1
		var now := body.global_position
		var step := _flat(now).distance_to(_flat(previous))
		if step > TELEPORT_M:
			stats.teleported = true
			return {"ok": false, "reason": "teleport correction %.1f m in one frame %s -> %s" % [step, _fmt(previous), _fmt(now)]}
		stats.distance += step
		previous = now
		var lost := health - float(player.get("vitals").health)
		if lost > 0.0:
			stats.health_lost += lost
			var fall := (airborne_from - now.y) if is_finite(airborne_from) else 0.0
			return {"ok": false, "reason": "health lost %.1f at %s (swimming=%s, on_floor=%s, airborne drop so far %.2f m, last landing drop %.2f m, fight=%s, locomotion=%s)" % [
				lost, _fmt(now), str(_swimming()), str(player.is_on_floor()), fall, float(stats.get("last_drop", 0.0)),
				str(world.get_node("CombatManager").is_fighting()), str(player.locomotion_enabled())]}
		if _swimming() or mounted:
			stats.swam = stats.swam or _swimming() or world.water_depth_at(now) > 0.5
		if on_foot:
			if _swimming():
				return {"ok": false, "reason": "entered swimming at %s (water depth %.2f)" % [_fmt(now), world.water_depth_at(now)]}
			var ground: float = world.ground_height_at(now.x, now.z)
			if now.y < ground - BELOW_TERRAIN_M:
				return {"ok": false, "reason": "fell below terrain at %s (ground %.2f)" % [_fmt(now), ground]}
			if player.is_on_floor():
				if is_finite(airborne_from):
					var drop := airborne_from - now.y
					stats.last_drop = drop
					stats.max_drop = maxf(stats.max_drop, drop)
					if drop > MAX_DROP_M:
						return {"ok": false, "reason": "unwalkable drop of %.2f m landing at %s" % [drop, _fmt(now)]}
				airborne_from = NAN
			elif not is_finite(airborne_from):
				airborne_from = now.y
		history.append(_flat(now).distance_to(_flat(target)))
		if history.size() > STALL_WINDOW_FRAMES:
			history.pop_front()
			if history[0] - history[-1] < STALL_PROGRESS_M:
				_stop_stick()
				return {"ok": false, "reason": _block_reason(now, target)}
	_stop_stick()
	return {"ok": false, "reason": "leg budget exhausted %.1f m short at %s" % [
		_flat(body.global_position).distance_to(_flat(target)), _fmt(body.global_position)]}


func _block_reason(at: Vector3, target: Vector3) -> String:
	var dir := _flat(target - at).normalized()
	var here: float = world.ground_height_at(at.x, at.z)
	var ahead: float = world.ground_height_at(at.x + dir.x * 1.5, at.z + dir.y * 1.5)
	var grade := rad_to_deg(atan(absf(ahead - here) / 1.5))
	return "stalled (<%.1f m progress in %.1f s) at %s; ground %.2f -> %.2f 1.5 m ahead (%.0f deg), on_floor=%s, swimming=%s, water_depth=%.2f" % [
		STALL_PROGRESS_M, STALL_WINDOW_FRAMES / PHYSICS_HZ, _fmt(at), here, ahead, grade,
		str(player.is_on_floor()), str(_swimming()), world.water_depth_at(at)]


## Right stick turns the camera toward the heading; left stick moves along the
## heading as read through the camera's live planar basis.
func _steer(offset: Vector3) -> void:
	var direction := offset.normalized()
	var desired := atan2(-direction.x, -direction.z)
	var yaw_error := wrapf(desired - float(camera.get("yaw")), -PI, PI)
	_send_axis(JOY_AXIS_RIGHT_X, clampf(-yaw_error * 1.5, -1.0, 1.0) if absf(yaw_error) > 0.15 else 0.0)
	var local: Vector3 = camera.planar_basis().inverse() * direction
	_send_stick(local.x, local.z)


func _swimming() -> bool:
	var swim: Node = player.get("swim_controller")
	return swim != null and bool(swim.is_swimming())


func _walk_to(point: Vector3, label: String, tolerance: float = 1.3) -> bool:
	var horizontal := _flat(player.global_position).distance_to(_flat(point))
	var arrived: bool = await navigator.walk_to(point, maxi(1200, int(horizontal * 65.0)), tolerance)
	_stop_stick()
	if not arrived:
		return _fail("%s: navigator could not reach %s from %s" % [label, _fmt(point), _fmt(player.global_position)])
	await _frames(4)
	return true


func _activate_prompt(prompt: Node3D, label: String) -> bool:
	if prompt == null or not is_instance_valid(prompt):
		return _fail(label + " has no production prompt")
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var at := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.5
		var floor_y: float = world.ground_height_at(at.x, at.z)
		if is_finite(floor_y):
			at.y = floor_y + 0.1
		if not await _walk_to(at, label + " approach", 1.0):
			return false
		if not prompt.interaction_offer(player.global_position).is_empty():
			prompt.interaction_activate()
			await _frames(5)
			return true
	return _fail("%s never offered interaction from a physically reached stance" % label)


func _prompt_of(equipment: Node3D) -> Node3D:
	if equipment == null:
		return null
	for child: Node in equipment.get_children():
		if child.has_method("interaction_offer"):
			return child as Node3D
	return null


func _place(at: Vector3, label: String) -> void:
	_stop_stick()
	var point := at
	point.y = float(world.ground_height_at(at.x, at.z)) + 0.15
	# F0: each element starts healthy and rested, so one element's fall damage
	# cannot kill the player (and trigger death recovery) during the next.
	var vitals: RefCounted = player.get("vitals")
	vitals.health = vitals.max_health
	vitals.stamina = vitals.max_stamina
	player.global_position = point
	player.velocity = Vector3.ZERO
	print("FIXTURE placement: %s at %s (health/stamina refilled)" % [label, _fmt(point)])
	await _frames(20)
	_check(_flat(player.global_position).distance_to(_flat(point)) < 1.0,
		"%s placement holds (no pending recovery moved the player)" % label)


func _wait_flag(id: String, maximum_frames: int) -> bool:
	for frame in maximum_frames:
		if game.world.flags.has(id):
			return true
		await physics_frame
	return game.world.flags.has(id)


# ---------------------------------------------------------------- data

func _shortcut(id: String) -> Dictionary:
	for row: Dictionary in world.config.return_shortcuts:
		if str(row.id) == id:
			return row
	_fail("return shortcut is missing: " + id)
	return {}


func _route(id: String) -> Dictionary:
	for row: Dictionary in world.config.water_routes:
		if str(row.id) == id:
			return row
	return {}


func _current(id: String) -> Dictionary:
	for row: Dictionary in world.config.currents:
		if str(row.id) == id:
			return row
	return {}


func _landmark(id: String) -> Vector3:
	for row: Dictionary in world.config.landmarks:
		if str(row.id) == id:
			return _v(row.position)
	return Vector3.INF


func _anchor(id: String) -> Vector3:
	for row: Dictionary in world.config.anchors:
		if str(row.id) == id:
			var point := _v(row.safe_position)
			point.y = float(world.ground_height_at(point.x, point.z)) + 0.15
			return point
	return Vector3.INF


func _nodes_named(from: Node, fragment: String) -> Array[String]:
	var found: Array[String] = []
	for child: Node in from.get_children():
		if str(child.name).to_lower().contains(fragment):
			found.append(str(child.get_path()))
		found.append_array(_nodes_named(child, fragment))
	return found


func _v(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _flat(value: Vector3) -> Vector2:
	return Vector2(value.x, value.z)


func _fmt(value: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [value.x, value.y, value.z]


func _yn(value: bool) -> String:
	return "YES" if value else "NO"


# ---------------------------------------------------------------- input

func _send_stick(x: float, y: float) -> void:
	_send_axis(JOY_AXIS_LEFT_X, x)
	_send_axis(JOY_AXIS_LEFT_Y, y)


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _stop_stick() -> void:
	_send_stick(0.0, 0.0)
	_send_axis(JOY_AXIS_RIGHT_X, 0.0)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


# ---------------------------------------------------------------- reporting

func _check(ok: bool, label: String) -> bool:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok:
		failures.append(label)
	return ok


func _fail(message: String) -> bool:
	_check(false, message)
	return false


func _defect(message: String) -> void:
	defects.append(message)
	print("DEFECT: ", message)


func _row(line: String) -> void:
	table.append(line)
	print("LOOPS/SHORTCUTS +%.1fs | %s" % [(Time.get_ticks_msec() - started_ms) / 1000.0, line])


func _watchdog() -> void:
	while not finished and Time.get_ticks_msec() - started_ms < WATCHDOG_S * 1000:
		await create_timer(1.0).timeout
	if not finished:
		_fail("%d minute loops/shortcuts watchdog expired" % int(WATCHDOG_S / 60))
		_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	_stop_stick()
	print("---- WATER LOOPS/SHORTCUTS SUMMARY (%.1f s wall) ----" % ((Time.get_ticks_msec() - started_ms) / 1000.0))
	for line in table:
		print("  ", line)
	for line in defects:
		print("  DEFECT ", line)
	print("WATER LOOPS/SHORTCUTS: %d checks, %d failures, %d defects" % [checks, failures.size(), defects.size()])
	if not failures.is_empty():
		print("WATER LOOPS/SHORTCUTS FAILURES: ", failures)
	quit(0 if failures.is_empty() else 1)
