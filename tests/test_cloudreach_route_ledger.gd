extends "res://tests/test_case.gd"

# ROADMAP F07 / ACCEPTANCE §6.1 F07: "an earned route and resource/XP ledger
# show no required new catch"; ACCEPTANCE §6 Cloudreach card: "Full route
# resource/XP ledger supports the retained five without a new catch".
#
# This is the ledger. It is pure data: it reads the shipped Cloudreach JSON and
# the shipped XP arithmetic (scripts/creatures/progression.gd, the same static
# functions combat_manager.gd::_award_victory calls) and replays the REQUIRED
# route as an ordered list of steps that mirrors the production continuous
# harness (tests/smoke_cloudreach_continuous.gd, `_run`): the same targets in
# the same order, walked with the same shortest-path rule over the ground
# polylines that are UNLOCKED at that moment (the harness's `_navigate`), and
# the same Fly legs. It never catches, never fights a wild site twice and never
# counts optional trainers.
#
# Gate and order discipline (the review defect this version fixes): a wild
# site, route pickup or harvest node is credited only on a walk whose path
# passes it AND only when the gate it needs (its encounter table's
# `requires_unlock`, the pickup's `requires_unlock`) is already held when that
# walk starts. A site first passed while closed is NOT credited then; it is
# credited only if a later required walk passes it with the gate open (e.g. the
# fly-gated return pairs on the Windscar floor after the shrine). Fly legs pay
# nothing. Every step's own data prerequisites (objective/interaction/trigger
# requires_flags, trainer encounter_requirements) must hold when the step is
# reached, so the replay cannot drift from the shipped gate order.
#
# Every figure is read from data or from a spec line named beside it. Where the
# specs leave a number open, the constant says so and is chosen in the
# conservative direction. If an assertion fails, the printed ledger is the
# evidence; do not tune data or loosen a constant to turn it green.
# Evidence writer: tools/cloudreach_ledger/write_route_ledger.gd.

const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const ENCOUNTERS_PATH := "res://data/config/cloudreach_encounters.json"
const WORLD_PATH := "res://data/config/cloudreach_world.json"
const PHYSICAL_PATH := "res://data/config/cloudreach_physical_runtime.json"
const ACT_ONE_PATH := "res://data/config/cloudreach_act_one_runtime.json"
const SCENE_PATH := "res://data/config/cloudreach_scene_runtime.json"
const FINALE_PATH := "res://data/config/cloudreach_finale.json"
const FLY_PATH := "res://data/config/fly_traversal.json"
const ITEMS_PATH := "res://data/items/items.json"
const TRADE_PATH := "res://data/config/trade.json"
const RECIPES_PATH := "res://data/recipes/recipes_cloudreach.json"
const CURVE_PATH := "res://data/config/chapter_curve.json"
const HARNESS_PATH := "res://tests/smoke_cloudreach_continuous.gd"

## --- the team the Meadows hands over ------------------------------------------
## Lead level: data/config/chapter_curve.json band5_stronghold_approach
## `team.exit` 21 (the level AFTER the Warden's XP is banked), which is also
## PROGRESSION.md §3's Meadows row "L3 → L21 lead". The other four: the same
## row's "other retained members within3 levels", taken at its floor (21-3).
## WORLD §2.4 names Cloudreach entry "18–21 overlap": this party spans exactly
## that band. (The continuous harness's L25 fixture is NOT used: it starts
## above the Meadows exit and would flatter the ledger.)
const MEADOWS_EXIT_REGION := "band5_stronghold_approach"
const RETAINED_SPREAD := 3
const TEAM_SIZE := 5
## The lead (index 0) is the active creature for every defeat; the other four
## are the "other eligible living party creature[s]" that receive the share
## (PROGRESSION.md §2; combat_manager.gd::_award_victory). No member faints, so
## no member misses XP. This is the floor for the four: they never lead.
const LEAD_INDEX := 0

## --- the difficulty band a required fight asks for -----------------------------
## LEDGER CRITERIA, CHOSEN HERE -- no spec states a per-fight level band.
## PROGRESSION.md §3's Cloudreach row says only "L18–21 overlap → L33"; WORLD.md
## §2.4 gives exit 33 against Veyra's ace 34. (PROGRESSION §3's "deficit≤2" is
## about a replacement catch relative to regional entry, NOT a fight band, and is
## not the source of these numbers.) This ledger's chosen criteria: the lead
## stands at >= ace-2 before each required fight; the weakest retained member at
## >= ace-2-RETAINED_SPREAD (ace-5); at exit the lead >= 33 (WORLD §2.4) and the
## weakest >= 30 (33 - RETAINED_SPREAD, again a ledger choice).
const LEAD_ACE_TOLERANCE := 2
## WORLD.md §2.4: "Cloudreach | 18–21 overlap | 33 target; Veyra ace 34".
const CLOUDREACH_EXIT_TARGET := 33
## F07#4 (coordinator-authorised tune): the finale band (Captain Veyra) and the
## exit must hold a POSITIVE margin, >= +1 level for the lead and the weakest,
## not merely meet the band. The earlier bands (Senn, Maela, Voss) keep >= 0.
## Ledger choice, like the bands above; the zero-slack pass it replaces failed
## at 40% engagement and on a single bench kill.
const LATE_MARGIN := 1

## --- what the required route is allowed to pay ------------------------------
## Conservative engagement fraction (no spec figure exists): Cloudreach wilds
## are non-aggressive (cloudreach_encounter_director.gd spawns them with
## "aggressive": false), so every wild fight is the player's choice. Credit
## only HALF (floored) of the gate-open wild sites a phase's walks pass, each
## fought once (PROGRESSION §7 "zero repeat wild encounters"; WORLD §2.5 "no
## wild respawns at all"), ONE defeat per site although most sites are pairs,
## at its table's MINIMUM level, lowest-level sites first.
const WILD_FRACTION := 0.5
## A wild site or verge pickup is "passed" by a walk when it lies this close to
## the walked path. The road-visibility pairs stand 5.5 m off the centre line
## and route_verge candy about 2 m off.
const ON_ROUTE_M := 12.0
## A harvest node is reachable from a walk when it lies this close to the path
## (the scripted required path steps 13.0 m and 19.8 m off the causeway for its
## gale-fiber nodes).
const RESOURCE_REACH_M := 25.0

## PROGRESSION.md §6: "Set available basic-material supply≥150% of solo
## mandatory craft cost along the intended path".
const SUPPLY_MARGIN := 1.5
## SYSTEMS.md §7 "Target supply policy": one recovery restock is "2 small
## potions,1 revive" (food excluded: SYSTEMS says basic food is gatherable at
## zero coins). Same basket tests/test_meadows_economy_solvency.gd prices.
const LOSS_BASKET := {"potion_small": 2, "revive": 1}
const LOSSES := 2

## Anything in a REQUIRED requirement that names one of these is a catch or
## party-composition check.
const CATCH_TOKENS := ["catch", "caught", "capture", "species", "party_size",
	"min_party", "new_creature", "recruit", "tame"]

## Flags the completed Meadows handoff holds on arrival (the harness fixture's
## explicit precondition) plus the arrival objective, which completes on the
## arrival anchor at the road's first vertex.
const START_FLAGS := ["warden_defeated", "realm_key_cloudreach", "realm_heart_meadows_earned",
	"realm_gate_cloudreach_unlocked", "cloudreach_chapter_started"]

