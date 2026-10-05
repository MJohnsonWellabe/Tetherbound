Shipping GPU diagnostic: Meadows, source12e1975a, Medium Forward+ fullscreen1920x1080, GTX1060 3GB. Original release mode2 package; official --gpu-profile only added to existing packaged route command. Native exit0/complete/allwaypoints/no ERROR. This is diagnostic evidence, not throughput A/B or performance acceptance.

80 original GPU reports preserved with original log line numbers. Whole-lifecycle latest-frame total range 14.854â€“55.850ms. Reports include startup and route; no synchronized timed-interval markers exist.

| Pass | Printed intervals | Median reported interval average (ms) | Reported range (ms) |
|---|---:|---:|---:|
| Render Opaque Pass | 80 | 9.946 | 5.068â€“28.987 |
| Render Depth Pre-Pass | 80 | 4.226 | 0.341â€“12.426 |
| Render 3D Transparent Pass | 79 | 1.565 | 0.011â€“6.891 |
| Setup Sky | 80 | 0.895 | 0.358â€“1.618 |
| Glow | 80 | 0.662 | 0.269â€“1.276 |
| Tonemap | 80 | 0.495 | 0.206â€“0.910 |
| Render OmniLight Shadows | 30 | 0.464 | 0.063â€“0.672 |
| Process SSAO | 80 | 0.379 | 0.150â€“0.657 |

Opaque and depth rendering dominate later reports. The final report has latest-frame total21.035ms, opaque interval average10.421ms and depth interval average5.151ms; these are different aggregation windows. Rendering cost is substantial, but this does not identify a responsible object or establish CPU/GPU exclusivity.

[Godot 4.7 implementation](https://github.com/godotengine/godot/blob/4.7/servers/rendering/rendering_server_default.cpp#L155-L194) prints pass averages accumulated over approximately one second, with latest profiled frame total in the header. Do not subtract those incompatible quantities. Printed pass statistics here are unweighted interval summaries, not route per-frame metrics.

Original two native PNGs, full route samples/logs/preset text/fresh profile records/receipt preserved byte-for-byte in native-diagnostic.zip; cache omissions explicit in inventory.json. Package identities and native command remain in original receipt. No new equipment/tests or game changes. Independent byte/math/profile-semantics audit PASS; see delivery-review.md.

- Godot prints each pass as the frame-count average accumulated over approximately one second. Header total is latest profiled frame, not that interval average; pass averages cannot be subtracted from header to infer unattributed cost.
- Reports cover startup, construction, warmup, captures and route. Original log lacks synchronized timed-interval markers; no exact per-route report classification claimed.
- Whole-lifecycle statistics are unweighted summaries of printed intervals, not per-frame means or percentiles. Reports omit pass averages <=0.01ms; missing passes are not represented as zero.
- GPU pass timestamps identify rendering phases, not terrain/vegetation/village/individual material contributions. No object-level root cause or true CPU time inferred.
- Profiler overhead/workload can change timing. Diagnostic FPS cannot replace unprofiled throughput A/B; no causal regression onset or complete performance acceptance.
- Original captures are outside timed interval. Runtime VSync/FPS caps/time settings not explicitly witnessed. Normal live clock/ecology variance remains.
- No code/material/geometry/culling/density/preset/default/physics changes in this diagnostic. No new profiler adapter, fixture, tool or test authored.
