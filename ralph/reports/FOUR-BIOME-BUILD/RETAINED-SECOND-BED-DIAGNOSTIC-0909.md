# Retained second-bed diagnostic — 2026-09-09

This was one copied-state diagnostic, not fresh continuity or acceptance evidence. `tools/diagnose_retained_second_bed.gd` passed `--check-only`, then loaded preserved day-2 state into a new isolated user directory. It validated the exact paid tent, campfire, bedroll and creature-bed records, party index 2 `rested=true`, and the single creature bed unoccupied before movement.

The diagnostic directly attempted party-index-0 assignment to creature bed 1. It walked from reconstructed save pose `(29.80001, 0.137814, -40.29507)` to the prompt target `(26.0, 1.388717, -39.3)` in frames 128–218, ending 1.362 m away inside the unchanged 1.4 m tolerance. It used no teleport, fixture mutation, sleep, or retry and exited 0.

This does not reproduce the fresh failure's direction. The fresh required leg began at the paid-bedroll side `(34.98708, -0.849575, -42.66916)` and ended after 3,600 frames at `(29.48413, 0.1243, -37.99322)`, 3.721 m short. The copied save restored a materially shorter, different approach. Its pass therefore says only that the bed prompt is reachable from the saved pose.

Artifacts: `.artifacts/opening-prefix-c3e-0909/bed2-diagnostic/engine.log` SHA-256 `797389807fa65d270538be9bd511dbc2cc9f0f12dbd02879bb34fb50f30a9abe`, `result.json` `4c00cd5643626c1170da52d48f2ef7d34e5d904cf6185ca5930cfb211eb625a9`, probe source `19248ddc202396ff18a7346fd147b6d57a6c325cb00d094cd7d2aa70ef7cbc11`. Terminal Godot census was empty.

Observer limitation: it sampled a supplemental center ray every ten frames and navigator state. It did not intercept the navigator's actual twelve `_free_space` rays, so its null hits cannot identify what the base navigator saw. The deferred sampler also printed a few records after walk arrival while assignment UI completed. Those records changed no state or movement.

## Proposed directional probe

Keep the same preserved copy and state validation. First use the same `BedInput`/`StickNavigator` controller path to walk to the actual paid bedroll prompt/stance, then immediately call the unchanged `_assign_to_bed(0)` so the required return uses `_walk_to_prompt(..., "creature bed 1")`, its 1.4 m tolerance and 3,600-frame budget. Stop after that arrival/failure.

Replace supplemental queries with a diagnostic-only `StickNavigator` subclass injected into `BedInput._nav`. Override `_free_space` and `_drops_away` by copying their current bodies exactly, preserving constants, masks, exclusions, ray order, `hit_from_inside`, and return values. Add observation only at the points where those exact queries already receive results: aggregate first-hit path/layer/distance by forward/side direction, log changes immediately and one snapshot every ten frames, record ground-hit path/height/drop verdict changes, and cap output per leg. Override `walk_to` only to open/close a leg record; call `super.walk_to` unchanged. This observes the decisions used by movement without extra physics queries. Source hashes and a mechanical diff against current navigator bodies should be recorded before parse-check. No native run should start until root reviews that equivalence diff.

## Directional attempt terminal

The reviewed directional source passed `--check-only`, but its one authorized native attempt stopped before movement on `Invalid access to property or key '_send_stick'` while constructing the diagnostic navigator from `TraceDriver`. Check-only did not detect that inherited member-access error. The otherwise idle process was interrupted, census returned empty, and the lease was released. There was no staging delta, obstacle attribution, or retry. Preserved hashes: executed probe `bb5bdf5766b218030ebbd0837d807faa18b345397fc02698994102b123941759`, `bed2-directional/engine.log` `5d987644708fdcf867d7e981158e5b62f50c3e7d8783591a387f5c96ab11253c`, and `stderr.log` `eaf390b018d4eeda6e0162e4a5e3dda4ab92ac2e4451df9eb8b5601f2e170076`.

## Corrected directional reproduction

After the callback correction, the one isolated directional attempt staged by ordinary controller movement to `(34.86634, -0.825769, -42.612)`, only 0.1336 m from the original failed-leg start. The unchanged required return then reproduced the failure: frames 196–3799, ending `(29.52055, 0.118252, -37.99024)`, 3.7563 m from the bed prompt. This closely matches the fresh terminal locality `(29.48413, 0.1243, -37.99322)`, 3.7211 m short.

The hard 1,000-record cap was reached: 301 nearest hits named the CreatureBed StaticBody layer 1, 646 named Terrain, 2 named a wild creature, and 51 had no hit. The bed box intercepted rays at 0.38/0.45/0.95 m around its east and south faces. Separately, low horizontal free-space rays repeatedly struck gently rising Terrain roughly 2–3 m ahead with normals near y 0.98–0.99, while actual ground-drop checks returned false. This distinguishes bed collision from rising-ground classification; it does not yet prove a correction. `drop_delta=0` on `kind=free` receipts is a placeholder, not a ground-drop measurement; only `kind=drop` receipts contain foot-y minus hit-y.

Terminal census was empty. Hashes: engine `1718bacfd1133550c08ad2509c51d5bbe3856c41de7f06c5e62534f67acc8ce6`, console `d7d3dd46ed5d567affce923b7e8d002e59dc2c1c3e0272879d2a184ce15d440c`, stderr `4be629d0bba0ea057629f943d81adc7da933f5a682c9efd5ea158546f9c81432`, result `76633235c8188333ee9fd288e9723d637d504c3946180b07871691a6bc0cefeb`, executed probe `c1cf6680a542c9678e97f77a0216753e8fdf1b7b13dbf2afb43199592cf4b969`.

## Changed-code directional result

The slope-aware navigator was subsequently exercised against the same copied state and reconstructed direction without the diagnostic `TraceNav` overrides. It staged within 0.13358 m of the original paid-bedroll-side start, then reached creature bed 1 in frames 196–643 at 1.13180 m from the prompt, inside the unchanged 1.4 m tolerance and 3,600-frame budget. `BED2 TERMINAL ok=true failures=[]` means the actual bed-panel interaction also opened, focused and accepted party row 0, observed that creature resting, closed, and returned the world unpaused.

The isolated slot SHA-256 remained `a773c9c9805725f778adaebf89a7c3dc6dc6b7430734351bb9ab896eb00a5d2a`. Raw console: `.artifacts/opening-prefix-c3e-0909/bed2-slope-fix/full-console.log`, SHA-256 `116c0f8ee71dd10d9cdd74e1302091d5d3e621f6bb729ccdda0551e49d1004a3`. This is retained copied-state evidence, not fresh continuity acceptance. The focused fixture and mechanism evidence are recorded in `NAVIGATOR-SLOPE-CLEARANCE-0909.md`.
