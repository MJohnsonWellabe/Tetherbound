# Published Windows binary runtime proof

## Bounded brief — 2026-09-09

The release workflow runs a Linux export for its runtime check. This separate
proof downloads the published Windows asset `552043230` for main `4830bf402`,
verifies its SHA256 against GitHub's recorded digest, extracts it into a new
isolated artifact directory and runs that actual `Tetherbound.exe` headless with
the existing `--verify-export` path. It does not run the editor or mount source
over the package. No KICKOFF script, campaign replay, save copy or fixture flags
are invoked. The export-check path owns its existing scene setup and assertions.

Expected ZIP digest:
`71ebb070f3ef2ae93094973acbee44e389b982785b73acd9b1d934bc116c9627`.
Use fresh APPDATA/LOCALAPPDATA, an exclusive full-world process lease, 600-second
external bound and existing 90%-commit/400-process ceilings. Preserve native logs,
check the complete distinct error set, DLL loading, packaged terrain and the
actual EXPORT-CHECK result. Stop at the first result; no automatic retry.

This can establish Windows packaged-runtime ground availability. Headless
execution does not prove Windows rendering, Ally performance, controller UX or
campaign acceptance.

## Result

Downloaded ZIP SHA256 matches the expected GitHub digest exactly. Extraction
verified that every archive entry remained within the new package directory.
The executable is 109,052,928 bytes and the PCK is 967,127,624 bytes.

The first invocation aborted before game startup: the export binary was compiled
without path-override support and explicitly rejects `--path`. No engine log or
world result was produced; the error is retained in `stderr.log` under
`.artifacts/windows-release-4830-20260909/`. This is an invocation finding, not
a terrain or gameplay result.

The corrected invocation used the package as its working directory and omitted
`--path`, running the adjacent PCK through the actual published executable with
`--headless --verify-export`. Its fresh profile and retained logs are under
`.artifacts/windows-release-4830-supported-20260909/`. No second download,
export or source overlay was used.

The actual Windows executable reported `EXPORT-CHECK terrain=yes
ground_at_spawn=0.90 player_y=2.90 props=383004`. It ran from 10:33:41.207 to
10:34:37.885 UTC, terminated naturally with no guard stop, and left no owned
game process. No ERROR or SCRIPT ERROR appeared; the only other warning was
the physics-interpolation deprecation. Peak system commit was 54.62%, process
count 246, and owned private memory 1,894,744,064 bytes.

The Windows packaged-ground predicate passed. The wrapper recorded a null exit
code (PowerShell process-handle capture limitation), so this receipt does not
claim a captured exit code of zero. Rendering, Ally performance and continuous
campaign acceptance remain outside this headless proof.
