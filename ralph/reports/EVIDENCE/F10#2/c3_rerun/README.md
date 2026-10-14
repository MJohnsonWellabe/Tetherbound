# F10#2 after the coordinator's four decisions (13 Oct): C2 PASS 18/18, in-world C3 1/6 (tb/ev-fights)
US Central, Tue 13 Oct 2026, 5:30–8:30 AM. The first re-run (2/6 C3, Capacitor C2 regression) is in git history at 7fa205df.

## Decisions applied (676ad4408, a6bb46f84)
1. **Capacitor Alpha:** the dive travels 7.5 m (was 5.5 m). Voltarach's visible-extent standoff is 8.7 m. Tell, speed and damage are unchanged. BOSSES §7 has the tune note, and `test_stormwood_named_fight_profiles` transcribes it. **Fixed:** the masher lead cost is now 0.27–0.85 against the reader's 0.03–0.05.
2. **Camera in foliage:** gave Stormwood's tree layers the camera-only canopy boxes. **Not fixed:** round 2 still shows black and green frames at Capacitor, Old Rodfolk, Blackwater and Glass Field. The black frames put the lens inside geometry the camera arm does not see. Reverted (the boxes and the test assertion), and parked for the camera owner.
3. **Lanes hidden under the spider:** added a faint no-depth-test copy of the lane (`lane_xray_alpha`). **Not fixed** at 0.35 or 0.7; the judge still reads the lane as under the body. The candidate is off (0). Parked after two attempts. Part of the cause is the capture fixture's L42 Sparkit, which is tiny next to Voltarach.
4. **Glass Field engage refused:** root cause found. The arena ring is sized from gameplay radii (12 m), but the L54 Voltarach's rendered legs reach 13.1 m, so all 395 seats were refused. **Fixed in product** (`combat_manager._open_arena`): when every other path fails off-pad with no room cap, the ring grows to fit both rendered bodies (capped at 26 m) and the same checks run again. The fight now starts, and C2 passes.

## C2: `smoke_stormwood_b_named_c2c3 --seeds=24`: PASS 18/18 (0 errors, 0 stalls). Rows: `r2/c2_rows_24seed.txt`.

## In-world C3, round 2 (`tools/capture_named_fights_f10_6.gd --draw-shots-only`, code-blind; key `KEY.json`)
| Fight | Verdict |
|---|---|
| hollows_alpha | FAIL: the ally is tiny and hidden under the spider; the lane is under the body; no visible step-out |
| capacitor_alpha | FAIL: the camera is behind trunks or inside foliage (two full-green impact frames) |
| crown_guardian | PASS: filled cone, clean step-out in tell3 |
| old_rodfolk_hall_guardian | FAIL: avoidance is visible, but the camera goes black or into foliage on strike frames |
| blackwater_elder | FAIL: its HEAVY field ring stays drawn under "it's open — hit it", stacked outlines, camera blackouts |
| glass_field_alpha | FAIL: now fights; spider framing and lane as in Hollows, plus canopy occlusion |

The spider-only re-judge with the lane copy at 0.7 is also FAIL x2. Shared notes:
- A stale "You backed off." carries into the next fight.
- The fixture fights end in a retreat.
- The trainer stands inside danger zones.

The judges in this round predate the /10 scoring rule (6:35 AM); every fight but Crown is a FAIL in any case. Sheets: `r2/*.jpg`.

**Verdict: F10#2 not met.** C2 is done. C3 is blocked on the camera (lens inside unmasked geometry at four stands) and on spider readability; both are parked with owners named above.
