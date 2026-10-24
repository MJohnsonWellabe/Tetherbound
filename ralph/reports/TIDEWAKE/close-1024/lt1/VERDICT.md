# Tidewake close-1024 round lt1: the Tidewake time-of-day grade (24 Oct 2026, CT)

- **Item:** the F39 biome look (F39#3's day/night requirement, and the largest finding in w1). Same six fixed views on `F39-look.json`, CPU llvmpipe, Low, 1920x1080.
- **Control:** main 5f1f388cc. **Candidate:** the OFF `lighting_candidate` section: 18:00 regraded to a real evening (low warm key, warm sky and haze), 23:00 to a directional moonlit night, plus stronger shared horizon haze and aerial perspective. Keyframe hours, the clock and the day length are untouched.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 55 --pairs 4 --include craft`; `calibrate.py` fitted a line (slope 0.531, r 0.534), top anchor 7.35, `confirming_batch: true`.
- **Caveat to report with the score:** anchor residual RMSE 0.89, above the 0.75 warning line. These judges did not rank the anchors the way the reference judges did, so the mapping is weaker than usual.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (main) | 5.4 / 5.2 / 4.2 | 5.60 |
| **Lighting candidate r1** | 6.4 / 6.4 / 5.4 | **6.21** |

+0.61 over the control in the same batch. Still below the 6.7 CPU-provisional bar, so it stays OFF.

## Recorded defects

| Defect | Control | Candidate |
|---|---|---|
| Time of day graded like midday | PRESENT x3 | **FIXED x2, PARTIAL x1** |
| Razor sea/sky seam, no haze | PRESENT x3 | PARTIAL x3 |
| Night beach flat ambient, no direction | PRESENT x3 | PARTIAL x3 |

Quoting the judges on the candidate's 18:00: "a warm golden hour with orange sand, long rake shadows across the beach and warm light carried into the water, the best frame in the batch"; "genuinely in the Valheim-class band".

## What r1 left, and what r2 changes

1. **Night casts nothing.** All three: the beach is still ambient-filled and the trainer and barrels throw no shadow; one judge adds that the candidate pushes the night far enough that the dock and posts almost stop reading. r2 trades night ambient (0.40 -> 0.26) for a stronger moon key (0.62 -> 0.95) so props cast.
2. **Dawn was never regraded.** Two judges: 05:00 is "the midday frame with a white disc added". r1 only touched golden and night. r2 adds a dawn grade.
3. **The midday seam is softened, not gone.** r2 raises horizon haze 0.34 -> 0.46 and aerial perspective 0.62 -> 0.72.
4. **Unchanged and out of this round:** the Veilfall close-up (new art, Meshy request 7-8), the even pebble and dune-grass scatter, and the HUD's keyboard prompts, empty quick-bar slots and the doubled slash in the health readout ("100//100") - that last one is a real UI defect worth a one-line fix in the UI lane.
