# Meadows wild roster — production report

The shared production record for the twelve Meadows wild species and Tuskroot,
referenced from `data/pals/species.json`'s `_comment_art` fields. One file
because the roster went through one pipeline (`tools/art_pipeline/meshy.py`),
not nineteen separate reports like the starters got.

**Gap closed (R0.8):** Bramblebun, Mudsnout and Trailpup are already
shipped — real GLBs with textures sit in
`assets/pals/tetherbound/{bramblebun,mudsnout,trailpup}/models/` and
`species.json` already points at them. Their `_comment_art` fields cite this
file, and for a while nobody could find their candidate-selection record —
it never went through `ralph/DONE.md` (that file's R0.1 entry accounts for
the ten species above, not these three, which predate the Ralph loop).
The record does exist, though: it survived in the git history that produced
these three, not in `ralph/`. Commit `d2520f0` ("Bramblebun stops being a
duck...") records Bramblebun's full pick — candidate b, on the ears (broad
with the concept's visible inner cup) and the compact sitting rump, with the
known miss that none of the three candidates modelled the sheet's dense
moss/leaf/flower plant mat as densely as drawn. Commit `9ec9eaa` ("Mudsnout
and Trailpup...") records both: Mudsnout candidate c for the spine bristle
ridge (on the Terrapup precedent that silhouette beats surface — candidate
b had the better snout disc and lost on the ridge), Trailpup candidate b for
its longest/narrowest muzzle and the only clear shoulder ruff. Both commits'
reasoning is already condensed into `docs/ASSET_LEDGER.md`'s rows for these
three creatures — this note exists so a future reader does not have to
git-archaeology it again.

## R0.4 — blind critique, ten species, candidates picked

Ten species had Meshy preview-tier candidates generated (`DONE.md` R0.1: 895 →
375 credits) and comparison sheets built (`DONE.md` R0.3) at
`shots/candidates/<species>-compare.png`, each with a blank scorecard beside
it at `shots/candidates/<species>-compare.md`.

**Method.** For each species, a fresh critic — a subagent with no access to
this conversation, shown only the comparison sheet and the species' canon
text (the one-line roster entry from `docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md`
plus the appearance brief from `SPECIES_PROMPTS` in `meshy.py`, which states
the signature feature in capitals and first) — scored **silhouette,
proportion and the signature feature only**. Candidates are untextured white
geometry at this stage, so material/colour, topology, rigging and
gameplay-distance readability are out of scope until R0.5/R0.6 and are marked
N/A on each scorecard rather than guessed at. A HARD FAIL on any candidate is
disqualifying regardless of its score total (`TETHERBOUND_3D_ART_PIPELINE.md`
§9) — the full reasoning and the runner-up comparison for each species lives
in its own `-compare.md` file; this table is the summary.

| Species | Winner | Hard fail on the winner? | Follow-up required before R0.6 |
|---|---|---|---|
| Brooktail | a | **Yes — shared by every candidate.** Paddle tail is absent; both give a round tapering tail instead of the canon's broad flat scaled paddle. | Sculpt a genuine broad/flat paddle tail. Not a texture fix — R0.5 cannot resolve this. |
| Burrowback | c | No | Shovel claws under-scale on all three candidates (shared, not c-specific) — flag for a claw pass. |
| Duskhush | a | No | None blocking; brow ridge reads slightly sharper/angrier than the "calm watchful" brief on a and c — cosmetic. |
| Galecrest | a | No | Talons are stubby/blunt on the winner — flag for a talon pass (candidate b's talons were the sharpest of the three, if a reference is wanted). |
| Meadowhart | a | No | a and c are near-duplicate generations (~3.5/255 mean pixel diff) — worth confirming with the art pipeline before spending R0.6 rig work on the assumption they're independent sculpts. |
| Mosshell | b | No | Minor: a thin protrusion near the hindquarters in the back three-quarter view reads as a possible errant tail/spike — topology check before final approval. |
| Paddlenewt | a | No | Tail is short and ends in an abrupt paddle-fin rather than a long taper (candidate b's tail was the better shape) — lengthen/taper before R0.6. |
| Pipwing | b | No | Crest is thin/blade-like rather than the reference's chunkier tuft (shared across all three) — cosmetic, not blocking. |
| Reedwing | a | No | Neck reads slightly longer/thinner than the reference's stouter neck — minor proportion pass. |
| Tuskroot | a | No | Stone plates read as rounded pebbles/warts rather than flat-edged slabs on all three candidates (shared) — flag for a plate-edge sculpt pass. |

**Nine of ten winners are clean picks with no hard fail.** Brooktail is the
one exception: every candidate for that species shares the same defect (no
paddle tail), so the "winner" is a tie-break on secondary criteria (face,
absence of a bolted-on seam), not a pass. It ships forward into R0.5/R0.6 with
that defect flagged rather than being blocked, per the pipeline's own
philosophy of iterating on what exists rather than re-rolling — but the tail
needs a real sculpting pass before this creature is considered done, and
whoever does that pass should read this note first rather than rediscover it.

Full per-candidate scores, the HARD FAIL checklist, and the complete defect
list that picked each winner (including what each runner-up did better) are
in the individual scorecards: `shots/candidates/<species>-compare.md`.

## What's next

- **R0.5** retextured the ten winners above, 30 credits each (`DONE.md`) —
  though R0.6 found the first pass was done in the wrong order and every
  species needed a second retexture; see Tuskroot's `DONE.md` entry.
- **R0.6** takes each winner through cleanup/remesh → rig → six clips →
  grade → install, one species at a time. **All six wild quadrupeds are
  done** (Tuskroot, Meadowhart, Burrowback, Paddlenewt, Mosshell,
  Brooktail). **The four birds (Galecrest, Duskhush, Pipwing, Reedwing) are
  blocked**: `finish.py rig`'s animate step is hardcoded to
  `animate_quadruped.py` regardless of `--kind`, and no `animate_bird.py`
  exists yet — see `BLOCKED.md`.
- **R0.8** owes a provenance row per creature in `docs/ASSET_LEDGER.md` —
  done for all six finished quadrupeds. The missing
  Bramblebun/Mudsnout/Trailpup production record noted above is now found
  and cited, not missing.
