# CODEX — pull in the new pickup assets, then finish the Meadows

**Written 2026-09-04.** This is the routing document for a fresh Codex session picking
up this repository. It replaces the generic `CODEX_START_HERE.md` / `PROMPT_THOUGHTS.md`
pair the owner had a separate tool draft — those reference files that do not exist in
this repository's current state (`docs/VISUAL_PARITY_PROGRESS.md`,
`docs/TETHERBOUND_VISUAL_BIBLE_V2.md` at the top level, `docs/VISUAL_PARITY_STAGED_GOAL_PROMPT_V2.md`)
and predate the 2026-09-02 repository reset. Do not read them. Read this instead.

## 1. Read in this order

1. `CLAUDE.md` — hard rules, binding, override everything below.
2. `docs/00_START_HERE.md` — the one routing document; it points at
   `docs/FINISH_THE_MEADOWS.md` and `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md`,
   which are the actual work plan.
3. `docs/CURRENT_STATE.md` — evidence-backed status; trust it over any self-report.
4. This file, for what changed today and where the new assets live.
5. `docs/prompts/73-PROGRESSION-VISIBLE-bond-and-level-feedback.md` — the bond/level
   feedback contract, written today, first in the addendum's own execution order.
6. `docs/prompts/74-ART-REFERENCE-owner-boards-for-meshy.md` — what art exists now,
   what is still needed, and the procedural-first task for the signpost and bridge.

**Do not throw away in-flight work.** If a branch already has committed progress,
checkpoint and continue rather than resetting. Commit and push after each coherent
step; never merge to `main` yourself — land through a pull request per
`docs/00_START_HERE.md`'s branch rules.

## 2. What exists now that didn't exist this morning

Four pickup meshes, generated through Meshy against an owner-supplied board and
already installed, textured (three of them), coloured, and oriented correctly:

| Asset | Path | Notes |
|---|---|---|
| Candy (all 3 tiers) | `assets/props/candy_pickup/candy_pickup.glb` | Textured. One mesh for Good/Great/Rare — tint + a medallion-decal swap per tier. Rare's wings are NOT in this mesh (the board draws them as real geometry); add them as small separate child meshes only on the Rare instance, don't regenerate. |
| Revive flower | `assets/props/revive_flower/revive_flower.glb` | Textured, upright, base at local origin. |
| Potion plant | `assets/props/potion_plant/potion_plant.glb` | Textured, upright. One mesh for small/medium/large — scale at placement time, matching the addendum's own note that these are growth-stage variants, not different objects. |
| Mushroom (all 3 tiers) | `assets/props/mushroom_pickup/mushroom_pickup.glb` | **Untextured mesh, coloured via vertex colours** (cap orange-red with a polka-dot pattern, cream stem/gills) rather than a baked texture — the raw generation had no usable UVs. One mesh for Speed/Stamina/Wild — tint via `material_override` (with `vertex_color_use_as_albedo` on) for Speed (blue) vs Stamina (the shipped orange); Wild Shroom's broader cap is a non-uniform scale, not a second mesh. |

Full provenance, task ids, credit spend, and exactly why each was oriented the way it
is: `docs/specs/ASSET_LEDGER.md`, the two entries dated 2026-09-04 near the end of the
file (search `Meadows pickup props`).

**All four load like any other prop in this codebase** — a plain `.glb`, no rig, no
animation — through the same seam `scripts/world/item_cache_pickup.gd` already uses for
one-time world pickups (`key_pickup.gd`'s TM-orb sibling; the file's own header explains
why it is generic rather than key-specific). `setup(item_id, label, model_path,
model_scale)` handles the satchel flag, save-safe one-time collection, and the shared
`pickup_glow.gd` highlight. **No new pickup mechanism is needed** — do not build one.

## 3. What is deferred, and why

`meadows_signpost` and `meadows_bridge_section` were **not** generated. The owner's
instruction: try editing the existing procedural signpost/bridge to read closer to the
reference board first, and spend the credit only if that fails. The task, grounded in
the actual scripts (`scripts/world/signpost.gd`, `scripts/world/gated_crossing.gd`,
`data/config/building_prefabs.json`), is `docs/prompts/74-ART-REFERENCE-owner-boards-for-meshy.md`
§7. Reference crops and prompts are already staged (`tools/art_pipeline/prop_views.json`,
`SPECIES_PROMPTS` in `meshy.py`) so the Meshy fallback is one command if the procedural
pass is judged insufficient — do not re-stage them.

