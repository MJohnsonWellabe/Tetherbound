# F14#1: Veilfall encounters and the Guardian vs C2/C3

**Verdict: FAIL.** The two Veilfall top fights, Officer Venn and Captain Nerissa, fail C2's top-fight bar: the masher's team wipes in 0% of Venn runs and at most 8% of Nerissa runs (Terrapup lead), where C2 and COMBAT §7 need at least 25%. Every other part passes: the reader wins every run, the masher's lead faints every run, and C3's measured half passes. Fennel, Morra and Evi pass C2 and C3. The Abyssal Guardian is **N/A**: in production it is not a fight.

Nothing was tuned, and no threshold was relaxed. The per-row data is in `SUMMARY_TABLE.md`, the verdict rules in `summarize.py` (F14#0's script plus the new tiers), the raw runs in `E_veilfall_trainers.json` and `F_veilfall_top.json`, and the logs in `RUN_*.txt`.

## One row per fight

All three starters, 24 seeds each, READER and MASHER, party L43. The ranges below span the three starters.

| Fight | Tier (rule) | C2 | C3 (measured) | Reader win | Masher win / lead faint / wipe | Median s, masher / reader | Failure reason |
|---|---|---|---|---|---|---|---|
| Officer Venn (Cannonback, Riptusk, Riverdrake, all L53) | top | FAIL | PASS | 1.00 | 1.00 / 1.00 / 0.00 | 165–208 / 198–373 | masher team wipe 0.00 < 0.25 (all starters) |
| Captain Nerissa (Cannonback, Mirejaw, Riverdrake, Riptusk, all L55) | top | FAIL | PASS | 1.00 | 0.92–1.00 / 1.00 / 0.00–0.08 | 214–258 / 256–501 | masher team wipe 0.08 (Terrapup), 0.00 (Ripplet, Galewisp) < 0.25 |
| Fennel (Mirejaw53, Mangrove Monitor53) | veilfall_trainer | PASS | PASS | 1.00 | 1.00 / 0.00–1.00 / 0.00 | 62–136 / 102–208 | — (reader/masher lead-cost ratio 0.00–0.06) |
| Morra (Cragclaw54, Mirejaw54, Cannonback54) | veilfall_trainer | PASS | PASS | 1.00 | 1.00 / 1.00 / 0.00 | 179–228 / 212–425 | — (ratio 0.06–0.09) |
| Evi (Sirenseal54, Riverdrake54, Mosshell54) | veilfall_trainer | PASS | PASS | 1.00 | 1.00 / 1.00 / 0.00 | 148–201 / 183–367 | — (ratio 0.00–0.07) |
| Abyssal Guardian (L55) | none | N/A | N/A | — | — | — | Not a fight: BOSSES §4.12 says "This is not a combat boss" |

The wipe column is meaningful for all five trainers. A trainer fight continues after the lead faints and ends only when the whole team is down. The F14#0 wild-fight limit, where a fight ends when the lead faints (combat_manager.gd:2799), therefore does not apply here. It would apply only to a Guardian wild fight, and no such fight exists.

## Which fights count, and the tier rules

**Fights found.** Veilfall's trainers in `water_characters.json` are Fennel, Venn, Morra, Evi and Nerissa. No `named_encounters` row is on Veilfall. Veilfall's `wild_sites` belong to ordinary tables and are out of scope for this task.

- **Captain.** `water_veilfall.json` names `captain_encounter_id: water_trainer_nerissa`. `water_veilfall.gd::_place_captain` reuses the same trainer spec and only moves it into the Heart Chamber, gated by `captain_requires`.
- **Guardian.** It is `guardian_species_id: water_abyssal_guardian` at `guardian_level: 55`. The `water_encounters.json` scripted reference `water_abyssal_guardian_release` gives its role as `legendary_ceremony_not_wild_or_named_combat_census`.

**Rules applied:**

- **Top rule (Venn and Nerissa).** COMBAT §7 reads: "Top trainer from Meadows Band3 onward: reader wins≥75%; masher loses its lead every run and loses the full team in≥25% of runs." ACCEPTANCE C2 gives the same bar for "top fights from band3". Venn and Nerissa are the only Veilfall trainers with their own BOSSES §4 major-fight entries:
  - Venn, §4.10: "the exterior Veilfall exam"; §8 lists him as "ACE; Veilfall gate".
  - Nerissa, §4.11; §8 lists her as "ACE; final captain". PROGRESSION §3 lists Tidewake's "final team test".
- **Normalized rule (Fennel, Morra and Evi).** None of them has a BOSSES §4 entry. They get C2's general rule, "reader median HP cost ≤55% of masher", plus a reader win of at least 90%. This is the same rule F14#0 used for its floor, named-wild and ladder tiers, so nothing is relaxed.
  - **Sensitivity for Morra.** Morra has three L54 creatures, more than Venn's L53, but no §4 entry. Under the top rule she would fail too, with a 0.00 masher wipe on all starters.
- **Guardian.** BOSSES §4.12 says: "This is not a combat boss. The Guardian is captive until Nerissa falls." §8 lists "scripted non-combat offer". In `water_veilfall.gd::_build_guardian`, the body has collision layer and mask set to 0 and `set_physics_process(false)`. Releasing it is a control interaction followed by the offer ceremony, `water_guardian_reward.gd`. There is no production fight to pilot, so C2/C3 are N/A.
  - **Proof-gap note.** ACCEPTANCE T2/F14 say "Veilfall and Guardian pass C2/C3". For the Guardian that can only be met vacuously, or through the freeing fight, which is Nerissa. If the owner means the Nerissa fight, it FAILs above.
- **Party level: L43.** COMBAT §7 measures "at region-entry levels", and PROGRESSION §3 gives Tidewake as "L43 overlap → L55". No spec gives Veilfall a separate entry level, so the rule applies as written. Even so, the reader beat the L53–55 teams in every run. A higher, earned party would make the missing masher wipes even less likely.

## C3 (measured half)

- **Largest single hit.** Across 720 runs, the largest was 12.9% of an L43 entry creature's HP, from Nerissa's L55 team. Venn's peaked at 12.8%, and the three other trainers at 9.9% or less. All are far below the 50% ceiling, and these are not only neutral matchups.
- **Tells.** Every tell was exactly 0.80 s. No foe used a heavy or charged attack, so the 1.1 s heavy rule holds vacuously. That includes Nerissa's specified "Break Tether ... 1.1 s heavy tell" on Riptusk, which is not built.
- **Framing and readability.** Not measured. This needs a rendered capture at the normal fight camera.

## Mechanics the pilot could not exercise

- **Nerissa's Channel Cycle, Pressure Rise and Break Tether.** BOSSES §4.11 calls them "a **target integration**, not current acceptance". No code implements them: a grep for channel sweeps, phases or a Nerissa controller under `scripts/` finds only the reward ledger. The production fight is the plain hosted four-creature roster, and that is what was measured. Once they land, the fight must be remeasured.
- **Venn's per-creature WALL, CHARGER and CURRENT roles (BOSSES §4.10).** Every trainer's `combat_profile` (ACE, WALL, CURRENT, DIVER) is unwired. The `_comment` fields call it "intent ... not an implemented AI selector". All foes fight on species defaults.
- **Arena staging.** The Heart Chamber arena, waterline and cover are not reproduced. The fixture is flat, as in F14#0.
- **Pilot limits.** Manual switch, burst and Y are not exercised, and the reader does not dodge a travelling lunge lane. These are known F14#0 pilot limits.

## Likely cause of the failures (for the COMBAT/BOSSES owner)

This is the same cause as F14#0's top fights.

- **Foes are soft.** Water trainer foes have no profiles, heavies, Y or power multipliers. Every incoming hit is a 0.80 s quick attack that takes at most 13% of HP.
- **Result for the masher.** Its party loses a median of 55–95% of total HP against Venn and Nerissa. It usually loses 2–4 creatures but almost never all 5. The maximum was 5 faints, in 2 of 24 Terrapup runs against Nerissa.
- **What would change it.** The unbuilt Nerissa staging (10% max-HP channel sweeps) and Break Tether's heavy CHARGER are the specified sources of the missing pressure. Wiring the ACE, WALL and CHARGER profiles would add more. The F14#0 coordinator ruling also authorizes a per-trainer foe damage-throughput tunable for top trainers.
- **What this report does not claim.** Whether wiring them would reach a 25% wipe rate is not predicted here. That needs the same run repeated after they land.

## Pacing (COMBAT §7; not a C2/C3 criterion)

- **Venn.** A "named multi-creature fight" has a 2–5 min target. The reader's median runs from 3.3 min (Galewisp) to 6.2 min (Terrapup).
- **Nerissa.** As the finale, her target is 3–7 min. The reader's median runs from 4.3 min to 8.4 min (Terrapup).
- **Other trainers.** Per creature, Morra and Evi take the reader about 60–140 s against a 30–60 s target. This is consistent with F14#0's pacing note.

## Method

- **Harness.** `tests/smoke_water_named_c2c3.gd`, F14#0's harness, extended only by five `TRAINER_CASES` entries (kinds `veilfall_top` and `veilfall_trainer`) and a comment on why the Guardian has no case. The shared `tests/helpers/combat_depth_pilot.gd` is unmodified. Everything else is unmodified: the real CombatManager, WildCreature AI and physics bodies on a flat collider.
- **Foes.** Built as production builds them. `water_encounter_runtime_data.gd` translates the species and level, and `trainer_owned` is true. There is no per-creature override, and a solo fight gets no co-op scaling.
- **Party.** The starter plus bramblebun, mudsnout, pipwing and trailpup, all at L43. No items are used.
- **Engine and seeds.** Godot 4.7 headless with `--fixed-fps 60`, 24 seeds per starter per policy. Seed = `hash("<case>/<starter>/<i>")`.
- **Outcome.** 720 runs, all exited 0, with 0 errors and 0 stalls.
- **Commands.** Each was run with its own `XDG_DATA_HOME`, one job at a time:
  - `godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=fennel,morra,evi --party-level=43 --json=E_veilfall_trainers.json`
  - `godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=venn,nerissa --party-level=43 --json=F_veilfall_top.json`
  - `python3 summarize.py ralph/reports/TIDEWAKE/f14_veilfall_c2c3 > SUMMARY_TABLE.md`
- **F14#0 cases.** They are unchanged. Running this `summarize.py` over `f14_named_c2c3/` reproduces F14#0's `SUMMARY_TABLE.md` exactly, plus the added Guardian N/A row.

## Next

1. **Build the fights, then rerun.** Build Nerissa's §4.11 staging and Break Tether heavy, and wire the ACE, WALL, CHARGER and CURRENT profiles, or apply the authorized top-trainer damage-throughput tunable. Then rerun `--case=venn,nerissa`.
2. **Settle the Guardian wording.** The owner or ACCEPTANCE should say whether "Guardian passes C2/C3" means the Nerissa freeing fight or is N/A.
3. **Capture C3 framing.** Render the Heart Chamber at the normal fight camera.
