extends "res://tests/smoke_net_proof_two_peer.gd"

# peers: scenario (not in the CI net shard; F06 evidence, run by hand -- see below)

## The two-peer PROOF runner (tests/smoke_net_proof_two_peer.gd), unchanged,
## with one difference: a longer heartbeat-silence tolerance, which
## net_harness.gd documents as the value "a smoke may raise BEFORE launch()".
##
## Why: the F06 scenario crosses both peers from the Meadows into Cloudreach
## through Game.enter_realm. On the 4-core evidence container that crossing
## blocked the host's heartbeat past the harness's 150 s realm-crossing
## allowance + 15 s twice (ERROR: peer silent at the host's enter_realm step),
## so the stock command could not reach the gate under test. The tolerance is
## raised to 420 s for this run only; every step keeps its own frame budget as
## the outer bound, and a hung peer is still caught (later).
##
##   TB_PROOF_SCENARIO=<abs scenario.json> TB_PROOF_OUT=<abs out dir> \
##   TB_NET_RUN_ID=net-<unique> TB_NET_OUT_DIR=<out>/net TB_NET_PEERS=2 \
##   godot --headless --path . --script tests/smoke_cloudreach_rejoin_closed_gate_proof.gd
##
## Scenario: tools/net/proof_scenarios/f06_cloudreach_mounted_rejoin.json.

const F06_SILENCE_TOLERANCE_S := 420.0


func _initialize() -> void:
	heartbeat_silence_tolerance_s = F06_SILENCE_TOLERANCE_S
	super._initialize()
