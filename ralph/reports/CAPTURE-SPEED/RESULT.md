# Capture-speed lane: result

Branch `tb/capture-speed`, based on main `2f2901db0`. Measured in a 4-vCPU cloud container. Forward+ runs used Mesa lavapipe at High, 1920×1080, under xvfb. Headless runs give the CPU-only reference. Absolute seconds will differ on the GTX 1060 rig; compare the ratios.

## Hand-off (top)

| # | Change | SHA | Before → after (this container) |
|---|---|---|---|
| 1 | **GameMenu stops walking the whole scene every frame** while no combat node is cached. This is the main game-side boot fix and players get it too. | `fd833691e` | Cloudreach Forward+ build **415.5 s → 164.5 s**; ground cover 348.5 → 102.7 s. Headless sliced Cloudreach 143.7 → 125.6 s; Meadows 36.0 → 34.3 s |
| 2 | **Batched launches** with `--jobs=<json>` or `--job=`, for `phase2_capture_dialogue.gd` (and defeated dialogue) and `phase2_capture_build_systems.gd`. Adds `tests/test_capture_jobs_args.gd`. | `d6e2c1737` | 11 Cloudreach dialogue launches → 1 boot (verified: 11 jobs, 11 manifests, frame names unchanged) |
| 3 | **Cheap Forward+ upload frames** while a solo world build slices: no main 3D pass, no vsync wait, both restored at build end. Flag: `performance.json forward_build_cheap_frames` (true). | `d6e2c1737` | Not measurable on lavapipe: its 3D frames don't behave like the GTX 1060's. Removes rendering of the half-built world at High from all ~2,400 Cloudreach upload frames and ~240 Meadows ones |
| 4 | **Cloudreach ground-cover instance cache**, on only with `--ground-cover-cache[=<dir>]`. Adds `tests/test_cloudreach_cover_cache.gd`. | `f387e380a` | Ground cover 72.7 s → 0.4 s on a hit; headless build 125.7 → 48.4 s; **Forward+ build 164.5 → 62.3 s**. Buffer hash identical for no-cache, miss and hit |

All four changes together, Cloudreach Forward+ on lavapipe: **415.5 s → 62.3 s per boot**, with the same 2,229,766 grass, 30,305 flowers and 1,244 bushes. Merging the per-post launches then removes 10 of 11 Cloudreach boots, 20 of 21 Meadows dialogue boots and 11 of 12 build-systems boots, provided those 12 differ only in output and flags (see below).

### Commands for the GPU driver

Shared prefix (unchanged): `godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --script res://tools/<tool>.gd -- --preset=<High|Medium> --source-commit=<40-char sha>`

**Cloudreach dialogue (11 launches → 1).** Each job's `output` is the folder the single launch used to write:

```
godot … --script res://tools/phase2_capture_dialogue.gd -- --biome=cloudreach --seed=2042 --preset=High --source-commit=<sha> --ground-cover-cache --jobs=res://<path>/cloudreach_dialogue_jobs.json
```

```json
{"jobs": [
  {"output": "res://<out>/warden_aila", "args": ["--subset=cloudreach__inventory__character__warden_aila"]},
  {"output": "res://<out>/healer_iven", "args": ["--subset=cloudreach__inventory__character__healer_iven"]}
]}
```

The full list has one job per post: `warden_aila healer_iven bridgekeeper_orrin courier_neri keeper_maela naturalist_sora trader_kelm young_trainer_tavi defector_rusk officer_voss captain_veyra`.

**Meadows dialogue (21 launches → 1).** Same pattern, one job per `--subset` the driver uses today. The inline form also works and is repeatable:

```
godot … --script res://tools/phase2_capture_dialogue.gd -- --biome=meadows --seed=2042 --preset=High --source-commit=<sha> "--job=res://<out>/mira|--subset=meadows__inventory__character__mira" "--job=res://<out>/oskar|--subset=meadows__inventory__character__oskar" …
```

**Meadows build_systems (12 launches → 1)**, assuming the launches differ only in output and per-run flags:

```
godot … --script res://tools/phase2_capture_build_systems.gd -- --biome=meadows --preset=High --source-commit=<sha> "--job=res://<out>/plain" "--job=res://<out>/gamepad|--gamepad" "--job=res://<out>/hints|--craft-hints-preview"
```

**Rules:**
- A job may add `--subset`, `--start/--count`, `--defeated-start/--defeated-count`, `--times`, `--views` or a tool flag.
- A job may not change `--biome`, `--character`, `--seed`, `--preset`, `--low-resolution` or the source SHA. A batch carrying any of these is refused before boot.
- Arms on different commits, and High versus Medium, stay separate boots.
- Every job needs its own fresh output folder. With `--preset`, the folder must not exist yet, as before.
- Exit code: 0 only when every job is complete. Each job's `manifest.json` has its own `complete` field, plus `batched_job: {jobs_in_boot, job_index, job_args}`.

**`--ground-cover-cache`:**
- Add it to every Cloudreach capture; other biomes ignore it.
- The first boot of a tree writes about 109 MB to `user://ground_cover_cache/`, and later boots of the same inputs read it.
- A headless boot and a Forward+ boot produced the same key here, so a cache can be shared between them.
- Old keys are never reused, so delete the folder whenever you like.

## 1. Boot-time regression

