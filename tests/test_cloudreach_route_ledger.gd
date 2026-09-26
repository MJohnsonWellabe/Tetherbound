extends "res://tests/test_case.gd"

# ROADMAP F07 / ACCEPTANCE §6.1 F07: "an earned route and resource/XP ledger
# show no required new catch"; ACCEPTANCE §6 Cloudreach card: "Full route
# resource/XP ledger supports the retained five without a new catch".
#
# This is the ledger. It is pure data: it reads the shipped Cloudreach JSON,
# the shipped XP arithmetic (scripts/creatures/progression.gd, the same static
# functions combat_manager.gd::_award_victory calls) and walks the REQUIRED
# story route once, in order, with the five creatures the Meadows hands over.
# It never catches, never fights a wild site twice and never counts optional
# detours, Fly-only pockets or optional trainers. No scene tree: tests run from
# SceneTree._init, where no root exists.
#
# Every figure below is read from data or from a spec line named next to it.
# Where the specs leave a number open, the constant says so and is chosen in
# the conservative direction. If an assertion fails, the printed ledger is the
# evidence; do not tune data or loosen a constant to turn it green.

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

## --- the team the Meadows hands over ------------------------------------------
## Lead level: data/config/chapter_curve.json band5_stronghold_approach
## `team.exit` 21 (the level AFTER the Warden's XP is banked), which is also
## PROGRESSION.md §3's Meadows row "L3 → L21 lead". The other four: the same
## row's "other retained members within3 levels", taken at its floor (21-3).
const MEADOWS_EXIT_REGION := "band5_stronghold_approach"
const RETAINED_SPREAD := 3
const TEAM_SIZE := 5
## The lead (index 0) is the active creature for every defeat; the other four
## are the "other eligible living party creature[s]" that receive the share
## (PROGRESSION.md §2; combat_manager.gd::_award_victory). No member faints, so
## no member misses XP. This is the floor for the four: they never lead.
const LEAD_INDEX := 0

## --- the difficulty band a required trainer asks for ---------------------------
## WORLD.md §2.4 Cloudreach row: intended exit 33 against Veyra's ace 34 -- the
## chapter's own envelope expects the lead to FINISH one level under the final
## ace, i.e. to fight it about two under. PROGRESSION.md §3's only per-creature
## level tolerance is "deficit≤2" (and "wild high≥entry−2"). So the lead must
## stand within 2 of each required trainer's ace before the fight, and every
## other retained member within RETAINED_SPREAD of that lead band.
const LEAD_ACE_TOLERANCE := 2
## WORLD.md §2.4: "Cloudreach | 18–21 overlap | 33 target; Veyra ace 34".
const CLOUDREACH_EXIT_TARGET := 33

## --- what the required route is allowed to pay ------------------------------
## Conservative assumption (no spec figure exists): Cloudreach wilds are
## non-aggressive (cloudreach_encounter_director.gd spawn_wild "aggressive":
## false), so every wild fight is the player's choice. Credit only HALF the
## wild sites that stand on the required route, each fought once (PROGRESSION
## §7 "zero repeat wild encounters"; WORLD §2.5 "no wild respawns at all"),
## ONE defeat per site although every site is a pair, at its table's MINIMUM
## level, lowest-level tables first.
const WILD_FRACTION := 0.5
## A wild site or verge pickup is "on" a required leg when it lies this close
## to the leg's polyline. The road-visibility pairs stand 5.5 m off the centre
## line and route_verge candy about 2 m off; optional loops are separate
## polylines, so nothing on them is picked up by a radius this small.
const ON_ROUTE_M := 12.0
## A harvest node is reachable from a required leg when it lies this close.
## The scripted required path (tests/helpers/cloudreach_live_segment.gd) steps
## off the causeway for the 13.0 m and 19.8 m gale-fiber nodes; the 38 m gate
## node sits beside the OPTIONAL lower_overlook_loop and is excluded.
const RESOURCE_REACH_M := 25.0
## Every story anchor of a phase must lie this close to that phase's legs, or
## the declared required route below has drifted from the data.
const ANCHOR_TOLERANCE_M := 25.0

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

