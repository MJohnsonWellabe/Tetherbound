# F01 criterion 3 — night village walk

Acceptance remains **OPEN** until the ordinary-controller night walk and a fresh code-blind judge both pass.

Source checkpoint: `89e1a9f75`, branch `tb/codex-r3`, based on `origin/main` at `e2fa5e4e6`. Only F01#3 source commits `d23625120` and `7bbc76535` were cherry-picked as `250f8e2f5` and `89e1a9f75`; `11880d39` was not taken. The rock relocation `9ad7461ac` awaits frame confirmation.

The requested `ralph/reports/F01-FIXES/HANDOFF.md` was absent from fetched `origin/tb/f01-fixes`. The scoped commit history and `origin/tb/reproof-f01:ralph/reports/INTEGRATION/reproof/f01-current/row3/VERDICT.md` supplied the prior evidence.

## Focused census

On source `89e1a9f75`, the unchanged existing tests passed on their first run: **6 tests, 239 assertions, 0 failed**, exit 0, no engine or script errors. Full native output is `census.log`.

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=f32_material_census,f32_essence_census
```

## Capture contract

Use the unchanged `tests/capture_village_walk.gd --time=night --route=visits --from-title` on native NVIDIA/Compatibility, with `--resolution 1920x1080`, under the sole `D:/tetherbound/RENDER_LOCK.json`. This existing tool resizes saved images to 1280x720; native render resolution and saved PNG resolution must be reported separately. No capture tool, fixture, or measurement script was added or modified.

Native capture and independent verdict are pending. Screenshot payloads remain local and are not committed.
