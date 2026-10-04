# F26 Ally harness implementation review

Verdict: **PASS, implementation only**. Separate read-only reviewer
`/root/f26_lookbar_review`, 2026-10-04. No native run or F26#5 acceptance.

Reviewed `tools/owner/f26_ally.ps1`, `F26_ALLY.cmd` and `ALLY_CHECKLIST.md`
against the existing production capture script, route config and F26#5.
Inspected PowerShell harness SHA-256:
`a2f4ac0089c30033b72e858aa74f10b44a176c1a07517911921daff3838ca89d`.

- Windows PowerShell 5.1 parser: zero errors. Independent real `-VerifyOnly`
  fixtures: correct hashes PASS; altered PCK, missing CMD and parent-directory
  escape all refused. Fixture bytes only; no game launched.
- Source/route hash, all waypoints, Medium/Forward+, Windows display, adapter,
  1080p, sample count and finite-positive timings are required. Raw receipts,
  stdout/stderr and start/end PNGs are hashed and retained.
- Mean/P95 target check is scoped to these four F26 routes. P99 and hitches are
  reported. `OWNER_REVIEW_REQUIRED` leaves actual Ally identity, 15 W, visible
  faults and acceptance open; no release endurance claim.
- Timeout and final cleanup terminate only the owned wrapper tree. Device
  environment and serial mutex are restored. No source blocker remains.
- Exported SceneTree script is structurally feasible. The exact packaged-script
  load still needs its own export smoke check before any delivery claim.

Initial reviewer backslash findings were withdrawn after examining actual source
characters and executing the harness; they were misreadings of escaped tool
output. Explicit platform separators remain for clarity.

Author also ran 19 focused receipt cases in Windows PowerShell
`5.1.19041.6456`: a valid route and interpolated percentile passed; incomplete,
wrong-source/config/biome/preset/renderer/display/resolution, absent adapter,
unreached waypoints, too few frames and NaN/infinite/zero samples were refused;
slow timings did not meet the target. Four package-integrity cases passed.
Local check inputs: `D:/tetherbound/.artifacts/check_f26_owner.ps1` and
`D:/tetherbound/.artifacts/check_f26_package_integrity.py`.

Owner hardware result, exported native route, full visual matrices and all other
open F26 criteria remain unproven. Compatibility remains the authored default.

## Release-package correction

The actual release preset provides a GUI EXE without a console wrapper. The
launcher now uses `Tetherbound.exe`, an explicit `--log-file "<path>"` argument
pair and a visible interactive measurement window. Native errors are checked in
engine log plus stdout/stderr; all three are hashed. Mandatory EXE/PCK/CMD/PS1
entries appear exactly once in the manifest. No export-preset/default change.

Separate review of this correction: **PASS**, same read-only reviewer. One
intermediate `--log-file=<path>` CLI bug was found and fixed; latest reviewed
harness SHA-256:
`70f7b92dc754d598b2452b0acd5cfdedbb72dcefe6e81c700cff792a86659db5`.
Windows PowerShell 5.1 parser: zero errors. Reviewer independently ran five real
release integrity fixtures with no console wrapper: valid package PASS; modified
PCK, missing CMD, parent-directory escape and duplicate EXE all refused.
The prior 19 receipt checks remain passing. Bundle parity and actual exported
native runs remain separate; no owner result is established by source review.

## Embedded release entry

Official pinned release templates disable CLI script/path overrides. The owner
launcher now passes an exact `-- --f26-route` user argument. A small title entry
attaches the existing production capture script to its SceneTree after disabling
and detaching the unbuilt title; autoloads remain available. Normal title behavior
is unchanged when the flag is absent. Missing/invalid/custom-loop cases fail closed.

Independent scoped source review: **PASS**, same reviewer, 2026-10-04. An
intermediate queued-but-active title lifecycle gap was found and fixed before
commit. Reviewed bootstrap SHA-256:
`3a9899d20c9a899099d65a7bc2d54503c68b8e929fbc87678b80aa9263b91b59`.

Author source CPU checks: normal title exit 0, explicit route entry reaches the
expected headless refusal exit 2, both zero errors; focused front-door tests
5 / 29 assertions / zero failures. [Receipt](export-entry-source-preflight.json).
This proves source dispatch, not exported native behavior or Ally performance.
Actual release dispatch and packaged-route rendering still require their own
checks before owner delivery.

## Actual release CPU preflight

Clean source `925821adc22527d3251c53df757a56d251b007a2`: release export exit 0,
zero errors; actual packaged EXE reached the explicit route's intentional
headless refusal exit 2 in 4.94 s. Ordinary release startup without that flag
exited 0 with zero errors. Real package `-VerifyOnly` passed in Windows
PowerShell 5.1. The candidate archive passed CRC and all seven embedded manifest
SHA-256 comparisons. [Export receipt](ally-export-success.json),
[follow-up receipt](ally-export-followup.json).

These are author-executed CPU proofs, separate from the scoped independent
source review above. Native packaged routes, full visual bar and actual Ally
results remain open; the candidate has not been published as a development
download. Earlier failed attempts remain in `ally-export-preflight.json`.

## Far-floor package and desktop preflight

Owner GPU-free handoff resumes item 1 on integration `648643576` or later.
The desktop switch runs the same four packaged Medium routes without claiming
Ally identity or 15 W; it records `DESKTOP_PREFLIGHT_COMPLETE` separately from
the default owner gate. A desktop below-target result remains a reported
desktop measurement, rather than an Ally verdict.

Independent read-only implementation review by `/root/f26_lookbar_review`:
**PASS**, including its timing follow-up. Route-only uncapping disables VSync
and the software FPS cap; fixed FPS, disabled rendering, changed time scale
and non-60 Hz physics are refused. Receipts preserve those conditions and
the production camera far value; the harness checks the package's four
declared vista floors. Min/average/1% low formulas match the checklist.
Author's focused Windows PowerShell 5.1 checks: 28 receipt cases and five
actual package hash cases passed; [CPU receipt](uncapped-harness-preflight.json).
These checks do not prove fresh exported or native execution. Those remain
required before owner delivery; the owner Ally result remains separate.
