extends "res://tests/test_case.gd"

## F15#2 (ACCEPTANCE §6.1 F15 / T3): "follow the measured physical return
## without an A7 empty interval". WORLD §6.5 fixes the route: First Shore's
## Stormwood passage, Stormwood's Cloudreach return gate, Cloudreach's Meadows
## return gate, then Grandpa's home. No new gate, ferry or teleport.
##
## This is the data-level measurement, the same method as
## test_cloudreach_route_cadence.gd: walk the authored route graph of each realm
## in the return direction and record the first actionable offer of every
## source the line passes within its prompt radius, then time the gaps.
##
## A7 (ACCEPTANCE §2): no more than 120 s of active travel without a meaningful
## choice, reveal, encounter, discovery or useful preparation. Repeated scenery
## does not reset the clock, so on a return journey only sources that are LIVE
## again count. Two definitions are measured:
##   return_live -- ordinary wild sites (WORLD §2: they repopulate after two
##     600 s world days once every player has left the region, which the return
##     satisfies for every realm the player crossed hours earlier), NPCs whose
##     dialogue changes after the ending, camps, and the realm gates themselves;
##   no_respawn  -- the same without any wild body (WORLD §2: the route must
##     still clear with no respawn at all).
## Once-only sources never count: pickups, trainers, named fights, quest prompts
## and permanent harvests (harvest_node.gd::_deactivate frees a gathered node for
## good, so the outward journey may already have taken it).
##
## Speeds are the conservative on-foot ones (movement.json walk, water_swimming
## human swim) so a gap measured here cannot be hidden by a mount. The total
## return time is also reported at the best legal travel mode per realm.

const A7_LIMIT_S := 120.0
const MOVEMENT_PATH := "res://data/config/movement.json"
const COMBAT_PATH := "res://data/config/combat.json"
const CAMP_RADIUS_M := 3.2
## npc_body.gd's greet prompt radius (the default every realm's NPC uses).
const NPC_PROMPT_RADIUS_M := 3.8
const GATE_RADIUS_M := 4.0

var _cache: Dictionary = {}


# --- shared walker -----------------------------------------------------------

## A leg is an ordered list of segments {"mode": "walk"|"swim", "points": [Vector2]}
## plus the sources live on it. Returns the timed events and the gaps.
func _walk_leg(realm: String, segments: Array, sources: Array, speeds: Dictionary,
		offered: Dictionary, t0: float) -> Dictionary:
	var events: Array[Dictionary] = []
	var t := t0
	var metres := {"walk": 0.0, "swim": 0.0}
	var samples: Array = []
	for segment: Dictionary in segments:
		var points: Array = segment.points
		var speed := float(speeds[segment.mode])
		for index in points.size() - 1:
			var a: Vector2 = points[index]
			var b: Vector2 = points[index + 1]
			var length := a.distance_to(b)
			if length <= 0.001:
				continue
			var hits: Array[Dictionary] = []
			for source: Dictionary in sources:
				if source.has("modes") and not (source.modes as Array).has(segment.mode):
					continue
				var closest := Geometry2D.get_closest_point_to_segment(source.at, a, b)
				var offset := (source.at as Vector2).distance_to(closest)
				if offset > float(source.radius):
					continue
				var along := maxf(0.0, a.distance_to(closest) - sqrt(float(source.radius) ** 2 - offset ** 2))
				hits.append({"t": t + along / speed, "id": source.id, "kind": source.kind, "realm": realm})
			hits.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.t) < float(y.t))
			for hit: Dictionary in hits:
				if offered.has(hit.id):
					continue
				offered[hit.id] = true
				events.append(hit)
			samples.append([t, t + length / speed, a, b])
			t += length / speed
			metres[segment.mode] = float(metres[segment.mode]) + length
	return {"events": events, "t_end": t, "metres": metres, "samples": samples}


## Where the walker was at time `t` (for naming a gap's midpoint on the map).
func _position_at(samples: Array, t: float) -> Vector2:
	for sample: Array in samples:
		if t <= float(sample[1]):
			var span := maxf(0.001, float(sample[1]) - float(sample[0]))
			return (sample[2] as Vector2).lerp(sample[3], clampf((t - float(sample[0])) / span, 0.0, 1.0))
	return samples[samples.size() - 1][3] if not samples.is_empty() else Vector2.ZERO


