# Gate F Capstone 2 — run report

**Branch:** `ralph/GATE-F-CAPSTONE-2` · **Candidate:** `679f990c`
(from `main` @ `721893a4`, carrying the CAP-1 fix `cf4c5ab1`)
**Run directory:** `ralph/reports/gate-f-run-20260831T185555Z/`
**Operator:** agent, tester role. **No game code, data or config was changed**
(`GATE_F_MASTER_PROTOCOL.md` §J / `GATE_F_PROTOCOL.md` §13).
**Outcome:** the chapter **cannot be completed on this candidate**. Halted after
S07 by operator decision, with the reason recorded below.

---

## 1. Result in one line

**CAP-1 is fixed — and the chapter still cannot be played to the end**, because a
second, independent dead end (**CAP-2**) stops the village tutorial ladder and
walls the player south of the South Bridge for the rest of the run.

---

## 2. Segment ledger

| segment | P | F | SKIP | complete | note |
|---|---|---|---|---|---|
| S01 Boot & front door | 13 | 0 | 0 | ✅ | clean |
| S02 Opening | 78 | 3 | 0 | ✅ | **CAP-1 verified fixed** |
| S03 Village ladder | 315 | 29 | 9 | ❌ | **CAP-2 — root cause** |
| S04 Tournament | 53 | 18 | 0 | ✅ | all inherited; no match ever ran |
| S05 Lower Meadows | 71 | 9 | 0 | ✅ | 5 inherited, 4 open |
| S06 Stone & Root | 76 | 19 | 0 | ✅ | walled at the bridge; 10 km walked, 0 m progress |
| S07 River & Relay | 45 | 12 | 56 | ❌ | derailed at `S07-51`; same wall |
| S08–S10e | — | — | — | not run | halted; see §5 |

Totals for what ran: **651 PASS · 90 FAIL · 65 SKIP** across 7 segments,
2 h 27 m of harness wall time.

**The 90 failures are not 90 defects.** By origin: **29** are CAP-2 itself
(S03); **~55** are inherited consequences of it in S04–S07; **4** are open items
in S05 that the operator declined to attribute; **3** are S02 rig-floor misses.

---

## 3. CAP-1: fixed, verified in real play

The thing capstone 1 died on. Verified against the **production exit save the
chapter chains from**, not a fixture:

| | capstone 1 | this run (`S02/saves/S02-exit.json`) |
|---|---|---|
| party | 1 creature, fainted | 2 creatures, both `fainted: false` |
| inventory | `orb_basic x11`, nothing else | `orb_basic x12`, **`revive x2`** |

The restored `give:revive:2` (CAP-1 fix item 4, the D40 regression `66eb47ec`
dropped) is present in a save produced by real play. The starter finished the
tutorial fight up rather than down, and the wild catch succeeded — `catch_throw`
t=256.07, verdict t=260.27, `combat_end` t=262.82.

## 4. CAP-2: the new blocker

Full write-up with reproduction:
**`ralph/reports/FINDING-CAP2-S03-TRAINING-LADDER-2026-08-31.md`**

In short: the starter enters the first village training fight at **53.0 / 117.6**
— unhealed damage carried out of S02 — and loses. From then the live prompt reads
*"Ripplet is out of the fight."*, and nine consecutive engage attempts correctly
**refuse** to press rather than misfire. The team never reaches five;
`home_materials_gathered`, `home_built`, `creature_bed_built`,
`player_slept_at_home` and `tournament_team_fed` all stay unset. S03 hands S04 a
save with a fainted starter, a team of two and no Revive left.

Two facts recorded **without diagnosis**, for Phase B:

1. Nothing the player owns heals a **living** creature. CAP-1 restored Revives
   but deliberately not potions or berries; a Revive returns a *fainted* creature
   at 50%.
2. S03 emits **zero `catch_throw` events while consuming four orbs**
   (`orb_basic` 12 → 11 → 8), and fight 3 spends its entire length in
   `input_context = combat_aim` against an opponent whose HP never moves off
   `106.191112967968`.

## 5. Why the run was halted at S07

`route.csv` for S06: **10,031.7 m walked, max z = 1327.8**, regions entered
`corridor` and `grandpas_village` only — **zero** rows in any band-2 region. The
South Bridge is at z = 1330. Ten `did not reach` walks in S06 all stop at
x ≈ 8–15, z ≈ 1317–1325, and `S05-56` failed at the same spot. S07 repeats it
(max z = 1327.2) and derails at `S07-51`.

`south_bridge_open` is unset because the gate fight never ran because the party
cannot fight. **S08, S09 and S10a–e all begin north of a crossing this save
cannot make.** Running them would have cost an estimated 4–6 hours to produce
more segments of "walked into the same shut gate" — a fact already evidenced
three times over. Halting is an operator decision, recorded here rather than
taken silently, and the segments are marked *not run* rather than failed.

## 6. What this run does NOT establish

Stated so nothing here is over-read:

- **`TOURNAMENT-SEMI-DIFFICULTY` is neither confirmed nor cleared.** S04 is gated
  at *entry*: sign-up never took, so `combat_running=false` for the quarter, the
  semi and the final alike. There was no semi-final to be difficult. S04's 53
  PASSes are the walk to the ground and scaffolding, not the event.
- **Bands 2–5 have no evidence.** Nothing about the Quarry, Warrens, River,
  Relay, Upper Meadows, Stronghold or the finale — pacing, navigation, combat,
  encounters, presentation — may be sourced from this run.
- **No prescribed screenshot exists.** `RUN_INVENTORY.json`: **0 of 82** frames
  present. Every one is a recorded DELEGATION from a logic lane to its `S..C`
  capture lane, and the capture lanes were not run. The debt is recorded in
  `RUN_INCOMPLETE.md`, not erased. Running them now would photograph a state
  CAP-2 has degraded, so they are better re-run after the fix.
- **All §K [OWNER-ONLY] gaps stand**, plus audio: this container has no audio
  device at all and Godot fell back to the dummy driver.
- Durations here are **not comparable** to the 2026-08-27 run: the same overhead
  measurement reports **24.170 ms/frame** on this box against **4.341** there.

## 7. Recommended disposition

1. Route **CAP-2** to a fix lane. It is a chapter-level dead end of the same
   family as CAP-1: a state the game can enter with no route out.
2. On the fix, **restart from `S02-exit.json`** — the last clean handoff. Not
   from any save at or after S03.
3. S01 and S02 need not be re-run for their logic; their evidence is sound. The
   capture lanes (`S01C`…) remain owed for all of it.
4. §A.2's freeze record for a candidate is a **coordinator** precondition. It had
   not been discharged here and the run refused at pre-flight until one existed —
   see `ralph/reports/gate-f-run-20260831T185309Z/BLOCKER_RUN.md`. The record
   this run used was written by the operator and says so in its own first field.