## The required route, in the harness's order (smoke_cloudreach_continuous.gd
## `_run`, line by line). Kinds:
##   walk  -> navigate over unlocked ground polylines to a data target
##   fly   -> glide through the harness's waypoints (pays nothing)
##   fight -> walk to the trainer as `_battle` does, then defeat its team
## `sets` are the flags the step completes. Step prerequisites are checked from
## data, not from this table.
const ROUTE := [
	{"do": "walk", "to": ["route_vertex", "arrival_gate_road", 3], "why": "arrival road"},
	{"do": "walk", "to": ["npc", "warden_aila"], "sets": ["cloudreach_crisis_learned"]},
	{"do": "walk", "to": ["anchor", "lower_west"], "sets": ["storm_anchor_lower_west_mapped"]},
	{"do": "walk", "to": ["node", "cr_node_gale_fiber_causeway"], "gather": true},
	{"do": "walk", "to": ["anchor", "lower_east"],
		"sets": ["storm_anchor_lower_east_mapped", "cloudreach_lower_anchors_investigated"]},
	{"do": "fight", "trainer": "tether_lieutenant_senn"},
	{"do": "walk", "to": ["interaction", "causeway_signal"], "sets": ["causeway_survivors_reconnected"]},
	{"do": "fight", "trainer": "keeper_maela_trial"},
	{"do": "walk", "to": ["interaction", "aerie_repair"], "sets": ["windscar_aerie_prepared"]},
	{"do": "walk", "to": ["npc", "keeper_maela"], "sets": ["cloudreach_act_i_complete"]},
	{"do": "walk", "to": ["camp", "windscar_flight_aerie_camp"], "why": "rest"},
	{"do": "walk", "to": ["interaction", "flight_trial_start"],
		"sets": ["fly_traversal_unlocked", "fly_tutorial_completed"], "why": "flight trial (rings flown)"},
	{"do": "fly", "via": [[535, 760, 3170], [750, 935, 3030], [1020, 1075, 2960], [1110, 1050, 2940]],
		"landing": "sky_shrine", "sets": ["sky_shrine_reached"]},
	{"do": "here", "interaction": "shrine_vane_west", "sets": ["cloudreach_shrine_vane_west_aligned"]},
	{"do": "here", "interaction": "shrine_vane_east", "sets": ["cloudreach_shrine_vane_east_aligned"]},
	{"do": "here", "interaction": "shrine_vane_crown", "sets": ["cloudreach_shrine_vane_crown_aligned"]},
	{"do": "here", "npc": "naturalist_sora", "sets": ["storm_anchor_engine_truth_learned"]},
	{"do": "here", "interaction": "shrine_windlass", "sets": ["cloudreach_upper_route_unlocked"]},
	{"do": "fly", "via": [[1020, 1075, 3000], [850, 975, 3020], [620, 800, 3150], [400, 610, 3250]],
		"why": "return glide to the aerie"},
	{"do": "walk", "to": ["trigger", "counterweight_entered"], "sets": ["cloudreach_act_ii_complete"]},
	{"do": "walk", "to": ["interaction", "upper_anchor_west"], "sets": ["storm_anchor_upper_west_disabled"]},
	{"do": "walk", "to": ["interaction", "upper_anchor_east"], "sets": ["storm_anchor_upper_east_disabled"]},
	{"do": "fight", "trainer": "officer_voss_summit_approach"},
	{"do": "walk", "to": ["interaction", "summit_feed"],
		"sets": ["storm_anchor_summit_feed_disabled", "cloudreach_upper_anchors_disabled"]},
	{"do": "walk", "to": ["camp", "summit_bivouac"], "why": "rest"},
	{"do": "walk", "to": ["trigger", "summit_threshold"], "sets": ["summit_extraction_engine_reached"]},
	{"do": "fight", "trainer": "captain_veyra_storm_anchor",
		"after": ["cloudreach_summit_relay_west_disabled", "cloudreach_summit_relay_crown_disabled",
			"cloudreach_summit_relay_east_disabled", "storm_anchor_network_disabled"]},
	{"do": "walk", "to": ["point", "aftermath_witness"], "sets": ["cloudreach_winds_restored"],
		"why": "Waterward overlook (winds restore on arrival, so restored pairs are closed on this walk)"},
	{"do": "here", "npc": "warden_aila", "sets": ["cloudreach_chapter_complete"]},
]

## The harness calls, in order, that this ROUTE mirrors. Checked against the
## harness source so the ledger cannot drift from the production walk.
const HARNESS_ORDER := ["_talk(\"warden_aila\"", "lower_west", "cr_node_gale_fiber_causeway",
	"lower_east", "_battle(\"tether_lieutenant_senn\"", "_physical_action(\"causeway_signal\"",
	"_battle(\"keeper_maela_trial\"", "_physical_action(\"aerie_repair\"", "_talk(\"keeper_maela\"",
	"_rest(\"windscar_flight_aerie_camp\"", "_trial()", "shrine_vane_west",
	"_talk(\"naturalist_sora\"", "_physical_action(\"shrine_windlass\"", "_return_to_aerie()",
	"Vector3(-720,700,3680)", "_physical_action(\"upper_anchor_west\"",
	"_physical_action(\"upper_anchor_east\"", "_battle(\"officer_voss_summit_approach\"",
	"_physical_action(\"summit_feed\"", "_rest(\"summit_bivouac\"", "Vector3(100,1160,5350)",
	"_battle(\"captain_veyra_storm_anchor\"", "Vector3(-420,1110,5650)",
	"_talk(\"warden_aila\", \"cloudreach_chapter_complete\""]

var _cache: Dictionary = {}
var _printed := false


# --- data -----------------------------------------------------------------------

func _json(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path] as Dictionary
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var result: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	_cache[path] = result
	return result


func _vec(raw: Variant) -> Vector3:
	if not (raw is Array) or (raw as Array).size() < 3:
		return Vector3.INF
	var a := raw as Array
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _by_id(rows: Variant) -> Dictionary:
	var out: Dictionary = {}
	if rows is Array:
		for raw: Variant in (rows as Array):
			if raw is Dictionary:
				out[str((raw as Dictionary).get("id", ""))] = raw
	return out


func _routes() -> Dictionary:
	return _by_id(_json(WORLD_PATH).get("routes", []))


func _ladder() -> Dictionary:
	return _by_id(_json(CHAPTER_PATH).get("trainer_ladder", []))


func _tables() -> Dictionary:
	return _by_id(_json(CHAPTER_PATH).get("encounter_tables", []))


func _interactions() -> Dictionary:
	return _by_id(_json(PHYSICAL_PATH).get("interactions", []))


func _items() -> Dictionary:
	return _json(ITEMS_PATH).get("items", {}) as Dictionary


func _cfg() -> Dictionary:
	return PROGRESSION.config()


func _meadows_exit_lead() -> int:
	for raw: Variant in (_json(CURVE_PATH).get("regions", []) as Array):
		var region := raw as Dictionary
		if str(region.get("id", "")) == MEADOWS_EXIT_REGION:
			return int((region.get("team", {}) as Dictionary).get("exit", 0))
	return 0


func _slots(trainer_id: String) -> Array:
	var trainer: Dictionary = _ladder().get(trainer_id, {}) as Dictionary
	return (trainer.get("team_contract", {}) as Dictionary).get("slots", []) as Array


