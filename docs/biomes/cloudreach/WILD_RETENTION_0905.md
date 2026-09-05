# Cloudreach wild grounding and retention — 2026-09-05

## Result and scope

The real production-world regression passes **73 checks, zero failures**, exit 0, with **zero ERROR, SCRIPT ERROR or WARNING lines**. Both actual residents at `lower_cliff_foragers`, `causeway_watch` and `ravine_wind` remain grounded through 30 seconds of live wandering per site. Each site supplies an Engage offer reached through normal controller movement, and the final Engage press starts a real production wild battle.

This is a bounded grounding/retention fix, not a density-placement batch or full-chapter acceptance. No world geometry, encounter tables, chapter configuration, species, rewards, Meadows wild behavior, save format or combat implementation changed. The combat-surface adapter is unchanged.

## Defect and evidence boundary

The earlier continuous log did **not** prove that every missing offer represented a fall. In particular, `merged-resume4-jump-timing.json` records a real `Engage Galewisp` offer at 1,153.0 simulated seconds from `ravine_wind_0`. The lower/causeway prefix had no Engage offers; that observation alone cannot distinguish a misplaced, wandering or fallen body.

There is also a deliberate prerequisite: the shared director's `_engageable()` returns null until an ally has actually been deployed. The continuous fixture did not deploy before its first mandatory Senn fight. Absence of earlier offers is therefore not evidence that the lower-road population was absent or had fallen. The retention smoke explicitly deploys through real recall input before judging its short Engage approaches.

The inspected defect was nevertheless concrete. Production resolves each site centre through `_resource_position`, but the old director then placed two bodies at global-X offsets of +/-4m and allowed unrestricted 8m wandering on narrow collision strips. Only the centre had been resolved, the final grounding result was ignored, and the base wild's exhausted clearance search accepted its last invalid candidate. Cloudreach's separate streaming loop also bypassed inherited `_set_wild_active`, so the Cloudreach reground override was not reached through the empty Meadows cluster list.

## Implementation

`scripts/combat/cloudreach_encounter_director.gd` now owns the Cloudreach-only changes:

- A local `CliffWild` subclass rejects an invalid final wander fallback and validates the next short peaceful movement before allowing it. Its health, combat, catch, animation and ordinary movement implementation remains inherited.
- Each actual body is admitted only after its capsule footprint plus a 0.25m safety margin fits real static collision on the intended analytic stratum. Eight perimeter samples plus the centre must agree with a walkable floor; a different stacked deck or another actor is not accepted as supporting ground.
- A deterministic nearby search repairs an edge-biased centre and checks short connections in 0.5m steps. It does not consume a random draw or change the chosen species/level. Unsupported objects are freed before entering `_wild_creatures`, home or once-only residency. Partial failed sites are reported once and are not marked complete or repeatedly resampled.
- Residency uses the validated home as a recovery anchor while preserving proximity activation for a body near the player. It invokes inherited `_set_wild_active`, retaining fight/faint/respawn/gate guards. Missing-floor/fallen bodies recover to a revalidated home, never to a different stratum selected by their falling Y. Hidden and engaged bodies are left alone.
- Repeated fight-start calls are guarded before the existing surface-binding step, so they cannot reposition an already active battle.

### Shared spawn-construction audit

Main's `spawn_wild` hardcodes its body script, so the Cloudreach override constructs the same canonical `CREATURE_SCENE` with the local subclass. The corresponding main contract was checked field by field: species validation, once-cleared guard, stable name and optional parent, `populate`, deep-copied combat override, `_set_fixed_level`, aggression override, shared wild configuration, home, `wants_to_engage` signal, population registration and once-only metadata remain present. Prefab/populate still owns visuals, groups, health and individuality; no second roll or combat implementation was introduced. Site respawn and unlock metadata still comes from `_spawn_available_sites`. Main trainer-body construction is untouched.

## Verified production placements

Successful run: `ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-retention-second.log`, recorded world seed **1594702062**. Coordinates below are actual resolved centre/home records, not the older authored table coordinates.

| Site | Resolved centre | Body 0 home / species | Body 1 home / species |
| --- | --- | --- | --- |
| `lower_cliff_foragers` | `(-188.24,194.23,619.54)` | `(-188.24,194.19,619.54)` / Pipwing L18 | `(-192.24,193.89,619.54)` / Pipwing L22 |
| `causeway_watch` | `(-235.98,390.06,1569.27)` | `(-231.98,390.00,1569.27)` / Shadelet L25 | `(-239.98,390.00,1569.27)` / Bramblebun L25 |
| `ravine_wind` | `(378.34,610.06,3257.36)` | `(382.34,610.00,3257.36)` / Frostclaw L23 | `(374.34,610.00,3257.36)` / Galewisp L25 |

