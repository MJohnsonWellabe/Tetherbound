extends "res://tools/earned_saves/earned_chain_runner.gd"

## F46#1 witness input: at each chapter gate, what the game itself tells the
## player to do next (quest log tracked goal, HUD objective, hint and any
## lesson card), recorded by f20_portal_travel.observe_next_goal. Starts from a
## disclosed generated boundary profile; where the profile is a chapter exit,
## it plays the ordinary gate (Home Key, Shrine Room hang, arch) and records
## the goal after each step. The printed "F46 NEXT GOAL OBSERVATION" lines are
## the input to an independent next-goal verdict; this script claims none.
##
##   godot --headless --path . --script tests/smoke_f46_next_goal_boundaries.gd -- --profile=<relay|sigils|tidewake|cloudreach|stormwood>

const TRAVEL_HELPER := preload("res://tests/helpers/f20_portal_travel.gd")
const LEGS := {"tidewake": ["tidewake", "water"], "cloudreach": ["cloudreach", "cloudreach"], "stormwood": ["stormwood", "stormwood"]}


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="): segment = arg.trim_prefix("--profile=")
	game = root.get_node("Game")
	var scratch := OS.get_user_data_dir().path_join("f46_next_goal_%s_%d_%d" % [segment, OS.get_process_id(), Time.get_ticks_msec()])
	save_dir = scratch.path_join(segment + "/save")
	receipt_path = scratch.path_join(segment + "/receipt.json")
	generated_fixture = true
	game.set("save_system", SAVE.new(scratch + "_working"))
	if segment.is_empty() or not await _generate_boundary_fixture():
		failures.append("generated boundary profile required: " + segment)
		_finish()
		return
	disclosures.append("Generated boundary profile %s (disclosed in generated_boundary_profiles.json); observations only." % segment)
	var travel := TRAVEL_HELPER.new(self, game)
	for frame in 120: await process_frame
	travel.observe_next_goal(segment, "gate_loaded")
	if LEGS.has(segment):
		var held: Array = game.local.redesign_character.get("relics_held", [])
		if not await travel.home_key(): failures.append_array(travel.failures); _finish(); return
		travel.observe_next_goal(segment, "after_home_key")
		if held.size() == 1:
			if not await travel.hang_relic(str(held[0])): failures.append_array(travel.failures); _finish(); return
			travel.observe_next_goal(segment, "after_relic_hang")
		if not await travel.enter(LEGS[segment][0], LEGS[segment][1]): failures.append_array(travel.failures); _finish(); return
		for frame in 120: await process_frame
		travel.observe_next_goal(segment, "after_arch_entry")
	_finish()
