# Remaining route batch: retained partial pass and native crash

Executed exact source `84194095503eede4e9d77b3499999da3b04de8ca`.
Meadows Low passed with native exit 0, 136 timed frames, two reached waypoints
and native 1920×1080 start/end PNGs. This uses the current pre-F17 village
route; the rebuilt farm-to-Hall route must replace it before integration.

The next process requested Medium/High Meadows with actual Vulkan Forward+
on GTX 1060 3 GB. It crashed before any route receipt with native exit
3221225725. No SCRIPT ERROR markers appear. Windows Application Error event
at 2026-09-30 05:33:49 UTC records exception 0xc00000fd in
Godot_v4.7-stable_win64.exe at offset 0x6650296; this is native failure
evidence, not a diagnosed root cause or a passing shader/material check.
The process had attached the production world and completed prop creation.

The wrapper stopped at this first failure. High Meadows, Cloudreach and
Stormwood were not certified. Combined with the separately retained three
Water cases, four of twelve requested biome/preset paths have passing native
receipts, subject to independent review of this new Low receipt. F26#4 and
the wider material/visual/Ally gates remain open. No test was skipped,
disabled or quarantined; no lower-resolution or renderer substitute is
counted as a Medium pass. Raw wrapper JSON and both native logs are retained.
