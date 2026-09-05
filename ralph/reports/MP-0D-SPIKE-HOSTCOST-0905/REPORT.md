# MP-0D-SPIKE-HOSTCOST — report

**Lane:** 0.D Spike S2, host cost and realm shells (Sonnet) · **Branch:**
`claude/tetherbound-roadmap-next-jrcjs8` from `main` `55c64aaa` · **Kind:** measurement spike,
probes only · **Brief:** `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` Wave 0 row 0.D.
Box: 4 vCPU / 15 GB, shared with two other lanes; every timing run preceded by a load check
(all < 1.5, recorded per run in `logs/`). Godot 4.7.stable headless. The lane could not write
this file itself; Fable wrote it from the lane's completion report. Raw logs stay in `logs/`
(payload, not committed); the probes are `tools/net/_probe_s2_*.gd`.

## One line per item, up front

| Item | Verdict |
|---|---|
| 0 **Unplanned: Cloudreach does not build on `main`** | **found and reproduced** — `cloudreach_world.gd:135` typed `for preset: Dictionary in times.values()` aborts `_ready()` on `art.json`'s `_comment_night_end_n13` string (added by N13); the unmodified `smoke_cloudreach_arrival_walk` fails the same way (exit 124). No Cloudreach smoke runs in CI, so `main` stayed green. **Fixed by Fable in the same wave** (`merge_sky_profile_into_times`, `tests/test_cloudreach_world_presets.gd`, seen red on the old loop). |
| 1 Concurrent world boots | **done** — 4 concurrent Meadows boots fit: 12.85 GB peak combined; wall-clock flat at 50–60 s warm, **84 s cold** |
| 2 Cluster-activation tick cost | **done** — active wild bodies 8 → 13 → 15 → 23 across 1/2/4 occupant positions (sub-linear, production streaming code); frame-time deltas below this box's noise floor |
| 3 Heightfield-grounded creature cost | **done, hypothesis refuted** — the `.call()`-reflection kinematic loop measured **+11 ms median** over `move_and_slide` for 40 bodies, twice |
| 4 Simulation-only shell | **done, floor only** — freeing 6 of 9 targets cut median frame time 30 % (19.8 → 13.8 ms) but memory only 1.2 %; vegetation (385,333 props) and Terrain3D data untouched |
| 5 Terrain3D collision alternatives | **done** — dynamic collision follows the render camera (confirmed by a distant second camera); **FULL_GAME mode builds whole-map collision for +16.1 MB in 3.06 s**, matching `MEADOWS_MACRO_LAYOUT.md` §8.2's estimate |
| 6 `ERROR:` lines | **done** — zero across 11 Meadows boots; three distinct on Cloudreach, all item 0 |

## 1. Concurrent boots (Meadows; per-process, isolated `XDG_DATA_HOME`)

| Concurrency | Wall-clock | Static mem | VmHWM | Sum VmHWM |
|---|---|---|---|---|
| 1× | 49.9 s | 2,783 MB | 3,237 MB | 3.16 GB |
| 2× | 57.9 / 58.3 s | 2,834 / 2,830 MB | 3,288 / 3,284 MB | 6.42 GB |
| 4× | 58.1–59.7 s | 2,788–2,884 MB | 3,239–3,338 MB | **12.85 GB** |

First cold boot of the session: 84.2 s. A relative `XDG_DATA_HOME` is silently ignored by Godot
(falls back to `$HOME/.local/share`); the launcher must pass an absolute path. Cloudreach: 8.9 s /
566 MB against the unbuilt stub scene — not representative.

## 2. Cluster activation (`_probe_s2_clusters.gd`, production `_tick_streaming`/`_set_wild_active`)

| Pass | Live wild | Active | Median | p95 |
|---|---|---|---|---|
| 1 occupant, spawn | 1,050 | 8 | 20.2 ms | 23.9 ms |
| 1 occupant, dense band-1 | 1,050 | 13 | 23.3 ms | 26.9 ms |
| 2 positions | 1,050 | 15 | 21.8 ms | 25.1 ms |
| 4 positions | 1,050 | 23 | 20.7 ms | 24.0 ms |

Probe bug found and fixed on the way: writing `cluster["active"]` is undone by the director's own
streaming next frame; only `_set_wild_active()` sticks.

## 3. Heightfield grounding (40 bodies, two independent boots)

| Run | `move_and_slide` median / p95 | heightfield `.call()` median / p95 | Δ median |
|---|---|---|---|
| 1 | 10.2 / 28.7 ms | 20.9 / 24.4 ms | +10.6 ms |
| 2 | 8.3 / 29.2 ms | 20.0 / 22.9 ms | +11.7 ms |

The physics path is bimodal (higher p95, lower median); the reflection loop is uniform but dearer.
Do not credit a kinematic mode as a cost saving without profiling a direct `Callable`.

## 4. Shell (post-hoc free after `_ready()`)

Before 2,791 MB / 19.8 ms median → after 2,757 MB / 13.8 ms. Safe to free: `GrassField`,
`Water`, `WorldWeather`, `WorldAudio`, `PlaygroundHUD`, `CombatHUD`. **Not safe:**
`DialoguePanel`, `NamePrompt`, `StarterPicker` — `sequence_director.gd:506/771` call them every
frame (13,000+ "previously freed instance" errors). Real shell = a boot-time flag through
`_dress_the_meadow()` (`playground_world.gd:1088`), `_stand_up_the_grass_field()` (`:1050`),
`_build_water()` (`:1100`), and — for memory — the visual half of vegetation; re-measure then.

## 5. Terrain3D

Baseline `collision_mode=1` (Dynamic/Game), `collision_radius=256`. A second camera 7 km up the
corridor handed to `set_camera()` builds collision there within 180 frames (distant point: no hit
before, hit after). `collision_mode=3` (FULL_GAME): built in 3,059 ms, +16.1 MB static,
+15.6 MB VmHWM, whole-map coverage re-verified with the camera moved back. The "abandoned spot
loses collision" sub-check is confounded by the player's own capsule and is not claimed.

## What Fable changed because of this report

- **D96 amended:** the host runs Terrain3D in FULL_GAME collision mode (+16 MB, 3 s) so
  host-simulated bodies keep the existing `move_and_slide` path everywhere in the Meadows; the
  kinematic heightfield mode is dropped from 4.B's scope (Cloudreach has authored mesh collision
  and analytic ground already). Correctness was the reason for the heightfield route; item 5 gives
  a cheaper way to the same correctness.
- **D97 amended:** a realm shell is a skip-build flag, not a post-hoc free; the three story panels
  stay; its memory budget is set only after the vegetation half is measured (a Wave 6 spike).
- **Harness budgets:** 2-peer smoke 300 s wall clock on PR CI (cold boot ~85 s × 2 + steps);
  3/4-peer nightly only (12.85 GB on a 16 GB runner leaves no margin for a fourth full boot beside
  the runner's own processes).
- **The Cloudreach build failure is fixed in this wave**, with a regression test that fails on the
  old loop, and a Cloudreach smoke is added to `verify-solo-regression`'s shard list in the wave PR
  so the chapter cannot silently break again.
