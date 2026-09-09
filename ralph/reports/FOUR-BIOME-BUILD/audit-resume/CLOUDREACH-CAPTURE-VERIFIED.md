# Cloudreach catalogue capture — verified fresh round

Capture status: **complete and accepted as catalogue-survey input**. The valid round is
`shots/catalogue/cloudreach/round-20260909T004031Z/`: 12 Settings destinations, each
captured by day and night, for **24/24 distinct 1280x800 PNGs**. The manifest says
`complete:true`, records 24/24 planned/captured frames, and has no failures.

The exact command was:

```powershell
tools/catalogue_survey.ps1 -Biome cloudreach -Godot C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/cloudreach/round-20260909T004031Z
```

It launched at 00:40:31 UTC with console PID **37484** and real rendered child PID
**29788**. The survey exited zero with `CATALOGUE SURVEY OK: 24/24 frames`; both
processes exited naturally. Fifty real-child memory samples and 17 five-second grouped
process samples exited normally. Peak sampled child private bytes were **5,180,575,744**;
peak system commit was **16,342,237,184 / 24,344,514,560** (67.14%); peak process count
was **258**. No 90%-commit/400-process safety threshold fired.

`engine.log` has no `ERROR:`, `SCRIPT ERROR`, crash, native allocation error or failed
survey marker. Its only runtime warning is the already-known physical surface warning
for `cr_candy_broken_route_good_07` at `(-88.9, 465.4, 2335.0)`.

## Requested and actual destination validation

The validator's 24 expected frame identities match the manifest's 24 unique frame
identities exactly and in plan order. Every file exists; every file is 1280x800; every
manifest byte count matches the file; every row records debug travel and trainer-framing
intent. For both day and night rows at each destination, actual player X/Z equals the
requested Settings X/Z exactly (maximum absolute X or Z delta **0.0 m**):

| # | Destination | Requested X/Z | Actual X/Y/Z (day and night) | Creatures within 160 m |
|---:|---|---:|---:|---:|
| 1 | Realm Gate Crag | `0, -130` | `0, 150.13, -130` | 4 |
| 2 | Galefoot Waycamp | `-280, 520` | `-280, 180.03, 520` | 6 |
| 3 | Three Bells Bridge | `-485, 1320` | `-485, 338.13, 1320` | 6 |
| 4 | Broken Skyroad Arch | `350, 1940` | `350, 480.13, 1940` | 0 |
| 5 | Windscar Beacon | `-260, 2680` | `-260, 500.13, 2680` | 2 |
| 6 | Windscar Flight Aerie | `400, 3250` | `400, 610.13, 3250` | 4 |
| 7 | Sky Shrine | `1110, 2940` | `1110, 1051.30, 2940` | 0 |
| 8 | The High Perches | `900, 2700` | `900, 1020.13, 2700` | 0 |
| 9 | Cliffhold | `-340, 3970` | `-340, 830.03, 3970` | 0 |
| 10 | Old Wind Observatory | `430, 4500` | `430, 920.03, 4500` | 0 |
| 11 | Summit Eyrie | `100, 5350` | `100, 1160.13, 5350` | 0 |
| 12 | Waterward Overlook | `-420, 5650` | `-420, 1110.13, 5650` | 0 |

Visual inspection of day and night validation mosaics confirms the ordinary HUD in
all 24 frames. The trainer is recognizable and usable as a scale reference in 20/24.
At Windscar Beacon, a large foreground form hides the trainer except for a small lower
body fragment; at Sky Shrine, the foreground well/wall fully hides the trainer. Both
day and night frames at those two destinations therefore retain their catalogue value
but do not provide a useful trainer scale reference. This is disclosed for the blind
judge rather than repaired or recaptured in this mechanical lane.

## Retained first attempt: command and process identity

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

The first attempt reproduced system commit exhaustion during Cloudreach mount; it does
not establish that `player_state.gd`, realm-map binding, or Cloudreach look allocation
is the root cause. The crash site is a plausible final allocation victim. Root's
removal of the generated-artifact Git process storm was the changed condition for the
successful round; the successful production-code run did not reproduce the crash.
No production, save/progress, capture-tool, retry-budget, `game_state`,
`shell_build_budget`, `cloudreach_world` or `cloudreach_look` change was made. The
earlier Lane 0 entry render remains unchanged. This lane makes no production
performance diagnosis or repair claim.
