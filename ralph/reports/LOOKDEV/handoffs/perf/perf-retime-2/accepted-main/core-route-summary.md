Accepted main334 desktop core performance escalation

Actual shipping release routes fail the owner20 FPS floor on GTX1060 3GB at1920x1080. Both Tidewake cases average below10 FPS. No earlier actual-release baseline was measured, so a new release regression is not established. The earlier diagnostic figures alone overstated Meadows slowdown.

| Route | Preset / renderer | Shipping average FPS | Shipping 1% low | Diagnostic average FPS | Diagnostic 1% low | Floor |
|---|---|---:|---:|---:|---:|---|
| Meadows | Medium / Forward+ | 12.266 | 10.379 | 5.858 | 1.040 | FAIL |
| Meadows | Low / Compatibility | 11.129 | 7.291 | 5.139 | 0.599 | FAIL |
| Tidewake | Medium / Forward+ | 9.615 | 6.224 | 6.273 | 1.174 | FAIL |
| Tidewake | Low / Compatibility | 8.385 | 5.258 | 5.146 | 0.673 | FAIL |

Shipping: actual release EXEa3e6b1cbd46ad153e7dfb24a5c0ee2b9187e0fb21fa7c0610fa8754ba5939d9c, release Terrain DLL40900e649c3c6c7619c383d28732c3e2e8dc87c2938de43b29122a668aedcf86, PCKea6ddca0ac0dce521ddd31709592d33d7572c47c4489c5775fdda7d4fe2b4165. Existing packaged --f26-route dispatch through title/autoloads; no debug, GPU profiler, EngineProfiler, external script or trace. Native exit0/no ERROR for all four cases. Fresh profiles and native preset cfg preserved.

Diagnostic: official editor-capable host with the same release PCK, existing external monitor/EngineProfiler overlay, GPU profiling enabled, tracing unset. These have independently verified uncapped/VSync0,60Hz/time1 fields and frame-specific CPU callbacks. Those CPU/GPU figures do not transfer directly to the shipping rows.

Limitations: the older packaged main route has no frame_limit receipt fields or explicit uncapping code. Shipping runtime maxFPS/VSync/physics/time settings remain unverified; only wallFPS and cached TIME_PROCESS/TIME_PHYSICS_PROCESS monitors are available. No true per-frame CPU, GPU cost or draw-call claim for shipping. Sequential build/entry/instrumentation differences preclude isolated profiling-overhead or preset causality. This is desktop route evidence, not Ally, earned campaign or full fight acceptance. All raw rows, logs, stills, command/payload hashes, preset cfg and case reviews remain in the linked case folders.

Performance remains OPEN. Accepted main source contains no review-blocked detail_cull. Existing-source CPU candidates were sent to coordinator#525; no patch was made in the PERF-owned hot files. Exact main-compatible existing CPU ablation command remains requested because main lacks perf_cpu_probe.gd. The previously traced Meadows2.799 FPS case and blocked-source cd85 partial ablation must not count release acceptance.
