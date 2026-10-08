extends SceneTree

## F22#1/#2 bounded C2 queue. Runs actual production bodies and manager;
## does not simulate damage or enable an absent consumer. Requires F19's
## new-order band targets and ROOT-integrated F22/F24 flags/callers.
## --seeds=12 --band=<substring> --json=<absolute output>
## A selected subset reports coverage=false and cannot certify all bands.
const PILOT := preload("res://tests/helpers/f22_pattern_pilot.gd")
const GEAR := preload("res://tests/helpers/f33_gear_fixture.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
## --trainers (coordinator ruling on F22#1, 2026-10-04): each band's ORDINARY
## trainer fights (COMBAT §7 floor trainer) instead of its wilds. Named
## pattern fights and boss ranks are excluded; a band without a roster in data
## is reported as a data gap, never filled with wilds.
const BOSS_RANKS := ["captain", "officer", "lieutenant", "elite"]
const STARTERS := ["terrapup", "ripplet", "galewisp"]
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
const EXPECTED_REGIONS := {
	"tidewake": ["first_shores", "marsh_channels", "tidal_cradle", "outer_reaches", "tether_current", "veilfall"],
	"cloudreach": ["gate_lower_cliffs", "broken_causeways", "windscar_ravine", "high_roost_sky_shrine", "upper_cloudreach", "summit_final_stronghold"],
	"stormwood": ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]}
var _seeds := 12
var _selection := ""
var _json := ""
var _trainers := false
## --named=<trainer id,...> (F22#4): those named trainers only, each with its
## authored F22 pattern row, judged on COMBAT §7's top-trainer bar.
var _named: PackedStringArray = []
## F33#2: --gear-tier / --gear-upgrade (tests/helpers/f33_gear_fixture.gd).
var _gear: Dictionary = GEAR.from_args()
var _compare_previous_gear := OS.get_cmdline_user_args().has("--compare-previous-gear")


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): _seeds = int(arg.trim_prefix("--seeds="))
		elif arg.begins_with("--band="): _selection = arg.trim_prefix("--band=")
		elif arg.begins_with("--json="): _json = arg.trim_prefix("--json=")
		elif arg == "--trainers": _trainers = true
		elif arg.begins_with("--named="):
			_named = arg.trim_prefix("--named=").split(",", false)
			_trainers = true
	_run.call_deferred()


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://" + path))
	return parsed if parsed is Dictionary else {}


func _cases(errors: Array[String]) -> Array[Dictionary]:
	var curve := _read("data/config/chapter_curve.json")
	var biomes: Dictionary = curve.get("biomes", {})
	var out: Array[Dictionary] = []
	if biomes.is_empty():
		errors.append("F19 new-order biome targets are absent")
		return out
	for biome: String in ["meadows", "tidewake", "cloudreach", "stormwood"]:
		if not biomes.has(biome): errors.append("missing required chapter " + biome)
	var meadows_ids: Array[String] = []
	for region: Dictionary in curve.get("regions", []):
		var id := str(region.id)
		meadows_ids.append(id)
		var spawns := _read("data/config/bands/%s/spawns.json" % id)
		var species: Array[String] = []
		for row: Dictionary in spawns.get("spawns", []):
			var sid := str(row.get("species", ""))
			if not sid.is_empty() and not species.has(sid): species.append(sid)
		out.append({"id": id, "chapter": "meadows", "level": int(region.team.enter),
			"foe_level": int(region.wild_band[1]), "species": species,
			"after_south_bridge": not id in ["band1_lower_meadows", "band2_stone_and_root"]})
	for band: String in ["band1_lower_meadows", "band2_stone_and_root", "band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"]:
		if not meadows_ids.has(band): errors.append("missing required Meadows band " + band)
	var sources := {
		"tidewake": ["water", "data/config/water_encounters.json", "tables"],
		"cloudreach": ["cloudreach", "data/config/cloudreach_chapter.json", "encounter_tables"],
		"stormwood": ["stormwood", "data/config/stormwood_encounters.json", "tables"]}
	for biome: String in sources:
		var source: Array = sources[biome]
		var catalog := _read(str(source[1]))
		var seen: Array[String] = []
		for region: Dictionary in (biomes.get(biome, {}) as Dictionary).get("regional_targets", []):
			if seen.has(str(region.region_id)): errors.append("duplicate band " + biome + "/" + str(region.region_id))
			seen.append(str(region.region_id))
			var species: Array[String] = []
			var foe_level := 0
			for table: Dictionary in catalog.get(str(source[2]), []):
				if not (region.get("tables", []) as Array).has(str(table.id)): continue
				foe_level = maxi(foe_level, int(table.level_range[1]))
				for member: Dictionary in table.get("entries", table.get("roles", [])):
					var sid := str(member.get("species_id", member.get("placeholder_species", "")))
					if not sid.is_empty() and not species.has(sid): species.append(sid)
			out.append({"id": biome + "/" + str(region.region_id), "chapter": str(source[0]),
				"level": int(region.team[0]), "foe_level": foe_level, "species": species})
		for id: String in EXPECTED_REGIONS[biome]:
			if not seen.has(id): errors.append("missing required band " + biome + "/" + id)
	for entry: Dictionary in out:
		if entry.species.is_empty() or int(entry.foe_level) < 1:
			errors.append("band has no actual catalogue: " + str(entry.id))
	return out


