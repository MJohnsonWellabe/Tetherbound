# b2-b4 (24 Oct 2026, CPU llvmpipe Compatibility/Low): F36#1 held shove hit + topple faints (`--candidate-1024`) vs shipping

Stage: `capture_f36_poses.gd --whole-body --context` (shipping = enabled species on their live recipe, others on installed clips; candidate = `f36_pose_postpass.py --candidate-1024` previewed with `--candidate`). Sides: standing, hit react, hit recover, faint mid, faint end.
Standard prompt verbatim, three fresh code-blind judges per batch, 3 anchor pairs per batch incl. f36_0_npc:C1 (confirming). Raw per-judge scores: `raw_scores.py`; keys, fits and mapped scores: `b2/`, `b3/`, `b4/`.

Fits: b2 linear slope 1.543, intercept -3.253, RMSE 0.33. b3 slope 1.052, intercept 0.275, RMSE 0.83 (warning: anchors ranked unlike the reference judges; read b3 with that caveat). b4 slope 0.953, intercept 1.219, RMSE 0.67 (Breezetail, Cloudfang, Craghorn, Staticub extrapolated above the top anchor; confirming batch).

| Species | Shipping | Candidate | Gain | Disposition |
|---|---|---|---|---|
| craghorn | 6.90 | **7.89** | +0.99 | ON (enabled) |
| cloudfang | 7.35 | **7.82** | +0.47 | ON |
| breezetail | 6.71 | **7.73** | +1.02 | ON (enabled) |
| stormraven | 6.65 | **7.47** | +0.82 | ON (enabled) |
| tidecoil | 6.16 | **7.43** | +1.27 | ON (enabled; b3 caveat) |
| burrowback | 7.29 | **7.34** | +0.05 | ON |
| frostclaw | 7.08 | **7.34** | +0.26 | ON |
| aquaryn | 6.27 | **7.29** | +1.02 | ON (enabled; b3 caveat) |
| thundertunnel | 6.74 | **7.22** | +0.48 | ON |
| cliffspike | 6.71 | **7.16** | +0.45 | ON |
| pebbik | 6.68 | **7.09** | +0.41 | ON |
| trailpup | 6.72 | **7.08** | +0.36 | ON |
| voltwig | 6.65 | **7.04** | +0.39 | ON (b3 caveat) |
| stormbrush | 6.55 | **6.97** | +0.42 | ON |
| sirenseal | 6.79 | **6.97** | +0.18 | ON (b3 caveat) |
| riptusk | 6.20 | **6.79** | +0.59 | ON (b3 caveat) |
| staticub | 8.11 | 8.14 | +0.03 | no change (within noise; its shove hit already ships) |
| cindercub | 6.47 | 6.67 | +0.20 | OFF (under 6.7) |
| cragclaw | 6.06 | 6.65 | +0.59 | OFF (under 6.7) |
| skyrill | 6.30 | 6.62 | +0.32 | OFF |
| ashtusk | 6.47 | 6.57 | +0.10 | OFF |
| nightburrow | 5.49 | 6.52 | +1.03 | OFF (under 6.7) |
| shadelet | 6.21 | 6.52 | +0.31 | OFF |
| mangrove_monitor | 6.30 | 6.51 | +0.21 | OFF |
| cannonback | 6.13 | 6.44 | +0.31 | OFF |
| torrentoad | 6.44 | 6.44 | 0.00 | OFF |
| mosshock | 5.81 | 6.13 | +0.32 | OFF |
| mudsnout | 5.64 | 6.00 | +0.36 | OFF |
| tuskroot | 5.44 | 5.95 | +0.51 | OFF |
| stormtrail | 5.34 | 5.75 | +0.41 | OFF |
| riftfrill | 4.72 | 5.18 | +0.46 | OFF |

Judges' asks (all nine): hits that leave the floor (airborne rears on cats, foxes, the raven); belly-up flips and shell rolls at faint end (Cannonback, Mosshock, Torrentoad, Riptusk-B side, Pebbik, Skyrill); Burrowback's stone back vanishing in faint mid/end (installed model, both arms); ruler overlapping long tails (Mangrove Monitor, Sirenseal, Frostclaw); off-style materials needing new art (Ashtusk/Mudsnout clay-orange, Stormtrail glossy camo, Riftfrill chibi and shorter than the trainer, Stormbrush electric-blue drift, Skyrill chrome gloss, Mosshock toxic green); dark bodies need rim light.
