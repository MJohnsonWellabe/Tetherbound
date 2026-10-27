# b52-b53: Breezetail harness print simplified (CPU, three judges each); parked

GPU CO8 (3/3 judges): Breezetail's blue harness print is busy and reads as a costume.

Both rounds use a torso-only vivid colourway rule (`where` z_min 0.38; the tail keeps its blue feather accents):
- **b52:** blues desaturated, closed 6 px over the print lines, smoothed 4 px, set to hue 212 / sat 0.26, keeping 40% of the form.
  - Every judge scored both sides the same: 5.6 / 5.6 / 6.0. Harness PRESENT x3 on both. **0.00.**
- **b53:** a stronger swing: closed 10 px, smoothed 6 px, hue 212 / sat 0.10 (a muted grey-blue cloth), keeping 25% of the form.
  - Mapped 5.99 vs main 5.90 (+0.09; fit r 0.60, RMSE 0.75, not confirming).
  - Harness PRESENT x3 on main; PARTIAL, PRESENT, PRESENT on the candidate.
  - The judges still read "a patterned garment"; the print's dark lines and the strap geometry carry the costume read.

Call: **parked after two rounds under 0.5.** No asset change committed; the b53 candidate rule is kept as `candidate.diff`.

Policy conflict, for the coordinator: any vivid rule beyond the single source-preserving one fails `test_cloudreach_source_colourways :: test_policy_preserves_authored_anatomical_regions` ("breezetail uses one source-preserving rule"). That pin guards against the old neon recolours. A harness fix through the colourway would need that policy amended for Breezetail; I did not touch the test.

Judges' other repeated reads: Breezetail seated "only just clears the ruler" (3/3); they suggest a muted leather strap, removing the harness, or growing it. Removing the harness or changing its material changes the board identity (the reference sheet draws the blue harness), so that is a new-art or owner call.
