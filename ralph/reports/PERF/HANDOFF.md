# PERF lane handoff (lane stopped; remaining work moves to Codex)

## Branch and head

- Branch `tb/perf`, head `3bf8ae68`. PR #543 is landing `3bf8ae68`.
- Jolt trial is `39e17a54`, a separate commit on this branch that `b62212c5` reverts. Nothing else touches `project.godot` physics.
- Measurements, judge verdicts and the realm cost tables are in `FINDINGS.md` and the folders next to it. This file lists only what is left.

## Done and landing (#543)

| Commit | Fix | Proof |
|---|---|---|
| `e36ad36f` | F32 realm mount filters adoptable legacy nodes once per call. Before, it walked all ~180k world nodes for each missing site. | A fresh 153-site mount goes from 10,031 ms to 311 ms. The timing check in `smoke_f32_type_crop_harvest` fails on the old code. |
| `b4a2c02b`, `3bf8ae68` | Guest `local_sample` and host `host_ending_context` (`foundation_travel_lifecycle.gd`) find the SequenceDirector through the `progression_restore` group. Before, each call walked the whole world. | A grouping check in `smoke_f32_type_crop_harvest`. Travel and ending tests pass: 25. |
| `e909bfdc` | `map_state.save_data` reuses each realm's base64 fog. The cache key is epoch/count/size; Cloudreach is covered. | `test_map_state::test_saved_fog_is_never_stale`. 68 map tests pass. |
| `10cdde31` | `enemy_pattern_telegraph.aim` samples each ground point once per rebuild and skips unchanged aims. Before, each aim cost ~125 ms, re-run every tell tick. | `test_enemy_pattern_telegraph`: 2 of its 3 cases fail on the old code. 157 combat/telegraph tests pass. |

An independent review of all four fixes passed. Before #543, everything up to `97bea36d` was already landable (see `FINDINGS.md`).

## Not done: one task each

### 1. Healing freeze: tether lights slice
- **Next step.** Spread `meadow_healing.gd::_kill_the_tether_lights` (~1.1 s) across frames, or collect its targets once from a group or an index instead of walking the ~180k-node world several times.
- **Files.** `scripts/world/meadow_healing.gd`, plus wherever the tether lights are spawned (they can join a group there).
- **Proof.** `smoke_meadow_healing_land_heals`: the freeing frame drops below its current ~6.0 s. Tighten that smoke's 9 s assert to the new figure. Every light is gone after healing in a solo run and on the host and guest of a two-peer run.

### 2. Healing freeze: pylons slice
- **Next step.** Same approach for `_topple_the_pylons` (~1.1 s).
- **Files.** `meadow_healing.gd` and the pylon spawn site.
- **Proof.** Same smoke, plus a check that each pylon toppled exactly once and its save flag holds after a reload.

### 3. Healing freeze: scatter regrowth slice
- **Next step.** Slice the scatter regrowth (0.6 s). The regreen (1.35 s, after `020be38b`) is the next-largest part of that frame.
- **Files.** `meadow_healing.gd`, `scripts/world/vegetation.gd` and `scripts/world/scatter_bake.gd`.
- **Proof.** Same smoke. The regreen mesh checksum (223,824 vertices) stays identical. A code-blind before/after visual judge on the healed land.

### 4. Jolt with its motion judge
- **Next step.** Revert the revert `b62212c5` on a lane branch, or cherry-pick `39e17a54`. Then:
  - run the full multiplayer/smoke CI;
  - run a **motion judge**: a code-blind comparison of the same scripted routes under the default engine and under Jolt (slopes and steps, `move_and_slide` on terrain, swimming, riding, flying, combat bursts and knockback), for feel.
- **Files.** `project.godot` only.
- **Proof.** Measured on the Tidewake stand: physics step 8.4 → 2.4 ms. The motion judge returns EQUIVALENT, CI is green and the coordinator signs off. An earlier 24-smoke batch passed 21. The other 3 also fail under the default engine; see Traps.

### 5. GTX 1060 Medium gap, per realm
The target is an average of ≥60 FPS and 1% lows ≥40 at Medium 1080p. Only Codex's PR #525 routes are device numbers.

