extends RefCounted

## Upper bounds in the units actually awaited by operator_harness.gd. Process
## waits and physics waits are sequential, so price each at its own measured
## rate. Never replace either rate with min/max of the two. State-dependent
## early exits (including skip_if) are deliberately not predicted.
static func predict(steps: Array, config: Dictionary = {}) -> Dictionary:
	var total := {"physics_frames": 0, "process_frames": 0, "wall_seconds": 0.0,
		"total_frames": 0, "unsupported_actions": []}
	for raw: Variant in steps:
		if not raw is Dictionary:
			continue
		var part := action_budget(raw, config)
		for key: String in ["physics_frames", "process_frames", "wall_seconds"]:
			total[key] += part[key]
		for action: String in part.unsupported_actions:
			if not total.unsupported_actions.has(action):
				total.unsupported_actions.append(action)
	total.total_frames = total.physics_frames + total.process_frames
	return total


static func seconds(budget: Dictionary, physics_seconds: float, process_seconds: float) -> float:
	return float(budget.physics_frames) * physics_seconds \
		+ float(budget.process_frames) * process_seconds + float(budget.wall_seconds)


static func hold_frames(spec: Variant) -> int:
	if spec is int or spec is float:
		return maxi(1, int(spec))
	return int({"tap": 1, "short": 10, "long": 60}.get(str(spec), 1))


