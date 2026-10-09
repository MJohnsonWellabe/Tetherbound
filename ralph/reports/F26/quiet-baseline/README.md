Quiet baseline, 2026-10-09

All 24 timing cases completed. Every Stormwood run reported a missing/stale scatter bake, so those six rows do not certify the complete biome. The current rolling shipping pack (now 7dd4a777f) has matching Stormwood bake/scatter resources; the full pack comparison is retained in pack-comparison.json. This report uses the release-mode F26 capture-tool fallback on published latest source `7c7d25873`. The executable matches the published Windows release; the PCK adds elapsed-time and viewport-timing instrumentation. The exact source/export delta is retained in measurement-source.patch. No gameplay/config default changed.

i5-8400, GTX 1060 3GB, 16 GiB RAM, Balanced power plan, 1920x1080 fullscreen at 60 Hz, VSync disabled, no fps cap. System CPU/GPU remained below 10% for a continuous minute before measurements. Process snapshot and utilization samples are in receipt.json.

Seed 2042, existing F26 routes, fresh isolated user home for every run, 15 seconds elapsed warmup, at least 60 seconds timed. Short Meadows/Tidewake routes hold their final pose to complete the timed interval; Cloudreach/Stormwood cover their longer full route. Low uses Compatibility and Medium/High use Forward+. Startup/world/shader time is outside the timed interval. Preparation and fresh startup made the overall quiet window longer than the 45-minute target.

FPS is 1000 divided by mean wall-frame milliseconds. P95/P99 are wall-frame percentiles. CPU render+setup is renderer work only; process and physics are separate overlapping monitors and cannot be summed into a total CPU frame time. GPU is the root viewport renderer time. Each repeat is shown separately.

| Biome | Preset | Run | Mean fps | P95 ms | P99 ms | CPU render+setup ms | GPU ms | CPU process ms | Physics ms |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Meadows | Low | 1 | 43.60 | 33.45 | 38.66 | 7.03 | 18.88 | 32.14 | 3.73 |
| Meadows | Low | 2 | 43.50 | 33.54 | 36.52 | 6.98 | 18.91 | 26.16 | 3.82 |
| Meadows | Medium | 1 | 42.05 | 32.84 | 37.39 | 3.13 | 22.34 | 34.05 | 9.81 |
| Meadows | Medium | 2 | 42.16 | 32.84 | 38.34 | 3.07 | 22.36 | 35.97 | 9.87 |
| Meadows | High | 1 | 36.30 | 33.97 | 37.68 | 3.10 | 27.09 | 34.30 | 5.33 |
| Meadows | High | 2 | 36.34 | 34.01 | 41.96 | 3.09 | 27.03 | 34.01 | 5.04 |
| Tidewake | Low | 1 | 22.12 | 83.52 | 131.74 | 3.91 | 13.91 | 20.62 | 14.50 |
| Tidewake | Low | 2 | 32.99 | 52.41 | 82.75 | 3.82 | 13.95 | 18.18 | 12.75 |
| Tidewake | Medium | 1 | 29.69 | 62.80 | 93.37 | 1.58 | 21.90 | 18.50 | 15.05 |
| Tidewake | Medium | 2 | 29.97 | 53.57 | 80.31 | 1.57 | 21.89 | 17.00 | 13.70 |
| Tidewake | High | 1 | 24.87 | 71.90 | 114.63 | 1.65 | 24.86 | 27.48 | 16.24 |
| Tidewake | High | 2 | 32.92 | 46.02 | 59.65 | 1.64 | 25.06 | 26.40 | 13.59 |
| Cloudreach | Low | 1 | 51.21 | 23.30 | 25.02 | 11.50 | 15.70 | 22.48 | 3.60 |
| Cloudreach | Low | 2 | 51.72 | 22.57 | 24.21 | 11.58 | 15.71 | 22.18 | 3.66 |
| Cloudreach | Medium | 1 | 92.65 | 14.74 | 17.12 | 1.39 | 10.55 | 14.36 | 3.74 |
| Cloudreach | Medium | 2 | 90.36 | 16.65 | 19.22 | 1.41 | 10.56 | 14.84 | 5.10 |
| Cloudreach | High | 1 | 72.53 | 17.35 | 19.01 | 1.46 | 13.58 | 15.67 | 4.14 |
| Cloudreach | High | 2 | 72.29 | 17.41 | 20.14 | 1.48 | 13.60 | 16.77 | 4.33 |
| Stormwood | Low | 1 | 71.29 | 16.70 | 18.18 | 4.88 | 13.09 | 18.45 | 3.35 |
| Stormwood | Low | 2 | 71.61 | 16.47 | 17.96 | 4.86 | 13.05 | 18.21 | 3.38 |
| Stormwood | Medium | 1 | 42.34 | 28.96 | 30.37 | 2.35 | 23.33 | 24.56 | 4.31 |
| Stormwood | Medium | 2 | 42.46 | 28.73 | 29.96 | 2.31 | 23.28 | 25.40 | 3.99 |
| Stormwood | High | 1 | 36.45 | 32.60 | 33.88 | 2.45 | 27.18 | 29.16 | 4.41 |
| Stormwood | High | 2 | 36.52 | 32.52 | 33.90 | 2.44 | 27.13 | 29.04 | 4.33 |

Raw samples and logs are committed per case, with hashes in receipt.json. Native shutdown/resource warnings and errors, if present, are retained and counted in the receipt; successful route completion does not assert clean engine teardown. Measurement timings alone do not establish a gameplay root cause. No visual verdict or whole-criterion READY is claimed by this baseline.
