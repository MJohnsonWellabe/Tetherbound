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
	{"label": "sensitivity: engagement 0.30", "options": {"wild_fraction": 0.3}},
	{"label": "sensitivity: engagement 0.40", "options": {"wild_fraction": 0.4}},
	{"label": "sensitivity: engagement 0.50 (baseline)", "options": {"wild_fraction": 0.5}},
	{"label": "sensitivity: engagement 0.60", "options": {"wild_fraction": 0.6}},
	{"label": "sensitivity: bench member lands 1 Veyra-phase kill", "options": {"bench_kills": {3: 1}}},
	{"label": "sensitivity: bench member lands 2 Veyra-phase kills", "options": {"bench_kills": {3: 2}}},
	{"label": "sensitivity: ON_ROUTE_M 8", "options": {"on_route_m": 8.0}},
	{"label": "sensitivity: ON_ROUTE_M 12 (baseline)", "options": {"on_route_m": 12.0}},
	{"label": "sensitivity: ON_ROUTE_M 20", "options": {"on_route_m": 20.0}},
	{"label": "sensitivity: Veyra rare_candy fed before overlook (exit only)", "options": {"feed_finale_reward": true}},
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
	var phases := PackedStringArray(["phase,trainer,path_m,wild_sites_available,wild_defeats_credited,wild_xp_to_lead,candy_levels,ace,need_lead,need_all,levels_before,banked_xp_before,lead_margin,weakest_margin,trainer_xp_to_lead,reward_xp_bonus_each,levels_after,coins,reward_items,verge_recovery_items,supply_checks"])
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
			_q(row["before"]), _q(_banked(ledger, row["before"], row["before_xp"])), str(row.get("lead_margin", "")), str(row.get("all_margin", "")),
			str(row["trainer_xp"]), str(row.get("bonus_xp", 0)), _q(row["after"]), str(row["coins"]), _q(row.get("reward_items", {})),
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
	var controls := PackedStringArray(["variant,options,verdict,worst_lead_margin,worst_weakest_margin,veyra_margin_lead/weakest,exit_margin_lead/weakest,levels_before_each_fight(banked xp lead/weakest),exit,exit_banked,lead_xp_wild_share,shortfalls"])
	for variant: Dictionary in VARIANTS:
		var result: Dictionary = ledger.call("ledger", variant["options"])
		var befores := PackedStringArray()
		var wild := 0
		var trainer := 0
		var veyra := ""
		for row: Dictionary in (result["phases"] as Array):
			befores.append("%s:%s (%s)" % [row["name"], " ".join(PackedStringArray(row["before"])),
				_banked(ledger, row["before"], row["before_xp"])])
			wild += int(row["wild_xp"])
			trainer += int(row["trainer_xp"]) + int(row.get("bonus_xp", 0))
			if bool(row.get("finale", false)):
				veyra = "%+d/%+d" % [int(row["lead_margin"]), int(row["all_margin"])]
		wild += int((result["tail"] as Dictionary)["wild_xp"])
		var m: Dictionary = ledger.call("margins", result)
		var fails: Array = ledger.call("shortfalls", result)
		controls.append(",".join(PackedStringArray([_q(variant["label"]), _q(variant["options"]),
			"FAIL" if fails.size() > 0 else "PASS",
			"%+d (%s)" % [int(m["lead"]), m["lead_at"]], "%+d (%s)" % [int(m["weakest"]), m["weakest_at"]],
			veyra, "%+d/%+d" % [int((result["exit"] as Array)[0]) - LEDGER.CLOUDREACH_EXIT_TARGET,
				_min(result["exit"]) - LEDGER.CLOUDREACH_EXIT_TARGET + LEDGER.RETAINED_SPREAD],
			_q(" | ".join(befores)), _q(result["exit"]), _q(_banked(ledger, result["exit"], result["exit_xp"])),
			"%.1f%%" % (100.0 * float(wild) / maxf(1.0, float(wild + trainer))),
			_q(" | ".join(PackedStringArray(fails)))])))
	_write("controls.csv", "\n".join(controls))
	print("F07 ROUTE LEDGER written to %s; baseline shortfalls %s" % [OUT, str(ledger.call("shortfalls", base))])
	quit(0)


## Banked XP of the lead and of the weakest member, "lead xp/cost ; weakest xp/cost".
func _banked(ledger: RefCounted, levels: Array, xps: Array) -> String:
	var weakest := 0
	for i in levels.size():
		if int(levels[i]) < int(levels[weakest]) or (int(levels[i]) == int(levels[weakest]) and int(xps[i]) < int(xps[weakest])):
			weakest = i
	return "lead %s ; weakest %s" % [ledger.call("banked", int(levels[0]), int(xps[0])),
		ledger.call("banked", int(levels[weakest]), int(xps[weakest]))]


func _min(levels: Array) -> int:
	var low := 1 << 30
	for value: Variant in levels:
		low = mini(low, int(value))
	return low


func _q(value: Variant) -> String:
	return "\"" + str(value).replace("\"", "'") + "\""


func _write(name: String, body: String) -> void:
	var file := FileAccess.open(OUT + "/" + name, FileAccess.WRITE)
	file.store_string(body + "\n")
	file.close()
