# F01 criterion 3 — night village walk

**R3 resumed — acceptance remains OPEN.** Round 5 completed an error-free 12-target native controller walk with readable NPC arrivals and successful inn departure. Its fresh code-blind review failed the complete visual sequence: roof/awning surfaces hide the playable view in departure frames 027/035, and the companion substantially obscures the camp arrival in 072. This branch is a WIP checkpoint, not a landing candidate.

Coordinator answer [6005143821](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-6005143821) removes the bake blocker without authorizing a bake: drop the terrain fingerpost, use the camp's own presentation config, take the previously frame-confirmed rock move, tune the marginal NPC fills and clear Bram's lamp sight line in data. R3 merged accepted main `f267c2b97`, restored `terrain_playground.json` exactly from that baseline, and cherry-picked `9ad7461ac` as `5a030f5f5`. Data tunes the camp fire's existing `glow_scale`, night fills for Mira/Oskar/Nessa/Maren, and Bram's stand spot. Candidate `4f4c200673` places Bram in the public entrance aisle, clear of the tables, barrels and door posts; no interior geometry changed.

## Current proof and retained failures

- Round 3 source `354c64ac69`: unchanged scoped checks **34 tests, 2,689 assertions, 0 failed**, exit 0; unchanged native essence-site smoke **29 checks, 0 failed**, exit 0; import exit 0. Full receipts are in `round3/`.
- Round 3 native walk: **PASS, 101 captures, 12 visited, max_off_road_m=0.00**, exit 0. All seven NPCs won their own prompts, the key was taken, RoadGate opened, and the camp/all three gates were reached. Native GTX 1060 / Compatibility at 1920x1080; saved PNGs are the unchanged tool's 1280x720 output. No engine/script errors. This is traversal proof, not acceptance: the fresh blind verdict in `round3/VERDICT.md` failed Bram's approach/arrival occlusion.
- Round 4 source `b11dce01e`: Bram's west-counter arrival was visually clear in the root inspection, but the walk **FAILED**, exit 1, after 42 captures. Departure selected a western nearest-road point and pushed against the inn's west wall while heading to the old key. Complete raw logs/exit are retained in `round4/`; no fresh judge was run on this incomplete walk.
- Round 5 source `4f4c200673`: **PASS, 97 captures, 12 visited, max_off_road_m=0.00**, exit 0, no engine/script errors. The unchanged native night/from-title walk used private APPDATA and the sole global lock; console 10688 exited and its supervisor released the lock. The full logs, exit and all-frame hash manifest are in `round5/`. The round 3 checks are reused for unchanged relevant source under RD-36; this candidate changes only Bram's data placement. The fresh no-context judge inspected all 97 frames at full size and 30% and returned **DOES NOT PASS**; its complete report is `round5/VERDICT.md`. All NPC arrival faces and prompts read, but 027/035 obscure player/ground and 072 obscures camp clearance. Broader reference bars: A yes, B no; no art-quality closure is claimed.

The next product correction needs roof/awning camera clearance and companion framing, rather than another NPC fill or counter move. Existing `building_prefabs.json` collider boxes and `opening.json` follower formation fields are candidate config locations. The F01 handoff assigns camera/interior work to F21/F38, while coordinator comment 6005143821 approves the NPC/camp data scope. R3 requested a bounded extension to those existing config fields; it has not edited them or created any new equipment.

Only six game files differ from the accepted baseline: `village_npcs.json`, band-1 `props.json` and `harvest.json`, `essence_nodes.json`, `village_npcs.gd`, and the existing scoped `villager_night_light.gd` hook. No tests, tools, fixtures, capture logic or bake guards changed. `11880d39` was not taken. Raw receipts and verdicts are committed; PNGs and isolated user profiles remain local.

## Historical diagnostics before the coordinator answer

Source checkpoint: `89e1a9f75`, branch `tb/codex-r3`, based on `origin/main` at `e2fa5e4e6`. Only F01#3 source commits `d23625120` and `7bbc76535` were cherry-picked as `250f8e2f5` and `89e1a9f75`; `11880d39` was not taken. The rock relocation `9ad7461ac` awaits frame confirmation.

The requested `ralph/reports/F01-FIXES/HANDOFF.md` was absent from fetched `origin/tb/f01-fixes`. The scoped commit history and `origin/tb/reproof-f01:ralph/reports/INTEGRATION/reproof/f01-current/row3/VERDICT.md` supplied the prior evidence.

