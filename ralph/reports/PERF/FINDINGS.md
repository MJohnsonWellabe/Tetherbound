# PERF lane findings (F26#5 / ACCEPTANCE §7)

Branch `tb/perf`. Target: the GTX 1060 at Medium, 1080p, averages ≥60 FPS with 1% lows ≥40 in every realm; Low is faster still. The ROG Ally at 15 W must hold ≥30 FPS. The far floors stay.

## How the numbers were taken

- **GTX 1060, Forward+ Medium 1080p.** Codex ran packaged routes on PR #525: perf-ab-1, then perf-retime-1. These are the only device numbers here.
- **This container (4 CPU cores, no GPU).**
  - `tools/perf_probe.gd` runs under xvfb with the Compatibility renderer. It reports structural counters only: draw calls, primitives, objects, node and light census, per-family attribution and a far-floor A/B. Software frame time is never quoted.
  - `tools/perf_cpu_probe.gd` runs headless with the Dummy renderer. It measures main-thread CPU frame time while standing (`--bisect`), walking the route (`--walk`) and over a 10-minute soak (`--soak`).
- JSON for every run is in `probe/`. The visual verdicts are in `village-batch/` and `light-fade/`.

## Device baseline (Codex perf-ab-1, diagnostic engine host, GTX 1060 Medium 1080p)

| Route | Far floor | Avg FPS | 1% low | True process ms mean | GPU ms mean | Draws |
|---|---:|---:|---:|---:|---:|---:|
| Meadows before → after the far floor | 520 → 2000 | 5.38 → 5.81 | 1.07 → 1.19 | 152 → 138 | 28.3 → 28.0 | 2169 |
| Tidewake before → after the far floor | 520 → 6500 | 5.30 → 4.06 | 1.15 → 1.07 | 116 → 142 | 21.7 → 32.8 | 759 → 773 |

**Meadows and Tidewake are CPU-bound.** Main-thread process time is 4–5× the GPU time. In Meadows the far floor costs almost nothing. In Tidewake it adds about 11 ms of GPU time and about 26 ms of process time; that cause is still open.

## Fixes landed on tb/perf

| Commit | Fix | Evidence |
|---|---|---|
| `c641da40` | `world_audio.gd` polls creature-voice connections from a set every 0.5 s. It used to run an O(n²) `Array.has` scan every frame over ~1,160 wild bodies. | Headless Meadows wall time ~56–70 → ~26 ms/frame. 77 tests green. |
| `6632f2fd` | Static per-material merge of settlement kit modules (`static_mesh_batch.gd`), with the LOD chain regenerated. | Meadows stand draws 8641→5396, 4461→2525, 2428→963; primitives ±1%. Judge: EQUIVALENT 8/8. 81 tests green. |
| `018918a5` | Distance fade for shadowed local lights. Exterior lights drop only their shadow past 18 m; room lights are untouched to 72 m, then fade light-first. | Hall nave stand 8971→6646 draws. Judge: EQUIVALENT 8/8 (two leaking variants were rejected). 92 tests green. |

**Device re-time (Codex perf-retime-1, Meadows, at `6632f2fd`):** average FPS 5.81 → 7.36, true process mean 138 → 110 ms, draws 2170 → 1917, GPU 28.0 → 27.1 ms. Still far from the target.

## Top costs per realm (current read)

_In progress. Updated as the soak, walk and other-realm probes land._
