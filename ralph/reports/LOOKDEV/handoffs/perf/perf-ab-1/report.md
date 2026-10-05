# Packaged-data PERF A/B: partial diagnostic evidence

Identical pinned editor-capable engine hosts with --main-pack loading byte-identical pinned release game PCKs and external instrumentation, not shipping release FPS. Standard export templates refuse --script. No source filesystem fallback or Ally acceptance. Pins differ in realm far floors and other integrated runtime changes; this is not a pure isolated far-plane experiment.

GTX 1060 3GB; Godot 4.7 stable; Medium Forward+, 1920x1080, uncapped, VSync off, normal physics and time scale. Serial isolated profiles. One unreplicated pair per completed realm. These engine-host FPS values do not replace shipping release measurements.

**INCOMPLETE:** before Cloudreach exited 1 after 964.532 seconds with ['production world shell build timed out']. No timed Cloudreach rows; the fail-closed runner stopped before AFTER Cloudreach and both Stormwood passes. Real-fight physics evidence remains open.

**Shipping qualification remains open:** BEFORE export emitted seven shutdown-leak ERRORs despite exit0. Actual PCK freshness independently passed, permitting explicitly diagnostic use only. No game source workaround or weakened qualification.

| Route / pin | Far m | Frames | Average FPS | 1% low FPS |
|---|---:|---:|---:|---:|
| meadows / before | 520 | 181 | 5.380 | 1.071 |
| meadows / after | 2000 | 178 | 5.810 | 1.188 |
| water / before | 520 | 120 | 5.302 | 1.147 |
| water / after | 6500 | 120 | 4.059 | 1.065 |

Each monitor cell below is sample mean / mean on the slowest ceil(1%) wall-frame rows. Physics/process monitor values are approximately one-second cached maxima, not exact CPU costs of those individual frames. Primitives count engine vertices/indices including passes, not triangles. Video memory is the engine allocation monitor.

| Route / pin | Draw calls | Primitives | Objects | Cached physics ms | Cached process ms | Video MiB | Nodes |
|---|---:|---:|---:|---:|---:|---:|---:|
| meadows / before | 2169.12 / 831.00 | 4209898.75 / 3477088.50 | 3472.70 / 2161.00 | 7.37 / 5.15 | 516.14 / 120.83 | 1650.98 / 1650.99 | 183597.01 / 183533.00 |
| meadows / after | 2169.60 / 1827.50 | 4269809.77 / 3984989.50 | 3518.17 / 3282.50 | 7.92 / 6.88 | 545.10 / 426.94 | 1657.69 / 1657.55 | 183601.56 / 183543.00 |
| water / before | 758.82 / 721.50 | 2980726.43 / 2960613.00 | 1113.14 / 1070.00 | 12.63 / 12.09 | 446.04 / 50.16 | 841.06 / 840.47 | 7816.40 / 7804.50 |
| water / after | 773.37 / 725.00 | 3056568.64 / 3036823.50 | 1135.37 / 1082.00 | 16.11 / 10.91 | 402.68 / 473.31 | 846.63 / 843.85 | 7817.38 / 7804.50 |

| Route / pin | True process ms mean / max | True physics max-step ms mean / max | Mean GPU ms | Top GPU pass | Category |
|---|---:|---:|---:|---|---|
| meadows / before | 152.200 / 904.535 | 5.395 / 9.229 | 28.269 | Render Opaque Pass | other: mixed geometry |
| meadows / after | 138.453 / 833.914 | 5.432 / 20.958 | 28.014 | Render Opaque Pass | other: mixed geometry |
| water / before | 115.658 / 789.592 | 10.808 / 14.692 | 21.663 | Render Opaque Pass | other: mixed geometry |
| water / after | 142.181 / 880.487 | 14.382 / 37.434 | 32.834 | Render Opaque Pass | other: mixed geometry |

Physics max-step is the maximum individual physics-step CPU cost in each rendered engine iteration; multiple steps may share an iteration. All individual-step costs and per-step averages are not exposed. Do not divide this maximum by step count. Raw GPU blocks/task means are retained; first timed block excluded because it may include warmup. The opaque pass does not distinguish terrain, vegetation, water or far meshes, so content-specific attribution remains unproven.

Meadows showed no observed paired slowdown; Tidewake slowed and its GPU time increased. Single pairs across two integrated source pins cannot establish an isolated far-plane cause. See the independent completed-case review for the bounded PASS.
