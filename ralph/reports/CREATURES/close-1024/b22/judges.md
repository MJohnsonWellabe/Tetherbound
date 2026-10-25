# b22 (24 Oct 2026, CPU candidate pick): texture-level fixes for the aspect variants Stormtrail and Riftfrill

Background:
- Owner on the GPU sheet: "Stormtrail: bad", "Riftfrill: doesn't work, too dark, not legible".
- Coordinator: both stay on their base meshes (owner-sheet aspect variants), so the fix happens at texture level.

The candidates:
- `data/creatures/aspect_variants.json` was re-specced and the repaints regenerated with `tools/generate_aspect_variant_textures.py`.
- Stormtrail:
  - cool storm-grey coat (in place of the near-black one);
  - lighter muzzle and chest;
  - the hard gold leg/flank lightning dropped;
  - one soft blue storm line along the spine, with a matching glow;
  - storm veins at intensity 0.8.
- Riftfrill:
  - lighter River Teal body;
  - lighter belly and throat, painted by region (normals facing down);
  - lilac only on the crest and frill;
  - both glows at half intensity, so they read as accents, not a full-body starfield.
- Base: shipping at land 5cecc01bd. This run has no b19 lift; the lift is dropped for these two on the lane.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1, f36_0_gap:C1, craft. This is a confirming batch.
- Fit: slope 1.161, intercept -0.683, RMSE 0.25.

| Species | Shipping | Repaint | Next |
|---|---|---|---|
| stormtrail | 5.58 | **7.21** | GPU READY |
| riftfrill | 5.93 | **6.63** | GPU READY; judges still name the glossy skin and the rear-up hit |

Judges on the repaints:
- Stormtrail "close to the Tanglevolt bar", but grey on grey without rim light.
- Riftfrill: the teal identity reads, a pale belly, and a speckle remains on the back.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
