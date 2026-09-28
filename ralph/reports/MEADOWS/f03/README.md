# F03#0 "At least six activities show a visible lure": Meadows lane evidence

The CLAUDE_START_HERE §4 row reads: "The lure read passes (judge F). Remaining: an unstaged ordinary-discovery witness, a night cue at the herd, and moving the Hall pack to a road sightline (the nameplate draw-through stays off)."

## 1. The lure read (already passed)

`ralph/reports/MEADOWS-PAYOFFS/six-activities/earned/LURE-JUDGE-earned-f.md`, a code-blind full-bar judge, passes the visible-lure read for all six activities: vault, Bram, Doss, Hall, herd and Juno. Bars A/B were NO there; they go to the Phase 2 catalog.

## 2. Unstaged ordinary-discovery witnesses

Each witness is `tests/capture_activity_lures.gd` driving ordinary input only: move, sprint, look, recall, interact and run. It sets no flag, position, party member or clock (receipt `script_state_writes: none`). The walker finds each lure on the ordinary road by its own on-screen visibility test and ends at the activity's prompt.

| Activity | Render (commit) | Save (disclosed, not earned) | Receipt |
|---|---|---|---|
| Bram | 36413136705 (122a8efb) `walks_122a8efb/bram` | S04-exit-pose-on-road | PASS, first seen 74.5 m on the road |
| Doss | `ralph/reports/MEADOWS-PAYOFFS/six-activities/earned/lure0/doss-f` (same walker, same save, `--off-road-cost=10`) | S07-exit-band3 | PASS; its 60 m on-road glance shows pennant, smoke and perch (judge F). The 122a8efb Doss walk (`walks_122a8efb/doss`) reached the prompt but first saw Doss at 24 m off the road after a deliberate look (judge r12 PARTLY), so it is not the witness. |
| Juno | 36413144937 (122a8efb) `walks_122a8efb/juno` | S07-exit-band4 | PASS |
| Herd (night) | 36426783755 (8fc88f20) `herd_night_walk_8fc88f20` | S04-exit-pose-on-road | PASS, first seen 63 m on the road at 23:31 |
| Vault | 36418251618 (36d88a84) `vault_cleared_36d88a84` | S06-exit-band3 | PASS (prompt "Engage Elder Trailpup") |
| Hall | 36437653848 (28d5928b) `hall_south_28d5928b` (earlier site: 36422882434 `hall_south_14e917a3`) | S08-exit-band4 | PASS, first seen 109 m and readable 109 m (25 px) on the road |

- **Vault, before the guardian:** `walks_122a8efb/vault` is from the uncleared save (a disclosed derived fixture). It shows the guardian and the lit vault door from the den entry, then GAPs behind the required guardian. The harness only runs from fights.
- **The saves:** the lure saves are Gate F exits and derived fixtures (`tests/fixtures/f03_lure_saves/README.md`), not earned play. They are allowed when disclosed under the relaxed-proof rule (STATE §1.1).

## 3. The herd's night cue

- **The change:** `meadowhart_watch_fire` (band1 props order 1058) now has fire 0.65, glow 2.4 and ring 1.2, up from 0.3/1.3.
- **Night views:** `herd_night_cue_8fc88f20/` (tests/capture_lure_cue_views.gd `--time=night`). The 40 m glance shows the fire and the pair.
- **The night walk:** fire and herd are visible from the road at 56 m (frames 04–06) and at approach and prompt (09–10). Judge r13 (`LURE-JUDGE-r13.md`) confirms the cue reads at 04–06, 09 and 10.

## 4. The Hall pack on a road sightline (nameplate depth test stays on)

- **Site:** band5 spawns order 5001 now centres on (-36,7290), with its authored 18 m disc and default wander. The envelope still reaches the Hall spine, so `tests/test_meadows_route_ambush_spacing.gd` passes for the authored world and 200 seeds.
- **New flag:** `alpha.stand_at_centre` puts the alpha itself on that centre. In the first two re-walks the alpha had landed 16 m from the probed spot, or behind approach pylon 8.
- **Sightline:** the centre is west of the pylon, 20 degrees or more off every walked sightline, inside the probe's clear band. `no_depth_test` stays false.
- **Walk from the south:** `hall_south_28d5928b` (distances are from the player; the receipt's 109 m is from the camera). From the road the name reads at 103 m (hall_12–13). There the body is only a faint fleck behind its own label, and in hall_11 the player's Ripple blocks it. The alpha's body reads clearly from the road at 51 m (hall_14, beside the base of approach pylon 7 (-24,7257.5), which clips the start of the name) and at 41 m (hall_15, in open ground before the road exit). It is under its name at 30 m (hall_16), and the pack is present at the prompt (hall_17).
- **The alpha can drift:** `stand_at_centre` fixes only where it spawns. The default wander (about 7 m) still applies.
- **The earlier 14e917a3 walk:** judged in r13 and the re-check, at (-45,7300) with an 8 m disc. It showed the body in open ground from the road at 58 m and 48 m.
- **Optionality:** `smoke_alpha_pins.gd --hall-decline` OK. The closest pack member is 39.0 m from the road walker and no fight starts (`hall_decline_smoke.txt`).

## 5. Judges this round

`LURE-JUDGE-r12.md` covers all seven walk sets; `LURE-JUDGE-r13.md` covers the herd night and the Hall. Their PARTLY notes:
- **Harness framing:** the walker's glance frames catch unrelated prompts, the player's own companion, or a tree trunk. This is noted for Doss, the herd (07/08) and Hall (11).
- **The Hall body** is not visible at the 48 m exit glance of the earlier 14e917a3 walk. In 28d5928b it is visible at the 41 m exit glance.
- **No watcher figure** stands at the herd fire.

None of these contradicts the visible-lure read in §1. The Bars A/B clause goes to the Phase 2 catalog.

## 6. Strict re-check: MET (`RECHECK.md`)

Disclosed shortcuts:
- **Start saves:** these are fixtures, not earned play. The vault witness uses the cleared save; the uncleared walks stall behind the required guardian.
- **The walker:** it plans on the road graph to a known lure, sets the camera rig's yaw and pitch directly, makes deliberate glance turns, flees fights, unsticks by jumping and strafing, and toggles the companion. Doss-f and the herd walks use `--off-road-cost=10`.
- **The walker's "first seen":** this is a raycast plus a frustum test that non-colliding foliage does not block. Readability comes from the judged frames.
- **Vault:** the receipt has no `lure_first_seen`, because the lure is inside the den.
- **Hall end frame:** the prompt frame (hall_16 in 14e917a3, hall_17 in 28d5928b) shows "You backed off." after the walker's Engage; in 28d5928b the on-screen prompt names a pack member ("Engage Galecrest"), while the receipt's winner is "Engage Alpha Galecrest". Open note: why the walker's engage fled.
- **Herd:** no watcher figure stands at the fire. Nothing reads at 110–160 m at night. At 40 m the fire sits 53 degrees off the road axis.
- **Judges r12/r13** returned PARTLY for Doss, herd and Hall. The re-check overrides them: r13 took the player's own Gale for the alpha and missed the alpha's body at 48 m, and the Doss witness is doss-f.
- **Bars A/B:** go to the Phase 2 catalog (judge F: NO).
