# F22#1 ordinary-trainer bands (smoke_f22_pattern_bands.gd --trainers, 12 seeds, verdict on the COMBAT §7 switching reader)

Coordinator rulings 2026-10-05:
- The verdict uses the §7 switching reader. Plain-reader rows are diagnostic only.
- trainer_power_scale is a declared per-chapter tunable: ordinary trainers only, Meadows held at 1.0.
- The reader throws the charged into a readable tell (COMBAT §4 interrupt; pilot 555c5857).

## Tidewake: trainer_power_scale 1.0 -> 1.3 (same pilot 555c5857)
Columns: masher lead-faint / median lead cost / win, then the same for the switching reader.
```
1.0: {'MASHER': 'stag 8.4 ci 3.3 worst-hit 0.12', 'SWITCH_READER': 'stag 5.4 ci 2.4 worst-hit 0.19'}
1.3: {'MASHER': 'stag 8.9 ci 3.5 worst-hit 0.16', 'SWITCH_READER': 'stag 5.7 ci 2.5 worst-hit 0.25'}
first_shores             terrapup M faint0.25 lead0.95 win1.00 -> faint1.00 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | P -> P
first_shores             ripplet  M faint0.00 lead0.71 win1.00 -> faint0.33 lead0.92 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | F -> P
first_shores             galewisp M faint0.17 lead0.77 win1.00 -> faint1.00 lead1.00 win1.00 | S faint0.00 lead0.30 win1.00 -> faint0.00 lead0.40 win1.00 | F -> P
marsh_channels           terrapup M faint0.25 lead0.92 win1.00 -> faint0.92 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | P -> P
marsh_channels           ripplet  M faint0.08 lead0.66 win1.00 -> faint0.33 lead0.90 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | F -> P
marsh_channels           galewisp M faint0.08 lead0.57 win1.00 -> faint0.08 lead0.74 win1.00 | S faint0.00 lead0.23 win1.00 -> faint0.00 lead0.30 win1.00 | F -> F
tidal_cradle             terrapup M faint0.08 lead0.92 win1.00 -> faint1.00 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | F -> P
tidal_cradle             ripplet  M faint0.00 lead0.75 win1.00 -> faint0.50 lead0.97 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | F -> P
tidal_cradle             galewisp M faint0.00 lead0.56 win1.00 -> faint0.17 lead0.73 win1.00 | S faint0.00 lead0.18 win1.00 -> faint0.00 lead0.24 win1.00 | F -> F
outer_reaches            terrapup M faint0.92 lead1.00 win1.00 -> faint1.00 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | P -> P
outer_reaches            ripplet  M faint0.00 lead0.57 win1.00 -> faint0.00 lead0.73 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | F -> F
outer_reaches            galewisp M faint0.00 lead0.35 win1.00 -> faint0.00 lead0.44 win1.00 | S faint0.00 lead0.52 win1.00 -> faint0.00 lead0.68 win1.00 | F -> F
tether_current           terrapup M faint0.33 lead0.86 win1.00 -> faint0.83 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | P -> P
tether_current           ripplet  M faint0.00 lead0.56 win1.00 -> faint0.08 lead0.73 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | F -> F
tether_current           galewisp M faint0.00 lead0.60 win1.00 -> faint0.00 lead0.78 win1.00 | S faint0.00 lead0.38 win1.00 -> faint0.00 lead0.50 win1.00 | F -> F
veilfall                 terrapup M faint0.58 lead1.00 win1.00 -> faint0.92 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | P -> P
veilfall                 ripplet  M faint0.17 lead0.82 win1.00 -> faint0.58 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 -> faint0.00 lead0.00 win1.00 | F -> P
veilfall                 galewisp M faint0.00 lead0.62 win1.00 -> faint0.50 lead0.75 win1.00 | S faint0.00 lead0.51 win1.00 -> faint0.00 lead0.60 win1.00 | F -> F
rows passing: 1.0 = 5  1.3 = 11  of 18
```

Kept at 1.3:
- The switching reader still wins 1.00 everywhere.
- Worst single hit is 0.25, under the 0.50 cap.
- The masher's lead faints more often: 5 -> 11 of 18 rows pass.

