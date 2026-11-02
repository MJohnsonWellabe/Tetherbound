# Full creature roster GPU baseline: installed (1 Nov) vs current main, mapped Bar A

GPU frames from origin/tb/gpu-frames-1101 at 894ce969b (main/ = 1 Nov installed models, control; main1102b/ = current main after #797, candidate; same tool and camera). Each side a 2x2 grid of hit-000, hit-050, faint-050, faint-100 with the batch-4 creature brief. Standard JUDGE_PROMPT, 3 anchor pairs per folder (anchor_tiles.py, seeds 801-810), 3 independent code-blind judges, calibrate.py --bar 7.5 (mapped_mean). Bar stays 7.5; the 7.0 column is the work-list line.

Skipped species (no main/ control frames): none

| Species | folder | installed (1 Nov) | current main | delta | current >= 7.0 | notes |
|---|---|---|---|---|---|---|
| abyssal_guardian | CREATURES-01 | 5.15 | 5.27 | +0.12 | no |  |
| aeriex | CREATURES-01 | 5.69 | 6.92 | +1.23 | no |  |
| aquaryn | CREATURES-01 | 6.75 | 5.45 | -1.30 | no |  |
| ashtusk | CREATURES-01 | 5.98 | 7.16 | +1.18 | YES |  |
| bramblebun | CREATURES-01 | 7.52 | 7.52 | +0.00 | YES |  |
| breezetail | CREATURES-01 | 5.33 | 6.51 | +1.18 | no |  |
| brooktail | CREATURES-01 | 4.56 | 7.04 | +2.48 | YES |  |
| burrowback | CREATURES-02 | 6.61 | 6.64 | +0.03 | no |  |
| cannonback | CREATURES-02 | 5.88 | 6.05 | +0.17 | no |  |
| cindercub | CREATURES-02 | 6.29 | 6.85 | +0.56 | no |  |
| cliffspike | CREATURES-02 | 6.05 | 6.44 | +0.39 | no |  |
| cloudfang | CREATURES-02 | 5.96 | 6.61 | +0.65 | no |  |
| cragclaw | CREATURES-02 | 6.17 | 5.55 | -0.62 | no |  |
| craghorn | CREATURES-02 | 6.29 | 6.47 | +0.18 | no |  |
| duskhush | CREATURES-03 | 6.74 | 6.37 | -0.37 | no |  |
| frostclaw | CREATURES-03 | 6.96 | 7.03 | +0.07 | YES |  |
| fulgocobra | CREATURES-03 | 6.23 | 6.12 | -0.11 | no |  |
| galecrest | CREATURES-03 | 7.39 | 7.39 | +0.00 | YES |  |
| galewisp | CREATURES-03 | 4.99 | 6.96 | +1.97 | no |  |
| glimmermoth | CREATURES-03 | 5.14 | 6.70 | +1.56 | no |  |
| mangrove_monitor | CREATURES-03 | 5.94 | 6.63 | +0.69 | no |  |
| meadowhart | CREATURES-04 | 7.21 | 7.04 | -0.17 | YES |  |
| mirejaw | CREATURES-04 | 6.17 | 6.47 | +0.30 | no |  |
| mosshell | CREATURES-04 | 6.92 | 6.92 | +0.00 | no |  |
| mosshock | CREATURES-04 | 6.23 | 6.47 | +0.24 | no |  |
| mudsnout | CREATURES-04 | 7.45 | 7.45 | +0.00 | YES |  |
| nightburrow | CREATURES-04 | 6.80 | 6.80 | +0.00 | no |  |
| paddlenewt | CREATURES-04 | 6.98 | 6.98 | +0.00 | no |  |
| pebbik | CREATURES-05 | 6.04 | 6.42 | +0.38 | no |  |
| pipwing | CREATURES-05 | 5.16 | 6.07 | +0.91 | no |  |
| reedwing | CREATURES-05 | 5.30 | 6.49 | +1.19 | no |  |
| ribbonray | CREATURES-05 | 5.51 | 5.23 | -0.28 | no |  |
| riftfrill | CREATURES-05 | 6.00 | 6.00 | +0.00 | no |  |
| ripplet | CREATURES-05 | 5.90 | 5.90 | +0.00 | no |  |
| riptusk | CREATURES-05 | 6.04 | 6.52 | +0.48 | no |  |
| riverdrake | CREATURES-06 | 5.41 | 6.45 | +1.04 | no |  |
| shadelet | CREATURES-06 | 5.61 | 5.95 | +0.34 | no |  |
| sirenseal | CREATURES-06 | 5.85 | 5.11 | -0.74 | no |  |
| skyrill | CREATURES-06 | 5.78 | 5.48 | -0.30 | no |  |
| solmane | CREATURES-06 | 6.35 | 7.02 | +0.67 | YES |  |
| sparkit | CREATURES-06 | 5.61 | 5.11 | -0.50 | no |  |
| staticub | CREATURES-06 | 7.43 | 5.98 | -1.45 | no |  |
| stormbrush | CREATURES-07 | 6.38 | 6.82 | +0.44 | no |  |
| stormcapra | CREATURES-07 | 8.37 | 8.37 | +0.00 | YES |  |
| stormraven | CREATURES-07 | 6.04 | 7.64 | +1.60 | YES |  |
| stormtrail | CREATURES-07 | 7.20 | 7.20 | +0.00 | YES |  |
| stormursa | CREATURES-07 | 8.61 | 8.61 | +0.00 | YES |  |
| tanglevolt | CREATURES-07 | 8.32 | 8.32 | +0.00 | YES |  |
| tempestwing | CREATURES-07 | 6.77 | 5.89 | -0.88 | no |  |
| terrapup | CREATURES-08 | 7.08 | 6.26 | -0.82 | no |  |
| thundertunnel | CREATURES-08 | 6.62 | 4.72 | -1.90 | no |  |
| tidecoil | CREATURES-08 | 6.89 | 7.35 | +0.46 | YES |  |
| torrentoad | CREATURES-08 | 7.30 | 5.53 | -1.77 | no |  |
| trailpup | CREATURES-08 | 6.99 | 6.99 | +0.00 | no |  |
| tuskroot | CREATURES-08 | 7.71 | 6.85 | -0.86 | no |  |
| veridian | CREATURES-08 | 6.17 | 6.17 | +0.00 | no |  |
| voltarach | CREATURES-09 | 5.39 | 5.72 | +0.33 | no |  |
| voltwig | CREATURES-09 | 5.32 | 6.41 | +1.09 | no |  |
| water_abyssal_guardian | CREATURES-09 | 5.47 | 5.47 | +0.00 | no |  |
| water_aquaryn | CREATURES-09 | 5.97 | 5.97 | +0.00 | no |  |
| water_cannonback | CREATURES-09 | 6.63 | 6.63 | +0.00 | no |  |
| water_cragclaw | CREATURES-09 | 6.34 | 6.34 | +0.00 | no |  |
| water_mangrove_monitor | CREATURES-09 | 5.90 | 5.90 | +0.00 | no |  |
| water_mirejaw | CREATURES-10 | 6.01 | 6.01 | +0.00 | no |  |
| water_mosshell | CREATURES-10 | 6.95 | 6.95 | +0.00 | no |  |
| water_riptusk | CREATURES-10 | 6.75 | 6.75 | +0.00 | no |  |
| water_riverdrake | CREATURES-10 | 6.65 | 6.65 | +0.00 | no |  |
| water_sirenseal | CREATURES-10 | 6.35 | 6.35 | +0.00 | no |  |
| water_tidecoil | CREATURES-10 | 7.01 | 7.01 | +0.00 | YES |  |
| water_torrentoad | CREATURES-10 | 7.38 | 7.38 | +0.00 | YES |  |

## Creature lane work list: current main below 7.0 (ascending)

1. thundertunnel: 4.72 (installed 6.62, delta -1.90)
2. sirenseal: 5.11 (installed 5.85, delta -0.74)
3. sparkit: 5.11 (installed 5.61, delta -0.50)
4. ribbonray: 5.23 (installed 5.51, delta -0.28)
5. abyssal_guardian: 5.27 (installed 5.15, delta +0.12)
6. aquaryn: 5.45 (installed 6.75, delta -1.30)
7. water_abyssal_guardian: 5.47 (installed 5.47, delta +0.00)
8. skyrill: 5.48 (installed 5.78, delta -0.30)
9. torrentoad: 5.53 (installed 7.30, delta -1.77)
10. cragclaw: 5.55 (installed 6.17, delta -0.62)
11. voltarach: 5.72 (installed 5.39, delta +0.33)
12. tempestwing: 5.89 (installed 6.77, delta -0.88)
13. ripplet: 5.90 (installed 5.90, delta +0.00)
14. water_mangrove_monitor: 5.90 (installed 5.90, delta +0.00)
15. shadelet: 5.95 (installed 5.61, delta +0.34)
16. water_aquaryn: 5.97 (installed 5.97, delta +0.00)
17. staticub: 5.98 (installed 7.43, delta -1.45)
18. riftfrill: 6.00 (installed 6.00, delta +0.00)
19. water_mirejaw: 6.01 (installed 6.01, delta +0.00)
20. cannonback: 6.05 (installed 5.88, delta +0.17)
21. pipwing: 6.07 (installed 5.16, delta +0.91)
22. fulgocobra: 6.12 (installed 6.23, delta -0.11)
23. veridian: 6.17 (installed 6.17, delta +0.00)
24. terrapup: 6.26 (installed 7.08, delta -0.82)
25. water_cragclaw: 6.34 (installed 6.34, delta +0.00)
26. water_sirenseal: 6.35 (installed 6.35, delta +0.00)
27. duskhush: 6.37 (installed 6.74, delta -0.37)
28. voltwig: 6.41 (installed 5.32, delta +1.09)
29. pebbik: 6.42 (installed 6.04, delta +0.38)
30. cliffspike: 6.44 (installed 6.05, delta +0.39)
31. riverdrake: 6.45 (installed 5.41, delta +1.04)
32. craghorn: 6.47 (installed 6.29, delta +0.18)
33. mirejaw: 6.47 (installed 6.17, delta +0.30)
34. mosshock: 6.47 (installed 6.23, delta +0.24)
35. reedwing: 6.49 (installed 5.30, delta +1.19)
36. breezetail: 6.51 (installed 5.33, delta +1.18)
37. riptusk: 6.52 (installed 6.04, delta +0.48)
38. cloudfang: 6.61 (installed 5.96, delta +0.65)
39. mangrove_monitor: 6.63 (installed 5.94, delta +0.69)
40. water_cannonback: 6.63 (installed 6.63, delta +0.00)
41. burrowback: 6.64 (installed 6.61, delta +0.03)
42. water_riverdrake: 6.65 (installed 6.65, delta +0.00)
43. glimmermoth: 6.70 (installed 5.14, delta +1.56)
44. water_riptusk: 6.75 (installed 6.75, delta +0.00)
45. nightburrow: 6.80 (installed 6.80, delta +0.00)
46. stormbrush: 6.82 (installed 6.38, delta +0.44)
47. cindercub: 6.85 (installed 6.29, delta +0.56)
48. tuskroot: 6.85 (installed 7.71, delta -0.86)
49. aeriex: 6.92 (installed 5.69, delta +1.23)
50. mosshell: 6.92 (installed 6.92, delta +0.00)
51. water_mosshell: 6.95 (installed 6.95, delta +0.00)
52. galewisp: 6.96 (installed 4.99, delta +1.97)
53. paddlenewt: 6.98 (installed 6.98, delta +0.00)
54. trailpup: 6.99 (installed 6.99, delta +0.00)

Folder notes: {"CREATURES-01 warnings": ["meets the bar only above the top anchor (7.35): F36 Bramblebun cand, F36 Bramblebun main; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch"], "CREATURES-02 warnings": [], "CREATURES-03 warnings": ["anchor residual RMSE 0.96 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat"], "CREATURES-04 warnings": [], "CREATURES-05 warnings": [], "CREATURES-06 warnings": [], "CREATURES-07 warnings": ["meets the bar only above the top anchor (7.03): F36 Stormcapra cand, F36 Stormcapra main, F36 Stormraven cand, F36 Stormursa cand, F36 Stormursa main, F36 Tanglevolt cand, F36 Tanglevolt main; extrapolated, confirm in a batch whose anchors reach at least 7.35 (anchor_tiles.py --include craft or --include f36_0_npc:C1)", "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)"], "CREATURES-08 warnings": ["meets the bar only above the top anchor (7.07): F36 Tuskroot main; extrapolated, confirm in a batch whose anchors reach at least 7.35 (anchor_tiles.py --include craft or --include f36_0_npc:C1)"], "CREATURES-09 warnings": [], "CREATURES-10 warnings": ["offset fallback (least-squares slope 0.096 outside 0.5-2.0): the map is only a mean offset; these judges spread the anchors differently from the reference judges", "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)"]}
