# Combat lane handoff — 2026-09-19

Owner requested wrap-up, push, and continuation elsewhere. Work is intentionally
unfinished. Do not mark the persistent goal or COMBAT-1 accepted.

- Checkout: `D:/tetherbound/combat-0919`.
- Branch: `ralph/combat-depth-0919`.
- Draft PR: https://github.com/MJohnsonWellabe/Tetherbound/pull/130
- Approved plan and approval: this directory's `PLAN.md` / `PLAN-APPROVED.md`.
- Detailed measurements and failure history: `RESULTS.md`.
- Highest completed rung: none accepted; COMBAT-1 verification/fixes underway.
  COMBAT-2/3 already contain substantial implementation, but have not passed this
  lane's ordered review. COMBAT-4–7 remain unimplemented by this lane.

## Delivered

Audited actual combat before planning; pushed plan and waited for approval. Fixed
zero-poise restagger loops on both sides, enemy cooldown closing, and physical
knockback accumulation (including the soft arena boundary). Added actual-input
MASHER/READER diagnostics, state-bound feedback and a charged camera nudge.

The final checkpoint also includes ground-conforming, body-clearing state rings
and a bounded camera correction: live visible widths influence shoulder clearance,
shoulder updates as the fight moves, while manual-look grace, throw/catch ownership,
room constraints and the existing 2.2m safety cap remain. These last presentation
changes have focused unit coverage but **no fresh native capture or full camera
smoke yet**. Close encounters can still exceed what that safety cap can separate.

Wrap-up selection: 46 tests, 144 assertions, zero failures;
`D:/tetherbound/combat-wrap-units.log`. Earlier broad combat selection: 167 tests,
611 assertions. Production combat smoke passed gameplay. Production playground
assertions passed in real-time mode, but the null-material runtime error and shutdown
leaks are retained limitations, not a clean engine log. See RESULTS for the failed
fixed-FPS attempt and corrected repeat.

Mira, 24 paired seeds after impulse correction: reader loses 2.59% lead HP versus
masher 23.99%; both win all runs. Wider two-seed diagnostics: 57 cases / 228 fights,
38 unmet criteria. This is not full statistical acceptance. Ordinary wild costs
and top-trainer punishment remain deficient. No thresholds were relaxed.

## Resume here

1. Read AGENTS/CLAUDE, the combat goal, approved PLAN and RESULTS. Fetch branch and
   inspect current PR CI. CI was queued at the last checked checkpoint; no green
   final CI claim has been made.
2. Capture the final ring/camera changes and run the camera smokes (ordinary,
   trainer and Stronghold), preserving manual look, switching and throw behavior.
   Compare actual participant visibility, not just whether centres are on screen.
3. Continue independent visual/motion review. Capture B and its blind verdict are
   valid observations of the earlier checkpoint, not the final presentation edits.
   Material/terrain-art findings belong to other lanes; combat readability is ours.
4. Complete COMBAT-1 evidence and review before advancing through COMBAT-2…7 in
   order. Final depth targets and owner hands-on feel review remain mandatory.

## Evidence and capture safety

Native capture B: `D:/tetherbound/combat-captures-0919-b`, 30 frames plus
`capture-report.json` and contact sheet. See `VISUAL-VERDICT-02.md`. Capture A is
diagnostic only: missing `current_scene` assignment left exploration HUD layers
visible. That harness defect is fixed. Current tool:
`tools/capture_combat_depth.gd -- --out=<absolute directory>`.

Before every capture/import/cache-writing run, check `D:/tetherbound/RENDER_LOCK.json`.
Meadows and Cloudreach outrank Combat. Claim only when free, verify immediately
before captures, and release only our claim in a finally path. Lock was checked
free at wrap-up. No capture process remains from this lane.

All raw logs/JSON/image payloads are outside git under `D:/tetherbound`; copy them
explicitly if the next environment is another machine. Source, reports, tests and
the capture tool are committed. Do not alter the dirty main source checkout or
other lanes. Persistent-goal tool still reported the old approval-wait `blocked`
status; do not mistake that stale scheduler state for a current missing approval.