## band id -> Array of ordinary trainer teams (each an Array of creature_for
## entries), from each chapter's own trainer data.
func _trainer_rosters(patterns: Dictionary) -> Dictionary:
	var named := {}
	for id: String in patterns.get("named", {}):
		named[str(patterns.named[id].get("encounter_id", ""))] = true
	var out := {}
	var add := func(band: String, id: String, rank: String, team: Array) -> void:
		if team.is_empty(): return
		if _named.is_empty() and (named.has(id) or BOSS_RANKS.has(rank)): return
		if not _named.is_empty() and not _named.has(id): return
		if not out.has(band): out[band] = []
		(out[band] as Array).append({"id": id, "team": team})
	for dir: String in DirAccess.get_directories_at("res://data/config/bands"):
		for row: Dictionary in _read("data/config/bands/%s/trainers.json" % dir).get("trainers", []):
			add.call(dir, str(row.id), str(row.get("rank", "")), row.get("team", []))
	var island_band := {}
	for region: Dictionary in (_read("data/config/chapter_curve.json").get("biomes", {}) as Dictionary).get("tidewake", {}).get("regional_targets", []):
		for table: String in region.get("tables", []):
			island_band[table.trim_prefix("water_").trim_suffix("_land").trim_suffix("_shallows")] = "tidewake/" + str(region.region_id)
	for row: Dictionary in _read("data/config/water_characters.json").get("trainers", []):
		if island_band.has(str(row.get("island_id", ""))):
			add.call(str(island_band[row.island_id]), str(row.id), str(row.get("rank", "")), row.get("team", []))
	var cloudreach := preload("res://scripts/combat/cloudreach_encounter_director.gd")
	var cloudreach_chapter := _read("data/config/cloudreach_chapter.json")
	var cloudreach_encounters := _read("data/config/cloudreach_encounters.json")
	# Use the live placement-to-ladder mapping, retaining its per-send-out
	# behavior_sequence combat profiles instead of rebuilding bare species.
	for placement: Dictionary in cloudreach_encounters.get("trainers", []):
		var authored: Dictionary = cloudreach.find_id(cloudreach_chapter.get("trainer_ladder", []), str(placement["id"]))
		if authored.is_empty(): continue
		var spec: Dictionary = cloudreach.trainer_spec(authored, placement, cloudreach_encounters)
		add.call("cloudreach/" + str(spec.region_id), str(spec.id), str(spec.get("chapter_rank", "")), spec.get("team", []))
	for row: Dictionary in _read("data/config/stormwood_trainers.json").get("trainers", []):
		var team: Array = []
		for member: Dictionary in row.get("party", []):
			team.append({"species": member.get("placeholder_species", ""), "level": member.get("level", 1),
				"combat": member.get("combat", {})})
		add.call("stormwood/" + str(row.region_id), str(row.id), str(row.get("rank", "")), team)
	return out


func _party(level: int, starter: String) -> Array[RefCounted]:
	var party: Array[RefCounted] = []
	for id: String in [starter] + RETAINED:
		var creature: RefCounted = SPECIES.spawn(id)
		if creature == null: return []
		creature.call("set_level", level, PROGRESSION.config())
		party.append(creature)
	return party


