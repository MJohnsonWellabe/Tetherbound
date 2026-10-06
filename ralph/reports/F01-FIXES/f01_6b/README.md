# F01#6b: tournament guest join and host RESOLVING stall, root cause

**Status: root-caused, not fixed in this lane.** Every hot path is in a file another lane owns (listed below). No timeout was changed, and no product code for 6b is in this branch.

## Runs

Each run was `TB_NET_RUN_ID=<id> TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 godot --headless --path . --script tests/smoke_net_shared_boss.gd -- --tournament`. The env vars follow row6/VERDICT.md. All runs used tb/f01-fixes at 2d69daf5 or 557553cb, plus local diagnostics that are never committed. Local machine: 4 vCPU, headless.

| Run | Alone? | Quarter-final guest join | Semi-final |
|---|---|---|---|
| sbE | no (op16 alongside) | **cancelled**: "host did not answer in time" (5141 ms) | budget exceeded |
| sbF | yes | bound after 4573 ms | budget exceeded |
| sbG | yes | bound after 1408 ms | no verdict; budget exceeded |
| sbH | yes | bound after 3287 ms | budget exceeded |
| sbI | yes | bound after 722 ms | **host stuck in RESOLVING**: enemy at 0 HP, encounter `done`, manager state 2 at 94.7 s of the 95 s allowance |

Both reproof symptoms reproduce, and they vary from run to run.

## What the diagnostics show

1. **The guest's join request reaches the host late, and the host answers it at once.** In sbF the guest sent `engage 1:1` at t=154213 ms. The host received it at t=158542 ms, committed it in 55 ms, and the verdict reached the guest at t=158638 ms. The peers' clocks start within milliseconds of each other. About 4.3 s went to the request waiting behind the host's main thread. The join deadline is `shared_opponent_join_timeout_s` (5 s), so a slower frame cancels the join.

2. **Both peers' main threads are saturated during the tournament.** A local per-callback profiler and a frame-stall detector showed:
   - **Host:** 0.4–2.7 process frames/s and 3–22 physics frames/s through the semi-final, with stalls of 0.3–2.3 s about every 1.5 s.
   - **Guest:** 2–5 frames/s.
   - **Owner-passive inputs (Lane A):** the host spends a mean of **126 ms** (max 381 ms) on each `owner_passive_input` packet (sbH: 445 packets, 56 s of host main thread). The guest re-sends every unacknowledged input in each packet, which reached 53 inputs per packet and 3.8–16.5 KB. Building the context costs about 0 ms; the cost is in applying the inputs. Each stall in sbG lines up with 4–5 such packets.
   - **World entry (F32):** `foundation_resources.gd:_process` took **about 10 s in one burst** on both peers (18 frames).
   - **Steady state:** `combat_manager.gd:_physics_process` takes up to 4.4 s per 10 s on the host. On the guest, `foundation_travel_lifecycle.gd:_process` takes about 2.5 s and `ledger_rpc.gd:_process` about 2.2 s per 10 s.

3. **Each round waits on a slow owner-passive checkpoint.** The host's RESOLVING waits on each participant's `combat_round_reward` duty. For the guest, that duty is held behind `owner_passive_checkpoint_pending` / `owner_passive_original_pending`. At these frame rates each guest checkpoint (frozen → save/saved repeated → journaled) takes **4.5–9.4 s on average, up to 22.9 s**, with 2.2–3.0 save rounds each (sbF–sbI). In sbE/sbG, `actor_vitals` also stayed pending into the semi-final, so both peers' `move_start` and `strike_intent` were refused with `pending_vitals`.

**Root cause.** Per-RPC and per-frame record processing starves both peers' main threads. The two worst sources are owner-passive input replay (about 126 ms a packet, with whole-batch re-sends) and the F32 resource mount burst. The host then answers a guest's `engage` too late for the 5 s admission window, and the round's owner-passive checkpoint handshake stretches to tens of seconds, so the host sits in RESOLVING past the smoke budget. Raising timeouts would hide this, so I did not change any.

