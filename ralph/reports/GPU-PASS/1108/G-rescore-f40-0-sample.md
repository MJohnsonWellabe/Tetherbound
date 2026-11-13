# G-rescore-f40-0-sample: Cloudreach frame matrix sample re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026. Rows: F40#0, F40#19, F40#21.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-f40-0-sample` @ 6b2bfe3ef: main 90ffeb663, High, `capture_cloudreach_f40_matrix.gd`, pieces d*8+3, +4, +7, +8 for all 12 stands: day clear, day rain, night clear, night rain × four views = 192 frames (half of the 384-frame matrix; dawn and golden are not in the sample). 0 blank.

**Batch:** three code-blind judges, the standard prompt. 24 one-sided sets: each stand in clear weather and in rain, four views by day (top row) and by night (bottom row) at 480×270. Each set carries F40#21's criterion as its recorded defect. **Five anchor pairs** (ten points), the first batch with five.

**Fit:** linear, slope 0.7698, intercept 1.7636, r 0.730, anchor RMSE 0.663; warnings: none. Five pairs did not tighten the fit; read every number here as about ±0.6.


## Row scores

| Row | Criterion | Board | Main now (mapped) | Basis |
|---|---|---|---|---|
| **F40#0** | biome re-captured and re-scored | 6.54 (384 frames, 10 Nov) | **5.98** | mean of all 24 sets; clear 6.29, rain 5.68 |
| **F40#19** | frame matrix passes the bar on High and Medium | 6.66 | **5.98** at High | the same matrix mean; the realm gate rain set alone is 5.59 |
| **F40#21** | no magenta rings or slabs, placeholder materials, floating bodies or clipping | 6.68 | **5.98** | matrix mean; the defect is FIXED 3/3 in both weathers at 4 of 12 stands and PARTIAL at the rest |

**F40#0 reads just under 6 here (5.98).** Given the ±0.6 on this batch and that the sample leaves out dawn and golden, treat it as "about 6, rain well below clear", not as a confirmed fall below 6.


## By stand, lowest first

| Stand | Clear | Rain | Raw clear a, b, c | Raw rain a, b, c | F40#21 defect, clear | F40#21 defect, rain |
|---|---|---|---|---|---|---|
| stormward overlook | 5.89 | 5.30 | 5.3, 5.2, 5.6 | 4.6, 4.4, 4.8 | PARTIAL / PARTIAL / PARTIAL | PARTIAL / PARTIAL / PARTIAL |
| windscar flight aerie | 6.00 | 5.28 | 5.3, 5.3, 5.9 | 4.5, 4.3, 4.9 | PARTIAL / PARTIAL / PARTIAL | PARTIAL / PARTIAL / PARTIAL |
| broken skyroad arch | 6.07 | 5.30 | 5.4, 5.6, 5.8 | 4.6, 4.5, 4.7 | FIXED / FIXED / FIXED | FIXED / FIXED / FIXED |
| old wind observatory | 6.07 | 5.61 | 5.4, 5.5, 5.9 | 4.9, 4.8, 5.3 | PARTIAL / PARTIAL / PARTIAL | PARTIAL / PARTIAL / PARTIAL |
| realm gate crag | 6.18 | 5.59 | 5.6, 5.7, 5.9 | 4.9, 4.9, 5.1 | FIXED / FIXED / FIXED | FIXED / FIXED / FIXED |
| the high perches | 6.20 | 5.79 | 5.8, 5.7, 5.8 | 5.3, 5.1, 5.3 | PARTIAL / PARTIAL / PARTIAL | PARTIAL / PARTIAL / PARTIAL |
| galefoot waycamp | 6.36 | 5.66 | 6.1, 5.6, 6.2 | 5.2, 4.7, 5.3 | PARTIAL / PARTIAL / PARTIAL | PARTIAL / PARTIAL / PARTIAL |
| three bells bridge | 6.41 | 5.72 | 6.1, 5.9, 6.1 | 5.3, 4.9, 5.2 | PARTIAL / PARTIAL / PARTIAL | PARTIAL / PARTIAL / PARTIAL |
| sky shrine | 6.38 | 5.82 | 6.2, 5.5, 6.3 | 5.4, 4.9, 5.5 | FIXED / PARTIAL / FIXED | FIXED / FIXED / FIXED |
| windscar beacon | 6.64 | 5.89 | 6.3, 6.2, 6.5 | 5.5, 5.1, 5.5 | FIXED / FIXED / FIXED | FIXED / FIXED / FIXED |
| cliffhold | 6.54 | 6.10 | 6.0, 6.0, 6.6 | 5.5, 5.5, 5.9 | PARTIAL / PARTIAL / PARTIAL | PARTIAL / PARTIAL / PARTIAL |
| summit eyrie | 6.74 | 6.07 | 6.4, 6.3, 6.7 | 5.6, 5.4, 5.8 | FIXED / FIXED / FIXED | FIXED / FIXED / FIXED |

## What the judges named (3/3)
- **Rain is 0.6 below clear at every stand** (5.68 against 6.29). All three name the rain and night grades: a "tiled striped grey sky", pale stone losing its value under a flat grey wash, no wet sheen, no fog depth layers; at night a "uniform blue" or "cobalt" wash with a self-lit trainer where a moon key and warm lamp pools should be. The rain time grade (#915) fixed night-reads-as-day; these are the next asks. The wet-ground arm (PLACES-WETPATH round 2, with LANE-THINGS) is aimed at the wet sheen.
- **Ground:** uniform lawn with lone blades, blurry low-resolution path and plot splats, unblended path edges.
- **Thin landmarks (new art):** stormward overlook (the arch and its dark slab bases), windscar flight aerie, broken skyroad arch and the old wind observatory are the four lowest stands. The summit dome and the beacon pavilion are named as the quality to match.
- **F40#21 stand-ins still PARTIAL at seven stands:** flat ground rings and slabs, a black wedge, banner rectangles.
- **Camera:** some fixed views cut the landmark or clip foreground geometry.

