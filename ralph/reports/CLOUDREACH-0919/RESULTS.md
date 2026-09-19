# Cloudreach 0919 — grass production results

Status: **window closed with a rejected/mixed candidate, not completed visual
production**. Candidate 89c176fd is isolated on draft PR #129, not merged.
See CANDIDATE-R1.md for the independent 32-frame comparison and retained contact
sheet. No location promotion. Packaged parity and motion remain unverified;
CI is not green. Earlier checkpoint entries below are history.

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

## Final window disposition

The matched source capture completed 16/16 at 1280x800, exit 0, no engine/script
errors. The code-blind reviewer inspected both full sets and references. Candidate
Y improved Summit clearly, Three Bells/Cliffhold slightly, tied four locations,
and regressed Observatory foreground crowding. Both visual bar answers were No.
See CANDIDATE-R1.md for exact findings, timing, pose parity and limitations.
**Do not merge this candidate or change a ledger grade.** No further endpoint,
count, clearance or unrelated-mechanism round was attempted merely to chase green.

Packaged attempt details: the existing release template's CLI does not offer the
source survey's override flags. Godot 4.7 `main/main.cpp` gates those overrides
under OVERRIDE_PATH_ENABLED; source capture is not release-runtime proof. A second
approach seeded only isolated `.artifacts/package-userdata-ui/` through real
`Game.save_game(0)` with the baseline Three Bells pose/clock. The seed succeeded,
with a verified isolated user directory (`seed-ui-r1.log`). The unchanged EXE/PCK
then launched under the lock via hidden Start-Process, PID 2128, but exposed no
targetable window to computer-use and an empty engine log. No Load action or
packaged screenshot occurred. Root stopped only that process after verifying its
full package path; launcher cleanup released the lock at 17:25:14 UTC. This does
not establish a broken shipping build: the hidden launch/automation path itself
was not resolved. It establishes **no packaged parity evidence** for this window.
The local movement probe was prepared but not executed; no motion/popping/FPS
acceptance claim. No source-scene image is relabelled as a shipping screenshot.

Additional existing environment test: 4 tests / 15 assertions / 0 failed, exit 0,
`environment-r1.log`; its existing unparented mesa test emits out-of-tree transform
diagnostics. No attempt to hide those diagnostics or broaden into other biomes.

CI run 35457280112 was superseded/cancelled after the results checkpoint push.
Run 35457436900 at a12af390 ran real code jobs. At final inspection, unit shards
1/3/4, harvest, terrain/scatter freshness, Gate B core and multiplayer shard 7
passed; unit shard 2 failed (928 tests / 70,139 assertions / 1 failed test).
Its log identifies `test_meadows_named_location_ledger_0912.gd::
test_final_polish_locations_have_complete_accepted_evidence_rounds`: missing
manifest/independent-review receipts for THE-RISE-IDENTITY-R33,
OLD-QUARRY-TERRACE-R55-DESKTOP-01, final-old-mill-63-desktop-01 and
final-warrens-62-desktop-01. These files/tests were not changed by this lane.
Other jobs were still running; no full-CI pass or landing claim. No retry was
requested and no Meadows evidence was invented to make this Cloudreach PR green.

Ledger delta: **none, 0 PASS / 9 POLISH / 3 FAIL**. No gameplay, content, assets
generated, or deployment. The report is a negative-result checkpoint for scope
review, with the source candidate retained for inspection. Another systemic
mechanism requires a revised plan under the existing owner approval contract.
