# F22#1 Galewisp sky_rend trial A/B (owner parity ruling 2026-10-05)

Run: `smoke_f22_pattern_bands.gd --trainers`, 12 seeds per starter per band, on one head (tb/f22 c0171ebb code). TRIAL-ON uses moves.json (sky_rend range 6.5). TRIAL-OFF uses `--move-patch=sky_rend.range=10`, an in-memory test-only override on the same head.

Columns: masher lead-faint (lf), masher median lead cost (lc), switching-reader win / median lead cost, then the row verdict.

```
== meadows   (masher lead-faint, masher lead cost | switch-reader win/lead cost, verdict)   TRIAL-ON  vs  TRIAL-OFF
  band1_lower_meadows            galewisp lf0.92 lc1.00|S1.00/0.00 P   lf0.75 lc1.00|S1.00/0.00 P
  band1_lower_meadows            ripplet  lf0.25 lc0.37|S1.00/0.11 P   lf0.25 lc0.37|S1.00/0.11 P
  band1_lower_meadows            terrapup lf0.17 lc0.30|S1.00/0.36 F   lf0.17 lc0.30|S1.00/0.36 F
  band2_stone_and_root           galewisp lf0.92 lc1.00|S1.00/0.00 P   lf0.83 lc1.00|S1.00/0.00 P
  band2_stone_and_root           ripplet  lf0.00 lc0.39|S1.00/0.14 F   lf0.00 lc0.39|S1.00/0.14 F
  band2_stone_and_root           terrapup lf0.00 lc0.40|S1.00/0.60 F   lf0.00 lc0.40|S1.00/0.60 F
  band3_the_river_lock           galewisp lf0.67 lc1.00|S1.00/0.00 P   lf0.67 lc1.00|S1.00/0.00 P
  band3_the_river_lock           ripplet  lf0.00 lc0.42|S1.00/0.16 F   lf0.00 lc0.42|S1.00/0.16 F
  band3_the_river_lock           terrapup lf0.00 lc0.29|S1.00/0.62 F   lf0.00 lc0.29|S1.00/0.62 F
  band4_upper_meadows_ironwood   galewisp lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  band4_upper_meadows_ironwood   ripplet  lf0.00 lc0.57|S1.00/0.11 F   lf0.00 lc0.57|S1.00/0.11 F
  band4_upper_meadows_ironwood   terrapup lf0.00 lc0.49|S1.00/0.60 F   lf0.00 lc0.49|S1.00/0.60 F
  band5_stronghold_approach      galewisp lf0.83 lc1.00|S1.00/0.00 P   lf0.67 lc1.00|S1.00/0.00 P
  band5_stronghold_approach      ripplet  lf0.00 lc0.49|S1.00/0.20 F   lf0.00 lc0.49|S1.00/0.20 F
  band5_stronghold_approach      terrapup lf0.00 lc0.44|S1.00/0.46 F   lf0.00 lc0.44|S1.00/0.46 F
   galewisp mean masher lead-faint ON 0.87 OFF 0.78   pass ON 5/5 OFF 5/5
   ripplet  mean masher lead-faint ON 0.05 OFF 0.05   pass ON 1/5 OFF 1/5
   terrapup mean masher lead-faint ON 0.03 OFF 0.03   pass ON 0/5 OFF 0/5
== tidewake   (masher lead-faint, masher lead cost | switch-reader win/lead cost, verdict)   TRIAL-ON  vs  TRIAL-OFF
  first_shores                   galewisp lf1.00 lc1.00|S1.00/0.40 P   lf1.00 lc1.00|S1.00/0.40 P
  first_shores                   ripplet  lf0.50 lc0.99|S1.00/0.00 P   lf0.50 lc0.99|S1.00/0.00 P
  first_shores                   terrapup lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  marsh_channels                 galewisp lf0.17 lc0.85|S1.00/0.30 F   lf0.08 lc0.79|S1.00/0.30 F
  marsh_channels                 ripplet  lf0.33 lc0.88|S1.00/0.00 P   lf0.33 lc0.88|S1.00/0.00 P
  marsh_channels                 terrapup lf0.92 lc1.00|S1.00/0.00 P   lf0.92 lc1.00|S1.00/0.00 P
  outer_reaches                  galewisp lf0.00 lc0.68|S1.00/0.68 F   lf0.00 lc0.44|S1.00/0.68 F
  outer_reaches                  ripplet  lf0.00 lc0.73|S1.00/0.00 F   lf0.00 lc0.73|S1.00/0.00 F
  outer_reaches                  terrapup lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  tether_current                 galewisp lf0.08 lc0.82|S1.00/0.50 F   lf0.08 lc0.80|S1.00/0.50 F
  tether_current                 ripplet  lf0.08 lc0.79|S1.00/0.00 F   lf0.08 lc0.79|S1.00/0.00 F
  tether_current                 terrapup lf0.83 lc1.00|S1.00/0.00 P   lf0.83 lc1.00|S1.00/0.00 P
  tidal_cradle                   galewisp lf0.42 lc0.84|S1.00/0.24 P   lf0.25 lc0.85|S1.00/0.24 P
  tidal_cradle                   ripplet  lf0.33 lc0.92|S1.00/0.00 P   lf0.33 lc0.92|S1.00/0.00 P
  tidal_cradle                   terrapup lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  veilfall                       galewisp lf0.50 lc0.83|S1.00/0.60 F   lf0.50 lc0.83|S1.00/0.60 F
  veilfall                       ripplet  lf0.58 lc1.00|S1.00/0.00 P   lf0.58 lc1.00|S1.00/0.00 P
  veilfall                       terrapup lf0.92 lc1.00|S1.00/0.00 P   lf0.92 lc1.00|S1.00/0.00 P
   galewisp mean masher lead-faint ON 0.36 OFF 0.32   pass ON 2/6 OFF 2/6
   ripplet  mean masher lead-faint ON 0.31 OFF 0.31   pass ON 4/6 OFF 4/6
   terrapup mean masher lead-faint ON 0.94 OFF 0.94   pass ON 6/6 OFF 6/6
== cloudreach   (masher lead-faint, masher lead cost | switch-reader win/lead cost, verdict)   TRIAL-ON  vs  TRIAL-OFF
  broken_causeways               galewisp lf0.33 lc0.98|S1.00/0.00 P   lf0.25 lc0.94|S1.00/0.00 P
  broken_causeways               ripplet  lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  broken_causeways               terrapup lf0.00 lc0.37|S1.00/0.58 F   lf0.00 lc0.37|S1.00/0.58 F
  gate_lower_cliffs              galewisp lf1.00 lc1.00|S1.00/0.00 P   lf0.92 lc1.00|S1.00/0.00 P
  gate_lower_cliffs              ripplet  lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  gate_lower_cliffs              terrapup lf0.00 lc0.57|S1.00/0.74 F   lf0.00 lc0.57|S1.00/0.74 F
  upper_cloudreach               galewisp lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  upper_cloudreach               ripplet  lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  upper_cloudreach               terrapup lf0.00 lc0.58|S1.00/0.69 F   lf0.00 lc0.58|S1.00/0.69 F
   galewisp mean masher lead-faint ON 0.78 OFF 0.72   pass ON 3/3 OFF 3/3
   ripplet  mean masher lead-faint ON 1.00 OFF 1.00   pass ON 3/3 OFF 3/3
   terrapup mean masher lead-faint ON 0.00 OFF 0.00   pass ON 0/3 OFF 0/3
== stormwood   (masher lead-faint, masher lead cost | switch-reader win/lead cost, verdict)   TRIAL-ON  vs  TRIAL-OFF
  cinder_verge                   galewisp lf0.58 lc1.00|S1.00/0.00 P   lf0.42 lc0.92|S1.00/0.00 P
  cinder_verge                   ripplet  lf0.33 lc0.87|S1.00/0.00 P   lf0.33 lc0.87|S1.00/0.00 P
  cinder_verge                   terrapup lf0.00 lc0.45|S1.00/0.40 F   lf0.00 lc0.45|S1.00/0.40 F
  conductor_run                  galewisp lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  conductor_run                  ripplet  lf0.42 lc0.99|S1.00/0.00 P   lf0.42 lc0.99|S1.00/0.00 P
  conductor_run                  terrapup lf0.00 lc0.65|S1.00/0.71 F   lf0.00 lc0.65|S1.00/0.71 F
  deepwood                       galewisp lf1.00 lc1.00|S1.00/0.00 P   lf1.00 lc1.00|S1.00/0.00 P
  deepwood                       ripplet  lf0.58 lc1.00|S1.00/0.00 P   lf0.58 lc1.00|S1.00/0.00 P
  deepwood                       terrapup lf0.00 lc0.60|S1.00/0.70 F   lf0.00 lc0.60|S1.00/0.70 F
  glowmoss_hollows               galewisp lf0.75 lc1.00|S1.00/0.00 P   lf0.67 lc1.00|S1.00/0.00 P
  glowmoss_hollows               ripplet  lf0.33 lc0.90|S1.00/0.00 P   lf0.33 lc0.90|S1.00/0.00 P
  glowmoss_hollows               terrapup lf0.00 lc0.58|S1.00/0.71 F   lf0.00 lc0.58|S1.00/0.71 F
  hollow_crown                   galewisp lf1.00 lc1.00|S1.00/0.00 P   lf0.92 lc1.00|S1.00/0.00 P
  hollow_crown                   ripplet  lf0.58 lc1.00|S1.00/0.00 P   lf0.58 lc1.00|S1.00/0.00 P
  hollow_crown                   terrapup lf0.00 lc0.47|S1.00/0.40 F   lf0.00 lc0.47|S1.00/0.40 F
   galewisp mean masher lead-faint ON 0.87 OFF 0.80   pass ON 5/5 OFF 5/5
   ripplet  mean masher lead-faint ON 0.45 OFF 0.45   pass ON 5/5 OFF 5/5
   terrapup mean masher lead-faint ON 0.00 OFF 0.00   pass ON 0/5 OFF 0/5
```

