# Gate F Capstone 3 — run report

**Branch:** `ralph/GATE-F-CAPSTONE-3` · **Candidate:** `4ef01e4063a11ea0b30035d4ccab5ec8b2be0b9c`
(origin/main HEAD at run start; carries both the CAP-1 fix and the CAP-2 fix)
**Run directory:** `ralph/reports/gate-f-run-20260831T223853Z/`
**Operator:** agent, tester role. **No game code, data or config was changed**
(`GATE_F_MASTER_PROTOCOL.md` §J / `GATE_F_PROTOCOL.md` §13).
**Outcome:** the chapter **still cannot be completed on this candidate**, but
for a different reason than CAP-1 or CAP-2. Halted after S04 by operator
decision.

---

## 1. Result in one line

**CAP-1 and CAP-2 are both confirmed fixed, in real play, four times over** —
and the chapter still cannot proceed past the village, because
`tools/gate_f/segments/S03.json`'s own catch-retry loop stalls after its
first attempt in every run, so the team never reaches the tournament's
required five and sign-up never takes. This reads as a **harness defect**
(Gate F instrumentation), not a new game defect — see §4.

---

## 2. Segment ledger

| segment | P | F | SKIP | complete | note |
|---|---|---|---|---|---|
| S01 Boot & front door | 13 | 0 | 0 | ✅ | clean, re-run fresh (not inherited) |
| S02 Opening | 77 | 4 | 0 | ✅ | **CAP-1 + CAP-2 both verified fixed**, third fresh attempt (see §3) |
| S03 Village ladder | 315 | 29 | 9 | ❌ | catch-loop stall, fourth fresh attempt kept for the chain |
| S04 Tournament | 53 | 18 | 0 | ✅ | sign-up correctly refused; all inherited from the S03 stall |
| S05–S10e | — | — | — | not run | halted; see §5 |

Totals for what ran: **458 PASS · 51 FAIL · 9 SKIP** across 4 segments,
roughly 2 h 8 m of harness wall time (this run also spent time on 3
superseded S02 attempts and 3 superseded S03 attempts establishing
reproducibility — see `RESTARTS.md` and the two finding docs).

---

## 3. A methodology correction, recorded because it nearly produced a false
## re-diagnosis of CAP-2

The task briefing's own recommended entry save — `S02-exit.json` fetched
from `ralph/GATE-F-CAPSTONE-2`'s run directory — turned out to be
**contaminated**: it was produced by CAPSTONE-2's own S02 run at candidate
`679f990c`, which carried the CAP-1 fix but **not** the CAP-2 fix (that
landed afterward as `4ef01e40`). Its inventory was `{orb_basic: 12,
revive: 2}` — no `potion_small`, no `berries`. Seeding S03 from it
reproduced CAP-2's exact wall (315 PASS / 29 FAIL / 9 SKIP, identical to
the pre-fix capstone-2 numbers) for the identical reason — not because
CAP-2 regressed, but because a save is a frozen snapshot and does not
retroactively gain items a later data-file fix would have given it.

Caught by inspecting the save's own inventory before trusting the
briefing's "downstream of S02's own completion" reasoning, which assumed the
save was produced under the fixed candidate. It was not. Full account in
`RESTARTS.md` in the run directory. **Re-ran S01 and S02 fresh** (production
title → New Game → opening beats) at the actual candidate instead, which is
what produced the real evidence in §3.1 below.

### 3.1 CAP-1 and CAP-2, verified in real play, across four fresh S02 runs

| | CAP-2's own pre-fix run | this run, S02 (kept) |
|---|---|---|
| starter HP entering S03's first fight | 53.0/117.6 | 110.3/117.6 |
| inventory after S02 | `orb_basic ×12, revive ×2` | `orb_basic ×13, potion_small ×3, berries ×5, revive ×2` |
| party after S02 | 2 (starter + 1 catch) | 2 (starter + 1 catch) |

Both fixes are present and doing their job in every one of the four fresh
S02 attempts this run made (three of which are superseded, kept as evidence
of the S02 catch-throw's own genuine RNG variance — see §4.1 below, not a
defect).

---

## 4. What actually stops the chapter now: S03's catch-loop stalls at 2

Full write-up with reproduction across four independent runs:
**`ralph/reports/FINDING-CAPSTONE3-S03-CATCH-LOOP-STALL-2026-09-01.md`**

`tournament_build_team`'s own objective text is *"Catch and raise a team for
the village tournament"*, and S03's own step-script scripts exactly that: ten
numbered catch attempts (`S03-32a`..`S03-32j`). In **all four** fresh S03
runs, only attempt "a" ever completed a throw. Attempts `b`-`j` FAILed at
"challenge it" every time, for a consistent, specific reason: the previous
fight/catch had not finished resolving (`input_context` still `combat`), or
the fixed-coordinate walk returned to the same already-resolved individual
(the live prompt read "Put Moss away" or "X is out of the fight", never
"Engage"). Team size stayed at 2 in all four runs regardless of how the
combat itself went (which varied genuinely — see §4.1).

