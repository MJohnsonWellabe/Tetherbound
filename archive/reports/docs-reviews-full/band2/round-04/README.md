# Band 2 (Stone & Root) — round 4

**What changed since round 3.** Three `berries` harvest nodes (two near the
early-forest viewpoint, one near the late-ridge viewpoint) — the two
stretches every round's critique has called out as bare, and exactly what
the coordinator's own guidance said `harvest.json` should carry now that
wood/stone are the scatter's job.

**Measured, not just eyeballed** (`tools/frame_stats.py`, round 3 vs round 4
on the two changed frames): `chrom%` (colour variety) moved **1.202 → 1.397**
on early-forest (+16%) and **1.260 → 1.403** on late-ridge (+11%) — well
above the <0.03 noise floor round 2→round 3 established on an unchanged
frame. This round clears the stopping rule's "measured movement" bar on its
own, independent of what the critic says.

**Not folded in yet, on purpose**: `HARVEST-ALL` (tree/rock density 3.4x/
3.9x, `ralph-status`/`ralph/NOTES.md`) landed on its own branch while this
round was rendering. Kept out of this round so the berries' own effect isn't
conflated with a much larger, unrelated density change — that's round 5.

**Critic's verdict, in its own words.** Bar A/B: still **No/No**. Ranked
top-3 gaps: (1) night frames "within a few RGB values of pure black"; (2)
"bare, undressed ground dominates most day frames — worst in 01, 03, and 05"
(the exact three frames named in every round so far); (3) frame 04's cave
mass reads as "flat, textureless blockout geometry" next to trees carrying
"the key art's reserved oxblood/danger accent as ordinary foliage colour."
Same three gaps as rounds 2 and 3, in the same rough order — the critic's
own prose does not show new top-level findings this round.

**But the round still counts as improvement, per `ralph/conventions.md`'s
own OR rule** — a round only needs a new defect *or* measured movement, not
both, and `frame_stats.py` (this README's own numbers above) showed real
movement well past the noise floor. This is worth stating plainly: the
critic's language plateaued on the big three while the actual pixels moved,
which is exactly why the rule doesn't rely on critic wording alone.

Two positive small signals in the prose worth keeping: it names "a small
positive" for 01 gesturing at "landmarks visible from distance," and no
seams/LOD popping/z-fighting were found anywhere in the set across all four
rounds now — the base terrain and streaming are clean.

**Round 5**: merging `HARVEST-ALL`'s tree/rock density (3.4x/3.9x, landed
underneath this band, not authored by it) and re-rendering unchanged
viewpoints, to test whether the single largest available density lever
moves the #1/#2 recurring complaint. If it does, the loop continues; if it
doesn't, that's real evidence Band 2 has reached the boundary a content-only
lane can move, and the honest record is a wall, not a failure.