func _run() -> void:
	var errors: Array[String] = []
	var previous_tiers := {"rootiron":"", "tidesteel":"rootiron", "skyglass":"tidesteel", "stormglass":"skyglass"}
	var gear_tiers: Array[String] = [str(_gear.tier)]
	if _compare_previous_gear:
		if _named.is_empty() or not previous_tiers.has(str(_gear.tier)):
			push_error("--compare-previous-gear requires nonempty --named and --gear-tier=rootiron|tidesteel|skyglass|stormglass")
			quit(1)
			return
		gear_tiers.append(str(previous_tiers[str(_gear.tier)]))
	var patterns: Dictionary = MATH.config().get("patterns", {})
	var proof: Dictionary = patterns.get("proof", {})
	if _seeds < maxi(12, int(proof.get("seeds_per_band", 12))):
		errors.append("F22 requires at least 12 paired seeds per band")
	if patterns.get("runtime_enabled") != true:
		errors.append("F22 runtime consumer is not enabled on integrated source")
	var cases := _cases(errors)
	if _compare_previous_gear:
		var paired_cases: Array[Dictionary] = []
		for tier: String in gear_tiers:
			for entry: Dictionary in cases:
				var paired := entry.duplicate(true)
				paired["gear_tier"] = tier
				paired_cases.append(paired)
		cases = paired_cases
	var rows: Array[Dictionary] = []
	var runs: Array[Dictionary] = []
	var rosters := _trainer_rosters(patterns) if _trainers else {}
	var gaps: Array[String] = []
	if errors.is_empty():
		for entry: Dictionary in cases:
			if not _selection.is_empty() and not str(entry.id).contains(_selection): continue
			if _trainers and (rosters.get(entry.id, []) as Array).is_empty():
				gaps.append(str(entry.id))
				continue
			var run_tier := str(entry.get("gear_tier", _gear.tier))
			var gear_label := GEAR.label(run_tier, int(_gear.upgrade))
			for starter: String in STARTERS:
				var scores := {"MASHER": [], "READER": [], "SWITCH_READER": []}
				for seed_index: int in _seeds:
					var sid := str(entry.species[seed_index % entry.species.size()])
					for policy: String in scores:
						var party := _party(int(entry.level), starter)
						var foes: Array = []
						if _trainers:
							var teams: Array = rosters[entry.id]
							var pick: Dictionary = teams[seed_index % teams.size()]
							var team: Array = pick.team
							sid = str(pick.id)
							for member: Dictionary in team:
								var built: RefCounted = TRAINERS.creature_for(member)
								if built != null: foes.append(built)
							if foes.size() != team.size(): foes.clear()
						else:
							var foe: RefCounted = SPECIES.spawn(sid)
							if foe != null:
								foe.call("set_level", int(entry.foe_level), PROGRESSION.config())
								foes.append(foe)
						if party.size() != 5 or foes.is_empty():
							errors.append("missing actual species in " + str(entry.id))
							continue
						GEAR.equip(self, party, run_tier, int(_gear.upgrade))
						var pilot := PILOT.new()
						pilot.context = {"chapter": entry.chapter, "band": entry.id,
							"floor_trainer": _trainers and _named.is_empty(),
							"after_south_bridge": bool(entry.get("after_south_bridge", true))}
						if not _named.is_empty() and (patterns.get("named", {}) as Dictionary).has("named_" + sid):
							pilot.context["pattern_id"] = "named_" + sid
						var result: Dictionary = await pilot.fight(self, party, foes, _trainers,
							hash("f22/%s/%s/%d" % [entry.id, starter, seed_index]), policy)
						result["lead_fainted"] = bool(party[0].get("fainted"))
						result["band"] = entry.id
						result["species"] = sid
						result["starter"] = starter
						if _compare_previous_gear:
							result["gear"] = gear_label
							result["seed_index"] = seed_index
						(scores[policy] as Array).append(result)
						runs.append(result)
				var masher := _score(scores.MASHER)
				var reader := _score(scores.READER)
				var switch_reader := _score(scores.SWITCH_READER)
				var reasons: Array[String] = []
				for policy: String in scores:
					var scored := _score(scores[policy])
					if int(scored.runs) != _seeds or int(scored.errors) > 0:
						reasons.append(policy + " incomplete or invalid actual fixture")
				# Trainer mode applies the coordinator's three-part F22#1 bar to
				# the COMBAT §7 reader, which switches on a real mismatch.
				var judged: Dictionary = switch_reader if _trainers else reader
				if not _named.is_empty():
					# COMBAT §7 top trainer: reader win >= .75, masher loses its lead
					# every run, reader median party cost <= .55x masher's.
					if float(judged.win_rate) < 0.75: reasons.append("top: reader win below .75")
					if float(masher.lead_faint_rate) < 1.0: reasons.append("top: masher kept its lead in some run")
					if float(judged.median_cost) > float(masher.median_cost) * 0.55: reasons.append("top: reader party cost above .55x masher")
					var row := {"band": entry.id, "starter": starter, "masher": masher,
						"reader": reader, "switch_reader": switch_reader, "pass": reasons.is_empty(), "reasons": reasons}
					if _compare_previous_gear: row["gear"] = gear_label
					rows.append(row)
					continue
				if float(judged.win_rate) < float(proof.get("reader_win_min", 0.9)):
					reasons.append("reader win rate below .9")
				if float(masher.lead_faint_rate) - float(judged.lead_faint_rate) < float(proof.get("masher_lead_faint_gap_min", 0.25)):
					reasons.append("masher lead losses insufficiently different")
				if _trainers and float(judged.median_lead_cost) > float(masher.median_lead_cost) * 0.55:
					reasons.append("reader median lead cost above .55x masher")
				rows.append({"band": entry.id, "starter": starter, "masher": masher,
					"reader": reader, "switch_reader": switch_reader, "pass": reasons.is_empty(), "reasons": reasons})
	if rows.is_empty(): errors.append("no valid band cohort completed")
	if not gaps.is_empty(): print("F22_PATTERN_BANDS data gaps (no ordinary trainer roster): " + ", ".join(gaps))
	var passed := errors.is_empty()
	for row: Dictionary in rows: passed = passed and bool(row.pass)
	var switch_values := {}
	var switch_passed := true
	for tier: String in gear_tiers:
		var gear_label := GEAR.label(tier, int(_gear.upgrade))
		var paired := {"READER": [], "SWITCH_READER": []}
		for run: Dictionary in runs:
			if _compare_previous_gear and run.gear != gear_label: continue
			if paired.has(str(run.pilot)): (paired[str(run.pilot)] as Array).append(run)
		var fixed_total := _score(paired.READER)
		var switched_total := _score(paired.SWITCH_READER)
		# F24's tag combo is one of three switching sources (COMBAT §12.3); while
		# its runtime flag is off the comparison measures the other two and says so.
		var combo_live := false
		for run: Dictionary in paired.SWITCH_READER: combo_live = combo_live or bool(run.get("tag_combo_available", false))
		var switch_value := (int(switched_total.tags) > 0 or not combo_live) \
			and int(switched_total.errors) == 0 \
			and float(switched_total.win_rate) >= float(fixed_total.win_rate) \
			and float(switched_total.median_cost) < float(fixed_total.median_cost) \
			and float(switched_total.median_cost) <= float(fixed_total.median_cost) * float(proof.get("switch_reader_hp_ratio_max", 0.9))
		switch_passed = switch_passed and switch_value
		switch_values[gear_label] = {"pass": switch_value, "tag_combo_live": combo_live,
			"status": "full" if combo_live else "partial_no_f24: type matchup and per-identity HP only; F24 tag combo off, F22#2 not fully measured",
			"fixed": fixed_total, "switched": switched_total}
	passed = passed and switch_passed
	var coverage := _selection.is_empty() and rows.size() + gaps.size() * STARTERS.size() == cases.size() * STARTERS.size()
	var receipt := {"kind": "actual flat-fixture C2; world/C3/authority proofs separate",
		"pass": passed and coverage, "coverage": coverage, "seeds_per_band": _seeds,
		"mode": "trainers" if _trainers else "wilds", "gear": GEAR.label(str(_gear.tier), int(_gear.upgrade)), "data_gaps": gaps,
		"acceptance": false, "policy_scope": "quick/charged/spatial diagnostic; full F23/F24 policy and actual admission fixture required",
		"switch_value": switch_values[GEAR.label(str(_gear.tier), int(_gear.upgrade))],
		"errors": errors, "rows": rows, "runs": runs}
	if _compare_previous_gear:
		receipt["matching_gear"] = receipt.gear
		receipt.erase("gear")
		receipt["comparison_tiers"] = []
		for tier: String in gear_tiers: receipt.comparison_tiers.append(GEAR.label(tier, int(_gear.upgrade)))
		receipt["switch_value"] = {"pass": switch_passed, "by_gear": switch_values}
	if not _json.is_empty():
		var output := FileAccess.open(_json, FileAccess.WRITE)
		if output == null: passed = false
		else: output.store_string(JSON.stringify(receipt, "\t"))
	print("F22_PATTERN_BANDS " + JSON.stringify(receipt))
	quit(0 if passed and coverage else 1)


