# Lane W01-ROUTE-STRIP — the route strip must photograph the game, not empty scenery (Phase 0.1 / CL-H9 / task 2.15)

Branch: `ralph/W01-ROUTE-STRIP-0904`. Model tier: visual judgement + capture engineering.

**Why.** The most blocking item in the project. `tools/_capture_route_strip.gd` walks the authored spine and shoots landscape with nobody in it; Bar B (is this a creature game?) cannot be answered on such frames. Read `docs/FINISH_THE_MEADOWS.md` §0.1 in full, then `docs/VISUAL_PARITY_PROGRESS.md` "Route-strip investigation" and "Exact resume point" — Codex prototyped this, learned three things (three-subject framing, wait past CombatManager's 0.25 s input guard before the scripted flee, cleanup must run even when a capture assertion fails) and reverted. Start from those findings, not from zero. Do NOT rebuild the capture system: `tools/_capture_life.gd`, `tools/_capture_combat_moments.gd`, `tools/_capture_creature_roster.gd` already know how to stage a companion and a fight; borrow their code.

**Owns:** `tools/_capture_route_strip.gd`, `tools/capture_check.gd`, `tools/vp_capture_windows.ps1` (only if the strip's CLI changes), any new `tools/_probe_route_strip_*.gd`, `tests/test_capture_check.gd`, `tests/test_route_strip_*.gd` (new), and `ralph/reports/W01-ROUTE-STRIP-0904/`. Do not touch game scripts under `scripts/` or `autoload/`; if the game itself refuses to deploy a companion after a load (run 3's GAME-2), prove it with a probe and report it — that is a game defect for another lane.

**Done when:**
1. The strip deploys the player's real party companion (summon through the production path, not a spawned wild) before it walks, and every road frame contains trainer + companion.
2. At least one frame per band is taken inside a real `CombatManager` fight, framed so trainer, companion and opponent are all readable (camera distance solved against all three projected bounds).
3. A frame that fails a "creature present and readable" projection check (not merely "AABB technically on screen") is rejected and the strip reports it rather than saving it; `capture_check.gd` gains that check with a real test that is seen to fail on an empty frame.
4. Fight cleanup (flee/exit) is unconditional, runs after the input guard, and leaves the world in the `world` input context so the walk continues.
5. A bounded run (`--bands=1 --max=3` or the script's equivalent) under xvfb produces the frames; you inspect them; a code-blind judge (Agent tool, `opus`) is handed the strip sheet and `docs/reference/` and answers the two bar questions — record the verdict verbatim in the report. You are not graded on the bars; you are graded on whether the frames finally contain the subjects.

Commit one `_sheet_route_strip.png` contact sheet (use `tools/contact_sheet.gd` or equivalent) and the judge transcript. Update `docs/CURRENT_STATE.md`'s 2.15 / CL-H9 rows and `docs/VISUAL_PARITY_PROGRESS.md`'s resume point to reflect what landed.
