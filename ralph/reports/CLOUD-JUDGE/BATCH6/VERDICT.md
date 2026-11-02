# GPU batch 6 creature remakes: installed (main) vs remake (batch6), mapped Bar A

GPU frames from origin/tb/gpu-frames-1101 at db9a4d96d (main/ = installed control, batch6/ = remake candidate; same tool and camera). Each side a 2x2 grid of hit-000, hit-050, faint-050, faint-100 with the batch-4 creature brief. Standard JUDGE_PROMPT v1, 3 anchor pairs per folder (anchor_tiles.py, seeds 701-703), 3 independent code-blind judges, calibrate.py --bar 7.5 (mapped_mean). m1102 columns are the main-1102 GPU numbers (m1102j/RESULTS.json: installed and shipped main1102); b4 columns are batch-4 GPU numbers (b4j/RESULTS.json: main and batch-4 candidate), each where that species was judged.

| Creature | folder | installed | remake | delta | remake >= 7.5 | m1102 installed | m1102 shipped | b4 main | b4 batch4 | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| stormraven | CREATURES-2 | 4.97 | 6.71 | +1.74 | no | n/a | n/a | n/a | n/a |  |
| solmane | CREATURES-2 | 6.31 | 7.64 | +1.33 | YES | n/a | n/a | n/a | n/a |  |
| pebbik | CREATURES-1 | 6.06 | 7.36 | +1.30 | no | n/a | n/a | n/a | n/a |  |
| reedwing | CREATURES-1 | 5.82 | 7.02 | +1.20 | no | n/a | n/a | n/a | n/a |  |
| stormbrush | CREATURES-2 | 5.14 | 6.19 | +1.05 | no | n/a | n/a | n/a | n/a |  |
| riverdrake | CREATURES-1 | 6.06 | 6.96 | +0.90 | no | n/a | n/a | n/a | n/a |  |
| voltarach | CREATURES-3 | 5.13 | 5.82 | +0.69 | no | n/a | n/a | n/a | n/a |  |
| riptusk | CREATURES-1 | 6.32 | 6.96 | +0.64 | no | 6.42 | 6.68 | n/a | n/a |  |
| voltwig | CREATURES-3 | 5.82 | 6.26 | +0.44 | no | n/a | n/a | n/a | n/a |  |
| shadelet | CREATURES-1 | 6.26 | 6.29 | +0.03 | no | n/a | n/a | n/a | n/a |  |
| tidecoil | CREATURES-3 | 6.23 | 6.26 | +0.03 | no | n/a | n/a | n/a | n/a |  |
| sparkit | CREATURES-2 | 5.14 | 4.80 | -0.34 | no | n/a | n/a | n/a | n/a |  |
| tempestwing | CREATURES-3 | 6.05 | 5.68 | -0.37 | no | n/a | n/a | n/a | n/a |  |
| ribbonray | CREATURES-1 | 6.02 | 5.62 | -0.40 | no | n/a | n/a | n/a | n/a |  |
| ripplet | CREATURES-1 | 6.69 | 6.12 | -0.57 | no | n/a | n/a | n/a | n/a |  |
| tuskroot | CREATURES-3 | 6.57 | 5.97 | -0.60 | no | 7.17 | 6.31 | n/a | n/a |  |
| torrentoad | CREATURES-3 | 6.57 | 5.71 | -0.86 | no | 7.06 | 5.59 | n/a | n/a |  |
| skyrill | CREATURES-2 | 5.67 | 4.80 | -0.87 | no | n/a | n/a | n/a | n/a |  |
| sirenseal | CREATURES-2 | 5.78 | 4.80 | -0.98 | no | n/a | n/a | n/a | n/a |  |
| thundertunnel | CREATURES-3 | 5.94 | 4.93 | -1.01 | no | n/a | n/a | n/a | n/a |  |
| staticub | CREATURES-2 | 7.93 | 5.55 | -2.38 | no | n/a | n/a | n/a | n/a |  |

## Remake at or above 7.5

- solmane: 6.31 -> 7.64

## Remake beats installed by 0.3 or more

- stormraven (+1.74)
- solmane (+1.33)
- pebbik (+1.30)
- reedwing (+1.20)
- stormbrush (+1.05)
- riverdrake (+0.90)
- voltarach (+0.69)
- riptusk (+0.64)
- voltwig (+0.44)

## Regressions vs installed (delta <= -0.3)

- sparkit (-0.34)
- tempestwing (-0.37)
- ribbonray (-0.40)
- ripplet (-0.57)
- tuskroot (-0.60)
- torrentoad (-0.86)
- skyrill (-0.87)
- sirenseal (-0.98)
- thundertunnel (-1.01)
- staticub (-2.38)

Folder notes: {"CREATURES-1 warnings": ["offset fallback (least-squares slope 0.062 outside 0.5-2.0): the map is only a mean offset; these judges spread the anchors differently from the reference judges"], "CREATURES-2 warnings": ["meets the bar only above the top anchor (7.35): F36 Solmane cand, F36 Staticub main; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch"], "CREATURES-3 warnings": ["anchor residual RMSE 0.77 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat"]}
