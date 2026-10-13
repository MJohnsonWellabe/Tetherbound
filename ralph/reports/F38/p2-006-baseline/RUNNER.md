# P2-006 exact baseline runner

This is a baseline-only capture. It creates no candidate and changes no source. It is prepared, not admitted or executed. The supervisor requires the exact clean `06bedfa5082e6ea5dd425c9fc04ffd1d5ace84eb` source commit, checks the pinned engine and canonical Git blobs, uses the root native writer lease, and requires a positive root admission for the requested preset.

For the P2-005/P2-006 runtime-contract audit and CPU-only fixture results, see `RUNTIME-AUDIT.md`.

Copy `run_p2_006_capture.ps1`, `capture-packet.json`, and `admission.template.json` to `D:\tetherbound\.artifacts\codex-service-meadows\p2-006-baseline\`. Set `capture-packet.json.supervisor_sha256` to the copied supervisor's SHA-256. Copy the template to `admission.json`; root sets `admitted=true` and the intended preset only after the native writer slot is released. Admission defaults false.

Run one preset per invocation, High first and Medium second:

```powershell
./run_p2_006_capture.ps1 -Preset High
./run_p2_006_capture.ps1 -Preset Medium
```

The supervisor uses `tools/phase2_capture_locations.gd` with the exact four identity subsets, `--biome=meadows`, `--character=trainer`, `--seed=2042`, `--times=day`, `--views=close`, `--preset=<High|Medium>`, `--source-commit=06bedfa...`, Forward+ at 1920×1080, and a fresh output and isolated capture home. It validates the complete manifest, exact IDs, production stand/camera receipts, four actual JPEG headers at 1920×1080, source state, and renderer/preset. The Medium run also requires the retained High manifest and rejects any difference in the selected stand, player position, camera/rigger transforms, heading, or spring length for a matched ID.

Admission requires 12 GiB free on C:, 20 GiB on D:, and 2 GiB of free physical memory and commit. It starts the rendered process with a hidden process window, not headless. The supervisor stops only the exact owned Godot process at 11 GiB free on C:, 20 GiB free on D:, 2 GiB memory/commit, a 1200-second run limit, foreign Godot/Blender activity, or a combined 512 MiB output/home/log cap. It rejects output-tree reparse points and records a full receipt, stdout/stderr, manifest copy, and every frame's SHA-256. A stopped run is missing evidence.

Keep all eight original images, both manifests, and both terminal receipts. Compare only High/Medium captures of the same exact IDs; this baseline packet makes no before/after or candidate claim. The requested observations and acceptance limits are in `CAPTURE-PACKET.md`.
