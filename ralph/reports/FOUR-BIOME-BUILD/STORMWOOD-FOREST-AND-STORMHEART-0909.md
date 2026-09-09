# Stormwood forest foundation and Stormheart — 2026-09-09

**HELD. No visual acceptance or traversal pass.** The corrected production run
shows ground cover at Rodline Post and Lantern Hollow. The parent inspected both
frames and still found raw cylindrical/polygon platforms in Lantern Hollow and
small house/NPC proportions. A clean render and a bound node do not establish
whole-scene quality. A fresh independent judge was unavailable at the thread limit;
the author has not self-accepted these frames. Stormheart needs its own clear
production approach render and independent assessment.

## Implemented scope

- `scripts/world/stormwood_world.gd`: instantiate the existing enabled GrassField
  in the production Stormwood scene, bind its actual Terrain3D and player camera,
  and register settlement ground-clear footprints.
- `data/config/stormwood_vegetation.json` and `scripts/world/stormwood_scatter.gd`:
  clustered trees and understory replace the sparse background lattice; green
  installed leaf textures replace crimson ornamental bushes. Existing terrain,
  route, structure, landmark and occupancy exclusions remain in force.
- `scripts/world/stormheart_tree.gd`: textured split bark, buttress roots, branch
  crowns made from installed leaf surfaces, and timber ascent dressing. Physical
  floors, ramps and ascent collision geometry remain unchanged. Lower inner bark
  radius is 46m through the 174m Crown floor, outside the 44m arena annuli; taper
  begins above 185m. Root ends sample production terrain height.
- `tests/test_stormheart_presentation.gd`: native construction verifies nonempty
  surfaces, lower shell clearance, retained floors and root exclusion bounds at
  the southern mouth and Water departure. This is geometry evidence, not walking.
- `tools/_capture_stormwood_groundcover.gd`: existing production catalogue capture
  with terrain/camera binding witnesses; no replacement world or camera.
- `tools/_capture_stormwood_stormheart_context.gd`: source-only supplemental
  Glass Field landmark probe; prepared after capture2 and not yet parsed or run.
- Official bake: manifest plus 121 region binaries. The complete owned output list
  is [STORMWOOD-FOREST-AND-STORMHEART-0909-BAKE-FILES.txt](STORMWOOD-FOREST-AND-STORMHEART-0909-BAKE-FILES.txt).

Shared GrassField, shaders, terrain configuration and other biome sources were not
edited by this lane. This report and the bake-file list are also owned artifacts.

## Retained run evidence

Evidence root: `.artifacts/stormwood-visual-foundation-0909/`.
Godot 4.7 stable, Windows, Compatibility/OpenGL3. The wrapper scoped a fresh profile
per phase, used 120s check/test and 180s bake/render deadlines, monitored 90% system
commit and 400 processes, and cleaned only owned processes. Capture2 peaked at
80.36% commit and 264 processes. Terminal census was zero Godot processes; the
native lease was released and now belongs to Water.

| Phase | Result |
|---|---|
| `check` | Clean check-only log; launcher exit code unavailable, retained as null. |
| `bake` | Official terminal marker: 262,434 kept, zero drained, 121 regions, 9,252,570 bytes. Launcher exit code unavailable, retained as null. |
| `unit` | Exit 0; bake freshness test: 1 test, 1 assertion, zero failed. |
| `capture` | **Failed and preserved.** `_bark_quad` assigned an untyped ternary Array to `Array[Vector3]`, followed by empty mesh errors. Manually stopped owned PIDs 11636/12348/412 at 23:27:02Z. Original result is unchanged; `capture/attribution.json` records `manual_script_error`. No image or clean-production credit. |
| `treeunit` | After explicit typed-array assignment and shell/root clearance correction: exit 0, 1 test, 127 assertions, zero failed; clean stderr. |
| `capture2` | 23:29:09–23:30:29Z; exit 0, 2/2 frames complete, no script/engine errors, clean stderr. Existing interpolation deprecation warning remains. |

The correction did not change scatter; no redundant bake was run. The manifest
fingerprint is **8963329852361785**, seed **20260906**. The focused freshness test
verified the official bake against current configuration/source inputs.

Capture2 uses production `res://scenes/world/stormwood.tscn` and the actual
`/root/Stormwood/CameraRig/Camera3D`, FOV 70. Both witnesses report ground cover
present, visible and bound to `/root/Stormwood/Terrain`; its bound camera is the
rendering camera. Each reports 62,140 tuft instances, with camera-follow centres
`(-698, 0, 2296)` and `(-452, 0, 3956)`. The screenshots visibly contain grass;
counts alone do not prove coverage quality or clear traversal.

Retained frames and manifest:

- `shots/catalogue/stormwood/groundcover-corrected-0909/stormwood__conductor_run__05__rodline_post__day.png`
- `shots/catalogue/stormwood/groundcover-corrected-0909/stormwood__deepwood__09__lantern_hollow__day.png`
- `shots/catalogue/stormwood/groundcover-corrected-0909/manifest.json`

The catalogue uses disclosed debug travel and clock freeze. These are production
presentation samples, not campaign/progression evidence. No finale visibility,
combat clearance, ordinary ascent or Water exit traversal is credited by this run.

## Exact capture2 SHA-256 snapshot

| Source | SHA-256 |
|---|---|
| `data/config/stormwood_vegetation.json` | `EE55462A07C841FC6A349FA17F91A92B9ED802439640BA5D711D82A450BB9D37` |
| `scripts/world/stormwood_scatter.gd` | `59D5A6E9145251C1CAA249B5D3C9E74DED5EA7B557FFC8B21B6EC64564F065CB` |
| `scripts/world/stormwood_world.gd` | `C1EF715570D785F9DDDDEF545D740F13CE041EDED81B70FA84DAD8867B07268B` |
| `scripts/world/stormheart_tree.gd` | `E97A3A7D4C20A74995617888232F5275B58AAB5FEDB85D0C837B6270472FD9BC` |
| `tools/_capture_stormwood_groundcover.gd` | `75384D7F5DED6A4E20D720EF01080D64D910BDA332E3746FA89537A3255431E3` |

The tree fixture's subsequent read-only hash is
`EA768BE953816F2F2557A367D9242B557359A4F8AC032E80D6738A0EF5B314CC`.
It was not included in the original capture2 source snapshot.

Next: source-only preparation of a supplemental Stormheart approach view from the
Glassfield catalogue destination using ordinary player/look input and the real
camera. Run only after the next native lease; preserve the canonical frame and
disclose supplemental motion. The remaining platform/building presentation defects
and independent visual judgment remain open.

Prepared next render arguments (not executed):

```text
--path C:/Projects/Tetherbound --rendering-driver opengl3 --resolution 1280x800 --position -10000,-10000 --script tools/_capture_stormwood_stormheart_context.gd -- --biome=stormwood --subset=glass_field --times=day --output=res://shots/catalogue/stormwood/stormheart-context-first-0909
```

The next leased phase must first parse the new probe under the 120s guard, then
capture under the 180s guard in a fresh output directory. The probe requires the
unchanged Glass Field coordinate, retains its canonical frame, and fails on
unreached ordinary look/walk targets. This source preparation is not run evidence.
