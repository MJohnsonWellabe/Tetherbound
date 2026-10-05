# F33#2 boss sims: each tier vs the previous tier (lane A, tb/f17)

**Verdict: OPEN.** Gear measurably helps at every pair: less HP spent, smaller worst hit and faster clears. But no boss passes C2 for all three starters with its matching tier. The failures come from the fights themselves (masher/reader separation), not from gear, which cannot make a reader beat a masher by more. Two gear gaps also reduce what the sims show:

- Harness max HP is not applied (below).
- The Charm's ultimate gain only exists in sessions; the solo pilot has no ultimate meter.

## How it ran

- **Engine path.** Production `CombatManager` and `WildCreature` bodies on the shared pilots (`combat_depth_pilot` / `f22_pattern_pilot`). Gear is read by the production solo hooks: `combat_manager._gear_power_scale` (Charm move power) and `_gear_defence_scale` (Harness defence).
- **Gear fixture.** Every one of the five party members wears the tier's Harness and Charm (+0), written into the owner record by `tests/helpers/f33_gear_fixture.gd` (disclosed fixture; it detaches saving while equipped).
- **Pairs.** Per `gear.json` `boss_proof`, each biome's tier is run against the previous one at identical seeds.
- **Where it ran.** Locally at `--fixed-fps 60`. On CI, render.yml runs in real time, and the 24-seed, 3-starter set ran past its 60-minute cap (runs 37319379237 and 37319384099). The Rootiron run there also hit "Save refused" on the fixture rows, which the fixture now prevents (27225f3e).

```
# Meadows / Warden Aldis, per starter, 8 seeds
godot --headless --path . --fixed-fps 60 --script tests/smoke_meadows_named_c2c3.gd -- --seeds=8 --case=warden_aldis --starter=<s> [--gear-tier=rootiron] --json=<out>
# Tidewake / Nerissa, per starter, 8 seeds
godot ... tests/smoke_water_named_c2c3.gd -- --seeds=8 --case=water_trainer_nerissa --starter=<s> --gear-tier=<rootiron|tidesteel> --json=<out>
# Cloudreach / Veyra and Stormwood / Marrow, 12 seeds (runner minimum)
godot ... tests/smoke_f22_pattern_bands.gd -- --seeds=12 --named=<captain_veyra_storm_anchor|captain_marrow_dynamo_core> --gear-tier=<tier> --json=<out>
```

The receipts in `boss-sims/` hold every run for Meadows and Tidewake. The Cloudreach and Stormwood receipts are compact, rows only; the full per-run files were 30–68 MB.

## Results

Notes on the tables:

- M / R / S are the masher / reader / switch-reader policies.
- "Party cost" is the median fraction of party HP lost.
- "Max hit" is the largest single hit as a fraction of the struck creature's max HP.
- Times are median seconds per fight.

### Meadows: Warden Aldis, L18, bare (tier 0) vs Rootiron (tier 1)

