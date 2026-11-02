# Creature-lane GPU checks: current main (main1102b/) vs tb/creatures-ralph, mapped Bar A

GPU frames from origin/tb/gpu-frames-1101, same tool and camera; 2x2 grid hit-000, hit-050, faint-050, faint-100 with the batch-4 creature brief. Standard JUDGE_PROMPT, 3 anchor pairs, 3 code-blind judges, calibrate.py --bar 7.5. 7.0 is the lane work-list line; the bar stays 7.5.

## cr1102 (tree 29518c111)

| Species | main | lane | delta | lane >= 7.0 |
|---|---|---|---|---|
| sirenseal | 5.93 | 7.10 | +1.17 | YES |
| skyrill | 6.05 | 6.87 | +0.82 | no |
| staticub | 6.46 | 7.16 | +0.70 | YES |
| thundertunnel | 5.59 | 6.28 | +0.69 | no |
| aquaryn | 6.26 | 6.64 | +0.38 | no |
| duskhush | 6.44 | 6.77 | +0.33 | no |
| mangrove_monitor | 6.13 | 6.44 | +0.31 | no |

## cr1102b (tree 29c1b53c5)

| Species | main | lane | delta | lane >= 7.0 |
|---|---|---|---|---|
| ashtusk | 7.21 | 7.52 | +0.31 | YES |
| torrentoad | 6.81 | 6.97 | +0.16 | no |
| tuskroot | 7.65 | 7.01 | -0.64 | YES |

## main1102c (tree 81702ded1)

| Species | main | lane | delta | lane >= 7.0 |
|---|---|---|---|---|
| cindercub | 6.78 | 6.78 | +0.00 | no |
| galecrest | 6.75 | 6.75 | +0.00 | no |
| mosshell | 6.69 | 6.69 | +0.00 | no |
| sirenseal | 5.93 | 5.93 | +0.00 | no |
| stormursa | 7.07 | 7.07 | +0.00 | YES |
| thundertunnel | 5.17 | 5.17 | +0.00 | no |
| tuskroot | 6.86 | 6.86 | +0.00 | no |

## cr1102c (tree 9b1e168f6)

| Species | main | lane | delta | lane >= 7.0 |
|---|---|---|---|---|
| staticub | 6.43 | 7.98 | +1.55 | YES |
| skyrill | 5.97 | 7.43 | +1.46 | YES |