Remaining failures:
- Galewisp in Marsh Channels, Tidal Cradle and Veilfall: the masher's lead rarely faints.
- Galewisp in Outer Reaches and Tether Current: both the lead-faint gap and the reader's lead cost (0.50–0.68) above 0.55× the masher's.
- Ripplet in Outer Reaches and Tether Current: the masher's lead faints in at most 0.08 of runs.

## Meadows band 2 (scale 1.0, held), before/after the interrupt pilot
```
t_b2.json {'MASHER': 'stag 5.2 ci 1.81 read_int 0.0', 'READER': 'stag 2.4 ci 0.00 read_int 0.0', 'SWITCH_READER': 'stag 3.9 ci 0.00 read_int 0.0'}
   terrapup M win1.00 faint0.00 lead0.35 S win1.00 faint0.00 lead0.71 ['masher lead losses insufficiently different', 'reader median lead cost above .55x masher']
   ripplet M win1.00 faint0.00 lead0.34 S win1.00 faint0.00 lead0.28 ['masher lead losses insufficiently different', 'reader median lead cost above .55x masher']
   galewisp M win1.00 faint0.83 lead1.00 S win1.00 faint0.00 lead0.00 PASS
ta_b2.json {'MASHER': 'stag 5.2 ci 1.81 read_int 0.0', 'READER': 'stag 3.3 ci 1.97 read_int 5.3', 'SWITCH_READER': 'stag 4.3 ci 1.81 read_int 4.4'}
   terrapup M win1.00 faint0.00 lead0.35 S win1.00 faint0.00 lead0.53 ['masher lead losses insufficiently different', 'reader median lead cost above .55x masher']
   ripplet M win1.00 faint0.00 lead0.34 S win1.00 faint0.00 lead0.12 ['masher lead losses insufficiently different']
   galewisp M win1.00 faint0.83 lead1.00 S win1.00 faint0.00 lead0.00 PASS

```

## Cloudreach and Stormwood baselines (scale 1.0, older pilot 638769ec, before the interrupt)
```
t_cloudreach data gaps (no ordinary trainer roster): ['cloudreach/windscar_ravine', 'cloudreach/high_roost_sky_shrine', 'cloudreach/summit_final_stronghold']
  cloudreach/gate_lower_cliffs       terrapup  M faint0.00 lead0.44 win1.00 | S faint0.00 lead0.73 win1.00 FAIL
  cloudreach/gate_lower_cliffs       ripplet   M faint1.00 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  cloudreach/gate_lower_cliffs       galewisp  M faint0.67 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  cloudreach/broken_causeways        terrapup  M faint0.00 lead0.29 win1.00 | S faint0.00 lead0.56 win1.00 FAIL
  cloudreach/broken_causeways        ripplet   M faint0.00 lead0.80 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  cloudreach/broken_causeways        galewisp  M faint0.00 lead0.67 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  cloudreach/upper_cloudreach        terrapup  M faint0.00 lead0.45 win1.00 | S faint0.00 lead0.50 win1.00 FAIL
  cloudreach/upper_cloudreach        ripplet   M faint1.00 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  cloudreach/upper_cloudreach        galewisp  M faint0.50 lead0.99 win1.00 | S faint0.00 lead0.00 win1.00 PASS
t_stormwood data gaps (no ordinary trainer roster): ['stormwood/dynamo']
  stormwood/cinder_verge             terrapup  M faint0.00 lead0.34 win1.00 | S faint0.00 lead0.38 win1.00 FAIL
  stormwood/cinder_verge             ripplet   M faint0.00 lead0.67 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  stormwood/cinder_verge             galewisp  M faint0.25 lead0.84 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  stormwood/glowmoss_hollows         terrapup  M faint0.00 lead0.42 win1.00 | S faint0.00 lead0.70 win1.00 FAIL
  stormwood/glowmoss_hollows         ripplet   M faint0.00 lead0.64 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  stormwood/glowmoss_hollows         galewisp  M faint0.08 lead0.81 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  stormwood/conductor_run            terrapup  M faint0.00 lead0.49 win1.00 | S faint0.00 lead0.71 win1.00 FAIL
  stormwood/conductor_run            ripplet   M faint0.00 lead0.71 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  stormwood/conductor_run            galewisp  M faint0.08 lead0.82 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  stormwood/hollow_crown             terrapup  M faint0.00 lead0.36 win1.00 | S faint0.00 lead0.43 win1.00 FAIL
  stormwood/hollow_crown             ripplet   M faint0.08 lead0.77 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  stormwood/hollow_crown             galewisp  M faint0.33 lead0.86 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  stormwood/deepwood                 terrapup  M faint0.00 lead0.48 win1.00 | S faint0.00 lead0.71 win1.00 FAIL
  stormwood/deepwood                 ripplet   M faint0.17 lead0.68 win1.00 | S faint0.00 lead0.00 win1.00 FAIL
  stormwood/deepwood                 galewisp  M faint0.33 lead0.93 win1.00 | S faint0.00 lead0.00 win0.92 FAIL
```

