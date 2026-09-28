# Aquaryn C2 with all three starters (strict re-check gap 1)

The earlier confirmation (`../../../f14_confirm_main/`) ran Aquaryn with Ripplet only. Here all three starters were run.

**Command:**
`godot --headless --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=aquaryn --starter=<s> --party-level=43`

**Setup:** the flat combat_depth arena, harness READER/MASHER pilots, a granted L43 five. All are declared shortcuts. Tree: tb/tidewake with this lane's uncommitted camera work; the fight data is unchanged.

**Results:** `SUMMARY.txt`. 144 runs, 0 errors.

| Starter | Reader win | Reader / masher median lead cost | Ratio | Masher wipe | Max hit | Tells |
|---|---|---|---|---|---|---|
| galewisp | 1.00 | 0.118 / 0.217 | 0.54 | 0.00 | 0.064 | 1.25-1.70 s |
| ripplet | 1.00 | 0.123 / 0.390 | 0.32 | 0.00 | 0.066 | 1.25-1.70 s |
| terrapup | 1.00 | 0.194 / 0.665 | 0.29 | 0.00 | 0.069 | 1.25-1.70 s |

Under the named-wild reading (ratio at most 0.55 plus reader win): **PASS**, with galewisp at the margin.
- Under the top-fight bar (masher wipe at least 25%): **FAIL**.
- Which bar applies is an open owner question (STATE).
