# Handover — T2-BUILDPLACE, 2026-08-30

**Branch:** `ralph/T2-BUILDPLACE`, off `origin/main` at `a97f3e84`, with
`origin/ralph/T2-STRANDING` merged forward (fast-forward, per instruction —
merging a sibling branch was not refused this session).

**Commits pushed, oldest first:**
```
7988a903  the S03 build-placement failure is a RIG defect, not a GAME one (finding)
dfa91aa1  fix S03.json's build-placement RIG defect (Mira robustness + tool-equip)
cb3e8b56  reorder Mira before the catch loop; flag a severe GAME defect
bb48aeb3  tighten Mira's move_to_entity arrival radius
9275e3b4  revert Mira's walk to the original coordinate
6622815e  settle after arriving at Mira, plus a diagnostic probe
972b86c5  move Mira's visit back to its original position
3b6f4c93  tighten Mira's arrival tolerance to 1.2m
ec56e2b5  use move_to_entity for the Bryn-to-Mira walk (final)
967c7dc9  update finding with round-2 GAME defect; keep validation evidence
```
Read `ralph/reports/FINDING-T2-BUILDPLACE-2026-08-30.md` in full — it is
the primary document and carries both rounds of evidence in detail. This
handover summarizes it.

---

## 1. What I was asked, and where I actually got to

Asked: is the S03 build-placement failure (`S03-118`..`S03-204`: the
tutorial's analog-stick ghost placement never registers `home_built`/
`creature_bed_built_3` with `home_progress.gd`) a RIG defect or a GAME
defect? Then fix it, and prove it with a real S03 replay producing a
healthy exit save.

**Got to: a conclusive, live-engine-confirmed RIG verdict, a real fix for
it, and — while trying to prove the fix end to end — a second, more
severe, previously-undiscovered GAME defect, fully diagnosed and pushed
loudly ahead of any fix attempt, exactly as the brief asked.** What I did
not get to: a clean, fully-healthy `S03-exit.json` from a real full-segment
replay. Ten replay attempts converged on the root causes but not on a
100%-reliable walk to one specific NPC (Mira), for reasons detailed below
and in the finding doc's own "still open" section.

---

## 2. RIG or GAME — both answers, stated once, plainly

**The assigned question (S03-118..204, build placement): RIG.**
`build_menu.gd`/`build_placer.gd`/`home_progress.gd` all work correctly —
proven live by `tools/gate_f/probe_build_catalogue_arm_cause.gd`
(`PROBE PASS`): at zero materials, arming a piece correctly refuses and
reproduces the run's own exact observation (`input_context` stuck on
`build_catalogue`); with the piece's real cost granted, the identical
button sequence arms it, places it for real, and `home_progress.gd` sets
`home_built` the instant both required pieces stand. The actual cause is
two rig-side gaps: `S03.json`'s gathering loop never equips a tool before
gathering (wood/stone/fiber are all tool-gated, and carrying-without-
equipping yields zero by design — pinned by an existing passing unit
test), and its Mira interaction never reliably completed either.

**A defect found while proving the fix (not the assigned question, found
investigating it): GAME.** `scripts/combat/encounter_director.gd`'s
fainted-ally interaction override has no proximity gate and outranks
every other interaction in the world for the rest of a live session. See
§4 and the finding doc for the full chain. **This is a real, severe,
player-facing defect and I flagged it as its own commit the moment I
confirmed it, per the brief's instruction, ahead of attempting any
fix for it.**

---

## 3. Done and verified, vs done but incomplete, vs still open

**Done and verified (live-engine, this session):**
- The RIG verdict for the assigned question, `PROBE PASS`
  (`tools/gate_f/probe_build_catalogue_arm_cause.gd`).
- The gathering-loop tool-gating root cause: `harvest_logic.gd::gather()`
  and `tests/test_harvest.gd::test_gather_with_no_equipped_tool_is_refused`
  both confirm, by design, that carrying a tool un-equipped yields
  nothing; the real run's own kept `S03-exit.json` (0 wood/stone/fiber,
  5 berries — the one ungated resource) is the live proof.
