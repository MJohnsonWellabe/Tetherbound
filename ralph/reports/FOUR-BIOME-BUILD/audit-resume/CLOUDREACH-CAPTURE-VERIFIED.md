# Cloudreach catalogue capture — allocation failure retained

Capture status: **failed before the first frame; not valid visual-audit input**.
This lane performed its one authorized full-world attempt under the exclusive RAM
lease and did not retry. The unique failed round remains at
`shots/catalogue/cloudreach/round-20260909T003357Z/` with its incomplete manifest,
engine log and real-child memory telemetry.

## Command and process identity

- Command: `tools/catalogue_survey.ps1 -Biome cloudreach -Godot C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/cloudreach/round-20260909T003357Z`
- Launch: 2026-09-09 00:33:57 UTC.
- Console wrapper PID: **10844**.
- Real rendered Godot child PID: **29396**, created 00:33:57.622 UTC.
- Monitor: `tools/allocation_resume_memory_watch.ps1 -TargetProcessId 29396`, output
  `memory-watch.csv`. It sampled the real child, not the console wrapper.
- Result: **0/24 PNGs**. `manifest.json` has all 24 planned frame IDs, `complete:false`,
  an empty `frames` array and no harness-recorded failure because the native process
  crashed before `_finish()` could update the manifest.
- The verified PIDs 29396 and 10844 were stopped after the allocation failure; no
  unrelated process was touched. No Godot process remained after cleanup.

## Exact failure

`engine.log` records the first native errors and call path:

```text
ERROR: Parameter "mem" is null.
   at: alloc_static (core/os/memory.cpp:96)
   [0] _json (res://autoload/player_state.gd:473)
   [1] map_for (res://autoload/player_state.gd:196)
   [2] bind_realm_map (res://autoload/game_state.gd:1764)
   [3] _ready (res://scripts/world/cloudreach_world.gd:358)
   [4] _mount_production_world (res://tools/catalogue_survey.gd:252)
   [5] _run (res://tools/catalogue_survey.gd:75)
ERROR: Parameter "mem_new" is null.
   at: _alloc_exact (./core/templates/cowdata.h:476)
CrashHandlerException: Program crashed with signal 11
```

Windows Resource Exhaustion Detector Event 2004, record **1950**, was created at
2026-09-09 00:35:07.0569087 UTC and places the exhaustion at 00:35:07.3742652 UTC.
It records:

| Event field | Bytes / count |
|---|---:|
| System commit charge | 32,819,085,312 |
| System commit limit | 32,897,179,648 |
| Remaining commit | 78,094,336 (74.5 MiB; 0.24%) |
| Aggregate process commit charge | 28,553,580,544 |
| Physical memory usage / size | 8,138,039,296 / 8,201,117,696 |
| Processes | 1,173 |
| Godot PID 29396 commit charge | 4,011,167,744 |

The other named event samples were ChatGPT PID 4228 at 718,495,744 bytes,
`mc-fw-host` PID 4988 at 578,883,584 bytes, and Codex PID 30060 at 537,239,552
bytes. These are event samples, not an attribution of the other aggregate commit.

Root's live pressure census identified the missing process-count surge: **688
`git.exe` processes** whose command lines were Codex-parented `git diff --no-textconv
--no-ext-diff --binary --no-index -- NUL .artifacts/<generated-cache>` operations.
That separate snapshot is preserved at `.artifacts/allocation-live-git-processes.json`.
The process storm explains the count spike and a large source of system pressure; it
does not change the exact Godot allocation crash recorded above.

The periodic watcher shows the real child growing from 2,490,703,872 private bytes
at 00:34:28Z to 4,013,678,592 at 00:35:07Z. In the same samples, system commit grew
from 19,650,875,392 / 24,344,514,560 bytes to 32,897,179,648 /
32,897,179,648 bytes, while process count grew from 551 to 1,168. The changing commit
limit is observed telemetry; this lane did not change pagefile or OS settings. The
watcher then itself stopped at `Get-Process` with `Insufficient memory to continue the
execution of the program.`

After the owned Godot chain was stopped, the read-only census at 00:37:42Z showed
10,954,014,720 / 24,344,514,560 committed bytes, 2,675 MiB available physical memory,
252 processes and no Godot process.

## Catalogue plan and coordinate check

Before launch, `tools/catalogue_survey_validate.ps1 -Biome cloudreach -Json` returned
12 destinations and 24 day/night frames. Each validator X/Z pair was compared directly
with `data/config/debug_teleport_spots.json`; all 12 matched exactly:

| # | Band | Settings destination | Requested X/Z |
|---:|---|---|---:|
| 1 | `gate_lower_cliffs` | Realm Gate Crag | `0, -130` |
| 2 | `gate_lower_cliffs` | Galefoot Waycamp | `-280, 520` |
| 3 | `broken_causeways` | Three Bells Bridge | `-485, 1320` |
| 4 | `broken_causeways` | Broken Skyroad Arch | `350, 1940` |
| 5 | `windscar_ravine` | Windscar Beacon | `-260, 2680` |
| 6 | `windscar_ravine` | Windscar Flight Aerie | `400, 3250` |
| 7 | `high_roost_sky_shrine` | Sky Shrine | `1110, 2940` |
| 8 | `high_roost_sky_shrine` | The High Perches | `900, 2700` |
| 9 | `upper_cloudreach` | Cliffhold | `-340, 3970` |
| 10 | `upper_cloudreach` | Old Wind Observatory | `430, 4500` |
| 11 | `summit_final_stronghold` | Summit Eyrie | `100, 5350` |
| 12 | `summit_final_stronghold` | Waterward Overlook | `-420, 5650` |

There are no actual player/camera coordinates or frame identities to validate because
the crash occurred in production-world mount before destination 1. Trainer/HUD
visibility likewise cannot be claimed. The retained empty manifest and absence of PNGs
make that failure explicit rather than substituting older Cloudreach images.

## Scope verdict

This attempt reproduces system commit exhaustion during an exclusive Cloudreach mount;
it does not establish that `player_state.gd`, realm-map binding, or Cloudreach look
allocation is the root cause. The crash site is a plausible final allocation victim.
No production, save/progress, capture-tool, retry-budget, `game_state`,
`shell_build_budget`, `cloudreach_world` or `cloudreach_look` change was made. The
earlier Lane 0 entry render remains unchanged. A fresh diagnosis is required before
another full-world attempt.
