# GPU lane handoff, 13 Nov 2026 21:50 (wrap-up)

**Last frames commit before this note: `2618730fc`** (G-land-mt-seadepth-r2-f39-10-medium).
Branch tb/gpu-frames-1113, started from 21fa0dc6a. Folder: gpu-frames-1108/.

## State of the PC

- Runners have stopped. vb_Glanes1113b.ps1 stopped on STOP_ONE before `beings-tam-coat`. No Godot is running.
- `D:\tb-gpu-runs\STOP_ONE` is still present. Delete it before the next run.
- No BEFORE_NEXT hooks or SKIP files are armed.
- The capture tree D:\tb-gpu-wt-crA is at tb/beings c012a8817, with an import marker for it. D: has about 150 GB free.

## Captured and pushed in the evening block (after 19:30)

| Section | Commit | Notes |
|---|---|---|
| G-lcs-wallband-bridge | 13b890cd3 | Wall-band no-loss, F40#8. The arm turns the cliff and bridge-head wall from brown to mottled grey. Judge for loss. |
| G-lcs-turf-matrix-gate / -shrine / -overlook | c7218f56c / ec71c2758 / 0a1f93781 | TURFGRAIN matrix. Base sides are the F40#0/#19/#21 partial re-score. Coordinator: no loss. |
| G-land-mt-shellshards-crash | 76f13eed9, 050104f20 | Crash evidence; see below. |
| G-land-mt-shellshards-retry | 07806bb97 | Clean, 10/10. The retry spawned turtles where every earlier run had badgers (spawn variation, not the arm). SHELLSHARDS landed in #964. |
| G-land-cs-soiloff | f6e148f94 | Black patches and the pale break slab are gone. Landed in #964. |
| G-lcs-archstand | c6ef25efe | F40#3. The arch is now the subject of the frame. Base survey reads 3/4 (causeway frame is arm-only), as expected. In PR #965. |
| G-lcs-rimseat | b43810834 | F40#17. Cluster seated back from the lip, fainter glow. Departure-lookback incomplete (glide/jump flakes; not row frames). In PR #965. |
| G-land-mt-seadepth-r2r3-high | 790e5f876 | Base vs r2 vs r3, 48 frames. S1/S2 live were sky false positives, released via frames-1108/reasons-G-land-mt-seadepth-r2r3-high.json. **Not judged** (LANE-JUDGE had left). |
| G-land-mt-seadepth-r2-f39-10-medium | 2618730fc | Medium, base vs r2, F39#10. **Not judged**. |

On the r2/r3 eye check, both soften the hard cyan-to-navy shelf edge and keep deep water navy. r3 is close to r2, with a slightly darker middle band.

## Local only, never pushed

- `gpu-frames-1108/G-land-mt-cragback-f39-2-noloss/`
- `gpu-frames-1108/G-things-meadowground-medium-time/`

Both sit untracked in D:\tb-gpu-frames-1108 with their manifests. They were held earlier in the day and my notes don't say why. Eye-check them before any push.

## Still queued, not captured (ralph/reports/COORDINATOR/gpu_queue.json)

- rescore-f39-21-lensground: one-sided F39#21 on main b5cfd21fa; pool 2 or more runs and pair by camera.
- scene-fleecard: F41#16, tb/scene 40ad00e38; run it before SCENE's older arms.
- land-cs-wallband2, beings-perch-clearance, land-mt-veilrebuild (held).
- The rest of vb_Glanes1113b, from `beings-tam-coat` onward:
  - TAM-COAT and the pose batch
  - STATICUB-COOL, TERRAPUP-SPHINX, RIPPLET-DEEP
  - arcs-world, OFFICER-FACES, FLY-SHOULDER
  - CLOUDNIGHT r2, WETPATH3
  - the scene block: PANELFILL, ROSTERNAMES r2, CURB, CACHE, WORKSHOP, TOURNEY
- Entries for these are in D:\tb-gpu-runs\entry_*.json. TOURNEY runs overlay-only on 94e97a6c7 with 1d637e656's fade-only overlay.

## Runner and driver issues

- **NVIDIA driver crash.** Exit 0xC0000094 is an integer divide by zero inside `nvoglv64.dll` 32.0.15.6094 (NVIDIA's Vulkan/GL driver) at offset 0xe93647.
  - It happened 11 times between 13 Oct and 13 Nov. It comes and goes, and one retry fixed it.
  - Godot writes no backtrace, and keeps only 5 logs per preset.
  - Evidence comes from the Application event log (ids 1000/1001) and C:\ProgramData\Microsoft\Windows\WER\ReportArchive\AppCrash_Godot_*\Report.wer.
- **Silent short runs.** vb_Gcheck counts a crashed run as done if it has any images. Always check `exit=` and the image counts per side.
- **F40 matrix tool flag.** The tool needs `--output=`, not `--out=`.
- **Fight cameras branch per run.** The Venn fight starts at camera A or B; the Warden fight takes path P or Q. Pool all runs (warm-ups included) and pair by camera. See docs/TECHNICAL.md §8.1 on tb/coord-runbook-1113.
- **High-perch departure.** It can fail with "glide ended before 35 m" or "repeated Jump did not launch". Both are flakes; the arm side's night departure worked.
- **Sky heuristic.** Calm, even sea reads as SKY-ONLY. Eye-check it, then release it with a reasons-<label>.json.
- **Git during imports.** A git fetch during an import is slow (one timed out tonight). Keep git light while an import runs.