## Reading

1. **The trial changes no verdict.** Galewisp's row passes are identical with
   the trial on and off in every chapter:
   - Meadows 5/5
   - Tidewake 2/6
   - Cloudreach 3/3
   - Stormwood 5/5

   The trial only raises Galewisp's masher lead-faint:
   - Meadows 0.78 → 0.87
   - Tidewake 0.32 → 0.36
   - Cloudreach 0.72 → 0.78
   - Stormwood 0.80 → 0.87

   In Meadows that moves away from parity.

2. **The trial did not cause the Meadows gap.** Without the trial, the Meadows
   masher lead-faint is 0.78 for Galewisp against 0.05 for Ripplet and 0.03
   for Terrapup.

3. **Terrapup is the outlier everywhere except Tidewake.**
   - Its masher lead-faint is 0.00 in Cloudreach and Stormwood, and 0.03 in
     Meadows.
   - In every failing Terrapup row, the switching reader's median lead cost
     is HIGHER than the masher's. Examples: Cloudreach 0.58–0.74 against
     0.37–0.58; Stormwood 0.40–0.71 against 0.45–0.65.
   - So reading costs Terrapup more than mashing. No restated lead-faint bar
     would fix that.
   - In Tidewake the type chart flips it: its masher lead-faint is 0.94 and
     every row passes.

