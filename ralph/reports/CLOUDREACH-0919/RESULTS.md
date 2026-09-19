# Cloudreach 0919 — grass production results

Status: approved window in progress; candidate 89c176fd pushed to draft PR #129.
Packaged visual acceptance and CI remain pending. Earlier checkpoint entries below
are history, superseded by the approved-window sections. No visual promotion.

- Base: c05c724740b1111b693fb87da72b182934a5232d. Plan initially committed and pushed as 8b437e5ef3d6b8cb33018a19ade98d0afeb3a0a2 on ralph/cloudreach-visual-production-0919. Draft PR: https://github.com/MJohnsonWellabe/Tetherbound/pull/129.
- Isolated worktree: D:\tetherbound\cloudreach-0919. Existing Meadows/source worktrees unchanged. Checkout inherited sparse rules; report files require exact staging with git add --sparse.
- Investigation found existing coverage-mask shaders, trail endpoint fades, 96 clustered banks, and spatially varied cliff strata. The plan now explicitly calls for validating retained work before residual repairs.
- Evidence discrepancy: committed BROAD-VISUAL-0911/CLOUDREACH-NAMED-LOCATION-LEDGER.md has 0/5/7, but the full-game handoff has 0/10/2. Neither is promoted to a newly verified count. Later per-location receipts still require reconciliation.
- Candidate validation seams: tests/test_cloudreach_atmosphere.gd, test_cloudreach_environment.gd, test_cloudreach_cliff_strata_contract.gd, test_cloudreach_route_verges.gd, affected named-location tests, and smoke_cloudreach_look/ground_truth/fall_recovery. The strata test is source-string based and cannot prove visual quality; production review remains mandatory.
- Validation performed: read-only Git/source inspection and git diff --cached --check on the initial plan. No Godot imports, tests, exports, screenshots, played path, or independent visual review were run. No shipping-build parity or visual improvement is claimed.
- Ledger delta: none. Gameplay/source changes: none. Generation spend: none.
- Render lock was absent when inspected; it was not acquired or changed because no capture was attempted. Every future capture must freshly check and acquire it, with Meadows priority.
- PLAN-APPROVED.md was absent from fetched main and lane refs at the last check. Substantive implementation remains held under the owner's September 19 directive. Continue low-risk evidence/consumer investigation and resume dependent work only after reading the approval.

## Approval-path check and read-only continuation

The next owner message pointed to MEADOWS-0919/PLAN-APPROVED.md. A fast-forward pull of this Cloudreach branch reported already up to date at 9dd79413. The referenced approval exists on codex/all-branches-integration-0913 at d3fd668b, and explicitly authorizes the Meadows village-passage harness repair with "No Cloudreach, Stormwood, or Water work." Neither lane approval file exists on this Cloudreach branch. Clarification requested because the named receipt does not approve this plan; no substantive implementation started.

Read-only findings for continuation:

- `_path_ribbon` lowers both mesh ends regardless of `fade_start`/`fade_end`; route sections end at landing-cap edges. Test actual generated geometry and production visibility before deciding whether this breaks the intended continuous wear surface.
- `cloudreach_ground_cover.gd` overrides proportional grass width with an independent 1.6–2.3 scale. Trace shared tuft dimensions before replacing this with the required low/medium/sparse-tall role system.
- Cloud banks already use deterministic related lobes and a lit shaded-base shader. Night exposure and bank/sheet continuity still need production evidence, not another presumed rebuild.
- Read-only delegated evidence audit found explicit later POLISH reports for Flight Aerie (PR121), Sky Shrine (PR122), High Perches (PR123), and Old Wind Observatory (PR124). Starting from the committed 0/5/7 ledger, those four rows would yield 0/9/3. The full-game handoff's 0/10/2 still requires locating a later independent Broken Skyroad Arch promotion; retained ledger evidence for that row ends at FAIL. This remains a provisional evidence crosswalk, not a ledger edit.
- PR124's cliff-strata blind PASS applies to that bounded shared candidate only, not named locations or biome acceptance.

No game files, collision, gameplay, screenshots, tests, or grade claims changed during this continuation. Git/documentation inspection only.