## The required story route, in story order, one phase per required trainer.
## Each leg is [route_id, from_vertex, to_vertex] of a cloudreach_world.json
## polyline. Derived from the three acts' objectives and the ground-route graph
## (routes join only at shared vertices, as the live segment's _navigate does):
##  - Senn: arrival road -> lower cliff road -> main causeway up to vertex 9,
##    Senn's battle-yard road position (cloudreach_scene_runtime.json). Both
##    lower anchors (act-one runtime) sit on it. lower_overlook_loop and
##    causeway_west_loop are declared optional in their own `purpose`.
##  - Maela: the causeway's last span into the ravine, the Windscar floor loop
##    to the aerie (signal bell, Maela, aerie repair, flight trial).
##  - Voss: the mandatory Fly crossing (objective cloudreach_reach_sky_shrine;
##    Maela's loaner guarantees it) plus the sky_shrine landing objective, the
##    counterweight stair, the plateau circuit through both upper anchors
##    (vertices 0..4; its closing leg to Cliffhold is a dead-end spur in the
##    graph and is NOT counted), and the summit road to Voss's yard (vertex 3).
##  - Veyra: the summit road's last span to the summit threshold.
## The summit overlook loop is only walked after Veyra, so it never counts.
const REQUIRED_PHASES := [
	{"trainer": "tether_lieutenant_senn",
		"legs": [["arrival_gate_road", 0, 4], ["lower_cliff_road", 0, 3], ["broken_causeway_main", 0, 9]],
		"landing": "",
		"anchors": [["anchor", "lower_west"], ["anchor", "lower_east"], ["yard", "tether_lieutenant_senn"]]},
	{"trainer": "keeper_maela_trial",
		"legs": [["broken_causeway_main", 9, 10], ["windscar_floor_loop", 0, 5]],
		"landing": "",
		"anchors": [["interaction", "causeway_signal"], ["trainer", "keeper_maela_trial"],
			["interaction", "aerie_repair"], ["interaction", "flight_trial_start"]]},
	{"trainer": "officer_voss_summit_approach",
		"legs": [["windscar_to_high_roost_flight", 0, 3], ["windscar_counterweight_pass", 0, 5],
			["upper_plateau_circuit", 0, 4], ["upper_summit_road", 0, 3]],
		"landing": "sky_shrine",
		"anchors": [["landing", "sky_shrine"], ["interaction", "shrine_windlass"],
			["trigger", "counterweight_entered"], ["interaction", "upper_anchor_west"],
			["interaction", "upper_anchor_east"], ["yard", "officer_voss_summit_approach"]]},
	{"trainer": "captain_veyra_storm_anchor",
		"legs": [["upper_summit_road", 3, 4]],
		"landing": "",
		"anchors": [["interaction", "summit_feed"], ["trigger", "summit_threshold"]]},
]

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


func _ace(trainer_id: String) -> int:
	var ace := 0
	var trainer: Dictionary = _ladder().get(trainer_id, {}) as Dictionary
	for raw: Variant in ((trainer.get("team_contract", {}) as Dictionary).get("slots", []) as Array):
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


# --- geometry -------------------------------------------------------------------

func _leg_distance(point: Vector3, legs: Array) -> float:
	var routes := _routes()
	var best := INF
	for raw: Variant in legs:
		var leg := raw as Array
		var polyline: Array = (routes.get(str(leg[0]), {}) as Dictionary).get("polyline", []) as Array
		var last := mini(int(leg[2]), polyline.size() - 1)
		for i in range(int(leg[1]), last):
			var closest := Geometry3D.get_closest_point_to_segment(point, _vec(polyline[i]), _vec(polyline[i + 1]))
			best = minf(best, point.distance_to(closest))
	return best