4. **Ripplet fails only the lead-faint gap, mostly in Meadows.** There, the
   reader's lead cost is 0.11–0.20 against the masher's 0.37–0.57. That
   satisfies the COMBAT §7 floor-trainer form: reader median lead cost ≤ 0.55×
   the masher's, reader win ≥ 0.9, and "masher may still win at meaningful
   cost".

## Terrapup per-starter tuning (coordinator ruling 2026-10-05, item 2): progress

Burst-distance lever (`combat.json` `burst.species_distance`, read by one
`burst_profile()` for solo, host and the Stormwood hosted fight). Measured in
Cloudreach, 12 seeds, with the switching reader's median lead cost:

| Band | 3.0 m (shipped) | 4.0 m | 5.0 m | Bar (≤0.55× masher) |
|---|---|---|---|---|
| gate_lower_cliffs | 0.74 | 0.72 | 0.73 | ≤0.31 |
| broken_causeways | 0.58 | 0.50 | 0.44 | ≤0.20 |
| upper_cloudreach | 0.69 | 0.59 | 0.53 | ≤0.32 |

Not sufficient after two attempts, so the approach changed. No override is
authored.

### Attribution

Cloudreach `gate_lower_cliffs`, 12 seeds. The pilot hit events now record the
attack that landed.

- With Terrapup, the switching reader takes 123 `current_zone` field hits and
  56 `current_volley` fan hits.
