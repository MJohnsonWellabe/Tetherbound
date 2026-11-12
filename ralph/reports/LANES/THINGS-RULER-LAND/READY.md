STATUS: land

# THINGS-RULER landing (pose stage: ruler clear of the posed creature by default)

Branch `tb/things-ruler-land`, cut from main f421556c. Tooling only; no game change.

Verdict: `ralph/reports/GPU-PASS/1108/G-things-ruler-rescore.md` on tb/item-scout-1108 86e6ee44 (GPU High): every row gains, none loses.

| Row | Before | After |
|---|---|---|
| F36#33 Ashtusk | 7.22 | 8.03 (needs Medium) |
| F36#36 Brooktail | 6.93 | 7.69 (needs Medium) |
| F36#52 Mirejaw | 6.07 | 7.26 |
| F36#62 Riftfrill | 6.88 | 7.31 |
| F36#70 Sparkit | 6.98 | 7.26 |
| F36#66 Shadelet | 6.88 | 7.07 |

Change: `tools/art_pipeline/capture_f36_poses.gd` places the trainer ruler clear of the posed mesh by default (`--clear-ruler` still accepted; `--rest-ruler` restores the old placement for reproducing earlier rounds). `docs/TECHNICAL.md` §8.1 line updated.

Check: CPU, mirejaw hit with no flag now matches the `--clear-ruler` frame (ruler in the clear position) and differs from the old one. No test references the flag.
