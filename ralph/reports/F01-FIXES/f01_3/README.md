# F01 criterion 3 — night village walk

**BLOCKED R3 — acceptance remains OPEN.** No complete error-free night walk or passing code-blind verdict is claimed. This branch is a WIP checkpoint, not a landing candidate.

Source checkpoint: `89e1a9f75`, branch `tb/codex-r3`, based on `origin/main` at `e2fa5e4e6`. Only F01#3 source commits `d23625120` and `7bbc76535` were cherry-picked as `250f8e2f5` and `89e1a9f75`; `11880d39` was not taken. The rock relocation `9ad7461ac` awaits frame confirmation.

The requested `ralph/reports/F01-FIXES/HANDOFF.md` was absent from fetched `origin/tb/f01-fixes`. The scoped commit history and `origin/tb/reproof-f01:ralph/reports/INTEGRATION/reproof/f01-current/row3/VERDICT.md` supplied the prior evidence.

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

**One exact question:** Which existing approved bake command or commit should R3 use to refresh the F01#3 camp-sign fingerprint while preserving harvest IDs and the data/config-only scope?