func _ace(trainer_id: String) -> int:
	var ace := 0
	for raw: Variant in _slots(trainer_id):
		ace = maxi(ace, int((raw as Dictionary).get("level", 0)))
	return ace


func _reward(trainer_id: String) -> Dictionary:
	var rank := str((_ladder().get(trainer_id, {}) as Dictionary).get("rank", ""))
	return (_json(ENCOUNTERS_PATH).get("reward_tiers", {}) as Dictionary).get(rank, {}) as Dictionary


func _price(item_id: String) -> int:
	var dearest := 0
	for raw: Variant in (_json(TRADE_PATH).get("vendors", {}) as Dictionary).values():
		var goods: Dictionary = (raw as Dictionary).get("goods", {}) as Dictionary
		if goods.has(item_id):
			dearest = maxi(dearest, int((goods[item_id] as Dictionary).get("buy", 0)))
	return dearest


func _loss_basket_price() -> int:
	var total := 0
	for item_id: String in LOSS_BASKET:
		total += _price(item_id) * int(LOSS_BASKET[item_id])
	return total


func _pickup_position(spec: Dictionary) -> Vector3:
	var overrides: Dictionary = _json(PHYSICAL_PATH).get("pickup_overrides", {}) as Dictionary
	var id := str(spec.get("id", ""))
	return _vec(overrides[id]) if overrides.has(id) else _vec(spec.get("position", []))


func _npc_position(id: String) -> Vector3:
	var overrides: Dictionary = _json(PHYSICAL_PATH).get("npc_position_overrides", {}) as Dictionary
	if overrides.has(id):
		return _vec(overrides[id])
	return _vec((_by_id(_json(CHAPTER_PATH).get("npcs", [])).get(id, {}) as Dictionary).get("position", []))


## Where the harness walks for a fight: the battle-yard road position when the
## trainer has a yard (cloudreach_scene_runtime.json), else the placement.
func _trainer_position(id: String) -> Vector3:
	var yard: Dictionary = _by_id(_json(SCENE_PATH).get("battle_yards", [])).get(id, {}) as Dictionary
	if not yard.is_empty():
		return _vec(yard.get("road_position", []))
	return _vec((_by_id(_json(ENCOUNTERS_PATH).get("trainers", [])).get(id, {}) as Dictionary).get("position", []))


func _target(spec: Array) -> Vector3:
	var kind := str(spec[0])
	var id := str(spec[1])
	match kind:
		"route_vertex":
			var polyline: Array = (_routes().get(id, {}) as Dictionary).get("polyline", []) as Array
			return _vec(polyline[int(spec[2])]) if int(spec[2]) < polyline.size() else Vector3.INF
		"npc":
			return _npc_position(id)
		"anchor":
			return _vec((_by_id(_json(ACT_ONE_PATH).get("anchors", [])).get(id, {}) as Dictionary).get("position", []))
		"node":
			var nodes: Array = (_json(CHAPTER_PATH).get("resource_tier", {}) as Dictionary).get("nodes", []) as Array
			return _vec((_by_id(nodes).get(id, {}) as Dictionary).get("position", []))
		"interaction":
			return _vec((_interactions().get(id, {}) as Dictionary).get("position", []))
		"trigger":
			return _vec((_by_id(_json(PHYSICAL_PATH).get("ground_triggers", [])).get(id, {}) as Dictionary).get("position", []))
		"camp":
			var camps: Array = (_json(CHAPTER_PATH).get("camping_contract", {}) as Dictionary).get("camps", []) as Array
			return _vec((_by_id(camps).get(id, {}) as Dictionary).get("position", []))
		"point":
			return _vec((_json(FINALE_PATH).get(id, {}) as Dictionary).get("position", []))
	return Vector3.INF


## The data prerequisites of a step, which must already hold when it is reached.
func _step_requires(step: Dictionary) -> Array:
	var out: Array = []
	var to: Array = step.get("to", []) as Array
	var interaction := str(step.get("interaction", ""))
	if not to.is_empty() and str(to[0]) == "interaction":
		interaction = str(to[1])
	if not interaction.is_empty():
		out.append_array((_interactions().get(interaction, {}) as Dictionary).get("requires_flags", []) as Array)
	if not to.is_empty() and str(to[0]) == "trigger":
		var trigger: Dictionary = _by_id(_json(PHYSICAL_PATH).get("ground_triggers", [])).get(str(to[1]), {}) as Dictionary
		out.append_array(trigger.get("requires_flags", []) as Array)
	if not to.is_empty() and str(to[0]) == "camp":
		var camps: Array = (_json(CHAPTER_PATH).get("camping_contract", {}) as Dictionary).get("camps", []) as Array
		var flag := str((_by_id(camps).get(str(to[1]), {}) as Dictionary).get("requires_flag", ""))
		if not flag.is_empty():
			out.append(flag)
	if str(step.get("landing", "")) != "":
		var landing: Dictionary = _by_id(_json(PHYSICAL_PATH).get("landing_objectives", [])).get(str(step["landing"]), {}) as Dictionary
		out.append_array(landing.get("requires_flags", []) as Array)
	if step.has("trainer"):
		var runtime: Dictionary = _json(PHYSICAL_PATH).get("encounter_requirements", {}) as Dictionary
		out.append_array(runtime.get(str(step["trainer"]), []) as Array)
	# The objective whose flag this step sets names its own prerequisites.
	for act_raw: Variant in (_json(CHAPTER_PATH).get("acts", []) as Array):
		for obj_raw: Variant in ((act_raw as Dictionary).get("objectives", []) as Array):
			var objective := obj_raw as Dictionary
			if str(objective.get("flag_id", "")) in (step.get("sets", []) as Array):
				out.append_array(objective.get("requires_flags", []) as Array)
	return out


# --- the harness's navigation, on data -----------------------------------------

## tests/smoke_cloudreach_continuous.gd::_navigate on data: build a graph from
## the ground polylines whose `requires_unlock` is held, attach the current
## position and the target to their nearest edges, shortest path by length.
## Returns the walked polyline: current position, graph vertices, target.
func _navigate(from: Vector3, target: Vector3, flags: Dictionary) -> Array:
	var points: Array = []
	var edges: Array = []
	for raw: Variant in (_json(WORLD_PATH).get("routes", []) as Array):
		var route := raw as Dictionary
		var gate := str(route.get("requires_unlock", ""))
		if str(route.get("traversal_mode", "")) != "ground" or (not gate.is_empty() and not flags.has(gate)):
			continue
		var previous := -1
		for vertex: Variant in (route.get("polyline", []) as Array):
			var at := _vec(vertex)
			var index := points.find(at)
			if index < 0:
				index = points.size()
				points.append(at)
			if previous >= 0:
				edges.append([previous, index])
			previous = index
	var endpoints: Array = []
	for at: Vector3 in [from, target]:
		var best := INF
		var chosen: Array = []
		var projected := Vector3.ZERO
		for edge: Variant in edges:
			var e := edge as Array
			var closest := Geometry3D.get_closest_point_to_segment(at, points[e[0]], points[e[1]])
			if at.distance_to(closest) < best:
				best = at.distance_to(closest)
				chosen = e
				projected = closest
		var index := points.size()
		points.append(projected)
		endpoints.append(index)
		edges.append([index, chosen[0]])
		edges.append([index, chosen[1]])
	var distances: Dictionary = {endpoints[0]: 0.0}
	var previous_of: Dictionary = {}
	var open: Array = [endpoints[0]]
	while not open.is_empty():
		open.sort_custom(func(a: int, b: int) -> bool: return float(distances[a]) < float(distances[b]))
		var current: int = open.pop_front()
		if current == endpoints[1]:
			break
		for edge: Variant in edges:
			var e := edge as Array
			var next: int = e[1] if e[0] == current else (e[0] if e[1] == current else -1)
			if next < 0:
				continue
			var cost := float(distances[current]) + (points[current] as Vector3).distance_to(points[next])
			if cost < float(distances.get(next, INF)):
				distances[next] = cost
				previous_of[next] = current
				if next not in open:
					open.append(next)
	if not distances.has(endpoints[1]):
		return []
	var path: Array = [target]
	var cursor: int = endpoints[1]
	while true:
		path.push_front(points[cursor])
		if cursor == endpoints[0]:
			break
		cursor = previous_of[cursor]
	path.push_front(from)
	return path


