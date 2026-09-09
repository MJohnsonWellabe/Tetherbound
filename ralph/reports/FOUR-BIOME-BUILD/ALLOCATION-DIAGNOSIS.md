# Allocation diagnosis — 2026-09-08 resume

Diagnosis only; no production repair justified. The sole fresh-campaign failure at
`map_baker.gd:192` coincides with a Windows-recorded system commit exhaustion event.
The native default-dimension resize and production baker both pass in an isolated
headless fixture. The failed resize is a plausible final victim of system pressure;
these findings do not establish that the minimap caused that pressure.

## Causal receipts

Windows System / Microsoft-Windows-Resource-Exhaustion-Detector Event 2004,
record 1945, created **2026-09-09 00:22:32.0108399 UTC**; its exhaustion timestamp
is **00:22:34.4482415 UTC**. The fresh engine log last-write is 19:22:34 local
(UTC−5). Event process PID **21720**, creation 00:21:51.7683373 UTC, matches the
fresh scratch profile's PID. Preserved XML: `.artifacts/allocation-resume-resource-events.xml`.

| Event field | Bytes / count |
|---|---:|
| System commit charge | 32,752,922,624 |
| System commit limit | 32,897,179,648 |
| Remaining commit | 144,257,024 (137.6 MiB; 0.44%) |
| Process commit charge | 28,366,221,312 |
| Physical memory usage / size | 8,076,476,416 / 8,201,117,696 |
| Processes | 1,357 |
| Godot PID 21720 commit charge | 340,078,592 |

Recorded largest consumers: ChatGPT.exe PID4228 **700,239,872** bytes;
mc-fw-host.exe PID4988 **584,990,720**; codex.exe PID30060 **463,904,768**;
Godot PID21720 **340,078,592**. These are event samples, **not historical peaks**.
There is no complete historical process inventory, so the other roughly 26GB of
aggregate process commit cannot be attributed from this event. Do not call any one
tool the culprit from these four entries. The 1,357-process count suggests many
consumers; it does not identify their executable names or owners.

Other low-virtual-memory events occurred at 18:16:26, 19:14:42 and 19:24:09 local.
The overlap event at 19:14:42 names Godot PID15768 at1,826,439,168 bytes and PID38868
at602,300,416 bytes. The 19:24:09 event still names fresh PID21720 and records
32,810,086,400 /32,897,179,648 system commit and1,373 processes. The later observed
~23GB commit limit is different from the recorded ~30.64GiB limit during failure;
post-crash free memory does not refute event-time exhaustion. The mechanism behind
the limit change was not established; no pagefile or OS setting was changed.

## Dimensions and native fixture

`tools/allocation_resume_map_probe.gd` reads the current production world bounds,
uses the production scale constants, calls native RGB8 bilinear resize, then calls
the actual `map_baker.bake()` with a flat RefCounted world. No scene, Terrain3D,
render, cache/save write, or progression injection. The flat height lies underwater
to avoid irrelevant heightfield path sampling cost; authored route overlay still runs.

Command: isolated APPDATA `.artifacts/allocation-resume-profile`, installed Godot
4.7 console, `--headless --path . --log-file .artifacts/allocation-resume-map-engine.log
--script tools/allocation_resume_map_probe.gd`.

First attempt: **exit0, ALLOC_PROBE PASS, no engine errors**. Authored bounds
x−1024..1024, z−512..7680 produce **256×1024 RGB8** (786,432 bytes), resized to
**512×2048 RGB8** (3,145,728 bytes). Heights require1,048,576 bytes. Native resize
and full production bake both returned the correct dimensions. Godot tracked static
memory was49,211,401 bytes before,52,359,953 after production bake; lifetime peak
65,119,606 bytes. These are engine static counters, not Windows private-memory peaks.
This rules out oversized authored dimensions in the current source and a deterministic
failure of this native resize at normal pressure. It does not rule out engine behavior
under exhaustion, corruption elsewhere, or a full-world allocation surge.

## Current read-only process census

At approximately19:28 local there were259 live processes, not1,357. Before the survey
grew, aggregate private MiB: ChatGPT6processes1097.9; svchost97/704.3;
msedgewebview2 13/571.0; mc-fw-host2/562.2; codex1/500.1; Godot1/483.2;
explorer2/331.1; node4/95.5. Snapshot payload:
`.artifacts/allocation-resume-process-totals.json` (later sample, dynamic values).

Parent/start/path inspection identifies active survey chain pwsh11448→powershell28556
→Godot-console28448→**real Godot16736**, started19:27:52 local. At19:29 the real
child had5,705,609,216 private bytes and1,975,525,376 working-set bytes; it is active,
not a stale cleanup candidate. Other current tool shells belong to this inspection
or Codex app MCP servers; there was no verified stale task-owned Python/PowerShell
population to clean up. App MCP hosts are not assumed disposable. Nothing was killed.

The survey's existing memory sampler selected the tiny **console wrapper**, which
cannot measure the actual game. Root was immediately notified. New read-only
`tools/allocation_resume_memory_watch.ps1` samples the explicit real child PID, private
bytes, peak paged/working-set counters, system commit/limit, and process count. It
does not claim exact peak private bytes: periodic private samples can miss a spike.

## Narrow handoff

No Sol production brief is supported yet. Do not batch Cloudreach cover, reduce map
resolution, skip the map, modify pagefile settings, or retry unchanged full campaigns
on this evidence. Preserve exclusive full-world lease and collect real-child plus
system-commit samples around the next already-authorized run. If pressure recurs,
capture aggregated executable counts/private totals while it exists to identify the
missing historical consumers. Any cleanup needs verified task ownership and root's
authorization. If a normal-commit exclusive run still fails, retain that distinct
receipt before isolating a game/engine defect. This lane ran one tiny fixture and
no full-world test; it does not claim campaign or visual acceptance.
