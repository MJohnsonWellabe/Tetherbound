# Combat 2026-09-19 plan — approved

Reviewed against `docs/CODEX_GOAL_2026-09-19_COMBAT_DEPTH_LANE.md` and
`docs/specs/COMBAT_DEPTH_PLAN.md`:

- The plan correctly did not trust the goal doc's claim that no combat code
  had changed — it audited `combat_manager.gd`, `wild_creature.gd`,
  `creature_body.gd`, `combat_hud.gd`, `combat.json`, and `combat_ai.gd`
  directly, citing specific functions, config values, and commit hashes
  (`dfb28289`, `9c77c1e6`, `b92d2e5f`). Finding: COMBAT-1 (poise/stagger/
  hitstop), COMBAT-2 (wind), and COMBAT-3 (burst/telegraph retune) are
  already substantially built; COMBAT-4 through 7 are not. This is exactly
  the right response to a stale briefing — verify against source, don't
  rebuild what already exists or assume gaps that aren't there.
- Sequencing (verify/complete 1 before 2, 2 before 3, etc.; each rung a
  separate reviewable checkpoint) matches `COMBAT_DEPTH_PLAN.md` §8.
- Correctly treats Option B (burst), level-based learnsets, and the 1.5/0.67
  type-chart widening as already-decided by the goal doc, not reopening
  `COMBAT_DEPTH_PLAN.md` §9's items as if still unresolved.
- Two-pilot (MASHER/READER) measurement plan matches §7's targets exactly,
  and correctly refuses to reuse the old single-policy `smoke_combat_baseline.gd`
  as-is since it doesn't model current wind/poise/stagger/burst.
- Render-lock handling is correct: checked current state (held by Meadows at
  audit time), correct priority ordering (Meadows/Cloudreach above Combat,
  Combat above the survey lane).
- Scope exclusions (no Meadows/Cloudreach/Stormwood/Water changes, no shields/
  human weapons/held inputs/extra opponent/combos/new battle scene/catching
  redesign/sixth creature) are complete and correctly cited.

Proceed with the ordered work in `PLAN.md`, starting with COMBAT-1
verification. Treat each rung as its own checkpoint — don't advance past one
on source presence alone, and report a partially-met criterion honestly rather
than folding it into the next rung's claim. Update `RESULTS.md` as each rung
completes; a mid-window update per rung is expected, not just one at the end.
