extends SceneTree

## STORMWOOD-B F10#2 measurement: do the six Stormwood named wilds (BOSSES §7)
## pass ACCEPTANCE C2 (seeded reader/masher comparison, all three starters)
## and the measurable half of C3 (single-hit ceiling, tell floors)?
##
##   godot --headless --path . --fixed-fps 60 --script tests/smoke_stormwood_b_named_c2c3.gd \
##       -- --seeds=24 [--case=<substring>[,...]] [--starter=<id>] [--party-level=<n>] --json=<path>
##
## Same method as tests/smoke_water_named_c2c3.gd (F14#0): the shared paired
## pilot tests/helpers/combat_depth_pilot.gd, unmodified -- real CombatManager,
## real WildCreature AI and CharacterBody3D bodies on a flat collider, READER
## and MASHER input policies. It adds no combat arithmetic of its own.
##
## FOES are built as production builds them: each named_encounters row of
## data/config/stormwood_encounters.json becomes its placeholder species at the
## authored level (the named spawn pins it), with the BOSSES §7 combat block
## the encounter director installs as `combat_override`
## (stormwood_encounter_catalogue.gd::named_combat: profile, then the row's
## own numbers, clamped to the .8/.6 s Stormwood floor), trainer_owned=false.
##
## PARTY: the retained five (starter + bramblebun, mudsnout, pipwing, trailpup,
## the F12 original-five precedent). C2 demands all three starters, so the
## lead cycles terrapup / ripplet / galewisp. COMBAT §7 measures "at
## region-entry levels"; each fight's party level is its region's Calm wild
## band midpoint + 1 (the chapter's declared entry, L33, sits one above Cinder
## Verge's 30-34 band midpoint). --party-level overrides it for every case.
##
## Verdict rules applied per case/starter (printed; nothing is tuned):
##   C2 named wild: READER median lead HP cost <= 0.55 x MASHER's, READER win >= 90%.
##   C3: no single incoming hit >= 50% of an entry creature's HP (worst seen,
##       not neutral-only: a harsher bound), every tell >= 0.8 s, and any tell
##       authored as heavy (>= 1.1 s by BOSSES) observed at >= 1.1 s.
## Not covered: terrain/arena geometry, storm strikes, manual switch/burst/Y,
## co-op scaling, framing (a rendered capture), an earned-save party.

const PILOT := preload("res://tests/helpers/combat_depth_pilot.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")

const STARTERS := ["terrapup", "ripplet", "galewisp"]
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
const RATIO_MAX := 0.55
const READER_WIN_MIN := 0.90
const HIT_CEILING := 0.50
const TELL_FLOOR := 0.8
const HEAVY_TELL := 1.1

var _seeds := 24
var _selection := ""
var _starter_only := ""
var _party_level_override := 0
var _json := ""


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): _seeds = maxi(1, int(arg.trim_prefix("--seeds=")))
		elif arg.begins_with("--case="): _selection = arg.trim_prefix("--case=")
		elif arg.begins_with("--starter="): _starter_only = arg.trim_prefix("--starter=")
		elif arg.begins_with("--party-level="): _party_level_override = int(arg.trim_prefix("--party-level="))
		elif arg.begins_with("--json="): _json = arg.trim_prefix("--json=")
	_run.call_deferred()


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Region-entry party level: Calm band midpoint + 1 (see header).
func _entry_levels(encounters: Dictionary) -> Dictionary:
	var out := {}
	for table: Dictionary in encounters.get("tables", []):
		if str(table.get("surge_phase", "")) != "calm": continue
		var band: Array = table.get("level_range", [])
		if band.size() == 2:
			out[str(table.region_id)] = floori((int(band[0]) + int(band[1])) / 2.0) + 1
	return out


func _cases(errors: Array[String]) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var encounters := _read("res://data/config/stormwood_encounters.json")
	var levels := _entry_levels(encounters)
	for named: Dictionary in encounters.get("named_encounters", []):
		var region := str(named.get("region_id", ""))
		if not levels.has(region):
			errors.append("%s: no Calm band for region %s" % [named.id, region])
			continue
		var combat := CATALOGUE.named_combat(named)
		cases.append({"id": str(named.id), "region": region, "profile": str(named.behavior_profile),
			"party_level": _party_level_override if _party_level_override > 0 else int(levels[region]),
			"authored_tell": float(combat.get("telegraph", TELL_FLOOR)),
			"foes": [{"species": str(named.placeholder_species), "level": int(named.level), "combat": combat}]})
	return cases


