# COMBAT-0919 plan — approval pending

Date: 2026-09-19. Branch: `ralph/combat-depth-0919`.
Worktree: `D:\tetherbound\combat-0919`.
Audited base: `8990a743ce6d4126a0c826a0f66ae20ee81f953e` (`origin/main`).

## Approval boundary and authority

This checkpoint changes documentation only. No implementation, import, Godot run,
screenshot, balancing change, or acceptance promotion has been performed.
Hold implementation until `ralph/reports/COMBAT-0919/PLAN-APPROVED.md` appears
with the orchestrator's approval of this plan. Never create that approval ourselves.
Fetch/check the combat branch and main for the committed approval, and check this
worktree for a locally delivered file before proceeding. A missing file is a hold,
not implied permission. Read any restrictions in the approval before starting.

Read AGENTS.md, CLAUDE.md, docs/00_START_HERE.md, the latest available exit
handoff (2026-09-15), the September 12 Meadows-first directive, the September 19
lane-split and parallel-lanes directives, the combat goal, COMBAT_DEPTH_PLAN.md,
and AGENT_WORKFLOW.md. The current user request and September 19 combat goal
control scope: COMBAT-1 through COMBAT-7, in order. Burst Option B, level-based
skills and 1.5/0.67 type magnitudes are explicitly authorized by that goal;
older proposal text calling those decisions open does not reopen them.

## What actually exists at the audited revision

These are source findings, not fresh runtime passes or claims that a step is done.
The goal's warning to verify was necessary: its assertion that no combat code
changed is contradicted by current main.

| Step | Directly inspected evidence | Remaining verification/gap |
|---|---|---|
| COMBAT-1 | `scripts/combat/combat_manager.gd` contains `_take_player_poise_damage`, charged-into-telegraph interrupt in `_perform_player_strike`, one-use stagger crits and body-only hitstop. `scripts/creatures/wild_creature.gd` drains/regenerates poise and cancels telegraphs. `creature_body.gd` has pivot flinch and hitstop; `combat_hud.gd` has poise pips and stagger messaging. `combat.json` has poise 40, quiet delay 2s, stagger 0.6s, crit 1.5 and 30/70/120ms hitstop. Profile poise overrides exist in band data. Commit `dfb28289` introduced stagger feedback. | Re-run behavior tests and verify full strike/interrupt paths, telegraph colour, feedback and charged-only camera nudge. No two-pilot acceptance evidence yet. |
| COMBAT-2 | Manager has party-slot wind, costs, quiet regeneration, exhaustion and host-authoritative snapshots. `combat.json`: max 100, quick 12, charged 35, skill 24, burst 30, regen 18/s after 0.6s, exhausted wind-up 2x and power 0.6x. Species overrides and `creature_condition.json` combat_wind bonuses exist. HUD has ally wind. Commit `9c77c1e6` introduced authoritative Wind. | Verify species coverage/defaults, satiety/bond effects, switch/faint boundaries, host parity and intended UI coverage; no wind integration was found in party_strip.gd. |
| COMBAT-3 | Baseline enemy telegraph is already 0.8s. Manager `request_burst` requires READY and sufficient wind, normalizes stick direction and commits to BURST. Config specifies 3m/0.2s. Body motion and host action-stream support exist, with `test_combat_burst.gd` and `smoke_combat_burst.gd`. Commit `b92d2e5f` introduced the host-authoritative burst. | Verify actual pad A input, wall/arena collision, no action cancel/i-frames, and encounter-specific timing/power rather than assuming baseline config changes every profile. |
| COMBAT-4 | No learnset, move_skill or skill-slot move was found by searching scripts/data/tests. `progression.gd` contains XP/stat/bond arithmetic, not move learning. Skill wind cost is only a hook. | Implement skill execution, authored learnsets, progression/persistence/evolution/TMs and Team/HUD presentation after steps 1–3. |
| COMBAT-5 | `combat_ai.gd` is still a pure four-beat decide(state, distance, timer, cooldown, cfg) table with no player-wind-up or health input. Wild node still documents no charged AI. | Charged use/energy, reactions, profile health behavior and officer skills remain to build. |
| COMBAT-6 | `data/config/type_chart.json` still authors 1.25/0.8. VFX currently scales by damage fraction/body size and charged flag. | Widen authorized magnitudes, preserve matchup topology, explicitly scale effectiveness feedback and revalidate dual types, tournament and Warden. |
| COMBAT-7 | Existing trainers, profiles and dialogue provide the authoring surface; no acceptance of the seven teaching rows is established by this audit. | Audit/author only the specified early ladder after all prerequisites; verify each row through real encounters. |