## Longest gaps between consecutive events (seconds), over A7 or not.
func _gaps(events: Array, t_start: float, t_end: float, start_id: String, end_id: String) -> Array[Dictionary]:
	var timeline: Array[Dictionary] = [{"t": t_start, "id": start_id}]
	timeline.append_array(events)
	timeline.append({"t": t_end, "id": end_id})
	var out: Array[Dictionary] = []
	for index in range(1, timeline.size()):
		out.append({"gap_s": float(timeline[index].t) - float(timeline[index - 1].t),
			"from": str(timeline[index - 1].id), "to": str(timeline[index].id),
			"t_from": float(timeline[index - 1].t), "t_to": float(timeline[index].t)})
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.gap_s) > float(y.gap_s))
	return out


# --- Water: Veilfall exit -> First Shore's Stormwood gate ----------------------

## The dock chain, Veilfall end first. Each entry is (island spine, swim that
## arrives on it from the previous island in return order).
const WATER_CHAIN := [
	["veilfall_exploration_spine", "sluice_isle_to_veilfall_sheltered"],
	["sluice_isle_exploration_spine", "salt_crown_to_sluice_isle_sheltered"],
	["salt_crown_exploration_spine", "tidal_cradle_to_salt_crown_sheltered"],
	["tidal_cradle_exploration_spine", "shellwatch_to_tidal_cradle_sheltered"],
	["shellwatch_exploration_spine", "brine_steps_to_shellwatch_sheltered"],
	["brine_steps_exploration_spine", "reedhaven_to_brine_steps_sheltered"],
	["reedhaven_exploration_spine", "first_shore_to_reedhaven_sheltered"],
]


func _water_segments() -> Array:
	var world := _json("res://data/config/water_world.json")
	var land := _by_id(world.land_routes)
	var swims := _by_id(world.water_routes)
	var gate: Array = world.entry_anchors.return_to_stormwood.position
	var segments: Array = []
	for pair: Array in WATER_CHAIN:
		# Spines run arrival -> departure (Veilfall's ends at the passage), so
		# the return walks each one backwards, then swims its arrival leg back.
		var spine: Array = land[pair[0]].polyline.duplicate()
		spine.reverse()
		segments.append({"mode": "walk", "points": _xz_all(spine), "id": pair[0]})
		var swim: Array = swims[pair[1]].polyline.duplicate()
		swim.reverse()
		segments.append({"mode": "swim", "points": _xz_all(swim), "id": pair[1]})
	var landing: Array = world.entry_anchors.from_stormwood.position
	segments.append({"mode": "walk", "points": [_xz(landing), _xz(gate)], "id": "first_shore_gate_walk"})
	# Spines run between anchor safe positions and swims between shore
	# positions: walk the short dock leg between each pair so no metre of the
	# return is skipped.
	var joined: Array = []
	for segment: Dictionary in segments:
		if not joined.is_empty():
			var last: Array = joined[joined.size() - 1].points
			var first: Vector2 = (segment.points as Array)[0]
			if (last[last.size() - 1] as Vector2).distance_to(first) > 0.01:
				joined.append({"mode": "walk", "points": [last[last.size() - 1], first], "id": "dock_leg"})
		joined.append(segment)
	return joined