func _path_distance(point: Vector3, path: Array) -> float:
	var best := INF
	for i in range(0, path.size() - 1):
		var closest := Geometry3D.get_closest_point_to_segment(point, path[i], path[i + 1])
		best = minf(best, point.distance_to(closest))
	return best


func _path_length(path: Array) -> float:
	var total := 0.0
	for i in range(0, path.size() - 1):
		total += (path[i] as Vector3).distance_to(path[i + 1])
	return total


# --- XP arithmetic, mirroring creature_instance.gd ------------------------------

## creature_instance.gd::gain_xp: bank, then level while xp covers xp_to_next.
func _gain(member: Dictionary, amount: int) -> void:
	var cfg := _cfg()
	var cap := int((cfg.get("level", {}) as Dictionary).get("cap", 100))
	var level := int(member["level"])
	var xp := int(member["xp"]) + maxi(0, amount)
	while level < cap and xp >= PROGRESSION.xp_to_next(level, cfg):
		xp -= PROGRESSION.xp_to_next(level, cfg)
		level += 1
	member["level"] = level
	member["xp"] = xp


## creature_instance.gd::gain_levels (the candy path): whole levels, banked xp
## kept, clamped to the cap.
func _feed_candy(member: Dictionary, levels: int) -> void:
	var cap := int((_cfg().get("level", {}) as Dictionary).get("cap", 100))
	member["level"] = clampi(int(member["level"]) + levels, 1, cap)


## combat_manager.gd::_award_victory: the active creature gets the award, every
## other non-fainted member gets party_share of it.
## `active` < 0 means the lead; otherwise the member at that index lands the
## kill (sensitivity: a bench member landing kills).
func _defeat(party: Array, enemy_level: int, active: int = -1) -> int:
	var award: int = PROGRESSION.xp_award_for(enemy_level, _cfg())
	var share: int = PROGRESSION.party_share(award, _cfg())
	var who := LEAD_INDEX if active < 0 else active
	for i in party.size():
		_gain(party[i] as Dictionary, award if i == who else share)
	return award


func _xps(party: Array) -> Array:
	var out: Array = []
	for raw: Variant in party:
		out.append(int((raw as Dictionary)["xp"]))
	return out


## Banked XP toward the next level vs that level's cost, as "xp/cost".
func banked(level: int, xp: int) -> String:
	return "%d/%d" % [xp, PROGRESSION.xp_to_next(level, _cfg())]


## Worst lead and weakest margins over every fight band and the exit.
func margins(result: Dictionary) -> Dictionary:
	var lead := 1 << 30
	var weakest := 1 << 30
	var where_lead := ""
	var where_weak := ""
	for raw: Variant in (result["phases"] as Array):
		var row := raw as Dictionary
		if int(row["lead_margin"]) < lead:
			lead = int(row["lead_margin"])
			where_lead = str(row["name"])
		if int(row["all_margin"]) < weakest:
			weakest = int(row["all_margin"])
			where_weak = str(row["name"])
	var exit_levels: Array = result["exit"] as Array
	if int(exit_levels[LEAD_INDEX]) - CLOUDREACH_EXIT_TARGET < lead:
		lead = int(exit_levels[LEAD_INDEX]) - CLOUDREACH_EXIT_TARGET
		where_lead = "exit"
	if _min_level(exit_levels) - (CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD) < weakest:
		weakest = _min_level(exit_levels) - (CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD)
		where_weak = "exit"
	return {"lead": lead, "lead_at": where_lead, "weakest": weakest, "weakest_at": where_weak}


func _lowest(party: Array) -> Dictionary:
	var lowest: Dictionary = party[0] as Dictionary
	for raw: Variant in party:
		if int((raw as Dictionary)["level"]) < int(lowest["level"]):
			lowest = raw as Dictionary
	return lowest


func _levels(party: Array) -> Array:
	var out: Array = []
	for raw: Variant in party:
		out.append(int((raw as Dictionary)["level"]))
	return out


func _min_level(levels: Array) -> int:
	var low := 1 << 30
	for value: Variant in levels:
		low = mini(low, int(value))
	return low


# --- the ledger -----------------------------------------------------------------

