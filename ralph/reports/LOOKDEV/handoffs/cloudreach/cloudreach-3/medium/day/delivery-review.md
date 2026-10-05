# Independent bounded delivery review

PASS for delivery integrity and capture completeness only. Independently verified all three ZIP hashes/sizes (107,995,381 bytes total; each below 45 MiB), all 47 archived entries' hashes/lengths and original byte identity, and the separate Medium graphics configuration hash. The capture tool hash matches both the recorded hash and exact source `56ba1bd87fd15f9868ddd627c9e9c73371bbe7c9`. Command/profile evidence agrees with Medium, Forward+, `--active=terrapup` and requested 1920×1080.

The original text manifest has 37 unique rows matching 37 original PNG filenames, with zero skips; five contact sheets also exist. All 42 PNG headers match the receipt. Every original frame is 1920×1061, so native 1080 qualification remains FAIL. Native exit 0 and the logged 37-written/zero-skipped completion support capture completeness; runtime qualification remains FAIL because the full native log contains `ERROR: unscoped chapter flag: fly_tutorial_completed`.

The log records boot after 3,585 frames. Independently matched first-PNG delay is 566.039 seconds and includes startup, boot, stance, rendering and writing. Recorded native duration is 696.438 seconds; supervisor duration 704.766 seconds includes the chooser. Exact boot wall time is unavailable; no pure-boot or FPS conclusion follows.

No images were viewed or judged, and no engine, import, render or test job was launched. Bounded CPU audit finished.
