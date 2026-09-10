# Final game revision Windows release

Runtime source: `dbb229436b473cf5d53eb585331893ab54e3b4fa`, including the
Deepwood Circuit delayed-client acceptance repair. This supersedes the earlier
`8aad9c373` package as the recommended local playtest build.

The exact-commit detached checkout imported 11:51:44–11:54:09 UTC, exported
11:54:10–11:54:39, and ran the actual exported `Tetherbound.exe`
11:54:40–11:56:25. All three phases exited 0 without script/parse/error
signatures. Root separately inspected the explicit exported engine log for
those signatures and confirmed the tracked worktree remained unchanged after
export. Eighteen importer-generated script UID files are recorded in the
receipt; unrelated development-checkout assets were excluded.

The shipped executable reported:

`EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=383004`

The PCK directory check passed 368 required JSON/scatter paths and terrain
presence. The declared Terrain3D release DLL was staged and hash checked.
The ordinary interpolation deprecation and intentional EXPORT-CHECK warnings
remain in the logs. The isolated profile, native process/creation-time guard,
90% system-commit ceiling and phase deadlines remained enabled.

Complete local package directory:
`.artifacts/broad-visual-0910/export-runs/windows-dbb-final/output/`.
Launch `Tetherbound.exe`; keep its adjacent `Tetherbound.pck` and libraries
together when moving the package. The executable alone is not the game.

Executable: 109,052,928 bytes, SHA-256
`a3e6b1cbd46ad153e7dfb24a5c0ee2b9187e0fb21fa7c0610fa8754ba5939d9c`.

PCK: 974,806,624 bytes, SHA-256
`a295b86adaf86ea6afe7247a2ded59a7f66bd63ac098a7c57acfbd00d388f082`.

The enclosing run directory retains `receipt.json`, exact worktree, isolated
profile, phase engine/stdout/stderr logs and resource samples. Reproduction
scripts are in `.artifacts/broad-visual-0910/export-tools/`; the official template
archive and SHA are documented in `WINDOWS-8AAD.md` and the run receipt.

This is native exported boot/content/ground evidence, not a full exported
campaign, multiplayer playthrough, signed installer, release-asset publication,
Ally performance result or commercial visual acceptance. CI and the longer
fresh earned prefix are separate receipts and are not inferred from this check.
