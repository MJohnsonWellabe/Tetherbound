extends RefCounted

const PILOT := preload("res://tests/helpers/combat_depth_pilot.gd")
const CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CONTENT := preload("res://scripts/data/band_content.gd")


func run(tree: SceneTree, args: PackedStringArray) -> int:
	var seeds := 24
	var selection := ""
	var output := ""
	for arg in args:
		if arg.begins_with("--seeds="): seeds = maxi(1, int(arg.trim_prefix("--seeds=")))
		if arg.begins_with("--case="): selection = arg.trim_prefix("--case=")
		if arg.begins_with("--json="): output = arg.trim_prefix("--json=")
	var difficulty: Dictionary = CURVE.config().get("difficulty", {})
	var roster: Array = difficulty.get("party", ["terrapup"])
	var cases := _cases()
	var runs: Array[Dictionary] = []
	var rows: Array[Dictionary] = []
	var failures: Array[String] = []
	for entry in cases:
		if not selection.is_empty() and not str(entry.id).contains(selection): continue
		var paired: Dictionary = {}
		for policy in ["MASHER", "READER"]:
			var summary := {"wins": 0, "lead_cost": 0.0, "party_wipes": 0,
				"lead_faints": 0, "seconds": 0.0, "max_hit": 0.0}
			for seed_index in seeds:
				var party: Array[RefCounted] = []
				for id in roster:
					var creature: RefCounted = SPECIES.spawn(str(id))
					creature.set_level(int(entry.level), PROGRESSION.config())
					party.append(creature)
				var foes: Array[RefCounted] = []
				if entry.kind == "wild":
					var foe: RefCounted = SPECIES.spawn(str(entry.species))
					foe.set_level(int(entry.foe_level), PROGRESSION.config())
					foes.append(foe)
				else:
					for member in TRAINERS.team_of(entry.spec):
						foes.append(TRAINERS.creature_for(member))
				var pilot := PILOT.new()
				var result: Dictionary = await pilot.fight(tree, party, foes,
					entry.kind != "wild", hash("%s/%d" % [entry.id, seed_index]), policy)
				result["case"] = entry.id
				runs.append(result)
				summary.wins += int(result.won)
				summary.lead_cost += float(result.lead_lost_frac) / seeds
				summary.party_wipes += int(int(result.faints) == party.size())
				summary.lead_faints += int(party[0].fainted)
				summary.seconds += float(result.seconds) / seeds
				summary.max_hit = maxf(float(summary.max_hit), float(result.max_hit_frac))
				if result.stalled or result.has("fixture_error"):
					failures.append("%s %s seed %d: stalled or invalid fixture" % [entry.id, policy, seed_index])
				print("DEPTH %s %s seed=%d won=%s hp_cost=%.3f seconds=%.2f hits=%d incoming=%d" % [
					entry.id, policy, seed_index, result.won, result.lead_lost_frac,
					result.seconds, result.hits, result.incoming_hits])
			paired[policy] = summary
		rows.append({"case": entry.id, "kind": entry.kind, "pilots": paired})
		var verdict := threshold_verdict(entry, paired.MASHER, paired.READER, seeds, difficulty)
		rows.back()["threshold_verdict"] = verdict
		for category in ["depth_failures", "baseline_failures"]:
			for failure in verdict[category]:
				failures.append("%s [%s]: %s" % [entry.id, category, failure])
	if rows.is_empty(): failures.append("no cases matched selection: %s" % selection)
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		if file == null:
			failures.append("cannot write evidence: %s" % output)
		else:
			file.store_string(JSON.stringify({"seeds": seeds, "selection": selection,
				"targets": difficulty.get("combat_depth", {}),
				"fixture": "production manager + bodies on flat collider", "rows": rows,
				"runs": runs, "failures": failures,
				"scope": "COMBAT-1 diagnostic", "sampled_thresholds_satisfied": failures.is_empty(),
				"accepted": false, "coverage_complete": false,
				"missing_coverage": ["burst", "skill", "full teaching ladder", "independent visual/motion review", "owner feel review"]}, "  "))
	for failure in failures: print("DEPTH FAIL: %s" % failure)
	print("COMBAT-1 diagnostic (not final acceptance): %d cases, %d runs, %d unmet criteria" % [rows.size(), runs.size(), failures.size()])
	return 0 if failures.is_empty() else 1


