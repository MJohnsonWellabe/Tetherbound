Accepted-main334 actual shipping preset comparison

All four Medium routes fail the owner desktop target of >=60 FPS average and >=40 FPS 1% low (STATE, owner2026-10-04 7:50PM CT). Meadows, Tidewake and Stormwood also fail the older20 FPS average floor. All12 strict minimums are below20. The performance blocker remains OPEN.

| Biome | Preset | Average FPS | 1% low | Minimum | Frames | Medium60/40 |
|---|---|---:|---:|---:|---:|---|
| Meadows | Low | 11.129 | 7.291 | 6.159 | 213 | not scored |
| Meadows | Medium | 12.266 | 10.379 | 9.929 | 235 | FAIL |
| Meadows | High | 11.888 | 10.025 | 9.922 | 228 | not scored |
| Tidewake | Low | 8.385 | 5.258 | 4.797 | 120 | not scored |
| Tidewake | Medium | 9.615 | 6.224 | 6.192 | 120 | FAIL |
| Tidewake | High | 10.633 | 6.395 | 6.352 | 120 | not scored |
| Stormwood | Low | 13.794 | 7.108 | 2.731 | 2100 | not scored |
| Stormwood | Medium | 17.544 | 11.968 | 5.886 | 2662 | FAIL |
| Stormwood | High | 17.599 | 12.082 | 5.593 | 2670 | not scored |
| Cloudreach | Low | 33.291 | 20.897 | 3.345 | 5835 | not scored |
| Cloudreach | Medium | 59.667 | 23.688 | 13.272 | 10446 | FAIL |
| Cloudreach | High | 59.285 | 26.095 | 12.418 | 10379 | not scored |

All cases used unchanged accepted-main334 actual release EXE/PCK/releaseTerrainDLL on GTX1060 3GB at1920x1080, without debug/EngineProfiler/gpu-profile/background trace. Native exit0 and routecomplete=true for all12. Exact CLI, fresh preset profile, native logs, original raw route and PNGs, source/payload identities and byte inventories are preserved percase. New8 cases use fullscreen; prior4 core cases did not request fullscreen. There is no single matched-source change A/B here.

Calculation: average=1000*n/sum(wall_ms); 1%low=1000/mean(slowest ceil(n*.01) intervals); minimum=1000/max(wall_ms). Samples exclude startup and use the existing packaged route timing. Low is Compatibility; Medium/High are Forward+. Authored camera far floors are2000/6500/9000/3500m for Meadows/Tidewake/Stormwood/Cloudreach.

Independent integrity/math reviews for original4 are in their delivery-review.md files. New8 fresh bounded independent delivery-review.md files also PASS byte integrity and arithmetic. Arithmetic and file preservation PASS never constitute performance acceptance.

Limitations: runtime caps/VSync/physics/time settings remain unverified in the embedded shipping tool; no uncapped assertion. Cached CPU monitors do not provide true per-frame CPU/GPU attribution. Sequential live environment/time/Surge, renderer differences, sampling lengths and fullscreen differences prevent isolated preset or optimization causality. No earlier comparable shipping baseline establishes a new regression. Desktop production-route fixtures do not establish earned campaign, full fight/co-op, Ally or full visual-bar acceptance.

Evidence paths:
- ralph/reports/LOOKDEV/handoffs/perf/perf-retime-2/accepted-main/shipping-low-meadows
- ralph/reports/LOOKDEV/handoffs/perf/perf-retime-2/accepted-main/shipping-medium-meadows
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-high-meadows
- ralph/reports/LOOKDEV/handoffs/perf/perf-retime-2/accepted-main/shipping-low-water
- ralph/reports/LOOKDEV/handoffs/perf/perf-retime-2/accepted-main/shipping-medium-water
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-high-water
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-low-stormwood
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-medium-stormwood
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-high-stormwood
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-low-cloudreach
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-medium-cloudreach
- ralph/reports/LOOKDEV/f26/shipping-preset-matrix/accepted-main334/shipping-high-cloudreach