- **Meadows.** CPU-bound, ~110 ms process vs 27 ms GPU.
  - **Next step.** Fold the Crossing Hall (F17's `crossing_hall.gd`) into `static_mesh_batch.merge()`.
  - **Then.** Per-preset grass ring density and sun shadow distance/cascades; these need a visual judge.
- **Tidewake.** CPU-bound, ~122 ms.
  - **Next step.** The remaining lever is Jolt (task 4). The first-shore wild creatures cost ~2 ms each in `move_and_slide`.
  - **Also open.** Why the far floor adds ~26 ms of process time.
- **Stormwood.** Average 17 FPS.
  - **Next step.** Per-preset ground cover density (2.0M primitives); needs a visual judge.
- **Cloudreach.** Average 74 FPS, 1% low 43; not profiled.
  - **Next step.** Run the PR #525 device route on the current head.
- **Needed from Codex.** A per-function device profile on #525 (requested; not received) before more CPU guesses.
- **Proof.** Codex re-runs the device routes per realm.

### 6. Tournament-phase per-frame costs left
- **Where the numbers come from.** Host profile from `smoke_net_shared_boss --tournament` under `-d --profiling`, taken before `10cdde31`, so the telegraph rows are already fixed.
- **Remaining rows, by self time:**

| Function | Cost (calls) |
|---|---|
| `session.gd::_rpc_owner_passive_input` | 12.8 s (217) |
| `vegetation.gd::_refresh_render_instances` | 22 s (37), ~600 ms each |
| `remote_creature.gd::_follow` | 5.3 s (932) |
| `session.gd::_admitted_character_state_work` | 5.0 s (638) |
| `companion_presence.gd::_scan_camp_sources` | 4.9 s (15), ~320 ms each |
| `telegraph_glow.gd::_ground_vertex` | 3.6 s (11k); same fix as `10cdde31` |
| `combat_manager.gd::_finish` + `encounter_director._resolve_ordinary_combat_round` | ~6 s (583 each) |

- **Not per-frame.** The boot-time `playground_hud._ensure_minimap_baked` / `map_baker.bake` (66 s under the debug profiler) runs once, at boot.
- **Next step.** Take `telegraph_glow._ground_vertex` first (cheapest). Then `_scan_camp_sources` and `_refresh_render_instances`, which are long single frames.
- **Proof.** For each fix: re-profile, plus a unit test that fails on the old code.
- **Separate failure.** Remaining smoke FAIL: "both peers completed tournament_semi_tam (no verdict)". That is Lane A's owner-passive checkpoint/RESOLVING path, not a perf item.

### 7. Tidewake per-creature water modifier cost
Not started.
- **Next step.** Profile one Tidewake wild creature's environment/water modifier path under `-d --profiling`.

## Known traps

- **Self time is double-counted across `call()`.** Godot's profiler counts a callee reached through `call()` as the caller's self time too. `wild_creature._update_pattern_geometry` showed 27.8 s "self" that was really `aim()`. Check the callee rows before blaming the caller.
- **Profiling a peer.** Temporarily add `-d --profiling` to the peer args in `tests/helpers/net_harness.gd`, gated on an env var such as `TB_PROFILE_PEER=0`. Revert it with `git checkout` afterwards.
- **Disk.** A profiled peer log is ~17 MB, and one stills run was 571 MB. The session disk filled once and a run lost its output. Delete `/tmp` run directories between runs.
- **Shared world walks.** Sharing one world walk across the healing steps broke them: steps free nodes that later steps read. Collect per step or by group.
- **Deferred calls per mesh.** One deferred call per mesh overflowed the message queue and crashed the Meadows boot. Batch into one deferred flush (`31e6846b`, `95f09f7c`).
- **Wild spawn slicing.** It runs only in host shells and live sessions (`33e131af`). Tests that index `wild_creatures()` mid-slice see far-away bodies.
- **Stale smokes, not in CI.** These fail identically with or without PERF changes and under either physics engine: `smoke_step_up`, `smoke_riding_saddle`, `smoke_combat_baseline`, `smoke_fireball_teaching`. Do not read them as regressions.
- **Container numbers.** The headless container uses Compatibility under xvfb. Quote only structural counters and profiler ratios from it; quote FPS only from the device.
