# Stormwood named encounters and Crown path

## Base and scope

- Branch: `codex/stormwood-named-crown-0907`
- Base: `3c7a250facc8b56cad2a0f5c6e6a4700e6bea0d6`
- Worktree: `C:\Projects\Tetherbound-stormwood-mainpath`
- Hosted combat was not changed or reproven.
- No shared encounter, session, save, HUD/map, import, other-biome, roster, Dynamo, or aftermath file was touched.

## Implemented

- The six authored `named_encounters` are appended to the production Stormwood `wild_config()` as fixed-position, fixed-level, fixed-species one-body entries.
- Named orders are deterministic hashes in `[100000, 199999]`; ordinary cluster orders begin at `300000`. Reordering either catalogue cannot move or reroll a named encounter.
- Each named encounter uses its authored G-3 profile through the existing per-body combat override, and its authored catchability through the production wild/trainer-owned catch rule.
- The shared once-only alpha contract is reused without editing the shared director. Runtime `wild_once_<order>` ids translate to durable `stormwood:named:<id>:cleared` flags. Both win and catch outcomes therefore set the same stable flag and skip ordinary respawn.
- `crown_guardian` now exists in that production population. Its clear flag is part of the chapter persistence contract.
- Archivist Wen selects an explicit guardian refusal after the Crown is reached, and cannot select the truth conversation until the guardian clear flag exists. The chapter objective also independently rejects `dialogue:wen_truth` before that flag.
- The Crown heartstone remains visible with a state-specific status, but is non-actionable until both guardian clear and engine truth. The Rootgate objective independently names both prerequisites.

## Static evidence completed under the SAVE resource lock

- `data/config/stormwood_encounters.json` and `data/config/stormwood_chapter.json` parse through PowerShell `ConvertFrom-Json`.
- Confirmed six unique authored named ids, all currently once-only.
- Confirmed all six derived named orders are unique and below the ordinary order namespace:
  - hollows_alpha `183570`
  - capacitor_alpha `180992`
  - crown_guardian `187544`
  - old_rodfolk_hall_guardian `182398`
  - blackwater_elder `167600`
  - glass_field_alpha `175623`
- Confirmed the Crown guardian flag is in `persistent_flags.main` and is a prerequisite of both engine truth and Rootgate release.
- `git diff --check` passes.

## Exact tests intentionally not run

Godot was not launched because the root task's SAVE lock explicitly forbids Godot/import/render/export until release. These are staged for the first runtime proof after release:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_encounter_catalogue.gd,test_stormwood_encounters_data.gd,test_stormwood_named_crown.gd
godot --headless --path . --script tests/smoke_stormwood_crown_heartstone.gd
godot --headless --path . --script tests/smoke_stormwood_chapter_prefix.gd
```

The first command proves production config inclusion, fixed authored fields, disjoint deterministic orders, G-3 overrides, catchability, stable once-id translation, and saved-clear suppression. The Crown smoke proves the interaction is refused before guardian clear and before truth, then releases exactly once after both. The chapter-prefix smoke is the nearest existing production-world regression for the chapter/NPC mount.

## Status

Implemented and statically checked; runtime proof is intentionally pending the SAVE lock release.
