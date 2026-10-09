extends SceneTree

## F22#0 engine witness: live production wild bodies, the actual combat
## manager and the F22 pattern consumer, piloted by the shared F22 pilot on
## the flat C2 fixture. It observes, per role, what the opponent ACTUALLY did:
##   - at least two distinct authored pattern ids telegraphed, every tell with
##     a declared shape and at or above its chapter floor;
##   - recoveries followed by a REPOSITION that moved the body (no stand and
##     trade);
##   - dodges caused by an observed player charged wind-up (pattern_reacted);
##   - punish tells caused by an observed player recovery (pattern_reacted).
## Nothing here decides combat. The pilot only supplies input.
##   godot --headless --path . --fixed-fps 60 --script tests/smoke_f22_wild_reactions.gd -- [--json=<path>]
const PILOT := preload("res://tests/helpers/f22_pattern_pilot.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const RETAINED := ["bramblebun", "mudsnout", "pipwing", "trailpup"]
## role -> [foe species, chapter, trainer_owned]. Water chapter: every role
## has its full post-opening pattern set there (the first Meadows band
## deliberately teaches one pattern).
const CASES := {
	"WALL": ["mosshell", "water", false],
	"CHARGER": ["tuskroot", "water", false],
	"DIVER": ["brooktail", "water", false],
	"CURRENT": ["reedwing", "water", false],
	"ACE": ["meadowhart", "water", true],
}
const SEEDS := 3
const LEVEL := 24
const REPOSITION_MIN_M := 0.75


class Witness:
	extends "res://tests/helpers/f22_pattern_pilot.gd"
	var witnessed: Dictionary = {"tells": {}, "shapes": {}, "recoveries": 0, "repositions_moved": 0,
		"dodges": 0, "punishes": 0, "min_tell_s": INF, "floor_breaches": [], "reader_opening_inputs": []}
	var _last_intent := -1
	var _reposition_from := Vector3.INF
	var _hooked := 0

	func _act(policy: String) -> void:
		var reader_opening := false
		if is_instance_valid(_wild):
			if _hooked != _wild.get_instance_id():
				_hooked = _wild.get_instance_id()
				witnessed["reader_opening_frame"] = -1
				_wild.connect("pattern_reacted", func(kind: String) -> void:
					witnessed[kind + "es" if kind == "punish" else kind + "s"] += 1)
				_wild.connect("telegraph_started", _on_tell)
			var intent := int(_wild.intent())
			reader_opening = policy != "MASHER" and (_manager.enemy_is_staggered() or intent == AI.Intent.RECOVER)
			if not reader_opening:
				witnessed["reader_opening_frame"] = -1
			elif int(witnessed.get("reader_opening_frame", -1)) < 0:
				witnessed["reader_opening_frame"] = _frames
			if intent != _last_intent:
				if _last_intent == AI.Intent.RECOVER and intent == AI.Intent.REPOSITION:
					witnessed.recoveries += 1
					_reposition_from = _wild.global_position
				elif _last_intent == AI.Intent.RECOVER:
					witnessed.recoveries += 1
				if _last_intent == AI.Intent.REPOSITION and _reposition_from != Vector3.INF:
					var moved := _wild.global_position - _reposition_from
					moved.y = 0.0
					if moved.length() >= REPOSITION_MIN_M: witnessed.repositions_moved += 1
					_reposition_from = Vector3.INF
				_last_intent = intent
		super._act(policy)
		if reader_opening:
			# The fixture released the previous tap before this tick: these are fresh inputs.
			for action: String in ["combat_quick", "combat_charged"]:
				if Input.is_action_pressed(action):
					(witnessed.reader_opening_inputs as Array).append({"seed": _tally.seed,
						"frame": _frames, "observed_frame": int(witnessed.reader_opening_frame), "action": action,
						"delay_s": float(_frames - int(witnessed.reader_opening_frame)) / Engine.physics_ticks_per_second})

	func _on_tell(seconds: float) -> void:
		var cfg: Dictionary = _wild.combat_config()
		var id := str(cfg.get("pattern_attack_id", ""))
		witnessed.tells[id] = int(witnessed.tells.get(id, 0)) + 1
		witnessed.shapes[id] = str(cfg.get("telegraph_shape", ""))
		witnessed.min_tell_s = minf(float(witnessed.min_tell_s), seconds)
		var floor_s := float(MATH.config().get("patterns", {}).get("chapter_floors", {}).get("water", {}).get("telegraph", 0.8))
		if bool(cfg.get("heavy", false)): floor_s = maxf(floor_s, float(MATH.config().get("patterns", {}).get("heavy_tell_floor_s", 1.1)))
		if seconds + 0.0001 < floor_s: (witnessed.floor_breaches as Array).append({"id": id, "seconds": seconds, "floor": floor_s})


var _json := ""


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="): _json = arg.trim_prefix("--json=")
	_run.call_deferred()


func _run() -> void:
	var errors: Array[String] = []
	var patterns: Dictionary = MATH.config().get("patterns", {})
	if patterns.get("runtime_enabled") != true: errors.append("F22 pattern runtime disabled")
	var observed := float(patterns.get("reactions", {}).get("observation_s", 0.25))
	var rows := {}
	for role: String in CASES:
		var spec: Array = CASES[role]
		var total := {"tells": {}, "shapes": {}, "recoveries": 0, "repositions_moved": 0,
			"dodges": 0, "punishes": 0, "min_tell_s": INF, "floor_breaches": [], "fights": 0, "reader_opening_inputs": []}
		for seed_index: int in SEEDS:
			for policy: String in ["MASHER", "READER"]:
				var party: Array[RefCounted] = []
				for id: String in ["terrapup"] + RETAINED:
					var creature: RefCounted = SPECIES.spawn(id)
					creature.call("set_level", LEVEL, PROGRESSION.config())
					party.append(creature)
				var foe: RefCounted = SPECIES.spawn(str(spec[0]))
				foe.call("set_level", LEVEL, PROGRESSION.config())
				var pilot := Witness.new()
				pilot.context = {"chapter": spec[1], "band": "f22_witness", "after_south_bridge": true}
				if role == "ACE": pilot.context["role"] = "ACE"
				await pilot.fight(self, party, [foe], bool(spec[2]), hash("f22w/%s/%d" % [role, seed_index]), policy)
				var seen: Dictionary = pilot.witnessed
				for id: String in seen.tells:
					total.tells[id] = int(total.tells.get(id, 0)) + int(seen.tells[id])
					total.shapes[id] = seen.shapes[id]
				for key: String in ["recoveries", "repositions_moved", "dodges", "punishes"]:
					total[key] = int(total[key]) + int(seen[key])
				total.min_tell_s = minf(float(total.min_tell_s), float(seen.min_tell_s))
				(total.floor_breaches as Array).append_array(seen.floor_breaches)
				(total.reader_opening_inputs as Array).append_array(seen.reader_opening_inputs)
				total.fights = int(total.fights) + 1
		var authored: Array = AI.pattern_ids(patterns, role, {"role": role, "chapter": "water", "trainer_owned": bool(spec[2])})
		var reasons: Array[String] = []
		var live_authored := 0
		for id: String in total.tells:
			if authored.has(id) and not str(total.shapes[id]).is_empty(): live_authored += 1
		if live_authored < 2: reasons.append("fewer than two authored patterns telegraphed live")
		if total.tells.has(""): reasons.append("an unpatterned generic strike was telegraphed")
		if not (total.floor_breaches as Array).is_empty(): reasons.append("tell below chapter/heavy floor")
		if int(total.recoveries) < 1 or float(total.repositions_moved) / maxf(1.0, total.recoveries) < 0.5:
			reasons.append("recoveries mostly stood and traded")
		for response: Dictionary in total.reader_opening_inputs:
			if float(response.delay_s) < observed:
				reasons.append("reader attacked an opening before its observation delay")
				break
		rows[role] = total.merged({"authored": authored, "pass": reasons.is_empty(), "reasons": reasons}, true)
	var dodges := 0
	var punishes := 0
	var reader_opening_responses := 0
	for role: String in rows:
		dodges += int(rows[role].dodges)
		punishes += int(rows[role].punishes)
		reader_opening_responses += (rows[role].reader_opening_inputs as Array).size()
	if dodges < 1: errors.append("no observed dodge across all roles")
	if punishes < 1: errors.append("no observed punish across all roles")
	if reader_opening_responses < 1: errors.append("no observed reader attack response to a recovery/stagger opening")
	var passed := errors.is_empty()
	for role: String in rows: passed = passed and bool(rows[role].pass)
	var receipt := {"kind": "F22#0 live wild-behaviour witness (flat fixture, production bodies/manager/AI)",
		"pass": passed, "errors": errors, "dodges": dodges, "punishes": punishes, "roles": rows,
		"reader_observation_s": observed, "reader_opening_responses": reader_opening_responses}
	if not _json.is_empty():
		var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_json).get_base_dir())
		var out := FileAccess.open(_json, FileAccess.WRITE)
		if directory_error != OK or out == null:
			errors.append("wild-reaction receipt could not be written")
			passed = false
			receipt.pass = false
		else:
			out.store_string(JSON.stringify(receipt, "\t"))
	print("F22_WILD_REACTIONS " + JSON.stringify(receipt))
	quit(0 if passed else 1)