`tests/smoke_combat_baseline.gd` remains a one-policy numeric simulator. Its
Action enum is only READY/WINDUP/RECOVERY; it does not model current wind,
poise, stagger or burst and has no READER. Reusing its old green result would
not measure the current game. Existing focused stagger/wind/burst tests are
useful starting points but have not been executed in this fresh worktree.

## Ordered work after approval

1. **COMBAT-1 first window: verify and complete, do not rewrite working code.**
   Run the existing stagger/math/AI/override tests. Exercise real manager/wild
   strike paths for player wind-up cancellation, charged interrupt, poise recovery,
   one-hit critical consumption, flinch and hitstop cleanup on faint/switch/end.
   Add the paired-pilot measurement foundation below and record the current
   integrated baseline. Repair only demonstrated COMBAT-1 gaps; finish its
   feedback review before declaring the rung accepted.
2. **COMBAT-2:** verify/complete wind semantics and UI, per-species tuning,
   satiety/fed/bond ties and hosted spend idempotency. Confirm walking stays free,
   exhausted attacks remain available, and switching cannot refill wind for free.
   Run paired measurements again; fix measured resource-rhythm gaps.
3. **COMBAT-3:** verify/complete the approved directional burst and telegraph
   retune through real input, movement and host verdicts. Confirm collision and
   cone resolution still decide safety. Measure the READER's spatial advantage.
4. **COMBAT-4:** add Y skill moves with geometry-changing effects (knockback,
   slow field, root, dash-strike and timed veil as specified), 8–12s cooldowns,
   wind spend and per-species level-4 learnsets. Connect learning/evolution/TM
   replacement, old-save defaults and catch/level initialization; show the next
   move in Team, a level-up announcement and first-fight Y hint. Preserve the
   existing quick/charged slots and energy rules. Verify ranged range feedback.
5. **COMBAT-5:** extend the pure AI's inputs while retaining four beats; build
   opponent energy/charged telegraphs, allowed wind-up reactions, WALL/DIVER/
   CURRENT low-health profiles and officer-plus skill use. Ordinary wilds do
   not gain trainer reaction behavior. Test deterministic decisions and live
   manager/host execution, including warning timing and damage caps.
6. **COMBAT-6:** change chart magnitude to 1.5/0.67, keep graph topology,
   implement effectiveness-based VFX and test dual-type multiplication/caps.
   Rebalance only from paired and actual tournament/Warden results; never hide
   difficulty regressions by weakening assertions.
7. **COMBAT-7:** author existing encounter dialogue/profiles only: Practice
   Meadow recovery lesson, Band 1 tell, level-4 skill lesson, Mira CURRENT wind
   lesson, round-2 type switch, Oskar ACE interrupt/1.2s stagger, South Bridge
   charged application. If a required teaching behavior lacks a code hook,
   report the prerequisite gap against its earlier rung rather than silently
   adding a new mechanic to this content-only step.

Treat each rung as a separate reviewable checkpoint/PR on its predecessor.
Do not advance on source presence alone. Record any partially met criterion
explicitly; no later rung substitutes for an earlier failure.

## Two-pilot measurement and tests

Extend the named baseline harness with MASHER and READER policies using the
production combat behavior. Avoid a second rules engine: drive actual manager,
wild and body paths in a lightweight fixture; if a fast simulation is retained,
require parity traces against those paths for interruption, resource spend,
strike timing and movement before trusting it. Harness work begins only after
approval and stays bounded to combat; no new full Gate F campaign.