func _landing(id: String) -> Dictionary:
	return _by_id(_json(PHYSICAL_PATH).get("landing_objectives", [])).get(id, {}) as Dictionary


func _phase_distance(point: Vector3, phase: Dictionary) -> float:
	var best := _leg_distance(point, phase["legs"] as Array)
	var landing_id := str(phase.get("landing", ""))
	if not landing_id.is_empty():
		var landing := _landing(landing_id)
		var centre := _vec(landing.get("position", []))
		if centre.is_finite() and point.distance_to(centre) <= float(landing.get("radius_m", 0.0)):
			best = 0.0
	return best


func _pickup_position(spec: Dictionary) -> Vector3:
	var overrides: Dictionary = _json(PHYSICAL_PATH).get("pickup_overrides", {}) as Dictionary
	var id := str(spec.get("id", ""))
	return _vec(overrides[id]) if overrides.has(id) else _vec(spec.get("position", []))


func _anchor_position(kind: String, id: String) -> Vector3:
	var row: Dictionary = {}
	match kind:
		"anchor":
			row = _by_id(_json(ACT_ONE_PATH).get("anchors", [])).get(id, {}) as Dictionary
		"interaction":
			row = _by_id(_json(PHYSICAL_PATH).get("interactions", [])).get(id, {}) as Dictionary
		"landing":
			row = _landing(id)
		"trigger":
			row = _by_id(_json(PHYSICAL_PATH).get("ground_triggers", [])).get(id, {}) as Dictionary
		"yard":
			var yard: Dictionary = _by_id(_json(SCENE_PATH).get("battle_yards", [])).get(id, {}) as Dictionary
			return _vec(yard.get("road_position", []))
		"trainer":
			row = _by_id(_json(ENCOUNTERS_PATH).get("trainers", [])).get(id, {}) as Dictionary
	return _vec(row.get("position", []))


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
func _defeat(party: Array, enemy_level: int) -> int:
	var award: int = PROGRESSION.xp_award_for(enemy_level, _cfg())
	var share: int = PROGRESSION.party_share(award, _cfg())
	for i in party.size():
		_gain(party[i] as Dictionary, award if i == LEAD_INDEX else share)
	return award


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