- With Galewisp, it takes 30 field hits and 26 fan hits.
- Per second of fight, that is about 0.09 field hits/s for Terrapup against
  0.015/s for Galewisp.
- Both starters share the same move speed and burst.

### Hypothesis under test

`current_zone`'s marker tracks the target for the first 30% of its 1.1 s tell
(`marker_tracks_fraction` 0.3). That leaves about 0.77 s after it locks to
clear the marker radius plus the body radius:

- Terrapup needs (2.5 + 1.46) m at 5 m/s, which is 0.79 s: not escapable on
  foot.
- Galewisp needs (2.5 + 1.23) m, which is 0.75 s: just escapable.

A burst would cover the gap, but the burst trial above barely helped, so the
cause is still unconfirmed. Next step: a per-tell pilot log of the distance
to the marker at strike and the action the reader took.

### Further Terrapup levers, measured in memory with `--config-patch` (Cloudreach, 12 seeds)

Each value is the switching reader's median lead cost.

| Patch | gate_lower_cliffs | broken_causeways | upper_cloudreach | `current_zone` reader hits |
|---|---|---|---|---|
| none (shipped) | 0.74 | 0.58 | 0.69 | 123 |
| `current_zone.marker_tracks_fraction` = 0 | 0.72 | 0.58 | 0.69 | — |
| `current_zone.field_duration_s` = 0.3 | 0.73 | 0.58 | 0.69 | 111 |
| `creature_movement.speed` = 6.2 (player only) | 0.73 | 0.63 | 0.62 | 120 |

None of these changes the verdict. A longer burst, a static field marker, a
0.3 s field and +11% move speed each make escaping easier, yet the reader
still takes the same field hits.

The remaining hits also come from the CHARGER rushes. In the 6.2 m/s run,
`charger_double_rush` landed 169 times and `charger_rush` 70.

Reading: the cost is not an escape-distance shortfall. The likeliest cause is
how the switching reader plays a melee, large-bodied starter, which is test
equipment. The other possibility is a matchup property of Terrapup's kit.
Three levers have now failed, so this is escalated for a decision instead of
another guess.

## Reader improvement (option a, one attempt; pilot commit 5478b0b4)

Full 12-seed table, all starters and chapters. Each cell is the switching reader / masher median lead cost on the shipped head, before and after the pilot change. Verdict uses the floor-trainer form: reader cost ≤ 0.55× the masher's, reader win ≥ 0.9.

