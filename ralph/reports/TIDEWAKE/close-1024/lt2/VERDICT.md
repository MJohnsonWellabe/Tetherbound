# Tidewake close-1024 round lt2: the time-of-day grade clears the CPU bar, and ships ON (24 Oct 2026, CT)

- **Item:** the Tidewake biome look on `F39-look.json`'s six fixed views (First Shore 12:00 / 18:00 / 23:00, the swim-lesson dune 12:00 / 05:00, Veilfall close). CPU llvmpipe, Low, 1920x1080.
- **r2 change, on the r1 judges' three asks:** a dawn grade (r1 never touched 05:00), night ambient 0.40 -> 0.26 traded for a moon key 0.62 -> 0.95 so props cast, and horizon haze 0.34 -> 0.46 with aerial perspective 0.62 -> 0.72.
- **Sides in one batch:** control, r1 and r2, with r2 judged twice (two sets) so the reading is checked against itself.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 77 --pairs 4 --include craft --include f36_0_npc:C1`; `calibrate.py` fitted a line (slope 1.366, r 0.871), anchor RMSE 0.60, top anchor 7.53, `confirming_batch: true`, nothing extrapolated.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (set Kd-A) | 5.2 / 6.2 / 5.3 | 5.84 |
| r1 (set Fk-B) | 5.8 / 6.2 / 5.8 | 6.34 |
| **r2 (set Kd-B)** | 6.5 / 6.7 / 6.4 | **7.16** |
| **r2 (set Fk-A)** | 6.4 / 6.6 / 6.2 | **6.98** |

**r2 means 7.07 across its two readings, above the 6.7 CPU-provisional bar**, +0.73 on r1 and +1.23 on the control. Round gains: r1 +0.61, r2 +0.73, both over +0.5, so the gain rule does not park it.

**Marked CPU-provisional.** A GPU pass is owed before 7.5 is claimed, and a GPU score below 7.5 reopens it.

## Disposition: the regrade ships ON

`lighting_candidate` is out of `sections_off`, with its score recorded in the config's `_why_lighting_candidate`. Two things had to hold first, and both do:

1. **It was judged passing**, not assumed: 7.07 mapped in a confirming batch whose anchors reach 7.53.
2. **Night is no less readable than the night the game already ships.** The r2 night is darker, so this was measured, not eyeballed: `tools/frame_stats.py` on the shore night frame gives near_luma **0.231**, against 0.292 shipping and the **0.135-0.222** band `art.json`'s own night contract accepted for Meadows. The regrade's night sits above that accepted band.

Checks with the grade ON: 543 water/clock/weather unit tests, 0 failed; `test_tidewake_look_profile` extended to assert the regrade ships on with its score recorded and the two new candidates ship off; `smoke_net_water_alpha` ALL CHECKS PASSED (the co-op water-alpha guard).

## Recorded defects

| Defect | Control | r2 |
|---|---|---|
| Time of day graded like midday | PRESENT x3 | PARTIAL x3 |
| Razor sea/sky seam, no haze | PRESENT x2, PARTIAL x1 | PARTIAL x3 |
| Night beach flat ambient, nothing casts | PRESENT x3 | PRESENT x2, PARTIAL x1 |

The evening and dawn frames are what the judges credit: "a warm peach sky with long raked shadows at 18:00, and a real sunrise at 05:00 with the sun disc on the horizon"; "side A's 05:00 dune, with its raked shadows and sun path on the water, genuinely reaches that finish". Two of the three recorded defects are reduced on every judge; none is fixed outright.

## What still holds this item under 7.5

1. **Night casts nothing.** All three judges, both rounds: at 23:00 the trainer, barrels, jetty and pebbles throw no shadow on the sand. The moon key is now strong enough to be seen on the water but not to read on the beach. This is the next round's target and is a shadow-reach or shadow-opacity question at this sun pitch, not another colour pass.
2. **The sea still ends on a line.** The haze band now sits in the sky above the seam; the water side gets nothing, so the sea is still flat strips with no falloff into distance.
3. **The Veilfall is the weakest frame in every batch, on every side.** All six judges across lt1 and lt2 mark it `new_art`: faceted untextured slabs, a waterfall that stops partway down with no plume, spray or plunge pool. Meshy requests 7-8 exist for exactly this.
4. **Even scatter.** Dune pebbles and grass at uniform scale and spacing, named by every judge in both rounds.
