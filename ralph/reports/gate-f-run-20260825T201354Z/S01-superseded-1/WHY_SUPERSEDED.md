# S01 attempt 1 (capture mode) — superseded, and why

**Not a failed segment. A failed *mode*.** All 14 of S01's steps executed and
emitted their events, the last at `t=180.8`. The process then never terminated:
at 35 minutes of wall clock it was still writing `route.csv` rows with the step
list exhausted, `events.jsonl` frozen at 14 records, and `frames/` holding
**one** PNG. Killed at that point and preserved here rather than deleted, so
`notes/` is empty — the harness writes verdicts at segment end, and this segment
had no end.

## The measurement that decides the run's mode

`route.csv` column `frame_ms`, sampled across the attempt:

| t (s) | frame_ms | physics_ms |
|---|---|---|
| 318 | 3295 | — |
| 481 | 3481 | — |
| 645 | 3408 | — |
| 814 | 3226 | — |
| 977 | 3523 | — |
| 1140 | 3526 | — |
| 1220 | 3446 | 611 |

**The Meadows renders at ~0.29 FPS at 1920×1080 through llvmpipe**, one physics
step costing ~610 ms. That is a software rasteriser drawing 466,922 props with no
GPU. It is a fact about this container and **nothing about device frame rate can
be read from it** — that stays [OWNER-ONLY] (§K.1).

## What it costs the protocol

§H asks S01 for a continuous record at 0.5 Hz — a PNG every two seconds. This
attempt produced **one frame in thirty-five minutes**. The continuous record is
not merely expensive in capture mode on the world scene; it is unobtainable. And
a segment that cannot terminate yields no notes, no verdicts and no handoff save,
which would end the journey at its first step.

So the journey runs in **logic mode** (`--headless`, no rendering driver — the
combination the protocol §0.2 and `ralph/conventions.md` both name as correct and
fast, measured at ~5 ms/frame here). Every planned shot becomes a manifest row
with `file: null`, which §C.4 states plainly is itself evidence. Visual evidence
comes instead from the DIAG world audit X07, whose 80 shots are teleport-sited
stills with no walking between them — the one segment shape this box can still
render.

This is a decision about **how to execute**, not a reduction of **what** is
executed. The journey's steps, assertions and telemetry are unchanged; the frames
are lost, and their absence is recorded rather than papered over.

## The one thing this attempt does establish about the game

The title screen renders correctly at 1920×1080 and `Start New Game` works:
`shots/GF-01-TITLE-01.png` is a real frame, and the world stood up behind it —
`region_enter grandpas_village` at `t=145.3` with the objective already reading
*"Catch your first wild creature."* Kept here as the segment's only frame.
