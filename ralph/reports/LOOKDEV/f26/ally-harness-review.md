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
