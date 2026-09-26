extends "res://tests/test_case.gd"

## F07 cadence: ACCEPTANCE A7 on Cloudreach's required grounded route.
##
## The continuous chapter witness (`smoke_cloudreach_continuous.gd`) recorded an
## 885.87 s no-action stretch from the return flight to the west upper anchor.
## This is the data-level twin of that measurement, cheap enough for every run:
## it walks the harness's own itinerary over the same authored ground-route graph
## (`_navigate`: shortest path over unlocked `ground` polylines, projecting both
## ends onto the nearest edge) and counts an action where the harness logs one --
## the FIRST actionable offer of each wild body, pickup, resource node, physical
## prompt, NPC or camp that the walked line passes within its prompt radius, plus
## the interaction/battle/flight that ends every leg. A source already offered on
## an earlier leg does not reset the clock again (A7: repeated scenery does not).
##
## Gating matches runtime: a wild site exists only once its table's
## `requires_unlock` holds, a pickup only once its own `requires_unlock` holds.
## A wild body counts as an encounter within the director's engage range with
## the active companion deployed, as `smoke_cloudreach_deployed_cadence.gd`
## walks (the full harness walks without one and so never logs an Engage).

const WORLD_PATH := "res://data/config/cloudreach_world.json"
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const ENCOUNTERS_PATH := "res://data/config/cloudreach_encounters.json"
const PHYSICAL_PATH := "res://data/config/cloudreach_physical_runtime.json"
const ACT_ONE_PATH := "res://data/config/cloudreach_act_one_runtime.json"
const SCENE_RUNTIME_PATH := "res://data/config/cloudreach_scene_runtime.json"
const COMBAT_PATH := "res://data/config/combat.json"
const MOVEMENT_PATH := "res://data/config/movement.json"

## ACCEPTANCE A7: no more than 120 s of active travel without an action.
const A7_LIMIT_SECONDS := 120.0
## Prompt radii of the production providers the harness polls:
## item_cache_pickup.gd / harvest_node.gd configure 2.4 m; camps use
## cloudreach_physical_runtime.gd::camp_rest_spec's 3.2 m.
const PICKUP_RADIUS_M := 2.4
const HARVEST_RADIUS_M := 2.4
const CAMP_RADIUS_M := 3.2
## Sites carrying this key are the F07 cadence additions; the negative control
## removes them to prove the check fails on the pre-fix data.
const CADENCE_KEY := "_why_cadence_f07"

const PRE_FLIGHT: Array[String] = []
const POST_FLIGHT: Array[String] = ["fly_traversal_unlocked", "cloudreach_upper_route_unlocked",
	"cloudreach_act_ii_complete"]
const UPPER_ANCHORS: Array[String] = ["fly_traversal_unlocked", "cloudreach_upper_route_unlocked",
	"cloudreach_act_ii_complete", "storm_anchor_upper_west_disabled", "storm_anchor_upper_east_disabled"]
const SUMMIT: Array[String] = ["fly_traversal_unlocked", "cloudreach_upper_route_unlocked",
	"cloudreach_act_ii_complete", "storm_anchor_upper_west_disabled", "storm_anchor_upper_east_disabled",
	"cloudreach_upper_anchors_disabled"]
const AFTERMATH: Array[String] = ["fly_traversal_unlocked", "cloudreach_upper_route_unlocked",
	"cloudreach_act_ii_complete", "storm_anchor_upper_west_disabled", "storm_anchor_upper_east_disabled",
	"cloudreach_upper_anchors_disabled", "captain_veyra_defeated", "storm_anchor_network_disabled",
	"cloudreach_winds_restored"]
## Still-open A7 intervals, keyed "<from> -> <to>". Each must keep failing so a
## fix has to delete its row, and nothing else may exceed the limit.
## The summit bivouac is a 626 m out-and-back spur off the stronghold threshold:
## no flag changes while the player rests, so no gated data can make the walk
## back new. Closing it needs a camp/route layout decision (move the bivouac
## onto the approach or connect it to the threshold), not more scatter.
const KNOWN_OPEN := {
	"arrive:summit_bivouac -> arrive:summit_threshold": "bivouac spur return; layout decision",
}


