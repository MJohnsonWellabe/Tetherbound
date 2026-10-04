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
| F26#5 Ally performance | BLOCKED_OWNER | Reviewed harness/checklist; CPU release export, actual EXE dispatch and archive integrity PASS. Native packaged routes remain MISSING; owner must measure >=30 fps, 40 preferred. |

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
- The initial exported `--script` attempt did not reach the intentional render-refusal within 300 s. Further CPU diagnosis found the pinned official release template disables path overrides: it clears `--script` and entered the ordinary title, rather than running the probe. A minimal `--main-pack` probe explicitly refused the override. Preserve these diagnostic attempts; they do not prove an engine hang. Raw bundle is not for owner use, and no download was published.
- Release launcher correction uses the GUI EXE with explicit engine log and visible owner measurement window; independently re-reviewed PASS. Five actual release integrity fixtures PASS without a console wrapper. No project, renderer default, shipping preset or runtime gameplay behavior changed.
- Added an exact `--f26-route` user-argument entry inside the normal title, reusing the existing production route and autoloads. The title is immediately disabled and detached before attaching the route. Independent scoped source review PASS; [ally-harness-review.md](ally-harness-review.md). Normal title startup and source route dispatch/refusal passed with zero errors; the focused front-door file passed 5 tests / 29 assertions. [CPU receipt](export-entry-source-preflight.json), raw logs at `D:/tetherbound/.artifacts/f26-entry-source-20261004T181606Z/`. Actual release dispatch and native/owner results remain open.
- Merged the coordinator's main through `a0f9e50b3` into both lanes, preserving history. Current lane has no `docs/STATE.md` difference from main; the coordinator owns that board.
- Fresh clean-source Windows release export on `925821adc22527d3251c53df757a56d251b007a2`: exit 0 / zero errors in 417.28 s. Actual release EXE reached the explicit route's headless refusal exit 2 / zero errors in 4.94 s. Windows PowerShell 5.1 verified the real package hashes. [Success receipt](ally-export-success.json). The earlier export's teardown leaks did not recur; retain that failed attempt separately, without claiming a demonstrated leak fix.
- Actual release ordinary startup without the route flag: exit 0 / zero errors in 5.25 s. The 774,981,035-byte candidate ZIP passed CRC and all seven embedded manifest file SHA-256 checks; [follow-up receipt](ally-export-followup.json). Archive SHA-256 `30a4fbd1eb052c99f5f3aca474fb2b68047830c97f56c17c78f20959baeb07a8`. Local candidate: `D:/tetherbound/.artifacts/f26-ally-925821adc-20261004T181841Z/Tetherbound-F26-Ally-925821adc.zip`. This is a CPU-verified candidate, awaiting native packaged routes before owner delivery; no release/download publication or Ally performance claim. Imported metadata changed only line endings: archived 185 exact generated files before restoring, zero substantive deltas.

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
Shared runtime file touched by the export-entry correction: `scripts/ui/title_screen.gd`, exact test-flag early dispatch only. The older lane STATE edit was superseded by the coordinator's complete main version during merge; no current STATE difference remains.
Owner need: Ally test after the build and checklist are supplied. No new purchase or renderer-default change authorized by desktop results.
