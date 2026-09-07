# Lane W18-DENSITY-B4-B5 — content after the village, bands 4 and 5 (CL-O4 density half; addendum §B/§C)

Branch: `ralph/W18-DENSITY-B4-B5-0904`. Model tier: world content authoring (creating).

Same brief as the bands 2–3 lane (read `ralph/briefs/0904/W17-DENSITY-B2-B3.md` first — the owner quotes, the documents, and the **pickup data contract** are identical and binding), applied to Upper Meadows (band 4, `band4_upper_meadows_ironwood`) and the Stronghold Approach (band 5, `band5_stronghold_approach`). Note D70: band 5 is short on purpose — its density is a crescendo of occupation, not a repeat of band 1; read it and `docs/prompts/65`, `66`, and the P-5.x rows of `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` before authoring.

**The loader (`scripts/world/band_pickups.gd`) is being written by the bands 2–3 lane on branch `ralph/W17-DENSITY-B2-B3-0904`.** Do NOT write your own. Fetch that branch periodically (`git fetch origin ralph/W17-DENSITY-B2-B3-0904`); once the loader and `tests/test_band_pickups.gd` exist there, cherry-pick or merge that branch into yours (a merge is fine; say so in the report) to run your `pickups.json` through it. Until then, author `pickups.json` to the schema and validate it statically (JSON parses; ids unique; items exist in `data/items/items.json`; positions inside the band's spine extent from `docs/specs/MEADOWS_MACRO_LAYOUT.md` / `terrain_playground.json`).

**Author bands 4 and 5:** ~40 pickups across the two bands (roughly 22 Good / 12 Great / 5 Rare, plus revives/potions/mushrooms sited before the Sigil captains, the ridge, the checkpoint and the final camp decision — recovery arriving BEFORE the attrition it supports; secrets and the hardest optional encounters get Rare), wild clusters and harvest nodes raised with authored reason (ironwood stands, the wind ridge, the healed vs drained ground, the outer watch), keeping the captains, the Sigil gate, the R-3 doorstep alpha and Ness untouched. Every entry gets a `why`.

**Owns:** `data/config/bands/band4_upper_meadows_ironwood/{spawns,harvest,props,pickups}.json`, `data/config/bands/band5_stronghold_approach/{spawns,harvest,props,pickups}.json`, `tools/_probe_band_density.gd` only if the other lane has not created it (check first; otherwise reuse), `ralph/reports/W18-DENSITY-B4-B5-0904/`. **Do not touch** `vegetation.json`, `trainers.json`, `stronghold_occupation.json`, bands 1–3, `items.json`, `playground_world.gd`, or the loader.

**Verify.** Same test list as the bands 2–3 lane, plus `smoke_stronghold`, `smoke_relay_station`; same per-band census numbers in the report against band 1; one xvfb frame of a Rare candy at a band 4 secret with the judge's read on tier legibility.

**Acceptance.** Both bands' numbers move materially with authored `why`s; band 5 keeps D70's shape; `docs/WORLD_AND_CONTENT.md` updated; `docs/CURRENT_STATE.md` CL-O4 (bands 4–5) rewritten.
