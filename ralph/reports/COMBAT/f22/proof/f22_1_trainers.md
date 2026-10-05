# F22#1 ordinary-trainer bands (smoke_f22_pattern_bands.gd --trainers, 12 seeds)

## Before: trainer_power_scale 1.0, Tidewake (code at e525187c)
```
tidewake/first_shores      terrapup  M win1.00 faint0.25 lead0.95 | R win1.00 faint1.00 lead1.00 | S win1.00 faint0.00 lead0.00 PASS
tidewake/first_shores      ripplet   M win1.00 faint0.00 lead0.71 | R win1.00 faint0.25 lead0.91 | S win1.00 faint0.00 lead0.00 ['masher lead losses insufficiently different']
tidewake/first_shores      galewisp  M win1.00 faint0.17 lead0.77 | R win1.00 faint0.00 lead0.33 | S win1.00 faint0.00 lead0.33 ['masher lead losses insufficiently different']
tidewake/marsh_channels    terrapup  M win1.00 faint0.25 lead0.92 | R win1.00 faint0.42 lead0.77 | S win1.00 faint0.00 lead0.00 PASS
tidewake/marsh_channels    ripplet   M win1.00 faint0.08 lead0.66 | R win1.00 faint0.25 lead0.34 | S win1.00 faint0.00 lead0.00 ['masher lead losses insufficiently different']
tidewake/marsh_channels    galewisp  M win1.00 faint0.08 lead0.57 | R win1.00 faint0.08 lead0.23 | S win1.00 faint0.00 lead0.23 ['masher lead losses insufficiently different']
tidewake/tidal_cradle      terrapup  M win1.00 faint0.08 lead0.92 | R win1.00 faint0.25 lead0.86 | S win1.00 faint0.00 lead0.00 ['masher lead losses insufficiently different']
tidewake/tidal_cradle      ripplet   M win1.00 faint0.00 lead0.75 | R win1.00 faint0.00 lead0.37 | S win1.00 faint0.00 lead0.00 ['masher lead losses insufficiently different']
tidewake/tidal_cradle      galewisp  M win1.00 faint0.00 lead0.56 | R win1.00 faint0.00 lead0.21 | S win1.00 faint0.00 lead0.21 ['masher lead losses insufficiently different']
tidewake/outer_reaches     terrapup  M win1.00 faint0.92 lead1.00 | R win1.00 faint1.00 lead1.00 | S win1.00 faint0.00 lead0.00 PASS
tidewake/outer_reaches     ripplet   M win1.00 faint0.00 lead0.57 | R win1.00 faint0.67 lead1.00 | S win1.00 faint0.00 lead0.00 ['masher lead losses insufficiently different']
tidewake/outer_reaches     galewisp  M win1.00 faint0.00 lead0.35 | R win1.00 faint0.33 lead0.90 | S win1.00 faint0.00 lead0.73 ['masher lead losses insufficiently different', 'reader median lead cost above .55x masher']
tidewake/tether_current    terrapup  M win1.00 faint0.33 lead0.86 | R win1.00 faint0.58 lead1.00 | S win1.00 faint0.00 lead0.00 PASS
tidewake/tether_current    ripplet   M win1.00 faint0.00 lead0.56 | R win1.00 faint0.42 lead0.64 | S win1.00 faint0.00 lead0.00 ['masher lead losses insufficiently different']
tidewake/tether_current    galewisp  M win1.00 faint0.00 lead0.60 | R win1.00 faint0.42 lead0.38 | S win1.00 faint0.00 lead0.38 ['masher lead losses insufficiently different', 'reader median lead cost above .55x masher']
tidewake/veilfall          terrapup  M win1.00 faint0.58 lead1.00 | R win1.00 faint0.50 lead0.95 | S win1.00 faint0.00 lead0.00 PASS
tidewake/veilfall          ripplet   M win1.00 faint0.17 lead0.82 | R win1.00 faint0.50 lead0.75 | S win1.00 faint0.00 lead0.00 ['masher lead losses insufficiently different']
tidewake/veilfall          galewisp  M win1.00 faint0.00 lead0.62 | R win1.00 faint0.33 lead0.63 | S win1.00 faint0.00 lead0.59 ['masher lead losses insufficiently different', 'reader median lead cost above .55x masher']
```

Meadows band 2 (one band, before): the plain reader takes more lead damage than the masher (0.62–0.85 vs 0.34–0.35 for Terrapup/Ripplet); only Galewisp passes.

## After: Tidewake trainer_power_scale 1.3 (TRIAL, re-sweep running)
Pending. If it doesn't close the lead-faint gap without breaking the switching reader's ≥0.9 win or the 0.5 single-hit cap, it reverts to 1.0.
