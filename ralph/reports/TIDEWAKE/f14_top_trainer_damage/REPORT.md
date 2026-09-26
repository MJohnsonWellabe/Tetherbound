# F14#0 / F14#1: top-trainer foe damage tunable (Calder, Tess, Venn, Nerissa)

**Verdict: PASS** for the four top trainers on C2's top-trainer bar and the measured part of C3. Every row is 24 seeds × 3 starters × READER/MASHER, party at L43.
- Nerissa is judged as the owner's "Guardian C2/C3" fight.
- The Abyssal Guardian itself stays N/A: it is not a combat boss (BOSSES §4.12).

## Authorization and mechanism
- **Authorization:** the coordinator's F14#0 ruling on #226, declared-number tuning, extended to Venn and Nerissa.
- **The tunable:** `data/config/water_characters.json` → trainer `foe_power_multiplier`.
- **How it reaches a fight:** `scripts/world/water_encounter_runtime_data.gd::team_member` is the one production translator. It writes `combat.power = (member combat.power, else combat.json enemy_trainer.power 10.4) × multiplier` into each team member. `trainer_npc.gd::creature_for` then hands that to `combat_override`. `enemy.damage_scale` (1.6) still applies once, afterwards.
- **Everything else is unchanged:** trainers without the key, every wild, and every other realm.

| Trainer | foe_power_multiplier | Effective strike power (× damage_scale) |
|---|---|---|
| Calder | 2.2 | 22.9 (36.6) |
| Tess | 2.2 | 22.9 (36.6) |
| Venn | 1.9 | 19.8 (31.6) |
| Nerissa | 1.8 | 18.7 (30.0) |

## Choosing the smallest value
**4-seed sweep:** masher team-wipe rate per lead, from `--multiplier-override`. The masher outcome is nearly all-or-nothing per starter, and the binding lead is Ripplet or Galewisp.

| Trainer | Lead | ×1.6 | ×1.8 | ×2.0 | ×2.2 | ×2.3 | ×2.5 |
|---|---|---|---|---|---|---|---|
| calder | galewisp | 0.00 | 0.00 | 0.00 | 1.00 | 1.00 | 1.00 |
| calder | ripplet | 0.00 | 0.00 | 0.00 | 0.50 | 0.75 | 1.00 |
| calder | terrapup | 0.00 | 0.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| nerissa | galewisp | — | — | — | 1.00 | 1.00 | 1.00 |
| nerissa | ripplet | — | — | — | 1.00 | 1.00 | 1.00 |
| nerissa | terrapup | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| tess | galewisp | 0.00 | 0.00 | 0.00 | 0.50 | 0.50 | 0.75 |
| tess | ripplet | 0.00 | 0.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| tess | terrapup | 0.50 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| venn | galewisp | 0.00 | 0.50 | 1.00 | 1.00 | 1.00 | 1.00 |
| venn | ripplet | 0.25 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| venn | terrapup | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

**Choices from the sweep:**
- **Calder and Tess:** the first swept value where every lead reaches at least 0.25 is 2.2. 2.1 was not swept.
- **Venn:** 1.8 was the sweep minimum, but at 24 seeds it gave a Galewisp masher wipe of 0.21 (`RUN_venn_1.8_partial.txt`). It was raised to 1.9, which passes.
- **Nerissa:** 1.8 passes at 24 seeds with wipe 1.00 for every lead. Values below 1.8 were not measured for Ripplet or Galewisp, so a lower Nerissa value may also pass. This is an open follow-up for the minimum, not a failure.

## 24-seed evidence (the shipped values)
`SUMMARY_TABLE.md` comes from `ralph/reports/TIDEWAKE/f14_veilfall_c2c3/summarize.py`. The raw data is in `G_<trainer>.json` and `RUN_<trainer>.txt` (Calder, Tess, Venn at 1.9, Nerissa).

| Trainer | Lead | Masher win / lead faint / wipe | Reader win | Reader median lead cost | Max hit |
|---|---|---|---|---|---|
| Calder | terrapup | 0.00 / 1.00 / 1.00 | 1.00 | 0.109 | 0.282 |
| Calder | ripplet | 0.38 / 1.00 / 0.62 | 1.00 | 0.106 | 0.195 |
| Calder | galewisp | 0.25 / 1.00 / 0.75 | 1.00 | 0.000 | 0.218 |
| Tess | terrapup | 0.00 / 1.00 / 1.00 | 1.00 | 0.061 | 0.202 |
| Tess | ripplet | 0.00 / 1.00 / 1.00 | 1.00 | 0.000 | 0.203 |
| Tess | galewisp | 0.71 / 1.00 / 0.29 | 1.00 | 0.000 | 0.202 |
| Venn | terrapup | 0.00 / 1.00 / 1.00 | 1.00 | 0.207 | 0.242 |
| Venn | ripplet | 0.00 / 1.00 / 1.00 | 1.00 | 0.205 | 0.244 |
| Venn | galewisp | 0.08 / 1.00 / 0.92 | 1.00 | 0.111 | 0.243 |
| Nerissa | terrapup | 0.00 / 1.00 / 1.00 | 1.00 | 0.205 | 0.166 |
| Nerissa | ripplet | 0.00 / 1.00 / 1.00 | 1.00 | 0.191 | 0.166 |
| Nerissa | galewisp | 0.00 / 1.00 / 1.00 | 1.00 | 0.105 | 0.166 |

- **C2 (top trainer):**
  - masher lead faints in every run;
  - masher team wipe is at least 0.25 for every lead (lowest: Tess with Galewisp, 0.29);
  - reader win is 1.00 for every lead, meeting the ruling's ≥0.90 as well as summarize.py's 0.75.
- **C3 (measured):** the largest single hit is 28.2% of the entry HP (Calder vs Terrapup), under 50%. Every tell is 0.80 s. Heavy tells never occur, so the heavy rule is not exercised.
- **Stalls:** 0 of 576 runs stalled. There are 0 harness errors.

## Limits (not claimed)
- Framing and readability at creature scale are not captured. C3's framing half needs rendered captures, which are ceded to Codex along with visual work.
- **Pacing (COMBAT §7, not a C2/C3 criterion):** reader fights take 166–506 s for a 3–4-creature team, as before this change. Faster reader play would need a pilot or Wind change, not this tunable.
- The pilot (`tests/helpers/combat_depth_pilot.gd`) now sidesteps travelling-lunge lanes (F04 `lunge_travels`). None of these four trainers authors a travelling lunge, so that change does not affect these rows.
- COMBAT §6's under-30% shifts, BOSSES §2.1 Y skills and Nerissa's Channel Cycle remain unbuilt and out of scope.