func _water_sources(with_wilds: bool) -> Array:
	var world := _json("res://data/config/water_world.json")
	var centres: Dictionary = {}
	for island: Dictionary in world.islands:
		centres[str(island.id)] = Vector2(float(island.center_xz_m[0]), float(island.center_xz_m[1]))
	var out: Array = []
	var engage := float(_json(COMBAT_PATH).get("flow", {}).get("engage_range", 6.0))
	if with_wilds:
		for site: Dictionary in _json("res://data/config/water_encounters.json").wild_sites:
			var habitat := str(site.get("habitat", "land"))
			out.append({"id": "water:wild:" + str(site.id), "kind": "encounter", "at": _xz(site.position),
				"radius": engage + float(site.get("radius_m", 0.0)),
				"modes": ["walk"] if habitat == "land" else ["swim", "walk"]})
	for npc: Dictionary in _json("res://data/config/water_characters.json").npcs:
		# Every Water NPC gains a water_currents_restored line (aftermath).
		if not JSON.stringify(npc.get("greeting_when", [])).contains("water_currents_restored"):
			continue
		var offset: Array = npc.island_local_offset
		var at: Vector2 = centres[str(npc.island_id)] + Vector2(float(offset[0]), float(offset[2]))
		out.append({"id": "water:npc:" + str(npc.id), "kind": "aftermath_npc", "at": at,
			"radius": NPC_PROMPT_RADIUS_M, "modes": ["walk"]})
	for camp: Dictionary in _json("res://data/config/water_camps.json").camps:
		out.append({"id": "water:camp:" + str(camp.id), "kind": "camp",
			"at": Vector2(float(camp.at[0]), float(camp.at[1])), "radius": CAMP_RADIUS_M, "modes": ["walk"]})
	var gate: Array = world.entry_anchors.return_to_stormwood.position
	out.append({"id": "water:gate:return_to_stormwood", "kind": "gate", "at": _xz(gate), "radius": GATE_RADIUS_M,
		"modes": ["walk"]})
	return out


func _water_speeds() -> Dictionary:
	return {"walk": _walk_speed(),
		"swim": float(_json("res://data/config/water_swimming.json").human.speed_m_s)}


func test_water_return_has_no_a7_empty_interval() -> void:
	var result := _walk_leg("water", _water_segments(), _water_sources(true), _water_speeds(), {}, 0.0)
	var gaps := _gaps(result.events, 0.0, result.t_end, "veilfall_passage_exit", "stormwood_gate")
	print("TIDEWAKE RETURN WATER " + JSON.stringify({
		"walk_m": snappedf(result.metres.walk, 1.0), "swim_m": snappedf(result.metres.swim, 1.0),
		"seconds": snappedf(result.t_end, 1.0), "events": result.events.size(),
		"worst": gaps.slice(0, 3).map(func(g: Dictionary) -> String:
			return "%.0fs %s -> %s" % [g.gap_s, g.from, g.to])}))
	assert_true(float(result.metres.walk) > 4000.0, "the Water return walks every island spine")
	assert_true(float(result.metres.swim) > 1500.0, "the Water return swims every sheltered crossing")
	assert_true(float(gaps[0].gap_s) <= A7_LIMIT_S, "Water return: %.0f s from %s to %s exceeds A7 %.0f s"
		% [gaps[0].gap_s, gaps[0].from, gaps[0].to, A7_LIMIT_S])


## Negative control: without Pierwright Rowan beside the Reedhaven spine the
## 151 s Brine Steps camp -> Stormwood gate stretch is back.
func test_water_check_has_teeth() -> void:
	var sources := _water_sources(true).filter(func(source: Dictionary) -> bool:
		return str(source.id) != "water:npc:water_rowan")
	var result := _walk_leg("water", _water_segments(), sources, _water_speeds(), {}, 0.0)
	var gaps := _gaps(result.events, 0.0, result.t_end, "veilfall_passage_exit", "stormwood_gate")
	assert_true(float(gaps[0].gap_s) > A7_LIMIT_S, "the Water cadence check fails the pre-fix placement")
	assert_eq(str(gaps[0].to), "water:gate:return_to_stormwood", "the pre-fix gap ends at the Stormwood gate")


# --- Stormwood: Water arrival deck -> Cloudreach return gate --------------------

## After the Tidewake ending every Stormwood unlock is held (the player crossed
## Stormwood's whole route and its finale before entering Water). Lit arches
## are a player choice with a relight cost, so they are measured separately.
func _stormwood_segments(use_arches: bool) -> Array:
	var world := _json("res://data/config/stormwood_world.json")
	var polylines: Array = []
	for route: Dictionary in world.routes:
		polylines.append(_xz_all(route.points))
	# A lit arch pair is a teleport (stormwood_arch_runtime.gd moves the body to
	# the twin), so it joins the graph as a zero-cost hop and splits the walk.
	var portals: Array = []
	if use_arches:
		# Each arch row is one end; the two ends of a pair share its letter.
		var ends: Dictionary = {}
		for arch: Dictionary in _json("res://data/config/stormwood_arches.json").get("arches", []):
			var pair := str(arch.get("pair", ""))
			ends[pair] = (ends.get(pair, []) as Array) + [_xz(arch.at)]
		for pair: String in ends:
			if (ends[pair] as Array).size() == 2:
				portals.append(ends[pair])
	var deck: Vector2 = _xz(world.transition_points.water_departure.position)
	var gate: Vector2 = _xz(world.transition_points.cloudreach_return.position)
	# The Stormheart ramps from the deck to the tree base are scene geometry,
	# not route data; the straight drop to the deepwood road's end stands in.
	return _split_at_portals(_navigate2d(polylines, deck, gate, portals), portals, "stormwood_roads")


