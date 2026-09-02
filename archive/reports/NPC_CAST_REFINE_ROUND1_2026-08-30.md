# T1-NPC-CAST — refine round 1: Team Tether, then Village

Owner instruction, live in-session: *"do team tether then villagers. use as
little budget as you can to still do the job well."* Scoped to the 7 Team
Tether subjects and the 8 clean Village subjects (`traveling_merchant`
excluded — its preview candidates all fused the cart into the body
geometry, see `NPC_CAST_PREVIEW_ROUND1_2026-08-30.md`; refining a broken
reference would waste credits, not save them). Trail & Wilderness was not
in scope for this round and stays preview-only.

## Budget discipline

One refine candidate per subject, not three — this pipeline's own stated
rule ("cheap preview, then two or three serious candidates, then spend
only on the winner") applied literally: the preview round already
produced three comparable candidates per subject and none of the 15 in
this batch showed a per-candidate quality problem worth paying to compare
again at refine tier (unlike `traveling_merchant`/`wandering_trainer`,
where a specific candidate was visibly broken).

**Real measured cost came in under the plan.** `meshy.py`'s own `COSTS`
table said refine was 40 credits; it is actually **30**, confirmed by
balance checked before and after both batches with zero variance across
15 separate calls (7 × 30 = 210 exactly, 8 × 30 = 240 exactly). Corrected
`COSTS["image_refine"]` in `tools/art_pipeline/meshy.py` to 30 with a
comment recording how it was measured, the same discipline that file's own
history already used once for preview pricing (5 → 20).

| Step | Before | After | Spent |
|---|---|---|---|
| Team Tether refine (7 × 1 candidate) | 1,440 | 1,230 | 210 |
| Village refine (8 × 1 candidate) | 1,230 | 990 | 240 |
| **Total** | | | **450** |

Planned for 600 (15 × 40, the stale rate); actual came in at 450 — 150
credits under plan, purely from the corrected per-unit cost, not from
cutting scope. **Balance is 990**, clear of the 900 reserved for the
sibling T1-CREATURE-MESH lane by 90 credits, with no need to ask for an
exception to that reserve this round.

## Result — 15/15 succeeded, fetched, reviewed

All 15 refine tasks polled to `SUCCEEDED` (parallel fetch, 10 workers, 0
failures). GLBs and thumbnails landed at `assets_raw/<slug>/refine_a/` —
gitignored, not committed, per this pipeline's standing convention.
Contact sheets built and sent directly to the owner
(`shots/npc_cast_refined_team_tether.png`,
`shots/npc_cast_refined_village.png` — also gitignored render evidence,
not committed).

**Team Tether — the rank silhouette differentiation reads clearly now, at
full texture.** `officer_a`/`officer_b` show visibly longer coats than the
grunts; `captain_a`/`captain_b` show full-length flowing capes, distinct
in cut and colour from both ranks below them (`captain_a`'s pale
silver-white cape especially). This is the render-proven gap from earlier
in this lane, closed.

**Village — all 8 read distinctly and match their board panels.**
Innkeeper (heavyset, green scarf, apron), Inn Helper (young, mustard
dress), Trader (hooded, muted green/brown), Craftsperson (goggles, tool
belt), Creature Caretaker (sage green, satchel), Farmer (straw hat,
pitchfork carried in-mesh — a held prop rather than a true separate
accessory, acceptable), Local Historian (elderly, cane, muted coat),
Young Trainer (cap, backpack) — no reruns needed on any of these eight.

## What's not done, on purpose

- **`traveling_merchant`**: still needs a genuinely person-only reference
  crop (the cart bled into every preview candidate) and a fresh preview
  roll before anything is spent refining it.
- **Trail & Wilderness (8 subjects)**: preview-only, not in this round's
  scope. `wandering_trainer` has two clean preview candidates (B, C) ready
  to refine without a re-roll when that group is picked up; the other
  seven are clean as previewed.
- **Installation**: none of these 15 GLBs are wired into
  `data/config/art.json`, placed at a production `assets/characters/`
  path, rigged, or animated. They are refine-tier textured meshes, not
  yet playable NPCs — matching this project's own established pipeline
  order (generate → install → rig/animate → wire in), and that install
  step was outside what was asked for this round ("do team tether then
  villagers" was read as the generation step, not the full in-engine
  integration, given the explicit budget-consciousness of the ask).
- **Rigging/animation credits**: not spent, not estimated here — a
  separate cost this report deliberately does not fold into "as little
  budget as you can," since it wasn't asked for yet.

## File footprint, this round

- **Changed:** `tools/art_pipeline/meshy.py` — `COSTS["image_refine"]`
  40 → 30, with a comment recording the measurement.
- **Changed:** `docs/ASSET_LEDGER.md` — new row for these 15 generated
  subjects, provenance, cost, and the two deferred subjects named.
- **Added:** this report.
- **Not committed (gitignored, by design):** `assets_raw/<slug>/refine_a/`
  (15 GLBs + thumbnails), `shots/npc_cast_refined_*.png` (sent to the
  owner directly).
