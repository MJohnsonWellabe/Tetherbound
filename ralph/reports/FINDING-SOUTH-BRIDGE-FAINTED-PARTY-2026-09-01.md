# FINDING — the "fainted party can't challenge the South Bridge grunt" blocker is already closed

**Task as handed in:** a Gate F audit (`ralph/reports/audit/GATE-F-FULL-2026-08-31.md`,
lines 33, 107-108, item TRAVERSAL-F8) recorded three runs stopping 12.6 m short
of the South Bridge because a fainted party cannot challenge the grunt
guarding it, so `south_bridge_open` never sets. Asked to find a genuine
recovery path (or add one) between the tournament and the bridge, and fix the
gate if it is refusing too strictly.

**Verdict: no game code or data change is needed. The mechanism already works
as designed, the two real bugs that put a party in that state are already
fixed and confirmed in real play, and the one thing genuinely missing — a CI
guard on the regression proof — is fixed by this branch.**

## The audit's own table already says this

`GATE-F-FULL-2026-08-31.md`'s finding index (§3) lists TRAVERSAL-F8 with
severity `—` and `fixed here?` = `n/a — the run's best positive result`. It is
not filed as a defect. The report's own §1 traces the stranding to **GAME-F4**
(a save-loaded creature silently losing species base stats, so the next
level-up crushes it to ~1 HP) and **GAME-F2** (the practice-fight level pin
deleted by a revert), both marked BLOCKER/SHIP and explicitly *not* about the
bridge, the gate, or rest.

## The stranding was investigated in depth, the same week, and closed as RIG

`ralph/reports/FINDING-T2-STRANDING-2026-08-30.md` — written the day before
the audit report this task quotes — reproduced the exact block live with
`tools/gate_f/probe_stranding_cause.gd` against a real fainted-party save and
found:

- `can_challenge()` and `summon_active_creature()` are both correctly
  refusing a fainted ally — working as designed, not a bug.
- **A real recovery path already exists on the route**: a creature bed heals
  a fainted creature to full (`heal_fully()`), and the probe shows healing
  the party's one creature is the *entire* difference between permanently
  blocked and immediately able to fight the grunt.
- **A real player is not stuck here.** The actual gap was that
  `tools/gate_f/segments/S03.json` — the Gate F test harness's own scripted
  playthrough — builds three creature beds and sleeps at home, but never
  once *assigns* the fainted creature to a bed first, so the sleep step
  healed nobody. That is a step-script gap, not a broken world.
- The fix (S03-205a..e, assigning the bed before the existing sleep step) was
  pushed with that finding and is already on `main`
  (`git log -- tools/gate_f/segments/S03.json`, most recently re-tuned in
  `04612b22`).

Separately, `trainer_npc.gd::_on_challenged()`'s only real secondary defect
that finding named — a fainted-ally refusal showing the trainer's `defeated`
line instead of an honest "nothing to fight with" line — is also already
fixed on `main` (`7490fc18`, "Fix GAME-0 fainted-ally interaction-offer
lockout and T1 trainer dialogue collapse", merged in `5c5f03ee`). Current
`scripts/world/trainer_npc.gd:181-189` shows the honest
`NO_USABLE_CREATURE_CONVERSATION` branch live.

## The recovery path this task was asked to check for or add already exists

`data/config/bands/band1_lower_meadows/props.json`'s `trail_camp` cluster
(`band1_trail_camp` in `map_landmarks.json`) sits at the corridor's own
midpoint between the pond and the South Bridge, and its `rest` block
(`scripts/world/rest_point.gd`) already offers:

- "Rest until morning" — `night_rest.gd`, the same heal/day-advance/autosave
  every built camp offers.
- **A working creature bed** (`bed_index: -11`), authored and built at world
  boot (`build_real(false)`) — no home construction required first. A player
  who arrives at the bridge with a fainted party can walk to this camp,
  bed one creature, sleep, and challenge the grunt with that one healed
  creature: `can_challenge()` only requires *one* usable ally
  (`encounter_director.gd:1830-1837`), not a fully healthy party.

This closes the two "what if" branches the task asked to check: the rest
point exists, is on the route, and mechanically heals (not just visually
dresses the camp) — this is a different, already-shipped fix
(`ralph/reports/REGION_AUDIT_2026-08-30.md`'s "camps are set dressing" gap),
not something this branch needed to add.

## The party-arrives-broken root causes are fixed and confirmed, not theoretical

Two later, independent capstone playthroughs (both merged to `main` via
`ralph/LAND-MEGA-0901`, after the audit this task cites) verified this in
real play, not by re-reading old reports:

- **CAP-1** (dropped starting Revives) — fixed, confirmed in
  `ralph/reports/gate-f-capstone-2/CAPSTONE_2_REPORT.md` §3.
- **CAP-2** (a living-but-damaged creature had nothing to heal it, so
  unhealed damage carried into the first village training fight and fainted
  the starter) — fixed, confirmed across **four independent fresh runs** in
  `ralph/reports/gate-f-capstone-3/CAPSTONE_3_REPORT.md` §3.1.

`ralph/START_HERE.md` (rewritten 2026-09-01, the current routing document)
already reflects this: it lists the South-Bridge-walled finding as a *prior*
run's result needing "re-verify against landed `main` before committing to a
full redo" — not a standing blocker to fix.

## What actually stops a full Gate F chain today

Per `CAPSTONE_3_REPORT.md` (2026-09-01, the most recent capstone run,
candidate `4ef01e40` — carries both CAP-1 and CAP-2): with both party-health
bugs fixed, the chain now stalls **earlier and for an unrelated reason** —
`tools/gate_f/segments/S03.json`'s own ten-attempt catch-retry loop only ever
lands its first attempt, so the team never reaches five and tournament
sign-up (which requires `min_party_size: 5`) never fires. That report's own
§7 recommends routing it to a Gate F instrumentation lane, explicitly *not* a
game-code fix lane — the same character as the original stranding. This
branch does not touch it; it is a separate, already-diagnosed piece of work.

## What this branch actually changes

Nothing in `scripts/`, `data/`, or `scenes/` — there was no game defect to
fix. The one real gap found: `tests/smoke_trainer_no_usable_ally.gd` (the
regression test proving the fainted-ally-refuses / heal-restores-challenge
behavior, written alongside the `T1-CAST` fix) existed on `main` but was
**never wired into any CI job**, so it has not actually run since the day it
proved the fix. `.github/workflows/ci.yml`'s `verify-gate-evidence-shard` now
runs it as a ninth step, alongside the other trainer/gate/camp evidence
already in that job.

## Recommended disposition

1. Do not reopen TRAVERSAL-F8 / the "12.6 m short" finding as a game defect —
   it was never one; the audit's own table already says so.
2. Land the CI wiring in this branch so `smoke_trainer_no_usable_ally.gd`
   actually guards this regression going forward.
3. The real remaining Gate F obstacle (S03's catch-loop harness stall,
   `FINDING-CAPSTONE3-S03-CATCH-LOOP-STALL-2026-09-01.md`) is separate,
   already-diagnosed, harness-only work — leave it to whatever lane picks
   that up; nothing here depends on it.
