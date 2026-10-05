# F01#6: opening and tournament state survive a two-peer join

**Verdict: FAIL.** Both smokes failed twice on the same commit. The opening-join failure is deterministic. Because both smokes stopped early, the joined guest's opening-layout comparison after the join and after a reload was **never reached**, so that check is unproven.

- **Commit:** `9a5a43655620252c98dd9fde9bd8544d6c9381f5` (origin/main). Local 4 vCPU, headless, each smoke alone with its own `TB_NET_RUN_ID` and `TB_NET_OUT_DIR`.
- `tools/net/run_net_smoke.sh` does not forward extra arguments (it rejects anything except `--peers` and `--out`), so both smokes were run as the coordinator script directly, with the environment the launcher sets:
  ```
  TB_NET_RUN_ID=<id> TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 \
    godot --headless --path . --script tests/smoke_net_shared_boss.gd -- --tournament
  TB_NET_RUN_ID=<id> TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 \
    godot --headless --path . --script tests/smoke_net_meadows_identity_fresh_join.gd -- --opening-together
  ```
  `--opening-together` is the two-peer opening join. It plays both fresh openings, saves and reloads each peer, rejoins, then compares the road layout across peers (`_assert_roads_agree("after the rejoin")`).

| Smoke | Run 1 | Run 2 |
|---|---|---|
| shared_boss `--tournament` | FAIL (28 PASS, 2 FAIL) 15:56Z | FAIL (26 PASS, 4 FAIL; budget exceeded) 16:43Z |
| meadows_identity_fresh_join `--opening-together` | FAIL (44 PASS, 1 FAIL) 16:00Z | FAIL (44 PASS, 1 FAIL), identical 16:47Z |

## 1. Two-peer opening: the guest's catch-supply dialogue never opens (2 of 2, deterministic)

Receipts: `opening-join-run1.txt` and `opening-join-run2.txt`.

What passed in both runs:
- the host and the join, through the production title;
- both registries and both identities;
- the host's whole opening: one named starter and 50 Basic Orbs;
- the guest's opening up to the second Grandpa visit. That covers the bed, the stairs, Grandpa's briefing (opened with a physical interact), the starter picker, naming with a distinct name, and the walk back to Grandpa.

What failed: the guest's physical `interact` at Grandpa's prompt (`peer 1 opened Grandpa's catch-supply reply`) was sent, but no dialogue opened within the 60-frame wait. The smoke stops there, so the per-peer save/reload, the rejoin and the road-layout comparison never ran.

Evidence for the cause:
- The guest's first Grandpa interaction, the briefing, opened normally.
- Only the second beat fails, and it fails only for the guest, after the host had already completed that same beat in the same world.
- Both bodies stand on the same point, the prompt anchor (host 0.317, 1.021, 14.944; guest 0.316, 1.021, 14.942).
- Grandpa's flag ladder (`opening.json` `grandpa_conversations_when`) is gated only on late-game flags that neither peer had set. The conversation therefore comes from the guest's own beat (`return_starter` -> `grandpa_first_catch`).

**Hypotheses for the coordinator, in order of likelihood:**
- (a) The return-starter conversation or its supply grant is consumed or deduplicated per world or per NPC, not per character, so the host's completion silences it for the guest.
- (b) A world delta from the host re-derives the guest's beat (`SequenceDirector.restore_progression_from_game()`) past `return_starter`.

The deciding probe is the guest's `_grandpa_conversation_id()` and `_beat` at the moment of the press. It is a co-op opening defect either way: a second fresh player cannot finish the opening.

## 2. Tournament: guest join fails in the quarter-final (2 of 2), and the semi-final never completes (2 of 2)

Receipts: `shared-boss-tournament-run1.txt` and `-run2.txt`, plus the host timeout sample `shared-boss-semi-timeout-host-sample.json`.

**Quarter-final (`tournament_quarter_mira`), both runs:** `peer 1 joined ... rather than opening another fight (the join did not put this peer in a fight)`.
- In `tools/net/peer_runner.gd` (around l.2783), the guest's `join_encounter` was not bound to the host record within its frame limit: the record was not active, the guest was not a participant, or `_shared_active_id` did not match.
- Afterwards, both peers still reduced the shared HP and both received the full authored reward with durable receipts, so the binding arrives late rather than never.
- In the semi-final the same join binds immediately (`joined 1:2 beside 'pipwing'`).
- So the defect is specific to the first shared trainer round after the guest joins.

**Semi-final (`tournament_semi_tam`):**
- **Run 1 stalled.** After Tam's first creature (a pipwing) fainted, the host's `combat_manager` stayed in RESOLVING with outcome `won`, resolve timer at -31 s, `queued_opponents: 1`, and encounter phase `done`. It was waiting on `_waiting_shared_trainer_round` (`combat_manager.gd` l.2311 and `_apply_shared_trainer_round` l.3071) for a next-round card that never arrived.
- So the shared record was closed (`done`) while the trainer still had a creature queued, and `win_trainer_battle` timed out with "no verdict".
- **Run 2:** the host's strike stopped connecting (opponent 4.47 m away, `connects=false` after 6 attempts), then the whole smoke exceeded its budget.
- The round-advance stall (run 1) is the concrete product finding. Run 2's strike geometry is the shared-strike class the smoke's own header already records as open.

The tournament reload leg (each peer's selected three surviving a production disk reload) was not reached in either run.

No product code was changed in this lane.