func _ledger() -> Dictionary:
	if _cache.has("__ledger"):
		return _cache["__ledger"] as Dictionary
	var lead := _meadows_exit_lead()
	var party: Array = []
	for i in TEAM_SIZE:
		party.append({"level": lead if i == LEAD_INDEX else lead - RETAINED_SPREAD, "xp": 0})
	var entry := _levels(party)
	var tables := _tables()
	var items := _items()
	var sites_used: Dictionary = {}
	var pickups_used: Dictionary = {}
	var fought_ids: Array = []
	var rows: Array = []
	var recovery_pre_finale: Dictionary = {"potion_small": 0, "potion_large": 0, "revive": 0}
	for p in REQUIRED_PHASES.size():
		var phase: Dictionary = REQUIRED_PHASES[p]
		var trainer_id := str(phase["trainer"])
		var finale := p == REQUIRED_PHASES.size() - 1

		# Route-verge pickups on this phase's legs, each claimed once.
		var candy_levels := 0
		var candy_ids: Array = []
		for raw: Variant in (_json(CHAPTER_PATH).get("pickups", []) as Array):
			var spec := raw as Dictionary
			var id := str(spec.get("id", ""))
			if pickups_used.has(id) or str(spec.get("placement", "")) != "route_verge":
				continue
			if _phase_distance(_pickup_position(spec), phase) > ON_ROUTE_M:
				continue
			pickups_used[id] = true
			var item_id := str(spec.get("item_id", ""))
			var up := int((items.get(item_id, {}) as Dictionary).get("level_up", 0)) * int(spec.get("count", 1))
			if up > 0:
				candy_levels += up
				candy_ids.append(id)
			elif not finale and recovery_pre_finale.has(item_id):
				recovery_pre_finale[item_id] = int(recovery_pre_finale[item_id]) + int(spec.get("count", 1))
		# Candy first (each later level costs more XP: the conservative order),
		# always into the lowest-level member.
		for _i in candy_levels:
			_feed_candy(_lowest(party), 1)

		# Required-route wild sites, each fought at most once, ever.
		var sites: Array = []
		for raw: Variant in (_json(ENCOUNTERS_PATH).get("wild_sites", []) as Array):
			var site := raw as Dictionary
			var id := str(site.get("id", ""))
			if sites_used.has(id) or _phase_distance(_vec(site.get("position", [])), phase) > ON_ROUTE_M:
				continue
			sites_used[id] = true
			sites.append(site)
		var low_level := func(site: Dictionary) -> int:
			var table: Dictionary = tables.get(str(site.get("table_id", "")), {}) as Dictionary
			return int((table.get("level_range", [0, 0]) as Array)[0])
		sites.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return low_level.call(a) < low_level.call(b))
		var fought := floori(float(sites.size()) * WILD_FRACTION)
		var wild_xp := 0
		for i in fought:
			var site: Dictionary = sites[i]
			fought_ids.append(str(site.get("id", "")))
			wild_xp += _defeat(party, int(low_level.call(site)))

		# The required trainer.
		var ace := _ace(trainer_id)
		var before := _levels(party)
		var trainer_xp := 0
		var trainer: Dictionary = _ladder().get(trainer_id, {}) as Dictionary
		for raw: Variant in ((trainer.get("team_contract", {}) as Dictionary).get("slots", []) as Array):
			trainer_xp += _defeat(party, int((raw as Dictionary).get("level", 0)))
		var reward := _reward(trainer_id)
		if not finale:
			for raw: Variant in (reward.get("items", []) as Array):
				var grant := raw as Dictionary
				var grant_id := str(grant.get("id", ""))
				if recovery_pre_finale.has(grant_id):
					recovery_pre_finale[grant_id] = int(recovery_pre_finale[grant_id]) + int(grant.get("count", 0))
		rows.append({
			"trainer": trainer_id, "name": str(trainer.get("name", trainer_id)),
			"optional": bool(trainer.get("optional", true)), "finale": finale,
			"sites": sites.size(), "fought": fought, "wild_xp": wild_xp,
			"candy_levels": candy_levels, "candy_ids": candy_ids,
			"ace": ace, "need_lead": ace - LEAD_ACE_TOLERANCE,
			"need_all": ace - LEAD_ACE_TOLERANCE - RETAINED_SPREAD,
			"before": before, "trainer_xp": trainer_xp, "after": _levels(party),
			"coins": int(reward.get("coins", 0)),
		})
	var ledger := {"entry": entry, "rows": rows, "exit": _levels(party),
		"fought_ids": fought_ids, "recovery_pre_finale": recovery_pre_finale}
	_cache["__ledger"] = ledger
	return ledger