func test_required_route_has_no_a7_empty_interval() -> void:
	var result := _measure(_data(false))
	var limit_m := A7_LIMIT_SECONDS * _walk_speed()
	var worst: Dictionary = result.worst
	print("CLOUDREACH ROUTE CADENCE " + JSON.stringify({"route_m": snappedf(result.route_m, 0.1),
		"longest_gap_m": snappedf(worst.gap_m, 0.1),
		"longest_gap_s_at_walk": snappedf(worst.gap_m / _walk_speed(), 0.1), "over_limit": result.over_limit,
		"from": worst.from, "to": worst.to, "at": worst.at, "leg": worst.leg}))
	assert_true(float(result.route_m) > 12000.0, "the modelled itinerary covers the grounded chapter route")
	for key: String in KNOWN_OPEN:
		assert_true((result.over_limit as Dictionary).has(key),
			"known-open interval %s no longer exceeds A7; delete its KNOWN_OPEN row" % key)
	assert_true(float(worst.gap_m) <= limit_m,
		"longest no-action stretch %.0f m (%.0f s at walk) from %s to %s on %s exceeds A7 %.0f s"
		% [worst.gap_m, worst.gap_m / _walk_speed(), worst.from, worst.to, worst.leg, A7_LIMIT_SECONDS])


func test_check_rejects_the_pre_fix_route_data() -> void:
	# Negative control: without the F07 cadence sites the recorded return-leg and
	# upper-plateau stretches are back, and the same measurement must fail.
	var result := _measure(_data(true))
	print("CLOUDREACH ROUTE CADENCE PRE-FIX " + JSON.stringify({
		"longest_gap_m": snappedf(result.worst.gap_m, 0.1), "from": result.worst.from,
		"to": result.worst.to, "leg": result.worst.leg, "over_limit": result.over_limit}))
	assert_true(float(result.worst.gap_m) > A7_LIMIT_SECONDS * _walk_speed(),
		"the cadence check has teeth: the pre-fix data still reads as an A7 failure")


## F07#2 route shape. The recorded 885.87 s stretch was a forced re-walk: the
## Windscar floor loop dead-ended at the aerie, so the required return from the
## aerie dais to the counterweight stair walked the whole floor loop back over
## the chain bridge to the Windscar junction and up the stair's lower flight
## (3,254 m). `windscar_counterweight_return` closes the loop from the chain
## bridge's far landing to the stair (WORLD §2.1: route edits, not scatter).
const WINDSCAR_JUNCTION := Vector3(-100, 470, 2440)
const CHAIN_BRIDGE_WEST := Vector3(-520, 430, 2720)
const PLATEAU_SUMMIT_FORK := Vector3(-180, 900, 4720)
const SUMMIT_ROAD_FIRST_BEND := Vector3(450, 900, 4660)
## Main walked 3,254 m; the loop return is ~1,700 m. Ceiling with headroom.
const WINDSCAR_RETURN_CEILING_M := 2000.0
## Route-only (no F07 cadence pairs) longest no-action stretch on the return
## leg: 1,609 m on main, 834 m after the return leg. Still over A7 route-only;
## the fly-gated return content on the floor loop carries the remainder.
const ROUTE_ONLY_RETURN_CEILING_M := 900.0


func test_windscar_return_closes_the_floor_loop() -> void:
	var data := _data(false)
	var physical: Dictionary = data.physical
	var aerie := _v(_by_id(physical.get("interactions", [])).flight_trial_start.position)
	var entered := _v(_by_id(physical.get("ground_triggers", [])).counterweight_entered.position)
	var path := _navigate(data.world, aerie, entered, POST_FLIGHT)
	var length := 0.0
	for index in path.size() - 1:
		length += path[index].distance_to(path[index + 1])
	print("CLOUDREACH WINDSCAR RETURN " + JSON.stringify({"walked_m": snappedf(length, 0.1),
		"vertices": path.map(func(at: Vector3) -> String: return "%.0f,%.0f,%.0f" % [at.x, at.y, at.z])}))
	assert_false(path.has(WINDSCAR_JUNCTION),
		"the aerie return no longer walks back to the Windscar junction (dead-end re-walk)")
	assert_false(path.has(CHAIN_BRIDGE_WEST),
		"the aerie return no longer re-crosses the chain bridge")
	assert_true(length <= WINDSCAR_RETURN_CEILING_M,
		"aerie -> counterweight stair walks %.0f m; the loop return keeps it under %.0f m"
		% [length, WINDSCAR_RETURN_CEILING_M])
	var shortcut: Dictionary = _by_id(data.world.get("routes", [])).get("windscar_counterweight_return", {})
	assert_false(shortcut.is_empty(), "the Windscar return leg is authored")
	if not shortcut.is_empty():
		assert_eq(str(shortcut.get("requires_unlock", "")), "cloudreach_upper_route_unlocked",
			"the return leg opens with the counterweight stair it feeds")
		var floor_loop: Array = _by_id(data.world.get("routes", [])).windscar_floor_loop.polyline
		var pass_line: Array = _by_id(data.world.get("routes", [])).windscar_counterweight_pass.polyline
		assert_true(floor_loop.has(shortcut.polyline[0]), "the return leg starts on a floor-loop vertex")
		assert_true(pass_line.has(shortcut.polyline[-1]), "the return leg lands on a counterweight vertex")
		var gate: Dictionary = _by_id(data.world.get("gates", [])).upper_counterweight_gate
		var gate_s := _arc_to(_points(pass_line), _v(gate.position))
		assert_true(_arc_to(_points(pass_line), _v(shortcut.polyline[-1])) < gate_s - 50.0,
			"the return leg joins the stair on the sealed gate's legal (Windscar) side")


