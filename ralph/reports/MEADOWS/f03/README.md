# F03#0 "At least six activities show a visible lure": Meadows lane evidence

The CLAUDE_START_HERE §4 row reads: "The lure read passes (judge F). Remaining: an unstaged ordinary-discovery witness, a night cue at the herd, and moving the Hall pack to a road sightline (the nameplate draw-through stays off)."

## 1. The lure read (already passed)

`ralph/reports/MEADOWS-PAYOFFS/six-activities/earned/LURE-JUDGE-earned-f.md`, a code-blind full-bar judge, passes the visible-lure read for all six activities: vault, Bram, Doss, Hall, herd and Juno. Bars A/B were NO there; they go to the Phase 2 catalog.

## 2. Unstaged ordinary-discovery witnesses

Each witness is `tests/capture_activity_lures.gd` driving ordinary input only: move, sprint, look, recall, interact and run. It sets no flag, position, party member or clock (receipt `script_state_writes: none`). The walker finds each lure on the ordinary road by its own on-screen visibility test and ends at the activity's prompt.

| Activity | Render (commit) | Save (disclosed, not earned) | Receipt |
|---|---|---|---|
| Bram | 36413136705 (122a8efb) `walks_122a8efb/bram` | S04-exit-pose-on-road | PASS, first seen 74.5 m on the road |
| Doss | 36413141253 (122a8efb) `walks_122a8efb/doss` | S07-exit-band3 | PASS |
| Juno | 36413144937 (122a8efb) `walks_122a8efb/juno` | S07-exit-band4 | PASS |
| Herd (night) | 36426783755 (8fc88f20) `herd_night_walk_8fc88f20` | S04-exit-pose-on-road | PASS, first seen 63 m on the road at 23:31 |
| Vault | 36418251618 (36d88a84) `vault_cleared_36d88a84` | S06-exit-band3 | PASS (prompt "Engage Elder Trailpup") |
| Hall | 36422882434 (14e917a3) `hall_south_14e917a3` | S08-exit-band4 | PASS, first seen 141 m and readable 112 m on the road |

- **Vault, before the guardian:** `walks_122a8efb/vault` is from the uncleared save (a disclosed derived fixture). It shows the guardian and the lit vault door from the den entry, then GAPs behind the required guardian. The harness only runs from fights.
- **The saves:** the lure saves are Gate F exits and derived fixtures (`tests/fixtures/f03_lure_saves/README.md`), not earned play. They are allowed when disclosed under the relaxed-proof rule (STATE §1.1).

## 3. The herd's night cue

- **The change:** `meadowhart_watch_fire` (band1 props order 1058) now has fire 0.65, glow 2.4 and ring 1.2, up from 0.3/1.3.
- **Night views:** `herd_night_cue_8fc88f20/` (tests/capture_lure_cue_views.gd `--time=night`). The 40 m glance shows the fire and the pair.
- **The night walk:** fire and herd are visible from the road at 56 m (frames 04–06) and at approach and prompt (09–10). Judge r13 (`LURE-JUDGE-r13.md`) confirms the cue reads at 04–06, 09 and 10.

## 4. The Hall pack on a road sightline (nameplate depth test stays on)

- **The move:** band5 spawns order 5001 moves to (-45,7300), with an 8 m disc and 5 m wander. It is west of approach pylon 8 and scores 13 hard-clear road samples on `tests/probe_lure_road_visibility.gd`. `no_depth_test` stays false.
- **Walk from the south:** `hall_south_14e917a3`. Judge r13 finds the alpha's body "in the open field right beside the road path … unobstructed by any structure or terrain … in direct line of sight from the road" at 58 m (hall_13). The name reads from 112 m.
- **Optionality:** `smoke_alpha_pins.gd --hall-decline` OK. The closest pack member is 44.4 m from the road walker, and no fight starts.

## 5. Judges this round

`LURE-JUDGE-r12.md` covers all seven walk sets; `LURE-JUDGE-r13.md` covers the herd night and the Hall. Their PARTLY notes:
- **Harness framing:** the walker's glance frames catch unrelated prompts, the player's own companion, or a tree trunk. This is noted for Doss, the herd (07/08) and Hall (11).
- **The Hall body** is not visible at the 48 m exit glance.
- **No watcher figure** stands at the herd fire.

None of these contradicts the visible-lure read in §1. The Bars A/B clause goes to the Phase 2 catalog.
