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
