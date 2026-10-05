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
| `c5e139d6` | Night-gated wild creatures in inactive clusters stay asleep (`encounter_director.gd::_sync_spawn_gates`). | Headless Meadows soak: night frames 47–67 ms → 37–39 ms. smoke_night_ecology and smoke_wild_streaming pass. |
| `8ee50b55`, `ad2c2f54` | Screen-size detail cull (`detail_cull.gd`): unranged small meshes stop drawing below 2.5 px at 1080p. The emissive exemption is limited to objects ≤1.5 m. | Tidewake stand_0 at 6.5 km: 3030→1374 draws (520 m: 1278). Stormwood stand_0 at 9 km: 3985→1211 draws, 6.2M→3.6M primitives (520 m: 992). Judge: EQUIVALENT 6/6 in each realm. 101 tests green. |
| `893e5d36` | Renewable harvest nodes poll stock once per second (`harvest_node.gd`, `renewable_stock_poll_s`), not every frame. | Tidewake headless ~42–47 → ~20–26 ms/frame. 95 tests and 4 F19/F32 smokes green. |
| `31e6846b`, `95f09f7c` | The light-fade and detail-cull hooks collect instance IDs and drain them in **one** deferred flush. One deferred call per mesh overflowed the message queue and **crashed the Meadows boot from 8ee50b55 to 78e4d65c; do not land those SHAs alone**. | Meadows boots; error count 0. |
| `cd85fa45` | `rematch_rules.gd`: `profile()` and `available()` read the cached config and stop deep-copying the whole document on every call. | **The once-a-second stutter in every realm.** TB_BACKGROUND_WORK_TRACE: `rematches.mount_realms` was 120 ms mean / 818 ms max per second, now ~5 ms (Tidewake 0.7 ms, Stormwood 2.5 ms). This matches Codex's ~850 ms spikes and ~1 FPS 1% lows. 104 tests and smoke_rematch_prompt_anchor green. |
| `25f3fce2`, `7aaba354` | Review fixes:<br>- **B1:** a MultiMesh that is empty or single when measured is never ranged, and pickup glow and VFX motes carry `detail_cull_skip`. A ranged MultiMesh gets its half-diagonal added to its range.<br>- The spawn-slice wait uses the population lifetime guard.<br>- Alpha publishes wait while the sliced build runs.<br>- Batching skips materials that depend on per-object space, and meshes with anything drawn beneath them. | Glow layers at a key 3.9 km from the pickup centre: 617 m → unranged. Judge: cull on ≡ off (2/2); `cc22c6c5` lost the halo (2/2), see `b1-glow/`. Meadows stand_0 draws 5,388 → 5,584 from the stricter batching. Independent review PASS. smoke_stormwood_spawn_slicing: worst gap 742 ms, 808 unique wilds. |

**Device re-time (Codex perf-retime-1, Meadows, at `6632f2fd`):** average FPS 5.81 → 7.36, true process mean 138 → 110 ms, draws 2170 → 1917, GPU 28.0 → 27.1 ms. Still far from the target.

## Co-op host stalls after the world facts land (#540 regressions, 2026-10-05)

Found through veridian_same_five and smoke_party_count_after_catches failing on #540. The host's `player_identity` probe timed out, because the host ran ~1 s frames for 60–100 s after the facts. The realm id was always correct.

| Commit | Cause and fix | Evidence |
|---|---|---|
| `2e21a1be`, `9404d3f3` | `teaching.gd::allowed_saved_moves` re-parsed moves.json (70 KB) and tms.json for every creature on every party validation. `move_db`/`tm_db` `load_default()` now return one shared table, keyed on file time and size; accessors return copies. | Native gdb samples showed tms.json being opened mid-frame. Unit test: shared instance, copies never leak. |
| `33e131af` | Wild spawn slicing now runs only in host shells and live sessions. Solo boots spawn in one frame as before. smoke_party_count_after_catches took `wild_creatures()[0..2]` mid-slice and got Warrens bodies 2.7 km away. **No production consumer depends on the list order**: nearest-instance lookups, once-id matches, deterministic node names, no index access. | party_count passes. The Stormwood shell still slices (worst gap 773 ms). |
| `020be38b` | **The single 12.8 s freeing frame** (`meadow_healing.gd::apply`, on host and solo alike). The regreen build called `path_factor` (which walks every road band) for each of ~69k corners. It now asks only the bands whose reach contains the corner, via `playground_heightfield.gd::path_factor_over`. | Regreen 7.7 → 1.35 s; the frame 12.8 → 6.0 s. The regreen mesh checksum (223,824 vertices) is identical. smoke_meadow_healing_land_heals now asserts a frame under 9 s: it fails at 12,848 ms on the old code. |
| `3b0c6319` | **The session-only slow frames.** Under Godot's script profiler (`-d --profiling` on the host), each applied guest passive input ran three full character-record validations. The validators also re-parsed species.json and configs through `redesign_data.gd::json()`, 42k times. `json()` now caches by file stamp and returns copies; `owner_passive_replay._record_valid` memoises by exact content. | Host slow frames per veridian run: ~100 → 5–6 (main: 15). veridian_same_five 3/3 pass; it was failing 3/3. |

The world_audio fix (c641da40) exposed this: faster guest frames meant more passive inputs per second for the host to replay.

Still about 6 s in the freeing frame: `_kill_the_tether_lights` and `_topple_the_pylons` (~1.1 s each, each walking the whole ~180k-node world several times), the regreen (1.35 s), and the scatter regrowth (0.6 s). Sharing one world walk across the steps broke them, because steps free nodes that later steps would read. Slicing the remainder is the next step.

