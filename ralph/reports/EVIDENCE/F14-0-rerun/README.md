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

EV F14#0 FAIL d1f3efc0b chapter masher-loss now ≥0.50 for every starter; the three Galewisp named-wild rows stay reader≈masher (0.32–0.43), the type-advantage class with Ripplet x guardian
