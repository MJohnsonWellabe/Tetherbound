# Stormwood forest foundation and Stormheart — 2026-09-09

**HELD. No visual acceptance or traversal pass.** The corrected production run
shows ground cover at Rodline Post and Lantern Hollow. The parent inspected both
frames and still found raw cylindrical/polygon forms in Lantern Hollow and
small house/NPC proportions. Subsequent source attribution identifies those forms
as the four-relic shrine, not gameplay decks (details below). A clean render and a bound node do not establish
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
  Glass Field landmark probe prepared after capture2; subsequently parsed/run as
  recorded in the follow-up below.
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

## Follow-up source attribution: Lantern Hollow foreground

`scripts/world/stormwood_ending.gd::_build_spark_shrine` mounts the ordinary
`SparkOfStormwoodShrine` at XZ `(-450, 3960)`. The shared
`scripts/world/realm_heart_shrine.gd::_build_visual` produces its untextured
10-sided StoneBase, octagonal HeartSocket and four rectangular standing stones;
`_build_relic_slots` adds the other three relic sockets. Those shapes and offsets
match the four gray forms in the retained Lantern Hollow image. They are not
Stormheart arena decks or new grass/scatter geometry.

The Settings catalogue and route potion use that same `(-450, 3960)` coordinate.
The canonical capture therefore resolves the trainer onto the central shrine
collision. This is the retained canonical audit view, not an ordinary walking
approach to the shrine. No image has been altered or discarded. A later bounded
Stormwood shrine presentation can inherit the shared state/prompt/collision contract
and replace only the visible masonry. No shrine source edits have been made; the
current next action remains the useful Stormheart approach capture.

The tree fixture's subsequent read-only hash is
`EA768BE953816F2F2557A367D9242B557359A4F8AC032E80D6738A0EF5B314CC`.
It was not included in the original capture2 source snapshot.

Next: source-only preparation of a supplemental Stormheart approach view from the
Glassfield catalogue destination using ordinary player/look input and the real
camera. Run only after the next native lease; preserve the canonical frame and
disclose supplemental motion. The remaining shrine/building presentation defects
and independent visual judgment remain open.

Supplemental render arguments (subsequently executed; follow-up below):

```text
--path C:/Projects/Tetherbound --rendering-driver opengl3 --resolution 1280x800 --position -10000,-10000 --script tools/_capture_stormwood_stormheart_context.gd -- --biome=stormwood --subset=glass_field --times=day --output=res://shots/catalogue/stormwood/stormheart-context-first-0909
```

The leased phase parsed the new probe under the 120s guard, then captured under
the 180s guard in a fresh output directory. The probe requires the
unchanged Glass Field coordinate, retains its canonical frame, and fails on
unreached ordinary look/walk targets.

## Follow-up: first production Stormheart approach — HELD / obstructed

Evidence root: `.artifacts/stormheart-context-0909/`. Parser phase ran
23:46:03–23:46:07Z, exit 0. Production capture ran 23:46:17–23:47:37Z,
exit 0, with three saved frames and no script/engine errors. The existing
interpolation deprecation warning remains. Peak system commit 77.31%, peak process
count 264; terminal Godot census zero. Native lease returned to Creature.

The manifest reports three captured frames against one canonical planned row;
its separately named two supplemental frames account for the difference. All
three files are retained under
`shots/catalogue/stormwood/stormheart-context-first-0909/`:

- `stormwood__dynamo__11__the_glass_field__day.png`
- `stormwood__stormheart__glass_field_look.png`
- `stormwood__stormheart__glass_field_backstep_look.png`

**The composition objective was not achieved.** The first look is inside a nearby
Voltarach mesh. The ordinary backstep clears the camera from its mesh, but the
creature still blocks the intended tree silhouette. This is retained crowding
evidence, not a useful clear finale view, art acceptance or campaign traversal
proof. No creature was moved, hidden, disabled or scaled by this probe.

The actual ordinary `move_back` travelled 12.146m horizontally over 167 physics
frames, ending at `(-316.498, 63.021, 5041.691)`. Ordinary look reached approximately
20.323 degrees pitch. The actual production tree was present at
`(-100, 112.059, 5470)` under `/root/Stormwood/StormheartTree`.

Source attribution: `data/config/stormwood_encounters.json` names
`glass_field_alpha`, Voltarach level 42, at XZ `(-310, 5050)`.
`data/config/debug_teleport_spots.json` uses the identical Glass Field coordinate,
as does the `deepwood_road` critical-route waypoint in
`data/config/stormwood_world.json`. `_named_spawn` in the Stormwood encounter
catalogue gives this fixed encounter zero placement scatter and resolves its Y
from actual terrain. The retained runtime witness is `Named_glass_field_alpha`
at `(-310.012, 65.308, 5049.915)`, body height 4.25m and radius 1.4875m.
This is an authored site/route/teleport overlap; it does not justify global
creature shrinking.

Tested supplemental probe SHA-256:
`A8F0C16F25BD2929105B57CD96CE101B75654341F71D90E3433C0E57EB2C76B0`.
All four production/config source hashes match capture2 above. Inherited helper
hashes are retained in `capture/source-hashes.json`; bake unchanged. The report
and tested probe are frozen for the root checkpoint.

Next work is a supported production route-side offset for this named encounter,
preserving its count, identity, catchability, level and rewards. Actual terrain,
mesh footprint plus ordinary wander, nearby vegetation and route/camera clearance
must be checked before the next production capture. A lateral ordinary approach
may then supplement the unchanged canonical view. Further tree geometry tuning
waits for a useful unobstructed frame; shrine and building source remain unchanged.