## Pure verdict over observed summaries. Baseline and depth are separate claims:
## a harmless floor cannot pass simply because both pilots take zero damage.
static func threshold_verdict(entry: Dictionary, masher: Dictionary, reader: Dictionary,
		seeds: int, difficulty: Dictionary) -> Dictionary:
	var depth_failures: Array[String] = []
	var baseline_failures: Array[String] = []
	var result := {"depth_failures": depth_failures, "baseline_failures": baseline_failures}
	var targets: Dictionary = difficulty.get("combat_depth", {})
	for key in ["floor_reader_max_cost_ratio", "top_masher_min_lead_faint_rate",
			"top_masher_min_party_wipe_rate", "top_party_wipe_from_band",
			"top_reader_min_win_rate", "wild_masher_min_win_rate", "wild_masher_min_lead_hp_cost"]:
		if not targets.has(key): depth_failures.append("missing combat_depth target: %s" % key)
	for key in ["max_single_hit_fraction", "trainer_floor_min_win_rate", "trainer_floor_lead_hp_cost"]:
		if not difficulty.has(key): baseline_failures.append("missing baseline target: %s" % key)
	if seeds <= 0: depth_failures.append("no sampled runs")
	if not depth_failures.is_empty() or not baseline_failures.is_empty(): return result
	var same_outcomes := true
	for key in ["wins", "lead_cost", "party_wipes", "lead_faints", "seconds", "max_hit"]:
		if not is_equal_approx(float(masher[key]), float(reader[key])):
			same_outcomes = false
	if same_outcomes: depth_failures.append("both policies produced identical measured outcomes")
	var hit_limit := float(difficulty.max_single_hit_fraction)
	if float(reader.max_hit) >= hit_limit or float(masher.max_hit) >= hit_limit:
		depth_failures.append("a single hit reached the %.0f%% HP ceiling" % (hit_limit * 100.0))
	var kind := str(entry.kind)
	if kind == "floor":
		var ratio := float(targets.floor_reader_max_cost_ratio)
		if float(reader.lead_cost) > float(masher.lead_cost) * ratio:
			depth_failures.append("reader HP cost exceeds %.0f%% of masher cost" % (ratio * 100.0))
		var minimum_win := float(difficulty.trainer_floor_min_win_rate)
		if float(masher.wins) / seeds < minimum_win:
			baseline_failures.append("floor masher win rate below %.0f%%" % (minimum_win * 100.0))
		if float(reader.wins) / seeds < minimum_win:
			depth_failures.append("floor reader win rate below %.0f%%" % (minimum_win * 100.0))
		var cost_band: Array = difficulty.trainer_floor_lead_hp_cost
		if float(masher.lead_cost) < float(cost_band[0]) or float(masher.lead_cost) > float(cost_band[1]):
			baseline_failures.append("floor masher lead HP cost outside authored baseline band")
	elif kind == "top":
		if float(masher.lead_faints) / seeds < float(targets.top_masher_min_lead_faint_rate):
			depth_failures.append("masher did not lose lead every run")
		if int(entry.band) >= int(targets.top_party_wipe_from_band) \
				and float(masher.party_wipes) / seeds < float(targets.top_masher_min_party_wipe_rate):
			depth_failures.append("masher party wipe rate below %.0f%%" % (float(targets.top_masher_min_party_wipe_rate) * 100.0))
		if float(reader.wins) / seeds < float(targets.top_reader_min_win_rate):
			depth_failures.append("reader win rate below %.0f%%" % (float(targets.top_reader_min_win_rate) * 100.0))
	elif kind == "wild":
		if float(masher.wins) / seeds < float(targets.wild_masher_min_win_rate):
			depth_failures.append("ordinary wild walled the masher")
		if float(masher.lead_cost) < float(targets.wild_masher_min_lead_hp_cost):
			depth_failures.append("ordinary wild lead HP cost below %.0f%%" % (float(targets.wild_masher_min_lead_hp_cost) * 100.0))
	else:
		depth_failures.append("unknown case kind: %s" % kind)
	return result


func _cases() -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var curve: Dictionary = CURVE.config()
	var trainers: Array = CONTENT.load_config("res://data/config/trainers.json", "trainers").get("trainers", [])
	var spawns: Array = CONTENT.load_config("res://data/config/spawns.json", "spawns").get("spawns", [])
	var band_number := 0
	for region in CURVE.regions(curve):
		band_number += 1
		var level := int(region.get("team", {}).get("enter", 1))
		var wild_band: Array = region.get("wild_band", [level, level])
		var seen: Dictionary = {}
		for spawn in spawns:
			var centre: Array = spawn.get("centre", [])
			if centre.size() < 3 or CURVE.region_at(float(centre[2]), curve).get("id") != region.id: continue
			var species := str(spawn.get("species", ""))
			if seen.has(species) or not SPECIES.has(species): continue
			seen[species] = true
			cases.append({"id": "%s/wild/%s" % [region.id, species], "kind": "wild",
				"species": species, "level": level, "foe_level": int((int(wild_band[0]) + int(wild_band[1])) / 2)})
		var candidates: Array[Dictionary] = []
		for spec in trainers:
			var pos: Array = spec.get("position", [])
			if pos.size() < 2 or CURVE.region_at(float(pos[1]), curve).get("id") != region.id: continue
			if bool(spec.get("gate_fight", false)) or str(spec.get("id")) == "practice_trainer": continue
			candidates.append(spec)
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return _trainer_strength(a) < _trainer_strength(b))
		if not candidates.is_empty():
			for kind in ["floor", "top"]:
				var spec: Dictionary = candidates.front() if kind == "floor" else candidates.back()
				cases.append({"id": "%s/%s/%s" % [region.id, kind, spec.id], "kind": kind,
					"spec": spec, "level": level, "band": band_number})
	return cases


func _trainer_strength(spec: Dictionary) -> int:
	var highest := 0
	var total := 0
	for member in TRAINERS.team_of(spec):
		var level := int(member.get("level", 1))
		highest = maxi(highest, level)
		total += level
	return highest * 1000 + total
