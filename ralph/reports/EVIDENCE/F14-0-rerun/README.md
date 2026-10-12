# F14#0 re-measure: the three failing Galewisp named-wild rows on the current reader (tb/ev-systems-a)
Command: `godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=<id> --starter=galewisp --party-level=<island entry> --json=<out>`
- Commit d1f3efc0b, 22:56–23:10 CT Sun 11 Oct 2026. Its reader is 1032b96d3, the same as F14#1's re-measure.
- Island-entry levels as in ../F14#0/EVIDENCE.md: brine 23, drowned_garden 28, deep_watch 30. Rows are in `rows.txt`.
- Bar (named wild): reader lead ≤.55× masher's, reader win ≥.9.

| Named wild | Reader / masher lead cost | Before (F14#0) | Verdict |
|---|---|---|---|
| brine_root_watcher | 0.425 / 0.413 | 0.417 / 0.413 | FAIL |
| drowned_garden_songweaver | 0.337 / 0.334 | 0.344 / 0.334 | FAIL |
| deep_watch_tidecoil | 0.322 / 0.337 | 0.285 / 0.337 | FAIL |

- Reader win is 1.00 throughout; worst hit 0.043–0.075; tells 0.85–1.10 s.
- The reader fixes did not move these rows. Galewisp (air) holds the type edge here, so the masher wins in 29–38 s against the reader's 42–77 s. Both lose about the same lead HP to small hits.
- This is the same class as Meadows Ripplet × guardian: a type-advantaged masher that wins the damage race.
- The Tidewake chapter masher-loss now passes for every starter: Nerissa alone gives ≥0.50 (../F14-1-rerun).

## Full Tidewake table on the adopted reader (1032b96d3), all 15 cases × 3 starters
- The 13 non-Veilfall cases ran on 5b18ea665, 00:58–02:05 CT Mon 12 Oct. That commit's reader is the same as 1032b96d3's.
- Veilfall: ../F14-1-rerun (d83f2d3b7 / b241114c5, same reader).
- Scored with `score_water2.py`: the F14#0 scorer, with input paths as arguments. Output is in `verdicts_full.txt`.
- **42 of 45 rows PASS.** Only the three Galewisp named-wild rows above FAIL.
- C3: worst hit 0.306; tells ≥0.85 s; 0 stalls.
- Chapter masher-loss over the 12 trainer cases: Terrapup 1.00, Ripplet 0.92, Galewisp 0.50 (bar 0.25, PASS).
- A ×2.0 power probe on each encounter's dodgeable heavy made the reader pay as much as the masher or more (../F04-7-rerun/punish_mode.md has the table), so these three rows go to the owner end-list as matchup-balance.

EV F14#0 FAIL 5b18ea665 42/45 Tidewake rows and the chapter bar (1.00/0.92/0.50) PASS on the adopted reader; only the three Galewisp named-wild rows fail (type-advantage class, owner end-list)

## Adopted reader, attempt 2 (904c3c537): all 18 water cases × 3 starters on one commit
- Run 04:57–06:43 CT Mon 12 Oct. Scored by `../F14-0-rerun/score_water2.py`; output in `../F14-0-rerun/verdicts_904c3c537.txt`.
- 51 of 54 rows PASS. Every Veilfall row passes.
- The only FAILs are the three Galewisp named-wild rows: brine 0.425/0.413, tidecoil 0.322/0.337, songweaver 0.281/0.334.
- Chapter masher-loss 1.00 / 0.92 / 0.50. C3: worst hit 0.311; tells ≥0.85 s; 0 stalls.

EV F14#0 FAIL 904c3c537 adopted reader: 51/54 Tidewake rows and the chapter bar (1.00/0.92/0.50) PASS; only the three Galewisp named-wild rows fail (brine 0.425/0.413, tidecoil 0.322/0.337, songweaver 0.281/0.334), the owner matchup-balance item
