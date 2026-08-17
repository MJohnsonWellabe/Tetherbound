# Band 2 (Stone & Root) — round 5 (measurement only, no new frames committed)

**What was tested.** Merged `origin/ralph/HARVEST-ALL` (tree/rock density
3.4x/3.9x, `ralph-status`/`ralph/NOTES.md`) and re-ran the identical 8
viewpoints, to test whether the single largest available density lever
would move the #1/#2 recurring complaint (night, bare ground) that every
round from 1 through 4 has named.

**Result: zero measured effect on these specific viewpoints.**
`tools/survey_band2.gd`'s own `spread` numbers came back byte-identical to
round 4's for every one of the 8 frames, and `tools/frame_stats.py` on the
two frames checked directly (early-forest, late-ridge) shows no movement
beyond the same JPEG-compression offset already established as noise in
round 2→3. Visual inspection confirms it: the rendered frames are pixel-
identical to round 4's.

**Why, and it's a real finding, not a shrug.** `HARVEST-ALL`'s own note is
explicit that it raised `per_clump`/`strays` *within* existing tree/rock
clumps and deliberately left `clumps` (copse centres) untouched, "already
tuned across five visual passes." Band 2's specific bare stretches (the
ones this whole loop has been trying to dress) don't happen to sit near an
existing tree/rock clump centre — so a density multiplier that thickens
clumps has nothing to multiply there. The lever is real and it is not
mine to move: retuning where clumps are *sited* is squarely
`vegetation.json`'s layer-rules territory, explicitly not something a band
content author edits (per this branch's own standing instruction).

**Not spending a fifth blind-critic round on pixel-identical images to
round 4's** — that would just reconfirm round 4's verdict at the cost of a
render and a critique for a result already known with certainty from the
numbers above. Recorded here as measurement, not as a round in the
convergence sense.

**Where this leaves the loop:** four real critic rounds run (1 baseline,
2 and 4 showed genuine movement — critic-named and `frame_stats`-measured
respectively — round 3 was the first flat round), plus this null result on
the best available lever outside the band's own file ownership. The three
recurring top-ranked gaps across every round — night illegibility, bare
ground beyond what hand-placed harvest nodes can dress, and shared-asset
material/texture quality (the quarry's rootstone, the Warrens' wall, the
absence of a full leafy-canopy tree asset, zero creatures ever appearing in
frame) — are consistently named as things a content-only author cannot
reach: they need a lighting fix, a clump-siting change, or new/different
art, none of which are `data/config/bands/band2_stone_and_root/*.json`'s to
make. Full writeup and recommendation in `ralph/NOTES.md` on `ralph-status`.
