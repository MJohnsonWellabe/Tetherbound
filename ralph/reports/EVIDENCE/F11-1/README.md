# F11#1 Stormheart offers at space and at capacity: evidence (lane coop-chapters, in progress)

Godot 4.7-stable headless, Linux container (4 vCPU, slow). Source commit `00d4a639` (tb/ev-coordinator head; no game-code change).

## Status: OPEN, waiting on coordinator approval of a harness fix

| Scenario | Result |
|---|---|
| `stormwood_f11_mirror_host_refuses_guest_accepts` | **PASS**, exit 0, Sun 11 Oct 12:20–12:40 PM CT (`mirror_host_refuses_guest_accepts/`) |
| `stormwood_f11_capacity_guest_full_releases_belt` | FAIL ×2 at #23: host Yes, "offer closed before its Yes/No line (2 presses)". Harness press timing (below) |
| `stormwood_f11_capacity_host_full_lets_stormheart_go` | not run yet |
| `f11_stormheart_accept_refuse` (supporting) | FAIL ×1 at the same host-Yes step; a diagnostic rerun failed at #24 from a stray press |

### Mirror PASS (what it shows)

Both trainers fought the Dynamo with free slots. The host says No and keeps nothing; the guest says Yes and keeps one Stormheart (`fulgocobra`). Each answer is its own world receipt (`legendary_resolution:refused:<host>`, `accepted:<guest>`) on both peers. A second press grants nothing (the prompt is dark). The host's saved world and both saved characters hold each answer once, against non-vacuous pre-offer baselines.

### Disclosed inputs (mirror run)

- **Fixture:** the scenario's own fixture. The host save is `tools/net/proof_saves/host_meadows_stormwood_route_open` (declared start, v28). The initial Crossing Hall portal fixture opens Stormwood. The Dynamo fight is replaced by its contributors fixture.
- **Scratch-copy deviations, no repo change** (`scenario_as_run.json`):
  1. Wall-clock tolerances only: step-level `budget_frames` is `max(4×, 12000)` (the coordinator's wall deadline only), `build_allowance_s` is 600 and `budget_s` is 4×.
  2. The two real portal crossings run guest first, then host. Host-first failed twice on this host: after the host left, it built a 96 s Meadows shell for the guest, and the guest's portal completion never arrived within budget. Guest-first crossed in about 800 frames each.
  3. This run also carried `args.budget_frames=18000` on those two crossings (a leftover from the host-first attempt). Both crossings used about 800 frames, inside the original 6000.

### Host-Yes failure diagnosis (`diagnostic_double_press/`)

A temporary print in `scripts/story/dialogue_runner.gd` (reverted, never committed) traced the host's offer: start at physics frame 13558, then advances at 13560, 13569, 13573 and 13579, the last being the Yes. That is four advances in 19 frames against `proof_steps._tap`'s 10-frame cadence, all from `dialogue_panel._physics_process`. So one injected tap is read as two presses on a slow frame:

- When the extra press lands, the conversation closes before the step sees its Yes/No line.
- In the diagnostic run the step passed, but a stray press then activated the newly enabled Waterward view prompt. That set `stormwood:waterward_revealed`, which #24 asserts is absent.

`proof_steps._tap()` calls `_press_edge` without `press_inject.tap()`'s `await process_frame` after each edge. `peer_runner.gd` (F11#3 note) documents that `process_frame` as the fix for this slow-frame double press. The proposed one-line harness fix is with the coordinator.