## Walk segments between portal hops; the hop itself takes no travel time.
func _split_at_portals(path: Array, portals: Array, id: String) -> Array:
	var segments: Array = []
	var current: Array = [path[0]]
	for index in range(1, path.size()):
		var a: Vector2 = path[index - 1]
		var b: Vector2 = path[index]
		var hop := false
		for pair: Array in portals:
			if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
				hop = true
		if hop:
			segments.append({"mode": "walk", "points": current, "id": id})
			current = [b]
		else:
			current.append(b)
	segments.append({"mode": "walk", "points": current, "id": id})
	return segments


func _stormwood_sources(with_wilds: bool) -> Array:
	var out: Array = []
	var engage := float(_json(COMBAT_PATH).get("flow", {}).get("engage_range", 6.0))
	var dialogue: Dictionary = _json("res://data/dialogue/stormwood.json").conversations
	if with_wilds:
		for cluster: Dictionary in _json("res://data/config/stormwood_encounters.json").wild_clusters:
			out.append({"id": "stormwood:wild:" + str(cluster.id), "kind": "encounter", "at": _xz(cluster.position),
				"radius": engage + float(cluster.get("radius", 0.0))})
	for npc: Dictionary in _json("res://data/config/stormwood_npcs.json").characters:
		# stormwood_chapter.gd branches every NPC to <id>_post_storm once the
		# Long Storm ends; the player left Stormwood from the Dynamo deck, so
		# the return is the first walk past these lines.
		if not dialogue.has("stormwood_%s_post_storm" % npc.id):
			continue
		out.append({"id": "stormwood:npc:" + str(npc.id), "kind": "aftermath_npc", "at": _xz(npc.position),
			"radius": NPC_PROMPT_RADIUS_M})
	for camp: Dictionary in _json("res://data/config/stormwood_camps.json").camps:
		out.append({"id": "stormwood:camp:" + str(camp.id), "kind": "camp",
			"at": Vector2(float(camp.at[0]), float(camp.at[1])), "radius": CAMP_RADIUS_M})
	var gate: Array = _json("res://data/config/stormwood_world.json").transition_points.cloudreach_return.position
	out.append({"id": "stormwood:gate:cloudreach_return", "kind": "gate", "at": _xz(gate), "radius": GATE_RADIUS_M})
	return out


# --- Cloudreach: Stormwood arrival (summit) -> Meadows return gate -------------

## Cloudreach stacks cliff levels in plan, so its graph joins only at exact
## shared vertices, as smoke_cloudreach_continuous.gd::_navigate does; every
## ground route is open once the chapter's aftermath flags are held.
func _cloudreach_segments() -> Array:
	var world := _json("res://data/config/cloudreach_world.json")
	var polylines: Array = []
	for route: Dictionary in world.routes:
		if str(route.traversal_mode) == "ground":
			polylines.append(_xz_all(route.polyline))
	var arrival: Vector2 = _xz(world.transition_points.stormwood_return.position)
	var gate: Vector2 = _xz(world.transition_points.meadows_return.position)
	return [{"mode": "walk", "points": _navigate2d(polylines, arrival, gate, [], false), "id": "cloudreach_ground"}]


