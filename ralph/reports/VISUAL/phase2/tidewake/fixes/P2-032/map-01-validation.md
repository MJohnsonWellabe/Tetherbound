# P2-032 / MAP-01 capture validation and strict recheck

**P2-032 fixed by activation commit `8c5009e09`.** This closes only the catalog defect in which the displayed biome heading disagreed with the apparently active realm tab. The independent code-blind [visual judgment](map-01-visual-judge.md) passes all three affected realms; this evidence/source recheck agrees. No chapter or regional art bar is accepted here.

## Capture provenance

Six separate native boots on source `0930716acaf88f4827576b050e782c32fb46269e` produced 24 images: before/after for Water/Tidewake, Stormwood and Cloudreach, four frames per boot. All six raw manifests report complete=true, failures=[], seed 2042, Windows, gl_compatibility, NVIDIA GeForce GTX 1060 3GB, and resolution 1920x1080. Independent image inspection confirms every JPEG is actually 1920x1080. Each boot captures exploration_hud, menu_map, map_selected_meadows and map_selected_<production realm>.

The committed source default was **false** at capture time. Before uses false; after uses a temporary true override of `map_realm_selection_visual.enabled`. The recorded repro specifies all other visual candidate flags at committed defaults, isolated APPDATA `.local/appdata`, and TB_WORLD_SEED=2042. No production source edits occurred between the six boots. This is a stocked-party/satchel production-scene fixture, not save/progression proof.

The six retained `map-01-{before,after}-{water,stormwood,cloudreach}/manifest.json` files preserve top-level and per-frame metadata, original paths and SHA-256 hashes, with four 320x180 tiles per sheet. All six original-manifest hashes and all 24 source-frame hashes match local raw files in this recheck. Root also successfully ran compact-round verification on all six. Raw `raw-map-01-*` directories remain local and must not be staged; the original compact inventory is unchanged.

Repro for each phase/realm (exact per-run command and configuration are retained in its compact manifest):

```text
Godot_v4.7-stable_win64.exe --path . --rendering-driver opengl3 --resolution 1920x1080 --fullscreen --audio-driver Dummy --script tools/phase2_capture_ui.gd -- --biome=<water|stormwood|cloudreach> --seed=2042 --map-cycle --output=res://ralph/reports/VISUAL/phase2/tidewake/fixes/P2-032/raw-map-01-<before|after>-<realm>
```

## Explicit cycle and behavioral limits

`tools/phase2_capture_ui.gd::_shoot_map_cycle` visits Meadows first, then returns to the production realm. It emits the existing non-disabled Button.pressed signal, waits eight process frames, and asserts `_display_realm()` matches the requested realm. This exercises the production selection callback, not physical mouse/controller input. Each explicit frame records selected_realm, selected_button_disabled=true and available_realms=[meadows, production realm]. Initial menu_map frames do not contain this explicit cycle metadata. Every frame records the production CameraRig/Camera3D, player_present=true and ui=true.

In each after sheet, the outlined tab agrees with its heading in the initial realm, Meadows and return states. The independent judge inspected all 24 native images and all six compact sheets, found the cue readable across the three label lengths, and observed no new adjacent layout regression. The separate strict recheck inspected all three after sheets and verified their explicit state metadata. Before/after stills do not prove physical input, focus, persistence or controller usability.

## Source and test checks

The styling implementation is `d68213708`. The narrow diff from capture source `0930716ac` to activation `8c5009e09` changes only the config gate false→true and its comment; `scripts/ui/tab_map.gd` is unchanged. Selected styling duplicates the inherited normal StyleBoxFlat on row rebuild, preserving margins/radii, and adds bright text plus a teal border to the selected disabled button. Selection, available-realm semantics, focus mode, map canvas and input callbacks are preserved, with no per-frame style allocation. Independent source review found no actionable issues.

Existing realm-view tests passed 8 tests / 36 assertions / 0 failures before activation (`.local/phase2/map-realm-selection-focused.log`). Root reran the actual enabled config with the same 8/36/0 result and no errors (`.local/phase2/map01-enabled-tests.log`). These tests cover realm-view semantics; the native comparison supplies the visual evidence.

The catalog recheck is **PASS for P2-032 only**: the selected realm cue matches the displayed realm rather than suggesting Meadows or the opposite choice. Existing sparse map content, Cloudreach label truncation and cramped footer remain separate defects documented by the judge. Small compact tiles prove selection hierarchy, not full small-screen text legibility. Chapter Bars A/B are not assessed. Subsequent default-off dune work at `e22fdbcb2` is outside this captured map change and awaits native evidence.