func test_observatory_link_removes_the_east_anchor_out_and_back() -> void:
	var data := _data(false)
	var physical: Dictionary = data.physical
	var east := _prompt(_by_id(physical.get("interactions", [])).upper_anchor_east)
	var voss := _v(_by_id(data.scene_runtime.get("battle_yards", [])).officer_voss_summit_approach.road_position)
	var path := _navigate(data.world, east, voss, UPPER_ANCHORS)
	assert_false(path.has(PLATEAU_SUMMIT_FORK),
		"east anchor -> Voss no longer walks 649 m west to the plateau fork and back")
	assert_true(path.has(SUMMIT_ROAD_FIRST_BEND), "the link joins the summit road at its first bend")


func test_route_only_return_interval_and_both_offer_definitions() -> void:
	# Route-only = without the eleven F07 cadence pairs. "No companion" also
	# drops every wild body: the continuous harness walks without a deployed
	# companion, so it never logs a wild Engage offer.
	var route_only := _measure(_data(true))
	var no_companion := _measure(_data(true, true))
	var with_pairs_no_companion := _measure(_data(false, true))
	var return_gap := 0.0
	for key: String in route_only.over_limit:
		if key.contains("windscar") or key.contains("counterweight"):
			return_gap = maxf(return_gap, float(route_only.over_limit[key]))
	print("CLOUDREACH ROUTE CADENCE DEFINITIONS " + JSON.stringify({
		"route_only_deployed": {"worst_m": snappedf(route_only.worst.gap_m, 0.1),
			"over_limit": route_only.over_limit},
		"route_only_no_companion": {"worst_m": snappedf(no_companion.worst.gap_m, 0.1),
			"over_limit": no_companion.over_limit},
		"shipped_no_companion": {"worst_m": snappedf(with_pairs_no_companion.worst.gap_m, 0.1),
			"over_limit": with_pairs_no_companion.over_limit}}))
	assert_true(return_gap <= ROUTE_ONLY_RETURN_CEILING_M,
		"route-only Windscar return stretch %.0f m exceeds its %.0f m ceiling (main: 1,609 m)"
		% [return_gap, ROUTE_ONLY_RETURN_CEILING_M])


func test_cadence_sites_are_gated_native_route_pairs() -> void:
	var data := _data(false)
	var tables := _by_id(data.chapter.get("encounter_tables", []))
	var routes := _by_id(data.world.get("routes", []))
	var added := 0
	for site: Dictionary in data.encounters.get("wild_sites", []):
		if str(site.get(CADENCE_KEY, "")).is_empty():
			continue
		added += 1
		var id := str(site.id)
		assert_true(id.begins_with("road_visibility_"), "%s keeps the ROAD pair contract" % id)
		assert_false(str(site.get("_why_road_visibility_0907", "")).is_empty(),
			"%s is an explicit ROAD addition" % id)
		assert_eq(int(site.get("count", 0)), 2, "%s is one visible pair" % id)
		assert_almost_eq(float(site.get("radius_m", 0.0)), 3.0, 0.001, "%s keeps the ROAD scatter" % id)
		var table: Dictionary = tables.get(str(site.table_id), {})
		assert_false(str(table.get("requires_unlock", "")).is_empty(),
			"%s uses a gated table, so it is absent before its unlock" % id)
		var route: Dictionary = routes.get(str(site.get("cadence_route_id", "")), {})
		assert_false(route.is_empty(), "%s names the route it paces" % id)
		if route.is_empty():
			continue
		assert_false(str(route.id).begins_with("windscar_counterweight_pass"),
			"%s leaves the counterweight pass to its owner" % id)
		var projected := _project(_v(site.position), _points(route.polyline))
		assert_true(float(projected.offset_m) <= 1.01, "%s stands in the one-metre route core" % id)
		assert_almost_eq(float(site.position[1]), float(projected.height), 0.05,
			"%s keeps the authored route stratum" % id)
	assert_eq(added, 11, "F07 adds exactly eleven cadence pairs")