**Where the time goes.** The fix is to change what yield frames cost, not what renders.
- Headless (unsliced), Cloudreach ground cover takes 65.5 s.
- Sliced Forward+ took 348.5 s for the same instances, even with cheap frames: about 112 ms of overhead on each of 2,528 yield frames.
- I timed each processing node's `_process` at yield 300. `/root/Game/GameMenu` took 62 ms and the next largest took 1.7 ms.
- `game_menu.gd _fight_in_progress()` ran `_find_combat()`, a recursive walk of the current scene (37k+ nodes). It ran every frame until some node answering `is_fighting()` existed. Cloudreach mounts its combat node last, so every build frame paid for the walk.
- Fix (`fd833691e`): walk only when the current scene changed or a node with `is_fighting()` entered the tree. It returns the same node. `tests/smoke_menu.gd` (fight guard and refusal) passes.

**Why boots doubled since 28 Oct.** No game-side change since 28 Oct altered what ground cover generates:
- `grass_density_per_m2` has been 4.8 since 10 Oct.
- The generator scripts and `cloudreach_visual.json` last changed 25 Oct (flag flips only).
- Instance counts match the GPU lane's report exactly.
- Headless CPU generation is about 65–73 s on this tree.

So I found no single regressing commit to revert. The per-frame costs scale with what each yield frame does:
- The GameMenu walk grows with node count.
- Each Forward+ upload frame renders the half-built world at the active preset. The GPU lane switched to High first on 31 Oct.

Both are now removed or flag-gated. A High versus Medium boot on the rig with and without `forward_build_cheap_frames` would confirm the preset share. I did not change density or look.

**Cheap frames (#3) details.** `shell_build_budget.gd` sets the main viewport's `disable_3d` and turns vsync off while a Forward+ solo build slices. Uploads still flush every frame, and SubViewports keep rendering. `end()` restores both. It is called from `summary()` (all three worlds) and on `tree_exiting`, plus Cloudreach's config-error return. A Cloudreach Forward+ frame captured after the build renders normally.

## 2. Batched launches

- **Base change:** `phase2_capture_locations.gd`. Tools opt in with `_supports_jobs()`: dialogue and build_systems yes; `stormwood_people`, `cloudreach_iven_dialogue` and `_probe_dialogue_speaker` no.
- **Before boot:** every job is validated, its plan loaded, its output checked fresh and its initial manifest written, all before the world boots.
- **One boot, then per job:** after one mount, each job runs its rows and closes its manifest. Mount-time records (camera and character) are copied into every manifest.
- **Between jobs:**
  - Dialogue already closes the panel and lets the conversation camera ease back, as it does between rows of a multi-row launch.
  - Build systems now closes the craft panel, restores its presentation flags and the previous input device, and clears the placed pieces.
- **Verified:** Cloudreach, 11 jobs in one Forward+ boot:
  - 8 complete, each with both frames (`…__<post>.jpg`, `…__<post>__dialogue.jpg`).
  - **Healer Iven, Bridgekeeper Orrin and Courier Neri fail with "debug travel failed" on all 28 stand candidates.** This is not batching: Iven failed the same way as job 0 of a 2-job run, and a headless probe shows `ground_height_at(-318, 539)` is NaN at Iven's stand on this tree. These three posts may be failing on the GPU too ("capture about 0 s").
- **Verified:** Cloudreach build_systems, 2 jobs (`plain` and `--gamepad`) in one Forward+ boot with a cache hit (build 60.2 s). Both jobs got 4/4 frames. The plain craft frame shows keyboard glyphs and the `--gamepad` one shows pad glyphs. The second job's camp frame starts from the same clean stand.

## 3. Ground-cover cache

`cloudreach_ground_cover.gd`:
- **Key:** sha256 over the format, the engine version hash, the source of the five generator scripts, the config, all patches and all exclusions, encoded as binary `var_to_bytes`. Crown-surface samplers are keyed by the bytes of their exact triangles. Any other input object disables the cache instead of risking a stale hit.
- **Hit:** uploads the stored float32 transforms through the same per-patch upload path.
- **Write:** goes to `.partial` first, then is renamed.
- **Verified:** headless no-cache, miss and hit gave the same MultiMesh hash `4d09dbe7…` over 2,959 multimeshes. Forward+ also hit with the cache written headless.

## Limits and notes

- **Meadows Forward+ cannot run in this container.** It segfaults in Terrain3D data loading on lavapipe on unchanged code too (control run with cheap frames off). Meadows was measured headless with the Forward+ slicing path forced by a local, uncommitted hack.
- **Meadows yields only ~240 times**, so fix #1 gains little there. On the GPU its 140 s build is mostly upload-frame rendering, which is what #3 targets, and settlement is 17.5 s of CPU here.
- **Stormwood:** headless, the whole build takes 9.9 s and vegetation `build_batches` takes 1.4 s, against 87 s on the rig. That gap is per-yield frame overhead: GameMenu walk plus rendered upload frames, because Stormwood also mounts its combat runtime after vegetation. Fixes #1 and #3 target exactly this. Stormwood Forward+ was not run here; it uses Terrain3D, like Meadows.
- **If a GPU boot misbehaves with #3** (for example Terrain3D not streaming until the first real frame), set `forward_build_cheap_frames` to false in `data/config/performance.json`. That keeps fixes #1, #2 and #4.
- **Remaining Cloudreach CPU cost** with a cache hit: routes about 25–30 s, and mount about 24 s, of which one 22 s slice is indivisible.
- **Tests run:**
  - `run_tests.gd --only=cloudreach_cover,grass_roles,capture_jobs,shell_build`: 23 tests, 3,717 assertions, 0 failed.
  - `smoke_menu.gd`: passed.
