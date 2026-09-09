# Navigator slope clearance — 2026-09-09

This is focused test and retained copied-state evidence for the shared test navigator. It is not a fresh continuous `--through-rest` acceptance result.

## Changed sources

- `tests/helpers/stick_navigator.gd` — SHA-256 `e8ae08d855be2de9b020db611ddc0c419f86edb555beb5eca1cec18f50ef9345`.
- `tests/smoke_stick_navigator_low_geometry.gd` — SHA-256 `b04f530bec667feaef6a61a717c22af102de0eae56d527bf693820d1330bae69`.
- Retained directional driver using the actual navigator — `tools/diagnose_retained_second_bed.gd`, SHA-256 `7e67c1684f1f4af3b4e66cbdacf93fef9c95babe30dfa01d958b3d3f909b725e`.
- The pre-change detached navigator is preserved at `.artifacts/nav-slope-smoke-20260909/stick_navigator.detached-baseline.gd`, SHA-256 `899f64093b1d656a7f8aebc692760e1066926f6f0e4c52239f59bb1092d3c7f4`.
- The earlier query-tracing diagnostic is preserved at `.artifacts/opening-prefix-c3e-0909/bed2-slope-fix/diagnose_retained_second_bed.trace-baseline.gd`, SHA-256 `c1cf6680a542c9678e97f77a0216753e8fdf1b7b13dbf2afb43199592cf4b969`.

## Focused native physics smoke

`tests/smoke_stick_navigator_low_geometry.gd` passed `--check-only`, then passed once under the 120-second process-tree/system-commit guard. The full run exited 0 in 52.46 seconds with empty stderr and a zero-Godot terminal census.

The actual Player fixture measured 9° and 40° supported ramps as the full 3.00 m clear. On the 9° ramp, an already active detour remained active through clear reading 19, cleared its side and remaining-frame state on reading 20, and the same actual-player `walk_to` then completed. Independent obstacle controls on the 9° ramp blocked a wall, a 0.40 m crate, and an overhead rail at 2.60 m. A 55° ramp blocked at 0.48 m. The original 0.40 m root, 0.30 m kerb, collision-mask, cliff, and confined-leg controls also passed.

The fixture uses an authored StaticBody3D as its floor and a test subclass that recognizes exactly that body through the navigator's terrain-classification seam. Production classifies real Terrain3D. This surrogate tests real physics queries and actual Player motion but does not replace a retained-world Terrain3D check. No convex-ground control was built or claimed.

Artifacts: `.artifacts/nav-slope-smoke-20260909/full/console.log` SHA-256 `5201228a83d30c2898e657475bc8e774d507063295c984b508b6945d48b85496`; `full/result.json` SHA-256 `65b436a8a696a3cf0fb28f625e6aa1a20a9510e3ad26fc0ea16a91a72ddc290e`. Maximum observed system commit was 52.1%; maximum process count was 255.

## Retained directional check

A separate isolated run copied the preserved day-2 terminal slot and instantiated the actual changed navigator, bypassing the old TraceNav overrides. It walked normally to the original paid-bedroll-side start within 0.13358 m, then returned toward creature bed 1 with the unchanged 1.4 m tolerance and 3,600-frame budget. The return arrived at a planar distance of 1.13180 m in frames 196–643.

`BED2 TERMINAL ok=true failures=[]` also establishes that `_assign_to_bed(0)` completed its real UI path: interaction opened the creature-bed panel, row 0 was focused and accepted, party slot 0 reported resting, the panel was cancelled, and the world was unpaused. This was more than movement-only success.

The isolated slot remained SHA-256 `a773c9c9805725f778adaebf89a7c3dc6dc6b7430734351bb9ab896eb00a5d2a` before and after. Full console: `.artifacts/opening-prefix-c3e-0909/bed2-slope-fix/full-console.log`, SHA-256 `116c0f8ee71dd10d9cdd74e1302091d5d3e621f6bb729ccdda0551e49d1004a3`. Result SHA-256: `4ab7dc55ed7a3b25c09d38bb848d4625c8250fe6c87ef31fde71a3c91f136ba9`. The run exited 0 in 80.7 seconds; terminal Godot census was zero. Stderr contained only the existing deprecated `instance_reset_physics_interpolation()` warning from `playground_world.gd:1092`.

This retained copied-state result reproduces the previously failing direction and shows it now completes against real Terrain3D and the paid bed collider. It does not prove fresh earned continuity, the complete rest lesson, or the full campaign.
