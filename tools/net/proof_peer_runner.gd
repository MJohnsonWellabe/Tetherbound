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


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not PROOF_STEPS.handles(action):
		return await super(msg)
	var before := _physics_count
	var out: Dictionary = await PROOF_STEPS.run(self, action, (msg.get("args", {}) as Dictionary))
	out["frames_used"] = _physics_count - before
	return out