func _score(runs: Array) -> Dictionary:
	var wins := 0
	var faints := 0
	var errors := 0
	var tags := 0
	var costs: Array[float] = []
	var lead_costs: Array[float] = []
	for row: Dictionary in runs:
		lead_costs.append(float(row.get("lead_lost_frac", 1.0)))
		wins += int(bool(row.get("won", false)))
		faints += int(bool(row.get("lead_fainted", false)))
		errors += int(row.has("fixture_error") or bool(row.get("stalled", false)))
		tags += int(row.get("tag_combos", 0))
		costs.append(float(row.get("party_lost_frac", 1.0)))
	costs.sort()
	var median := 1.0
	if not costs.is_empty():
		var middle := int(costs.size() / 2)
		median = costs[middle] if costs.size() % 2 == 1 else (costs[middle - 1] + costs[middle]) * 0.5
	var count := maxf(1.0, runs.size())
	lead_costs.sort()
	var lead_median := 1.0
	if not lead_costs.is_empty():
		var half := int(lead_costs.size() / 2)
		lead_median = lead_costs[half] if lead_costs.size() % 2 == 1 else (lead_costs[half - 1] + lead_costs[half]) * 0.5
	return {"runs": runs.size(), "win_rate": wins / count, "lead_faint_rate": faints / count,
		"median_lead_cost": lead_median,
		"median_cost": median, "tags": tags, "errors": errors}
