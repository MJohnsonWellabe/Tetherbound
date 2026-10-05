PERF retime 1: Meadows and Tidewake comparison

Source `6632f2fd5af9b1de173ee919560a46ac9dd65cdb` versus prior AFTER `1b85fb4d985b7d622e022867055770b2f0de6b18`. Same GTX 1060 3GB, Medium Forward+, 1920x1080, uncapped, VSync off, physics 60 Hz, time scale 1, unchanged existing monitor overlay and official Godot 4.7 editor-capable host loading the release PCK.

| Realm | Source | Average FPS / 1% low | True process mean / max ms | Physics max-step mean / max ms | GPU mean ms | Draw calls mean |
|---|---|---:|---:|---:|---:|---:|
| meadows | 1b85fb4d | 5.810 / 1.188 | 138.453 / 833.914 | 5.432 / 20.958 | 28.014 | 2169.60 |
| meadows | 6632f2fd | 7.356 / 1.125 | 109.794 / 854.467 | 5.343 / 26.476 | 27.132 | 1917.25 |
| water | 1b85fb4d | 4.059 / 1.065 | 142.181 / 880.487 | 14.382 / 37.434 | 32.834 | 773.37 |
| water | 6632f2fd | 4.937 / 1.127 | 122.439 / 805.617 | 11.405 / 30.683 | 22.077 | 769.29 |

The route config has identical tracked content and parsed route definitions. Its raw-byte hash differs because the new checkout uses LF and the previous AFTER checkout used CRLF; converting line endings reproduces the old hash exactly. Both hashes are retained in report.json.

Both new core routes completed with exit 0 and no ERROR lines. Both remain below the owner's 20 FPS floor. Meadows averaged 26.6% faster; Tidewake averaged 21.6% faster. Meadows' 1% low declined slightly. This comparison does not isolate the contribution of either source change.

Meadows has 236 wall frames and 236 profiler iterations; Tidewake has 120 wall frames and 119 correlated profiler iterations. Cached Godot process/physics monitors are distinct from the true CPU values above. Physics describes the maximum individual step within each rendered iteration, not the mean of all executed steps. The 1% low uses the ceiling of 1% of wall frames, then 1000 divided by their mean duration.

Meadows' largest GPU pass is Render Opaque Pass, 13.229 ms; depth prepass is 6.969 ms and transparent pass is 2.183 ms. Sixteen timed cost blocks exclude the first warmup-overlap block. These are mixed geometry passes; their names do not identify individual terrain, vegetation, water or distant meshes.

Import passed. Export exited 0 but emitted seven shutdown ERROR lines, retained in full: shipping export qualification FAIL. The produced PCK passed the existing scatter freshness check for all 108 regions, with no missing regions or ERROR lines. Original export mode 2 and temporary plaintext mode 0 are recorded; source settings were restored. These measurements qualify only the diagnostic editor host and PCK, with shipping EXE and ROG Ally FPS still open.

Cloudreach and Stormwood are pending. Real-fight physics remains open. Full native logs, route/performance manifests, PNGs, preferences and receipts are archived unchanged; report.json records raw-file and archive hashes. No game, default or STATE edits. Independent evidence integrity and arithmetic review PASS; see core-review.md. Performance, shipping and remaining-route gates retain the failures and open items above.