## options (negative controls and comparisons only):
##   "drop_wild_phase": int      -- that phase's walks credit no wild XP
##   "drop_trainer_xp": String   -- that trainer's defeat pays no XP
##   "drop_candy": bool          -- verge candy pays nothing
##   "ignore_gates": bool        -- the pre-fix model: sites/pickups credited when
##                                  passed even if their gate is closed
##   "wild_fraction": float      -- replaces WILD_FRACTION
func ledger(options: Dictionary = {}) -> Dictionary:
	var key := "__ledger" + str(options)
	if _cache.has(key):
		return _cache[key] as Dictionary
	var ignore_gates := bool(options.get("ignore_gates", false))
	var fraction := float(options.get("wild_fraction", WILD_FRACTION))
	var on_route := float(options.get("on_route_m", ON_ROUTE_M))
	var lead := _meadows_exit_lead()
	var party: Array = []
	for i in TEAM_SIZE:
		party.append({"level": lead if i == LEAD_INDEX else lead - RETAINED_SPREAD, "xp": 0})
	var entry := _levels(party)
	var tables := _tables()
	var items := _items()
	var flags: Dictionary = {}
	for flag: String in START_FLAGS:
		flags[flag] = true
	var position := _vec((_routes().get("arrival_gate_road", {}) as Dictionary).get("polyline", [[0, 0, 0]])[0])
	var sites_used: Dictionary = {}
	var pickups_used: Dictionary = {}
	var nodes_used: Dictionary = {}
	var inventory: Dictionary = {}
	var steps: Array = []
	var phases: Array = []
	var problems: Array = []
	var fought_ids: Array = []
	var phase := _new_phase()
	for s in ROUTE.size():
		var step: Dictionary = ROUTE[s]
		var kind := str(step["do"])
		for flag: Variant in _step_requires(step):
			if not flags.has(str(flag)):
				problems.append("step %d (%s) is reached before its prerequisite '%s'" % [s, _label(step), str(flag)])
		var row := {"step": s, "phase": phases.size(), "label": _label(step), "kind": kind,
			"path_m": 0.0, "sites_open": [], "sites_closed": [], "candy": 0, "recovery": {},
			"nodes": []}
		var path: Array = []
		if kind == "walk" or kind == "fight":
			var target := _trainer_position(str(step["trainer"])) if kind == "fight" else _target(step["to"] as Array)
			if not target.is_finite():
				problems.append("step %d (%s) has no data position" % [s, _label(step)])
			else:
				path = _navigate(position, target, flags)
				if path.is_empty():
					problems.append("step %d (%s): no unlocked ground route" % [s, _label(step)])
				else:
					position = target
		elif kind == "fly":
			var via: Array = step["via"] as Array
			position = _vec(via[via.size() - 1])
		row["path_m"] = _path_length(path)
		if path.size() >= 2:
			# Wild sites passed on this walk.
			for raw: Variant in (_json(ENCOUNTERS_PATH).get("wild_sites", []) as Array):
				var site := raw as Dictionary
				var id := str(site.get("id", ""))
				if sites_used.has(id) or _path_distance(_vec(site.get("position", [])), path) > on_route:
					continue
				var table: Dictionary = tables.get(str(site.get("table_id", "")), {}) as Dictionary
				var gate := str(table.get("requires_unlock", ""))
				if gate.is_empty() or flags.has(gate) or ignore_gates:
					sites_used[id] = true
					var low := int((table.get("level_range", [0, 0]) as Array)[0])
					(row["sites_open"] as Array).append(id)
					(phase["sites"] as Array).append({"id": id, "level": low, "step": s})
				elif not (id in (row["sites_closed"] as Array)):
					(row["sites_closed"] as Array).append("%s[%s]" % [id, gate])
			# Route-verge pickups, gate respected, each claimed once.
			for raw: Variant in (_json(CHAPTER_PATH).get("pickups", []) as Array):
				var spec := raw as Dictionary
				var id := str(spec.get("id", ""))
				if pickups_used.has(id) or str(spec.get("placement", "")) != "route_verge":
					continue
				var gate := str(spec.get("requires_unlock", ""))
				if not gate.is_empty() and not flags.has(gate) and not ignore_gates:
					continue
				if _path_distance(_pickup_position(spec), path) > on_route:
					continue
				pickups_used[id] = true
				var item_id := str(spec.get("item_id", ""))
				var count := int(spec.get("count", 1))
				var up := int((items.get(item_id, {}) as Dictionary).get("level_up", 0)) * count
				if up > 0:
					row["candy"] = int(row["candy"]) + up
				else:
					var rec: Dictionary = row["recovery"] as Dictionary
					rec[item_id] = int(rec.get(item_id, 0)) + count
			# Harvest nodes, first pass only (world_day_regrow not counted:
			# PROGRESSION §6 "do not silently turn all nodes into infinite respawn").
			for raw: Variant in ((_json(CHAPTER_PATH).get("resource_tier", {}) as Dictionary).get("nodes", []) as Array):
				var node := raw as Dictionary
				var id := str(node.get("id", ""))
				if nodes_used.has(id):
					continue
				var distance := _path_distance(_vec(node.get("position", [])), path)
				if distance > RESOURCE_REACH_M:
					continue
				nodes_used[id] = true
				var resource := str(node.get("resource_id", ""))
				inventory[resource] = int(inventory.get(resource, 0)) + int(node.get("amount", 0))
				(row["nodes"] as Array).append("%s(%d@%.1fm)" % [id, int(node.get("amount", 0)), distance])
		# Candy goes in as soon as it is picked up, into the lowest member.
		if not bool(options.get("drop_candy", false)):
			for _i in int(row["candy"]):
				_feed_candy(_lowest(party), 1)
			phase["candy"] = int(phase["candy"]) + int(row["candy"])
		for item_id: String in (row["recovery"] as Dictionary):
			var rec: Dictionary = phase["recovery"] as Dictionary
			rec[item_id] = int(rec.get(item_id, 0)) + int((row["recovery"] as Dictionary)[item_id])
		# A required interaction's cost is paid from what the route has reached.
		var to: Array = step.get("to", []) as Array
		if not to.is_empty() and str(to[0]) == "interaction":
			var cost: Dictionary = (_interactions().get(str(to[1]), {}) as Dictionary).get("cost", {}) as Dictionary
			if not cost.is_empty():
				var item_id := str(cost.get("item_id", ""))
				var need := int(cost.get("count", 0))
				(phase["costs"] as Array).append({"interaction": str(to[1]), "item_id": item_id,
					"count": need, "supply": int(inventory.get(item_id, 0))})
				inventory[item_id] = int(inventory.get(item_id, 0)) - need
		phase["path_m"] = float(phase["path_m"]) + float(row["path_m"])
		for flag: Variant in (step.get("sets", []) as Array):
			flags[str(flag)] = true
		steps.append(row)
		if kind == "fight":
			var trainer_id := str(step["trainer"])
			# Wild sites for the whole phase: fight the lowest-level half.
			var sites: Array = phase["sites"] as Array
			sites.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return int(a["level"]) < int(b["level"]) or (int(a["level"]) == int(b["level"]) and int(a["step"]) < int(b["step"])))
			var fought := floori(float(sites.size()) * fraction)
			if int(options.get("drop_wild_phase", -1)) == phases.size():
				fought = 0
			var wild_xp := 0
			# Sensitivity: the first N of this phase's wild kills are landed by
			# the weakest bench member instead of the lead.
			var bench_kills := int((options.get("bench_kills", {}) as Dictionary).get(phases.size(), 0))
			for i in fought:
				fought_ids.append(str((sites[i] as Dictionary)["id"]))
				var active := -1
				if i < bench_kills:
					active = party.find(_lowest(party))
				var award := _defeat(party, int((sites[i] as Dictionary)["level"]), active)
				if active < 0:
					wild_xp += award
			var before := _levels(party)
			var before_xp := _xps(party)
			var trainer_xp := 0
			var reward := _reward(trainer_id)
			var bonus_xp := 0
			if str(options.get("drop_trainer_xp", "")) != trainer_id:
				for raw: Variant in _slots(trainer_id):
					trainer_xp += _defeat(party, int((raw as Dictionary).get("level", 0)))
				# encounter_director.gd::_pay_trainer_reward: the tier's flat
				# `xp_bonus` goes, whole, to every living party member.
				bonus_xp = maxi(0, int(reward.get("xp_bonus", 0)))
				for member: Variant in party:
					_gain(member as Dictionary, bonus_xp)
			var trainer: Dictionary = _ladder().get(trainer_id, {}) as Dictionary
			for raw: Variant in (reward.get("items", []) as Array):
				var grant := raw as Dictionary
				var rec: Dictionary = phase["reward_items"] as Dictionary
				rec[str(grant.get("id", ""))] = int(rec.get(str(grant.get("id", "")), 0)) + int(grant.get("count", 0))
			var ace := _ace(trainer_id)
			phase.merge({"trainer": trainer_id, "name": str(trainer.get("name", trainer_id)),
				"optional": bool(trainer.get("optional", true)),
				"finale": trainer_id == str(_json(FINALE_PATH).get("encounter_id", "")),
				"available": sites.size(), "fought": fought, "wild_xp": wild_xp,
				"ace": ace, "need_lead": ace - LEAD_ACE_TOLERANCE,
				"need_all": ace - LEAD_ACE_TOLERANCE - RETAINED_SPREAD,
				"before": before, "before_xp": before_xp, "trainer_xp": trainer_xp, "bonus_xp": bonus_xp,
				"after": _levels(party), "coins": int(reward.get("coins", 0))}, true)
			phase["lead_margin"] = int(before[LEAD_INDEX]) - int(phase["need_lead"])
			phase["all_margin"] = _min_level(before) - int(phase["need_all"])
			phase["min_margin"] = LATE_MARGIN if bool(phase["finale"]) else 0
			flags[str(trainer.get("defeat_flag", ""))] = true
			for flag: Variant in (step.get("after", []) as Array):
				flags[str(flag)] = true
			phases.append(phase)
			phase = _new_phase()
	# The post-finale walk to the overlook: credited like any phase, no trainer.
	var tail_sites: Array = phase["sites"] as Array
	var tail_fought := floori(float(tail_sites.size()) * fraction)
	var tail_xp := 0
	for i in tail_fought:
		fought_ids.append(str((tail_sites[i] as Dictionary)["id"]))
		tail_xp += _defeat(party, int((tail_sites[i] as Dictionary)["level"]))
	# Sensitivity only: the finale's reward candy fed before the overlook
	# (affects the exit, never a fight band).
	if bool(options.get("feed_finale_reward", false)):
		for raw: Variant in (_reward(str(_json(FINALE_PATH).get("encounter_id", ""))).get("items", []) as Array):
			var grant := raw as Dictionary
			var up := int((items.get(str(grant.get("id", "")), {}) as Dictionary).get("level_up", 0)) * int(grant.get("count", 0))
			for _i in up:
				_feed_candy(_lowest(party), 1)
	phase.merge({"trainer": "", "name": "Exit (overlook)", "available": tail_sites.size(),
		"fought": tail_fought, "wild_xp": tail_xp, "before": _levels(party), "before_xp": _xps(party), "after": _levels(party),
		"trainer_xp": 0, "bonus_xp": 0, "coins": 0}, true)
	var result := {"entry": entry, "phases": phases, "tail": phase, "steps": steps,
		"exit": _levels(party), "exit_xp": _xps(party), "fought_ids": fought_ids, "problems": problems, "options": options}
	_cache[key] = result
	return result


