# F10#2 re-run on current source: C2 (24 seeds) and in-world C3 code-blind judge (tb/ev-fights)
Times US Central, Tue 13 Oct 2026, from about 12:20 to 2:30 AM. Source: tb/ev-fights at 3fce1858 or later. The fight code is unchanged from the base; the Capacitor probes below were reverted.

## C2: `smoke_stormwood_b_named_c2c3.gd --seeds=24`, six cases x three starters (864 fights, 0 errors, 0 stalls)
- PASS on 15/18 rows: hollows_alpha, crown_guardian, old_rodfolk_hall_guardian, blackwater_elder and glass_field_alpha, all three starters each. Rows are in `c2_rows_24seed.txt`.
- **FAIL capacitor_alpha x3 (regression since the 11 Oct PASS on 00d4a639):**
  - Both pilots take 0 hits (ratio 0/0). COMBAT §5's visible-extent contact floor gives Voltarach (leg span) a standoff of 8.69 m and a reach floor of 9.39 m, so its authored 5.5 m travelling dive (BOSSES §7) always stops short.
  - Probes (2 seeds, Ripplet, all reverted): lunge 7.5 m lands (masher lead 0.32); lunge travel off lands; a `range` cap is regrown by spacing; growing the lunge to the spaced range in `spaced_config_for` fixes it but breaks `test_charger_lunge` (lane length = configured lunge, a BOSSES contract).
  - Parked after two approaches. The fix needs a decision: either a travelling lunge counts as surface-to-surface under the visible-extent floor (contact-spacing owner), or Capacitor's authored 5.5 m changes (BOSSES).

## C3: in-world capture (`tools/capture_named_fights_f10_6.gd --draw-shots-only`, production stormwood.tscn, camera and HUD), code-blind judge
Disclosed fixture: the party is at L42, the player is placed beside each wild, and the storm is pinned to Calm. Sheets: `fight_*_sheet*.jpg`; the key in `KEY.json` was withheld from the judge.

| Fight | Verdict | Judge's reason |
|---|---|---|
| hollows_alpha | FAIL | Tells are drawn under the spider's body and legs, so the area and safe ground can't be read. The L42 ally is tiny under it. |
| capacitor_alpha | FAIL | The fight camera sits inside foliage or trunks for whole tells and swings about 90° at the strike. |
| crown_guardian | PASS | A filled cone, honest hits and a visible avoidance. |
| old_rodfolk_hall_guardian | FAIL | The camera is blocked: a black frame and foliage through tell1's impact. |
| blackwater_elder | PASS (marginal) | A cone and a ring overlap, the ring lingers into recovery, and the camera flips during tell3. |
| glass_field_alpha | FAIL | The fight never started: "There isn't enough clear ground here for both creatures." |

- Shared notes: strikes and misses show no effect on the ground; "it's open — hit it" appears while the ally is being hit; the ally's own hits read weakly; the trainer stands in danger zones; the bottom HUD (about 40% at 960x540) clips shape tips; a stale "You backed off." carries into the next fight.

**Verdict: F10#2 not met.** C2 is 15/18 (Capacitor is a regression with a known root cause). C3 is 2/6. Camera occlusion at the Conductor Run and Deepwood stands, the spider tells hidden under the body, and Glass Field's engage refusal are presentation and placement defects for the Stormwood visual and placement owners.
