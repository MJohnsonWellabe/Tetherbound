extends SceneTree

## F22#1/#2 bounded C2 queue. Runs actual production bodies and manager;
## does not simulate damage or enable an absent consumer. Requires F19's
## new-order band targets and ROOT-integrated F22/F24 flags/callers.
## --seeds=12 --band=<substring> --json=<absolute output>
## A selected subset reports coverage=false and cannot certify all bands.
const PILOT := preload("res://tests/helpers/f22_pattern_pilot.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const STARTERS := ["terrapup", "ripplet", "galewisp"]
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
const EXPECTED_REGIONS := {
	"tidewake": ["first_shores", "marsh_channels", "tidal_cradle", "outer_reaches", "tether_current", "veilfall"],
	"cloudreach": ["gate_lower_cliffs", "broken_causeways", "windscar_ravine", "high_roost_sky_shrine", "upper_cloudreach", "summit_final_stronghold"],
	"stormwood": ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]}
var _seeds := 12
var _selection := ""
var _json := ""


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): _seeds = int(arg.trim_prefix("--seeds="))
		elif arg.begins_with("--band="): _selection = arg.trim_prefix("--band=")
		elif arg.begins_with("--json="): _json = arg.trim_prefix("--json=")
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
	var patterns: Dictionary = MATH.config().get("patterns", {})
	var proof: Dictionary = patterns.get("proof", {})
	if _seeds < maxi(12, int(proof.get("seeds_per_band", 12))):
		errors.append("F22 requires at least 12 paired seeds per band")
	if patterns.get("runtime_enabled") != true:
		errors.append("F22 runtime consumer is not enabled on integrated source")
	var cases := _cases(errors)
	var rows: Array[Dictionary] = []
	var runs: Array[Dictionary] = []
	if errors.is_empty():
		for entry: Dictionary in cases:
			if not _selection.is_empty() and not str(entry.id).contains(_selection): continue
			for starter: String in STARTERS:
				var scores := {"MASHER": [], "READER": [], "SWITCH_READER": []}
				for seed_index: int in _seeds:
					var sid := str(entry.species[seed_index % entry.species.size()])
					for policy: String in scores:
						var party := _party(int(entry.level), starter)
						var foe: RefCounted = SPECIES.spawn(sid)
						if party.size() != 5 or foe == null:
							errors.append("missing actual species in " + str(entry.id))
							continue
						foe.call("set_level", int(entry.foe_level), PROGRESSION.config())
						var pilot := PILOT.new()
						pilot.context = {"chapter": entry.chapter, "band": entry.id,
							"after_south_bridge": bool(entry.get("after_south_bridge", true))}
						var result: Dictionary = await pilot.fight(self, party, [foe], false,
							hash("f22/%s/%s/%d" % [entry.id, starter, seed_index]), policy)
						result["lead_fainted"] = bool(party[0].get("fainted"))
						result["band"] = entry.id
						result["species"] = sid
						result["starter"] = starter
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
				if float(reader.win_rate) < float(proof.get("reader_win_min", 0.9)):
					reasons.append("reader win rate below .9")
				if float(masher.lead_faint_rate) - float(reader.lead_faint_rate) < float(proof.get("masher_lead_faint_gap_min", 0.25)):
					reasons.append("masher lead losses insufficiently different")
				rows.append({"band": entry.id, "starter": starter, "masher": masher,
					"reader": reader, "switch_reader": switch_reader, "pass": reasons.is_empty(), "reasons": reasons})
	if rows.is_empty(): errors.append("no valid band cohort completed")
	var passed := errors.is_empty()
	for row: Dictionary in rows: passed = passed and bool(row.pass)
	var paired := {"READER": [], "SWITCH_READER": []}
	for run: Dictionary in runs:
		if paired.has(str(run.pilot)): (paired[str(run.pilot)] as Array).append(run)
	var fixed_total := _score(paired.READER)
	var switched_total := _score(paired.SWITCH_READER)
	var switch_value := int(switched_total.tags) > 0 \
		and int(switched_total.errors) == 0 \
		and float(switched_total.win_rate) >= float(fixed_total.win_rate) \
		and float(switched_total.median_cost) < float(fixed_total.median_cost) \
		and float(switched_total.median_cost) <= float(fixed_total.median_cost) * float(proof.get("switch_reader_hp_ratio_max", 0.9))
	passed = passed and switch_value
	var coverage := _selection.is_empty() and rows.size() == cases.size() * STARTERS.size()
	var receipt := {"kind": "actual flat-fixture C2; world/C3/authority proofs separate",
		"pass": passed and coverage, "coverage": coverage, "seeds_per_band": _seeds,
		"acceptance": false, "policy_scope": "quick/charged/spatial diagnostic; full F23/F24 policy and actual admission fixture required",
		"switch_value": {"pass": switch_value, "fixed": fixed_total, "switched": switched_total},
		"errors": errors, "rows": rows, "runs": runs}
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
	for row: Dictionary in runs:
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
	return {"runs": runs.size(), "win_rate": wins / count, "lead_faint_rate": faints / count,
		"median_cost": median, "tags": tags, "errors": errors}
