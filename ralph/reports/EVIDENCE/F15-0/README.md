# F15#0 Dock exchange settles once: evidence (lane coop-chapters, branch tb/ev-coop-chapters)

Run Sun 11 Oct 2026, 11:05–11:16 AM CT. Godot 4.7-stable headless, Linux container (4 vCPU, ~1–2 fps in combat).
Source commit: `00d4a639` (origin/tb/ev-coordinator head; no game-code change in this lane).

## Result: PASS (real two-process run, exit 0, 43 PASS lines, 0 FAIL)

Criterion: "Host and guest settle the dock exchange once" (ACCEPTANCE §6.1 F15, T3).

Command:

    GODOT_BIN=<godot 4.7> tools/net/run_two_peer_proof.sh <scratch>/scen/f15_dock_exchange_once.json --out=<scratch>/f15

Two real Godot processes over ENet loopback. Key rows (full table in `PROOF.md`):

- #17 guest pays for the Reedhaven repair through the real prompt: 6 reed fiber + 4 driftwood debited at the press and saved; the host sends no `item_take`.
- #20 host sees the repair done and paid nothing; #21 host does a different (free) action, the Deep Watch chart, through the real prompt.
- #25 guest charged exactly once, in memory and on disk (8/6 → 2/2).
- #26 guest's forced stale resend of the finished repair: no second charge. #27 host's forced press: not charged.
- #29–#31 both peers show both actions done; guest still charged once; host never charged.
- #32/#33 the host's saved world holds both actions; the baseline world held neither.

## Disclosed inputs and shortcuts

- **Fixture (in the scenario itself):** the host loads `tools/net/proof_saves/host_meadows_stormwood_route_open`, a declared-start v28 save built by `tools/net/build_proof_save.gd` (see its README). Both peers use the disclosed initial Crossing Hall portal fixture (`initial_hall_position_and_open_route_no_earned_credit`) to open the Tidewake arch. The swim lesson and Tidecoil prerequisites are set as world flags. Materials are granted in place of gathering. Every step from the dock prompt onward is production code.
- **Slow-host wall-clock scaling, scratch copy only (no repo change):** the scenario ran from a scratch copy (`scenario_as_run.json`) that differs from `tools/net/proof_scenarios/f15_dock_exchange_once.json` only in wall-clock tolerances:
  - every step's step-level `budget_frames` is `max(4×, 12000)`;
  - `build_allowance_s` is 600 (the runner's own cap);
  - `budget_s` is 4×.

  In the proof runner, step-level `budget_frames` only sets the coordinator's wall deadline (frames ÷ nominal 60 fps + 5 s). Peer-side sim budgets come from `args.budget_frames`, which is unchanged. No step, expectation or assertion changed.
  - Why: the unmodified scenario failed twice on this host for wall-clock reasons only. First, the host's Meadows `load_save` took longer than its ~210 s coordinator deadline (peer silent). Second, with that raised, the guest's stale-resend step (7 teleport probes with 60-frame settles) passed its 55 s coordinator deadline. The coordinator then tore the session down, which freed the guest's scene mid-step. Both are slow-host failures, not dock behavior.
- **Environment note:** the first import raced the checkout (`tideglass_shrine.glb` landed mid-import, so `playground_world.gd` failed to parse). A second `--import` fixed it before these runs.

## Files

- `PROOF.md`: every step, expectation, verdict and detail.
- `scenario_as_run.json`: the scratch scenario that ran.
- `NET_RUN.json`, `SUMMARY.md`: coordinator records.
- `peer-*.log.gz`: peer logs.
- `saved_worlds.tgz`: each captured `world.json`.