Use the same entry-level roster, encounters, conditions and paired deterministic
seeds (24 per row initially, 48 for the acceptance checkpoint). MASHER closes,
quicks on cooldown, charges when full and never dodges. READER reads telegraphs,
steps out, punishes recovery, commits charged interrupts when feasible, maintains
25% wind and uses unlocked skills. Prior-rung measurements cannot require a skill
that is not implemented yet. Record seed, pilot, lead/party HP cost, win/loss,
duration, landed/missed hits, interruptions, exhaustion and skill/burst use.
Exercise ordinary wilds, floor and top trainers per band, plus the early ladder.

Final §7 targets, stored in chapter_curve.json difficulty and asserted:

- Floor trainer: READER lead HP cost <=55% of MASHER cost; the floor must not wall five.
- Top trainer: MASHER loses the lead every seed; Band 3+ loses all five >=25%.
- Top trainer: READER wins >=75%.
- Ordinary wild: MASHER still wins and pays >=25% lead HP.
- Any single hit: <50% of full-health entry-level HP.

Record per-rung deltas and failures honestly. An identical pilot outcome fails
the depth claim. Final targets stay visible throughout; unmet later-dependent
criteria are not presented as early-rung passes. Automated results establish
decision space, not subjective fun.

Initial focused command (Godot executable is the installed 4.7 console binary):

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=combat_stagger,combat_wind,combat_burst,combat_math,combat_ai,encounter_combat_override
```

Then run smoke_combat, smoke_combat_burst and the upgraded
smoke_combat_baseline with paired seeds. Add real input/HUD and hosted-action
regressions for changed paths. For steps 4–6 add progression/TM/save/type/VFX
coverage, smoke_tournament_bracket, smoke_tournament_heal, smoke_tournament_consent
and smoke_boss (the existing Warden smoke). Run smoke_art for creature data,
smoke_playground for creature/encounter changes, and the full suite for
save/autoload changes. Review every ERROR line and first-attempt outcome.
Use PR CI for the full relevant checks; docs-only CI is not combat validation.

## Render lock and evidence

Before every capture, import or other cache-writing Godot launch, read
`D:\tetherbound\RENDER_LOCK.json`. At audit time it was held by `meadows`.
No capture or lock mutation was performed. Meadows and Cloudreach outrank
Combat; Combat outranks the survey. If occupied, do read-only/source work and
recheck later. Do not bypass the machine-wide lock with a separate worktree.

When available and higher-priority work is clear, claim as `combat` with a UTC
timestamp and re-read ownership before launching. Release only our lock in a
finally path on success, crash or abort. Reclaim an old lock only under the
stated >2h/no-new-output abandonment rule, with a recorded reason. Cold import
of this new worktree also needs the lock. Already-imported read-only headless
unit tests may run concurrently; serialize memory-heavy world smokes.

Never combine --headless with a rendering driver. Capture fresh production
combat evidence for changed HUD/telegraph/flinch/skill/VFX, sanity-check against
the shipping path, and obtain independent code-blind review per the repo's
visual-judge workflow. Still frames alone cannot prove hitstop; include timing
traces/motion evidence. Commit verdicts/references, not bulk payloads.

## Scope, checkpoints and stop conditions

No Meadows exploration/visual content changes outside the explicit COMBAT-7
encounters; no Cloudreach/Stormwood/Water building, new meshes, shields, human
weapons, held inputs, extra opponent, long combos, separate battle scene,
catching redesign or sixth creature. Shared combat changes must preserve hosted
behavior without reopening biome content lanes. Leave other worktrees untouched.

Write `ralph/reports/COMBAT-0919/RESULTS.md` after approval as work progresses:
base/head SHA, rung, changed behavior, exact test commands/counts and first-run
failures, paired measurements, capture/verdict references, remaining gaps and
next rung. Exact-stage files, push branch checkpoints, open draft PRs for code
CI, and verify reviewed landings. Stop for unresolved material design choices,
approval restrictions or two unsuccessful attempts at the same mechanism;
report evidence and change approach, never promote a ledger by assertion.