func _selected(id: String) -> bool:
	if _selection.is_empty(): return true
	for part in _selection.split(",", false):
		if id.contains(part): return true
	return false


func _run() -> void:
	var errors: Array[String] = []
	var cases := _cases(errors)
	var rows: Array[Dictionary] = []
	var runs: Array[Dictionary] = []
	var failures := 0
	for entry in cases:
		if not _selected(str(entry.id)): continue
		for starter: String in STARTERS:
			if not _starter_only.is_empty() and starter != _starter_only: continue
			var row := {"case": entry.id, "profile": entry.profile, "region": entry.region,
				"starter": starter, "party_level": entry.party_level, "pilots": {}}
			for policy in ["MASHER", "READER"]:
				var s := {"wins": 0, "lead_cost": [], "party_cost": [], "seconds": [],
					"lead_faints": 0, "party_wipes": 0, "max_hit": 0.0, "min_tell": INF,
					"max_tell": 0.0, "stalled": 0, "incoming_hits": 0, "hits": 0}
				for seed_index in _seeds:
					var party: Array[RefCounted] = []
					for id in [starter] + RETAINED:
						var creature: RefCounted = SPECIES.spawn(str(id))
						if creature == null:
							errors.append("party species missing: %s" % id)
							continue
						creature.set_level(int(entry.party_level), PROGRESSION.config())
						party.append(creature)
					var foes: Array = []
					for member: Dictionary in entry.foes:
						var foe: RefCounted = TRAINERS.creature_for(member)
						if foe == null:
							errors.append("%s: foe species missing: %s" % [entry.id, member.species])
							continue
						foes.append(foe)
					if party.size() != 5 or foes.size() != entry.foes.size(): break
					var pilot: RefCounted = PILOT.new()
					var result: Dictionary = await pilot.fight(self, party, foes, false,
						hash("stormwood/%s/%s/%d" % [entry.id, starter, seed_index]), policy)
					var tells: Array = []
					for event: Dictionary in result.get("events", []):
						if str(event.get("event", "")) == "telegraph": tells.append(float(event.seconds))
					result.erase("events")
					result["tells"] = tells
					result["case"] = entry.id
					result["starter"] = starter
					runs.append(result)
					s.wins += int(result.won)
					s.lead_cost.append(float(result.lead_lost_frac))
					s.party_cost.append(float(result.party_lost_frac))
					s.seconds.append(float(result.seconds))
					s.lead_faints += int(party[0].fainted)
					s.party_wipes += int(int(result.faints) == party.size())
					s.max_hit = maxf(float(s.max_hit), float(result.max_hit_frac))
					s.stalled += int(bool(result.stalled) or result.has("fixture_error"))
					s.incoming_hits += int(result.incoming_hits)
					s.hits += int(result.hits)
					for t in tells:
						s.min_tell = minf(float(s.min_tell), float(t))
						s.max_tell = maxf(float(s.max_tell), float(t))
				var summary := {"runs": s.seconds.size(), "wins": s.wins,
					"win_rate": float(s.wins) / maxf(1.0, s.seconds.size()),
					"median_lead_cost": _median(s.lead_cost), "mean_lead_cost": _mean(s.lead_cost),
					"median_party_cost": _median(s.party_cost),
					"median_seconds": _median(s.seconds), "max_seconds": _max(s.seconds),
					"lead_faint_rate": float(s.lead_faints) / maxf(1.0, s.seconds.size()),
					"party_wipe_rate": float(s.party_wipes) / maxf(1.0, s.seconds.size()),
					"max_single_hit_frac": s.max_hit,
					"min_tell_s": s.min_tell if is_finite(float(s.min_tell)) else -1.0,
					"max_tell_s": s.max_tell, "stalled": s.stalled,
					"incoming_hits": s.incoming_hits, "hits": s.hits}
				row.pilots[policy] = summary
				print("STORMWOOD_C2C3 %s %s %s L%d runs=%d win=%.2f med_lead=%.3f med_party=%.3f med_s=%.1f max_s=%.1f lead_faint=%.2f wipe=%.2f max_hit=%.3f tell=[%.2f,%.2f] incoming=%d stalled=%d" % [
					entry.id, starter, policy, int(entry.party_level), summary.runs, summary.win_rate,
					summary.median_lead_cost, summary.median_party_cost, summary.median_seconds,
					summary.max_seconds, summary.lead_faint_rate, summary.party_wipe_rate,
					summary.max_single_hit_frac, summary.min_tell_s, summary.max_tell_s,
					summary.incoming_hits, summary.stalled])
			var m: Dictionary = row.pilots.get("MASHER", {})
			var r: Dictionary = row.pilots.get("READER", {})
			if not m.is_empty() and not r.is_empty():
				row["verdict"] = _verdict(entry, m, r)
				if not bool(row.verdict.pass): failures += 1
				print("STORMWOOD_C2C3_VERDICT %s %s %s ratio=%.2f reader_win=%.2f max_hit=%.3f min_tell=%.2f %s" % [
					entry.id, starter, "PASS" if bool(row.verdict.pass) else "FAIL",
					float(row.verdict.ratio), float(r.win_rate), float(row.verdict.max_hit),
					float(row.verdict.min_tell), ", ".join(row.verdict.reasons)])
			rows.append(row)
	if rows.is_empty(): errors.append("no cases matched: %s" % _selection)
	if not _json.is_empty():
		var file := FileAccess.open(_json, FileAccess.WRITE)
		if file == null:
			errors.append("cannot write %s" % _json)
		else:
			file.store_string(JSON.stringify({"seeds": _seeds, "selection": _selection,
				"party": {"lead": STARTERS, "retained": RETAINED, "level_rule": "region Calm band midpoint + 1",
					"override": _party_level_override},
				"fixture": "production CombatManager + WildCreature bodies on a flat collider (combat_depth_pilot.gd)",
				"rules": {"ratio_max": RATIO_MAX, "reader_win_min": READER_WIN_MIN, "hit_ceiling": HIT_CEILING,
					"tell_floor": TELL_FLOOR, "heavy_tell": HEAVY_TELL},
				"rows": rows, "runs": runs, "errors": errors}, "  "))
	for e in errors: print("STORMWOOD_C2C3 ERROR: %s" % e)
	print("STORMWOOD_C2C3 done: %d rows, %d runs, %d failing rows, %d errors" % [rows.size(), runs.size(), failures, errors.size()])
	# Exit reflects the harness, not the verdict: a FAIL row is evidence.
	quit(0 if errors.is_empty() else 1)


