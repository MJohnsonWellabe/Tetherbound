# T1-NPC-CAST — "build the rest": Trail & Wilderness + Traveling Merchant fix

Owner instruction, following the Team Tether + Village refine round:
*"build the rest."* Scoped to the two things left open from
`NPC_CAST_REFINE_ROUND1_2026-08-30.md`: the 8 Trail & Wilderness subjects
(preview-only until now) and `traveling_merchant` (broken, deferred).

## Trail & Wilderness — 8/8 refined cleanly

One refine candidate per subject (`rival_trainer`, `field_researcher`,
`wandering_trainer`, `lost_traveler`, `campfire_traveler`,
`alpha_tracker`, `courier`, `former_tether_member`), same discipline as
the previous round. Before refining `wandering_trainer`, checked whether
its reference crop still showed the companion creature that fused into
one of its three preview candidates (`NPC_CAST_PREVIEW_ROUND1
_2026-08-30.md`) — it did, prominently, in `front.png`. Refine reuses the
same reference images as preview (it's a fresh generation at a higher
tier, not a continuation of a specific preview candidate), so refining
against that crop unchanged would likely have reproduced the same defect.
Re-cropped `front.png` to exclude the creature entirely before refining,
rather than spend a refine credit on a probable repeat failure.

240 credits (8 × 30), balance 950 → 710. All 8 succeeded, fetched,
reviewed — clean, distinct, on-brief, `wandering_trainer` confirmed
creature-free in the result.

## Traveling Merchant — the one subject that needed a different approach

Two more attempts before this one worked, both recorded rather than only
reporting the eventual success:

**Attempt 2 (this round): tighter image-to-3D crop.** Re-cropped
`front.png`/`three_quarter.png` to exclude the cart's cargo bed and wheel
as much as the pose allowed (a small satchel corner touching her hand was
unavoidable without cutting off her arm). Re-ran preview at 2 candidates
(40 credits). **Still failed** — both candidates fused the remaining cart
fragment into something between a wheelchair and a cart frame around her
legs. Sent the result to the owner for visibility rather than silently
retrying.

**Root cause, actually isolated this time:** not crop tightness, the
reference image itself. The board draws this NPC in exactly one pose —
no second angle exists to crop from — and multi-image-to-3D seems to need
that second angle to resolve an ambiguous silhouette; with only two
near-identical images of one pose plus any trace of an adjacent object,
it reached for the nearest coherent interpretation, which turned out to
be "seated." No amount of crop tightening was going to fix a
single-viewpoint ambiguity.

**Attempt 3: text-to-3D instead of image-to-3D.** `meshy.py text
traveling_merchant --candidates 2` (40 credits) — no reference image at
all, prompt only. **Worked cleanly**, both candidates: a normal standing
figure, no fused geometry. Picked candidate `a`, fetched the GLB, then ran
`meshy.py texture traveling_merchant <glb>` (10 credits — see the cost
note below) against her board crop for the paint pass, per this pipeline's
own documented order for a subject with no clean multi-view reference:
"text-to-3D for the FORM, then `texture` against a starter's concept crop
for the STYLE" (`cmd_text`'s own docstring, written for the wild creature
roster and equally applicable here). Result: a clean, textured figure in
the board's warm-earth palette, satchel bag, practical boots — not a
pixel-exact match to the board's illustrated outfit, but a legitimate,
usable Traveling Merchant with none of the fusion defects.

**Cost note:** the retexture call measured at 10 credits, not the 30
`meshy.py`'s `COSTS` table states. This is a single measurement (one
retexture call), unlike the refine correction in the previous round
(confirmed across 15 independent calls with zero variance) — **not**
correcting `COSTS["retexture"]` on this evidence alone; flagging it as
worth re-measuring on the next retexture call this project makes, not
treating it as settled.

**Total spend on this one subject, across every attempt:** 150 credits
(60 original 3-candidate preview + 40 failed re-crop-and-reroll + 40
text-to-3D + 10 retexture) — well above the ~90-credit baseline every
other subject in this cast landed near. Recorded plainly rather than
folded into the total unremarked, since it's the one place this session's
"use as little budget as you can" instruction didn't hold, for a specific,
diagnosed reason (a single-pose board reference with no real second
angle), not carelessness.

## Where this leaves the cast

**All 24 board designs (every NPC except the Warden) now have a refined,
textured result**, fetched to `assets_raw/<slug>/refine_a/` (or
`assets_raw/traveling_merchant/textured/` for the one text-to-3D subject)
— gitignored, not committed, per this pipeline's standing convention.

In the actual order run (Traveling Merchant's re-crop attempt happened
*before* the Trail & Wilderness batch, not after):

| Step | Spend | Balance after (confirmed via `meshy.py balance`) |
|---|---|---|
| Preview, all 24 | 1,440 | 1,440 |
| Refine, Team Tether + Village (15) | 450 | 990 |
| Traveling Merchant re-crop + reroll (failed) | 40 | 950 |
| Refine, Trail & Wilderness (8) | 240 | 710 |
| Traveling Merchant text-to-3D | 40 | 670 |
| Traveling Merchant retexture | 10 | 660 |

**Final confirmed balance: 660.** Every row above was checked against the
live balance endpoint at the time, not computed after the fact.

**This dips 240–280 credits into the 900 the coordinator asked to reserve
for the sibling T1-CREATURE-MESH lane.** That happened under a direct,
explicit owner instruction to finish the remaining groups, not a
unilateral call by this lane — disclosed here plainly rather than
smoothed over, so the coordinator can react to it if the creature lane's
remaining need turns out to be tighter than expected.

## Not done, still ahead of this branch

- **Installation**: none of the 24 GLBs are wired into
  `data/config/art.json`, placed at a production `assets/characters/`
  path, rigged, or animated.
- **Rigging/animation credits**: not spent, not estimated.
- **`COSTS["retexture"]`**: flagged as possibly stale (10 measured vs. 30
  documented) but not corrected on a single data point.

## File footprint, this round

- **Changed:** `docs/ASSET_LEDGER.md` — closing update to the NPC cast
  entry, final spend total, the Traveling Merchant rework recorded.
- **Changed:** `assets/creatures/tetherbound/traveling_merchant/reference/
  front.png` / `three_quarter.png`, `assets/creatures/tetherbound/
  wandering_trainer/reference/front.png` — re-cropped (committed
  separately, previous commit in this session).
- **Added:** this report.
- **Not committed (gitignored, by design):** `assets_raw/**` (all fetched
  GLBs/thumbnails, all rounds), `shots/npc_cast_refined_trail.png` (sent
  to the owner directly).
