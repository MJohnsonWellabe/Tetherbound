# Prepared six-frame colony comparison (not run)

This is a scratch-only recipe for a later render queue slot. No queue slot is claimed. No Godot, shader compilation, native binding test, capture or visual/performance judgment was executed during preparation. Root must review the exact files before running this after the separate Gull-mask slot.

The parent driver is the production `tools/phase2_capture_locations.gd`; the wrapper explicitly calls each applicable `super` method. One production Water boot captures Gull Rest Beach baseline/candidate, Sluice Isle Twin Pumps baseline/candidate, then First Shore Welcome Beacon baseline/candidate, all day/close, seed 2042, 1920x1080. A failed frame or pair verification prevents any later captures. Parent bounded support-stand retries remain available for baseline; candidate is restricted to its baseline's chosen offset/lateral and fixed camera pitch.

Both variants mount the existing dunes-05 ZIP containing exactly two config JSON files, each differing from production only in `enabled: true`. The ZIP is hash-pinned and no new script ZIP is mounted. Terrain, lighting setup, ground-cover config, grass geometry and requested count stay at the 05 configuration for both variants. The sole variant change is the cached production grass Shader resource's code: unchanged production baseline versus the exact shader section of the reviewed coastal proposal. Candidate uses the shader's new `.18` default; the production controller and all on-disk configs/shaders stay untouched. The new config/controller hunks of the proposal are intentionally not applied.

The wrapper refuses a frame unless the actual live GrassField `_material`, its `material_override`, and the cached Shader are the same objects; the actual shader code hash matches; every listed 05 custom uniform matches the mounted config; candidate effective default is .18; mesh/instance counts exist and match the live ring; and the production camera/support checks pass. Geometry resource IDs/counts and custom parameters must remain identical within each pair. Stand position/height must match exactly; player and camera positions must be within 5cm. Each record contains actual player/camera/stand/terrain data from the parent plus material/shader identities, uniforms, active config and geometry identities. Shader code is restored and hash-verified in `_finish`; process termination discards process-only changes if a fatal error prevents finishing.

The fresh capture is a controlled source/config comparison, not pixel-perfect isolation of the moving world: the parent production physics, creatures and wind continue between frames. Native compiler and binding behavior is deliberately unproven until execution. Any shader/script error, absent binding, mismatched pair or incomplete manifest fails the run; retained JPGs from a failed pair are not accepted evidence.

## Exact review files

- `colony06-build.ps1`: CPU-only builder. Applies only the exact shader patch hunks to an in-memory source string with fail-closed line anchors; checks the config ZIP's members and contents; writes inert `.txt` shader snapshots and metadata. Do not regenerate after review without reviewing changed hashes.
- `colony06-baseline.gdshader.txt` and `colony06-candidate.gdshader.txt`: exact normalized-LF code texts. Their SHA-256 values are in `colony06-review.json`; original file-byte hashes are recorded separately.
- `colony06-review.json`: expected .18 uniform, exact proposal/pack hashes, all source-anchor hashes, and both false production gate/hash pairs. Prepared at the recorded source commit, rather than claiming the earlier frozen commit if unrelated commits moved HEAD.
- `colony06-locations.gd`: runtime wrapper, source-only prepared. No parser/native execution performed.
- `colony06-capture.ps1`: later runner. Static preflight mode does not acquire the render lock or create a native process. Native mode uses a unique UUID lock token, refuses a held lock, opens fresh output/log/APPDATA paths, launches exactly one hidden engine process, stops on failure/deadline, verifies false production gates/hashes again, and releases only its own token. Failed outputs are retained, never overwritten or auto-retried.

CPU preparation completed: exact shader patch anchors applied; ZIP exact two-member and only-gate semantic comparison passed; both production gates were false; both PowerShell scripts parsed with zero parser errors; static runner preflight passed. These are source checks only. `colony06-file-hashes.json` records the prepared review files' hashes.

From `D:\tetherbound\x04-tidewake`, static preflight:

```powershell
& .artifacts/phase2/colony06-capture.ps1 -PreflightOnly
```

Only after root review and a free render slot, execute with a new unique round:

```powershell
& .artifacts/phase2/colony06-capture.ps1 -Round colony06-reviewed-unique
```

Do not run another viewport probe or engine boot as part of this recipe. The wrapper checks native dimensions itself. Completion is six frames plus a clean manifest and runner receipt; it still requires independent visual judgment and does not provide performance acceptance.

## Corrected site provenance

The initial CPU proposal had Gull/Sluice labels reversed. Production catalogue and retained 05 manifest identify Sluice Twin Pumps near player `[906.6229,93.2032,2859.8015]`, and Gull Rest Beach near `[-59.9730,1.56655,785.18036]`. Those are prior observed player positions, not terrain heights imposed by this harness. Exact catalogue identities drive the new run; actual supported stands/heights are freshly recorded. The coastal adjustment directly targets low Gull ground; Sluice provides a >=6m control. Welcome Beacon supplies a third real scene. None of the constant-height probability grids represent actual terrain coverage.

The separate root-prepared `terrain-probability-study.json` reports decreased mean eligible probability on the Gull source-height grid despite denser local cores, because the common fade reduces low eligible grass. This recipe makes no overall-more-cover promise. That study is CPU source evidence and is not a native appearance result.
