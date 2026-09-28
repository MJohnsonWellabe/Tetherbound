extends SceneTree

## MEADOWS CORE F04#7 measurement: do the Meadows named fights pass ACCEPTANCE
## C2 (seeded reader/masher comparison, all three starters) and the
## measurable half of C3 (single-hit ceiling, tell floors)?
##
##   godot --headless --path . --fixed-fps 60 --script tests/smoke_meadows_named_c2c3.gd \
##       -- --seeds=24 [--case=<substring>[,...]] [--starter=<id>] [--party-level=<n>] --json=<path>
##
## Same method as tests/smoke_water_named_c2c3.gd (F14#0) and
## tests/smoke_stormwood_b_named_c2c3.gd (F10#2): the shared paired pilot
## tests/helpers/combat_depth_pilot.gd, unmodified -- real CombatManager, real
## WildCreature AI and CharacterBody3D bodies on a flat collider, READER and
## MASHER input policies. It adds no combat arithmetic of its own.
##
## FOES are built as production builds them:
## - the six named trainers (BOSSES 4.2-4.5: Vance, Oreth, Halder, Vess, Hald,
##   the Warden) from their band trainers.json rows through
##   trainer_npc.gd::creature_for(member), every member in team order,
##   trainer_owned=true;
## - the Warrens guardian (BOSSES 4.1) from burrow_warrens.json's `guardian`
##   block (species, level and its `combat` block), trainer_owned=false. Its
##   1.35 instance scale is not applied on the flat fixture (a stated limit).
##
## PARTY: the retained five, the precedent the water and Stormwood harnesses
## share (starter + bramblebun, mudsnout, pipwing, trailpup). C2 demands all
## three starters, so the lead cycles terrapup / ripplet / galewisp. COMBAT 7
## measures "at region-entry levels": each fight's party level is its band's
## chapter_curve.json `team.enter`. --party-level overrides it for every case.
##
## Verdict rules per case/starter (printed; nothing is tuned):
##   top trainer (Band 3 onward; every trainer case here):
##     READER win >= 75%, MASHER loses its lead in every run and its whole
##     team in >= 25% of runs (COMBAT 7).
##   named wild (the guardian): READER median lead HP cost <= 0.55 x MASHER's,
##     READER win >= 90%.
##   C3: no single incoming hit >= 50% of an entry creature's HP (worst seen, a
##     harsher bound than "neutral"), every tell >= 0.8 s, and a tell authored
##     as heavy (>= 1.1 s) observed at >= 1.1 s.
## Not covered: terrain/arena geometry, manual switch/burst, co-op scaling,
## framing (rendered captures), an earned-save party.

