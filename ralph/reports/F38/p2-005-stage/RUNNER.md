# P2-005 supervised capture launcher

Status: prepared only. No Godot process or native checkout was touched. The script will launch one supervised capture per invocation after root admission; each run emits the complete 16-frame `village_road` matrix.

## Files

- `run_p2_005_capture.ps1` — single-process supervisor and manifest/image validator.
- `capture-packet.json` — exact source, engine, asset, frame-ID, and resource-limit pins.
- `admission.template.json` — deliberately false until root admits a specific arm/preset.
- `CAPTURE-PACKET.md` — candidate bounds, scope, and blind-review subset.
- `rebind_p2_005_packet.ps1` and `REBIND.md` — optional post-checkout raw-SHA rebind, gated by exact commit and canonical Git blob pins.

Copy these files to `D:\tetherbound\.artifacts\codex-service-meadows\p2-005-capture\`. Set `capture-packet.json.supervisor_sha256` to the copied script's SHA-256. Copy `admission.template.json` to `admission.json`; root updates its arm/preset and sets `admitted=true` only for the run being launched.

Native-stage handoff: the stage is currently pinned to `47716c3` for D5 validation. This launcher requires exact HEAD `5bb435c2ded96ecbec6a4a762e231ef7d7fabac0` and will fail preflight until root switches the stage after D5 validation. Do not bypass the commit check or fetch from this runner.

If working-tree raw SHA values differ after that switch because of line-ending conversion, root may use `rebind_p2_005_packet.ps1` as described in `REBIND.md`. The helper requires a clean exact-commit checkout, verifies every packet-bound canonical blob, preserves the original packet snapshot, and writes a separate rebound packet for review.

## Invocations

From the artifact directory, after the native writer lease is idle and admitted:

```powershell
./run_p2_005_capture.ps1 -Arm Off -Preset High
```

That is the requested first run. It is pinned to source `5bb435c2ded96ecbec6a4a762e231ef7d7fabac0`, requires the P2-005 flag OFF, and saves to a fresh `p2-005-off-high` output and isolated home. Run later conditions with a newly admitted entry for each invocation:

```powershell
./run_p2_005_capture.ps1 -Arm Off -Preset Medium
./run_p2_005_capture.ps1 -Arm On -Preset High
./run_p2_005_capture.ps1 -Arm On -Preset Medium
```

For ON, root changes only `data/config/props.json:p2_005_groundcover_candidate_enabled` to `true`. The wrapper accepts exactly that one tracked change and checks its pinned ON hash; it never edits source. Keep the two P2-003 flags false for all four runs. Use fresh output and home paths; never rerun over an existing directory. Preserve all four raw 16-frame captures and supervisor receipts. The four-frame blind subset remains the one listed in `CAPTURE-PACKET.md`.

The launcher refuses to start without explicit root admission, an idle root lease, exact source and asset pins, clean source scope for the selected arm, 14 GiB free on C: and 20 GiB on D:, 2 GiB free physical memory and commit, no other Godot/Blender process, and fresh output/home/log paths. It starts Godot with a hidden process window while keeping the normal rendered display mode (no `--headless`). During the run it stops only the exact owned Godot PID if the 1200-second wall limit, 11 GiB C: floor, 20 GiB D: floor, 2 GiB memory/commit floor, foreign engine guard, or 512 MiB run-tree cap is crossed. Output-tree reparse points are rejected, and all 16 JPEG headers must report exactly 1920×1080. An interrupted run stays missing evidence.

No native work was launched by this preparation. The P2-006 baseline packet remains queued under `../p2-006-baseline/CAPTURE-PACKET.md`.
