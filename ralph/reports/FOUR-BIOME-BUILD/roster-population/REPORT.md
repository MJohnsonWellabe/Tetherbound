# ROSTER population report — 2026-09-07

## Outcome

The creature-table half of the ROSTER matrix is closed on
`codex/roster-population-0907`, based exactly on integration commit `2b8eea015`.
All 32 newly installed species now occur in an authored later-biome wild,
trainer, named, alpha, or legendary row. The only Meadows species retained in
those tables are the three reuse anchors named by the authoritative roster:
Galecrest in Cloudreach, Sparkit in Stormwood, and Mosshell in Water.

This was a static-only pass under the AUTOSAVE Godot lock. No Godot process,
import, render, export, world placement, encounter position, group count, level,
weight, catchability, or combat tuning was changed.

## Authored mappings

### Cloudreach

- Pebbik: lower-cliff `ledge_forager`.
- Craghorn: causeway `stone_hold`; durable/terrain trainer anchor.
- Stormcapra: high-roost `shrine_guard`, upper `storm_charger`, edge-denial trainer.
- Skyrill: lower `air_scout`; switch-punisher/switching-ace trainer roles.
- Aeriex: wind/crosswind controller and wind-tutor roles.
- Ribbonray: causeway `air_patrol`, high-roost `perch_flock`, air finisher.
- Breezetail: causeway `bridge_ambusher`, summit `engine_scavenger`, fast opener.
- Cloudfang: ravine/plateau/cold-front hunter and pursuer roles.
- Cliffspike: upper `night_ledge_stalker` and disruptor.
- Tempestwing: high-roost `rare_glider`, explicitly tagged `alpha_catch`.
- Solmane: summit `summit_sentinel`, explicitly tagged `legendary`.
- Galecrest remains only as the documented reusable flight anchor.

### Stormwood

- Voltwig: cinder forager and vine climber.
- Glimmermoth: glass lurker, night glider, and crown wisp.
- Stormbrush: late ash charger.
- Mosshock: pool drifter/ambusher, moss grazer, and Blackwater elder.
- Staticub: crown keeper, giant rooter/ember scavenger, and Crown Guardian.
- Tanglevolt: storm runner, ridge/fence stalker, and old hall guardian.
- Stormraven: edge scout, arc diver, and canopy hunter.
- Thundertunnel: ash digger and conduit gnawer.
- Voltarach: every authored `*_alpha` named encounter.
- Fulgocobra: the existing `legendary_placeholder` row.
- Sparkit remains only in `spark_darter` ecology and trainer slots as the
  documented reusable Electric anchor.

Trainer parties follow the same old-role-to-new-ecology substitutions. All
existing `replacement_point` strings remain byte-for-byte unchanged.

### Water

The merged Water encounter catalogue already named every board species in its
wild/named/scripted rows. This pass closed the remaining runtime presentation
and trainer seams:

- each new namespaced Water definition now overrides its legacy source body
  with the corresponding installed board model in `water_roster.json`;
- Fen's Brooktail slot is now Sirenseal and Rune's Galecrest slot is now
  Riverdrake;
- Mosshell is explicitly marked `reused_meadows_anchor`;
- the existing authoritative identities remain Aquaryn for the midpoint Alpha
  (`water_aquaryn`) and Abyssal Guardian for the release legendary.

Legacy `source_species` fields in `water_roster.json` remain solely as the
catalogue adapter's collision-safe source for default presentation dimensions
and animations. They are not encounter placements; each runtime `model` field
now points at the installed new species mesh.

## Tests added or updated

- Added `tests/test_four_biome_roster_population.gd`:
  - all 32 installed IDs exist and are placed in their intended biome;
  - later-biome table IDs are limited to that biome's new roster plus its one
    documented Meadows anchor;
  - Tempestwing/Solmane, Voltarach/Fulgocobra, and
    Aquaryn/Abyssal Guardian identity pairs are exact;
  - Water runtime presentation paths equal the installed species model paths.
- Updated `tests/test_water_encounter_runtime_data.gd` so every trainer party
  member must translate through the Water board namespace; there are no longer
  Brooktail/Galecrest encounter exceptions in authored trainer data.

## Static validation completed

```text
JSON parse: cloudreach_chapter.json, stormwood_encounters.json,
stormwood_trainers.json, water_roster.json, water_characters.json — PASS

Installed species + model path existence for all 32 new IDs — PASS
Full placement matrix and exact allowed-anchor census — PASS
Cloudreach/Stormwood/Water identity assertions — PASS

Invariant comparison against 2b8eea015:
levels, weights, counts, positions, catchability, trainer ownership,
replacement_point values, and named/legendary mechanics — PASS

git diff --check — PASS
```

## Godot validation awaiting lock release

These were intentionally not run while AUTOSAVE held exclusive Godot:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_four_biome_roster_population.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_cloudreach_chapter_data.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_encounters_data.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_trainers_data.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_encounter_catalogue.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_water_species_catalog.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_water_encounter_runtime_data.gd
godot --headless --path . --script tests/smoke_art.gd
```

ROAD-VISUAL-CREATURES owns gameplay placement anchors, scale/readability,
materials, and rendered/blind-judge evidence. This report's mapping section is
the handoff for that lane; no such work was performed here.
