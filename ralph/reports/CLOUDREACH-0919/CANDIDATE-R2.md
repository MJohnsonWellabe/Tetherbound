# Cloudreach grass R2 — validation in progress

Status: mixed visual improvement, not accepted. No grade change. Persistent goal
remains active; R1's rejection is retained. Packaged parity remains pending.

## Candidate and rationale

Source `846324f4f8e6c5f32a9e538da00b752e735e8f15`, after docs-only main merge
`760c4f50` and CI sparse-fixture repair `a2d2f9d12`. R1's broad sinusoidal field
passed global role proportions but produced locally monolithic roles. The new
tracked neighborhood test fails against R1 and passes against R2. R2 uses cached,
non-fractal cellular distance and cell-value fields for small irregular masses.
Same seed, dimensions, proportional widths, placement counts, RNG progression,
route exclusions and tall demotion. No new grass pass, gameplay, other-biome,
terrain, cloud, cliff or shared mesh/shader changes.

## Matched production evidence

Command: `tools/catalogue_survey.ps1 -Biome cloudreach -Character trainer` with
the same eight named subsets, default day/night pair and Godot 4.7 executable,
wrapped by the local atomic render-lock runner. Native Windows Compatibility,
NVIDIA GTX 1060 3GB, OpenGL 3.3 NVIDIA 560.94, 1280x800, production
`scenes/world/cloudreach_cliffs.tscn`, trainer, ordinary HUD and CameraRig/Camera3D
at FOV 70. Catalogue travel and clock freeze are disclosed fixture behavior.
This is full production-scene evidence, not packaged-build verification.

- Root: `shots/catalogue/cloudreach/grass-0919-candidate-r2/`.
- Log: `.artifacts/cloudreach-0919/capture-candidate-r2.log`.
- Capture 18:03:16–18:07:00 UTC, September 19; exit 0, 16/16, complete true,
  failures empty. All PNG dimensions and frame IDs verified.
- Manifest SHA256: `e51f4cacd1e198354913c1fdf1b291c1b389e2b284cd2976e42d4cb5b7333e2d`.
- Every player position equals baseline. Largest numerical camera transform
  component difference: 0.000244141; same camera and framing, floating-point
  settling difference. No capture errors. Existing candy-placement warning remains.
- World attached at 196784ms, versus R1 177862ms and baseline 168029ms. These are
  single runs with different concurrent machine load, not a performance comparison.
- `_sheet-candidate-r2.png`: X baseline, Y R2, both day/night. Raw frames stay local.

## Structural checks

All logs under `.artifacts/cloudreach-0919/`:

| Check | Evidence |
|---|---|
| Focused role tests against R1 | 5 tests, 574 assertions, 1 failed local-role test; `roles-local-coverage-r1-red.log`. This is intentional defect reproduction, not a green run. |
| Same tests against R2 | 5 tests, 574 assertions, 0 failures, exit 0; `roles-local-coverage-r2.log`. |
| Real sliced construction | Same origin/yaw/scale fingerprints and 2600 grass / 20 flowers / 10 understorey counts, three budget yields, exit 0; `roles-sliced-r2.log`. |
| Existing sparse CI fixture test | 1 test, 16 assertions, 0 failures; `ci-fixtures-focused-r1.log`. Eight preexisting Git blobs materialized; no invented acceptance receipts. |

CI run 35459957819 is in progress. All four unit shards now pass, including the
previously failing sparse-fixture shard. Current Warrens smoke still fails.
Prior run 35458097381 also failed Warrens
egress/haze/root checks and combat HUD roster positioning. Those source/test
paths are unchanged by this lane. The existing unmerged Warrens repair
`aa19df9c5` is not an ancestor of tested main `8990a743`; the HUD failure shows a
roster 49px below its computed settled target. These remain explicit delivery
blockers, not grass-test failures or reasons to modify another lane's production.

Independent code review found no production correctness defect: both producers
preserve RNG progression and non-grass behavior, and tall demotion is wired to
their existing route geometry. Limits: sliced fingerprints compare post-change
solo versus sliced construction using origin and selected basis components,
rounded to five decimals; they are not a baseline or bytewise matrix comparison.
Direct generation tests do not exercise all three finishing-grass caller paths.
The review checked those paths in source. No new materials or batches are added;
full-world noise cost and repeated config lookups are not profiled by unit tests.

## Independent code-blind verdict

Fresh reviewer `/root/r2_blind_review` inspected all 32 X/Y full frames, ten prior
Z frames at five sites, the contact sheet, key art and all five Palworld images.
No implementation or earlier reports were supplied. X is baseline, Y is R2,
Z is R1. Both day and night were reviewed.

| Location | X/Y preference | Prior Z comparison / unresolved finding |
|---|---|---|
| Gate | Tie | Fuller distant fringe does not fix bare ramp or broken path edge. |
| Three Bells | X | Y's right mass is larger/upright, with broad blades and bright isolated fragments. Small regression; abrupt grass island persists. |
| Beacon | Y | Better than Z: fewer leg-crossing spikes and clearer stone contacts. Isolated blades and blank lawn remain. |
| Shrine | Y narrowly | Slightly better than Z around legs/tree bases; still a continuous repetitive grass carpet. |
| Perches | Tie | Architecture dominates; no material grass improvement. |
| Cliffhold | Y narrowly | Y/Z effectively tied. Repeated hillside bands and empty square remain. |
| Observatory | Y narrowly | Better than Z; clearing more visible, but grass still emerges through intact paving and blue pieces. |
| Summit | Y | Z narrowly strongest: quieter right foreground. Both improve the baseline approach; grass still crosses route. |

Reviewer: "Y provides a bounded improvement, strongest at Summit Eyrie and
Windscar Beacon. It does not achieve overall visual acceptance."

Reference bar A: **No**. Reference bar B: **No**. Principal gaps are character and
creature integration, authored ground transitions/material agreement, and landmark
construction/atmosphere. Foreground blackness versus pale night distance and the
separately lit trainer remain. Scene work can improve coverage, planting, prop
integration, lighting and atmosphere; coarse grass forms and mismatched tree,
rock, architecture and character art need revised or additional art. This grass
change cannot certify those other mechanisms or the whole biome.

The next investigation checks the approved plan's still-incomplete role-specific
width requirement against Three Bells' broad-blade regression. Current code uses
one width ratio range for all roles. No further height/count/clearance/tip/arc
trial or other mechanism is authorized by this finding alone.

## Acceptance still open

Movement capture completed separately at `shots/catalogue/cloudreach/grass-0919-motion-r2/`,
2/2 setup frames plus 62 movement frames, exit 0. Review invalidates Three Bells
as an acceptance route: fixed forward input eventually walks off the crown,
giving 58.31m displacement dominated by falling. Beacon shows real movement
through 20.33m of grass and under the arch. The loop count is not an exact physics
duration because synchronous image saves permit extra physics steps between
awaits; observed FPS 2–36 is capture-perturbed and proves no performance result.
The next local probe stops at six horizontal metres, checks vertical support,
records elapsed time and turns along the crown at Three Bells. The flawed first
probe remains evidence; a zero exit alone does not establish movement acceptance.
Packaged Cloudreach
geometry and movement are not yet verified. Retained location ledger stays
**0 PASS / 9 POLISH / 3 FAIL**. Any further mechanism needs revised-plan approval.