- The exact `backpack_assign`/hotbar-bind sequence needed to equip
  axe/pickaxe/knife from the REAL S02-exit starting inventory, live-
  verified end to end including a real gather of each resource
  (`tools/gate_f/probe_tool_equip_sequence.gd`, `PROBE PASS`).
- The GAME defect in `encounter_director.gd`: live-confirmed via a real
  segment replay (`S03-53` FAILed with the live prompt reading exactly
  `"Ripplet is out of the fight."`) and via source reading
  (`interaction_offer()` L1037, `prompt_arbiter.gd`'s own "priority
  before distance always" rule). The `creature_recall` dismiss mitigation
  is also confirmed live: after adding it, the SAME blocking prompt never
  reappeared in any of the six subsequent replays — only a *different*,
  narrower problem (reaching Mira at all) remained.

**Done, pushed, sound in isolation, NOT proven via a full clean segment
replay:**
- `S03.json`'s fix as a whole. Every individual mechanism it relies on is
  independently proven (tool-equip sequence, catalogue arm+place chain,
  `creature_recall` dismiss all pass in isolated probes) but the full
  segment has not produced a healthy `S03-exit.json` because of the open
  item below.

**Still open, explicitly not resolved this session:**
- **Reaching Mira reliably.** Ten replays, several approaches tried
  (raw authored coordinate — which is in fact her exact configured spawn
  point; `move_to_entity` against her live position; tightening/loosening
  `close_enough`/`within`; a settle wait). Results were inconsistent run
  to run (0–120 held frames, 2.27m–4.9m short at arrival) because the
  catch loop's own RNG changes Bryn's outcome and therefore the player's
  exact starting point for this leg. A last diagnostic (a from-scratch
  raycast against `interactable.gd::_has_line_of_sight`'s own logic) is
  **not trustworthy as recorded** — it very likely hit Mira's own
  collision body rather than a real wall, because it did not replicate
  the two clearance trims the real function applies. I deleted that probe
  rather than commit unreliable evidence. The finding doc's own "still
  open" section names the exact next diagnostic step (replicate
  `_has_line_of_sight`'s clearance constants exactly, or add temporary
  logging inside `interaction_offer()` itself).
- **The GAME defect itself** (`encounter_director.gd`'s unconditional
  fainted-ally override) — deliberately not fixed, per file ownership
  (`scripts/combat/**` is T3-TYPECHART's, actively being edited).
- A secondary, much smaller RIG defect noted in passing: `S03-181`
  ("focus Creature Bed") independently FAILs — `1 x ui_right did not move
  focus off` the first cell in the furniture category's grid — not the
  cause of anything in this finding, sidestepped rather than fixed.

---

## 4. What I learned that is not visible in the diff

### The build-placement question had a clean answer; proving it end to end did not

The assigned RIG-vs-GAME question resolved quickly and conclusively once
I read the actual save contents (per the brief's own method): the run's
kept `S03-exit.json` had zero wood/stone/fiber and `placed_buildings: []`
— not "insufficient," genuinely none — which pointed straight at the
gathering loop's missing tool-equip step. Proving the FIX, however,
required a real continuous segment replay, and continuous replay is where
the second defect lives: it only manifests across many steps in a single
live session (a fainted creature from the catch loop poisoning everything
downstream), which is exactly the shape neither an isolated probe nor a
fresh-load probe would ever surface. `probe_mira_intro_grant.gd` (round 1)
tested this exact scenario with a fainted party and got a clean pass —
because it directly set `fainted=true` on a party object without ever
deploying that creature through `encounter_director.gd`'s own tracked
`_ally` reference. The real bug lives in state EncounterDirector caches
itself, separate from party data, and only a probe that goes through the
same summon/faint path the real game uses will see it. This is worth
naming as a general caution for this codebase: a probe that sets state
directly on a data object can silently miss a bug that lives in a
different system's own cached copy of that same fact.

### One defect masquerading as several

Every one of this session's dead ends traced back to the SAME root
mechanism once diagnosed: `encounter_director.gd`'s blanket interaction
override. "Mira's dialogue never completes," "the shop's steps run into
nothing," "the walk-to-Mira prompt reads wrong" all looked like
independent bugs before the pattern was clear. The STRANDING lane's own
finding (fainted ally blocks `can_challenge()`) and this one (fainted
ally blocks `interaction_offer()` generally) are the SAME underlying
state (`_ally`/`_ally_body`) read by two different gates in the same
file, and I did not connect them until reading `interaction_offer()`'s
full body rather than just the branch the trainer-challenge chain uses.

### Iteration cost on a positioning bug can run away from you

I spent ten full segment replays (each several minutes of real wall
time) on the walk-to-Mira issue, tuning `close_enough`/`within` and
switching between `move_to`/`move_to_entity` reactively to each new
result rather than stopping to get a cheap, direct diagnostic (a live
raycast probe) earlier. The one I eventually wrote arrived too late in
the session to build correctly (missing the real function's clearance
trims) and I did not have budget left to fix and rerun it. The lesson for
whoever picks this up: a cheap, targeted probe against the exact game
function in question (not a hand-rolled approximation of it) should come
BEFORE the third or fourth full-segment-replay iteration on a
positioning problem, not after the tenth.

---

## 5. Disagreements, or things worth owner/coordinator attention

1. **The GAME defect found here is, I believe, more severe than the
   South Bridge stranding it superficially resembles.** The stranding
   blocked trainer battles specifically and had a documented recovery
   path (creature beds, already built by the tutorial). This defect
   blocks EVERY interaction in the world — catching a replacement
   creature included — with no recovery path reachable through ordinary
   play once it triggers. I want this in front of whoever prioritizes
   Track 2 work next, explicitly, not folded into "another `_ally`-
   related issue."
2. **I do not think the "still open" Mira-approach item should block
   landing this branch's other fixes.** The build-placement RIG verdict
   and its fix stand on their own live-engine proof, independent of
   whether a full segment replay ever goes fully green — the same way
   the T2-STRANDING lane's own fix landed before its own full-chain
   re-run could happen, for a structurally identical reason (a different
   pre-existing bug blocking the full replay). I flagged this precedent
   to myself deliberately rather than holding useful, proven work hostage
   to an unrelated flaky walk.
3. **I disagree with my own earlier instinct (round 1) that the Mira
   grant issue was purely about `move_to` vs `move_to_entity`.** I said
   as much explicitly in the first finding pass and it was wrong in a
   more interesting way than I expected — the real defect was the
   fainted-ally lockout, and the walk mechanics turned out to be a real,
   separate, second problem underneath it. Worth remembering: fixing the
   first plausible cause a probe finds does not mean the investigation is
   over.

---

## 6. File footprint

**Touched, committed, pushed:**
- `tools/gate_f/segments/S03.json` — the fix: Mira's interaction upgraded
  to `move_to_entity`/`interact_with`/`advance_dialogue_until_closed`
  with an explicit flag assertion; a `creature_recall` dismiss after the
  catch loop; a Satchel `backpack_assign` sequence binding axe/pickaxe/
  knife to hotbar 2/3/4; a hotbar-switch press before each gather node
  whose resource differs from what's currently equipped (16 insertions);
  several `note` steps recording the investigation inline for the next
  reader. No pre-existing step's `id` was reused or removed except the
  original Mira block, which was rewritten in place.
- `tools/gate_f/probe_build_catalogue_arm_cause.gd` (+ `.uid`) — new,
  live-engine probe proving the catalogue-driven arm+place chain.
- `tools/gate_f/probe_mira_intro_grant.gd` (+ `.uid`) — new, round-1
  probe (superseded in its conclusions by round 2, kept as-is since its
  own result — the fainted party is not what blocks Mira — is still
  correct and useful).
- `tools/gate_f/probe_tool_equip_sequence.gd` (+ `.uid`) — new, live-
  engine probe proving the hotbar-bind sequence and a real gather of
  each resource.
- `tools/gate_f/probe_mira_position_check.gd` (+ `.uid`) — new, small
  diagnostic probe (teleport-based); its own result is a true positive
  (Mira's greeting DOES win at the tested point) but turned out not to be
  representative of the real walker's actual stop points.
- `ralph/reports/FINDING-T2-BUILDPLACE-2026-08-30.md` — the finding,
  pushed ahead of the fix per instruction, then updated with the round-2
  discovery. Read it in full.
- `ralph/reports/gate-f-buildplace-validation/` — kept as evidence: the
  seed (`S02/saves/S02-exit.json`, copied from the original run) and the
  last (10th) attempt's full output (notes, telemetry, INVENTORY.json,
  INCOMPLETE.md). Earlier attempts' outputs were overwritten in place
  (not superseded-renamed) since this is an ad hoc validation run, not a
  canonical Gate F run under that protocol's own restart-protection rule.
- `ralph/reports/handover-T2-BUILDPLACE-2026-08-30.md` — this file.

**Not touched:** `scripts/combat/encounter_director.gd` (read extensively,
not edited — explicitly out of ownership and the defect found there is
not fixed by this lane); `scripts/build/**`, `home_progress.gd` (read,
confirmed correct, not edited — nothing there was broken);
`tools/gate_f/operator_harness.gd` (read to understand `move_to_entity`/
`interact_with`/`advance_dialogue_until_closed`/`open_menu`/
`backpack_assign` semantics, not edited); the global
`ralph/reports/gate-f-candidate/RUN_METADATA.json` (read, confirmed
stale, NOT edited — a local `RUN_METADATA.json` was written inside my own
scratch run directory instead, per the same reasoning T2-STRANDING's own
handover already recorded: this file is shared and outside this lane's
ownership).

**Deleted, not committed:** `tools/gate_f/probe_mira_los_check.gd` — the
last diagnostic probe, written and run once, found to be unreliable
(likely hitting Mira's own collision body rather than real geometry, for
not replicating `_has_line_of_sight`'s clearance trims), and removed
rather than committed as if it were trustworthy evidence.

---

## 7. Exact commands, and what I'd do next

**To re-run the three solid probes** (fast, ~1-2 minutes each):
```
godot --headless --path . --script tools/gate_f/probe_build_catalogue_arm_cause.gd
godot --headless --path . --script tools/gate_f/probe_mira_intro_grant.gd
godot --headless --path . --script tools/gate_f/probe_tool_equip_sequence.gd
```
All three should `PROBE PASS`.

**To re-attempt a full S03 replay** (several minutes; needs a scratch run
dir seeded with a real `S02-exit.json` and a local `RUN_METADATA.json`
declaring a plain headless `display_server` — see
`ralph/reports/gate-f-buildplace-validation/RUN_METADATA.json` for the
exact shape needed to satisfy the harness's own capture pre-flight):
```
tools/gate_f/run_segment.sh --run-dir ralph/reports/gate-f-buildplace-validation S03
```

**What I'd do next, in order:**
1. Fix the Mira-approach positioning properly: either replicate
   `interactable.gd::_has_line_of_sight`'s exact clearance-trimmed
   raycast in a probe, or add temporary debug prints inside
   `interaction_offer()` itself (radius check vs. line-of-sight check,
   which one is refusing, at the walker's real stop point) and read the
   answer directly from a live replay rather than guessing at tolerances
   again.
2. Once that converges, re-run the full S03 replay and confirm
   `S03-exit.json` shows the party creature not fainted (the T2-STRANDING
   fix's own bed-rest steps, `S03-205a`..`e`, are already on this branch
   and should complete once a bed actually gets built) — that closes the
   loop this task opened.
3. Route the `encounter_director.gd` finding to whoever owns it now
   (T3-TYPECHART per my brief) — I deliberately did not implement a fix.
   My own read of the smallest safe shape: gate the fainted-ally
   statement in `interaction_offer()` behind the SAME kind of proximity
   check `_engageable()` already uses, or at minimum make it lose to any
   real nearby offer rather than substituting for one — I have not
   verified this is safe against the ~8+ call sites the STRANDING
   finding already catalogued reading `can_challenge()`/`_ally`, so
   treat it as a starting hypothesis, not a reviewed patch.
4. A real, canonical Gate F S03 run (not this ad hoc validation
   directory) is still what actually produces evidence anyone downstream
   should treat as authoritative; this session's own validation directory
   is explicitly scratch, kept only as a record of what was tried.