`docs/art/reference/17_Candy_Revive_Potion_Mushroom_Pickups.png` and
`18_Signpost_Bridge_Modular_Props.png` are the owner boards these came from, for anyone
who needs to see the target look. `19_Meadows_Asset_Boards_Visual_Direction.png` is a
broad style moodboard across categories mostly already covered by installed assets or
barred by the one-nature-family / one-village-family hard rules — treat it as direction,
not a generation queue.

Remaining balance on the owner's Meshy account after this batch: **125 credits.** Do not
spend it without checking `docs/specs/ASSET_LEDGER.md`'s art-source order first
(installed asset → free pack → Meshy) — the mushroom entry there is a cautionary tale:
120 credits were spent chasing a generation before anyone checked
`assets/environment/nature/` and `assets/environment/stylized_nature/`, which already
had usable mushroom meshes. Check first next time.

## 4. Wiring the four assets in — this session's actual task

None of this is done yet. In order:

1. **Item definitions.** `data/items/items.json` already has `revive`, `potion_small`,
   `potion_large` as working item ids with heal/revive effects — they just have no
   world-model art until now (point their pickup instances at the new meshes). `good_candy`
   / `great_candy` / `rare_candy` and the three mushroom buff items **do not exist yet** —
   this is new item-effect plumbing (a level-up effect kind nothing in the item schema
   currently has; a duration-limited stat buff for mushrooms). Design it carefully against
   `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md` §B's "Progression safety" checklist
   before authoring the data — level cap behaviour, what happens when +2/+3 would cross
   it, and whether candy funnelled onto one creature can trivialise a required encounter
   are explicitly things to test before mass placement, not after.
2. **Material per tier.** `candy_pickup.glb` and `mushroom_pickup.glb` need a
   `material_override`-driven tint (and, for candy, a medallion decal texture swap) per
   tier at instancing time — the same economy `character_model.gd` already uses for
   villager palettes and `tm_orb`'s own material job (see that row in
   `docs/specs/ASSET_LEDGER.md` for the exact pattern: shell texture with the emissive
   region separated out, hue-shifted per variant). Rare Candy's wings: two small
   primitive or kitbashed meshes as children of that one instance only.
3. **Placement.** `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md` §B and §C give the
   counts and the regional-batch contract (~100 candy at a 60/30/10 Good/Great/Rare
   split, ~100–150 total findables including candy, authored per band, never a uniform
   scatter). Do not author all of them in one pass — regional batches, tested and landed
   incrementally, per the addendum's own execution order.
4. **Progression feed.** Candy's level-up must push through the feed
   `docs/prompts/73-PROGRESSION-VISIBLE-bond-and-level-feedback.md` defines, not a
   separate silent path — the addendum is explicit about this. If that prompt's feed
   is not yet built, build it first; candy consumes it, it does not invent its own event.
5. **Companion presence and everything else in `docs/FINISH_THE_MEADOWS.md` /
   `docs/GATE2_GATE3_CLOSURE_PLAN.md`** continues exactly as those documents describe —
   nothing about today's art batch changes the rest of the plan or its ordering. The
   phase-0 instrument fixes (route strip, harness input context, the S08 freeze) are
   still the most blocking items in the project; do not let a fun art-wiring task pull
   focus from them if this session has a choice of what to pick up next.

## 5. Standards that apply to this work like any other

- Test the real interact-driven pickup path (`tests/`, Gate F harness), never assume a
  model that imports cleanly is a model that plays correctly.
- Render and blind-judge the new props in place before calling a regional batch done —
  `docs/VISUAL_BIBLE.md` and the visual-judge skill, same as any other visual work.
- `docs/AGENT_WORKFLOW.md` §4–6 before pushing. Branch rules, CI expectations, evidence
  template — all unchanged by this batch.
- If a design question comes up that nothing in the repo settles (which candy tier goes
  where, exact buff durations, the wing attachment's exact silhouette), record the
  decision in `docs/decisions/` per `docs/00_START_HERE.md`'s standing rule rather than
  inventing it silently or blocking on the owner.
