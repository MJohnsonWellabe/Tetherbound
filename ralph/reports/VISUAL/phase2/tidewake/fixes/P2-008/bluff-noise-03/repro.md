# Gull Rest noise-neutral mask diagnostic — prepared, not run

Scratch only. No production edits, project imports, render-lock mutation, world-scene launch, or GPU capture was performed in this revision. Six CPU/source tests, 46 actual launcher-tail mock checks, PowerShell AST parsing, and one isolated headless file-IO probe (eight checks) pass. The root owns final wrapper parsing and native compilation/runtime validation. This prepares causal evidence; it is not a shipping material or art acceptance.

## Scope

`bluff-noise03-wrapper.gd` extends `.artifacts/phase2/dune_bluff_mask_ablation.gd`, explicitly calling `super()` after checking the existing config ZIP hash. The parent mounts that pack before explicitly calling the capture base initializer. Both cases rebuild from the **original installed shader**:

1. `mask_baseline`: existing exact final bluff mask, unshaded.
2. `noise_neutral`: same unshaded final mask; the sole material-input change is replacing `float bluff_patch = coast_noise(v_vertex.xz * 0.16 + vec2(v_vertex.y * 0.025));` with `float bluff_patch = 0.5;`.

This zeros both existing `(bluff_patch - 0.5)` perturbations. No input-02 height/control/slope snippets are used. No palette, threshold, normal, vertex, height/control asset, geometry, LOD, collision or Sun changes. **Zero additional texture fetches.** The original shader is restored on completion or a handled preparation/capture failure; exiting the process also discards the transient resource override.

The unchanged ZIP SHA-256 is `f28a8ac9e5001c9dd4f435832ebfae777280a94145a759d003c66b6f5b436c12`. It enables dunes only within the diagnostic process. The launcher verifies both production dune gates remain false. Neither the ZIP nor the parent wrapper was edited.

## Repro after owner scheduling

Static preflight performs read-only file/hash/config/path checks, then returns **before** opening the lock or launching Godot:

```powershell
& 'D:/tetherbound/x04-tidewake/.artifacts/phase2/bluff-noise03-launch.ps1' -StaticPreflight
```

After the root's parser/review and explicit GPU slot allocation, the same launcher without that switch runs **one boot, two native frames**:

```powershell
& 'D:/tetherbound/x04-tidewake/.artifacts/phase2/bluff-noise03-launch.ps1' -Round bluff-noise03
```

It uses the existing seed-2042 Water Gull Rest day/close production fixture, fullscreen OpenGL3 1920×1080 and fresh isolated APPDATA. Raw output is `.artifacts/phase2/p2008-bluff-noise03/`; stdout/stderr, APPDATA, and output paths must all be absent. A retry requires a fresh `bluff-noise03-<suffix>`. It never removes old evidence. The static branch was source-reviewed but not executed in this preparation, consistent with the CPU/source and PowerShell-parser-only scope.

The runner atomically claims an **empty** shared lock under an exclusive file handle held through child cleanup, with owner `tb/x04-tidewake` and a unique token in both token fields; any occupied same-lane/other-lane token is rejected. A monotonic deadline bounds its own hidden child. Cleanup stops only the returned child object, tolerates a verified natural-exit race, and waits at most ten seconds before checking terminal state. The original failure survives cleanup errors; a best-effort `.log.failure.json` adds cleanup/terminal diagnostics. Failed terminal verification retains the JSON token even after closing the handle. APPDATA and source-receipt environment variables are restored in finally. No queue permission is inferred from a successful preflight.

## Measurements and failure semantics

Each capture checks the live shader hash/identity, enabled override/gate, actual LOD, Sun transform/shadow settings/energy, exact player/stand/ground/surface-state/clock, current production Camera3D identity and actual fullscreen window/viewport/saved-image dimensions. The manifest includes full final-camera and rig transforms, per-frame JPEG hashes and lens values: FOV, projection mode, keep-aspect, size, frustum offset, horizontal/vertical offsets and near/far planes. Lens values and the fixed 1920×1080 aspect must match exactly between cases.

Final Camera3D origin may differ by at most **1e-6 m Euclidean distance**; its basis may differ by at most **1e-6 maximum component**. Actual unrounded deltas are recorded. Malformed/nonfinite transform values fail closed. Rig drift is separately reported; acceptance follows the actual rendering camera. The inherited 0.01 m camera check is retained but the new final-camera check is stricter. No input-02 manifest or failed result is changed by this prospective tolerance.

Source HEAD, a hash of the UTF-8 PowerShell text representation of the tracked working diff (`git diff --binary HEAD -- scripts data tools tests`), original/live shader hashes, exact pack hash, original parent wrapper, launcher, capture implementation and material/wrapper hashes are retained. The diff-text hash is provenance of that serialization, not a Git object hash; actual live shader hashes are the stronger material receipt.

Before replacing an existing canonical manifest, the writer copies it to a unique `manifest.previous-NNNNNN.json` and verifies the copy's SHA256 against the original. Backup failure aborts without touching the canonical file. It then stages/flush-checks `manifest.pending.json` and promotes it using `DirAccess.rename_absolute`. **This replacement is not claimed atomic:** Windows may remove the old canonical before a failed move. Verified previous checkpoints and raw images are retained on failure; checkpoint paths and authoritative engine-exit semantics are disclosed in manifest metadata and IO-error logs. A leftover pending/checkpoint file is evidence, not completion. The finalizer accepts only successful final IO and exactly two records without failures; exit 1 remains authoritative even if a prior manifest appears complete. The isolated IO probe exercised actual extracted writer code for replacement, backup failure, and pending-open failure, plus a primitive simulation of failed promotion after canonical removal. Its expected negative-case IO errors are logged under `bluff-noise03-io-probe-01/probe.log`; this is not a world capture or GPU proof.

The runner requires exit zero, `complete=true`, no failures, two frame records, matching image hashes and no script/parse/compile/shader errors. Other engine warnings remain in logs. Fog/tonemapping, JPEG compression and live moving creatures/vegetation limit pixel interpretation; judge the fixed terrain boundaries.

If the teeth survive neutral noise, that perturbation is not necessary for them at this fixture. If they collapse, next isolate the height-dependent noise phase from the XZ component. Neither outcome authorizes enabling a material, broadening mineral coverage or declaring P2-008 fixed.

## Checks completed

`bluff-noise03-check.py`: **6 tests PASS**. They cover prior-round tiny drift, tolerance boundaries, Euclidean rather than componentwise origin limits, nonfinite/malformed rejection, exact current anchors, unchanged vertex code and sampling call counts, the single material-input difference, wrapper guard/checkpoint ordering and launch preflight-before-lock ordering. These are Python/source checks, not shader execution. `bluff-noise03-cleanup-check.ps1`: **46 checks PASS**, exercising the actual launcher tail with all process/lease/write boundaries mocked: timeout, natural-exit race, denied stop, failed start, occupied lock, failure-receipt failure, and lease-release failure. PowerShell AST parser: **PASS**. The single isolated headless IO probe: **8 checks PASS, exit 0**, with expected IO errors in its negative cases; no project world/import/GPU was used. The final revision only enriched the IO-error message with the last verified checkpoint path after that probe; the writer algorithm is unchanged. No native comparison images or acceptance claim exist for this prepared round.