func _print_ledger() -> void:
	if _printed:
		return
	_printed = true
	var ledger := _ledger()
	print("")
	print("  CLOUDREACH ROUTE LEDGER  entry %s  lead=index %d  wild fraction %.2f  no catches, no repeats"
		% [str(ledger["entry"]), LEAD_INDEX, WILD_FRACTION])
	print("  %-16s %-7s %7s %6s %4s %9s  %-20s %6s  %-20s" % ["trainer", "wilds", "wildXP",
		"candy", "ace", "need L/all", "levels before", "trnXP", "levels after"])
	for raw: Variant in (ledger["rows"] as Array):
		var row := raw as Dictionary
		print("  %-16s %-7s %7d %6s %4d %9s  %-20s %6d  %-20s" % [str(row["name"]),
			"%d/%d" % [int(row["fought"]), int(row["sites"])], int(row["wild_xp"]),
			"+%d" % int(row["candy_levels"]), int(row["ace"]),
			"%d/%d" % [int(row["need_lead"]), int(row["need_all"])],
			_join(row["before"] as Array), int(row["trainer_xp"]), _join(row["after"] as Array)])
	var exit_levels: Array = ledger["exit"] as Array
	print("  exit %s  (lead target %d, others >= %d)" % [_join(exit_levels),
		CLOUDREACH_EXIT_TARGET, CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD])
	var pre := 0
	var total := 0
	for raw: Variant in (ledger["rows"] as Array):
		var row := raw as Dictionary
		total += int(row["coins"])
		if not bool(row["finale"]):
			pre += int(row["coins"])
	print("  coins: required pre-finale %d, required total %d; %d losses x basket %d = %d"
		% [pre, total, LOSSES, _loss_basket_price(), _loss_basket_price() * LOSSES])
	print("  in-kind recovery on the required route before the finale: %s"
		% str(ledger["recovery_pre_finale"]))
	for raw: Variant in _required_costs():
		var cost := raw as Dictionary
		print("  supply: %s needs %d %s; reachable first-pass supply %d from %s"
			% [str(cost["interaction"]), int(cost["count"]), str(cost["item_id"]),
			int(cost["supply"]), str(cost["nodes"])])
	print("")


func _join(values: Array) -> String:
	var parts := PackedStringArray()
	for value: Variant in values:
		parts.append(str(int(value)))
	return " ".join(parts)


# --- required flags, costs and catch checks --------------------------------------

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
	for phase_raw: Variant in REQUIRED_PHASES:
		var trainer: Dictionary = _ladder().get(str((phase_raw as Dictionary)["trainer"]), {}) as Dictionary
		flags[str(trainer.get("defeat_flag", ""))] = true
	flags.erase("")
	return flags


func _required_interactions() -> Array:
	var required := _required_flags()
	var out: Array = []
	for raw: Variant in (_json(PHYSICAL_PATH).get("interactions", []) as Array):
		var spec := raw as Dictionary
		if required.has(str(spec.get("completion_flag", ""))):
			out.append(spec)
	return out


## The first phase whose own legs pass within ANCHOR_TOLERANCE_M of `point`.
func _phase_of(point: Vector3) -> int:
	for p in REQUIRED_PHASES.size():
		if _phase_distance(point, REQUIRED_PHASES[p] as Dictionary) <= ANCHOR_TOLERANCE_M:
			return p
	return -1


func _required_costs() -> Array:
	var out: Array = []
	var nodes: Array = (_json(CHAPTER_PATH).get("resource_tier", {}) as Dictionary).get("nodes", []) as Array
	for raw: Variant in _required_interactions():
		var spec := raw as Dictionary
		var cost: Dictionary = spec.get("cost", {}) as Dictionary
		if cost.is_empty():
			continue
		var item_id := str(cost.get("item_id", ""))
		var phase := _phase_of(_vec(spec.get("position", [])))
		var legs: Array = []
		for p in range(0, phase + 1):
			legs.append_array((REQUIRED_PHASES[p] as Dictionary)["legs"] as Array)
		var supply := 0
		var used: Array = []
		for node_raw: Variant in nodes:
			var node := node_raw as Dictionary
			if str(node.get("resource_id", "")) != item_id:
				continue
			# First pass only: world_day_regrow is not counted (PROGRESSION §6
			# "do not silently turn all nodes into infinite respawn").
			var distance := _leg_distance(_vec(node.get("position", [])), legs)
			if phase >= 0 and distance <= RESOURCE_REACH_M:
				supply += int(node.get("amount", 0))
				used.append("%s(%d@%.1fm)" % [str(node.get("id", "")), int(node.get("amount", 0)), distance])
		out.append({"interaction": str(spec.get("id", "")), "item_id": item_id,
			"count": int(cost.get("count", 0)), "phase": phase, "supply": supply, "nodes": used})
	return out