# --- measurement ------------------------------------------------------------

func _measure(data: Dictionary) -> Dictionary:
	var act_one: Dictionary = data.act_one
	var physical: Dictionary = data.physical
	var trainers := _by_id(data.encounters.get("trainers", []))
	var yards := _by_id(data.scene_runtime.get("battle_yards", []))
	var npcs := _by_id(data.chapter.get("npcs", []))
	var camps := _by_id(data.chapter.get("camping_contract", {}).get("camps", []))
	var nodes := _by_id(data.chapter.get("resource_tier", {}).get("nodes", []))
	var anchors := _by_id(act_one.get("anchors", []))
	var interactions := _by_id(physical.get("interactions", []))
	var triggers := _by_id(physical.get("ground_triggers", []))
	var landings := _by_id(physical.get("landing_objectives", []))
	var arrival: Dictionary = _by_id(data.world.get("routes", [])).get("arrival_gate_road", {})
	# The harness's required order (smoke_cloudreach_continuous.gd::_run). A
	# prompt target is approached 0.8 m below its authored point, as it does.
	var legs: Array[Dictionary] = [
		{"leg": "arrival_to_aila", "to": _v(npcs.warden_aila.position), "flags": PRE_FLIGHT},
		{"leg": "lower_west_anchor", "to": _v(anchors.lower_west.position), "flags": PRE_FLIGHT},
		{"leg": "causeway_fiber", "to": _v(nodes.cr_node_gale_fiber_causeway.position), "flags": PRE_FLIGHT},
		{"leg": "lower_east_anchor", "to": _v(anchors.lower_east.position), "flags": PRE_FLIGHT},
		{"leg": "senn", "to": _v(yards.tether_lieutenant_senn.road_position), "flags": PRE_FLIGHT},
		{"leg": "causeway_signal", "to": _prompt(interactions.causeway_signal), "flags": PRE_FLIGHT},
		{"leg": "maela_trial", "to": _v(trainers.keeper_maela_trial.position), "flags": PRE_FLIGHT},
		# Trial, shrine and return glide are flight-waypoint actions; the harness
		# lands back on the aerie launch dais.
		{"leg": "return_glide", "land": _v(interactions.flight_trial_start.position)},
		{"leg": "counterweight_pass", "to": _v(triggers.counterweight_entered.position), "flags": POST_FLIGHT},
		{"leg": "upper_anchor_west", "to": _prompt(interactions.upper_anchor_west), "flags": POST_FLIGHT},
		{"leg": "upper_anchor_east", "to": _prompt(interactions.upper_anchor_east), "flags": POST_FLIGHT},
		{"leg": "voss", "to": _v(yards.officer_voss_summit_approach.road_position), "flags": UPPER_ANCHORS},
		{"leg": "summit_feed", "to": _prompt(interactions.summit_feed), "flags": UPPER_ANCHORS},
		{"leg": "summit_bivouac", "to": _v(camps.summit_bivouac.position), "flags": SUMMIT},
		{"leg": "summit_threshold", "to": _v(triggers.summit_threshold.position), "flags": SUMMIT},
		# Veyra, the relay exam and the deck exit are fight/interaction actions.
		{"leg": "finale", "land": _v(triggers.summit_threshold.position)},
		{"leg": "aftermath_overlook", "to": _v(landings.survey_waterward.position), "flags": AFTERMATH},
	]
	var at := _v(arrival.polyline[0])
	var arc := 0.0
	var offered: Dictionary = {}
	var events: Array[Dictionary] = [{"arc": 0.0, "id": "arrival", "leg": "arrival_to_aila", "at": at}]
	for leg: Dictionary in legs:
		if leg.has("land"):
			at = leg.land
			events.append({"arc": arc, "id": "flight:" + str(leg.leg), "leg": str(leg.leg), "at": at})
			continue
		var path := _navigate(data.world, at, leg.to, leg.flags)
		var sources := _sources(data, leg.flags)
		var hits: Array[Dictionary] = []
		var start := arc
		for index in path.size() - 1:
			var a: Vector3 = path[index]
			var b: Vector3 = path[index + 1]
			var length := a.distance_to(b)
			if length <= 0.001:
				continue
			for source: Dictionary in sources:
				var closest := Geometry3D.get_closest_point_to_segment(source.at, a, b)
				var offset: float = (source.at as Vector3).distance_to(closest)
				if offset > float(source.radius):
					continue
				var along := start + a.distance_to(closest) - sqrt(float(source.radius) ** 2 - offset ** 2)
				hits.append({"arc": maxf(along, arc), "id": source.id, "leg": str(leg.leg), "at": closest})
			start += length
		hits.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.arc) < float(y.arc))
		for hit: Dictionary in hits:
			if offered.has(hit.id):
				continue
			offered[hit.id] = true
			events.append(hit)
		arc = start
		at = leg.to
		events.append({"arc": arc, "id": "arrive:" + str(leg.leg), "leg": str(leg.leg), "at": at})
	events.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.arc) < float(y.arc))
	var worst := {"gap_m": 0.0, "from": "", "to": "", "at": "", "leg": ""}
	var over: Dictionary = {}
	var limit_m := A7_LIMIT_SECONDS * _walk_speed()
	for index in range(1, events.size()):
		var gap := float(events[index].arc) - float(events[index - 1].arc)
		var key := "%s -> %s" % [events[index - 1].id, events[index].id]
		if gap > limit_m:
			over[key] = gap
		if KNOWN_OPEN.has(key):
			continue
		if gap > float(worst.gap_m):
			worst = {"gap_m": gap, "from": str(events[index - 1].id), "to": str(events[index].id),
				"at": "%s -> %s" % [events[index - 1].at, events[index].at], "leg": str(events[index].leg)}
	return {"route_m": arc, "worst": worst, "over_limit": over}