## Galewisp (Tidewake at 1.3, per-starter, same pilot)
```
starter   pilot          median s  hits/s  incoming/s  switches  lead cost  lead faint  bursts
galewisp  MASHER         43        0.99    0.19        0         0.78       0.29        0
galewisp  SWITCH_READER  87        0.45    0.06        0.5       0.41       0.00        32
ripplet   MASHER         53        1.04    0.21        0         0.88       0.31        0
ripplet   SWITCH_READER  64        0.57    0.02        2.2       0.00       0.00        11
terrapup  MASHER         68        1.16    0.20        0         1.00       0.94        0
terrapup  SWITCH_READER  61        0.57    0.03        2.2       0.00       0.00        10
```

Galewisp's failures have two parts.

1. Pilot. The reader keeps Galewisp in because its visible type matchup is the best available against Tidewake teams (0.5 switches per fight vs 2.2). It then plays slowly: 87 s fights and 32 bursts, spent escaping fans and fields. Its lead cost of 0.41 lands just above 0.55× the masher's (0.43).
2. Game. A masher with Galewisp finishes trainer teams fastest (43 s), so its lead faints in only 29% of runs, against 94% with Terrapup. Galewisp's speed and offence let blind pressure win before the lead falls. This is a real "mashing works with the fastest starter" finding. It is not a trainer-data defect.

## Bands with no ordinary trainer roster: by design
- **Cloudreach Windscar Ravine:** only `keeper_maela_trial` (rank "mentor"; named pattern fight; WORLD §4.3 "Keeper Maela's Windscar trial teaches flight").
- **Cloudreach High Roost:** no trainer in `cloudreach_chapter.json::trainer_ladder`. WORLD §4 gives High Roost its payoff through bells and aeries, not fights.
- **Cloudreach Summit:** only `officer_voss_summit_approach` (elite) and `captain_veyra_storm_anchor` (captain), the WORLD §4.3 story fights.
- **Stormwood Dynamo:** only `outerworks_lieutenant_sera`, `officer_kestrel_outer_works` and `captain_marrow_dynamo_core` (`stormwood_trainers.json`, the finale region).

These bands are covered by F22#4's named fights, not by the ordinary-trainer sweep.