## Files that own the fixes (none edited here)

- `scripts/net/owner_passive_sync.gd` (Lane A / F18):
  - the guest's re-send of the whole unacknowledged batch;
  - the host's per-input apply cost in `_inputs_host`;
  - the save/saved repeat rounds per checkpoint.
- `scripts/net/foundation_resources.gd`, `scripts/world/f32_world_mount.gd` (F32): the about-10 s synchronous mount at world entry.
- `scripts/net/foundation_travel_lifecycle.gd`, `scripts/net/ledger_rpc.gd` (F18 / Lane A): the per-frame cost on the guest.
- `scripts/combat/combat_manager.gd` (F21/F22): the host's physics cost late in the fight.
- F27 `actor_vitals`: pending vitals that outlive a round.

The `combat_round_reward` owner action follows once Lane A has settled the checkpoint path.

## Tournament seat fix (lane A, 2026-10-06, after #547)

**Problem.** In `smoke_net_shared_boss --tournament`, a striker's blow landed on nothing. The leg seated the striker a fixed 1.4 m from the encounter record's `opponent_pos`. That is inside a 0.57–0.67 m opponent plus a 1.46 m striker, so physics pushed the striker out. Also, the record's position lags a trainer creature that keeps moving. One host receipt measured the opponent 9.29 m from the host's resolved origin against a 9.0 m reach.

**Fix (smoke and probe only, no product change).**
- The `encounter` probe (`tools/net/peer_runner.gd`) now reports `presentation_radius` (the opponent body) and `ally_radius` (this peer's creature).
- The leg seats on the host's live opponent body (`presentation_centre`), at opponent radius + striker radius + 0.35 m (`SEAT_MARGIN`), at floor height, facing it. With no radii it falls back to the old 1.4 m.
- The host-receipt line now prints the keys `combat_math.move_connects` reads (`range`, `cone_degrees`). Before, it printed `reach=-1`, which was a display key mismatch, not a missing reach.

**Measured** (local, each run alone; `[tournament seat]` lines in the run output):

| Run | Round | Peer | Opponent r | Striker r | Seat | Attempts to land |
|---|---|---|---|---|---|---|
| t6b2 | quarter (Mira) | host | 0.67 | 1.46 | 2.48 m | 3 |
| t6b2 | quarter (Mira) | guest | 0.67 | 1.46 | 2.48 m | 1 |
| t6b2 | semi (Tam) | host | 0.57 | 1.46 | 2.38 m | 2 |
| t6b2 | semi (Tam) | guest | 0.57 | 1.46 | 2.38 m | 1 |
| t6b3 | quarter (Mira) | host | 0.67 | 1.46 | 2.48 m | 1 |
| t6b3 | quarter (Mira) | guest | 0.67 | 1.46 | 2.48 m | 2 |
| t6b3 | semi (Tam) | host | 0.57 | 1.46 | 2.38 m | 1 |
| t6b3 | semi (Tam) | guest | 0.57 | 1.46 | 2.38 m | 2 |

Example seat (t6b3, semi, host): live opponent (-0.91, 7.76), creature placed at (2.80, 0.90, 7.76). The opponent moves 1–5 m between attempts (live against record, for example (-1.12, 3.77) against (-2.81, 2.40)), which is why the leg reads the live body.

Before the fix (t6b1, record position), the host's semifinal blow missed all six attempts: opponent 9.29 m from the origin, 9.0 m reach.

**Still open.** In both runs the quarterfinal completes with rewards for both characters. In the semifinal both blows land, but `win_trainer_battle` reaches the coordinator deadline (5400 frames) with no verdict. This is the known stalled round (pending vitals outliving a round), which waits on Codex R1's pending_vitals round fencing. F01#6b stays open until that lands and the final runs.
