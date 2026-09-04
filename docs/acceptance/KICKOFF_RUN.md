# The kickoff run — all of the evidence, none of the human

**Status:** process document, 2026-09-04, per D73. This is what
`tools/owner/KICKOFF.cmd` does, what it leaves behind, and what the agents do
with it. The owner's whole part is starting it.

## Why this exists

Every gate's acceptance had a human step folded into it: an owner playtest on
the Ally, an owner confirmation of a fix, an owner screenshot on a GPU. Those
steps happened days late, on stale release builds, covered the first hour of
the game, and re-opened three same-day "landed" fixes in one weekend. The
Gate F chain, the only end-to-end instrument, cannot render in a container
(6.5–12.7 s per frame, ~8,000 hours for the protocol) and has never got past
S05. The visual judge has only ever seen software-rendered stills.

One machine with a GPU removes all of that, if nothing on it needs a person
after the double-click.

## What the owner does

1. Get `tools/owner/KICKOFF.cmd` onto a Windows machine with a GPU. The ROG
   Ally is the right machine (D73 §1). A checkout of the repo is best; the
   two files alone also work, they clone or download the branch themselves.
2. Double-click it. Walk away. The default run is overnight; `-Quick` is
   about half an hour and skips the chapter playthrough.
3. Nothing else. The window says when it is done and names the branch it
   pushed (`owner-run/<stamp>`) and the zip on the Desktop.

The machine is busy for the duration: a game window opens and closes
repeatedly, and the chapter plays itself with video recording. Do not use it
for anything else during the run; a stray keypress goes into the game.

## What it does, phase by phase

| Phase | What happens | Leaves behind |
|---|---|---|
| `prepare` | Fetches the branch (`main` unless `kickoff.branch` or `-Branch` says otherwise). Installs the pinned Godot 4.7-stable console binary and ffmpeg under `%LOCALAPPDATA%\Tetherbound`. Imports the project twice. Records the machine (GPU, driver, CPU, RAM, OS) and the shipped config flags (grass on/off). | `RUN_METADATA.json` |
| `frames` | Renders on the GPU at 1280×800: the five survey stands, the eight Band 1 composition stands, the five places, the location set, and the **route strip** (`tools/_capture_route_strip.gd`): one frame every 40 m along the whole trail spine at eye height by day, every 80 m by night. Sheets everything. | `frames/_sheet_*.png`, the route manifests |
| `perf` | `tools/perf_render_stats.gd` (draw calls, primitives) and `tools/_owner_fps_probe.gd`: twenty seconds of real frame times at nine sites, eye-level and elevated, with the shipped grass setting. | `perf_render_stats.txt`, `fps.json` |
| `export` | Downloads the shipped `Tetherbound-windows.zip`, records its Last-Modified, runs the exported binary with `--verify-export`, applies the same checks as `tools/verify_export.sh`. | `EXPORT_VERDICT.md` |
| `chain` | Runs the capture smoke, then Gate F **S01 → S10e** through `tools/gate_f/operator_harness.gd` with Godot's movie writer (`--write-movie`, 30 fps, audio included), then the capture lanes `S01C → S10cC` for the prescribed frames. Each segment's video is transcoded, cut into one tile per minute of play, and sheeted; per-frame strips at one frame per ten seconds stay on the machine. | `ralph/reports/gate-f-run-<stamp>-owner/` with every segment's telemetry, saves, prescribed shots and `_sheet_video_*.png`; the `.mp4` files under `%LOCALAPPDATA%\Tetherbound\runs\<stamp>\video` |
| `package` | Writes `RUN_SUMMARY.md`, zips the evidence to the Desktop, commits the two evidence directories (forced past the payload ignores) on `owner-run/<stamp>` and pushes with retries. | the branch, the zip |

A phase that fails is recorded in `PHASES.json` and the next one runs. A
segment that already has an `INVENTORY.json` is skipped, so `-Resume <stamp>`
continues an interrupted run. No phase asks anything.

Movie-writer mode makes every rendered frame a physics step, exactly as the
headless logic lane does, so the harness's waits and fights resolve
identically; it is the same run with pictures. It also means the chain's frame
time is not a performance number; `fps.json` is.

## What the agents do with it

The run lands as a branch. A Routine (or the next orchestrator session) picks
it up and does the following, none of which needs the owner:

1. **Bar questions.** Hand the route-strip sheets (day, then night) and
   `docs/reference/` to a code-blind judge under `.claude/skills/visual-judge/`.
   It answers Bar A and Bar B per band. That answer, not the fixed stands, is
   the gate's visual verdict (D73 §2).
2. **Motion.** Cut eight-frame walk and sprint strips from the S02/S03 video
   (rear and side) and judge them against the rebuild plan's locomotion "done
   when" list. First motion evidence the project has had.
3. **Reliability.** `tools/gate_f/chain_defects.py` over the run directory.
   Every DEFECT row is a ledger row in `docs/CURRENT_STATE.md` §3 with the
   video minute it happened at.
4. **Pacing and content.** `tools/gate_f/chain_pacing.py` for dead-travel
   peaks per band; `chain_party.py` for the team timeline. Fill the roadmap's
   evidence template per segment from these plus the video sheets.
5. **Hardware.** `fps.json` closes or reopens "frame rate with grass on".
   Telemetry's clock column closes or reopens "day never advances". The S03
   sleep steps close or reopen "player sleep". The interact rows close or
   reopen "interact half the time".
6. **Shipped build.** `EXPORT_VERDICT.md` is the release's pass/fail, and the
   Last-Modified line says whether the owner has been playing a stale build.
7. **Script read.** A separate agent reads every conversation in
   `data/dialogue/` in chapter order beside the S05–S10 video sheets and says
   what the player was told in each band. Bands 2 to 5 currently carry a few
   dozen words between them; this is where that stops being invisible.

Findings go to `docs/CURRENT_STATE.md`; decisions to `docs/decisions/`;
nothing waits on a person.

## What this still cannot measure, said plainly

- **Taste.** Whether the chapter is fun is now an agent's judgement on
  player-view evidence (video, transcript, telemetry) rather than a human's.
  That is the trade the owner chose. The judge is code-blind and is asked the
  vision's §10 statements one by one; it is not asked "is it fun".
- **Feel under the thumb.** Stick response, rumble, and the Ally's thermal
  throttling over an hour are not in any file. `fps.json` runs twenty seconds
  per site, not sixty minutes.
- **A player who does not know the route.** The harness walks to authored
  coordinates. A navigator that works only from the objective marker, the
  map trails and the signposts is the next instrument to build; until it
  exists, "the player always knows where to go" is asserted from the objective
  text, not proven.
- **First-run truth.** This document was written without a Windows machine.
  The first kickoff will find what it got wrong; `kickoff.log` and
  `PHASES.json` are written so that run is still evidence.
