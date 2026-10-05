# F01#4 and F01#5: three starters through naming, fight and catch, three beds and the bracket, and reload survival on the v28 save

**F01#4: PASS** for terrapup, ripplet and galewisp. **F01#5: PASS** for all three (both in-chain v28 reloads hold). Each starter has one complete passing full-chain run. **Two first runs failed, and each failure is root-caused below.** One of them (terrapup) is a real, intermittent defect in the opening that a player can meet, so it is reported as an open finding even though the row passes.

- **Commit:** `9a5a43655620252c98dd9fde9bd8544d6c9381f5` (origin/main). Local 4 vCPU, headless, one run at a time on its own test save directory.
- **Command:** `godot --headless --path . --script tests/smoke_gate_b_continuous.gd -- --gate-b-full-chain --starter=<terrapup|ripplet|galewisp>`

| Starter | Run 1 | Run 2 | Passing run: reloads |
|---|---|---|---|
| terrapup | FAIL 15:30Z (opening fight) | **PASS** 16:35Z | three-bed readiness reload: Bud L5; after the third round: Bud L8 xp297, party unchanged |
| ripplet | FAIL 15:31Z (naming grid) | **PASS** 16:17Z | same: Bud L5, then Bud L8 xp297 |
| galewisp | **PASS** 15:49Z | (not needed) | same: Bud L5, then Bud L8 xp297 |

Every passing run walked all 12 Gate B objectives in order:
- the real starter pick and the name "Bud";
- the natural Bramblebun weakening and a physical catch;
- 3 creature beds through the build menu, with one night bringing all three entrants to Rested, Fed and Happy;
- the quarter-final, semi-final and final, all won, with recipe_saddle learned;
- ending on "Reach South Bridge -- Team Tether holds the crossing".

The passing logs are `gateb-galewisp-run1.txt`, `gateb-ripplet-run2.txt` and `gateb-terrapup-run2.txt`. Both reload lines record the same starter uid and party before and after the reload.

## Run-1 failures

### terrapup, run 1: an ambient wild steals the tutorial engage (product, open)

The run failed with `opening: real piloted attacks did not weaken Bramblebun within the bounded fight`.
- The drive targeted the tutorial `Wild_bramblebun_0_2`. When it pressed, the engage prompt read **"Engage Mudsnout"** at 2.56 m.
- The passing runs read "Engage Bramblebun" at 5.33 m and 5.79 m.
- `encounter_director.gd::_engageable()` offers the **nearest** visible live wild within range. An ordinary `meadows_open` wild (that table rolls Bramblebun or Mudsnout, per `spawn_tables.json`) can stand nearer the Practice Meadow road end than the opening's practice Bramblebun.
- The tutorial fight therefore started against a Mudsnout. The drive kept steering toward the Bramblebun, so the real foe was never weakened.

A player can hit this too: their practice fight can be against a wandering Mudsnout instead of the scripted practice Bramblebun that `opening.json` names.

- **Product fix area:** during the opening's encounter beats, the engage offer should prefer, or be limited to, the opening's own practice creature. Alternatively, keep ambient wilds out of the practice stand until the first catch.
- **Harness hardening:** `gate_a_opening_drive.gd::_walk_to_and_engage_wild` should require the prompt to name the target.

### ripplet, run 1: naming cursor overshoot (test harness timing, no product defect)

The run failed with `controller stopped on 'X' instead of 'd'` while typing "Bud".
- Reaching 'd' (row 3) from 'u' (row 5) takes six wrapping `ui_down` taps. The cursor ended on row 2, then moved to column 3, which is 'X'.
- `gate_a_opening_drive.gd::_select_name_cell` reads `entry.row` straight after `_tap_action`. A press delivered late under load gets counted against a stale row.
- This is the class `_tap_action`'s own comment already patched once ("stopped on 'A' instead of 'B'" under xvfb).
- The run-2 pass on the same commit confirms it is timing, not grid logic.
- **Harness fix:** after each tap, wait until `entry.row` changes (bounded) before reading it again.

No product code was changed in this lane.