const PILOT := preload("res://tests/helpers/combat_depth_pilot.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CURVE := preload("res://scripts/creatures/chapter_curve.gd")

const STARTERS := ["terrapup", "ripplet", "galewisp"]
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
## trainer id -> band id (for the band's region-entry level)
const TRAINER_CASES := {
	"relay_captain": "band3_the_river_lock",
	"captain_riverwatch": "band3_the_river_lock",
	"captain_field": "band4_upper_meadows_ironwood",
	"captain_ridge": "band4_upper_meadows_ironwood",
	"stronghold_elite": "band5_stronghold_approach",
	"warden_aldis": "band5_stronghold_approach",
}
const GUARDIAN_BAND := "band2_stone_and_root"
const TOP_READER_WIN_MIN := 0.75
const TOP_MASHER_LEAD_FAINT_MIN := 1.0
const TOP_MASHER_WIPE_MIN := 0.25
const WILD_RATIO_MAX := 0.55
const WILD_READER_WIN_MIN := 0.90
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


func _entry_level(band: String) -> int:
	for region: Dictionary in CURVE.regions(CURVE.config()):
		if str(region.get("id", "")) == band:
			return int((region.get("team", {}) as Dictionary).get("enter", 1))
	return 1


func _cases(errors: Array[String]) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var warrens: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/burrow_warrens.json"))
	var guardian: Dictionary = (warrens as Dictionary).get("guardian", {}) if warrens is Dictionary else {}
	if guardian.is_empty():
		errors.append("burrow_warrens.json has no guardian block")
	else:
		var combat: Dictionary = guardian.get("combat", {})
		cases.append({"id": "warrens_guardian", "kind": "named_wild", "owned": false,
			"band": GUARDIAN_BAND,
			"heavy": float(combat.get("charged_telegraph", 0.0)) >= HEAVY_TELL,
			"foes": [{"species": str(guardian.species), "level": int(guardian.level), "combat": combat}]})
	for id: String in TRAINER_CASES:
		var spec: Dictionary = TRAINERS.trainer(id)
		if spec.is_empty():
			errors.append("no trainer %s" % id)
			continue
		var heavy := false
		for member: Dictionary in spec.get("team", []):
			var c: Dictionary = member.get("combat", {})
			heavy = heavy or float(c.get("charged_telegraph", c.get("telegraph", 0.0))) >= HEAVY_TELL
		cases.append({"id": id, "kind": "top", "owned": true, "band": TRAINER_CASES[id],
			"heavy": heavy, "foes": spec.get("team", [])})
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
		var party_level := _party_level_override if _party_level_override > 0 else _entry_level(str(entry.band))
		for starter: String in STARTERS:
			if not _starter_only.is_empty() and starter != _starter_only: continue
			var row := {"case": entry.id, "kind": entry.kind, "band": entry.band,
				"starter": starter, "party_level": party_level, "pilots": {}}
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
						creature.set_level(party_level, PROGRESSION.config())
						party.append(creature)
					var foes: Array = []
					for member: Dictionary in entry.foes:
						var foe: RefCounted = TRAINERS.creature_for(member)
						if foe == null:
							errors.append("%s: foe species missing: %s" % [entry.id, member.get("species", "?")])
							continue
						foes.append(foe)
					if party.size() != 5 or foes.size() != entry.foes.size(): break
					var result: Dictionary = await PILOT.new().fight(self, party, foes, bool(entry.owned),
						hash("meadows/%s/%s/%d" % [entry.id, starter, seed_index]), policy)
					var tells: Array = []
					for event: Dictionary in result.get("events", []):
						if str(event.get("event", "")) == "telegraph": tells.append(float(event.seconds))
					result.erase("events")
					result["tells"] = tells
					result["case"] = entry.id
					result["starter"] = starter
					result["policy"] = policy
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
				var n := maxf(1.0, s.seconds.size())
				var summary := {"runs": s.seconds.size(), "wins": s.wins,
					"win_rate": float(s.wins) / n,
					"median_lead_cost": _median(s.lead_cost), "median_party_cost": _median(s.party_cost),
					"median_seconds": _median(s.seconds), "max_seconds": _max(s.seconds),
					"lead_faint_rate": float(s.lead_faints) / n, "party_wipe_rate": float(s.party_wipes) / n,
					"max_single_hit_frac": s.max_hit,
					"min_tell_s": s.min_tell if is_finite(float(s.min_tell)) else -1.0,
					"max_tell_s": s.max_tell, "stalled": s.stalled,
					"incoming_hits": s.incoming_hits, "hits": s.hits}
				row.pilots[policy] = summary
				print("MEADOWS_C2C3 %s %s %s L%d runs=%d win=%.2f med_lead=%.3f lead_faint=%.2f wipe=%.2f max_hit=%.3f tell=[%.2f,%.2f] med_s=%.1f stalled=%d" % [
					entry.id, starter, policy, party_level, summary.runs, summary.win_rate,
					summary.median_lead_cost, summary.lead_faint_rate, summary.party_wipe_rate,
					summary.max_single_hit_frac, summary.min_tell_s, summary.max_tell_s,
					summary.median_seconds, summary.stalled])
			var verdict := _verdict(entry, row.pilots.get("MASHER", {}), row.pilots.get("READER", {}))
			row["verdict"] = verdict
			failures += int(not bool(verdict.pass))
			print("MEADOWS_C2C3_VERDICT %s %s %s%s" % [entry.id, starter,
				"PASS" if bool(verdict.pass) else "FAIL",
				"" if bool(verdict.pass) else " -- " + "; ".join(verdict.reasons)])
			rows.append(row)
	if rows.is_empty(): errors.append("no cases matched: %s" % _selection)
	if not _json.is_empty():
		var file := FileAccess.open(_json, FileAccess.WRITE)
		if file == null:
			errors.append("cannot write %s" % _json)
		else:
			file.store_string(JSON.stringify({"seeds": _seeds, "selection": _selection,
				"party": {"lead": STARTERS, "retained": RETAINED, "level_override": _party_level_override},
				"fixture": "production CombatManager + WildCreature bodies on a flat collider (combat_depth_pilot.gd)",
				"rows": rows, "runs": runs, "errors": errors}, "  "))
	for e in errors: print("MEADOWS_C2C3 ERROR: %s" % e)
	print("MEADOWS_C2C3 done: %d rows, %d failing rows, %d runs, %d errors" % [rows.size(), failures, runs.size(), errors.size()])
	quit(0 if errors.is_empty() and failures == 0 else 1)


func _verdict(entry: Dictionary, m: Dictionary, r: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	if m.is_empty() or r.is_empty():
		return {"pass": false, "reasons": ["missing policy summary"]}
	if str(entry.kind) == "top":
		if float(r.win_rate) < TOP_READER_WIN_MIN:
			reasons.append("reader win %.2f < %.2f" % [r.win_rate, TOP_READER_WIN_MIN])
		if float(m.lead_faint_rate) < TOP_MASHER_LEAD_FAINT_MIN:
			reasons.append("masher lead faint %.2f < %.2f" % [m.lead_faint_rate, TOP_MASHER_LEAD_FAINT_MIN])
		if float(m.party_wipe_rate) < TOP_MASHER_WIPE_MIN:
			reasons.append("masher wipe %.2f < %.2f" % [m.party_wipe_rate, TOP_MASHER_WIPE_MIN])
	else:
		if float(r.median_lead_cost) > float(m.median_lead_cost) * WILD_RATIO_MAX:
			reasons.append("reader/masher lead cost %.3f/%.3f > %.2f" % [r.median_lead_cost, m.median_lead_cost, WILD_RATIO_MAX])
		if float(r.win_rate) < WILD_READER_WIN_MIN:
			reasons.append("reader win %.2f < %.2f" % [r.win_rate, WILD_READER_WIN_MIN])
	var worst_hit := maxf(float(m.max_single_hit_frac), float(r.max_single_hit_frac))
	if worst_hit >= HIT_CEILING:
		reasons.append("C3 single hit %.3f >= %.2f" % [worst_hit, HIT_CEILING])
	for p: Dictionary in [m, r]:
		if float(p.min_tell_s) >= 0.0 and float(p.min_tell_s) < TELL_FLOOR - 0.001:
			reasons.append("C3 tell %.2f < %.2f" % [p.min_tell_s, TELL_FLOOR])
			break
	if bool(entry.heavy) and maxf(float(m.max_tell_s), float(r.max_tell_s)) < HEAVY_TELL - 0.001:
		reasons.append("C3 authored heavy never observed at >= %.1f s" % HEAVY_TELL)
	return {"pass": reasons.is_empty(), "reasons": reasons}


static func _median(values: Array) -> float:
	if values.is_empty(): return -1.0
	var sorted := values.duplicate()
	sorted.sort()
	var n := sorted.size()
	return float(sorted[n / 2]) if n % 2 == 1 else (float(sorted[n / 2 - 1]) + float(sorted[n / 2])) * 0.5


static func _max(values: Array) -> float:
	var best := 0.0
	for v in values: best = maxf(best, float(v))
	return best