This reads as a **harness retry-pacing/targeting bug** in
`tools/gate_f/segments/S03.json`'s own catch loop — not a game defect — for
three reasons: the failure is about the scripted retry's pacing and
targeting, not wild-creature availability; a real player would naturally
walk toward a *different* visible wild after resolving one, not return to a
fixed coordinate; and the FAIL text names the mechanism precisely enough to
fix without touching any gameplay system (wait for combat to fully close;
exclude already-resolved entities from the next `refresh_pois`).

A second, independently reproduced shortfall: **materials gathering came up
short of the build threshold in all four runs** (fiber: 0 against a required
18; stone: 8 against a required 8, the segment's own documented one-node-wide
margin), so `home_materials_gathered`/`home_built`/`creature_bed_built` never
set — no individual gather `move_to` step ever failed, so this is a shortfall
in what was collected, not in reaching the nodes. Not independently isolated
from the catch-loop's own effects here; plausibly related to the same
scripting fragility (`tools/gate_f/segments/S03.json`'s own inline comments
already flag "why the tools need binding by hand" as a known area).

### 4.1 What's genuine variance, recorded so it isn't mistaken for the same defect

Combat outcomes varied meaningfully run to run — how much HP each fight
costs, whether a creature faints outright, whether both Revives get spent —
exactly the shape of RNG variance the S02 catch-throw investigation
established (three fresh S02 attempts: attempt 1 and 2 missed all three
throws entirely — different trajectories, both missed; attempt 3 landed on
the third try). This is the game responding differently to different rolls,
not a defect, and it is explicitly *not* what §4 is about.

---

## 5. Why the run was halted after S04

Tournament sign-up requires `min_party_size: 5`
(`data/config/tournament.json:7`, confirmed live and current — not the "3"
one step's own stale expected-text comment names, which is a harmless
authoring artifact in the instrumentation, not a live read). With team stuck
at 2, S04 correctly refuses sign-up: `tournament_team_ready`,
`tournament_training_ready`, `tournament_condition_ready`, and
`tournament_entered` all stay unset; no quarter/semi/final round ever runs;
`south_bridge_open` never sets.

This is the **anticipated downstream consequence** of §4, not a new finding.
Running S05–S10e now would only reproduce "the South Bridge gate is shut,
walked into it" repeatedly, with no new evidence — the same reasoning
CAPSTONE-2 used to halt at S07 after its own dead end. Continuing would cost
hours of harness wall time (each fresh S03/S04 pair costs roughly 20-25
minutes; S05-S10e would cost substantially more) to re-confirm a fact already
established once cleanly.

---

## 6. What this run does NOT establish

- **Bands 1–5, the finale, and the release ceremony have no evidence** from
  this run. Pacing, navigation, combat, encounters, and presentation for
  everything past the village tutorial ladder remain untested here.
- **`TOURNAMENT-SEMI-DIFFICULTY` is neither confirmed nor cleared**, same as
  CAP-2's run: no semi-final has ever been reached by any capstone run.
- **No prescribed screenshot exists.** This run's segments all declared
  `evidence_lane: logic` and delegated their §G captures to their `S0nC`
  capture lanes, none of which were run (same disposition as CAPSTONE-2 —
  photographing a state about to be superseded by a harness fix is not
  worth the capture-lane cost yet).
- All §K [OWNER-ONLY] gaps stand (handheld frame rate, GPU cost, real
  controller feel, audio — this container again fell back to the dummy audio
  driver, no audio device present).
- A wall-clock projection toward the 3–4 hour first-clear target is **not
  meaningful from this run**: the chapter never reached a state resembling
  continuous natural play (three of four S02 attempts and three of four S03
  attempts exist purely to establish reproducibility of harness-side
  findings, not as pacing data), and the segments that did complete (S01,
  S02, S04) are too early and too short to extrapolate from.

---

## 7. Recommended disposition

1. **Route the S03 catch-loop finding to a Gate F instrumentation lane**, not
   a game-code fix lane: `tools/gate_f/segments/S03.json`'s `S03-32b`
   through `S03-32j` need to (a) wait for `input_context` to leave `combat`
   before re-attempting the next challenge, and (b) have
   `refresh_pois`/`move_to_entity` exclude wild individuals already
   fought/caught this segment, so each of the ten attempts targets a
   genuinely live wild rather than looping back onto the same one. The
   materials/fiber shortfall (§4) is worth a look in the same pass, though
   it was not independently isolated from the catch-loop's effects here.
2. **Do not re-open CAP-1 or CAP-2.** Both are confirmed fixed in real play
   across four independent fresh runs each; the evidence is in §3.1 and this
   run's own S02 telemetry.
3. On the harness fix, **restart the journey chain from a fresh S01+S02**
   (not from any S03-or-later save produced by this run — all four are
   downstream of the very loop being fixed). S01 and S02 are cheap to
   re-run fresh (roughly 5 and 4 minutes respectively) and doing so avoids
   any question about save provenance of the kind that cost time in this
   run (§3).
4. This run's own `RUN_METADATA.json` is operator-authored, following the
   same precedent CAPSTONE-2 set: §A.2's coordinator freeze-record
   precondition was not separately discharged before this run began.
