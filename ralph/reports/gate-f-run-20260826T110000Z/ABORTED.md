# This run is ABORTED against a superseded candidate. Do not read its evidence as the run.

**Halted 2026-08-26 ~11:05Z, mid-S02, on a coordinator hold.**

## What exists here, and what it is worth

| segment | state | worth |
|---|---|---|
| `S01/` | complete, 13 PASS / 1 FAIL | evidence against candidate `14e88c7c`, which is **not** the candidate the real run will use |
| `S02-aborted-1/` | killed mid-flight | nothing. A truncated `route.csv`, no exit save, no verdicts. Kept rather than deleted because a deleted attempt is invisible, which is the rule the previous run followed for its own seven S02 attempts |

## Why it stopped

The candidate was frozen from `main` at `14e88c7c`, and **that SHA does not carry
the grass work.** `ralph/WORLD-GRASS` and `ralph/GRASS-FIELD` are both still
unlanded and hold grass scale and mid-layer, the shader cover tiers, sky and
clouds, stone and path grit, and the narrowed paths.

I had reasoned that the *journey* segments do not depend on grass presentation —
they are pacing, progression, combat and save-chain evidence — and held X01–X07
for exactly the ordering directive's reason. That reasoning was right about the
segments and **wrong about the candidate**, which is the part that matters:
every segment's evidence is attributed to a candidate SHA, and the freeze has to
be redone against a `main` that carries the grass. S01's 13/1 above therefore
belongs to a candidate that will not exist. Running S02–S10 on top would have
built a nine-segment save chain on the same superseded SHA — which is precisely
the "S01 is stranded on an older candidate" failure the previous run's handover
was careful to avoid, arrived at from the other direction.

One partial segment and one orphaned segment is the whole cost of stopping here.

## What replaces it

A fresh run directory, frozen from a `main` that carries both grass branches.
`ralph/reports/gate-f-candidate/RUN_METADATA.json` needs re-freezing at that
point; its current contents describe this aborted attempt.

## A correction that must travel with the re-freeze

The hold message states that withdrawing the night severity claim "means the
overnight X07 run is immune to that artefact." **It does not, and X07 is not
immune.** Lane-log check-in 6 has the measurement: pinned-and-frozen read R/B
2.90 against live 2.91 at the same hour, so the clock is not the mechanism and
`pin_clock` does not shield anything. What was actually established is that the
artefact is **position-in-process** — three independent fresh-process *first*
frames at pinned hour 22 read 0.42–0.44 (correct cool night), and every frame
after the first in the same process came back hue-rotated, deterministically,
across four probes. Five explanations were eliminated and the cause was not
found.

X07 takes 80 frames in one process. Its own 79 frames from 2026-08-25 looked
normal, so its capture path may well not hit this — but that is untested, and it
is the run's only real visual evidence. **Spot-check a late X07 frame's colour
against an early one before trusting the batch.**
