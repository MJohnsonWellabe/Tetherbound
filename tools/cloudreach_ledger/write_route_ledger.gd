extends SceneTree

## Writes the F07 Cloudreach route resource/XP ledger evidence from the same
## code the unit test asserts on (tests/test_cloudreach_route_ledger.gd).
##
##   godot --headless --path . --script tools/cloudreach_ledger/write_route_ledger.gd
##
## Output: ralph/reports/CLOUDREACH-LANE/f07-route-ledger/{phases.csv,steps.csv,
## controls.csv,ledger.txt}. Pure data; no scene is loaded.

const LEDGER := preload("res://tests/test_cloudreach_route_ledger.gd")
const OUT := "res://ralph/reports/CLOUDREACH-LANE/f07-route-ledger"

const VARIANTS := [
	{"label": "baseline", "options": {}},
	{"label": "pre-fix gate-blind model (comparison)", "options": {"ignore_gates": true}},
	{"label": "control: no wild XP in Voss phase", "options": {"drop_wild_phase": 2}},
	{"label": "control: no Voss trainer XP + no Veyra-phase wild XP", "options": {"drop_trainer_xp": "officer_voss_summit_approach", "drop_wild_phase": 3}},
	{"label": "control: no verge candy", "options": {"drop_candy": true}},
	{"label": "control: wild fraction 0.25", "options": {"wild_fraction": 0.25}},
	{"label": "sensitivity: wild fraction 0.40", "options": {"wild_fraction": 0.4}},
]


func _init() -> void:
	var ledger: RefCounted = LEDGER.new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var base: Dictionary = ledger.call("ledger")
	var text := PackedStringArray()
	for variant: Dictionary in VARIANTS:
		text.append("### " + str(variant["label"]))
		for line: String in ledger.call("report_lines", ledger.call("ledger", variant["options"])):
			text.append(line)
	_write("ledger.txt", "\n".join(text))
	# Per-phase table (baseline).
	var phases := PackedStringArray(["phase,trainer,path_m,wild_sites_available,wild_defeats_credited,wild_xp_to_lead,candy_levels,ace,need_lead,need_all,levels_before,lead_margin,weakest_margin,trainer_xp_to_lead,levels_after,coins,reward_items,verge_recovery_items,supply_checks"])
	var rows: Array = (base["phases"] as Array).duplicate()
	rows.append(base["tail"])
	for i in rows.size():
		var row: Dictionary = rows[i]
		var costs := PackedStringArray()
		for cost: Dictionary in (row.get("costs", []) as Array):
			costs.append("%s needs %d %s / reached %d" % [cost["interaction"], cost["count"], cost["item_id"], cost["supply"]])
		phases.append(",".join(PackedStringArray([str(i), str(row.get("trainer", "exit")),
			"%.0f" % float(row["path_m"]), str(row["available"]), str(row["fought"]), str(row["wild_xp"]),
			str(row["candy"]), str(row.get("ace", "")), str(row.get("need_lead", "")), str(row.get("need_all", "")),
			_q(row["before"]), str(row.get("lead_margin", "")), str(row.get("all_margin", "")),
			str(row["trainer_xp"]), _q(row["after"]), str(row["coins"]), _q(row.get("reward_items", {})),
			_q(row.get("recovery", {})), _q("; ".join(costs))])))
	_write("phases.csv", "\n".join(phases))
	# Per-step table (baseline): what each ordered walk passed, open vs gated.
	var steps := PackedStringArray(["step,phase,label,path_m,sites_credited,sites_passed_while_gate_closed,candy_levels,recovery_items,harvest_nodes"])
	for row: Dictionary in (base["steps"] as Array):
		steps.append(",".join(PackedStringArray([str(row["step"]), str(row["phase"]), _q(row["label"]),
			"%.0f" % float(row["path_m"]), _q(" ".join(PackedStringArray(row["sites_open"]))),
			_q(" ".join(PackedStringArray(row["sites_closed"]))), str(row["candy"]), _q(row["recovery"]),
			_q(" ".join(PackedStringArray(row["nodes"])))])))
	_write("steps.csv", "\n".join(steps))
	# Controls and comparisons.
	var controls := PackedStringArray(["variant,options,entry,levels_before_each_fight,exit,shortfalls"])
	for variant: Dictionary in VARIANTS:
		var result: Dictionary = ledger.call("ledger", variant["options"])
		var befores := PackedStringArray()
		for row: Dictionary in (result["phases"] as Array):
			befores.append("%s:%s" % [row["name"], " ".join(PackedStringArray(row["before"]))])
		controls.append(",".join(PackedStringArray([_q(variant["label"]), _q(variant["options"]),
			_q(result["entry"]), _q(" | ".join(befores)), _q(result["exit"]),
			_q(" | ".join(PackedStringArray(ledger.call("shortfalls", result))))])))
	_write("controls.csv", "\n".join(controls))
	print("F07 ROUTE LEDGER written to %s; baseline shortfalls %s" % [OUT, str(ledger.call("shortfalls", base))])
	quit(0)


func _q(value: Variant) -> String:
	return "\"" + str(value).replace("\"", "'") + "\""


func _write(name: String, body: String) -> void:
	var file := FileAccess.open(OUT + "/" + name, FileAccess.WRITE)
	file.store_string(body + "\n")
	file.close()