func _new_phase() -> Dictionary:
	return {"sites": [], "candy": 0, "recovery": {}, "reward_items": {}, "costs": [], "path_m": 0.0}


func _label(step: Dictionary) -> String:
	if step.has("trainer"):
		return "fight " + str(step["trainer"])
	if step.has("to"):
		var to: Array = step["to"] as Array
		return "%s %s:%s" % [str(step["do"]), str(to[0]), str(to[1])]
	if step.has("interaction"):
		return "here interaction:" + str(step["interaction"])
	if step.has("npc"):
		return "here npc:" + str(step["npc"])
	return "%s %s" % [str(step["do"]), str(step.get("why", step.get("landing", "")))]


## Every per-fight and exit failure of a ledger, as text. Empty = pass.
func shortfalls(result: Dictionary) -> Array:
	var out: Array = []
	for raw: Variant in (result["phases"] as Array):
		var row := raw as Dictionary
		var before: Array = row["before"] as Array
		var need_lead := int(row["need_lead"]) + int(row["min_margin"])
		var need_all := int(row["need_all"]) + int(row["min_margin"])
		if int(before[LEAD_INDEX]) < need_lead:
			out.append("%s: lead L%d < band L%d%s (ace L%d), short %d"
				% [str(row["name"]), int(before[LEAD_INDEX]), need_lead, _plus(int(row["min_margin"])),
				int(row["ace"]), need_lead - int(before[LEAD_INDEX])])
		if _min_level(before) < need_all:
			out.append("%s: weakest retained L%d < band L%d%s, short %d"
				% [str(row["name"]), _min_level(before), need_all, _plus(int(row["min_margin"])),
				need_all - _min_level(before)])
	var exit_levels: Array = result["exit"] as Array
	if int(exit_levels[LEAD_INDEX]) < CLOUDREACH_EXIT_TARGET + LATE_MARGIN:
		out.append("exit: lead L%d < target L%d + %d margin" % [int(exit_levels[LEAD_INDEX]),
			CLOUDREACH_EXIT_TARGET, LATE_MARGIN])
	if _min_level(exit_levels) < CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD + LATE_MARGIN:
		out.append("exit: weakest L%d < L%d + %d margin" % [_min_level(exit_levels),
			CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD, LATE_MARGIN])
	return out


func _plus(margin: int) -> String:
	return " (+%d margin)" % margin if margin > 0 else ""


func _print_ledger() -> void:
	if _printed:
		return
	_printed = true
	for line: String in report_lines(ledger()):
		print(line)


func report_lines(result: Dictionary) -> Array:
	var out: Array = []
	out.append("")
	out.append("  CLOUDREACH ROUTE LEDGER (ordered, gate-aware)  entry %s  wild fraction %.2f  no catches, no repeats  %s"
		% [str(result["entry"]), float((result["options"] as Dictionary).get("wild_fraction", WILD_FRACTION)),
		str(result["options"])])
	out.append("  %-16s %7s %7s %7s %6s %4s %9s  %-15s %6s  %-15s %6s %7s" % ["phase", "path_m", "wilds",
		"wildXP", "candy", "ace", "need L/all", "levels before", "trnXP", "levels after", "coins", "bonusXP"])
	var all_rows: Array = (result["phases"] as Array).duplicate()
	all_rows.append(result["tail"])
	for raw: Variant in all_rows:
		var row := raw as Dictionary
		out.append("  %-16s %7.0f %7s %7d %6s %4s %9s  %-15s %6d  %-15s %6d %7d" % [str(row["name"]),
			float(row["path_m"]), "%d/%d" % [int(row["fought"]), int(row["available"])], int(row["wild_xp"]),
			"+%d" % int(row["candy"]), str(row.get("ace", "-")),
			"%s/%s" % [str(row.get("need_lead", "-")), str(row.get("need_all", "-"))],
			_join(row["before"] as Array), int(row["trainer_xp"]), _join(row["after"] as Array),
			int(row["coins"]), int(row.get("bonus_xp", 0))])
	out.append("  exit %s  (lead target %d, others >= %d; finale and exit need +%d margin)" % [_join(result["exit"] as Array),
		CLOUDREACH_EXIT_TARGET, CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD, LATE_MARGIN])
	var closed := 0
	for raw: Variant in (result["steps"] as Array):
		closed += ((raw as Dictionary)["sites_closed"] as Array).size()
	out.append("  gate-closed site passes excluded: %d; shortfalls: %s" % [closed, str(shortfalls(result))])
	for raw: Variant in (result["phases"] as Array):
		for cost_raw: Variant in ((raw as Dictionary)["costs"] as Array):
			var cost := cost_raw as Dictionary
			out.append("  supply: %s needs %d %s; reached first-pass supply %d"
				% [str(cost["interaction"]), int(cost["count"]), str(cost["item_id"]), int(cost["supply"])])
	out.append("")
	return out


func _join(values: Array) -> String:
	var parts := PackedStringArray()
	for value: Variant in values:
		parts.append(str(int(value)))
	return " ".join(parts)


# --- catch checks ----------------------------------------------------------------

