extends "res://tools/net/peer_runner.gd"

## F20-only runner. The shared runner and other feature fixtures are untouched.
const F20 := preload("res://tests/helpers/f20_ending_probe.gd")
var f20 := F20.new()

func _boot_scene(which: String, settle: int) -> void:
	await process_frame
	var game := root.get_node("Game")
	if not f20.fixture(game, "Peer%d" % _peer_index):
		quit(2); return
	# reset_for_new_game in the disclosed setup reclaims solo ownership.
	# Restore the shipping joiner's guard before a throwaway world is built.
	if OS.get_cmdline_user_args().has("--joiner"):
		# A shipping guest resumes its portable character, with no host-world
		# slot competing with that newer acknowledgement on the title route.
		if not f20.check(game.save_system.call("delete_slot", 0) and not game.call("has_save", 0),
			"guest fixture retains only its portable character save"):
			quit(2); return
		game.call("relinquish_world_save_ownership")
	await super._boot_scene(which, settle)

func _execute_step(msg: Dictionary) -> Dictionary:
	var action: String = str(msg.get("action", ""))
	var game := root.get_node("Game")
	var passed := false
	match action:
		"f20_return": passed = await f20.return_home(self, game)
		"f20_talk": passed = await f20.open_credits(self, game)
		"f20_skip": passed = await f20.finish_credits(self, game)
		"f20_revisit": passed = await f20.revisit_completed(self, game)
		"f20_fifth": passed = await f20.fifth(self, game)
		"f20_inspect":
			return {"verdict": "PASS", "data": {"retained": f20.retained(game),
				"context": F20.HOME.journey_context(game), "checks": f20.checks,
				"credits_open": _f20_credits_open()}}
		_:
			return await super._execute_step(msg)
	return {"verdict": "PASS" if passed else "FAIL", "detail": str(f20.failures),
		"data": {"checks": f20.checks, "context": F20.HOME.journey_context(game)}}

func _f20_credits_open() -> bool:
	for node: Node in get_nodes_in_group("story_modal"):
		if node.get_script() == load("res://scripts/ui/regional_credits.gd") and node.call("is_open"): return true
	return false
