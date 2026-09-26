# F14#0: named Tidewake encounters vs C2/C3 from the ordinary route

**Verdict: FAIL.** The four top fights, Tidecoil, Aquaryn, Calder and Tess, fail C2's top-fight bar: the masher's team never wipes, where C2 needs at least 25%. Against Tidecoil (Ripplet or Galewisp leading) and against Aquaryn, the masher's lead also never faints, where COMBAT §7 needs every run.

Every other encounter passes the parts that were measured. Nothing was tuned, and no threshold was relaxed. The per-row data is in `SUMMARY_TABLE.md`, the verdict rules in `summarize.py`, the raw runs in `*.json`, and the logs in `RUN_*.txt`.

## Tier assignment

C2 does not tier named wilds, so this report assigns them:

| Tier | Encounters | Rule applied |
|---|---|---|
| floor | Pell | the reader floor |
| top | Tidecoil, Aquaryn, Calder (strongest critical non-Veilfall trainer), Tess (strongest non-Veilfall trainer) | the top-fight rule |
| named wild | Sentinel, Basalt Claw, Root Watcher, Songweaver | the reader-to-masher HP-cost ratio (at most 0.55) plus reader win of at least 90% |
| ladder | Tovin, Solm, Irva, Bex | 8 seeds, informational only |

## C3

- **Largest single hit:** across 1,488 fights, the largest was 9.9% of an entry creature's HP. That was Water against Ground, which is harsher than a neutral hit.
- **Tells:** every tell was at least 0.80 s. Aquaryn's were 1.25–1.70 s. No other foe ever used a heavy tell, so the 1.1 s heavy rule holds only because heavies never occur.
- **Framing and readability:** not measured. This needs a rendered capture at the normal fight camera.

## Likely cause (for the COMBAT/BOSSES owner)

- **Profiles are not wired.** Water foes fight on species defaults. The trainer `combat_profile` value (WALL, CHARGER, ACE and so on) is not read by any script. Calder's `_comment` in `water_characters.json` calls it "intent ... not an implemented AI selector".
- **No named-wild overrides.** Named wilds spawn with no combat override.
- **No heavies or skills.** No Water foe sets `charged_every`, has a Y skill, or has a profile power multiplier.
- **Named-fight designs are not built.** BOSSES §4.9 (Tidecoil's intensity bands) and §8 (the named-wild templates) are target, not built.
- **Result:** every hit is a small, dodgeable 0.80 s quick attack. The reader loses only 0–10% of its lead's HP where C2 passes, so those passes are shallow.

## Pacing (COMBAT §7; not a C2/C3 criterion)

Against Tess and Calder, reader fights take 55–113 s per creature, against a 30–60 s target. This is consistent with the slowdown after the Wind resource landed in 9c77c1e62.

## Method

- **Harness:** `tests/smoke_water_named_c2c3.gd` over the shared `tests/helpers/combat_depth_pilot.gd`, unmodified. It uses the real CombatManager, the wild AI and real physics bodies on a flat collider.
- **Policies:** READER and MASHER.
- **Party:** the retained five at L43, the Tidewake entry level. The lead cycles through Terrapup, Ripplet and Galewisp. No items are used.
- **Foes:** built as production builds them, with Aquaryn's HP phases applied.
- **Engine:** Godot 4.7 headless, `--fixed-fps 60`.
- **Seeds:** 24 per starter per policy; 8 for the ladder trainers.
- **Outcome:** every run exited 0, with no errors and no stalls.

**Pilot artefact:** a fainted lead ends a wild fight, and the pilot never switches creature by hand. Terrapup's 0% masher wins against named wilds therefore partly reflect the pilot.

**Not covered:** terrain and arena geometry, Aquaryn's surface-channel runs, manual switch, burst and Y, co-op scaling, and a blind footage review.

**Excluded as F14#1:** Venn, Fennel, Morra, Evi, Nerissa and the Guardian.

## Next

1. Wire the Water combat profiles, Tidecoil's §4.9 bands, the §8 named-wild templates, the charged cadence and Y. Then rerun `--case=tidecoil,aquaryn,calder,tess`.
2. Add a reader switch-on-mismatch policy to the shared pilot.
3. Capture C3 framing with one render per named encounter.
4. Repeat from an earned Tidewake save once F13 produces one.
