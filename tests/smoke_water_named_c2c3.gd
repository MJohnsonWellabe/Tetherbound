extends SceneTree

## TIDEWAKE F14#0 measurement: do the named Tidewake encounters pass
## ACCEPTANCE C2 (seeded reader/masher comparison, all three starters) and the
## measurable half of C3 (single-hit ceiling, tell floors)?
##
##   godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd \
##       -- --seeds=24 [--case=<substring>[,<substring>...]] [--starter=<id>] [--party-level=43] --json=<path>
##
## Water-lane file. It reuses the shared paired pilot
## (tests/helpers/combat_depth_pilot.gd, unmodified): real CombatManager, real
## WildCreature AI and CharacterBody3D bodies on a flat collider, READER and
## MASHER input policies. It adds no combat arithmetic of its own.
##
## FOES are built exactly as production builds them today:
## - the five data-named wilds (water_encounters.json::named_encounters) spawn
##   through WaterEncounterDirector.named_spawn_plan with NO combat override,
##   trainer_owned=false: species defaults at the authored level;
## - Water trainers (water_characters.json::trainers) are translated by
##   water_encounter_runtime_data.gd: species + level, trainer_owned=true, no
##   per-creature override (the `combat_profile` label is not consumed);
## - Aquaryn (water_alpha.json) gets its three phase overrides applied by HP
##   threshold exactly as water_alpha_body.gd builds them. Its surface-channel
##   runs are NOT reproduced on the flat fixture (a stated limitation).
##
## PARTY (the "ordinary route" fixture): the retained five from the F12
## original-five precedent -- starter + bramblebun, mudsnout, pipwing,
## trailpup -- all at the Tidewake region-entry level (PROGRESSION §3 "L43
## overlap"; COMBAT §7 measures "at region-entry levels"). C2 demands all three
## starters, so the lead slot cycles terrapup / ripplet / galewisp.
##
## Never tunes anything. Prints one WATER_C2C3 row per case/starter/policy and
## writes the full evidence (every run) to --json.

const PILOT := preload("res://tests/helpers/combat_depth_pilot.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const WATER_DATA := preload("res://scripts/world/water_encounter_runtime_data.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const STARTERS := ["terrapup", "ripplet", "galewisp"]
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
## Trainers outside Veilfall that the task names, plus the chapter floor and
## the strongest non-Veilfall trainer (the matrix's own floor/top rule).
const TRAINER_CASES := {
	"water_trainer_pell_trial": "floor",
	"water_trainer_tovin": "named_trainer",
	"water_trainer_solm": "named_trainer",
	"water_trainer_irva": "named_trainer",
	"water_trainer_bex": "named_trainer",
	"water_trainer_calder": "top_critical",
	"water_trainer_tess": "top",
}


## Aquaryn's HP-phase overrides, as water_alpha_body.gd::_tick_combat builds them.
class AlphaPilot:
	extends "res://tests/helpers/combat_depth_pilot.gd"
	var phases: Array = []
	var preferred_fraction := 0.7
	var phase_log: Array = []
	var _phase_index := -1

	func _act(policy: String) -> void:
		if _wild != null and is_instance_valid(_wild) and _wild.instance != null:
			var fraction := float(_wild.instance.hp) / maxf(1.0, float(_wild.instance.max_hp))
			var index := maxi(_phase_index, 0)
			for i in phases.size():
				if fraction <= float(phases[i].enter_below_hp_fraction):
					index = maxi(index, i)
			if index != _phase_index:
				_phase_index = index
				var phase: Dictionary = phases[index]
				_wild.combat_override = {
					"telegraph": float(phase.telegraph_s),
					"recovery": float(phase.recovery_s),
					"attack_cooldown": float(phase.cooldown_s),
					"range": float(phase.reach_m),
					"preferred_range": float(phase.reach_m) * preferred_fraction,
					"cone_degrees": float(phase.cone_degrees),
					"power": float(MATH.config().get("enemy", {}).get("power", 8.0)) * float(phase.power_multiplier),
				}
				_wild.refresh_combat_profile()
				phase_log.append({"frame": _frames, "phase": str(phase.id)})
		super(policy)


var _seeds := 24
var _selection := ""
var _starter_only := ""
var _party_level := 43
var _json := ""


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): _seeds = maxi(1, int(arg.trim_prefix("--seeds=")))
		elif arg.begins_with("--case="): _selection = arg.trim_prefix("--case=")
		elif arg.begins_with("--starter="): _starter_only = arg.trim_prefix("--starter=")
		elif arg.begins_with("--party-level="): _party_level = int(arg.trim_prefix("--party-level="))
		elif arg.begins_with("--json="): _json = arg.trim_prefix("--json=")
	_run.call_deferred()


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _cases(errors: Array[String]) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var encounters := _read("res://data/config/water_encounters.json")
	for named: Dictionary in encounters.get("named_encounters", []):
		cases.append({"id": str(named.id), "kind": "named_wild", "owned": false,
			"foes": [{"species": WATER_DATA._species(str(named.species_id), errors),
				"level": int(named.level)}]})
	var alpha := _read("res://data/config/water_alpha.json")
	cases.append({"id": "water_aquaryn_alpha", "kind": "alpha", "owned": false,
		"phases": alpha.get("phases", []),
		"preferred_fraction": float(alpha.get("movement", {}).get("preferred_reach_fraction", 0.7)),
		"foes": [{"species": str(alpha.species_id), "level": int(alpha.level)}]})
	var characters := _read("res://data/config/water_characters.json")
	for trainer: Dictionary in characters.get("trainers", []):
		var id := str(trainer.id)
		if not TRAINER_CASES.has(id): continue
		var foes: Array = []
		for member: Dictionary in trainer.get("team", []):
			var entry := member.duplicate(true)
			entry["species"] = WATER_DATA._species(str(member.get("species", "")), errors)
			foes.append(entry)
		cases.append({"id": id, "kind": TRAINER_CASES[id], "owned": true, "foes": foes})
	return cases


