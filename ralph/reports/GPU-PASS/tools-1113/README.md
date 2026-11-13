# GPU lane capture tools (snapshot 13 Nov 2026)

These are the Windows-side tools the GPU capture lane used on the owner's PC (GTX 1060, D:). Until now they lived only in `D:\tb-gpu-runs\tools`. This folder is a copy for review; nothing here is wired into the game or CI. Paths are hard-coded to that machine:

| Path | What it is |
|---|---|
| `D:\tb-gpu-wt-crA` | capture worktree |
| `D:\tb-gpu-pass` | object store / tb/gpu-pass checkout |
| `D:\tb-gpu-frames-1108` | frames branch worktree |
| `D:\tb-gpu-runs\arms` | run output |

## The tools

| File | What it does |
|---|---|
| `vb_Gcheck.ps1` | One queue entry (a tool + args + presets from an entry JSON) captured per arm. See the arm spec below. Before each call it runs every `BEFORE_NEXT*.ps1` in `D:\tb-gpu-runs`, listed once at call start. Imports when `crA_imported_sha.txt` differs from the side's sha. Applies the pad-glyph patch. Retries once on missing frames. `-DryRun` prints the commands. Capture only. |
| `vb_Garm.ps1` | Same idea, but takes job.json frame ids. It resolves them to job items and runs `arm_run.ps1`, then `vb_export.py` and `pack_1108.py`. `-NoPush` holds the section for an eye check. `BEFORE_<Id>.ps1` and `SKIP_<Id>` hook files are honoured. |
| `arm_run.ps1` | Engine of `vb_Garm`: worktree checkout, flips (`@sha:path` byte copy, `%sha:overlay.json` deep merge, or a file/key/value triple), import, and one Godot run per job command. |
| `run_tool.ps1` | Launches one Godot tool run. Each preset gets its own APPDATA copy (`appdata-<Preset>`, whose `graphics_override.cfg` names the preset). Has a watchdog timeout (`TB_RUN_TIMEOUT_MIN`). |
| `json_flip.py` | Applies flips to the worktree's JSON: `--overlay` deep-merges an overlay file; `--from` copies a file's bytes from a commit. |
| `pack_check.py` | Copies a vb_Gcheck run into `G-<id>/<side-preset>/` on the frames worktree, with a manifest, sky check and blank scan. Holds the section on any SCRIPT ERROR, sky-only frame or missing frame. `PACK_STAGE_FRAMES=1` bypasses the sky heuristic for neutral pose-stage frames (after an eye check only). |
| `pack_1108.py`, `vb_export.py` | Pack and export for vb_Garm sections (grouped by board row). |
| `blank_scan.py`, `sky_check.py` | Frame checks used by the packers. |
| `vb_Gpush.ps1` | Stages only one section's files on tb/gpu-frames-1108, commits, pushes, and prints that section's own commit. |
| `vb_Gafter1112.ps1` | Sequence runner: waits for a marker line, then runs the `AFTER_*.ps1` files listed once at loop start. |
| `queue_watch.ps1` | Read-only poll of `gpu_queue.json` on the coordinator branch; exits when new ids appear. |
| `pad_glyphs.py` | Keeps prompts on gamepad glyphs (mouse or keyboard input on the PC flips them otherwise). |
| `cam_check.py` (new 13 Nov) | Compares `capture_manifest.json` `camera_position` for named frames between two runs. Exit 1 if any frame is more than 0.3 m apart. |
| `pair_frames.py` (new 13 Nov) | For each scored frame, picks the base run and arm run (same config, same preset) whose cameras match best. Writes a pairs JSON. |
| `compose_pairs.py` (new 13 Nov) | Builds a composite `R1108-G-<section>` from a pairs JSON, copying each source run's `*.err.log`, so `pack_check.py` still sees every script error. |
| `example_BEFORE_NEXT_hook.ps1` | The last front-of-queue hook: hallmoss + telldust2, gated on a caller id, with a one-retry camera pairing. It was never run (wrap-up). |

Arm spec format for `vb_Gcheck.ps1`, one string per arm:
- `tag=<sha>`: the commit, captured as-is.
- `|%<sha>:<overlay.json>`: deep-merge an overlay.
- `|@<sha>:<path>`: copy a file's bytes from a commit.
- `|+<arg>`: an extra tool argument for that arm only.

## Fight-camera pairing (why the three new tools exist)

`phase2_capture_fights.gd` is not deterministic run to run, even at `--fixed-fps 20`. The fight itself diverges: damage numbers differ at the same frame. The camera follows the fighters and is steady within a run.

Over 15 runs of one config:
- `warden_aldis-08` landed at 7 camera positions, up to 10.7 m apart.
- `warden_aldis-03` landed at 3 positions.

So a base/arm pair from a single run of each side is often framed differently. The method:
1. Capture base and arm.
2. Run `pair_frames.py` over every run of the same config and preset.
3. Re-run the arm side once if a scored frame is unmatched.
4. Run `compose_pairs.py`, then `pack_check.py <id> <sha> <tool> <note> <frames…>`, then `vb_Gpush.ps1`.
5. Name unmatched frames in the note.

## Runbook (one arm)

1. **Dry-check the tree.** Fetch the branch. Check the commit contains main. Read the overlay. Trace each key to its reader (`git grep`) and check nothing later overrides it, such as a later flag in file order, an exterior block, or a scope gate.
2. **Write the entry.** Write an entry JSON (tool, args, presets, `godot_args` such as `--fixed-fps 20` for fights). Run `vb_Gcheck.ps1 … -DryRun`.
3. **Queue it.** Add it to the running sequence: a `BEFORE_NEXT_<n>_<name>.ps1` hook gated on a caller id that has not started yet (`if ($Id -ne "<caller>") { re-arm; return }`), or a not-yet-started `AFTER_*.ps1`. A running PowerShell script never sees edits.
4. **Eye-check.** Build a base|arm contact sheet with a mean diff. Check framing (`cam_check.py` / `pair_frames.py`). Read the script errors. If there's no visible change, hold it and push nothing.
5. **Pack and push** each section as soon as it's ready. Report to LANE-SCOUT (full), the owning lane, and the coordinator (one line).