static func action_budget(step: Dictionary, config: Dictionary = {}) -> Dictionary:
	var a: Dictionary = step.get("args", {})
	var action := str(step.get("action", ""))
	var physics := 0
	var process := 0
	var wall := 0.0
	var unsupported: Array[String] = []
	var hold := hold_frames(a.get("hold", "tap"))
	var rate := float(config.get("physics_ticks_per_second", 60.0))
	match action:
		"boot":
			physics = maxi(0, int(a.get("settle_frames", config.get("settle_frames", 240))))
			process = 1 # Existing scene removal, if there is one.
		"wait":
			physics = maxi(int(a.get("frames", 0)), int(float(a.get("seconds", 0.0)) * rate))
		"stick":
			physics = maxi(0, int(a.get("frames", 10))) + 1
		"move_to", "move_to_entity":
			var held := maxi(0, int(a.get("held_budget_frames", config.get("walk_held_budget_frames", 3600))))
			physics = maxi(0, int(a.get("budget_frames", config.get("walk_budget_frames", 2400)))) + held + 1
			if bool(a.get("answer_prompts", false)):
				var presses := held / 20
				physics += presses * 2
				process += presses * 2
		"face":
			physics = maxi(0, int(a.get("budget_frames", 240))) + 1
		"wait_until":
			physics = maxi(1, int(a.get("budget_frames", 600)))
		"place_bedroll_under_tent":
			physics = maxi(0, int(a.get("budget_frames", 1200)))
			process = 2
		"rest_team_one_bed":
			physics = 5 * (3600 + 180 + 18)
			process = 5 * (18 + 25)
		"charged_hit":
			var budget := maxi(1, int(a.get("budget_frames", 1800)))
			physics = budget + 61
			process = 2 * int(ceil(float(budget) / 20.0))
		"combat_checkpoint":
			physics = maxi(1, int(a.get("budget_frames", 600))) + 3
			process = 2 * int(ceil(float(physics) / 20.0))
		"capture_seq_complete":
			physics = maxi(1, int(a.get("budget_frames", 3000)))
		"press":
			var n := maxi(1, int(a.get("times", 1)))
			physics = n * (hold + 1)
			process = n * (2 + maxi(0, int(a.get("settle_frames", 8))))
		"press_multi":
			physics = hold + 1 # Unlike _inject, this action has no idle-edge waits.
		"press_until", "chip_to_floor", "equip_tool":
			var count_key := "max_attempts" if action == "equip_tool" else "max_presses"
			var defaults: Dictionary = {"press_until": [4, 20], "chip_to_floor": [15, 30], "equip_tool": [3, 60]}
			var n := maxi(1, int(a.get(count_key, defaults[action][0])))
			var actual_hold := 1 if action == "equip_tool" else hold
			physics = n * (actual_hold + 1 + maxi(1, int(a.get("settle_frames", defaults[action][1]))))
			process = n * 2
		"select_menu_tab":
			var n := clampi(int(a.get("max_presses", 16)), 1, 32)
			physics = n * 2
			process = n * 44 # two injection edges +40 transition +2 deferred focus.
		"open_menu", "close_menu":
			var n := maxi(1, int(a.get("max_attempts", 3))) if action == "close_menu" else 1
			physics = n * 2
			process = n * 44
		"interact_with":
			var settle := maxi(2, int(a.get("settle_frames", 20)))
			physics = hold + 1 + settle
			process = 2 + settle
		"advance_dialogue_until_closed":
			var n := maxi(0, int(a.get("max_presses", 60)))
			var close := maxi(4, int(a.get("close_settle_frames", 30)))
			physics = n * 2 + close
			process = n * (4 + maxi(0, int(a.get("settle_frames", 90)))) + close
		"focus_move", "focus_item", "focus_row":
			var n := maxi(0, int(a.get("times", 1)))
			if action == "focus_item":
				n = maxi(0, int(a.get("max_moves", 60)))
			elif action == "focus_row":
				n = maxi(1, int(a.get("max_presses", 6)))
			physics = n * 2
			process = n * 5
			if action == "focus_row" and bool(a.get("optional", false)):
				physics += 2
				process += 22
		"fight_until_resolved":
			var budget := maxi(60, int(a.get("budget_frames", 9000)))
			var gap := maxi(1, int(a.get("gap_frames", 18)))
			# spent charges each injection as3, and checks its budget only at
			# loop entry. Include final-loop overshoot and every possible idle edge.
			physics = budget + gap + 2
			process = 2 * int(ceil(float(budget) / float(gap + 3)))
		"track_aim":
			physics = maxi(0, int(a.get("budget_frames", 240)))
		"force_aim":
			physics = maxi(1, int(a.get("budget_frames", 10)))
		"throw_until_caught":
			var n := maxi(1, int(a.get("max_throws", 4)))
			var resolve := int(float(a.get("resolve_seconds", 6.0)) * rate)
			# Five arm presses (20 physics settle each), aim, throw, strike
			# recognition, catch verdict, then the separate outcome settle.
			physics = n * (110 + maxi(1, int(a.get("aim_budget_frames", 240)))
				+ 2 + 180 + maxi(60, resolve) + maxi(1, resolve))
			process = n * 12
		"capture":
			process = maxi(6, int(config.get("capture_settle_frames", 4)) + 1)
		"capture_seq":
			var hz := maxf(1.0, float(a.get("hz", 5.0)))
			var n := int(hz * maxf(0.2, float(a.get("seconds", 2.0))))
			physics = n * int(maxf(1.0, rate / hz))
			process = n * maxi(6, int(config.get("capture_settle_frames", 4)) + 1)
		"probe_cell":
			physics = 9
			process = 3 # two actual edge waits plus legacy conservative frame.
		"teleport":
			physics = maxi(0, int(a.get("resettle_frames", 60)))
		"pin_clock":
			physics = maxi(0, int(a.get("settle_frames", 30))) # retain conservative legacy default.
		"await_save", "await_load":
			wall = maxf(0.0, float(a.get("timeout_s", 30.0 if action == "await_save" else 180.0)))
			physics = 1 # timeout is checked before the final paired await.
			process = 1
		"type_name":
			var n := (str(a.get("name", "")).length() + 1) * 37
			physics = n * 2
			process = n * 2 + 182
		"assert", "assert_context", "note", "defect", "hold", "release", "record_start", "record_stop", "save_out", "seed_save", "wipe_saves", "refresh_pois":
			process = 1 # retain legacy minimum for synchronous work.
		_:
			# Integration must reject unknown wait-bearing actions, not silently
			# claim that a new action has no cost.
			unsupported.append(action)
	return {"physics_frames": physics, "process_frames": process,
		"wall_seconds": wall, "total_frames": physics + process,
		"unsupported_actions": unsupported}