```
meadows    band1_lower_meadows    galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
meadows    band1_lower_meadows    ripplet  before S0.11/0.37 P  after S0.00/0.37 P  minwin 1.00
meadows    band1_lower_meadows    terrapup before S0.36/0.30 F  after S0.40/0.30 F  minwin 1.00
meadows    band2_stone_and_root   galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
meadows    band2_stone_and_root   ripplet  before S0.14/0.39 P  after S0.18/0.39 P  minwin 1.00
meadows    band2_stone_and_root   terrapup before S0.60/0.40 F  after S0.48/0.40 F  minwin 1.00
meadows    band3_the_river_lock   galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
meadows    band3_the_river_lock   ripplet  before S0.16/0.42 P  after S0.20/0.42 P  minwin 1.00
meadows    band3_the_river_lock   terrapup before S0.62/0.29 F  after S0.61/0.29 F  minwin 1.00
meadows    band4_upper_meadows_ir galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
meadows    band4_upper_meadows_ir ripplet  before S0.11/0.57 P  after S0.16/0.57 P  minwin 1.00
meadows    band4_upper_meadows_ir terrapup before S0.60/0.49 F  after S0.46/0.49 F  minwin 1.00
meadows    band5_stronghold_appro galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
meadows    band5_stronghold_appro ripplet  before S0.20/0.49 P  after S0.14/0.49 P  minwin 1.00
meadows    band5_stronghold_appro terrapup before S0.46/0.44 F  after S0.41/0.44 F  minwin 1.00
tidewake   first_shores           galewisp before S0.40/1.00 P  after S0.47/1.00 P  minwin 1.00
tidewake   first_shores           ripplet  before S0.00/0.99 P  after S0.00/0.99 P  minwin 1.00
tidewake   first_shores           terrapup before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
tidewake   marsh_channels         galewisp before S0.30/0.79 P  after S0.26/0.79 P  minwin 1.00
tidewake   marsh_channels         ripplet  before S0.00/0.88 P  after S0.00/0.88 P  minwin 1.00
tidewake   marsh_channels         terrapup before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
tidewake   outer_reaches          galewisp before S0.68/0.44 F  after S0.71/0.44 F  minwin 1.00
tidewake   outer_reaches          ripplet  before S0.00/0.73 P  after S0.00/0.73 P  minwin 1.00
tidewake   outer_reaches          terrapup before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
tidewake   tether_current         galewisp before S0.50/0.80 F  after S0.41/0.80 P  minwin 1.00
tidewake   tether_current         ripplet  before S0.00/0.79 P  after S0.00/0.79 P  minwin 1.00
tidewake   tether_current         terrapup before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
tidewake   tidal_cradle           galewisp before S0.24/0.85 P  after S0.27/0.85 P  minwin 1.00
tidewake   tidal_cradle           ripplet  before S0.00/0.92 P  after S0.00/0.92 P  minwin 1.00
tidewake   tidal_cradle           terrapup before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
tidewake   veilfall               galewisp before S0.60/0.83 F  after S0.57/0.83 F  minwin 1.00
tidewake   veilfall               ripplet  before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
tidewake   veilfall               terrapup before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
cloudreach broken_causeways       galewisp before S0.00/0.94 P  after S0.00/0.94 P  minwin 1.00
cloudreach broken_causeways       ripplet  before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
cloudreach broken_causeways       terrapup before S0.58/0.37 F  after S0.58/0.37 F  minwin 1.00
cloudreach gate_lower_cliffs      galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
cloudreach gate_lower_cliffs      ripplet  before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
cloudreach gate_lower_cliffs      terrapup before S0.74/0.57 F  after S0.73/0.57 F  minwin 1.00
cloudreach upper_cloudreach       galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
cloudreach upper_cloudreach       ripplet  before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
cloudreach upper_cloudreach       terrapup before S0.69/0.58 F  after S0.73/0.58 F  minwin 1.00
stormwood  cinder_verge           galewisp before S0.00/0.92 P  after S0.00/0.92 P  minwin 1.00
stormwood  cinder_verge           ripplet  before S0.00/0.87 P  after S0.00/0.87 P  minwin 1.00
stormwood  cinder_verge           terrapup before S0.40/0.45 F  after S0.41/0.45 F  minwin 1.00
stormwood  conductor_run          galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
stormwood  conductor_run          ripplet  before S0.00/0.99 P  after S0.00/0.99 P  minwin 1.00
stormwood  conductor_run          terrapup before S0.71/0.65 F  after S0.68/0.65 F  minwin 1.00
stormwood  deepwood               galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
stormwood  deepwood               ripplet  before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
stormwood  deepwood               terrapup before S0.70/0.60 F  after S0.71/0.60 F  minwin 1.00
stormwood  glowmoss_hollows       galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
stormwood  glowmoss_hollows       ripplet  before S0.00/0.90 P  after S0.00/0.90 P  minwin 1.00
stormwood  glowmoss_hollows       terrapup before S0.71/0.58 F  after S0.71/0.58 F  minwin 1.00
stormwood  hollow_crown           galewisp before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
stormwood  hollow_crown           ripplet  before S0.00/1.00 P  after S0.00/1.00 P  minwin 1.00
stormwood  hollow_crown           terrapup before S0.40/0.47 F  after S0.51/0.47 F  minwin 1.00
```

Result:

- No previously passing row fails, and the reader win rate is 1.00 in every row.
- Tidewake `tether_current` Galewisp now passes (reader 0.41 against masher 0.80).
- Terrapup still fails all 13 Meadows, Cloudreach and Stormwood rows, with small movements in both directions.

The one attempt is spent. Under the owner ruling of 2026-10-05 Terrapup must be balanced like the other starters, so the next step is product tuning, proposed to the coordinator before any data change.

Attribution note: the switching reader's lead cost is 0.00 for Galewisp and Ripplet in most rows because it switches them out of visible mismatches. Terrapup's visible matchups are favourable in Cloudreach and Stormwood, so it stays in. Its reader fights also run about twice as long as its masher fights (about 110 s against 49 s) at a similar hit rate.