| Gear | Starter | Win M/R | Lead faint M/R | Party cost M/R | Max hit M/R | Time M/R | C2 |
|---|---|---|---|---|---|---|---|
| bare | galewisp | 1.00/1.00 | 1.00/1.00 | 0.783/0.245 | 0.50/0.48 | 114/246 | PASS |
| bare | ripplet | 1.00/1.00 | 1.00/1.00 | 0.611/0.458 | **0.51**/0.48 | 112/268 | FAIL (ratio 0.75; C3 hit) |
| bare | terrapup | 1.00/1.00 | 1.00/1.00 | 0.779/0.469 | 0.50/**0.53** | 121/266 | FAIL (ratio 0.60; C3 hit) |
| Rootiron | galewisp | 1.00/1.00 | 1.00/1.00 | 0.768/0.263 | 0.45/0.43 | 107/221 | PASS |
| Rootiron | ripplet | 1.00/1.00 | 1.00/1.00 | 0.578/0.254 | 0.49/0.31 | 104/224 | PASS |
| Rootiron | terrapup | 1.00/1.00 | 1.00/1.00 | 0.633/0.407 | 0.41/0.47 | 106/219 | FAIL (ratio 0.64 > 0.55) |

**Rootiron vs bare**
- Every starter's worst hit drops under the C3 ceiling of 0.50.
- Reader party cost falls by 0.20 (Ripplet) and 0.06 (Terrapup), and rises slightly (+0.02) for Galewisp. Masher party cost falls by 0.02–0.15.
- Clears are 6–18% faster.
- C2 passes for 2 of 3 starters, against 1 of 3 bare. The bare tier is clearly harder.

**Still failing:** Terrapup's reader/masher party-cost ratio, and nobody faints-free (lead faint 1.00 for both policies).

### Tidewake: Nerissa, L43, Rootiron (tier 1) vs Tidesteel (tier 2)

| Gear | Starter | Win M/R | Lead faint M/R | Party cost M/R | Max hit | Time M/R |
|---|---|---|---|---|---|---|
| Rootiron | galewisp | 1.00/1.00 | 1.00/1.00 | 0.438/0.343 | 0.14 | 127/243 |
| Rootiron | ripplet | 1.00/1.00 | 1.00/1.00 | 0.609/0.586 | 0.14 | 142/296 |
| Rootiron | terrapup | 1.00/1.00 | 1.00/1.00 | 0.671/0.661 | 0.15 | 144/316 |
| Tidesteel | galewisp | 1.00/1.00 | 1.00/0.88 | 0.350/0.373 | 0.14 | 113/221 |
| Tidesteel | ripplet | 1.00/1.00 | 1.00/1.00 | 0.560/0.499 | 0.14 | 136/267 |
| Tidesteel | terrapup | 1.00/1.00 | 1.00/1.00 | 0.650/0.633 | 0.14 | 141/307 |

**Tidesteel vs Rootiron:** masher party cost falls by 0.02–0.09; reader party cost falls by 0.03–0.09 for Ripplet and Terrapup and rises by 0.03 for Galewisp; worst hits are slightly smaller; clears are 2–11% faster. The previous tier is harder, but only modestly.

**C2 fails at both tiers:** reader lead cost equals masher's (ratio 1.00), and reader party cost is about the same as masher's. That is the fight's reader/masher separation (F22 / water lane), not gear.

### Cloudreach: Captain Veyra, Tidesteel (tier 2) vs Skyglass (tier 3), 12 seeds

| Gear | Starter | Lead faint M/R/S | Party cost M/R/S | Max hit | Time M/R | C2 (top) |
|---|---|---|---|---|---|---|
| Tidesteel | terrapup | 0.00/0.00/0.00 | 0.072/0.098/0.098 | 0.04 | 70/165 | FAIL |
| Tidesteel | ripplet | 1.00/0.17/0.00 | 0.236/0.169/0.055 | 0.08 | 100/259 | PASS |
| Tidesteel | galewisp | 0.00/0.00/0.00 | 0.128/0.112/0.048 | 0.06 | 88/215 | FAIL |
| Skyglass | terrapup | 0.00/0.00/0.00 | 0.060/0.094/0.094 | 0.04 | 67/159 | FAIL |
| Skyglass | ripplet | 0.83/0.25/0.00 | 0.225/0.165/0.047 | 0.07 | 98/235 | FAIL (masher kept lead once) |
| Skyglass | galewisp | 0.00/0.00/0.00 | 0.114/0.100/0.046 | 0.06 | 82/201 | FAIL |

- All runs are wins.
- Skyglass cuts masher party cost by 0.01–0.02 and clears 2–9% faster (median, either policy).
- Veyra deals at most 4–8% of max HP per hit, and with Terrapup or Galewisp the masher never loses its lead. The fight is too gentle for the top-trainer bar at either tier, so gear cannot make a difference there.

### Stormwood: Captain Marrow, Skyglass (tier 3) vs Stormglass (tier 4), 12 seeds

| Gear | Starter | Lead faint M/R/S | Party cost M/R/S | Max hit | Time M/R | C2 (top) |
|---|---|---|---|---|---|---|
| Skyglass | terrapup | 1.00/0.75/0.00 | 0.290/0.241/0.184 | 0.05 | 211/391 | FAIL (ratio) |
| Skyglass | ripplet | 1.00/0.92/0.00 | 0.337/0.229/0.077 | 0.06 | 168/369 | PASS |
| Skyglass | galewisp | 1.00/0.92/0.00 | 0.349/0.225/0.067 | 0.07 | 178/365 | PASS |
| Stormglass | terrapup | 1.00/0.75/0.00 | 0.261/0.241/0.180 | 0.05 | 201/378 | FAIL (ratio) |
| Stormglass | ripplet | 1.00/0.83/0.00 | 0.292/0.225/0.057 | 0.06 | 157/361 | PASS |
| Stormglass | galewisp | 1.00/0.83/0.00 | 0.312/0.217/0.057 | 0.06 | 170/350 | PASS |

**Stormglass vs Skyglass:** masher party cost falls by 0.03–0.05, switch-reader cost falls, reader cost is flat, and clears are 2–7% faster. That makes Skyglass the harder tier, as `boss_proof` asks.

**Passing:** Ripplet and Galewisp pass at both tiers. **Failing:** Terrapup fails the reader ≤ 0.55× masher party-cost bar at both tiers.

## Gaps this pass did not close

1. **Harness max HP is not applied.** `gear.json` declares +12% / 24% / 38% / 54% max HP, and HOMESTEAD §"Effect" says the Harness raises maximum HP. A creature's saved HP must stay intrinsic, so the smallest safe implementation is a fight-scoped incoming-damage divisor of 1 / (1 + max_hp), applied on the solo and host damage paths. The drawback is that the HP bar would not show a larger maximum. **Asked of the coordinator before building.**
2. **Charm ultimate gain** is credited only by the session host (`encounter_host.credit_move_hit`). The solo pilot has no ultimate meter, so these sims do not exercise it.
3. **Seeds.** These runs use 8 seeds (Meadows, Tidewake) and 12 (Cloudreach, Stormwood), not the 24 of the original Meadows protocol.
4. **What C2 depends on.** A boss's C2 pass depends on its pattern tuning, owned by F22 and the water lane. Gear moves every metric in the right direction, but it cannot create the reader/masher gap that Nerissa and Veyra lack.