func _required_flags() -> Dictionary:
	var flags: Dictionary = {}
	for act_raw: Variant in (_json(CHAPTER_PATH).get("acts", []) as Array):
		var act := act_raw as Dictionary
		flags[str(act.get("completion_flag", ""))] = true
		for obj_raw: Variant in (act.get("objectives", []) as Array):
			var objective := obj_raw as Dictionary
			flags[str(objective.get("flag_id", ""))] = true
			for key: String in ["requires_flags", "count_flags", "grants_flags"]:
				for flag: Variant in (objective.get(key, []) as Array):
					flags[str(flag)] = true
	flags.erase("")
	return flags


func _required_trainers() -> Array:
	var out: Array = []
	for raw: Variant in ROUTE:
		if (raw as Dictionary).has("trainer"):
			out.append(str((raw as Dictionary)["trainer"]))
	return out


func _names_a_catch(value: String) -> String:
	var lower := value.to_lower()
	for token: String in CATCH_TOKENS:
		if lower.contains(token):
			return token
	return ""


# --- tests ----------------------------------------------------------------------

func test_the_replayed_route_follows_the_harness_and_the_data_gates() -> void:
	var result := ledger()
	assert_eq((result["problems"] as Array).size(), 0, "route replay problems: %s" % str(result["problems"]))
	# Same order as the production continuous harness.
	var source := FileAccess.get_file_as_string(HARNESS_PATH)
	var run_start := source.find("func _run()")
	var run_end := source.find("\nfunc ", run_start + 1)
	var body := source.substr(run_start, run_end - run_start)
	var cursor := 0
	for needle: String in HARNESS_ORDER:
		var at := body.find(needle, cursor)
		assert_true(at >= 0, "the harness no longer calls %s after position %d; re-derive ROUTE" % [needle, cursor])
		if at >= 0:
			cursor = at
	# Every non-optional ladder entry is fought, and every fought one is required.
	var fought := _required_trainers()
	for id: String in _ladder():
		var optional := bool((_ladder()[id] as Dictionary).get("optional", true))
		assert_eq(id in fought, not optional,
			"trainer '%s' (optional=%s) disagrees with the ledger's required fights" % [id, str(optional)])
	assert_true(_meadows_exit_lead() > 0, "chapter_curve.json lost its Meadows exit lead level")
	# Every act objective flag is reached by the replay (the route is complete).
	var reached: Dictionary = {}
	for flag: String in START_FLAGS:
		reached[flag] = true
	for raw: Variant in ROUTE:
		for flag: Variant in ((raw as Dictionary).get("sets", []) as Array):
			reached[str(flag)] = true
		for flag: Variant in ((raw as Dictionary).get("after", []) as Array):
			reached[str(flag)] = true
		if (raw as Dictionary).has("trainer"):
			reached[str((_ladder().get(str((raw as Dictionary)["trainer"]), {}) as Dictionary).get("defeat_flag", ""))] = true
	for act_raw: Variant in (_json(CHAPTER_PATH).get("acts", []) as Array):
		var act := act_raw as Dictionary
		assert_true(reached.has(str(act.get("completion_flag", ""))),
			"act completion '%s' is never reached by the replay" % str(act.get("completion_flag", "")))
		for obj_raw: Variant in (act.get("objectives", []) as Array):
			var objective := obj_raw as Dictionary
			assert_true(reached.has(str(objective.get("flag_id", ""))),
				"objective '%s' flag '%s' is never reached by the replay"
				% [str(objective.get("id", "")), str(objective.get("flag_id", ""))])

func test_gates_are_respected_leg_by_leg() -> void:
	var result := ledger()
	var tables := _tables()
	var credited: Dictionary = {}
	var closed_total := 0
	# Re-derive each credited site's gate against the flags the replay held.
	var flags: Dictionary = {}
	for flag: String in START_FLAGS:
		flags[flag] = true
	var sites := _by_id(_json(ENCOUNTERS_PATH).get("wild_sites", []))
	for s in ROUTE.size():
		var step: Dictionary = ROUTE[s]
		var row: Dictionary = (result["steps"] as Array)[s] as Dictionary
		for id: Variant in (row["sites_open"] as Array):
			var gate := str((tables.get(str((sites[str(id)] as Dictionary).get("table_id", "")), {}) as Dictionary).get("requires_unlock", ""))
			assert_true(gate.is_empty() or flags.has(gate),
				"step %d credits site %s while its gate %s is closed" % [s, str(id), gate])
			assert_false(credited.has(str(id)), "site %s credited twice" % str(id))
			credited[str(id)] = true
		closed_total += (row["sites_closed"] as Array).size()
		for flag: Variant in (step.get("sets", []) as Array):
			flags[str(flag)] = true
		for flag: Variant in (step.get("after", []) as Array):
			flags[str(flag)] = true
		if step.has("trainer"):
			flags[str((_ladder().get(str(step["trainer"]), {}) as Dictionary).get("defeat_flag", ""))] = true
	# The fly-gated Windscar return pairs are passed while closed on the way to
	# Maela and must then count on the grounded return, not before Maela.
	assert_true(closed_total > 0, "no gate-closed site was ever passed; the gate check has gone quiet")
	var maela: Dictionary = (result["phases"] as Array)[1] as Dictionary
	for raw: Variant in (maela["sites"] as Array):
		var gate := str((tables.get(str((sites[str((raw as Dictionary)["id"])] as Dictionary).get("table_id", "")), {}) as Dictionary).get("requires_unlock", ""))
		assert_true(gate.is_empty(), "Maela's phase credits gated site %s" % str((raw as Dictionary)["id"]))
	# Restored-summit pairs open only at the overlook: never credited.
	for id: String in credited:
		assert_ne(str((sites[id] as Dictionary).get("table_id", "")), "cloudreach_summit_restored_wild",
			"a restored-winds pair was credited before the winds were restored")


func test_every_retained_member_meets_each_required_fights_band() -> void:
	_print_ledger()
	var result := ledger()
	assert_eq((result["phases"] as Array).size(), _required_trainers().size())
	var unique: Dictionary = {}
	for id: Variant in (result["fought_ids"] as Array):
		assert_false(unique.has(str(id)), "wild site '%s' was fought twice" % str(id))
		unique[str(id)] = true
	for raw: Variant in (result["phases"] as Array):
		var row := raw as Dictionary
		assert_false(bool(row["optional"]), "an optional trainer was counted as required income")
		var before: Array = row["before"] as Array
		# Senn/Maela/Voss: meet the band. Veyra (the finale): beat it by LATE_MARGIN.
		assert_eq(int(row["min_margin"]), LATE_MARGIN if bool(row["finale"]) else 0)
		assert_true(int(row["lead_margin"]) >= int(row["min_margin"]),
			("%s: the lead reaches L%d but the ace is L%d and the band asks for L%d + %d margin "
			+ "(%d/%d wild defeats, +%d candy levels, no catch)") % [str(row["name"]),
			int(before[LEAD_INDEX]), int(row["ace"]), int(row["need_lead"]), int(row["min_margin"]),
			int(row["fought"]), int(row["available"]), int(row["candy"])])
		assert_true(int(row["all_margin"]) >= int(row["min_margin"]),
			"%s: the weakest retained member is L%d against a band of L%d + %d margin (party %s)"
			% [str(row["name"]), _min_level(before), int(row["need_all"]), int(row["min_margin"]), str(before)])