## `--case=` takes comma-separated substrings; empty selects every case.
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
	for entry in cases:
		if not _selected(str(entry.id)): continue
		for starter: String in STARTERS:
			if not _starter_only.is_empty() and starter != _starter_only: continue
			var row := {"case": entry.id, "kind": entry.kind, "starter": starter,
				"party_level": _party_level, "pilots": {}}
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
						creature.set_level(_party_level, PROGRESSION.config())
						party.append(creature)
					var foes: Array = []
					for member: Dictionary in entry.foes:
						var foe: RefCounted = TRAINERS.creature_for(member)
						if foe == null:
							errors.append("%s: foe species missing: %s" % [entry.id, member.species])
							continue
						foes.append(foe)
					if party.size() != 5 or foes.size() != entry.foes.size(): break
					var pilot: RefCounted
					if entry.kind == "alpha":
						pilot = AlphaPilot.new()
						pilot.phases = entry.phases
						pilot.preferred_fraction = entry.preferred_fraction
					else:
						pilot = PILOT.new()
					var result: Dictionary = await pilot.fight(self, party, foes, bool(entry.owned),
						hash("%s/%s/%d" % [entry.id, starter, seed_index]), policy)
					var tells: Array = []
					for event: Dictionary in result.get("events", []):
						if str(event.get("event", "")) == "telegraph": tells.append(float(event.seconds))
					result.erase("events")
					result["tells"] = tells
					result["case"] = entry.id
					result["starter"] = starter
					if entry.kind == "alpha": result["phases"] = pilot.phase_log
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
				print("WATER_C2C3 %s %s %s runs=%d win=%.2f med_lead=%.3f med_party=%.3f med_s=%.1f max_s=%.1f lead_faint=%.2f wipe=%.2f max_hit=%.3f tell=[%.2f,%.2f] stalled=%d" % [
					entry.id, starter, policy, summary.runs, summary.win_rate,
					summary.median_lead_cost, summary.median_party_cost, summary.median_seconds,
					summary.max_seconds, summary.lead_faint_rate, summary.party_wipe_rate,
					summary.max_single_hit_frac, summary.min_tell_s, summary.max_tell_s, summary.stalled])
			var m: Dictionary = row.pilots.get("MASHER", {})
			var r: Dictionary = row.pilots.get("READER", {})
			if not m.is_empty() and not r.is_empty():
				row["reader_to_masher_lead_cost"] = float(r.median_lead_cost) / maxf(0.0001, float(m.median_lead_cost))
				print("WATER_C2C3_PAIR %s %s reader/masher median lead cost = %.3f / %.3f (ratio %.2f)" % [
					entry.id, starter, r.median_lead_cost, m.median_lead_cost, row.reader_to_masher_lead_cost])
			rows.append(row)
	if rows.is_empty(): errors.append("no cases matched: %s" % _selection)
	if not _json.is_empty():
		var file := FileAccess.open(_json, FileAccess.WRITE)
		if file == null:
			errors.append("cannot write %s" % _json)
		else:
			file.store_string(JSON.stringify({"seeds": _seeds, "selection": _selection,
				"party": {"lead": STARTERS, "retained": RETAINED, "level": _party_level},
				"fixture": "production CombatManager + WildCreature bodies on a flat collider (combat_depth_pilot.gd)",
				"rows": rows, "runs": runs, "errors": errors, "accepted": false}, "  "))
	for e in errors: print("WATER_C2C3 ERROR: %s" % e)
	print("WATER_C2C3 done: %d rows, %d runs, %d errors" % [rows.size(), runs.size(), errors.size()])
	quit(0 if errors.is_empty() else 1)


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