## Approved window: baseline complete

Approval pulled as 34538edb. First baseline import and production catalogue capture completed successfully: 16/16 frames, no manifest/engine errors. See BASELINE.md for commands, source/GPU/scene identity, frame root and independent code-blind verdict. Seven views show grass defects; High Perches does not justify a grass intervention. Role candidate will retain all placement/count/exclusion behavior and use the same role helper in both existing Cloudreach grass-transform layers. No gameplay or shared Meadows grass edits. Exported-build comparison and candidate validation are still pending; ledger unchanged at 0/9/3.

## Candidate 89c176fd — implementation and structural validation

One Cloudreach-only spatial role field now drives ordinary ground cover and the
existing look-finishing grass passes. Low/medium/sparse-tall roles use proportional
width; tall accents near existing route centres demote to medium without deleting
placements. No density/count, shared mesh/shader, route-verge, terrain, cloud,
cliff, collision, gameplay or other-biome edits. Fixed broad-grid distribution:
6,958 low / 2,520 medium / 723 tall (68.2% / 24.7% / 7.1%); adjacency agreement
0.715 versus shuffled 0.531. These are structural measurements, not visual proof.

Godot 4.7.stable.official.5b4e0cb0f; logs local under
`.artifacts/cloudreach-0919/`:

| Check | Result / receipt |
|---|---|
| `--headless --path . --script tests/run_tests.gd -- --only=cloudreach_grass_roles` | Final r2: 3 tests, 530 assertions, 0 failed, exit 0; `roles-focused-r2.log`. |
| `--headless --path . --script tests/smoke_cloudreach_sliced_ground_cover.gd` | First corrected CPU-seam run: solo and sliced counts 2600/20/10, full CPU transform fingerprints identical, 3 budget yields, exit 0; `roles-sliced-r1.log`. |
| Baseline/candidate generation parity | Real ellipse + segment + exclusion fixture: 256 grass positions/yaws unchanged, 256 scale changes, all 27 flower / 7 understorey transforms identical, exit 0; `placement-parity-cpu-r1.log`. Local probe instruments both versions before GPU upload; baseline extracted from 34538edb. |
| `--headless --path . --script tests/smoke_playground.gd` | First run: smoke OK, exit 0. Known dummy-renderer null-material error during equipped-tool checks plus RID/allocator/resource shutdown leak diagnostics; no SCRIPT ERROR. `smoke-playground-r1.log`. This exercises the unchanged Meadows world, not Cloudreach visual acceptance. |

Failed attempts retained: focused r1 failed on an invalid test-helper call before
assertions; r1b exposed the headless dummy renderer returning identity transforms
from MultiMesh readback. The test was corrected to inspect real CPU transforms at
the production upload boundary, not weakened to accept identity output. The first
local parity probe also had a NodePath typing error; its next readback-based result
was invalidated by the same dummy-renderer finding. This is not a first-attempt
green claim. No engine retries were used to conceal a production failure.

## Packaged-build validation in progress

Windows export r1 succeeded with no export errors. Pack source: 89c176fd. Local
artifact `.artifacts/cloudreach-0919/package-r1/`. The genuine existing 4.7 release
runtime was used as custom release template; export presets were restored exactly.
Terrain3D release DLL is present both beside the executable and at its runtime
relative path. No deployed build was overwritten.

- EXE SHA256: `A3E6B1CBD46AD153E7DFB24A5C0EE2B9187E0FB21FA7C0610FA8754BA5939D9C`.
- PCK SHA256: `51D56D55DDB30F766479645DF985E1E730E98FA4DDE1F99712E3ABCCD4BC94A8`.
- First launch at `shots/catalogue/cloudreach/grass-0919-package-r1` produced no
  frames/engine log and is not evidence. Launcher corrected to explicitly wait for
  the GUI process and collect its exit code. Retry deferred while Meadows owns lock.

Render/import/export and world smoke used the machine lock with cleanup. No other
session's lock was cleared. CI run 35457280112 is pending; no green claim.
Ledger stays **0 PASS / 9 POLISH / 3 FAIL**. Candidate has not been accepted or landed.