## All chapters at scale 1.0 on the interrupt pilot (555c5857)
```
ta_band10 gaps [] rows passing 5/15 {'MASHER': 'stag/fight 5.2 worst-hit 0.23', 'SWITCH_READER': 'stag/fight 3.3 worst-hit 0.20'}
  band1_lower_meadows            terrapup  M faint0.08 lead0.26 win1.00 | S faint0.00 lead0.32 win1.00 
  band1_lower_meadows            ripplet   M faint0.00 lead0.32 win1.00 | S faint0.00 lead0.10 win1.00 
  band1_lower_meadows            galewisp  M faint0.58 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  band2_stone_and_root           terrapup  M faint0.00 lead0.35 win1.00 | S faint0.00 lead0.53 win1.00 
  band2_stone_and_root           ripplet   M faint0.00 lead0.34 win1.00 | S faint0.00 lead0.12 win1.00 
  band2_stone_and_root           galewisp  M faint0.83 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  band3_the_river_lock           terrapup  M faint0.00 lead0.25 win1.00 | S faint0.00 lead0.58 win1.00 
  band3_the_river_lock           ripplet   M faint0.00 lead0.37 win1.00 | S faint0.00 lead0.14 win1.00 
  band3_the_river_lock           galewisp  M faint0.50 lead0.99 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  band4_upper_meadows_ironwood   terrapup  M faint0.00 lead0.36 win1.00 | S faint0.00 lead0.52 win1.00 
  band4_upper_meadows_ironwood   ripplet   M faint0.00 lead0.50 win1.00 | S faint0.00 lead0.09 win1.00 
  band4_upper_meadows_ironwood   galewisp  M faint0.58 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  band5_stronghold_approach      terrapup  M faint0.00 lead0.38 win1.00 | S faint0.00 lead0.40 win1.00 
  band5_stronghold_approach      ripplet   M faint0.00 lead0.42 win1.00 | S faint0.00 lead0.17 win1.00 
  band5_stronghold_approach      galewisp  M faint0.50 lead0.92 win1.00 | S faint0.00 lead0.00 win1.00 PASS
ta_cloudreach10 gaps ['cloudreach/windscar_ravine', 'cloudreach/high_roost_sky_shrine', 'cloudreach/summit_final_stronghold'] rows passing 4/9 {'MASHER': 'stag/fight 12.5 worst-hit 0.09', 'SWITCH_READER': 'stag/fight 8.2 worst-hit 0.07'}
  cloudreach/gate_lower_cliffs   terrapup  M faint0.00 lead0.44 win1.00 | S faint0.00 lead0.72 win1.00 
  cloudreach/gate_lower_cliffs   ripplet   M faint1.00 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  cloudreach/gate_lower_cliffs   galewisp  M faint0.67 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  cloudreach/broken_causeways    terrapup  M faint0.00 lead0.29 win1.00 | S faint0.00 lead0.45 win1.00 
  cloudreach/broken_causeways    ripplet   M faint0.00 lead0.80 win1.00 | S faint0.00 lead0.00 win1.00 
  cloudreach/broken_causeways    galewisp  M faint0.00 lead0.67 win1.00 | S faint0.00 lead0.00 win1.00 
  cloudreach/upper_cloudreach    terrapup  M faint0.00 lead0.45 win1.00 | S faint0.00 lead0.53 win1.00 
  cloudreach/upper_cloudreach    ripplet   M faint1.00 lead1.00 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  cloudreach/upper_cloudreach    galewisp  M faint0.50 lead0.99 win1.00 | S faint0.00 lead0.00 win1.00 PASS
ta_stormwood10 gaps ['stormwood/dynamo'] rows passing 3/15 {'MASHER': 'stag/fight 13.2 worst-hit 0.08', 'SWITCH_READER': 'stag/fight 8.9 worst-hit 0.06'}
  stormwood/cinder_verge         terrapup  M faint0.00 lead0.34 win1.00 | S faint0.00 lead0.31 win1.00 
  stormwood/cinder_verge         ripplet   M faint0.00 lead0.67 win1.00 | S faint0.00 lead0.00 win1.00 
  stormwood/cinder_verge         galewisp  M faint0.25 lead0.84 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  stormwood/glowmoss_hollows     terrapup  M faint0.00 lead0.42 win1.00 | S faint0.00 lead0.66 win1.00 
  stormwood/glowmoss_hollows     ripplet   M faint0.00 lead0.64 win1.00 | S faint0.00 lead0.00 win1.00 
  stormwood/glowmoss_hollows     galewisp  M faint0.08 lead0.81 win1.00 | S faint0.00 lead0.00 win1.00 
  stormwood/conductor_run        terrapup  M faint0.00 lead0.49 win1.00 | S faint0.00 lead0.63 win1.00 
  stormwood/conductor_run        ripplet   M faint0.00 lead0.71 win1.00 | S faint0.00 lead0.00 win1.00 
  stormwood/conductor_run        galewisp  M faint0.08 lead0.82 win1.00 | S faint0.00 lead0.00 win1.00 
  stormwood/hollow_crown         terrapup  M faint0.00 lead0.36 win1.00 | S faint0.00 lead0.31 win1.00 
  stormwood/hollow_crown         ripplet   M faint0.08 lead0.77 win1.00 | S faint0.00 lead0.00 win1.00 
  stormwood/hollow_crown         galewisp  M faint0.33 lead0.86 win1.00 | S faint0.00 lead0.00 win1.00 PASS
  stormwood/deepwood             terrapup  M faint0.00 lead0.48 win1.00 | S faint0.00 lead0.62 win1.00 
  stormwood/deepwood             ripplet   M faint0.17 lead0.68 win1.00 | S faint0.00 lead0.00 win1.00 
  stormwood/deepwood             galewisp  M faint0.33 lead0.93 win1.00 | S faint0.00 lead0.00 win1.00 PASS
```
