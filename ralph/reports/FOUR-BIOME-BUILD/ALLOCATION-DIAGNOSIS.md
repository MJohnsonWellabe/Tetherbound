# Allocation diagnosis — 2026-09-08 resume

**Updated after the exclusive Cloudreach failure:** live evidence now identifies a
large Codex-owned fanout of Git binary diffs against untracked generated artifacts
as an external pressure source. A repository ignore repair is justified; no game
allocation repair is justified. Recovery is confounded by the owner's intervention,
the capture stopping, and root's local exclusions; do not credit one action alone.

The sole fresh-campaign failure at
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

## Follow-up: live Cloudreach pressure and Git fanout

The exclusive Cloudreach run's real-child receipt is
`shots/catalogue/cloudreach/round-20260909T003357Z/memory-watch.csv`, PID29396.

| UTC | System commit / limit bytes | Godot private bytes | Processes |
|---|---:|---:|---:|
| 00:34:28.853 | 19,650,875,392 /24,344,514,560 | 2,490,703,872 | 551 |
| 00:35:04.306 | 32,675,385,344 /32,790,052,864 | 4,002,148,352 | 1,149 |
| 00:35:07.979 | 32,897,179,648 /32,897,179,648 | 4,013,678,592 | 1,168 |

System commit increased **13,246,304,256 bytes**, while Godot private grew only
**1,522,974,720 bytes**. Most growth was outside the game process. The final sampled
commit equals the limit; the limit itself increased during sampling. Root reported
that new host processes could no longer start and the capture was terminated.
These are sampled values, not proof of the absolute peak after the last sample.

During recovery root captured `.artifacts/allocation-live-git-processes.json`.
The saved JSON contains **846 process entries**, all running Git `diff --no-textconv
--no-ext-diff --binary --no-index -- NUL .artifacts/...` against generated shader
caches, map images, scratch saves and other evidence. **423 entries are direct
children of current Codex PID30060**; most others are Git launcher children. One
older entry identifies previous Codex PID5220 as parent. Root's separate live count
was **688 Git processes**; these are different snapshots, not interchangeable counts.
The saved inventory contains no per-process private-byte measurements, so the exact
aggregate Git commit cannot be reconstructed from that file.

This is direct evidence of task-tool process fanout targeting the generated artifact
tree during the pressure episode. Combined with the system-versus-Godot growth, it
supports Git artifact enumeration as a major external pressure mechanism. It does
not prove every non-Godot byte belonged to Git, nor retroactively identify the full
consumer population in the earlier fresh-game event.

Root verified the giant untracked `.artifacts/` tree was not excluded, then added
**local `.git/info/exclude`** entries for `/.artifacts/` and seven specific existing
generated payload folders under `ralph/reports/FOUR-BIOME-BUILD/`. All files were
preserved; no game code, OS/pagefile setting, or app setting changed. Root stopped
**one** remaining matching local artifact-diff process; the other687 from its live
count had already exited. Do not describe this as killing hundreds of processes.
Root subsequently observed normal status/diff commands below1s, one Git process,
and approximately11GB/24GB system commit.

The owner also said, **"I stopped what was eating memory"**. The consumer and exact
timing were unspecified. Consequently the observed recovery cannot be attributed
solely to exclusions, stopping Godot, or root's one-process cleanup. Exclusions
address a verified exposure to enumeration; their independent effect and stability
still require observation. Root authorized one changed Cloudreach capture after
mitigation; its result was pending when this addendum was written.

## Narrow implementation handoff

Sol may add a tracked, root-anchored **`/.artifacts/`** ignore rule to prevent the
same generated diagnostic tree becoming an untracked diff workload in future
checkouts. Inspect existing ignore conventions and add exact generated report
payload folders only where necessary; do not ignore the report Markdown or probes.
Validate `git check-ignore` on representative generated files, confirm tracked
evidence verdicts remain visible, and time normal status/diff enumeration. This is
repository tooling hygiene, not a game memory/performance patch. Root's local
exclusions are mitigation only and do not ship with commits.

Do not batch Cloudreach cover, reduce map resolution, skip the minimap, or alter OS
memory settings from this evidence. Keep the exclusive full-world lease and monitor
real-child memory, system commit and process count on the already-authorized changed
capture. A failure under normal commit is a different signal requiring its own
receipt. This diagnosis lane launched no additional Godot process in the follow-up
and claims no campaign or visual acceptance.