On a subsequent fetch, `origin/tb/f01-fixes` advanced to `4c508ed7e` and supplied the requested handoff. It reports a prior 12-target pass on `9ad7461ac`, captured with Mesa llvmpipe at 1280x720, and a barely passing blind verdict. Its committed receipts contain the visit/PASS lines but no complete stderr or scatter-repair receipt. Neither that branch nor the newly fetched `origin/main` at `f797d3c0c` changes the pinned bake guard, scope-preparation tool, or scatter manifest. The handoff therefore supplies prior context but does not resolve this checkout's native scatter error or failed blind verdict. R3's product source remains `89e1a9f75`.

## Focused census

On source `89e1a9f75`, the unchanged existing tests passed on their first run: **6 tests, 239 assertions, 0 failed**, exit 0, no engine or script errors. Full native output is `census.txt`.

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=f32_material_census,f32_essence_census
```

The existing `villager_night_light.gd` hook also compiled with `--headless --check-only --script scripts/world/villager_night_light.gd`, exit 0, no errors.

## Capture contract

Use the unchanged `tests/capture_village_walk.gd --time=night --route=visits --from-title` on native NVIDIA/Compatibility, with `--resolution 1920x1080`, under the sole `D:/tetherbound/RENDER_LOCK.json`. This existing tool resizes saved images to 1280x720; native render resolution and saved PNG resolution must be reported separately. No capture tool, fixture, or measurement script was added or modified.

## Native diagnostic capture

Product source: `89e1a9f75`. The `round2/` run used the unchanged capture, isolated APPDATA, and the sole global render lock. Its native renderer receipt is:

```text
OpenGL API 3.3.0 NVIDIA 560.94 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce GTX 1060 3GB
```

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --path D:/tetherbound/codex-r3 --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1920x1080 --script tests/capture_village_walk.gd -- --time=night --route=visits --from-title --capture-dir=D:/tetherbound/codex-r3/ralph/reports/F01-FIXES/f01_3/round2
```

The run saved **72 PNGs** at the tool's fixed 1280x720 output size. Engine receipts reached all seven NPCs on their own interaction prompts, took the old key, and opened/reached RoadGate. The camp, PondGate and TrailGate were not reached before the run stopped. It has no final `[village-walk] PASS` receipt.

The boot logged `ERROR: Stable harvest generation is invalid; repair scoped bake before playing: playground`. The new fingerpost changes `terrain_playground.json`, invalidating the shipped scatter fingerprint. This run therefore remains diagnostic even for its completed legs. Native output is preserved in `round2/night-walk-stdout.txt` and `round2/night-walk-stderr.txt`.

At 2026-10-05 22:58:59 UTC, the owner reserved the GPU for Valheim. The supervisor stopped only its owned R3 process tree, released its own lock, and preserved all frames/logs. The reservation subsequently specified no GPU work before **2026-10-05 9 p.m. America/Chicago** (2026-10-06 02:00 UTC), and continuation still requires absence of Valheim and no newer owner reservation.

`round1/` produced no accepted frames: the reused generated cache lacked Terrain3D's extension registration. That cache entry was restored from the existing imported project; the unchanged capture then passed `--check-only`, exit 0. The original failure is preserved in `round1/cache-registration-stderr.txt`. No game or tool source was changed for this cache repair.

## Fresh code-blind diagnostic review

`night_readability_judge` was created with no inherited conversation. It received only the criterion, PNG paths, visual-judge rubric and reference-art access, and read no source or logs. Its amended result is **DOES NOT PASS**, recorded in `DIAGNOSTIC_VERDICT.md`.

Grandpa and Tam are clear; Mira, Nessa, Maren and Oskar are marginal. Bram is hidden by a large hanging lamp in frame 035. The pre-pickup key is recognizable in frame 064, though marginal. RoadGate is clear. The camp and remaining gate arrivals are unproven. No camp arrival frame exists to confirm the proposed essence-rock relocation, so `9ad7461ac` was not taken.

All PNGs remain local in `D:/tetherbound/codex-r3/ralph/reports/F01-FIXES/f01_3/round2/`; none are committed.

## Existing-tool blocker

The existing `tools/prepare_village_bake_scope.py` was run unchanged and exited 1:

```text
Refused source outside approved village snapshot: data/config/terrain_playground.json
```

Its output is `bake-scope-refusal.txt`. The existing identity-preserving regional writer requires `terrain_bake.gd`'s hardcoded F17 snapshot, approved source `8ee152a47ee90f430a3e8aafb13d2b0d9c9ad1ea`, and exact input hashes. The new camp sign is outside that snapshot. The existing full scatter writer explicitly refuses replacing a stable-harvest-ID generation (`stable_ids_require_identity_preserving_writer`). Editing guards, faking receipts, manually restamping manifests, or building a replacement tool would violate this task's constraints; none was done.

The historical bake question was resolved by coordinator comment 6005143821: remove the terrain fingerpost and retain the approved shipped bake. No bake was refreshed.
