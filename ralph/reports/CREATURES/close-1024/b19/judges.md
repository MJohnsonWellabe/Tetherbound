# b19 (24 Oct 2026, CPU candidate pick): value lift for the dark remakes (owner GPU-sheet verdicts)

What was compared:
- Owner on Cindercub: "needs a bit of definition and features".
- Owner on Riftfrill: "too dark, not legible".
- Owner on Stormtrail: "bad".
- Candidate: a hue-preserving albedo lift through the existing `field_emission` lever (Cindercub 0.8, Stormtrail 1.0, Riftfrill 1.0).
- Base: shipping at land 5cecc01bd.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1, f36_0_gap:C1, f04_6_r22. This is a confirming batch.
- Fit: linear, slope 0.884, intercept 1.259, RMSE 0.41.

| Species | Shipping | Lift | Next |
|---|---|---|---|
| cindercub | 6.88 | **7.15** | READY for GPU |
| stormtrail | 6.59 | 6.77 | Lift helps, but the hard yellow emissive leg bands read as UV artefacts. A distinct storm treatment or Meshy is needed (see note). |
| riftfrill | 6.03 | 6.21 | Lift helps, but the galaxy/starfield skin reads synthetic. Needs a Meshy redraft (see note). |

Judges also ask for:
- a grounded hit flinch instead of the rear-up;
- tails clear of the ruler.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
