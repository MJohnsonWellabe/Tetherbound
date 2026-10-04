# F26 GPU continuation evidence

Source baseline: `826d273c3dbdcb1002034812041b1dfb59d84120`, PR #525 integration.
Branch: `tb/lookdev`. The coordinator integrates this lane; no lane PR.

| Criterion | Current label | Evidence / remaining proof |
|---|---|---|
| F26#0 materials and Low fallback | STALE | Native material census refresh pending for village, Hall and four biomes. |
| F26#1 presets and persistence | STALE | Native Settings and separate Forward+ reload PASS, 21 checks; [native-settings.json](native-settings.json). GPU ranges and independent acceptance pending. |
| F26#2 authored look bar | CURRENT | Independent criterion-only MET on `311e97078`; [look-bar-review.md](look-bar-review.md). No runtime full-bar claim. |
| F26#3 full bar on High/Medium | MISSING | Fresh complete biome matrices and independent code-blind Bars A/B verdicts required. |
| F26#4 twelve scripted routes | STALE | Fresh Low/Medium/High route timing at 1920x1080 required. |
| F26#5 Ally performance | BLOCKED_OWNER | Owner harness and [one-page checklist](ALLY_CHECKLIST.md) implemented/reviewed; package preflight pending. Owner must measure >=30 fps, 40 preferred. |

No new acceptance credit. Compatibility remains the default.

## Executed preflight

- Inspected installed Godot 4.7 Windows editor and export templates.
- Native adapter inventory: NVIDIA GeForce GTX 1060 3GB. Desktop evidence cannot certify Ally performance.
- Refreshed integration/main refs. Recovered the partial clone's 71 missing source blobs and verified every recovered byte sequence against its Git object SHA-1 before restoring it. Source checkout is now the exact integration baseline.
- Pushed `tb/lookdev` at the baseline. GitHub accepted the branch.
- Ran one serialized import and the named native Settings/reload proofs under `D:/tetherbound/RENDER_LOCK.json`, with isolated device preferences. All three exit 0 with zero native errors; Settings/reload pass 21 checks. Raw local artifacts and log hashes: `D:/tetherbound/.artifacts/f26-initial-826d273c3/`, [native-settings.json](native-settings.json). Generated UID/import support files are retained locally; no generated source changes were committed.
- Started the full Tidewake Medium material census on `311e97078`. It produced 24 native 1920x1080 catalogue PNGs, but the owner announced Valheim play before completion. The owned renderer was stopped and the lock released. The manifest was interrupted during its rewrite and is empty; these partial frames cannot certify the census. Logs and unmodified images remain at `D:/tetherbound/.artifacts/f26-census-311e97078/water-medium/`. Repeat into a fresh directory after the game exits; preserve this attempt.
- Implemented the packaged Ally Medium/1080p four-route launcher, isolated device profile, hardware/power declarations, raw evidence hashes and fail-closed result summary. Independent implementation review PASS; [ally-harness-review.md](ally-harness-review.md). Windows PowerShell 5.1: 19 focused receipt checks and four actual package-integrity fixtures passed without launching a game. Export/native route/device performance remain separate gates.
- Actual CPU release export on `5b07c2fbb`: first isolated profile lacked the installed templates; resolved by copying and hashing the matching installed 4.7 templates. Fresh second attempt exited 0 and produced a 109 MB Windows x64 PE and 1.12 GB PCK, but logged DummyRenderer/resource shutdown leaks. Strict preflight did not pass. Preserved errors and log hashes in [ally-export-preflight.json](ally-export-preflight.json).
- The exact exported route-script headless load did not reach its intentional render-refusal within the 300 s operational deadline; its owned process tree was terminated and output retained. This is not a native rendering/performance run. Package hashes passed, but the bundle launcher at that attempt preceded the final CLI correction; that raw bundle is not for owner use. No archive or development download was published. Fresh export/startup/native proof remains open.
- Release launcher correction uses the GUI EXE with explicit engine log and visible owner measurement window; independently re-reviewed PASS. Five actual release integrity fixtures PASS without a console wrapper. No project, renderer default, shipping preset or runtime gameplay behavior changed.

## Coordinator exchange

The owner authorized communication with Claude through GitHub. Initial check-in:
[PR #525 comment](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-5982193817).
Baseline checkpoint:
[PR #525 comment](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-5982302971).

The coordinator may fetch `tb/lookdev` and read this receipt at its advertised SHA.
Checkpoint comments include criterion labels/evidence paths, changed shared files,
review status and required input. Requests and acknowledgments belong in replies
on the same PR discussion. [Claude acknowledged receipt](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-5982376444)
and is incorporating checkpoints in the hourly board. Claude owns subsequent STATE
updates; lane status stays here to avoid shared-file conflicts. F17 route/source and
F21 camera-ready source pins are pending from the coordinator.

## GPU scheduling

The persistent goal remains active. GPU captures and performance runs are deferred
while the owner plays Valheim on this PC; continue CPU, reference and Meshy work.
Resume native captures only after observing Valheim start and exit, or explicit
owner notice that the PC is free. Concurrent gameplay invalidates frame-time
comparisons. No renderer or unrelated user process was left running by the stopped
census. Local occupancy marker: `D:/tetherbound/.artifacts/GPU_OWNER_PLAY.json`.

## Review and shared files

F26#2 independent acceptance review: MET. Other F26 criteria remain open.
Shared file touched by this checkpoint: `docs/STATE.md`, GPU resumption and F26 line only.
Owner need: Ally test after the build and checklist are supplied. No new purchase or renderer-default change authorized by desktop results.
