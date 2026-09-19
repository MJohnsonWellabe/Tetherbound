# Stormwood current status survey — 2026-09-19

## Bottom line

Stormwood currently stands at **0 PASS / 5 POLISH / 7 FAIL / 0 unknown** across 12 named locations. The inherited `0 / 5 / 6 / 1 invalid` handoff was almost right, but Crown Arch's later valid production evidence converts the invalid row to FAIL.

Content is also below its specified floor: **63 of at least 160 dialogue conversations**, **8 of 12 live recipes**, and **533 explicit replacement points**. The replacement count is higher than the inherited 461 because current data contains 401 wild clusters and 62 trainer party slots; this is real data growth, not a visual promotion.

## Named-location ledger

| # | Named location | Current grade | Evidence-backed reason |
|---:|---|---|---|
| 1 | The Struck Sentinel | POLISH | Retains the inherited POLISH grade. Full survey shows strong obstruction by a near trunk and weak delivered landmark framing; no later PASS receipt exists. |
| 2 | Verge Rod Station | FAIL | The station reads as a small isolated pale pylon/monument with little surface information; the trainer and encounter are hidden. Explicit FAIL in the final handoff. |
| 3 | Rodline Post | POLISH | Retains inherited POLISH. A readable settlement hint and appealing small creatures exist, but sparse ground, actor/pickup overlap and weak composition prevent PASS. |
| 4 | The Capacitor Grove | POLISH | Retains inherited POLISH. The canonical view is dominated by clipped magenta spider limbs; no accepted later whole-location promotion exists. |
| 5 | Lantern Hollow | POLISH | Retains inherited POLISH. Settlement elements exist, but pale primitive-like bases and the absence of a convincing lantern-lit night focal keep it below PASS. |
| 6 | The Fallen Giant | FAIL | Explicit final-handoff FAIL. Valid frames do not present a fallen-tree landmark and show physically incoherent creature/trainer staging. |
| 7 | The Glass Field | POLISH | Retains inherited POLISH. The location remains obscured by an extreme creature close-up and does not demonstrate a glass-field identity strongly enough for PASS. |
| 8 | The Stormheart Tree | FAIL | This is the sixth inherited FAIL implied by the 0/5/6/1 aggregate and the only remaining non-POLISH/non-invalid row. Full and targeted reviews show the named tree is not a commanding landmark; the thin coil/beam and foreground creature dominate instead. |
| 9 | The Lantern Pools | FAIL | Explicit prior valid-survey FAIL. No pool is visible; repeated dark floor/isolated props and weak night-light relationships do not deliver the named place. |
| 10 | Crown Overlook | FAIL | Explicit prior valid-survey FAIL. The corridor opens onto sparse rolling ground without a meaningful overlook destination; later shadow work was narrow and remained A No / B No. |
| 11 | The Crown Arch | FAIL | Reconciled from invalid. `STORMWOOD-CROWN-ARCH-0909.md` supplies valid production day/night and ordinary-camera contexts, but independent review answers A No / B No; the arch remains blocky, pale and under-integrated. |
| 12 | The Crown Heartstone | FAIL | Explicit final-handoff FAIL. The focal is overwhelmed by a giant close creature and repeated distant forms; the landmark/ritual composition is not readable. |

Aggregate: **0 PASS + 5 POLISH + 7 FAIL + 0 unknown = 12**.

The per-row POLISH assignment is reconstructed from the archived 0/5/6/1 aggregate and its explicit FAIL/invalid disclosures. The archive did not print a 12-row table. That limitation is recorded rather than presented as stronger provenance than exists. The later complete blind report supplies direct visible findings for every row, and no later receipt promotes any Stormwood location.

## Content-floor recount

### Dialogue: 63 / >=160

`data/dialogue/stormwood.json` currently contains **63 conversation properties** and **186 delivered line entries**. The historical 57 figure used conversations as “dialogue nodes,” so the comparable current numerator is 63, not 186. Counting lines would silently change the metric.

### Recipes: 8 / 12 live

The live recipe book `data/recipes/recipes_stormwood.json` contains eight recipe IDs:

`insulated_helm`, `insulated_vest`, `rod_mast`, `voltcap_stew`, `glowmoss_tonic`, `stormglass_orb_socket`, `stormglass_lining`, `thunderwood_frame`.

`data/config/stormwood_items_recipes.json` contains a 12-recipe integration payload, but four rows are not in the live recipe book: `stormglass_arch`, `lightning_rod`, `moss_lantern`, and `insulated_workbench_upgrade`. The floor therefore remains **8/12**, not 12/12.

### Explicit replacement points: 533

The recount recursively counts every property named `replacement_point` in the current explicit placeholder-bearing Stormwood data:

| Source | Count | Composition |
|---|---:|---|
| `stormwood_encounters.json` | 444 | 36 table-role points + 401 wild clusters + 6 named encounters + 1 legendary placeholder |
| `stormwood_trainers.json` | 88 | 26 trainer roots + 62 party slots |
| `stormwood_dynamo.json` | 1 | captive placeholder |
| **Total** | **533** | 533 unique explicit points; no duplicate point identities found in the recount |

Compared with the inherited 461, this is **+72**: wild clusters increased to 401 (+71 versus the earlier basis) and the trainer-party accounting gained one point.

## What is working versus what is accepted

- Current source contains substantial playable systems, encounters, trainers, routes and a completed connected Deepwood Circuit side-chain path.
- Later reports demonstrate targeted functional progress and retained palette/ground-cover improvements.
- Those facts do not convert any named-location row to PASS. The accepted visual evidence still shows a thin repeated forest, weak forest-floor/root integration, creature/camera crowding, under-authored electrical landmarks and route thresholds, and night values that often separate bright creatures/props from a dark flat environment.
- Five other configured Stormwood side chains still lack complete authored player interactions. That is supplemental context; the requested Stormwood floor in this survey is dialogue, recipes and replacement points.

## Gap to the current biome bar

Stormwood would need accepted evidence that every named location first reaches at least POLISH and ultimately PASS, with a convincing layered deep-forest floor/canopy, rooted vegetation, readable storm/electrical landmarks, authored approach thresholds, controlled creature staging, coherent night silhouettes, and a Stormheart that reads as the biome climax. Separately, the content floor still needs 97 or more comparable dialogue conversations and four live recipes. This describes the gap only; it is not authorization or a scoped repair plan.

## Evidence boundary

Primary evidence is committed at `1a357d3e` (corrected 24-frame survey), `2f41763a` (independent rejudge history), `e42ff4a1` (valid Crown Arch evidence), `44473241` (retained palette direction), `4e150c65` (Deepwood Circuit), and `5a3f6c56` (remaining side-chain audit). Local metadata does not reliably map those commits to PR numbers, so none is invented. No new render was necessary or taken for this survey.