func _cloudreach_sources(with_wilds: bool) -> Array:
	var out: Array = []
	var engage := float(_json(COMBAT_PATH).get("flow", {}).get("engage_range", 6.0))
	var chapter := _json("res://data/config/cloudreach_chapter.json")
	var physical := _json("res://data/config/cloudreach_physical_runtime.json")
	var dialogue: Dictionary = _json("res://data/dialogue/cloudreach.json").get("conversations", {})
	if with_wilds:
		for site: Dictionary in _json("res://data/config/cloudreach_encounters.json").wild_sites:
			out.append({"id": "cloudreach:wild:" + str(site.id), "kind": "encounter", "at": _xz(site.position),
				"radius": engage + float(site.get("radius_m", 0.0))})
	var overrides: Dictionary = physical.get("npc_position_overrides", {})
	# cloudreach_npc_runtime.json position_when relocates a body once its flag
	# holds; after the ending every aftermath flag does (Aila moves to the summit).
	var relocated: Dictionary = {}
	for runtime_npc: Dictionary in _json("res://data/config/cloudreach_npc_runtime.json").get("npcs", []):
		for branch: Dictionary in runtime_npc.get("position_when", []):
			if str(branch.get("if_flag", "")) == "cloudreach_winds_restored":
				relocated[str(runtime_npc.id)] = branch.position
	for npc: Dictionary in chapter.npcs:
		# Only the NPCs with an after-restoration line say something new: the
		# player left Cloudreach from the summit straight after Veyra.
		var short := str(npc.id).get_slice("_", str(npc.id).get_slice_count("_") - 1)
		if not dialogue.has("cloudreach_%s_after_restoration" % short):
			continue
		out.append({"id": "cloudreach:npc:" + str(npc.id), "kind": "aftermath_npc",
			"at": _xz(relocated.get(str(npc.id), overrides.get(str(npc.id), npc.position))),
			"radius": NPC_PROMPT_RADIUS_M})
	for camp: Dictionary in chapter.camping_contract.camps:
		out.append({"id": "cloudreach:camp:" + str(camp.id), "kind": "camp", "at": _xz(camp.position),
			"radius": CAMP_RADIUS_M})
	for node: Dictionary in chapter.resource_tier.nodes:
		# world_day_regrow nodes renew; a permanent node would be once-only.
		if str(node.get("respawn_policy", "")) != "world_day_regrow":
			continue
		out.append({"id": "cloudreach:node:" + str(node.id), "kind": "harvest", "at": _xz(node.position),
			"radius": 2.4})
	var gate: Array = _json("res://data/config/cloudreach_world.json").transition_points.meadows_return.position
	out.append({"id": "cloudreach:gate:meadows_return", "kind": "gate", "at": _xz(gate), "radius": GATE_RADIUS_M})
	return out


# --- Meadows: Storm Road arrival -> Grandpa --------------------------------------

func _meadows_segments(use_haul_road: bool = true) -> Array:
	var terrain := _json("res://data/config/terrain_playground.json")
	var transitions := _json("res://data/config/realm_transitions.json")
	var polylines: Array = []
	for band: Dictionary in terrain.trail.bands:
		polylines.append(_xz_all(band.points))
	for loop: Dictionary in terrain.trail.loops:
		polylines.append(_xz_all(loop.points))
	for shortcut: Dictionary in terrain.trail.shortcuts:
		# The quarry haul road runs one way, quarry -> village: the return's
		# own direction. The ferry has no authored points and no runtime.
		if not (shortcut.get("points", []) as Array).is_empty() and use_haul_road:
			polylines.append(_xz_all(shortcut.points))
	for spoke: Dictionary in terrain.spokes.routes:
		if str(spoke.id) == "storm_road":
			polylines.append(_xz_all(spoke.road))
	for route: Dictionary in terrain.paths.routes:
		polylines.append(_xz_all(route.points))
	for approach: Dictionary in terrain.paths.get("approaches", []):
		polylines.append(_xz_all(approach.points))
	var arrival: Vector2 = _xz(transitions.meadows_entries.meadows_cloudreach_gate_return.position)
	var grandpa: Vector2 = _xz(terrain.paths.village_topology.home_door)
	return [{"mode": "walk", "points": _navigate2d(polylines, arrival, grandpa), "id": "meadows_trail"}]


## Probe hook: proposed Meadows sources (another lane's data, not yet landed)
## measured against the same walk. Empty in the test itself.
var extra_meadows_sources: Array = []


