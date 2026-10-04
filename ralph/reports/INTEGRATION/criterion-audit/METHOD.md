# Acceptance audit brief (read-only)

Repository: /home/user/Tetherbound (Godot 4.7 co-op creature RPG "Tetherbound").
AUDIT TARGET = commit b4e4897d5, the consolidated branch that is about to become main. Read files only with
`git -C /home/user/Tetherbound show b4e4897d5:<path>`, search with `git -C /home/user/Tetherbound grep -n <pattern> b4e4897d5 -- <paths>`, and diff with `git -C /home/user/Tetherbound diff <old>..b4e4897d5 -- <paths>`.
NEVER check out, modify, commit, push, or run Godot. Do not touch any working tree.

## Sources
- Criteria text:
  - docs/ACCEPTANCE.md: §6.1 has the F01–F15 rows and §6.2 has the F16–F49 rows. Each row lists criteria #0..#n.
  - CODEX_START_HERE.md: "### Fxx" work orders, with Owns / Depends on / Acceptance.
- Owner decisions RD-01..RD-37 (CODEX_START_HERE.md) and CLAUDE.md hard rules. Use these to spot superseded criteria.
- Prior evidence (a baseline only, NOT proof):
  - ralph/reports/INTEGRATION/criterion-closeout/criteria-evidence-map.json, recorded 2026-10-02 on source 582b2f13;
  - ralph/reports/** per-feature evidence;
  - docs/STATE.md, which may be stale.
- Tests: tests/test_*.gd (unit), tests/smoke_*.gd (engine), tests/smoke_net_*.gd (co-op). CI wiring is in .github/workflows/ci.yml.

## Labels (exactly one per criterion)
- CURRENT: an automated test that exists at b4e4897d5 and runs in CI (named in ci.yml, or discovered by its unit/net glob) directly asserts the criterion. That test path is still gated. Name the test. Do not use CURRENT for visual-judge, earned-playthrough or device criteria.
- STALE: evidence exists, but the code it exercised has changed materially since that evidence's commit. Check with `git diff <evidence_sha>..b4e4897d5 --stat -- <exercised paths>`. Visual or judge verdicts are STALE if any renderer, VFX, world-art, HUD or scene path in their scope changed. Earned or playthrough evidence is STALE if any save, progression, route or quest path in scope changed. Give the re-proof action: the test to re-run, or the capture plus judge to redo.
- MISSING: there is no test or witness for the criterion. Say what proof must be built: a unit test, an engine smoke, a net smoke, a capture plus code-blind judge, or a frame-time capture.
- BLOCKED_OWNER: only the owner can close it, e.g. the ROG Ally device test, an owner play pass, or an owner decision. New Meshy meshes go to a Codex lane: label those BLOCKED_OWNER with "Codex Meshy" in the action.
- SUPERSEDED: a later owner decision (cite its RD-xx or dated owner directive) replaced the criterion. Give the citation.
- OFF: the source exists but the feature ships switched off by config. Name the flag and its value at b4e4897d5. Add what would be needed to switch it on.

For F01–F16 criteria that are STALE or MISSING, also name the redesign row F16–F49 that owns that area now ("folds into").

## Output
Write ONE markdown file to the output path you are given. It contains a table with these columns:
`F# | # | criterion (≤15 words) | label | evidence (path@sha or test) | reason (≤25 words) | action (≤25 words) | folds into`

After the table, write a short "Feature summary" section with one line per feature. Each line gives the count of each label, and a verdict: DONE (all CURRENT or SUPERSEDED), PROVE (only re-runs needed), BUILD (proof or feature work needed), or OWNER.

Be factual: write "unknown" rather than guess. Keep your final chat reply to 3 lines: the output path, and your label totals.
