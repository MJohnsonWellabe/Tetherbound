extends "res://tools/net/peer_runner.gd"

## The peer process of the two-peer proof command
## (`tools/net/run_two_peer_proof.sh`, runner `tests/smoke_net_proof_two_peer.gd`).
##
## Exactly `peer_runner.gd` -- every step and probe, the heartbeat, the control
## channel -- plus the proof steps in `tools/net/proof_steps.gd` (named saves,
## screenshots, save capture and checks, F11). Kept as its own script so the
## shared peer runner every smoke uses is unchanged; only the proof runner
## launches this one.

const PROOF_STEPS := preload("res://tools/net/proof_steps.gd")
## The Stormwood lane's own proof steps (F11#3), in their own file.
const STORMWOOD_STEPS := preload("res://tools/net/proof_steps_stormwood.gd")
## The Tidewake lane's reward-pocket claim steps (F13#2), in their own file.
const TIDEWAKE_POCKET_STEPS := preload("res://tools/net/proof_steps_tidewake_pockets.gd")
const F37_STEPS := preload("res://tools/net/proof_steps_f37.gd")
const F48_STEPS := preload("res://tools/net/proof_steps_f48.gd")
## CI segment checkpoints (tests/helpers/ci_segments.gd).
const SEGMENT_STEPS := preload("res://tools/net/proof_steps_segments.gd")


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if action.begins_with("f48_"):
		if action == "f48_fixture_trainer_fight":
			# This dispatch bypasses the base win_trainer_battle branch. Carry its
			# actual outer budget into diagnostic retention only; execution bounds
			# remain with the coordinator and the original input driver.
			_trainer_fight_command_budget_frames = int(msg.get("budget_frames", NET_STEP_BUDGET_FRAMES))
		return await F48_STEPS.step(self, action, msg.get("args", {}))
	if action.begins_with("f37_"):
		return await F37_STEPS.step(self, action, msg.get("args", {}))
	if SEGMENT_STEPS.handles(action):
		return SEGMENT_STEPS.run(self, action, msg.get("args", {}))
	var stormwood := STORMWOOD_STEPS.handles(action)
	var pockets := TIDEWAKE_POCKET_STEPS.handles(action)
	if not stormwood and not pockets and not PROOF_STEPS.handles(action):
		return await super(msg)
	var before := _physics_count
	var args := msg.get("args", {}) as Dictionary
	var out: Dictionary
	if pockets:
		out = await TIDEWAKE_POCKET_STEPS.run(self, action, args)
	elif stormwood:
		out = await STORMWOOD_STEPS.run(self, action, args)
	else:
		out = await PROOF_STEPS.run(self, action, args)
	out["frames_used"] = _physics_count - before
	return out