func _sources(data: Dictionary, flags: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var tables := _by_id(data.chapter.get("encounter_tables", []))
	var engage := float(data.combat.get("flow", {}).get("engage_range", 6.0))
	for site: Dictionary in data.encounters.get("wild_sites", []):
		var gate := str(tables.get(str(site.table_id), {}).get("requires_unlock", ""))
		if not gate.is_empty() and not flags.has(gate):
			continue
		# A wild body wanders within its site radius; engage is measured to the body.
		out.append({"id": "wild:" + str(site.id), "at": _v(site.position),
			"radius": engage + float(site.get("radius_m", 0.0))})
	var overrides: Dictionary = data.physical.get("pickup_overrides", {})
	for pickup: Dictionary in data.chapter.get("pickups", []):
		var gate := str(pickup.get("requires_unlock", ""))
		if not gate.is_empty() and not flags.has(gate):
			continue
		out.append({"id": "pickup:" + str(pickup.id),
			"at": _v(overrides.get(str(pickup.id), pickup.position)), "radius": PICKUP_RADIUS_M})
	for node: Dictionary in data.chapter.get("resource_tier", {}).get("nodes", []):
		out.append({"id": "node:" + str(node.id), "at": _v(node.position), "radius": HARVEST_RADIUS_M})
	var prompt_radius := float(data.physical.get("interaction_radius_m", 3.8))
	for prompt: Dictionary in data.physical.get("interactions", []):
		out.append({"id": "prompt:" + str(prompt.id), "at": _v(prompt.position), "radius": prompt_radius})
	var npc_overrides: Dictionary = data.physical.get("npc_position_overrides", {})
	for npc: Dictionary in data.chapter.get("npcs", []):
		out.append({"id": "npc:" + str(npc.id), "at": _v(npc_overrides.get(str(npc.id), npc.position)),
			"radius": float(data.encounters.get("trainer_prompt_radius_m", 4.2))})
	for camp: Dictionary in data.chapter.get("camping_contract", {}).get("camps", []):
		var gate := str(camp.get("requires_flag", ""))
		if not gate.is_empty() and not flags.has(gate):
			continue
		out.append({"id": "camp:" + str(camp.id), "at": _v(camp.position), "radius": CAMP_RADIUS_M})
	return out


## Same graph and endpoint projection as smoke_cloudreach_continuous.gd::_navigate.
func _navigate(world: Dictionary, from: Vector3, target: Vector3, flags: Array[String]) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var edges: Array = []
	for route: Dictionary in world.get("routes", []):
		var gate := str(route.get("requires_unlock", ""))
		if str(route.traversal_mode) != "ground" or (not gate.is_empty() and not flags.has(gate)):
			continue
		var previous := -1
		for raw: Array in route.polyline:
			var point := _v(raw)
			var index := points.find(point)
			if index < 0:
				index = points.size()
				points.append(point)
			if previous >= 0:
				edges.append([previous, index])
			previous = index
	var endpoints: Array[int] = []
	for point: Vector3 in [from, target]:
		var best := INF
		var chosen: Array = []
		var projected := Vector3.ZERO
		for edge: Array in edges:
			var closest := Geometry3D.get_closest_point_to_segment(point, points[edge[0]], points[edge[1]])
			if point.distance_to(closest) < best:
				best = point.distance_to(closest)
				chosen = edge
				projected = closest
		var index := points.size()
		points.append(projected)
		endpoints.append(index)
		edges.append([index, chosen[0]])
		edges.append([index, chosen[1]])
	var distances: Dictionary = {endpoints[0]: 0.0}
	var previous_of: Dictionary = {}
	var open: Array[int] = [endpoints[0]]
	while not open.is_empty():
		open.sort_custom(func(a: int, b: int) -> bool: return float(distances[a]) < float(distances[b]))
		var current: int = open.pop_front()
		if current == endpoints[1]:
			break
		for edge: Array in edges:
			var next: int = edge[1] if edge[0] == current else (edge[0] if edge[1] == current else -1)
			if next < 0:
				continue
			var cost := float(distances[current]) + points[current].distance_to(points[next])
			if cost < float(distances.get(next, INF)):
				distances[next] = cost
				previous_of[next] = current
				if next not in open:
					open.append(next)
	assert_true(distances.has(endpoints[1]), "an unlocked ground route reaches %s" % target)
	var path: Array[Vector3] = [target]
	var cursor := endpoints[1]
	while distances.has(endpoints[1]):
		path.push_front(points[cursor])
		if cursor == endpoints[0]:
			break
		cursor = previous_of[cursor]
	path.push_front(from)
	return path


# --- data -------------------------------------------------------------------

func _data(without_cadence_sites: bool, without_wild: bool = false) -> Dictionary:
	var encounters := _json(ENCOUNTERS_PATH)
	if without_wild:
		encounters["wild_sites"] = []
	if without_cadence_sites:
		var kept: Array = []
		for site: Dictionary in encounters.get("wild_sites", []):
			if str(site.get(CADENCE_KEY, "")).is_empty():
				kept.append(site)
		encounters["wild_sites"] = kept
	return {"world": _json(WORLD_PATH), "chapter": _json(CHAPTER_PATH), "encounters": encounters,
		"physical": _json(PHYSICAL_PATH), "act_one": _json(ACT_ONE_PATH),
		"scene_runtime": _json(SCENE_RUNTIME_PATH), "combat": _json(COMBAT_PATH)}


func _walk_speed() -> float:
	return float(_json(MOVEMENT_PATH).get("locomotion", {}).get("walk_speed", 5.0))


func _prompt(spec: Dictionary) -> Vector3:
	return _v(spec.position) - Vector3.UP * 0.8


func _arc_to(line: Array[Vector3], at: Vector3) -> float:
	var best := INF
	var best_s := 0.0
	var walked := 0.0
	for index in line.size() - 1:
		var closest := Geometry3D.get_closest_point_to_segment(at, line[index], line[index + 1])
		if at.distance_to(closest) < best:
			best = at.distance_to(closest)
			best_s = walked + line[index].distance_to(closest)
		walked += line[index].distance_to(line[index + 1])
	return best_s


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _by_id(rows: Array) -> Dictionary:
	var out: Dictionary = {}
	for row: Variant in rows:
		if row is Dictionary and (row as Dictionary).has("id"):
			out[str(row.id)] = row
	return out


func _v(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _points(raw: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for point: Array in raw:
		out.append(_v(point))
	return out


func _project(at: Vector3, points: Array[Vector3]) -> Dictionary:
	var best := {"offset_m": INF, "height": NAN}
	var flat := Vector2(at.x, at.z)
	for index in points.size() - 1:
		var a := Vector2(points[index].x, points[index].z)
		var b := Vector2(points[index + 1].x, points[index + 1].z)
		if a.distance_squared_to(b) <= 0.001:
			continue
		var along := clampf((flat - a).dot(b - a) / a.distance_squared_to(b), 0.0, 1.0)
		var offset := flat.distance_to(a.lerp(b, along))
		if offset < float(best.offset_m):
			best = {"offset_m": offset, "height": lerpf(points[index].y, points[index + 1].y, along)}
	return best
