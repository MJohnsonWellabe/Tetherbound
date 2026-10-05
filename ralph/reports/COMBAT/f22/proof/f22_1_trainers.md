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