func test_the_retained_five_leave_cloudreach_inside_the_envelope() -> void:
	_print_ledger()
	var exit_levels: Array = ledger()["exit"] as Array
	assert_true(int(exit_levels[LEAD_INDEX]) >= CLOUDREACH_EXIT_TARGET + LATE_MARGIN,
		"the lead leaves Cloudreach at L%d against WORLD §2.4's exit target L%d + %d margin"
		% [int(exit_levels[LEAD_INDEX]), CLOUDREACH_EXIT_TARGET, LATE_MARGIN])
	assert_true(_min_level(exit_levels) >= CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD + LATE_MARGIN,
		"the weakest retained member leaves at L%d against L%d + %d margin"
		% [_min_level(exit_levels), CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD, LATE_MARGIN])


func test_negative_controls_fail_the_same_assertion() -> void:
	# Each control removes one real income source; the same shortfall check
	# that passes the shipped ledger must now report a failure. If a control
	# stops failing, the ledger has slack it does not admit, or went quiet.
	assert_eq(shortfalls(ledger()).size(), 0, "baseline must pass for the controls to mean anything")
	var controls := [{"drop_wild_phase": 2}, {"drop_trainer_xp": "officer_voss_summit_approach", "drop_wild_phase": 3},
		{"drop_candy": true}, {"wild_fraction": 0.25}]
	for options: Dictionary in controls:
		var failures := shortfalls(ledger(options))
		assert_true(failures.size() > 0, "negative control %s did not fail the ledger" % str(options))


func test_required_coin_income_before_the_finale_covers_two_losses() -> void:
	_print_ledger()
	for item_id: String in LOSS_BASKET:
		assert_true(_price(item_id) > 0, "no vendor prices '%s'; the loss basket is imaginary" % item_id)
	# A loss to the finale is by definition suffered before the finale pays, so
	# only the required trainers BEFORE it fund the two recoveries.
	var income := 0
	for raw: Variant in (ledger()["phases"] as Array):
		var row := raw as Dictionary
		if not bool(row["finale"]):
			income += int(row["coins"])
	var cost := _loss_basket_price() * LOSSES
	assert_true(income > 0, "the required Cloudreach trainers pay no coins at all")
	assert_true(income >= cost,
		("Cloudreach's required trainers pay %d coins before the finale and recovering from %d "
		+ "losses costs %d at the documented basket price") % [income, LOSSES, cost])


func test_required_interaction_costs_have_a_150_percent_route_supply() -> void:
	_print_ledger()
	var outputs: Dictionary = {}
	for raw: Variant in (_json(RECIPES_PATH).get("recipes", {}) as Dictionary).values():
		outputs[str(((raw as Dictionary).get("output", {}) as Dictionary).get("id", ""))] = true
	var aerie_seen := false
	var required := _required_flags()
	var costed := 0
	for spec_raw: Variant in (_json(PHYSICAL_PATH).get("interactions", []) as Array):
		var spec := spec_raw as Dictionary
		if required.has(str(spec.get("completion_flag", ""))) and not (spec.get("cost", {}) as Dictionary).is_empty():
			costed += 1
	var seen := 0
	for raw: Variant in (ledger()["phases"] as Array):
		for cost_raw: Variant in ((raw as Dictionary)["costs"] as Array):
			var cost := cost_raw as Dictionary
			seen += 1
			assert_false(outputs.has(str(cost["item_id"])),
				"'%s' costs a crafted item; this ledger only models raw first-pass supply" % str(cost["interaction"]))
			if str(cost["interaction"]) == "aerie_repair":
				aerie_seen = true
				assert_eq(int(cost["count"]), int(_json(PHYSICAL_PATH).get("aerie_fiber_cost", -1)),
					"the aerie repair's cost row disagrees with aerie_fiber_cost")
			assert_true(float(cost["supply"]) >= float(cost["count"]) * SUPPLY_MARGIN,
				"'%s' needs %d %s; the route reached only %d before it (< %.0f%%)"
				% [str(cost["interaction"]), int(cost["count"]), str(cost["item_id"]), int(cost["supply"]),
				SUPPLY_MARGIN * 100.0])
	assert_eq(seen, costed, "a required costed interaction is not on the replayed route")
	assert_true(aerie_seen, "the required aerie repair no longer has a cost row")


func test_no_required_step_requires_a_catch() -> void:
	var checked := 0
	# Objectives: every requirement, completion event and key.
	for act_raw: Variant in (_json(CHAPTER_PATH).get("acts", []) as Array):
		for obj_raw: Variant in ((act_raw as Dictionary).get("objectives", []) as Array):
			var objective := obj_raw as Dictionary
			var id := str(objective.get("id", ""))
			for key: Variant in objective.keys():
				assert_eq(_names_a_catch(str(key)), "", "objective '%s' carries a '%s' field" % [id, str(key)])
			var strings: Array = [str(objective.get("completion_event", ""))]
			for key: String in ["requires_flags", "count_flags"]:
				strings.append_array(objective.get(key, []) as Array)
			for value: Variant in strings:
				checked += 1
				assert_eq(_names_a_catch(str(value)), "", "objective '%s' requires '%s'" % [id, str(value)])
	# Every replayed step's prerequisites (trainers, interactions, triggers).
	for raw: Variant in ROUTE:
		for value: Variant in _step_requires(raw as Dictionary):
			checked += 1
			assert_eq(_names_a_catch(str(value)), "", "required step %s checks '%s'" % [_label(raw as Dictionary), str(value)])
	var placements := _by_id(_json(ENCOUNTERS_PATH).get("trainers", []))
	for id: String in _required_trainers():
		var values: Array = []
		values.append_array((placements.get(id, {}) as Dictionary).get("requires_flags", []) as Array)
		for key: Variant in (_ladder().get(id, {}) as Dictionary).keys():
			values.append(str(key))
		for value: Variant in values:
			checked += 1
			assert_eq(_names_a_catch(str(value)), "", "required trainer '%s' checks '%s'" % [id, str(value)])
	var finale_values: Array = []
	finale_values.append_array(_json(FINALE_PATH).get("requires_flags", []) as Array)
	finale_values.append_array((_json(CHAPTER_PATH).get("final_encounter", {}) as Dictionary).get("requires_flags", []) as Array)
	for value: Variant in finale_values:
		checked += 1
		assert_eq(_names_a_catch(str(value)), "", "the finale checks '%s'" % str(value))
	assert_true(checked >= 40, "only %d required requirements were inspected; this check has gone quiet" % checked)
	# The one required step that needs a creature capability is Fly. WORLD §4.2:
	# Maela's loaner keeps a non-flying five from deadlocking, and never becomes
	# owned. Without it, "earn Fly" would be a required catch.
	var loaner: Dictionary = _json(FLY_PATH).get("mentor_loaner", {}) as Dictionary
	assert_false(str(loaner.get("species_id", "")).is_empty(), "Fly has no mentor loaner; a non-flying five must catch a carrier")
	assert_eq(str(loaner.get("realm_id", "")), "cloudreach")
	assert_true(bool(loaner.get("available_during_trial", false)), "the loaner is withheld from the required flight trial")
	assert_true(bool(loaner.get("available_after_unlock", false)), "the loaner is withheld from the required Sky Shrine flight")
	# The chapter pays no creature: nothing replaces the five by reward.
	for raw: Variant in ((_json(CHAPTER_PATH).get("rewards", {}) as Dictionary).get("grants", []) as Array):
		var kind := str((raw as Dictionary).get("kind", ""))
		assert_false(kind.contains("creature") or kind.contains("legendary"),
			"the chapter reward grants a '%s'" % kind)
