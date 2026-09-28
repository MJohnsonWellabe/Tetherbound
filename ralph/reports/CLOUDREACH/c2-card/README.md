# Card C2 — Cloudreach cadence, rewards and art (Phase 1 integrated run)

ACCEPTANCE §6 C2: "Remove the recorded 885-second no-action stretch and every A7 empty interval; at least six
qualified activities include one per principal region. Full route resource/XP ledger supports the retained
five without a new catch. Correct high-perch production-camera footage, cliff silhouettes, settlements and
day/night route cues pass the chapter frame matrix and Bars A/B." Phase 1 (STATE §1 ruling 4): the frame
matrix clause closes on function and readability; **Bars A/B → Phase 2 catalog**.

Feeders: F07#0-#4 met; F08#3 and F08#4 closed on this branch (strict re-checks MET).

## The integrated run (one head: game state identical at 4fc380f4 and 1178e18a)

| Clause | Evidence | Result |
|---|---|---|
| 885 s stretch gone; no A7 interval over 120 s | `run-1/` — `tests/smoke_cloudreach_b_c1_card.gd --from-save=res://tests/fixtures/earned_saves/c1_arrival --accelerated --live-combat` at 4fc380f4; `run-1/c2-analysis.json` (from `b/c2-cadence/analyze_c1_events.py`) | C1 CARD PASS, CONTINUOUS PASS stage=complete, 18,865 m; 296 activity intervals, longest 98.18 s (upper_anchor_east → Voss), none over 120 s |
| Six qualified activities, one per principal region | `run-1/six-activities/` — `tests/smoke_cloudreach_b_f07_0_six_activities.gd` at 1178e18a | SIX ACTIVITIES PASS: Waycamp shelter, Three Bells, Windscar couriers, Aeries, Cliff Circuit, Observatory latch — lure, action, payoff, acknowledgement and disk-reload for each, default five (no flier) |
| Route resource/XP ledger supports the retained five, no new catch | `run-1/c2-analysis.json` ledger | Same five start to finish (ripplet, bramblebun, mudsnout ×2, veridian; L21-26 → L24-29); four named fights won (Senn, Maela, Voss, Veyra); 0 legendary offers in this run |
| High-perch production camera | `../f08-3-high-perch-camera/r5/` | CAMERA READ PASS (code-blind), re-check MET |
| Cliff silhouettes, settlements, day/night route cues (frame matrix) | `../f08-4-settlements/` r1/r1c/r1d/r1f | Code-blind: settlements PASS, routes PASS (after the Broken Causeways crown carve), night PASS; re-check MET |
| Bars A/B | — | Phase 2 catalog (owner ruling 2026-09-28) |

## Disclosed shortcuts
- **Earned run:** starts from the earned `c1_arrival` checkpoint; accelerated clock (physics 1/60 s, fights at 1x);
  live-combat pilot writes camera yaw; Title Load by signal; logged walking aids (relay-leg sidesteps, bed
  approaches, waypoint recentring); every flight on Maela's loaner (owned-carrier Fly is open debt). The harness
  predates Solmane and completes the chapter without entering the tether chamber: Solmane's freeing and
  per-participant offer are card C3's (two-peer run-9-solmane) and F08#5's, skipped here.
- **Six activities:** fixture start (Act I-II flags, level-30 five, no flier), teleports to each prompt, 4 Gale Fiber
  granted, Tavi through the mechanics-mode lethal seam, accelerated clock.
- **Frame matrix:** as disclosed in the two feeder READMEs.

## Independent re-check: PASS
Disclosed with it: `run-1/head.txt` and `six-activities/head.txt` were written from the run script's
`git rev-parse` at launch (the harness artifacts themselves carry no commit); the card is a composite of the
earned chapter run (A7 and ledger; side activities skipped), the fixture six-activities run (not the earned
five) and the feeders' fixture frame captures; the longest raw interval is 98.9 s inside the Veyra fight
(98.18 s is the longest travel interval); coins 875 → 1300 over the chapter, Gale Fiber 5 gathered and 3 spent;
the settlements read was marginal (Cliffhold PARTLY) and Bars A/B are deferred to Phase 2, not passed.
