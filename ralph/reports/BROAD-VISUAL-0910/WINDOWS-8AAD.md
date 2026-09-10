# Windows release at 8aad9c373

Exact source commit: `8aad9c3737a3c94097fd30b4a35cdfbfbcc1a149`.
A detached clean checkout supplied the export. The import generated 18 missing
GDScript UID metadata files; each path and SHA-256 is recorded in the receipt.
Tracked files and the index remained clean. Unrelated untracked assets in the
development checkout were not export inputs.

The native import passed 11:26:51–11:29:36 UTC. Release export passed
11:29:37–11:30:04 UTC, producing a 109,052,928-byte executable and
974,803,328-byte PCK. The original orchestration then stopped on its incorrect
assumption that a release console wrapper was required. The preset uses
`debug/export_console_wrapper=1` (Debug Only), so that absence was expected.
The failed orchestration output remains preserved; import/export were not rerun.

The corrected resume path launched the actual exported `Tetherbound.exe` with
`--verify-export`, OpenGL Compatibility, 1280×800, an isolated user profile and
an explicit engine log. It ran 11:44:10–11:46:05 UTC, exited 0, and emitted no
script/parse/error signatures. Its final receipt was:

`EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=383004`

The complete PCK directory was parsed, including 368 required JSON/scatter
paths and a nonempty terrain-data prefix. The declared Windows release
Terrain3D DLL was staged and its copied hash checked. The ordinary interpolation
deprecation warning and the intentional EXPORT-CHECK warning remain in logs.
The 90% system-commit guard remained enabled throughout.

Artifacts are retained under
`.artifacts/broad-visual-0910/export-runs/windows-8aad-first/`:
`output/Tetherbound.exe`, its adjacent PCK and library, `receipt.json`, and each
phase's logs/results/resource samples. The output directory is the complete
package; the executable alone is insufficient.

Executable SHA-256:
`a3e6b1cbd46ad153e7dfb24a5c0ee2b9187e0fb21fa7c0610fa8754ba5939d9c`

PCK SHA-256:
`a18a11ea4f7fc6ae57f6461f4a1c8f31c044d8b631e31f7e237ba5be8b49cac1`

This proves the exported boot, packed content, extension and spawn terrain.
It does not prove a full playthrough, multiplayer, installer/signing, performance
on the Ally, or the commercial visual target. The subsequently identified
Deepwood Circuit pending-client acceptance defect is still present in this
revision; a later repaired package must be tracked separately. CI for this
revision was superseded by the next push before all jobs completed, so it does
not have a full green CI result. Earlier full BA11 CI and later-head CI remain
distinct evidence.
