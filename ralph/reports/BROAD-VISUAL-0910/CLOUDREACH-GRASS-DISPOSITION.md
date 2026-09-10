# Cloudreach grass disposition — 2026-09-10

Cloudreach grass work is stopped after repeated clean native captures and blind judgments found no substantial overall improvement. Do not revive these mechanisms without new evidence that changes the diagnosed cause.

## Held candidates

1. `cloudreach-cover-candidate01.patch` — tightened camera clearance and compacted tuft scale. Native tests/captures passed. Blind judgment found no meaningful preference; the dominant lawn and shelf remained.
2. `cloudreach-footprint-candidate02.patch` — replaced generic landmark holes with geometry-aware structure footprints. Native validation passed after one preserved parse failure/fix. Judgment found modest wall-edge planting only and no overall coverage improvement; baseline retained better immediate foreground blades.
3. `grass-basal01-held.patch` — added a low splayed basal storey to the shared tuft without raising instance counts. Four-biome captures were clean. Gull Rest and South Bridge judgments found no meaningful overall preference.
4. `cloudreach-far-turf-candidate03.patch` — added analytic world-space far-turf value structure to existing crown/ridge surfaces across the 260m cover handoff. Six native frames passed. Judgment found no meaningful terrain/vegetation preference; root read it as blurred greens rather than grass.

## Evidence retained

- `ralph/reports/BROAD-VISUAL-0910/JUDGE-CLOUDREACH-COVER01.md`
- `ralph/reports/BROAD-VISUAL-0910/JUDGE-CLOUDREACH-FOOTPRINTS01.md`
- `ralph/reports/BROAD-VISUAL-0910/GRASS-BASAL01-HELD.md`
- Native run logs and all matched frame directories under `.artifacts/broad-visual-0910/runs/` and `shots/catalogue/`.

## Conclusion

The dominant distant green shelf is real supported turf roughly 430m from the Gate camera, beyond the 260m blade range. Blade silhouette, local eligibility, and analytic colour breakup each failed to change the scene-wide read. A later attempt needs a different art mechanism with real mid-distance vegetation masses or redesigned terrain composition, plus a performance budget; further tuft tuning, blanket density, local clearance edits, and blurred procedural colour are exhausted.

Far-surface verdict: ralph/reports/BROAD-VISUAL-0910/JUDGE-CLOUD-FARTURF01.md. These paths name retained evidence, not passing visual acceptance.
