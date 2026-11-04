# REPO-SLIM — ready for landing

Branch `tb/repo-slim-1104`. Archive commit `8f318bb4d`. Base: `origin/main` `98879e2e1`. ci.yml is untouched (it belongs to CI-SPEED).

## Measurement (CI engine-job sparse checkout)

The size is computed from `git ls-tree -r -l` using ci.yml's engine pattern: `/*` minus `ralph/ docs/ shots/ assets_raw/ archive/` and minus `tests/fixtures/earned_saves/f49_*/save/`.

| | files | bytes |
|---|---|---|
| before (`98879e2e1`) | 16,839 | 7.48 GB |
| after (`8f318bb4d`) | 16,723 | 6.55 GB |
| saved | 116 | 0.93 GB (12%) |

The saving is smaller than the 7 GB problem suggested. Of the 5.72 GB scanned:
- 4.62 GB is REFERENCED. A `data/` file names it (often a flag-OFF candidate, which counts as referenced), a script or test names it, or it is an extracted texture of a named glb.
- 0.16 GB is KEPT_POLICY: provenance, references, scale checks, previews, prompts, scripts and Blender sources.

## Archive safety

- `tb/meshy-archive` = `98879e2e1` (main as it stood) was pushed before anything was removed.
- `git ls-tree -r origin/tb/meshy-archive` contains all 116 removed paths (0 missing).
- `git diff --name-status origin/tb/meshy-archive HEAD -- assets` shows exactly 116 `D` lines. The only other asset changes are 59 provenance records, which gained an `"archived"` block.
- Restore instructions: `assets/ARCHIVED_ASSETS.md`.

## Classification

- `manifest.json`: every file under assets/creatures/tetherbound, props/meshy-*, crossing_hall_hero, generated_camp, realm_gate_meshy and vl-1103, each with path, size, class and why.
- `asset_reference_graph.py` builds it from a revision.
  - Seeds are all text outside the excluded evidence trees.
  - It matches path, basename, stem, directory, uid and dynamic `%s`/`{x}`/`*` patterns.
  - It follows .import twins, glTF extracted textures and glTF uris to a fixpoint.
- `patterns.txt` logs the dynamic patterns it used. One prefix-only check was excluded by hand, the `begins_with` in `test_water_species_catalog.gd`.

Largest archived groups:
- 643 MB: raw Meshy downloads in `creatures/*/candidate_owner1101/source/`. The processed `/models` stay on main and ship.
- 83 MB: r9/r10 sources.
- 65 MB: meshy-1031 props that no file names.
- 24 MB: crossing_hall_hero `source-v2`.
- 57 MB: older b4/nat1022/nat1024 creature candidates.

## Proofs

- **Import:** CI fast tier, run 41750152969 on `8f318bb4d`. The `export` job passed: import cold, import verify, Windows export, and the exported build runs with ground under the player. The bake freshness checks also passed.
- **Unit tests:**
  - `verify-suite (3)`: 2,319 tests, 0 failed. `test_texture_import_policy` is visible by name in the log.
  - `verify-suite (4)`: 2,451 tests, 0 failed.
  - `test_remake_owner1101_finish` and `test_hero_landmarks_1101` are in `tests/test_*.gd`, which the unit shards run, but their names are not in the log tails I could fetch.
  - The `ci-gate` aggregator passed (01:18Z), so the whole fast-tier run is green.
- **Creature capture smoke:** render.yml run 41750298706, `tools/_capture_creature_roster.gd` at `8f318bb4d`. Passed (script ran; "Fail if the script failed" green).
- **Spot-check, zero references:** for each of the five archived glbs, `git grep -F <basename>` outside ralph/docs/shots/archive/assets_raw finds only its own provenance.json, which now carries the "archived" note. The five:
  - abyssal_guardian_a.glb
  - cannonback_b.glb
  - fulgocobra_b.glb
  - riptusk_a.glb
  - creature_mudsnout_nat1024.glb (no hits at all)
- A local `godot --import` was not possible: the container's disk allowance is spent by the 21 GB history pack. The CI import above is the import proof.

## Tier 2 (coordinator ask): none found

Tier 2 would be a referenced candidate glb that meets all of these:
- only `data/*.json` names it;
- no script, test, tool or asset resource names it;
- every naming entry is OFF;
- every naming entry's text records a judged rejection ("reject", "regressed", "flat", "stays off", "parked", "below bar").

A strict scan found 0 such files. Every flag-OFF candidate is either also named by a script, test or tool, or its entry does not record a rejection. Nothing was moved under tier 2.
