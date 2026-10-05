PASS for original-byte preservation, route completion and wall-FPS arithmetic. This independent audit compared all four `native-route.zip` archives and their inventories with the original cases under `D:/tetherbound/.artifacts/f26-perf-comparison-e2-292`. Their SHA-256 values and sizes match the inventories: 108,585,636 bytes total, 13 unique entries per archive, 52 entries matching the original raw bytes. All eight original PNGs fully decode at 1920×1080; no image or art judgment was performed. The explicitly excluded cache files account for every remaining raw file; original included profile/config text is preserved byte for byte.

Recomputed from every positive finite `wall_ms`: average = 1000 × count / summed intervals; 1% low = reciprocal mean of the slowest ceil(count × .01) intervals; minimum = reciprocal maximum interval.

| Case | Frames / slow frames | Average FPS | 1% low FPS | Minimum FPS |
|---|---:|---:|---:|---:|
| main e2 Tidewake | 120 / 2 | 9.826906 | 6.116077 | 6.076959 |
| CPU292 Tidewake | 233 / 3 | 28.503931 | 7.290242 | 6.645755 |
| main e2 Meadows | 225 / 3 | 11.752469 | 9.833422 | 9.536525 |
| CPU292 Meadows | 357 / 4 | 18.620716 | 13.904628 | 12.455472 |

All values match the individual summaries and `comparison.json`. Every case has native exit 0, complete route, empty failure/error lists, all declared waypoints reached, native Medium config, Forward+, fullscreen command and GTX 1060 3GB adapter. Source receipts distinguish main `e2fa5e4e6bb0060e5f98f9129f2f2e949f8a37f3` from candidate `29237b38efd3c011b88a5588e92e319b05b90c98`. Paired route objects, fixture flags, revision, config SHA-256 `099262d6119cbe092ff3540e493454e5bfba41fcbc676a1fbc16caf6c7e4e355`, FOV 70, near plane and camera floor match: Tidewake 6500 m; Meadows 2000 m. Both pairs record identical release EXE/DLL hashes and source-specific PCK identities; this audit reused the reviewed package/prelaunch identity evidence rather than rehashing the large payloads. Logs preserve two Tidewake and eleven Meadows warnings per case, including deprecated interpolation, UID fallbacks and Meadows torch-surface warnings.

Qualification: all four cases FAIL the current Medium 60-average/40-low FPS target. Tidewake's baseline reaches the configured 120-frame minimum and includes stationary padding, versus 233 candidate frames; Meadows uses 225 versus 357 frames with summed wall intervals 19.144913 versus 19.172195 seconds. These are sequential single pairs with differing live clock states, not isolated causal or regression-onset proof. Cached process/physics monitors do not measure true per-frame CPU/GPU cost; runtime cap, VSync and time settings remain unverified. No full F26, earned travel, fight, co-op or Ally acceptance follows.

Report wording correction identified: README's opening “Measured CPU improvement” should say “Observed route FPS improvement with CPU subset.” The preserved measurements establish route FPS, not measured CPU-duration improvement or CPU-bound behavior. The integrity/arithmetic verdict does not endorse that CPU attribution.
