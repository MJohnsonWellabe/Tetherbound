extends SceneTree

## WO-F09 #3: ordinary walk witness for Stormwood's authored loops, far-side
## shortcuts and alternate route (WORLD §5.1; ACCEPTANCE §6.1 F09 "four loops,
## three shortcuts, five pockets and the authored alternate routes are
## physically traversable"). The five pockets are
## tests/smoke_stormwood_pocket_walks.gd's job; this smoke walks the rest:
##
##   LOOP      every `kind: "loop"` route in stormwood_world.json (five; the
##             rule needs four), each vertex in order and back to the start.
##   ALTERNATE dynamo_west_approach end to end (the 5->6 second road). The
##             3->5 second route is arch pair C, walked below.
##   SHORTCUT  ancient pairs C (c_rodline <-> c_lantern) and D (d_hall <->
##             d_giant), each relit through its ordinary Relight prompt, then
##             walked through in both directions; and the player-built "Raise
##             a Road" pair on two optional footings (verge_road,
##             hollows_road), chosen through the footings' own prompts, raised
##             through ordinary Build input, walked through both ways.
##
## Walking is the production Player driven by left-stick joypad events, through
## `smoke_stormwood_continuous.gd`'s `Segment` (its `_walk_xz`, fights,
## lightning dodges and satchel recovery, `_relight_arch`, `_activate_node`).
## Arch travel is the production Passage Area3D + session arch travel: the
## harness only walks into the threshold and watches
## `Session.stormwood_arch_arrival` and where the trainer stands afterwards.
##
## Where an authored route line runs through a lit, linked arch's opening
## (pools_west_loop crosses Lantern Pools North Arch b_pools), walking it
## straight would carry the trainer to the twin. The walk steps round the
## frame instead, as a player keeping to the road does, and prints a FINDING;
## an unexpected arch trip during a route is a FAIL. Loops are walked before
## pairs C and D are relit, so their dark arches (d_hall and d_giant stand on
## hall_loop and blackwater_loop vertices) do not carry anyone yet.
##
## DISCLOSED SEAMS (nothing else is staged):
##   1. Earned checkpoint start: `--from-save=user://swcp_a/4_core` is the
##      `4_core` checkpoint of the continuous full run
##      (ralph/reports/STORMWOOD/full_run/checkpoints/4_core.tgz), loaded by the
##      real title screen's Load. That run itself began at the disclosed
##      Cloudreach-boundary fixture (in-memory completed-Cloudreach party and
##      entitlement; see ralph/reports/STORMWOOD/full_run/README.md). The save
##      already carries `stormwood:rootgate_released`, the recipe and the paid
##      Crown pair; this smoke asserts that and writes no flag. The tree is
##      copied to a fresh user://route_walks_<pid>_<usec> first and the copy is
##      loaded, because play autosaves and must not rewrite the checkpoint.
##   2. One `Game.debug_teleport_to` per route start (onto the route's first
##      authored vertex, facing its second), per arch endpoint before its
##      relight (8 m in front of the arch) and per road footing before its
##      choice (10 m south of the footing). Between those, every metre is
##      walked.
##   3. Material grants through the inventory API, printed as they happen:
##      the relight cost (3 Stormglass) before each dark arch's prompt when the
##      satchel lacks it, and the exact shortfall of the Stormglass Arch recipe
##      (6 Stormglass, 2 Thunderwood Frame, 4 Conductor Vine) before each road
##      arch. The 4_core save carries none of these.
##   4. Clock: Engine.time_scale 8 with 480 Hz physics (the production 1/60 s
##      simulation step), as the continuous smoke. Segment keeps fights and
##      "conductor" roads at 1x/60 Hz; the Build steps also run at 1x/60 Hz.
##   5. Build placement uses ordinary input (build_shortcut, pad navigation of
##      the Build catalogue, build_place) from a stance 1.6 m in front of the
##      footing centre, so the placer's own ghost snaps onto the footing; no
##      ledger intent is submitted by the harness.
##   6. Only if the building-uid defect below comes back (it is a FAILED
##      check first): `WorldState._migrate_building_uids()` is called once, the
##      same derivation `WorldState.load_data` performs, so the road's
##      walk-through can still be witnessed. Defect (found by this smoke, fixed
##      in autoload/game_state.gd's `placed_buildings` setter with
##      tests/test_register_building.gd): the title Load restored
##      `placed_buildings` without re-deriving `WorldState.next_building_uid`,
##      so the ledger minted "b1" again beside the saved Crown arch "b1" and the
##      new arch's `building_arch_link` rewrote the Crown record instead.
##
##   godot --headless --path . --script tests/smoke_stormwood_route_walks.gd \
##     -- --from-save=user://swcp_a/4_core [--only=<route_id>|loops|c|d|road]

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const CONTINUOUS := preload("res://tests/smoke_stormwood_continuous.gd")
const ARCH_RULES := preload("res://scripts/world/stormwood_arch_rules.gd")
const BUILT := preload("res://scripts/world/stormwood_arch_build_rules.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const ROOTGATE_FLAG := "stormwood:rootgate_released"
const SCENE_WAIT_FRAMES := 7200
const WATCHDOG_S := 5100.0
const LOOP_IDS: Array[String] = ["pools_west_loop", "crown_sightline_loop", "conductor_west_loop",
	"hall_loop", "blackwater_loop"]
const ALTERNATE_ID := "dynamo_west_approach"
const ARCH_PAIRS := {"c": ["c_rodline", "c_lantern"], "d": ["d_hall", "d_giant"]}
const ROAD_FOOTINGS_USED: Array[String] = ["verge_road", "hollows_road"]
## Intermediate waypoints: linear interpolation along the authored polyline.
const WAYPOINT_SPACING_M := 40.0
const VERTEX_TOLERANCE_M := 2.5
const ARRIVAL_RADIUS_M := 12.0
## A per-physics-frame move larger than this is not walking (death respawn,
## arch travel) and is counted as a jump, not as metres.
const FRAME_JUMP_M := 3.0
## travel_for_peer refuses a second trip for 2000 ms of wall clock.
const TRAVEL_COOLDOWN_S := 2.6
const MAX_CONSECUTIVE_STALLS := 3
## A walk leg passing this close to a lit, linked arch's centre would enter
## its 2.5 m passage; the detour goes out to x = 7 m, z = 6.5 m in the
## arch's frame (the ancient footing slab is 9 m square).
const ARCH_DETOUR_TRIGGER_M := 3.5
const ARCH_DETOUR_X := 7.0
const ARCH_DETOUR_Z := 6.5
const RELIGHT_FRONT_M := 8.0
const RELIGHT_STANCE_BACK_M := 2.8
const BUILD_STANCE_M := 1.6
const GHOST_EPSILON_M := 0.75
const BUILD_MENU_GROUP := "build_menu"
const FAST_SCALE := 8.0
const FAST_HZ := 480

var _from_save := ""
var _fixture_entry := false
var _only := ""
var game: Node
var world: Node3D
var seg: Variant = null
var arches: Node3D
var routes: Array = []
var failures: Array[String] = []
var checks := 0
var finished := false
var _summary: Array[String] = []
var _details: Array[String] = []
var _seams: Array[String] = []
var _tracking := false
var _track_metres := 0.0
var _track_jumps := 0
var _track_last := Vector3.INF
var _fights := 0
var _arrivals: Array[Dictionary] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(WATCHDOG_S, true, false, true).timeout.connect(func() -> void:
		if not finished:
			_fail("watchdog expired after %d s" % int(WATCHDOG_S))
			_finish())
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			_only = argument.trim_prefix("--only=")
		elif argument.begins_with("--from-save="):
			_from_save = argument.trim_prefix("--from-save=")
		elif argument == "--fixture-entry":
			_fixture_entry = true
	if not _check(not _from_save.is_empty() or _fixture_entry,
			"--from-save=user://<dir> names the earned checkpoint (or --fixture-entry)"):
		_finish()
		return
	var entered := false
	if _fixture_entry:
		entered = await _enter_fixture()
	else:
		entered = await _enter_from_save()
	if not entered:
		_finish()
		return
	seg = CONTINUOUS.Segment.new()
	if not _check(bool(seg.bind(self, world, game)), "Segment bound the live Stormwood world: %s" % str(seg.failures)):
		_finish()
		return
	arches = world.get_node_or_null(^"StormglassArches") as Node3D
	if not _check(arches != null, "production StormglassArches runtime is mounted"):
		_finish()
		return
	(seg.manager as Node).connect("exited", func(_outcome: String) -> void: _fights += 1)
	(game.get("session") as Node).connect("stormwood_arch_arrival", _on_arrival)
	physics_frame.connect(_sample)
	routes = (world.call("config_data") as Dictionary).get("routes", [])
	await _clock(FAST_SCALE, FAST_HZ)
	_seam("SEAM 4 clock: Engine.time_scale=%.0f physics=%d Hz (fights/conductor roads/Build at 1x)" % [FAST_SCALE, FAST_HZ])
	for id: String in LOOP_IDS:
		if _wants(id):
			await _walk_route(id, "LOOP")
	if _wants(ALTERNATE_ID):
		await _walk_route(ALTERNATE_ID, "ALTERNATE")
	for pair: String in ["c", "d"]:
		if _wants(pair):
			await _ancient_pair(pair)
	if _wants("road"):
		await _raise_road()
	_finish()


func _wants(id: String) -> bool:
	return _only.is_empty() or _only == id or (_only == "loops" and LOOP_IDS.has(id))


# ------------------------------------------------------------------ seam 1

## `--fixture-entry`: no v28 mid-chapter checkpoint exists yet. Enter as
## smoke_stormwood_pocket_walks.gd does (disclosed): the in-memory
## completed-Cloudreach fixture, its opened Stormwood portal, the production
## router, then `stormwood:rootgate_released` set for the routes behind the
## Rootgate. Loops and the alternate road only; arch pairs and the road keep
## their earned-save prerequisites (recipe, paid Crown pair).
func _enter_fixture() -> bool:
	game = root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	game.set("save_system", SAVE_GAME.new("user://route_walks_fixture_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]))
	await process_frame
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "stormwood-route-walks")
	game.get("world").set("world_id", "stormwood-route-walks-world")
	for flag: String in CONTINUOUS.COMPLETED_CLOUDREACH_FLAGS:
		game.get("ledger").call("submit", {"kind": "set_world_flag", "realm": "cloudreach", "id": flag, "value": true})
	for species_id: String in CONTINUOUS.ENTRY_PARTY:
		var creature: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn(species_id)
		if creature != null:
			creature.call("set_level", 44, preload("res://scripts/creatures/progression.gd").config())
			game.get("party").call("add", creature)
	var route: Dictionary = (game.get("world").get("redesign_world") as Dictionary).duplicate(true)
	var opened: Array = (route.get("portal_unlocks", []) as Array).duplicate()
	if not opened.has("stormwood"): opened.append("stormwood")
	route["portal_unlocks"] = opened
	game.get("world").set("redesign_world", route)
	var source := Node3D.new()
	source.name = "StormwoodRouteWalksEntrySource"
	root.add_child(source)
	current_scene = source
	await process_frame
	if not _check(await game.call("enter_realm", "stormwood", "stormwood_arrival_from_cloudreach"),
			"production router accepted the fixture Stormwood entry"):
		return false
	for _frame in SCENE_WAIT_FRAMES:
		var candidate := current_scene as Node3D
		if candidate != null and candidate.name == "Stormwood" and bool(candidate.call("shell_build_complete")):
			world = candidate
			break
		await physics_frame
	if not _check(world != null, "production Stormwood scene became current"):
		return false
	for _frame in SCENE_WAIT_FRAMES:
		if str(game.get("pending_realm_entry")) == "":
			break
		await physics_frame
	game.get("progression").call("set_flag", ROOTGATE_FLAG, true)
	_seam("SEAM 1 fixture entry: in-memory completed-Cloudreach party, opened Stormwood portal, %s set (no earned checkpoint)" % ROOTGATE_FLAG)
	for _frame in 60:
		await physics_frame
	return true


func _enter_from_save() -> bool:
	game = root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	# The walk autosaves (arch relights, side-chain steps). Load a copy so the
	# earned checkpoint on disk stays exactly as the full run wrote it.
	var scratch := "user://route_walks_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	CONTINUOUS._copy_tree(ProjectSettings.globalize_path(_from_save), ProjectSettings.globalize_path(scratch))
	print("ROUTE WALKS loading a copy of %s from %s" % [_from_save, scratch])
	game.set("save_system", SAVE_GAME.new(scratch))
	await process_frame
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 30:
		await process_frame
	title.set("_host_port", 0)
	title.call("_load_slot", int(game.call("autosave_slot")))
	for _frame in SCENE_WAIT_FRAMES:
		var candidate := current_scene as Node3D
		if candidate != null and candidate.name == "Stormwood" and bool(candidate.call("shell_build_complete")):
			world = candidate
			break
		await physics_frame
	if not _check(world != null, "title Load reopened the earned Stormwood save %s" % _from_save):
		return false
	for _frame in SCENE_WAIT_FRAMES:
		if str(game.get("pending_realm_entry")) == "":
			break
		await physics_frame
	var released := bool(game.get("progression").call("has", ROOTGATE_FLAG))
	print("ROUTE WALKS earned start %s rootgate_released=%s party=%d placed_buildings=%d" % [_from_save,
		str(released), (game.get("party").call("members") as Array).size(),
		(game.get("placed_buildings") as Array).size()])
	_seam("SEAM 1 earned start: title Load of %s (4_core of the continuous full run, which began at the Cloudreach-boundary fixture)" % _from_save)
	_check(released, "the earned save carries %s" % ROOTGATE_FLAG)
	for _frame in 60:
		await physics_frame
	return true


# ------------------------------------------------------------------ routes

func _route(id: String) -> Dictionary:
	for route: Dictionary in routes:
		if str(route.get("id", "")) == id:
			return route
	return {}


## [{xz, vertex}] along the polyline: every WAYPOINT_SPACING_M, and each
## authored vertex (vertex = its index; -1 for an interpolated point).
static func densify(points: Array[Vector2], spacing: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var n := maxi(1, ceili(a.distance_to(b) / spacing))
		for k in range(1, n + 1):
			out.append({"xz": a.lerp(b, float(k) / float(n)), "vertex": i if k == n else -1})
	return out


func _walk_route(id: String, kind: String) -> void:
	var route := _route(id)
	if not _check(not route.is_empty() and (route.get("points", []) as Array).size() >= 2, "%s is authored" % id):
		_summary.append("%s %s result=FAIL (not authored)" % [kind, id])
		return
	var points: Array[Vector2] = []
	for raw: Array in route.points:
		points.append(Vector2(float(raw[0]), float(raw[1])))
	var authored := 0.0
	for i in range(1, points.size()):
		authored += points[i - 1].distance_to(points[i])
	var legs := densify(points, WAYPOINT_SPACING_M)
	print("ROUTE WALKS start %s %s: %d vertices, %d waypoints, %.0f m authored, requires=%s" % [kind, id,
		points.size(), legs.size(), authored, str(route.get("requires_unlock", ""))])
	await _ready_ally(id)
	await _teleport(points[0], points[1] - points[0], "%s start" % id)
	var fights0 := _fights
	var hits0 := int(seg.safety.counts.hits)
	var deaths0 := int(seg.safety.counts.deaths)
	var t0 := Time.get_ticks_msec()
	_begin_track()
	var vertices_reached := 0
	var waypoints_reached := 0
	var stalls: Array[String] = []
	var consecutive := 0
	var arch_findings := {}
	var findings: Array[String] = []
	for index in legs.size():
		var leg: Dictionary = legs[index]
		var xz: Vector2 = leg.xz
		var vertex := int(leg.vertex)
		var before: int = seg.failures.size()
		var label := "%s waypoint %d/%d%s" % [id, index + 1, legs.size(), " (vertex %d)" % vertex if vertex >= 0 else ""]
		var trips_before := _arrivals.size()
		var ok := true
		# A lit, linked arch standing across the authored line would carry the
		# trainer away: step round its frame, as a player keeping to the road
		# does, and record that the road runs through it.
		for detour: Dictionary in _arch_detours(_flat(seg.player.global_position), xz):
			if not arch_findings.has(str(detour.arch)):
				arch_findings[str(detour.arch)] = true
				var finding := "FINDING %s: the authored line %s crosses lit linked arch %s at (%.1f,%.1f) (%.1f m from its centre); walking it straight carries the trainer to %s, so the walk steps round the frame via %s" % [
					id, str(detour.segment), str(detour.arch), float(detour.at.x), float(detour.at.y), float(detour.miss),
					str(detour.twin), str(detour.points)]
				_detail(finding)
				findings.append(finding)
			for point: Vector2 in detour.points:
				if ok and not await seg._walk_xz(point, "%s round arch %s" % [label, str(detour.arch)], 1.2):
					ok = false
		if ok:
			ok = await seg._walk_xz(xz, label, VERTEX_TOLERANCE_M)
		if _arrivals.size() > trips_before:
			var trip: Dictionary = _arrivals[_arrivals.size() - 1]
			var tripped := "ARCH TRIP %s during %s: %s; trainer now at %s" % [id, label, _event_text(trip),
				str(seg.player.global_position)]
			seg.failures.resize(before)
			stalls.append(tripped)
			print(tripped)
			stalls.append("ABANDONED %s: an arch carried the trainer off the route" % id)
			break
		if ok:
			consecutive = 0
			waypoints_reached += 1
			if vertex >= 0:
				vertices_reached += 1
			continue
		var why := str(seg.failures[seg.failures.size() - 1]) if seg.failures.size() > before else "walk returned false"
		seg.failures.resize(before)
		var p: Vector3 = seg.player.global_position
		var next_vertex := _next_vertex(legs, index)
		var which := " = authored vertex %d" % vertex if vertex >= 0 else \
			" (toward vertex %d (%.0f,%.0f))" % [next_vertex, points[next_vertex].x, points[next_vertex].y]
		var stall := "STALL %s waypoint %d/%d target=(%.1f,%.1f)%s player=(%.1f,%.2f,%.1f) %.1f m short; ahead=%s; %s" % [
			id, index + 1, legs.size(), xz.x, xz.y, which,
			p.x, p.y, p.z, Vector2(p.x, p.z).distance_to(xz), _probe_ahead(xz), why]
		stalls.append(stall)
		print(stall)
		consecutive += 1
		if consecutive >= MAX_CONSECUTIVE_STALLS:
			stalls.append("ABANDONED %s after %d consecutive stalls" % [id, consecutive])
			break
	_end_track()
	var total_vertices := points.size() - 1
	var passed := stalls.is_empty() and vertices_reached == total_vertices
	var wall := float(Time.get_ticks_msec() - t0) / 1000.0
	var line := "%s %s vertices=%d/%d waypoints=%d/%d walked=%.0fm authored=%.0fm wall=%.0fs fights=%d lightning_hits=%d deaths=%d jumps=%d result=%s" % [
		kind, id, vertices_reached, total_vertices, waypoints_reached, legs.size(), _track_metres, authored,
		wall, _fights - fights0, int(seg.safety.counts.hits) - hits0, int(seg.safety.counts.deaths) - deaths0,
		_track_jumps, "PASS" if passed else "FAIL"]
	_check(passed, "%s %s walked end to end: %s" % [kind, id, "; ".join(stalls)])
	_summary.append(line)
	for stall: String in stalls:
		_summary.append("  " + stall)
	for finding: String in findings:
		_summary.append("  " + finding)
	print(line)


## Detours for every lit, linked arch whose opening the straight walk from
## `from` to `to` would cross: in the arch's frame, out to x = +/-ARCH_DETOUR_X
## on the near side, along to the far side, clear of the 9 m footing.
func _arch_detours(from: Vector2, to: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for child: Node in arches.get_children():
		var node := child as Node3D
		if node == null or node.get_node_or_null(^"Passage") == null or not node.visible:
			continue
		var twin: Dictionary = arches.call("_twin", str(node.name))
		if twin.is_empty():
			continue
		var centre := _flat(node.global_position)
		var closest := Geometry2D.get_closest_point_to_segment(centre, from, to)
		var miss := closest.distance_to(centre)
		if miss > ARCH_DETOUR_TRIGGER_M:
			continue
		var a := node.to_local(Vector3(from.x, node.global_position.y, from.y))
		var b := node.to_local(Vector3(to.x, node.global_position.y, to.y))
		if signf(a.z) == signf(b.z) and absf(a.z) > 0.5 and absf(b.z) > 0.5:
			continue
		var side := 1.0 if a.x + b.x >= 0.0 else -1.0
		var near_z := ARCH_DETOUR_Z * (1.0 if a.z >= 0.0 else -1.0)
		var points: Array[Vector2] = []
		for local: Vector3 in [Vector3(side * ARCH_DETOUR_X, 0.0, near_z), Vector3(side * ARCH_DETOUR_X, 0.0, -near_z)]:
			points.append(_flat(node.to_global(local)))
		out.append({"arch": str(node.name), "twin": str(twin.get("id", "")), "at": centre, "miss": miss,
			"points": points, "segment": "(%.0f,%.0f)->(%.0f,%.0f)" % [from.x, from.y, to.x, to.y]})
	return out


func _next_vertex(legs: Array[Dictionary], index: int) -> int:
	for i in range(index, legs.size()):
		if int(legs[i].vertex) >= 0:
			return int(legs[i].vertex)
	return 0


## What stands in the way: a chest-height and a knee-height ray 4 m toward
## `xz` from the trainer.
func _probe_ahead(xz: Vector2) -> String:
	var player: CharacterBody3D = seg.player
	var from := player.global_position
	var dir := Vector3(xz.x - from.x, 0.0, xz.y - from.z)
	if dir.length() < 0.01:
		return "nothing (on target)"
	dir = dir.normalized()
	var parts: Array[String] = []
	for height: float in [0.4, 1.2]:
		var origin := from + Vector3(0.0, height, 0.0)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * 4.0, 0xFFFFFFFF)
		query.exclude = [player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			parts.append("h%.1f clear" % height)
		else:
			parts.append("h%.1f %s at %.1fm (%.1f,%.1f,%.1f)" % [height, _name(hit.collider), origin.distance_to(hit.position),
				hit.position.x, hit.position.y, hit.position.z])
	var ground_here := float(world.call("ground_height_at", from.x, from.z))
	var ahead := from + dir * 3.0
	var ground_ahead := float(world.call("ground_height_at", ahead.x, ahead.z))
	parts.append("terrain rise over 3 m %.2f m" % (ground_ahead - ground_here))
	return ", ".join(parts)


func _name(collider: Variant) -> String:
	if collider is Node:
		var node := collider as Node
		return "%s/%s" % [node.get_parent().name if node.get_parent() != null else "", node.name]
	return str(collider)


# ------------------------------------------------------------------ arches

func _arch_node(id: String) -> Node3D:
	return arches.get_node_or_null(NodePath(id)) as Node3D


func _flat(at: Vector3) -> Vector2:
	return Vector2(at.x, at.z)


func _ancient_pair(pair: String) -> void:
	var ids: Array = ARCH_PAIRS[pair]
	var first := str(ids[0])
	var second := str(ids[1])
	print("ROUTE WALKS start SHORTCUT %s: %s <-> %s" % [pair, first, second])
	var relit := true
	for id: String in [first, second]:
		if not await _relight(id):
			relit = false
			break
	if not relit:
		for dir: String in ["%s->%s" % [second, first], "%s->%s" % [first, second]]:
			_summary.append("SHORTCUT %s dir=%s result=FAIL (relight failed; see details)" % [pair, dir])
			_check(false, "SHORTCUT %s %s: relight failed" % [pair, dir])
		return
	# The trainer stands behind `second` after its relight: through it, then
	# out of `first`'s landing, turn round, back through `first`.
	await _travel(pair, second, first)
	await _travel(pair, first, second)


func _relight(id: String) -> bool:
	var node := _arch_node(id)
	if not _check(node != null, "ancient arch %s is mounted" % id):
		return false
	var flags: RefCounted = game.get("progression")
	var spec := ARCH_RULES.definition(id)
	if ARCH_RULES.is_lit(spec, flags):
		_detail("RELIGHT %s already lit in the earned save" % id)
		return true
	if not _check(ARCH_RULES.is_available(spec, flags), "%s is available (Rootgate open)" % id):
		return false
	var front := node.to_global(Vector3(0.0, 0.0, RELIGHT_FRONT_M))
	await _teleport(_flat(front), _flat(node.global_position) - _flat(front), "%s front" % id)
	var cost := int(ARCH_RULES.config().relight_cost)
	var inventory: RefCounted = game.get("inventory")
	var have := int(inventory.call("count", "stormglass"))
	if have < cost:
		inventory.call("add", "stormglass", cost - have)
		_seam("SEAM 3 grant: +%d stormglass before %s's Relight prompt (had %d, cost %d)" % [cost - have, id, have, cost])
	var before := int(inventory.call("count", "stormglass"))
	var stance := node.to_global(Vector3(0.0, 0.0, -RELIGHT_STANCE_BACK_M))
	var failed_before: int = seg.failures.size()
	var ok: bool = await seg._relight_arch(id, _flat(stance), "")
	var why := "; ".join(seg.failures.slice(failed_before))
	seg.failures.resize(failed_before)
	var after := int(inventory.call("count", "stormglass"))
	var lit := ARCH_RULES.is_lit(spec, flags)
	var line := "RELIGHT %s prompt='%s' ok=%s lit=%s stormglass %d->%d player=%s %s" % [id,
		str(node.get_node(^"Relight").get("label")) if node.get_node_or_null(^"Relight") != null else "<none>", ok, lit, before, after, str(seg.player.global_position), why]
	_detail(line)
	return _check(ok and lit and after == before - cost, line)


## Walk through `source`'s threshold and expect to arrive at `target`. From a
## landing (in front) the trainer first walks out 7 m and turns round; from
## behind it first lines up 3.5 m behind. If an approach cannot get into the
## opening (the navigator steers round the frame and no trip happens), that is
## recorded as a FINDING with that side's footing-edge measurement, and the
## trainer walks through once more from whichever side it now stands on.
func _travel(pair: String, source_id: String, target_id: String) -> void:
	var dir := "%s->%s" % [source_id, target_id]
	var source := _arch_node(source_id)
	var target := _arch_node(target_id)
	if not _check(source != null and target != null, "SHORTCUT %s %s: both arches mounted" % [pair, dir]):
		_summary.append("SHORTCUT %s dir=%s result=FAIL (arch missing)" % [pair, dir])
		return
	var fights0 := _fights
	var hits0 := int(seg.safety.counts.hits)
	var t0 := Time.get_ticks_msec()
	var failed_before: int = seg.failures.size()
	_begin_track()
	var attempt := await _through_once(source, target, target_id)
	var finding := ""
	if not bool(attempt.ok) and (attempt.event as Dictionary).is_empty():
		finding = "FINDING %s: approaching from %s the trainer could not walk into %s's opening and was steered round the frame (local trail %s); %s" % [
			dir, "the front (landing side)" if str(attempt.side) == "front" else "behind", source_id, str(attempt.trail), _footing_edge(source, 1.0 if str(attempt.side) == "front" else -1.0)]
		_detail(finding)
		attempt = await _through_once(source, target, target_id)
	_end_track()
	var why := "; ".join(seg.failures.slice(failed_before))
	seg.failures.resize(failed_before)
	var event: Dictionary = attempt.event
	var here: Vector3 = seg.player.global_position
	var ok := bool(attempt.ok)
	var line := "SHORTCUT %s dir=%s approach=%s%s lined_up=%s event=%s landed=(%.1f,%.1f,%.1f) %.1f m from %s at (%.0f,%.0f) walked=%.1fm wall=%.1fs fights=%d lightning_hits=%d%s%s result=%s" % [
		pair, dir, str(attempt.side), " (retry from the other side after FINDING)" if not finding.is_empty() else "",
		attempt.lined, _event_text(event), here.x, here.y, here.z, float(attempt.distance), target_id,
		target.global_position.x, target.global_position.z, _track_metres,
		float(Time.get_ticks_msec() - t0) / 1000.0, _fights - fights0, int(seg.safety.counts.hits) - hits0,
		(" NO TRIP; local trail " + str(attempt.trail)) if not ok else "", (" " + why) if not why.is_empty() else "",
		"PASS" if ok else "FAIL"]
	_check(ok, line)
	_summary.append(line)
	if not finding.is_empty():
		_summary.append("  " + finding)
	print(line)


func _through_once(source: Node3D, target: Node3D, target_id: String) -> Dictionary:
	var local_z := source.to_local(seg.player.global_position).z
	var side := "front" if local_z >= 0.0 else "behind"
	var line_up := source.to_global(Vector3(0.0, 0.0, 7.0 if side == "front" else -3.5))
	var beyond := source.to_global(Vector3(0.0, 0.0, -3.0 if side == "front" else 3.0))
	var lined: bool = await seg._walk_xz(_flat(line_up), "%s line up (%s)" % [source.name, side], 0.8)
	# travel_for_peer refuses a second trip within 2000 ms of wall clock.
	await create_timer(TRAVEL_COOLDOWN_S, true, false, true).timeout
	_arrivals.clear()
	var navigator: RefCounted = seg.navigator
	var manager: Node = seg.manager
	var goal := Vector3(beyond.x, float(world.call("ground_height_at", beyond.x, beyond.z)), beyond.z)
	navigator.call("reset")
	var passed_without := false
	var twin_now: Dictionary = arches.call("_twin", str(source.name))
	var trail: Array[String] = ["twin=%s" % str(twin_now.get("id", ""))]
	for frame in 2400:
		if frame % 30 == 0:
			var lp := source.to_local(seg.player.global_position)
			trail.append("(%.1f,%.1f,%.1f)" % [lp.x, lp.y, lp.z])
		if not _arrivals.is_empty():
			break
		if _flat(seg.player.global_position).distance_to(_flat(beyond)) < 0.9:
			passed_without = true
			break
		if bool(navigator.call("can_walk")):
			await navigator.call("step", goal)
		elif bool(manager.call("is_fighting")):
			await seg._fight_current_encounter("%s threshold" % source.name)
			navigator.call("reset")
		else:
			seg._send_stick(0.0, 0.0)
			await physics_frame
	seg._send_stick(0.0, 0.0)
	for _frame in 20:
		await physics_frame
	var event: Dictionary = _arrivals[_arrivals.size() - 1] if not _arrivals.is_empty() else {}
	var distance := _flat(seg.player.global_position).distance_to(_flat(target.global_position))
	var ok := bool(event.get("ok", false)) and str(event.get("target", "")) == target_id \
		and distance <= ARRIVAL_RADIUS_M
	return {"ok": ok, "side": side, "lined": lined, "passed_without": passed_without, "event": event,
		"distance": distance, "trail": " ".join(trail)}


## The step at the arch footing's edge on one side (`sense` +1 front, -1
## behind): floor height just inside the 9 m slab (local |z| 4.3) against just
## outside it (local |z| 4.9): a ray down onto the slab, the terrain height
## outside.
func _footing_edge(source: Node3D, sense: float) -> String:
	var parts: Array[String] = []
	for local_x: float in [-2.0, 0.0, 2.0]:
		var inside := _floor_at(source.to_global(Vector3(local_x, 0.0, 4.3 * sense)))
		var out_at := source.to_global(Vector3(local_x, 0.0, 4.9 * sense))
		var outside := float(world.call("ground_height_at", out_at.x, out_at.z))
		var at := source.to_global(Vector3(local_x, 0.0, 4.6 * sense))
		parts.append("edge at (%.1f,%.1f): slab %.2f vs ground %.2f, step %.2f m" % [at.x, at.z, inside, outside, inside - outside])
	return "%s footing edge: %s" % ["front" if sense > 0.0 else "rear", "; ".join(parts)]


func _floor_at(at: Vector3) -> float:
	var from := Vector3(at.x, at.y + 6.0, at.z)
	var query := PhysicsRayQueryParameters3D.create(from, Vector3(at.x, at.y - 6.0, at.z), 1)
	query.exclude = [(seg.player as CharacterBody3D).get_rid()]
	var hit := (seg.player as Node3D).get_world_3d().direct_space_state.intersect_ray(query)
	return (hit.position as Vector3).y if not hit.is_empty() else NAN


func _event_text(event: Dictionary) -> String:
	if event.is_empty():
		return "none"
	if not bool(event.get("ok", false)):
		return "refused('%s')" % str(event.get("reason", ""))
	return "ok(%s->%s)" % [str(event.get("source", "")), str(event.get("target", ""))]


func _on_arrival(event: Dictionary) -> void:
	_arrivals.append(event.duplicate())


# ------------------------------------------------------------------ Raise a Road

func _socket(id: String) -> Dictionary:
	for socket: Dictionary in ARCH_RULES.config().footings:
		if str(socket.id) == id:
			return socket
	return {}


func _raise_road() -> void:
	var buildings: Array = game.get("placed_buildings")
	var standing := BUILT.records(buildings)
	var crown := 0
	var ordinary := 0
	for row: Dictionary in standing:
		if str(row.get("arch_twin", "")) == "e_crown":
			crown += 1
		else:
			ordinary += 1
	var limit := int(ARCH_RULES.config().player_pair_limit)
	var room := limit - crown - ceili(float(ordinary) / 2.0)
	var cap := "ROAD cap: player_pair_limit=%d standing crown_pairs=%d ordinary_arches=%d room_for_pairs=%d" % [
		limit, crown, ordinary, room]
	_detail(cap)
	if not _check(room >= 1, cap):
		_summary.append("SHORTCUT road result=FAIL (%s)" % cap)
		return
	# FINDING guard: the host mints "b<next_building_uid>". A title Load
	# restores placed_buildings through GameState's setter (save_game.gd), which
	# does not re-derive WorldState.next_building_uid the way
	# WorldState.load_data does, so after a Load the counter can name a live
	# record. The next building_arch_link would then rewrite that record.
	var world_state: Object = game.get("world")
	var minted := "b%d" % int(world_state.get("next_building_uid"))
	var live_uids: Array[String] = []
	for row: Variant in buildings:
		if row is Dictionary:
			live_uids.append(str((row as Dictionary).get("uid", "")))
	var collision := live_uids.has(minted)
	var finding := "ROAD uid counter after title Load: next minted uid=%s live uids=%s collision=%s" % [
		minted, str(live_uids), collision]
	_detail(finding)
	if not _check(not collision, "FINDING (game defect): %s; the first arch placed after a Load would duplicate %s and its building_arch_link would rewrite that record (the Crown pair)" % [
			finding, minted]):
		world_state.call("_migrate_building_uids")
		_seam("SEAM 6 uid counter: called WorldState._migrate_building_uids() (the derivation WorldState.load_data runs) so the road walk can still be witnessed; next uid %s -> b%d" % [
			minted, int(world_state.get("next_building_uid"))])
	var uids: Array[String] = []
	for footing: String in ROAD_FOOTINGS_USED:
		var uid := await _choose_and_build(footing)
		if uid.is_empty():
			for dir: String in ["b->a", "a->b"]:
				_summary.append("SHORTCUT road dir=%s result=FAIL (build at %s failed; see details)" % [dir, footing])
				_check(false, "SHORTCUT road %s: build at %s failed" % [dir, footing])
			return
		uids.append(uid)
	var twin := BUILT.linked_twin(uids[1], game.get("progression"), game.get("placed_buildings"))
	var road := BUILT.chosen_road(game.get("progression"), game.get("placed_buildings"))
	var linked := "ROAD pair %s(%s) <-> %s(%s) linked_twin=%s chosen_road=%s" % [uids[0], ROAD_FOOTINGS_USED[0],
		uids[1], ROAD_FOOTINGS_USED[1], str(twin.get("id", "")), str(road)]
	_detail(linked)
	_check(str(twin.get("id", "")) == uids[0], linked)
	await _travel("road", uids[1], uids[0])
	await _travel("road", uids[0], uids[1])
	for footing: String in ROAD_FOOTINGS_USED:
		_detail("ROAD departed flag %s = %s" % [footing,
			str(bool(game.get("progression").call("has", BUILT.ROAD_DEPARTED_PREFIX + footing)))])


## The footing's own "Choose this footing" prompt, then an ordinary Build of a
## Stormglass Arch on it. Returns the placed record's uid, "" on failure.
func _choose_and_build(footing: String) -> String:
	var socket := _socket(footing)
	if not _check(not socket.is_empty(), "footing %s is authored" % footing):
		return ""
	var centre := Vector2(float(socket.at[0]), float(socket.at[1]))
	await _teleport(centre + Vector2(0.0, -10.0), Vector2(0.0, 1.0), "%s footing" % footing)
	var prompts: Dictionary = arches.get("_footing_prompts")
	var prompt := prompts.get(footing) as Node3D
	var body := arches.get_node_or_null(NodePath("Footing_%s" % footing)) as Node3D
	var chosen_flag := BUILT.ROAD_CHOSEN_PREFIX + footing
	var failed_before: int = seg.failures.size()
	if not bool(game.get("progression").call("has", chosen_flag)):
		var label := str(prompt.get("label")) if prompt != null else "<none>"
		var chosen := false
		if prompt != null and body != null:
			var ok: bool = await seg._activate_node(body, prompt,
				Vector2(prompt.global_position.x, prompt.global_position.z - 1.3), "choose %s footing" % footing)
			if ok:
				chosen = await seg._wait_flag(chosen_flag, 300)
		var why := "; ".join(seg.failures.slice(failed_before))
		seg.failures.resize(failed_before)
		var line := "ROAD choose %s prompt='%s' chosen=%s %s" % [footing, label, chosen, why]
		_detail(line)
		_check(chosen, line)
	# Materials: the exact shortfall of the recipe (disclosed seam 3).
	var inventory: RefCounted = game.get("inventory")
	var anchor := Vector3(centre.x, float(world.call("ground_height_at", centre.x, centre.y)), centre.y)
	var cost: Array = BUILT.cost(anchor)
	var granted: Array[String] = []
	for need: Dictionary in cost:
		var have := int(inventory.call("count", str(need.id)))
		if have < int(need.n):
			inventory.call("add", str(need.id), int(need.n) - have)
			granted.append("+%d %s (had %d)" % [int(need.n) - have, str(need.id), have])
	if not granted.is_empty():
		_seam("SEAM 3 grant before the %s arch build: %s" % [footing, ", ".join(granted)])
	await _clock(1.0, 60)
	var uid := await _build_on(footing, centre, anchor, cost)
	await _clock(FAST_SCALE, FAST_HZ)
	return uid


func _build_on(footing: String, centre: Vector2, anchor: Vector3, cost: Array) -> String:
	var placer := get_first_node_in_group(&"build_placer")
	if not _check(placer != null, "production BuildPlacer present"):
		return ""
	var stance := centre + Vector2(0.0, -BUILD_STANCE_M)
	var failed_before: int = seg.failures.size()
	if not await seg._walk_xz(stance, "%s build stance" % footing, 0.5):
		_check(false, "ROAD %s: walk to build stance failed: %s" % [footing, "; ".join(seg.failures.slice(failed_before))])
		seg.failures.resize(failed_before)
		return ""
	if not await _select_arch_from_catalogue():
		return ""
	if not await seg._walk_xz(stance, "%s armed build stance" % footing, 0.5):
		_check(false, "ROAD %s: armed stance walk failed: %s" % [footing, "; ".join(seg.failures.slice(failed_before))])
		seg.failures.resize(failed_before)
		return ""
	var ghost: Node3D = null
	for _frame in 120:
		ghost = placer.get("_ghost") as Node3D
		if ghost != null and bool(placer.get("_ghost_ok")) \
				and _flat(ghost.global_position).distance_to(centre) <= GHOST_EPSILON_M:
			break
		await physics_frame
	ghost = placer.get("_ghost") as Node3D
	if not _check(ghost != null and bool(placer.get("_ghost_ok"))
			and _flat(ghost.global_position).distance_to(centre) <= GHOST_EPSILON_M,
			"ROAD %s: green ghost on the footing (reason='%s' ghost=%s)" % [footing, str(placer.get("_ghost_reason")),
				str(ghost.global_position) if ghost != null else "<none>"]):
		return ""
	var inventory: RefCounted = game.get("inventory")
	var before := {}
	for need: Dictionary in cost:
		before[str(need.id)] = int(inventory.call("count", str(need.id)))
	var records_before := (game.get("placed_buildings") as Array).size()
	await seg._tap(&"build_place")
	for _frame in 300:
		if (game.get("placed_buildings") as Array).size() > records_before:
			break
		await physics_frame
	var records: Array = game.get("placed_buildings")
	if not _check(records.size() == records_before + 1, "ROAD %s: one build_place added %d records" % [
			footing, records.size() - records_before]):
		return ""
	var record: Dictionary = records.back()
	var charged := true
	for need: Dictionary in cost:
		if int(inventory.call("count", str(need.id))) != int(before[str(need.id)]) - int(need.n):
			charged = false
	var line := "ROAD build %s record uid=%s footing=%s twin='%s' paid=%s at=%s charged_exact=%s" % [footing,
		str(record.get("uid", "")), str(record.get("arch_footing", "")), str(record.get("arch_twin", "")),
		str(record.get("paid", false)), str(record.get("position", [])), charged]
	_detail(line)
	if str(game.get("pending_build")) != "":
		await seg._tap(&"build_cancel")
	for _frame in 30:
		await physics_frame
	if not _check(str(record.get("id", "")) == "stormglass_arch" and str(record.get("arch_footing", "")) == footing
			and charged and _arch_node(str(record.get("uid", ""))) != null, line):
		return ""
	return str(record.uid)


## Ported from tests/helpers/stormwood_crown_build_segment.gd: open the Build
## catalogue with build_shortcut, pad-navigate to the Stormglass Arch cell,
## accept to arm it.
func _select_arch_from_catalogue() -> bool:
	var menu := _open_build_menu()
	for _attempt in 4:
		if menu != null:
			break
		for _frame in 900:
			if bool(seg.manager.call("is_fighting")):
				await seg._fight_current_encounter("Build catalogue approach")
			if bool(seg.arbiter.call("enabled")) and not paused and INPUT_OWNER.current(self) == null:
				break
			await physics_frame
		await seg._tap(&"build_shortcut")
		for _frame in 45:
			menu = _open_build_menu()
			if menu != null:
				break
			await physics_frame
	if not _check(menu != null, "controller build_shortcut opened the production Build catalogue"):
		return false
	for _category_try in 5:
		var pieces: Array = menu.call("_current_pieces") as Array
		var wanted := -1
		for index in pieces.size():
			if str((pieces[index] as Dictionary).get("id", "")) == "stormglass_arch":
				wanted = index
				break
		if wanted >= 0:
			var cells: Array = menu.get("_cell_buttons") as Array
			var focused := cells.find(root.gui_get_focus_owner())
			if not _check(focused >= 0 and wanted < cells.size(), "Stormglass Arch catalogue cell has a controller focus path"):
				return false
			var action := &"ui_right" if wanted >= focused else &"ui_left"
			for _step in absi(wanted - focused):
				await seg._tap(action)
			await seg._tap(&"ui_accept")
			for _frame in 60:
				if str(game.get("pending_build")) == "stormglass_arch" and _open_build_menu() == null:
					return true
				await physics_frame
			return _check(false, "focused Stormglass Arch accept armed and closed the catalogue (pending=%s)" % str(game.get("pending_build")))
		await seg._tap(&"menu_tab_right")
		for _frame in 8:
			await physics_frame
	return _check(false, "controller tabs reached the Stormglass Arch catalogue cell")


func _open_build_menu() -> Node:
	for node: Node in get_nodes_in_group(BUILD_MENU_GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return node
	return null


# ------------------------------------------------------------------ helpers

## Disclosed seam 2: one debug teleport, then the rig settles.
func _teleport(xz: Vector2, heading: Vector2, label: String) -> void:
	if bool(seg.manager.call("is_fighting")):
		await seg._fight_current_encounter("before teleport to " + label)
	seg._send_stick(0.0, 0.0)
	var heading_deg := rad_to_deg(atan2(heading.x, heading.y))
	var ok: bool = await game.call("debug_teleport_to", xz.x, xz.y, "", "", heading_deg)
	_seam("SEAM 2 teleport: %s (%.1f,%.1f) accepted=%s" % [label, xz.x, xz.y, ok])
	_check(ok, "debug_teleport_to accepted %s" % label)
	for _frame in 45:
		await physics_frame


func _ready_ally(label: String) -> void:
	var failed_before: int = seg.failures.size()
	if not bool(await seg._ensure_usable_ally(label)):
		_detail("ALLY before %s: %s" % [label, "; ".join(seg.failures.slice(failed_before))])
	seg.failures.resize(failed_before)


func _clock(scale: float, hz: int) -> void:
	await process_frame
	Engine.time_scale = scale
	Engine.physics_ticks_per_second = hz
	Engine.max_physics_steps_per_frame = 32 if scale > 1.0 else 8
	await process_frame


func _begin_track() -> void:
	_tracking = true
	_track_metres = 0.0
	_track_jumps = 0
	_track_last = seg.player.global_position


func _end_track() -> void:
	_tracking = false


func _sample() -> void:
	if not _tracking or seg == null or not is_instance_valid(seg.player):
		return
	var here: Vector3 = seg.player.global_position
	var step := _flat(here).distance_to(_flat(_track_last))
	if step < FRAME_JUMP_M:
		_track_metres += step
	else:
		_track_jumps += 1
		print("ROUTE WALKS jump %.1f m (%.1f,%.1f) -> (%.1f,%.1f) fighting=%s" % [step, _track_last.x, _track_last.z,
			here.x, here.z, str(bool(seg.manager.call("is_fighting")))])
	_track_last = here


func _seam(line: String) -> void:
	_seams.append(line)
	print("DISCLOSED ", line)


func _detail(line: String) -> void:
	_details.append(line)
	print(line)


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)
	return condition


func _fail(message: String) -> void:
	failures.append(message)
	print("FAIL: ", message)


func _finish() -> void:
	if finished:
		return
	finished = true
	if seg != null:
		for line: Variant in seg.failures:
			_fail("segment: %s" % str(line))
		seg._send_stick(0.0, 0.0)
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8
	print("")
	print("==== STORMWOOD ROUTE WALKS SUMMARY ====")
	for line: String in _summary:
		print(line)
	print("---- details ----")
	for line: String in _details:
		print(line)
	print("---- disclosed seams used ----")
	for line: String in _seams:
		print(line)
	if seg != null:
		print("SAFETY %s" % JSON.stringify(seg.safety.counts))
	for line: String in failures:
		print("FAILURE: ", line)
	print("Stormwood route walks smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
