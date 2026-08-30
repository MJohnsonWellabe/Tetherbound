extends SceneTree

## T3-ACTIVITIES. Non-mirror combat-lab evidence for the captain_field/
## captain_ridge second-type rebalance: for each of the three types, what
## average incoming multiplier does a MONO-TYPE challenger's quick attack
## face against each captain's real (post-rebalance) team, and what does the
## captain's own attacking type average back against a mono-type party?
## Deliberately not a mirror matchup (smoke_combat.gd's own director draws
## ground-vs-ground, a weaker check for exactly this reason) -- every row
## below pits a challenger type against a roster of a DIFFERENT type.
##
##   godot --headless --path . --script tools/_probe_captain_typechart.gd

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")

const CAPTAINS := ["captain_field", "captain_ridge", "captain_riverwatch"]
const CHALLENGER_TYPES := ["water", "ground", "air"]


func _team_types(id: String) -> Array[String]:
	var out: Array[String] = []
	for member: Variant in TRAINERS.trainer(id).get("team", []):
		var species_id := str((member as Dictionary).get("species", ""))
		out.append(str(SPECIES.definition(species_id).get("type", "neutral")))
	return out


func _init() -> void:
	for id: String in CAPTAINS:
		var types := _team_types(id)
		print("--- %s: %s ---" % [id, ", ".join(types)])
		for challenger: String in CHALLENGER_TYPES:
			var in_mults: Array[float] = []
			var out_mults: Array[float] = []
			for defender: String in types:
				in_mults.append(TYPE_CHART.multiplier(challenger, defender))
				out_mults.append(TYPE_CHART.multiplier(defender, challenger))
			var avg_in := 0.0
			var avg_out := 0.0
			for m in in_mults:
				avg_in += m
			for m in out_mults:
				avg_out += m
			avg_in /= float(in_mults.size())
			avg_out /= float(out_mults.size())
			var sweep := in_mults.count(1.25) == in_mults.size()
			var swept := out_mults.count(1.25) == out_mults.size()
			print("  %-6s challenger: dealt avg x%.3f, taken avg x%.3f  [in=%s out=%s]%s%s" % [
				challenger, avg_in, avg_out, str(in_mults), str(out_mults),
				"  MONO-TYPE FREE SWEEP (dealt)" if sweep else "",
				"  MONO-TYPE FREE SWEEP (taken)" if swept else ""])
	quit(0)
