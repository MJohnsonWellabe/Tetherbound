# F33#2 partial: Meadows Warden (warden_aldis) at Rootiron +0
- Commit: tb/ev-coordinator 00d4a639 (no code change). Run Sun 11 Oct 2026, 10:44–11:50 AM CT, 66 min on a 4-core host shared with net smokes.
- Command: `godot --headless --path . --fixed-fps 60 --script tests/smoke_f22_pattern_bands.gd -- --seeds=12 --band=band5_stronghold_approach --named=warden_aldis --gear-tier=rootiron --json=<out>`
- Fixture (disclosed): tests/helpers/f33_gear_fixture.gd writes the party's gear into the owner record; party = starter + retained four at band entry level; flat-fixture C2.
- Receipt pass=false only because coverage=false (one band selected); errors=[]; gear label 'rootiron'.

| starter | top-trainer bar | switch_reader win | masher lead lost | switch_reader median cost | masher median cost |
|---|---|---|---|---|---|
| terrapup | PASS | 1.00 | 1.00 | 0.260 | 0.633 |
| ripplet | PASS | 1.00 | 1.00 | 0.195 | 0.625 |
| galewisp | PASS | 1.00 | 1.00 | 0.116 | 0.710 |

Not run here: Meadows bare (previous tier) and the other three bosses; F33#2 moved to systems-a, which owns the verdict.