**Stale tests, not in CI, failing identically on default physics and with or without the PERF changes:**
- `smoke_step_up`: "the trainer reached z=-16.88 without standing on the step (y=0.00)";
- `smoke_riding_saddle`: "the party would not take a veridian (it holds 5)";
- `smoke_combat_baseline`: band2/band4 wild lead-HP cost 15%, and the W-1 Warden vs elite cost;
- `smoke_fireball_teaching`: "real backpack teaching did not consume exactly the claimed disc and preserve quick move".

## Top costs per realm (current read)

The Cost, Evidence, Fix and Visual risk columns follow the brief's format. "Open" means not yet fixed.

### Meadows (device: CPU-bound, ~110 ms process vs 27 ms GPU after the fixes)

| # | Cost | Evidence | Fix (status) | Visual risk |
|---|---|---|---|---|
| 1 | Main-thread CPU every frame. It started at ~56–70 ms standing, with the night doubling it and a once-a-second 100–800 ms stutter. | Headless bisect, soak, walk and background trace (`probe/meadows_cpu_*.json`); Codex process 152→110 ms at 6632f2fd. | Audio, night-gate, renewable-poll and rematch fixes landed. Headless Meadows is now ~17–18 ms standing and ~24 ms mean walking. The once-a-second stutter is fixed in `cd85fa45` (rematch config copies). Device confirmation is pending perf-retime-2 at cd85fa45. | None (CPU) |
| 2 | Draw calls from settlement kit modules and cube shadows of room lights. | Attribution: Village 6,417 of 8,641 draws; GrandpaHouse 2,446 at the Hall stand. | Batching and light fade landed: 8641→5396, Hall 8971→6646. The Crossing Hall (crossing_hall.gd, owned by the F17 lane) is still per-module and **open**: to fold it, call `static_mesh_batch.merge()` on its static shell. | Low (judged) |
| 3 | GPU: 27 ms, of which the opaque pass is 13.2 ms and depth 7.0 ms (Codex). GrassField is 1.9M primitives and Terrain 1.0–1.3M; the sun shadow is 2.9–3.4k draws. | Attribution `probe/meadows_*`. | **Open.** Options: a grass ring density per preset, a sun shadow cascade count or max distance per preset, and a Terrain3D LOD bias. | Medium. These are visible and need a judge. |

### Tidewake (device: CPU-bound, ~122 ms process; GPU 22 ms after the fixes)

| # | Cost | Evidence | Fix (status) | Visual risk |
|---|---|---|---|---|
| 1 | Far-floor draws from small unranged dressing at 6.5 km: WaterCamps 1,064, LocalChains 380, RenewableResources 216. | `probe/water_fixes.json` attribution. | Detail cull landed: 3030→1374. | Low (judged) |
| 2 | Physics step 11–14 ms on the device (Meadows ~5 ms), with only 7.6k nodes and 20 physics-processing nodes, none of them significant on its own. Terrain3D collision costs ~4 ms; the physics server's own broadphase and pairs cost the rest. | Codex physics max-step; container toggles: default physics 8.4 ms/step, without terrain collision 4.3. | **Decision for the owner or coordinator:** switch to the built-in Jolt engine. Measured with a temporary override, not committed: **8.4 → 2.4 ms/step**; terrain collision 4.1 → 0.7 ms. Risk is gameplay feel (move_and_slide slopes and steps, areas, net). It needs a full physics, traversal, combat and net smoke batch. | None visual; gameplay feel |
| 3 | Process ~115–140 ms on the desktop (before cd85fa45). In the container, after the fixes, a standing frame is ~23–29 ms and climbs to 42–61 ms in the in-game daytime hours 12–18 (`probe/water_cpu_soak_now.json`). The six First Shore wild creatures near the stand cost ~11–14 ms between them (~2 ms each), in their own script physics: not animation, and not the (bone-less) PhysicalBoneSimulator3D. | Focused A/B: bodies on 21.4 ms, off 7.4 ms; AnimationPlayer off: no change. | **Profiled.** One active wild creature's step costs 1.61 ms. Its script parts sum to ~0.36 ms (AI 0.08, environment velocity 0.002, animator 0.001, a still move_and_slide 0.27); the rest is `move_and_slide()` with real motion against Terrain3D's heightmap under the default Godot physics. The daytime band is consistent with more creatures being active and moving. This is the same cost the Jolt measurement cut 3.5× (Tidewake step 8.4 → 2.4 ms), so the remaining lever is **the Jolt decision**, not a script fix. | None |

### Stormwood (device baseline avg 17 FPS, 1% low 9.7)

| # | Cost | Evidence | Fix (status) | Visual risk |
|---|---|---|---|---|
| 1 | The 9 km far floor draws 802 wild creatures (1,566 draws, 2.5M primitives) and small dressing: 3,985 draws at 9 km vs 992 at 520 m. | `probe/stormwood_cull.json`, A/B in the probe logs. | Detail cull landed: 3985→1211 draws, 6.2M→3.6M primitives. | Low (judged EQUIVALENT 6/6) |
| 2 | Ground cover at 2.0M primitives. | Attribution. | **Open.** Per-preset ring density. | Medium |
| 3 | Night cost from gated wild creatures, as in Meadows. | Soak. | Landed (`c5e139d6`). | None |

### Cloudreach (device avg 74 FPS, 1% low 43; meets the proxy target on average)

Not profiled yet in this lane. The BEFORE shell build timed out on the device (perf-ab-1).
