# Stopped-session checkpoint — 2026-09-09

Owner requested that the prior run stop, then authorized this wrap-up. Development
is stopped; this is preservation and status reconciliation, not implementation or
acceptance. Resume only on a new owner request. Do not infer permission to resume
the four-biome goal from older orchestration prompts.

## Recovery anchors

- Prior session: `01a08464-0096-7880-b86e-cb5202863943`. Its recorded final turn is
  interrupted, with no final handoff. App history retrieved here lags the files;
  repository evidence below is newer and takes precedence for saved work.
- Original branch: `codex/aim-windup-proof-0909`, preserved at
  `fbacb53509065cc83aa73e92b0dd38ca3be83685`.
- Local preservation branch: `scratch/session-wrapup-20260909`. Its checkpoint
  commit contains this handoff and the held source/report files listed below.
  Use `git log -1 scratch/session-wrapup-20260909` for its exact commit. This
  mixed experimental branch is not a shipping candidate and was not pushed.
- Remote `main`, checked with `git ls-remote` during wrap-up:
  `a46fc868d6d93d491a8a17c8931576148ed0dfb7` (PR101).
- Before any checkpoint edits, all **306** dirty/untracked files were copied to
  `.artifacts/session-wrapup-20260909/files/` and each copy was verified against
  its original SHA-256. `files-sha256.csv`, `source-head.txt` and
  `source-status.txt` in that directory are the recovery inventory.
  This is a local backup of the pending files, not the whole repository or all
  ignored evidence. Existing `.artifacts/` and `shots/` evidence stays in place.

## Shipping state checked during wrap-up

| Item | Verified state | Remaining requirement |
| --- | --- | --- |
| PR103, Satchel equipment and worn saves | Open draft, head `a76c50bd64a352a35b3a030e03ba457490a401b7`; CI34384910163 completed with success | Full job/raw-log and first-attempt audit remains unfinished; no acceptance or merge from the green badge alone |
| PR104, First Shore timber barrier | Open draft, head `33340cbe0bc43c6e33c303e4e941ade189a6de65`; CI34385582148 completed with success | Audit the combined head; land only after PR103 when development resumes |
| Main PR101 | Remote main is `a46fc868d...`; existing records verify publication | Local main CI34384656606 audit is still pending; wrap-up did not establish a new final run verdict |

PR links: <https://github.com/MJohnsonWellabe/Tetherbound/pull/103> and
<https://github.com/MJohnsonWellabe/Tetherbound/pull/104>.
No PR was merged, closed, updated, or newly created by this wrap-up. No remote
job was started or rerun. Completed PR CI requires no cancellation.

## Saved work and limits

- Latest prior commit `fbacb5350` preserves equipment reconnect instrumentation
  in `tests/smoke_net_reconnect_keeps_character.gd`, `tools/net/peer_runner.gd`,
  and `ralph/reports/FOUR-BIOME-BUILD/NET-RECONNECT-EQUIPMENT-0909.md`.
  That report records 71 checks and real socket/disk restoration, but the test
  rejoins directly from the title transition without the production world-first
  JoinDriver flow. Missing trainer replication means **playable reconnect is
  unproven**. Existing disconnect cleanup diagnostics remain open. Do not
  reinterpret persistence success as clean multiplayer acceptance.
- Held waterfall material/config/runtime/shader and capture probe are preserved:
  `data/config/water_veilfall.json`, `scripts/world/water_veilfall.gd`,
  `shaders/waterfall_curtain.gdshader`, `tools/veilfall_visual_probe.gd`, and
  `VEILFALL-VISUAL-ATTRIBUTION.md` under the report directory. The corrected
  final blind verdict is A No / B Yes / shipping No. The corrected camera
  evidence replaces the contaminated comparison, not the rejected verdict.
  No further waterfall tuning or visual gate closure is implied.
- Shared creature material investigation, mipmap probes, policy test, neighbour
  material probe and craftsperson atlas probe are preserved as unfinished
  experiments. `CREATURE-SHARED-MATERIAL-ROOTCAUSE-0909.md` records the test's
  initial failure and corrected 3 tests / 209 assertions. A successful policy
  test is not a completed visual cohort experiment or production import change.
- Pending main/PR103/PR104 audit reports, equipment source review and Relay
  cable report edits are preserved, with their evidence limits intact.
- **287 pre-existing `.import` sidecars remain untouched and uncommitted.**
  Their exact bytes are in the verified backup. Do not blanket-restore or stage
  them. Some report no semantic diff despite dirty status; that is not grounds
  to replace the protected set without inspecting its provenance.
- The user attachment, root capture `manifest.json`, and temporary Terrain3D DLL
  `addons/terrain_3d/bin/~libterrain.windows.debug.x86_64.dll` remain outside
  the commit and are included in the local recovery backup. No raw capture,
  telemetry, attachment or binary payload was committed.

## Shutdown and validation

At wrap-up inspection no Godot, Git, or Python process was running. Two Node
processes belonged to the Codex computer-use runtime; they were not identified
as game work and were left alone. No new agents, tests, render runs, imports,
or implementation tasks were started. This handoff does not certify that all
app-internal agents or any independent remote activity were cancelled.

Validation for this preservation task is the 306-file hash-verified backup,
review of the exact staged path list, whitespace checks on changed tracked text,
and verification that protected pending files retain their original hashes.
The snapshot deliberately contains held, unverified work. No new game/runtime
validation or chapter, commercial-art, multiplayer, or Beta pass is claimed.

## Next session, only when requested

1. Read this handoff, `CLAUDE.md`, `docs/00_START_HERE.md`, current owner
   directives, and the existing evidence reports before choosing work.
2. Recheck live PR/main status. Complete exact-head CI/raw-log audits before
   considering PR103 and then PR104. Do not merge the preservation branch.
3. Treat equipment persistence and playable reconnect as separate findings;
   any reconnect continuation must exercise the production world-first flow.
4. Keep rejected/held visuals and proposed mipmap work isolated. Preserve the
   protected import bytes and retained failed attempts.
5. Select a bounded next task with the owner; the former ongoing goal is not
   resumed by this checkpoint.