func _names_a_catch(value: String) -> String:
	var lower := value.to_lower()
	for token: String in CATCH_TOKENS:
		if lower.contains(token):
			return token
	return ""


# --- tests ----------------------------------------------------------------------

func test_the_declared_required_route_is_the_story_route() -> void:
	var routes := _routes()
	var declared: Dictionary = {}
	for raw: Variant in REQUIRED_PHASES:
		var phase := raw as Dictionary
		declared[str(phase["trainer"])] = true
		for leg_raw: Variant in (phase["legs"] as Array):
			var leg := leg_raw as Array
			var route: Dictionary = routes.get(str(leg[0]), {}) as Dictionary
			assert_false(route.is_empty(), "required leg names no route: %s" % str(leg[0]))
			var size := (route.get("polyline", []) as Array).size()
			assert_true(int(leg[1]) >= 0 and int(leg[1]) < int(leg[2]) and int(leg[2]) < size,
				"required leg %s has vertex range %d..%d outside its %d-point polyline"
				% [str(leg[0]), int(leg[1]), int(leg[2]), size])
			if str(route.get("traversal_mode", "")) == "fly":
				assert_eq(str(phase.get("landing", "")), "sky_shrine",
					"a Fly leg is counted only where an objective requires that landing")
		for anchor_raw: Variant in (phase["anchors"] as Array):
			var anchor := anchor_raw as Array
			var at := _anchor_position(str(anchor[0]), str(anchor[1]))
			assert_true(at.is_finite(), "story anchor %s/%s has no position" % [str(anchor[0]), str(anchor[1])])
			if at.is_finite():
				var distance := _phase_distance(at, phase)
				assert_true(distance <= ANCHOR_TOLERANCE_M,
					"story anchor %s/%s is %.1f m from %s's declared legs; the required route has drifted"
					% [str(anchor[0]), str(anchor[1]), distance, str(phase["trainer"])])
	# Every non-optional ladder entry is a phase, and every phase is required.
	for id: String in _ladder():
		var optional := bool((_ladder()[id] as Dictionary).get("optional", true))
		assert_eq(declared.has(id), not optional,
			"trainer '%s' (optional=%s) disagrees with the ledger's required phases" % [id, str(optional)])
	var lead := _meadows_exit_lead()
	assert_true(lead > 0, "chapter_curve.json lost its Meadows exit lead level")


func test_every_retained_member_meets_each_required_trainers_band() -> void:
	_print_ledger()
	var ledger := _ledger()
	var rows: Array = ledger["rows"] as Array
	assert_eq(rows.size(), REQUIRED_PHASES.size())
	var fought: Array = ledger["fought_ids"] as Array
	var unique: Dictionary = {}
	for id: Variant in fought:
		assert_false(unique.has(str(id)), "wild site '%s' was fought twice" % str(id))
		unique[str(id)] = true
	for raw: Variant in rows:
		var row := raw as Dictionary
		assert_false(bool(row["optional"]), "an optional trainer was counted as required income")
		var before: Array = row["before"] as Array
		assert_true(int(before[LEAD_INDEX]) >= int(row["need_lead"]),
			("%s: the lead reaches L%d but the ace is L%d and the band asks for L%d "
			+ "(%d wild defeats, +%d candy levels, no catch)") % [str(row["name"]),
			int(before[LEAD_INDEX]), int(row["ace"]), int(row["need_lead"]), int(row["fought"]),
			int(row["candy_levels"])])
		assert_true(_min_level(before) >= int(row["need_all"]),
			"%s: the weakest retained member is L%d against a band of L%d (party %s)"
			% [str(row["name"]), _min_level(before), int(row["need_all"]), str(before)])