func _verdict(entry: Dictionary, masher: Dictionary, reader: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	# A masher that loses no lead HP makes the ratio undefined; the reader then
	# cannot be cheaper, so the comparison says nothing: report it as a FAIL of
	# "decisions have value" rather than divide by zero.
	var masher_cost := float(masher.median_lead_cost)
	var ratio := float(reader.median_lead_cost) / masher_cost if masher_cost > 0.0001 else INF
	if ratio > RATIO_MAX: reasons.append("reader/masher lead cost %.2f > %.2f" % [ratio, RATIO_MAX])
	if float(reader.win_rate) < READER_WIN_MIN: reasons.append("reader win %.2f < %.2f" % [float(reader.win_rate), READER_WIN_MIN])
	var max_hit := maxf(float(masher.max_single_hit_frac), float(reader.max_single_hit_frac))
	if max_hit >= HIT_CEILING: reasons.append("single hit %.2f >= %.2f" % [max_hit, HIT_CEILING])
	var tells: Array = [float(masher.min_tell_s), float(reader.min_tell_s)].filter(func(t: float) -> bool: return t >= 0.0)
	var min_tell := -1.0 if tells.is_empty() else float(tells.min())
	if min_tell < 0.0: reasons.append("no tell observed")
	elif min_tell < TELL_FLOOR - 0.001: reasons.append("tell %.2f < %.2f" % [min_tell, TELL_FLOOR])
	if float(entry.authored_tell) >= HEAVY_TELL and min_tell >= 0.0 and min_tell < HEAVY_TELL - 0.001:
		reasons.append("heavy-authored tell seen at %.2f < %.2f" % [min_tell, HEAVY_TELL])
	if int(masher.stalled) + int(reader.stalled) > 0: reasons.append("stalled runs")
	return {"pass": reasons.is_empty(), "ratio": ratio, "max_hit": max_hit, "min_tell": min_tell, "reasons": reasons}


static func _median(values: Array) -> float:
	if values.is_empty(): return -1.0
	var sorted := values.duplicate()
	sorted.sort()
	var n := sorted.size()
	return float(sorted[n / 2]) if n % 2 == 1 else (float(sorted[n / 2 - 1]) + float(sorted[n / 2])) * 0.5


static func _mean(values: Array) -> float:
	if values.is_empty(): return -1.0
	var total := 0.0
	for v in values: total += float(v)
	return total / values.size()


static func _max(values: Array) -> float:
	var best := 0.0
	for v in values: best = maxf(best, float(v))
	return best
