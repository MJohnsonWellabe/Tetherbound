# Items and hero props: bounded visual audit

Date: 2026-09-27. Independent image-only review against ART_DIRECTION.md. No implementation, configuration, previous audit reports or engine inspection. This records visible evidence and priorities; it is not whole-game acceptance or a refinement plan.

## Evidence and branch boundary

- Current inventory: `shots/ranked-audit-current/_sheet_inventory_icons.jpg`, 89 labelled item definitions displayed at 64px. The capture owner reports 46 unique icon paths; this count was not independently checked in source. Visual duplication is directly observable in the sheet.
- Unmerged PR355: `D:/tetherbound/visual-acceptance-local/meshy-bottle-badges.jpg`, six frontal Meshy bottle variants. These are pending candidates, not current main-game bottle evidence.
- PR365 candidate: `ralph/reports/VISUAL/_sheet_tether_machine.jpg`, baseline/candidate held day/night and candidate released day/night.
- PR365 candidate: `ralph/reports/VISUAL/_sheet_tidewake_local_sites.jpg`, Gull and Deep landing, approach, near and night panels. These are candidate-site evidence, not whole-main Tidewake acceptance.

World sheets are scaled composites of DRY RUN fixtures. They support broad visual comparisons, not native-pixel defect certification, motion, earned gameplay, on-device performance or Bars A/B acceptance.

## Ranked findings

1. **Current inventory item identity — FAIL.** Most icons are crisp, but many distinct items share an indistinguishable image: hide/insulated armour; berries/cloudberry/preserve/seeds; multiple fibre, stone and wood resources; most TMs. Wild mushroom, voltcap and voltcap stew also share an image. Labels carry distinctions the artwork does not. Distinct silhouettes or large secondary marks have higher value here than finer ornament.

2. **Tether machine whole-asset finish — WEAK.** In both held day/night rows, irregular bright metal highlights produce dense visual noise, while the captive creature is difficult to separate from surrounding machinery. Candidate suspension and small cyan plaques improve structural/state cues without resolving the underlying finish or prisoner hierarchy. Monumental scale and entrance framing remain strengths. This is a PR365 candidate comparison, not acceptance of the main-game machine or the whole asset.

3. **Gull station discovery and integration — WEAK.** `gull: 1_landing` does not present an apparent station lure; `gull: 2_approach` does. The near station reads as a credible chart site, but grass crowds the working area and conceals lower supports. Deep is stronger across `deep: 1_landing`, `2_approach`, `3_near` and `4_night`: visible destination, clear canopy/chart silhouette, clearer working area and readable illuminated chart face. These are PR365 candidate findings only.

4. **Current small tool icons — WEAK.** Torch nearly disappears at the shown slot size. Fishing rod and knife have substantially less visual weight than neighbouring tools. Hoe and pickaxe are insufficiently differentiated. Recognition at actual slot size is the relevant deficit.

5. **Pending bottle family — retain, with recognition coverage gaps.** PR355's six frontal variants show coherent glass, leather, brass and cork treatment. Large badges distinguish the displayed variants; light/dark fields help class separation. However, the shared green 3D silhouette contrasts with inventory icons that rely heavily on bottle shape and colour. Cross-view recognition remains a question. This frontal sheet cannot establish pickup-distance, reverse-view or grass-obscured identity. PR355 remains unmerged.

## Retained strengths and missing coverage

Retain the inventory's consistent palette and contrast, clear heart/shield/lightning marks, distinguishable orb tiers and sigils. Retain the bottle candidate's coherent craft treatment, the machine's monumental staging, and Deep's restrained night illumination.

These sheets do not establish the wider current-main pickup, gatherable, camp, saddle or held-tool roster in use. Missing evidence is not proof that those assets fail. The findings support a scoped priority ranking, not a whole-prop-family or Bars A/B pass.