func test_the_retained_five_leave_cloudreach_inside_the_envelope() -> void:
	_print_ledger()
	var exit_levels: Array = _ledger()["exit"] as Array
	assert_true(int(exit_levels[LEAD_INDEX]) >= CLOUDREACH_EXIT_TARGET,
		"the lead leaves Cloudreach at L%d against WORLD §2.4's exit target L%d"
		% [int(exit_levels[LEAD_INDEX]), CLOUDREACH_EXIT_TARGET])
	assert_true(_min_level(exit_levels) >= CLOUDREACH_EXIT_TARGET - RETAINED_SPREAD,
		"the weakest retained member leaves at L%d, more than %d under the L%d exit target"
		% [_min_level(exit_levels), RETAINED_SPREAD, CLOUDREACH_EXIT_TARGET])


func test_required_coin_income_before_the_finale_covers_two_losses() -> void:
	_print_ledger()
	for item_id: String in LOSS_BASKET:
		assert_true(_price(item_id) > 0, "no vendor prices '%s'; the loss basket is imaginary" % item_id)
	# A loss to the finale is by definition suffered before the finale pays, so
	# only the required trainers BEFORE it fund the two recoveries.
	var income := 0
	for raw: Variant in (_ledger()["rows"] as Array):
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
	var costs := _required_costs()
	assert_true(costs.size() >= 1, "no required interaction costs anything; the aerie repair's fiber went missing")
	var outputs: Dictionary = {}
	for raw: Variant in (_json(RECIPES_PATH).get("recipes", {}) as Dictionary).values():
		outputs[str(((raw as Dictionary).get("output", {}) as Dictionary).get("id", ""))] = true
	var aerie_seen := false
	for raw: Variant in costs:
		var cost := raw as Dictionary
		assert_true(int(cost["phase"]) >= 0,
			"required interaction '%s' is not on the declared required route" % str(cost["interaction"]))
		assert_false(outputs.has(str(cost["item_id"])),
			"'%s' costs a crafted item; this ledger only models raw first-pass supply" % str(cost["interaction"]))
		if str(cost["interaction"]) == "aerie_repair":
			aerie_seen = true
			assert_eq(int(cost["count"]), int(_json(PHYSICAL_PATH).get("aerie_fiber_cost", -1)),
				"the aerie repair's cost row disagrees with aerie_fiber_cost")
		var needed := float(cost["count"]) * SUPPLY_MARGIN
		assert_true(float(cost["supply"]) >= needed,
			"'%s' needs %d %s; the required route reaches only %d on first pass (%.0f%% < %.0f%%): %s"
			% [str(cost["interaction"]), int(cost["count"]), str(cost["item_id"]), int(cost["supply"]),
			100.0 * float(cost["supply"]) / maxf(1.0, float(cost["count"])), SUPPLY_MARGIN * 100.0,
			str(cost["nodes"])])
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
	# Required trainers, under both their placement and runtime requirements.
	var placements := _by_id(_json(ENCOUNTERS_PATH).get("trainers", []))
	var runtime: Dictionary = _json(PHYSICAL_PATH).get("encounter_requirements", {}) as Dictionary
	for raw: Variant in REQUIRED_PHASES:
		var id := str((raw as Dictionary)["trainer"])
		var values: Array = []
		values.append_array((placements.get(id, {}) as Dictionary).get("requires_flags", []) as Array)
		values.append_array(runtime.get(id, []) as Array)
		for key: Variant in (_ladder().get(id, {}) as Dictionary).keys():
			values.append(str(key))
		for value: Variant in values:
			checked += 1
			assert_eq(_names_a_catch(str(value)), "", "required trainer '%s' checks '%s'" % [id, str(value)])
	# Required physical interactions and the finale.
	for raw: Variant in _required_interactions():
		var spec := raw as Dictionary
		for value: Variant in (spec.get("requires_flags", []) as Array):
			checked += 1
			assert_eq(_names_a_catch(str(value)), "",
				"required interaction '%s' checks '%s'" % [str(spec.get("id", "")), str(value)])
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
