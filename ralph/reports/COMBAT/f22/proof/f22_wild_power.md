# Ordinary-wild masher cost (COMBAT §7 target: masher win >=90%, lead HP cost 15-30%)

Correction: the earlier lane report of masher cost 1-11% was the median PARTY cost, not lead cost.
Baseline (scale 1.0, pilot a31ab858) masher median LEAD cost per band:
- band1_lower_meadows: win 0.97, lead 0.27, worst single hit 0.18
- band2_stone_and_root: win 1.00, lead 0.18, worst single hit 0.13
- band3_the_river_lock: win 1.00, lead 0.15, worst single hit 0.12
- band4_upper_meadows_ironwood: win 1.00, lead 0.17, worst single hit 0.12
- band5_stronghold_approach: win 1.00, lead 0.17, worst single hit 0.10
- tidewake/first_shores: win 1.00, lead 0.21, worst single hit 0.09
- tidewake/marsh_channels: win 1.00, lead 0.20, worst single hit 0.09
- tidewake/outer_reaches: win 1.00, lead 0.26, worst single hit 0.07
- tidewake/tether_current: win 1.00, lead 0.20, worst single hit 0.06
- tidewake/tidal_cradle: win 1.00, lead 0.24, worst single hit 0.08
- tidewake/veilfall: win 1.00, lead 0.24, worst single hit 0.07
- cloudreach/broken_causeways: win 1.00, lead 0.30, worst single hit 0.07
- cloudreach/gate_lower_cliffs: win 1.00, lead 0.27, worst single hit 0.07
- cloudreach/high_roost_sky_shrine: win 1.00, lead 0.43, worst single hit 0.06
- cloudreach/summit_final_stronghold: win 1.00, lead 0.28, worst single hit 0.06
- cloudreach/upper_cloudreach: win 1.00, lead 0.23, worst single hit 0.06
- cloudreach/windscar_ravine: win 1.00, lead 0.23, worst single hit 0.07
- stormwood/cinder_verge: win 1.00, lead 0.31, worst single hit 0.06
- stormwood/conductor_run: win 1.00, lead 0.21, worst single hit 0.05
- stormwood/deepwood: win 1.00, lead 0.31, worst single hit 0.05
- stormwood/dynamo: win 1.00, lead 0.28, worst single hit 0.05
- stormwood/glowmoss_hollows: win 1.00, lead 0.24, worst single hit 0.06
- stormwood/hollow_crown: win 1.00, lead 0.26, worst single hit 0.05

Trial wild_power_scale 2.5 (Tidewake, Cloudreach; commit 66e7e765): masher win falls to 0.53-1.00, lead cost 0.47-0.94. That overshoots the target, so it was reverted to 1.0 everywhere. before = scale 1.0, after = 2.5:
```
band                                   before win/lead/max  after win/lead/max   after R win / S win
tidewake/first_shores                  1.00/0.21/0.09       0.81/0.68/0.23       0.72 / 1.00
tidewake/marsh_channels                1.00/0.20/0.09       0.78/0.72/0.21       0.64 / 1.00
tidewake/outer_reaches                 1.00/0.26/0.07       0.81/0.70/0.19       0.56 / 1.00
tidewake/tether_current                1.00/0.20/0.06       0.83/0.67/0.17       0.64 / 1.00
tidewake/tidal_cradle                  1.00/0.24/0.08       0.92/0.65/0.20       0.94 / 1.00
tidewake/veilfall                      1.00/0.24/0.07       0.81/0.69/0.17       0.69 / 1.00
band                                   before win/lead/max  after win/lead/max   after R win / S win
cloudreach/broken_causeways            1.00/0.30/0.07       0.58/0.83/0.17       0.08 / 1.00
cloudreach/gate_lower_cliffs           1.00/0.27/0.07       1.00/0.57/0.19       0.86 / 1.00
cloudreach/high_roost_sky_shrine       1.00/0.43/0.06       0.53/0.94/0.15       0.33 / 1.00
cloudreach/summit_final_stronghold     1.00/0.28/0.06       0.67/0.61/0.15       0.31 / 1.00
cloudreach/upper_cloudreach            1.00/0.23/0.06       0.81/0.56/0.16       0.81 / 1.00
cloudreach/windscar_ravine             1.00/0.23/0.07       1.00/0.47/0.16       0.83 / 1.00
```