Actual Engage offers: Pipwing at player `(-184.07,194.83,623.72)`, Shadelet at `(-226.06,390.03,1569.27)`, and Frostclaw at `(388.26,610.10,3257.36)`. These are short physical-approach proofs, not a claim that every resident is automatically presented on the uninterrupted main route.

## Tests and reproduction

```powershell
& 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=test_cloudreach_wild_retention.gd,test_cloudreach_encounters.gd
& 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' --headless --path . --log-file 'ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-retention-second.log' --script tests/smoke_cloudreach_wild_retention.gd
```

Focused unit result: **6 tests, 346 assertions, zero failures**, no engine/script errors (`wild-retention-unit.log`). Negative controls cover a rejected final fallback, nonfinite/missing-world requests, and a path with supported endpoints but an unsupported middle. Valid target/path controls still succeed.

The real-world smoke leaves all six authored sites configured and validates the three ungated early sites without replacing their wild tables. It checks finite grounded footprints during and after actual wandering, actual movement rather than frozen residency, repeated deterministic placement search, the all-eight-invalid live fallback, unsupported spawning, forced 80m falls, genuine fainted instances, faint/respawn timers, closed gates, sleep/wake identity and unchanged safe homes. The final actual wild combat verifies that retention cannot reset active-fight position or physics. Combat exits through an explicit test-only flee cleanup, not a victory/difficulty claim.

Site-to-site player relocation and fault injection are explicitly test fixtures, not a continuous route. A temporarily noncolliding player avoids turning a relocated fixture into a moving floor under a wild; normal collision and real recall/movement/Engage input are restored for the approach. Saves are isolated under a process-specific `user://cloudreach_wild_retention_<pid>` directory.

The first run remains non-green in `wild-retention-first.log`: 72 checks, 20 failures. Its player was parked on a spawn and then moved overhead, carrying a wild with it; it also omitted the deployment required for Engage. A remaining Windscar edge-slip motivated the per-step check. None of that first run is presented as a passing grounding or Engage result.

## Performance caveat — not a budget pass

Successful log creation-to-completion wall time was **158.70s**. Its explicit startup marker was **55.03s**; the remaining **103.67s** includes script preload overhead, **90 simulated seconds** of ordinary 60Hz roaming, support assertions, approaches, fault checks and combat cleanup. This is aggregate diagnostic timing, not an isolated CPU/GPU profile or owner-device frame-rate measurement. Startup partially overlapped a separate authorized headless test.

There is a real new query cost: the ordinary short movement check can make **two footprint samples x nine rays = 18 rays per moving wild per physics tick** (up to 1,080 rays/second at 60Hz), plus destination searches and spawn checks. Invalid paths often exit early; those are bounds from the implementation, not measured call counters. No optimization or unmeasured performance claim was made.

A stationary Galefoot camp capture is insufficient by itself: `(-280,180,520)` is approximately **136m** from the resolved lower site, outside the **130m** activation radius, so those residents may not be active there. The isolated profile below instead uses the actual lower/causeway/Windscar bodies spawned and moving.

### Isolated active-roaming probe

`tools/probe_cloudreach_wild_performance.gd` uses the production world, all six authored site configurations and the three actual early-site resident pairs. It fixes fixture seed 1594702062, uses ordinary 60Hz physics/time scale 1, and holds a separate camera constant within each site's four phases: sleeping, active idle, uninstrumented roaming, instrumented roaming. Each phase has 3 simulated seconds of discarded warmup and 10 simulated seconds of measurement. The same body/creature instance/home is retained; between-window home and wander-RNG resets are explicit comparison fixtures, not gameplay tuning. Roaming windows must contain actual measured movement and end with supported footprints. Saves are process-isolated.

The default-off diagnostic seam counts actual support calls and rays, including early exits, and measures inclusive support wall time. Disabled play performs no clock/counter work. Enabled timings include the clock calls, counter updates and script ray proxy; engine process/physics percentiles and real frame intervals are recorded separately for the uninstrumented comparison. The probe itself adds common sampling overhead. These are not isolated OS CPU measurements, GPU timings, an ROG Ally budget pass, or a substitute for an uninterrupted player path. Fixed phase order and operating-system scheduling can also bias a short comparison. Do not use `--fixed-fps`, which decouples simulated time from wall time.

### Measured results — two separate quiet runs

Both runs finished **12 phases, zero failures, exit 0**, with no `ERROR`, `SCRIPT ERROR` or `WARNING` lines. Check-only was clean, and the default-off seam also retained **6 tests / 346 assertions / zero failures** in the focused retention/encounter suite (`wild-performance-unit.log`). No other Godot world or renderer ran alongside either measured process. Host: Intel Core i5-8400, six cores, NVIDIA GTX 1060 3GB; Godot 4.7 stable. The rendered command requested a **1280x720** window and used the production OpenGL 3.3 Compatibility renderer (NVIDIA 560.94), not an ROG Ally capture or 1080p acceptance.