func _meadows_sources(with_wilds: bool) -> Array:
	var out: Array = extra_meadows_sources.duplicate()
	var engage := float(_json(COMBAT_PATH).get("flow", {}).get("engage_range", 6.0))
	for band: Dictionary in _json("res://data/config/terrain_playground.json").trail.bands:
		var dir := "res://data/config/bands/%s/" % band.id
		if with_wilds and FileAccess.file_exists(dir + "spawns.json"):
			for spawn: Dictionary in _json(dir + "spawns.json").spawns:
				# Alphas are once-only named fights; ordinary spawns repopulate.
				# Alphas are once-only; night- or rain-only spawns are not live on
				# every return, so they never close a gap here.
				if spawn.has("alpha") or spawn.has("time") or spawn.has("weather"):
					continue
				out.append({"id": "meadows:wild:%s:%d" % [band.id, int(spawn.order)], "kind": "encounter",
					"at": _xz(spawn.centre), "radius": engage + float(spawn.get("radius", 0.0))})
		if FileAccess.file_exists(dir + "props.json"):
			for cluster: Dictionary in _json(dir + "props.json").get("clusters", []):
				var rest: Dictionary = cluster.get("rest", {})
				if rest.is_empty():
					continue
				out.append({"id": "meadows:camp:%s:%s" % [band.id, str(rest.at)], "kind": "camp",
					"at": _xz(rest.at), "radius": float(rest.get("radius", CAMP_RADIUS_M))})
	var door: Array = _json("res://data/config/terrain_playground.json").paths.village_topology.home_door
	out.append({"id": "meadows:grandpa", "kind": "homecoming", "at": _xz(door), "radius": GATE_RADIUS_M})
	return out


# --- the whole return -------------------------------------------------------------

## One clock across all four realms. The realm transitions themselves are
## loads, not travel, and are excluded from the clock (ACCEPTANCE §7 times
## loading separately); each gate is an event on both sides.
func _whole_return(with_wilds: bool, use_arches: bool, use_haul_road: bool = true) -> Dictionary:
	var offered: Dictionary = {}
	var t := 0.0
	var legs: Array = [
		["water", _water_segments(), _water_sources(with_wilds), _water_speeds()],
		["stormwood", _stormwood_segments(use_arches), _stormwood_sources(with_wilds), {"walk": _walk_speed()}],
		["cloudreach", _cloudreach_segments(), _cloudreach_sources(with_wilds), {"walk": _walk_speed()}],
		["meadows", _meadows_segments(use_haul_road), _meadows_sources(with_wilds), {"walk": _walk_speed()}],
	]
	var events: Array = []
	var per_realm: Dictionary = {}
	var samples: Array = []
	for leg: Array in legs:
		var start := t
		events.append({"t": t, "id": "%s:arrive" % leg[0], "kind": "gate", "realm": leg[0]})
		var result := _walk_leg(leg[0], leg[1], leg[2], leg[3], offered, t)
		events.append_array(result.events)
		for sample: Array in result.samples:
			samples.append(sample + [leg[0]])
		t = float(result.t_end)
		per_realm[leg[0]] = {"seconds": snappedf(t - start, 1.0),
			"walk_m": snappedf(result.metres.walk, 1.0), "swim_m": snappedf(result.metres.swim, 1.0),
			"events": result.events.size()}
	var gaps := _gaps(events, 0.0, t, "veilfall_passage_exit", "grandpa")
	var over := gaps.filter(func(g: Dictionary) -> bool: return float(g.gap_s) > A7_LIMIT_S)
	for gap: Dictionary in over:
		var mid := (float(gap.t_from) + float(gap.t_to)) * 0.5
		gap["midpoint"] = _position_at(samples, mid)
		for sample: Array in samples:
			if mid <= float(sample[1]):
				gap["realm"] = str(sample[4])
				break
	return {"seconds": t, "per_realm": per_realm, "gaps": gaps, "over": over}


## A7 intervals still open on the return, in realms other lanes own. Each has
## a SHARED-FILE REQUEST on the Tidewake PR. A gap is matched by realm and by
## its midpoint lying within KNOWN_MATCH_M of the listed one, not by the ids at
## its ends, so another lane's partial edit that shifts an end offer does not
## turn this test red. A fix that closes a gap prints the stale row; a gap
## anywhere else fails the test.
const KNOWN_MATCH_M := 200.0
const KNOWN_OPEN: Array[Dictionary] = [
	{"realm": "meadows", "midpoint": Vector2(316, 1535),
		"note": "quarry haul road, upper half (133 s at walk); the band trail has no gap"},
	{"realm": "meadows", "midpoint": Vector2(65, 469),
		"note": "quarry haul road, village half (138 s at walk, daytime); the band trail has no gap"},
]


