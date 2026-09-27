# F14#1: Captain Nerissa C2 in the actual Water world, 3 starters x 24 seeds

**Result: C2 PASS for Nerissa (the owner's "Guardian C2/C3" fight).**

- Harness: `tests/smoke_tidewake_named_inworld_c2.gd`, one fight per process, driven by
  `tests/batch_tidewake_named_inworld_c2.gd` (added on this branch).
- Setting: the actual Water world, the Heart Chamber body, the production summon and
  challenge prompt, CombatManager and the hosted roster. The shared READER/MASHER
  pilot presses the real input actions.
- Code: `tb/tidewake-full` 4398c59e. Nine render.yml headless dispatches (runs
  36332036090, 36332038055, 36332039969, 36332042090, 36332043519, 36332044868,
  36332046530, 36332048409, 36332050397). Raw result lines are in `runs/*.jsonl`
  and the table below is `python3 summarize.py runs`.

| starter | pilot | n | win | party wiped | median lead HP lost | median party HP lost | max single hit (of entry HP) | tells (s) | reached all 4 |
|---|---|---|---|---|---|---|---|---|---|
| galewisp | MASHER | 24 | 0.00 | 1.00 | 1.00 | 1.00 | 0.166 | 0.8-1.1 | 21 |
| galewisp | READER | 24 | 1.00 | 0.00 | 0.78 | 0.153 | 0.178 | 0.8-1.1 | 24 |
| ripplet | MASHER | 24 | 0.00 | 1.00 | 1.00 | 1.00 | 0.166 | 0.8 | 0 |
| ripplet | READER | 24 | 1.00 | 0.00 | 0.533 | 0.116 | 0.134 | 0.8-1.1 | 24 |
| terrapup | MASHER | 24 | 0.00 | 1.00 | 1.00 | 1.00 | 0.166 | 0.8 | 0 |
| terrapup | READER | 24 | 0.88 | 0.00 | 1.00 | 0.241 | 0.152 | 0.8-1.1 | 21 |

## Against ACCEPTANCE C2/C3
- **Top fight, reader win >= 75%:** 1.00 / 1.00 / 0.88. Met.
- **Top fight, masher team wipe >= 25%:** 1.00 on every starter. Met.
- **Reader median HP cost <= 55% of masher:** party HP 0.153 / 0.116 / 0.241 against
  1.00 (ratios 0.15 / 0.12 / 0.24). Met. The lead-only measure is disclosed too:
  galewisp 0.78 and terrapup 1.00, because the lead often faints before a teammate
  finishes; party HP is the team measure for a five-member trainer fight.
- **C3, any single neutral hit leaves > 50% of entry HP:** largest hit is 17.8% of entry HP.
  Met.
- **C3 tells:** ordinary tells 0.8 s; Riptusk's heavy Break Tether 1.1 s, taught per
  BOSSES §4.11. Met.
- C3 framing is judged separately from the capture in `../f14_c3_judge_full/`.

## Shortcuts disclosed
- The party is granted: the original five at L43, with the named starter leading.
- The player is placed in front of Nerissa.
- Her two upstream pump flags (`water_veilfall_intake_stopped`,
  `water_veilfall_return_opened`) are set.
- The fights are harness-driven (READER/MASHER policy), headless on CPU runners.
- There is no HP, damage, victory or roster injection.
- The co-op half is `ralph/reports/INVITE-COOP/x05-f14-nerissa-r5/` on `tb/x05` (not
  rerun here).