Artifacts under `ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/`:

- `wild-performance-headless.json` / `.log`: process 7596; 54.45s reported startup, 214.34s script-run total.
- `wild-performance-rendered.json` / `.log`: process 12368; 55.78s reported startup, 213.32s script-run total.

Each JSON preserves all four phases at all three sites: exact counters, inclusive support time, engine process/physics monitor distributions, independently measured frame intervals, actual movement, start/end positions, species, levels, body/creature IDs and unchanged homes. The observed pairs match the production placement table above. Both residents were active for all 1,200 possible body-ticks in every idle/roaming window. Uninstrumented/instrumented roaming had **670/672 lower, 734/734 causeway and 637/637 Windscar moving body-ticks**, consistently in both runs. Every final footprint was supported; identities survived all phase resets. Sleeping and active-idle controls made **zero support calls/rays**; uninstrumented windows left all diagnostic counters at zero.

Exact instrumented workload over each 10-simulated-second roaming window (600 physics ticks), for **both residents combined**:

| Mode | Site | Support calls | Actual rays | Inclusive support ms / physics tick |
| --- | --- | ---: | ---: | ---: |
| Headless | Lower | 1,418 | 12,740 | 0.603 |
| Headless | Causeway | 1,558 | 14,022 | 0.545 |
| Headless | Windscar | 1,415 | 12,721 | 0.546 |
| Rendered | Lower | 1,418 | 12,740 | 0.382 |
| Rendered | Causeway | 1,558 | 14,022 | 0.553 |
| Rendered | Windscar | 1,415 | 12,721 | 0.350 |

Ordinary **uninstrumented** active-roaming windows, in milliseconds (engine monitor samples are not independent per-call CPU measurements; actual frame intervals are measured separately):

| Mode | Site | Process monitor mean | Physics monitor mean / p95 | Actual frame interval p95 / max |
| --- | --- | ---: | ---: | ---: |
| Headless | Lower | 5.269 | 4.378 / 9.639 | 17.026 / 25.335 |
| Headless | Causeway | 4.427 | 3.664 / 10.829 | 16.972 / 26.236 |
| Headless | Windscar | 4.960 | 3.091 / 6.445 | 16.900 / 31.095 |
| Rendered | Lower | 9.133 | 2.167 / 6.051 | 16.787 / 21.954 |
| Rendered | Causeway | 17.628 | 4.417 / 11.965 | 19.302 / 28.096 |
| Rendered | Windscar | 10.713 | 1.842 / 3.694 | 16.729 / 22.912 |

Instrumentation overhead is **not isolated by this short comparison**: changing from uninstrumented to instrumented changed mean physics-monitor samples by -0.156/+0.795/-0.102ms in headless lower/causeway/Windscar, and -0.061/+0.075/+0.531ms rendered. Negative deltas do not mean profiling makes the code faster; scheduling, fixed order and monitor sampling are confounders. Inclusive support timings already contain the profiling work and should not be presented as native ray-only costs. No pre-fix world baseline was run, so total idle-to-roaming differences cannot all be attributed to the retention change.

The control windows expose a separate unresolved whole-world timing risk: **headless causeway active-idle reached a 596.001ms maximum frame interval (11.819s wall / 10s simulated)** and **Windscar sleeping reached 430.467ms (10.915s wall / 10s simulated)**, both with zero support queries. Those stalls did not reproduce in the corresponding rendered controls, and their cause was not diagnosed by this bounded probe. Rendered causeway roaming itself had **19.302ms p95 / 28.096ms max** uninstrumented, while the instrumented Windscar window peaked at **32.713ms**. These are preserved failures of a clean per-frame 60fps budget, not hidden by the 60fps cap or average support cost.

Conclusion: the exact safety-query cost is now measured on real moving residents and is roughly **0.35-0.60ms per physics tick averaged across each pair**, including profiling overhead. The samples do **not** establish an overall scene/device performance pass, isolated OS CPU/GPU cost, or the worst possible wander-seed/query spike. No gameplay tuning or performance optimization was made from these measurements.

```powershell
& 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' --headless --path . --log-file 'ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-headless.log' --script tools/probe_cloudreach_wild_performance.gd -- --output=res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-headless.json
& 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' --path . --resolution 1280x720 --windowed --log-file 'ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-rendered.log' --script tools/probe_cloudreach_wild_performance.gd -- --output=res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/wild-performance-rendered.json
```