func _known(gap: Dictionary) -> int:
	for index in KNOWN_OPEN.size():
		var row: Dictionary = KNOWN_OPEN[index]
		if str(gap.get("realm", "")) == str(row.realm) \
				and (gap.midpoint as Vector2).distance_to(row.midpoint) <= KNOWN_MATCH_M:
			return index
	return -1


func test_whole_return_has_only_known_open_intervals() -> void:
	var result := _whole_return(true, false)
	var matched: Dictionary = {}
	for gap: Dictionary in result.over:
		var index := _known(gap)
		matched[index] = true
		assert_true(index >= 0, "new A7 empty interval on the return: %.0f s %s -> %s (%s midpoint %.0f,%.0f)"
			% [gap.gap_s, gap.from, gap.to, gap.get("realm", "?"), (gap.midpoint as Vector2).x,
				(gap.midpoint as Vector2).y])
	for index in KNOWN_OPEN.size():
		if not matched.has(index):
			print("TIDEWAKE RETURN: known-open interval resolved, delete its KNOWN_OPEN row: %s %s"
				% [KNOWN_OPEN[index].realm, KNOWN_OPEN[index].note])
	var per_realm: Dictionary = result.per_realm
	assert_true(float(per_realm.stormwood.walk_m) > 5000.0, "the Stormwood return walks the road network")
	assert_true(float(per_realm.cloudreach.walk_m) > 8000.0, "the Cloudreach return walks the ground graph")
	assert_true(float(per_realm.meadows.walk_m) > 9000.0, "the Meadows return walks the trail to Grandpa")


## The midpoint match is what keeps other lanes' partial edits from turning
## this red, so it must still reject a gap somewhere unlisted.
func test_known_open_match_rejects_an_unlisted_gap() -> void:
	assert_true(_known({"realm": "meadows", "midpoint": Vector2(316, 1600)}) >= 0, "a nearby midpoint matches")
	assert_eq(_known({"realm": "meadows", "midpoint": Vector2(0, 5000)}), -1, "a distant midpoint is new")
	assert_eq(_known({"realm": "stormwood", "midpoint": Vector2(-451, 4644)}), -1, "another realm is new")


## Reports only: the strict no-respawn definition, lit arches, the Meadows band
## trail instead of the haul road, and pacing.
func test_whole_return_report() -> void:
	var trail := _whole_return(true, false, false)
	print("TIDEWAKE RETURN WHOLE return_live no_haul_road " + JSON.stringify({
		"minutes": snappedf(float(trail.seconds) / 60.0, 0.1), "meadows": trail.per_realm.meadows,
		"over_a7": (trail.over as Array).map(func(g: Dictionary) -> String:
			return "%.0fs %s -> %s (%s midpoint %.0f,%.0f)" % [g.gap_s, g.from, g.to,
				g.get("realm", "?"), (g.midpoint as Vector2).x, (g.midpoint as Vector2).y])}))
	for with_wilds in [true, false]:
		for use_arches in [false, true]:
			var result := _whole_return(with_wilds, use_arches)
			print("TIDEWAKE RETURN WHOLE %s arches=%s " % ["return_live" if with_wilds else "no_respawn", use_arches]
				+ JSON.stringify({"minutes": snappedf(float(result.seconds) / 60.0, 0.1),
				"per_realm": result.per_realm,
				"over_a7": (result.over as Array).map(func(g: Dictionary) -> String:
					return "%.0fs %s -> %s (%s midpoint %.0f,%.0f)" % [g.gap_s, g.from, g.to,
						g.get("realm", "?"), (g.midpoint as Vector2).x, (g.midpoint as Vector2).y])}))


## Shortest path over polylines. Polylines meeting at an exact shared vertex are
## joined there; an end vertex that no other polyline shares is joined to the
## nearest other polyline segment (spurs and approaches authored beside a road).
## Both endpoints are projected onto their nearest segment, as the Cloudreach
## harness's _navigate does.
func _navigate2d(polylines: Array, from: Vector2, target: Vector2, portals: Array = [],
		join_unshared: bool = true) -> Array:
	var points: Array[Vector2] = []
	var edges: Array = []
	var index_of := func(point: Vector2) -> int:
		var found := points.find(point)
		if found >= 0:
			return found
		points.append(point)
		return points.size() - 1
	var line_of: Array = []
	for line_index in polylines.size():
		var line: Array = polylines[line_index]
		for i in line.size() - 1:
			edges.append([index_of.call(line[i]), index_of.call(line[i + 1])])
			line_of.append(line_index)
	var project := func(point: Vector2, skip_line: int) -> Array:
		var best := INF
		var chosen := -1
		var at := Vector2.ZERO
		# Only authored segments are projection targets, never the joins below.
		for e in line_of.size():
			if int(line_of[e]) == skip_line:
				continue
			var edge: Array = edges[e]
			var closest := Geometry2D.get_closest_point_to_segment(point, points[edge[0]], points[edge[1]])
			if point.distance_to(closest) < best:
				best = point.distance_to(closest)
				chosen = e
				at = closest
		return [chosen, at, best]
	for line_index in (polylines.size() if join_unshared else 0):
		var line: Array = polylines[line_index]
		for end: Vector2 in [line[0], line[line.size() - 1]]:
			var shared := false
			for other in polylines.size():
				if other != line_index and (polylines[other] as Array).has(end):
					shared = true
			if shared:
				continue
			var hit: Array = project.call(end, line_index)
			if int(hit[0]) < 0 or float(hit[2]) > 80.0:
				continue
			var joint: int = index_of.call(hit[1])
			var edge: Array = edges[hit[0]]
			edges.append([joint, edge[0]])
			edges.append([joint, edge[1]])
			edges.append([joint, index_of.call(end)])
	var zero_cost: Dictionary = {}
	for pair: Array in portals:
		# A portal end stands beside its road; join it like an unshared end.
		var ends: Array[int] = []
		for end: Vector2 in pair:
			var hit: Array = project.call(end, -1)
			var joint: int = index_of.call(hit[1])
			var edge: Array = edges[hit[0]]
			edges.append([joint, edge[0]])
			edges.append([joint, edge[1]])
			var own: int = index_of.call(end)
			edges.append([own, joint])
			ends.append(own)
		edges.append([ends[0], ends[1]])
		zero_cost["%d:%d" % [mini(ends[0], ends[1]), maxi(ends[0], ends[1])]] = true
	var endpoints: Array[int] = []
	for point: Vector2 in [from, target]:
		var hit: Array = project.call(point, -1)
		var joint: int = index_of.call(hit[1])
		var edge: Array = edges[hit[0]]
		edges.append([joint, edge[0]])
		edges.append([joint, edge[1]])
		var own: int = index_of.call(point)
		edges.append([own, joint])
		endpoints.append(own)
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
			var step := 0.0 if zero_cost.has("%d:%d" % [mini(current, next), maxi(current, next)]) \
				else points[current].distance_to(points[next])
			var cost := float(distances[current]) + step
			if cost < float(distances.get(next, INF)):
				distances[next] = cost
				previous_of[next] = current
				if next not in open:
					open.append(next)
	assert_true(distances.has(endpoints[1]), "a route reaches %s from %s" % [target, from])
	var path: Array = []
	var cursor := endpoints[1]
	while distances.has(endpoints[1]):
		path.push_front(points[cursor])
		if cursor == endpoints[0]:
			break
		cursor = previous_of[cursor]
	return path


# --- helpers -------------------------------------------------------------------

func _walk_speed() -> float:
	return float(_json(MOVEMENT_PATH).get("locomotion", {}).get("walk_speed", 5.0))


func _json(path: String) -> Dictionary:
	if not _cache.has(path):
		_cache[path] = JSON.parse_string(FileAccess.get_file_as_string(path))
	return _cache[path]


func _by_id(rows: Array) -> Dictionary:
	var out: Dictionary = {}
	for row: Dictionary in rows:
		out[str(row.id)] = row
	return out


func _xz(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[raw.size() - 1]))


func _xz_all(raw: Array) -> Array:
	return raw.map(func(p: Array) -> Vector2: return _xz(p))
